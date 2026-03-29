# Nextcloud Wallpaper Plugins - KDE Plasma 6

Two wallpaper plugins for KDE Plasma 6 that display media from your Nextcloud server:
- **Nextcloud Carousel**: Photo carousel from Nextcloud with automatic orientation correction
- **Nextcloud Video**: Video wallpaper with playback controls and automatic switching

> ⚠️ **WARNING**: This project is an **experiment** and is provided "as is" without warranties. Use it at your own risk.

## Features

### Nextcloud Carousel (Image Plugin)
- ✅ **Automatic photo carousel** from Nextcloud
- ✅ **Automatic EXIF orientation** correction
- ✅ **4 ordering modes**: Sequential, Random, Shuffle Once, Smart Random
- ✅ **Recursive subfolder support** (loads images from all subfolders)
- ✅ **Multiple image formats**: JPEG, PNG, WebP, GIF, BMP, SVG, TIFF
- ✅ **Configurable display settings**: Fill mode, scale, blur, background color
- ✅ **Loading indicator**: Show/hide option

### Nextcloud Video (Video Plugin)
- ✅ **Video wallpaper** from Nextcloud
- ✅ **Automatic video switching** with configurable interval
- ✅ **4 ordering modes**: Sequential, Random, Shuffle Once, Smart Random
- ✅ **Recursive subfolder support** (loads videos from all subfolders)
- ✅ **Multiple video formats**: MP4, WebM, OGG, MOV, AVI, MKV, M4V
- ✅ **Video loop control**: Loop each video or play once
- ✅ **Audio control**: Mute/unmute option
- ✅ **Configurable display settings**: Fill mode, scale, background color
- ✅ **Loading indicator**: Shows progress during video loading

### Common Features
- ✅ **WebDAV API integration** with Basic Authentication
- ✅ **Secure authentication** with app password support

## Requirements

- **KDE Plasma 6.x**
- **Qt 6.x**
- **Accessible Nextcloud server** with WebDAV enabled

## Installation

### Quick Install

```bash
./install.sh
```

The script will:
- Copy image plugin to `~/.local/share/plasma/wallpapers/org.nextcloud.carousel/`
- Copy video plugin to `~/.local/share/plasma/wallpapers/org.nextcloud.video/`
- Display instructions for configuration

### Manual Install

```bash
mkdir -p ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cp -r nextcloud-carousel/* ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/
killall plasmashell && kstart plasmashell
```

### After Installation

**Restart plasmashell** to load the plugin:
```bash
killall plasmashell && kstart plasmashell
```

**Note:** If the plugin doesn't appear after restart, you may need to **restart your Plasma session**:
- **Log out and log back in**, or
- **Restart your system**

## Configuration

### Basic Setup

#### For Image Carousel
1. **Right-click on desktop** → **Configure Desktop and Wallpaper**
2. Select **Nextcloud Carousel** from the wallpaper list
3. Click **Configure** and enter:
   - **Nextcloud URL**: Your server address (e.g., `https://nextcloud.example.com`)
   - **Username**: Your Nextcloud username
   - **Password**: Your password or app password (recommended for security)
   - **Photo Path**: Path to photos folder (default: `/Photos`)

#### For Video Wallpaper
1. **Right-click on desktop** → **Configure Desktop and Wallpaper**
2. Select **Nextcloud Video** from the wallpaper list
3. Click **Configure** and enter:
   - **Nextcloud URL**: Your server address (e.g., `https://nextcloud.example.com`)
   - **Username**: Your Nextcloud username
   - **Password**: Your password or app password (recommended for security)
   - **Video Path**: Path to videos folder (default: `/Videos`)

### Configuration Options

#### Nextcloud Settings
- **Nextcloud URL**: Server address without trailing slash
- **Username**: Your Nextcloud username
- **Password**: Main password or app password (recommended)
  - To create app password: Nextcloud → Settings → Security → App passwords
- **Photo Path** (Image Plugin): Folder path in Nextcloud (supports recursive subfolders)
  - Examples: `/Photos`, `/Pictures/Vacation`, `/Media/Images`
- **Video Path** (Video Plugin): Folder path in Nextcloud (supports recursive subfolders)
  - Examples: `/Videos`, `/Media/Videos`, `/Movies`

#### Image Carousel Settings
- **Slide Interval**: Time between image changes (seconds, recommended: 10-30)
- **Order Mode**: 
  - **Sequential**: Images in order
  - **Random**: Random order each time
  - **Shuffle Once**: Shuffled once, then sequential
  - **Smart Random**: Random but avoids recent repeats

#### Display Settings
- **Fill Mode**: How images fill the screen
  - **Stretch**: Fill entire screen (may distort)
  - **Fit**: Preserve aspect ratio, fit entire image
  - **Crop**: Preserve aspect ratio, crop to fill (recommended)
  - **Tile**: Repeat image to fill screen
  - **Tile Vertically**: Repeat vertically
  - **Tile Horizontally**: Repeat horizontally
- **Image Scale**: Zoom level (50-200%, default: 100%)
- **Blur Background**: Apply blur effect to images
- **Blur Opacity**: Blur intensity (0-100%, lower = more transparent)
- **Background Color**: Color shown when image doesn't fill screen
- **Loading Indicator**: Show/hide loading indicator when loading images

