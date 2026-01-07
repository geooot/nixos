{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Swap configuration for hibernation
  # 18GB swapfile (larger than 16GB RAM for safe hibernation)
  swapDevices = [
    {
      device = "/swapfile";
      size = 18432; # Size in MB
    }
  ];

  # Hibernation configuration
  # Resume offset calculated with: sudo filefrag -v /swapfile
  boot.resumeDevice = "/dev/disk/by-uuid/3b41365f-c5c1-43bd-99ba-e881f19e5889";
  boot.kernelParams = [
    "resume_offset=58896384" # Physical offset of swapfile on disk
  ];

  # Power management behavior
  # - Hibernate on battery power (lid close, suspend key)
  # - Suspend on AC power (faster resume)
  # - Ignore lid close when docked (external display)
  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "suspend";
    HandleSuspendKey = "hibernate";
    HandleHibernateKey = "hibernate";
  };

  # Lock screen before sleep/hibernate
  systemd.services.lock-before-sleep = {
    description = "Lock screen before suspend/hibernate";
    before = [
      "sleep.target"
      "hibernate.target"
      "suspend.target"
    ];
    wantedBy = [
      "sleep.target"
      "hibernate.target"
      "suspend.target"
    ];
    serviceConfig = {
      Type = "simple";
      User = "george";
      Environment = [
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
      ExecStart = "${pkgs.hyprlock}/bin/hyprlock";
      ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
    };
  };
}
