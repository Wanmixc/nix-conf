{ ... }:
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    theme = {
      mgr = {
        cwd = { fg = "#a6e3f1"; bold = true; };
        hovered = { fg = "#89cde1"; bg = "#263842"; bold = true; };
        preview_hovered = { fg = "#89cde1"; bg = "#263842"; bold = true; };
        find_keyword = { fg = "#fcb38a"; italic = true; };
        find_position = { fg = "#89cde1"; bg = "reset"; italic = true; };
        symlink_target = { fg = "#a6e3f1"; };
        marker_copied = { fg = "#a6d189"; bg = "#a6d189"; };
        marker_cut = { fg = "#e78284"; bg = "#e78284"; };
        marker_marked = { fg = "#a6e3f1"; bg = "#a6e3f1"; };
        marker_selected = { fg = "#89cde1"; bg = "#89cde1"; };
        count_copied = { fg = "#1b161d"; bg = "#a6d189"; };
        count_cut = { fg = "#1b161d"; bg = "#e78284"; };
        count_selected = { fg = "#1b161d"; bg = "#89cde1"; };
        border_symbol = "|";
        border_style = { fg = "#514254"; };
      };

      indicator = {
        parent = { fg = "#514254"; };
        current = { fg = "#89cde1"; };
        preview = { fg = "#a6e3f1"; };
        padding = { open = ""; close = ""; };
      };

      tabs = {
        active = { fg = "#1b161d"; bg = "#89cde1"; bold = true; };
        inactive = { fg = "#d5c0d7"; bg = "#2d252f"; };
        sep_inner = { open = ""; close = ""; };
        sep_outer = { open = " "; close = " "; };
      };

      mode = {
        normal_main = { fg = "#1b161d"; bg = "#89cde1"; bold = true; };
        normal_alt = { fg = "#89cde1"; bg = "#2d252f"; };
        select_main = { fg = "#1b161d"; bg = "#a6e3f1"; bold = true; };
        select_alt = { fg = "#a6e3f1"; bg = "#2d252f"; };
        unset_main = { fg = "#1b161d"; bg = "#fcb38a"; bold = true; };
        unset_alt = { fg = "#fcb38a"; bg = "#2d252f"; };
      };

      status = {
        overall = { fg = "#d5c0d7"; bg = "#1b161d"; };
        sep_left = { open = ""; close = ""; };
        sep_right = { open = ""; close = ""; };
        perm_type = { fg = "#89cde1"; };
        perm_read = { fg = "#a6d189"; };
        perm_write = { fg = "#fcb38a"; };
        perm_exec = { fg = "#e78284"; };
        perm_sep = { fg = "#514254"; };
        progress_label = { fg = "#d5c0d7"; bold = true; };
        progress_normal = { fg = "#89cde1"; bg = "#2d252f"; };
        progress_error = { fg = "#e78284"; bg = "#2d252f"; };
      };

      which = {
        cols = 3;
        mask = { bg = "#1b161d"; };
        cand = { fg = "#89cde1"; bold = true; };
        rest = { fg = "#a6e3f1"; };
        desc = { fg = "#d5c0d7"; };
        separator = " -> ";
        separator_style = { fg = "#514254"; };
      };

      confirm = {
        border = { fg = "#514254"; };
        title = { fg = "#89cde1"; bold = true; };
        body = { fg = "#d5c0d7"; };
        list = { fg = "#a6e3f1"; };
        btn_yes = { fg = "#1b161d"; bg = "#89cde1"; bold = true; };
        btn_no = { fg = "#d5c0d7"; bg = "#2d252f"; };
        btn_labels = [ "Yes" "No" ];
      };

      spot = {
        border = { fg = "#514254"; };
        title = { fg = "#89cde1"; bold = true; };
        tbl_col = { fg = "#a6e3f1"; };
        tbl_cell = { fg = "#d5c0d7"; };
      };

      notify = {
        title_info = { fg = "#89cde1"; bold = true; };
        title_warn = { fg = "#fcb38a"; bold = true; };
        title_error = { fg = "#e78284"; bold = true; };
      };

      pick = {
        border = { fg = "#514254"; };
        active = { fg = "#1b161d"; bg = "#89cde1"; bold = true; };
        inactive = { fg = "#d5c0d7"; };
      };

      input = {
        border = { fg = "#514254"; };
        title = { fg = "#89cde1"; bold = true; };
        value = { fg = "#d5c0d7"; };
        selected = { fg = "#1b161d"; bg = "#89cde1"; };
      };

      cmp = {
        border = { fg = "#514254"; };
        active = { fg = "#1b161d"; bg = "#89cde1"; bold = true; };
        inactive = { fg = "#d5c0d7"; };
      };

      tasks = {
        border = { fg = "#514254"; };
        title = { fg = "#89cde1"; bold = true; };
        hovered = { fg = "#1b161d"; bg = "#89cde1"; };
      };

      help = {
        on = { fg = "#89cde1"; bold = true; };
        run = { fg = "#a6e3f1"; };
        desc = { fg = "#d5c0d7"; };
        hovered = { fg = "#1b161d"; bg = "#89cde1"; };
        footer = { fg = "#d5c0d7"; bg = "#2d252f"; };
      };

      filetype = {
        rules = [
          { url = "*/"; fg = "#89cde1"; bold = true; }
          { url = "*"; fg = "#89cde1"; }
          { url = "*"; is = "exec"; fg = "#a6d189"; }
          { url = "*"; is = "orphan"; fg = "#e78284"; }
          { mime = "image/*"; fg = "#a6e3f1"; }
          { mime = "{audio,video}/*"; fg = "#89cde1"; }
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,bzip*,zstd}"; fg = "#fcb38a"; }
          { mime = "application/{json,xml}"; fg = "#89cde1"; }
        ];
      };

      icon = {
        prepend_conds = [
          { "if" = "dir"; text = "󰉋"; fg = "#89cde1"; }
          { "if" = "!dir"; text = "󰈔"; fg = "#89cde1"; }
        ];
      };
    };

    settings = {
      mgr = {
        show_hidden = true;
      };

      opener = {
        edit = [
          {
            run = ''nvim "$@"'';
            block = true;
            orphan = false;
            desc = "Edit with Neovim";
          }
        ];
      };

      open = {
        rules = [
          { mime = "text/*"; use = "edit"; }
          { mime = "application/json"; use = "edit"; }
          { mime = "application/x-yaml"; use = "edit"; }
          { mime = "application/xml"; use = "edit"; }
          { mime = "*/javascript"; use = "edit"; }
          { mime = "*/typescript"; use = "edit"; }
          { mime = "*/x-python"; use = "edit"; }
          { mime = "*/x-shellscript"; use = "edit"; }
        ];
      };
    };
  };
}
