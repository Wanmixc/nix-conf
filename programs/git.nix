{ pkgs, lib, ... }:
let
  secretsPath = /home/wanmixc/.config/home-manager/secrets.json;
  secrets =
    if builtins.pathExists secretsPath
    then builtins.fromJSON (builtins.readFile secretsPath)
    else { };
  githubToken = secrets.github_token or "";
  gitConfigText =
    let
      githubSection = lib.optionalString (githubToken != "") ''
[url "https://oauth2:${githubToken}@github.com"]
	insteadOf = https://github.com

'';
    in
    githubSection
    + ''
[push]
	autoSetupRemote = true
	default = current

[merge]
	conflictstyle = diff3

[diff]
	colorMoved = default

[user]
	email = wanmixc@gmail.com
	name = wanmixc
'';
in
{
  home.packages = [ pkgs.git ];

  xdg.configFile."git/config".text = gitConfigText;

  programs.delta = {
    enable = true;
    options = {
      line-numbers = true;
      side-by-side = true;
      navigate = true;
    };
  };
}
