{ pkgs, lib, ... }:
let
  secretsPath = /home/wanmixc/configuration/secrets.json;
  secrets =
    if builtins.pathExists secretsPath
    then builtins.fromJSON (builtins.readFile secretsPath)
    else { };
  githubToken = secrets.github_token or "";
in
{
  home.packages = [
    pkgs.git
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
    }
    // lib.optionalAttrs (githubToken != "") {
      url."https://oauth2:${githubToken}@github.com/".insteadOf = [
        "https://github.com/"
        "git@github.com:"
        "ssh://git@github.com/"
      ];
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
