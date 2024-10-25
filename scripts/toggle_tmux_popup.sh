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
      "tmux new-session -A -s ${tmux_popup_session_name}"
fi

