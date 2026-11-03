{ pkgs, lib, secretsPath, ... }:
let
  claudeCodePkg = pkgs.claude-code.overrideAttrs (_oldAttrs: {
    version = "2.1.286";

    src = pkgs.fetchurl {
      url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.286/linux-x64/claude";
      sha256 = "sha256-/lA/ZcYonVnCPlshrkTwNYP5l90zosv8datPlvuPxz8=";
    };
  });

  notionMcpWrapper = import ./codex/notion-mcp-wrapper.nix { inherit pkgs secretsPath; };
in
{
  # bun runs the Telegram channel plugin.
  home.packages = [ claudeCodePkg pkgs.bun ];

  home.file.".claude/CLAUDE.md" = {
    source = ./agents/AGENTS.md;
    force = true;
  };
  # Superpowers skills come from the Claude Code plugin, so only shared extras here.
  home.file.".claude/skills/commit-message-id" = {
    source = ./agents/skills/commit-message-id;
    recursive = true;
  };
  home.file.".claude/skills/herdr" = {
    source = ./agents/skills/herdr;
    recursive = true;
  };

  home.activation.validateClaudeNotionToken = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${./codex/notion_token.py} check ${secretsPath}
  '';

  home.activation.claudeNotion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    token_file="$HOME/.config/runtime-env/notion-token"
    config_file="$HOME/.claude.json"
    command="${notionMcpWrapper}/bin/notion-mcp-server"

    ${pkgs.python3}/bin/python3 ${./codex/notion_token.py} write ${secretsPath} "$token_file"

    current="$(${pkgs.jq}/bin/jq -r '.mcpServers["notion-api"].command // empty' "$config_file" 2>/dev/null || true)"
    if [ "$current" != "$command" ]; then
      ${claudeCodePkg}/bin/claude mcp remove --scope user notion-api >/dev/null 2>&1 || true
      ${claudeCodePkg}/bin/claude mcp add --scope user notion-api -- "$command"
    fi
  '';

  # Telegram channel: run `claude --channels plugin:telegram@claude-plugins-official`,
  # then pair once with /telegram:access. The token is optional until a bot exists.
  home.activation.claudeTelegram = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    plugin="telegram@claude-plugins-official"
    installed="$HOME/.claude/plugins/installed_plugins.json"
    if ! ${pkgs.jq}/bin/jq -e --arg p "$plugin" '.plugins | has($p)' "$installed" >/dev/null 2>&1; then
      ${claudeCodePkg}/bin/claude plugin install --scope user "$plugin" \
        || echo "warning: could not install $plugin; retry on the next switch" >&2
    fi

    token="$(${pkgs.jq}/bin/jq -r '.telegram_bot_token // empty' ${secretsPath} 2>/dev/null || true)"
    if [ -n "$token" ]; then
      state_dir="$HOME/.claude/channels/telegram"
      mkdir -p -m 700 "$state_dir"
      (umask 077 && printf 'TELEGRAM_BOT_TOKEN=%s\n' "$token" > "$state_dir/.env")
    else
      echo "telegram_bot_token is not set in ${secretsPath}; skipping Telegram channel token" >&2
    fi
  '';
}
