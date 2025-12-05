{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.portal.enable = true;

  # Chromium apps have a flicker when using nvidia drivers
  # This apparently fixes it
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
