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
    property alias cfg_VideoPath: videoPathField.text
    property alias cfg_VideoInterval: videoIntervalField.text
    property alias cfg_RandomOrder: randomOrderComboBox.currentIndex
    property alias cfg_LoopVideo: loopVideoCheckBox.checked
    property alias cfg_MuteAudio: muteAudioCheckBox.checked
    property alias cfg_Color: colorButton.color
    property alias cfg_FillMode: fillModeComboBox.currentIndex
    property alias cfg_VideoScale: videoScaleSlider.value
    property alias formLayout: root

    // Nextcloud Connection
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
        id: videoPathField
        Kirigami.FormData.label: i18n("Video Path:")
        placeholderText: i18n("/Videos")
    }

    // Video Settings
    QtControls2.TextField {
        id: videoIntervalField
        Kirigami.FormData.label: i18n("Video Interval (seconds):")
        placeholderText: i18n("30")
        validator: IntValidator {
            bottom: 5
            top: 300
        }
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
        id: loopVideoCheckBox
        Kirigami.FormData.label: i18n("Loop Video:")
        text: i18n("Loop each video")
    }

    QtControls2.CheckBox {
        id: muteAudioCheckBox
        Kirigami.FormData.label: i18n("Mute Audio:")
        text: i18n("Mute video audio")
    }

    // Display Settings
    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("Background Color:")
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
        Kirigami.FormData.label: i18n("Video Scale (%):")
        Kirigami.FormData.buddyFor: videoScaleSlider
        
        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            
            QtControls2.Slider {
                id: videoScaleSlider
                from: 50
                to: 200
                stepSize: 5
                value: wallpaper.configuration.VideoScale || 100
            }
            
            QtControls2.Label {
                anchors.verticalCenter: videoScaleSlider.verticalCenter
                text: Math.round(videoScaleSlider.value) + "%"
                width: 50
            }
        }
    }
}

