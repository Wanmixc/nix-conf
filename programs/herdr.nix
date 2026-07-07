{ herdr, pkgs, ... }:
let
  herdrPackage = herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [ herdrPackage ];

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [update]
    version_check = false

    [terminal]
    shell_mode = "auto"
    new_cwd = "follow"

    [keys]
    prefix = "ctrl+a"
    detach = "prefix+q"
    reload_config = "prefix+r"
    new_tab = "prefix+c"
    switch_tab = "prefix+1..9"
    copy_mode = "prefix+["

    split_vertical = "prefix+|"
    split_horizontal = "prefix+minus"

    focus_pane_left = "prefix+h"
    focus_pane_down = "prefix+j"
    focus_pane_up = "prefix+k"
    focus_pane_right = "prefix+l"

    navigate_pane_left = "h"
    navigate_pane_down = "j"
    navigate_pane_up = "k"
    navigate_pane_right = "l"

    swap_pane_left = "prefix+shift+h"
    swap_pane_down = "prefix+shift+j"
    swap_pane_up = "prefix+shift+k"
    swap_pane_right = "prefix+shift+l"

    close_pane = "prefix+x"
    zoom = "prefix+z"
    resize_mode = "prefix+shift+r"
    toggle_sidebar = "prefix+b"

    [theme]
    name = "terminal"

    [ui]
    mouse_capture = true
    pane_borders = true
    pane_gaps = true
    confirm_close = true
    prompt_new_tab_name = false
  '';
}
