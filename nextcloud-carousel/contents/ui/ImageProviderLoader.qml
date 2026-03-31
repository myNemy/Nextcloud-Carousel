/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: AGPL-3.0-or-later
    
    This component tests if image://nextcloud/ URLs work.
    If they do, the C++ ImageProvider plugin was auto-loaded by Qt.
    This is safe - no import that can fail.
*/

import QtQuick

QtObject {
    // Test if image://nextcloud/ provider exists
    // This works if the plugin was auto-loaded, even without QML import
    property bool providerAvailable: false
    property var testImage: null
    
    Component.onCompleted: {
        // Create a test Image to check if image://nextcloud/ URLs work
        // This is safe - if provider doesn't exist, Image will just error
        testImage = Qt.createQmlObject('import QtQuick 2.0; Image { source: "image://nextcloud/test"; visible: false; asynchronous: true }', parent, "TestImageProvider")
        
        if (testImage) {
            testImage.statusChanged.connect(function() {
                // If status is Ready or Loading, provider exists
                // If status is Error, provider might not exist (or image doesn't exist)
                // We can't distinguish, so we'll be conservative
                if (testImage.status === Image.Ready || testImage.status === Image.Loading) {
                    providerAvailable = true
                } else {
                    providerAvailable = false
                }
                // Cleanup
                Qt.callLater(function() {
                    if (testImage) {
                        testImage.destroy()
                        testImage = null
                    }
                })
            })
        } else {
            providerAvailable = false
        }
    }
}

