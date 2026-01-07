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
}
