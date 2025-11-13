#!/bin/bash
# Installation script for Nextcloud Carousel Plasma Wallpaper Plugin

set -e

PLUGIN_NAME="org.nextcloud.carousel"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_NAME}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nextcloud-carousel"

echo "Installing Nextcloud Carousel Wallpaper Plugin..."
echo "Source: $SOURCE_DIR"
echo "Destination: $PLUGIN_DIR"

# Create destination directory
mkdir -p "$PLUGIN_DIR"

# Copy plugin files
cp -r "$SOURCE_DIR"/* "$PLUGIN_DIR/"

echo "Plugin installed successfully!"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  HOW TO CONFIGURE THE PLUGIN:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Simplest method:"
echo "  1. Right-click on desktop → 'Configure Desktop and Wallpaper'"
echo "  2. Select 'Nextcloud Carousel' from the wallpaper list"
echo "  3. Click 'Configure'"
echo "  4. Enter Nextcloud URL, username, password, and photo path"
echo ""
echo "Alternative method:"
echo "  System Settings → Appearance → Wallpaper"
echo "  Select 'Nextcloud Carousel' → Configure"
echo ""
echo "For complete details, see: README.md"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  IMPORTANT: Restart plasmashell to load the plugin:"
if command -v kstart >/dev/null 2>&1; then
    echo "   killall plasmashell && kstart plasmashell"
else
    echo "   killall plasmashell && plasmashell --replace &"
fi
echo ""
echo "To uninstall: rm -rf $PLUGIN_DIR"

