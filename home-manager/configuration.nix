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
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    backupFileExtension = "backup"; 
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      george = import ./home.nix;
    };
  };
}
