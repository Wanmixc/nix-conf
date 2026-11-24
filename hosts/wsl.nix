{ pkgs, ... }:
{
  imports = [
    ../profiles/common.nix
    ../profiles/agents.nix
  ];

  home.packages = [ pkgs.noto-fonts-color-emoji ];
}
