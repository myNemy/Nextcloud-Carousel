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
   - ❌ **Transitions NOT IMPLEMENTED** - Image change is instant, no visual transitions between images
   - ✅ FillMode implemented (Stretch, Fit, Crop, Tile) - backend + UI
   - ✅ Blur implemented - simplified (opacity reduction, not true blur) - backend + UI

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
   - **Status:** ✅ COMPLETE - Fully implemented in UI
   - **Current behavior:** 
     - ⚠️ **IMPORTANT:** Currently only controls the `Behavior on opacity` animation for blur effect
     - Does NOT control transitions between images (images change instantly)
     - Default: 1000ms
     - Used in: `Behavior on opacity { NumberAnimation { duration: TransitionDuration } }`
   - **UI Components:**
     - TextField with IntValidator (100-10000ms range)
     - Property alias cfg_TransitionDuration configured
     - Translation strings added (EN/IT)
   - **Note:** To enable actual image transitions, the transition system must be implemented first (see TransitionType)

2. **TransitionType** - Transition type (Fade/Slide/Zoom)
   - **Complexity:** Medium - Requires implementing actual transitions
   - **Status:** ✅ UI COMPLETE - Backend NOT IMPLEMENTED
   - **UI Implementation:**
     - ✅ ComboBox added to config.qml (3 options: Fade, Slide, Zoom)
     - ✅ Translation strings added (EN/IT)
     - ✅ Property alias cfg_TransitionType configured
   - **Backend Status:** NOT IMPLEMENTED - Only direct image change without animation
   - **Current state:**
     - StackView is defined with pushEnter/pushExit transitions but NOT USED
     - Images are loaded directly into Image component, changing source instantly
     - Only opacity fade exists (for blur effect, not for transitions)
     - Slide and Zoom transitions are not implemented
   - **What needs to be done (Backend):**
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
   - **Status:** ✅ COMPLETE - Fully implemented in UI
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
   - **UI Components:**
     - ComboBox with 6 options
     - Translation strings added (EN/IT)
     - Property alias cfg_FillMode configured
     - Handler onFillModeChanged implemented

5. **ImageScale** - Image zoom/scale control
   - **Complexity:** Low-Medium - Slider with percentage display
   - **Status:** ✅ COMPLETE - Fully implemented
   - **Implementation details:**
     - Slider range: 50-200% (default: 100%)
     - Step size: 5%
     - Applied as `scale` property on Image component
     - `transformOrigin: Item.Center` for centered scaling
     - Conversion: ImageScale/100.0 (50% = 0.5, 100% = 1.0, 200% = 2.0)
   - **UI Components:**
     - Slider with label showing current percentage
     - Property alias cfg_ImageScale configured
     - Handler onImageScaleChanged implemented

## 🔄 Image Loading Process (Technical Details)

### Current Image Change Flow

1. **Timer Trigger** (every `SlideInterval` seconds)
   - `carouselTimer` triggers → calls `carouselController.nextPhoto()`

2. **Next Photo Selection** (`nextPhoto()` function)
   - Calculates new `currentIndex` based on `RandomOrder` mode:
     - Mode 0: Sequential `(currentIndex + 1) % length`
     - Mode 1: Random (avoids immediate repeat)
     - Mode 2: Sequential through shuffled list
     - Mode 3: Smart random (avoids last 5 used)
   - Calls `updateCurrentImage()`

3. **Image Update** (`updateCurrentImage()` function)
   - Gets URL from `photoList[currentIndex]`
   - Calls `loadImageWithAuth(photoUrl)`

4. **Image Download** (`loadImageWithAuth()` function)
   - Sets `root.loading = true` (shows loading indicator)
   - Extracts clean URL (removes `username:password@`)
   - Performs `XMLHttpRequest GET` with Basic Authentication
   - `responseType = "arraybuffer"`

