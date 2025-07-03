#!/bin/zsh

# Generate a unique session name based on the pane ID
tmux_popup_session_name="_popup_$(tmux display-message -p -F "#{pane_id}")"

# Check if the current session name contains "popup"
if [[ "$(tmux display-message -p -F "#{session_name}")" == *"_popup_"* ]]; then
    # If we're already in a popup, detach instead of creating another one
    tmux detach-client
else
    # Open a new popup session with the unique name for the current pane
    tmux popup -d '#{pane_current_path}' -xC -yC -w80% -h80% -E \
      "tmux new-session -A -s ${tmux_popup_session_name} -c '#{pane_current_path}' \; \
       set -g mouse on \; \
       set -g set-clipboard on \; \
       bind-key -T copy-mode-vi v send-keys -X begin-selection \; \
       bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
       bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
       bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
       bind-key -T copy-mode y send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
       bind-key -T copy-mode Enter send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
       bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
       bind-key C-y run-shell 'tmux save-buffer - | wl-copy' \; \
       bind-key C-p run-shell 'wl-paste | tmux load-buffer - && tmux paste-buffer' \;"
fi
