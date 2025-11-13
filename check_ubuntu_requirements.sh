#!/bin/bash
# Script to check system requirements for Nextcloud Carousel on Ubuntu 25.04

echo "═══════════════════════════════════════════════════════════"
echo "  Nextcloud Carousel - Ubuntu 25.04 Requirements Check"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Function to search for available packages
search_packages() {
    echo "🔍 Searching for available KDE packages on this system..."
    echo ""
    echo "Plasma framework packages:"
    apt-cache search plasma-framework 2>/dev/null | grep -i "dev\|6" | head -5 || echo "   (apt-cache not available, try: apt search plasma-framework)"
    echo ""
    echo "Kirigami packages:"
    apt-cache search kirigami 2>/dev/null | grep -i "dev\|6\|2" | head -5 || echo "   (apt-cache not available, try: apt search kirigami)"
    echo ""
    echo "KCMUtils packages:"
    apt-cache search kcmutils 2>/dev/null | grep -i "dev\|6" | head -5 || echo "   (apt-cache not available, try: apt search kcmutils)"
    echo ""
}

# Check Ubuntu version
echo "📋 System Information:"
echo "   Ubuntu Version:"
lsb_release -a 2>/dev/null | grep -E "Description|Release" || echo "   ⚠️  lsb_release not found"
echo ""

# Check KDE Plasma (multiple methods)
echo "🔍 Checking KDE Plasma:"
PLASMA_VERSION=""
PLASMA_INSTALLED=false

# Method 1: Check if plasmashell is running
PLASMA_VERSION=$(plasmashell --version 2>/dev/null | head -1)
if [ -n "$PLASMA_VERSION" ]; then
    echo "   ✅ Plasma running: $PLASMA_VERSION"
    PLASMA_INSTALLED=true
    PLASMA_MAJOR=$(echo "$PLASMA_VERSION" | grep -oE "[0-9]+\.[0-9]+" | head -1 | cut -d. -f1)
    if [ "$PLASMA_MAJOR" -ge 6 ]; then
        echo "   ✅ Plasma version 6.x or higher (compatible)"
    else
        echo "   ⚠️  Plasma version is below 6.0 (may not work)"
    fi
else
    # Method 2: Check if Plasma packages are installed
    if dpkg -l | grep -qE "^ii.*plasma-desktop|^ii.*plasma-workspace|^ii.*kde-plasma|^ii.*libplasma"; then
        PLASMA_PACKAGES=$(dpkg -l | grep -E "^ii.*(plasma-desktop|plasma-workspace|kde-plasma|libplasma)" | head -3 | awk '{print $2}' | tr '\n' ' ')
        echo "   ✅ Plasma packages installed (but plasmashell not running)"
        echo "   💡 Found packages: $PLASMA_PACKAGES"
        PLASMA_INSTALLED=true
        
        # Try to get version from package (handle epoch:version format)
        PLASMA_PKG_VERSION=$(dpkg -l | grep -E "^ii.*plasma-workspace" | awk '{print $3}' | head -1)
        if [ -n "$PLASMA_PKG_VERSION" ]; then
            # Remove epoch if present (format: epoch:version)
            VERSION_ONLY=$(echo "$PLASMA_PKG_VERSION" | sed 's/^[0-9]*://')
            PLASMA_MAJOR=$(echo "$VERSION_ONLY" | cut -d. -f1)
            # Check if it's a valid number before comparing
            if [ -n "$PLASMA_MAJOR" ] && [ "$PLASMA_MAJOR" -ge 6 ] 2>/dev/null; then
                echo "   ✅ Plasma package version 6.x or higher (compatible)"
            elif [ -n "$PLASMA_MAJOR" ] && [ "$PLASMA_MAJOR" -ge 5 ] 2>/dev/null; then
                echo "   ⚠️  Plasma package version 5.x (may work but 6.x recommended)"
            fi
        fi
    else
        echo "   ❌ Plasma not found"
        echo "   💡 Install with: sudo apt install kde-plasma-desktop"
        echo "   💡 Or minimal: sudo apt install plasma-desktop plasma-workspace"
    fi
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
elif dpkg -l | grep -qE "^ii.*libplasma|^ii.*libkirigami|^ii.*libkcmutils|^ii.*plasma-framework|^ii.*kirigami|^ii.*libkf[56].*plasma|^ii.*libkf[56].*kirigami|^ii.*libkf[56].*kcmutils"; then
    echo "   ✅ KF6 packages found (Ubuntu naming)"
    INSTALLED_KF6=$(dpkg -l | grep -E "^ii.*(libplasma|libkirigami|libkcmutils|plasma-framework|kirigami|libkf[56].*plasma|libkf[56].*kirigami|libkf[56].*kcmutils)" | head -5 | awk '{print $2}' | tr '\n' ' ')
    echo "   💡 Found packages: $INSTALLED_KF6"
