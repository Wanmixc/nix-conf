{ lib, ... }:
let
  hostname = lib.strings.removeSuffix "\n" (builtins.readFile /etc/hostname);
  osrelease =
    if builtins.pathExists /proc/sys/kernel/osrelease
    then builtins.readFile /proc/sys/kernel/osrelease
    else "";
  isWsl =
    lib.hasInfix "WSL" osrelease ||
    lib.hasInfix "Microsoft" osrelease ||
    builtins.getEnv "ubuntu" != "";
  hostModule =
    if isWsl then
      ./hosts/wsl.nix
    else if hostname == "Wan-PC" then
      ./hosts/cachyos-nix.nix
    else
      throw ''
        Unsupported non-flake host "${hostname}".
        Use an explicit flake target instead:
          home-manager switch --flake .#wanmixc-vps
          home-manager switch --flake .#wanmixc-wsl
          home-manager switch --flake .#wanmixc-cachyos-nix
      '';
in
{
  imports = [
    hostModule
  ];
}
