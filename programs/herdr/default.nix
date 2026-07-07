{ herdr, pkgs, ... }:
let
  herdrPackage = herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ herdrPackage ];

  # Config lives in ./config.toml (raw TOML, edited directly).
  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
