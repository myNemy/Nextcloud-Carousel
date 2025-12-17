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
MISSING_FILES=0

# Check essential files
if [ ! -f "$PLUGIN_DIR/metadata.json" ]; then
    echo "   ❌ metadata.json missing!"
    MISSING_FILES=1
else
    echo "   ✅ metadata.json found"
fi

if [ ! -f "$PLUGIN_DIR/contents/ui/main.qml" ]; then
    echo "   ❌ main.qml missing!"
    MISSING_FILES=1
else
    echo "   ✅ main.qml found"
fi

if [ ! -f "$PLUGIN_DIR/contents/ui/config.qml" ]; then
    echo "   ❌ config.qml missing!"
    MISSING_FILES=1
else
    echo "   ✅ config.qml found"
fi

if [ ! -f "$PLUGIN_DIR/contents/ui/ImageComponent.qml" ]; then
    echo "   ❌ ImageComponent.qml missing!"
    MISSING_FILES=1
else
    echo "   ✅ ImageComponent.qml found"
fi

if [ ! -f "$PLUGIN_DIR/contents/config/main.xml" ]; then
    echo "   ❌ main.xml (config) missing!"
    MISSING_FILES=1
else
    echo "   ✅ main.xml (config) found"
fi

if [ $MISSING_FILES -eq 1 ]; then
    echo "   ❌ Some essential files are missing!"
    echo "   Run: ./install.sh to reinstall"
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
else
    echo "   ✅ KPackageStructure correct"
fi

# Verify plugin ID
if ! grep -q '"Id": "org.nextcloud.carousel"' "$PLUGIN_DIR/metadata.json"; then
    echo "   ⚠️  Plugin ID might be incorrect"
else
    echo "   ✅ Plugin ID correct"
fi

echo "   ✅ metadata.json OK"
echo ""

echo "4. Verifying Qt/KDE versions..."
# Check Qt version
if command -v qml >/dev/null 2>&1; then
    QT_VERSION=$(qml --version 2>/dev/null | head -1)
    if [ -n "$QT_VERSION" ]; then
        echo "   ✅ Qt version: $QT_VERSION"
        # Check if Qt 6.x
        if echo "$QT_VERSION" | grep -qE "Qt 6\.[0-9]"; then
            echo "   ✅ Qt 6.x detected (compatible)"
        else
            echo "   ⚠️  Qt version might not be 6.x (plugin requires Qt 6)"
        fi
    fi
else
    echo "   ⚠️  qml command not found (Qt might not be installed)"
fi

# Check KDE Plasma version
if command -v plasmashell >/dev/null 2>&1; then
    PLASMA_VERSION=$(plasmashell --version 2>/dev/null | head -1)
    if [ -n "$PLASMA_VERSION" ]; then
        echo "   ✅ Plasma version: $PLASMA_VERSION"
        # Check if Plasma 6.x
        if echo "$PLASMA_VERSION" | grep -qE "Plasma 6\.[0-9]|KDE Plasma 6"; then
            echo "   ✅ Plasma 6.x detected (compatible)"
        else
            echo "   ⚠️  Plasma version might not be 6.x (plugin requires Plasma 6)"
        fi
    fi
else
    echo "   ⚠️  plasmashell not found (KDE Plasma might not be installed)"
fi
echo ""

echo "5. Checking QML imports (Qt/KDE modules)..."
# Use qmlimportscanner to verify QML imports (Qt/KDE official tool)
if command -v qmlimportscanner >/dev/null 2>&1; then
    echo "   Scanning QML imports..."
    IMPORTS=$(qmlimportscanner -rootPath "$PLUGIN_DIR/contents/ui" 2>/dev/null)
    if [ -n "$IMPORTS" ]; then
        # Check for required Qt modules
        if echo "$IMPORTS" | grep -q "QtQuick"; then
            echo "   ✅ QtQuick module found"
        else
            echo "   ⚠️  QtQuick module not found"
        fi
        
        # Check for required KDE modules
        if echo "$IMPORTS" | grep -q "org.kde.plasma"; then
            echo "   ✅ KDE Plasma modules found"
        else
            echo "   ⚠️  KDE Plasma modules not found"
        fi
        
        if echo "$IMPORTS" | grep -q "org.kde.kirigami"; then
            echo "   ✅ Kirigami module found"
        else
            echo "   ⚠️  Kirigami module not found"
        fi
        
        # Check for kquickcontrols (might be deprecated but still used)
        if echo "$IMPORTS" | grep -q "org.kde.kquickcontrols"; then
            echo "   ✅ kquickcontrols module found"
        fi
    else
        echo "   ⚠️  Could not scan QML imports"
    fi
