#!/bin/bash
# Script to verify and fix plugin installation

echo "═══════════════════════════════════════════════════════════"
echo "  Verify Nextcloud Carousel Plugin Installation"
echo "═══════════════════════════════════════════════════════════"
echo ""

PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/org.nextcloud.carousel"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "❌ Plugin not found in: $PLUGIN_DIR"
    echo "   Run first: ./install.sh"
    exit 1
fi

echo "1. Verifying plugin structure..."
if [ ! -f "$PLUGIN_DIR/metadata.json" ]; then
    echo "   ❌ metadata.json missing!"
    exit 1
fi
if [ ! -f "$PLUGIN_DIR/contents/ui/main.qml" ]; then
    echo "   ❌ main.qml missing!"
    exit 1
fi
echo "   ✅ Structure OK"
echo ""

echo "2. Fixing permissions..."
chmod -R 755 "$PLUGIN_DIR"
echo "   ✅ Permissions fixed"
echo ""

echo "3. Verifying metadata.json..."
# Verify that KPackageStructure is correct
if ! grep -q '"KPackageStructure": "Plasma/Wallpaper"' "$PLUGIN_DIR/metadata.json"; then
    echo "   ⚠️  KPackageStructure might be incorrect"
fi
echo "   ✅ metadata.json OK"
echo ""

echo "4. Restarting plasmashell..."
if pgrep -x plasmashell > /dev/null; then
    echo "   Stopping plasmashell..."
    killall plasmashell 2>/dev/null
    sleep 2
fi

echo "   Starting plasmashell with kstart..."
if command -v kstart >/dev/null 2>&1; then
    kstart plasmashell > /dev/null 2>&1
else
    # Fallback to plasmashell --replace if kstart not available
    plasmashell --replace > /dev/null 2>&1 &
fi
sleep 3

if pgrep -x plasmashell > /dev/null; then
    echo "   ✅ plasmashell restarted"
else
    echo "   ⚠️  plasmashell might not have started correctly"
    echo "   Try manually: killall plasmashell && kstart plasmashell"
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  COMPLETED"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Now try:"
echo "  1. Right-click on desktop → 'Configure Desktop and Wallpaper'"
echo "  2. Look for 'Nextcloud Carousel' in the list"
echo ""
echo "If it still doesn't appear:"
echo "  - Check logs: journalctl --user -n 100 | grep -i plasma"
echo "  - Restart KDE session"
echo ""

