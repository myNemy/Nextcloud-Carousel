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

# Check KF6
echo "🔍 Checking KDE Frameworks 6:"
KF6_VERSION=$(pkg-config --modversion KF6Plasma 2>/dev/null)
if [ -n "$KF6_VERSION" ]; then
    echo "   ✅ KF6 found: $KF6_VERSION"
else
    echo "   ❌ KF6 not found"
    echo "   💡 Install with: sudo apt install libkf6plasma-dev"
fi
echo ""

# Check QML modules
echo "🔍 Checking QML modules:"
QML_MODULES=(
    "org.kde.kirigami"
    "org.kde.kcmutils"
    "org.kde.plasma.core"
    "org.kde.kquickcontrols"
)

MISSING_MODULES=()
for module in "${QML_MODULES[@]}"; do
    if qml6 --list-types | grep -q "$module" 2>/dev/null; then
        echo "   ✅ $module"
    else
        echo "   ❌ $module (missing)"
        MISSING_MODULES+=("$module")
    fi
done
echo ""

# Check required packages
echo "🔍 Checking required packages:"
REQUIRED_PACKAGES=(
    "qt6-base-dev"
    "libkf6plasma-dev"
    "libkf6kirigami2-dev"
    "libkf6kcmutils-dev"
    "cmake"
)

MISSING_PACKAGES=()
for package in "${REQUIRED_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii.*$package"; then
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

if [ -z "$PLASMA_VERSION" ] || [ -z "$QT_VERSION" ] || [ -z "$KF6_VERSION" ] || [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo "⚠️  Some requirements are missing!"
    echo ""
    echo "Install missing packages with:"
    echo "  sudo apt update"
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo "  sudo apt install ${MISSING_PACKAGES[*]}"
    fi
    if [ -z "$PLASMA_VERSION" ]; then
        echo "  sudo apt install kde-plasma-desktop"
    fi
    if [ -z "$QT_VERSION" ]; then
        echo "  sudo apt install qt6-base-dev"
    fi
    if [ -z "$KF6_VERSION" ]; then
        echo "  sudo apt install libkf6plasma-dev"
    fi
else
    echo "✅ All requirements are met!"
    echo "   You can proceed with installation."
fi
echo ""

