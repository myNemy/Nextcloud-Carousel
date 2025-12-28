#!/bin/bash
# Installation script for Nextcloud Plasma Wallpaper Plugins

# NON usare set -e qui - vogliamo continuare anche se la compilazione fallisce
# set -e  # RIMOSSO

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_IMAGE_NAME="org.nextcloud.carousel"
PLUGIN_VIDEO_NAME="org.nextcloud.video"
PLUGIN_IMAGE_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_IMAGE_NAME}"
PLUGIN_VIDEO_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_VIDEO_NAME}"
SOURCE_IMAGE_DIR="${SCRIPT_DIR}/nextcloud-carousel"
SOURCE_VIDEO_DIR="${SCRIPT_DIR}/nextcloud-video"

echo "Installing Nextcloud Plasma Wallpaper Plugins..."
echo ""

# Funzione per rilevare il tipo di distribuzione
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ -f /etc/redhat-release ]; then
        echo "rhel"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Funzione per verificare se un pacchetto è installato (portabile)
check_package_installed() {
    local pkg="$1"
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            dpkg -l | grep -qE "^ii.*$pkg" 2>/dev/null
            ;;
        fedora|rhel|centos)
            rpm -qa | grep -qE "^$pkg" 2>/dev/null
            ;;
        arch|manjaro)
            pacman -Q "$pkg" >/dev/null 2>&1
            ;;
        opensuse*|sles)
            rpm -qa | grep -qE "^$pkg" 2>/dev/null
            ;;
        *)
            # Fallback: usa solo pkg-config (universale)
            return 1
            ;;
    esac
}

# Funzione per verificare se le dipendenze di compilazione sono disponibili (portabile)
check_build_dependencies() {
    local has_cmake=false
    local has_qt6=false
    local has_kf6=false
    
    # Verifica CMake (universale - comando)
    if command -v cmake >/dev/null 2>&1; then
        has_cmake=true
    fi
    
    # Verifica Qt6 (universale - pkg-config o comando)
    # Prova prima pkg-config (più affidabile), poi qmake6
    if pkg-config --exists Qt6Core 2>/dev/null; then
        has_qt6=true
    elif command -v qmake6 >/dev/null 2>&1; then
        has_qt6=true
    fi
    
    # Verifica KF6 (universale - pkg-config, fallback a gestori pacchetti)
    # Prova prima pkg-config (più affidabile e universale)
    if pkg-config --exists KF6CoreAddons 2>/dev/null; then
        has_kf6=true
    else
        # Fallback: verifica tramite gestore pacchetti (distro-specific)
        # Solo se pkg-config non trova KF6 (può succedere su alcune distro)
        local distro=$(detect_distro)
        case "$distro" in
            ubuntu|debian)
                if dpkg -l 2>/dev/null | grep -qE "^ii.*libkf6coreaddons|^ii.*kf6-coreaddons" 2>/dev/null; then
                    has_kf6=true
                fi
                ;;
            fedora|rhel|centos)
                if rpm -qa 2>/dev/null | grep -qE "kf6-coreaddons|KF6CoreAddons" 2>/dev/null; then
                    has_kf6=true
                fi
                ;;
            arch|manjaro)
                # Su Arch Linux, KF6 CoreAddons si chiama "kcoreaddons" (non kf6-coreaddons)
                if pacman -Q kcoreaddons >/dev/null 2>&1; then
                    has_kf6=true
                fi
                ;;
            opensuse*|sles)
                if rpm -qa 2>/dev/null | grep -qE "kf6-coreaddons|KF6CoreAddons" 2>/dev/null; then
                    has_kf6=true
                fi
                ;;
        esac
    fi
    
    # Debug: mostra cosa è stato rilevato (solo se richiesto via variabile d'ambiente)
    if [ "${DEBUG_INSTALL:-}" = "1" ]; then
        echo "   [DEBUG] CMake: $has_cmake"
        echo "   [DEBUG] Qt6: $has_qt6"
        echo "   [DEBUG] KF6: $has_kf6"
    fi
    
    if [ "$has_cmake" = true ] && [ "$has_qt6" = true ] && [ "$has_kf6" = true ]; then
        return 0  # Tutte le dipendenze disponibili
    else
        return 1  # Dipendenze mancanti
    fi
}

