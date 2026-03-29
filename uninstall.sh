#!/bin/bash
# Uninstallation script for Nextcloud Plasma Wallpaper Plugins (carousel + video)
#
# Removes only paths for plugin IDs org.nextcloud.carousel / org.nextcloud.video,
# the carousel C++ QML module, and caches named nextcloud-carousel — not other Nextcloud software.

# Do not use set -e — we want to report partial success and optional sudo failures clearly

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_IMAGE_NAME="org.nextcloud.carousel"
PLUGIN_VIDEO_NAME="org.nextcloud.video"

# Same home resolution as install.sh (sudo ./uninstall.sh must target the real user, not /root)
PLASMA_USER_HOME="${HOME}"
if [ "$(id -u)" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        _suh="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
        if [ -n "$_suh" ] && [ -d "$_suh" ]; then
            PLASMA_USER_HOME="$_suh"
        else
            echo "⚠️  Could not resolve home for SUDO_USER=$SUDO_USER; using $HOME"
        fi
    else
        echo "⚠️  Running as root without SUDO_USER: user paths use $HOME/.local/..."
        echo "    To remove another user's files, run: sudo -u <user> $0"
        echo ""
    fi
fi
unset _suh

NC_USER_LOCAL="${PLASMA_USER_HOME}/.local"
PLUGIN_IMAGE_DIR="${NC_USER_LOCAL}/share/plasma/wallpapers/${PLUGIN_IMAGE_NAME}"
PLUGIN_VIDEO_DIR="${NC_USER_LOCAL}/share/plasma/wallpapers/${PLUGIN_VIDEO_NAME}"
SYSTEM_PLASMA_WALLPAPER_ROOT="/usr/share/plasma/wallpapers"
SYSTEM_IMAGE_DIR="${SYSTEM_PLASMA_WALLPAPER_ROOT}/${PLUGIN_IMAGE_NAME}"
SYSTEM_VIDEO_DIR="${SYSTEM_PLASMA_WALLPAPER_ROOT}/${PLUGIN_VIDEO_NAME}"
QML_PLUGIN_USER="${NC_USER_LOCAL}/lib/qt6/qml/org/nextcloud/carousel"
QML_PLUGIN_SYSTEM="/usr/lib/qt6/qml/org/nextcloud/carousel"

# Cache paths (C++ downloader uses plasmashell cache; legacy path kept if present)
CACHE_PLASMA="${PLASMA_USER_HOME}/.cache/plasmashell/nextcloud-carousel"
CACHE_LEGACY="${PLASMA_USER_HOME}/.cache/nextcloud-carousel"

run_as_target_plasma_user() {
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" -- "$@"
    else
        "$@"
    fi
}

if [ -f "${SCRIPT_DIR}/scripts/plasma-nextcloud-common.sh" ]; then
    # shellcheck source=scripts/plasma-nextcloud-common.sh
    . "${SCRIPT_DIR}/scripts/plasma-nextcloud-common.sh"
    nc_prompt_obsolete_cleanup uninstall
fi

echo "═══════════════════════════════════════════════════════════"
echo "  UNINSTALL Nextcloud Carousel / Nextcloud Video (Plasma)"
echo "═══════════════════════════════════════════════════════════"
echo ""

USER_HAS=false
SYSTEM_HAS=false
[ -d "$PLUGIN_IMAGE_DIR" ] && USER_HAS=true
[ -d "$PLUGIN_VIDEO_DIR" ] && USER_HAS=true
[ -d "$QML_PLUGIN_USER" ] && USER_HAS=true
[ -d "$SYSTEM_IMAGE_DIR" ] && SYSTEM_HAS=true
[ -d "$SYSTEM_VIDEO_DIR" ] && SYSTEM_HAS=true
[ -d "$QML_PLUGIN_SYSTEM" ] && SYSTEM_HAS=true

if [ "$USER_HAS" != true ] && [ "$SYSTEM_HAS" != true ]; then
    if [ "${NC_OBSOLETE_REMOVED:-0}" -gt 0 ]; then
        echo "✅ Obsolete paths removed. No regular plugin installation detected under:"
        echo "   user or system paths (see list below)."
        echo ""
        echo "Checked:"
        echo "  User:   $PLUGIN_IMAGE_DIR"
        echo "          $PLUGIN_VIDEO_DIR"
        echo "          $QML_PLUGIN_USER"
        echo "  System: $SYSTEM_IMAGE_DIR"
        echo "          $SYSTEM_VIDEO_DIR"
        echo "          $QML_PLUGIN_SYSTEM"
        exit 0
    fi
    echo "⚠️  Nothing found to remove."
    echo ""
    echo "Checked:"
    echo "  User:   $PLUGIN_IMAGE_DIR"
    echo "          $PLUGIN_VIDEO_DIR"
    echo "          $QML_PLUGIN_USER"
    echo "  System: $SYSTEM_IMAGE_DIR"
    echo "          $SYSTEM_VIDEO_DIR"
    echo "          $QML_PLUGIN_SYSTEM"
    exit 1
fi

echo "Per-user paths (desktop user: $PLASMA_USER_HOME):"
[ -d "$PLUGIN_IMAGE_DIR" ] && echo "  • Carousel QML: $PLUGIN_IMAGE_DIR"
[ -d "$PLUGIN_VIDEO_DIR" ] && echo "  • Video QML:    $PLUGIN_VIDEO_DIR"
[ -d "$QML_PLUGIN_USER" ] && echo "  • C++ QML lib:  $QML_PLUGIN_USER"
echo ""
echo "System-wide paths (if installed with sudo ./install.sh → /usr):"
[ -d "$SYSTEM_IMAGE_DIR" ] && echo "  • Carousel: $SYSTEM_IMAGE_DIR"
[ -d "$SYSTEM_VIDEO_DIR" ] && echo "  • Video:    $SYSTEM_VIDEO_DIR"
[ -d "$QML_PLUGIN_SYSTEM" ] && echo "  • C++ QML:  $QML_PLUGIN_SYSTEM"
echo ""
echo "Nothing is deleted until you confirm. Cancel with \"n\" or Enter."
echo ""
read -p "Proceed with uninstallation of the paths listed above? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo "Removing user-local components..."
run_as_target_plasma_user rm -rf "$PLUGIN_IMAGE_DIR" 2>/dev/null || true
run_as_target_plasma_user rm -rf "$PLUGIN_VIDEO_DIR" 2>/dev/null || true
run_as_target_plasma_user rm -rf "$QML_PLUGIN_USER" 2>/dev/null || true
echo "✅ User-local plugin paths processed."

echo "Removing image cache (optional, frees disk)..."
run_as_target_plasma_user rm -rf "$CACHE_PLASMA" 2>/dev/null || true
run_as_target_plasma_user rm -rf "$CACHE_LEGACY" 2>/dev/null || true
echo "✅ Cache directories processed (~/.cache/plasmashell/nextcloud-carousel)."

if [ "$SYSTEM_HAS" = true ]; then
    echo ""
    echo "⚠️  System-wide installation detected (requires sudo to remove)."
    echo "   Targets: $SYSTEM_IMAGE_DIR"
    echo "            $SYSTEM_VIDEO_DIR"
    echo "            $QML_PLUGIN_SYSTEM"
    echo "   Nothing under /usr is deleted until you confirm below."
    echo ""
    read -p "Remove these system-wide paths? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if sudo rm -rf "$SYSTEM_IMAGE_DIR" "$SYSTEM_VIDEO_DIR" "$QML_PLUGIN_SYSTEM" 2>/dev/null; then
            echo "✅ System-wide components removed."
        else
            echo "⚠️  Could not remove some system paths (sudo password or permissions)."
            echo "   Manual cleanup:"
            echo "   sudo rm -rf $SYSTEM_IMAGE_DIR $SYSTEM_VIDEO_DIR $QML_PLUGIN_SYSTEM"
        fi
    else
        echo "   Skipped system paths — remove manually if needed (see commands above)."
    fi
fi

echo ""
echo "✅ Uninstall steps completed."
echo ""

CONFIG_FILE="${PLASMA_USER_HOME}/.config/plasmarc"
if [ -f "$CONFIG_FILE" ]; then
    if grep -qE 'org\.nextcloud\.(carousel|video)' "$CONFIG_FILE" 2>/dev/null; then
        echo "⚠️  Wallpaper entries may still be listed in:"
        echo "   $CONFIG_FILE"
        echo "   Remove stale entries manually if the UI still shows the old plugin."
    fi
fi

echo ""
echo "To apply:"
if command -v kstart >/dev/null 2>&1; then
    echo "  killall plasmashell && kstart plasmashell"
else
    echo "  killall plasmashell && plasmashell --replace &"
fi
echo ""
