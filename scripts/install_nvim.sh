#!/bin/bash

# Get the current date and time in the format YYYY-MM-DD_HH-MM-SS
current_date=$(date +"%Y-%m-%d_%H-%M-%S")

# Define the source and destination directories for nvim
NVIM_DIR="./nvim"  # Change this if the new nvim directory is elsewhere
BACKUP_DIR="$HOME/.config-backup-$current_date"
OLD_NVIM_DIR="$HOME/.config/nvim" 

# Create a backup directory
mkdir -p "$BACKUP_DIR"

# Handle the nvim directory as a special case
if [ -d "$OLD_NVIM_DIR" ]; then
    BACKUP_NVIM_DIR="$BACKUP_DIR/nvim"

    # Backup the old nvim directory
    echo "Backing up the old nvim directory to $BACKUP_NVIM_DIR"
    mv "$OLD_NVIM_DIR" "$BACKUP_NVIM_DIR"
else
    echo "No existing nvim directory found. No backup needed."
fi

# Copy the new nvim directory if it exists
if [ -d "$NVIM_DIR" ]; then
    echo "Copying the new nvim directory from $NVIM_DIR to $OLD_NVIM_DIR"
    cp -r "$NVIM_DIR" "$OLD_NVIM_DIR"
else
    echo "Error: New nvim directory $NVIM_DIR does not exist."
    exit 1
fi

echo "Backup and copy for nvim completed successfully."

