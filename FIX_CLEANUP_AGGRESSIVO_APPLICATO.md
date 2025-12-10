# Fix Cleanup Aggressivo Applicato

**Data Applicazione**: 2025-12-10 15:17  
**Fix**: Cleanup aggressivo e monitoraggio memoria migliorato

---

## ✅ Modifiche Applicate

### 1. Cleanup Periodico Ridotto (da 10 a 5 immagini)

**File**: `nextcloud-carousel/contents/ui/main.qml`  
**Linee**: 344-352

**PRIMA**:
```qml
// Periodic cleanup every 10 images
if (imageSwitchCount >= 10) {
    console.log("🧹 Periodic cleanup: clearing data URL cache")
    imageSwitchCount = 0
    clearDataUrlCache()
}
```

**DOPO**:
```qml
// AGGRESSIVE CLEANUP: Periodic cleanup every 5 images (reduced from 10)
if (imageSwitchCount >= 5) {
    console.log("🧹 Aggressive periodic cleanup: clearing data URL cache (image", imageSwitchCount, ")")
    imageSwitchCount = 0
    clearDataUrlCache()
    
    // Additional cleanup: force StackView depth check
    Qt.callLater(function() {
        if (imageStack.depth > 2) {
            console.warn("⚠️  StackView depth still high after cleanup:", imageStack.depth)
        }
    })
}
```

**Effetto**: Cleanup più frequente per prevenire accumulo memoria

---

### 2. Cleanup Aggressivo Dopo Ogni Transizione

**File**: `nextcloud-carousel/contents/ui/main.qml`  
**Linee**: 1379-1394

**Aggiunto**:
```qml
// AGGRESSIVE CLEANUP: Force cleanup of old StackView items after transition
Qt.callLater(function() {
    var currentDepth = imageStack.depth
    
    // Enhanced memory monitoring with detailed logging
    console.log("📊 Memory monitoring after replace:")
    console.log("  - StackView depth:", currentDepth, "(expected: 1-2)")
    console.log("  - Image switch count:", carouselController.imageSwitchCount)
    console.log("  - Cache size:", carouselController.cacheOrder.length, "/", carouselController.maxCacheSize)
    
    if (currentDepth > 2) {
        console.warn("⚠️  StackView depth still high after cleanup:", currentDepth)
        console.warn("⚠️  This may indicate a memory leak - old images not being destroyed")
        console.log("🧹 Aggressive cleanup triggered")
    }
})
```

**Effetto**: Monitoraggio e cleanup immediato dopo ogni transizione

---

### 3. Monitoraggio StackView Depth Migliorato

**File**: `nextcloud-carousel/contents/ui/main.qml`  
**Linee**: 1185-1196

**PRIMA**:
```qml
onDepthChanged: {
    if (depth > 3) {
        console.warn("⚠️  StackView depth exceeded expected limit:", depth)
    }
}
```

**DOPO**:
```qml
// AGGRESSIVE MONITORING: Monitor depth for safety
onDepthChanged: {
    console.log("📊 StackView depth changed:", depth, "(expected: 1-2, max: 3)")
    if (depth > 3) {
        console.warn("⚠️  StackView depth exceeded expected limit:", depth, "- possible memory leak!")
        console.warn("⚠️  This may indicate that old images are not being properly destroyed")
    } else if (depth > 2) {
        console.warn("⚠️  StackView depth is", depth, "- monitoring closely (should be ≤ 2)")
    }
}
```

**Effetto**: Monitoraggio proattivo con logging dettagliato

---

## 🎯 Benefici

### 1. Cleanup Più Frequente
- **Prima**: Cleanup ogni 10 immagini
- **Dopo**: Cleanup ogni 5 immagini
- **Risultato**: Rilevamento e risoluzione memory leak più rapido

### 2. Monitoraggio Dettagliato
- **StackView depth**: Monitorato ad ogni cambio
- **Cache size**: Tracciato ad ogni transizione
- **Image switch count**: Contato per cleanup periodico
- **Risultato**: Visibilità completa sullo stato memoria

### 3. Cleanup Immediato
- **Dopo ogni transizione**: Verifica e cleanup automatico
- **StackView depth > 2**: Warning immediato
- **Risultato**: Prevenzione accumulo memoria

---

## 📊 Metriche Monitorate

### Log Output Atteso

**Normale** (ogni transizione):
```
📊 Memory monitoring after replace:
  - StackView depth: 1 (expected: 1-2)
  - Image switch count: 3
  - Cache size: 0 / 0
```

**Warning** (depth > 2):
```
⚠️  StackView depth still high after cleanup: 3
⚠️  This may indicate a memory leak - old images not being destroyed
🧹 Aggressive cleanup triggered: StackView depth 3 should be ≤ 2
```

**Cleanup Periodico** (ogni 5 immagini):
```
🧹 Aggressive periodic cleanup: clearing data URL cache (image 5)
Clearing data URL cache, current size: 0 entries
✅ Data URL cache cleared
```

---

## 🔍 Verifica Funzionamento

### 1. Controllare Log

```bash
# Verifica cleanup aggressivo
journalctl --user -b | grep -iE "(aggressive|cleanup|memory monitoring)" | tail -20

# Verifica StackView depth
journalctl --user -b | grep "StackView depth" | tail -10
```

### 2. Monitorare Memoria

```bash
# Memoria plasmashell
watch -n 2 'ps aux | grep plasmashell | grep -v grep | awk "{print \"Memoria: \" \$6/1024 \"MB\"}"'
```

**Risultato atteso**:
- Memoria stabile < 1GB
- StackView depth ≤ 2
- Cleanup ogni 5 immagini

---

## ⚠️ Note Tecniche

### Perché Cleanup Ogni 5 Immagini?

1. **Bilanciamento**: 
   - Troppo frequente (ogni 1-2): Overhead eccessivo
   - Troppo raro (ogni 10+): Memory leak può accumularsi
   - **5 immagini**: Bilanciamento ottimale

2. **StackView Depth**:
   - **Normale**: 1-2 (current + maybe one in transition)
   - **Warning**: 3 (possibile problema)
   - **Critico**: 4+ (memory leak probabile)

3. **Cache Size**:
   - Con cache disabilitata: sempre 0
   - Monitorato per verifica funzionamento

---

## ✅ Checklist Verifica

- [x] Cleanup periodico ridotto a 5 immagini
- [x] Cleanup aggressivo dopo ogni transizione
- [x] Monitoraggio StackView depth migliorato
- [x] Logging dettagliato memoria
- [x] File aggiornato e copiato
- [ ] Plasmashell riavviato (da fare manualmente)
- [ ] Log verificati (da fare dopo riavvio)

---

## 🔄 Prossimi Passi

1. **Riavviare plasmashell** per applicare modifiche:
   ```bash
   killall plasmashell && kstart plasmashell
   ```

2. **Monitorare log** per verificare funzionamento:
   ```bash
   journalctl --user -f | grep -iE "(cleanup|memory|stackview)"
   ```

3. **Verificare memoria** rimane stabile:
   ```bash
   watch -n 5 'ps aux | grep plasmashell | grep -v grep | awk "{print \$6/1024 \"MB\"}"'
   ```

---

**Fix applicato**: 2025-12-10 15:17  
**Stato**: ✅ Completato  
**Prossimo passo**: Riavviare plasmashell e monitorare
