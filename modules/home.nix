{ config, lib, pkgs, home-manager, inputs, ... }:

{
  # Let Home Manager install and manage itself.
  #programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  # home.username = "bradford";
  # home.homeDirectory = "/Users/bradford";
  home.sessionVariables = {
    EDITOR = "nvim";
    # SSL certificates for all programs
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
    GIT_SSL_CAINFO = "/etc/ssl/certs/ca-certificates.crt";
  };
  home.sessionPath = [ "$HOME/.local/bin" ];
  #
  programs.bash = {
    enable = true;
    shellAliases = { timeout = "gtimeout"; };
  };

  programs.direnv = {
    enable = true;
    # enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      search_mode = "fuzzy";
      filter_mode = "global";
      style = "compact";
    };
  };

  programs.bat = { enable = true; };

  # Better ls
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # ZOxide
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Git config
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Bradford Toney";
        email = "bradford.toney@gmail.com";
        signingkey = "9159E6B4C25B8F6B";
      };
      alias = { st = "status"; };
      core = { editor = "nvim"; };
      # TODO: Breaks Cargo?
      # url."ssh://git@github.com/".insteadOf = "https://github.com/";
      pull.rebase = true;
      push.autoSetupRemote = true;
      commit.gpgsign = false;
      rerere.enabled = true;
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.11";

  home.packages = [
    pkgs.coreutils-prefixed # GNU coreutils with g prefix (gtimeout, gdate, etc.)
    pkgs.any-nix-shell
    pkgs.fd
    pkgs.gh
    pkgs.gnupg
    pkgs.htop
    # jq, ripgrep, curl, nodejs, git, python3 — provided by openclaw batteries bundle
    pkgs.just
    pkgs.nixfmt-classic
    pkgs.openssl
    pkgs.nil
    pkgs.tmux
    pkgs.tree
    pkgs.age
    inputs.agenix.packages.aarch64-darwin.default

    # Shell enhancements
    pkgs.starship
    pkgs.tldr

    # System monitoring
    pkgs.btop
    pkgs.procs
    pkgs.duf

    # Data
    (pkgs.snowflake-cli.overrideAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    }))

    # Network/HTTP
    pkgs.xh

    # Git/Diff
    pkgs.lazygit
    pkgs.delta

    # AI
    inputs.claude-code.packages.${pkgs.system}.default

    # Misc
    pkgs.fastfetch

    inputs.nixvim-config.packages.${pkgs.system}.default
  ];

  home.activation.snowflakePermissions =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      chmod 0600 "$HOME/.snowflake/config.toml" 2>/dev/null || true
    '';

  home.file.".snowflake/config.toml".text = ''
    [connections.default]
    account = "so07687.us-east-2.aws"
    user = "BRADFORD_TONEY"
    role = "ANALYST_ROLE"
    warehouse = "PC_DBT_WH"
    database = "DBT_DEV_BTONEY"
    authenticator = "SNOWFLAKE_JWT"
    private_key_path = "/run/agenix/snowflake-rsa-key"
  '';

  imports = [ ./home-manager/fish.nix ./home-manager/tmux.nix ];
}
