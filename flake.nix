{
  description = "OpenClaw Server (wz-oc) Nix Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nur.url = "github:nix-community/NUR";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    base16 = {
      url = "github:shaunsingh/base16.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    base16-carbon-dark = {
      url = "github:shaunsingh/base16-carbon-dark";
      flake = false;
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim-config = {
      url = "path:./modules/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixvim.follows = "nixvim";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let pkgs = nixpkgs.legacyPackages."aarch64-darwin";
    in {
      darwinConfigurations."wz-oc" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit self inputs; };
        modules = [
          ./modules/mac-server.nix
          inputs.agenix.darwinModules.default
          ./modules/secrets.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
              users.wz_oc = {
                imports = [
                  inputs.base16.hmModule
                  ./modules/home.nix
                  ./modules/openclaw.nix
                ];
              };
            };
          }
          ({ ... }: {
            system.primaryUser = "wz_oc";
            environment.etc."nix-host".text = "wz-oc";
          })
          ({ config, pkgs, lib, ... }: {
            nix.enable = true;
            nix.settings = {
              substituters = [ "https://claude-code.cachix.org" ];
              trusted-public-keys = [
                "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
              ];
            };
            nixpkgs = {
              config.allowBroken = true;
              config.allowUnfree = true;
              overlays = with inputs; [
                nur.overlays.default
                nix-openclaw.overlays.default
              ];
            };
          })
        ];
      };
    };
}
