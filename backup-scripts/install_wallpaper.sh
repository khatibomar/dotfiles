#!/bin/bash

WALLPAPER_DIR="$HOME/.local/share/wallpapers"

mkdir -p "$WALLPAPER_DIR"

echo "Copying wallpaper to $WALLPAPER_DIR"
cp wallpapers/839766.png "$WALLPAPER_DIR/"

echo "Applying wallpaper via plasma-apply-wallpaperimage"
plasma-apply-wallpaperimage "$WALLPAPER_DIR/839766.png"

echo "Wallpaper installed and applied successfully."
