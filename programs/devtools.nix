{ inputs, pkgs, ... }:
let
  unstablePkgs = import inputs.nixpkgs-yt-dlp {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
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
    unstablePkgs.sshm
  ];

  programs.direnv.enable = true;
}
