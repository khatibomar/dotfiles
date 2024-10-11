#!/bin/bash

# Path to your custom gitconfig file
CUSTOM_GITCONFIG_PATH="./config/gitconfig"  # Adjusted path to match your directory structure

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

