{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab;
  delugeCfg = config.services.deluge;
  configDir = "${delugeCfg.dataDir}/.config/deluge";
  netnsExec = "${pkgs.iproute2}/bin/ip netns exec surfshark";
in
{
  config = lib.mkIf cfg.services.deluge.enable {
    services.deluge = {
      enable = true;
      group = cfg.mediaGroup;
      web.enable = true;
      web.port = 8112;
    };

    systemd.services = lib.mkIf cfg.vpn.bindDeluge {
      deluged = {
        after = [
          "surfshark-netns.service"
          "network.target"
        ];
        requires = [ "surfshark-netns.service" ];
        serviceConfig.ExecStart = lib.mkForce (
          "${netnsExec} ${delugeCfg.package}/bin/deluged --do-not-daemonize --config ${configDir}"
        );
      };
      delugeweb = {
        after = [
          "surfshark-netns.service"
          "deluged.service"
        ];
        requires = [ "surfshark-netns.service" ];
        serviceConfig.ExecStart = lib.mkForce (
          "${netnsExec} ${delugeCfg.package}/bin/deluge-web --do-not-daemonize --config ${configDir} --port ${toString config.services.deluge.web.port}"
        );
      };
    };
  };
}
