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
    property alias cfg_Color: colorButton.color
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

    KQuickControls.ColorButton {
        id: colorButton
        Kirigami.FormData.label: i18n("Background Color:")
        dialogTitle: i18n("Select Background Color")
    }
}
