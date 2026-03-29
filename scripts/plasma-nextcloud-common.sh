# shellcheck shell=bash
# Shared helpers for install.sh / uninstall.sh — obsolete paths and duplicate installs.
#
# Scope (only this Plasma wallpaper project; does not touch other Nextcloud apps):
#   • Wallpaper dirs: org.nextcloud.carousel / org.nextcloud.video under …/plasma/wallpapers/
#   • C++ QML import: …/lib/qt6/qml/org/nextcloud/carousel (and obsolete …/share/qml/…/carousel)
#   • Image cache: …/nextcloud-carousel (subfolder name used by this plugin’s downloader)
# Never removes: Nextcloud Desktop, ~/.cache/Nextcloud, other QML modules under org/nextcloud/*
#   except the carousel import path above.
#
# Source after: PLASMA_USER_HOME, NC_USER_LOCAL, PLUGIN_IMAGE_NAME, PLUGIN_VIDEO_NAME,
# SYSTEM_IMAGE_DIR, SYSTEM_VIDEO_DIR, run_as_target_plasma_user

: "${QML_PLUGIN_SYSTEM:=/usr/lib/qt6/qml/org/nextcloud/carousel}"
QML_PLUGIN_USER="${NC_USER_LOCAL}/lib/qt6/qml/org/nextcloud/carousel"
NC_CACHE_LEGACY="${PLASMA_USER_HOME}/.cache/nextcloud-carousel"
NC_CACHE_PLASMA="${PLASMA_USER_HOME}/.cache/plasmashell/nextcloud-carousel"
# Wrong location from old docs — only this plugin’s module, not all of org/nextcloud
NC_WRONG_QML_SHARE="${NC_USER_LOCAL}/share/qml/org/nextcloud/carousel"

# Set by nc_prompt_obsolete_cleanup (for uninstall exit status)
NC_OBSOLETE_REMOVED=0

# Optional: NC_NONINTERACTIVE=1 skips the prompt (no cleanup)
nc_prompt_obsolete_cleanup() {
    local ctx="${1:-install}"
    NC_OBSOLETE_REMOVED=0

    if [ "${NC_NONINTERACTIVE:-}" = "1" ]; then
        return 0
    fi

    local path
    local -a entries_desc=()
    local -a entries_path=()
    local -a entries_mode=() # user | root

    # 1) Legacy cache (wrong path; downloader uses .cache/plasmashell/)
    if [ -d "$NC_CACHE_LEGACY" ]; then
        entries_desc+=("Cache in obsolete path (use ~/.cache/plasmashell/nextcloud-carousel/)")
        entries_path+=("$NC_CACHE_LEGACY")
        entries_mode+=(user)
    fi

    # 2) Wrong QML tree from old documentation (carousel module only — not sibling org/nextcloud/*)
    if [ -d "$NC_WRONG_QML_SHARE" ]; then
        entries_desc+=("Obsolete QML for this plugin only: share/qml/org/nextcloud/carousel (Qt6 uses lib/qt6/qml/)")
        entries_path+=("$NC_WRONG_QML_SHARE")
        entries_mode+=(user)
    fi

    # 3) System + user duplicate (user tree overrides system in Plasma)
    if [ -d "$SYSTEM_IMAGE_DIR" ] && [ -d "$PLUGIN_IMAGE_DIR" ]; then
        entries_desc+=("Duplicate: per-user carousel wallpaper while system-wide copy exists")
        entries_path+=("$PLUGIN_IMAGE_DIR")
        entries_mode+=(user)
    fi
    if [ -d "$SYSTEM_VIDEO_DIR" ] && [ -d "$PLUGIN_VIDEO_DIR" ]; then
        entries_desc+=("Duplicate: per-user video wallpaper while system-wide copy exists")
        entries_path+=("$PLUGIN_VIDEO_DIR")
        entries_mode+=(user)
    fi
    if [ -d "$QML_PLUGIN_SYSTEM" ] && [ -d "$QML_PLUGIN_USER" ]; then
        entries_desc+=("Duplicate: per-user C++ QML plugin while system copy exists in /usr")
        entries_path+=("$QML_PLUGIN_USER")
        entries_mode+=(user)
    fi

    # 4) Orphan under /root/.local from old \"sudo ./install.sh\" (HOME=/root)
    if [ "$(id -u)" -eq 0 ]; then
        local rp
        for rp in \
            "/root/.local/share/plasma/wallpapers/${PLUGIN_IMAGE_NAME}" \
            "/root/.local/share/plasma/wallpapers/${PLUGIN_VIDEO_NAME}" \
            "/root/.local/lib/qt6/qml/org/nextcloud/carousel" \
            "/root/.cache/nextcloud-carousel" \
            "/root/.cache/plasmashell/nextcloud-carousel"; do
            if [ -d "$rp" ]; then
                entries_desc+=("Orphan under /root (leftover from sudo install with wrong HOME)")
                entries_path+=("$rp")
                entries_mode+=(root)
            fi
        done
    fi

    local n="${#entries_path[@]}"
    # Dedupe paths (e.g. /root/.local/... can match both duplicate and orphan rules)
    if [ "$n" -gt 1 ]; then
        local -a u_path=() u_desc=() u_mode=()
        local j k dup
        for ((j = 0; j < n; j++)); do
            dup=false
            for ((k = 0; k < ${#u_path[@]}; k++)); do
                if [ "${entries_path[$j]}" = "${u_path[$k]}" ]; then
                    dup=true
                    break
                fi
            done
            if [ "$dup" = false ]; then
                u_path+=("${entries_path[$j]}")
                u_desc+=("${entries_desc[$j]}")
                u_mode+=("${entries_mode[$j]}")
            fi
        done
        entries_path=("${u_path[@]}")
        entries_desc=("${u_desc[@]}")
        entries_mode=("${u_mode[@]}")
        n="${#entries_path[@]}"
    fi

    if [ "$n" -eq 0 ]; then
        return 0
    fi

    echo "═══════════════════════════════════════════════════════════"
    echo "  Obsolete / duplicate installations detected"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo "The following paths are unused, legacy, or duplicate a system install:"
    echo ""
    local i
    for ((i = 0; i < n; i++)); do
        printf "  %s\n     → %s\n\n" "${entries_desc[$i]}" "${entries_path[$i]}"
    done
    if [ "$ctx" = "install" ]; then
        echo "Removing them avoids shadowing /usr with stale per-user copies and frees disk."
    else
        echo "Removing them completes cleanup alongside normal uninstall paths."
    fi
    echo ""
    echo "Nothing is deleted until you confirm. No files are removed on \"n\" or Enter."
    echo ""
    read -p "Remove these listed paths now? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipped obsolete cleanup (you can run ./uninstall.sh later)."
        echo ""
        return 0
    fi

    for ((i = 0; i < n; i++)); do
        path="${entries_path[$i]}"
        if [ "${entries_mode[$i]}" = root ]; then
            if rm -rf "$path" 2>/dev/null; then
                echo "✅ Removed: $path"
                NC_OBSOLETE_REMOVED=$((NC_OBSOLETE_REMOVED + 1))
            else
                echo "⚠️  Could not remove: $path"
            fi
        else
            if run_as_target_plasma_user rm -rf "$path" 2>/dev/null; then
                echo "✅ Removed: $path"
                NC_OBSOLETE_REMOVED=$((NC_OBSOLETE_REMOVED + 1))
            else
                echo "⚠️  Could not remove: $path"
            fi
        fi
    done
    echo ""
    return 0
}
