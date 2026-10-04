{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.syncthing;

  # Folder paths may be absolute or relative to the user's home directory.
  absPath = p: if lib.hasPrefix "/" p then p else "${cfg.homeDir}/${p}";

  enabledFolders = lib.filterAttrs (_: folder: folder.enable) cfg.folders;

  # JSON folder list handed to the .stignore generator script.
  foldersJson = pkgs.writeText "syncthing-folders.json" (
    builtins.toJSON (
      lib.mapAttrsToList (_: folder: {
        path = absPath folder.path;
        inherit (folder) gitignore;
      }) enabledFolders
    )
  );
in
{
  options.syncthing = {
    enable = lib.mkEnableOption "Syncthing folder syncing";

    user = lib.mkOption {
      type = lib.types.str;
      default = "george";
      description = ''
        User to run Syncthing as. Synced folders live in this user's home
        directory.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = ''
        Group to run Syncthing under.
      '';
    };

    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}";
      defaultText = lib.literalExpression ''"/home/''${config.syncthing.user}"'';
      description = ''
        Home directory of the Syncthing user. Relative folder paths are
        resolved against this directory.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open the default Syncthing ports in the firewall (TCP/UDP 22000 for
        transfers, UDP 21027 for local discovery).
      '';
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        vada = "A1B2C3D-E4F5G6H-I7J8K9L-M0N1O2P-Q3R4S5T-U6V7W8X-Y9Z0A1B-2C3D4E5";
      };
      description = ''
        Remote devices to sync with, as name to device ID pairs. All folders
        are shared with all devices listed here. Find a machine's device ID in
        its Syncthing GUI (http://localhost:8384, Actions -> Show ID) after
        first boot.
      '';
    };

    folders = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Whether this machine syncs the folder. Useful to opt a single
                machine out of a shared folder definition.
              '';
            };

            path = lib.mkOption {
              type = lib.types.str;
              example = "github.com/geooot";
              description = ''
                Path of the folder to sync: absolute, or relative to homeDir.
              '';
            };

            type = lib.mkOption {
              type = lib.types.enum [
                "sendreceive"
                "sendonly"
                "receiveonly"
              ];
              default = "sendreceive";
              description = ''
                Controls whether this machine sends and/or receives changes
                for the folder.
              '';
            };

            gitignore = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Translate .gitignore files found inside this folder (at any
                depth) into the folder's generated .stignore, so git-ignored
                files are not synced.
              '';
            };
          };
        }
      );
      default = {
        github.path = "github.com/geooot";
        photos.path = "Photos";
        documents.path = "Documents";
      };
      description = ''
        Folders to sync. The attribute name is the Syncthing folder ID and
        must match on all devices. Every folder also gets the global ignore
        patterns from syncthing/global-ignore in this repo.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      inherit (cfg) user group;
      dataDir = cfg.homeDir;
      configDir = "${cfg.homeDir}/.config/syncthing";
      databaseDir = "${cfg.homeDir}/.local/share/syncthing";
      openDefaultPorts = cfg.openFirewall;
      settings = {
        devices = lib.mapAttrs (_: id: { inherit id; }) cfg.devices;
        folders = lib.mapAttrs (_: folder: {
          path = absPath folder.path;
          inherit (folder) type;
          devices = lib.attrNames cfg.devices;
          fsWatcherEnabled = true;
        }) enabledFolders;
        # Decline the anonymous usage report so the GUI doesn't prompt on first run.
        options.urAccepted = -1;
      };
    };

    # Generate .stignore files (global-ignore + translated .gitignore patterns)
    # before Syncthing starts, and periodically afterwards so edits to
    # .gitignore files or syncthing/global-ignore are picked up.
    systemd.services.syncthing-ignores = {
      description = "Generate .stignore files for Syncthing folders";
      wantedBy = [ "syncthing.service" ];
      before = [ "syncthing.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
      };
      script = ''
        ${lib.getExe pkgs.python3} ${./generate-stignore.py} ${./global-ignore} ${foldersJson}
      '';
    };

    systemd.timers.syncthing-ignores = {
      description = "Regenerate .stignore files for Syncthing folders";
      wantedBy = [ "timers.target" ];
      timerConfig.OnUnitActiveSec = "15min";
    };
  };
}
