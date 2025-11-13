# Nextcloud Carousel - KDE Plasma 6 Wallpaper Plugin

Un plugin wallpaper per KDE Plasma 6 che crea un carosello di foto dalle tue immagini Nextcloud.

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

### Carousel Settings

- **Change every**: Intervallo tra il cambio delle foto (in secondi)
- **Transition Type**: Tipo di transizione tra le foto
  - Fade (dissolvenza)
  - Slide (scorrimento)
  - Zoom
- **Transition Duration**: Durata dell'animazione di transizione (in millisecondi)
- **Random order**: Abilita l'ordine casuale delle foto

### Display Settings

- **Fill Mode**: Modalità di riempimento dell'immagine
  - Stretch (allunga)
  - Fit (adatta)
  - Crop (ritaglia)
  - Tile (piastrelle)
  - Tile Vertically (piastrelle verticali)
  - Tile Horizontally (piastrelle orizzontali)
- **Blur background**: Applica effetto sfocatura allo sfondo
- **Background Color**: Colore di sfondo quando l'immagine non copre tutto lo schermo

## Funzionalità

- ✅ Carosello automatico delle foto da Nextcloud
- ✅ Transizioni animate tra le foto
- ✅ Supporto per ordine casuale o sequenziale
- ✅ Configurazione completa tramite interfaccia grafica
- ✅ Supporto per diversi formati immagine (JPEG, PNG, WebP, etc.)

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

**TODO per implementazione completa:**

- [ ] Integrazione con Nextcloud WebDAV API per il caricamento delle foto
- [ ] Cache locale delle immagini
- [ ] Supporto per autenticazione OAuth2
- [ ] Test di connessione funzionante
- [ ] Gestione errori migliorata

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

## Supporto

Per problemi o domande, apri una issue sul repository del progetto.

## Riferimenti

- [KDE Plasma Wallpaper Plugin Documentation](https://api.kde.org/frameworks/plasma-framework/html/)
- [KDE Plasma 6 Documentation](https://develop.kde.org/docs/)

