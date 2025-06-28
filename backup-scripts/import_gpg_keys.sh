#!/bin/bash

# Set the email address for the GPG key
EMAIL="elkhatibomar@outlook.com"

# Set the paths for the public and private key files
PUBLIC_GPG_KEY_FILE="./keys/github_gpg_public_key.asc"
PRIVATE_GPG_KEY_FILE="./keys/github_gpg_private_key.asc"

import_gpg_keys() {
    echo "Importing GPG keys..."
    gpg --import "$PRIVATE_GPG_KEY_FILE"
    gpg --import "$PUBLIC_GPG_KEY_FILE"
    echo "GPG keys imported successfully."
}

# Check if a GPG key already exists for the specified email
if gpg --list-keys "$EMAIL" &> /dev/null; then
    echo "GPG key already exists for $EMAIL."
else
    echo "No GPG key found for $EMAIL. Importing keys..."

    # Check if the public and private key files exist
    if [[ -f "$PUBLIC_GPG_KEY_FILE" && -f "$PRIVATE_GPG_KEY_FILE" ]]; then
        import_gpg_keys
    else
        echo "Public or private key file not found. Please ensure the keys exist at specified paths."
        exit 1
    fi

    echo "Done importing GPG key."
fi

