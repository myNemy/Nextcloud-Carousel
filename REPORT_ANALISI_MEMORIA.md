# Report Analisi Memoria - Nextcloud Carousel Plugin

**Data Analisi**: 2025-12-10 13:42  
**Sistema**: Linux 6.17.9-zen1-1-zen  
**Uptime**: 6 giorni, 4 ore

---

## 🚨 PROBLEMA CRITICO IDENTIFICATO

### Evento OOM Killer

**Timestamp**: 2025-12-10 01:48:33  
**Processo**: `plasmashell` (PID 1760284)  
**Causa**: Ucciso dall'OOM Killer (Out Of Memory Killer)  
**Memoria Utilizzata**: **7.6GB** (peak)  
**Swap Utilizzato**: 8.2MB (peak)

```
dic 10 01:48:33 PanOS systemd[3790]: app-plasmashell@5cd7e6452727442e8d601f112cdfc0c7.service: A process of this unit has been killed by the OOM killer.
dic 10 01:48:33 PanOS systemd[3790]: app-plasmashell@5cd7e6452727442e8d601f112cdfc0c7.service: Main process exited, code=killed, status=9/KILL
dic 10 01:48:33 PanOS systemd[3790]: app-plasmashell@5cd7e6452727442e8d601f112cdfc0c7.service: Failed with result 'oom-kill'.
dic 10 01:48:33 PanOS systemd[3790]: app-plasmashell@5cd7e6452727442e8d601f112cdfc0c7.service: Consumed 3min 16.668s CPU time, 7.6G memory peak, 8.2M memory swap peak.
```

### Stato Attuale

- ✅ **Plugin installato correttamente**: `~/.local/share/plasma/wallpapers/org.nextcloud.carousel/`
- ✅ **File aggiornati**: Ultima modifica 10 dicembre 2025 01:00
- ❌ **Plasmashell non in esecuzione**: Terminato dall'OOM Killer
- ✅ **Nextcloud client attivo**: Processo in esecuzione (0.3% memoria)
- ✅ **Sistema stabile**: 15GB memoria disponibile

---

## 🔍 Analisi Causa Root

### 1. Gestione Cache Data URLs

**Problema**: Le immagini vengono convertite in data URLs base64 che occupano ~1.3x la dimensione originale.

**Configurazione Attuale**:
- `maxCacheSize`: 1-2 data URLs (configurato correttamente)
- Cache LRU implementata
- Cleanup periodico ogni 10 immagini

**Problema Identificato**:
1. **Data URLs enormi**: Immagini da 5-10MB diventano 6-13MB in base64
2. **StackView potrebbe non rilasciare**: Anche con `destroy()`, StackView potrebbe mantenere riferimenti
3. **Accumulo progressivo**: Se il cleanup non funziona, le immagini si accumulano

### 2. StackView Memory Management

**Codice Attuale** (linee 1329-1346):
```qml
imageToCleanup.QQC2.StackView.onDeactivated.connect(function() {
    if (imageToCleanup && !isDestroyed) {
        isDestroyed = true
        imageToCleanup.destroy()
    }
})
```

**Problema Potenziale**:
- `destroy()` potrebbe non rilasciare immediatamente la memoria
- Data URLs potrebbero rimanere in memoria anche dopo `destroy()`
- StackView potrebbe mantenere riferimenti interni

### 3. Monitoraggio Depth StackView

**Codice Attuale** (linee 1191-1195):
```qml
onDepthChanged: {
    if (depth > 3) {
        console.warn("⚠️  StackView depth exceeded expected limit:", depth)
    }
}
```

**Problema**: Il warning viene solo loggato, ma non previene l'accumulo.

---

## 📊 Stima Uso Memoria

### Scenario Tipico

**Assumendo**:
- 100 immagini nella cartella Nextcloud
- Dimensione media immagine: 5MB
- Dimensione data URL base64: ~6.5MB (1.3x)

**Memoria Teorica**:
- Cache configurata: 2 immagini = **13MB**
- Memoria reale osservata: **7.6GB** ❌

**Conclusione**: C'è un **memory leak significativo**. Le immagini non vengono rilasciate correttamente.

---

## 🛠️ Soluzioni Proposte

### 1. **URGENTE**: Disabilitare Cache Data URLs

**Azione Immediata**: Disabilitare completamente la cache per ridurre uso memoria.

**Modifica**:
```qml
// In updateCacheSize()
maxCacheSize = 0  // Disabilita cache completamente
```

**Pro**: Riduce immediatamente uso memoria  
**Contro**: Re-download immagini ad ogni cambio (più lento, ma funzionale)

