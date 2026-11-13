{ pkgs, lib, secretsPath, ... }:
let
  codexPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex";
    version = "0.162.1";

    src = pkgs.fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v0.162.1/codex-package-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "sha256-pnb1ciquDYbL43ZDMvCOqx/didwKMAs61P+/SGEfo+M=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.gnutar
    ];

    buildInputs = [
      pkgs.ncurses
      pkgs.stdenv.cc.cc.lib
    ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      tar -xzf $src
    '';

    installPhase = ''
      mkdir -p $out
      cp -r bin codex-path codex-resources $out/
      cp codex-package.json $out/
      chmod +x \
        $out/bin/codex \
        $out/bin/codex-code-mode-host \
        $out/codex-path/rg

      if [ -f $out/codex-resources/bwrap ]; then
        chmod +x $out/codex-resources/bwrap
      fi
    '';
  };

  notionMcpWrapper = import ../notion/notion-mcp-wrapper.nix { inherit pkgs secretsPath; };

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
        }
      ]
    }
  '';
in
{
  home.packages = with pkgs; [
    codexPkg
    notionMcpWrapper
    bash-language-server
  ];

  home.file.".codex/AGENTS.md" = {
    source = ../AGENTS.md;
    force = true;
  };

  home.activation.validateNotionToken = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${../notion/notion_token.py} check ${secretsPath}
  '';

  home.activation.codexSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    for root in ${../skills} ${./skills}; do
      while IFS= read -r src; do
        rel="''${src#$root/}"
        install -Dm644 "$src" "$HOME/.codex/skills/$rel"
      done < <(find "$root" -type f)
    done

    rm -rf "$HOME/.codex/skills/brainstorming"
  '';

  home.activation.codexPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    while IFS= read -r src; do
      rel="''${src#${./plugins}/}"
      install -Dm644 "$src" "$HOME/plugins/$rel"
      install -Dm644 "$src" "$HOME/.agents/plugins/plugins/$rel"
    done < <(find ${./plugins} -type f)

    install -Dm644 ${codexPluginsMarketplace} "$HOME/.agents/plugins/marketplace.json"
    install -Dm644 ${codexPluginsMarketplace} "$HOME/.agents/plugins/api_marketplace.json"
  '';

  home.activation.codexNotion = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    runtime_env_dir="$HOME/.config/runtime-env"
    token_file="$runtime_env_dir/notion-token"
    config_file="$HOME/.codex/config.toml"

    ${pkgs.python3}/bin/python3 ${../notion/notion_token.py} write ${secretsPath} "$token_file"
    ${pkgs.python3}/bin/python3 ${./reconcile_notion_config.py} \
      "$config_file" \
      "${notionMcpWrapper}/bin/notion-mcp-server"
  '';
}
