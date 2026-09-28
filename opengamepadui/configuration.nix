{
  config,
  pkgs,
  ...
}:

{
  services.displayManager.defaultSession = "opengamepadui";

  # Steam is still needed to launch games.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  # Use OpenGamepadUI as the session instead of Steam.
  programs.opengamepadui = {
    enable = true;
    inputplumber.enable = true;
    powerstation.enable = true;
    gamescopeSession = {
      enable = true;
      args = [
        "--prefer-output"
        "*,eDP-1"
        "--xwayland-count"
        "2"
        "--default-touch-mode"
        "4"
        "--hide-cursor-delay"
        "3000"
        "--fade-out-duration"
        "200"
        "--steam"
        "-w"
        "1920"
        "-h"
        "1080"
      ];
    };
  };
}
