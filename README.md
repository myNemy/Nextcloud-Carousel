# Nextcloud Carousel - KDE Plasma 6 Wallpaper Plugin

A wallpaper plugin for KDE Plasma 6 that creates a photo carousel from your Nextcloud images with smooth transitions and automatic orientation correction.

> ⚠️ **WARNING**: This project is an **experiment** and is provided "as is" without warranties. Use it at your own risk.

## Features

- ✅ **Automatic photo carousel** from Nextcloud
- ✅ **Smooth animated transitions** (Fade, Slide, Zoom)
- ✅ **Automatic EXIF orientation** correction
- ✅ **4 ordering modes**: Sequential, Random, Shuffle Once, Smart Random
- ✅ **Recursive subfolder support** (loads images from all subfolders)
- ✅ **Multiple image formats**: JPEG, PNG, WebP, GIF, BMP, SVG, TIFF
- ✅ **WebDAV API integration** with Basic Authentication
- ✅ **Configurable display settings**: Fill mode, scale, blur, background color
- ✅ **Transition controls**: Enable/disable, randomize, duration control
- ✅ **Loading indicator**: Show/hide option

## Requirements

- **KDE Plasma 6.x**
- **Qt 6.x**
- **Accessible Nextcloud server** with WebDAV enabled
- **Network connection** to Nextcloud server

## Installation

### Quick Install

```bash
./install.sh
```

The script will:
- Copy plugin files to `~/.local/share/plasma/wallpapers/org.nextcloud.carousel/`
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

Or if `kstart` is not available:
```bash
killall plasmashell && plasmashell --replace &
```

## Configuration

### Basic Setup

1. **Right-click on desktop** → **Configure Desktop and Wallpaper**
2. Select **Nextcloud Carousel** from the wallpaper list
3. Click **Configure** and enter:
   - **Nextcloud URL**: Your server address (e.g., `https://nextcloud.example.com`)
   - **Username**: Your Nextcloud username
   - **Password**: Your password or app password (recommended for security)
   - **Photo Path**: Path to photos folder (default: `/Photos`)

### Configuration Options

#### Nextcloud Settings
- **Nextcloud URL**: Server address without trailing slash
- **Username**: Your Nextcloud username
- **Password**: Main password or app password (recommended)
  - To create app password: Nextcloud → Settings → Security → App passwords
- **Photo Path**: Folder path in Nextcloud (supports recursive subfolders)
  - Examples: `/Photos`, `/Pictures/Vacation`, `/Media/Images`

#### Carousel Settings
- **Slide Interval**: Time between image changes (seconds, recommended: 10-30)
- **Order Mode**: 
  - **Sequential**: Images in order
  - **Random**: Random order each time
  - **Shuffle Once**: Shuffled once, then sequential
  - **Smart Random**: Random but avoids recent repeats

#### Transition Settings
- **Transitions**: Enable/disable transitions between images
- **Transition Type**: 
  - **Fade**: Smooth fade in/out (recommended)
  - **Slide**: Horizontal slide animation
  - **Zoom**: Zoom in/out effect
- **Transition Duration**: Animation duration in milliseconds (100-10000, default: 1000)
- **Randomize Transition**: Randomly select transition type for each image

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

## Features Details

### Transitions

The plugin supports three transition types with smooth animations:

- **Fade**: Opacity animation (0→1 for new image, 1→0 for old image)
- **Slide**: Horizontal slide animation (new image slides in from right)
- **Zoom**: Scale animation (new image zooms in from 0.8 to 1.0)

Transitions can be:
- **Enabled/Disabled**: Toggle transitions on/off
- **Randomized**: Random transition type for each image
- **Customized**: Fixed transition type with adjustable duration

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

### Transitions Not Working

- Check that "Transitions" is enabled in configuration
- Verify transition duration is set (100-10000ms)
- Check logs for errors: `journalctl --user -b | grep -i "transition\|animation"`

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

For detailed development information, see [MILESTONE.md](MILESTONE.md)
