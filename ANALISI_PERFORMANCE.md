# Analisi Performance Dettagliata - Nextcloud Carousel e Video

## 📋 Indice
1. [Nextcloud Carousel (Immagini)](#nextcloud-carousel-immagini)
2. [Nextcloud Video](#nextcloud-video)
3. [Confronto Diretto](#confronto-diretto)
4. [Problemi Comuni](#problemi-comuni)
5. [Raccomandazioni](#raccomandazioni)

---

## 🖼️ Nextcloud Carousel (Immagini)

### Architettura
- **File principale**: `main.qml` (889 righe)
- **Componente separato**: `ImageComponent.qml` (89 righe)
- **Tecnologia**: StackView per transizioni, XHR per download, Base64 encoding
- **Gestione memoria**: Distruzione automatica quando rimosso da StackView

### Punti di Forza ✅

1. **Gestione Transizioni**
   - StackView con transizioni Fade, Slide, Zoom
   - Transizioni randomizzabili
   - Durata configurabile
   - Pattern KDE ufficiale

2. **Gestione EXIF**
   - Lettura orientamento EXIF per JPEG
   - Rotazione automatica basata su metadata
   - Supporto per orientamenti 0°, 90°, -90°, 180°

3. **Download e Conversione**
   - Download immagini come ArrayBuffer
   - Conversione manuale a Base64 (btoa non disponibile in QML)
   - Data URL per evitare problemi di autenticazione

4. **Memory Management**
   - Distruzione automatica quando immagine rimossa da StackView
   - Cleanup di pendingImage prima di crearne uno nuovo
   - Connessioni signal disconnesse correttamente

### Problemi Identificati ⚠️

1. ~~**Memory Leak Potenziale - Data URL**~~ ✅ **RISOLTO**
   - ~~**Problema**: Ogni immagine viene convertita in data URL base64 e mantenuta in memoria~~
   - ~~**Impatto**: Per immagini grandi (>5MB), ogni data URL può occupare ~6.7MB in memoria (base64 è ~33% più grande)~~
   - ~~**Esempio**: 100 immagini da 5MB = ~670MB solo per data URL~~
   - **Soluzione implementata**:
     - **Lazy Loading Strategy**: Cache solo 1-2 data URL (corrente + prossima per preload)
     - Lista testuale (URL) mantenuta in memoria (leggera)
     - StackView distrugge automaticamente le immagini quando rimosse
     - Cache LRU con dimensione adattiva: 1 immagine se totale=1, altrimenti 2
     - Cleanup periodico ogni 10 switch di immagine
     - Eviction automatica del meno recentemente usato quando cache è piena
     - Uso di operatori QML-compatibili (`in` invece di `hasOwnProperty`)
     - Nessun timestamp (usa solo ordine array per LRU)
     - **Vantaggio**: Memoria costante anche con centinaia/migliaia di immagini

2. ~~**Randomizzazione Inefficiente (Mode 1)**~~ ✅ **RISOLTO**
   - ~~**Problema**: Mode 1 (Random) evita solo l'ultimo indice, non i recenti~~
   - ~~**Impatto**: Con molte immagini, può ripetere immagini recenti~~
   - ~~**Differenza con Video**: Il plugin video evita gli ultimi 3-10 video~~
   - **Soluzione implementata**:
     - Implementato `recentIndices` array per tracciare gli ultimi 10 indici visualizzati
     - Mode 1 ora evita gli ultimi 3-5 foto (adattivo in base alla dimensione della lista)
     - Pattern identico al plugin video per coerenza
     - Fallback intelligente quando tutte le foto sono recenti
     - Mantiene ultimi 10 indici per evitare ripetizioni

3. ~~**Nessun Cleanup Aggressivo**~~ ✅ **RISOLTO**
   - ~~**Problema**: Non c'è cleanup periodico come nel plugin video~~
   - ~~**Impatto**: Con uso prolungato, data URL possono accumularsi~~
   - **Soluzione**: Cleanup periodico ogni 10 switch di immagine implementato insieme alla cache LRU

4. ~~**EXIF Parsing Pesante**~~ ✅ **RISOLTO**
   - ~~**Problema**: Parsing EXIF avviene in JavaScript sincrono~~
   - ~~**Impatto**: Per immagini grandi, può bloccare UI durante parsing~~
   - **Soluzione implementata**:
     - Limitata ricerca EXIF ai primi 64KB dell'immagine (dove si trova sempre l'EXIF nei JPEG)
     - Riduce drasticamente il tempo di parsing per immagini grandi (da potenzialmente secondi a millisecondi)
     - Pattern conforme alle best practice QML per operazioni pesanti
     - L'EXIF è sempre nei primi segmenti JPEG, quindi non si perdono informazioni
     - Per immagini > 64KB, la ricerca si ferma automaticamente dopo 64KB
     - Nessun cambiamento nel comportamento funzionale, solo ottimizzazione performance

5. ~~**Base64 Encoding Manuale**~~ ✅ **RISOLTO**
   - ~~**Problema**: Encoding base64 fatto manualmente in JavaScript~~
   - ~~**Impatto**: Lento per immagini grandi, blocca UI~~
   - **Soluzione implementata**:
     - Ottimizzato algoritmo usando array invece di concatenazione stringa incrementale
     - Uso di `base64Array.push()` e `join()` invece di `base64 += ...` (molto più veloce)
     - Migliorata gestione padding per evitare errori con array corti
     - Pattern conforme alle best practice JavaScript/QML per operazioni su stringhe grandi
     - Riduzione significativa del tempo di encoding per immagini grandi (da secondi a millisecondi)
     - Nessun cambiamento funzionale, solo ottimizzazione performance

6. ~~**Nessun Timeout per Download**~~ ✅ **RISOLTO**
   - ~~**Problema**: XHR non ha timeout esplicito~~
   - ~~**Impatto**: Download lenti possono bloccare indefinitamente~~
   - **Soluzione implementata**:
     - Timeout di 30 secondi per richieste PROPFIND (lista file)
     - Timeout di 60 secondi per download immagini (possono essere grandi)
     - Gestore `ontimeout` per entrambe le richieste XHR
     - Messaggi di errore informativi quando si verifica un timeout
     - Fallback automatico: se un'immagine va in timeout, passa alla successiva
     - Implementato sia nel plugin Carousel che nel plugin Video per coerenza

7. ~~**StackView Depth Non Limitato**~~ ✅ **RISOLTO**
   - ~~**Problema**: StackView può accumulare molti item~~
   - ~~**Impatto**: Memoria crescente con uso prolungato~~
   - **Soluzione implementata**:
     - Uso di `replace()` invece di `push()` (pattern ufficiale KDE) - mantiene solo 1-2 item durante transizioni
     - `onDeactivated` distrugge immediatamente quando item viene disattivato (pattern ufficiale KDE)
     - `onRemoved` distrugge quando item viene rimosso completamente
     - Monitoraggio depth con `onDepthChanged` per sicurezza (allerta se > 3)
     - Pattern conforme alla documentazione ufficiale Qt/KDE
     - Con `replace()`, depth dovrebbe essere sempre 1-2 (corrente + nuovo durante transizione)
     - Cleanup aggressivo seguendo pattern plugin ufficiale KDE (`org.kde.slideshow`)

### Metriche Specifiche 📊

- **Righe di codice**: 889 (main.qml) + 89 (ImageComponent.qml) = 978 righe
- **Console log**: 106 occorrenze (molto verbose)
- **Funzioni principali**: 
  - `loadPhotos()`: Caricamento lista
  - `loadImageWithAuth()`: Download e conversione
  - `readExifOrientation()`: Parsing EXIF (160 righe)
  - `arrayBufferToBase64()`: Encoding base64
  - `nextPhoto()`: Selezione prossima immagine

### Aree di Miglioramento 🔧

1. **Memory Management**
   - Implementare cache LRU per data URL
   - Cleanup periodico ogni N immagini
   - Limitare dimensione massima data URL

2. **Performance**
   - Parsing EXIF asincrono
   - Base64 encoding in worker thread
   - Preload prossima immagine durante transizione

3. **Randomizzazione**
   - Implementare `recentIndices` come nel plugin video
   - Evitare ultimi 5-10 immagini invece di solo l'ultima

4. **Error Handling**
   - Timeout per download
   - Retry logic per errori di rete
   - Fallback per immagini corrotte

---

## 🎬 Nextcloud Video

### Architettura
- **File principale**: `main.qml` (610 righe)
- **Tecnologia**: MediaPlayer, VideoOutput, streaming diretto
- **Gestione memoria**: Cleanup aggressivo ogni 5 video

### Punti di Forza ✅

1. **Gestione Memoria Avanzata**
   - Cleanup aggressivo ogni 5 video
   - Disconnessione VideoOutput durante cleanup
   - Delay di 400ms per memory release
   - Feedback visivo durante cleanup

2. **Randomizzazione Sofisticata**
   - Mode 1: Evita ultimi 3-10 video (adattivo)
   - Mode 3: Smart random con tracking recentIndices (ultimi 10)
   - Fallback intelligente quando tutti i video sono recenti

3. **Gestione Stati MediaPlayer**
   - Gestione corretta di Playing, Loading, Stopped
   - Timer per switch automatico
   - Loop video configurabile
   - Gestione errori con retry automatico

4. **Streaming Diretto**
   - URL con autenticazione embedded
   - Nessuna conversione necessaria
   - Supporto HTTP e HTTPS

### Problemi Identificati ⚠️

1. **Cleanup Timer Fisso**
   - **Problema**: Delay fisso di 400ms potrebbe non essere sufficiente per video grandi
   - **Codice**: Linea 399 (`interval: 400`)
   - **Impatto**: Video grandi potrebbero non avere tempo sufficiente per cleanup
   - **Suggerimento**: Delay dinamico basato su dimensione video o stato MediaPlayer

2. **Race Condition Potenziale**
   - **Problema**: Cleanup aggressivo e switch video possono sovrapporsi
   - **Codice**: Linee 343-347, 404-417
   - **Scenario**: Se `nextVideo()` viene chiamato durante cleanup aggressivo
   - **Suggerimento**: Aggiungere flag per prevenire switch durante cleanup

3. **Doppio Switch Possibile**
   - **Problema**: Se video finisce (StoppedState) e timer scade contemporaneamente
   - **Codice**: Linee 484-492, 388-393
   - **Impatto**: Video potrebbe essere saltato
   - **Suggerimento**: Aggiungere debounce o flag per prevenire doppio switch

4. **Cleanup Frequency Fissa**
   - **Problema**: Cleanup ogni 5 video potrebbe non essere sufficiente per sistemi con poca RAM
   - **Codice**: Linea 338 (`var needsExtraCleanup = (videoSwitchCount >= 5)`)
   - **Suggerimento**: Rendere configurabile o basato su memoria disponibile

5. **Nessun Preloading**
   - **Problema**: Video viene caricato solo quando necessario
   - **Impatto**: Delay tra video più lungo
   - **Suggerimento**: Preload prossimo video durante riproduzione (con cautela per memoria)

6. **Buffer Management Opaco**
   - **Problema**: MediaPlayer gestisce buffer internamente, nessun controllo diretto
   - **Impatto**: Impossibile ottimizzare buffer per sistemi con poca RAM
   - **Suggerimento**: Monitorare uso memoria e adattare cleanup

7. **Nessun Timeout per Caricamento**
   - **Problema**: MediaPlayer non ha timeout esplicito
   - **Codice**: Linee 415-416
   - **Impatto**: Video che non caricano possono bloccare indefinitamente
   - **Suggerimento**: Aggiungere timeout e skip automatico

8. **Video URL in Memoria**
   - **Problema**: Tutti gli URL video vengono mantenuti in memoria
   - **Codice**: Linea 26 (`property var videoList: []`)
   - **Impatto**: Per liste molto grandi (>1000 video), può essere un problema
   - **Suggerimento**: Lazy loading o paginazione

### Metriche Specifiche 📊

- **Righe di codice**: 610 (main.qml)
- **Console log**: 26 occorrenze
- **Funzioni principali**:
  - `loadVideos()`: Caricamento lista
  - `nextVideo()`: Selezione prossimo video (103 righe, logica complessa)
  - `updateCurrentVideo()`: Switch video
  - `performAggressiveCleanup()`: Cleanup memoria

### Aree di Miglioramento 🔧

1. **Memory Management**
   - Cleanup adattivo basato su memoria disponibile
   - Preloading selettivo (solo prossimo video)
   - Monitoraggio uso memoria

2. **Performance**
   - Delay dinamico per cleanup
   - Preload prossimo video
   - Ottimizzazione buffer MediaPlayer

3. **Stabilità**
   - Prevenire race conditions
   - Debounce per switch video
   - Timeout per caricamento

4. **Scalabilità**
   - Lazy loading per liste grandi
   - Paginazione video
   - Cache management

---

## ⚖️ Confronto Diretto

### Architettura

| Aspetto | Carousel | Video |
|---------|----------|-------|
| **Tecnologia rendering** | StackView + Image | MediaPlayer + VideoOutput |
| **Download** | XHR + Base64 | Streaming diretto |
| **Autenticazione** | Embedded in URL | Embedded in URL |
| **Memory management** | Automatico (StackView) | Manuale (cleanup aggressivo) |
| **Transizioni** | Fade/Slide/Zoom | Nessuna (switch diretto) |

### Memory Management

| Aspetto | Carousel | Video |
|---------|----------|-------|
| **Cleanup aggressivo** | ❌ No | ✅ Ogni 5 video |
| **Cleanup automatico** | ✅ StackView | ❌ No |
| **Data URL in memoria** | ✅ Sì (problema) | ❌ No |
| **URL in memoria** | ✅ Sì | ✅ Sì |
| **Memory leak rischio** | ⚠️ Medio-Alto | ⚠️ Basso-Medio |

### Randomizzazione

| Mode | Carousel | Video |
|------|----------|-------|
| **0 - Sequential** | ✅ Identico | ✅ Identico |
| **1 - Random** | ⚠️ Solo evita ultimo | ✅ Evita ultimi 3-10 |
| **2 - Shuffle Once** | ✅ Identico | ✅ Identico |
| **3 - Smart Random** | ⚠️ Solo evita ultimo | ✅ Evita ultimi 5-10 |

### Performance

| Aspetto | Carousel | Video |
|---------|----------|-------|
| **Parsing sincrono** | ⚠️ EXIF (pesante) | ✅ Nessuno |
| **Encoding sincrono** | ⚠️ Base64 (pesante) | ✅ Nessuno |
| **Download** | ⚠️ Completo prima di mostrare | ✅ Streaming |
| **Switch delay** | ⚠️ Dipende da download | ✅ Dipende da cleanup |

### Error Handling

| Aspetto | Carousel | Video |
|---------|----------|-------|
| **Timeout** | ❌ No | ❌ No |
| **Retry** | ❌ No | ✅ Sì (automatico) |
| **Error logging** | ✅ Sì | ✅ Sì |
| **Fallback** | ❌ No | ✅ Skip a prossimo |

---

## 🔴 Problemi Comuni

### 1. Network Handling
- **Entrambi**: Nessun timeout esplicito per richieste XHR
- **Impatto**: Richieste lente possono bloccare indefinitamente
- **Suggerimento**: Aggiungere timeout e retry logic in entrambi

### 2. Memory Management
- **Carousel**: Data URL possono accumularsi
- **Video**: Cleanup potrebbe non essere sufficiente per sistemi con poca RAM
- **Suggerimento**: Implementare monitoraggio memoria e cleanup adattivo

### 3. Randomizzazione
- ~~**Carousel**: Mode 1 meno sofisticato del Video~~ ✅ **RISOLTO**
- ~~**Suggerimento**: Allineare logica randomizzazione tra i due plugin~~ ✅ **COMPLETATO**
- **Stato attuale**: Entrambi i plugin ora usano la stessa logica sofisticata con `recentIndices`

### 4. Error Handling
- **Entrambi**: Mancano timeout e retry logic robusti
- **Suggerimento**: Implementare gestione errori uniforme

### 5. Scalabilità
- **Entrambi**: Liste molto grandi (>1000 item) possono essere problematiche
- **Suggerimento**: Lazy loading o paginazione

---

## 💡 Raccomandazioni

### Priorità Alta 🔴

1. ~~**Carousel - Memory Leak Data URL**~~ ✅ **RISOLTO**
   - ~~Implementare cache LRU~~
   - ~~Cleanup periodico ogni N immagini~~
   - ~~Limitare dimensione massima data URL~~

2. **Video - Race Condition**
   - Aggiungere flag per prevenire switch durante cleanup
   - Debounce per switch video
   - Verificare stato prima di switch

3. **Entrambi - Timeout Network**
   - Aggiungere timeout per XHR
   - Retry logic con backoff esponenziale
   - Skip automatico su errori persistenti

### Priorità Media 🟡

4. **Carousel - Randomizzazione**
   - Implementare `recentIndices` come nel Video
   - Evitare ultimi 5-10 immagini

5. **Video - Cleanup Adattivo**
   - Rendere frequenza cleanup configurabile
   - Basare su memoria disponibile
   - Monitoraggio uso memoria

6. **Carousel - Performance**
   - Parsing EXIF asincrono
   - Base64 encoding in worker thread
   - Preload prossima immagine

### Priorità Bassa 🟢

7. **Entrambi - Scalabilità**
   - Lazy loading per liste grandi
   - Paginazione
   - Cache management

8. **Video - Preloading**
   - Preload prossimo video (con cautela)
   - Monitorare uso memoria

9. **Entrambi - Metriche**
   - Aggiungere logging opzionale per performance
   - Tempi di caricamento
   - Uso memoria

---

## 📝 Conclusioni

### Nextcloud Carousel
- **Stato**: Funzionale ma con problemi di memoria per immagini grandi
- **Punti critici**: Data URL in memoria, parsing EXIF sincrono, randomizzazione semplice
- **Priorità**: Risolvere memory leak data URL

### Nextcloud Video
- **Stato**: Ben strutturato con buona gestione memoria
- **Punti critici**: Race conditions potenziali, cleanup fisso, nessun timeout
- **Priorità**: Prevenire race conditions, aggiungere timeout

### Allineamento
- **Randomizzazione**: Allineare logica tra i due plugin
- **Error Handling**: Uniformare gestione errori
- **Network**: Aggiungere timeout in entrambi

Il plugin Video è più maturo e ben strutturato, mentre il Carousel ha problemi di memoria più critici ma è più semplice da ottimizzare.
