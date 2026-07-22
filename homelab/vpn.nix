{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab;
  netns = "surfshark";
  vethRoot = "veth-surf-root";
  vethNs = "veth-surf-ns";
  nsIp = "10.99.0.2";
  rootIp = "10.99.0.1";

  upScript = pkgs.writeShellScriptBin "surfshark-netns-up" ''
    set -euo pipefail

    ip="${pkgs.iproute2}/bin/ip"
    wg="${pkgs.wireguard-tools}/bin/wg"
    iptables="${pkgs.iptables}/bin/iptables"
    ip6tables="${pkgs.iptables}/bin/ip6tables"

    # Clean up any leftover state so the start is idempotent.
    $ip netns del ${netns} 2>/dev/null || true
    $ip link del ${vethRoot} 2>/dev/null || true
    $iptables -t nat -D POSTROUTING -s 10.99.0.0/30 ! -o ${vethRoot} -j MASQUERADE 2>/dev/null || true

    # Resolve the endpoint in the root namespace BEFORE creating the
    # namespace. Inside the namespace there's no route to any DNS server
    # until the WireGuard tunnel is up, so wg set cannot resolve there.
    endpoint="${cfg.vpn.endpoint}"
    host="''${endpoint%%:*}"
    port="''${endpoint##*:}"
    addr="$(${pkgs.glibc.getent}/bin/getent ahostsv4 "$host" | head -1 | awk '{print $1}')"
    if [ -z "$addr" ]; then
      echo "surfshark-netns: failed to resolve $host" >&2
      exit 1
    fi
    echo "surfshark-netns: resolved $host -> $addr"

    # DNS for processes run via `ip netns exec surfshark`.
    mkdir -p /etc/netns/${netns}
    : > /etc/netns/${netns}/resolv.conf
    ${lib.concatMapStringsSep "\n" (d: ''
      echo "nameserver ${d}" >> /etc/netns/${netns}/resolv.conf
    '') cfg.vpn.dns}

    # Create the namespace and a veth pair so the root namespace can reach
    # services bound inside it (e.g. the deluge web UI at ${nsIp}).
    $ip netns add ${netns}
    $ip link add ${vethRoot} type veth peer name ${vethNs}
    $ip link set ${vethNs} netns ${netns}

    $ip addr add ${rootIp}/30 dev ${vethRoot}
    $ip link set ${vethRoot} up

    # NAT traffic from the namespace going out to the internet. Without
    # this, WireGuard's UDP handshake packets have source 10.99.0.2 (the
    # veth address) which can't be routed back from the internet.
    $iptables -t nat -A POSTROUTING -s 10.99.0.0/30 ! -o ${vethRoot} -j MASQUERADE
    $ip6tables -t nat -A POSTROUTING -s 10.99.0.0/30 ! -o ${vethRoot} -j MASQUERADE 2>/dev/null || true

    $ip -n ${netns} addr add ${nsIp}/30 dev ${vethNs}
    $ip -n ${netns} link set ${vethNs} up
    $ip -n ${netns} link set lo up

    # WireGuard interface created inside the namespace. The endpoint is
    # pre-resolved to an IP so wg doesn't need DNS inside the namespace.
    $ip -n ${netns} link add wg0 type wireguard
    $ip -n ${netns} addr add ${cfg.vpn.address} dev wg0
    $ip netns exec ${netns} $wg set wg0 \
      private-key ${cfg.vpn.privateKeyFile} \
      peer "${cfg.vpn.publicKey}" \
      endpoint "$addr:$port" \
      allowed-ips 0.0.0.0/0
    $ip -n ${netns} link set wg0 up
    # Route to the WireGuard endpoint through the veth (not wg0), so
    # encrypted packets can actually reach the Surfshark server. Without
    # this the default route through wg0 creates a routing loop.
    $ip -n ${netns} route add "$addr" dev ${vethNs} via ${rootIp}
    $ip -n ${netns} route add default dev wg0

    echo "surfshark-netns: tunnel up. Test with: ip netns exec ${netns} ping -c1 1.1.1.1"
  '';

  downScript = pkgs.writeShellScriptBin "surfshark-netns-down" ''
    ${pkgs.iproute2}/bin/ip netns del ${netns} 2>/dev/null || true
    ${pkgs.iproute2}/bin/ip link del ${vethRoot} 2>/dev/null || true
    ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.99.0.0/30 ! -o ${vethRoot} -j MASQUERADE 2>/dev/null || true
    ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s 10.99.0.0/30 ! -o ${vethRoot} -j MASQUERADE 2>/dev/null || true
  '';
in
{
  config = lib.mkIf cfg.vpn.enable {
    # Enable IP forwarding so the root namespace can route packets from
    # the surfshark namespace (veth) out to the internet (eno1/etc).
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    environment.systemPackages = [
      pkgs.wireguard-tools
      pkgs.iproute2
    ];

    systemd.services.surfshark-netns = {
      description = "Surfshark WireGuard network namespace";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.iproute2
        pkgs.wireguard-tools
        pkgs.glibc.getent
        pkgs.coreutils
        pkgs.gawk
        pkgs.iptables
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${upScript}/bin/surfshark-netns-up";
        ExecStop = "${downScript}/bin/surfshark-netns-down";
      };
    };
  };
}