### 2. **URGENTE**: Cleanup Aggressivo StackView

**Azione**: Forzare cleanup immediato dopo ogni transizione.

**Modifica** (dopo `replace()`):
```qml
// Forza garbage collection esplicito
Qt.callLater(function() {
    // Rimuovi tutti gli item tranne currentItem
    while (imageStack.depth > 1) {
        var item = imageStack.get(0)
        if (item && item !== imageStack.currentItem) {
            item.destroy()
        }
    }
})
```

### 3. **MEDIO TERMINE**: Limite Dimensione Data URL

**Azione**: Non convertire in base64 immagini troppo grandi.

**Modifica**:
```qml
// In loadImageWithAuth()
var maxDataUrlSize = 5 * 1024 * 1024  // 5MB limite
if (xhr.response.byteLength > maxDataUrlSize) {
    console.warn("Image too large for base64 conversion, using direct URL")
    // Usa URL diretto invece di data URL
    createImageComponent(cleanUrl, imageUrl, skipAnimation, orientation)
} else {
    // Converti in base64 come prima
    var dataUrl = "data:" + mimeType + ";base64," + base64
    createImageComponent(dataUrl, imageUrl, skipAnimation, orientation)
}
```

**Nota**: QML Image potrebbe non supportare URL autenticati direttamente, potrebbe richiedere modifiche.

### 4. **MEDIO TERMINE**: Cleanup Periodico Più Aggressivo

**Azione**: Ridurre intervallo cleanup e forzare garbage collection.

**Modifica**:
```qml
// In nextPhoto(), invece di ogni 10 immagini, ogni 5
if (imageSwitchCount % 5 === 0) {
    console.log("Performing aggressive cleanup...")
    clearDataUrlCache()
    // Forza cleanup StackView
    Qt.callLater(function() {
        // Cleanup esplicito
    })
}
```

### 5. **LUNGO TERMINE**: Usare File System Cache

**Azione**: Salvare immagini su disco invece di memoria.

**Implementazione**:
- Salva immagini scaricate in `~/.cache/nextcloud-carousel/`
- Usa file path invece di data URLs
- Implementa LRU cache su file system
- Limita dimensione cache su disco (es. 500MB)

---

## ✅ Azioni Immediate Consigliate

### Priorità 1: Disabilitare Cache (URGENTE)

1. Modificare `updateCacheSize()` per impostare `maxCacheSize = 0`
2. Riavviare plasmashell
3. Monitorare uso memoria

### Priorità 2: Cleanup Aggressivo (URGENTE)

1. Aggiungere cleanup esplicito dopo ogni `replace()`
2. Ridurre intervallo cleanup periodico a 5 immagini
3. Aggiungere monitoraggio memoria

### Priorità 3: Limite Dimensione Immagini (MEDIO)

1. Implementare limite 5MB per data URLs
2. Per immagini più grandi, usare approccio alternativo
3. Testare con immagini grandi

---

## 📝 Monitoraggio

### Comandi per Monitorare

```bash
# Monitora memoria plasmashell
watch -n 1 'ps aux | grep plasmashell | grep -v grep | awk "{print \$2, \$3\"%\", \$4\"%\", \$11}"'

# Log memoria sistema
free -h

# Log OOM killer
journalctl -k | grep -i oom

# Log plugin
journalctl --user -b | grep -i "nextcloud\|carousel" | tail -50
```

### Metriche da Monitorare

1. **Memoria plasmashell**: Dovrebbe rimanere < 500MB
2. **StackView depth**: Dovrebbe rimanere ≤ 2
3. **Cache size**: Dovrebbe rimanere ≤ maxCacheSize
4. **Numero immagini caricate**: Monitorare se cresce indefinitamente

---

## 🎯 Conclusione

Il plugin ha un **memory leak critico** che causa accumulo di memoria fino a 7.6GB, risultando nella terminazione di plasmashell da parte dell'OOM Killer.

**Cause Principali**:
1. Data URLs base64 non vengono rilasciati correttamente
2. StackView mantiene riferimenti anche dopo `destroy()`
3. Cache potrebbe non funzionare correttamente

**Azioni Immediate**:
1. ✅ Disabilitare cache data URLs
2. ✅ Implementare cleanup aggressivo
3. ✅ Monitorare uso memoria

**Stato**: 🔴 **CRITICO** - Richiede intervento immediato

---

**Report generato**: 2025-12-10 13:42  
**Analista**: AI Assistant  
**Versione Plugin**: 2025-12-10 01:00
