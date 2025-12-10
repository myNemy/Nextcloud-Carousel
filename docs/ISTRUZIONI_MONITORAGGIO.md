# Istruzioni Monitoraggio Memoria - Nextcloud Carousel

> ℹ️ **NOTA**: Questo documento contiene istruzioni per il monitoraggio della memoria del plugin. Alcune informazioni potrebbero riferirsi a fix specifici applicati in passato.

**Data**: 2025-12-10  
**Fix Applicato**: Cache disabilitata per prevenire memory leak

---

## ✅ Fix Applicato

La cache data URLs è stata **disabilitata** per prevenire l'accumulo di memoria che causava l'OOM Killer.

**Stato Attuale**:
- ✅ Modifica applicata: `maxCacheSize = 0`
- ✅ Plasmashell riavviato
- ✅ Memoria iniziale: ~520MB (normale per avvio)

---

## 📊 Comandi Monitoraggio

### 1. Monitorare Memoria Plasmashell in Tempo Reale

```bash
# Aggiornamento ogni 2 secondi
watch -n 2 'ps aux | grep plasmashell | grep -v grep | awk "{print \"Memoria: \" \$6/1024 \"MB (\" \$3 \"% CPU, \" \$4 \"% RAM)\"}"'
```

**Cosa aspettarsi**:
- **Normale**: 200-500MB (dipende da numero di widget/plugin)
- **Con plugin attivo**: 300-800MB (immagine corrente caricata)
- **⚠️ Allarme**: > 1.5GB (possibile memory leak)

### 2. Verificare Log Cache Disabilitata

```bash
# Verifica che la cache sia disabilitata
journalctl --user -b | grep -i "cache disabled\|cache configuration" | tail -10
```

**Output atteso**:
```
⚠️  Cache DISABLED to prevent memory leaks (OOM Killer fix)
📊 Cache configuration: caching disabled (0 data URLs)
```

### 3. Monitorare Uso Memoria Sistema

```bash
# Memoria totale sistema
free -h

# Top process per memoria
ps aux --sort=-%mem | head -10
```

### 4. Verificare Funzionamento Plugin

```bash
# Log plugin Nextcloud Carousel
journalctl --user -b | grep -iE "(nextcloud|carousel)" | tail -20

# Cerca errori
journalctl --user -b | grep -iE "(error|warning|fail)" | grep -iE "(nextcloud|carousel)" | tail -10
```

### 5. Monitorare StackView Depth

```bash
# Verifica depth StackView (dovrebbe rimanere ≤ 2)
journalctl --user -b | grep -i "stackview depth" | tail -10
```

**Output atteso**:
- `StackView depth after replace: 1` ✅ (normale)
- `StackView depth after replace: 2` ✅ (durante transizione)
- `StackView depth exceeded expected limit: 3` ⚠️ (possibile problema)

---

## 🎯 Metriche da Monitorare

### Memoria Plasmashell

| Stato | Memoria | Azione |
|-------|---------|--------|
| ✅ Normale | < 500MB | Nessuna azione |
| 🟡 Attenzione | 500MB - 1GB | Monitorare |
| 🟠 Allarme | 1GB - 1.5GB | Verificare log |
| 🔴 Critico | > 1.5GB | Riavviare plasmashell |

### Cache Size

| Valore | Significato |
|--------|-------------|
| `0` | ✅ Cache disabilitata (corretto) |
| `1-2` | ⚠️ Cache abilitata (non dovrebbe accadere) |

### StackView Depth

| Valore | Significato |
|--------|-------------|
| `1` | ✅ Normale (solo immagine corrente) |
| `2` | ✅ Normale (durante transizione) |
| `3+` | ⚠️ Possibile memory leak |

---

## 🔍 Verifica Funzionamento Plugin

### 1. Test Base

1. **Aprire configurazione**:
   - Click destro desktop → "Configure Desktop and Wallpaper"
   - Selezionare "Nextcloud Carousel"
   - Verificare che appaia nella lista

2. **Configurare plugin**:
   - Inserire URL Nextcloud
   - Inserire username e password
   - Inserire percorso foto (es. `/Photos`)
   - Applicare

3. **Verificare caricamento**:
   - Le immagini dovrebbero caricarsi (con piccolo ritardo per download)
   - Cambio immagine ogni `SlideInterval` secondi
   - Nessun errore nei log

### 2. Test Memoria

```bash
# Prima di attivare plugin
ps aux | grep plasmashell | grep -v grep | awk '{print "Memoria prima:", $6/1024 "MB"}'

# Attivare plugin e attendere 5 minuti

# Dopo 5 minuti
ps aux | grep plasmashell | grep -v grep | awk '{print "Memoria dopo:", $6/1024 "MB"}'
```

**Risultato atteso**:
- Memoria dovrebbe rimanere **stabile** (< 1GB)
- Non dovrebbe crescere indefinitamente
- Piccole fluttuazioni sono normali (caricamento/scaricamento immagini)

---

## ⚠️ Segnali di Allarme

### Memory Leak in Corso

1. **Memoria cresce costantemente**:
   ```bash
   # Monitora per 10 minuti
   for i in {1..10}; do
       ps aux | grep plasmashell | grep -v grep | awk '{print $6/1024 "MB"}'
       sleep 60
   done
   ```
   - Se memoria cresce > 100MB ogni minuto → **PROBLEMA**

2. **StackView depth > 3**:
   - Indica che le immagini non vengono rilasciate
   - Verificare log per errori

3. **OOM Killer attivato**:
   ```bash
   journalctl -k | grep -i oom | tail -5
   ```
   - Se plasmashell viene ucciso → **PROBLEMA CRITICO**

### Azioni in Caso di Problema

1. **Memoria > 1.5GB**:
   ```bash
   # Riavviare plasmashell
   killall plasmashell && kstart plasmashell
   ```

2. **OOM Killer attivato**:
   - Verificare che cache sia disabilitata
   - Controllare log per errori
   - Considerare ripristino backup

3. **Plugin non funziona**:
   - Verificare configurazione Nextcloud
   - Controllare log per errori di connessione
   - Verificare che plugin sia installato correttamente

---

## 📝 Log da Controllare

### Log Importanti

```bash
# Cache disabilitata (dovrebbe apparire all'avvio)
journalctl --user -b | grep "Cache DISABLED"

# Caricamento immagini
journalctl --user -b | grep "Loading image\|Downloading image"

# Errori
journalctl --user -b | grep -iE "(error|warning|fail)" | grep -iE "(nextcloud|carousel)"

# StackView depth
journalctl --user -b | grep "StackView depth"
```

---

## ✅ Checklist Verifica

- [ ] Cache disabilitata (`maxCacheSize = 0`)
- [ ] Plasmashell in esecuzione
- [ ] Memoria < 1GB
- [ ] Plugin appare nella lista wallpaper
- [ ] Immagini caricano correttamente
- [ ] Nessun errore nei log
- [ ] StackView depth ≤ 2
- [ ] Memoria rimane stabile dopo 10 minuti

---

## 🔄 Ripristino Backup (se necessario)

Se qualcosa va storto, puoi ripristinare il backup:

```bash
# Trovare backup più recente
ls -lt ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/main.qml.backup_* | head -1

# Ripristinare
cp ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/main.qml.backup_YYYYMMDD_HHMMSS \
   ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/main.qml

# Riavviare plasmashell
killall plasmashell && kstart plasmashell
```

---

**Documento creato**: 2025-12-10 15:12  
**Stato**: ✅ Fix applicato, monitoraggio attivo
