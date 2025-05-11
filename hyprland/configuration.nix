{ config, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-hyprland
  ];

  # Chromium apps have a flicker when using nvidia drivers
  # This apparently fixes it
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
