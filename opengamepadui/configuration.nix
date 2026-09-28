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
        "-w 1920"
        "-h 1080"
        "-W 1920"
        "-H 1080"
        "-f"
      ];
    };
  };
}
