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
      # Don't override nixpkgs — gateway needs fetchPnpmDeps from its own pin
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
            nix.enable = false; # Determinate Nix manages the daemon
            # Caches: configure via `determinate-nixd` or /etc/nix/nix.conf on the machine
            # claude-code.cachix.org, cache.garnix.io
            nixpkgs = {
              config.allowBroken = true;
              config.allowUnfree = true;
              overlays = with inputs; [
                nur.overlays.default
                # Thin shim: expose nix-openclaw's pre-built packages in pkgs.*
                # so the HM module's lib.nix can reference pkgs.openclaw / pkgs.openclawPackages.
                # We do NOT use the upstream overlay (it callPackage's openclaw-gateway
                # against our nixpkgs which lacks fetchPnpmDeps).
                (final: prev:
                  let
                    system = prev.stdenv.hostPlatform.system;
                    oc = nix-openclaw.packages.${system};
                    # For withTools: import nix-openclaw's package builder using its own nixpkgs
                    ocNixpkgs =
                      import nix-openclaw.inputs.nixpkgs { inherit system; };
                    ocSrc = nix-openclaw;
                    steipetePkgs = if nix-openclaw.inputs.nix-steipete-tools
                    ? packages && builtins.hasAttr system
                    nix-openclaw.inputs.nix-steipete-tools.packages then
                      nix-openclaw.inputs.nix-steipete-tools.packages.${system}
                    else
                      { };
                  in {
                    inherit (oc) openclaw openclaw-gateway openclaw-tools;
                    openclawPackages = oc // {
                      toolNames = [ ];
                      withTools =
                        { toolNamesOverride ? null, excludeToolNames ? [ ] }:
                        import "${ocSrc}/nix/packages" {
                          pkgs = ocNixpkgs;
                          inherit steipetePkgs toolNamesOverride
                            excludeToolNames;
                        };
                    };
                  })
              ];
            };
          })
        ];
      };
    };
}
