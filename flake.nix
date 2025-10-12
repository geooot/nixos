{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:nix-community/stylix";

    # impermanence = {
    #   url = "github:nix-community/impermanence";
    # };

    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.hyprland.follows = "hyprland";
    };

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprgrass = {
      url = "github:horriblename/hyprgrass";
      inputs.hyprland.follows = "hyprland";
    };

    # Private flakes
    fontpkgs = {
      url = "git+file:///home/george/github.com/geooot/fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      stylix,
      nixpkgs,
      disko,
      fontpkgs,
      nixos-hardware,
      xremap-flake,
      ...
    }@inputs:
    let
      inherit (self) outputs;
    in
    {
      nixosConfigurations.dosa = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          stylix.nixosModules.stylix
          disko.nixosModules.default
          (import ./disko/disko.nix { device = "/dev/nvme0n1"; })

          ./systems/dosa/hardware-configuration.nix
          ./systems/dosa/configuration.nix
          ./hyprland/configuration.nix
          ./obs/configuration.nix
          ./plasma6/configuration.nix
          ./stylix/configuration.nix
          ./home-manager/configuration.nix

          # inputs.impermanence.nixosModules.impermanence
        ];
      };
      nixosConfigurations.appam = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          stylix.nixosModules.stylix
          # disko.nixosModules.default
          # (import ./disko/disko.nix { device = "/dev/nvme0n1"; })

          ./systems/appam/hardware-configuration.nix
          ./systems/appam/configuration.nix
          ./hyprland/configuration.nix
          ./plasma6/configuration.nix
          ./stylix/configuration.nix
          ./home-manager/configuration.nix

          # inputs.impermanence.nixosModules.impermanence
        ];
      };
      nixosConfigurations.vada = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs;
        };
        modules = [
          nixos-hardware.nixosModules.framework-12-13th-gen-intel
          stylix.nixosModules.stylix
          # disko.nixosModules.default
          # (import ./disko/disko.nix { device = "/dev/nvme0n1"; })
          ./hyprland/configuration.nix
          xremap-flake.nixosModules.default
          ./xremap/configuration.nix
          ./systems/vada/hardware-configuration.nix
          ./systems/vada/configuration.nix
          ./obs/configuration.nix
          ./plasma6/configuration.nix
          ./stylix/configuration.nix
          ./home-manager/configuration.nix

          # inputs.impermanence.nixosModules.impermanence
        ];
      };
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
