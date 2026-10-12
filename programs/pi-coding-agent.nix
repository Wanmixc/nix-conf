{ pkgs, lib, ... }:
let
  version = "1.1.0";

  rawSrc = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-Cc2KCkPbsdgaZzRrCUALQ5znHYGMq6TpY+qViEahrtQ=";
  };

  # Since 1.0.0 the published tarball ships no lockfile. Generate one with
  # `npm install --package-lock-only` (see the header comment below), vendor it
  # in this directory, and have the sandboxed build step only patch it in.
  #
  # Update procedure for a new version:
  #   1. set `version` and refresh `rawSrc.hash`
  #   2. regenerate the vendored lockfile:
  #        npm install --package-lock-only --ignore-scripts --omit=dev \
  #          --prefix <unpacked tarball with devDependencies removed>
  #      and copy it to pi-coding-agent-<version>-package-lock.json
  #   3. set `npmDepsHash` to a dummy, build, and use the reported hash
  vendoredLockfile = ./pi/pi-coding-agent-${version}-package-lock.json;

  src = pkgs.runCommand "pi-coding-agent-src-${version}" {
    nativeBuildInputs = [ pkgs.jq pkgs.python3 ];
  } ''
    mkdir -p "$out"
    tar xzf ${rawSrc} --strip-components=1 -C "$out"
    chmod -R u+w "$out"
    cd "$out"

    # devDependencies are published workspace members and rely on local
    # workspaces, so drop them and install the release dependencies only.
    jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
    cp ${vendoredLockfile} package-lock.json

    # Make Tab context-aware: autocomplete wins when visible; otherwise Tab
    # queues a follow-up only while the agent is working. Keep these rewrites
    # exact so a Pi upgrade fails loudly instead of silently losing behavior.
    ${pkgs.python3}/bin/python3 - <<'PY'
from pathlib import Path

replacements = {
    Path("dist/modes/interactive/components/custom-editor.js"): (
        """        // Check all other app actions
""",
        """        // Let autocomplete consume Tab before the follow-up action.
        if (this.keybindings.matches(data, \"app.message.followUp\") && this.isShowingAutocomplete()) {
            super.handleInput(data);
            return;
        }
        // Check all other app actions
""",
    ),
    Path("dist/modes/interactive/interactive-mode.js"): (
        """        // If not streaming, Alt+Enter acts like regular Enter (trigger onSubmit)
        else if (this.editor.onSubmit) {
            this.editor.setText(\"\");
            this.editor.onSubmit(text);
        }
""",
        """        // Follow-up is only meaningful while the agent is working.
        // When idle, Tab remains available for autocomplete and never submits.
""",
    ),
}

for path, (old, new) in replacements.items():
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"patch target not found: {path}")
    path.write_text(text.replace(old, new, 1))
PY
  '';

  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version src;

    npmDepsHash = "sha256-dB8OUdcpBrQKBy1jhIkXwjfWiAqDmjW5s2LO42UyYHo=";

    # The published tarball already ships a built dist/, so there is nothing
    # to compile; only install the pinned dependencies.
    dontNpmBuild = true;
    npmFlags = [ "--ignore-scripts" "--omit=dev" ];

    # pi-tui is a dependency installed by npm rather than part of src. Patch
    # its Enter completion path after installation so slash/file completion
    # never submits the prompt accidentally.
    postInstall = ''
      found=0
      while IFS= read -r editor; do
        ${pkgs.python3}/bin/python3 - "$editor" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
confirm = '            if (kb.matches(data, "tui.select.confirm")) {'
confirm_pos = text.find(confirm)
if confirm_pos < 0:
    raise SystemExit(f"confirm target not found: {path}")
selected = '                const selected = this.autocompleteList.getSelectedItem();\n'
selected_pos = text.find(selected, confirm_pos)
provider = '                if (selected && this.autocompleteProvider) {\n'
provider_pos = text.find(provider, selected_pos)
if selected_pos < 0 or provider_pos < 0:
    raise SystemExit(f"confirm selection target not found: {path}")
insert_at = provider_pos + len(provider)
text = text[:insert_at] + """                    const wasExactSlashCommand = this.autocompletePrefix.startsWith(\"/\") &&
                        this.getText().trim() === `/''${selected.value}`;
                    const slashPrefix = this.autocompletePrefix.startsWith(\"/\")
                        ? this.autocompletePrefix.slice(1).toLowerCase()
                        : \"\";
                    const matchingSlashCommands = slashPrefix
                        ? this.autocompleteList.filteredItems.filter((item) => item.value.toLowerCase().startsWith(slashPrefix))
                        : [];
                    const isOnlyMatchingSlashCommand = matchingSlashCommands.length === 1 &&
                        matchingSlashCommands[0].value === selected.value;
""" + text[insert_at:]
slash = 'if (this.autocompletePrefix.startsWith("/")'
slash_pos = text.find(slash, confirm_pos)
if slash_pos < 0:
    raise SystemExit(f"slash condition target not found: {path}")
comment = '                        // Fall through to submit'
comment_pos = text.find(comment, slash_pos)
if comment_pos < 0:
    raise SystemExit(f"slash submit marker not found: {path}")
