#!/bin/bash

# Set the email address for the GPG key
EMAIL="elkhatibomar@outlook.com"

# Set the paths for the public and private key files
PUBLIC_GPP_KEY_FILE="github_gpg_public_key.asc"
PRIVATE_GPG_KEY_FILE="github_gpg_private_key.asc"

# Path to your custom gitconfig file
CUSTOM_GITCONFIG_PATH="./gitconfig"

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

# Starting message
echo "Starting to merge custom .gitconfig settings..."

# Variable to track the current section
current_section=""

# Read the custom gitconfig file line by line
while IFS= read -r line; do
    # Skip empty lines and comments (lines starting with #)
    if [[ -z "$line" || "$line" =~ ^# ]]; then
        continue
    fi

    # Check if the line is a section header (e.g., [alias], [user], [color "branch"])
    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        section=$(echo "$line" | sed -E 's/\[([a-zA-Z0-9_-]+).*/\1/')    # Extract section part
        tag=$(echo "$line" | sed -nE 's/.*\"([^\"]+)\".*/\1/p')          # Extract tag part if present

        if [[ -n "$tag" ]]; then
            current_section="${section}.${tag}"  # Combine section and tag
        else
            current_section="${section}"        # No tag, just use section
        fi
        continue
    fi

    # Skip lines that don't match key = value format
    if [[ ! "$line" =~ = ]]; then
        continue
    fi

    # Trim leading and trailing whitespace from the line
    line=$(echo "$line" | awk '{$1=$1;print}')  # Using awk to trim whitespace

    # Extract key and value, preserving quotes
    key="${line%%=*}"  # Get the part before the '='
    value="${line#*=}" # Get the part after the '='

    # Further trim whitespace from key and value
    key=$(echo "$key" | sed 's/[ \t]*//g')    # Trim spaces around the key
    value=$(echo "$value" | sed 's/^[ \t]*//;s/[ \t]*$//')  # Trim spaces around the value

    # Combine the section with the key (e.g., alias.co or color.branch.upstream)
    full_key="${current_section}.${key}"

    # Check if the key already exists in the global .gitconfig
    if ! git config --global --get "$full_key" > /dev/null; then
        # If key doesn't exist, set it without printing logs
        git config --global "$full_key" "$value" > /dev/null 2>&1
    fi
done < "$CUSTOM_GITCONFIG_PATH"

echo "Git configuration merged successfully!"

# Function to import GPG keys
import_gpg_keys() {
    echo "Importing GPG keys..."
    
    # Import the private key
    gpg --import "$PRIVATE_KEY_FILE"
    
    # Import the public key
    gpg --import "$PUBLIC_KEY_FILE"
    
    echo "GPG keys imported successfully."
}

# Check if a GPG key already exists for the specified email
if gpg --list-keys "$EMAIL" &> /dev/null; then
    echo "GPG key already exists for $EMAIL."
else
    echo "No GPG key found for $EMAIL. Importing keys..."

    # Check if the public and private key files exist
    if [[ -f "$PUBLIC_KEY_FILE" && -f "$PRIVATE_KEY_FILE" ]]; then
        import_gpg_keys
    else
        echo "Public or private key file not found. Please ensure the keys exist at specified paths."
        exit 1
    fi

    echo "Done GPG key imported"
fi

