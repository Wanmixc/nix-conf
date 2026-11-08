{
  description = "Wanmixc multi-machine Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    herdr.url = "github:ogulcancelik/herdr/v0.7.4";
    herdr.inputs.nixpkgs.follows = "nixpkgs";

    hermes-agent.url = "github:NousResearch/hermes-agent";
  };

  outputs = { nixpkgs, home-manager, herdr, ... }@inputs:
    let
      system = "x86_64-linux";
      secretsPath = "/home/wanmixc/configuration/secrets.json";
      pkgsUnstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      mkHome = module:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = { inherit herdr inputs system secretsPath pkgsUnstable; };

          modules = [ module ];
        };
    in
    {
      packages.${system} =
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (import ./pkgs) ];
          };
        in
        {
          inherit (pkgs) neossh notion-mcp-server pi-coding-agent;
        };

      homeConfigurations = {
        "wanmixc-cachyos-nix" = mkHome ./hosts/cachyos-nix.nix;
        "wanmixc-wsl" = mkHome ./hosts/wsl.nix;
        "wanmixc-vps" = mkHome ./hosts/vps.nix;
      };
    };
}
