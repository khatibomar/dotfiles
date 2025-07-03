#!/bin/zsh

# Generate a unique popup server name based on the current pane
popup_server_name="popup_$(tmux display-message -p -F "#{pane_id}" | tr -d '%')"
popup_session_name="popup_session"

# Check if we're currently in a popup by checking the server socket
current_socket=$(echo $TMUX | cut -d',' -f1)
if [[ "$current_socket" == *"popup_"* ]]; then
    # If we're in a popup, detach instead of killing to preserve state
    tmux detach-client
    exit 0
fi

# Get current working directory from the main session
current_path=$(tmux display-message -p -F "#{pane_current_path}")

# Check if popup server already exists
if tmux -L "$popup_server_name" has-session -t "$popup_session_name" 2>/dev/null; then
    # Popup session exists, just attach to it
    tmux popup -d "$current_path" -xC -yC -w80% -h80% -s none -B -E \
        "tmux -L $popup_server_name attach-session -t $popup_session_name"
else
    # Create new popup session with full configuration
    tmux popup -d "$current_path" -xC -yC -w80% -h80% -s none -B -E \
        "tmux -L $popup_server_name new-session -d -s $popup_session_name -c '$current_path' \; \
         set-option -g mouse on \; \
         set-option -g set-clipboard on \; \
         set-option -g escape-time 10 \; \
         set-option -g focus-events on \; \
         set-option -g default-terminal 'screen-256color' \; \
         set-option -ga terminal-overrides ',*256col*:Tc' \; \
         set-option -g status-position bottom \; \
         set-option -g status-style 'bg=#2d3748,fg=#a0aec0' \; \
         set-option -g status-left '' \; \
         set-option -g status-right '[POPUP] %H:%M' \; \
         set-option -g status-right-length 20 \; \
         set-option -g window-status-current-style 'bg=#4a5568,fg=#ffffff' \; \
         set-option -g pane-border-style 'fg=#4a5568' \; \
         set-option -g pane-active-border-style 'fg=#63b3ed' \; \
         unbind-key -T root MouseDrag1Border \; \
         unbind-key -T root MouseDown1Status \; \
         bind-key -T copy-mode-vi v send-keys -X begin-selection \; \
         bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
         bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
         bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
         bind-key -T copy-mode y send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
         bind-key -T copy-mode Enter send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
         bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'wl-copy' \; \
         bind-key -T root MouseDown1Pane select-pane -t = \; \
         bind-key -T root MouseDrag1Pane if -Ft= '#{mouse_any_flag}' 'if -Ft= \"#{pane_in_mode}\" \"copy-mode -M\" \"send-keys -M\"' 'copy-mode -M' \; \
         bind-key C-y run-shell 'tmux save-buffer - | wl-copy' \; \
         bind-key C-p run-shell 'wl-paste | tmux load-buffer - && tmux paste-buffer' \; \
         bind-key Q kill-server \; \
         bind-key X confirm-before -p 'Kill popup session? (y/n)' kill-server \; \
         attach-session -t $popup_session_name"
fi
