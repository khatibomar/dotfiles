#!/bin/bash

# Set the paths for the SSH key files
SSH_PRIVATE_KEY_FILE="./keys/id_ed25519"
SSH_PUBLIC_KEY_FILE="./keys/id_ed25519.pub"
SSH_CONFIG_FILE="./keys/ssh_config"
SSH_KNOWN_HOSTS_FILE="./keys/known_hosts"

# SSH directory
SSH_DIR="$HOME/.ssh"

import_ssh_keys() {
    echo "Importing SSH keys..."

    # Create SSH directory if it doesn't exist
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # Import private key
    if [[ -f "$SSH_PRIVATE_KEY_FILE" ]]; then
        cp "$SSH_PRIVATE_KEY_FILE" "$SSH_DIR/"
        chmod 600 "$SSH_DIR/$(basename "$SSH_PRIVATE_KEY_FILE")"
        echo "Private SSH key imported successfully."
    else
        echo "Private SSH key file not found at $SSH_PRIVATE_KEY_FILE"
    fi

    # Import public key
    if [[ -f "$SSH_PUBLIC_KEY_FILE" ]]; then
        cp "$SSH_PUBLIC_KEY_FILE" "$SSH_DIR/"
        chmod 644 "$SSH_DIR/$(basename "$SSH_PUBLIC_KEY_FILE")"
        echo "Public SSH key imported successfully."
    else
        echo "Public SSH key file not found at $SSH_PUBLIC_KEY_FILE"
    fi

    # Import SSH config if it exists
    if [[ -f "$SSH_CONFIG_FILE" ]]; then
        cp "$SSH_CONFIG_FILE" "$SSH_DIR/config"
        chmod 644 "$SSH_DIR/config"
        echo "SSH config imported successfully."
    else
        echo "SSH config file not found at $SSH_CONFIG_FILE (optional)"
    fi

    # Import known_hosts if it exists
    if [[ -f "$SSH_KNOWN_HOSTS_FILE" ]]; then
        cp "$SSH_KNOWN_HOSTS_FILE" "$SSH_DIR/known_hosts"
        chmod 644 "$SSH_DIR/known_hosts"
        echo "SSH known_hosts imported successfully."
    else
        echo "SSH known_hosts file not found at $SSH_KNOWN_HOSTS_FILE (optional)"
    fi

    echo "SSH keys imported successfully."
}

# Check if SSH keys already exist
if [[ -f "$SSH_DIR/id_ed25519" || -f "$SSH_DIR/id_rsa" ]]; then
    echo "SSH keys already exist in $SSH_DIR."
    read -p "Do you want to overwrite them? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup existing keys
        BACKUP_DIR="$HOME/.ssh_backup_$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing SSH keys to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        cp -r "$SSH_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true

        import_ssh_keys
    else
        echo "SSH key import cancelled."
        exit 0
    fi
else
    echo "No SSH keys found. Importing keys..."

    # Check if at least the private and public key files exist
    if [[ -f "$SSH_PRIVATE_KEY_FILE" && -f "$SSH_PUBLIC_KEY_FILE" ]]; then
        import_ssh_keys
    else
        echo "SSH private or public key file not found. Please ensure the keys exist at:"
        echo "  Private key: $SSH_PRIVATE_KEY_FILE"
        echo "  Public key: $SSH_PUBLIC_KEY_FILE"
        exit 1
    fi

    echo "Done importing SSH keys."
fi

# Start SSH agent and add the key
if [[ -f "$SSH_DIR/id_ed25519" ]]; then
    echo "Adding SSH key to agent..."
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add "$SSH_DIR/id_ed25519" 2>/dev/null && echo "SSH key added to agent" || echo "Could not add SSH key to agent (may require passphrase)"
fi
