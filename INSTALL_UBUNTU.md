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

**First, search for available packages on your Ubuntu system:**

```bash
# Search for KDE Frameworks 6 packages
apt search plasma-framework | grep -i dev
apt search kirigami | grep -i dev
apt search kcmutils | grep -i dev
```

**Then install the packages. Based on Ubuntu 25.04, try these names:**

```bash
sudo apt update
sudo apt install \
    qt6-base-dev \
    qt6-declarative-dev \
    qt6-tools-dev \
    libkf6plasma-dev \
    kirigami2-dev \
    libkf6kcmutils-dev \
    libkf6config-dev \
    qml6-module-org-kde-kirigami \
    qml6-module-org-kde-kcmutils \
    qml6-module-org-kde-plasma \
    qml6-module-org-kde-kquickcontrols \
    cmake \
    build-essential
```

**If the above packages are not found, try alternatives:**

```bash
sudo apt install \
    qt6-base-dev \
    libkf5plasma-dev \
    libkirigami-dev \
    libkf6kcmutils-dev \
    libkf6config-dev \
    qml6-module-org-kde-kirigami \
    qml6-module-org-kde-kcmutils \
    qml6-module-org-kde-plasma \
    qml6-module-org-kde-kquickcontrols \
    cmake \
    build-essential
```

**Or try simplified names:**

```bash
sudo apt install \
    qt6-base-dev \
    libplasma6-dev \
    libkirigami2-6 \
    libkcmutils6 \
    qml6-module-org-kde-kirigami \
    qml6-module-org-kde-kcmutils \
    qml6-module-org-kde-plasma \
    qml6-module-org-kde-kquickcontrols \
    cmake \
    build-essential
```

**Note:** Package names on Ubuntu 25.04 may vary. Common variants:
- `libkf6plasma-dev` or `libkf5plasma-dev` or `libplasma6-dev` or `libplasma-dev`
- `kirigami2-dev` or `libkirigami-dev` or `libkf5kirigami2-5` or `libkirigami2-6`
- `libkf6kcmutils-dev` or `libkf5kcmutils-dev` or `libkcmutils6` or `libkcmutils-dev`

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
killall plasmashell && kstart plasmashell
```

### Method 2: Manual Installation

```bash
# Create plugin directory
mkdir -p ~/.local/share/plasma/wallpapers/org.nextcloud.carousel

# Copy plugin files
cp -r nextcloud-carousel/* ~/.local/share/plasma/wallpapers/org.nextcloud.carousel/

# Restart plasmashell
killall plasmashell && kstart plasmashell
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
killall plasmashell && kstart plasmashell
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
   killall plasmashell && kstart plasmashell
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
killall plasmashell && kstart plasmashell
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

