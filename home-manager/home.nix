# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  volumeUp = pkgs.writeShellScript "volume-up" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0
    ${pkgs.libnotify}/bin/notify-send -h int:value:$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | ${pkgs.gawk}/bin/awk '{print int($2 * 100)}') -t 500 -r 66 "Volume"
  '';

  volumeDown = pkgs.writeShellScript "volume-down" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
    ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- --limit 1.0
    ${pkgs.libnotify}/bin/notify-send -h int:value:$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | ${pkgs.gawk}/bin/awk '{print int($2 * 100)}') -t 500 -r 66 "Volume"
  '';

  volumeMute = pkgs.writeShellScript "volume-mute" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | ${pkgs.gnugrep}/bin/grep -q MUTED; then
      ${pkgs.libnotify}/bin/notify-send -t 500 -r 66 "Volume Muted"
    else
      ${pkgs.libnotify}/bin/notify-send -t 500 -r 66 "Volume Unmuted"
    fi
  '';

  micMute = pkgs.writeShellScript "mic-mute" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -q MUTED; then
      ${pkgs.libnotify}/bin/notify-send -t 500 -r 67 "Microphone Muted"
    else
      ${pkgs.libnotify}/bin/notify-send -t 500 -r 67 "Microphone Unmuted"
    fi
  '';

  brightnessUp = pkgs.writeShellScript "brightness-up" ''
    ${pkgs.brightnessctl}/bin/brightnessctl s 10%+
    ${pkgs.libnotify}/bin/notify-send -h int:value:$(${pkgs.brightnessctl}/bin/brightnessctl g -P) -t 500 -r 68 "Brightness"
  '';

  brightnessDown = pkgs.writeShellScript "brightness-down" ''
    ${pkgs.brightnessctl}/bin/brightnessctl s 10%-
    ${pkgs.libnotify}/bin/notify-send -h int:value:$(${pkgs.brightnessctl}/bin/brightnessctl g -P) -t 500 -r 68 "Brightness"
  '';
