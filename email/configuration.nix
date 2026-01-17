{
  inputs,
  outputs,
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./pass.nix
    ./mbsync.nix
    ./aerc.nix
    ./goimapnotify.nix
  ];

  # Ensure maildir base directory exists
  home.file.".maildir/.keep".text = "";
}
