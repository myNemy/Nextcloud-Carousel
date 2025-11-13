#!/bin/bash
# Uninstallation script for Nextcloud Carousel Plasma Wallpaper Plugin

set -e

PLUGIN_NAME="org.nextcloud.carousel"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_NAME}"

echo "═══════════════════════════════════════════════════════════"
echo "  UNINSTALL Nextcloud Carousel Plugin"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "⚠️  Plugin does not seem to be installed in:"
    echo "   $PLUGIN_DIR"
    echo ""
    echo "Manually verify if it exists in other locations:"
    echo "  - ~/.local/share/plasma/wallpapers/"
    echo "  - /usr/share/plasma/wallpapers/"
    exit 1
fi

echo "Plugin found in: $PLUGIN_DIR"
echo ""
read -p "Do you want to proceed with uninstallation? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo "Removing plugin..."
rm -rf "$PLUGIN_DIR"

echo ""
echo "✅ Plugin removed successfully!"
echo ""

# Also remove configuration files if they exist
CONFIG_FILE="$HOME/.config/plasmarc"
if [ -f "$CONFIG_FILE" ]; then
    echo "Checking configuration file..."
    if grep -q "org.nextcloud.carousel" "$CONFIG_FILE" 2>/dev/null; then
        echo "⚠️  Found configurations in plasmarc file"
        echo "   You may want to remove them manually from:"
        echo "   $CONFIG_FILE"
    fi
fi

echo ""
echo "To complete uninstallation:"
echo "  1. Restart plasmashell: killall plasmashell && plasmashell &"
echo "  2. Or restart KDE session"
echo ""
echo "The 'Nextcloud Carousel' plugin should no longer appear"
echo "in the list of available wallpapers."

