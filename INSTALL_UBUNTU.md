# Installation Guide for Ubuntu 25.04

This guide will help you install the Nextcloud Carousel wallpaper plugin on Ubuntu 25.04.

## Prerequisites

### 1. KDE Plasma 6 Desktop Environment

Ubuntu 25.04 may come with different desktop environments. You need KDE Plasma 6 installed.

**Check if KDE Plasma is installed:**
```bash
dpkg -l | grep -i "plasma-desktop\|plasma-workspace"
```

**If not installed, install KDE Plasma:**
```bash
sudo apt update
sudo apt install kde-plasma-desktop
# Or for full KDE experience:
sudo apt install kubuntu-desktop
```

### 2. Required Packages

Install the following packages:

```bash
sudo apt update
sudo apt install \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-tools-dev \
    libplasma-dev \
    libkirigami-dev \
    libkcmutils-dev \
    libkconfig-dev \
    qml6-module-org-kde-kirigami \
    qml6-module-org-kde-kcmutils \
    qml6-module-org-kde-plasma \
    qml6-module-org-kde-kquickcontrols \
    cmake \
    build-essential
```

**Note:** On Ubuntu, KDE Frameworks 6 packages use different names:
- `libkf6plasma-dev` → `libplasma-dev`
- `libkf6kirigami2-dev` → `libkirigami-dev`
- `libkf6kcmutils-dev` → `libkcmutils-dev`
- `libkf6config-dev` → `libkconfig-dev`

### 3. Verify Versions

Check installed versions:

```bash
# Check Plasma version
plasmashell --version

# Check Qt version
qmake6 --version

# Check KF6 availability (may not work on Ubuntu)
pkg-config --modversion KF6Plasma 2>/dev/null || echo "KF6 not found via pkg-config (check packages instead)"
```

**Required versions:**
- KDE Plasma: 6.0 or higher
- Qt: 6.0 or higher
- KF6: Required

## Installation Methods

### Method 1: Simple Installation (Recommended)

This method doesn't require compilation:

```bash
# Clone or download the repository
git clone https://github.com/myNemy/Nextcloud-Carousel.git
cd Nextcloud-Carousel

# Run installation script
chmod +x install.sh
./install.sh

# Restart plasmashell
killall plasmashell && plasmashell &
```

### Method 2: Manual Installation

```bash
# Create plugin directory
mkdir -p ~/.local/share/plasma/wallpapers/org.nextcloud.carousel

# Copy plugin files
cp -r nextcloud-carousel/* ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/

# Restart plasmashell
killall plasmashell && plasmashell &
```

### Method 3: System-wide Installation (with CMake)

For system-wide installation (requires root):

```bash
# Install build dependencies (see above)
sudo apt install cmake build-essential qt6-base-dev libkf6plasma-dev

# Build and install
mkdir build
cd build
cmake ..
make
sudo make install

# Restart plasmashell
killall plasmashell && plasmashell &
```

## Verification

After installation, verify the plugin is recognized:

```bash
# Check if plugin directory exists
ls -la ~/.local/share/plasma/wallpapers/org.nextcloud.carousel

# Verify plugin structure
ls -la ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/contents/ui/

# Should show: config.qml and main.qml
```

## Configuration

1. **Right-click on desktop** → **Configure Desktop and Wallpaper**
2. Select **Nextcloud Carousel** from the wallpaper list
3. Click **Configure**
4. Enter:
   - Nextcloud URL (e.g., `https://nextcloud.example.com`)
   - Username
   - Password (or app password)
   - Photo Path (e.g., `/Photos`)

## Troubleshooting

### Plugin doesn't appear

1. **Check installation:**
   ```bash
   ls ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
   ```

2. **Restart plasmashell:**
   ```bash
   killall plasmashell && plasmashell &
   ```

3. **Check for errors:**
   ```bash
   journalctl -f | grep plasma
   ```

### Missing dependencies

If you get errors about missing QML modules:

```bash
# Install missing QML modules
sudo apt install \
    qml6-module-org-kde-kirigami \
    qml6-module-org-kde-kcmutils \
    qml6-module-org-kde-plasma \
    qml6-module-org-kde-kquickcontrols

# Also install development libraries if needed
sudo apt install \
    libkirigami-dev \
    libkcmutils-dev \
    libplasma-dev
```

### Permission issues

```bash
# Fix permissions
chmod -R 755 ~/.local/share/plasma/wallpapers/org.nextcloud.carousel
```

## Uninstallation

```bash
# Remove plugin
rm -rf ~/.local/share/plasma/wallpapers/org.nextcloud.carousel

# Restart plasmashell
killall plasmashell && plasmashell &
```

Or use the uninstall script:
```bash
./uninstall.sh
```

## Notes

- The plugin works with KDE Plasma 6.x
- Qt 6.x is required
- KF6 (KDE Frameworks 6) must be installed
- Ubuntu 25.04 should have these packages available in the repositories

## Support

For issues specific to Ubuntu 25.04, please open an issue on the repository with:
- Ubuntu version: `lsb_release -a`
- Plasma version: `plasmashell --version`
- Qt version: `qmake6 --version`
- Error messages from logs

