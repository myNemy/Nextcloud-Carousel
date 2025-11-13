/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

WallpaperItem {
    id: root

    Component.onCompleted: {
        root.loading = true
        carouselController.initialize()
    }

    // Carousel controller
    QtObject {
        id: carouselController
        
        property var photoList: []
        property var usedIndices: []  // Track recently used indices to avoid repeats
        property int currentIndex: 0
        property bool initialized: false
        property int lastIndex: -1  // Track last shown index
        
        function initialize() {
            if (root.configuration.NextcloudUrl === "" || 
                root.configuration.Username === "") {
                console.warn("Nextcloud URL or Username not configured")
                root.loading = false
                return
            }
            loadPhotos()
        }
        
        function loadPhotos() {
            console.log("Loading photos from Nextcloud:", root.configuration.NextcloudUrl)
            
            var baseUrl = root.configuration.NextcloudUrl
            if (baseUrl.endsWith("/")) {
                baseUrl = baseUrl.slice(0, -1)
            }
            
            var username = root.configuration.Username
            var password = root.configuration.Password
            var photoPath = root.configuration.PhotoPath || "/Photos"
            
            if (!photoPath.startsWith("/")) {
                photoPath = "/" + photoPath
            }
            
            // Nextcloud WebDAV endpoint
            var webdavUrl = baseUrl + "/remote.php/dav/files/" + encodeURIComponent(username) + photoPath
            
            console.log("WebDAV URL:", webdavUrl)
            
            // Create PROPFIND request to list files (including subfolders)
            var xhr = new XMLHttpRequest()
            xhr.open("PROPFIND", webdavUrl, true, username, password)
            xhr.setRequestHeader("Depth", "infinity")  // Read all subfolders recursively
            xhr.setRequestHeader("Content-Type", "application/xml")
            
            var propfindBody = '<?xml version="1.0"?>' +
                '<d:propfind xmlns:d="DAV:">' +
                '<d:prop><d:getcontenttype/></d:prop>' +
                '</d:propfind>'
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 207 || xhr.status === 200) {
                        // Parse XML response using regex (DOMParser might not be available)
                        var xmlText = xhr.responseText
                        var images = []
                        
                        // Extract all href elements using regex
                        var hrefRegex = /<d:href>([^<]+)<\/d:href>/g
                        var match
                        var paths = []
                        
                        while ((match = hrefRegex.exec(xmlText)) !== null) {
                            var filePath = decodeURIComponent(match[1])
                            paths.push(filePath)
                        }
                        
                        // Process each path
                        for (var i = 0; i < paths.length; i++) {
                            var filePath = paths[i]
                            
                            // Skip the directory itself
                            if (filePath.endsWith(photoPath) || filePath.endsWith(photoPath + "/")) {
                                continue
                            }
                            
                            // Extract filename
                            var fileName = filePath.split("/").pop()
                            
                            // Skip if no filename (directory)
                            if (!fileName || fileName === "") {
                                continue
                            }
                            
                            // Check if it's an image file
                            var ext = fileName.split(".").pop().toLowerCase()
                            var imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "tiff", "tif"]
                            
                            if (imageExtensions.indexOf(ext) !== -1) {
                                // Build direct download URL
                                // Remove the base WebDAV path and rebuild
                                var relativePath = filePath
                                if (filePath.indexOf("/remote.php/dav/files/") !== -1) {
                                    relativePath = filePath.split("/remote.php/dav/files/" + encodeURIComponent(username))[1]
                                }
                                
                                var imageUrl = baseUrl + "/remote.php/dav/files/" + 
                                              encodeURIComponent(username) + relativePath
                                
                                // Store URL with auth info for later download
                                // We'll download with XHR and convert to data URL
                                var authUrl = imageUrl.replace("https://", "https://" + 
                                                               encodeURIComponent(username) + ":" + 
                                                               encodeURIComponent(password) + "@")
                                
                                images.push(authUrl)
                            }
                        }
                        
                        console.log("Found", images.length, "images")
                        if (images.length > 0) {
                            console.log("First image URL:", images[0].replace(/https?:\/\/[^@]+@/, ""))
                            console.log("Sample paths found:", paths.slice(0, 3))
                        } else {
                            console.warn("No images found! XML response preview:", xmlText.substring(0, 500))
                            console.warn("Paths extracted:", paths)
                        }
                        photoList = images
                        
                        if (photoList.length > 0) {
                            // Handle different order modes
                            var orderMode = root.configuration.RandomOrder || 0
                            
                            if (orderMode === 1 || orderMode === 2) {
                                // Random or Shuffle once: shuffle the list
                                for (var j = photoList.length - 1; j > 0; j--) {
                                    var k = Math.floor(Math.random() * (j + 1))
                                    var temp = photoList[j]
                                    photoList[j] = photoList[k]
                                    photoList[k] = temp
                                }
                                currentIndex = 0
                            } else if (orderMode === 3) {
                                // Smart random: start with random index
                                currentIndex = Math.floor(Math.random() * photoList.length)
                                usedIndices = [currentIndex]
                            } else {
                                // Sequential: start from beginning
                                currentIndex = 0
                            }
                            
                            lastIndex = -1
                            startCarousel()
                            updateCurrentImage()
                        } else {
                            console.warn("No images found in", photoPath)
                            root.loading = false
                        }
                    } else {
                        console.error("Failed to load photos. Status:", xhr.status, xhr.statusText)
                        console.error("Response preview:", xhr.responseText.substring(0, 500))
                        if (xhr.status === 401) {
                            console.error("Authentication failed - check username and password")
                        } else if (xhr.status === 404) {
                            console.error("Path not found - check Photo Path setting")
                        } else if (xhr.status === 0) {
                            console.error("Network error or CORS issue")
                        }
                        root.loading = false
                    }
                }
            }
            
            xhr.send(propfindBody)
        }
        
        function startCarousel() {
            if (photoList.length === 0) return
            
            initialized = true
            root.loading = false
            
            // Start timer for carousel
            carouselTimer.restart()
        }
        
        function nextPhoto() {
            if (photoList.length === 0) return
            
            var orderMode = root.configuration.RandomOrder || 0
            
            if (orderMode === 0) {
                // Sequential: next in order
                currentIndex = (currentIndex + 1) % photoList.length
            } else if (orderMode === 1) {
                // Random: completely random each time
                var newIndex
                do {
                    newIndex = Math.floor(Math.random() * photoList.length)
                } while (newIndex === lastIndex && photoList.length > 1)
                currentIndex = newIndex
                lastIndex = newIndex
            } else if (orderMode === 2) {
                // Shuffle once: sequential through shuffled list
                currentIndex = (currentIndex + 1) % photoList.length
            } else if (orderMode === 3) {
                // Smart random: avoid showing same image consecutively
                // Keep track of recently used indices
                var availableIndices = []
                for (var i = 0; i < photoList.length; i++) {
                    if (i !== lastIndex) {
                        availableIndices.push(i)
                    }
                }
                
                if (availableIndices.length === 0) {
                    // Fallback if only one image
                    availableIndices = [0]
                }
                
                // Pick random from available
                var randomPos = Math.floor(Math.random() * availableIndices.length)
                currentIndex = availableIndices[randomPos]
                lastIndex = currentIndex
                
                // Track used indices (keep last 5)
                usedIndices.push(currentIndex)
                if (usedIndices.length > 5) {
                    usedIndices.shift()
                }
            }
            
            updateCurrentImage()
        }
        
        function updateCurrentImage() {
            if (currentIndex >= 0 && currentIndex < photoList.length) {
                var photoUrl = photoList[currentIndex]
                console.log("Loading image", currentIndex + 1, "of", photoList.length)
                console.log("Image URL (without auth):", photoUrl.replace(/https?:\/\/[^@]+@/, ""))
                
                // Image component doesn't support auth in URL, so we need to download it
                loadImageWithAuth(photoUrl)
            }
        }
        
        function arrayBufferToBase64(buffer) {
            // Manual base64 encoding (btoa might not be available in QML)
            var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            var bytes = new Uint8Array(buffer)
            var len = bytes.length
            var base64 = ''
            
            for (var i = 0; i < len; i += 3) {
                base64 += chars[bytes[i] >> 2]
                base64 += chars[((bytes[i] & 3) << 4) | (bytes[i + 1] >> 4)]
                base64 += chars[((bytes[i + 1] & 15) << 2) | (bytes[i + 2] >> 6)]
                base64 += chars[bytes[i + 2] & 63]
            }
            
            if ((len % 3) === 2) {
                base64 = base64.substring(0, base64.length - 1) + '='
            } else if (len % 3 === 1) {
                base64 = base64.substring(0, base64.length - 2) + '=='
            }
            
            return base64
        }
        
        function loadImageWithAuth(imageUrl) {
            root.loading = true
            
            // Extract URL without auth for the request
            var cleanUrl = imageUrl
            if (imageUrl.indexOf("@") !== -1) {
                var parts = imageUrl.split("@")
                if (parts.length > 1) {
                    cleanUrl = imageUrl.split("@")[1]
                    if (!cleanUrl.startsWith("http")) {
                        cleanUrl = "https://" + cleanUrl
                    }
                }
            }
            
            var username = root.configuration.Username
            var password = root.configuration.Password
            
            console.log("Downloading image from:", cleanUrl)
            
            var xhr = new XMLHttpRequest()
            xhr.open("GET", cleanUrl, true, username, password)
            xhr.responseType = "arraybuffer"
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    console.log("XHR response status:", xhr.status)
                    if (xhr.status === 200) {
                        console.log("Image downloaded, size:", xhr.response.byteLength, "bytes")
                        
                        // Convert arraybuffer to base64 data URL
                        // btoa() might not be available, use manual base64 encoding
                        var bytes = new Uint8Array(xhr.response)
                        var base64 = arrayBufferToBase64(bytes)
                        
                        // Determine MIME type from URL
                        var mimeType = "image/jpeg"
                        if (cleanUrl.toLowerCase().indexOf(".png") !== -1) {
                            mimeType = "image/png"
                        } else if (cleanUrl.toLowerCase().indexOf(".gif") !== -1) {
                            mimeType = "image/gif"
                        } else if (cleanUrl.toLowerCase().indexOf(".webp") !== -1) {
                            mimeType = "image/webp"
                        } else if (cleanUrl.toLowerCase().indexOf(".svg") !== -1) {
                            mimeType = "image/svg+xml"
                        }
                        
                        var dataUrl = "data:" + mimeType + ";base64," + base64
                        console.log("Image converted to data URL, MIME type:", mimeType)
                        console.log("Setting image source (data URL length:", dataUrl.length, ")")
                        imageView.source = dataUrl
                    } else {
                        console.error("Failed to load image. Status:", xhr.status, xhr.statusText)
                        if (xhr.status === 401) {
                            console.error("Authentication failed - check username and password")
                        } else if (xhr.status === 404) {
                            console.error("Image not found - check URL path")
                        }
                        root.loading = false
                    }
                }
            }
            
            xhr.onerror = function() {
                console.error("Error loading image:", cleanUrl)
                root.loading = false
            }
            
            xhr.send()
        }
    }
    
    Timer {
        id: carouselTimer
        interval: root.configuration.SlideInterval * 1000
        running: carouselController.initialized && carouselController.photoList.length > 0
        repeat: true
        onTriggered: carouselController.nextPhoto()
    }

    // Main image view with carousel transitions
    Item {
        id: imageContainer
        anchors.fill: parent
        
        // Background color
        Rectangle {
            anchors.fill: parent
            color: root.configuration.Color
        }
        
        // Image stack for smooth transitions
        QQC2.StackView {
            id: imageStack
            anchors.fill: parent
            
            property int transitionDuration: root.configuration.TransitionDuration
            
            pushEnter: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: imageStack.transitionDuration
                }
            }
            
            pushExit: Transition {
                PropertyAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: imageStack.transitionDuration
                }
            }
        }
        
        // Current image display
        Image {
            id: imageView
            anchors.fill: parent
            fillMode: {
                switch (root.configuration.FillMode) {
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
            scale: root.configuration.ImageScale / 100.0
            transformOrigin: Item.Center
            asynchronous: true
            cache: true
            smooth: true
            
            // Blur effect - simplified for now
            // Note: Full blur effect would require additional QML components
            // Using opacity reduction as simplified blur effect
            // BlurOpacity is 0-100, convert to 0.0-1.0
            opacity: root.configuration.Blur ? (root.configuration.BlurOpacity / 100.0) : 1.0
            
            // Fade transition
            Behavior on opacity {
                NumberAnimation {
                    duration: root.configuration.TransitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
            
            onStatusChanged: {
                if (status === Image.Ready) {
                    root.loading = false
                } else if (status === Image.Error) {
                    console.warn("Failed to load image:", source)
                    root.loading = false
                }
            }
        }
        
        // Loading indicator
        Kirigami.LoadingPlaceholder {
            anchors.centerIn: parent
            visible: root.loading
        }
    }
    
    // Update image when configuration changes
    Connections {
        target: root.configuration
        function onNextcloudUrlChanged() { carouselController.initialize() }
        function onUsernameChanged() { carouselController.initialize() }
        function onPasswordChanged() { carouselController.initialize() }
        function onPhotoPathChanged() { carouselController.initialize() }
        function onSlideIntervalChanged() { 
            carouselTimer.interval = root.configuration.SlideInterval * 1000
        }
        function onBlurChanged() {
            console.log("Blur setting changed:", root.configuration.Blur)
            // Force opacity update
            imageView.opacity = root.configuration.Blur ? (root.configuration.BlurOpacity / 100.0) : 1.0
        }
        function onBlurOpacityChanged() {
            console.log("Blur opacity changed:", root.configuration.BlurOpacity, "%")
            // Force opacity update if blur is enabled
            if (root.configuration.Blur) {
                imageView.opacity = root.configuration.BlurOpacity / 100.0
            }
        }
        function onFillModeChanged() {
            console.log("FillMode changed:", root.configuration.FillMode)
        }
        function onImageScaleChanged() {
            console.log("Image scale changed:", root.configuration.ImageScale, "%")
            // Force scale update
            imageView.scale = root.configuration.ImageScale / 100.0
        }
    }
}

