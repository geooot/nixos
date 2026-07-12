{
  config,
  lib,
  pkgs,
  ...
}:

{
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos";
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };
}
