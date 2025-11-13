#!/bin/bash
# Installation script for Nextcloud Carousel Plasma Wallpaper Plugin

set -e

PLUGIN_NAME="org.nextcloud.carousel"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_NAME}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/nextcloud-carousel"

echo "Installing Nextcloud Carousel Wallpaper Plugin..."
echo "Source: $SOURCE_DIR"
echo "Destination: $PLUGIN_DIR"

# Create destination directory
mkdir -p "$PLUGIN_DIR"

# Copy plugin files
cp -r "$SOURCE_DIR"/* "$PLUGIN_DIR/"

echo "Plugin installed successfully!"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  COME CONFIGURARE IL PLUGIN:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Metodo più semplice:"
echo "  1. Clic destro sul desktop → 'Configura Desktop e Sfondo'"
echo "  2. Seleziona 'Nextcloud Carousel' dalla lista sfondi"
echo "  3. Clicca su 'Configura'"
echo "  4. Inserisci URL Nextcloud, username, password e percorso foto"
echo ""
echo "Metodo alternativo:"
echo "  System Settings → Appearance → Wallpaper"
echo "  Seleziona 'Nextcloud Carousel' → Configura"
echo ""
echo "Per dettagli completi, vedi: CONFIGURAZIONE.md"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Per disinstallare: rm -rf $PLUGIN_DIR"

