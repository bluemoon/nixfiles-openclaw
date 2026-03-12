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
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
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
          # System-level LaunchDaemon for the openclaw gateway.
          # Runs as user wz_oc in the system domain — works over SSH
          # without a GUI login session (unlike gui/UID LaunchAgents).
          ({ config, pkgs, lib, ... }: {
            launchd.daemons."com.steipete.openclaw.gateway" = {
              serviceConfig = {
                Label = "com.steipete.openclaw.gateway";
                UserName = "wz_oc";
                ProgramArguments = [
                  "/bin/sh"
                  "-c"
                  # wait4path ensures the nix store is mounted, then exec the
                  # wrapper from the HM-generated LaunchAgent plist.  This
                  # indirection means the daemon always runs the latest wrapper
                  # after a darwin-rebuild.  We also read agenix secret files
                  # and export the actual key values (the gateway expects real
                  # keys, not file paths).
                  ''
                    /bin/wait4path /nix/store && \
                    wrapper="$(/usr/bin/sed -n 's|.*exec \(/nix/store/[^ ]*openclaw-gateway-default\).*|\1|p' \
                      /Users/wz_oc/Library/LaunchAgents/com.steipete.openclaw.gateway.plist | /usr/bin/head -1)" && \
                    export ANTHROPIC_API_KEY="$(/bin/cat /run/agenix/openclaw-anthropic-key)" && \
                    export OPENAI_API_KEY="$(/bin/cat /run/agenix/openclaw-openai-key)" && \
                    exec "$wrapper" gateway --port 18789
                  ''
                ];
                RunAtLoad = true;
                KeepAlive = true;
                WorkingDirectory = "/Users/wz_oc/.openclaw";
                StandardOutPath = "/tmp/openclaw/openclaw-gateway.log";
                StandardErrorPath = "/tmp/openclaw/openclaw-gateway.log";
                EnvironmentVariables = {
                  HOME = "/Users/wz_oc";
                  OPENCLAW_CONFIG_PATH = "/Users/wz_oc/.openclaw/openclaw.json";
                  OPENCLAW_STATE_DIR = "/Users/wz_oc/.openclaw";
                  OPENCLAW_IMAGE_BACKEND = "sips";
                  OPENCLAW_NIX_MODE = "1";
                  # ANTHROPIC_API_KEY and OPENAI_API_KEY are read from agenix
                  # files at launch time in ProgramArguments above.
                  PATH = lib.concatStringsSep ":" [
                    "/etc/profiles/per-user/wz_oc/bin"
                    "/run/current-system/sw/bin"
                    "/nix/var/nix/profiles/default/bin"
                    "/usr/bin"
                    "/bin"
                    "/usr/sbin"
                    "/sbin"
                  ];
                };
              };
            };
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
                # Disable failing tests in snowflake-connector-python
                (final: prev: {
                  python313Packages = prev.python313Packages.override {
                    overrides = pfinal: pprev: {
                      snowflake-connector-python =
                        pprev.snowflake-connector-python.overridePythonAttrs {
                          doCheck = false;
                        };
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
