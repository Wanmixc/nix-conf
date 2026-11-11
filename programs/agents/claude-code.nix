{ pkgs, lib, secretsPath, ... }:
let
  claudeCodePkg = pkgs.claude-code.overrideAttrs (_oldAttrs: {
    version = "2.1.286";

    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.286/linux-x64/claude";
      sha256 = "sha256-/lA/ZcYonVnCPlshrkTwNYP5l90zosv8datPlvuPxz8=";
    };
  });

  notionMcpWrapper = import ./notion/notion-mcp-wrapper.nix { inherit pkgs secretsPath; };
in
{
  home.packages = [ claudeCodePkg ];

  home.file.".claude/CLAUDE.md" = {
    source = ./AGENTS.md;
    force = true;
  };
  # Superpowers skills come from the Claude Code plugin, so only shared extras here.
  home.file.".claude/skills/commit-message-id" = {
    source = ./skills/commit-message-id;
    recursive = true;
  };
  home.file.".claude/skills/teach" = {
    source = ./skills/teach;
    recursive = true;
  };
  home.file.".claude/skills/herdr" = {
    source = ./skills/herdr;
    recursive = true;
  };

  home.activation.validateClaudeNotionToken = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${./notion/notion_token.py} check ${secretsPath}
  '';

  home.activation.claudeNotion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    token_file="$HOME/.config/runtime-env/notion-token"
    config_file="$HOME/.claude.json"
    command="${notionMcpWrapper}/bin/notion-mcp-server"

    ${pkgs.python3}/bin/python3 ${./notion/notion_token.py} write ${secretsPath} "$token_file"

    current="$(${pkgs.jq}/bin/jq -r '.mcpServers["notion-api"].command // empty' "$config_file" 2>/dev/null || true)"
    if [ "$current" != "$command" ]; then
      ${claudeCodePkg}/bin/claude mcp remove --scope user notion-api >/dev/null 2>&1 || true
      ${claudeCodePkg}/bin/claude mcp add --scope user notion-api -- "$command"
    fi
  '';

}
