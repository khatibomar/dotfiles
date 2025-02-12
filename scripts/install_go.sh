#!/bin/bash

# Check if curl is installed
if ! command -v curl &>/dev/null; then
	echo "Error: curl is required. Please install curl first."
	exit 1
fi

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
	echo "This script requires root privileges. Please enter your password:"
	sudo -v
fi

# Get system information
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
x86_64)
	ARCH="amd64"
	;;
aarch64)
	ARCH="arm64"
	;;
*)
	echo "Unsupported architecture: $ARCH"
	exit 1
	;;
esac

# Get latest Go version
LATEST_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
if [ -z "$LATEST_VERSION" ]; then
	echo "Error: Failed to fetch latest Go version"
	exit 1
fi

# Set download URL
TARBALL="${LATEST_VERSION}.${OS}-${ARCH}.tar.gz"
URL="https://dl.google.com/go/${TARBALL}"

# Create temporary directory
TMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TMP_DIR"

# Download Go
echo "Downloading Go ${LATEST_VERSION}..."
curl -L -o "$TMP_DIR/$TARBALL" "$URL"
if [ $? -ne 0 ]; then
	echo "Error: Failed to download Go tarball"
	exit 1
fi

# Remove previous installation
echo "Removing old Go installation (if exists)..."
sudo rm -rf /usr/local/go

# Install Go
echo "Installing Go to /usr/local..."
sudo tar -C /usr/local -xzf "$TMP_DIR/$TARBALL"
if [ $? -ne 0 ]; then
	echo "Error: Failed to extract Go tarball"
	exit 1
fi

# Update environment variables
echo "Updating environment variables..."
SHELL_PROFILE="$HOME/.profile"
if [[ $SHELL == *"zsh"* ]]; then
	SHELL_PROFILE="$HOME/.zshrc"
fi

# Cleanup
echo "Cleaning up temporary files..."
rm -rf "$TMP_DIR"

# Verify installation
echo "Verifying installation..."
/usr/local/go/bin/go version

echo "Installation completed successfully!"
echo "Restart your terminal or run 'source $SHELL_PROFILE' to update your environment"
