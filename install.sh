#!/bin/bash

# Get the current date and time in the format YYYY-MM-DD_HH-MM-SS
current_date=$(date +"%Y-%m-%d_%H-%M-%S")

# Define the source and destination directories
config_dir="$HOME/.config/nvim"
backup_dir="$HOME/.config/nvim-$current_date"
new_nvim_dir="./nvim"

# Check if the config directory exists
if [ -d "$config_dir" ]; then
    # Backup the existing nvim folder
    echo "Backing up existing nvim configuration to $backup_dir"
    mv "$config_dir" "$backup_dir"
else
    echo "No existing nvim configuration found, proceeding to copy."
fi

# Copy the new nvim folder to the config directory
if [ -d "$new_nvim_dir" ]; then
    echo "Copying new nvim configuration from $new_nvim_dir to $config_dir"
    cp -r "$new_nvim_dir" "$config_dir"
else
    echo "Error: New nvim folder $new_nvim_dir does not exist."
    exit 1
fi

echo "Backup and copy completed successfully."
