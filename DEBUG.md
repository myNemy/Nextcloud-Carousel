# Debug - Caricamento Immagini

## Problema
Le immagini non vengono caricate nonostante la configurazione sia corretta.

## Correzioni Applicate

### 1. Base64 Encoding Manuale
- `btoa()` potrebbe non essere disponibile in QML
- Implementato encoding base64 manuale

### 2. Logging Migliorato
- Log dettagliati per ogni fase:
  - Conteggio immagini trovate
  - URL delle immagini
  - Stato del download
  - Errori specifici (401, 404, ecc.)

## Come Verificare

### 1. Riavvia plasmashell
```bash
killall plasmashell && plasmashell &
```

### 2. Controlla i log
Apri la console QML per vedere i messaggi di debug:
```bash
QT_LOGGING_RULES="qml.debug=true" plasmashell 2>&1 | tee /tmp/plasmashell.log
```

Poi in un altro terminale:
```bash
tail -f /tmp/plasmashell.log | grep -i "nextcloud\|image\|error\|found"
```

### 3. Cosa Cercare nei Log

**Se funziona, vedrai:**
- "Loading photos from Nextcloud: https://..."
- "WebDAV URL: https://..."
- "Found X images"
- "Downloading image from: https://..."
- "Image downloaded, size: X bytes"
- "Image converted to data URL"

**Se non funziona, cerca:**
- "Failed to load photos. Status: XXX"
- "Authentication failed" (401)
- "Path not found" (404)
- "No images found"
- "Network error" (status 0)

## Possibili Problemi

### 1. Autenticazione (401)
- Verifica username e password
- Prova con app password invece della password principale

### 2. Percorso Non Trovato (404)
- Verifica che il percorso `/Foto` esista in Nextcloud
- Prova con percorso assoluto come `/Photos` o `/Pictures`

### 3. Nessuna Immagine Trovata
- Verifica che ci siano file immagine nella cartella
- Controlla i formati supportati (jpg, png, gif, webp, ecc.)

### 4. Network Error (status 0)
- Verifica la connessione a Nextcloud
- Controlla se ci sono problemi CORS

## Test Manuale

Puoi testare manualmente la connessione WebDAV:
```bash
curl -u "nemeyes:PASSWORD" \
  -X PROPFIND \
  -H "Depth: 1" \
  -H "Content-Type: application/xml" \
  -d '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:getcontenttype/></d:prop></d:propfind>' \
  "https://nemeyes.xyz/remote.php/dav/files/nemeyes/Foto"
```

Se questo funziona, il problema è nel plugin. Se non funziona, il problema è nella configurazione.

