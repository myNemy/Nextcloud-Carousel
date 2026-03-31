/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// C++ ImageProvider: NO direct import to avoid plasmashell crash if module missing
// We'll detect availability via image://nextcloud/ URL test and load dynamically

// C++ ImageProvider: Dynamic loading with guaranteed fallback
// According to Qt documentation, we use a Loader to dynamically test module availability
// If module is not found, Loader.status will be Loader.Error and we use QML fallback
// This approach guarantees plasmashell will always start, even if C++ module is missing

WallpaperItem {
    id: root

    // C++ NextcloudDownloader availability (detected dynamically)
    // Livello 1: Componente che gestisce solo download da Nextcloud
    property bool nextcloudDownloaderAvailable: false
    property var nextcloudDownloader: null
    property var pendingDownloads: ({})  // Track pending downloads: { imageUrl: true }
    
    // Track current image processing method (for indicator)
    property string currentImageMethod: "QML"  // "QML" or "C++"
    
    // Log when method changes
    onCurrentImageMethodChanged: {
        console.log("═══════════════════════════════════════════════════════════")
        console.log("🔄 METHOD CHANGED:", currentImageMethod)
        console.log("   nextcloudDownloaderAvailable:", nextcloudDownloaderAvailable)
        console.log("   nextcloudDownloader:", nextcloudDownloader ? "available" : "null")
        console.log("═══════════════════════════════════════════════════════════")
    }
    
    // Loader for NextcloudDownloader singleton (loaded dynamically)
    Loader {
        id: nextcloudDownloaderLoader
        asynchronous: true
        active: false
        source: "NextcloudDownloaderSingleton.qml"
        
        onLoaded: {
            console.log("🔍 NextcloudDownloaderLoader onLoaded: item =", item, ", item.downloader =", item ? item.downloader : "N/A")
            if (item && item.downloader) {
                root.nextcloudDownloader = item.downloader
                root.nextcloudDownloaderAvailable = true  // Mark as available
                console.log("✅✅✅ NextcloudDownloader singleton loaded successfully! Downloader:", root.nextcloudDownloader)
                console.log("✅✅✅ nextcloudDownloaderAvailable set to TRUE")
                console.log("🔍 Downloader methods available: downloadImage =", typeof root.nextcloudDownloader.downloadImage)
                
                // Connect to imageDownloaded signal
                if (root.nextcloudDownloader.imageDownloaded) {
                    root.nextcloudDownloader.imageDownloaded.connect(function(localFilePath, originalUrl) {
                        console.log("📥 NextcloudDownloader: imageDownloaded signal received for", originalUrl, "->", localFilePath)
                        // Check if this is a pending download we're waiting for
                        if (root.pendingDownloads && root.pendingDownloads[originalUrl]) {
                            var pendingInfo = root.pendingDownloads[originalUrl]
                            if (pendingInfo.loadGen !== carouselController.slideLoadGeneration) {
                                delete root.pendingDownloads[originalUrl]
                                return
                            }
                            console.log("🔄 Image ready for pending download, creating image component from file:", localFilePath)
                            // Remove from pending downloads
                            delete root.pendingDownloads[originalUrl]
                            // Create image component from local file (Livello 2: usa file locale con ottimizzazioni Plasma)
                            root.currentImageMethod = "C++"  // Track method used
                            console.log("✅✅✅ METHOD: C++ - Using local file from NextcloudDownloader (downloaded):", localFilePath)
                            // Orientation will be read from EXIF in createImageComponentFromFile
                            carouselController.createImageComponentFromFile(localFilePath, pendingInfo.imageUrl || originalUrl, pendingInfo.orientation)
                            
                            // Update method indicator
                            if (root.configuration.ShowMethodIndicator) {
                                methodIndicator.opacity = 1.0
                                if (root.configuration.MethodIndicatorDuration > 0) {
                                    methodIndicatorTimer.restart()
                                }
                            }
                        }
                    })
                    console.log("✅ Connected to imageDownloaded signal")
                } else {
                    console.warn("⚠️  imageDownloaded signal not available on downloader")
                }
                
                // Connect to downloadFailed signal
                if (root.nextcloudDownloader.downloadFailed) {
                    root.nextcloudDownloader.downloadFailed.connect(function(url, errorString) {
                        console.warn("❌ NextcloudDownloader: Download failed for", url, ":", errorString)
                        var pendingInfo = root.pendingDownloads[url]
                        if (!pendingInfo) {
                            return
                        }
                        // Ignore failures from an older slide (user already advanced)
                        if (pendingInfo.loadGen !== carouselController.slideLoadGeneration) {
                            delete root.pendingDownloads[url]
                            return
                        }
                        delete root.pendingDownloads[url]
                        root.loading = false
                        if (carouselController.photoList.length > 1) {
                            console.log("Skipping failed C++ download, advancing on next slide tick...")
                            carouselTimer.restart()
                        }
                    })
                }
            } else {
                console.warn("⚠️  NextcloudDownloaderLoader loaded but item or downloader is null")
            }
        }
        
        onStatusChanged: {
            console.log("🔍 NextcloudDownloaderLoader status changed:", status, "(Null=" + Loader.Null + ", Ready=" + Loader.Ready + ", Loading=" + Loader.Loading + ", Error=" + Loader.Error + ")")
            if (status === Loader.Error) {
                console.warn("⚠️  NextcloudDownloaderLoader failed to load - module may not be available")
                console.warn("   This is OK - will use QML fallback (Data URLs)")
            } else if (status === Loader.Ready) {
                console.log("✅ NextcloudDownloaderLoader is Ready")
            } else if (status === Loader.Loading) {
                console.log("⏳ NextcloudDownloaderLoader is Loading...")
            }
        }
    }
    
    // Function to try loading NextcloudDownloader singleton dynamically
    function tryImportNextcloudDownloader() {
        if (root.nextcloudDownloader) {
            // Already imported
            console.log("✅ NextcloudDownloader already available")
            return
        }
        
        if (nextcloudDownloaderLoader.status === Loader.Loading || nextcloudDownloaderLoader.status === Loader.Ready) {
            // Already loading or loaded
            console.log("🔍 NextcloudDownloaderLoader already active, status:", nextcloudDownloaderLoader.status)
            return
        }
        
        console.log("🔍 Attempting to load NextcloudDownloader singleton via Loader...")
        nextcloudDownloaderLoader.active = true
    }

    Component.onCompleted: {
        root.loading = true
        
        // CRITICAL: Log immediately to verify Component.onCompleted is called
        console.log("═══════════════════════════════════════════════════════════")
        console.log("🔍 NEXTCLOUD CAROUSEL: Component.onCompleted called")
        console.log("🔍 Testing C++ NextcloudDownloader availability...")
        console.log("═══════════════════════════════════════════════════════════")
        
        // Try to load NextcloudDownloader (Livello 1: solo download)
        // This will update nextcloudDownloaderAvailable asynchronously
        root.tryImportNextcloudDownloader()
        
        // Initialize carousel (will use QML fallback if C++ not available)
        console.log("🔍 Initializing carousel controller...")
        carouselController.initialize()
    }

    // Timer for EXIF orientation read timeout
    Timer {
        id: orientationReadTimer
        interval: 500
        repeat: false
        property var callback: null
        onTriggered: {
            if (callback) {
                callback()
            }
        }
    }
    
    // Carousel controller
    QtObject {
        id: carouselController
        
        property var photoList: []
        property var usedIndices: []  // Track recently used indices to avoid repeats
        property var recentIndices: []  // Track recent indices for better randomization
        property int currentIndex: 0
        property bool initialized: false
        property int lastIndex: -1  // Track last shown index
        property int imageSwitchCount: 0  // Track number of image switches for periodic cleanup
        // Incremented on each slide load request; async completions must match or they are ignored (timer vs. slow network race).
        property int slideLoadGeneration: 0
        property int maxCacheSize: 1  // Will be calculated based on photoList.length
        property var dataUrlCache: ({})  // LRU cache: { imageUrl: dataUrl }
        property var cacheOrder: []  // Track cache order for LRU eviction (first = least recently used)
        property bool cacheLocked: false  // Prevent race conditions during cache operations
        property int retryCount: 0  // Track retry attempts for PROPFIND
        property int retryDelay: 30  // Current retry delay in seconds (starts at 30s)
        property int maxRetries: 10  // Maximum retry attempts before giving up
        property int maxImageSizeForDataUrl: 10 * 1024 * 1024  // 10MB default (increased from 5MB)
        property var tempFilePaths: []  // Track temporary file paths for cleanup
        
        // Dynamic memory limit calculation
        // Calculates safe image size limit based on estimated available memory
        // Formula: (estimated_available_memory * safety_factor) / (memory_per_image_multiplier * concurrent_images)
        // Memory per image multiplier (QML fallback path): ~8.6x (ArrayBuffer + Base64 + DataURL + Decoded)
        // Single slide surface: at most one ImageComponent at a time (no StackView / transitions)
        // Safety factor: 0.1 (use only 10% of available memory for images)
        function calculateDynamicImageLimit() {
            // Default conservative values (for systems with unknown memory)
            // NOTE: With sourceSize limit now implemented, decoded memory is reduced by 50-75%
            // However, the Data URL itself (base64 string) still consumes memory, so use a limit unless explicitly disabled.
            var defaultLimitMB = 3  // 3MB default (more conservative, safe for all systems)
            var minLimitMB = 3  // Minimum limit (3MB - safe even on low-end systems)
            var maxLimitMB = 30  // Maximum limit (30MB - even high-end systems shouldn't need more)
            
            // Try to get configured memory limit from user settings
            // NOTE: MaxImageSizeMB = 0 means "no limit" (do not skip images based on size).
            var configuredLimitMB = root.configuration.MaxImageSizeMB || 0
            
            if (configuredLimitMB > 0) {
                // User has configured a limit, use it (but clamp to safe range)
                var limitMB = Math.max(minLimitMB, Math.min(maxLimitMB, configuredLimitMB))
                maxImageSizeForDataUrl = limitMB * 1024 * 1024
                console.log("📊 Using configured image size limit:", limitMB, "MB")
                return
            }

            // No limit (MaxImageSizeMB = 0): do not skip images based on size.
            // WARNING: For Data URL fallback this can be memory-heavy; prefer the C++ downloader path when possible.
            maxImageSizeForDataUrl = 0
            console.log("📊 Image size limit: disabled (MaxImageSizeMB = 0)")
        }
        
        // Calculate optimal cache size based on total number of photos in the list
        // Strategy: DISABLED to prevent memory leaks (OOM Killer issue)
        // Data URLs base64 are very large and not properly released, causing memory accumulation
        // Disabling cache forces re-download but prevents OOM crashes
        // Only one slide ImageComponent at a time; cache of data URLs disabled to limit RAM
        function updateCacheSize() {
            // CRITICAL FIX: Disable cache completely to prevent memory leaks
            // This is a temporary fix until proper memory management is implemented
            maxCacheSize = 0
            
            // Calculate dynamic image size limit based on available memory
            calculateDynamicImageLimit()
            
            var limitMB = maxImageSizeForDataUrl > 0 ? (maxImageSizeForDataUrl / 1024 / 1024).toFixed(0) : "∞"
            console.log("⚠️  Cache DISABLED to prevent memory leaks (OOM Killer fix)")
            console.log("📊 Cache configuration: caching disabled (0 data URLs) - images will be re-downloaded each time")
            console.log("🛡️  Memory protection: Images > " + limitMB + "MB will be skipped to prevent OOM crashes")
            
            // Clear any existing cache immediately
            clearDataUrlCache()
        }
        
        function initialize() {
            if (root.configuration.NextcloudUrl === "" || 
                root.configuration.Username === "") {
                console.warn("Nextcloud URL or Username not configured")
                root.loading = false
                return
            }
            // Reset retry state on new initialization
            retryCount = 0
            retryDelay = 30
            loadPhotos()
        }
        
        // Retry PROPFIND with exponential backoff
        function retryLoadPhotos() {
            if (retryCount >= maxRetries) {
                console.error("❌ Maximum retry attempts reached (" + maxRetries + "). Giving up.")
                console.error("Please check your network connection and Nextcloud server status.")
                root.loading = false
                return
            }
            
            retryCount++
            console.log("🔄 Retrying to load photos (attempt " + retryCount + "/" + maxRetries + ") in " + retryDelay + " seconds...")
            
            // Schedule retry with exponential backoff (30s, 60s, 120s, max 5min)
            retryTimer.interval = retryDelay * 1000
            retryTimer.start()
            
            // Increase delay for next retry (exponential backoff, capped at 5 minutes)
            retryDelay = Math.min(retryDelay * 2, 300)
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
            xhr.timeout = 30000  // 30 seconds timeout for PROPFIND (can be slow with many folders)
            
            var propfindBody = '<?xml version="1.0"?>' +
                '<d:propfind xmlns:d="DAV:">' +
                '<d:prop><d:getcontenttype/></d:prop>' +
                '</d:propfind>'
            
            xhr.ontimeout = function() {
                console.error("⏱️  PROPFIND request timed out after 30 seconds")
                console.error("This may indicate network issues or a very large folder structure")
                root.loading = false
                // Retry with exponential backoff
                retryLoadPhotos()
            }
            
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
                        if (images.length === 0) {
                            console.warn("No images found! XML response preview:", xmlText.substring(0, 500))
                            console.warn("Paths extracted:", paths)
                        }
                        photoList = images
                        
                        if (photoList.length > 0) {
                            // Reset retry state on successful load
                            retryCount = 0
                            retryDelay = 30
                            
                            // Reset switch counter and clear cache when reloading photo list
                            imageSwitchCount = 0
                            clearDataUrlCache()
                            
                            // Update cache size based on number of photos
                            updateCacheSize()
                            
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
                                recentIndices = [currentIndex]
                            } else {
                                // Sequential: start from beginning
                                currentIndex = 0
                            }
                            
                            lastIndex = -1
                            usedIndices = []
                            recentIndices = []
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
                            console.error("Network error or CORS issue - connection may be down")
                            // Retry with exponential backoff for network errors
                            retryLoadPhotos()
                            return  // Don't set loading = false here, retry will handle it
                        }
                        // For other errors (401, 404), don't retry (configuration issues)
                        root.loading = false
                    }
                }
            }
            
            xhr.onerror = function() {
                console.error("Network error during PROPFIND request - connection may be down")
                root.loading = false
                // Retry with exponential backoff
                retryLoadPhotos()
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
                // Random: avoid recent photos (last 3-5 depending on list size)
                var avoidCount = Math.min(Math.max(3, Math.floor(photoList.length * 0.3)), 5)
                var availableIndices = []
                
                // Build list of available indices excluding recent ones
                for (var i = 0; i < photoList.length; i++) {
                    var isRecent = false
                    // Check if index is in recent list
                    for (var j = 0; j < recentIndices.length && j < avoidCount; j++) {
                        if (recentIndices[recentIndices.length - 1 - j] === i) {
                            isRecent = true
                            break
                        }
                    }
                    if (!isRecent) {
                        availableIndices.push(i)
                    }
                }
                
                // If all indices are recent, use all except last one
                if (availableIndices.length === 0) {
                    for (var k = 0; k < photoList.length; k++) {
                        if (k !== lastIndex) {
                            availableIndices.push(k)
                        }
                    }
                    if (availableIndices.length === 0) {
                        availableIndices = [0]
                    }
                }
                
                var randomPos = Math.floor(Math.random() * availableIndices.length)
                currentIndex = availableIndices[randomPos]
                lastIndex = currentIndex
                
                // Track recent indices
                recentIndices.push(currentIndex)
                if (recentIndices.length > 10) {
                    recentIndices.shift()
                }
            } else if (orderMode === 2) {
                // Shuffle once: sequential through shuffled list
                currentIndex = (currentIndex + 1) % photoList.length
            } else if (orderMode === 3) {
                // Smart random: avoid showing same image consecutively and prefer unused images
                var availableIndices = []
                
                // First, try to find images not in recent list
                for (var i = 0; i < photoList.length; i++) {
                    if (i !== lastIndex) {
                        var isRecent = false
                        // Check if index is in recent list (last 5)
                        for (var j = 0; j < recentIndices.length && j < 5; j++) {
                            if (recentIndices[recentIndices.length - 1 - j] === i) {
                                isRecent = true
                                break
                            }
                        }
                        if (!isRecent) {
                            availableIndices.push(i)
                        }
                    }
                }
                
                // If all images are recent, use all except last one
                if (availableIndices.length === 0) {
                    for (var k = 0; k < photoList.length; k++) {
                        if (k !== lastIndex) {
                            availableIndices.push(k)
                        }
                    }
                    if (availableIndices.length === 0) {
                        availableIndices = [0]
                    }
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
                
                // Track recent indices (keep last 10)
                recentIndices.push(currentIndex)
                if (recentIndices.length > 10) {
                    recentIndices.shift()
                }
            }
            
            // Increment switch counter for periodic cleanup
            imageSwitchCount++
            
            // Data URL cache stays disabled (maxCacheSize 0); clear maps each slide to drop JS references early
            clearDataUrlCache()
            
            if (imageSwitchCount >= 5) {
                imageSwitchCount = 0
                Qt.callLater(function() {
                    clearDataUrlCache()
                })
            }
            
            updateCurrentImage()
        }
        
        // Clear data URL cache to free memory
        function clearDataUrlCache() {
            // Prevent concurrent access
            if (cacheLocked) {
                console.warn("⚠️  Cache is locked, skipping cleanup")
                return
            }
            
            try {
                cacheLocked = true
                
                // Clear cache by creating new objects (safer than delete in QML)
                dataUrlCache = {}
                cacheOrder = []
            } catch (e) {
                console.error("❌ Error clearing cache:", e)
                // Reset to safe state
                try {
                    dataUrlCache = {}
                    cacheOrder = []
                } catch (e2) {
                    console.error("❌ Critical error resetting cache:", e2)
                }
            }
            // Always unlock (QML doesn't support finally, so we do it here)
            cacheLocked = false
        }
        
        // Get data URL from cache or return null if not cached
        // Uses LRU: moves accessed item to end of cacheOrder (most recently used)
        function getCachedDataUrl(imageUrl) {
            // Safety checks
            if (!imageUrl) {
                return null
            }
            if (!dataUrlCache || !cacheOrder) {
                return null
            }
            
            // Skip if cache is being cleared
            if (cacheLocked) {
                return null
            }
            
            try {
                // Check if URL exists in cache using 'in' operator (QML-compatible)
                if (imageUrl in dataUrlCache) {
                    // Move to end of cache order (most recently used)
                    // Create a copy to avoid modifying while iterating
                    var currentOrder = cacheOrder.slice()  // Copy array
                    var index = currentOrder.indexOf(imageUrl)
                    if (index !== -1) {
                        currentOrder.splice(index, 1)
                    }
                    currentOrder.push(imageUrl)
                    cacheOrder = currentOrder  // Replace entire array (atomic)
                    return dataUrlCache[imageUrl]
                }
            } catch (e) {
                console.error("❌ Error in getCachedDataUrl:", e)
                return null
            }
            return null
        }
        
        // Store data URL in cache (LRU eviction if needed)
        // Uses LRU: removes first item in cacheOrder (least recently used) if cache is full
        function cacheDataUrl(imageUrl, dataUrl) {
            // Safety checks
            if (!imageUrl || !dataUrl) {
                console.warn("⚠️  cacheDataUrl: Invalid parameters")
                return
            }
            if (!dataUrlCache || !cacheOrder) {
                console.warn("⚠️  cacheDataUrl: Cache not initialized")
                return
            }
            
            // Skip if cache is being cleared
            if (cacheLocked) {
                console.warn("⚠️  Cache is locked, skipping cache operation")
                return
            }
            
            try {
                // Always cache - no size limit (user wants to see all images)
                // If cache is disabled (maxCacheSize = 0), don't cache
                if (maxCacheSize <= 0) {
                    return
                }
                
                // Create a copy to avoid modifying while iterating (atomic operations)
                var currentOrder = cacheOrder.slice()  // Copy array
                
                // If already in cache, just update order (move to end)
                if (imageUrl in dataUrlCache) {
                    var index = currentOrder.indexOf(imageUrl)
                    if (index !== -1) {
                        currentOrder.splice(index, 1)
                    }
                } else {
                    // Remove oldest entry (first in cacheOrder) if cache is full
                    if (currentOrder.length >= maxCacheSize) {
                        var oldestUrl = currentOrder.shift()
                        if (oldestUrl) {
                            // Create new cache object without the oldest entry (safer than delete in QML)
                            var newCache = {}
                            for (var key in dataUrlCache) {
                                if (key !== oldestUrl) {
                                    newCache[key] = dataUrlCache[key]
                                }
                            }
                            dataUrlCache = newCache
                        }
                    }
                }
                
                // Add/update in cache (always add to end)
                dataUrlCache[imageUrl] = dataUrl
                currentOrder.push(imageUrl)
                cacheOrder = currentOrder  // Replace entire array (atomic)
            } catch (e) {
                console.error("❌ Error in cacheDataUrl:", e)
                // Don't crash, just log the error
            }
        }
        
        function updateCurrentImage() {
            if (currentIndex >= 0 && currentIndex < photoList.length) {
                slideLoadGeneration++
                var loadGen = slideLoadGeneration
                var photoUrl = photoList[currentIndex]
                // Reduced logging verbosity - only log every 10th image to prevent log bloat
                if (currentIndex % 10 === 0 || currentIndex === 0) {
                    // Reduced logging frequency for performance (log every 100 images or first/last)
                    var shouldLog = (currentIndex === 0 || 
                                    currentIndex === photoList.length - 1 || 
                                    (currentIndex + 1) % 100 === 0)
                    if (shouldLog) {
                        console.log("Loading image", currentIndex + 1, "of", photoList.length)
                    }
                }
                
                // Image component doesn't support auth in URL, so we need to download it
                loadImageWithAuth(photoUrl, loadGen)
            }
        }
        
        function arrayBufferToBase64(buffer) {
            // Optimized manual base64 encoding (btoa might not be available in QML)
            // Uses array instead of string concatenation for better performance with large images
            // This follows QML best practices for heavy string operations
            var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
            var bytes = new Uint8Array(buffer)
            var len = bytes.length
            var base64Array = []  // Use array instead of string concatenation (much faster)
            
            // Process in chunks of 3 bytes
            for (var i = 0; i < len; i += 3) {
                base64Array.push(chars[bytes[i] >> 2])
                base64Array.push(chars[((bytes[i] & 3) << 4) | ((i + 1 < len ? bytes[i + 1] : 0) >> 4)])
                base64Array.push(chars[((i + 1 < len ? bytes[i + 1] : 0) & 15) << 2 | ((i + 2 < len ? bytes[i + 2] : 0) >> 6)])
                base64Array.push(chars[(i + 2 < len ? bytes[i + 2] : 0) & 63])
            }
            
            // Handle padding
            if ((len % 3) === 2) {
                base64Array[base64Array.length - 1] = '='
            } else if (len % 3 === 1) {
                base64Array[base64Array.length - 1] = '='
                base64Array[base64Array.length - 2] = '='
            }
            
            // Join array to string (much faster than incremental concatenation)
            return base64Array.join('')
        }
        
        // Read EXIF orientation from JPEG ArrayBuffer
        // Returns rotation angle in degrees (0, 90, -90, 180) or 0 if not found/error
        // Extended EXIF data structure
        property var currentExifData: ({
            orientation: 0,
            dateTime: "",
            make: "",
            model: "",
            iso: 0,
            fNumber: 0,
            exposureTime: "",
            latitude: 0,
            longitude: 0,
            latitudeRef: "",
            longitudeRef: "",
            country: "",
            city: "",
            hasData: false
        })
        // Separate property for filename to ensure QML binding works correctly
        // QML doesn't always detect changes to nested object properties in property var
        property string currentFileName: ""
        
        // Unique identifier for current image to prevent location updates for wrong image
        // This ensures reverse geocoding responses only update the correct image
        property string currentImageId: ""
        
        // Optimized: Only searches first 64KB where EXIF data is always located (prevents UI blocking on large images)
        // Extended to read multiple EXIF tags
        function readExifData(arrayBuffer) {
            // Reset EXIF data (fileName is stored separately in currentFileName property)
            currentExifData = {
                orientation: 0,
                dateTime: "",
                make: "",
                model: "",
                iso: 0,
                fNumber: 0,
                exposureTime: "",
                latitude: 0,
                longitude: 0,
                latitudeRef: "",
                longitudeRef: "",
                country: "",
                city: "",
                hasData: false
            }
            // Reset image ID when reading new EXIF data
            currentImageId = ""
            
            var orientation = readExifOrientation(arrayBuffer)
            // Force update to trigger QML bindings
            var exifData = currentExifData
            exifData.orientation = orientation
            
            // If orientation was found (non-zero), we have EXIF data
            // This ensures hasData is true even if only orientation is available
            if (orientation !== 0) {
                exifData.hasData = true
            }
            currentExifData = exifData
            
            // Read additional EXIF tags
            readExifTags(arrayBuffer)
            
            return orientation  // Keep backward compatibility
        }
        
        // Legacy function for backward compatibility
        // Now supports JPEG, TIFF, and WebP (which can contain EXIF)
        function readExifOrientation(arrayBuffer) {
            try {
                // CRITICAL: Limit memory usage - only read first 64KB for EXIF parsing
                // EXIF data is always in the first segments, so we don't need the full image
                // This prevents creating huge Uint8Array from large images (8MB+)
                var maxBytesForExif = Math.min(arrayBuffer.byteLength, 65536)  // 64KB limit
                
                // Create a view of only the first 64KB to prevent memory issues with large images
                // Using ArrayBuffer.slice() would copy, so we use Uint8Array with offset/length
                var bytes = new Uint8Array(arrayBuffer, 0, maxBytesForExif)
                if (bytes.length < 8) {
                    return 0  // Too small to contain EXIF
                }
                
                // Optimize: EXIF data is always in the first segments (typically < 64KB)
                // Limit search to first 64KB to prevent UI blocking on very large images
                // This follows QML best practices for heavy operations
                var maxSearchBytes = bytes.length  // Already limited to 64KB above
                
                var tiffOffset = -1
                var isIntel = false
                
                // Check if it's a JPEG (starts with 0xFFD8)
                if (bytes[0] === 0xFF && bytes[1] === 0xD8) {
                    // JPEG: Search for APP1 marker (0xFFE1) which contains EXIF data
                    var i = 2  // Start after SOI marker
                    while (i < maxSearchBytes - 1) {
                        // Check for APP1 marker
                        if (bytes[i] === 0xFF && bytes[i + 1] === 0xE1) {
                            // Found APP1 segment
                            var segmentLength = (bytes[i + 2] << 8) | bytes[i + 3]
                            var segmentStart = i + 4
                            
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
                                
                                if (exifHeader === "Exif\0\0") {
                                    // Found EXIF segment in JPEG
                                    tiffOffset = segmentStart + 6
                                    break
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
                } else if ((bytes[0] === 0x49 && bytes[1] === 0x49) || (bytes[0] === 0x4D && bytes[1] === 0x4D)) {
                    // TIFF file (Intel: 0x4949, Motorola: 0x4D4D)
                    // TIFF can contain EXIF directly (EXIF is based on TIFF)
                    tiffOffset = 0
                } else {
                    // Try to find "Exif\0\0" header (for WebP and other formats)
                    // WebP can contain EXIF in a similar format
                    for (var j = 0; j < maxSearchBytes - 6; j++) {
                        if (bytes[j] === 0x45 && bytes[j + 1] === 0x78 && bytes[j + 2] === 0x69 && 
                            bytes[j + 3] === 0x66 && bytes[j + 4] === 0x00 && bytes[j + 5] === 0x00) {
                            // Found "Exif\0\0" header
                            tiffOffset = j + 6
                            break
                        }
                    }
                }
                
                // If we found EXIF/TIFF data, parse it
                if (tiffOffset >= 0 && tiffOffset + 8 <= bytes.length) {
                    // Found EXIF segment, now find Orientation tag (0x0112)
                    // EXIF structure: TIFF header (8 bytes) + IFD0
                                
                    // Check byte order (0x4949 = Intel, 0x4D4D = Motorola)
                    isIntel = (bytes[tiffOffset] === 0x49 && bytes[tiffOffset + 1] === 0x49)
                    
                    // Read IFD0 offset (offset 4 from TIFF start, 4 bytes)
                    var ifd0OffsetAddr = tiffOffset + 4
                    if (ifd0OffsetAddr + 4 > bytes.length) {
                        return 0
                    }
                    
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
                    if (ifd0Addr + 2 > bytes.length) {
                        return 0
                    }
                    
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
                            // Read orientation value (offset 8 from entry start)
                            var valueOffset = entryOffset + 8
                            var orientation
                            if (isIntel) {
                                orientation = bytes[valueOffset] | (bytes[valueOffset + 1] << 8)
                            } else {
                                orientation = (bytes[valueOffset] << 8) | bytes[valueOffset + 1]
                            }
                            
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
                                return rotationAngle
                            case 3: 
                                rotationAngle = 180
                                return rotationAngle
                            case 6: 
                                // Image was rotated 90° clockwise, need to rotate 90° counter-clockwise to correct
                                rotationAngle = 90
                                return rotationAngle
                            case 8: 
                                // Image was rotated 90° counter-clockwise, need to rotate 90° clockwise to correct
                                rotationAngle = -90
                                return rotationAngle
                            default: 
                                return 0    // Unknown, assume normal
                            }
                        }
                        
                        entryOffset += 12  // Each IFD entry is 12 bytes
                    }
                }
                
                // Orientation not found - silently return 0 (normal orientation)
                return 0  // Orientation not found, assume normal
            } catch (e) {
                console.warn("❌ Error reading EXIF orientation:", e)
                return 0  // On error, assume normal orientation
            }
        }
        
        // Read additional EXIF tags (DateTime, Make, Model, ISO, FNumber, ExposureTime)
        // Following same pattern as readExifOrientation but reading multiple tags
        // Now supports JPEG, TIFF, and WebP
        function readExifTags(arrayBuffer) {
            try {
                // CRITICAL: Limit memory usage - only read first 64KB for EXIF parsing
                // EXIF data is always in the first segments, so we don't need the full image
                // This prevents creating huge Uint8Array from large images (8MB+)
                var maxBytesForExif = Math.min(arrayBuffer.byteLength, 65536)  // 64KB limit
                console.log("🌍 readExifTags called, arrayBuffer length:", arrayBuffer ? arrayBuffer.byteLength : "null", "reading first", maxBytesForExif, "bytes for EXIF")
                
                // Create a view of only the first 64KB to prevent memory issues with large images
                // Using ArrayBuffer.slice() would copy, so we use Uint8Array with offset/length
                var bytes = new Uint8Array(arrayBuffer, 0, maxBytesForExif)
                if (bytes.length < 8) {
                    console.log("🌍 readExifTags: too small, returning")
                    return  // Too small to contain EXIF
                }
                
                var tiffOffset = -1
                var isIntel = false
                
                var maxSearchBytes = bytes.length  // Already limited to 64KB above
                console.log("🌍 readExifTags: searching for EXIF, maxSearchBytes:", maxSearchBytes)
                
                // Check if it's a JPEG (starts with 0xFFD8)
                if (bytes[0] === 0xFF && bytes[1] === 0xD8) {
                    // JPEG: Search for APP1 marker
                    var i = 2
                    while (i < maxSearchBytes - 1) {
                        if (bytes[i] === 0xFF && bytes[i + 1] === 0xE1) {
                            var segmentLength = (bytes[i + 2] << 8) | bytes[i + 3]
                            var segmentStart = i + 4
                            
                            if (segmentStart + 6 <= bytes.length) {
                                var exifHeader = String.fromCharCode(
                                    bytes[segmentStart], bytes[segmentStart + 1],
                                    bytes[segmentStart + 2], bytes[segmentStart + 3],
                                    bytes[segmentStart + 4], bytes[segmentStart + 5]
                                )
                                
                                if (exifHeader === "Exif\0\0") {
                                    tiffOffset = segmentStart + 6
                                    break
                                }
                            }
                            i += 2 + segmentLength
                        } else if (bytes[i] === 0xFF && (bytes[i + 1] & 0xF0) === 0xE0) {
                            var segLen = (bytes[i + 2] << 8) | bytes[i + 3]
                            i += 2 + segLen
                        } else if (bytes[i] === 0xFF && bytes[i + 1] === 0xDA) {
                            break
                        } else {
                            i++
                        }
                    }
                } else if ((bytes[0] === 0x49 && bytes[1] === 0x49) || (bytes[0] === 0x4D && bytes[1] === 0x4D)) {
                    // TIFF file (Intel: 0x4949, Motorola: 0x4D4D)
                    tiffOffset = 0
                } else {
                    // Try to find "Exif\0\0" header (for WebP and other formats)
                    for (var j = 0; j < maxSearchBytes - 6; j++) {
                        if (bytes[j] === 0x45 && bytes[j + 1] === 0x78 && bytes[j + 2] === 0x69 && 
                            bytes[j + 3] === 0x66 && bytes[j + 4] === 0x00 && bytes[j + 5] === 0x00) {
                            tiffOffset = j + 6
                            break
                        }
                    }
                }
                
                // If we found EXIF/TIFF data, parse it
                console.log("🌍 readExifTags: tiffOffset found:", tiffOffset)
                if (tiffOffset < 0 || tiffOffset + 8 > bytes.length) {
                    console.log("🌍 GPS search skipped - tiffOffset not found or invalid")
                } else {
                    // Parse EXIF data
                    isIntel = (bytes[tiffOffset] === 0x49 && bytes[tiffOffset + 1] === 0x49)
                    console.log("🌍 readExifTags: byte order isIntel:", isIntel)
                    
                    // Read IFD0 offset
                    var ifd0OffsetAddr = tiffOffset + 4
                    if (ifd0OffsetAddr + 4 > bytes.length) {
                        console.log("🌍 readExifTags: ifd0OffsetAddr out of bounds, returning")
                        return
                    }
                    
                    var ifd0Offset
                    if (isIntel) {
                        ifd0Offset = bytes[ifd0OffsetAddr] | (bytes[ifd0OffsetAddr + 1] << 8) | 
                                     (bytes[ifd0OffsetAddr + 2] << 16) | (bytes[ifd0OffsetAddr + 3] << 24)
                    } else {
                        ifd0Offset = (bytes[ifd0OffsetAddr] << 24) | (bytes[ifd0OffsetAddr + 1] << 16) | 
                                     (bytes[ifd0OffsetAddr + 2] << 8) | bytes[ifd0OffsetAddr + 3]
                    }
                    
                    var ifd0Addr = tiffOffset + ifd0Offset
                    console.log("🌍 readExifTags: calculated ifd0Addr:", ifd0Addr, "bytes.length:", bytes.length)
                    if (ifd0Addr + 2 > bytes.length) {
                        console.log("🌍 GPS search skipped - ifd0Addr out of bounds")
                        return
                    }
                    
                    var numEntries
                    if (isIntel) {
                        numEntries = bytes[ifd0Addr] | (bytes[ifd0Addr + 1] << 8)
                    } else {
                        numEntries = (bytes[ifd0Addr] << 8) | bytes[ifd0Addr + 1]
                    }
                    console.log("🌍 IFD0 found - addr:", ifd0Addr, "entries:", numEntries, "isIntel:", isIntel)
                    
                    // Read tags from IFD0
                    var entryOffset = ifd0Addr + 2
                    console.log("🌍 Starting to read IFD0 tags, entryOffset:", entryOffset)
                    for (var e = 0; e < numEntries && entryOffset + 12 <= bytes.length; e++) {
                        var tag
                        if (isIntel) {
                            tag = bytes[entryOffset] | (bytes[entryOffset + 1] << 8)
                        } else {
                            tag = (bytes[entryOffset] << 8) | bytes[entryOffset + 1]
                        }
                        
                        var type
                        if (isIntel) {
                            type = bytes[entryOffset + 2] | (bytes[entryOffset + 3] << 8)
                        } else {
                            type = (bytes[entryOffset + 2] << 8) | bytes[entryOffset + 3]
                        }
                        
                        var count
                        if (isIntel) {
                            count = bytes[entryOffset + 4] | (bytes[entryOffset + 5] << 8) | 
                                    (bytes[entryOffset + 6] << 16) | (bytes[entryOffset + 7] << 24)
                        } else {
                            count = (bytes[entryOffset + 4] << 24) | (bytes[entryOffset + 5] << 16) | 
                                    (bytes[entryOffset + 6] << 8) | bytes[entryOffset + 7]
                        }
                        
                        // Read tag value based on type
                        var valueOffset = entryOffset + 8
                        var valueAddr = tiffOffset
                        
                        // If value fits in 4 bytes, it's stored directly, otherwise it's an offset
                        if (type === 2) {  // ASCII string
                            var value = ""
                            // Handle both inline (count <= 4) and offset-based strings
                            if (count <= 4) {
                                // Value is stored directly in the entry
                                for (var c = 0; c < count - 1 && valueOffset + c < bytes.length; c++) {
                                    value += String.fromCharCode(bytes[valueOffset + c])
                                }
                            } else {
                                // Value is stored at an offset
                                var stringOffset
                                if (isIntel) {
                                    stringOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) | 
                                                  (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24)
                                } else {
                                    stringOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) | 
                                                  (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3]
                                }
                                var stringAddr = tiffOffset + stringOffset
                                for (var c = 0; c < count - 1 && stringAddr + c < bytes.length; c++) {
                                    value += String.fromCharCode(bytes[stringAddr + c])
                                }
                            }
                            
                            if (tag === 0x0132) {  // DateTime
                                console.log("📅 Found DateTime tag in IFD0:", value)
                                var exifData = currentExifData
                                exifData.dateTime = value
                                exifData.hasData = true
                                currentExifData = exifData
                            } else if (tag === 0x010F) {  // Make
                                console.log("📷 Found Make tag in IFD0:", value)
                                var exifData = currentExifData
                                exifData.make = value
                                exifData.hasData = true
                                currentExifData = exifData
                            } else if (tag === 0x0110) {  // Model
                                console.log("📷 Found Model tag in IFD0:", value)
                                var exifData = currentExifData
                                exifData.model = value
                                exifData.hasData = true
                                currentExifData = exifData
                            }
                        } else if (type === 3 && count === 1) {  // Short (2 bytes)
                            var shortValue
                            if (isIntel) {
                                shortValue = bytes[valueOffset] | (bytes[valueOffset + 1] << 8)
                            } else {
                                shortValue = (bytes[valueOffset] << 8) | bytes[valueOffset + 1]
                            }
                            
                            // ISO can be in IFD0 or EXIF IFD, but we'll read it from EXIF IFD
                            // (handled below when reading EXIF IFD)
                        } else if (type === 5 && count === 1) {  // Rational (2 longs)
                            // Read offset to rational value
                            var rationalOffset
                            if (isIntel) {
                                rationalOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) | 
                                               (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24)
                            } else {
                                rationalOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) | 
                                               (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3]
                            }
                            
                            // FNumber and ExposureTime are typically in EXIF IFD, not IFD0
                            // We'll read them from EXIF IFD (handled below)
                        }
                        
                        entryOffset += 12
                    }
                    console.log("🌍 Finished reading IFD0 tags, now searching for EXIF IFD")
                    
                    // Read EXIF IFD (subdirectory) for ISO, FNumber, ExposureTime
                    // These tags are typically in EXIF IFD, not IFD0
                    // Also search for GPSInfo tag (0x8825) in IFD0 - according to EXIF spec, it's in IFD0
                    entryOffset = ifd0Addr + 2
                    var exifIFDOffset = -1
                    var gpsIFDOffset = -1  // Store GPS IFD offset found in IFD0
                    console.log("🌍 Searching IFD0 for ExifOffset (0x8769) and GPSInfo (0x8825) tags")
                    for (var e2 = 0; e2 < numEntries && entryOffset + 12 <= bytes.length; e2++) {
                        var tag2
                        if (isIntel) {
                            tag2 = bytes[entryOffset] | (bytes[entryOffset + 1] << 8)
                        } else {
                            tag2 = (bytes[entryOffset] << 8) | bytes[entryOffset + 1]
                        }
                        
                        // Read tag type to determine how to read the value
                        var type2
                        if (isIntel) {
                            type2 = bytes[entryOffset + 2] | (bytes[entryOffset + 3] << 8)
                        } else {
                            type2 = (bytes[entryOffset + 2] << 8) | bytes[entryOffset + 3]
                        }
                        
                        var valueOffset2 = entryOffset + 8
                        
                        if (tag2 === 0x8769) {  // ExifOffset tag (unsigned long)
                            // Read offset to EXIF IFD
                            if (isIntel) {
                                exifIFDOffset = bytes[valueOffset2] | (bytes[valueOffset2 + 1] << 8) | 
                                                (bytes[valueOffset2 + 2] << 16) | (bytes[valueOffset2 + 3] << 24)
                            } else {
                                exifIFDOffset = (bytes[valueOffset2] << 24) | (bytes[valueOffset2 + 1] << 16) | 
                                                (bytes[valueOffset2 + 2] << 8) | bytes[valueOffset2 + 3]
                            }
                            console.log("🔍 Found ExifOffset tag (0x8769), EXIF IFD at offset:", exifIFDOffset)
                        } else if (tag2 === 0x8825) {  // GPSInfo tag (unsigned long) - according to EXIF spec
                            // Read offset to GPS IFD
                            if (isIntel) {
                                gpsIFDOffset = bytes[valueOffset2] | (bytes[valueOffset2 + 1] << 8) | 
                                               (bytes[valueOffset2 + 2] << 16) | (bytes[valueOffset2 + 3] << 24)
                            } else {
                                gpsIFDOffset = (bytes[valueOffset2] << 24) | (bytes[valueOffset2 + 1] << 16) | 
                                               (bytes[valueOffset2 + 2] << 8) | bytes[valueOffset2 + 3]
                            }
                            console.log("🌍 ✅ Found GPSInfo tag (0x8825) in IFD0, GPS IFD at offset:", gpsIFDOffset)
                        }
                        entryOffset += 12
                    }
                    
                    // If we found EXIF IFD, read tags from it
                    if (exifIFDOffset >= 0) {
                        var exifIFDAddr = tiffOffset + exifIFDOffset
                        if (exifIFDAddr + 2 <= bytes.length) {
                            var numExifEntries
                            if (isIntel) {
                                numExifEntries = bytes[exifIFDAddr] | (bytes[exifIFDAddr + 1] << 8)
                            } else {
                                numExifEntries = (bytes[exifIFDAddr] << 8) | bytes[exifIFDAddr + 1]
                            }
                            console.log("📊 Reading EXIF IFD with", numExifEntries, "entries")
                            
                            var exifEntryOffset = exifIFDAddr + 2
                            for (var e3 = 0; e3 < numExifEntries && exifEntryOffset + 12 <= bytes.length; e3++) {
                                var tag3
                                if (isIntel) {
                                    tag3 = bytes[exifEntryOffset] | (bytes[exifEntryOffset + 1] << 8)
                                } else {
                                    tag3 = (bytes[exifEntryOffset] << 8) | bytes[exifEntryOffset + 1]
                                }
                                
                                var type3
                                if (isIntel) {
                                    type3 = bytes[exifEntryOffset + 2] | (bytes[exifEntryOffset + 3] << 8)
                                } else {
                                    type3 = (bytes[exifEntryOffset + 2] << 8) | bytes[exifEntryOffset + 3]
                                }
                                
                                var count3
                                if (isIntel) {
                                    count3 = bytes[exifEntryOffset + 4] | (bytes[exifEntryOffset + 5] << 8) | 
                                            (bytes[exifEntryOffset + 6] << 16) | (bytes[exifEntryOffset + 7] << 24)
                                } else {
                                    count3 = (bytes[exifEntryOffset + 4] << 24) | (bytes[exifEntryOffset + 5] << 16) | 
                                            (bytes[exifEntryOffset + 6] << 8) | bytes[exifEntryOffset + 7]
                                }
                                
                                var valueOffset3 = exifEntryOffset + 8
                                
                                // Read ISO (0x8827) - Short type
                                if (tag3 === 0x8827 && type3 === 3 && count3 === 1) {
                                    var isoValue
                                    if (isIntel) {
                                        isoValue = bytes[valueOffset3] | (bytes[valueOffset3 + 1] << 8)
                                    } else {
                                        isoValue = (bytes[valueOffset3] << 8) | bytes[valueOffset3 + 1]
                                    }
                                    console.log("📸 Found ISO tag (0x8827) in EXIF IFD:", isoValue)
                                    var exifData = currentExifData
                                    exifData.iso = isoValue
                                    exifData.hasData = true
                                    currentExifData = exifData
                                }
                                // Read FNumber (0x829D) and ExposureTime (0x829A) - Rational type
                                else if ((tag3 === 0x829D || tag3 === 0x829A) && type3 === 5 && count3 === 1) {
                                    var rationalOffset3
                                    if (isIntel) {
                                        rationalOffset3 = bytes[valueOffset3] | (bytes[valueOffset3 + 1] << 8) | 
                                                         (bytes[valueOffset3 + 2] << 16) | (bytes[valueOffset3 + 3] << 24)
                                    } else {
                                        rationalOffset3 = (bytes[valueOffset3] << 24) | (bytes[valueOffset3 + 1] << 16) | 
                                                         (bytes[valueOffset3 + 2] << 8) | bytes[valueOffset3 + 3]
                                    }
                                    
                                    var rationalAddr3 = tiffOffset + rationalOffset3
                                    if (rationalAddr3 + 8 <= bytes.length) {
                                        var numerator3, denominator3
                                        if (isIntel) {
                                            numerator3 = bytes[rationalAddr3] | (bytes[rationalAddr3 + 1] << 8) | 
                                                         (bytes[rationalAddr3 + 2] << 16) | (bytes[rationalAddr3 + 3] << 24)
                                            denominator3 = bytes[rationalAddr3 + 4] | (bytes[rationalAddr3 + 5] << 8) | 
                                                          (bytes[rationalAddr3 + 6] << 16) | (bytes[rationalAddr3 + 7] << 24)
                                        } else {
                                            numerator3 = (bytes[rationalAddr3] << 24) | (bytes[rationalAddr3 + 1] << 16) | 
                                                         (bytes[rationalAddr3 + 2] << 8) | bytes[rationalAddr3 + 3]
                                            denominator3 = (bytes[rationalAddr3 + 4] << 24) | (bytes[rationalAddr3 + 5] << 16) | 
                                                          (bytes[rationalAddr3 + 6] << 8) | bytes[rationalAddr3 + 7]
                                        }
                                        
                                        if (denominator3 > 0) {
                                            var exifData = currentExifData
                                            if (tag3 === 0x829D) {  // FNumber
                                                var fNum = numerator3 / denominator3
                                                console.log("📸 Found FNumber tag (0x829D) in EXIF IFD:", fNum)
                                                exifData.fNumber = fNum
                                                exifData.hasData = true
                                                currentExifData = exifData
                                            } else if (tag3 === 0x829A) {  // ExposureTime
                                                var expTime = numerator3 / denominator3
                                                var expTimeStr = expTime < 1 ? "1/" + Math.round(1 / expTime) + "s" : expTime.toFixed(1) + "s"
                                                console.log("📸 Found ExposureTime tag (0x829A) in EXIF IFD:", expTimeStr)
                                                exifData.exposureTime = expTimeStr
                                                exifData.hasData = true
                                                currentExifData = exifData
                                            }
                                        }
                                    }
                                }
                                
                                exifEntryOffset += 12
                            }
                        }
                    }
                    
                    // Read GPS IFD (subdirectory) for GPS coordinates
                    // GPS data is in a separate IFD referenced by GPSInfo tag (0x8825) in IFD0
                    // According to EXIF spec, GPSInfo tag (0x8825) is in IFD0 (we already searched for it above)
                    // gpsIFDOffset was found in the loop above when searching for ExifOffset
                    console.log("🌍 About to read GPS IFD - gpsIFDOffset:", gpsIFDOffset)
                    if (gpsIFDOffset >= 0) {
                        var gpsIFDAddr = tiffOffset + gpsIFDOffset
                        console.log("🌍 GPS IFD address:", gpsIFDAddr, "(tiffOffset:", tiffOffset, "+ gpsIFDOffset:", gpsIFDOffset + ")")
                        if (gpsIFDAddr + 2 <= bytes.length) {
                            var numGpsEntries
                            if (isIntel) {
                                numGpsEntries = bytes[gpsIFDAddr] | (bytes[gpsIFDAddr + 1] << 8)
                            } else {
                                numGpsEntries = (bytes[gpsIFDAddr] << 8) | bytes[gpsIFDAddr + 1]
                            }
                            console.log("🌍 Reading GPS IFD with", numGpsEntries, "entries")
                            
                            var gpsEntryOffset = gpsIFDAddr + 2
                            var gpsLatitudeRef = ""
                            var gpsLongitudeRef = ""
                            var gpsLatitude = null  // Will be array of 3 rationals [degrees, minutes, seconds]
                            var gpsLongitude = null  // Will be array of 3 rationals [degrees, minutes, seconds]
                            
                            for (var e5 = 0; e5 < numGpsEntries && gpsEntryOffset + 12 <= bytes.length; e5++) {
                                var tag5
                                if (isIntel) {
                                    tag5 = bytes[gpsEntryOffset] | (bytes[gpsEntryOffset + 1] << 8)
                                } else {
                                    tag5 = (bytes[gpsEntryOffset] << 8) | bytes[gpsEntryOffset + 1]
                                }
                                
                                var type5
                                if (isIntel) {
                                    type5 = bytes[gpsEntryOffset + 2] | (bytes[gpsEntryOffset + 3] << 8)
                                } else {
                                    type5 = (bytes[gpsEntryOffset + 2] << 8) | bytes[gpsEntryOffset + 3]
                                }
                                
                                var count5
                                if (isIntel) {
                                    count5 = bytes[gpsEntryOffset + 4] | (bytes[gpsEntryOffset + 5] << 8) | 
                                             (bytes[gpsEntryOffset + 6] << 16) | (bytes[gpsEntryOffset + 7] << 24)
                                } else {
                                    count5 = (bytes[gpsEntryOffset + 4] << 24) | (bytes[gpsEntryOffset + 5] << 16) | 
                                             (bytes[gpsEntryOffset + 6] << 8) | bytes[gpsEntryOffset + 7]
                                }
                                
                                var valueOffset5 = gpsEntryOffset + 8
                                
                                // Log GPS tags for debugging
                                var tag5Hex = "0x" + tag5.toString(16).toUpperCase().padStart(4, '0')
                                if (e5 < 10) {
                                    console.log("🌍 GPS IFD tag", e5, ":", tag5Hex, "type:", type5, "count:", count5)
                                }
                                
                                // Read GPSLatitudeRef (0x0001) - ASCII string
                                if (tag5 === 0x0001 && type5 === 2 && count5 <= 2) {
                                    gpsLatitudeRef = String.fromCharCode(bytes[valueOffset5])
                                    console.log("🌍 Found GPSLatitudeRef:", gpsLatitudeRef)
                                }
                                // Read GPSLongitudeRef (0x0003) - ASCII string
                                else if (tag5 === 0x0003 && type5 === 2 && count5 <= 2) {
                                    gpsLongitudeRef = String.fromCharCode(bytes[valueOffset5])
                                    console.log("🌍 Found GPSLongitudeRef:", gpsLongitudeRef)
                                }
                                // Read GPSLatitude (0x0002) - Rational (3 values: degrees, minutes, seconds)
                                else if (tag5 === 0x0002 && type5 === 5 && count5 === 3) {
                                    var latOffset
                                    if (isIntel) {
                                        latOffset = bytes[valueOffset5] | (bytes[valueOffset5 + 1] << 8) | 
                                                   (bytes[valueOffset5 + 2] << 16) | (bytes[valueOffset5 + 3] << 24)
                                    } else {
                                        latOffset = (bytes[valueOffset5] << 24) | (bytes[valueOffset5 + 1] << 16) | 
                                                   (bytes[valueOffset5 + 2] << 8) | bytes[valueOffset5 + 3]
                                    }
                                    
                                    var latAddr = tiffOffset + latOffset
                                    if (latAddr + 24 <= bytes.length) {
                                        gpsLatitude = []
                                        for (var i = 0; i < 3; i++) {
                                            var latRationalAddr = latAddr + (i * 8)
                                            var latNum, latDen
                                            if (isIntel) {
                                                latNum = bytes[latRationalAddr] | (bytes[latRationalAddr + 1] << 8) | 
                                                         (bytes[latRationalAddr + 2] << 16) | (bytes[latRationalAddr + 3] << 24)
                                                latDen = bytes[latRationalAddr + 4] | (bytes[latRationalAddr + 5] << 8) | 
                                                         (bytes[latRationalAddr + 6] << 16) | (bytes[latRationalAddr + 7] << 24)
                                            } else {
                                                latNum = (bytes[latRationalAddr] << 24) | (bytes[latRationalAddr + 1] << 16) | 
                                                         (bytes[latRationalAddr + 2] << 8) | bytes[latRationalAddr + 3]
                                                latDen = (bytes[latRationalAddr + 4] << 24) | (bytes[latRationalAddr + 5] << 16) | 
                                                         (bytes[latRationalAddr + 6] << 8) | bytes[latRationalAddr + 7]
                                            }
                                            if (latDen > 0) {
                                                gpsLatitude.push(latNum / latDen)
                                            }
                                        }
                                        console.log("🌍 Found GPSLatitude:", gpsLatitude)
                                    }
                                }
                                // Read GPSLongitude (0x0004) - Rational (3 values: degrees, minutes, seconds)
                                else if (tag5 === 0x0004 && type5 === 5 && count5 === 3) {
                                    var lonOffset
                                    if (isIntel) {
                                        lonOffset = bytes[valueOffset5] | (bytes[valueOffset5 + 1] << 8) | 
                                                   (bytes[valueOffset5 + 2] << 16) | (bytes[valueOffset5 + 3] << 24)
                                    } else {
                                        lonOffset = (bytes[valueOffset5] << 24) | (bytes[valueOffset5 + 1] << 16) | 
                                                   (bytes[valueOffset5 + 2] << 8) | bytes[valueOffset5 + 3]
                                    }
                                    
                                    var lonAddr = tiffOffset + lonOffset
                                    if (lonAddr + 24 <= bytes.length) {
                                        gpsLongitude = []
                                        for (var j = 0; j < 3; j++) {
                                            var lonRationalAddr = lonAddr + (j * 8)
                                            var lonNum, lonDen
                                            if (isIntel) {
                                                lonNum = bytes[lonRationalAddr] | (bytes[lonRationalAddr + 1] << 8) | 
                                                         (bytes[lonRationalAddr + 2] << 16) | (bytes[lonRationalAddr + 3] << 24)
                                                lonDen = bytes[lonRationalAddr + 4] | (bytes[lonRationalAddr + 5] << 8) | 
                                                         (bytes[lonRationalAddr + 6] << 16) | (bytes[lonRationalAddr + 7] << 24)
                                            } else {
                                                lonNum = (bytes[lonRationalAddr] << 24) | (bytes[lonRationalAddr + 1] << 16) | 
                                                         (bytes[lonRationalAddr + 2] << 8) | bytes[lonRationalAddr + 3]
                                                lonDen = (bytes[lonRationalAddr + 4] << 24) | (bytes[lonRationalAddr + 5] << 16) | 
                                                         (bytes[lonRationalAddr + 6] << 8) | bytes[lonRationalAddr + 7]
                                            }
                                            if (lonDen > 0) {
                                                gpsLongitude.push(lonNum / lonDen)
                                            }
                                        }
                                        console.log("🌍 Found GPSLongitude:", gpsLongitude)
                                    }
                                }
                                
                                gpsEntryOffset += 12
                            }
                            
                            // Convert GPS coordinates to decimal degrees and store
                            if (gpsLatitude && gpsLatitude.length === 3 && gpsLongitude && gpsLongitude.length === 3) {
                                var latDecimal = gpsLatitude[0] + (gpsLatitude[1] / 60) + (gpsLatitude[2] / 3600)
                                var lonDecimal = gpsLongitude[0] + (gpsLongitude[1] / 60) + (gpsLongitude[2] / 3600)
                                
                                // Apply sign based on reference
                                if (gpsLatitudeRef === "S") latDecimal = -latDecimal
                                if (gpsLongitudeRef === "W") lonDecimal = -lonDecimal
                                
                                var exifData = currentExifData
                                exifData.latitude = latDecimal
                                exifData.longitude = lonDecimal
                                exifData.latitudeRef = gpsLatitudeRef
                                exifData.longitudeRef = gpsLongitudeRef
                                // Reset location info - will be filled by reverse geocoding
                                exifData.country = ""
                                exifData.city = ""
                                exifData.hasData = true
                                currentExifData = exifData
                                console.log("🌍 GPS coordinates:", latDecimal, lonDecimal)
                                
                                // Perform reverse geocoding to get country and city
                                // NOTE: The actual reverse geocoding call happens later in loadImageWithAuth
                                // after the image data URL is created, so we can wait for it before showing the image
                                console.log("🌍 GPS coordinates found, reverse geocoding will be done during preload")
                            }
                        } else {
                            console.log("🌍 GPS IFD found but address out of bounds")
                        }
                    } else {
                        console.log("🌍 No GPSInfo tag (0x8825) found in IFD0 - image has no GPS data")
                    }
                }
            } catch (e) {
                console.warn("❌ Error reading EXIF tags:", e)
            }
        }
        
        // Track active reverse geocoding requests to prevent too many simultaneous requests
        property var activeGeocodeRequests: []
        
        // Cache for reverse geocoding results to avoid repeated requests for same coordinates
        // Format: { "lat,lon": { country: "...", city: "...", timestamp: ... }, ... }
        // Limited to 50 entries to prevent memory issues (each entry ~100-200 bytes = ~5-10 KB total)
        property var geocodeCache: ({})
        property int maxGeocodeCacheSize: 50  // Conservative limit to prevent OOM (different from maxCacheSize for image cache)
        
        // Pending reverse geocoding callback - called when geocoding completes
        property var pendingGeocodeCallback: null
        
        // Reverse geocoding function to get country and city from GPS coordinates
        // Uses Nominatim (OpenStreetMap) free service
        // If callback is provided, it will be called when geocoding completes (or immediately if cached)
        // imageId: unique identifier for the image to prevent updating wrong image
        function reverseGeocode(lat, lon, callback, imageId) {
            if (lat === 0 && lon === 0) {
                // Call callback even when coordinates are 0,0 (no GPS data)
                if (callback && typeof callback === "function") {
                    callback(false, "", "")  // false = no GPS data, empty = no location
                }
                return
            }
            
            // Round coordinates to 6 decimal places for cache key (about 0.1 meters precision)
            // Increased precision to prevent different images with similar coordinates from sharing cache
            var cacheKey = Math.round(lat * 1000000) / 1000000 + "," + Math.round(lon * 1000000) / 1000000
            
            // Check cache first
            if (geocodeCache[cacheKey]) {
                var cached = geocodeCache[cacheKey]
                
                // Update timestamp for LRU (Least Recently Used) behavior
                cached.timestamp = Date.now()
                
                console.log("🌍 Using cached location for", lat, lon, "- Country:", cached.country, "City:", cached.city)
                
                // Verify image ID and coordinates still match before using cache
                // CRITICAL: imageId must match if provided (it's the most reliable check)
                var imageIdMatch = true
                if (imageId && imageId !== "") {
                    imageIdMatch = (currentImageId === imageId)
                    if (!imageIdMatch) {
                        console.log("🌍 Cache: Image ID mismatch - request:", imageId, "current:", currentImageId)
                    }
                }
                
                var coordsMatch = currentExifData && 
                    Math.abs((currentExifData.latitude || 0) - lat) < 0.0001 && 
                    Math.abs((currentExifData.longitude || 0) - lon) < 0.0001
                
                if (!coordsMatch) {
                    console.log("🌍 Cache: Coordinates mismatch - request:", lat, lon, "current:", currentExifData.latitude, currentExifData.longitude)
                }
                
                if (imageIdMatch && coordsMatch) {
                    console.log("🌍 ✅ Cache match verified - applying cached location")
                    // Create new object to force QML binding update
                    var exifData = {
                        orientation: currentExifData.orientation,
                        dateTime: currentExifData.dateTime,
                        make: currentExifData.make,
                        model: currentExifData.model,
                        iso: currentExifData.iso,
                        fNumber: currentExifData.fNumber,
                        exposureTime: currentExifData.exposureTime,
                        latitude: currentExifData.latitude,
                        longitude: currentExifData.longitude,
                        latitudeRef: currentExifData.latitudeRef,
                        longitudeRef: currentExifData.longitudeRef,
                        country: cached.country,
                        city: cached.city,
                        hasData: true
                    }
                    currentExifData = exifData
                    console.log("🌍 Cached location applied - Country:", cached.country, "City:", cached.city)
                    
                    // Call callback immediately if cached
                    if (callback && typeof callback === "function") {
                        callback(true, cached.country, cached.city)  // true = from cache
                    }
                } else {
                    if (!imageIdMatch) {
                        console.warn("⚠️  Cached location IGNORED - image changed (request ID:", imageId, "current ID:", currentImageId + ")")
                    } else {
                        console.warn("⚠️  Cached location IGNORED - coordinates changed (request:", lat, lon, "current:", currentExifData.latitude, currentExifData.longitude + ")")
                    }
                    if (callback && typeof callback === "function") {
                        callback(false, "", "")  // Image or coordinates changed, callback anyway
                    }
                }
                return
            }
            
            // Limit concurrent requests (Nominatim has rate limits)
            if (activeGeocodeRequests.length >= 3) {
                console.log("🌍 Reverse geocoding: too many active requests, skipping")
                // Call callback even when skipping to prevent hanging
                if (callback && typeof callback === "function") {
                    callback(false, "", "")  // false = skipped, empty = too many requests
                }
                return
            }
            
            // Store coordinates and image ID for verification when response arrives
            // This prevents overwriting data from a different image
            var requestLat = lat
            var requestLon = lon
            var requestImageId = imageId || ""  // Store image ID to verify it's still the current image
            var requestId = cacheKey  // Use cache key as request ID
            
            // Use Nominatim reverse geocoding API (free, no API key required)
            // Format: https://nominatim.openstreetmap.org/reverse?format=json&lat=LAT&lon=LON
            var url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=" + lat + "&lon=" + lon + "&zoom=10&addressdetails=1"
            
            // Track request start time for performance monitoring
            var requestStartTime = Date.now()
            console.log("🌍 Sending reverse geocoding request at", requestStartTime, "for", lat, lon)
            
            // Add request to active list
            activeGeocodeRequests.push(requestId)
            
            var xhr = new XMLHttpRequest()
            xhr.open("GET", url)
            xhr.setRequestHeader("User-Agent", "Nextcloud-Carousel/1.0")  // Nominatim requires User-Agent
            
            // Cleanup function to remove request from active list
            var cleanup = function() {
                var index = activeGeocodeRequests.indexOf(requestId)
                if (index !== -1) {
                    activeGeocodeRequests.splice(index, 1)
                }
            }
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            // Safety check: verify response exists and is not empty
                            if (!xhr.responseText || xhr.responseText.trim() === "") {
                                console.warn("❌ Reverse geocoding: empty response")
                                // Call callback with error
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = error
                                }
                                cleanup()
                                return
                            }
                            
                            // CRITICAL: Verify image ID and coordinates still match before updating
                            // This prevents overwriting data from a different image that loaded in the meantime
                            if (!currentExifData) {
                                console.warn("❌ Reverse geocoding: currentExifData is null")
                                // Call callback even if currentExifData is null
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = error
                                }
                                cleanup()
                                return
                            }
                            
                            // First check: verify image ID matches (most reliable check)
                            if (requestImageId && requestImageId !== "" && currentImageId !== requestImageId) {
                                console.log("🌍 Reverse geocoding response ignored - image changed (request ID:", requestImageId, "current ID:", currentImageId + ")")
                                // Call callback even if image changed
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = image changed
                                }
                                cleanup()
                                return
                            }
                            
                            var currentLat = currentExifData.latitude || 0
                            var currentLon = currentExifData.longitude || 0
                            
                            // Second check: verify coordinates match (with small tolerance for floating point)
                            var latMatch = Math.abs(currentLat - requestLat) < 0.0001
                            var lonMatch = Math.abs(currentLon - requestLon) < 0.0001
                            
                            if (!latMatch || !lonMatch) {
                                console.log("🌍 Reverse geocoding response ignored - coordinates changed (request:", requestLat, requestLon, "current:", currentLat, currentLon + ")")
                                // Call callback even if coordinates changed
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = coordinates changed
                                }
                                cleanup()
                                return
                            }
                            
                            // Parse JSON with error handling
                            var response
                            try {
                                response = JSON.parse(xhr.responseText)
                            } catch (parseError) {
                                console.warn("❌ Reverse geocoding: JSON parse error:", parseError, "Response:", xhr.responseText.substring(0, 200))
                                // Call callback with error
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = parse error
                                }
                                cleanup()
                                return
                            }
                            
                            if (!response) {
                                console.warn("❌ Reverse geocoding: parsed response is null")
                                // Call callback with error
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = null response
                                }
                                cleanup()
                                return
                            }
                            
                            if (response && response.address) {
                                var address = response.address
                                if (!address || typeof address !== "object") {
                                    console.warn("❌ Reverse geocoding: invalid address object")
                                    // Call callback with error
                                    if (callback && typeof callback === "function") {
                                        callback(false, "", "")  // false = from API, empty = invalid address
                                    }
                                    cleanup()
                                    return
                                }
                                
                                var country = (address.country && typeof address.country === "string") ? address.country : ""
                                var city = (address.city && typeof address.city === "string") ? address.city : 
                                          (address.town && typeof address.town === "string") ? address.town :
                                          (address.village && typeof address.village === "string") ? address.village :
                                          (address.municipality && typeof address.municipality === "string") ? address.municipality : ""
                                
                                var requestDuration = Date.now() - requestStartTime
                                console.log("🌍 Reverse geocoding result for", requestLat, requestLon, "- Country:", country, "City:", city, "- Duration:", requestDuration, "ms")
                                console.log("🌍 Verifying match - requestImageId:", requestImageId, "currentImageId:", currentImageId)
                                
                                // Double-check image ID and coordinates still match before updating
                                // CRITICAL: imageId must match if provided (it's the most reliable check)
                                var imageIdMatch = true
                                if (requestImageId && requestImageId !== "") {
                                    imageIdMatch = (currentImageId === requestImageId)
                                    if (!imageIdMatch) {
                                        console.log("🌍 Image ID mismatch - request:", requestImageId, "current:", currentImageId)
                                    }
                                }
                                
                                var coordsMatch = currentExifData && 
                                    Math.abs((currentExifData.latitude || 0) - requestLat) < 0.0001 && 
                                    Math.abs((currentExifData.longitude || 0) - requestLon) < 0.0001
                                
                                if (!coordsMatch) {
                                    console.log("🌍 Coordinates mismatch - request:", requestLat, requestLon, "current:", currentExifData.latitude, currentExifData.longitude)
                                }
                                
                                if (imageIdMatch && coordsMatch) {
                                    console.log("🌍 ✅ Match verified - updating location")
                                    // Store in cache for future use (with timestamp for potential TTL)
                                    geocodeCache[cacheKey] = {
                                        country: country,
                                        city: city,
                                        timestamp: Date.now()
                                    }
                                    
                                    // Limit cache size to prevent memory issues (FIFO eviction)
                                    // Each entry is small (~100-200 bytes), so 50 entries = ~5-10 KB total
                                    var cacheKeys = Object.keys(geocodeCache)
                                    if (cacheKeys.length > maxGeocodeCacheSize) {
                                        // Sort by timestamp (oldest first) and remove oldest entries
                                        var sortedKeys = cacheKeys.sort(function(a, b) {
                                            var timeA = geocodeCache[a].timestamp || 0
                                            var timeB = geocodeCache[b].timestamp || 0
                                            return timeA - timeB
                                        })
                                        
                                        var keysToRemove = sortedKeys.slice(0, sortedKeys.length - maxGeocodeCacheSize)
                                        for (var i = 0; i < keysToRemove.length; i++) {
                                            delete geocodeCache[keysToRemove[i]]
                                        }
                                        console.log("🌍 Cache cleanup: removed", keysToRemove.length, "old entries, cache size now:", Object.keys(geocodeCache).length)
                                    }
                                    
                                    // Log cache size periodically for monitoring
                                    if (cacheKeys.length % 10 === 0) {
                                        console.log("🌍 Cache size:", cacheKeys.length, "/", maxGeocodeCacheSize, "entries")
                                    }
                                    
                                    // Update currentExifData with location info
                                    // Create new object to force QML binding update
                                    var exifData = {
                                        orientation: currentExifData.orientation,
                                        dateTime: currentExifData.dateTime,
                                        make: currentExifData.make,
                                        model: currentExifData.model,
                                        iso: currentExifData.iso,
                                        fNumber: currentExifData.fNumber,
                                        exposureTime: currentExifData.exposureTime,
                                        latitude: currentExifData.latitude,
                                        longitude: currentExifData.longitude,
                                        latitudeRef: currentExifData.latitudeRef,
                                        longitudeRef: currentExifData.longitudeRef,
                                        country: country,
                                        city: city,
                                        hasData: true
                                    }
                                    currentExifData = exifData
                                    console.log("🌍 Location updated in currentExifData - Country:", country, "City:", city)
                                    
                                    // Call callback if provided
                                    if (callback && typeof callback === "function") {
                                        callback(false, country, city)  // false = from API
                                    }
                                } else {
                                    if (!imageIdMatch) {
                                        console.warn("⚠️  Reverse geocoding update SKIPPED - image changed (request ID:", requestImageId, "current ID:", currentImageId + ")")
                                    } else {
                                        console.warn("⚠️  Reverse geocoding update SKIPPED - coordinates changed (request:", requestLat, requestLon, "current:", currentExifData.latitude, currentExifData.longitude + ")")
                                    }
                                    if (callback && typeof callback === "function") {
                                        callback(false, "", "")  // Image or coordinates changed
                                    }
                                }
                            } else {
                                console.log("🌍 Reverse geocoding: no address in response")
                                // Call callback even if no address found
                                if (callback && typeof callback === "function") {
                                    callback(false, "", "")  // false = from API, empty = no address
                                }
                            }
                            cleanup()
                        } catch (e) {
                            console.warn("❌ Error in reverse geocoding callback:", e, e.stack)
                            cleanup()
                        }
                    } else {
                        console.warn("❌ Reverse geocoding failed with status:", xhr.status)
                        // Call callback with error even on failure
                        if (callback && typeof callback === "function") {
                            callback(false, "", "")  // false = from API, empty = error
                        }
                        cleanup()
                    }
                }
            }
            
            xhr.onerror = function() {
                console.warn("❌ Reverse geocoding network error")
                // Call callback with error
                if (callback && typeof callback === "function") {
                    callback(false, "", "")  // false = from API, empty = error
                }
                cleanup()
            }
            
            // Set timeout to avoid blocking (increased from 5s to 15s for Nominatim API)
            // Nominatim can be slow, especially with rate limits, so we need more time
            xhr.timeout = 15000  // 15 seconds timeout for reverse geocoding
            xhr.ontimeout = function() {
                console.warn("❌ Reverse geocoding timeout after 15 seconds")
                // Call callback with error
                if (callback && typeof callback === "function") {
                    callback(false, "", "")  // false = from API, empty = timeout
                }
                cleanup()
            }
            
            xhr.send()
        }
        
        function loadImageWithAuth(imageUrl, loadGen) {
            // Safety check
            if (!imageUrl) {
                console.error("❌ loadImageWithAuth: Invalid imageUrl")
                root.loading = false
                return
            }
            if (loadGen === undefined) {
                loadGen = carouselController.slideLoadGeneration
            }
            
            root.loading = true
            
            // Extract filename from URL for display in OSD
            var cleanUrlForName = imageUrl
            if (imageUrl.indexOf("@") !== -1) {
                var parts = imageUrl.split("@")
                if (parts.length > 1) {
                    cleanUrlForName = parts[1]
                    if (!cleanUrlForName.startsWith("http")) {
                        cleanUrlForName = "https://" + cleanUrlForName
                    }
                }
            }
            var fileName = cleanUrlForName.split("/").pop()
            if (fileName.indexOf("?") !== -1) {
                fileName = fileName.split("?")[0]
            }
            try {
                fileName = decodeURIComponent(fileName)
            } catch (e) {
                // If decoding fails, use as-is
            }
            // Set filename in separate property for reliable QML binding
            currentFileName = fileName
            
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
            
            // Livello 1: Try NextcloudDownloader (C++) - gestisce solo download e salva in file temporanei
            // Livello 2: Usa file locale con ottimizzazioni standard Plasma (sourceSize, cache: false, asynchronous: true)
            console.log("🔍 loadImage check: nextcloudDownloaderAvailable =", nextcloudDownloaderAvailable, ", nextcloudDownloader =", nextcloudDownloader, ", type =", typeof nextcloudDownloader)
            if (nextcloudDownloaderAvailable && nextcloudDownloader) {
                console.log("✅✅✅ Using C++ NextcloudDownloader for download")
                try {
                    // Calculate max size limit (same as QML fallback)
                    var configuredLimitMB = root.configuration.MaxImageSizeMB || 0
                    if (configuredLimitMB > 0) {
                        // User-configured explicit limit (MB)
                        var maxSizeMB = configuredLimitMB
                    } else {
                        // 0 = no limit
                        var maxSizeMB = 0
                    }
                    var localFilePath = nextcloudDownloader.downloadImage(cleanUrl, username, password, maxSizeMB)
                    if (localFilePath && localFilePath.length > 0) {
                        if (loadGen !== carouselController.slideLoadGeneration) {
                            root.loading = false
                            return
                        }
                        // NextcloudDownloader returned a local file path (cached or ready), use it immediately
                        root.currentImageMethod = "C++"  // Track method used
                        console.log("✅✅✅ METHOD: C++ - Using local file from NextcloudDownloader (cached):", localFilePath)
                        // Use local file with Plasma standard optimizations (Livello 2)
                        // Orientation will be read from EXIF in createImageComponentFromFile
                        carouselController.createImageComponentFromFile(localFilePath, imageUrl, undefined)
                        
                        // Update method indicator
                        if (root.configuration.ShowMethodIndicator) {
                            methodIndicator.opacity = 1.0
                            if (root.configuration.MethodIndicatorDuration > 0) {
                                methodIndicatorTimer.restart()
                            }
                        }
                        return
                    } else {
                        // NextcloudDownloader returned empty string (download in progress)
                        // Track this download so we can reload when imageDownloaded signal is received
                        if (!root.pendingDownloads) {
                            root.pendingDownloads = {}
                        }
                        root.pendingDownloads[cleanUrl] = { imageUrl: imageUrl, orientation: undefined, loadGen: loadGen }  // orientation from EXIF; loadGen avoids stale UI updates
                        root.currentImageMethod = "C++"  // Track method used
                        console.log("⏳ NextcloudDownloader: Download in progress, waiting for imageDownloaded signal for", cleanUrl)
                        return  // Exit - image will be loaded when signal is received
                    }
                } catch (e) {
                    console.warn("NextcloudDownloader error, falling back to QML:", e)
                    if (root.pendingDownloads && root.pendingDownloads[cleanUrl]) {
                        delete root.pendingDownloads[cleanUrl]  // Clear pending status
                    }
                    if (root.configuration.QmlDataUrlFallback === false) {
                        console.warn("QML Data URL fallback disabled — not retrying with Data URL after C++ error")
                        root.loading = false
                        if (carouselController.photoList.length > 1) {
                            carouselTimer.restart()
                        }
                        return
                    }
                }
            }
            
            if (root.configuration.QmlDataUrlFallback === false) {
                console.warn("QML Data URL fallback disabled: need C++ NextcloudDownloader for", cleanUrl.replace(/https?:\/\/[^@]+@?/, ""))
                root.loading = false
                if (carouselController.photoList.length > 1) {
                    carouselTimer.restart()
                }
                return
            }
            
            // Fallback to Data URL (used when NextcloudDownloader not available or download in progress)
            console.log("⚠️  METHOD: QML (fallback) - NextcloudDownloader not available or download in progress")
            // Check cache first
            var cachedDataUrl = getCachedDataUrl(imageUrl)
            if (cachedDataUrl) {
                if (loadGen !== carouselController.slideLoadGeneration) {
                    root.loading = false
                    return
                }
                // Removed verbose cache hit logging
                // Use cached data URL directly
                root.currentImageMethod = "QML"  // Track method used
                console.log("✅✅✅ METHOD: QML - Using cached Data URL")
                createImageComponent(cachedDataUrl, imageUrl, currentExifData.orientation)
                
                // Update method indicator
                if (root.configuration.ShowMethodIndicator) {
                    methodIndicator.opacity = 1.0
                    if (root.configuration.MethodIndicatorDuration > 0) {
                        methodIndicatorTimer.restart()
                    }
                }
                
                // Update OSD if EXIF info is enabled and we have filename or EXIF data
                if (root.configuration.ShowExifInfo && (currentFileName !== "" || currentExifData.hasData)) {
                    exifOsd.opacity = 1.0
                    if (root.configuration.ExifInfoDuration > 0) {
                        exifHideTimer.restart()
                    }
                }
                return
            }
            
            // Reduced logging verbosity - only log errors, not every download
            
            var xhr = new XMLHttpRequest()
            xhr.open("GET", cleanUrl, true, username, password)
            xhr.responseType = "arraybuffer"
            xhr.timeout = 60000  // 60 seconds timeout for image download (images can be large)
            
            xhr.ontimeout = function() {
                if (loadGen !== carouselController.slideLoadGeneration) {
                    return
                }
                console.error("⏱️  Image download timed out after 60 seconds:", cleanUrl.replace(/https?:\/\/[^@]+@/, ""))
                console.error("This may indicate network issues or a very large image file")
                root.loading = false
                // Try next image if available
                if (photoList.length > 1) {
                    console.log("Skipping timed out image, trying next...")
                    carouselTimer.restart()
                }
            }
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (loadGen !== carouselController.slideLoadGeneration) {
                        root.loading = false
                        return
                    }
                    if (xhr.status === 200) {
                        // Removed verbose download logging to prevent log bloat
                        
                        // Extract filename from URL for display in OSD
                        var fileName = cleanUrl.split("/").pop()
                        // Remove query parameters if any
                        if (fileName.indexOf("?") !== -1) {
                            fileName = fileName.split("?")[0]
                        }
                        // Decode URL encoding
                        try {
                            fileName = decodeURIComponent(fileName)
                        } catch (e) {
                            // If decoding fails, use as-is
                        }
                        // Set filename in separate property for reliable QML binding
                        currentFileName = fileName
                        
                        // Detect MIME type from magic bytes (more reliable than file extension)
                        // Some files have wrong extensions (e.g., .png files that are actually JPEG)
                        var mimeType = "image/jpeg"  // Default
                        var bytes = new Uint8Array(xhr.response)
                        if (bytes.length >= 4) {
                            // Check magic bytes to determine actual file type
                            if (bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
                                // JPEG: starts with 0xFFD8FF
                                mimeType = "image/jpeg"
                            } else if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) {
                                // PNG: starts with 0x89504E47 (PNG signature)
                                mimeType = "image/png"
                            } else if (bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46) {
                                // GIF: starts with GIF
                                mimeType = "image/gif"
                            } else if ((bytes[0] === 0x49 && bytes[1] === 0x49 && bytes[2] === 0x2A && bytes[3] === 0x00) ||
                                       (bytes[0] === 0x4D && bytes[1] === 0x4D && bytes[2] === 0x00 && bytes[3] === 0x2A)) {
                                // TIFF: Intel (0x49492A00) or Motorola (0x4D4D002A)
                                mimeType = "image/tiff"
                            } else if (bytes.length >= 12 && bytes[0] === 0x52 && bytes[1] === 0x49 && 
                                       bytes[2] === 0x46 && bytes[3] === 0x46 && bytes[8] === 0x57 && 
                                       bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50) {
                                // WebP: starts with RIFF...WEBP
                                mimeType = "image/webp"
                            } else {
                                // Fallback to extension-based detection if magic bytes don't match
                                if (cleanUrl.toLowerCase().indexOf(".png") !== -1) {
                                    mimeType = "image/png"
                                } else if (cleanUrl.toLowerCase().indexOf(".gif") !== -1) {
                                    mimeType = "image/gif"
                                } else if (cleanUrl.toLowerCase().indexOf(".webp") !== -1) {
                                    mimeType = "image/webp"
                                } else if (cleanUrl.toLowerCase().indexOf(".tif") !== -1) {
                                    mimeType = "image/tiff"
                                } else if (cleanUrl.toLowerCase().indexOf(".svg") !== -1) {
                                    mimeType = "image/svg+xml"
                                }
                            }
                        }
                        
                        // CRITICAL FIX: Check image size FIRST before processing EXIF
                        // This prevents downloading and processing very large images that will be skipped anyway
                        var imageSize = xhr.response.byteLength
                        var maxSize = carouselController.maxImageSizeForDataUrl

                        if (maxSize > 0 && imageSize > maxSize) {
                            console.warn("⚠️  Image too large for data URL conversion:", (imageSize / 1024 / 1024).toFixed(2), "MB (limit:", (maxSize / 1024 / 1024).toFixed(2), "MB)")
                            console.warn("⚠️  Skipping image to prevent OOM crash. Consider resizing images in Nextcloud.")
                            
                            // CRITICAL FIX: Clean up XHR and response data immediately to prevent memory corruption
                            // The XHR has already downloaded the full image, so we need to release it explicitly
                            var tempXhr = xhr
                            xhr = null  // Release XHR reference
                            
                            // Force cleanup of response data with delayed GC hint
                            Qt.callLater(function() {
                                if (tempXhr && tempXhr.response) {
                                    // Clear response reference to help GC
                                    tempXhr.response = null
                                }
                                tempXhr = null
                            })
                            
                            root.loading = false
                            
                            // Try next image if available
                            if (photoList.length > 1) {
                                console.log("Skipping oversized image, trying next...")
                                carouselTimer.restart()
                            }
                            return
                        }
                        
                        // Read EXIF orientation before converting to base64
                        var orientation = 0
                        
                        // Read EXIF data for JPEG, TIFF, and WebP images
                        // EXIF is supported in JPEG (standard), TIFF (native), and WebP (can contain EXIF)
                        // Use magic bytes detection to ensure we read EXIF even if file extension is wrong
                        if (mimeType === "image/jpeg" || mimeType === "image/tiff" || mimeType === "image/webp") {
                            // CRITICAL: Reset GPS coordinates and location BEFORE reading EXIF to prevent showing data from previous image
                            // This ensures that if new image doesn't have GPS, coordinates are 0 and location is empty
                            // Create new object to force QML binding update
                            var exifDataReset = {
                                orientation: currentExifData.orientation,
                                dateTime: currentExifData.dateTime,
                                make: currentExifData.make,
                                model: currentExifData.model,
                                iso: currentExifData.iso,
                                fNumber: currentExifData.fNumber,
                                exposureTime: currentExifData.exposureTime,
                                latitude: 0,  // Reset GPS coordinates
                                longitude: 0,  // Reset GPS coordinates
                                latitudeRef: "",  // Reset GPS refs
                                longitudeRef: "",  // Reset GPS refs
                                country: "",  // Reset location
                                city: "",  // Reset location
                                hasData: currentExifData.hasData
                            }
                            currentExifData = exifDataReset
                            
                            orientation = readExifOrientation(xhr.response)
                            readExifTags(xhr.response)  // Read additional EXIF tags
                            
                            // Force update of currentExifData to trigger QML bindings
                            // QML doesn't always detect changes to nested object properties
                            var exifData = currentExifData
                            currentExifData = exifData
                            
                            // Ensure hasData is set if orientation was found
                            // This is important because readExifTags might not set hasData
                            // if it doesn't find the specific tags it's looking for
                            if (orientation !== 0 && !currentExifData.hasData) {
                                var exifData2 = currentExifData
                                exifData2.hasData = true
                                currentExifData = exifData2
                            }
                            
                            // Log EXIF data found for debugging (reduced verbosity for performance)
                            // Only log if EXIF info is enabled in settings to reduce log spam
                            if (root.configuration.ShowExifInfo) {
                                if (orientation !== 0) {
                                    console.log("EXIF orientation:", orientation, "degrees")
                                }
                                if (currentExifData.hasData) {
                                    console.log("📸 EXIF:", currentExifData.make, currentExifData.model)
                                }
                            }
                            
                            // Force a complete refresh of currentExifData to ensure QML bindings update
                            // Create a completely new object to force QML to detect the change
                            // CRITICAL: Always reset location here - it will be filled by reverse geocoding callback
                            // This prevents showing location from previous image even if GPS coordinates are similar
                            var finalExifData = {
                                orientation: currentExifData.orientation,
                                dateTime: currentExifData.dateTime,
                                make: currentExifData.make,
                                model: currentExifData.model,
                                iso: currentExifData.iso,
                                fNumber: currentExifData.fNumber,
                                exposureTime: currentExifData.exposureTime,
                                latitude: currentExifData.latitude,
                                longitude: currentExifData.longitude,
                                latitudeRef: currentExifData.latitudeRef,
                                longitudeRef: currentExifData.longitudeRef,
                                country: "",  // Always reset - will be filled by reverse geocoding
                                city: "",  // Always reset - will be filled by reverse geocoding
                                hasData: currentExifData.hasData
                            }
                            currentExifData = finalExifData
                            // Removed verbose EXIF logging to improve performance
                        }
                        
                        // Note: Image size check was moved BEFORE EXIF processing to prevent
                        // downloading and processing images that will be skipped anyway
                        
                        // Convert arraybuffer to base64 data URL
                        // IMPORTANT: pass the ArrayBuffer directly.
                        // Passing a Uint8Array here causes an additional full copy in arrayBufferToBase64()
                        // (new Uint8Array(uint8Array) copies), which can spike memory and trigger OOM.
                        var base64 = arrayBufferToBase64(xhr.response)
                        
                        // CRITICAL: Clear ArrayBuffer reference immediately after conversion
                        // This helps the GC release the original buffer sooner
                        var tempResponse = xhr.response
                        xhr = null  // Release XHR reference
                        
                        var dataUrl = "data:" + mimeType + ";base64," + base64
                        // Removed verbose logging of data URL to prevent log bloat (syslog/journal growth)
                        // Data URLs are very large (hundreds of KB to MB) and should not be logged
                        
                        // CRITICAL: Clear base64 string from memory immediately after creating data URL
                        // This helps prevent memory accumulation
                        // Use multiple assignments to force GC hint
                        base64 = ""
                        base64 = null
                        tempResponse = null
                        
                        // Cache data URL for future use (if not too large and cache is enabled)
                        // Note: Cache is currently disabled (maxCacheSize = 0) to prevent memory leaks
                        if (dataUrl && dataUrl.length > 0 && carouselController.maxCacheSize > 0) {
                            cacheDataUrl(imageUrl, dataUrl)
                        }

                        // Create image component with data URL
                        // Note: Reverse geocoding is asynchronous and will update location when it arrives
                        // If location is in cache, it will be available immediately
                        root.currentImageMethod = "QML"  // Track method used (Data URL)
                        console.log("✅✅✅ METHOD: QML - Using downloaded Data URL (fallback)")
                        createImageComponent(dataUrl, imageUrl, orientation)
                        
                        // Update method indicator
                        if (root.configuration.ShowMethodIndicator) {
                            methodIndicator.opacity = 1.0
                            if (root.configuration.MethodIndicatorDuration > 0) {
                                methodIndicatorTimer.restart()
                            }
                        }
                        
                        // CRITICAL: Force immediate cleanup of data URL after use to free memory
                        // Use multiple delayed cleanups to force GC and memory release
                        var tempDataUrl = dataUrl
                        Qt.callLater(function() {
                            // First cleanup: clear reference
                            tempDataUrl = ""
                            tempDataUrl = null
                            // Second cleanup after short delay to allow GC
                            Qt.callLater(function() {
                                dataUrl = ""
                                dataUrl = null
                            })
                        })
                        
                        // Start reverse geocoding if we have GPS coordinates
                        // This is asynchronous - location will appear in OSD when response arrives
                        var hasGPS = currentExifData.latitude !== 0 && currentExifData.longitude !== 0
                        if (hasGPS) {
                            // Generate unique image ID from filename and coordinates to prevent location updates for wrong image
                            var imageId = currentFileName + "_" + currentExifData.latitude.toFixed(6) + "_" + currentExifData.longitude.toFixed(6)
                            currentImageId = imageId  // Store current image ID
                            
                            var geocodeStartTime = Date.now()
                            console.log("🌍 Starting reverse geocoding for coordinates:", currentExifData.latitude, currentExifData.longitude, "image ID:", imageId)
                            
                            // Start reverse geocoding (will use cache if available, otherwise async API call)
                            // Pass imageId to ensure location only updates for the correct image
                            reverseGeocode(currentExifData.latitude, currentExifData.longitude, function(fromCache, country, city) {
                                var duration = Date.now() - geocodeStartTime
                                console.log("🌍 Reverse geocoding completed in", duration, "ms (cached:", fromCache, ")")
                                // Location is already updated in currentExifData by reverseGeocode function
                                // OSD will be updated by the main Qt.callLater below
                            }, imageId)
                        } else {
                            // Reset image ID when no GPS data
                            currentImageId = ""
                        }
                        
                        // Update OSD if EXIF info is enabled and we have filename or EXIF data
                        if (root.configuration.ShowExifInfo && (currentFileName !== "" || currentExifData.hasData)) {
                            // Log what we're about to display
                            console.log("🖼️  Showing OSD - Make:", currentExifData.make, "Model:", currentExifData.model, 
                                      "ISO:", currentExifData.iso, "FNumber:", currentExifData.fNumber, 
                                      "ExposureTime:", currentExifData.exposureTime, "DateTime:", currentExifData.dateTime,
                                      "GPS:", currentExifData.latitude, currentExifData.longitude)
                            
                            // Force a final refresh of currentExifData to ensure QML bindings update
                            // This is called after reverse geocoding may have updated the location
                            // Use Qt.callLater to ensure it runs after any pending reverse geocoding updates
                            Qt.callLater(function() {
                                // Read current values (may have been updated by reverse geocoding)
                                // IMPORTANT: Only preserve location if GPS coordinates match (prevent stale location from previous image)
                                var hasGPS = currentExifData.latitude !== 0 && currentExifData.longitude !== 0
                                var finalExifData = {
                                    orientation: currentExifData.orientation,
                                    dateTime: currentExifData.dateTime,
                                    make: currentExifData.make,
                                    model: currentExifData.model,
                                    iso: currentExifData.iso,
                                    fNumber: currentExifData.fNumber,
                                    exposureTime: currentExifData.exposureTime,
                                    latitude: currentExifData.latitude,
                                    longitude: currentExifData.longitude,
                                    latitudeRef: currentExifData.latitudeRef,
                                    longitudeRef: currentExifData.longitudeRef,
                                    country: hasGPS ? (currentExifData.country || "") : "",  // Reset if no GPS
                                    city: hasGPS ? (currentExifData.city || "") : "",  // Reset if no GPS
                                    hasData: currentExifData.hasData
                                }
                                currentExifData = finalExifData
                                console.log("🔄 Final OSD refresh - Make:", finalExifData.make, "Model:", finalExifData.model, 
                                          "ISO:", finalExifData.iso, "FNumber:", finalExifData.fNumber, 
                                          "ExposureTime:", finalExifData.exposureTime, "GPS:", finalExifData.latitude, finalExifData.longitude,
                                          "Location:", finalExifData.city, finalExifData.country)
                            })
                            
                            exifOsd.opacity = 1.0
                            if (root.configuration.ExifInfoDuration > 0) {
                                exifHideTimer.restart()
                            }
                        }
                    } else {
                        console.error("Failed to load image. Status:", xhr.status, xhr.statusText)
                        if (xhr.status === 401) {
                            console.error("Authentication failed - check username and password")
                        } else if (xhr.status === 404) {
                            console.error("Image not found - check URL path")
                        } else if (xhr.status === 0) {
                            console.error("Network error - connection may be down")
                        }
                        root.loading = false
                        // Try next image if available (same behavior as timeout)
                        if (photoList.length > 1) {
                            console.log("Skipping failed image, trying next...")
                            carouselTimer.restart()
                        }
                    }
                }
            }
            
            xhr.onerror = function() {
                if (loadGen !== carouselController.slideLoadGeneration) {
                    return
                }
                console.error("Network error loading image (connection may be down):", cleanUrl.replace(/https?:\/\/[^@]+@/, ""))
                root.loading = false
                // Try next image if available (same behavior as timeout)
                if (photoList.length > 1) {
                    console.log("Skipping failed image, trying next...")
                    carouselTimer.restart()
                }
            }
            
            xhr.send()
        }
        
        // Create image component with data URL (extracted for reuse)
        // Livello 2: Crea componente immagine da file locale con ottimizzazioni standard Plasma
        // Usa le stesse ottimizzazioni dei plugin ufficiali: sourceSize, cache: false, asynchronous: true
        function createImageComponentFromFile(localFilePath, imageUrl, orientation) {
            // Single image host: destroy previous slide before showing the next (no dual StackView items)
            imageHost.destroyCurrentSlideImage()
            
            // CRITICAL: Read EXIF orientation from local file BEFORE creating image component
            // This ensures auto-rotation works correctly when using C++ component
            var imageOrientation = orientation !== undefined && orientation !== 0 ? orientation : 0
            
            // Function to create image component with orientation
            function createImageWithOrientation(orientationValue) {
                var component = imageHost.imageComponent
                if (component && component.status === Component.Ready) {
                // CRITICAL: Use Plasma standard optimizations (same as org.kde.image plugin)
                // sourceSize: limits decoded resolution to screen size + devicePixelRatio
                // This reduces memory usage by 50-75% without quality loss
                var screenWidth = imageHost.width || 1920
                var screenHeight = imageHost.height || 1080
                var devicePixelRatio = Screen.devicePixelRatio || 1.0
                var sourceSizeLimit = Qt.size(
                    Math.ceil(screenWidth * devicePixelRatio),
                    Math.ceil(screenHeight * devicePixelRatio)
                )
                
                imageHost.slideImageInstance = component.createObject(imageHost, {
                    "source": "file://" + localFilePath,  // Use file:// URL for local file
                    "fillMode": root.configuration.FillMode,
                    "color": root.configuration.Color,
                    "blur": root.configuration.Blur,
                    "blurOpacity": root.configuration.BlurOpacity,
                    "imageScale": root.configuration.ImageScale,
                    "orientation": imageOrientation,
                    "sourceSizeLimit": sourceSizeLimit,  // Plasma standard optimization
                    "width": imageHost.width,
                    "height": imageHost.height,
                    "x": 0,
                    "scale": 1.0
                })
                
                    if (imageHost.slideImageInstance) {
                        if (imageHost.slideImageInstance.statusChanged) {
                            imageHost.slideImageInstance.statusChanged.connect(imageHost.onSlideImageStatusChanged)
                        } else {
                            console.warn("statusChanged signal not available!")
                        }
                        imageHost.onSlideImageStatusChanged()
                    } else {
                        console.error("Failed to create image component from file:", component ? component.errorString() : "component is null")
                        root.loading = false
                    }
                } else {
                    console.error("Image component not ready:", component ? component.errorString() : "component is null")
                    root.loading = false
                }
            }
            
            // Read ALL EXIF data from local file using C++ component (more reliable than QML)
            // This ensures ShowExifInfo option works correctly when using C++ component
            console.log("🔍 Checking EXIF read: localFilePath =", localFilePath, ", nextcloudDownloaderAvailable =", nextcloudDownloaderAvailable, ", nextcloudDownloader =", nextcloudDownloader, ", getAllExifData =", nextcloudDownloader ? (typeof nextcloudDownloader.getAllExifData) : "N/A")
            if (localFilePath && nextcloudDownloaderAvailable && nextcloudDownloader && nextcloudDownloader.getAllExifData) {
                try {
                    console.log("🔍 Calling getAllExifData for:", localFilePath)
                    var allExifData = nextcloudDownloader.getAllExifData(localFilePath)
                    console.log("🔍 getAllExifData returned:", JSON.stringify(allExifData), ", type =", typeof allExifData, ", hasData =", allExifData ? (allExifData.hasData !== undefined ? allExifData.hasData : "undefined") : "null")
                    
                    // QVariantMap might need explicit property access
                    var hasData = false
                    if (allExifData) {
                        // Try different ways to access hasData (QVariantMap conversion can vary)
                        hasData = allExifData.hasData === true || allExifData["hasData"] === true || (allExifData.hasData !== undefined && allExifData.hasData !== false && allExifData.hasData !== 0)
                        console.log("🔍 hasData check:", hasData, ", allExifData.hasData =", allExifData.hasData, ", allExifData['hasData'] =", allExifData["hasData"])
                    }
                    
                    if (allExifData && hasData) {
                        console.log("✅ EXIF data found via C++:", allExifData)
                        
                        // Update currentExifData with all EXIF fields (matching QML structure)
                        // Use bracket notation for QVariantMap access (more reliable)
                        var exifData = {
                            orientation: (allExifData["orientation"] !== undefined ? allExifData["orientation"] : (allExifData.orientation || 0)),
                            dateTime: (allExifData["dateTime"] !== undefined ? String(allExifData["dateTime"]) : (allExifData.dateTime || "")),
                            make: (allExifData["make"] !== undefined ? String(allExifData["make"]) : (allExifData.make || "")),
                            model: (allExifData["model"] !== undefined ? String(allExifData["model"]) : (allExifData.model || "")),
                            iso: (allExifData["iso"] !== undefined ? allExifData["iso"] : (allExifData.iso || 0)),
                            fNumber: (allExifData["fNumber"] !== undefined ? allExifData["fNumber"] : (allExifData.fNumber || 0)),
                            exposureTime: (allExifData["exposureTime"] !== undefined ? String(allExifData["exposureTime"]) : (allExifData.exposureTime || "")),
                            latitude: (allExifData["latitude"] !== undefined ? allExifData["latitude"] : (allExifData.latitude || 0)),
                            longitude: (allExifData["longitude"] !== undefined ? allExifData["longitude"] : (allExifData.longitude || 0)),
                            latitudeRef: (allExifData["latitudeRef"] !== undefined ? String(allExifData["latitudeRef"]) : (allExifData.latitudeRef || "")),
                            longitudeRef: (allExifData["longitudeRef"] !== undefined ? String(allExifData["longitudeRef"]) : (allExifData.longitudeRef || "")),
                            country: "",  // Will be filled by reverse geocoding if GPS available
                            city: "",     // Will be filled by reverse geocoding if GPS available
                            hasData: true
                        }
                        console.log("🔍 Parsed EXIF data:", JSON.stringify(exifData))
                        currentExifData = exifData
                        
                        // Use orientation for image rotation
                        imageOrientation = exifData.orientation
                        
                        // Update OSD if EXIF info is enabled (same as QML fallback)
                        if (root.configuration.ShowExifInfo && (currentFileName !== "" || currentExifData.hasData)) {
                            console.log("🖼️  Showing OSD (C++) - Make:", currentExifData.make, "Model:", currentExifData.model, 
                                      "ISO:", currentExifData.iso, "FNumber:", currentExifData.fNumber, 
                                      "ExposureTime:", currentExifData.exposureTime, "DateTime:", currentExifData.dateTime,
                                      "GPS:", currentExifData.latitude, currentExifData.longitude)
                            exifOsd.opacity = 1.0
                            if (root.configuration.ExifInfoDuration > 0) {
                                exifHideTimer.restart()
                            }
                        }
                        
                        // If GPS coordinates are available, trigger reverse geocoding (same as QML)
                        if (exifData.latitude !== 0 && exifData.longitude !== 0) {
                            // Generate unique image ID from filename and coordinates to prevent location updates for wrong image
                            // Same logic as QML fallback to ensure consistency
                            var imageId = currentFileName + "_" + exifData.latitude.toFixed(6) + "_" + exifData.longitude.toFixed(6)
                            currentImageId = imageId  // Store current image ID
                            
                            var geocodeStartTime = Date.now()
                            console.log("🌍 Starting reverse geocoding (C++) for coordinates:", exifData.latitude, exifData.longitude, "image ID:", imageId)
                            
                            // Start reverse geocoding (will use cache if available, otherwise async API call)
                            // Pass imageId to ensure location only updates for the correct image (same as QML)
                            reverseGeocode(exifData.latitude, exifData.longitude, function(fromCache, country, city) {
                                var duration = Date.now() - geocodeStartTime
                                console.log("🌍 Reverse geocoding completed (C++) in", duration, "ms (cached:", fromCache, ")")
                                
                                var exifDataUpdate = currentExifData
                                exifDataUpdate.country = country || ""
                                exifDataUpdate.city = city || ""
                                currentExifData = exifDataUpdate
                                
                                // Update OSD again after reverse geocoding (location might have changed)
                                if (root.configuration.ShowExifInfo && currentExifData.hasData) {
                                    exifOsd.opacity = 1.0
                                    if (root.configuration.ExifInfoDuration > 0) {
                                        exifHideTimer.restart()
                                    }
                                }
                            }, imageId)  // Pass imageId to ensure location only updates for correct image
                        } else {
                            // Reset image ID when no GPS data
                            currentImageId = ""
                        }
                    } else {
                        console.log("ℹ️  No EXIF data found (normal orientation)")
                        // Reset EXIF data
                        currentExifData = {
                            orientation: 0,
                            dateTime: "",
                            make: "",
                            model: "",
                            iso: 0,
                            fNumber: 0,
                            exposureTime: "",
                            latitude: 0,
                            longitude: 0,
                            latitudeRef: "",
                            longitudeRef: "",
                            country: "",
                            city: "",
                            hasData: false
                        }
                    }
                } catch (e) {
                    console.warn("⚠️  Error reading EXIF data via C++:", e)
                }
            }
            
            // Now create image component with the correct orientation
            createImageWithOrientation(imageOrientation)
        }
        
        function createImageComponent(dataUrl, imageUrl, orientation) {
            // Removed data URL length logging to prevent log bloat
            
        // CRITICAL: Validate data URL size before creating component
        // This prevents memory exhaustion from extremely large data URLs
        // NOTE: With sourceSize limit, we can allow larger original images because
        // the decoded resolution is limited, reducing memory usage by 50-75%
        // However, the Data URL itself still consumes memory, so we keep a limit
        var effectiveLimit = carouselController.maxImageSizeForDataUrl
        
        // With sourceSize, the decoded image memory is limited, but the Data URL
        // (base64 string) still uses memory. We can be slightly more lenient
        // because the decoded image won't use as much memory.
        // Increase limit by 30% when sourceSize is used (screen resolution is known)
        var screenWidth = imageHost.width || 0
        var screenHeight = imageHost.height || 0
        if (effectiveLimit > 0 && screenWidth > 0 && screenHeight > 0) {
            // sourceSize will be used, so we can allow slightly larger Data URLs
            effectiveLimit = effectiveLimit * 1.3  // +30% because decoded size is limited
        }
        
        if (effectiveLimit > 0 && dataUrl && dataUrl.length > effectiveLimit * 1.4) {
            // Data URL is ~1.3x larger than original (base64 encoding)
            // If it exceeds our limit, skip it
            console.error("⚠️  Data URL too large:", (dataUrl.length / 1024 / 1024).toFixed(2), "MB (limit:", (effectiveLimit / 1024 / 1024).toFixed(2), "MB) - skipping to prevent OOM")
            root.loading = false
            if (photoList.length > 1) {
                console.log("Skipping oversized data URL, trying next image...")
                carouselTimer.restart()
            }
            return
        }
            
            imageHost.destroyCurrentSlideImage()
            
            var component = imageHost.imageComponent
            if (component && component.status === Component.Ready) {
                var imageOrientation = orientation !== undefined ? orientation : 0
                
                // CRITICAL FIX: Calculate sourceSize limit based on screen resolution (Qt official best practice)
                // This limits the decoded image resolution, reducing memory usage by 50-75%
                // Formula: screen resolution + 20% margin for quality (handles scaling and rotation)
                var screenWidth = imageHost.width || 1920  // Fallback to 1920 if not available
                var screenHeight = imageHost.height || 1080  // Fallback to 1080 if not available
                // Add 20% margin for quality (handles imageScale > 100%, rotations, and high-DPI displays)
                var maxWidth = Math.ceil(screenWidth * 1.2)
                var maxHeight = Math.ceil(screenHeight * 1.2)
                var sourceSizeLimit = Qt.size(maxWidth, maxHeight)
                
                imageHost.slideImageInstance = component.createObject(imageHost, {
                    "source": dataUrl,
                    "fillMode": root.configuration.FillMode,
                    "color": root.configuration.Color,
                    "blur": root.configuration.Blur,
                    "blurOpacity": root.configuration.BlurOpacity,
                    "imageScale": root.configuration.ImageScale,
                    "orientation": imageOrientation,
                    "sourceSizeLimit": sourceSizeLimit,  // NEW: Limit decoded resolution
                    "width": imageHost.width,
                    "height": imageHost.height,
                    "x": 0,
                    "scale": 1.0
                })
                
                if (imageHost.slideImageInstance) {
                    if (imageHost.slideImageInstance.statusChanged) {
                        imageHost.slideImageInstance.statusChanged.connect(imageHost.onSlideImageStatusChanged)
                    } else {
                        console.warn("statusChanged signal not available!")
                    }
                    imageHost.onSlideImageStatusChanged()
                } else {
                    console.error("Failed to create image component:", component ? component.errorString() : "component is null")
                    root.loading = false
                }
                } else {
                    console.error("Image component not ready. Status:", component ? component.status : "null", "Error:", component ? component.errorString() : "component is null")
                    // Fallback: try to create component on the fly
                    if (!component || component.status === Component.Error) {
                        imageHost.imageComponent = Qt.createComponent("ImageComponent.qml", imageHost)
                    }
                    root.loading = false
                }
        }
    }
    
    Timer {
        id: carouselTimer
        interval: root.configuration.SlideInterval * 1000
        running: carouselController.initialized && carouselController.photoList.length > 0
        repeat: true
        onTriggered: carouselController.nextPhoto()
    }
    
    // Retry timer for PROPFIND with exponential backoff
    Timer {
        id: retryTimer
        repeat: false
        onTriggered: {
            carouselController.loadPhotos()
        }
    }
    
    // Periodic cache cleanup timer (every 30 minutes)
    // Prevents cache from growing indefinitely and helps with memory management
    Timer {
        id: cacheCleanupTimer
        interval: 30 * 60 * 1000  // 30 minutes
        running: true
        repeat: true
        onTriggered: {
            var cacheKeys = Object.keys(carouselController.geocodeCache)
            var now = Date.now()
            var maxAge = 24 * 60 * 60 * 1000  // 24 hours TTL
            var cleaned = 0
            
            for (var i = 0; i < cacheKeys.length; i++) {
                var key = cacheKeys[i]
                var entry = carouselController.geocodeCache[key]
                if (entry && entry.timestamp) {
                    var age = now - entry.timestamp
                    if (age > maxAge) {
                        delete carouselController.geocodeCache[key]
                        cleaned++
                    }
                }
            }
            
            if (cleaned > 0) {
                console.log("🌍 Periodic cache cleanup: removed", cleaned, "expired entries")
            }
            
            // Also enforce size limit
            var remainingKeys = Object.keys(carouselController.geocodeCache)
            if (remainingKeys.length > carouselController.maxGeocodeCacheSize) {
                var sortedKeys = remainingKeys.sort(function(a, b) {
                    var timeA = carouselController.geocodeCache[a].timestamp || 0
                    var timeB = carouselController.geocodeCache[b].timestamp || 0
                    return timeA - timeB
                })
                
                var toRemove = sortedKeys.slice(0, sortedKeys.length - carouselController.maxGeocodeCacheSize)
                for (var j = 0; j < toRemove.length; j++) {
                    delete carouselController.geocodeCache[toRemove[j]]
                }
                console.log("🌍 Periodic cache cleanup: enforced size limit, removed", toRemove.length, "entries")
            }
        }
    }

    // Main image view (single slide surface, no transitions)
    Item {
        id: imageContainer
        anchors.fill: parent
        
        // Background color
        Rectangle {
            anchors.fill: parent
            color: root.configuration.Color
        }
        
        // Single image host: one ImageComponent child at a time (no StackView, no transitions)
        Item {
            id: imageHost
            anchors.fill: parent
            
            property Component imageComponent: null
            property Item slideImageInstance: null
            
            Component.onCompleted: {
                imageComponent = Qt.createComponent("ImageComponent.qml", imageHost)
                if (imageComponent.status === Component.Error) {
                    console.error("Failed to load ImageComponent:", imageComponent.errorString())
                } else if (imageComponent.status !== Component.Ready) {
                    imageComponent.statusChanged.connect(function() {
                        if (imageComponent.status === Component.Error) {
                            console.error("ImageComponent failed to load:", imageComponent.errorString())
                        }
                    })
                }
            }
            
            function destroyCurrentSlideImage() {
                if (slideImageInstance) {
                    if (slideImageInstance.statusChanged) {
                        slideImageInstance.statusChanged.disconnect(onSlideImageStatusChanged)
                    }
                    slideImageInstance.destroy()
                    slideImageInstance = null
                }
            }
            
            function onSlideImageStatusChanged() {
                if (!slideImageInstance) {
                    return
                }
                if (slideImageInstance.status === Image.Loading) {
                    return
                }
                slideImageInstance.statusChanged.disconnect(onSlideImageStatusChanged)
                root.loading = false
                if (slideImageInstance.status !== Image.Ready) {
                    console.warn("Image failed to load, status:", slideImageInstance.status)
                }
            }
        }
        
        // EXIF Information OSD (On-Screen Display)
        // Following Qt/KDE best practices for overlay components
        Rectangle {
            id: exifOsd
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: Kirigami.Units.gridUnit * 2
            }
            width: exifContent.implicitWidth + Kirigami.Units.gridUnit * 2
            height: exifContent.implicitHeight + Kirigami.Units.gridUnit * 2
            // Show OSD when ShowExifInfo is enabled AND we have EXIF data or filename AND opacity > 0
            // Using explicit binding to ensure visibility updates correctly
            visible: root.configuration.ShowExifInfo && 
                    (carouselController.currentExifData.hasData || 
                     carouselController.currentExifData.orientation !== 0 ||
                     carouselController.currentExifData.dateTime !== "" ||
                     carouselController.currentExifData.make !== "" ||
                     carouselController.currentExifData.model !== "" ||
                     carouselController.currentExifData.iso > 0 ||
                     carouselController.currentExifData.fNumber > 0 ||
                     carouselController.currentExifData.exposureTime !== "" ||
                     (carouselController.currentExifData.latitude !== 0 && carouselController.currentExifData.longitude !== 0) ||
                     carouselController.currentFileName !== "") && 
                    opacity > 0
            opacity: 0
            color: Qt.rgba(0, 0, 0, 0.75)  // Semi-transparent black background
            radius: Kirigami.Units.smallSpacing
            border {
                width: 1
                color: Qt.rgba(1, 1, 1, 0.3)
            }
            
            // Fade in animation when EXIF data changes
            Behavior on opacity {
                OpacityAnimator {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            
            Column {
                id: exifContent
                anchors {
                    fill: parent
                    margins: Kirigami.Units.smallSpacing
                }
                spacing: Kirigami.Units.smallSpacing
                
                // Title
                Text {
                    text: i18n("EXIF Information")
                    font {
                        bold: true
                        pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                    }
                    color: "white"
                }
                
                // Filename - Always show if available
                Text {
                    id: fileNameText
                    visible: carouselController.currentFileName !== ""
                    text: carouselController.currentFileName !== "" ? 
                          i18n("File: %1", carouselController.currentFileName) : ""
                    font {
                        bold: true
                        pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.95
                    }
                    color: "white"
                    elide: Text.ElideMiddle  // Truncate long filenames with "..."
                    maximumLineCount: 1
                }
                
                // Date/Time
                Text {
                    visible: carouselController.currentExifData.dateTime !== ""
                    text: i18n("Date: %1", carouselController.currentExifData.dateTime)
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
                
                // Camera Make/Model
                Text {
                    visible: carouselController.currentExifData.make !== "" || carouselController.currentExifData.model !== ""
                    text: {
                        var camera = ""
                        if (carouselController.currentExifData.make !== "") {
                            camera = carouselController.currentExifData.make
                        }
                        if (carouselController.currentExifData.model !== "") {
                            if (camera !== "") camera += " "
                            camera += carouselController.currentExifData.model
                        }
                        return i18n("Camera: %1", camera)
                    }
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
                
                // ISO
                Text {
                    visible: carouselController.currentExifData.iso > 0
                    text: i18n("ISO: %1", carouselController.currentExifData.iso)
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
                
                // Aperture (F-Number)
                Text {
                    visible: carouselController.currentExifData.fNumber > 0
                    text: i18n("Aperture: f/%1", carouselController.currentExifData.fNumber.toFixed(1))
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
                
                // Exposure Time
                Text {
                    visible: carouselController.currentExifData.exposureTime !== ""
                    text: i18n("Exposure: %1", carouselController.currentExifData.exposureTime)
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
                
                // GPS Coordinates and Location
                Text {
                    visible: carouselController.currentExifData.latitude !== 0 && carouselController.currentExifData.longitude !== 0
                    text: {
                        var lat = carouselController.currentExifData.latitude
                        var lon = carouselController.currentExifData.longitude
                        var latRef = carouselController.currentExifData.latitudeRef
                        var lonRef = carouselController.currentExifData.longitudeRef
                        var country = carouselController.currentExifData.country
                        var city = carouselController.currentExifData.city
                        
                        // Format: "37.5665° N, 126.9780° E" or "37.5665, 126.9780"
                        var latStr = Math.abs(lat).toFixed(4) + "°"
                        if (latRef !== "") latStr += " " + latRef
                        var lonStr = Math.abs(lon).toFixed(4) + "°"
                        if (lonRef !== "") lonStr += " " + lonRef
                        
                        // If we have country/city, show them, otherwise show coordinates
                        if (country !== "" || city !== "") {
                            var location = ""
                            if (city !== "") {
                                location = city
                                if (country !== "") location += ", " + country
                            } else if (country !== "") {
                                location = country
                            }
                            return i18n("Location: %1", location)
                        } else {
                            return i18n("Coordinates: %1, %2", latStr, lonStr)
                        }
                    }
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
                
                // GPS Coordinates (detailed) - show if location name is available
                Text {
                    visible: (carouselController.currentExifData.latitude !== 0 && carouselController.currentExifData.longitude !== 0) && 
                             (carouselController.currentExifData.country !== "" || carouselController.currentExifData.city !== "")
                    text: {
                        var lat = carouselController.currentExifData.latitude
                        var lon = carouselController.currentExifData.longitude
                        var latRef = carouselController.currentExifData.latitudeRef
                        var lonRef = carouselController.currentExifData.longitudeRef
                        
                        var latStr = Math.abs(lat).toFixed(4) + "°"
                        if (latRef !== "") latStr += " " + latRef
                        var lonStr = Math.abs(lon).toFixed(4) + "°"
                        if (lonRef !== "") lonStr += " " + lonRef
                        
                        return i18n("Coordinates: %1, %2", latStr, lonStr)
                    }
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                    color: "white"
                    opacity: 0.8
                }
                
                // Orientation
                Text {
                    visible: carouselController.currentExifData.orientation !== 0
                    text: {
                        var orient = carouselController.currentExifData.orientation
                        if (orient === 90) return i18n("Orientation: 90°")
                        else if (orient === -90) return i18n("Orientation: -90°")
                        else if (orient === 180) return i18n("Orientation: 180°")
                        else return i18n("Orientation: Normal")
                    }
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    color: "white"
                }
            }
            
            // Auto-hide timer
            Timer {
                id: exifHideTimer
                interval: (root.configuration.ExifInfoDuration || 5) * 1000
                onTriggered: {
                    if (root.configuration.ExifInfoDuration > 0) {
                        exifOsd.opacity = 0
                    }
                }
            }
            
        }
        
        // Method Indicator OSD (QML vs C++) - Shows processing method
        Rectangle {
            id: methodIndicator
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: methodIndicatorText.width + 20
            height: methodIndicatorText.height + 10
            radius: 5
            color: root.currentImageMethod === "C++" ? "#4CAF50" : "#2196F3"  // Green for C++, Blue for QML
            opacity: 0
            visible: root.configuration.ShowMethodIndicator && opacity > 0
            
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
            
            Text {
                id: methodIndicatorText
                anchors.centerIn: parent
                text: root.currentImageMethod === "C++" ? "C++" : "QML"
                font.pixelSize: 14
                font.bold: true
                color: "white"
            }
            
            // Auto-hide timer
            Timer {
                id: methodIndicatorTimer
                interval: (root.configuration.MethodIndicatorDuration || 3) * 1000
                onTriggered: {
                    if (root.configuration.MethodIndicatorDuration > 0) {
                        methodIndicator.opacity = 0
                    }
                }
            }
        }
        
        // Location OSD (Permanent overlay with script font)
        Text {
            id: locationOsd
            // Calculate position based on configuration
            // Use root.width/height instead of parent to ensure values are available
            x: {
                var pos = root.configuration.LocationOsdPosition || 1
                var offset = root.configuration.LocationOsdXOffset || 20
                if (pos === 0 || pos === 2) return offset  // Left
                if (pos === 1 || pos === 3) return root.width - width - offset  // Right
                if (pos === 4 || pos === 5) return (root.width - width) / 2 + offset  // Center (with offset)
                return offset
            }
            y: {
                var pos = root.configuration.LocationOsdPosition || 1
                var offset = root.configuration.LocationOsdYOffset || 20
                if (pos === 0 || pos === 1 || pos === 4) return offset  // Top
                if (pos === 2 || pos === 3 || pos === 5) return root.height - height - offset  // Bottom
                return offset
            }
            
            // Debug: log visibility state
            onVisibleChanged: {
                console.log("📍 Location OSD visible changed:", visible, "text:", text, "ShowLocationOsd:", root.configuration.ShowLocationOsd)
            }
            
            // Show only when enabled and location is available
            // Show if we have GPS coordinates and either country or city
            visible: {
                if (!root.configuration.ShowLocationOsd) return false
                var hasGPS = carouselController.currentExifData.latitude !== 0 && 
                            carouselController.currentExifData.longitude !== 0
                if (!hasGPS) return false
                var hasLocation = (carouselController.currentExifData.country !== "" || 
                                  carouselController.currentExifData.city !== "")
                return hasLocation
            }
            
            // Location text
            text: {
                var country = carouselController.currentExifData.country || ""
                var city = carouselController.currentExifData.city || ""
                var location = ""
                if (city !== "") {
                    location = city
                    if (country !== "") location += ", " + country
                } else if (country !== "") {
                    location = country
                }
                // Debug: log when text changes
                if (location !== "") {
                    console.log("📍 Location OSD text:", location)
                }
                return location
            }
            
            // Font styling with user-selectable font family
            font {
                pixelSize: root.configuration.LocationOsdFontSize || 24
                italic: true
                weight: Font.Light
                family: {
                    var fontFamily = root.configuration.LocationOsdFontFamily || ""
                    if (fontFamily === "" || fontFamily === "System Default") {
                        return Qt.application.font.family
                    }
                    return fontFamily
                }
            }
            
            // Styling with script font
            color: "white"
            style: Text.Outline
            styleColor: Qt.rgba(0, 0, 0, 0.8)  // Dark outline for better visibility
            opacity: 0.95
        }
        
        // Loading indicator
        Kirigami.LoadingPlaceholder {
            anchors.centerIn: parent
            visible: root.loading && root.configuration.ShowLoadingIndicator
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
            // Settings will be applied to next image via ImageComponent
        }
        function onBlurOpacityChanged() {
            // Settings will be applied to next image via ImageComponent
        }
        function onFillModeChanged() {
            // Settings will be applied to next image via ImageComponent
        }
        function onImageScaleChanged() {
            // Settings will be applied to next image via ImageComponent
        }
        function onShowExifInfoChanged() {
            // When ShowExifInfo is enabled, show OSD if we have any EXIF data
            // This works even if the option is enabled after image is already loaded
            if (root.configuration.ShowExifInfo) {
                // Force update of hasData by checking if we have any EXIF data or filename
                // Check if orientation is non-zero or any other EXIF field is set, or filename is available
                var hasAnyData = carouselController.currentExifData.orientation !== 0 ||
                                 carouselController.currentExifData.dateTime !== "" ||
                                 carouselController.currentExifData.make !== "" ||
                                 carouselController.currentExifData.model !== "" ||
                                 carouselController.currentExifData.iso > 0 ||
                                 carouselController.currentExifData.fNumber > 0 ||
                                 carouselController.currentExifData.exposureTime !== "" ||
                                 (carouselController.currentExifData.latitude !== 0 && carouselController.currentExifData.longitude !== 0) ||
                                 carouselController.currentFileName !== ""
                
                if (hasAnyData) {
                    // Ensure hasData is set correctly
                    if (!carouselController.currentExifData.hasData) {
                        carouselController.currentExifData.hasData = true
                    }
                    exifOsd.opacity = 1.0
                    if (root.configuration.ExifInfoDuration > 0) {
                        exifHideTimer.restart()
                    }
                } else {
                    exifOsd.opacity = 0
                }
            } else {
                exifOsd.opacity = 0
            }
        }
        function onExifInfoDurationChanged() {
            if (root.configuration.ExifInfoDuration > 0 && exifOsd.opacity > 0) {
                exifHideTimer.interval = root.configuration.ExifInfoDuration * 1000
                exifHideTimer.restart()
            }
        }
    }
}


