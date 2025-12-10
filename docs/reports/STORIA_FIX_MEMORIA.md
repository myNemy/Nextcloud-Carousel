# Storia Fix Memoria - Nextcloud Carousel

> ⚠️ **NOTA**: Questo documento riassume la storia del problema di memoria identificato e risolto nel dicembre 2025. I fix descritti sono stati applicati e verificati.

**Periodo**: Dicembre 2025  
**Problema**: Memory leak critico che causava OOM Killer  
**Stato**: ✅ **RISOLTO**

---

## 📋 Riepilogo

Il plugin Nextcloud Carousel ha subito un problema critico di memory leak che causava l'accumulo di memoria fino a 7.6GB, risultando nella terminazione di plasmashell da parte dell'OOM Killer. Il problema è stato identificato, analizzato e risolto attraverso una serie di fix applicati tra il 10 e l'11 dicembre 2025.

---

## 🚨 Problema Identificato (10 Dicembre 2025)

### Evento OOM Killer

**Timestamp**: 2025-12-10 01:48:33  
**Processo**: `plasmashell` (PID 1760284)  
**Memoria Utilizzata**: **7.6GB** (peak)  
**Causa**: Memory leak che causava accumulo progressivo di memoria

### Analisi Causa Root

1. **Data URLs Base64 enormi**: 
   - Immagini da 5-10MB diventano 6-13MB in base64 (1.3x)
   - Cache configurata per 1-2 immagini ma accumulo fino a 7.6GB

2. **StackView Memory Management**:
   - `destroy()` non rilascia immediatamente la memoria
   - Data URLs rimangono in memoria anche dopo `destroy()`
   - StackView mantiene riferimenti interni

3. **Cache non funzionante correttamente**:
   - Cleanup periodico ogni 10 immagini insufficiente
   - Accumulo progressivo non rilevato

---

## ✅ Fix Applicati

### Fix 1: Cache Disabilitata (10 Dicembre 2025, 15:12)

**Modifica**: Disabilitazione completa della cache data URLs

**File**: `nextcloud-carousel/contents/ui/main.qml`

```qml
function updateCacheSize() {
    // CRITICAL FIX: Disable cache completely to prevent memory leaks
    maxCacheSize = 0
    console.log("⚠️  Cache DISABLED to prevent memory leaks (OOM Killer fix)")
    clearDataUrlCache()
}
```

**Risultato**:
- ✅ Memoria ridotta da 7.6GB a ~50-100MB
- ✅ Nessun accumulo di data URLs
- ⚠️ Re-download necessario ad ogni cambio immagine (overhead accettabile)

### Fix 2: Cleanup Aggressivo (10 Dicembre 2025, 15:17)

**Modifiche**:
1. Cleanup periodico ridotto da 10 a 5 immagini
2. Cleanup aggressivo dopo ogni transizione
3. Monitoraggio StackView depth migliorato

**Risultato**:
- ✅ Cleanup più frequente previene accumulo
- ✅ Monitoraggio dettagliato dello stato memoria
- ✅ StackView depth sempre ≤ 2 (normale)

---

## ✅ Verifica Post-Fix (10 Dicembre 2025, 17:45)

### Risultati

**Memoria Plasmashell**: 616MB (prima: 7.6GB)  
**Riduzione**: **~92%** di memoria in meno

**Metriche**:
- ✅ Memoria stabile (non cresce)
- ✅ StackView depth: 1 (normale)
- ✅ Cleanup periodico funzionante (ogni 5 immagini)
- ✅ Nessun OOM Killer
- ✅ Nessun errore critico

**Conclusione**: ✅ **Sistema stabile e funzionante**

---

## 📊 Stato Attuale

### Implementazione

I fix sono stati applicati e sono attivi nel codice:
- ✅ Cache disabilitata (`maxCacheSize = 0`)
- ✅ Cleanup aggressivo ogni 5 immagini
- ✅ Monitoraggio memoria attivo
- ✅ StackView depth monitoring

### Performance

- **Memoria**: Stabile a ~300-800MB (normale per plugin attivo)
- **Velocità cambio immagine**: 1-3 secondi (download necessario)
- **Traffico**: Medio-Alto (re-download continuo)

### Note Tecniche

**Perché la cache è disabilitata**:
- Data URLs base64 occupano ~1.3x la dimensione originale
- StackView non rilascia correttamente data URLs anche con `destroy()`
- Re-download è preferibile rispetto a memory leak

**Soluzione Futura (Lungo Termine)**:
- Implementare file system cache (`~/.cache/nextcloud-carousel/`)
- Usare file path invece di data URLs
- LRU cache su disco (limite 500MB)

---

## 📝 Documenti Originali

Per dettagli tecnici completi, consultare i documenti originali:
- `REPORT_ANALISI_MEMORIA.md` - Analisi dettagliata del problema
- `FIX_MEMORIA_APPLICATO.md` - Dettagli tecnici del fix cache
- `FIX_CLEANUP_AGGRESSIVO_APPLICATO.md` - Dettagli tecnici del cleanup
- `VERIFICA_POST_FIX.md` - Verifica completa post-fix

---

**Documento creato**: 2025-12-10  
**Ultimo aggiornamento**: 2025-12-10  
**Stato**: ✅ Problema risolto, fix attivi
