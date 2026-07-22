{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab;
in
{
  imports = [
    ./media-group.nix
    ./caddy.nix
    ./vpn.nix
    ./migrate.nix
    ./services/jellyfin.nix
    ./services/sonarr.nix
    ./services/radarr.nix
    ./services/deluge.nix
    ./services/prowlarr.nix
    ./services/readarr.nix
    ./services/flaresolverr.nix
    ./services/calibre.nix
  ];

  options.homelab = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "dosa.geooot.com";
      description = "Base domain for homelab virtual hosts.";
    };

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/dosa/media";
      description = "Directory containing media libraries (movies, tv, anime, books, downloads).";
    };

    mediaGroup = lib.mkOption {
      type = lib.types.str;
      default = "media";
      description = "Shared group for all homelab service users and media files.";
    };

    migrateSourceDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/dfw/config";
      description = "Source directory containing old docker configs to migrate via homelab-migrate.";
    };

    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "me@geooot.com";
      description = "Email for LetsEncrypt ACME account.";
    };

    cloudflareTokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/caddy-secrets/cloudflare-token";
      description = ''
        systemd EnvironmentFile containing a line
        `CLOUDFLARE_API_TOKEN=<token>` with Cloudflare API access
        (Zone:DNS:Edit on the base domain). Used by Caddy for DNS-01
        ACME challenges. Create this file before starting Caddy.
      '';
    };

    caddyPluginHash = lib.mkOption {
      type = lib.types.str;
      default = "sha256-hEHgAG0F0ozHRAPuxEqLyTATBrE+pajeXDiSNwniorg=";
      description = "Vendor hash for caddy built with the cloudflare DNS plugin.";
    };

    calibreAdminHash = lib.mkOption {
      type = lib.types.str;
      default = "$2y$05$gdP3W6zsO0Ld8zoCfaSGOONZBJdPaRQ6tCUluUXrZExjTGTOCdCeW";
      description = "bcrypt hash for the basic-auth protected calibre admin vhost.";
    };

    vpn = {
      enable = lib.mkEnableOption "Surfshark WireGuard tunnel in an isolated network namespace";

      bindDeluge = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Run deluge inside the surfshark network namespace so all torrent
          traffic is forced through the VPN (kill switch). When enabling this,
          update the deluge download client host in Sonarr/Radarr/Readarr from
          `localhost` to `10.99.0.2` (the veth address of the namespace).
          Requires homelab.vpn.enable.
        '';
      };

      privateKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/surfshark-secrets/private-key";
        description = "Path to a file containing the Surfshark WireGuard private key.";
      };

      endpoint = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Surfshark WireGuard endpoint (host:port).";
      };

      publicKey = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Surfshark WireGuard peer public key.";
      };

      address = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "WireGuard interface address assigned by Surfshark.";
      };

      dns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "DNS servers used inside the surfshark namespace.";
      };
    };

    services = {
      jellyfin.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Jellyfin.";
      };
      sonarr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Sonarr.";
      };
      radarr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Radarr.";
      };
      deluge.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Deluge.";
      };
      prowlarr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Prowlarr.";
      };
      readarr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Readarr.";
      };
      flaresolverr.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable FlareSolverr.";
      };
      calibre.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Calibre server and web.";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion =
          cfg.vpn.enable -> cfg.vpn.publicKey != "" && cfg.vpn.endpoint != "" && cfg.vpn.address != "";
        message = "homelab.vpn.{publicKey,endpoint,address} must be set when homelab.vpn.enable is true.";
      }
      {
        assertion = cfg.vpn.bindDeluge -> cfg.vpn.enable;
        message = "homelab.vpn.bindDeluge requires homelab.vpn.enable.";
      }
    ];
  };
}
