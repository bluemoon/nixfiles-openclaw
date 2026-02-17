{ config, pkgs, lib, inputs, ... }: {
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  # Ensure the gateway's launchd job has nix profile paths so agent-spawned
  # shell commands (rg, jq, etc.) are found.
  launchd.agents."com.steipete.openclaw.gateway".config.EnvironmentVariables.PATH =
    lib.mkForce (lib.concatStringsSep ":" [
      "/etc/profiles/per-user/wz_oc/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]);

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

      agents.defaults.subagents.model = "openai/gpt-5.2";

      channels.telegram = {
        tokenFile = "/run/agenix/openclaw-telegram-token";
        allowFrom = [ 7494222458 8200770039 ];
        groupPolicy = "allowlist";
        groupAllowFrom = [ 7494222458 8200770039 ];
        groups."*" = {
          requireMention = true;
        };
      };

      # ANTHROPIC_API_KEY is injected via bundledPlugins.oracle.config.env below,
      # NOT here. env.vars writes literal strings into the JSON — the gateway
      # would send the file path to Anthropic instead of the key contents.
    };

    bundledPlugins = {
      summarize.enable = true;
      peekaboo.enable = true;
      # oracle plugin carries ANTHROPIC_API_KEY: the gateway wrapper reads the
      # agenix file at runtime and exports the contents as a real env var.
      oracle = {
        enable = true;
        config.env = {
          ANTHROPIC_API_KEY = "/run/agenix/openclaw-anthropic-key";
          OPENAI_API_KEY = "/run/agenix/openclaw-openai-key";
        };
      };
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
