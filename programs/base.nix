{ ... }:
{
  home.username = "wanmixc";
  home.homeDirectory = "/home/wanmixc";
  home.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ (import ../pkgs) ];

  programs.home-manager.enable = true;
}
