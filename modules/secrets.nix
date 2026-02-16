{ config, lib, ... }:
let
  hostname = config.environment.etc."nix-host".text;
  isWzOc = hostname == "wz-oc";
  primaryUser = config.system.primaryUser;
in {
  age.identityPaths = [ "/Users/${primaryUser}/.ssh/id_ed25519" ];

  age.secrets = lib.mkIf isWzOc {
    openclaw-telegram-token = {
      file = ../secrets/openclaw-telegram-token.age;
      owner = primaryUser;
      mode = "600";
    };
    openclaw-anthropic-key = {
      file = ../secrets/openclaw-anthropic-key.age;
      owner = primaryUser;
      mode = "600";
    };
    openclaw-openai-key = {
      file = ../secrets/openclaw-openai-key.age;
      owner = primaryUser;
      mode = "600";
    };
    openclaw-gateway-token = {
      file = ../secrets/openclaw-gateway-token.age;
      owner = primaryUser;
      mode = "600";
    };
    snowflake-rsa-key = {
      file = ../secrets/snowflake-rsa-key.age;
      owner = primaryUser;
      mode = "600";
    };
  };
}
