#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
GPG_CONFIG_DIR="${GNUPGHOME:-$HOME/.gnupg}"
GPG_CONFIG_FILE="$GPG_CONFIG_DIR/gpg-agent.conf"
GPG_CONFIG_SOURCE="$DOTFILES_DIR/config/gnupg/gpg-agent.conf"

if [ ! -x /usr/bin/pinentry-qt ]; then
    echo "Install pinentry-qt before configuring KDE Wallet signing." >&2
    exit 1
fi

mkdir -p "$GPG_CONFIG_DIR"
chmod 700 "$GPG_CONFIG_DIR"
candidate=$(mktemp "$GPG_CONFIG_DIR/gpg-agent.conf.new.XXXXXX")
trap 'rm -f "$candidate"' EXIT
cat "$GPG_CONFIG_SOURCE" > "$candidate"
printf '\npinentry-program %s\n' "$GPG_CONFIG_DIR/pinentry-kde-wallet" >> "$candidate"
if [ -e "$GPG_CONFIG_FILE" ] && ! cmp -s "$candidate" "$GPG_CONFIG_FILE"; then
    backup=$(mktemp "$GPG_CONFIG_FILE.backup.XXXXXX")
    cp -p "$GPG_CONFIG_FILE" "$backup"
    echo "Backed up agent settings to $backup"
fi
install -m 700 "$DOTFILES_DIR/config/gnupg/pinentry-kde-wallet" "$GPG_CONFIG_DIR/pinentry-kde-wallet"
install -m 600 "$candidate" "$GPG_CONFIG_FILE"
gpgconf --check-options gpg-agent
gpgconf --reload gpg-agent
echo "GPG signing configured for KDE Wallet with a 24-hour memory cache."
echo "On the next prompt, select Save passphrase in password manager."
