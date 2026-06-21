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
    bash-language-server
    bun
    gitui
  ];

  home.activation.codexSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    while IFS= read -r src; do
      rel="''${src#${./codex/skills}/}"
      install -Dm644 "$src" "$HOME/.codex/skills/$rel"
    done < <(find ${./codex/skills} -type f)

    rm -rf "$HOME/.codex/skills/brainstorming"
  '';

  home.activation.codexPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    while IFS= read -r src; do
      rel="''${src#${./codex/plugins}/}"
      install -Dm644 "$src" "$HOME/plugins/$rel"
    done < <(find ${./codex/plugins} -type f)

    install -Dm644 ${codexPluginsMarketplace} "$HOME/.agents/plugins/marketplace.json"
    install -Dm644 ${codexPluginsMarketplace} "$HOME/.agents/plugins/api_marketplace.json"
  '';
}
