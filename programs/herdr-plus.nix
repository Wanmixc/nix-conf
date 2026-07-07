{ pkgs, lib, ... }:
let
  # Herdr Plus — a first-class herdr plugin (Projects + Quick Actions) by
  # Cloudmanic Labs.  https://github.com/cloudmanic/herdr-plus
  #
  # Installed declaratively instead of via `herdr plugin install`:
  #   1. Build the plugin binary from a pinned source with buildGoModule and
  #      assemble a plugin_root ($out) holding herdr-plugin.toml + bin/herdr-plus
  #      (the manifest's entrypoints run `./bin/herdr-plus …` relative to it).
  #   2. Register it by writing herdr's plugin registry (~/.config/herdr/
  #      plugins.json) on activation. herdr loads that JSON on startup; a
  #      `local`-kind source needs no managed-path validation, so pointing it at
  #      the read-only /nix/store plugin_root is valid.
  #   3. Manage the plugin's own config declaratively under ~/.config/herdr-plus.
  version = "0.1.16";

  # herdr-plus's go.mod requires Go 1.26.x; the default nixpkgs go is older.
  buildGo126Module = pkgs.buildGoModule.override { go = pkgs.go_1_26; };

  herdr-plus = buildGo126Module {
    pname = "herdr-plus";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "cloudmanic";
      repo = "herdr-plus";
      rev = "v${version}";
      hash = "sha256-WWu83LMBB9V0OFF1g4qmIkoTqOgXgWeNynv4Fk84xas=";
    };

    # Refresh alongside `version`: set to lib.fakeHash, build once, copy the
    # "got:" hash Nix prints back here.
    vendorHash = "sha256-im2gPhLarMf1w/8rhxbOe9EhUdvseffukT9tqU4EEXI=";

    # One upstream test (TestIsInsideGitWorkTree) asserts the CWD is not inside
    # a git work tree, which is environment-dependent and fails in the Nix
    # sandbox's /build dir. The binary itself builds fine; skip the check phase.
    doCheck = false;

    # `go build .` yields ./bin/herdr-plus (module basename). We also need the
    # manifest at the plugin_root so herdr can read the entrypoints and so the
    # relative `./bin/herdr-plus` commands resolve.
    postInstall = ''
      install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
    '';

    meta = {
      description = "Herdr plugin: Projects (declarative workspace templates) and Quick Actions";
      homepage = "https://github.com/cloudmanic/herdr-plus";
      license = lib.licenses.mit;
      mainProgram = "herdr-plus";
    };
  };

  pluginId = "cloudmanic.herdr-plus";
