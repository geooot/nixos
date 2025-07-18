{
  inputs,
  outputs,
  config,
  system,
  lib,
  pkgs,
  ...
}:
{
  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  stylix.polarity = "dark";
  stylix.fonts.monospace = {
    package = inputs.fontpkgs.packages.x86_64-linux.berkeley-mono;
    name = "Berkeley Mono Variable";
  };
}
