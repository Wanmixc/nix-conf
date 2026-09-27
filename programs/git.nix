{ pkgs, ... }:
{
  home.packages = [
    pkgs.git
    pkgs.gh
    pkgs.openssh
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "wanmixc";
        email = "wanmixc@gmail.com";
      };
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      credential.helper = "!$HOME/.config/runtime-env/github-credential-helper";
    };
  };

  programs.delta = {
    enable = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
    };
  };
}
