{
  description = "Wanmixc multi-machine Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-yt-dlp.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    herdr.url = "github:ogulcancelik/herdr/v0.7.4";
    herdr.inputs.nixpkgs.follows = "nixpkgs";

    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs = { nixpkgs, home-manager, herdr, ... }@inputs:
    let
      system = "x86_64-linux";
      mkHome = module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = { inherit herdr inputs system; };

          modules = [ module ];
        };
    in
    {
      homeConfigurations = {
        "wanmixc-cachyos-nix" = mkHome ./hosts/cachyos-nix.nix;
        "wanmixc-wsl" = mkHome ./hosts/wsl.nix;
        "wanmixc-vps" = mkHome ./hosts/vps.nix;
      };
    };
}
