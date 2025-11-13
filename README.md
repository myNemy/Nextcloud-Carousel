# Nextcloud Carousel - KDE Plasma 6 Wallpaper Plugin

Un plugin wallpaper per KDE Plasma 6 che crea un carosello di foto dalle tue immagini Nextcloud.

> ⚠️ **ATTENZIONE**: Questo progetto è un **esperimento** e viene fornito "così com'è" senza garanzie. Utilizzalo a tuo rischio e pericolo. Non è un prodotto ufficiale e potrebbe contenere bug o comportamenti inattesi.

## 🚀 Guida Rapida

**Dopo l'installazione, per configurare:**

1. **Clic destro sul desktop** → **Configura Desktop e Sfondo**
2. Seleziona **Nextcloud Carousel** dalla lista degli sfondi
3. Clicca su **Configura**
4. Inserisci URL Nextcloud, username, password e percorso foto
5. Applica le modifiche

Vedi la sezione [Configurazione](#configurazione) per dettagli completi.

## Requisiti

- KDE Plasma 6.x
- Qt 6.x
- Nextcloud server accessibile

## Installazione

### Metodo 1: Script di installazione (consigliato)

```bash
./install.sh
```

### Metodo 2: Installazione manuale

```bash
mkdir -p ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cp -r nextcloud-carousel/* ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/
```

### Metodo 3: Con CMake

```bash
mkdir build
cd build
cmake ..
make
sudo make install
```

## Configurazione

### Come accedere alla configurazione

Ci sono diversi modi per configurare il wallpaper:

#### Metodo 1: Dal Desktop (più semplice)
1. **Clic destro sul desktop** → **Configura Desktop e Sfondo** (o **Configure Desktop and Wallpaper**)
2. Nella finestra che si apre, nella sezione **Sfondo** (Wallpaper)
3. Seleziona **Nextcloud Carousel** dalla lista degli sfondi disponibili
4. Clicca sul pulsante **Configura** (Configure) in basso
5. Si aprirà la finestra di configurazione con tutte le opzioni

#### Metodo 2: Da Impostazioni di Sistema
1. Apri **Impostazioni di Sistema** (System Settings)
   - Dal menu applicazioni, oppure
   - Premi `Alt+F2` e digita `systemsettings`
2. Vai su **Aspetto** (Appearance) → **Sfondo** (Wallpaper)
3. Seleziona **Nextcloud Carousel** dalla lista
4. Clicca su **Configura** (Configure)

#### Metodo 3: Da KRunner
1. Premi `Alt+F2` (o `Meta` + `R`)
2. Digita: `systemsettings appearance` oppure `wallpaper`
3. Seleziona l'opzione appropriata e segui i passaggi sopra

### Configurazione del Plugin

Una volta aperta la finestra di configurazione, inserisci:

**Sezione Nextcloud Configuration:**
- **Nextcloud URL**: L'indirizzo del tuo server Nextcloud (es. `https://nextcloud.example.com`)
- **Username**: Il tuo nome utente Nextcloud
- **Password**: La tua password o app password (consigliato usare un'app password)
- **Photo Path**: Il percorso della cartella foto in Nextcloud (default: `/Photos`)

**Sezione Carousel Settings:**
- Configura intervallo, transizioni, ecc. (vedi sotto)

**Sezione Display Settings:**
- Configura modalità di visualizzazione, blur, colore sfondo

## Opzioni di Configurazione

### Nextcloud Configuration (Obbligatorio)

- **Nextcloud URL**: L'indirizzo del tuo server Nextcloud (es. `https://nextcloud.example.com`)
  - Senza slash finale
- **Username**: Il tuo nome utente Nextcloud
- **Password**: La tua password o app password (consigliato usare un'app password)
  - Per creare un'app password: Nextcloud → Impostazioni → Sicurezza → App password
- **Photo Path**: Il percorso della cartella foto in Nextcloud
  - Default: `/Photos`
  - Esempi: `/Photos/Vacanze`, `/Pictures`
  - Il plugin legge ricorsivamente anche le sottocartelle

### Carousel Settings

- **Change every**: Intervallo tra il cambio delle foto (in secondi)
  - Minimo: 1 secondo
  - Consigliato: 10-30 secondi per un carosello veloce
- **Transition Type**: Tipo di transizione tra le foto
  - **Fade**: Dissolvenza (consigliato)
  - **Slide**: Scorrimento laterale
  - **Zoom**: Effetto zoom
- **Transition Duration**: Durata dell'animazione di transizione (in millisecondi)
  - Default: 1000ms (1 secondo)
  - Range: 100-5000ms
- **Order Mode**: Modalità di ordinamento delle foto
  - **Sequential**: Ordine sequenziale (dalla prima all'ultima)
  - **Random (each time)**: Completamente casuale ad ogni cambio
  - **Shuffle Once**: Mescola una volta all'inizio, poi sequenziale
  - **Smart Random**: Evita di mostrare la stessa immagine consecutivamente

### Display Settings

- **Fill Mode**: Modalità di riempimento dell'immagine
  - **Stretch**: Allunga per riempire tutto lo schermo (può deformare)
  - **Fit**: Adatta mantenendo proporzioni (può lasciare bordi)
  - **Crop**: Ritaglia per riempire (consigliato, mantiene proporzioni)
  - **Tile**: Ripete l'immagine come piastrelle
  - **Tile Vertically**: Piastrelle verticali
  - **Tile Horizontally**: Piastrelle orizzontali
- **Blur background**: Applica effetto sfocatura allo sfondo (attualmente semplificato)
- **Background Color**: Colore di sfondo quando l'immagine non copre tutto lo schermo
  - Utile con Fill Mode "Fit"
  - Default: Nero (#000000)

## Funzionalità

- ✅ Carosello automatico delle foto da Nextcloud
- ✅ Transizioni animate tra le foto (Fade, Slide, Zoom)
- ✅ 4 modalità di ordinamento: Sequenziale, Random, Shuffle Once, Smart Random
- ✅ Supporto ricorsivo per sottocartelle
- ✅ Configurazione completa tramite interfaccia grafica
- ✅ Supporto per diversi formati immagine (JPEG, PNG, WebP, GIF, BMP, SVG, TIFF)
- ✅ Caricamento immagini tramite WebDAV API
- ✅ Configurazione colore di sfondo personalizzabile

## Sviluppo

### Struttura del Progetto

```
nextcloud-carousel/
├── metadata.json          # Metadati del plugin
├── contents/
│   ├── config/
│   │   └── main.xml       # File di configurazione
│   └── ui/
│       ├── main.qml       # Componente principale del wallpaper
│       └── config.qml     # Interfaccia di configurazione
```

### Note per Sviluppatori

Il plugin è basato sulla documentazione ufficiale di KDE Plasma 6 per i wallpaper plugins. La struttura segue lo standard `Plasma/Wallpaper` KPackage.

**Miglioramenti futuri:**

- [ ] Cache locale delle immagini migliorata
- [ ] Supporto per autenticazione OAuth2
- [ ] Test di connessione automatico
- [ ] Gestione errori migliorata con messaggi più chiari
- [ ] Indicatore di progresso per il caricamento

## Compatibilità

- **Plasma**: 6.0+
- **Qt**: 6.0+
- **KF6**: Richiesto

## Licenza

GPL-2.0-or-later

## Disinstallazione

### Metodo 1: Script di disinstallazione (consigliato)

```bash
./uninstall.sh
```

### Metodo 2: Disinstallazione manuale

```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
killall plasmashell && plasmashell &
```

### Metodo 3: Con kpackagetool6

```bash
kpackagetool6 --type=Plasma/Wallpaper --remove org.nextcloud.carousel
killall plasmashell && plasmashell &
```

## Risoluzione Problemi

### Il plugin non appare nella lista

1. Verifica l'installazione:
   ```bash
   ls ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
   ```

2. Riavvia plasmashell:
   ```bash
   killall plasmashell && plasmashell &
   ```

3. Oppure riavvia la sessione KDE

### Il pulsante "Configura" non appare

1. **Applica prima il wallpaper**: Seleziona "Nextcloud Carousel" e clicca su "Applica" o "OK"
2. Riapri la finestra di configurazione - ora dovrebbe apparire il pulsante "Configura"
3. Riavvia plasmashell se necessario:
   ```bash
   killall plasmashell && plasmashell &
   ```

### La configurazione non si apre

1. Verifica i permessi dei file:
   ```bash
   chmod -R 755 ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
   ```

2. Controlla i log:
   ```bash
   journalctl -f | grep plasma
   ```

### Le foto non si caricano

1. **Verifica la connessione a Nextcloud**:
   - Testa l'URL nel browser
   - Verifica username e password
   - Controlla che il percorso foto sia corretto

2. **Verifica i permessi Nextcloud**:
   - Assicurati di avere accesso alla cartella foto
   - Controlla che le foto siano in formati supportati (JPEG, PNG, WebP, etc.)

3. **Test manuale WebDAV**:
   ```bash
   curl -u "USERNAME:PASSWORD" \
     -X PROPFIND \
     -H "Depth: infinity" \
     -H "Content-Type: application/xml" \
     -d '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:getcontenttype/></d:prop></d:propfind>' \
     "https://TUO_SERVER/remote.php/dav/files/USERNAME/PATH"
   ```
   Sostituisci `USERNAME`, `PASSWORD`, `TUO_SERVER` e `PATH` con i tuoi valori.

4. **Controlla i log di debug**:
   ```bash
   QT_LOGGING_RULES="qml.debug=true" plasmashell 2>&1 | grep -i "nextcloud\|image\|error"
   ```

### Reinstallazione del plugin

Se hai problemi persistenti, prova a reinstallare:

```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cd /path/to/nextcloud-plasma-addon
./install.sh
killall plasmashell && plasmashell &
```

## Note Importanti

- **Sicurezza**: La password viene salvata in chiaro nel file di configurazione locale. Per maggiore sicurezza, usa un'app password invece della password principale.
- **WebDAV**: Il plugin carica le foto tramite WebDAV API di Nextcloud con autenticazione Basic Auth.
- **Cache**: Le immagini vengono cachate localmente per migliori prestazioni.
- **Sottocartelle**: Il plugin legge ricorsivamente tutte le immagini nelle sottocartelle della cartella specificata.

## Supporto

Per problemi o domande, apri una issue sul repository del progetto.

## Riferimenti

- [KDE Plasma Wallpaper Plugin Documentation](https://api.kde.org/frameworks/plasma-framework/html/)
- [KDE Plasma 6 Documentation](https://develop.kde.org/docs/)
- [Nextcloud WebDAV API](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html)

---

**Nota**: Questo progetto è stato sviluppato utilizzando [Cursor](https://cursor.sh), un editor di codice potenziato dall'AI.

