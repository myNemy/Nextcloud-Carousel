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
    property alias cfg_TransitionDuration: transitionDurationField.text
    property alias cfg_TransitionEnabled: transitionEnabledCheckBox.checked
    property alias cfg_TransitionRandom: transitionRandomCheckBox.checked
    property alias cfg_TransitionType: transitionTypeComboBox.currentIndex
    property alias cfg_RandomOrder: randomOrderComboBox.currentIndex
    property alias cfg_Blur: blurCheckBox.checked
    property alias cfg_BlurOpacity: blurOpacitySlider.value
    property alias cfg_FillMode: fillModeComboBox.currentIndex
    property alias cfg_ImageScale: imageScaleSlider.value
    property alias cfg_Color: colorButton.color
    property alias cfg_ShowLoadingIndicator: showLoadingIndicatorCheckBox.checked
    property alias formLayout: root

    QtControls2.TextField {
        id: nextcloudUrlField
        Kirigami.FormData.label: i18n("Nextcloud URL:")
        placeholderText: i18n("https://nextcloud.example.com")
    }

    QtControls2.TextField {
        id: usernameField
        Kirigami.FormData.label: i18n("Username:")
        placeholderText: i18n("Your Nextcloud username")
    }

    QtControls2.TextField {
        id: passwordField
        Kirigami.FormData.label: i18n("Password:")
        placeholderText: i18n("Password or app password")
        echoMode: QtControls2.TextField.Password
    }

    QtControls2.TextField {
        id: photoPathField
        Kirigami.FormData.label: i18n("Photo Path:")
        placeholderText: i18n("/Photos")
    }

    QtControls2.TextField {
        id: slideIntervalField
        Kirigami.FormData.label: i18n("Slide Interval (seconds):")
        placeholderText: i18n("10")
    }

    QtControls2.TextField {
        id: transitionDurationField
        Kirigami.FormData.label: i18n("Transition Duration (ms):")
        placeholderText: i18n("1000")
        validator: IntValidator {
            bottom: 100
            top: 10000
        }
    }

    QtControls2.CheckBox {
        id: transitionEnabledCheckBox
        Kirigami.FormData.label: i18n("Transitions:")
        text: i18n("Enable transitions between images")
    }

    QtControls2.CheckBox {
        id: transitionRandomCheckBox
        Kirigami.FormData.label: i18n("")
        text: i18n("Randomize transition type")
        enabled: transitionEnabledCheckBox.checked
    }

    QtControls2.ComboBox {
        id: transitionTypeComboBox
        Kirigami.FormData.label: i18n("Transition Type:")
        model: [
            i18n("Fade"),
            i18n("Slide"),
            i18n("Zoom")
        ]
        currentIndex: wallpaper.configuration.TransitionType || 0
        enabled: transitionEnabledCheckBox.checked && !transitionRandomCheckBox.checked
    }

    QtControls2.ComboBox {
        id: randomOrderComboBox
        Kirigami.FormData.label: i18n("Order Mode:")
        model: [
            i18n("Sequential"),
            i18n("Random (each time)"),
            i18n("Shuffle Once"),
            i18n("Smart Random (avoid repeats)")
        ]
        currentIndex: wallpaper.configuration.RandomOrder || 0
    }

    QtControls2.CheckBox {
        id: blurCheckBox
        Kirigami.FormData.label: i18n("Blur background:")
        text: i18n("Apply blur effect to images")
    }

    Item {
        Kirigami.FormData.label: i18n("Blur opacity (%):")
        Kirigami.FormData.buddyFor: blurOpacitySlider
        implicitHeight: blurOpacitySlider.implicitHeight
        enabled: blurCheckBox.checked
        
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
            }
            
            QtControls2.Label {
                text: Math.round(blurOpacitySlider.value) + " %"
                width: 50
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    QtControls2.ComboBox {
        id: fillModeComboBox
        Kirigami.FormData.label: i18n("Fill Mode:")
        model: [
            i18n("Stretch"),
            i18n("Fit (Preserve Aspect)"),
            i18n("Crop (Preserve Aspect)"),
            i18n("Tile"),
            i18n("Tile Vertically"),
            i18n("Tile Horizontally")
        ]
        currentIndex: wallpaper.configuration.FillMode || 2
    }

    Item {
        Kirigami.FormData.label: i18n("Image Scale (%):")
        Kirigami.FormData.buddyFor: imageScaleSlider
        implicitHeight: imageScaleSlider.implicitHeight
        
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
        Kirigami.FormData.label: i18n("Background Color:")
        dialogTitle: i18n("Select Background Color")
    }

    QtControls2.CheckBox {
        id: showLoadingIndicatorCheckBox
        Kirigami.FormData.label: i18n("Loading Indicator:")
        text: i18n("Show loading indicator when loading images")
    }

    // Information Section
    Kirigami.Separator {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing
    }

    Item {
        Kirigami.FormData.label: i18n("About:")
        Kirigami.FormData.isSection: true
        
        Column {
            spacing: Kirigami.Units.smallSpacing
            width: parent.width
            
            QtControls2.Label {
                text: i18n("Nextcloud Carousel")
                font.bold: true
                font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize * 1.1
            }
            
            QtControls2.Label {
                text: i18n("Version: 1.0")
                font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            
            QtControls2.Label {
                text: i18n("Carousel wallpaper plugin for displaying photos from Nextcloud")
                wrapMode: Text.WordWrap
                width: parent.width
                font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize * 0.9
            }
            
            QtControls2.Label {
                text: i18n("License: GPL-2.0-or-later")
                font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
            
            QtControls2.Label {
                text: i18n("Author: Nextcloud Carousel Developer")
                font.pixelSize: Kirigami.Units.fontMetrics.font.pixelSize * 0.9
                color: Kirigami.Theme.disabledTextColor
            }
        }
    }
}
