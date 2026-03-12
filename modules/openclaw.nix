{ config, pkgs, lib, inputs, ... }: {
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  # On headless/SSH-only machines the gui/UID launchd domain isn't available,
  # so HM's LaunchAgent fails to load.  We keep it enabled (so the plist +
  # wrapper are still built) but suppress the activation-time bootout/bootstrap
  # errors.  A system-level LaunchDaemon in the darwin config loads the
  # gateway as user wz_oc instead.

  # Inject env vars into the HM-generated plist (used by the LaunchDaemon).
  launchd.agents."com.steipete.openclaw.gateway".config.EnvironmentVariables = {
    PATH = lib.mkForce (lib.concatStringsSep ":" [
      "/etc/profiles/per-user/wz_oc/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]);
    ANTHROPIC_API_KEY = "/run/agenix/openclaw-anthropic-key";
    OPENAI_API_KEY = "/run/agenix/openclaw-openai-key";
  };

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

      acp = {
        enabled = true;
        defaultAgent = "pi";
        allowedAgents = [ "pi" "claude-code" ];
      };

      channels.telegram = {
        tokenFile = "/run/agenix/openclaw-telegram-token";
        allowFrom = [ 7494222458 8200770039 8471427964 ];
        groupPolicy = "allowlist";
        groupAllowFrom = [ 7494222458 8200770039 8471427964 ];
        groups."*" = {
          requireMention = true;
        };
      };

      # ANTHROPIC_API_KEY and OPENAI_API_KEY are read from agenix files
      # and exported as real key values by the system LaunchDaemon's
      # ProgramArguments script in flake.nix.
};

    bundledPlugins = {
      acpx.enable = true;
      summarize.enable = true;
      peekaboo.enable = true;
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
