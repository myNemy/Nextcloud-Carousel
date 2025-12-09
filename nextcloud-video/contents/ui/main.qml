/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtMultimedia
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

WallpaperItem {
    id: root

    Component.onCompleted: {
        root.loading = true
        videoController.initialize()
    }

    // Video controller
    QtObject {
        id: videoController
        
        property var videoList: []
        property var usedIndices: []  // Track recently used indices to avoid repeats
        property var recentIndices: []  // Track recent indices for better randomization
        property int currentIndex: 0
        property bool initialized: false
        property int lastIndex: -1  // Track last shown index
        property int videoSwitchCount: 0  // Track number of video switches for periodic reset
        property bool isCleaningUp: false  // Track if aggressive cleanup is in progress
        
        function initialize() {
            if (root.configuration.NextcloudUrl === "" || 
                root.configuration.Username === "") {
                console.warn("Nextcloud URL or Username not configured")
                root.loading = false
                return
            }
            loadVideos()
        }
        
        function loadVideos() {
            console.log("Loading videos from Nextcloud:", root.configuration.NextcloudUrl)
            root.loading = true  // Show loading indicator during video list loading
            
            var baseUrl = root.configuration.NextcloudUrl
            if (baseUrl.endsWith("/")) {
                baseUrl = baseUrl.slice(0, -1)
            }
            
            var username = root.configuration.Username
            var password = root.configuration.Password
            var videoPath = root.configuration.VideoPath || "/Videos"
            
            if (!videoPath.startsWith("/")) {
                videoPath = "/" + videoPath
            }
            
            // Nextcloud WebDAV endpoint
            var webdavUrl = baseUrl + "/remote.php/dav/files/" + encodeURIComponent(username) + videoPath
            
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
            }
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 207 || xhr.status === 200) {
                        // Parse XML response using regex
                        var xmlText = xhr.responseText
                        var videos = []
                        
                        // Extract all href elements using regex
                        var hrefRegex = /<d:href>([^<]+)<\/d:href>/g
                        var match
                        var paths = []
                        
                        while ((match = hrefRegex.exec(xmlText)) !== null) {
                            var filePath = decodeURIComponent(match[1])
                            paths.push(filePath)
                        }
                        
                        // Process each path
                        // Pre-define video extensions outside loop for better performance
                        var videoExtensions = ["mp4", "webm", "ogg", "ogv", "mov", "avi", "mkv", "m4v"]
                        var davFilesPath = "/remote.php/dav/files/" + encodeURIComponent(username)
                        
                        for (var i = 0; i < paths.length; i++) {
                            var filePath = paths[i]
                            
                            // Skip the directory itself
                            if (filePath.endsWith(videoPath) || filePath.endsWith(videoPath + "/")) {
                                continue
                            }
                            
                            // Extract filename
                            var fileName = filePath.split("/").pop()
                            
                            // Skip if no filename (directory)
                            if (!fileName || fileName === "") {
                                continue
                            }
                            
                            // Check if it's a video file
                            var lastDotIndex = fileName.lastIndexOf(".")
                            if (lastDotIndex === -1) continue  // No extension
                            var ext = fileName.substring(lastDotIndex + 1).toLowerCase()
                            
                            if (videoExtensions.indexOf(ext) !== -1) {
                                // Build direct download URL
                                var relativePath = filePath
                                var davIndex = filePath.indexOf(davFilesPath)
                                if (davIndex !== -1) {
                                    relativePath = filePath.substring(davIndex + davFilesPath.length)
                                }
                                
                                var videoUrl = baseUrl + "/remote.php/dav/files/" + 
                                              encodeURIComponent(username) + relativePath
                                
                                // Store URL with auth info for MediaPlayer
                                // MediaPlayer supports Basic Auth in URL
                                // Handle both http:// and https:// protocols
                                var authUrl = videoUrl
                                if (videoUrl.startsWith("https://")) {
                                    authUrl = videoUrl.replace("https://", "https://" + 
                                                               encodeURIComponent(username) + ":" + 
                                                               encodeURIComponent(password) + "@")
                                } else if (videoUrl.startsWith("http://")) {
                                    authUrl = videoUrl.replace("http://", "http://" + 
                                                               encodeURIComponent(username) + ":" + 
                                                               encodeURIComponent(password) + "@")
                                }
                                
                                videos.push(authUrl)
                            }
                        }
                        
                        console.log("Found", videos.length, "videos")
                        if (videos.length > 0) {
                            console.log("First video URL:", videos[0].replace(/https?:\/\/[^@]+@/, ""))
                        } else {
                            console.warn("No videos found! XML response preview:", xmlText.substring(0, 500))
                        }
                        videoList = videos
                        
                        if (videoList.length > 0) {
                            // Reset switch counter when reloading video list
                            videoSwitchCount = 0
                            
                            // Handle different order modes
                            var orderMode = root.configuration.RandomOrder || 0
                            
                            if (orderMode === 1 || orderMode === 2) {
                                // Random or Shuffle once: shuffle the list
                                for (var j = videoList.length - 1; j > 0; j--) {
                                    var k = Math.floor(Math.random() * (j + 1))
                                    var temp = videoList[j]
                                    videoList[j] = videoList[k]
                                    videoList[k] = temp
                                }
                                currentIndex = 0
                            } else if (orderMode === 3) {
                                // Smart random: start with random index
                                currentIndex = Math.floor(Math.random() * videoList.length)
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
                            updateCurrentVideo()
                        } else {
                            console.warn("No videos found in", videoPath)
                            root.loading = false
                        }
                    } else {
                        console.error("Failed to load videos. Status:", xhr.status, xhr.statusText)
                        if (xhr.status === 401) {
                            console.error("Authentication failed - check username and password")
                        } else if (xhr.status === 404) {
                            console.error("Path not found - check Video Path setting")
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
            if (videoList.length === 0) return
            
            initialized = true
            root.loading = false
            
            // Start timer for video switching if LoopVideo is false
            if (!root.configuration.LoopVideo) {
                videoTimer.restart()
            }
        }
        
        function nextVideo() {
            if (videoList.length === 0) return
            
            var orderMode = root.configuration.RandomOrder || 0
            
            if (orderMode === 0) {
                // Sequential: next in order
                currentIndex = (currentIndex + 1) % videoList.length
            } else if (orderMode === 1) {
                // Random: avoid recent videos (last 3-5 depending on list size)
                var avoidCount = Math.min(Math.max(3, Math.floor(videoList.length * 0.3)), 5)
                var availableIndices = []
                
                // Build list of available indices excluding recent ones
                for (var i = 0; i < videoList.length; i++) {
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
                    for (var k = 0; k < videoList.length; k++) {
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
                currentIndex = (currentIndex + 1) % videoList.length
            } else if (orderMode === 3) {
                // Smart random: avoid showing same video consecutively and prefer unused videos
                var availableIndices = []
                
                // First, try to find videos not in recent list
                for (var i = 0; i < videoList.length; i++) {
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
                
                // If all videos are recent, use all except last one
                if (availableIndices.length === 0) {
                    for (var k = 0; k < videoList.length; k++) {
                        if (k !== lastIndex) {
                            availableIndices.push(k)
                        }
                    }
                }
                
                if (availableIndices.length === 0) {
                    availableIndices = [0]
                }
                
                var randomPos = Math.floor(Math.random() * availableIndices.length)
                currentIndex = availableIndices[randomPos]
                lastIndex = currentIndex
                
                // Track used indices (keep last 5)
                usedIndices.push(currentIndex)
                if (usedIndices.length > 5) {
                    usedIndices.shift()
                }
                
                // Track recent indices
                recentIndices.push(currentIndex)
                if (recentIndices.length > 10) {
                    recentIndices.shift()
                }
            }
            
            updateCurrentVideo()
        }
        
        function updateCurrentVideo() {
            if (currentIndex >= 0 && currentIndex < videoList.length) {
                var videoUrl = videoList[currentIndex]
                console.log("Loading video", currentIndex + 1, "of", videoList.length)
                console.log("Video URL (without auth):", videoUrl.replace(/https?:\/\/[^@]+@/, ""))
                
                // Increment switch counter for periodic reset
                videoSwitchCount++
                
                // Periodic aggressive cleanup every 5 videos to prevent memory accumulation
                var needsExtraCleanup = (videoSwitchCount >= 5)
                if (needsExtraCleanup) {
                    console.log("⚠️  Periodic reset: performing extra aggressive cleanup (video", videoSwitchCount, ")")
                    videoSwitchCount = 0
                    isCleaningUp = true
                    performAggressiveCleanup()
                    // Wait for cleanup to complete before loading new video
                    cleanupTimer.videoUrl = videoUrl
                    cleanupTimer.start()
                    return
                }
                
                // Normal cleanup: stop current video gently
                if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    mediaPlayer.pause()
                }
                mediaPlayer.stop()
                mediaPlayer.source = ""
                
                // Small delay to ensure cleanup, then load new video
                cleanupTimer.videoUrl = videoUrl
                cleanupTimer.start()
            }
        }
        
        function performAggressiveCleanup() {
            console.log("🔧 Performing aggressive MediaPlayer cleanup...")
            
            // Stop and clear completely
            if (mediaPlayer.playbackState !== MediaPlayer.StoppedState) {
                mediaPlayer.stop()
            }
            mediaPlayer.pause()
            mediaPlayer.source = ""
            
            // Disconnect VideoOutput to force memory release
            if (mediaPlayer.videoOutput === videoOutput) {
            mediaPlayer.videoOutput = null
            }
            
                console.log("✅ Aggressive cleanup completed")
        }
    }

    // Timer for video switching (only active when LoopVideo is false)
    Timer {
        id: videoTimer
        interval: (root.configuration.VideoInterval || 30) * 1000
        running: false
        repeat: false
        onTriggered: {
            if (!root.configuration.LoopVideo) {
                console.log("Video interval elapsed, switching to next video...")
                videoController.nextVideo()
            }
        }
    }
    
    // Timer for cleanup delay before loading new video
    Timer {
        id: cleanupTimer
        interval: 400  // Delay for cleanup and memory release
        running: false
        repeat: false
        property string videoUrl: ""
        
        onTriggered: {
            // Show loading indicator
            root.loading = true
            console.log("Loading new video...")
            
            // Reconnect VideoOutput if it was disconnected during aggressive cleanup
            if (mediaPlayer.videoOutput !== videoOutput) {
                mediaPlayer.videoOutput = videoOutput
            }
            
            // Load and play new video
            mediaPlayer.source = videoUrl
            mediaPlayer.play()
        }
    }
    
    // Timer to show cleanup feedback briefly
    Timer {
        id: cleanupFeedbackTimer
        interval: 1500  // Show feedback for 1.5 seconds
        running: false
        repeat: false
        onTriggered: {
            videoController.isCleaningUp = false
        }
    }

    // Background color
    Rectangle {
        anchors.fill: parent
        color: root.configuration.Color
        z: -1
    }

    // Video output
    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: {
            // VideoOutput only supports: Stretch, PreserveAspectFit, PreserveAspectCrop
            // Map FillMode values accordingly
            switch (root.configuration.FillMode) {
            case 0: return VideoOutput.Stretch
            case 1: return VideoOutput.PreserveAspectFit
            case 2: return VideoOutput.PreserveAspectCrop
            case 3: // Tile -> use PreserveAspectCrop
            case 4: // Tile Vertically -> use PreserveAspectFit
            case 5: // Tile Horizontally -> use PreserveAspectFit
            default: return VideoOutput.PreserveAspectCrop
            }
        }
        scale: (root.configuration.VideoScale || 100) / 100.0
        transformOrigin: Item.Center
    }

    // MediaPlayer for video playback
    MediaPlayer {
        id: mediaPlayer
        videoOutput: videoOutput
        audioOutput: AudioOutput {
            muted: root.configuration.MuteAudio !== false  // Default to muted
        }
        loops: root.configuration.LoopVideo ? MediaPlayer.Infinite : 1
        
        onPlaybackStateChanged: {
            console.log("MediaPlayer playback state changed:", playbackState)
            if (playbackState === MediaPlayer.PlayingState) {
                // Video started playing, hide loading indicator
                console.log("Video started playing, hiding loading indicator")
                root.loading = false
                videoController.isCleaningUp = false  // Clear cleanup flag when video starts
                
                // Start timer for next switch if LoopVideo is false
                if (!root.configuration.LoopVideo) {
                    videoTimer.restart()
                }
            } else if (playbackState === MediaPlayer.LoadingState) {
                console.log("Video is loading...")
                root.loading = true
            } else if (playbackState === MediaPlayer.StoppedState) {
                // Video finished - stop timer and switch if not looping
                videoTimer.stop()
                if (!root.configuration.LoopVideo) {
                    console.log("Video finished, switching to next...")
                    // Small delay to ensure video is fully stopped before switching
                    Qt.callLater(function() {
                videoController.nextVideo()
                    })
                }
            }
        }
        
        onMediaStatusChanged: {
            console.log("MediaPlayer status changed:", mediaStatus)
            if (mediaStatus === MediaPlayer.LoadedMedia) {
                console.log("Video media loaded successfully")
            } else if (mediaStatus === MediaPlayer.InvalidMedia) {
                console.error("Invalid media, trying next video")
                root.loading = false
                Qt.callLater(function() {
                    videoController.nextVideo()
                })
            }
        }
        
        onErrorOccurred: {
            console.error("MediaPlayer error:", error, errorString)
            // Try next video on error after a short delay
            Qt.callLater(function() {
                videoController.nextVideo()
            })
        }
    }

    // Loading indicator
    Item {
        anchors.fill: parent
        visible: root.loading
        z: 100
        
        // Semi-transparent overlay
        Rectangle {
            anchors.fill: parent
            color: root.configuration.Color
            opacity: 0.8
        }
        
        // Loading spinner and text
        Column {
            anchors.centerIn: parent
            spacing: 20
            
            Kirigami.LoadingPlaceholder {
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (videoController.isCleaningUp) {
                        return i18n("🔧 Optimizing memory...")
                    } else if (videoController.videoList.length === 0) {
                        return i18n("Loading videos from Nextcloud...")
                    } else if (videoController.currentIndex >= 0 && videoController.currentIndex < videoController.videoList.length) {
                        return i18n("Loading video %1 of %2...", videoController.currentIndex + 1, videoController.videoList.length)
                    } else {
                        return i18n("Loading video...")
                    }
                }
                color: "white"
                font.pixelSize: 16
            }
        }
    }

    // Connections for configuration changes
    Connections {
        target: root.configuration
        
        function onVideoIntervalChanged() {
            videoTimer.interval = (root.configuration.VideoInterval || 30) * 1000
            // Restart timer if video is currently playing
            if (!root.configuration.LoopVideo && mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                videoTimer.restart()
            }
        }
        
        function onLoopVideoChanged() {
            mediaPlayer.loops = root.configuration.LoopVideo ? MediaPlayer.Infinite : 1
            // Update timer based on loop setting
            if (root.configuration.LoopVideo) {
                videoTimer.stop()
            } else if (videoController.initialized && mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                videoTimer.restart()
            }
        }
        
        function onMuteAudioChanged() {
            mediaPlayer.audioOutput.muted = root.configuration.MuteAudio !== false
        }
        
        function onVideoPathChanged() {
            if (videoController.initialized) {
                videoController.initialize()
            }
        }
        
        function onNextcloudUrlChanged() {
            if (videoController.initialized) {
                videoController.initialize()
            }
        }
        
        function onUsernameChanged() {
            if (videoController.initialized) {
                videoController.initialize()
            }
        }
        
        function onPasswordChanged() {
            if (videoController.initialized) {
                videoController.initialize()
            }
        }
    }
}

