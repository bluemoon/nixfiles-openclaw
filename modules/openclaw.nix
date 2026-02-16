{ config, pkgs, inputs, ... }: {
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;
    documents = ./openclaw-documents;

    # Exclude tools with broken downloads or that we don't need
    excludeTools = [ "bird" "sonoscli" "imsg" "gogcli" "goplaces" ];

    # Plugin packages are already bundled in the openclaw package and available
    # via the gateway wrapper PATH — don't also add them to home.packages
    exposePluginPackages = false;

    # Use explicit instance so the submodule type system provides defaults
    # (works around missing nixMode in defaultInstance hardcoded attrset).
    # Config goes on the instance to avoid recursiveUpdate null-clobbering.
    instances.default.config = {
      gateway = {
        mode = "local";
        auth = { token = "/run/agenix/openclaw-gateway-token"; };
      };

      channels.telegram = {
        tokenFile = "/run/agenix/openclaw-telegram-token";
        allowFrom = [ 7494222458 ];
      };

      env.vars = { ANTHROPIC_API_KEY = "/run/agenix/openclaw-anthropic-key"; };
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
