#!/usr/bin/env bash

set -euo pipefail

# Directories
TMP_DIR="/tmp/jetbrains-toolbox"
INSTALL_DIR="$HOME/.local/opt/jetbrains-toolbox"
BIN_LINK="$HOME/.local/bin/jetbrains-toolbox"
DESKTOP_FILE="$HOME/.local/share/applications/jetbrains-toolbox.desktop"

# Ensure dirs
mkdir -p "$TMP_DIR" "$HOME/.local/bin" "$HOME/.local/opt" "$HOME/.local/share/applications"

# Check jq
command -v jq >/dev/null || {
  echo "❌ 'jq' required. Install with: sudo dnf install jq"
  exit 1
}

# Get URL
echo "📡 Fetching JetBrains Toolbox download URL..."
DOWNLOAD_URL=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" |
  jq -r '.TBA[0].downloads.linux.link')

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "❌ Could not fetch toolbox download URL."
  exit 1
fi

# Download & extract
echo "📥 Downloading..."
curl -L "$DOWNLOAD_URL" -o "$TMP_DIR/toolbox.tar.gz"

echo "📦 Extracting..."
tar -xzf "$TMP_DIR/toolbox.tar.gz" -C "$TMP_DIR"

EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "jetbrains-toolbox-*")
if [[ -z "$EXTRACTED_DIR" ]]; then
  echo "❌ Could not find extracted directory."
  exit 1
fi

# Install to ~/.local/opt
echo "📂 Installing to $INSTALL_DIR"
rm -rf "$INSTALL_DIR"
mv "$EXTRACTED_DIR" "$INSTALL_DIR"

# Symlink to ~/.local/bin
echo "🔗 Creating symlink at $BIN_LINK"
ln -sf "$INSTALL_DIR/bin/jetbrains-toolbox" "$BIN_LINK"

# Create .desktop file
echo "🖥️ Creating .desktop file..."
cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=JetBrains Toolbox
Comment=Manage your JetBrains IDEs
Exec=$BIN_LINK
Icon=$INSTALL_DIR/bin/toolbox-tray-color.png
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

# Cleanup
echo "🧹 Cleaning up temp files..."
rm -rf "$TMP_DIR"

echo "✅ Installed JetBrains Toolbox!"
echo "👉 Run it with: jetbrains-toolbox"
