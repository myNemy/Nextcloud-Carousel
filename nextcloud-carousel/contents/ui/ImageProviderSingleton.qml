/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
    
    This component loads the ImageProvider singleton dynamically.
    It imports the module directly - if module is not available, Loader will fail gracefully.
*/

import QtQuick 2.0
// Import via relative path under contents/ui/ (see NextcloudDownloaderSingleton.qml for rationale).
import "org/nextcloud/carousel"

QtObject {
    property var provider: ImageProvider
    
    Component.onCompleted: {
        console.log("✅ ImageProviderSingleton component loaded")
        console.log("🔍 Provider:", provider)
        console.log("🔍 Provider type:", typeof provider)
        if (provider) {
            console.log("✅✅✅ ImageProvider singleton available:", provider)
        } else {
            console.warn("⚠️  ImageProvider is null")
        }
    }
}