else
    echo "   ℹ️  qmlimportscanner not available (install qt6-declarative-dev)"
    echo "   ℹ️  Skipping QML import verification"
fi
echo ""

echo "6. Checking for QML syntax errors..."
# Try to validate QML files (basic check)
if command -v qmlformat >/dev/null 2>&1; then
    echo "   Checking QML syntax..."
    QML_FILES=("main.qml" "config.qml" "ImageComponent.qml")
    for qml_file in "${QML_FILES[@]}"; do
        if [ -f "$PLUGIN_DIR/contents/ui/$qml_file" ]; then
            if qmlformat --check "$PLUGIN_DIR/contents/ui/$qml_file" >/dev/null 2>&1; then
                echo "   ✅ $qml_file syntax OK"
            else
                echo "   ⚠️  $qml_file might have syntax issues"
            fi
        fi
    done
else
    echo "   ℹ️  qmlformat not available, skipping syntax check"
    echo "   💡 Install with: sudo apt install qml6-module-qtquick-tools"
fi
echo ""

echo "7. Verifying KPackage structure..."
# Verify KPackage structure using KDE standards
# KPackage plugins should follow specific structure
if [ -d "$PLUGIN_DIR/contents" ]; then
    echo "   ✅ contents/ directory found"
    
    if [ -d "$PLUGIN_DIR/contents/ui" ]; then
        echo "   ✅ contents/ui/ directory found"
    else
        echo "   ⚠️  contents/ui/ directory missing"
    fi
    
    if [ -d "$PLUGIN_DIR/contents/config" ]; then
        echo "   ✅ contents/config/ directory found"
    else
        echo "   ⚠️  contents/config/ directory missing"
    fi
    
    if [ -d "$PLUGIN_DIR/contents/locale" ]; then
        echo "   ✅ contents/locale/ directory found (translations)"
    fi
else
    echo "   ❌ contents/ directory missing (invalid KPackage structure)"
fi
echo ""

echo "8. Checking recent logs for errors..."
# Check for recent QML/Plasma errors
if command -v journalctl >/dev/null 2>&1; then
    RECENT_ERRORS=$(journalctl --user -n 50 --no-pager 2>/dev/null | grep -i "nextcloud\|carousel\|qml" | grep -i "error\|fail" | wc -l)
    if [ "$RECENT_ERRORS" -gt 0 ]; then
        echo "   ⚠️  Found $RECENT_ERRORS recent errors in logs"
        echo "   Check: journalctl --user -n 100 | grep -i 'nextcloud\|carousel'"
    else
        echo "   ✅ No recent errors found in logs"
    fi
else
    echo "   ℹ️  journalctl not available, skipping log check"
fi
echo ""

echo "9. Restarting plasmashell..."
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
echo "  - Check logs: journalctl --user -n 100 | grep -i 'nextcloud\|carousel\|qml'"
echo "  - Check for QML errors: journalctl --user -n 100 | grep -i 'error\|fail'"
echo "  - Verify Qt/KDE versions: qml --version && plasmashell --version"
echo "  - Verify QML imports: qmlimportscanner -rootPath $PLUGIN_DIR/contents/ui"
echo "  - Restart KDE session (log out and back in)"
echo ""
echo "Qt/KDE Tools for debugging:"
echo "  - qmlimportscanner: Verify QML module imports"
echo "  - qmlformat: Format and check QML syntax"
echo "  - qmlscene: Test QML files independently"
echo "  - kpackage: Verify KPackage structure (if available)"
echo ""
echo "For memory issues (OOM Killer):"
echo "  - Cache is disabled by default to prevent memory leaks"
echo "  - Check memory usage: free -h"
echo "  - Monitor StackView depth in logs"
echo ""

