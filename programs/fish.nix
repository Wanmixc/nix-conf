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

    shellAbbrs = {
      wc = "wan-copy";
      wp = "wan-paste";
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

      __wan_paste_unique_output_path = {
        body = ''
          set -l requested "$argv[1]"
          if not test -e "$requested"
            printf '%s\n' "$requested"
            return 0
          end

          set -l dir (dirname -- "$requested")
          set -l name (basename -- "$requested")
          set -l stem "$name"
          set -l ext

          if string match -qr '^.+\.[^/]+$' -- "$name"
            set stem (string replace -r '\.[^.]+$' "" -- "$name")
            set ext (string match -r '\.[^.]+$' -- "$name")
          end

          set -l i 1
          while true
            set -l candidate "$dir/$stem-$i$ext"
            if not test -e "$candidate"
              printf '%s\n' "$candidate"
              return 0
            end
            set i (math $i + 1)
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
          set -l payload
          if test (count $argv) -eq 1; and test -f "$argv[1]"
            if not test -r "$argv[1]"
              echo "wan-copy: cannot read file: $argv[1]" >&2
              return 1
            end

            if not cat -- "$argv[1]" | string collect | string trim | string length --quiet
              echo "wan-copy: file content is empty: $argv[1]" >&2
              return 1
            end

            set payload (jq -cn --rawfile content "$argv[1]" '{content: $content}')
          else
            set -l content (string join ' ' -- $argv)
            set payload (jq -cn --arg content "$content" '{content: $content}')
          end

          set -l response_file (mktemp)
          set -l http_code (curl -sS -o "$response_file" -w '%{http_code}' -X POST "$paste_url/api/pastes" -H 'content-type: application/json' -d "$payload")
          if test $status -ne 0
            rm -f -- "$response_file"
            return 1
          end

          set -l response (cat -- "$response_file")
          rm -f -- "$response_file"

          if not string match -qr '^2' -- "$http_code"
            echo "wan-copy: create failed with HTTP $http_code" >&2
            printf '%s\n' "$response" | jq -r '.errors[]? // .description? // empty' 2>/dev/null >&2
            or printf '%s\n' "$response" >&2
            return 1
          end

          set -l id (printf '%s' "$response" | jq -r '.data.id // .id // empty')
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

          if test (count $argv) -lt 1; or test (count $argv) -gt 2
            echo 'usage: wan-paste <id> [output-file]' >&2
            return 1
          end

          set -l paste_url (string trim --right --chars=/ -- "$WAN_PASTE_URL")
          set -l response (curl -fsS "$paste_url/api/pastes/$argv[1]")
          if test $status -ne 0
            return 1
          end

          printf '%s' "$response" | jq -e '((.data | type) == "object" and (.data | has("content"))) or has("content")' >/dev/null
          if test $status -ne 0
            echo 'wan-paste: get response did not include content' >&2
            printf '%s\n' "$response" >&2
            return 1
          end

          set -l content_filter 'if (.data | type) == "object" and (.data | has("content")) then .data.content elif has("content") then .content else empty end'
          if test (count $argv) -eq 2
            set -l output_path (__wan_paste_unique_output_path "$argv[2]")
            printf '%s' "$response" | jq -rj "$content_filter" > "$output_path"
            if test $status -ne 0
              echo "wan-paste: cannot write file: $output_path" >&2
              return 1
            end

            printf 'wrote %s\n' "$output_path"
            return 0
          end

          printf '%s' "$response" | jq -rj "$content_filter"
          printf '\n'
        '';
      };

      wan-del-paste = {
        body = ''
          if not __wan_paste_require_url
            return 1
          end

          if test (count $argv) -ne 1
            echo 'usage: wan-del-paste <id>' >&2
            return 1
          end

          set -l paste_url (string trim --right --chars=/ -- "$WAN_PASTE_URL")
          curl -fsS -X DELETE "$paste_url/api/pastes/$argv[1]" >/dev/null
          if test $status -ne 0
            return 1
          end

          printf 'deleted %s\n' "$argv[1]"
        '';
      };
    };
  };
}
