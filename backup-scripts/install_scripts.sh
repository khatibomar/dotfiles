#!/bin/bash

# Get the current date and time in the format YYYY-MM-DD_HH-MM-SS
current_date=$(date +"%Y-%m-%d_%H-%M-%S")

# Define the source and destination directories for scripts
SCRIPTS_DIR="./scripts" # Change this if the new scripts directory is elsewhere
BACKUP_DIR="$HOME/.config-backup-$current_date"
OLD_SCRIPTS_DIR="$HOME/scripts"

# Create a backup directory
mkdir -p "$BACKUP_DIR"

# Handle the scripts directory as a special case
if [ -d "$OLD_SCRIPTS_DIR" ]; then
  BACKUP_SCRIPTS_DIR="$BACKUP_DIR/.scripts"

  # Backup the old scripts directory
  echo "Backing up the old scripts directory to $BACKUP_SCRIPTS_DIR"
  mv "$OLD_SCRIPTS_DIR" "$BACKUP_SCRIPTS_DIR"
else
  echo "No existing scripts directory found. No backup needed."
fi

# Copy the new scripts directory if it exists
if [ -d "$SCRIPTS_DIR" ]; then
  echo "Copying the new scripts directory from $SCRIPTS_DIR to $OLD_SCRIPTS_DIR"
  cp -r "$SCRIPTS_DIR" "$OLD_SCRIPTS_DIR"
else
  echo "Error: New scripts directory $SCRIPTS_DIR does not exist."
  exit 1
fi

echo "Backup and copy for scripts completed successfully."
