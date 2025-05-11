{ config, pkgs, ... }:

{
  services.desktopManager.plasma6.enable = true;

  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;
  xdg.portal.extraPortals = [
    pkgs.kdePackages.xdg-desktop-portal-kde 
    pkgs.xdg-desktop-portal-gtk
  ];

  # Chromium apps have a flicker when using nvidia drivers
  # This apparently fixes it
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
