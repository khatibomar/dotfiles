#!/bin/sh

# Define installation directory (e.g., ~/.local/bin)
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Download the latest git-recover script
curl -fsSL "https://raw.githubusercontent.com/ethomson/git-recover/refs/heads/main/git-recover" -o "$INSTALL_DIR/git-recover"

# Make it executable
chmod +x "$INSTALL_DIR/git-recover"

echo "git-recover installed successfully!"
