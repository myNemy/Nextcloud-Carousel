# Nextcloud Carousel - KDE Plasma 6 Wallpaper Plugin

A wallpaper plugin for KDE Plasma 6 that creates a photo carousel from your Nextcloud images.

> ⚠️ **WARNING**: This project is an **experiment** and is provided "as is" without warranties. Use it at your own risk.

## Requirements

- KDE Plasma 6.x
- Qt 6.x
- Accessible Nextcloud server

## Installation

**Recommended:**
```bash
./install.sh
```

**Manual:**
```bash
mkdir -p ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
cp -r nextcloud-carousel/* ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/
killall plasmashell && plasmashell &
```

## Configuration

1. Right-click on desktop → **Configure Desktop and Wallpaper**
2. Select **Nextcloud Carousel** from the wallpaper list
3. Click **Configure** and enter:
   - **Nextcloud URL**: Your server address (e.g., `https://nextcloud.example.com`)
   - **Username**: Your Nextcloud username
   - **Password**: Your password or app password (recommended)
   - **Photo Path**: Path to photos folder (default: `/Photos`)

### Configuration Options

**Nextcloud Configuration:**
- URL without trailing slash
- Use app password for better security (Settings → Security → App password)
- Photo path supports subfolders (recursive)

**Carousel Settings:**
- **Change every**: Interval in seconds (recommended: 10-30)
- **Transition Type**: Fade (recommended), Slide, or Zoom
- **Transition Duration**: 100-5000ms (default: 1000ms)
- **Order Mode**: Sequential, Random, Shuffle Once, or Smart Random

**Display Settings:**
- **Fill Mode**: Crop (recommended), Stretch, Fit, or Tile variants
- **Blur background**: Apply blur effect
- **Background Color**: Color when image doesn't fill screen

## Features

- ✅ Automatic photo carousel from Nextcloud
- ✅ Animated transitions (Fade, Slide, Zoom)
- ✅ 4 ordering modes
- ✅ Recursive subfolder support
- ✅ Multiple image formats (JPEG, PNG, WebP, GIF, BMP, SVG, TIFF)
- ✅ WebDAV API integration

## Uninstallation

```bash
./uninstall.sh
```

Or manually:
```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
killall plasmashell && plasmashell &
```

## Troubleshooting

**Plugin doesn't appear:**
- Restart plasmashell: `killall plasmashell && plasmashell &`

**"Configure" button doesn't appear:**
- Apply the wallpaper first, then reopen configuration

**Photos don't load:**
- Verify URL, username, password, and photo path
- Test WebDAV access in browser
- Check file permissions and supported formats

**Reinstall if needed:**
```bash
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
./install.sh
killall plasmashell && plasmashell &
```

## Important Notes

- Password is stored in plain text (use app password for security)
- Images are cached locally for performance
- Plugin uses Nextcloud WebDAV API with Basic Auth

## License

GPL-2.0-or-later
