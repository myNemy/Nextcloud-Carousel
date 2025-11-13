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
            
            var propfindBody = '<?xml version="1.0"?>' +
                '<d:propfind xmlns:d="DAV:">' +
                '<d:prop><d:getcontenttype/></d:prop>' +
                '</d:propfind>'
            
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
                            var ext = fileName.split(".").pop().toLowerCase()
                            var videoExtensions = ["mp4", "webm", "ogg", "ogv", "mov", "avi", "mkv", "m4v"]
                            
                            if (videoExtensions.indexOf(ext) !== -1) {
                                // Build direct download URL
                                var relativePath = filePath
                                if (filePath.indexOf("/remote.php/dav/files/") !== -1) {
                                    relativePath = filePath.split("/remote.php/dav/files/" + encodeURIComponent(username))[1]
                                }
                                
                                var videoUrl = baseUrl + "/remote.php/dav/files/" + 
                                              encodeURIComponent(username) + relativePath
                                
                                // Store URL with auth info for MediaPlayer
                                // MediaPlayer supports Basic Auth in URL
                                var authUrl = videoUrl.replace("https://", "https://" + 
                                                               encodeURIComponent(username) + ":" + 
                                                               encodeURIComponent(password) + "@")
                                
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
                            } else {
                                // Sequential: start from beginning
                                currentIndex = 0
                            }
                            
                            lastIndex = -1
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
            
            // Start timer for video switching only if LoopVideo is false
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
                // Random: completely random each time
                var newIndex
                do {
                    newIndex = Math.floor(Math.random() * videoList.length)
                } while (newIndex === lastIndex && videoList.length > 1)
                currentIndex = newIndex
                lastIndex = newIndex
            } else if (orderMode === 2) {
                // Shuffle once: sequential through shuffled list
                currentIndex = (currentIndex + 1) % videoList.length
            } else if (orderMode === 3) {
                // Smart random: avoid showing same video consecutively
                var availableIndices = []
                for (var i = 0; i < videoList.length; i++) {
                    if (i !== lastIndex) {
                        availableIndices.push(i)
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
            }
            
            updateCurrentVideo()
        }
        
        function updateCurrentVideo() {
            if (currentIndex >= 0 && currentIndex < videoList.length) {
                var videoUrl = videoList[currentIndex]
                console.log("Loading video", currentIndex + 1, "of", videoList.length)
                console.log("Video URL (without auth):", videoUrl.replace(/https?:\/\/[^@]+@/, ""))
                
                // Stop current video if playing
                if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    mediaPlayer.stop()
                }
                
                // Show loading indicator
                root.loading = true
                console.log("Loading indicator shown, waiting for video to start playing...")
                
                // MediaPlayer supports Basic Auth in URL directly
                mediaPlayer.source = videoUrl
                mediaPlayer.play()
            }
        }
    }

    // Timer for video switching (only active when LoopVideo is false)
    Timer {
        id: videoTimer
        interval: (root.configuration.VideoInterval || 30) * 1000
        running: false
        repeat: true
        onTriggered: {
            if (!root.configuration.LoopVideo) {
                videoController.nextVideo()
            }
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
                
                // Start timer for next switch if LoopVideo is false
                if (!root.configuration.LoopVideo) {
                    videoTimer.restart()
                }
            } else if (playbackState === MediaPlayer.LoadingState) {
                console.log("Video is loading...")
                root.loading = true
            } else if (playbackState === MediaPlayer.StoppedState && !root.configuration.LoopVideo) {
                // Video finished, switch to next immediately
                videoController.nextVideo()
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
                    if (videoController.videoList.length === 0) {
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

