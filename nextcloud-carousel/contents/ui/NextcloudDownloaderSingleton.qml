/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
    
    This component loads the NextcloudDownloader singleton dynamically.
    It imports the module directly - if module is not available, Loader will fail gracefully.
*/

import QtQuick 2.0
// Direct import here is safe because this file is loaded by Loader,
// which handles errors gracefully without crashing plasmashell.
import org.nextcloud.carousel 1.0

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

