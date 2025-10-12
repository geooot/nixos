{ config, pkgs, ... }:

{
  services.desktopManager.plasma6.enable = true;
  # Chromium apps have a flicker when using nvidia drivers
  # This apparently fixes it
  # environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
