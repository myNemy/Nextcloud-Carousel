/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root
    
    required property url source
    required property int fillMode
    required property color color
    required property bool blur
    required property real blurOpacity
    required property real imageScale
    required property size sourceSize
    
    // Background color
    Rectangle {
        anchors.fill: parent
        color: root.color
        z: -1
    }
    
    // Main image
    Image {
        id: mainImage
        anchors.fill: parent
        source: root.source
        fillMode: {
            switch (root.fillMode) {
            case 0: return Image.Stretch
            case 1: return Image.PreserveAspectFit
            case 2: return Image.PreserveAspectCrop
            case 3: return Image.Tile
            case 4: return Image.TileVertically
            case 5: return Image.TileHorizontally
            default: return Image.PreserveAspectCrop
            }
        }
        // Image scale (zoom) - ImageScale is 50-200, convert to 0.5-2.0
        scale: root.imageScale / 100.0
        transformOrigin: Item.Center
        asynchronous: true
        cache: true
        smooth: true
        autoTransform: true
        
        // Blur effect - simplified (opacity reduction)
        // BlurOpacity is 0-100, convert to 0.0-1.0
        opacity: root.blur ? (root.blurOpacity / 100.0) : 1.0
        
        // For centered and tiled images
        sourceSize: fillMode === Image.Pad ? undefined : root.sourceSize
    }
    
    // Expose status for pendingImage pattern
    readonly property alias status: mainImage.status
}

