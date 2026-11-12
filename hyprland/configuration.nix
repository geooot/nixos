{
  config,
  pkgs,
  inputs,
  ...
}:
{
  # Hyprland from nixpkgs (0.57.x). The old setup used inputs.hyprland, but
  # that input is commented out in flake.nix, so use the nixpkgs package.
  # Note: 0.57 only supports the Lua config (~/.config/hypr/hyprland.lua),
  # installed by ./home.nix from ./hyprland.lua in this directory.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs.hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
  };

  # Used by the Quickshell menu panels (./quickshell).
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;

  # Chromium apps have a flicker when using nvidia drivers
  # This apparently fixes it
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
