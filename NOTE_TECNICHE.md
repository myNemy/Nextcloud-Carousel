# Note Tecniche - Problema Pulsante Configura

## Stato Attuale

Il plugin è installato e riconosciuto da Plasma (`kpackagetool6` lo vede), ma il pulsante "Configura" non appare nella finestra di configurazione desktop.

## Analisi

### File Presenti ✅
- `metadata.json` - ✅ Presente e corretto
- `contents/ui/main.qml` - ✅ Presente
- `contents/ui/config.qml` - ✅ Presente
- `contents/config/main.xml` - ✅ Presente

### Struttura Plugin
```
~/.local/share/plasma/wallpapers/org.nextcloud.carousel/
├── metadata.json
└── contents/
    ├── config/
    │   └── main.xml
    └── ui/
        ├── main.qml
        └── config.qml
```

### Confronto con Plugin Ufficiali

**org.kde.color** (funziona):
- Usa `Kirigami.FormLayout` come root
- Ha `twinFormLayouts: parentLayout`
- Struttura molto semplice

**org.kde.slideshow** (funziona):
- Usa `ColumnLayout` come root
- Ha `property var parentLayout`
- Struttura complessa

**org.nextcloud.carousel** (non funziona):
- Usa `ColumnLayout` come root
- Ha `property var parentLayout`
- Struttura simile a slideshow

## Possibili Cause

1. **Versioni import**: Corrette (aggiunte)
2. **Struttura file**: Corretta
3. **Proprietà mancanti**: Potrebbe mancare qualcosa
4. **Cache Plasma**: Potrebbe non essere aggiornata
5. **Errore silenzioso**: Il file potrebbe non essere caricato per un errore non visibile

## Prossimi Passi

1. Verificare i log di Plasma per errori QML
2. Testare con una versione semplificata del config.qml
3. Verificare se il problema è specifico di Plasma 6.5.2
4. Consultare la documentazione ufficiale API

## Disinstallazione

Lo script `uninstall.sh` è stato creato e funziona correttamente.

## Riferimenti

- Documentazione API: https://api.kde.org/frameworks/plasma-framework/html/
- Plugin di esempio: `/usr/share/plasma/wallpapers/org.kde.*`

