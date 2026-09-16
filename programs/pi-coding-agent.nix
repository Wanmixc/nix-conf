{ pkgs, lib, ... }:
let
  version = "0.84.1";

  # sha512 SRI integrity for @earendil-works workspace tarballs.
  # The published npm-shrinkwrap.json omits these, which breaks `npm ci`
  # under Nix. Values come from `npm view @earendil-works/<pkg>@<version>
  # dist.integrity` and must be refreshed together with `version`.
  workspaceIntegrity = {
    pi-ai = "sha512-wMsAdJMxuNri08vLqTyYVI201DQQezGhPSTkzYsHdw5dYX3rCNwEmSvpaAwhi7ELKI/2tE/CEgSWg/6iRxSgdQ==";
    pi-agent-core = "sha512-evyzXYWCLQGmcaBYHlmSku02r8qoN4SGI60GZABo6iV+H+nqX+P9ud8fEZ4GmRq9mUSREvvfX+w9dA9ThF9C6w==";
    pi-client = "sha512-/V5hGHE4Zq+jG0GtwIB9PyBUOGd6gBLZ7lkQYFKchKnxYHeH3rmWC5xw4kpnZKKBuBuFTdLVbU9vEjlAGMMb2A==";
    pi-protocol = "sha512-Ox1pciyeSPGEEUcxvR0/dJcrY7C6hrEGA8y71rOsvSIUlXN1Cbp/be/eoL71OGDBk5O97TeQPfWN6Ju/2Ehjww==";
    pi-telemetry = "sha512-180/xGJtsq7IoR3p9EKWjRd0e9M4DkxInhlo9xyD7prDC7Qrhqq+nhvwrW0lFjPfXcEI2FSHmGCSyvSJE9GsaQ==";
    pi-tui = "sha512-udeXFbgEhJ6JiB0uguwNVNkDy2FENfmtQwPcY+/iJ8GWeq18wkal1tKqa5YyeH0IqtX1vG0cGh8zfSYzyzVuLA==";
  };

  rawSrc = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-ppoYWWAX6RlV/Q/Wd75p+rW26gHVsGIHvO407hUivCA=";
  };

  # Unpack the npm tarball, backfill the missing workspace integrities so both
  # dependency fetching and `npm ci` see a valid lockfile, and drop the
  # devDependencies (which the published shrinkwrap omits) since dist/ is
  # already built and we never compile.
  src = pkgs.runCommand "pi-coding-agent-src-${version}" {
    nativeBuildInputs = [ pkgs.jq pkgs.python3 ];
  } ''
    mkdir -p "$out"
    tar xzf ${rawSrc} --strip-components=1 -C "$out"
    cd "$out"
    jq '
        .packages["node_modules/@earendil-works/pi-ai"].integrity = "${workspaceIntegrity.pi-ai}"
      | .packages["node_modules/@earendil-works/pi-agent-core"].integrity = "${workspaceIntegrity.pi-agent-core}"
      | .packages["node_modules/@earendil-works/pi-client"].integrity = "${workspaceIntegrity.pi-client}"
      | .packages["node_modules/@earendil-works/pi-protocol"].integrity = "${workspaceIntegrity.pi-protocol}"
      | .packages["node_modules/@earendil-works/pi-telemetry"].integrity = "${workspaceIntegrity.pi-telemetry}"
      | .packages["node_modules/@earendil-works/pi-tui"].integrity = "${workspaceIntegrity.pi-tui}"
    ' npm-shrinkwrap.json > npm-shrinkwrap.json.tmp
    mv npm-shrinkwrap.json.tmp npm-shrinkwrap.json
    jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json

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

    npmDepsHash = "sha256-FfwODI+m5Jts0PrjA9mFa+Mp9QT17/ejixg84RGXGe4=";

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

  settings = {
    theme = "dark";
    quietStartup = true;
    enableInstallTelemetry = false;
    collapseChangelog = true;
    defaultProvider = "mimo";
    defaultModel = "deepseek/deepseek-v4.1-flash:free";
    defaultThinkingLevel = "medium";
    # These packages are installed declaratively below. Pin their Pi sources to
    # the same versions so Pi does not run an online update check at startup.
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
            id = "deepseek/deepseek-v4.1-flash:free";
            name = "qdeepseek/deepseek-v4.1-flash:free";
          }
        ];
      };
    };
  };
  permissionConfig = builtins.fromJSON (builtins.readFile ./pi/permission-config.json);
in
{
  home.packages = [ pi-coding-agent ];

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
  '';
  home.file.".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;
  home.file.".pi/agent/extensions/pi-permission-system/config.json".text = builtins.toJSON permissionConfig;
  home.file.".pi/agent/skills/brainstorming/SKILL.md".source = ./codex/skills/superpowers/brainstorming/SKILL.md;
  home.file.".pi/agent/skills/dispatching-parallel-agents/SKILL.md".source = ./codex/skills/superpowers/dispatching-parallel-agents/SKILL.md;
  home.file.".pi/agent/skills/executing-plans/SKILL.md".source = ./codex/skills/superpowers/executing-plans/SKILL.md;
  home.file.".pi/agent/skills/finishing-a-development-branch/SKILL.md".source = ./codex/skills/superpowers/finishing-a-development-branch/SKILL.md;
  home.file.".pi/agent/skills/receiving-code-review/SKILL.md".source = ./codex/skills/superpowers/receiving-code-review/SKILL.md;
  home.file.".pi/agent/skills/requesting-code-review/SKILL.md".source = ./codex/skills/superpowers/requesting-code-review/SKILL.md;
  home.file.".pi/agent/skills/subagent-driven-development/SKILL.md".source = ./codex/skills/superpowers/subagent-driven-development/SKILL.md;
  home.file.".pi/agent/skills/systematic-debugging/SKILL.md".source = ./codex/skills/superpowers/systematic-debugging/SKILL.md;
  home.file.".pi/agent/skills/test-driven-development/SKILL.md".source = ./codex/skills/superpowers/test-driven-development/SKILL.md;
  home.file.".pi/agent/skills/using-git-worktrees/SKILL.md".source = ./codex/skills/superpowers/using-git-worktrees/SKILL.md;
  home.file.".pi/agent/skills/using-superpowers/SKILL.md".source = ./codex/skills/superpowers/using-superpowers/SKILL.md;
  home.file.".pi/agent/skills/verification-before-completion/SKILL.md".source = ./codex/skills/superpowers/verification-before-completion/SKILL.md;
  home.file.".pi/agent/skills/writing-plans/SKILL.md".source = ./codex/skills/superpowers/writing-plans/SKILL.md;
  home.file.".pi/agent/skills/writing-skills/SKILL.md".source = ./codex/skills/superpowers/writing-skills/SKILL.md;
  home.file.".pi/agent/skills/commit-message-id/SKILL.md".source = ./codex/skills/commit-message-id/SKILL.md;
  home.file.".pi/agent/skills/herdr/SKILL.md".source = ./pi/skills/herdr/SKILL.md;

  home.file."${piDir}/settings.json".text = builtins.toJSON settings;
  home.file."${piDir}/keybindings.json".text = builtins.toJSON {
    # Use Tab for queued follow-up messages while Pi is working. Pi's patched
    # editor gives autocomplete priority when a completion menu is visible.
    "app.message.followUp" = "tab";
  };
  home.file."${piDir}/models.json".text = builtins.toJSON models;
}
