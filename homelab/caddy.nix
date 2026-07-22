{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab;

  mkVhost = target: {
    extraConfig = ''
      tls {
        dns cloudflare {$CLOUDFLARE_API_TOKEN}
      }
      reverse_proxy ${target}
    '';
  };
in
{
  config = {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = cfg.caddyPluginHash;
      };
      email = cfg.acmeEmail;
      environmentFile = cfg.cloudflareTokenFile;

      virtualHosts = lib.mkMerge [
        (lib.mkIf cfg.services.jellyfin.enable {
          "jellyfin.${cfg.domain}" = mkVhost "127.0.0.1:8096";
        })
        (lib.mkIf cfg.services.sonarr.enable {
          "sonarr.${cfg.domain}" = mkVhost "127.0.0.1:8989";
        })
        (lib.mkIf cfg.services.radarr.enable {
          "radarr.${cfg.domain}" = mkVhost "127.0.0.1:7876";
        })
        (lib.mkIf cfg.services.deluge.enable {
          "deluge.${cfg.domain}" = mkVhost (
            if cfg.vpn.bindDeluge then "10.99.0.2:8112" else "127.0.0.1:8112"
          );
        })
        (lib.mkIf cfg.services.prowlarr.enable {
          "prowlarr.${cfg.domain}" = mkVhost "127.0.0.1:9696";
        })
        (lib.mkIf cfg.services.readarr.enable {
          "readarr.${cfg.domain}" = mkVhost "127.0.0.1:8787";
        })
        (lib.mkIf cfg.services.flaresolverr.enable {
          "flaresolverr.${cfg.domain}" = mkVhost "127.0.0.1:8191";
        })
        (lib.mkIf cfg.services.calibre.enable {
          "admin.calibre.${cfg.domain}" = {
            extraConfig = ''
              tls {
                dns cloudflare {$CLOUDFLARE_API_TOKEN}
              }
              basic_auth /* {
                george ${cfg.calibreAdminHash}
              }
              reverse_proxy 127.0.0.1:8090
            '';
          };
          "calibre.${cfg.domain}" = mkVhost "127.0.0.1:8083";
        })
      ];
    };
  };
}
