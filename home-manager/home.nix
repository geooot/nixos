# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
  ${pkgs.waybar}/bin/waybar &
  ${pkgs.swww}/bin/swww-daemon &
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" &
  ${pkgs.dunst}/bin/dunst
''; in {
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
      #   hi = final.hello.overrideAttrs (oldAttrs: {
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

  gtk.enable = true;

  qt = {
    enable = true;
    style.name = "Breeze";
  };


  programs.git = {
    enable = true;
    userName = "George Thayamkery";
    userEmail = "george.thayamkery@gmail.com";
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

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = [
        "DP-3,2560x1440,0x0,1"
        "DP-1,2560x1440,2560x0,1"
      ];
      exec-once = ''${startupScript}/bin/start'';
      general = {
        gaps_in = 5;
	gaps_out = 5;

	resize_on_border = false;
	allow_tearing = false;
	layout = "dwindle";
      };
      dwindle = {
        pseudotile = true;
	preserve_split = true;
      };
      input = {
      	kb_layout = "us";
      };

      "$mod" = "SUPER";
      "$terminal" = ''${pkgs.alacritty}/bin/alacritty'';
      "$menu" = ''${pkgs.rofi-wayland}/bin/rofi -show run -show-icons'';
      "$fileManager" = ''${pkgs.xfce.thunar}/bin/thunar'';

      misc = {
        disable_hyprland_logo = true;
	disable_splash_rendering = true;
      };

      bind = [
        "$mod, Return, exec, $terminal"
	"$mod, C, killactive"
	"$mod, E, exec, $fileManager"
	"$mod, V, togglefloating"
	"$mod, R, exec, $menu"
	"$mod, P, pseudo" # dwindle
	"$mod, J, togglesplit"
        
	# Move focus with mod and arrows
	"$mod, left, movefocus, l"
	"$mod, right, movefocus, r"
	"$mod, up, movefocus, u"
	"$mod, down, movefocus, d"

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
