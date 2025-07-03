#!/bin/zsh

# Cleanup script for tmux popup sessions
# This script will list and optionally clean up all popup tmux servers

echo "🔍 Scanning for tmux popup sessions..."

# Find all popup servers
popup_servers=()
for socket in /tmp/tmux-*/popup_*; do
    if [[ -S "$socket" ]]; then
        server_name=$(basename "$socket")
        popup_servers+=("$server_name")
    fi
done

if [[ ${#popup_servers[@]} -eq 0 ]]; then
    echo "✅ No popup sessions found."
    exit 0
fi

echo "📋 Found ${#popup_servers[@]} popup session(s):"
echo

# List all popup sessions with details
for i in {1..${#popup_servers[@]}}; do
    server=${popup_servers[$i]}
    echo "[$i] Server: $server"

    # Try to get session info
    if tmux -L "$server" list-sessions 2>/dev/null; then
        echo "    Status: Active"
    else
        echo "    Status: Dead socket"
    fi
    echo
done

echo "Options:"
echo "  [a] Clean up ALL popup sessions"
echo "  [d] Clean up only dead sockets"
echo "  [1-${#popup_servers[@]}] Clean up specific session"
echo "  [q] Quit without changes"
echo

read -p "Choose an option: " choice

case "$choice" in
    a|A)
        echo "🧹 Cleaning up ALL popup sessions..."
        for server in "${popup_servers[@]}"; do
            echo "  Killing server: $server"
            tmux -L "$server" kill-server 2>/dev/null || true
        done
        echo "✅ All popup sessions cleaned up."
        ;;
    d|D)
        echo "🧹 Cleaning up dead sockets..."
        for server in "${popup_servers[@]}"; do
            if ! tmux -L "$server" list-sessions 2>/dev/null; then
                echo "  Removing dead socket: $server"
                rm -f "/tmp/tmux-*/$server" 2>/dev/null || true
            fi
        done
        echo "✅ Dead sockets cleaned up."
        ;;
    [1-9])
        if [[ $choice -le ${#popup_servers[@]} ]]; then
            server=${popup_servers[$choice]}
            echo "🧹 Cleaning up server: $server"
            tmux -L "$server" kill-server 2>/dev/null || true
            echo "✅ Server $server cleaned up."
        else
            echo "❌ Invalid selection."
            exit 1
        fi
        ;;
    q|Q)
        echo "👋 No changes made."
        ;;
    *)
        echo "❌ Invalid option."
        exit 1
        ;;
esac
