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
          "Alt_L" = "Super_L";
          "Super_L" = "Alt_L";
        };
      }
    ];
    config.keymap = [
      {
	name = "Copy Paste";
	remap = { 
	  "Super-c" = "C-KEY_INSERT";
	  "Super-v" = "Shift-KEY_INSERT";
	  "Super-a" = "C-a";
	  "Super-z" = "C-z";
	  "Super-b" = "C-b";
	  "Super-d" = "C-d";
	  "Super-u" = "C-u";
	  "Super-i" = "C-i";
	  "Super-s" = "C-s";
	  "Super-r" = "C-r";
        };
      }
      {
	name = "Tab management";
	remap = { 
	  "Super-w" = "C-w";
	  "Super-t" = "C-t";
	  "Super-n" = "C-n";
	  "Super-f" = "C-f";
        };
      }
    ];
  };
}

