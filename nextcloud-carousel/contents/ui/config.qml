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
    property alias cfg_ShowExifInfo: showExifInfoCheckBox.checked
    property alias cfg_ExifInfoDuration: exifInfoDurationField.text
    property alias formLayout: root

    QtControls2.TextField {
        id: nextcloudUrlField
        Kirigami.FormData.label: i18n("Nextcloud URL:")
        placeholderText: i18n("https://nextcloud.example.com")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("URL of your Nextcloud server (e.g., https://nextcloud.example.com)")
    }

    QtControls2.TextField {
        id: usernameField
        Kirigami.FormData.label: i18n("Username:")
        placeholderText: i18n("Your Nextcloud username")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Your Nextcloud username for authentication")
    }

    QtControls2.TextField {
        id: passwordField
        Kirigami.FormData.label: i18n("Password:")
        placeholderText: i18n("Password or app password")
        echoMode: QtControls2.TextField.Password
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Your Nextcloud password or app password (recommended for security)")
    }

    QtControls2.TextField {
        id: photoPathField
        Kirigami.FormData.label: i18n("Photo Path:")
        placeholderText: i18n("/Photos")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Path to the photo folder on Nextcloud (searches in subfolders too)")
    }

    QtControls2.TextField {
        id: slideIntervalField
        Kirigami.FormData.label: i18n("Slide Interval (seconds):")
        placeholderText: i18n("10")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Time each image is displayed before switching to the next")
    }

    QtControls2.TextField {
        id: transitionDurationField
        Kirigami.FormData.label: i18n("Transition Duration (ms):")
        placeholderText: i18n("1000")
        validator: IntValidator {
            bottom: 100
            top: 10000
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Duration of the transition effect between images (in milliseconds)")
    }

    QtControls2.CheckBox {
        id: transitionEnabledCheckBox
        Kirigami.FormData.label: i18n("Transitions:")
        text: i18n("Enable transitions between images")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Enable smooth transition effects (fade, slide, zoom) when switching between images")
    }

    QtControls2.CheckBox {
        id: transitionRandomCheckBox
        Kirigami.FormData.label: i18n("")
        text: i18n("Randomize transition type")
        enabled: transitionEnabledCheckBox.checked
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Randomly select a different transition type for each image change")
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
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Type of transition: Fade (crossfade), Slide (horizontal movement), Zoom (scale effect)")
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
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Sequential: in order | Random: random each time | Shuffle: shuffle once | Smart: avoids recent repeats")
    }

    QtControls2.CheckBox {
        id: blurCheckBox
        Kirigami.FormData.label: i18n("Blur background:")
        text: i18n("Apply blur effect to images")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Apply a blur effect to the images for a softer, artistic appearance")
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
                QtControls2.ToolTip.delay: 1000
                QtControls2.ToolTip.visible: hovered
                QtControls2.ToolTip.text: i18n("Opacity of the blur effect (0% = no blur, 100% = maximum blur)")
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
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("How the image is displayed: Stretch fills screen, Fit preserves aspect, Crop fills without distortion, Tile repeats")
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
                QtControls2.ToolTip.delay: 1000
                QtControls2.ToolTip.visible: hovered
                QtControls2.ToolTip.text: i18n("Scale image size (50% = half size, 100% = normal, 200% = double)")
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
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Background color shown while loading or if image doesn't fill screen")
    }

    QtControls2.CheckBox {
        id: showLoadingIndicatorCheckBox
        Kirigami.FormData.label: i18n("Loading Indicator:")
        text: i18n("Show loading indicator when loading images")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Display a visual indicator while images are being loaded from Nextcloud")
    }

    QtControls2.CheckBox {
        id: showExifInfoCheckBox
        Kirigami.FormData.label: i18n("EXIF Information:")
        text: i18n("Show EXIF information overlay (OSD)")
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("Display EXIF metadata (date, camera, ISO, etc.) as an overlay when images change")
    }

    QtControls2.TextField {
        id: exifInfoDurationField
        Kirigami.FormData.label: i18n("EXIF Info Duration (seconds):")
        placeholderText: i18n("5")
        enabled: showExifInfoCheckBox.checked
        validator: IntValidator {
            bottom: 0
            top: 30
        }
        QtControls2.ToolTip.delay: 1000
        QtControls2.ToolTip.visible: hovered
        QtControls2.ToolTip.text: i18n("How long to show EXIF information (0 = always visible, 1-30 = auto-hide after N seconds)")
    }
}