in
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttdrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "george";
    homeDirectory = "/home/george";
  };

  # Add stuff for your user as you see fit:
  # programs.neovim.enable = true;
  # home.packages = with pkgs; [ steam ];

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # qt = {
  #   enable = true;
  #   style.name = "Breeze";
  # };

  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "George Thayamkery";
      user.email = "george.thayamkery@gmail.com";
      core.editor = "vim";
    };
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    plugins = {
      inherit (pkgs.yaziPlugins) rich-preview;
      inherit (pkgs.yaziPlugins) yatline;
      inherit (pkgs.yaziPlugins) vcs-files;
      inherit (pkgs.yaziPlugins) mediainfo;
    };
    settings = {
      manager = {
        show_size = true;
      };
      preview = {
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
      };
      plugin = {
        prepend_previewers = [
          {
            mime = "image/*";
            run = "mediainfo";
          }
          {
            mime = "audio/*";
            run = "mediainfo";
          }
          {
            mime = "video/*";
            run = "mediainfo";
          }
        ];
      };
    };
  };

  stylix.targets.waybar.addCss = false;
  programs.waybar = {
    enable = true;
    style = ''
      * {
          font-size: 14px;
          font-family: "Berkeley Mono Variable";
      }

      window#waybar { 
          background-color: #000000; 
          color: #ffffff;
      }

      #workspaces {
          padding: 0;
      }

      #workspaces button {
      	padding: 0px 8px 0px 8px; 
       	min-width: 1px;
      	color: #888888;
          border-radius: 0;
      	background-color: #000000;
          border: 1px solid #323232;
      }


      .modules-left, .modules-right, .modules-center {
        background: #000;
        margin: 4px;
      }

      #tray, #battery {
        margin-right: 8px;
      }

      #workspaces button.active { 
      	color: @base0D;
      	background-color: #000000;
          border: 1px solid @base0D;
      }
    '';
  };

  xdg.configFile."waybar/config-hyprland".text = builtins.toJSON {
    layer = "top";
    position = "top";
    clock.format = "{:%I:%M %p}";
    tray.spacing = 8;
    modules-left = [
      "hyprland/workspaces"
    ];
    modules-center = [
      "hyprland/window"
    ];
    modules-right = [
      "tray"
      "battery"
      "clock"
    ];
    battery = {
      format = "{icon} {capacity}%";
      format-charging = "󱐋 {capacity}%";
      format-icons = [ "󰁹" ];
    };
  };

  xdg.configFile."waybar/config-niri".text = builtins.toJSON {
    layer = "top";
    position = "top";
    clock.format = "{:%I:%M %p}";
    tray.spacing = 8;
    modules-left = [
      "niri/workspaces"
    ];
    modules-center = [
      "niri/window"
    ];
    modules-right = [
      "tray"
      "battery"
      "clock"
    ];
    battery = {
      format = "{icon} {capacity}%";
      format-charging = "󱐋 {capacity}%";
      format-icons = [ "󰁹" ];
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    shellAliases = {
      vim = "nvim";
      wifi = ''${pkgs.networkmanager}/bin/nmtui'';
    };
    oh-my-zsh = {
      enable = true;
      theme = "avit";
    };
  };

  programs.rofi = {
    enable = true;
    plugins = with pkgs; [
      rofimoji
    ];
    terminal = "${pkgs.kitty}/bin/kitty";
    package = pkgs.rofi;
    extraConfig = {
      combi-modi = "window,drun";
      cycle = true;
      display-window = "Window";
      display-combi = ">";
      display-drun = "Launch";
      dpi = 144;
      disable-history = false;
      drun-display-format = "{icon} {name}";
      modi = "window,drun";
      show-icons = true;
      sidebar-mode = true;
      sort = true;
      ssh-client = "ssh";
    };
  };

  home.file.".local/share/applications/nmtui.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Wifi Configuration
    Comment=Manage network connections
    Exec=${pkgs.kitty}/bin/kitty --class floating-tui -e ${pkgs.networkmanager}/bin/nmtui
    Terminal=false
    Categories=Network;Settings;
    Icon=network-wired
  '';

  home.file.".local/share/applications/steam-gamescope.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Steam (gamescope)
    Comment=Run steam through gamescope
    Exec=${pkgs.gamescope}/bin/gamescope -e -w 1920 -h 1200 -- ${pkgs.steam}/bin/steam -gamepadui -720p -nointro
    Terminal=false
  '';

  home.file.".local/share/applications/bluetui.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bluetooth Configuration
    Comment=Manage bluetooth connections
    Exec=${pkgs.kitty}/bin/kitty --class floating-tui -e ${pkgs.bluetui}/bin/bluetui
    Terminal=false
    Categories=Network;Settings;
    Icon=bluetooth
  '';

  home.file.".local/share/applications/zsf-zulip.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=ZSF Zulip Chat
    Exec=${pkgs.google-chrome}/bin/google-chrome-stable --app="https://zsf.zulipchat.com"
    Terminal=false
  '';

  home.file.".local/share/applications/zig-zulip.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Zig Zulip Chat
    Exec=${pkgs.google-chrome}/bin/google-chrome-stable --app="https://zig-lang.zulipchat.com"
    Terminal=false
  '';

  home.file.".local/share/applications/t3-chat.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=T3 Chat
    Exec=${pkgs.google-chrome}/bin/google-chrome-stable --app="https://t3.chat"
    Terminal=false
  '';

  home.file.".local/share/applications/tldraw.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=tldraw
    Exec=${pkgs.google-chrome}/bin/google-chrome-stable --app="https://tldraw.com"
    Terminal=false
  '';

  home.file.".local/bin/volume-up".source = volumeUp;
  home.file.".local/bin/volume-down".source = volumeDown;
  home.file.".local/bin/volume-mute".source = volumeMute;
  home.file.".local/bin/mic-mute".source = micMute;
  home.file.".local/bin/brightness-up".source = brightnessUp;
  home.file.".local/bin/brightness-down".source = brightnessDown;

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }
        
        touchpad {
            tap
            natural-scroll
            click-method "clickfinger"
            scroll-factor 0.3
        }
        
        mouse {
        }
    }

    output "eDP-1" {
        scale 1.2
    }

    output "DP-3" {
        mode "2560x1440@143.912"
        position x=0 y=0
        scale 1.0
    }

    output "DP-1" {
        mode "2560x1440@143.912"
        position x=2560 y=0
        scale 1.0
    }

    layout {
        gaps 4
        
        preset-column-widths {
            proportion 0.33333
            proportion 0.5
            proportion 0.66667
        }

        default-column-width { proportion 0.5; }
        
        focus-ring {
            width 2
            active-color "#${config.lib.stylix.colors.base0D}"
            inactive-color "#${config.lib.stylix.colors.base03}"
        }
        
        border {
            off
        }
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    spawn-at-startup "${pkgs.waybar}/bin/waybar" "-c" "/home/george/.config/waybar/config-niri"
    spawn-at-startup "${pkgs.swww}/bin/swww-daemon"
    spawn-at-startup "${pkgs.dunst}/bin/dunst"
    spawn-at-startup "${pkgs.wayvnc}/bin/wayvnc" "-g"
    spawn-at-startup "${pkgs.hypridle}/bin/hypridle"
    spawn-at-startup "dbus-update-activation-environment" "--systemd" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP"

    environment {
        NIXOS_OZONE_WL "1"
        ELECTRON_OZONE_PLATFORM_HINT "auto"
    }

    cursor {
        xcursor-theme "Posy_Cursor_Black"
        xcursor-size 24
    }

    binds {
        Mod+Return { spawn "${pkgs.kitty}/bin/kitty"; }
        Mod+Q { close-window; }
        Mod+Shift+Q { spawn "${pkgs.hyprlock}/bin/hyprlock"; }
        Mod+Escape { spawn "${pkgs.hyprlock}/bin/hyprlock"; }
        Mod+E { spawn "${pkgs.kitty}/bin/kitty" "-e" "${pkgs.yazi}/bin/yazi"; }
        Mod+M { maximize-column; }
        Mod+Shift+M { toggle-window-floating; }
        Mod+Shift+6 { fullscreen-window; }
        Mod+Space { spawn "${config.programs.rofi.package}/bin/rofi" "-show" "combi" "-show-icons"; }
        Mod+Slash { show-hotkey-overlay; }
        Mod+J { consume-or-expel-window-left; }
        
        Mod+Left { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up { focus-window-up; }
        Mod+Down { focus-window-down; }
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+K { focus-window-up; }
        
        Mod+Ctrl+Left { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Up { move-window-up; }
        Mod+Ctrl+Down { move-window-down; }
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+L { move-column-right; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+J { move-window-down; }
        
        Mod+Shift+BracketLeft { move-column-left; }
        Mod+Shift+BracketRight { move-column-right; }
        
        Mod+Home { focus-column-first; }
        Mod+End { focus-column-last; }
        Mod+Ctrl+Home { move-column-to-first; }
        Mod+Ctrl+End { move-column-to-last; }
        
        Mod+Shift+Left { focus-monitor-left; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+Up { focus-monitor-up; }
        Mod+Shift+Down { focus-monitor-down; }
        Mod+Shift+H { focus-monitor-left; }
        Mod+Shift+L { focus-monitor-right; }
        Mod+Shift+K { focus-monitor-up; }
        Mod+Shift+J { focus-monitor-down; }
        
        Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+Up { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+Down { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+H { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+L { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+K { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+J { move-column-to-monitor-down; }
        
        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up { focus-workspace-up; }
        Mod+U { focus-workspace-down; }
        Mod+I { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
        Mod+Ctrl+U { move-column-to-workspace-down; }
        Mod+Ctrl+I { move-column-to-workspace-up; }
        
        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up { move-workspace-up; }
        Mod+Shift+U { move-workspace-down; }
        Mod+Shift+I { move-workspace-up; }
        
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+0 { focus-workspace 10; }
        
        Mod+Alt+1 { move-column-to-workspace 1; }
        Mod+Alt+2 { move-column-to-workspace 2; }
        Mod+Alt+3 { move-column-to-workspace 3; }
        Mod+Alt+4 { move-column-to-workspace 4; }
        Mod+Alt+5 { move-column-to-workspace 5; }
        Mod+Alt+6 { move-column-to-workspace 6; }
        Mod+Alt+7 { move-column-to-workspace 7; }
        Mod+Alt+8 { move-column-to-workspace 8; }
        Mod+Alt+9 { move-column-to-workspace 9; }
        Mod+Alt+0 { move-column-to-workspace 10; }
        
        Mod+Comma { consume-window-into-column; }
        Mod+Period { expel-window-from-column; }
        
        Mod+BracketLeft { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        
        Mod+Backslash { switch-preset-column-width; }
        Mod+C { center-column; }
        
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }
        
        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }
        
        XF86AudioRaiseVolume { spawn "${volumeUp}"; }
        XF86AudioLowerVolume { spawn "${volumeDown}"; }
        XF86AudioMute { spawn "${volumeMute}"; }
        XF86AudioMicMute { spawn "${micMute}"; }
        XF86MonBrightnessUp { spawn "${brightnessUp}"; }
        XF86MonBrightnessDown { spawn "${brightnessDown}"; }
        
        Mod+WheelScrollDown cooldown-ms=150 { focus-column-right; }
        Mod+WheelScrollUp cooldown-ms=150 { focus-column-left; }
        Mod+Shift+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
        Mod+Shift+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
        
        Mod+WheelScrollRight { focus-column-right; }
        Mod+WheelScrollLeft { focus-column-left; }
        Mod+Shift+WheelScrollRight { focus-workspace-down; }
        Mod+Shift+WheelScrollLeft { focus-workspace-up; }
    }

    window-rule {
        match app-id="floating-tui"
        default-column-width { fixed 800; }
    }

    animations {
        window-open {
            duration-ms 150
            curve "ease-out-quad"
        }
        
        window-close {
            duration-ms 150
            curve "ease-out-quad"
        }
        
        horizontal-view-movement {
            duration-ms 200
            curve "ease-out-cubic"
        }
        
        window-movement {
            duration-ms 200
            curve "ease-out-cubic"
        }
        
        workspace-switch {
            duration-ms 200
            curve "ease-out-cubic"
        }
        
        window-resize {
            duration-ms 150
            curve "ease-out-quad"
        }
    }
  '';

  home.file.".local/share/applications/powerprofile.desktop".text =
    let
      powerProfileScript = pkgs.writeShellScript "powerprofile-selector" ''
        current=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl list | ${pkgs.gnugrep}/bin/grep "^\*" | ${pkgs.gnused}/bin/sed "s/^\* //" | ${pkgs.gnused}/bin/sed "s/:$//")

        profile=$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl list | \
          ${pkgs.gnugrep}/bin/grep ":$" | \
          ${pkgs.gnused}/bin/sed "s/^[ *]*//" | \
          ${pkgs.gnused}/bin/sed "s/:$//" | \
          ${pkgs.gawk}/bin/awk -v curr="$current" '{if ($0 == curr) print "● " $0; else print "  " $0}' | \
          ${config.programs.rofi.package}/bin/rofi -dmenu -p "Power Profile" | \
          ${pkgs.gnused}/bin/sed "s/^[● ]*//" | \
          ${pkgs.coreutils}/bin/tr -d " ")

        [ -n "$profile" ] && ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set "$profile"
      '';
    in
    ''
      [Desktop Entry]
      Type=Application
      Name=Power Profile
      Comment=Manage power profiles
      Exec=${powerProfileScript}
      Terminal=false
      Categories=System;Settings;
      Icon=battery
    '';

  programs.kitty = {
    enable = true;
    keybindings = {
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
    };
  };

  services.hypridle = {
    enable = true;
    package = pkgs.hypridle;

    settings = {
      general = {
        after_sleep_cmd = "${pkgs.bash}/bin/bash -c 'if command -v hyprctl &> /dev/null; then hyprctl dispatch dpms on; elif command -v niri &> /dev/null; then niri msg action power-on-monitors; fi'";
        lock_cmd = "pidof hyprlock || hyprlock";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 630;
          on-timeout = "${pkgs.bash}/bin/bash -c 'if command -v hyprctl &> /dev/null; then hyprctl dispatch dpms off; elif command -v niri &> /dev/null; then niri msg action power-off-monitors; fi'";
          on-resume = "${pkgs.bash}/bin/bash -c 'if command -v hyprctl &> /dev/null; then hyprctl dispatch dpms on; elif command -v niri &> /dev/null; then niri msg action power-on-monitors; fi'";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    package = pkgs.hyprlock;

    settings = {
      image = {
        monitor = "";
        path = "/home/george/Pictures/Good Photos/IMG_0572.jpg";
        size = 950;
        rounding = 0;
        position = "0, 0";
        border_color = "rgb(${config.lib.stylix.colors.base05})";
        halign = "right";
        valign = "center";
        reload_time = 30;
        reload_cmd = ''find "/home/george/Pictures/Good Photos" -type f -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.JPG" -o -iname "*.png" | shuf -n 1'';
      };

      input-field = {
        monitor = "";
        size = "300, 50";
        outline_thickness = 2;
        dots_size = 0.2;
        dots_spacing = 0.3;
        dots_center = true;
        fade_on_empty = false;
        placeholder_text = "<span foreground='##${config.lib.stylix.colors.base04}'>Enter password...</span>";
        hide_input = false;
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        position = "-700, -85";
        halign = "center";
        valign = "center";
      };

      label = [
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<b>$(date +"%I:%M %p")</b>"'';
          color = "rgb(${config.lib.stylix.colors.base05})";
          font_size = 72;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-700, 120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
          color = "rgb(${config.lib.stylix.colors.base04})";
          font_size = 24;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-700, 50";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:5000] battery=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1); status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1); if [ "$status" = "Charging" ]; then echo "󱐋 $battery%"; else echo "󰁹 $battery%"; fi'';
          color = "rgb(${config.lib.stylix.colors.base05})";
          font_size = 18;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-20, -20";
          halign = "right";
          valign = "top";
        }
      ];
    };
  };

  home.pointerCursor = {
    package = pkgs.posy-cursors;
    name = "Posy_Cursor_Black";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    plugins = [
      inputs.hyprgrass.packages.${pkgs.system}.default

      # optional integration with pulse-audio, see examples/hyprgrass-pulse/README.md
      inputs.hyprgrass.packages.${pkgs.system}.hyprgrass-pulse
    ];
    settings = {
      monitor = [
        "DP-3,2560x1440,0x0,1"
        "DP-1,2560x1440,2560x0,1"
        ",preferred,auto,1.2"
      ];
      exec-once = [
        ''${pkgs.wayvnc}/bin/wayvnc -g''
        ''${pkgs.waybar}/bin/waybar -c ~/.config/waybar/config-hyprland''
        ''${pkgs.swww}/bin/swww-daemon''
        ''${pkgs.dunst}/bin/dunst''
        ''${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden -L 300''
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "hyprctl setcursor Posy_Cursor_Black 24"
      ];
      xwayland = {
        force_zero_scaling = true;
      };
      general = {
        gaps_in = 4;
        gaps_out = 4;
        resize_on_border = false;
        allow_tearing = true;
        layout = "dwindle";
      };
      input = {
        sensitivity = 0;
        touchpad = {
          disable_while_typing = false;
          natural_scroll = true;
          scroll_factor = 0.3;
          clickfinger_behavior = 1;
        };
      };
      gestures = {
        workspace_swipe_cancel_ratio = 0.15;
      };
      device = {
        name = "pixa38454:00-093a:0239-touchpad";
        sensitivity = 0;
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      input = {
        kb_layout = "us";
      };
      bindle = [
        ", XF86AudioRaiseVolume, exec, ${volumeUp}"
        ", XF86AudioLowerVolume, exec, ${volumeDown}"
        ", XF86MonBrightnessUp, exec, ${brightnessUp}"
        ", XF86MonBrightnessDown, exec, ${brightnessDown}"
      ];
      env = [
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"

        # nvidia crap
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "NVD_BACKEND,direct"
      ];
      gesture = [
        "3, horizontal, scale:0.9, workspace"
      ];
      plugin = {
        touch_gestures = {
          # The default sensitivity is probably too low on tablet screens,
          # I recommend turning it up to 4.0
          sensitivity = 4.0;

          # must be >= 3
          workspace_swipe_fingers = 3;

          # switching workspaces by swiping from an edge, this is separate from workspace_swipe_fingers
          # and can be used at the same time
          # possible values: l, r, u, or d
          # to disable it set it to anything else
          workspace_swipe_edge = "d";

          # in milliseconds
          long_press_delay = 400;

          # resize windows by long-pressing on window borders and gaps.
          # If general:resize_on_border is enabled, general:extend_border_grab_area is used for floating
          # windows
          resize_on_border_long_press = true;

          # in pixels, the distance from the edge that is considered an edge
          edge_margin = 20;

          # emulates touchpad swipes when swiping in a direction that does not trigger workspace swipe.
          # ONLY triggers when finger count is equal to workspace_swipe_fingers
          #
          # might be removed in the future in favor of event hooks
          emulate_touchpad_swipe = false;

          hyprgrass-bind = [
            ",edge:d:u,exec,kill -34 $(ps -C wvkbd-mobintl -o pid | grep -v PID)"
          ];

          experimental = {
            # send proper cancel events to windows instead of hacky touch_up events,
            # NOT recommended as it crashed a few times, once it's stabilized I'll make it the default
            send_cancel = 0;
          };
        };
      };

      "$mod" = "Super";
      "$mod_alt" = "Shift";
      "$terminal" = ''${pkgs.kitty}/bin/kitty'';
      "$menu" = ''${config.programs.rofi.package}/bin/rofi -show combi -show-icons'';
      "$fileManager" = ''${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi'';
      "$locker" = ''${pkgs.hyprlock}/bin/hyprlock'';

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        vfr = true;
      };

      windowrulev2 = [
        "float, class:^(floating-tui)$"
        "size 800 600, class:^(floating-tui)$"
        "center, class:^(floating-tui)$"
      ];

      animation = [
        "global, 1, 1, default"
        "windows, 1, 1, default, popin 95%"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod $mod_alt, mouse:272, resizewindow"
      ];

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive"
        "$mod $mod_alt, Q, exec, $locker"
        "$mod, escape, exec, $locker"
        "$mod, E, exec, $fileManager"
        "$mod $mod_alt, M, togglefloating"
        "$mod, M, fullscreen, 1"
        "$mod, space, exec, $menu"
        "$mod $mod_alt, P, pseudo" # dwindle
        "$mod, J, togglesplit"

        # Media keys
        ", XF86AudioMute, exec, ${volumeMute}"
        ", XF86AudioMicMute, exec, ${micMute}"

        # Move focus with mod and arrows
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Move workspace to monitor
        "$mod $mod_alt, left, movecurrentworkspacetomonitor, l"
        "$mod $mod_alt, right, movecurrentworkspacetomonitor, r"

        # Switch workspaces relatively
        "$mod $mod_alt, left, workspace, r-1"
        "$mod $mod_alt, right, workspace, r+1"

        # Move active window to workspace relatively
        "$mod Alt, left, movetoworkspace, r-1"
        "$mod Alt, right, movetoworkspace, r+1"

        # Switch workspaces with mod and numbers
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 0"

        # Move active window to a workspace
        "$mod Alt, 1, movetoworkspace, 1"
        "$mod Alt, 2, movetoworkspace, 2"
        "$mod Alt, 3, movetoworkspace, 3"
        "$mod Alt, 4, movetoworkspace, 4"
        "$mod Alt, 5, movetoworkspace, 5"
        "$mod Alt, 6, movetoworkspace, 6"
        "$mod Alt, 7, movetoworkspace, 7"
        "$mod Alt, 8, movetoworkspace, 8"
        "$mod Alt, 9, movetoworkspace, 9"
        "$mod Alt, 0, movetoworkspace, 0"
      ];
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
