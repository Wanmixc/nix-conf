{
  description = "Wanmixc multi-machine Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    herdr.url = "github:ogulcancelik/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs";

    # Hermes Agent ships its own flake (uv2nix build pinned to nixos-unstable).
    # Deliberately NOT `follows`-ing our nixpkgs: overriding its pin would break
    # the uv2nix/pyproject build and lose upstream binary-cache hits.
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

          # `herdr` is consumed directly by programs/herdr.nix; `inputs` and
          # `system` are consumed by programs/hermes.nix (hermes-agent flake).
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
