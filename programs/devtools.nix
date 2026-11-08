{ pkgs, pkgsUnstable, ... }:
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
    (pkgs.callPackage ./neossh/package.nix { })
  ];

  programs.direnv.enable = true;
}
