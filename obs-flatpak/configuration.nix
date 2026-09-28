{
  config,
  lib,
  pkgs,
  ...
}:
let
  flatpak = config.services.flatpak.package;
in
{
  services.flatpak.enable = true;

  systemd.services.flatpak-obs = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      ${flatpak}/bin/flatpak install -y --noninteractive --system flathub com.obsproject.Studio
    '';
  };
}
