#!/bin/bash

echo "Patching Discord Flatpak for drag and drop..."
flatpak override --user \
  --filesystem=xdg-download \
  --filesystem=xdg-videos \
  --filesystem=~/.var/app/org.telegram.desktop \
  com.discordapp.Discord
echo "Discord Flatpak patched."
