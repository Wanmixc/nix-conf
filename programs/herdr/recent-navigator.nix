{ pkgs, lib, ... }:
let
  version = "0.6.2";
  pluginId = "beyondlex.herdr-recent-navigator";

  source = pkgs.fetchFromGitHub {
    owner = "beyondlex";
    repo = "herdr-recent-navigator";
    rev = "79cd2feaa8e493da32c230950545ec4c5ce2743b";
    hash = "sha256-E1FEqTSgCjnhW44H8EFkA9t8Qmcaf6wMJ3H292x5/vs=";
  };

  herdr-recent-navigator = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-recent-navigator";
    inherit version;

    src = source;
    cargoHash = "sha256-I2cMQLQRO4TL6+BNWXwTVoWItcWAXUnjcLRh4QjMVKk=";

    postInstall = ''
      install -Dm644 herdr-plugin.toml "$out/herdr-plugin.toml"
      substituteInPlace "$out/herdr-plugin.toml" \
        --replace-fail "./target/release/herdr-recent-navigator" "./bin/herdr-recent-navigator"
    '';

    meta = {
      description = "Recent workspaces, tabs, panes, and AI agents switcher for Herdr";
      homepage = "https://github.com/beyondlex/herdr-recent-navigator";
      license = lib.licenses.mit;
      mainProgram = "herdr-recent-navigator";
    };
  };
in
{
  home.activation.herdrRecentNavigatorRegister = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 - "${herdr-recent-navigator}" "${pluginId}" "$HOME/.config/herdr/plugins.json" <<'PY'
import json
import os
import sys
import tomllib

plugin_root, plugin_id, registry_path = sys.argv[1], sys.argv[2], sys.argv[3]
manifest_path = os.path.join(plugin_root, "herdr-plugin.toml")

with open(manifest_path, "rb") as f:
    manifest = tomllib.load(f)

entry = {
    "plugin_id": manifest["id"],
    "name": manifest.get("name", plugin_id),
    "version": manifest.get("version", ""),
    "min_herdr_version": manifest.get("min_herdr_version", ""),
    "manifest_path": manifest_path,
    "plugin_root": plugin_root,
    "enabled": True,
    "source": {"kind": "local"},
}
if "description" in manifest:
    entry["description"] = manifest["description"]
if "platforms" in manifest:
    entry["platforms"] = manifest["platforms"]
for key in ("actions", "events", "panes", "link_handlers"):
    if manifest.get(key):
        entry[key] = manifest[key]

os.makedirs(os.path.dirname(registry_path), exist_ok=True)
try:
    with open(registry_path, encoding="utf-8") as f:
        plugins = json.load(f)
    if not isinstance(plugins, list):
        plugins = []
except (FileNotFoundError, json.JSONDecodeError):
    plugins = []

plugins = [plugin for plugin in plugins if plugin.get("plugin_id") != plugin_id]
plugins.append(entry)

with open(registry_path, "w", encoding="utf-8") as f:
    json.dump(plugins, f, indent=2)
    f.write("\n")
PY
  '';
}
