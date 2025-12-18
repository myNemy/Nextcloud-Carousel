/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2

/**
 * Image component for StackView transitions
 * Based on KDE's StaticImageComponent pattern
 */
Item {
    id: imageComponent
    
    // Note: Do NOT use anchors.fill here - StackView manages anchors automatically
    // Using anchors here causes "conflicting anchors" error
    // StackView will set width/height automatically when item is added
    // Use parent dimensions as fallback (parent is the StackView when item is added)
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    
    // Initial position for Slide transition (will be animated by StackView transition)
    // Default to 0 (normal position), will be set by transition if needed
    x: 0
    y: 0
    
    // Initial scale for Zoom transition (will be animated by StackView transition)
    // Default to 1.0 (normal scale), will be set by transition if needed
    scale: 1.0
    transformOrigin: Item.Center
    
    // Required properties (set when creating component)
    required property url source
    required property int fillMode
    required property color color
    required property bool blur
    required property real blurOpacity
    required property real imageScale
    required property real orientation  // EXIF orientation rotation angle in degrees (0, 90, -90, 180)
    
    // Expose image status for loading detection
    // Note: statusChanged signal is automatically available via property alias
    readonly property alias status: mainImage.status
    readonly property alias sourceSize: mainImage.sourceSize
    
    // Background color
    Rectangle {
        anchors.fill: parent
        color: imageComponent.color
        z: -1
    }
    
    // Main image
    Image {
        id: mainImage
        anchors.fill: parent
        source: imageComponent.source
        visible: true
        fillMode: {
            switch (imageComponent.fillMode) {
            case 0: return Image.Stretch
            case 1: return Image.PreserveAspectFit
            case 2: return Image.PreserveAspectCrop
            case 3: return Image.Tile
            case 4: return Image.TileVertically
            case 5: return Image.TileHorizontally
            default: return Image.PreserveAspectCrop
            }
        }
        scale: imageComponent.imageScale / 100.0
        rotation: imageComponent.orientation  // Apply EXIF orientation rotation
        transformOrigin: Item.Center
        
        Component.onCompleted: {
            if (imageComponent.orientation !== 0) {
                console.log("ImageComponent: Applying rotation", imageComponent.orientation, "degrees to image")
            }
        }
        asynchronous: true
        // CRITICAL: data: URLs + Image cache cause unbounded memory growth.
        // With a slideshow of thousands of images, Qt's image cache can retain many decoded frames.
        // Disable it to avoid plasmashell being OOM-killed over time.
        cache: false
        smooth: true
        
        // Blur effect (simplified - using opacity)
        opacity: imageComponent.blur ? (imageComponent.blurOpacity / 100.0) : 1.0
    }
}