in
{
  # Register the plugin in herdr's on-disk registry. herdr's registry is a JSON
  # array at ~/.config/herdr/plugins.json (data_dir == config_dir for the
  # default session). We parse the store manifest and merge one entry, leaving
  # any other installed plugins untouched. Manifest-driven so it tracks the
  # pinned plugin version automatically; unknown fields are ignored by herdr.
  home.activation.herdrPlusRegister = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 - "${herdr-plus}" "${pluginId}" "$HOME/.config/herdr/plugins.json" <<'PY'
import json, os, sys, tomllib

plugin_root, plugin_id, registry_path = sys.argv[1], sys.argv[2], sys.argv[3]
manifest_path = os.path.join(plugin_root, "herdr-plugin.toml")

with open(manifest_path, "rb") as f:
    m = tomllib.load(f)

# Transform the manifest into a herdr InstalledPluginInfo entry. Field names in
# the [[actions]]/[[events]]/[[panes]]/[[link_handlers]] tables match herdr's
# schema 1:1, so they copy across verbatim; only the top-level `id` is renamed.
entry = {
    "plugin_id": m["id"],
    "name": m.get("name", plugin_id),
    "version": m.get("version", ""),
    "min_herdr_version": m.get("min_herdr_version", ""),
    "manifest_path": manifest_path,
    "plugin_root": plugin_root,
    "enabled": True,
    "source": {"kind": "local"},
}
if "description" in m:
    entry["description"] = m["description"]
if "platforms" in m:
    entry["platforms"] = m["platforms"]
for key in ("actions", "events", "panes", "link_handlers"):
    if m.get(key):
        entry[key] = m[key]

os.makedirs(os.path.dirname(registry_path), exist_ok=True)
try:
    with open(registry_path, encoding="utf-8") as f:
        plugins = json.load(f)
    if not isinstance(plugins, list):
        plugins = []
except (FileNotFoundError, json.JSONDecodeError):
    plugins = []

# Replace any existing entry for this plugin, preserve the rest.
plugins = [p for p in plugins if p.get("plugin_id") != plugin_id]
plugins.append(entry)

with open(registry_path, "w", encoding="utf-8") as f:
    json.dump(plugins, f, indent=2)
    f.write("\n")
PY
  '';

  # Declarative Herdr Plus config. herdr-plus reads every *.toml under its
  # MANAGED config dir: ~/.config/herdr/plugins/config/<plugin-id>/{projects,
  # quick-actions}/ — NOT ~/.config/herdr-plus/. Paths below use ''${pluginId}
  # so they can't drift from the registered id.
  #
  #   projects/      — workspace templates: a working_dir + ordered tabs, each
  #                    optionally split into panes. Fuzzy-picked (prefix+p) to
  #                    spin up the whole workspace at once.
  #   quick-actions/ — one-off launchers. `command` is a Go text/template
  #                    rendered against the launch context ({{.WorkDir}} = the
  #                    directory you launched from) then run in a shell.

  # Quick Action: drop into a shell in the launch directory.
  xdg.configFile."herdr/plugins/config/${pluginId}/quick-actions/shell-here.toml".text = ''
    name = "Shell here"
    description = "Open a shell in the directory you launched from"
    type = "command"
    command = "cd {{.WorkDir}} && exec $SHELL"
  '';

  # Project: this nix configuration repo. Opens 3 tabs; the "edit" tab is split
  # into an editor pane + a file-tree pane. Rename/duplicate this file per
  # project. Schema fields:
  #   name / description / group  — shown in the picker (group clusters entries)
  #   working_dir                 — ~ and $VARS expand; cwd for every tab
  #   [[tabs]] name / command     — a tab; command runs on startup (omit = shell)
  #   [[tabs.panes]] label/command/split — split a tab; split = up|down|left|right
  xdg.configFile."herdr/plugins/config/${pluginId}/projects/configuration.toml".text = ''
    name = "Nix Config"
    description = "Nix home-manager config"
    group = "Dev"
    working_dir = "~/configuration"

    [[tabs]]
    name = "shell"
  '';

  # Project: my_budget — .NET backend + pnpm frontend monorepo (direnv/flake
  # dev shell). Server tabs use `direnv exec .` so pnpm/dotnet are on PATH even
  # though the tab command runs before the interactive direnv hook fires.
  xdg.configFile."herdr/plugins/config/${pluginId}/projects/my-budget.toml".text = ''
    name = "my_budget"
    description = "my budget project"
    group = "Dev"
    working_dir = "~/Extra/Development/my_budget"

    [[tabs]]
    name = "editor FE"
    command = "cd frontend; nvim"

    [[tabs]]
    name = "editor BE"
    command = "cd backend; nvim"

    # Dedicated servers tab: frontend dev server + backend split beside it.
    [[tabs]]
    name = "servers"

    [[tabs.panes]]
    label = "pnpm dev"
    command = "cd frontend; direnv exec . pnpm dev"

    [[tabs.panes]]
    label = "dotnet"
    command = "cd backend; direnv exec . dotnet run --urls http://localhost:5002"
    split = "right"

    [[tabs]]
    name = "git"
    command = "gitui"

    [[tabs]]
    name = "atac"
    command = "atac"

    [[tabs]]
    name = "codex"
    command = "codex"

    [[tabs]]
    name = "dummy api"
    command = "cd ~/Extra/Development/dummy_api/target/release; ./dummy_api"

    [[tabs]]
    name = "cheatsheet nvim"
    command = "bat ~/configuration/programs/nvim/CHEATSHEET.md"
  '';
}
