#!/usr/bin/env bash
set -euo pipefail

install_sdl2() {
  if pkg-config --exists sdl2; then
    echo "SDL2 already installed"
    return
  fi

  echo "SDL2 not found, installing..."

  if command -v dnf &>/dev/null; then
    sudo dnf install -y SDL2 SDL2-devel
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -y && sudo apt-get install -y libsdl2-2.0-0 libsdl2-dev
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm sdl2
  else
    echo "Warning: Could not detect package manager. Install SDL2 manually."
  fi
}

install_sdl2

LATEST_VERSION=$(curl -s https://api.github.com/repos/nesdev-org/MesenCE/releases/latest | grep -oP '"tag_name":\s*"v?\K[^"]+')

if [[ -z "$LATEST_VERSION" ]]; then
  echo "Failed to fetch latest MesenCE version"
  exit 1
fi

echo "Latest MesenCE version: $LATEST_VERSION"

DOWNLOAD_URL="https://github.com/nesdev-org/MesenCE/releases/download/${LATEST_VERSION}/Mesen_${LATEST_VERSION}_Linux_x64.zip"
INSTALL_DIR="$HOME/.local/share/MesenCE"
BIN_DIR="$HOME/.local/bin"
ZIP_FILE="/tmp/mesen_${LATEST_VERSION}_linux_x64.zip"

echo "Downloading $DOWNLOAD_URL"
curl -fSL -o "$ZIP_FILE" "$DOWNLOAD_URL"

echo "Extracting to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
unzip -o "$ZIP_FILE" -d "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/Mesen"

mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/Mesen" "$BIN_DIR/mesen"

rm -f "$ZIP_FILE"
echo "MesenCE ${LATEST_VERSION} installed successfully"
echo "Make sure $BIN_DIR is in your PATH"