5. **Image Conversion**
   - ArrayBuffer → Base64 (manual conversion, `btoa()` not available in QML)
   - Determines MIME type from file extension (`.jpg`, `.png`, `.gif`, `.webp`, `.svg`)
   - Creates data URL: `"data:image/jpeg;base64,..."`

6. **Image Display**
   - **Direct assignment:** `imageView.source = dataUrl`
   - **Result:** ⚠️ **INSTANT CHANGE** - No transition animation
   - Image component loads and displays immediately
   - `root.loading = false` (hides loading indicator)

### Current Limitations

- ❌ **No visual transitions** between images
- ❌ **Instant image change** - `imageView.source` is changed directly
- ⚠️ `Behavior on opacity` exists but only controls blur opacity animation, not image transitions
- ⚠️ `StackView` is defined in code but **NOT USED**
- ⚠️ `TransitionDuration` setting exists but only affects blur opacity animation, not image transitions

### What's Needed for Real Transitions

To implement actual image transitions, the following is required:

1. **Dual Image Layers** or **StackView System**
   - Two `Image` components (current + next)
   - Or use `StackView` with proper push/pop transitions

2. **Transition Animations**
   - Fade: opacity 0→1 on new image, 1→0 on old image
   - Slide: horizontal/vertical position animation
   - Zoom: scale animation

3. **Transition Coordination**
   - Load next image in background
   - Start transition animation
   - Swap images at animation midpoint or end
   - Clean up old image

4. **TransitionType Implementation**
   - Map `TransitionType` setting to actual transition behavior
   - Apply `TransitionDuration` to transition animations

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

**FillMode and ImageScale (UI Implementation)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13
- **Status:** ✅ COMPLETE
- **Implementation:**
  - ✅ FillMode ComboBox added to config.qml (6 options)
  - ✅ ImageScale Slider added (50-200%, default: 100%)
  - ✅ Translation strings added (EN/IT) for all options
  - ✅ Property aliases configured (cfg_FillMode, cfg_ImageScale)
  - ✅ Handlers onFillModeChanged and onImageScaleChanged implemented
  - ✅ Image scale property applied with transformOrigin: Center
- **Technical details:**
  - FillMode: ComboBox with user-friendly names
  - ImageScale: Slider with percentage display (50-200%)
  - Scale conversion: ImageScale/100.0 for QML scale property
  - All Tile options (Tile, TileVertically, TileHorizontally) available

**TransitionDuration (UI Implementation)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13
- **Status:** ✅ COMPLETE
- **Implementation:**
  - ✅ TextField added to config.qml with IntValidator (100-10000ms)
  - ✅ Translation strings added (EN/IT)
  - ✅ Property alias cfg_TransitionDuration configured
  - ✅ Already used in backend for `Behavior on opacity` animation
- **Technical details:**
  - TextField with IntValidator for input validation
  - Range: 100-10000ms (default: 1000ms)
  - Controls blur opacity animation duration
  - Note: Does not control image transitions (not yet implemented)

**TransitionType (UI Implementation)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13
- **Status:** ✅ UI COMPLETE - Backend NOT IMPLEMENTED
- **Implementation:**
  - ✅ ComboBox added to config.qml (3 options: Fade, Slide, Zoom)
  - ✅ Translation strings added (EN/IT)
  - ✅ Property alias cfg_TransitionType configured
- **Technical details:**
  - ComboBox with 3 transition type options
  - Default: 0 (Fade)
  - Options: 0=Fade, 1=Slide, 2=Zoom
  - Note: Backend transition system not yet implemented - setting is saved but not used

## 📝 Next Steps

1. ✅ Add Blur setting to configuration interface (COMPLETE)
2. ✅ Add FillMode and ImageScale to configuration interface (COMPLETE)
3. ✅ Add TransitionDuration to configuration interface (COMPLETE)
4. ✅ Add TransitionType to configuration interface (UI COMPLETE - Backend pending)
5. Improve validation and user feedback
6. Add settings preview
7. Optimize performance for large photo collections

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
