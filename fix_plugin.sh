#!/bin/bash
# Script to fix plugin detection issues

echo "═══════════════════════════════════════════════════════════"
echo "  Fix Nextcloud Carousel Plugin Detection"
echo "═══════════════════════════════════════════════════════════"
echo ""

PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/org.nextcloud.carousel"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "❌ Plugin non trovato in: $PLUGIN_DIR"
    echo "   Esegui prima: ./install.sh"
    exit 1
fi

echo "1. Verifica struttura plugin..."
if [ ! -f "$PLUGIN_DIR/metadata.json" ]; then
    echo "   ❌ metadata.json mancante!"
    exit 1
fi
if [ ! -f "$PLUGIN_DIR/contents/ui/main.qml" ]; then
    echo "   ❌ main.qml mancante!"
    exit 1
fi
echo "   ✅ Struttura OK"
echo ""

echo "2. Correzione permessi..."
chmod -R 755 "$PLUGIN_DIR"
echo "   ✅ Permessi corretti"
echo ""

echo "3. Verifica metadata.json..."
# Verifica che KPackageStructure sia corretto
if ! grep -q '"KPackageStructure": "Plasma/Wallpaper"' "$PLUGIN_DIR/metadata.json"; then
    echo "   ⚠️  KPackageStructure potrebbe essere errato"
fi
echo "   ✅ metadata.json OK"
echo ""

echo "4. Riavvio plasmashell..."
if pgrep -x plasmashell > /dev/null; then
    echo "   Fermando plasmashell..."
    killall plasmashell 2>/dev/null
    sleep 2
fi

echo "   Avviando plasmashell..."
plasmashell > /dev/null 2>&1 &
sleep 3

if pgrep -x plasmashell > /dev/null; then
    echo "   ✅ plasmashell riavviato"
else
    echo "   ⚠️  plasmashell potrebbe non essere avviato correttamente"
    echo "   Prova manualmente: killall plasmashell && plasmashell &"
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo "  COMPLETATO"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Ora prova a:"
echo "  1. Tasto destro sul desktop → 'Configure Desktop and Wallpaper'"
echo "  2. Cerca 'Nextcloud Carousel' nella lista"
echo ""
echo "Se non appare ancora:"
echo "  - Verifica i log: journalctl --user -n 100 | grep -i plasma"
echo "  - Riavvia la sessione KDE"
echo ""

