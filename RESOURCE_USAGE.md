# Resource Usage Analysis

## Current Resource Consumption

### System Overview
- **Total Memory**: 23.8 GB
- **Used Memory**: 7.2 GB
- **Available Memory**: 16 GB
- **Swap Usage**: 4.2 GB / 8.0 GB

### plasmashell Process (with plugins)
- **CPU Usage**: ~35-40% (during active playback)
- **Memory Usage**: ~690 MB (2.8% of total)
- **Virtual Memory**: ~5.4 GB
- **Resident Set Size (RSS)**: ~691 MB
- **Runtime**: ~10 minutes (at time of analysis)

## Observations

### Image Plugin (Nextcloud Carousel)
✅ **Good Memory Management:**
- Uses StackView with automatic cleanup via `onDeactivated` and `onRemoved` signals
- Old images are explicitly destroyed when replaced
- Base64 conversion happens in memory but is temporary (released after Image component loads)
- Image caching is enabled (`cache: true`) which helps performance

**Potential Optimizations:**
- Consider limiting the number of images loaded in memory at once
- Base64 conversion could be memory-intensive for large images
- Consider implementing image size limits or compression

### Video Plugin (Nextcloud Video)
⚠️ **Memory Considerations:**
- MediaPlayer handles video buffering internally
- No explicit cleanup of previous video buffers (relies on MediaPlayer)
- Video files are typically much larger than images
- Hardware acceleration errors observed: `Failed setup for format vulkan: hwaccel initialisation returned error`

**Potential Issues:**
- Video buffering can consume significant memory
- Multiple video switches without proper cleanup could accumulate memory
- Hardware acceleration fallback to software decoding increases CPU usage

**Recommendations:**
1. **Monitor memory growth** over extended periods (hours/days)
2. **Consider video preloading limits** - don't buffer too many videos ahead
3. **Implement explicit MediaPlayer cleanup** when switching videos
4. **Add video resolution/bitrate limits** in configuration
5. **Monitor for memory leaks** during long-running sessions

## Performance Metrics

### CPU Usage
- **Idle**: ~0-5% (when no transitions/playback)
- **Active**: ~35-40% (during video playback or image transitions)
- **Peak**: Can spike during:
  - Image transitions (especially Zoom with scaling)
  - Video decoding (especially without hardware acceleration)
  - WebDAV requests (PROPFIND, image downloads)

### Memory Usage
- **Base plasmashell**: ~200-300 MB (without plugins)
- **With Image Plugin**: +100-200 MB (depending on image count and size)
- **With Video Plugin**: +300-500 MB (depending on video resolution and buffering)

### Network Usage
- **PROPFIND requests**: Minimal (only when loading file lists)
- **Image downloads**: Varies by image size (typically 1-5 MB per image)
- **Video streaming**: Continuous during playback (varies by bitrate)

## Optimization Recommendations

### Short-term Improvements
1. **Add explicit MediaPlayer cleanup** in video plugin:
   ```qml
   function updateCurrentVideo() {
       // Stop and clear previous video
       if (mediaPlayer.playbackState !== MediaPlayer.StoppedState) {
           mediaPlayer.stop()
       }
       mediaPlayer.source = ""  // Clear source before loading new one
       // ... rest of function
   }
   ```

2. **Limit image list size** - don't load thousands of images at once
3. **Add configuration for max image/video count** in memory
4. **Implement image size limits** - skip or compress very large images

### Long-term Enhancements
1. **Local caching system** - cache downloaded images/videos locally
2. **Thumbnail generation** - use thumbnails for preview, full images only when needed
3. **Progressive loading** - load images in batches, not all at once
4. **Memory monitoring** - add optional memory usage reporting
5. **Video quality selection** - allow users to choose video quality/resolution

## Monitoring Commands

### Check Current Resource Usage
```bash
# CPU and Memory
ps aux | grep plasmashell

# Detailed memory breakdown
cat /proc/$(pgrep plasmashell)/status | grep -E "VmSize|VmRSS|VmData"

# Monitor over time
watch -n 1 'ps -p $(pgrep plasmashell) -o pid,pcpu,pmem,rss'
```

### Check for Memory Leaks
```bash
# Monitor memory growth over time
while true; do
    ps -p $(pgrep plasmashell) -o rss,etime
    sleep 60
done
```

### Check Video Decoding
```bash
# Monitor video-related errors
journalctl --user -f | grep -i "h264\|video\|mediaplayer"
```

## Known Issues

1. **Hardware Acceleration**: Vulkan hardware acceleration failing, falling back to software decoding
   - Impact: Higher CPU usage during video playback
   - Solution: Check GPU drivers and Qt Multimedia backend configuration

2. **Video Buffering**: No explicit limits on video buffer size
   - Impact: High memory usage with large/high-quality videos
   - Solution: Implement buffer size limits or quality selection

3. **Base64 Conversion**: Images converted to base64 in memory
   - Impact: Temporary memory spike during image loading
   - Solution: Consider streaming or chunked loading for large images

## Best Practices for Users

1. **Use appropriate image/video sizes** - don't use 4K videos or 50MB images
2. **Limit folder sizes** - avoid folders with thousands of files
3. **Use app passwords** - more secure and potentially more efficient
4. **Monitor system resources** - check memory/CPU usage periodically
5. **Restart plasmashell** if memory usage grows excessively over time

## Conclusion

The plugins are generally efficient, but video playback can be resource-intensive. The current implementation follows KDE best practices for memory management in the image plugin. The video plugin could benefit from explicit cleanup and buffer management.

**Current Status**: ✅ Acceptable for typical use cases
**Recommendation**: Monitor over extended periods and implement optimizations if memory leaks are detected.

