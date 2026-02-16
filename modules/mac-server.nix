{ config, pkgs, lib, self, ... }:
let
  primaryUser = config.system.primaryUser;
  hasPrimaryUser = primaryUser != null;
  primaryHome = if hasPrimaryUser then "/Users/${primaryUser}" else null;
in {

  system.stateVersion = 6;

  nix = {
    package = pkgs.nix;
    extraOptions = ''
      system = aarch64-darwin
      extra-platforms = aarch64-darwin x86_64-darwin
      experimental-features = nix-command flakes
      build-users-group = nixbld
    '';
  };

  programs.fish.enable = true;
  environment.shells = with pkgs; [ fish ];
  users.users = lib.optionalAttrs hasPrimaryUser {
    ${primaryUser} = {
      home = primaryHome;
      shell = pkgs.fish;
      uid = 501;
    };
  };

  system.activationScripts.postActivation.text =
    lib.optionalString hasPrimaryUser ''
      sudo chsh -s /run/current-system/sw/bin/fish ${primaryUser}
    '';

  # Server: never sleep
  power.sleep.display = "never";
  power.sleep.computer = "never";
}
