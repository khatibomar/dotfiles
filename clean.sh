#!/bin/bash

# Clean nvim backups
echo "Starting nvim backups cleaning"
rm -rf "$HOME/.config-backup-*"  # Adjusted to match the backup naming scheme
echo "Cleaning nvim backups completed successfully."

