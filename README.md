# Nextcloud Carousel - KDE Plasma 6 Wallpaper Plugin

A wallpaper plugin for KDE Plasma 6 that creates a photo carousel from your Nextcloud images.

> ⚠️ **WARNING**: This project is an **experiment** and is provided "as is" without warranties. Use it at your own risk. It is not an official product and may contain bugs or unexpected behavior.

## 🚀 Quick Start

**After installation, to configure:**

1. **Right-click on desktop** → **Configure Desktop and Wallpaper**
2. Select **Nextcloud Carousel** from the wallpaper list
3. Click **Configure**
4. Enter Nextcloud URL, username, password, and photo path
5. Apply changes

See the [Configuration](#configuration) section for complete details.

## Requirements

- KDE Plasma 6.x
- Qt 6.x
- Accessible Nextcloud server

## Installation

### Method 1: Installation script (recommended)

```bash
./install.sh
```

### Method 2: Manual installation

```bash
mkdir -p ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cp -r nextcloud-carousel/* ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/
```

### Method 3: With CMake

```bash
mkdir build
cd build
cmake ..
make
sudo make install
```

## Configuration

### How to access configuration

There are several ways to configure the wallpaper:

#### Method 1: From Desktop (simplest)
1. **Right-click on desktop** → **Configure Desktop and Wallpaper**
2. In the window that opens, in the **Wallpaper** section
3. Select **Nextcloud Carousel** from the available wallpapers list
4. Click the **Configure** button at the bottom
5. The configuration window with all options will open

#### Method 2: From System Settings
1. Open **System Settings**
   - From the application menu, or
   - Press `Alt+F2` and type `systemsettings`
2. Go to **Appearance** → **Wallpaper**
3. Select **Nextcloud Carousel** from the list
4. Click **Configure**

#### Method 3: From KRunner
1. Press `Alt+F2` (or `Meta` + `R`)
2. Type: `systemsettings appearance` or `wallpaper`
3. Select the appropriate option and follow the steps above

### Plugin Configuration

Once the configuration window is open, enter:

**Nextcloud Configuration section:**
- **Nextcloud URL**: Your Nextcloud server address (e.g., `https://nextcloud.example.com`)
- **Username**: Your Nextcloud username
- **Password**: Your password or app password (recommended to use an app password)
- **Photo Path**: The path to the photos folder in Nextcloud (default: `/Photos`)

**Carousel Settings section:**
- Configure interval, transitions, etc. (see below)

**Display Settings section:**
- Configure display mode, blur, background color

## Configuration Options

### Nextcloud Configuration (Required)

- **Nextcloud URL**: Your Nextcloud server address (e.g., `https://nextcloud.example.com`)
  - Without trailing slash
- **Username**: Your Nextcloud username
- **Password**: Your password or app password (recommended to use an app password)
  - To create an app password: Nextcloud → Settings → Security → App password
- **Photo Path**: The path to the photos folder in Nextcloud
  - Default: `/Photos`
  - Examples: `/Photos/Vacation`, `/Pictures`
  - The plugin recursively reads subfolders as well

### Carousel Settings

- **Change every**: Interval between photo changes (in seconds)
  - Minimum: 1 second
  - Recommended: 10-30 seconds for a fast carousel
- **Transition Type**: Type of transition between photos
  - **Fade**: Fade (recommended)
  - **Slide**: Side scrolling
  - **Zoom**: Zoom effect
- **Transition Duration**: Transition animation duration (in milliseconds)
  - Default: 1000ms (1 second)
  - Range: 100-5000ms
- **Order Mode**: Photo ordering mode
  - **Sequential**: Sequential order (from first to last)
  - **Random (each time)**: Completely random each time
  - **Shuffle Once**: Shuffle once at the start, then sequential
  - **Smart Random**: Avoids showing the same image consecutively

### Display Settings

- **Fill Mode**: Image fill mode
  - **Stretch**: Stretch to fill entire screen (may distort)
  - **Fit**: Fit maintaining proportions (may leave borders)
  - **Crop**: Crop to fill (recommended, maintains proportions)
  - **Tile**: Repeat image as tiles
  - **Tile Vertically**: Vertical tiles
  - **Tile Horizontally**: Horizontal tiles
- **Blur background**: Apply blur effect to background (currently simplified)
- **Background Color**: Background color when image doesn't cover entire screen
  - Useful with Fill Mode "Fit"
  - Default: Black (#000000)

## Features

- ✅ Automatic photo carousel from Nextcloud
- ✅ Animated transitions between photos (Fade, Slide, Zoom)
- ✅ 4 ordering modes: Sequential, Random, Shuffle Once, Smart Random
- ✅ Recursive support for subfolders
- ✅ Complete configuration via graphical interface
- ✅ Support for various image formats (JPEG, PNG, WebP, GIF, BMP, SVG, TIFF)
- ✅ Image loading via WebDAV API
- ✅ Customizable background color configuration

## Development

### Project Structure

```
nextcloud-carousel/
├── metadata.json          # Plugin metadata
├── contents/
│   ├── config/
│   │   └── main.xml       # Configuration file
│   └── ui/
│       ├── main.qml       # Main wallpaper component
│       └── config.qml     # Configuration interface
```

### Notes for Developers

The plugin is based on the official KDE Plasma 6 documentation for wallpaper plugins. The structure follows the `Plasma/Wallpaper` KPackage standard.

**Future improvements:**

- [ ] Improved local image cache
- [ ] OAuth2 authentication support
- [ ] Automatic connection test
- [ ] Improved error handling with clearer messages
- [ ] Loading progress indicator

## Compatibility

- **Plasma**: 6.0+
- **Qt**: 6.0+
- **KF6**: Required

## License

GPL-2.0-or-later

## Uninstallation

### Method 1: Uninstallation script (recommended)

```bash
./uninstall.sh
```

### Method 2: Manual uninstallation

```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
killall plasmashell && plasmashell &
```

### Method 3: With kpackagetool6

```bash
kpackagetool6 --type=Plasma/Wallpaper --remove org.nextcloud.carousel
killall plasmashell && plasmashell &
```

## Troubleshooting

### Plugin doesn't appear in the list

1. Verify installation:
   ```bash
   ls ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
   ```

2. Restart plasmashell:
   ```bash
   killall plasmashell && plasmashell &
   ```

3. Or restart KDE session

### "Configure" button doesn't appear

1. **Apply wallpaper first**: Select "Nextcloud Carousel" and click "Apply" or "OK"
2. Reopen the configuration window - the "Configure" button should now appear
3. Restart plasmashell if necessary:
   ```bash
   killall plasmashell && plasmashell &
   ```

### Configuration doesn't open

1. Verify file permissions:
   ```bash
   chmod -R 755 ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
   ```

2. Check logs:
   ```bash
   journalctl -f | grep plasma
   ```

### Photos don't load

1. **Verify Nextcloud connection**:
   - Test the URL in browser
   - Verify username and password
   - Check that the photo path is correct

2. **Verify Nextcloud permissions**:
   - Ensure you have access to the photos folder
   - Check that photos are in supported formats (JPEG, PNG, WebP, etc.)

3. **Manual WebDAV test**:
   ```bash
   curl -u "USERNAME:PASSWORD" \
     -X PROPFIND \
     -H "Depth: infinity" \
     -H "Content-Type: application/xml" \
     -d '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:getcontenttype/></d:prop></d:propfind>' \
     "https://YOUR_SERVER/remote.php/dav/files/USERNAME/PATH"
   ```
   Replace `USERNAME`, `PASSWORD`, `YOUR_SERVER`, and `PATH` with your values.

4. **Check debug logs**:
   ```bash
   QT_LOGGING_RULES="qml.debug=true" plasmashell 2>&1 | grep -i "nextcloud\|image\|error"
   ```

### Plugin reinstallation

If you have persistent issues, try reinstalling:

```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cd /path/to/nextcloud-plasma-addon
./install.sh
killall plasmashell && plasmashell &
```

## Important Notes

- **Security**: The password is saved in plain text in the local configuration file. For better security, use an app password instead of the main password.
- **WebDAV**: The plugin loads photos via Nextcloud WebDAV API with Basic Auth authentication.
- **Cache**: Images are cached locally for better performance.
- **Subfolders**: The plugin recursively reads all images in subfolders of the specified folder.

## Support

For issues or questions, open an issue on the project repository.

## References

- [KDE Plasma Wallpaper Plugin Documentation](https://api.kde.org/frameworks/plasma-framework/html/)
- [KDE Plasma 6 Documentation](https://develop.kde.org/docs/)
- [Nextcloud WebDAV API](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html)

---

**Note**: This project was developed using [Cursor](https://cursor.sh), an AI-powered code editor.
