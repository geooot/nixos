{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Real-time IMAP notifications using goimapnotify
  # Configure via accounts.email.accounts
  services.imapnotify.enable = true;

  # Install required packages
  home.packages = with pkgs; [
    goimapnotify
    libnotify # For desktop notifications
  ];
}