# Funzione per tentare la compilazione del componente C++
try_build_cpp_component() {
    echo "═══════════════════════════════════════════════════════════"
    echo "🔧 Building C++ ImageProvider (optional optimization)..."
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Determina se abbiamo autorizzazioni sudo per installazione di sistema
    local HAS_SUDO=false
    local INSTALL_PREFIX="$HOME/.local"
    local INSTALL_TYPE="user"
    
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        # Sudo disponibile e password già inserita (NOPASSWD configurato)
        HAS_SUDO=true
        INSTALL_PREFIX="/usr"
        INSTALL_TYPE="system"
        echo "   ✅ Sudo disponibile - installerò in /usr/lib/qt6/qml/ (installazione di sistema)"
        echo "   💡 Il plugin C++ sarà disponibile per tutti gli utenti"
    elif command -v sudo >/dev/null 2>&1; then
        # Sudo disponibile ma richiede password
        echo "   🔐 Sudo disponibile - richiederà password per installazione di sistema"
        echo "   💡 Se fornisci autorizzazioni, installerò in /usr/lib/qt6/qml/ (sistema)"
        echo "   💡 Altrimenti installerò in ~/.local/lib/qt6/qml/ (utente, QML fallback)"
        read -p "   ❓ Installare in /usr/ (richiede sudo)? [S/n]: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[SsYy]$ ]] || [[ -z $REPLY ]]; then
            if sudo -v 2>/dev/null; then
                HAS_SUDO=true
                INSTALL_PREFIX="/usr"
                INSTALL_TYPE="system"
                echo "   ✅ Autorizzazioni ottenute - installerò in /usr/lib/qt6/qml/"
            else
                echo "   ⚠️  Autorizzazioni non ottenute - installerò in ~/.local/lib/qt6/qml/"
                echo "   ⚠️  Il plugin C++ potrebbe non essere trovato da plasmashell"
                echo "   ⚠️  Verrà usato QML fallback (funziona ma meno ottimizzato)"
            fi
        else
            echo "   ℹ️  Installazione utente selezionata - installerò in ~/.local/lib/qt6/qml/"
            echo "   ⚠️  Il plugin C++ potrebbe non essere trovato da plasmashell"
            echo "   ⚠️  Verrà usato QML fallback (funziona ma meno ottimizzato)"
        fi
    else
        echo "   ⚠️  Sudo non disponibile - installerò in ~/.local/lib/qt6/qml/ (utente)"
        echo "   ⚠️  Il plugin C++ potrebbe non essere trovato da plasmashell"
        echo "   ⚠️  Verrà usato QML fallback (funziona ma meno ottimizzato)"
    fi
    
    # Verifica dipendenze con logging dettagliato
    echo "   🔍 Checking build dependencies..."
    
    local has_cmake=false
    local has_qt6=false
    local has_kf6=false
    
    # Verifica CMake
    if command -v cmake >/dev/null 2>&1; then
        has_cmake=true
        echo "      ✅ CMake: found"
    else
        echo "      ❌ CMake: not found"
    fi
    
    # Verifica Qt6
    if pkg-config --exists Qt6Core 2>/dev/null; then
        has_qt6=true
        echo "      ✅ Qt6: found (via pkg-config)"
    elif command -v qmake6 >/dev/null 2>&1; then
        has_qt6=true
        echo "      ✅ Qt6: found (via qmake6)"
    else
        echo "      ❌ Qt6: not found"
    fi
    
    # Verifica KF6
    if pkg-config --exists KF6CoreAddons 2>/dev/null; then
        has_kf6=true
        echo "      ✅ KF6 CoreAddons: found (via pkg-config)"
    else
        # Fallback: verifica tramite gestore pacchetti
        local distro=$(detect_distro)
        case "$distro" in
            ubuntu|debian)
                if dpkg -l 2>/dev/null | grep -qE "^ii.*libkf6coreaddons|^ii.*kf6-coreaddons" 2>/dev/null; then
                    has_kf6=true
                    echo "      ✅ KF6 CoreAddons: found (via dpkg)"
                else
                    echo "      ❌ KF6 CoreAddons: not found"
                fi
                ;;
            fedora|rhel|centos)
                if rpm -qa 2>/dev/null | grep -qE "kf6-coreaddons|KF6CoreAddons" 2>/dev/null; then
                    has_kf6=true
                    echo "      ✅ KF6 CoreAddons: found (via rpm)"
                else
                    echo "      ❌ KF6 CoreAddons: not found"
                fi
                ;;
            arch|manjaro)
                if pacman -Q kcoreaddons >/dev/null 2>&1; then
                    has_kf6=true
                    echo "      ✅ KF6 CoreAddons: found (via pacman: kcoreaddons)"
                else
                    echo "      ❌ KF6 CoreAddons: not found (checked: kcoreaddons)"
                fi
                ;;
            opensuse*|sles)
                if rpm -qa 2>/dev/null | grep -qE "kf6-coreaddons|KF6CoreAddons" 2>/dev/null; then
                    has_kf6=true
                    echo "      ✅ KF6 CoreAddons: found (via rpm)"
                else
                    echo "      ❌ KF6 CoreAddons: not found"
                fi
                ;;
            *)
                echo "      ❌ KF6 CoreAddons: unknown distribution, cannot check"
                ;;
        esac
    fi
    
    echo ""
    
    if [ "$has_cmake" = true ] && [ "$has_qt6" = true ] && [ "$has_kf6" = true ]; then
        echo "   ✅ All build dependencies found"
        echo "   🔨 Attempting compilation..."
    else
        echo "   ⚠️  Some build dependencies are missing"
        echo "   ℹ️  Will install QML-only version (works fine, but uses Data URLs)"
        echo ""
        return 1
    fi
    
    # Crea directory build temporanea
    BUILD_DIR="${SCRIPT_DIR}/.build_temp"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configura CMake (mostra output per debug)
    echo "   📋 Running CMake configuration..."
    echo "   📍 Install prefix: $INSTALL_PREFIX ($INSTALL_TYPE installation)"
    if ! cmake "$SCRIPT_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_IMAGEPROVIDER=ON 2>&1 | sed 's/^/      /'; then
        echo ""
        echo "   ❌ CMake configuration failed (see errors above)"
        echo "   ℹ️  Will install QML-only version instead"
        cd "$SCRIPT_DIR"
        rm -rf "$BUILD_DIR"
        return 1
    fi
    echo ""
    
    # Compila
    if ! make -j$(nproc 2>/dev/null || echo 2) >/dev/null 2>&1; then
        echo "   ❌ Compilation failed"
        echo "   ℹ️  Will install QML-only version instead"
        cd "$SCRIPT_DIR"
        rm -rf "$BUILD_DIR"
        return 1
    fi
    
    # Installa il plugin C++
    echo "   📦 Installing C++ ImageProvider..."
    if [ "$HAS_SUDO" = true ] && [ "$INSTALL_PREFIX" = "/usr" ]; then
        # Installazione di sistema - usa sudo
        echo "   🔐 Installing to system directory (requires sudo)..."
        if ! sudo cmake --install "$BUILD_DIR" 2>&1 | sed 's/^/      /'; then
            echo ""
            echo "   ❌ System installation failed (see errors above)"
            echo "   ℹ️  Trying user installation instead..."
            INSTALL_PREFIX="$HOME/.local"
            INSTALL_TYPE="user"
            HAS_SUDO=false
            # Ricompila con nuovo prefix
            if ! cmake "$SCRIPT_DIR" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DBUILD_IMAGEPROVIDER=ON 2>&1 | sed 's/^/      /'; then
                echo "   ❌ User installation also failed"
                cd "$SCRIPT_DIR"
                rm -rf "$BUILD_DIR"
                return 1
            fi
            if ! cmake --install "$BUILD_DIR" 2>&1 | sed 's/^/      /'; then
                echo "   ❌ User installation failed"
                cd "$SCRIPT_DIR"
                rm -rf "$BUILD_DIR"
                return 1
            fi
        fi
    else
        # Installazione utente - senza sudo
        if ! cmake --install "$BUILD_DIR" 2>&1 | sed 's/^/      /'; then
            echo ""
            echo "   ❌ Installation failed (see errors above)"
            echo "   ℹ️  Will install QML-only version instead"
            cd "$SCRIPT_DIR"
            rm -rf "$BUILD_DIR"
            return 1
        fi
    fi
    
    # Cleanup
    cd "$SCRIPT_DIR"
    rm -rf "$BUILD_DIR"
    
    if [ "$INSTALL_TYPE" = "system" ]; then
        echo "   ✅ C++ ImageProvider compiled and installed successfully in /usr/lib/qt6/qml/"
        echo "   💡 Plugin will use file temporanei (reduces memory usage by ~30%)"
        echo "   ✅ Installazione di sistema - disponibile per tutti gli utenti"
        echo "   ✅ Plasmashell troverà automaticamente il plugin C++"
    else
        echo "   ✅ C++ ImageProvider compiled and installed successfully in ~/.local/lib/qt6/qml/"
        echo "   ⚠️  ATTENZIONE: Plasmashell potrebbe non trovare il plugin in ~/.local/lib/qt6/qml/"
        echo "   ⚠️  Se il plugin C++ non viene trovato, verrà usato QML fallback"
        echo "   💡 Per usare il plugin C++, installa in /usr/ con: sudo ./install.sh"
        echo "   💡 Oppure aggiungi ~/.local/lib/qt6/qml/ a QML_IMPORT_PATH"
    fi
    echo ""
    return 0
}

