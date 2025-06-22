#!/bin/bash

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

# Install tools
bash ./scripts/install_tools.sh

# Install Git enhancements
echo "Installing Git enhancement tools..."
mkdir -p ~/.local/bin
cp bin/git-nvimdiff ~/.local/bin/
cp bin/git-setup-check ~/.local/bin/
cp bin/git_functions.sh ~/.local/bin/
chmod +x ~/.local/bin/git-nvimdiff ~/.local/bin/git-setup-check ~/.local/bin/git_functions.sh
echo "Git enhancement tools installed to ~/.local/bin/"
echo "Shell functions are enabled and ready to use in zsh sessions"
echo "Use 'git-setup-check' to check overall setup"
