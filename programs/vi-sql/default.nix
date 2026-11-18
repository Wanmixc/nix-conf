{ lib, pkgs, ... }:
let
  # vi-sql rewrites config.yaml whenever settings change (theme, options page,
  # security setup), so it cannot be linked read-only from the store. It is
  # seeded once at activation and owned by the app afterwards.
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
in
{
  # Keybindings are only written by vi-sql when the file does not exist, so a
  # read-only link is safe. The partial file overrides individual bindings and
  # the rest keeps the built-in defaults.
  xdg.configFile."vi-sql/keybindings-vim.yaml" = {
    source = ./keybindings-vim.yaml;
    force = true;
  };

  home.activation.viSqlConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    config_dir="$config_home/vi-sql"
    config_file="$config_dir/config.yaml"

    if [ ! -f "$config_file" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$config_dir"
      ${pkgs.coreutils}/bin/install -m 600 ${seedConfig} "$config_file"
    fi
  '';
}
