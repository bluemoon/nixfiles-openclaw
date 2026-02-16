# This file is used by agenix to determine which keys can decrypt which secrets.
# Run: cd secrets && agenix -e <secret>.age
let
  # User keys (derived from SSH keys via ssh-to-age)
  bradford = "age1uuu65p336eycfej7wmyzg9vmf0a46lllkcknd4nat6f48thkhdzqun8kla";

  allKeys = [ bradford ];
in {
  # OpenClaw secrets (wz-oc)
  "openclaw-telegram-token.age".publicKeys = allKeys;
  "openclaw-anthropic-key.age".publicKeys = allKeys;
  "openclaw-gateway-token.age".publicKeys = allKeys;

  # Snowflake
  "snowflake-rsa-key.age".publicKeys = allKeys;
}
