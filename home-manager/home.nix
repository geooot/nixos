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
    userName = "George Thayamkery";
    userEmail = "george.thayamkery@gmail.com";
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
        "clock"
      ];
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

      #tray {
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
    };
    oh-my-zsh = {
      enable = true;
      theme = "avit";
    };
  };

  programs.rofi = {
    enable = true;
  };

  programs.alacritty = {
    enable = true;
  };

  # services.hypridle = {
  #   enable = true;
  #   package = pkgs.hypridle;
  #
  #   settings = {
  #     general = {
  #       after_sleep_cmd = "hyprctl dispatch dpms on";
  #       lock_cmd = "pidof hyprlock || hyprlock";
  #     };
  #     listener = [
  #       {
  #         timeout = 900;
  #         on-timeout = "loginctl lock-session";
  #       }
  #       {
  #         timeout = 1200;
  #         on-timeout = "hyprctl dispatch dpms off";
  #         on-resume = "hyprctl dispatch dpms on";
  #       }
  #     ];
  #   };
  # };

  # programs.hyprlock = {
  #   enable = true;
  #   package = pkgs.hyprlock;
  #   settings = {
  #     general = {
  #       hide_cursor = false;
  #       no_fade_in = true;
  #       immediate_render = true;
  #     };
  #     render = {
  #       explicit_sync = 2;
  #       explicit_sync_kms = 0;
  #     };
  #     opengl = {
  #       nvidia_anti_flicker = 0;
  #       force_introspection = 2;
  #     };
  #     debug = {
  #       damage_tracking = 0;
  #     };
  #     background = [
  #       {
  #         monitor = "";
  #         color = "#000000";
  #       }
  #     ];
  #     input-field = [
  #       {
  #         monitor = "DP-3";
  #         size = "300, 50";
  #         outline_thickness = 1;
  #         placeholder_text = "<i>enter password</i>";
  #         fade_on_empty = false;
  #         font_family = "Berkeley Mono Variable";
  #         dots_spacing = 0.2;
  #         dots_center = true;
  #         position = "0, -200";
  #         halign = "center";
  #         dots_fade_time = "0";
  #         inner_color = "rgba(0,0,0,0)";
  #         check_color = "rgba(0,0,0,0)";
  #         font_color = "rgb(255,255,255)";
  #         rounding = "-1";
  #         valign = "center";
  #       }
  #     ];
  #     label = [
  #       {
  #         monitor = "DP-3";
  #         text = "cmd[update:1000] echo \"$(date +\"%-I:%M\")\"";
  #         color = "#FFFFFF";
  #         font_size = 95;
  #         font_family = "Berkeley Mono Variable";
  #         position = "0, 200";
  #         halign = "center";
  #         valign = "center";
  #       }
  #     ];
  #   };
  # };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [
        "DP-3,2560x1440,0x0,1"
        "DP-1,2560x1440,2560x0,1"
      ];
      exec-once = [
        ''${pkgs.wayvnc}/bin/wayvnc -g''
        ''${pkgs.waybar}/bin/waybar''
        ''${pkgs.swww}/bin/swww-daemon''
        ''${pkgs.dunst}/bin/dunst''
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];
      general = {
        gaps_in = 4;
        gaps_out = 4;
        resize_on_border = false;
        allow_tearing = true;
        layout = "dwindle";
      };
      input = {
        sensitivity = -0.5;
      };
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      input = {
        kb_layout = "us";
      };
      env = [
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        
        # nvidia crap
        "LIBVA_DRIVER_NAME,nvidia"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "NVD_BACKEND,direct"
      ];

      "$mod" = "Super";
      "$terminal" = ''${pkgs.alacritty}/bin/alacritty'';
      "$menu" = ''${pkgs.rofi-wayland}/bin/rofi -show run -show-icons'';
      "$fileManager" = ''${pkgs.kdePackages.dolphin }/bin/dolphin'';
      "$locker" = ''${pkgs.hyprlock}/bin/hyprlock'';

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      animation = [
        "global, 1, 1, default"
        "windows, 1, 1, default, popin 95%"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive"
        "$mod Ctrl, Q, exec, $locker"
        "$mod, E, exec, $fileManager"
        "$mod, V, togglefloating"
        "$mod, M, fullscreen, 1"
        "$mod, escape, exit"
        "$mod, space, exec, $menu"
        "$mod Alt, P, pseudo" # dwindle
        "$mod, J, togglesplit"

        # Move focus with mod and arrows
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Move workspace to monitor 
        "$mod Ctrl, left, movecurrentworkspacetomonitor, l"
        "$mod Ctrl, right, movecurrentworkspacetomonitor, r"

        # Switch workspaces relatively 
        "$mod Alt, left, workspace, r-1"
        "$mod Alt, right, workspace, r+1"

        # Move active window to workspace relatively 
        "$mod Shift, left, movetoworkspace, r-1"
        "$mod Shift, right, movetoworkspace, r+1"

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
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 0"
      ];
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
