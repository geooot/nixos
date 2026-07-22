{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.homelab;

  migrateScript = pkgs.writeShellApplication {
    name = "homelab-migrate";
    runtimeInputs = [
      pkgs.rsync
      pkgs.sqlite
      pkgs.gnused
      pkgs.findutils
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail
      src="${cfg.migrateSourceDir}"
      media="${cfg.mediaDir}"
      group="${cfg.mediaGroup}"
      force=0

      for arg in "$@"; do
        case "$arg" in
          --force) force=1 ;;
          *) echo "homelab-migrate: unknown argument: $arg" >&2; exit 1 ;;
        esac
      done

      copy_config() {
        local s="$1" d="$2"
        if [ "$force" -eq 1 ] && [ -d "$d" ]; then
          echo "homelab-migrate: --force, wiping $d"
          rm -rf "$d"
        fi
        if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
          echo "homelab-migrate: $d already populated, skipping (use --force to overwrite)"
          return 0
        fi
        mkdir -p "$d"
        rsync -a "$s/" "$d/"
        echo "homelab-migrate: copied $s -> $d"
      }

      # --- Media ownership (one-time; skipped once the top dir is correct) ---
      if [ "$(stat -c '%U:%G' "$media" 2>/dev/null)" != "george:$group" ]; then
        echo "homelab-migrate: chown -R george:$group $media (may take a moment)..."
        chown -R george:"$group" "$media" 2>/dev/null || true
        chmod -R g+w "$media" 2>/dev/null || true
      fi

      # --- Sonarr ---
      if [ -d "$src/sonarr" ]; then
        copy_config "$src/sonarr" /var/lib/sonarr
        if [ -f /var/lib/sonarr/sonarr.db ]; then
          sqlite3 /var/lib/sonarr/sonarr.db \
            "UPDATE RootFolders SET Path = REPLACE(Path, '/data/', '$media/');" 2>/dev/null || true
          sqlite3 /var/lib/sonarr/sonarr.db \
            "UPDATE DownloadClients SET Settings = REPLACE(Settings, 'surfshark', 'localhost');" 2>/dev/null || true
        fi
        chown -R sonarr:"$group" /var/lib/sonarr
        chmod -R g+w /var/lib/sonarr
      fi

      # --- Radarr ---
      if [ -d "$src/radarr" ]; then
        copy_config "$src/radarr" /var/lib/radarr
        if [ -f /var/lib/radarr/radarr.db ]; then
          sqlite3 /var/lib/radarr/radarr.db \
            "UPDATE RootFolders SET Path = REPLACE(Path, '/data/', '$media/');" 2>/dev/null || true
          sqlite3 /var/lib/radarr/radarr.db \
            "UPDATE DownloadClients SET Settings = REPLACE(Settings, 'surfshark', 'localhost');" 2>/dev/null || true
        fi
        chown -R radarr:"$group" /var/lib/radarr
        chmod -R g+w /var/lib/radarr
      fi

      # --- Readarr ---
      if [ -d "$src/readarr" ]; then
        copy_config "$src/readarr" /var/lib/readarr
        if [ -f /var/lib/readarr/readarr.db ]; then
          sqlite3 /var/lib/readarr/readarr.db \
            "UPDATE RootFolders SET Path = REPLACE(Path, '/media/', '$media/');" 2>/dev/null || true
          sqlite3 /var/lib/readarr/readarr.db \
            "UPDATE DownloadClients SET Settings = REPLACE(Settings, 'surfshark', 'localhost');" 2>/dev/null || true
        fi
        chown -R readarr:"$group" /var/lib/readarr
        chmod -R g+w /var/lib/readarr
      fi

      # --- Prowlarr ---
      if [ -d "$src/prowlarr" ]; then
        copy_config "$src/prowlarr" /var/lib/prowlarr
        chown -R prowlarr:"$group" /var/lib/prowlarr
        chmod -R g+w /var/lib/prowlarr
      fi

      # --- Deluge ---
      if [ -d "$src/deluge" ]; then
        mkdir -p /var/lib/deluge/.config/deluge
        copy_config "$src/deluge" /var/lib/deluge/.config/deluge
        if [ -f /var/lib/deluge/.config/deluge/core.conf ]; then
          sed -i \
            -e "s|\"/downloads\"|\"$media/downloads\"|g" \
            -e "s|\"/config/plugins\"|\"/var/lib/deluge/.config/deluge/plugins\"|g" \
            -e "s|\"/config/torrents\"|\"/var/lib/deluge/.config/deluge/torrents\"|g" \
            /var/lib/deluge/.config/deluge/core.conf
        fi
        chown -R deluge:"$group" /var/lib/deluge
        chmod -R g+w /var/lib/deluge
      fi

      # --- Jellyfin ---
      if [ -d "$src/jellyfin" ]; then
        copy_config "$src/jellyfin" /var/lib/jellyfin
        find /var/lib/jellyfin/root -name '*.mblink' -exec sed -i "s|/media/|$media/|g" {} \; 2>/dev/null || true
        if [ -f /var/lib/jellyfin/config/system.xml ]; then
          sed -i \
            -e "s|<CachePath>/cache</CachePath>|<CachePath>/var/cache/jellyfin</CachePath>|g" \
            -e "s|<MetadataPath>/config/metadata</MetadataPath>|<MetadataPath>/var/lib/jellyfin/metadata</MetadataPath>|g" \
            /var/lib/jellyfin/config/system.xml
        fi
        if [ -f /var/lib/jellyfin/config/encoding.xml ]; then
          sed -i \
            -e "s|<TranscodingTempPath>/config/transcodes</TranscodingTempPath>|<TranscodingTempPath>/var/cache/jellyfin/transcodes</TranscodingTempPath>|g" \
            -e "s|<EncoderAppPathDisplay>[^<]*</EncoderAppPathDisplay>|<EncoderAppPathDisplay />|g" \
            /var/lib/jellyfin/config/encoding.xml
        fi
        if [ -f /var/lib/jellyfin/config/network.xml ]; then
          if ! grep -q '127.0.0.1' /var/lib/jellyfin/config/network.xml; then
            sed -i 's|<KnownProxies />|<KnownProxies><string>127.0.0.1</string></KnownProxies>|g' \
              /var/lib/jellyfin/config/network.xml
          fi
        fi
        chown -R jellyfin:"$group" /var/lib/jellyfin
        chmod -R g+w /var/lib/jellyfin
      fi

      # --- Calibre-web (app.db preserves the old login) ---
      if [ -d "$src/calibre-web" ]; then
        copy_config "$src/calibre-web" /var/lib/calibre-web
        chown -R calibre-web:"$group" /var/lib/calibre-web
        chmod -R g+w /var/lib/calibre-web
      fi

      echo "homelab-migrate: done."
      echo "  Start services with:"
      echo "    systemctl start caddy jellyfin sonarr radarr deluge prowlarr readarr flaresolverr calibre-server calibre-web"
    '';
  };
in
{
  config = {
    environment.systemPackages = [ migrateScript ];
  };
}
