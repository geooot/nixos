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
    flags = [
      # Update all flake inputs (like `nix flake update`) before rebuilding
      "--recreate-lock-file"
      # Print build logs to the journal
      "-L"
    ];
    dates = "daily";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };
}
