#!/bin/bash

# Navigate to the scripts folder
SCRIPT_DIR="$(dirname "$0")/scripts"

# Run the backup and copy process for Neovim
bash "$SCRIPT_DIR/install_nvim.sh"

# Run the backup and copy process for Config
bash "$SCRIPT_DIR/install_config.sh"

# Merge custom gitconfig settings
bash "$SCRIPT_DIR/merge_gitconfig.sh"

# Import GPG keys
bash "$SCRIPT_DIR/import_gpg_keys.sh"
