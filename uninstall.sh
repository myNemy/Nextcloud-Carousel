#!/bin/bash
# Uninstallation script for Nextcloud Carousel Plasma Wallpaper Plugin

set -e

PLUGIN_NAME="org.nextcloud.carousel"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/${PLUGIN_NAME}"

echo "═══════════════════════════════════════════════════════════"
echo "  DISINSTALLAZIONE Nextcloud Carousel Plugin"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "⚠️  Il plugin non sembra essere installato in:"
    echo "   $PLUGIN_DIR"
    echo ""
    echo "Verifica manualmente se esiste in altre posizioni:"
    echo "  - ~/.local/share/plasma/wallpapers/"
    echo "  - /usr/share/plasma/wallpapers/"
    exit 1
fi

echo "Plugin trovato in: $PLUGIN_DIR"
echo ""
read -p "Vuoi procedere con la disinstallazione? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Disinstallazione annullata."
    exit 0
fi

echo "Rimozione del plugin..."
rm -rf "$PLUGIN_DIR"

echo ""
echo "✅ Plugin rimosso con successo!"
echo ""

# Rimuovi anche i file di configurazione se esistono
CONFIG_FILE="$HOME/.config/plasmarc"
if [ -f "$CONFIG_FILE" ]; then
    echo "Verifica file di configurazione..."
    if grep -q "org.nextcloud.carousel" "$CONFIG_FILE" 2>/dev/null; then
        echo "⚠️  Trovate configurazioni nel file plasmarc"
        echo "   Potresti voler rimuoverle manualmente da:"
        echo "   $CONFIG_FILE"
    fi
fi

echo ""
echo "Per completare la disinstallazione:"
echo "  1. Riavvia plasmashell: killall plasmashell && plasmashell &"
echo "  2. Oppure riavvia la sessione KDE"
echo ""
echo "Il plugin 'Carosello Nextcloud' non dovrebbe più apparire"
echo "nella lista degli sfondi disponibili."

