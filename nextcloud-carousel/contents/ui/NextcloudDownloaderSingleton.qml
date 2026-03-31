/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: AGPL-3.0-or-later
    
    This component loads the NextcloudDownloader singleton dynamically.
    It imports the module directly - if module is not available, Loader will fail gracefully.
*/

import QtQuick 2.0
// Import the module via a relative path under contents/ui/.
// This avoids relying on distro-specific Qt import paths (e.g. /usr/lib/... vs /usr/lib/x86_64-linux-gnu/...),
// and works for both user installs and system installs of the wallpaper package.
// If the C++ module is not present, Loader will fail gracefully and we fall back in main.qml.
import "org/nextcloud/carousel"

QtObject {
    id: root
    property var downloader: null

    Component.onCompleted: {
        try {
            // Try to access the singleton directly via the imported module
            if (typeof NextcloudDownloader !== 'undefined') {
                root.downloader = NextcloudDownloader
                console.log("✅✅✅ NextcloudDownloaderSingleton: Downloader loaded successfully:", root.downloader)
            } else {
                console.warn("⚠️  NextcloudDownloaderSingleton: NextcloudDownloader is undefined after import")
            }
        } catch (e) {
            console.warn("⚠️  NextcloudDownloaderSingleton: Failed to load downloader (catch block):", e)
            root.downloader = null
        }
    }
}