else
    echo "   ❌ KF6 packages not found"
    echo "   💡 Try installing: sudo apt install libkf6plasma-dev libkf6kirigami2-dev libkf6kcmutils-dev"
    echo "   💡 Or alternatives: sudo apt install libkf5plasma-dev kirigami2-dev libkf6kcmutils-dev"
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

# Check required packages (Ubuntu package names - try multiple variants)
echo "🔍 Checking required packages:"
REQUIRED_PACKAGES=(
    "qt6-base-dev"
    "libkf6plasma-dev"
    "kirigami2-dev"
    "libkf6kcmutils-dev"
    "cmake"
)

# Alternative package names to check
ALTERNATIVE_NAMES=(
    "libplasma6-dev:libplasma-dev:plasma-framework-dev"
    "libkirigami2-6:libkirigami-dev:kirigami2-dev"
    "libkcmutils6:libkcmutils-dev:kcmutils-dev"
)


MISSING_PACKAGES=()
for package in "${REQUIRED_PACKAGES[@]}"; do
    # Check if package is installed (handle different naming)
    INSTALLED=false
    INSTALLED_NAME=""
    
    # Try primary name
    if dpkg -l | grep -q "^ii.*$package"; then
        INSTALLED=true
        INSTALLED_NAME="$package"
    else
        # Try alternative names based on package
        case "$package" in
            "libkf6plasma-dev")
                for alt in libkf5plasma-dev libplasma6-dev libplasma-dev libplasma6 plasma-framework-dev libkf6-plasma-dev; do
                    if dpkg -l | grep -qE "^ii.*$alt"; then
                        INSTALLED=true
                        INSTALLED_NAME="$alt"
                        break
                    fi
                done
                ;;
            "kirigami2-dev")
                for alt in libkirigami-dev libkf5kirigami2-5 libkirigami2 libkf6kirigami2-dev libkf6-kirigami-dev libkf5-kirigami-dev libkirigami2-6; do
                    if dpkg -l | grep -qE "^ii.*$alt"; then
                        INSTALLED=true
                        INSTALLED_NAME="$alt"
                        break
                    fi
                done
                ;;
            "libkf6kcmutils-dev")
                for alt in libkf6kcmutils-dev libkf5kcmutils-dev libkcmutils6 libkcmutils-dev libkcmutils kcmutils-dev libkf6-kcmutils-dev libkf5-kcmutils-dev; do
                    if dpkg -l | grep -qE "^ii.*$alt"; then
                        INSTALLED=true
                        INSTALLED_NAME="$alt"
                        break
                    fi
                done
                ;;
        esac
    fi
    
    if [ "$INSTALLED" = true ]; then
        if [ -n "$INSTALLED_NAME" ] && [ "$INSTALLED_NAME" != "$package" ]; then
            echo "   ✅ $package (found as: $INSTALLED_NAME)"
        else
            echo "   ✅ $package"
        fi
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

if [ "$PLASMA_INSTALLED" = false ] || [ -z "$QT_VERSION" ] || [ ${#MISSING_PACKAGES[@]} -gt 0 ] || [ ${#MISSING_MODULES[@]} -gt 0 ]; then
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
    if [ "$PLASMA_INSTALLED" = false ]; then
        echo "  sudo apt install kde-plasma-desktop"
        echo "  # OR for minimal install:"
        echo "  sudo apt install plasma-desktop plasma-workspace"
    fi
    if [ -z "$QT_VERSION" ]; then
        echo "  sudo apt install qt6-base-dev"
    fi
    echo ""
    echo "Note: On Ubuntu 25.04, package names may vary. Based on your system, try:"
    echo "  sudo apt install libkf6plasma-dev kirigami2-dev libkf6kcmutils-dev"
    echo "  # OR alternatives:"
    echo "  sudo apt install libkf5plasma-dev libkirigami-dev libkf6kcmutils-dev"
    echo "  # OR:"
    echo "  sudo apt install libplasma6-dev libkirigami2-6 libkcmutils6"
    echo ""
    echo "To find exact package names on your system, run:"
    echo "  apt search plasma-framework | grep -i dev"
    echo "  apt search kirigami | grep -i dev"
    echo "  apt search kcmutils | grep -i dev"
    echo ""
    read -p "Show available packages now? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        search_packages
    fi
else
    echo "✅ All requirements are met!"
    echo "   You can proceed with installation."
fi
echo ""

