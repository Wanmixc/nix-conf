{ pkgs, ... }:
let
  deepseekPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "deepseek-tui";
    version = "0.8.58";

    src = pkgs.fetchurl {
      url = "https://github.com/Hmbown/CodeWhale/releases/download/v0.8.58/codewhale-linux-x64.tar.gz";
      sha256 = "sha256-M4iz0w1IpQXTstn0G49Y8xUQ+FDBY7Pkr6gfCw2w4DY=";
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

      codewhale_bin="$(find . -type f -name codewhale | head -n1)"
      codewhale_tui_bin="$(find . -type f -name codewhale-tui | head -n1)"

      test -n "$codewhale_bin"
      test -n "$codewhale_tui_bin"

      install -m755 "$codewhale_bin" "$out/bin/codewhale"
      install -m755 "$codewhale_tui_bin" "$out/bin/codewhale-tui"

      ln -s codewhale "$out/bin/deepseek"
      ln -s codewhale-tui "$out/bin/deepseek-tui"
    '';
  };
in
{
  home.packages = [ deepseekPkg ];

  home.sessionVariables = {
    DEEPSEEK_TUI_BIN = "${deepseekPkg}/bin/deepseek-tui";
  };

  home.file = {
    ".deepseek/skills/commit-message-id/SKILL.md".source =
      ./agents/skills/commit-message-id/SKILL.md;
    ".deepseek/skills/skill-creator/SKILL.md".source =
      ./deepseek/skills/skill-creator/SKILL.md;
  };
}
