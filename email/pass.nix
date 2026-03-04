{
  config,
  lib,
  pkgs,
  ...
}:

{
  # GPG setup for password encryption
  programs.gpg = {
    enable = true;
    settings = {
      # Use GPG agent for key management
      use-agent = true;
    };
  };

  # GPG agent for caching passphrases
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    # Cache passphrase for 8 hours
    defaultCacheTtl = 31560000;
    maxCacheTtl = 31560000;
    pinentry.package = pkgs.pinentry-curses;
  };

  # Password store (pass) for secure password management
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
    };
  };

  # Install packages needed for pass
  home.packages = with pkgs; [
    gnupg
    pinentry-curses
  ];
}