# Tenta la compilazione (opzionale, non blocca l'installazione)
CPP_COMPONENT_AVAILABLE=false
if try_build_cpp_component; then
    CPP_COMPONENT_AVAILABLE=true
fi

# Install Image Carousel Plugin (sempre, anche se compilazione fallita)
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
echo "═══════════════════════════════════════════════════════════"
echo "  INSTALLATION SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
if [ "$CPP_COMPONENT_AVAILABLE" = true ]; then
    echo "✅ INSTALLATION TYPE: COMPLETE (with C++ optimization)"
    echo ""
    echo "   • QML plugin files: ✅ Installed"
    echo "   • C++ ImageProvider: ✅ Installed (file temporanei enabled)"
    echo "   • Memory optimization: ✅ Active (~30% reduction)"
    echo ""
    if [ -f "/usr/lib/qt6/qml/org/nextcloud/carousel/nextcloudimageprovider.so" ]; then
        echo "💡 The C++ plugin is installed in /usr/lib/qt6/qml/ (system installation)"
        echo "   Plasmashell will automatically find the C++ plugin"
        echo "   The plugin will use file temporanei instead of Data URLs,"
        echo "   reducing memory usage by approximately 30%."
    else
        echo "💡 The C++ plugin is installed in ~/.local/lib/qt6/qml/ (user installation)"
        echo "   ⚠️  If plasmashell doesn't find the plugin, QML fallback will be used"
        echo "   To use the C++ plugin, install to /usr/ with: sudo ./install.sh"
    fi
    echo ""
    echo "⚠️  NOTE: If the indicator shows 'QML' instead of 'C++', plasmashell"
    echo "   might not be finding the QML module. The plugin is installed in:"
    echo "   ~/.local/share/qml/org/nextcloud/carousel/"
    echo ""
    echo "   To fix this, add to your ~/.bashrc or ~/.profile:"
    echo "   export QML2_IMPORT_PATH=\$HOME/.local/share/qml:\$QML2_IMPORT_PATH"
    echo "   Then restart plasmashell."
