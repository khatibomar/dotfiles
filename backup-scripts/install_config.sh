#!/bin/bash

# Get the current date and time in the format YYYY-MM-DD_HH-MM-SS
current_date=$(date +"%Y-%m-%d_%H-%M-%S")

# Define the source directory and backup directory
CONFIG_DIR="config" # Change this if your config files are elsewhere
BACKUP_DIR="$HOME/.config-backup-$current_date"

# Create a backup directory
mkdir -p "$BACKUP_DIR"

# Define an exclusion list for the general config files
EXCLUDED_FILES=("htoprc" "mpv.conf" "konsole" "konsolerc")

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

# Handle htoprc separately
if [ -f "$CONFIG_DIR/htoprc" ]; then
	HTOP_DIR="$HOME/.config/htop"
	mkdir -p "$HTOP_DIR" # Create the alacritty directory if it doesn't exist
	echo "Copying htoprc to $HTOP_DIR/htoprc"
	cp "$CONFIG_DIR/htoprc" "$HTOP_DIR/htoprc"
else
	echo "Error: Config directory $CONFIG_DIR does not exist."
	exit 1
fi

# Handle mpv separately
if [ -f "$CONFIG_DIR/mpv.conf" ]; then
	MPV_DIR="$HOME/.config/mpv"
	mkdir -p "$MPV_DIR" # Create the alacritty directory if it doesn't exist
	echo "Copying mpv to $MPV_DIR/mpv.conf"
	cp "$CONFIG_DIR/mpv.conf" "$MPV_DIR/mpv.conf"
else
	echo "Error: Config directory $CONFIG_DIR does not exist."
	exit 1
fi

# Handle konsole profiles
if [ -d "$CONFIG_DIR/konsole" ]; then
	KONSOLE_DIR="$HOME/.local/share/konsole"
	mkdir -p "$KONSOLE_DIR"
	echo "Copying konsole profiles to $KONSOLE_DIR"
	cp -r "$CONFIG_DIR/konsole"/* "$KONSOLE_DIR/"
else
	echo "No konsole config directory found. Skipping."
fi

# Handle konsolerc (set Ayn as default Konsole profile)
if [ -f "$CONFIG_DIR/konsolerc" ]; then
	KONSOLERC_DIR="$HOME/.config"
	mkdir -p "$KONSOLERC_DIR"
	echo "Copying konsolerc to $KONSOLERC_DIR/konsolerc"
	cp "$CONFIG_DIR/konsolerc" "$KONSOLERC_DIR/konsolerc"
else
	echo "Error: Config directory $CONFIG_DIR does not exist."
	exit 1
fi

echo "Backup and copy for general config completed successfully."