#### Video Wallpaper Settings
- **Video Interval**: Time between video switches (seconds, 5-300, default: 30)
- **Order Mode**: 
  - **Sequential**: Videos in order
  - **Random**: Random order each time
  - **Shuffle Once**: Shuffled once, then sequential
  - **Smart Random**: Random but avoids recent repeats
- **Loop Video**: Loop each video infinitely or play once
- **Mute Audio**: Mute video audio (recommended for wallpaper)
- **Fill Mode**: How videos fill the screen
  - **Stretch**: Fill entire screen (may distort)
  - **Fit**: Preserve aspect ratio, fit entire video
  - **Crop**: Preserve aspect ratio, crop to fill (recommended)
  - Note: Tile modes not supported for videos
- **Video Scale**: Zoom level (50-200%, default: 100%)
- **Background Color**: Color shown when video doesn't fill screen
- **Loading Indicator**: Shows progress during video loading

## Features Details

### Video Playback

The video plugin supports:
- **Automatic switching**: Videos change after the configured interval (when loop is disabled)
- **Loop control**: Each video can loop infinitely or play once
- **Audio control**: Videos are muted by default (can be enabled)
- **Smooth loading**: Loading indicator shows progress during video buffering
- **Error handling**: Automatically skips to next video on playback errors

### Automatic EXIF Orientation

The plugin automatically reads EXIF orientation data from JPEG images and rotates them correctly:
- Supports all standard EXIF orientation values (1, 3, 6, 8)
- Works with both Intel and Motorola byte order
- No manual rotation needed

### Image Loading

- Images are loaded via WebDAV API
- Supports recursive folder scanning (all subfolders)
- Multiple image formats supported
- Automatic format detection from file extension

## Troubleshooting

### Plugin Doesn't Appear in List

**Verify installation:**
```bash
./verify_plugin.sh
```

This script will:
- Verify plugin structure and files
- Fix permissions if needed
- Restart plasmashell automatically

**Manual steps:**
1. Verify installation: `ls ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/`
2. Check permissions: `chmod -R 755 ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/`
3. Restart plasmashell: `killall plasmashell && kstart plasmashell`

### "Configure" Button Doesn't Appear

- Apply the wallpaper first (select it from the list)
- Then reopen the configuration dialog

### Photos Don't Load

**Check configuration:**
- Verify Nextcloud URL (no trailing slash)
- Verify username and password (try app password)
- Verify photo path exists in Nextcloud
- Test WebDAV access in browser: `https://your-server.com/remote.php/dav/files/USERNAME/PATH`

**Check logs:**
```bash
journalctl --user -b | grep -i "nextcloud\|carousel"
```

**Common issues:**
- Wrong URL format (should be `https://example.com`, not `https://example.com/`)
- Incorrect photo path (must start with `/`)
- Network connectivity issues
- WebDAV not enabled on Nextcloud server

### Images Appear Rotated or Upside Down

- The plugin automatically corrects EXIF orientation
- If images are still rotated, the EXIF data might be missing or corrupted
- Try re-saving images in Nextcloud or using a different image viewer

### Reinstall Plugin

If you need to reinstall:
```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
./install.sh
killall plasmashell && kstart plasmashell
```

## Uninstallation

### Quick Uninstall

```bash
./uninstall.sh
```

### Manual Uninstall

```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
killall plasmashell && kstart plasmashell
```

**Note:** Configuration data in `~/.config/plasmarc` may remain. Remove manually if needed.

## Scripts

- **`install.sh`**: Install the plugin
- **`uninstall.sh`**: Remove the plugin
- **`verify_plugin.sh`**: Verify installation and fix common issues
- **`check_ubuntu_requirements.sh`**: Check system requirements for Ubuntu 25.04

## Important Notes

### Security
- **Password storage**: Passwords are stored in plain text in KDE configuration
- **Recommendation**: Use Nextcloud app passwords instead of main password
  - Create in: Nextcloud → Settings → Security → App passwords
  - App passwords can be revoked individually

### Performance
- Images are downloaded and converted to base64 data URLs
- Large images may take time to load
- Network speed affects loading time
- Consider image optimization in Nextcloud

### Limitations
- Blur effect is simplified (opacity reduction, not true blur)
- No local image caching (images downloaded each time)
- No offline support (requires network connection)
- Password stored in plain text (use app passwords)

## Technical Details

### Architecture
- **QML-based**: Uses Qt Quick and Kirigami components
- **WebDAV API**: Fetches images via Nextcloud WebDAV endpoint
- **StackView transitions**: Uses KDE official pattern for smooth animations
- **EXIF parsing**: Manual EXIF orientation reading from JPEG files

### File Structure
```
nextcloud-carousel/
├── metadata.json          # Plugin metadata
├── contents/
│   ├── config/
│   │   └── main.xml      # Configuration schema
│   ├── locale/
│   │   └── it/
│   │       └── LC_MESSAGES/
│   │           └── org.nextcloud.carousel.po  # Italian translations
│   └── ui/
│       ├── main.qml      # Main wallpaper display
│       ├── config.qml    # Configuration UI
│       └── ImageComponent.qml  # Image component for transitions
```

## License

GPL-2.0-or-later

## Credits

**Note**: This project was developed using AI-powered code editor.

---

For detailed development information, see [DEVELOPMENT.md](DEVELOPMENT.md)
