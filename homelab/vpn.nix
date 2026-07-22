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

    # Clean up any leftover state so the start is idempotent.
    $ip netns del ${netns} 2>/dev/null || true
    $ip link del ${vethRoot} 2>/dev/null || true

    # Resolve the endpoint in the root namespace; the namespace has no DNS
    # until the tunnel is up, so wg cannot resolve it from inside.
    endpoint="${cfg.vpn.endpoint}"
    host="''${endpoint%%:*}"
    port="''${endpoint##*:}"
    addr="$(${lib.getBin pkgs.glibc}/bin/getent ahostsv4 "$host" | ${pkgs.coreutils}/bin/head -1 | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
    if [ -z "$addr" ]; then
      echo "surfshark-netns: failed to resolve $host" >&2
      exit 1
    fi

    # Create the namespace and a veth pair so the root namespace can reach
    # services bound inside it (e.g. the deluge web UI at ${nsIp}).
    $ip netns add ${netns}
    $ip link add ${vethRoot} type veth peer name ${vethNs}
    $ip link set ${vethNs} netns ${netns}

    $ip addr add ${rootIp}/30 dev ${vethRoot}
    $ip link set ${vethRoot} up

    $ip -n ${netns} addr add ${nsIp}/30 dev ${vethNs}
    $ip -n ${netns} link set ${vethNs} up
    $ip -n ${netns} link set lo up

    # WireGuard interface created directly inside the namespace.
    $ip -n ${netns} link add wg0 type wireguard
    $ip -n ${netns} addr add ${cfg.vpn.address} dev wg0
    $ip netns exec ${netns} $wg set wg0 \
      private-key ${cfg.vpn.privateKeyFile} \
      peer "${cfg.vpn.publicKey}" \
      endpoint "$addr:$port" \
      allowed-ips 0.0.0.0/0
    $ip -n ${netns} link set wg0 up
    $ip -n ${netns} route add default dev wg0

    # DNS for processes run via `ip netns exec surfshark`.
    mkdir -p /etc/netns/${netns}
    : > /etc/netns/${netns}/resolv.conf
    ${lib.concatMapStringsSep "\n" (d: ''
      echo "nameserver ${d}" >> /etc/netns/${netns}/resolv.conf
    '') cfg.vpn.dns}

    echo "surfshark-netns: tunnel up. Test with: ip netns exec ${netns} ping -c1 1.1.1.1"
  '';

  downScript = pkgs.writeShellScriptBin "surfshark-netns-down" ''
    ${pkgs.iproute2}/bin/ip netns del ${netns} 2>/dev/null || true
    ${pkgs.iproute2}/bin/ip link del ${vethRoot} 2>/dev/null || true
  '';
in
{
  config = lib.mkIf cfg.vpn.enable {
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
        pkgs.glibc
        pkgs.coreutils
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
