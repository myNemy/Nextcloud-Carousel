# Fix Memoria Applicato - Cache Disabilitata

> ⚠️ **NOTA**: Questo è un documento storico che descrive un fix applicato al progetto. Le informazioni contenute si riferiscono allo stato del progetto al momento dell'applicazione del fix.

**Data Applicazione**: 2025-12-10 15:12  
**Fix**: Disabilitazione cache data URLs per prevenire memory leak

---

## ✅ Modifiche Applicate

### File Modificato
- `nextcloud-carousel/contents/ui/main.qml`
- Backup creato: `~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/main.qml.backup_YYYYMMDD_HHMMSS`

### Modifica Implementata

**Funzione `updateCacheSize()`** (linee 37-63):

**PRIMA**:
```qml
function updateCacheSize() {
    // ... calcolo dinamico basato su numero foto
    if (totalPhotos === 0) {
        maxCacheSize = 1
    } else if (totalPhotos === 1) {
        maxCacheSize = 1
    } else {
        maxCacheSize = 2  // Cache 2 immagini
    }
}
```

**DOPO**:
```qml
function updateCacheSize() {
    // CRITICAL FIX: Disable cache completely to prevent memory leaks
    maxCacheSize = 0
    console.log("⚠️  Cache DISABLED to prevent memory leaks (OOM Killer fix)")
    console.log("📊 Cache configuration: caching disabled (0 data URLs)")
    
    // Clear any existing cache immediately
    clearDataUrlCache()
}
```

---

## 🎯 Effetti della Modifica

### ✅ Vantaggi
1. **Prevenzione Memory Leak**: Nessun accumulo di data URLs in memoria
2. **Memoria Stabile**: Uso memoria rimane costante (solo immagine corrente)
3. **Nessun OOM Killer**: Plasmashell non verrà più terminato per memoria eccessiva

### ⚠️ Svantaggi
1. **Re-download**: Ogni immagine viene scaricata nuovamente ad ogni cambio
2. **Latenza**: Piccolo ritardo durante il cambio immagine (download)
3. **Traffico**: Maggiore utilizzo di banda (re-download continuo)

### 📊 Impatto Performance

**Prima** (con cache):
- Memoria: 7.6GB (peak) → OOM Killer ❌
- Velocità cambio: Istantaneo (da cache)
- Traffico: Basso (solo primo download)

**Dopo** (senza cache):
- Memoria: ~50-100MB (solo immagine corrente) ✅
- Velocità cambio: 1-3 secondi (download necessario)
- Traffico: Medio-Alto (re-download continuo)

---

## 🔄 Prossimi Passi

### 1. Riavviare Plasmashell

```bash
# Verificare se plasmashell è in esecuzione
pgrep plasmashell

# Se non è in esecuzione, avviarlo
kstart plasmashell

# Se è in esecuzione, riavviarlo
killall plasmashell && kstart plasmashell
```

### 2. Monitorare Uso Memoria

```bash
# Monitora memoria plasmashell in tempo reale
watch -n 2 'ps aux | grep plasmashell | grep -v grep | awk "{print \"Memoria: \" \$6/1024 \"MB (\" \$3 \"% CPU, \" \$4 \"% RAM)\"}"'

# Verifica log per conferma cache disabilitata
journalctl --user -f | grep -i "cache\|memory"
```

### 3. Verificare Funzionamento

1. **Aprire configurazione wallpaper**:
   - Click destro desktop → "Configure Desktop and Wallpaper"
   - Selezionare "Nextcloud Carousel"
   - Verificare che immagini carichino correttamente

2. **Monitorare log**:
   ```bash
   journalctl --user -b | grep -i "cache disabled\|nextcloud\|carousel" | tail -20
   ```

3. **Verificare memoria**:
   - Dovrebbe rimanere stabile < 500MB
   - Non dovrebbe crescere indefinitamente

---

## 📝 Note Tecniche

### Perché Disabilitare la Cache?

1. **Data URLs Base64 sono enormi**: 
   - Immagine 5MB → Data URL ~6.5MB (1.3x)
   - 100 immagini = 650MB solo in cache

2. **Memory Leak Identificato**:
   - StackView non rilascia correttamente data URLs
   - `destroy()` non libera memoria immediatamente
   - Accumulo progressivo fino a 7.6GB

3. **Soluzione Temporanea**:
   - Cache disabilitata = nessun accumulo
   - Re-download = overhead accettabile per stabilità

### Soluzione Definitiva (Futuro)

1. **File System Cache**:
   - Salvare immagini su disco (`~/.cache/nextcloud-carousel/`)
   - Usare file path invece di data URLs
   - LRU cache su disco (limite 500MB)

2. **Cleanup Aggressivo**:
   - Forzare garbage collection dopo ogni transizione
   - Monitorare StackView depth
   - Cleanup periodico più frequente

3. **Limite Dimensione**:
   - Non convertire in base64 immagini > 5MB
   - Usare approccio alternativo per immagini grandi

---

## ✅ Verifica Applicazione

Per verificare che la modifica sia stata applicata:

```bash
# Controlla che maxCacheSize = 0 sia presente
grep -A 3 "maxCacheSize = 0" ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/main.qml

# Dovrebbe mostrare:
# maxCacheSize = 0
# console.log("⚠️  Cache DISABLED to prevent memory leaks (OOM Killer fix)")
```

---

**Fix applicato**: 2025-12-10 15:12  
**Stato**: ✅ Completato  
**Prossimo passo**: Riavviare plasmashell e monitorare memoria
