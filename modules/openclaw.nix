{ config, pkgs, inputs, ... }:
let
  # Use nix-openclaw's own packages (built against its pinned nixpkgs)
  # to avoid fetchPnpmDeps mismatch with our nixpkgs
  openclawPkgs =
    inputs.nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;
    package = openclawPkgs.openclaw;
    documents = ./openclaw-documents;

    # Use explicit instance so the submodule type system provides defaults
    # (works around missing nixMode in defaultInstance hardcoded attrset)
    instances.default = { };

    config = {
      gateway = {
        mode = "local";
        auth = { token = "/run/agenix/openclaw-gateway-token"; };
      };

      channels.telegram = {
        tokenFile = "/run/agenix/openclaw-telegram-token";
        allowFrom = [ ]; # TODO: add your Telegram chat ID here
      };
    };

    config.env.vars = {
      ANTHROPIC_API_KEY = "/run/agenix/openclaw-anthropic-key";
    };

    bundledPlugins = {
      summarize.enable = true;
      peekaboo.enable = true;
      oracle.enable = true;
      poltergeist.enable = true;
      sag.enable = true;
      camsnap.enable = true;
      gogcli.enable = false; # needs Google Calendar API setup
      goplaces.enable = false; # needs Google Places API key
      bird.enable = false; # needs Twitter/X auth
      sonoscli.enable = false; # needs Sonos on network
      imsg.enable = false; # needs iMessage setup
    };
  };
}
