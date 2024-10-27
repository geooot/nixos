{
  description = "Nixos config flake";
     
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    # impermanence = {
    #   url = "github:nix-community/impermanence";
    # };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Private flakes
    fontpkgs = {
      url = "git+file:///home/george/github.com/geooot/fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
    };

  };

  outputs = {self, stylix, nixpkgs, disko, fontpkgs, ...} @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations.dosa = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs outputs;};
      modules = [
        stylix.nixosModules.stylix
        disko.nixosModules.default
        (import ./disko/disko.nix { device = "/dev/nvme0n1"; })

        ./nixos/configuration.nix
              
        # inputs.home-manager.nixosModules.default
        # inputs.impermanence.nixosModules.impermanence
      ];
    };
  };
}
