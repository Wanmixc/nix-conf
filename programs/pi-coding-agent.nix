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
    nativeBuildInputs = [ pkgs.jq ];
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
  '';

  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version src;

    npmDepsHash = "sha256-FfwODI+m5Jts0PrjA9mFa+Mp9QT17/ejixg84RGXGe4=";

    # The published tarball already ships a built dist/, so there is nothing
    # to compile; only install the pinned dependencies.
    dontNpmBuild = true;
    npmFlags = [ "--ignore-scripts" "--omit=dev" ];

    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

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
    defaultModel = "deepseek/deepseek-v4-pro";
    defaultThinkingLevel = "medium";
    packages = ["npm:pi-web-access" "npm:@gotgenes/pi-permission-system" "npm:pi-zentui"];
  };

  models = {
    providers = {
      mimo = {
        baseUrl = "https://api.xkiro.com/v1";
        api = "openai-completions";
        apiKey = "$MIMO_API_KEY";
        models = [
          {
            id = "deepseek/deepseek-v4-pro";
            name = "deepseek/deepseek-v4-pro";
          }
        ];
      };
    };
  };
  permissionConfig = builtins.fromJSON (builtins.readFile ./pi/permission-config.json);
in
{
  home.packages = [ pi-coding-agent ];
  home.activation.piPackages = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    package_source=${./pi/packages}
    target="$HOME/.pi/agent/npm"
    mkdir -p "$target"
    cp "$package_source/package.json" "$target/package.json"
    cp "$package_source/package-lock.json" "$target/package-lock.json"
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
  home.file."${piDir}/models.json".text = builtins.toJSON models;
}
