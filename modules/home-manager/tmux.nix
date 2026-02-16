{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    #plugins = with unstable; [ tmuxPlugins.nord ];
    shortcut = "o";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    terminal = "screen-256color";
    extraConfig = ''
      bind s set-option -g status
      bind C-s set-option -g status
    '';
  };
}
