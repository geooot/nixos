# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

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
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

  nixpkgs.config.allowUnfree = true;

  fonts.packages = [
    inputs.fontpkgs.packages.x86_64-linux.berkeley-mono
  ];

  networking.hostName = "dosa"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.tailscale.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.george = {
    isNormalUser = true;
    initialPassword = "abc";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      nodejs
      pnpm
      yt-dlp
      pnpm
      zoxide
      neovim
      waybar
      alacritty
      firefox
      rofi-wayland
      dunst
      swww
      libnotify
      spotify
      cargo
      neofetch
      discord
      obs-studio
      blender
      btop
      steam
      tmux
      mpv
      imv
    ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      george = import ../home-manager/home.nix;
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    libgcc
    nodejs_22
    libgcc
    gccgo
    kdePackages.dolphin
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum
    kdePackages.breeze
    fzf
    ripgrep
    htop
    wayvnc
    pavucontrol
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
  ];

  stylix.image = /etc/nixos/background.png;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/primer-dark-dimmed.yaml";
  stylix.polarity = "dark";
  stylix.fonts.monospace = {
    package = inputs.fontpkgs.packages.x86_64-linux.berkeley-mono;
    name = "Berkeley Mono Variable";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    gamescopeSession.enable = true;
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "george";
      };
      default_session = initial_session;
    };
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.production;

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = true;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;
    };
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    57621
    5900
    47984
    47989
    47990
    48010
  ];
  networking.firewall.allowedUDPPorts = [
    5353
    5900
    {
      from = 47998;
      to = 48000;
    }
    {
      from = 8000;
      to = 8010;
    }
  ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
