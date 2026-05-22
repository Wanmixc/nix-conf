{ config, pkgs, lib, ... }:
let
  secrets = builtins.fromJSON (builtins.readFile ./secrets.json);
  deepseek-tui-src = pkgs.fetchFromGitHub {
    owner = "Hmbown";
    repo = "DeepSeek-TUI";
    rev = "v0.8.17"; # ganti sesuai release yang mau dipakai
    hash = "sha256-lEOOFWrIqouM/2m7cSzezNXS3+cSXojvx9YdxuuiWlc=";
  };

  deepseek-cli = pkgs.rustPlatform.buildRustPackage {
    pname = "deepseek-tui-cli";
    version = "0.8.17";

    src = deepseek-tui-src;
    cargoLock.lockFile = "${deepseek-tui-src}/Cargo.lock";

    cargoHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.dbus ];

    buildAndTestSubdir = "crates/cli";
  };

  deepseek-tui = pkgs.rustPlatform.buildRustPackage {
    pname = "deepseek-tui";
    version = "0.8.17";

    src = deepseek-tui-src;
    cargoLock.lockFile = "${deepseek-tui-src}/Cargo.lock";

    cargoHash = "sha256-CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.dbus ];

    buildAndTestSubdir = "crates/tui";
    doCheck = false;
  };
  deepseek-tui-combined = pkgs.symlinkJoin {
    name = "deepseek-tui-combined-0.8.17";
    paths = [
     deepseek-cli
     deepseek-tui
   ];
  };

in
{
  # Modules
  imports = [
    ./tmux/tmux.nix
  ];

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;

  # Home metadata
  home.username = "wanmixc";
  home.homeDirectory = "/home/wanmixc";
  home.stateVersion = "25.11";

  # Packages
  home.packages = with pkgs; [
    bash-language-server
    bat
    bun
    eza
    fastfetch
    gitui
    neovim
    ripgrep
    shfmt
    sxiv
    tmux
    unzip
    fzf
    deepseek-tui-combined
    btop
    fish
  ];

  # Session
  home.sessionVariables = {
    EDITOR = "nvim";
    DEEPSEEK_TUI_BIN = "${deepseek-tui}/bin/deepseek-tui";
  };

  # XDG
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  xdg.configFile = {
    "fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;
    "fastfetch/logo.txt".source = ./fastfetch/logo.txt;
    "nvim/init.lua".source = ./nvim/init.lua;
    "rmpc/themes/theme.ron".source = ./rmpc/theme.ron;
    "starship.toml".source = ./starship/starship.toml;
  };

  # DeepSeek skills managed declaratively via Home Manager
  home.file = {
    ".deepseek/skills/commit-message-id/SKILL.md".source = ./deepseek/skills/commit-message-id/SKILL.md;
    ".deepseek/skills/skill-creator/SKILL.md".source = ./deepseek/skills/skill-creator/SKILL.md;
  };

  home.activation.codexChromeDevtoolsMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CODex_CONFIG="$HOME/.codex/config.toml"
    mkdir -p "$HOME/.codex"

    if [ -f "$CODex_CONFIG" ]; then
      if grep -q '^\[mcp_servers\.chrome-devtools\]$' "$CODex_CONFIG"; then
        ${pkgs.gawk}/bin/awk '
          BEGIN { skip = 0 }
          /^\[mcp_servers\.chrome-devtools\]$/ { skip = 1; next }
          /^\[/ && skip { skip = 0 }
          !skip { print }
        ' "$CODex_CONFIG" > "$CODex_CONFIG.tmp"
        mv "$CODex_CONFIG.tmp" "$CODex_CONFIG"
      fi
    fi

    cat >> "$CODex_CONFIG" <<'EOF'

[mcp_servers.chrome-devtools]
command = "bunx"
args = [
  "chrome-devtools-mcp@latest",
  "--executablePath",
  "/home/wanmixc/.nix-profile/bin/microsoft-edge",
]
EOF
  '';

  home.activation.codexCommitMessageSkill = lib.hm.dag.entryAfter ["linkGeneration"] ''
    install -Dm644 ${./codex/skills/commit-message-id/SKILL.md} \
      "$HOME/.codex/skills/commit-message-id/SKILL.md"
    install -Dm644 ${./codex/skills/commit-message-id/agents/openai.yaml} \
      "$HOME/.codex/skills/commit-message-id/agents/openai.yaml"
  '';

  # Programs
  programs = {
    home-manager.enable = true;
    vim.enable = true;

    starship = {
      enable = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fish = {
       enable = true;

        shellInit = ''
          fish_add_path ~/.nix-profile/bin
        '';

        interactiveShellInit = ''
          # No greeting
          set fish_greeting
        fastfetch
      '';

      shellAliases = {
        pamcan = "pacman";
        l      = "eza --icons";
        ls     = "eza --icons";
        clear  = "printf '\\033[2J\\033[3J\\033[1;1H'";
        q      = "qs -c ii";
        ll     = "eza --icons -T -L 1";
        l1     = "eza --icons -T -L 1";
        l2     = "eza --icons -T -L 2";
      };

      functions = {
        fish_prompt = {
          description = "Write out the prompt";
          body = ''
            printf '%s@%s %s%s%s > ' $USER $hostname \
                (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
          '';
        };
      };
    };

    git = {
      enable = true;
      package = pkgs.git;
      delta.enable = true;
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };
      userEmail = "wanmixc@gmail.com"; # FIXME: set your git email
      userName = "wanmixc"; #FIXME: set your git username
      extraConfig = {
        # FIXME: uncomment the next lines if you want to be able to clone private https repos
        url = {
          "https://oauth2:${secrets.github_token}@github.com" = {
            insteadOf = "https://github.com";
          };
          # "https://oauth2:${secrets.gitlab_token}@gitlab.com" = {
          #   insteadOf = "https://gitlab.com";
          # };
        };
        push = {
          default = "current";
          autoSetupRemote = true;
        };
        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
    };

    rmpc = {
      enable = true;
      config = builtins.readFile ./rmpc/config.ron;
    };

    yazi = {
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
  };

  # Services
  services.mpd = {
    enable = true;
    musicDirectory = config.xdg.userDirs.music;
    network.startWhenNeeded = true;
    extraConfig = ''
      auto_update "yes"
      restore_paused "yes"
      follow_outside_symlinks "yes"
      follow_inside_symlinks "yes"

      audio_output {
        type "pulse"
        name "PulseAudio / PipeWire"
      }
    '';
  };
}
