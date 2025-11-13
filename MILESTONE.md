# Milestone: Working Base

**Date:** 2024-11-13

---

## 📚 General Rule: Official Documentation Consultation

**Fundamental rule:** Before implementing any new feature or modification, it is **mandatory** to consult the official KDE Plasma documentation.

### When to consult the documentation:

1. **Before adding new settings**
   - Verify best practices for `config.qml`
   - Check supported UI component types
   - Verify naming conventions and structure

2. **Before modifying plugin behavior**
   - Consult `WallpaperItem` documentation
   - Verify available APIs for wallpaper plugins
   - Check official plugin examples

3. **Before adding new dependencies or imports**
   - Verify compatibility with Plasma 6
   - Check supported QML module versions
   - Verify official alternatives

4. **Before implementing complex features**
   - Search for examples in the documentation
   - Verify if an official solution already exists
   - Check recommended patterns

### Documentation sources:

- **Official KDE Plasma documentation:**
  - https://develop.kde.org/docs/
  - https://api.kde.org/frameworks/
  
- **QML documentation:**
  - https://doc.qt.io/qt-6/qtqml-index.html
  
- **Official plugins as reference:**
  - `/usr/share/plasma/wallpapers/` (installed plugins)
  - KDE repositories on GitHub

### Recommended process:

1. **Read** the official documentation
2. **Study** existing official plugin examples
3. **Implement** following official patterns
4. **Test** with reference to documentation
5. **Document** any deviations or alternative choices

### Benefits:

- ✅ Guaranteed compatibility with Plasma 6
- ✅ Code aligned with best practices
- ✅ Long-term maintainability
- ✅ Future support facilitated
- ✅ Avoids non-standard or deprecated solutions

---

## ✅ Current Status - Working Base

The Nextcloud Carousel plugin has reached a working base with the following features:

### Implemented Features

1. **Nextcloud Connection**
   - ✅ Configurable server URL
   - ✅ Configurable username and password
   - ✅ App password support
   - ✅ Working WebDAV integration

2. **Photo Management**
   - ✅ Recursive loading from folders and subfolders
   - ✅ Multiple format support (JPEG, PNG, WebP, GIF, BMP, SVG, TIFF)
   - ✅ WebDAV XML parsing with regex

3. **Carousel**
   - ✅ Configurable slide interval
   - ✅ 4 ordering modes:
     - Sequential
     - Random (each time)
     - Shuffle once
     - Smart random (avoids repeats)
   - ✅ Automatic timer for slide change

4. **Display**
   - ✅ Configurable background color
   - ⚠️ Transitions partially implemented - StackView defined but not used, only direct image change
   - ✅ FillMode implemented (Stretch, Fit, Crop, Tile) - backend
   - ⚠️ Blur implemented - simplified (opacity reduction, not true blur) - backend

5. **Interface**
   - ✅ Working configuration UI
   - ✅ Multilingual support (EN/IT)
   - ✅ Input validation

6. **System**
   - ✅ Automated installation/uninstallation
   - ✅ Diagnostic scripts
   - ✅ Ubuntu 25.04 compatibility
   - ✅ Complete documentation

## ⚠️ Missing Settings in UI

The following settings are implemented in the backend (`main.qml`) but are not yet configurable in the user interface (`config.qml`):

1. **TransitionDuration** - Transition animation duration (ms)
   - **Complexity:** Low - Simple integer input field
   - **Current behavior:** Controls fade transition duration (default: 1000ms)

2. **TransitionType** - Transition type (Fade/Slide/Zoom)
   - **Complexity:** Medium - Requires implementing actual transitions
   - **Current behavior:** NOT IMPLEMENTED - Only direct image change without animation
   - **Current state:**
     - StackView is defined with pushEnter/pushExit transitions but NOT USED
     - Images are loaded directly into Image component, changing source instantly
     - Only opacity fade exists (for blur effect, not for transitions)
     - Slide and Zoom transitions are not implemented
   - **What needs to be done:**
     - Implement proper transition system using StackView or multiple Image layers
     - Add Fade transition (opacity 0→1)
     - Add Slide transition (horizontal/vertical movement)
     - Add Zoom transition (scale animation)
     - Apply transition based on TransitionType setting

