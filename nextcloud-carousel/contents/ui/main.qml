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
        
        // Read EXIF orientation from JPEG ArrayBuffer
        // Returns rotation angle in degrees (0, 90, -90, 180) or 0 if not found/error
        function readExifOrientation(arrayBuffer) {
            try {
                var bytes = new Uint8Array(arrayBuffer)
                console.log("readExifOrientation: Image size:", bytes.length, "bytes")
                
                // Check if it's a JPEG (starts with 0xFFD8)
                if (bytes.length < 2 || bytes[0] !== 0xFF || bytes[1] !== 0xD8) {
                    console.log("⚠️  Not a JPEG image (first bytes:", bytes[0], bytes[1], "), skipping EXIF orientation")
                    return 0  // Not a JPEG, assume normal orientation
                }
                console.log("✅ JPEG header found (0xFFD8)")
                
                // Search for APP1 marker (0xFFE1) which contains EXIF data
                var i = 2  // Start after SOI marker
                var app1Found = false
                while (i < bytes.length - 1) {
                    // Check for APP1 marker
                    if (bytes[i] === 0xFF && bytes[i + 1] === 0xE1) {
                        app1Found = true
                        console.log("✅ APP1 marker found at offset:", i)
                        // Found APP1 segment
                        var segmentLength = (bytes[i + 2] << 8) | bytes[i + 3]
                        var segmentStart = i + 4
                        console.log("  Segment length:", segmentLength, "Segment start:", segmentStart)
                        
                        // Check if it's an EXIF segment (starts with "Exif\0\0")
                        if (segmentStart + 6 <= bytes.length) {
                            var exifHeader = String.fromCharCode(
                                bytes[segmentStart],
                                bytes[segmentStart + 1],
                                bytes[segmentStart + 2],
                                bytes[segmentStart + 3],
                                bytes[segmentStart + 4],
                                bytes[segmentStart + 5]
                            )
                            console.log("  Header check:", exifHeader, "===", "Exif\0\0", "?", exifHeader === "Exif\0\0")
                            
                            if (exifHeader === "Exif\0\0") {
                                console.log("✅ EXIF segment found!")
                                // Found EXIF segment, now find Orientation tag (0x0112)
                                // EXIF structure: TIFF header (8 bytes) + IFD0
                                var tiffOffset = segmentStart + 6
                                
                                if (tiffOffset + 8 > bytes.length) break
                                
                                // Check byte order (0x4949 = Intel, 0x4D4D = Motorola)
                                var isIntel = (bytes[tiffOffset] === 0x49 && bytes[tiffOffset + 1] === 0x49)
                                
                                // Read IFD0 offset (offset 4 from TIFF start, 4 bytes)
                                var ifd0OffsetAddr = tiffOffset + 4
                                if (ifd0OffsetAddr + 4 > bytes.length) break
                                
                                var ifd0Offset
                                if (isIntel) {
                                    ifd0Offset = bytes[ifd0OffsetAddr] | (bytes[ifd0OffsetAddr + 1] << 8) | 
                                                 (bytes[ifd0OffsetAddr + 2] << 16) | (bytes[ifd0OffsetAddr + 3] << 24)
                                } else {
                                    ifd0Offset = (bytes[ifd0OffsetAddr] << 24) | (bytes[ifd0OffsetAddr + 1] << 16) | 
                                                 (bytes[ifd0OffsetAddr + 2] << 8) | bytes[ifd0OffsetAddr + 3]
                                }
                                
                                // IFD0 address is relative to TIFF start
                                var ifd0Addr = tiffOffset + ifd0Offset
                                
                                // Read number of IFD entries
                                if (ifd0Addr + 2 > bytes.length) break
                                
                                var numEntries
                                if (isIntel) {
                                    numEntries = bytes[ifd0Addr] | (bytes[ifd0Addr + 1] << 8)
                                } else {
                                    numEntries = (bytes[ifd0Addr] << 8) | bytes[ifd0Addr + 1]
                                }
                                
                                // Search for Orientation tag (0x0112) in IFD0
                                var entryOffset = ifd0Addr + 2
                                for (var e = 0; e < numEntries && entryOffset + 12 <= bytes.length; e++) {
                                    var tag
                                    if (isIntel) {
                                        tag = bytes[entryOffset] | (bytes[entryOffset + 1] << 8)
                                    } else {
                                        tag = (bytes[entryOffset] << 8) | bytes[entryOffset + 1]
                                    }
                                    
                                    // Orientation tag is 0x0112 (274)
                                    if (tag === 0x0112) {
                                        console.log("✅ Orientation tag (0x0112) found at entry", e)
                                        // Read orientation value (offset 8 from entry start)
                                        var valueOffset = entryOffset + 8
                                        var orientation
                                        if (isIntel) {
                                            orientation = bytes[valueOffset] | (bytes[valueOffset + 1] << 8)
                                        } else {
                                            orientation = (bytes[valueOffset] << 8) | bytes[valueOffset + 1]
                                        }
                                        console.log("  EXIF orientation value:", orientation, "(1=normal, 3=180°, 6=90°CW, 8=90°CCW)")
                                        
                                        // Convert EXIF orientation to rotation angle
                                        // EXIF orientation values:
                                        // 1 = Normal (0°)
                                        // 3 = Rotated 180° (needs 180° correction)
                                        // 6 = Rotated 90° clockwise (needs +90° counter-clockwise correction)
                                        // 8 = Rotated 90° counter-clockwise (needs -90° clockwise correction)
                                        // Note: In QML, positive rotation is counter-clockwise, negative is clockwise
                                        var rotationAngle
                                        switch (orientation) {
                                        case 1: 
                                            rotationAngle = 0
                                            console.log("  → Rotation: 0° (normal)")
                                            return rotationAngle
                                        case 3: 
                                            rotationAngle = 180
                                            console.log("  → Rotation: 180° (upside down)")
                                            return rotationAngle
                                        case 6: 
                                            // Image was rotated 90° clockwise, need to rotate 90° counter-clockwise to correct
                                            rotationAngle = 90
                                            console.log("  → Rotation: 90° (image was 90°CW, correcting with 90°CCW)")
                                            return rotationAngle
                                        case 8: 
                                            // Image was rotated 90° counter-clockwise, need to rotate 90° clockwise to correct
                                            rotationAngle = -90
                                            console.log("  → Rotation: -90° (image was 90°CCW, correcting with 90°CW)")
                                            return rotationAngle
                                        default: 
                                            console.log("  ⚠️  Unknown orientation value:", orientation, "→ assuming 0°")
                                            return 0    // Unknown, assume normal
                                        }
                                    }
                                    
                                    entryOffset += 12  // Each IFD entry is 12 bytes
                                }
                            }
                        }
                        
                        // Move to next segment
                        i += 2 + segmentLength
                    } else if (bytes[i] === 0xFF && (bytes[i + 1] & 0xF0) === 0xE0) {
                        // Other APP segment, skip it
                        var segLen = (bytes[i + 2] << 8) | bytes[i + 3]
                        i += 2 + segLen
                    } else if (bytes[i] === 0xFF && bytes[i + 1] === 0xDA) {
                        // Start of scan (SOS), no more segments
                        break
                    } else {
                        i++
                    }
                }
                
                // Orientation not found
                if (!app1Found) {
                    console.log("⚠️  APP1 marker not found in JPEG, no EXIF data")
                } else {
                    console.log("⚠️  EXIF segment found but Orientation tag (0x0112) not found in IFD0")
                }
                return 0  // Orientation not found, assume normal
            } catch (e) {
                console.warn("❌ Error reading EXIF orientation:", e)
                return 0  // On error, assume normal orientation
            }
        }
        
        function loadImageWithAuth(imageUrl, skipAnimation) {
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
                        
                        // Read EXIF orientation before converting to base64
                        var orientation = 0
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
                        
                        // Read EXIF orientation for JPEG images
                        if (mimeType === "image/jpeg") {
                            console.log("Reading EXIF orientation from JPEG image...")
                            orientation = readExifOrientation(xhr.response)
                            console.log("EXIF orientation result:", orientation, "degrees (0=normal, 90=rotate 90°, -90=rotate -90°, 180=rotate 180°)")
                            if (orientation !== 0) {
                                console.log("✅ EXIF orientation detected, rotation will be applied:", orientation, "degrees")
                            } else {
                                console.log("ℹ️  No EXIF orientation found or orientation is normal (0°)")
                            }
                        } else {
                            console.log("Not a JPEG image, skipping EXIF orientation (MIME type:", mimeType, ")")
                        }
                        
                        // Convert arraybuffer to base64 data URL
                        // btoa() might not be available, use manual base64 encoding
                        var bytes = new Uint8Array(xhr.response)
                        var base64 = arrayBufferToBase64(bytes)
                        
                        var dataUrl = "data:" + mimeType + ";base64," + base64
                        console.log("Image converted to data URL, MIME type:", mimeType)
                        console.log("Creating image component for StackView (data URL length:", dataUrl.length, ")")
                        
                        // Use StackView pattern (following KDE official implementation)
                        // Clean up any existing pending image
                        if (imageStack.pendingImage) {
                            imageStack.pendingImage.statusChanged.disconnect(imageStack.replaceWhenLoaded)
                            imageStack.pendingImage.destroy()
                            imageStack.pendingImage = null
                        }
                        
                        // Determine if we should skip animation (first image, explicit skip, or transitions disabled)
                        imageStack.doesSkipAnimation = (imageStack.currentItem === undefined) || !!skipAnimation || !root.configuration.TransitionEnabled
                        
                        // Determine transition type (random or fixed)
                        if (root.configuration.TransitionEnabled && root.configuration.TransitionRandom) {
                            // Randomize transition type (0=Fade, 1=Slide, 2=Zoom)
                            imageStack.transitionType = Math.floor(Math.random() * 3)
                            console.log("Random transition type selected:", imageStack.transitionType, "(0=Fade, 1=Slide, 2=Zoom)")
                        } else {
                            // Use fixed transition type from configuration
                            imageStack.transitionType = root.configuration.TransitionType || 0
                        }
                        
                        // Create image component in background (following KDE pattern)
                        var component = imageStack.imageComponent
                        console.log("Component status:", component ? component.status : "null")
                        if (component && component.status === Component.Ready) {
                            console.log("Creating image component with data URL")
                            console.log("StackView dimensions:", imageStack.width, "x", imageStack.height)
                            console.log("Transition enabled:", root.configuration.TransitionEnabled)
                            console.log("Transition random:", root.configuration.TransitionRandom)
                            console.log("Transition type:", imageStack.transitionType, "(0=Fade, 1=Slide, 2=Zoom)")
                            // Create with explicit dimensions to avoid size issues
                            // Set initial position/scale based on transition type
                            var initialX = (imageStack.transitionType === 1) ? imageStack.width : 0
                            var initialScale = (imageStack.transitionType === 2) ? 0.8 : 1.0
                            console.log("Creating ImageComponent with orientation:", orientation, "degrees")
                            imageStack.pendingImage = component.createObject(imageStack, {
                                "source": dataUrl,
                                "fillMode": root.configuration.FillMode,
                                "color": root.configuration.Color,
                                "blur": root.configuration.Blur,
                                "blurOpacity": root.configuration.BlurOpacity,
                                "imageScale": root.configuration.ImageScale,
                                "orientation": orientation,
                                "width": imageStack.width,
                                "height": imageStack.height,
                                "x": initialX,
                                "scale": initialScale
                            })
                            
                            if (imageStack.pendingImage) {
                                console.log("ImageComponent created with orientation property:", imageStack.pendingImage.orientation, "degrees")
                            }
                            
                            if (imageStack.pendingImage) {
                                console.log("Image component created:")
                                console.log("  - status:", imageStack.pendingImage.status, "Image.Ready =", Image.Ready)
                                console.log("  - dimensions:", imageStack.pendingImage.width, "x", imageStack.pendingImage.height)
                                console.log("  - visible:", imageStack.pendingImage.visible)
                                console.log("  - opacity:", imageStack.pendingImage.opacity)
                                // Connect to statusChanged to replace when loaded
                                // Note: statusChanged signal is automatically available via property alias
                                if (imageStack.pendingImage.statusChanged) {
                                    imageStack.pendingImage.statusChanged.connect(imageStack.replaceWhenLoaded)
                                    console.log("Connected to statusChanged signal")
                                } else {
                                    console.warn("statusChanged signal not available!")
                                }
                                // Try to replace immediately (will wait if still loading)
                                imageStack.replaceWhenLoaded()
                            } else {
                                console.error("Failed to create image component:", component ? component.errorString() : "component is null")
                                root.loading = false
                            }
                        } else {
                            console.error("Image component not ready. Status:", component ? component.status : "null", "Error:", component ? component.errorString() : "component is null")
                            // Fallback: try to create component on the fly
                            if (!component || component.status === Component.Error) {
                                console.log("Attempting to reload ImageComponent")
                                imageStack.imageComponent = Qt.createComponent("ImageComponent.qml", imageStack)
                            }
                            root.loading = false
                        }
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
        
        // Image stack for smooth transitions (following KDE official pattern)
        QQC2.StackView {
            id: imageStack
            anchors.fill: parent
            
            // Properties for transition configuration
            property int transitionDuration: root.configuration.TransitionDuration || 1000
            property int transitionType: 0  // Will be set based on TransitionRandom or TransitionType
            // Skip animation if transitions are disabled or if it's the first image
            property bool doesSkipAnimation: !root.configuration.TransitionEnabled || (currentItem === undefined)
            
            // Pending image (loaded in background before replacing)
            property Item pendingImage: null
            
            // Component for creating image items (lazy loading)
            property Component imageComponent: null
            
            Component.onCompleted: {
                console.log("StackView Component.onCompleted: loading ImageComponent")
                imageComponent = Qt.createComponent("ImageComponent.qml", imageStack)
                if (imageComponent.status === Component.Error) {
                    console.error("Failed to load ImageComponent:", imageComponent.errorString())
                } else if (imageComponent.status === Component.Ready) {
                    console.log("ImageComponent loaded successfully")
                } else {
                    console.log("ImageComponent loading, status:", imageComponent.status)
                    // Wait for component to be ready
                    imageComponent.statusChanged.connect(function() {
                        if (imageComponent.status === Component.Ready) {
                            console.log("ImageComponent ready after async load")
                        } else if (imageComponent.status === Component.Error) {
                            console.error("ImageComponent failed to load:", imageComponent.errorString())
                        }
                    })
                }
            }
            
            // Transition configuration based on TransitionType
            // Following KDE pattern with support for Fade, Slide, and Zoom transitions
            // Note: Cannot use conditional animations inside Transition
            // Solution: Set initial properties in ImageComponent based on transitionType, then animate all properties
            replaceEnter: Transition {
                id: replaceEnterTransition
                enabled: !imageStack.doesSkipAnimation
                
                // Parallel animation for combining multiple effects
                ParallelAnimation {
                    // Fade transition (always active for all types)
                    OpacityAnimator {
                        id: replaceEnterOpacityAnimator
                        from: 0
                        to: 1
                        duration: imageStack.transitionDuration
                    }
                    
                    // Slide transition (type 1) - horizontal slide in from right
                    // Animate x only if transition type is Slide (initial x set in ImageComponent)
                    PropertyAnimation {
                        property: "x"
                        from: imageStack.transitionType === 1 ? imageStack.width : 0
                        to: 0
                        duration: imageStack.transitionDuration
                    }
                    
                    // Zoom transition (type 2) - zoom in from 0.8 to 1.0
                    // Animate scale only if transition type is Zoom (initial scale set in ImageComponent)
                    PropertyAnimation {
                        property: "scale"
                        from: imageStack.transitionType === 2 ? 0.8 : 1.0
                        to: 1.0
                        duration: imageStack.transitionDuration
                    }
                }
            }
            
            // Keep old image until new one is fully visible (prevents background showing through)
            // Following KDE pattern: PauseAnimation keeps old image visible during enter transition
            replaceExit: Transition {
                // Parallel animation for exit effects
                ParallelAnimation {
                    // Pause to keep old image visible during enter transition
                    PauseAnimation {
                        // 100ms buffer to ensure smooth transition
                        duration: replaceEnterOpacityAnimator.duration + 100
                    }
                    
                    // Fade out old image (always active)
                    OpacityAnimator {
                        from: 1
                        to: 0
                        duration: imageStack.transitionDuration
                    }
                    
                    // Slide out (type 1) - horizontal slide out to left
                    PropertyAnimation {
                        property: "x"
                        from: 0
                        to: imageStack.transitionType === 1 ? -imageStack.width : 0
                        duration: imageStack.transitionDuration
                    }
                    
                    // Zoom out (type 2) - zoom out from 1.0 to 1.2
                    PropertyAnimation {
                        property: "scale"
                        from: 1.0
                        to: imageStack.transitionType === 2 ? 1.2 : 1.0
                        duration: imageStack.transitionDuration
                    }
                }
            }
            
            // Function to replace image when loaded (following KDE pattern)
            function replaceWhenLoaded() {
                if (!pendingImage) {
                    console.log("replaceWhenLoaded: no pendingImage")
                    return
                }
                
                console.log("replaceWhenLoaded: checking status, current status:", pendingImage.status)
                
                // Wait for image to finish loading
                if (pendingImage.status === Image.Loading) {
                    console.log("replaceWhenLoaded: image still loading, waiting...")
                    return
                }
                
                console.log("replaceWhenLoaded: image ready, replacing in StackView")
                
                // Disconnect statusChanged signal
                pendingImage.statusChanged.disconnect(replaceWhenLoaded)
                
                // Cleanup old image when removed (memory management)
                // Store reference to avoid null errors
                var imageToCleanup = pendingImage
                imageToCleanup.QQC2.StackView.onDeactivated.connect(function() {
                    console.log("Image deactivated, destroying")
                    if (imageToCleanup) {
                        imageToCleanup.destroy()
                    }
                })
                imageToCleanup.QQC2.StackView.onRemoved.connect(function() {
                    console.log("Image removed, destroying")
                    if (imageToCleanup) {
                        imageToCleanup.destroy()
                    }
                })
                
                // Replace with transition
                console.log("Calling imageStack.replace() with pendingImage")
                var result = imageStack.replace(pendingImage, {}, QQC2.StackView.Transition)
                console.log("replace() result:", result)
                console.log("StackView currentItem:", imageStack.currentItem)
                console.log("StackView depth:", imageStack.depth)
                
                root.loading = false
                
                // Handle errors
                if (pendingImage.status !== Image.Ready) {
                    console.warn("Image failed to load, status:", pendingImage.status)
                } else {
                    console.log("Image successfully replaced in StackView")
                    console.log("Current item source:", imageStack.currentItem ? imageStack.currentItem.source : "null")
                }
                
                var tempPending = pendingImage
                pendingImage = null
                
                // Verify the item is actually in the StackView
                Qt.callLater(function() {
                    if (imageStack.currentItem) {
                        console.log("StackView currentItem verified:")
                        console.log("  - visible:", imageStack.currentItem.visible)
                        console.log("  - opacity:", imageStack.currentItem.opacity)
                        console.log("  - width:", imageStack.currentItem.width, "height:", imageStack.currentItem.height)
                        console.log("  - source:", imageStack.currentItem.source)
                        console.log("  - image status:", imageStack.currentItem.status)
                        // Check if image inside is visible
                        if (imageStack.currentItem.children && imageStack.currentItem.children.length > 0) {
                            var imageChild = null
                            for (var i = 0; i < imageStack.currentItem.children.length; i++) {
                                if (imageStack.currentItem.children[i].source !== undefined) {
                                    imageChild = imageStack.currentItem.children[i]
                                    break
                                }
                            }
                            if (imageChild) {
                                console.log("  - Image child found:")
                                console.log("    - visible:", imageChild.visible)
                                console.log("    - opacity:", imageChild.opacity)
                                console.log("    - width:", imageChild.width, "height:", imageChild.height)
                                console.log("    - source:", imageChild.source)
                                console.log("    - status:", imageChild.status)
                            }
                        }
                    } else {
                        console.error("StackView currentItem is null after replace!")
                    }
                })
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
            // Settings will be applied to next image via ImageComponent
        }
        function onBlurOpacityChanged() {
            console.log("Blur opacity changed:", root.configuration.BlurOpacity, "%")
            // Settings will be applied to next image via ImageComponent
        }
        function onFillModeChanged() {
            console.log("FillMode changed:", root.configuration.FillMode)
            // Settings will be applied to next image via ImageComponent
        }
        function onImageScaleChanged() {
            console.log("Image scale changed:", root.configuration.ImageScale, "%")
            // Settings will be applied to next image via ImageComponent
        }
            function onTransitionEnabledChanged() {
                console.log("Transition enabled changed:", root.configuration.TransitionEnabled)
                imageStack.doesSkipAnimation = !root.configuration.TransitionEnabled
            }
            function onTransitionRandomChanged() {
                console.log("Transition random changed:", root.configuration.TransitionRandom)
                // Transition type will be determined on next image load
            }
            function onTransitionTypeChanged() {
                console.log("Transition type changed:", root.configuration.TransitionType, "(0=Fade, 1=Slide, 2=Zoom)")
                // Only update if random is disabled
                if (!root.configuration.TransitionRandom) {
                    imageStack.transitionType = root.configuration.TransitionType || 0
                }
            }
        function onTransitionDurationChanged() {
            console.log("Transition duration changed:", root.configuration.TransitionDuration, "ms")
            imageStack.transitionDuration = root.configuration.TransitionDuration || 1000
        }
    }
}

