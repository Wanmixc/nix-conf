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
    (python3.withPackages (pythonPackages: [ pythonPackages.mutagen ]))
    croc
    neossh
  ];

  programs.direnv.enable = true;
}
