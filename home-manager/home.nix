# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
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

  stylix.targets.waybar.addCss = false;
  programs.waybar = {
    enable = true;
    settings.main = {
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
        format = "{capacity}%";
      };
    };
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

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    shellAliases = {
      vim = "nvim";
      wifi = "nmtui";
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
    terminal = "${pkgs.alacritty}/bin/alacritty";
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
    Exec=${pkgs.alacritty}/bin/alacritty --class floating-tui -e ${pkgs.networkmanager}/bin/nmtui
    Terminal=false
    Categories=Network;Settings;
    Icon=network-wired
  '';

  home.file.".local/share/applications/bluetui.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bluetooth Configuration
    Comment=Manage bluetooth connections
    Exec=${pkgs.alacritty}/bin/alacritty --class floating-tui -e ${pkgs.bluetui}/bin/bluetui
    Terminal=false
    Categories=Network;Settings;
    Icon=bluetooth
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

  programs.alacritty = {
    enable = true;
  };

  services.hypridle = {
    enable = true;
    package = pkgs.hypridle;

    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        lock_cmd = "pidof hyprlock || hyprlock";
      };
      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 630;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
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
        size = 850;
        rounding = 0;
        position = "0, 0";
        halign = "right";
        valign = "center";
        reload_time = 30;
        reload_cmd = ''find "/home/george/Pictures/Good Photos" -type f -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" | shuf -n 1'';
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
        position = "-600, -120";
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
          position = "-600, 200";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
          color = "rgb(${config.lib.stylix.colors.base04})";
          font_size = 24;
          font_family = config.stylix.fonts.sansSerif.name;
          position = "-600, 120";
          halign = "center";
          valign = "center";
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
        ''${pkgs.waybar}/bin/waybar''
        ''${pkgs.swww}/bin/swww-daemon''
        ''${pkgs.dunst}/bin/dunst''
	''${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden -L 300''
        ''${pkgs.hypridle}/bin/hypridle''
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
        '', XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && ${pkgs.libnotify}/bin/notify-send -h int:value:$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}') -t 500 -r 66 "Volume"''
        '', XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && ${pkgs.libnotify}/bin/notify-send -h int:value:$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}') -t 500 -r 66 "Volume"''
        '', XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%+''
        '', XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%-''
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
      "$terminal" = ''${pkgs.alacritty}/bin/alacritty'';
      "$menu" = ''${config.programs.rofi.package}/bin/rofi -show combi -show-icons'';
      "$fileManager" = ''${pkgs.kdePackages.dolphin}/bin/dolphin'';
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
