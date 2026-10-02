{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.t3code;
in
{
  options.t3code = {
    package = lib.mkPackageOption pkgs "t3code" { };

    serve = {
      enable = lib.mkEnableOption "the T3 Code headless server (`t3 serve`) as a systemd service";

      user = lib.mkOption {
        type = lib.types.str;
        default = "george";
        description = ''
          User to run `t3 serve` as. T3 Code drives provider CLIs (claude,
          codex, opencode, ...) using this user's authentication and projects.
        '';
      };

      host = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "100.x.y.z";
        description = ''
          Host/interface for the server to bind (e.g. 127.0.0.1, 0.0.0.0, or a
          Tailnet IP). When null, the `t3 serve` default (loopback) is used.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3773;
        description = "Port for the T3 Code server.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open the firewall for the T3 Code server port.";
      };

      caddyVhost = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "t3code.dosa.geooot.com";
        description = ''
          Caddy virtual host that reverse-proxies to the T3 Code server (with
          Cloudflare DNS-01 TLS, like the homelab vhosts). Requires the
          homelab Caddy setup. When set, keep `host` on loopback.
        '';
      };
    };
  };

  config = lib.mkMerge [
    {
      environment.systemPackages = [ cfg.package ];
    }

    (lib.mkIf cfg.serve.enable {
      systemd.services.t3-serve = {
        description = "T3 Code headless server (t3 serve)";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = cfg.serve.user;
          Restart = "on-failure";
          RestartSec = "5";
        };
        script = ''
          exec ${lib.getExe' cfg.package "t3"} serve \
            --port ${toString cfg.serve.port} \
            ${lib.optionalString (cfg.serve.host != null) "--host ${lib.escapeShellArg cfg.serve.host}"}
        '';
      };

      networking.firewall.allowedTCPPorts = lib.optional cfg.serve.openFirewall cfg.serve.port;
    })

    (lib.mkIf (cfg.serve.enable && cfg.serve.caddyVhost != null) {
      services.caddy.virtualHosts.${cfg.serve.caddyVhost}.extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:${toString cfg.serve.port}
      '';
    })
  ];
}
