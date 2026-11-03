{ pkgs, secretsPath, ... }:
let
  piDir = ".pi/agent";

  settings = {
    theme = "dark";
    quietStartup = true;
    enableInstallTelemetry = false;
    collapseChangelog = true;
    # defaultProvider = "mimo";
    # defaultModel = "deepseek/deepseek-v4.1-flash:free";
    # defaultThinkingLevel = "medium";
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-luna";
    defaultThinkingLevel = "xhigh";
    # These packages are installed declaratively below. Pin their Pi sources to
    # the same versions so Pi does not run an online update check at startup.
    # MCP is built into Pi since 1.0.0 (see ~/.pi/agent/mcp.json), so the former
    # pi-mcp-adapter package is intentionally absent: it replaces built-in MCP.
    packages = [
      "npm:pi-web-access@0.22.0"
      "npm:@gotgenes/pi-permission-system@25.0.0"
      "npm:pi-zentui@0.18.1"
    ];
  };

  models = {
    providers = {
      mimo = {
        baseUrl = "https://api.xkiro.com/v1";
        api = "openai-completions";
        apiKey = "$MIMO_API_KEY";
        models = [
          {
            id = "qwen/qwen3.8-max:free";
            name = "qwen/qwen3.8-max:free";
          }
        ];
      };
      deeperseeker = {
        # Local DeeperSeeker OpenAI-compatible API.
        baseUrl = "http://localhost:4000/v1";
        api = "openai-completions";
        # Keep this aligned with DEEPSEEKER_API_KEY in DeeperSeeker's .env.
        apiKey = "dseeker";
        models = [
          {
            id = "instant";
            name = "instant";
          }
          {
            id = "vision";
            name = "vision";
          }
          {
            id = "expert";
            name = "expert";
          }
        ];
      };
    };
  };

  permissionConfig = builtins.fromJSON (builtins.readFile ./permission-config.json);

  # Shared with Codex and Claude Code: same secrets key, token file, and wrapper.
  notionMcpWrapper = import ../codex/notion-mcp-wrapper.nix { inherit pkgs secretsPath; };
  # Built-in MCP reads user-level servers from ~/.pi/agent/mcp.json, using the
  # same mcpServers shape as other MCP clients.
  mcpConfig = {
    mcpServers = {
      notion-api = {
        command = "${notionMcpWrapper}/bin/notion-mcp-server";
      };
    };
  };
in
{
  home.file.".pi/agent/AGENTS.md".source = ../agents/AGENTS.md;
  home.file.".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON permissionConfig;
  # Include reference documents, prompts, and scripts alongside each SKILL.md.
  home.file.".pi/agent/skills" = {
    source = ../agents/skills/superpowers;
    recursive = true;
  };
  home.file.".pi/agent/skills/commit-message-id" = {
    source = ../agents/skills/commit-message-id;
    recursive = true;
  };
  home.file.".pi/agent/skills/herdr/SKILL.md".source = ../agents/skills/herdr/SKILL.md;

  home.file."${piDir}/settings.json".text = builtins.toJSON settings;
  home.file."${piDir}/keybindings.json".text = builtins.toJSON {
    # Use Tab for queued follow-up messages while Pi is working. Pi's patched
    # editor gives autocomplete priority when a completion menu is visible.
    "app.message.followUp" = "tab";
  };
  home.file."${piDir}/models.json".text = builtins.toJSON models;
  home.file."${piDir}/mcp.json".text = builtins.toJSON mcpConfig;
}
