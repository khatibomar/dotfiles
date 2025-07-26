#!/bin/bash

set -e

TMP_RPM="/tmp/vscode.rpm"
VS_CODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"

echo "📦 Downloading latest VS Code RPM to $TMP_RPM ..."
curl -L "$VS_CODE_URL" -o "$TMP_RPM"

echo "💾 Installing VS Code..."
sudo rpm -Uvh "$TMP_RPM"

echo "🧹 Cleaning up..."
rm -f "$TMP_RPM"

echo "✅ Done. Run it with: code"
