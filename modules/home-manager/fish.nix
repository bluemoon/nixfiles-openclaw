{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    package = pkgs.fish;
    loginShellInit = ''
      set -xg TERM xterm-256color

      fish_add_path --move --prepend --path $HOME/.nix-profile/bin /run/wrappers/bin /etc/profiles/per-user/$USER/bin /run/current-system/sw/bin /nix/var/nix/profiles/default/bin 

      # User paths
      fish_add_path -g $HOME/bin
      fish_add_path $HOME/.local/bin

      # Development tools
      fish_add_path -g $HOME/.cargo/bin
      fish_add_path -g $HOME/go/bin

      # Python 3.11
      fish_add_path -g /Library/Frameworks/Python.framework/Versions/3.11/bin

      # Yarn global bin - check if yarn exists first
      if command -q yarn
        set -l yarn_global_bin (yarn global bin 2>/dev/null)
        if test -n "$yarn_global_bin"
          fish_add_path -g $yarn_global_bin
        end
      end
    '';

    interactiveShellInit = ''
      any-nix-shell fish --info-right | source
      set -xg NIX_PATH $HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels
      set -xg NIXPKGS_ALLOW_UNFREE 1
      eval (zoxide init fish)
      eval (direnv hook fish)

      # Granted assume wrapper (use fenv to source bash script)
      function assume
        fenv source (which assume) $argv
      end

      if test -f ~/.config/fish/completions/granted.fish
        source ~/.config/fish/completions/granted.fish
      end

      function nixswitch
        if not test -f /etc/nix-host
          echo "Error: /etc/nix-host not found. Run darwin-rebuild manually first."
          return 1
        end
        set -l host (cat /etc/nix-host)
        sudo darwin-rebuild switch --flake $HOME/nixfiles-openclaw#$host
      end

      function nixup
        if not test -f /etc/nix-host
          echo "Error: /etc/nix-host not found. Run darwin-rebuild manually first."
          return 1
        end
        set -l host (cat /etc/nix-host)
        nix flake update --flake $HOME/nixfiles-openclaw
        and sudo darwin-rebuild switch --flake $HOME/nixfiles-openclaw#$host
      end

      if type -q rbenv
        status --is-interactive; and rbenv init - fish | source
      end


      # Git helper functions
      function git_current_branch
        git branch --show-current 2> /dev/null
      end

      function gdnolock
        git diff $argv --color | sed 's/index [0-9a-f]\{7\}\.\.[0-9a-f]\{7\}/index .../g'
      end

      function grename
        if test (count $argv) -ne 2
          echo "Usage: grename old_branch new_branch"
          return 1
        end
        git branch -m $argv[1] $argv[2]
        if git push origin :$argv[1]
          git push --set-upstream origin $argv[2]
        end
      end

      # Kill process on specified port
      function killport
        if test (count $argv) -eq 0
          echo "Usage: killport <port>"
          return 1
        end
        set -l port $argv[1]
        set -l pid (lsof -ti:$port)
        if test -n "$pid"
          kill -9 $pid
          echo "Killed process $pid on port $port"
        else
          echo "No process found on port $port"
        end
      end

      # Git worktree helpers
      # gwa <branch> - create worktree with new branch (prefixed with bradford/)
      function gwa
        if test (count $argv) -lt 1
          echo "Usage: gwa <branch>"
          return 1
        end
        set -l branch "bradford/$argv[1]"
        set -l root (git rev-parse --show-toplevel)
        set -l path "$root/.worktrees/$argv[1]"
        mkdir -p (dirname "$path")
        git worktree add -b "$branch" "$path"
        cd "$path"
      end

      # gwd - remove current worktree and delete branch
      function gwd
        set -l current (pwd)
        set -l root (git rev-parse --show-toplevel 2>/dev/null)
        if not string match -q "*.worktrees/*" "$current"
          echo "Not in a .worktrees directory"
          return 1
        end
        set -l branch (git branch --show-current)
        read -l -P "Remove worktree and delete branch '$branch'? [y/N] " confirm
        if test "$confirm" != "y" -a "$confirm" != "Y"
          return 1
        end
        # Go to main worktree
        set -l main_root (string replace -r '/.worktrees/.*' "" "$current")
        cd "$main_root"
        git worktree remove "$current"
        git branch -D "$branch"
      end

      # gwpr <PR> - create worktree for a pull request
      function gwpr
        if test (count $argv) -lt 1
          echo "Usage: gwpr <PR_NUMBER> [<REMOTE>]"
          return 1
        end
        set -l pr $argv[1]
        set -l remote (test (count $argv) -ge 2; and echo $argv[2]; or echo origin)
        set -l branch (gh pr view "$pr" --json headRefName -q .headRefName)
        if test -z "$branch"
          echo "Failed to get branch for PR #$pr"
          return 1
        end
        set -l root (git rev-parse --show-toplevel)
        set -l path "$root/.worktrees/$branch"
        mkdir -p (dirname "$path")
        git fetch "$remote" "$branch"
        git worktree add "$path" "$branch"
        cd "$path"
        echo "PR #$pr: $branch"
      end

    '';

    shellAliases = {
      cat = "bat";
      vim = "nvim";
      timeout = "gtimeout"; # GNU timeout from coreutils-prefixed
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gc = "git commit -v";
    };

    shellAbbrs = {
      # Quick jumps
      nx = "cd ~/nixfiles-openclaw";

      # Git shortcuts
      gapa = "git add --patch";
      gau = "git add --update";
      gav = "git add --verbose";
      gap = "git apply";
      gapt = "git apply --3way";

      gb = "git branch";
      gba = "git branch -a";
      gbd = "git branch -d";
      gbda =
        "git for-each-ref --format '%(refname:short)' refs/heads | xargs git branch -d";
      gbD = "git branch -D";
      gbl = "git blame -b -w";
      gbnm = "git branch --no-merged";
      gbr = "git branch --remote";
      gbs = "git bisect";
      gbsb = "git bisect bad";
      gbsg = "git bisect good";
      gbsr = "git bisect reset";
      gbss = "git bisect start";

      "gc!" = "git commit -v --amend";
      "gcn!" = "git commit -v --no-edit --amend";
      gca = "git commit -v -a";
      "gca!" = "git commit -v -a --amend";
      "gcan!" = "git commit -v -a --no-edit --amend";
      "gcans!" = "git commit -v -a -s --no-edit --amend";
      gcam = "git commit -a -m";
      gcsm = "git commit -s -m";
      gcb = "git checkout -b";
      gcf = "git config --list";
      gcl = "git clone --recurse-submodules";
      gclean = "git clean -id";
      gpristine = "git reset --hard && git clean -dffx";
      gcm = "git checkout main";
      gcd = "git checkout develop";
      gcmsg = "git commit -m";
      gco = "git checkout";
      gcount = "git shortlog -sn";
      gcp = "git cherry-pick";
      gcpa = "git cherry-pick --abort";
      gcpc = "git cherry-pick --continue";
      gcs = "git commit -S";

      gd = "git diff";
      gdca = "git diff --cached";
      gdcw = "git diff --cached --word-diff";
      gdct = "git describe --tags $(git rev-list --tags --max-count=1)";
      gds = "git diff --staged";
      gdt = "git diff-tree --no-commit-id --name-only -r";
      gdw = "git diff --word-diff";

      gf = "git fetch";
      gfa = "git fetch --all --prune";
      gfo = "git fetch origin";

      gg = "git gui citool";
      gga = "git gui citool --amend";

      ghh = "git help";

      gignore = "git update-index --assume-unchanged";
      gignored = "git ls-files -v | grep '^[[:lower:]]'";

      gl = "git pull";
      glg = "git log --stat";
      glgp = "git log --stat -p";
      glgg = "git log --graph";
      glgga = "git log --graph --decorate --all";
      glgm = "git log --graph --max-count=10";
      glo = "git log --oneline --decorate";
      glol =
        "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'";
      glols =
        "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --stat";
      glod =
        "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'";
      glods =
        "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short";
      glola =
        "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --all";
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";

      gm = "git merge";
      gmom = "git merge origin/main";
      gmt = "git mergetool --no-prompt";
      gmtvim = "git mergetool --no-prompt --tool=vimdiff";
      gmum = "git merge upstream/main";
      gma = "git merge --abort";

      gp = "git push";
      gpd = "git push --dry-run";
      gpf = "git push --force-with-lease";
      "gpf!" = "git push --force";
      gpoat = "git push origin --all && git push origin --tags";
      gpu = "git push upstream";
      gpv = "git push -v";

      gr = "git remote";
      gra = "git remote add";
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbd = "git rebase develop";
      grbi = "git rebase -i";
      grbm = "git rebase main";
      grbs = "git rebase --skip";
      grev = "git revert";
      grh = "git reset";
      grhh = "git reset --hard";
      groh = "git reset origin/$(git_current_branch) --hard";
      grm = "git rm";
      grmc = "git rm --cached";
      grmv = "git remote rename";
      grrm = "git remote remove";
      grs = "git restore";
      grset = "git remote set-url";
      grss = "git restore --source";
      grt = "cd $(git rev-parse --show-toplevel || echo .)";
      gru = "git reset --";
      grup = "git remote update";
      grv = "git remote -v";

      gsb = "git status -sb";
      gsd = "git svn dcommit";
      gsh = "git show";
      gsi = "git submodule init";
      gsps = "git show --pretty=short --show-signature";
      gsr = "git svn rebase";
      gss = "git status -s";
      gst = "git status";

      gsta = "git stash push";
      gstaa = "git stash apply";
      gstc = "git stash clear";
      gstd = "git stash drop";
      gstl = "git stash list";
      gstp = "git stash pop";
      gsts = "git stash show --text";
      gstu = "git stash --include-untracked";
      gstall = "git stash --all";
      gsu = "git submodule update";
      gsw = "git switch";
      gswc = "git switch -c";

      gts = "git tag -s";
      gtv = "git tag | sort -V";

      gunignore = "git update-index --no-assume-unchanged";
      gunwip =
        "git log -n 1 | grep -q -c '\\-\\-wip\\-\\-' && git reset HEAD~1";
      gup = "git pull --rebase";
      gupv = "git pull --rebase -v";
      gupa = "git pull --rebase --autostash";
      gupav = "git pull --rebase --autostash -v";
      glum = "git pull upstream main";

      gwt = "git worktree";
      gwta = "git worktree add";
      gwtl = "git worktree list";
      gwtr = "git worktree remove";
      gwtm = "git worktree move";

      gwch = "git whatchanged -p --abbrev-commit --pretty=medium";
      gwip =
        "git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m '--wip-- [skip ci]'";

      # Kubernetes shortcuts (matches oh-my-zsh kubectl plugin)
      k = "kubectl";
      kca = "kubectl --all-namespaces";
      kaf = "kubectl apply -f";
      keti = "kubectl exec -t -i";

      # Context management (less needed with direnv)
      kcuc = "kubectl config use-context";
      kcsc = "kubectl config set-context";
      kcdc = "kubectl config delete-context";
      kccc = "kubectl config current-context";
      kcgc = "kubectl config get-contexts";
      kcn = "kubectl config set-context --current --namespace";

      # Delete
      kdel = "kubectl delete";
      kdelf = "kubectl delete -f";

      # Get all
      kga = "kubectl get all";
      kgaa = "kubectl get all --all-namespaces";

      # Pods
      kgp = "kubectl get pods";
      kgpl = "kubectl get pods -l";
      kgpn = "kubectl get pods -n";
      kgpsl = "kubectl get pods --show-labels";
      kgpa = "kubectl get pods --all-namespaces";
      kgpw = "kubectl get pods --watch";
      kgpwide = "kubectl get pods -o wide";
      kgpall = "kubectl get pods --all-namespaces -o wide";
      kep = "kubectl edit pods";
      kdp = "kubectl describe pods";
      kdelp = "kubectl delete pods";

      # Services
      kgs = "kubectl get svc";
      kgsa = "kubectl get svc --all-namespaces";
      kgsw = "kubectl get svc --watch";
      kgswide = "kubectl get svc -o wide";
      kes = "kubectl edit svc";
      kds = "kubectl describe svc";
      kdels = "kubectl delete svc";

      # Ingress
      kgi = "kubectl get ingress";
      kgia = "kubectl get ingress --all-namespaces";
      kei = "kubectl edit ingress";
      kdi = "kubectl describe ingress";
      kdeli = "kubectl delete ingress";

      # Namespaces
      kgns = "kubectl get namespaces";
      kens = "kubectl edit namespace";
      kdns = "kubectl describe namespace";
      kdelns = "kubectl delete namespace";

      # ConfigMaps
      kgcm = "kubectl get configmaps";
      kgcma = "kubectl get configmaps --all-namespaces";
      kecm = "kubectl edit configmap";
      kdcm = "kubectl describe configmap";
      kdelcm = "kubectl delete configmap";

      # Secrets
      kgsec = "kubectl get secret";
      kgseca = "kubectl get secret --all-namespaces";
      kdsec = "kubectl describe secret";
      kdelsec = "kubectl delete secret";

      # Deployments
      kgd = "kubectl get deployment";
      kgda = "kubectl get deployment --all-namespaces";
      kgdw = "kubectl get deployment --watch";
      kgdwide = "kubectl get deployment -o wide";
      ked = "kubectl edit deployment";
      kdd = "kubectl describe deployment";
      kdeld = "kubectl delete deployment";
      ksd = "kubectl scale deployment";
      krsd = "kubectl rollout status deployment";
      krrd = "kubectl rollout restart deployment";

      # ReplicaSets
      kgrs = "kubectl get replicaset";
      kdrs = "kubectl describe replicaset";
      kers = "kubectl edit replicaset";

      # Rollout
      krh = "kubectl rollout history";
      kru = "kubectl rollout undo";

      # StatefulSets
      kgss = "kubectl get statefulset";
      kgssa = "kubectl get statefulset --all-namespaces";
      kgssw = "kubectl get statefulset --watch";
      kgsswide = "kubectl get statefulset -o wide";
      kess = "kubectl edit statefulset";
      kdss = "kubectl describe statefulset";
      kdelss = "kubectl delete statefulset";
      ksss = "kubectl scale statefulset";
      krsss = "kubectl rollout status statefulset";
      krrss = "kubectl rollout restart statefulset";

      # DaemonSets
      kgds = "kubectl get daemonset";
      kgdsa = "kubectl get daemonset --all-namespaces";
      kgdsw = "kubectl get daemonset --watch";
      keds = "kubectl edit daemonset";
      kdds = "kubectl describe daemonset";
      kdelds = "kubectl delete daemonset";

      # Jobs & CronJobs
      kgcj = "kubectl get cronjob";
      kecj = "kubectl edit cronjob";
      kdcj = "kubectl describe cronjob";
      kdelcj = "kubectl delete cronjob";
      kgj = "kubectl get job";
      kej = "kubectl edit job";
      kdj = "kubectl describe job";
      kdelj = "kubectl delete job";

      # Nodes
      kgno = "kubectl get nodes";
      kgnosl = "kubectl get nodes --show-labels";
      keno = "kubectl edit node";
      kdno = "kubectl describe node";
      kdelno = "kubectl delete node";

      # PVC
      kgpvc = "kubectl get pvc";
      kgpvca = "kubectl get pvc --all-namespaces";
      kgpvcw = "kubectl get pvc --watch";
      kepvc = "kubectl edit pvc";
      kdpvc = "kubectl describe pvc";
      kdelpvc = "kubectl delete pvc";

      # Service Accounts
      kdsa = "kubectl describe sa";
      kdelsa = "kubectl delete sa";

      # Events
      kge = "kubectl get events --sort-by='.lastTimestamp'";
      kgew = "kubectl get events --sort-by='.lastTimestamp' --watch";

      # Logs
      kl = "kubectl logs";
      kl1h = "kubectl logs --since 1h";
      kl1m = "kubectl logs --since 1m";
      kl1s = "kubectl logs --since 1s";
      klf = "kubectl logs -f";
      klf1h = "kubectl logs --since 1h -f";
      klf1m = "kubectl logs --since 1m -f";
      klf1s = "kubectl logs --since 1s -f";

      # Other
      kcp = "kubectl cp";
      kpf = "kubectl port-forward";
      ktp = "kubectl top pods";
      ktn = "kubectl top nodes";
    };
  };

  programs.fish.plugins = [
    {
      name = "fenv";
      src = pkgs.fetchFromGitHub {
        owner = "oh-my-fish";
        repo = "plugin-foreign-env";
        rev = "b3dd471bcc885b597c3922e4de836e06415e52dd";
        sha256 = "sha256-3h03WQrBZmTXZLkQh1oVyhv6zlyYsSDS7HTHr+7WjY8=";
      };
    }
    {
      name = "git";
      src = pkgs.fetchFromGitHub {
        owner = "jhillyerd";
        repo = "plugin-git";
        rev = "2a3e35c05bdc5b9005f917d5281eb866b2e13104";
        sha256 = "sha256-tWiGIB6yHfZ+QSNJrahHxRQCIOaOlSNFby4bGIOIwic=";
      };
    }
  ];

}
