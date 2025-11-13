# Risoluzione Problemi - Pulsante Configura Non Visibile

## Problema: Il pulsante "Configura" non appare

Se nella finestra "Impostazioni di Desktop" non vedi il pulsante "Configura" dopo aver selezionato "Carosello Nextcloud", prova queste soluzioni:

### Soluzione 1: Riavvia Plasmashell

```bash
killall plasmashell && plasmashell &
```

Poi riapri la finestra di configurazione desktop.

### Soluzione 2: Applica prima il wallpaper

1. Nella finestra "Impostazioni di Desktop"
2. Seleziona "Carosello Nextcloud"
3. Clicca su **"Applica"** o **"OK"**
4. Riapri la finestra di configurazione
5. Ora dovrebbe apparire il pulsante "Configura"

### Soluzione 3: Verifica installazione

Controlla che tutti i file siano presenti:

```bash
ls -la ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/
```

Dovresti vedere:
- `config.qml` ✅
- `main.qml` ✅

### Soluzione 4: Reinstalla il plugin

```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cd /home/nemeyes/SCRIPT/nextcloud-plasma-addon
./install.sh
killall plasmashell && plasmashell &
```

### Soluzione 5: Configurazione manuale (alternativa)

Se il pulsante non appare, puoi modificare manualmente il file di configurazione:

1. Trova il file di configurazione:
```bash
find ~/.config -name "*nextcloud*carousel*" 2>/dev/null
```

2. Oppure modifica direttamente:
```bash
kwriteconfig5 --file ~/.config/plasmarc --group "Containments" --group "1" --group "Wallpaper" --group "org.nextcloud.carousel" --key "NextcloudUrl" "https://tuoserver.com"
```

### Soluzione 6: Verifica log per errori

Controlla se ci sono errori:

```bash
journalctl -f | grep -i "nextcloud\|carousel\|wallpaper" &
```

Poi riapri la configurazione desktop e guarda i log.

## Accesso alternativo alla configurazione

Se il pulsante "Configura" non appare, puoi anche:

1. **Clic destro sul desktop** → **Configura Desktop e Sfondo**
2. Seleziona **"Carosello Nextcloud"**
3. Il pulsante "Configura" dovrebbe essere visibile in basso nella finestra
4. Se non c'è, prova a cliccare su "Applica" prima

## Note

- Il pulsante "Configura" appare automaticamente quando Plasma rileva un file `config.qml` valido
- Potrebbe essere necessario riavviare plasmashell dopo l'installazione
- Assicurati di aver applicato il wallpaper prima di cercare il pulsante

