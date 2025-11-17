#!/bin/bash
# Installation script for Nextcloud Plasma Wallpaper Plugins

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_IMAGE_NAME="org.nextcloud.carousel"
PLUGIN_VIDEO_NAME="org.nextcloud.video"
PLUGIN_IMAGE_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_IMAGE_NAME}"
PLUGIN_VIDEO_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_VIDEO_NAME}"
SOURCE_IMAGE_DIR="${SCRIPT_DIR}/nextcloud-carousel"
SOURCE_VIDEO_DIR="${SCRIPT_DIR}/nextcloud-video"

echo "Installing Nextcloud Plasma Wallpaper Plugins..."
echo ""

# Install Image Carousel Plugin
if [ -d "$SOURCE_IMAGE_DIR" ]; then
    echo "Installing Nextcloud Carousel (Images) Plugin..."
    echo "Source: $SOURCE_IMAGE_DIR"
    echo "Destination: $PLUGIN_IMAGE_DIR"
    
    mkdir -p "$PLUGIN_IMAGE_DIR"
    cp -r "$SOURCE_IMAGE_DIR"/* "$PLUGIN_IMAGE_DIR/"
    echo "✅ Image plugin installed successfully!"
    
    # Compile translations for image plugin
    if command -v msgfmt >/dev/null 2>&1; then
        echo "Compiling translations for carousel plugin..."
        for po_file in "$SOURCE_IMAGE_DIR"/contents/locale/*/LC_MESSAGES/*.po; do
            if [ -f "$po_file" ]; then
                lang_dir=$(dirname "$po_file")
                lang=$(basename "$(dirname "$lang_dir")")
                po_name=$(basename "$po_file" .po)
                mo_file="$PLUGIN_IMAGE_DIR/contents/locale/$lang/LC_MESSAGES/${po_name}.mo"
                mkdir -p "$(dirname "$mo_file")"
                msgfmt -o "$mo_file" "$po_file" 2>/dev/null && echo "  ✅ Compiled $lang translation" || echo "  ⚠️  Failed to compile $lang translation"
            fi
        done
    fi
else
    echo "⚠️  Image plugin source not found: $SOURCE_IMAGE_DIR"
fi

echo ""

# Install Video Plugin
if [ -d "$SOURCE_VIDEO_DIR" ]; then
    echo "Installing Nextcloud Video Plugin..."
    echo "Source: $SOURCE_VIDEO_DIR"
    echo "Destination: $PLUGIN_VIDEO_DIR"
    
    mkdir -p "$PLUGIN_VIDEO_DIR"
    cp -r "$SOURCE_VIDEO_DIR"/* "$PLUGIN_VIDEO_DIR/"
    echo "✅ Video plugin installed successfully!"
    
    # Compile translations for video plugin
    if command -v msgfmt >/dev/null 2>&1; then
        echo "Compiling translations for video plugin..."
        for po_file in "$SOURCE_VIDEO_DIR"/contents/locale/*/LC_MESSAGES/*.po; do
            if [ -f "$po_file" ]; then
                lang_dir=$(dirname "$po_file")
                lang=$(basename "$(dirname "$lang_dir")")
                po_name=$(basename "$po_file" .po)
                mo_file="$PLUGIN_VIDEO_DIR/contents/locale/$lang/LC_MESSAGES/${po_name}.mo"
                mkdir -p "$(dirname "$mo_file")"
                msgfmt -o "$mo_file" "$po_file" 2>/dev/null && echo "  ✅ Compiled $lang translation" || echo "  ⚠️  Failed to compile $lang translation"
            fi
        done
    fi
else
    echo "⚠️  Video plugin source not found: $SOURCE_VIDEO_DIR"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  HOW TO CONFIGURE THE PLUGINS:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Simplest method:"
echo "  1. Right-click on desktop → 'Configure Desktop and Wallpaper'"
echo "  2. Select 'Nextcloud Carousel' (images) or 'Nextcloud Video' from the wallpaper list"
echo "  3. Click 'Configure'"
echo "  4. Enter Nextcloud URL, username, password, and path"
echo ""
echo "Alternative method:"
echo "  System Settings → Appearance → Wallpaper"
echo "  Select plugin → Configure"
echo ""
echo "For complete details, see: README.md"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  IMPORTANT: Restart plasmashell to load the plugins:"
if command -v kstart >/dev/null 2>&1; then
    echo "   killall plasmashell && kstart plasmashell"
else
    echo "   killall plasmashell && plasmashell --replace &"
fi
echo ""
echo "To uninstall:"
echo "  Images: rm -rf $PLUGIN_IMAGE_DIR"
echo "  Video:  rm -rf $PLUGIN_VIDEO_DIR"

