# Guida alla Configurazione - Nextcloud Carousel

## 📍 Dove trovare la configurazione

### Metodo più semplice: Dal Desktop

1. **Fai clic destro su un'area vuota del desktop**
2. Seleziona **"Configura Desktop e Sfondo"** (o **"Configure Desktop and Wallpaper"** in inglese)
3. Nella finestra che si apre:
   - Vai alla sezione **"Sfondo"** (Wallpaper) nella barra laterale sinistra
   - Nella lista degli sfondi disponibili, cerca e seleziona **"Nextcloud Carousel"**
   - Clicca sul pulsante **"Configura"** (Configure) in basso a destra
4. Si aprirà la finestra di configurazione del plugin

### Metodo alternativo: Impostazioni di Sistema

1. Apri **Impostazioni di Sistema** (System Settings):
   - Dal menu applicazioni: **Impostazioni** → **Impostazioni di Sistema**
   - Oppure premi `Alt+F2` e digita `systemsettings`
2. Naviga: **Aspetto** (Appearance) → **Sfondo** (Wallpaper)
3. Seleziona **Nextcloud Carousel** dalla lista
4. Clicca su **Configura** (Configure)

### Metodo rapido: KRunner

1. Premi `Alt+F2` (o `Meta + R`)
2. Digita: `wallpaper` o `systemsettings appearance`
3. Seleziona l'opzione e segui i passaggi sopra

## ⚙️ Cosa configurare

### 1. Nextcloud Configuration (Obbligatorio)

- **Nextcloud URL**: 
  - Esempio: `https://nextcloud.example.com`
  - Senza slash finale
  
- **Username**: 
  - Il tuo nome utente Nextcloud
  
- **Password**: 
  - La tua password o (consigliato) un'app password
  - Per creare un'app password: Nextcloud → Impostazioni → Sicurezza → App password
  
- **Photo Path**: 
  - Percorso della cartella foto in Nextcloud
  - Default: `/Photos`
  - Esempi: `/Photos/Vacanze`, `/Pictures`

### 2. Carousel Settings

- **Change every**: Quanto tempo (in secondi) prima di cambiare foto
  - Minimo: 1 secondo
  - Consigliato: 10-30 secondi per un carosello veloce
  
- **Transition Type**: Tipo di animazione tra le foto
  - **Fade**: Dissolvenza (consigliato)
  - **Slide**: Scorrimento laterale
  - **Zoom**: Effetto zoom
  
- **Transition Duration**: Durata dell'animazione (in millisecondi)
  - Default: 1000ms (1 secondo)
  - Range: 100-5000ms
  
- **Random order**: 
  - ✅ Attivato: foto in ordine casuale
  - ❌ Disattivato: foto in ordine sequenziale

### 3. Display Settings

- **Fill Mode**: Come l'immagine viene visualizzata
  - **Stretch**: Allunga per riempire tutto lo schermo (può deformare)
  - **Fit**: Adatta mantenendo proporzioni (può lasciare bordi)
  - **Crop**: Ritaglia per riempire (consigliato, mantiene proporzioni)
  - **Tile**: Ripete l'immagine come piastrelle
  - **Tile Vertically**: Piastrelle verticali
  - **Tile Horizontally**: Piastrelle orizzontali

- **Blur background**: Applica sfocatura (attualmente semplificato)

- **Background Color**: Colore di sfondo quando l'immagine non copre tutto
  - Utile con Fill Mode "Fit"
  - Default: Nero (#000000)

## 🔧 Risoluzione Problemi

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

1. Verifica la connessione a Nextcloud:
   - Testa l'URL nel browser
   - Verifica username e password
   - Controlla che il percorso foto sia corretto

2. Verifica i permessi Nextcloud:
   - Assicurati di avere accesso alla cartella foto
   - Controlla che le foto siano in formati supportati (JPEG, PNG, WebP, etc.)

## 📝 Note

- La password viene salvata in chiaro nel file di configurazione locale
- Per maggiore sicurezza, usa un'app password invece della password principale
- Il plugin carica le foto tramite WebDAV API di Nextcloud
- Le immagini vengono cachate localmente per migliori prestazioni

