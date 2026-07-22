{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;
  delugeCfg = config.services.deluge;
  configDir = "${delugeCfg.dataDir}/.config/deluge";
in
{
  config = lib.mkIf cfg.services.deluge.enable {
    services.deluge = {
      enable = true;
      group = cfg.mediaGroup;
      web.enable = true;
      web.port = 8112;
    };

    # When VPN binding is enabled, use systemd's NetworkNamespacePath to
    # place deluge in the surfshark namespace. This is the systemd-native
    # approach — no `ip netns exec` wrapper, no CAP_SYS_ADMIN needed.
    systemd.services = lib.mkIf cfg.vpn.bindDeluge {
      deluged = {
        after = [
          "surfshark-netns.service"
          "network.target"
        ];
        requires = [ "surfshark-netns.service" ];
        serviceConfig.NetworkNamespacePath = "/var/run/netns/surfshark";
      };
      delugeweb = {
        after = [
          "surfshark-netns.service"
          "deluged.service"
        ];
        requires = [ "surfshark-netns.service" ];
        serviceConfig.NetworkNamespacePath = "/var/run/netns/surfshark";
      };
    };
  };
}
