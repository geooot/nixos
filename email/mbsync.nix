{
  config,
  lib,
  pkgs,
  ...
}:

{
  # mbsync (isync) for syncing IMAP email
  programs.mbsync = {
    enable = true;
    package = pkgs.isync;
  };

  # msmtp for sending emails
  programs.msmtp.enable = true;

  # Account configuration
  accounts.email.accounts.gmail = {
    primary = true;
    address = "george.thayamkery@gmail.com"; # TODO: Replace with your actual Gmail address
    userName = "george.thayamkery@gmail.com"; # TODO: Replace with your actual Gmail address
    realName = "George Thayamkery"; # TODO: Replace with your actual name

    # IMAP settings for Gmail
    imap = {
      host = "imap.gmail.com";
      port = 993;
      tls.enable = true;
    };

    # SMTP settings for sending (used by msmtp)
    smtp = {
      host = "smtp.gmail.com";
      port = 587;
      tls = {
        enable = true;
        useStartTls = true;
      };
    };

    # Password management via pass
    passwordCommand = "${pkgs.pass}/bin/pass email/gmail";

    # Local maildir location
    maildir.path = "gmail";

    # Enable mbsync for this account
    mbsync = {
      enable = true;
      create = "both"; # Create missing mailboxes on both local and remote
      expunge = "both"; # Delete messages on both sides when moved to trash
      remove = "both"; # Remove deleted messages on both sides

      patterns = [
        "INBOX"
        "[Gmail]/Sent Mail"
        "[Gmail]/Drafts"
        "[Gmail]/Trash"
        "Newsletters"
      ];

      # Subfolders configuration
      subFolders = "Verbatim";
    };

    # Enable msmtp for sending emails
    msmtp.enable = true;

    # Aerc support
    aerc.enable = true;

    # IMAP notifications with goimapnotify
    imapnotify = {
      enable = true;
      boxes = [
        "INBOX"
        "[Gmail]/Sent Mail"
        "[Gmail]/Drafts"
        "Newsletters"
      ];
      # Sync all folders bidirectionally when new mail arrives
      onNotify = "${pkgs.isync}/bin/mbsync -a";
      onNotifyPost = "${pkgs.libnotify}/bin/notify-send 'New mail arrived'";
    };
  };

  # Install isync and msmtp packages
  home.packages = with pkgs; [
    isync
    msmtp
  ];

  # Configure msmtpq to skip connectivity tests
  # Since we're typically always online, skip the ping test
  home.sessionVariables = {
    EMAIL_CONN_NOTEST = "true";
  };

  # Periodic mbsync timer to sync local changes back to Gmail
  # goimapnotify only handles Gmail -> Local, this handles Local -> Gmail
  systemd.user.services.mbsync = {
    Unit = {
      Description = "Sync local maildir changes to Gmail";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.isync}/bin/mbsync -a";
      # If password is locked, fail quickly and try again on next run
      TimeoutStartSec = "60s";
    };
  };

  systemd.user.timers.mbsync = {
    Unit = {
      Description = "Periodic mbsync timer";
    };
    Timer = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
