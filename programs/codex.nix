{ pkgs, lib, ... }:
let
  codexPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex";
    version = "0.141.0";

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v0.141.0/codex-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "sha256-8eK/n6C6brghGdYhtrcbw47dM8BtwoZ7MaAnBSNYlX0=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.gnutar
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
    ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      tar -xzf $src
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp codex-x86_64-unknown-linux-musl $out/bin/codex
      chmod +x $out/bin/codex
    '';
  };

  ensureSupermemoryConfigScript = pkgs.writeShellScript "ensure-supermemory-config.sh" ''
    # BEGIN ensure-supermemory-config
    set -euo pipefail

    config_file="''${1:?config file path is required}"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp)"
    trap '${pkgs.coreutils}/bin/rm -f "$tmp_file"' EXIT

    ${pkgs.gawk}/bin/awk '
      BEGIN {
        in_features = 0
        in_plugin = 0
        features_seen = 0
        plugin_seen = 0
        features_hooks_written = 0
        plugin_enabled_written = 0
      }

      function flush_features() {
        if (in_features && !features_hooks_written) {
          print "hooks = true"
        }
      }

      function flush_plugin() {
        if (in_plugin && !plugin_enabled_written) {
          print "enabled = true"
        }
      }

      /^\[/ {
        flush_features()
        flush_plugin()
        in_features = 0
        in_plugin = 0
      }

      /^\[features\]$/ {
        features_seen = 1
        in_features = 1
        features_hooks_written = 0
        print
        next
      }

      /^\[plugins\."supermemory@wanmixc-local"\]$/ {
        plugin_seen = 1
        in_plugin = 1
        plugin_enabled_written = 0
        print
        next
      }

      {
        if (in_features) {
          if ($0 ~ /^codex_hooks = / || $0 ~ /^hooks = /) {
            if (!features_hooks_written) {
              print "hooks = true"
              features_hooks_written = 1
            }
            next
          }
        }

        if (in_plugin) {
          if ($0 ~ /^enabled = /) {
            if (!plugin_enabled_written) {
              print "enabled = true"
              plugin_enabled_written = 1
            }
            next
          }
        }

        print
      }

      END {
        flush_features()
        flush_plugin()

        if (!features_seen) {
          print ""
          print "[features]"
          print "hooks = true"
        }

        if (!plugin_seen) {
          print ""
          print "[plugins.\"supermemory@wanmixc-local\"]"
          print "enabled = true"
        }
      }
    ' "$config_file" > "$tmp_file"

    ${pkgs.coreutils}/bin/mv "$tmp_file" "$config_file"
    # END ensure-supermemory-config
  '';

  codexSupermemoryPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex-supermemory";
    version = "1.0.5";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/codex-supermemory/-/codex-supermemory-1.0.5.tgz";
      sha256 = "sha256-C6e47JqziIeF7nHr3a1C4D1IQRcc8s/PONUS9OJgYvA=";
    };

    nativeBuildInputs = [
      pkgs.gnutar
    ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      tar -xzf $src
    '';

    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp -r package/dist $out/lib/dist

      cat > $out/bin/codex-supermemory <<EOF
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.nodejs}/bin/node $out/lib/dist/cli.js "\$@"
      EOF
      chmod +x $out/bin/codex-supermemory
    '';
  };

  codexPluginsMarketplace = builtins.toFile "codex-marketplace.json" ''
    {
      "name": "wanmixc-local",
      "interface": {
        "displayName": "Wanmixc Local"
      },
      "plugins": [
        {
          "name": "brainstorming",
          "source": {
            "source": "local",
            "path": "./plugins/brainstorming"
          },
          "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
            "products": ["CODEX"]
          },
          "category": "Productivity"
        },
        {
          "name": "supermemory",
          "source": {
            "source": "local",
            "path": "./plugins/supermemory"
          },
          "policy": {
            "installation": "AVAILABLE",
            "authentication": "ON_INSTALL",
            "products": ["CODEX"]
          },
          "category": "Productivity"
        }
      ]
    }
  '';
in
{
  home.packages = with pkgs; [
    codexPkg
    codexSupermemoryPkg
    bash-language-server
    bun
    gitui
    nodejs
  ];

  home.activation.codexSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    while IFS= read -r src; do
      rel="''${src#${./codex/skills}/}"
      install -Dm644 "$src" "$HOME/.codex/skills/$rel"
    done < <(find ${./codex/skills} -type f)

    rm -rf "$HOME/.codex/skills/brainstorming"
  '';

  home.activation.codexPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    rm -rf \
      "$HOME/plugins/supermemory/skills" \
      "$HOME/.agents/plugins/plugins/supermemory/skills" \
      "$HOME/.codex/plugins/cache/wanmixc-local/supermemory"

    while IFS= read -r src; do
      rel="''${src#${./codex/plugins}/}"
      install -Dm644 "$src" "$HOME/plugins/$rel"
      install -Dm644 "$src" "$HOME/.agents/plugins/plugins/$rel"
    done < <(find ${./codex/plugins} -type f)

    install -Dm644 ${codexPluginsMarketplace} "$HOME/.agents/plugins/marketplace.json"
    install -Dm644 ${codexPluginsMarketplace} "$HOME/.agents/plugins/api_marketplace.json"
  '';

  home.activation.codexSupermemory = lib.hm.dag.entryAfter [ "codexSkills" "codexPlugins" ] ''
    rm -f \
      "$HOME/.codex/supermemory/recall.js" \
      "$HOME/.codex/supermemory/flush.js" \
      "$HOME/.codex/supermemory/search-memory.js" \
      "$HOME/.codex/supermemory/save-memory.js" \
      "$HOME/.codex/supermemory/forget-memory.js" \
      "$HOME/.codex/supermemory/login.js"

    rm -rf \
      "$HOME/.codex/skills/supermemory-search" \
      "$HOME/.codex/skills/supermemory-save" \
      "$HOME/.codex/skills/supermemory-forget" \
      "$HOME/.codex/skills/supermemory-login"

    ${codexSupermemoryPkg}/bin/codex-supermemory install

    config_file="$HOME/.codex/config.toml"

    if [ -f "$config_file" ]; then
      ${ensureSupermemoryConfigScript} "$config_file"
    fi
  '';
}
