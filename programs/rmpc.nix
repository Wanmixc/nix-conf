{ config, pkgs, pkgsUnstable, ... }:
let
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
    cava
    ffmpeg
    pkgsUnstable.yt-dlp
  ];

  programs.rmpc = {
    enable = true;
    package = pkgsUnstable.rmpc;
    config = rmpcConfig;
  };

  xdg.configFile."rmpc/themes/theme.ron".source = ./rmpc/theme.ron;
}