3. **Blur** - Enable/disable blur effect with adjustable opacity
   - **Complexity:** Low-Medium - Checkbox + Slider
   - **Status:** ✅ COMPLETE - Fully implemented in UI
   - **Current behavior:** 
     - Checkbox to enable/disable blur effect
     - Slider to adjust opacity percentage (0-100%)
     - Simplified implementation - reduces image opacity based on BlurOpacity setting (not a true blur effect)
     - Default opacity: 75% (0.75)
   - **Note:** Full blur effect would require additional QML components (FastBlur, GaussianBlur, or shader effects)
   - **When used:** Applied to the main image display when `root.configuration.Blur` is true
   - **UI Components:**
     - CheckBox for enable/disable
     - Slider (0-100%) with label showing current value
     - Slider disabled when blur is off

4. **FillMode** - Image fill mode (Stretch/Fit/Crop/Tile)
   - **Complexity:** Medium - ComboBox with 6 options + translations
   - **Current behavior:** FULLY IMPLEMENTED in backend - Works correctly
   - **Implementation details:**
     - Switch statement in main.qml (lines 403-413) maps values 0-5 to Image.FillMode
     - Applied directly to Image component
     - Default: 2 (Image.PreserveAspectCrop)
   - **Available options:**
     - 0 = Image.Stretch (stretch to fill, may distort)
     - 1 = Image.PreserveAspectFit (maintain aspect ratio, all visible, may have borders)
     - 2 = Image.PreserveAspectCrop (maintain aspect ratio, fill screen, may crop)
     - 3 = Image.Tile (tile pattern)
     - 4 = Image.TileVertically (tile vertically)
     - 5 = Image.TileHorizontally (tile horizontally)
   - **What's missing:** Only ComboBox in config.qml to make it user-configurable

## 🚧 Development Status

### Completed

**Blur Setting (UI Implementation)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13
- **Status:** ✅ COMPLETE
- **Implementation:**
  - ✅ Backend implemented (opacity reduction based on BlurOpacity percentage)
  - ✅ CheckBox added to config.qml for enable/disable
  - ✅ Slider added for opacity control (0-100%)
  - ✅ Translation strings added (EN/IT)
  - ✅ Property aliases configured (cfg_Blur, cfg_BlurOpacity)
  - ✅ Handler onBlurChanged and onBlurOpacityChanged implemented
  - ✅ Opacity value: BlurOpacity/100.0 (default: 75% = 0.75)
- **Note:** Simplified implementation (opacity reduction, not true blur effect)
- **Technical details:**
  - Used Slider instead of SpinBox for better Qt6 compatibility
  - Slider range: 0-100% with 5% step size
  - Default opacity: 75% (more visible than initial 90%)
  - Slider disabled when blur checkbox is off

## 📝 Next Steps

1. ✅ Add Blur setting to configuration interface (COMPLETE)
2. Add remaining missing settings to the configuration interface:
   - TransitionDuration
   - TransitionType
   - FillMode
3. Improve validation and user feedback
4. Add settings preview
5. Optimize performance for large photo collections

## 🔮 Planned Features

### Photo Information Display
- **EXIF Data Extraction:**
  - Photo name/filename
  - Folder/path information
  - Location (GPS coordinates if available)
  - Date and time (from EXIF)
  - Full EXIF metadata access

### Automatic Orientation
- **Smart Orientation Detection:**
  - Automatic horizontal/vertical detection
  - Rotation based on EXIF orientation data
  - Optimal display based on image aspect ratio
  - Support for portrait and landscape modes

## 🎯 Objective

Make all implemented features configurable from the user interface for a complete and customizable experience.
