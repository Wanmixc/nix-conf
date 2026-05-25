{ ... }:
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    sensibleOnTop = true;
    terminal = "tmux-256color";

    baseIndex = 1;
    extraConfig = ''
      set -ga terminal-features ",*:RGB"

      set -g pane-base-index 1
      set -g renumber-windows on
      set -g detach-on-destroy off
      set -g status-position bottom

      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      unbind '"'
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      set -g status-style "bg=#251d27,fg=#d5c0d7"
      set -g message-style "bg=#afc2fc,fg=#251d27"
      set -g message-command-style "bg=#afc2fc,fg=#251d27"
      set -g pane-border-style "fg=#514254"
      set -g pane-active-border-style "fg=#afc2fc"

      set -g status-left-length 30
      set -g status-right-length 100
      set -g status-left "#[fg=#251d27,bg=#afc2fc,bold] #S #[fg=#afc2fc,bg=#251d27]█#[default]"
      set -g status-right "#[fg=#8fc9fc]#(whoami) #[fg=#9d8ba0]| #[fg=#eddeec]%a %d %b #[fg=#fcb38a]%H:%M "

      setw -g window-status-format "#[fg=#d5c0d7,bg=#2d252f] #I:#W "
      setw -g window-status-current-format "#[fg=#251d27,bg=#afc2fc,bold] #I:#W "
      setw -g window-status-style "fg=#d5c0d7,bg=#2d252f"
    '';
  };
}
