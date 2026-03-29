/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QtControls2
import org.kde.kquickcontrols as KQuickControls
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: root
    twinFormLayouts: parentLayout

    property alias cfg_NextcloudUrl: nextcloudUrlField.text
    property alias cfg_Username: usernameField.text
    property alias cfg_Password: passwordField.text
    property alias cfg_PhotoPath: photoPathField.text
    property alias cfg_SlideInterval: slideIntervalField.text
    property alias cfg_RandomOrder: randomOrderComboBox.currentIndex
    property alias cfg_Blur: blurCheckBox.checked
    property alias cfg_BlurOpacity: blurOpacitySlider.value
    property alias cfg_FillMode: fillModeComboBox.currentIndex
    property alias cfg_ImageScale: imageScaleSlider.value
    property alias cfg_Color: colorButton.color
    property alias cfg_ShowLoadingIndicator: showLoadingIndicatorCheckBox.checked
    property alias cfg_ShowExifInfo: showExifInfoCheckBox.checked
    property alias cfg_ExifInfoDuration: exifInfoDurationField.text
    property alias cfg_ShowLocationOsd: showLocationOsdCheckBox.checked
    property alias cfg_LocationOsdFontSize: locationOsdFontSizeField.text
    property alias cfg_LocationOsdPosition: locationOsdPositionComboBox.currentIndex
    property alias cfg_LocationOsdXOffset: locationOsdXOffsetField.text
    property alias cfg_LocationOsdYOffset: locationOsdYOffsetField.text
    property alias cfg_LocationOsdFontFamily: locationOsdFontFamilyComboBox.currentText
    property alias cfg_MaxImageSizeMB: maxImageSizeMBField.text
    property alias cfg_ShowMethodIndicator: showMethodIndicatorCheckBox.checked
    property alias cfg_MethodIndicatorDuration: methodIndicatorDurationField.text
    property alias cfg_QmlDataUrlFallback: qmlDataUrlFallbackCheckBox.checked
    property alias formLayout: root

    // Proprietà per sezioni collassabili
    property bool sectionNextcloudExpanded: true
    property bool sectionSlideshowExpanded: true
    property bool sectionVisualizationExpanded: true
    property bool sectionOverlayExpanded: true

    // ============================================
    // SEZIONE 1: CONNESSIONE NEXTCLOUD
    // ============================================
    
    QtControls2.CheckBox {
        Kirigami.FormData.isSection: true
        text: i18n("Connessione Nextcloud")
        checked: sectionNextcloudExpanded
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
        onCheckedChanged: sectionNextcloudExpanded = checked
    }

    QtControls2.TextField {
        id: nextcloudUrlField
        Kirigami.FormData.label: i18n("Nextcloud URL:")
        placeholderText: i18n("https://nextcloud.example.com")
        visible: sectionNextcloudExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("URL del server Nextcloud (es. https://nextcloud.example.com)\n\nFormato: https://dominio.com (senza barra finale)\nDeve essere accessibile dal tuo computer")
    }

    QtControls2.TextField {
        id: usernameField
        Kirigami.FormData.label: i18n("Username:")
        placeholderText: i18n("Il tuo username Nextcloud")
        visible: sectionNextcloudExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Il tuo username Nextcloud per l'autenticazione\n\nDeve corrispondere esattamente al nome utente usato per accedere a Nextcloud")
    }

    QtControls2.TextField {
        id: passwordField
        Kirigami.FormData.label: i18n("Password:")
        placeholderText: i18n("Password o app password")
        echoMode: QtControls2.TextField.Password
        visible: sectionNextcloudExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Password Nextcloud o app password (consigliato per sicurezza)\n\nApp password: Nextcloud → Impostazioni → Sicurezza → App passwords\nLe app password possono essere revocate individualmente e sono più sicure")
    }

    QtControls2.TextField {
        id: photoPathField
        Kirigami.FormData.label: i18n("Percorso Foto:")
        placeholderText: i18n("/Photos")
        visible: sectionNextcloudExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Percorso alla cartella foto su Nextcloud (cerca anche nelle sottocartelle)\n\nEsempi: /Photos, /Pictures/Vacation, /Media/Images\nDeve iniziare con / e corrispondere al percorso esatto in Nextcloud")
    }

    QtControls2.TextField {
        id: maxImageSizeMBField
        Kirigami.FormData.label: i18n("Limite Dimensione Immagini (MB):")
        placeholderText: i18n("0")
        visible: sectionNextcloudExpanded
        validator: IntValidator {
            bottom: 0
            top: 50
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Dimensione massima immagini da caricare (0 = auto, 3-50MB)\n\nImmagini più grandi vengono saltate per prevenire problemi di memoria.\n\nValori consigliati:\n• 0 = Auto (usa 5MB di default)\n• 3-5MB = Sistemi con poca RAM (< 8GB)\n• 5-10MB = Sistemi medi (8-16GB RAM)\n• 10-15MB = Sistemi potenti (> 16GB RAM)\n• 15-20MB = Solo sistemi molto potenti (> 32GB RAM)\n\nLimite massimo: 50MB (per sicurezza)")
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: false
    }

    // ============================================
    // SEZIONE 2: IMPOSTAZIONI SLIDESHOW
    // ============================================
    
    QtControls2.CheckBox {
        Kirigami.FormData.isSection: true
        text: i18n("Impostazioni Slideshow")
        checked: sectionSlideshowExpanded
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
        onCheckedChanged: sectionSlideshowExpanded = checked
    }

    QtControls2.TextField {
        id: slideIntervalField
        Kirigami.FormData.label: i18n("Intervallo Slide (secondi):")
        placeholderText: i18n("10")
        visible: sectionSlideshowExpanded
        validator: IntValidator {
            bottom: 1
            top: 3600
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Tempo di visualizzazione di ogni immagine prima di passare alla successiva\n\nRange: 1-3600 secondi\nConsigliato: 10-30 secondi per foto, 5-10 secondi per immagini veloci\nValori molto bassi (< 5s) possono causare uso eccessivo di banda")
    }

    QtControls2.ComboBox {
        id: randomOrderComboBox
        Kirigami.FormData.label: i18n("Modalità Ordine:")
        visible: sectionSlideshowExpanded
        model: [
            i18n("Sequenziale"),
            i18n("Casuale (ogni volta)"),
            i18n("Mescola Una Volta"),
            i18n("Casuale Intelligente (evita ripetizioni)")
        ]
        currentIndex: wallpaper.configuration.RandomOrder || 0
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Come vengono ordinate le immagini:\n\n• Sequenziale: in ordine come appaiono in Nextcloud\n• Casuale: ordine completamente casuale ad ogni ciclo\n• Mescola Una Volta: mescola all'inizio, poi sequenziale\n• Casuale Intelligente: evita di mostrare immagini recenti, migliore varietà")
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: false
    }

    // ============================================
    // SEZIONE 3: VISUALIZZAZIONE IMMAGINE
    // ============================================

    QtControls2.CheckBox {
        Kirigami.FormData.isSection: true
        text: i18n("Visualizzazione Immagine")
        checked: sectionVisualizationExpanded
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
        onCheckedChanged: sectionVisualizationExpanded = checked
    }

    QtControls2.ComboBox {
        id: fillModeComboBox
        Kirigami.FormData.label: i18n("Modalità Riempimento:")
        visible: sectionVisualizationExpanded
        model: [
            i18n("Stretch (Allunga)"),
            i18n("Fit (Mantieni Proporzioni)"),
            i18n("Crop (Ritaglia)"),
            i18n("Tile (Piastrella)"),
            i18n("Tile Verticale"),
            i18n("Tile Orizzontale")
        ]
        currentIndex: wallpaper.configuration.FillMode || 2
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Come viene visualizzata l'immagine:\n\n• Stretch: allunga per riempire tutto lo schermo (può distorcere)\n• Fit: mantiene proporzioni, mostra tutta l'immagine (può lasciare bordi)\n• Crop: mantiene proporzioni, riempie lo schermo ritagliando (consigliato)\n• Tile: ripete l'immagine per riempire lo schermo\n• Tile Verticale: ripete solo verticalmente\n• Tile Orizzontale: ripete solo orizzontalmente")
    }

    Item {
        Kirigami.FormData.label: i18n("Scala Immagine (%):")
        Kirigami.FormData.buddyFor: imageScaleSlider
        implicitHeight: imageScaleSlider.implicitHeight
        visible: sectionVisualizationExpanded
        
        Row {
            anchors.fill: parent
            spacing: 10
            
            QtControls2.Slider {
                id: imageScaleSlider
                from: 50
                to: 200
                stepSize: 5
                value: wallpaper.configuration.ImageScale || 100
                width: 200
                QtControls2.ToolTip.delay: 1000
                QtControls2.ToolTip.visible: hovered
                QtControls2.ToolTip.text: i18n("Scala della dimensione dell'immagine\n\nRange: 50-200%\n• 50% = metà dimensione\n• 100% = dimensione normale (default)\n• 200% = doppia dimensione (può essere pixelata)\n\nUtile per zoomare immagini piccole o ridurre immagini molto grandi")
            }
            
            QtControls2.Label {
                text: Math.round(imageScaleSlider.value) + " %"
                width: 50
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("Colore di Sfondo:")
        visible: sectionVisualizationExpanded
        dialogTitle: i18n("Seleziona Colore di Sfondo")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Colore di sfondo mostrato durante il caricamento o se l'immagine non riempie lo schermo\n\nVisibile quando:\n• L'immagine è in caricamento\n• L'immagine è più piccola dello schermo (con modalità Fit)\n• C'è un errore nel caricamento")
    }

    QtControls2.CheckBox {
        id: blurCheckBox
        Kirigami.FormData.label: i18n("Sfondo sfocato:")
        text: i18n("Applica effetto sfocatura alle immagini")
        visible: sectionVisualizationExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Applica un effetto di sfocatura alle immagini per un aspetto più morbido e artistico\n\nL'effetto è semplificato (riduzione opacità) e può essere regolato con l'opacità sotto")
    }

    Item {
        Kirigami.FormData.label: i18n("Opacità Sfocatura (%):")
        Kirigami.FormData.buddyFor: blurOpacitySlider
        implicitHeight: blurOpacitySlider.implicitHeight
        visible: sectionVisualizationExpanded && blurCheckBox.checked
        
        Row {
            anchors.fill: parent
            spacing: 10
            
            QtControls2.Slider {
                id: blurOpacitySlider
                from: 0
                to: 100
                stepSize: 5
                value: wallpaper.configuration.BlurOpacity || 75
                width: 200
                QtControls2.ToolTip.delay: 1000
                QtControls2.ToolTip.visible: hovered
                QtControls2.ToolTip.text: i18n("Intensità dell'effetto di sfocatura\n\nRange: 0-100%\n• 0% = nessuna sfocatura (immagine normale)\n• 50% = sfocatura media\n• 100% = sfocatura massima (immagine molto trasparente)\n\nValori più bassi = immagine più visibile ma più sfocata")
            }
            
            QtControls2.Label {
                text: Math.round(blurOpacitySlider.value) + " %"
                width: 50
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Kirigami.Separator {
        Kirigami.FormData.isSection: false
    }

    // ============================================
    // SEZIONE 4: OVERLAY E INFORMAZIONI
    // ============================================
    
    QtControls2.CheckBox {
        Kirigami.FormData.isSection: true
        text: i18n("Overlay e Informazioni")
        checked: sectionOverlayExpanded
        font.bold: true
        font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
        onCheckedChanged: sectionOverlayExpanded = checked
    }

    QtControls2.CheckBox {
        id: showLoadingIndicatorCheckBox
        Kirigami.FormData.label: i18n("Indicatore Caricamento:")
        text: i18n("Mostra indicatore durante il caricamento immagini")
        visible: sectionOverlayExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Mostra un indicatore visivo mentre le immagini vengono caricate da Nextcloud\n\nUtile per sapere quando un'immagine è in caricamento, specialmente con connessioni lente")
    }

    QtControls2.CheckBox {
        id: showExifInfoCheckBox
        Kirigami.FormData.label: i18n("Informazioni EXIF:")
        text: i18n("Mostra overlay informazioni EXIF (OSD)")
        visible: sectionOverlayExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Mostra metadati EXIF (data, fotocamera, ISO, apertura, tempo esposizione, ecc.) come overlay quando cambiano le immagini\n\nLe informazioni vengono estratte automaticamente dalle foto che contengono dati EXIF")
    }

    QtControls2.TextField {
        id: exifInfoDurationField
        Kirigami.FormData.label: i18n("Durata Info EXIF (secondi):")
        placeholderText: i18n("5")
        visible: sectionOverlayExpanded && showExifInfoCheckBox.checked
        validator: IntValidator {
            bottom: 0
            top: 30
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Quanto tempo mostrare le informazioni EXIF\n\nRange: 0-30 secondi\n• 0 = sempre visibile (non scompare mai)\n• 1-30 = scompare automaticamente dopo N secondi\n\nConsigliato: 5-10 secondi per avere tempo di leggere senza essere invadente")
    }

    QtControls2.CheckBox {
        id: showLocationOsdCheckBox
        Kirigami.FormData.label: i18n("Overlay Posizione:")
        text: i18n("Mostra overlay posizione permanente")
        visible: sectionOverlayExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Mostra la posizione (città, paese) come overlay permanente con font script\n\nLa posizione viene determinata automaticamente dalle coordinate GPS nelle foto (se presenti) usando reverse geocoding")
    }

    QtControls2.TextField {
        id: locationOsdFontSizeField
        Kirigami.FormData.label: i18n("Dimensione Font Posizione (px):")
        placeholderText: i18n("24")
        visible: sectionOverlayExpanded && showLocationOsdCheckBox.checked
        validator: IntValidator {
            bottom: 12
            top: 72
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Dimensione del font per l'overlay di posizione\n\nRange: 12-72 pixel\n• 12-24px = piccolo, discreto\n• 24-48px = medio, ben visibile (consigliato)\n• 48-72px = grande, molto visibile\n\nAdatta in base alla risoluzione del tuo schermo")
    }

    QtControls2.ComboBox {
        id: locationOsdPositionComboBox
        Kirigami.FormData.label: i18n("Posizione Overlay:")
        visible: sectionOverlayExpanded && showLocationOsdCheckBox.checked
        model: [
            i18n("Alto-Sinistra"),
            i18n("Alto-Destra"),
            i18n("Basso-Sinistra"),
            i18n("Basso-Destra"),
            i18n("Alto-Centro"),
            i18n("Basso-Centro")
        ]
        currentIndex: wallpaper.configuration.LocationOsdPosition || 1
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Posizione dell'overlay di posizione sullo schermo\n\nScegli la posizione dove vuoi che appaia l'overlay. Puoi regolare ulteriormente la posizione con gli offset X e Y sotto")
    }

    QtControls2.TextField {
        id: locationOsdXOffsetField
        Kirigami.FormData.label: i18n("Offset X Posizione (px):")
        placeholderText: i18n("20")
        visible: sectionOverlayExpanded && showLocationOsdCheckBox.checked
        validator: IntValidator {
            bottom: -200
            top: 200
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Offset orizzontale dalla posizione selezionata\n\nRange: -200 a +200 pixel\n• Valori negativi = sposta a sinistra\n• Valori positivi = sposta a destra\n• 0 = usa la posizione esatta selezionata\n\nUtile per regolare finemente la posizione dell'overlay")
    }

    QtControls2.TextField {
        id: locationOsdYOffsetField
        Kirigami.FormData.label: i18n("Offset Y Posizione (px):")
        placeholderText: i18n("20")
        visible: sectionOverlayExpanded && showLocationOsdCheckBox.checked
        validator: IntValidator {
            bottom: -200
            top: 200
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Offset verticale dalla posizione selezionata\n\nRange: -200 a +200 pixel\n• Valori negativi = sposta in alto\n• Valori positivi = sposta in basso\n• 0 = usa la posizione esatta selezionata\n\nUtile per regolare finemente la posizione dell'overlay")
    }

    QtControls2.ComboBox {
        id: locationOsdFontFamilyComboBox
        Kirigami.FormData.label: i18n("Famiglia Font Posizione:")
        visible: sectionOverlayExpanded && showLocationOsdCheckBox.checked
        editable: true
        
        // Static list with common script fonts - user can type custom ones
        model: [
            "System Default",
            "Dancing Script",
            "Pacifico",
            "Brush Script MT",
            "Lucida Handwriting",
            "Comic Sans MS",
            "Kalam",
            "Satisfy",
            "Great Vibes",
            "Allura",
            "Lobster",
            "Amatic SC",
            "Nanum Brush Script",
            "Nanum Pen Script"
        ]
        
        // Simple initialization - default to System Default
        currentIndex: 0
        
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Seleziona un font script/corsivo per l'overlay di posizione\n\nPuoi scegliere tra i font predefiniti o digitare il nome di un font personalizzato installato sul sistema.\nScegli 'System Default' per usare il font di sistema.\n\nI font script danno un aspetto più elegante e decorativo all'overlay")
    }

    QtControls2.CheckBox {
        id: showMethodIndicatorCheckBox
        Kirigami.FormData.label: i18n("Indicatore Metodo:")
        text: i18n("Mostra indicatore metodo elaborazione (QML/C++)")
        visible: sectionOverlayExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Mostra un badge nell'angolo superiore destro che indica se l'immagine corrente è processata con QML (Data URLs) o C++ (file temporanei)\n\n• Badge BLU = QML (modalità standard, usa Data URLs)\n• Badge VERDE = C++ (modalità ottimizzata, usa file temporanei, ~30% meno memoria)\n\nUtile per verificare quale metodo viene utilizzato")
    }

    QtControls2.TextField {
        id: methodIndicatorDurationField
        Kirigami.FormData.label: i18n("Durata Indicatore (secondi):")
        placeholderText: i18n("3")
        visible: sectionOverlayExpanded && showMethodIndicatorCheckBox.checked
        validator: IntValidator {
            bottom: 0
            top: 30
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Quanto tempo mostrare l'indicatore del metodo dopo il caricamento di un'immagine\n\nRange: 0-30 secondi\n• 0 = sempre visibile (non scompare mai)\n• 1-30 = scompare automaticamente dopo N secondi\n\nConsigliato: 3-5 secondi per vedere rapidamente il metodo usato")
    }

    QtControls2.CheckBox {
        id: qmlDataUrlFallbackCheckBox
        Kirigami.FormData.label: i18n("Fallback QML:")
        text: i18n("Allow Data URL download when C++ downloader is missing or fails")
        visible: sectionOverlayExpanded
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("When checked, the wallpaper can load images via QML (in-memory Data URLs) if the optional C++ module is not installed or a download error occurs.\n\nUncheck to use only the C++ file-based pipeline: slides are skipped until the C++ module works. Reduces memory use and avoids the slower path, but requires the C++ plugin (see README / install.sh).")
    }
}
