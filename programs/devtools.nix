{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    direnv
    eza
    ripgrep
    shfmt
    unzip
    zoxide
    atac
    bubblewrap
    fzf
    jq
    speedtest-cli
    python3
  ];

  programs.direnv.enable = true;
}
