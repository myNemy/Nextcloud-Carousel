# Implementazione Caricamento Immagini Nextcloud

## Funzionalità Implementata

Ho implementato il caricamento delle immagini da Nextcloud usando l'API WebDAV.

## Come Funziona

### 1. Autenticazione
- Usa Basic Authentication con username e password
- Costruisce l'URL WebDAV: `https://nextcloud.example.com/remote.php/dav/files/USERNAME/PATH`

### 2. Lista File (PROPFIND)
- Esegue una richiesta PROPFIND con Depth=1 per listare i file nella cartella
- Parsa la risposta XML per estrarre i percorsi dei file
- Filtra solo i file immagine (jpg, jpeg, png, gif, webp, bmp, svg, tiff)

### 3. Costruzione URL Immagini
- Costruisce URL diretti per il download delle immagini
- Aggiunge autenticazione all'URL per permettere il download

### 4. Carosello
- Carica le immagini nella lista
- Se "Random order" è attivo, mescola la lista
- Avvia il carosello con il timer configurato

## Formati Supportati

- JPEG/JPG
- PNG
- GIF
- WebP
- BMP
- SVG
- TIFF

## Note

- Le credenziali sono incluse nell'URL (Basic Auth)
- Per maggiore sicurezza, considera l'uso di app password invece della password principale
- Il plugin carica le immagini in modo asincrono

## Troubleshooting

Se le immagini non si caricano:

1. **Verifica le credenziali**: Username e password devono essere corretti
2. **Verifica il percorso**: Il percorso foto deve esistere in Nextcloud
3. **Verifica i permessi**: Devi avere accesso alla cartella in Nextcloud
4. **Controlla i log**: Apri la console QML per vedere i messaggi di debug
   ```bash
   QT_LOGGING_RULES="qml.debug=true" plasmashell
   ```

## Miglioramenti Futuri

- Cache locale delle immagini
- Supporto per OAuth2
- Gestione errori migliorata
- Indicatore di progresso per il caricamento

