{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab.ddns;
in
{
  options.homelab.ddns = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Cloudflare dynamic DNS for public homelab hosts.";
    };

    apiTokenFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/caddy-secrets/cloudflare-token-raw";
      description = "Path to a file containing only the raw Cloudflare API token.";
    };

    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "calibre.geooot.com" ];
      description = "Public DNS records to keep updated with the current public IP.";
    };

    proxied = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether records are proxied through Cloudflare.";
    };

    ipv4 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep A records updated.";
    };

    ipv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Keep AAAA records updated.";
    };

    frequency = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "*:0/5";
      description = "How often to check and update the records (see systemd.time(7) format).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = cfg.apiTokenFile;
      domains = cfg.domains;
      proxied = cfg.proxied;
      ipv4 = cfg.ipv4;
      ipv6 = cfg.ipv6;
      frequency = cfg.frequency;
    };
  };
}
