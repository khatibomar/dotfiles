#!/bin/bash

# Get the current date and time in the format YYYY-MM-DD_HH-MM-SS
current_date=$(date +"%Y-%m-%d_%H-%M-%S")

# Define the source directory and backup directory
CONFIG_DIR="config" # Change this if your config files are elsewhere
BACKUP_DIR="$HOME/.config-backup-$current_date"

# Create a backup directory
mkdir -p "$BACKUP_DIR"

# Define an exclusion list for the general config files
EXCLUDED_FILES=("gitconfig" "alacritty.toml")

# Backup and copy general config files
if [ -d "$CONFIG_DIR" ]; then
  for item in "$CONFIG_DIR"/*; do
    # Check if there are no files in CONFIG_DIR
    if [ ! -e "$item" ]; then
      echo "No config files found in $CONFIG_DIR."
      break
    fi

    # Get the base name of the item
    base_name=$(basename "$item")

    # Check if the item is in the exclusion list
    if [[ " ${EXCLUDED_FILES[@]} " =~ " $base_name " ]]; then
      echo "Skipping excluded item: $base_name"
      continue
    fi

    OLD_FILE="$HOME/.$base_name"
    BACKUP_FILE="$BACKUP_DIR/$base_name"

    # Backup the old file or directory if it exists
    if [ -e "$OLD_FILE" ]; then
      echo "Backing up the old .$base_name to $BACKUP_FILE"
      mv "$OLD_FILE" "$BACKUP_FILE"
    else
      echo "No existing .$base_name found. No backup needed."
    fi

    # Copy the new item to the HOME directory with a . prefix
    echo "Copying the new $base_name to $OLD_FILE"
    cp -r "$item" "$OLD_FILE"
  done
else
  echo "Error: Config directory $CONFIG_DIR does not exist."
  exit 1
fi

# Handle alacritty.toml separately
if [ -f "$CONFIG_DIR/alacritty.toml" ]; then
  ALACRITTY_DIR="$HOME/.config/alacritty"
  mkdir -p "$ALACRITTY_DIR" # Create the alacritty directory if it doesn't exist
  echo "Copying alacritty.toml to $ALACRITTY_DIR/alacritty.toml"
  cp "$CONFIG_DIR/alacritty.toml" "$ALACRITTY_DIR/alacritty.toml"
else
  echo "Error: Config directory $CONFIG_DIR does not exist."
  exit 1
fi

echo "Backup and copy for general config completed successfully."
