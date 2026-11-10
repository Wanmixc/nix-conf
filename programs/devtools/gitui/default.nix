{ pkgs, ... }:
{
  home.packages = [ pkgs.gitui ];

  # hjkl movement, help moved to '?'. Arrow keys keep working.
  # Configured via xdg.configFile rather than programs.gitui so that no
  # theme.ron is written: the Home Manager module's default theme uses the
  # pre-0.28 unwrapped format, which gitui 0.28 rejects at startup.
  xdg.configFile."gitui/key_bindings.ron".source = ./key_bindings.ron;
}
