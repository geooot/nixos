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
  config = lib.mkIf cfg.services.calibre.enable {
    services.calibre-server = {
      enable = true;
      group = cfg.mediaGroup;
      libraries = [ "${cfg.mediaDir}/books" ];
      host = "127.0.0.1";
      port = 8090;
    };

    services.calibre-web = {
      enable = true;
      group = cfg.mediaGroup;
      listen.ip = "127.0.0.1";
      listen.port = 8083;
      dataDir = "/var/lib/calibre-web";
      options = {
        calibreLibrary = "${cfg.mediaDir}/books";
        enableBookConversion = true;
        reverseProxyAuth = {
          enable = true;
          header = "X-Forwarded-For";
        };
      };
      package = pkgs.calibre-web.overridePythonAttrs (old: rec {
        dependencies = old.dependencies ++ old.optional-dependencies.kobo;
      });
    };

    # The stock SystemCallFilter hardening denies @resources syscalls
    # (setrlimit/prlimit64/nice), which kills calibre's page-render worker
    # during book conversion and hangs "Convert book" jobs at 1%.
    # Re-allow @resources; keep the rest of the filter list.
    systemd.services.calibre-web.serviceConfig.SystemCallFilter = lib.mkForce [
      "~@obsolete"
      "~@privileged"
      "~@raw-io"
      "~@mount"
      "~@debug"
      "~@cpu-emulation"
    ];
  };
}
