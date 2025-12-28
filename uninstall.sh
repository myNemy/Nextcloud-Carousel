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

# Remove C++ component if installed (Livello 1: NextcloudDownloader)
QML_PLUGIN_USER="$HOME/.local/lib/qt6/qml/org/nextcloud/carousel"
QML_PLUGIN_SYSTEM="/usr/lib/qt6/qml/org/nextcloud/carousel"

if [ -d "$QML_PLUGIN_USER" ]; then
    echo "Removing C++ component from user installation..."
    rm -rf "$QML_PLUGIN_USER"
    echo "✅ C++ component removed from ~/.local/lib/qt6/qml/"
fi

if [ -d "$QML_PLUGIN_SYSTEM" ]; then
    echo "⚠️  C++ component found in system installation: $QML_PLUGIN_SYSTEM"
    echo "   This requires sudo to remove."
    read -p "   Remove system installation? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if sudo rm -rf "$QML_PLUGIN_SYSTEM" 2>/dev/null; then
            echo "✅ C++ component removed from /usr/lib/qt6/qml/"
        else
            echo "⚠️  Failed to remove system installation (may require sudo password)"
            echo "   You can remove it manually with: sudo rm -rf $QML_PLUGIN_SYSTEM"
        fi
    else
        echo "   Skipping system installation removal"
    fi
fi

# Remove cache directory (temporary files downloaded by NextcloudDownloader)
CACHE_DIR="$HOME/.cache/nextcloud-carousel"
if [ -d "$CACHE_DIR" ]; then
    echo "Removing cache directory (downloaded images)..."
    rm -rf "$CACHE_DIR"
    echo "✅ Cache directory removed"
fi

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
if command -v kstart >/dev/null 2>&1; then
    echo "  1. Restart plasmashell: killall plasmashell && kstart plasmashell"
else
    echo "  1. Restart plasmashell: killall plasmashell && plasmashell --replace &"
fi
echo "  2. Or restart KDE session"
echo ""
echo "The 'Nextcloud Carousel' plugin should no longer appear"
echo "in the list of available wallpapers."

