{ config, pkgs, ... }:

{
  services.xremap = {
    enable = true;
    withWlroots = true;
    serviceMode = "user";
    userName = "george"; # TODO: fix, seems bad
    config.modmap = [
      {
        name = "Global";
        remap = {
          "CapsLock" = "Esc";
	  "Alt_L" = "Ctrl_L";
	  "Ctrl_L" = "Alt_L";
        };
      }
    ];
  };
}
