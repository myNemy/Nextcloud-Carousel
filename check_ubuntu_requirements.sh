#!/bin/bash
# Script to check system requirements for Nextcloud Carousel on Ubuntu 25.04

echo "═══════════════════════════════════════════════════════════"
echo "  Nextcloud Carousel - Ubuntu 25.04 Requirements Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check Ubuntu version
echo "📋 System Information:"
echo "   Ubuntu Version:"
lsb_release -a 2>/dev/null | grep -E "Description|Release" || echo "   ⚠️  lsb_release not found"
echo ""

# Check KDE Plasma
echo "🔍 Checking KDE Plasma:"
PLASMA_VERSION=$(plasmashell --version 2>/dev/null | head -1)
if [ -n "$PLASMA_VERSION" ]; then
    echo "   ✅ Plasma found: $PLASMA_VERSION"
    PLASMA_MAJOR=$(echo "$PLASMA_VERSION" | grep -oE "[0-9]+\.[0-9]+" | head -1 | cut -d. -f1)
    if [ "$PLASMA_MAJOR" -ge 6 ]; then
        echo "   ✅ Plasma version 6.x or higher (compatible)"
    else
        echo "   ⚠️  Plasma version is below 6.0 (may not work)"
    fi
else
    echo "   ❌ Plasma not found or not running"
    echo "   💡 Install with: sudo apt install kde-plasma-desktop"
fi
echo ""

# Check Qt
echo "🔍 Checking Qt:"
QT_VERSION=$(qmake6 --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
if [ -n "$QT_VERSION" ]; then
    echo "   ✅ Qt6 found: $QT_VERSION"
    QT_MAJOR=$(echo "$QT_VERSION" | cut -d. -f1)
    if [ "$QT_MAJOR" -ge 6 ]; then
        echo "   ✅ Qt version 6.x or higher (compatible)"
    else
        echo "   ⚠️  Qt version is below 6.0 (may not work)"
    fi
else
    echo "   ❌ Qt6 not found"
    echo "   💡 Install with: sudo apt install qt6-base-dev"
fi
echo ""

# Check KF6 (via packages on Ubuntu)
echo "🔍 Checking KDE Frameworks 6:"
KF6_VERSION=$(pkg-config --modversion KF6Plasma 2>/dev/null)
if [ -n "$KF6_VERSION" ]; then
    echo "   ✅ KF6 found via pkg-config: $KF6_VERSION"
elif dpkg -l | grep -qE "^ii.*libplasma|^ii.*libkirigami|^ii.*libkcmutils"; then
    echo "   ✅ KF6 packages found (Ubuntu naming)"
    echo "   💡 Note: Ubuntu uses different package names (libplasma-dev, libkirigami-dev, etc.)"
else
    echo "   ❌ KF6 packages not found"
    echo "   💡 Install with: sudo apt install libplasma-dev libkirigami-dev libkcmutils-dev"
fi
echo ""

# Check QML modules (check via package names instead)
echo "🔍 Checking QML modules (via packages):"
QML_PACKAGES=(
    "qml6-module-org-kde-kirigami"
    "qml6-module-org-kde-kcmutils"
    "qml6-module-org-kde-plasma"
    "qml6-module-org-kde-kquickcontrols"
)

MISSING_MODULES=()
for package in "${QML_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii.*$package"; then
        echo "   ✅ $package"
    else
        echo "   ❌ $package (not installed)"
        MISSING_MODULES+=("$package")
    fi
done
echo ""

# Check required packages (Ubuntu package names)
echo "🔍 Checking required packages:"
REQUIRED_PACKAGES=(
    "qt6-base-dev"
    "libplasma-dev"
    "libkirigami-dev"
    "libkcmutils-dev"
    "cmake"
)

# Also check alternative names
ALTERNATIVE_PACKAGES=(
    "libkf6plasma-dev:libplasma-dev"
    "libkf6kirigami2-dev:libkirigami-dev"
    "libkf6kcmutils-dev:libkcmutils-dev"
)

MISSING_PACKAGES=()
for package in "${REQUIRED_PACKAGES[@]}"; do
    # Check if package is installed (handle different naming)
    INSTALLED=false
    if dpkg -l | grep -q "^ii.*$package"; then
        INSTALLED=true
    else
        # Try alternative names
        case "$package" in
            "libplasma-dev")
                if dpkg -l | grep -qE "^ii.*libplasma|^ii.*libkf6.*plasma"; then
                    INSTALLED=true
                fi
                ;;
            "libkirigami-dev")
                if dpkg -l | grep -qE "^ii.*libkirigami|^ii.*libkf6.*kirigami"; then
                    INSTALLED=true
                fi
                ;;
            "libkcmutils-dev")
                if dpkg -l | grep -qE "^ii.*libkcmutils|^ii.*libkf6.*kcmutils"; then
                    INSTALLED=true
                fi
                ;;
        esac
    fi
    
    if [ "$INSTALLED" = true ]; then
        echo "   ✅ $package"
    else
        echo "   ❌ $package (not installed)"
        MISSING_PACKAGES+=("$package")
    fi
done
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "  SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ -z "$PLASMA_VERSION" ] || [ -z "$QT_VERSION" ] || [ ${#MISSING_PACKAGES[@]} -gt 0 ] || [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    echo "⚠️  Some requirements are missing!"
    echo ""
    echo "Install missing packages with:"
    echo "  sudo apt update"
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo "  sudo apt install ${MISSING_PACKAGES[*]}"
    fi
    if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
        echo "  sudo apt install ${MISSING_MODULES[*]}"
    fi
    if [ -z "$PLASMA_VERSION" ]; then
        echo "  sudo apt install kde-plasma-desktop"
        echo "  # OR for minimal install:"
        echo "  sudo apt install plasma-desktop plasma-workspace"
    fi
    if [ -z "$QT_VERSION" ]; then
        echo "  sudo apt install qt6-base-dev"
    fi
    echo ""
    echo "Note: On Ubuntu, package names may differ:"
    echo "  - libkf6plasma-dev → libplasma-dev"
    echo "  - libkf6kirigami2-dev → libkirigami-dev"
    echo "  - libkf6kcmutils-dev → libkcmutils-dev"
else
    echo "✅ All requirements are met!"
    echo "   You can proceed with installation."
fi
echo ""

