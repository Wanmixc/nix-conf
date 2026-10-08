{ config, inputs, pkgs, ... }:
let
  ytPkgs = import inputs.nixpkgs-yt-dlp {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  youtubeCacheDir = "${config.xdg.userDirs.music}/.rmpc-youtube";
  rmpcConfig = builtins.replaceStrings
    [
      "address: \"127.0.0.1:6600\","
      "cache_dir: None,"
    ]
    [
      "address: \"/run/user/1000/mpd/socket\","
      "cache_dir: Some(\"${youtubeCacheDir}\"),"
    ]
    (builtins.readFile ./rmpc/config.ron);
in
{
  home.packages = with pkgs; [
    ffmpeg
    ytPkgs.yt-dlp
  ];

  programs.rmpc = {
    enable = true;
    package = ytPkgs.rmpc;
    config = rmpcConfig;
  };

  xdg.configFile."rmpc/themes/theme.ron".source = ./rmpc/theme.ron;
}
