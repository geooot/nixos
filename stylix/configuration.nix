{ inputs, outputs, config, system, lib, pkgs, ... }:
{
  stylix.image = /etc/nixos/background.png; 
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/primer-dark-dimmed.yaml";
  stylix.polarity = "dark";
  stylix.fonts.monospace = {
    package = inputs.fontpkgs.packages.x86_64-linux.berkeley-mono;
    name = "Berkeley Mono Variable";
  };
}
