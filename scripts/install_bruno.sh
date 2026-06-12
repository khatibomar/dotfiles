#!/usr/bin/env bash
set -euo pipefail

LATEST_VERSION=$(curl -s https://api.github.com/repos/usebruno/bruno/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')

if [[ -z "$LATEST_VERSION" ]]; then
  echo "Failed to fetch latest Bruno version"
  exit 1
fi

echo "Latest Bruno version: $LATEST_VERSION"

RPM_URL="https://github.com/usebruno/bruno/releases/download/v${LATEST_VERSION}/bruno_${LATEST_VERSION}_x86_64_linux.rpm"
RPM_FILE="/tmp/bruno_${LATEST_VERSION}_x86_64_linux.rpm"

echo "Downloading $RPM_URL"
curl -fSL -o "$RPM_FILE" "$RPM_URL"

echo "Installing Bruno v${LATEST_VERSION}..."
sudo rpm -Uvh --replacepkgs "$RPM_FILE"

rm -f "$RPM_FILE"
echo "Bruno v${LATEST_VERSION} installed successfully"