text = text[:comment_pos] + '                        if (!wasExactSlashCommand && !isOnlyMatchingSlashCommand)\n                            return;' + text[comment_pos + len(comment):]
path.write_text(text)
PY
        found=$((found + 1))
      done < <(find "$out" -path '*/node_modules/@earendil-works/pi-tui/dist/components/editor.js' -type f)
      test "$found" -eq 1
    '';

    nativeBuildInputs = [ pkgs.makeBinaryWrapper pkgs.python3 ];

    # pi shells out to ripgrep and fd at runtime.
    postFixup = ''
      wrapProgram "$out/bin/pi" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';

    meta = {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://pi.dev/";
      license = lib.licenses.mit;
      mainProgram = "pi";
    };
  };
  # ── pi agent declarative config ──────────────────────────────────────
  piDir = ".pi/agent";

  autoChatName = {
    enable = true;
  };
  # Only non-secret values belong here. The extension reads ntfy_url at runtime.
  ntfyNotifications = {
    enable = true;
    thresholdSeconds = 60;
    secretsFile = "/home/wanmixc/configuration/secrets.json";
  };
  ntfyConfig = pkgs.writeText "pi-ntfy-config.json" (builtins.toJSON {
    autoNameEnabled = autoChatName.enable;
    notificationsEnabled = ntfyNotifications.enable;
    inherit (ntfyNotifications) thresholdSeconds secretsFile;
  });
  # Keep config and imports adjacent even after Nix/Home Manager symlink resolution.
  ntfyExtension = pkgs.runCommand "pi-ntfy-extension" { } ''
    mkdir -p "$out"
    cp ${./pi/extensions/ntfy}/index.ts "$out/index.ts"
    cp ${./pi/extensions/ntfy}/notify.mjs "$out/notify.mjs"
    cp ${./pi/extensions/ntfy}/auto-name.mjs "$out/auto-name.mjs"
    cp ${./pi/extensions/ntfy}/title-request.mjs "$out/title-request.mjs"
    cp ${ntfyConfig} "$out/config.json"
  '';

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
  permissionConfig = builtins.fromJSON (builtins.readFile ./pi/permission-config.json);

  # Shared with Codex and Claude Code: same secrets key, token file, and wrapper.
  secretsPath = "/home/wanmixc/configuration/secrets.json";
  notionMcpWrapper = import ./codex/notion-mcp-wrapper.nix { inherit pkgs secretsPath; };
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
  home.packages = [ pi-coding-agent ];

  assertions = [
    {
      assertion = builtins.isInt ntfyNotifications.thresholdSeconds && ntfyNotifications.thresholdSeconds >= 0;
      message = "Pi ntfy thresholdSeconds must be a non-negative integer.";
    }
  ];
  home.file."${piDir}/extensions/ntfy" = lib.mkIf (autoChatName.enable || ntfyNotifications.enable) {
    source = ntfyExtension;
  };

  # Keep asynchronous startup update banners out of normal interactive use.
  # Explicit update commands still run normally: `pi update` and
  # `pi update --extensions`.
  programs.fish.functions.pi = {
    body = ''
      if test (count $argv) -eq 0
        env PI_SKIP_VERSION_CHECK=1 /home/wanmixc/.local/state/nix/profiles/profile/bin/pi
      else
        command pi $argv
      end
    '';
  };

  home.activation.piPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    package_source=${./pi/packages}
    target="$HOME/.pi/agent/npm"
    mkdir -p "$target"
    # Files copied from the Nix store are read-only. Replace old manifests
    # atomically so repeated Home Manager switches do not fail on permissions.
    cp "$package_source/package.json" "$target/.package.json.tmp"
    cp "$package_source/package-lock.json" "$target/.package-lock.json.tmp"
    mv -f "$target/.package.json.tmp" "$target/package.json"
    mv -f "$target/.package-lock.json.tmp" "$target/package-lock.json"
    ${pkgs.nodejs}/bin/npm ci --ignore-scripts --omit=dev --prefix "$target"

    # Pi aliases host-provided packages (typebox, @earendil-works/*) to its own
    # copies when loading extensions, so copies installed under $target are
    # never imported. pi-web-access still lists typebox under dependencies,
    # which Pi reports at startup as a package that could bypass the extension
    # loader. Move it to peerDependencies to match Pi's expectation.
    ${pkgs.python3}/bin/python3 ${./pi/packages/fix-host-deps.py} "$target/node_modules"
  '';
  home.file.".pi/agent/AGENTS.md".source = ./agents/AGENTS.md;
  home.file.".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON permissionConfig;
  # Include reference documents, prompts, and scripts alongside each SKILL.md.
  home.file.".pi/agent/skills" = {
    source = ./agents/skills/superpowers;
    recursive = true;
  };
  home.file.".pi/agent/skills/commit-message-id" = {
    source = ./agents/skills/commit-message-id;
    recursive = true;
  };
  home.file.".pi/agent/skills/herdr/SKILL.md".source = ./agents/skills/herdr/SKILL.md;

  home.file."${piDir}/settings.json".text = builtins.toJSON settings;
  home.file."${piDir}/keybindings.json".text = builtins.toJSON {
    # Use Tab for queued follow-up messages while Pi is working. Pi's patched
    # editor gives autocomplete priority when a completion menu is visible.
    "app.message.followUp" = "tab";
  };
  home.file."${piDir}/models.json".text = builtins.toJSON models;
  home.file."${piDir}/mcp.json".text = builtins.toJSON mcpConfig;

  home.activation.validatePiNotionToken = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${./codex/notion_token.py} check ${secretsPath}
  '';

  home.activation.piNotion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${./codex/notion_token.py} write ${secretsPath} "$HOME/.config/runtime-env/notion-token"
  '';
}
