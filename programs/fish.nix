{ ... }:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      fish_vi_key_bindings
      set fish_greeting

      starship init fish | source
      if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
      end

      zoxide init fish | source
      direnv hook fish | source

      fastfetch
    '';

    shellAliases = {
      pamcan = "pacman";
      gc = "git clone";
      l = "eza --icons --group-directories-first";
      ls = "eza --icons";
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
      ll = "eza --icons --group-directories-first -T -L 1";
      l1 = "eza --icons --group-directories-first -T -L 1";
      l2 = "eza --icons --group-directories-first -T -L 2";
      h = "hyprland";
      cachy-nix = "home-manager switch --impure --flake .#wanmixc-cachyos-nix";
      wsl-nix = "home-manager switch --impure --flake .#wanmixc-wsl";
    };

    functions = {
      fish_user_key_bindings = {
        body = ''
          bind -M insert -m default jj repaint-mode
          bind -M default -m insert i repaint-mode
          bind -M insert \cr history-pager
          bind -M default \cr history-pager
          bind -M insert \ct __wanmixc_fzf_ctrl_t
          bind -M default \ct __wanmixc_fzf_ctrl_t
        '';
      };

      fish_mode_prompt = {
        body = ''
          switch $fish_bind_mode
            case default
              set_color --bold 89cde1
              echo -n 'N '
            case insert
              set_color --bold green
              echo -n 'I '
            case visual
              set_color --bold magenta
              echo -n 'V '
            case replace_one
              set_color --bold yellow
              echo -n 'R '
          end
          set_color normal
        '';
      };

      fish_prompt = {
        description = "Write out the prompt";
        body = ''
          printf '%s@%s %s%s%s > ' $USER $hostname \
            (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
        '';
      };

      y = {
        body = ''
          set tmp (mktemp -t "yazi-cwd.XXXXX")
          yazi $argv --cwd-file="$tmp"
          if set cwd (cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
            cd -- "$cwd"
          end
          rm -f -- "$tmp"
        '';
      };

      __wanmixc_fzf_ctrl_t = {
        body = ''
          set -l selection (command find -L . \
            -path '*/.git' -prune -o \
            -path '*/node_modules' -prune -o \
            -path '*/.direnv' -prune -o \
            -type f -print -o -type d -print | sed 's#^\./##' | fzf)

          if test -n "$selection"
            commandline -i -- (string escape -- $selection)
          end

          commandline -f repaint
        '';
      };

      __wan_paste_require_url = {
        body = ''
          if not set -q WAN_PASTE_URL; or test -z "$WAN_PASTE_URL"
            echo 'WAN_PASTE_URL is not configured. Add "paste_api_url" to secrets.json and run home-manager switch.' >&2
            return 1
          end
        '';
      };

      wan-copy = {
        body = ''
          if not __wan_paste_require_url
            return 1
          end

          if test (count $argv) -eq 0
            echo 'usage: wan-copy "text to paste"' >&2
            return 1
          end

          set -l paste_url (string trim --right --chars=/ -- "$WAN_PASTE_URL")
          set -l content (string join ' ' -- $argv)
          set -l payload (jq -cn --arg content "$content" '{content: $content}')
          set -l response (curl -fsS -X POST "$paste_url/api/pastes" -H 'content-type: application/json' -d "$payload")
          if test $status -ne 0
            return 1
          end

          set -l id (printf '%s' "$response" | jq -r '.id // empty')
          if test -z "$id"
            echo 'wan-copy: create response did not include an id' >&2
            printf '%s\n' "$response" >&2
            return 1
          end

          printf '%s\n' "$id"
        '';
      };

      wan-paste = {
        body = ''
          if not __wan_paste_require_url
            return 1
          end

          if test (count $argv) -ne 1
            echo 'usage: wan-paste <id>' >&2
            return 1
          end

          set -l paste_url (string trim --right --chars=/ -- "$WAN_PASTE_URL")
          set -l response (curl -fsS "$paste_url/api/pastes/$argv[1]")
          if test $status -ne 0
            return 1
          end

          printf '%s' "$response" | jq -e 'has("content")' >/dev/null
          if test $status -ne 0
            echo 'wan-paste: get response did not include content' >&2
            printf '%s\n' "$response" >&2
            return 1
          end

          set -l content (printf '%s' "$response" | jq -r '.content')
          printf '%s\n' "$content"
        '';
      };
    };
  };
}
