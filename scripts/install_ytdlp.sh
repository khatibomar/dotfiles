#!/usr/bin/env bash
set -euo pipefail

# Target directory
TARGET_DIR="$HOME/.local/bin"
TARGET_FILE="$TARGET_DIR/yt-dlp"

# Ensure directory exists
mkdir -p "$TARGET_DIR"

# Download yt-dlp
echo "Downloading yt-dlp to $TARGET_FILE..."
curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o "$TARGET_FILE"

# Make it executable
chmod +x "$TARGET_FILE"

echo "yt-dlp installed at $TARGET_FILE"
echo "Make sure $TARGET_DIR is in your PATH."