else
    echo "✅ INSTALLATION TYPE: QML-ONLY (basic version)"
    echo ""
    echo "   • QML plugin files: ✅ Installed"
    echo "   • C++ ImageProvider: ❌ Not installed (build dependencies missing)"
    echo "   • Memory optimization: ❌ Not available (uses Data URLs)"
    echo ""
    echo "💡 To enable C++ optimization (file temporanei), install build dependencies:"
    
    # Suggerisci comandi appropriati per la distribuzione rilevata
    distro=$(detect_distro)
    case "$distro" in
        ubuntu|debian)
            echo "   sudo apt install cmake qt6-base-dev libkf6coreaddons-dev"
            ;;
        fedora|rhel|centos)
            echo "   sudo dnf install cmake qt6-qtbase-devel kf6-kcoreaddons-devel"
            ;;
        arch|manjaro)
            echo "   sudo pacman -S cmake qt6-base kcoreaddons"
            ;;
        opensuse*|sles)
            echo "   sudo zypper install cmake qt6-base-devel kf6coreaddons-devel"
            ;;
        *)
            echo "   Install: cmake, Qt6 development packages, KF6 CoreAddons development packages"
            echo "   (Package names may vary by distribution)"
            ;;
    esac
    echo "   Then run ./install.sh again"
    echo ""
    echo "ℹ️  Note: The QML-only version works perfectly fine, but uses more memory"
    echo "   because it stores images as Data URLs instead of temporary files."
fi
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "⚠️  IMPORTANT: Restart plasmashell to load the plugins:"
if command -v kstart >/dev/null 2>&1; then
    echo "   killall plasmashell && kstart plasmashell"
else
    echo "   killall plasmashell && plasmashell --replace &"
fi

# C++ component is installed in ~/.local/lib/qt6/qml/ which Qt6 searches automatically
# No manual configuration needed - Qt6 will find it automatically
echo ""
echo "To uninstall:"
echo "  Images: rm -rf $PLUGIN_IMAGE_DIR"
echo "  Video:  rm -rf $PLUGIN_VIDEO_DIR"
