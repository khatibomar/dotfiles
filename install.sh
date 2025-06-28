#!/bin/bash

# Install all applications first
echo "Installing all applications and dependencies..."
bash ./scripts/install_apps.sh

# Navigate to the scripts folder
SCRIPT_DIR="$(dirname "$0")/backup-scripts"

# Run the backup and copy process for Neovim
bash "$SCRIPT_DIR/install_nvim.sh"

# Run the backup and copy process for Config
bash "$SCRIPT_DIR/install_config.sh"

# Run the backup and copy process for Scripts
bash "$SCRIPT_DIR/install_scripts.sh"

# Import GPG keys
bash "$SCRIPT_DIR/import_gpg_keys.sh"

# Import SSH keys
bash "$SCRIPT_DIR/import_ssh_keys.sh"

# Install Git enhancements
echo "Installing Git enhancement tools..."
mkdir -p ~/.local/bin
cp bin/git_functions.sh ~/.local/bin/ 2>/dev/null || true
chmod +x ~/.local/bin/git-* ~/.local/bin/git_functions.sh 2>/dev/null || true
echo "Git enhancement tools installed to ~/.local/bin/"
echo "Shell functions are enabled and ready to use in zsh sessions"
echo "Installation complete! Restart your terminal or run: source ~/.zshrc"
