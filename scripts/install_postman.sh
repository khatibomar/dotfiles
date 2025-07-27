#!/usr/bin/env bash

set -euo pipefail

# Paths
TMP_DIR="/tmp/postman-install"
ARCHIVE="$TMP_DIR/postman.tar.gz"
INSTALL_DIR="$HOME/.local/opt/postman"
BIN_LINK="$HOME/.local/bin/postman"
DESKTOP_FILE="$HOME/.local/share/applications/postman.desktop"

# URLs
POSTMAN_URL="https://dl.pstmn.io/download/latest/linux64"

# Ensure dirs
mkdir -p "$TMP_DIR" "$HOME/.local/opt" "$HOME/.local/bin" "$HOME/.local/share/applications"

echo "📥 Downloading latest Postman..."
curl -L "$POSTMAN_URL" -o "$ARCHIVE"

echo "📦 Extracting..."
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

EXTRACTED_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "Postman")

if [[ -z "$EXTRACTED_DIR" ]]; then
	echo "❌ Could not find extracted Postman directory."
	exit 1
fi

# Install
echo "📂 Installing to $INSTALL_DIR"
rm -rf "$INSTALL_DIR"
mv "$EXTRACTED_DIR" "$INSTALL_DIR"

# Symlink
echo "🔗 Linking binary to $BIN_LINK"
ln -sf "$INSTALL_DIR/Postman" "$BIN_LINK"

# .desktop file
ICON_PATH="$INSTALL_DIR/app/resources/app/assets/icon.png"
echo "🖥️ Creating launcher..."
cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Postman
Comment=Postman API Platform
Exec=$BIN_LINK
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Development;API;Web;
EOF

# Cleanup
rm -rf "$TMP_DIR"

echo "✅ Postman installed!"
echo "👉 Run it with: postman"
