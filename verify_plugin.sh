#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

print_usage() {
  cat <<'EOF'
Usage:
  ./verify_plugin.sh [--restart]

Checks that the wallpaper plugin files are present in the expected user install paths.
Optionally restarts plasmashell at the end.
EOF
}

RESTART=0
for arg in "$@"; do
  case "$arg" in
    --restart) RESTART=1 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; print_usage; exit 2 ;;
  esac
done

CAROUSEL_ID="org.nextcloud.carousel"
VIDEO_ID="org.nextcloud.video"

USER_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
USER_QML_HOME="${XDG_DATA_HOME:-$HOME/.local}/lib/qt6/qml"

SYSTEM_WP_HOME="/usr/share/plasma/wallpapers"
SYSTEM_QML_HOME="/usr/lib/qt6/qml"

CAROUSEL_DIR="$USER_DATA_HOME/plasma/wallpapers/$CAROUSEL_ID"
VIDEO_DIR="$USER_DATA_HOME/plasma/wallpapers/$VIDEO_ID"

CAROUSEL_SYS_DIR="$SYSTEM_WP_HOME/$CAROUSEL_ID"
VIDEO_SYS_DIR="$SYSTEM_WP_HOME/$VIDEO_ID"

echo "Checking install paths."
echo "  User carousel:   $CAROUSEL_DIR"
echo "  User video:      $VIDEO_DIR"
echo "  System carousel: $CAROUSEL_SYS_DIR"
echo "  System video:    $VIDEO_SYS_DIR"
echo

fail=0

check_path() {
  local p="$1"
  local label="$2"
  if [[ ! -e "$p" ]]; then
    echo "❌ Missing: $label ($p)"
    fail=1
  else
    echo "✅ Found:   $label ($p)"
  fi
}

check_tree() {
  local base="$1"
  local label_prefix="$2"
  local missing=0

  if [[ ! -d "$base" ]]; then
    echo "❌ Missing: $label_prefix dir ($base)"
    return 1
  fi

  check_path "$base/metadata.json" "$label_prefix metadata.json" || true
  check_path "$base/contents/ui/main.qml" "$label_prefix main.qml" || true
  check_path "$base/contents/config/main.xml" "$label_prefix config main.xml" || true

  if [[ ! -e "$base/metadata.json" || ! -e "$base/contents/ui/main.qml" || ! -e "$base/contents/config/main.xml" ]]; then
    missing=1
  fi
  return "$missing"
}

echo "User install checks."
user_ok=1
check_tree "$CAROUSEL_DIR" "carousel (user)" && user_ok=0 || true
check_tree "$VIDEO_DIR" "video (user)" && user_ok=0 || true

echo
echo "System install checks."
system_ok=1
check_tree "$CAROUSEL_SYS_DIR" "carousel (system)" && system_ok=0 || true
check_tree "$VIDEO_SYS_DIR" "video (system)" && system_ok=0 || true

echo
echo "Optional C++ module checks (may be absent if not built/installed)."

check_path "$USER_QML_HOME/org/nextcloud/carousel" "user QML module dir"
check_path "$SYSTEM_QML_HOME/org/nextcloud/carousel" "system QML module dir"

# Embedded module under the wallpaper tree (both user and system installs may embed it)
check_path "$CAROUSEL_DIR/contents/ui/org/nextcloud/carousel/qmldir" "embedded qmldir (user tree)"
check_path "$CAROUSEL_DIR/contents/ui/org/nextcloud/carousel/libnextcloudimageprovider.so" "embedded libnextcloudimageprovider.so (user tree)"
check_path "$CAROUSEL_SYS_DIR/contents/ui/org/nextcloud/carousel/qmldir" "embedded qmldir (system tree)"
check_path "$CAROUSEL_SYS_DIR/contents/ui/org/nextcloud/carousel/libnextcloudimageprovider.so" "embedded libnextcloudimageprovider.so (system tree)"

echo
if [[ "$user_ok" -ne 0 && "$system_ok" -ne 0 ]]; then
  cat <<EOF
No valid install tree was found (neither user-local nor system-wide).

Suggested fix:
  cd "$ROOT_DIR"
  ./install.sh
  killall plasmashell && kstart plasmashell
EOF
  exit 1
fi

echo "A valid install tree was found."

if [[ "$RESTART" -eq 1 ]]; then
  echo "Restarting plasmashell."
  killall plasmashell && kstart plasmashell
fi
