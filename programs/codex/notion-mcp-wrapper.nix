{ pkgs, secretsPath }:
let
  notionMcpPkg = pkgs.callPackage ./notion-mcp-server.nix { };
in
pkgs.writeShellScriptBin "notion-mcp-server" ''
  set -euo pipefail

  token_file="$HOME/.config/runtime-env/notion-token"
  if [ ! -s "$token_file" ]; then
    echo "Notion token is missing. Run Home Manager after setting notion_token in ${secretsPath}." >&2
    exit 1
  fi

  export NOTION_TOKEN="$(${pkgs.coreutils}/bin/cat "$token_file")"
  exec ${notionMcpPkg}/bin/notion-mcp-server "$@"
''
