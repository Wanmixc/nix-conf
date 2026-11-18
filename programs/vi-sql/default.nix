{ lib, pkgs, ... }:
let
  # vi-sql writes both files back when it loads them (merged config is written
  # to disk), so they cannot be linked read-only from the store. They are
  # seeded as real files at activation and owned by the app afterwards.
  #
  # log.path is pinned because the upstream default is derived from TMPDIR at
  # first launch; if that first launch happens inside a nix-shell, the stale
  # /tmp/nix-shell.* path makes vi-sql abort with "Error creating log file".
  seedConfig = pkgs.writeText "vi-sql-config.yaml" ''
    log:
        path: /tmp/vi-sql.log
    ui:
        mouse: true
    styles:
        nerdFont: true
        currentStyle: catppuccin.yaml
  '';

  seedKeybindings = ./keybindings-vim.yaml;
in
{
  # Runs after linkGeneration so a stale store symlink is removed by Home
  # Manager before the real file is seeded.
  home.activation.viSqlConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    config_dir="$config_home/vi-sql"

    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

    if [ ! -f "$config_dir/config.yaml" ]; then
      ${pkgs.coreutils}/bin/install -m 600 ${seedConfig} "$config_dir/config.yaml"
    fi

    keybindings="$config_dir/keybindings-vim.yaml"
    if [ -L "$keybindings" ] || [ ! -f "$keybindings" ]; then
      ${pkgs.coreutils}/bin/rm -f "$keybindings"
      ${pkgs.coreutils}/bin/install -m 600 ${seedKeybindings} "$keybindings"
    fi
  '';
}
