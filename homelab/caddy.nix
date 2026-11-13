{
  config,
  lib,
  ...
}:

let
  cfg = config.homelab;

  # Each vhost gets its own cert from security.acme (DNS-01 via Cloudflare,
  # see below). useACMEHost makes the NixOS Caddy module emit
  # `tls /var/lib/acme/<name>/cert.pem .../key.pem`, order Caddy after the
  # acme-<name> services, and reload Caddy on renewal.
  mkVhost = name: target: {
    useACMEHost = name;
    extraConfig = ''
      reverse_proxy ${target}
    '';
  };

  # calibre-web reads the request scheme from X-Scheme (not X-Forwarded-Proto).
  # Without it, Kobo download URLs are generated as http:// and the ereader
  # fails the download silently on the http->https redirect.
  mkCalibreWebVhost = name: target: {
    useACMEHost = name;
    extraConfig = ''
      reverse_proxy ${target} {
        header_up X-Scheme {scheme}
      }
    '';
  };

  # Replacement for the caddy-cloudflare-ip plugin's dynamic range source:
  # Cloudflare's published edge ranges (https://www.cloudflare.com/ips).
  # Changes are rare; review when Cloudflare announces new ranges.
  cloudflareIpRanges = [
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];
in
{
  config = {
    # Certificates are issued by lego (DNS-01) instead of Caddy's built-in
    # ACME, so the stock pkgs.caddy suffices and no plugin vendor hash has
    # to be maintained. Certs for individual vhosts are created implicitly
    # by the Caddy module from useACMEHost; they inherit these defaults.
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = cfg.acmeEmail;
        dnsProvider = "cloudflare";
        credentialFiles = {
          "CLOUDFLARE_DNS_API_TOKEN_FILE" = cfg.cloudflareTokenFile;
        };
      };
    };

    services.caddy = {
      enable = true;

      globalConfig = ''
        servers {
          trusted_proxies static ${lib.concatStringsSep " " cloudflareIpRanges}
          trusted_proxies_strict
          client_ip_headers CF-Connecting-IP CF-Connecting-IPv6 X-Forwarded-For
        }
      '';

      virtualHosts = lib.mkMerge [
        (lib.mkIf cfg.services.jellyfin.enable {
          "jellyfin.${cfg.domain}" = mkVhost "jellyfin.${cfg.domain}" "127.0.0.1:8096";
        })
        (lib.mkIf cfg.services.sonarr.enable {
          "sonarr.${cfg.domain}" = mkVhost "sonarr.${cfg.domain}" "127.0.0.1:8989";
        })
        (lib.mkIf cfg.services.radarr.enable {
          "radarr.${cfg.domain}" = mkVhost "radarr.${cfg.domain}" "127.0.0.1:7876";
        })
        (lib.mkIf cfg.services.deluge.enable {
          "deluge.${cfg.domain}" = mkVhost "deluge.${cfg.domain}" (
            if cfg.vpn.bindDeluge then "10.99.0.2:8112" else "127.0.0.1:8112"
          );
        })
        (lib.mkIf cfg.services.prowlarr.enable {
          "prowlarr.${cfg.domain}" = mkVhost "prowlarr.${cfg.domain}" "127.0.0.1:9696";
        })
        (lib.mkIf cfg.services.readarr.enable {
          "readarr.${cfg.domain}" = mkVhost "readarr.${cfg.domain}" "127.0.0.1:8787";
        })
        (lib.mkIf cfg.services.flaresolverr.enable {
          "flaresolverr.${cfg.domain}" = mkVhost "flaresolverr.${cfg.domain}" "127.0.0.1:8191";
        })
        (lib.mkIf cfg.services.calibre.enable {
          "admin.calibre.${cfg.domain}" = {
            useACMEHost = "admin.calibre.${cfg.domain}";
            extraConfig = ''
              basic_auth /* {
                george ${cfg.calibreAdminHash}
              }
              reverse_proxy 127.0.0.1:8090
            '';
          };
          "calibre.${cfg.domain}" = mkCalibreWebVhost "calibre.${cfg.domain}" "127.0.0.1:8083";
          "calibre.${cfg.publicDomain}" = mkCalibreWebVhost "calibre.${cfg.publicDomain}" "127.0.0.1:8083";
        })
      ];
    };
  };
}
