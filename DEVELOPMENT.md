# Development Status and Documentation

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
   - ✅ **Transitions FULLY IMPLEMENTED** - Fade, Slide, and Zoom transitions working using StackView (KDE official pattern)
   - ✅ Transition enable/disable control
   - ✅ Transition randomization (random type per image)
   - ✅ FillMode implemented (Stretch, Fit, Crop, Tile) - backend + UI
   - ✅ Blur implemented - simplified (opacity reduction, not true blur) - backend + UI
   - ✅ ImageScale implemented - backend + UI
   - ✅ **Automatic EXIF orientation** - Images automatically rotated based on EXIF orientation data

5. **Interface**
   - ✅ Working configuration UI
   - ✅ Multilingual support (EN/IT)
   - ✅ Input validation
   - ✅ Loading indicator visibility control (show/hide)

6. **System**
   - ✅ Automated installation/uninstallation
   - ✅ Diagnostic scripts
   - ✅ Ubuntu 25.04 compatibility
   - ✅ Complete documentation

## ⚠️ Missing Settings in UI

All major settings are now implemented in both backend and UI. The following are complete:

1. **TransitionDuration** - ✅ COMPLETE
   - Fully implemented in UI and backend
   - Controls fade transition duration between images
   - Default: 1000ms
   - Range: 100-10000ms

2. **TransitionEnabled** - ✅ COMPLETE
   - Fully implemented in UI and backend
   - CheckBox to enable/disable transitions
   - When disabled, images change instantly without animation
   - Default: true

3. **TransitionRandom** - ✅ COMPLETE
   - Fully implemented in UI and backend
   - CheckBox to randomize transition type
   - When enabled, randomly selects Fade/Slide/Zoom for each image
   - Enabled only when transitions are enabled
   - Default: false

4. **TransitionType** - ✅ COMPLETE
   - Fully implemented in UI and backend
   - ComboBox with Fade/Slide/Zoom options
   - Used when TransitionRandom is disabled
   - All three transition types (Fade, Slide, Zoom) working
   - Default: 0 (Fade)

5. **ShowLoadingIndicator** - ✅ COMPLETE
   - Fully implemented in UI and backend
   - CheckBox to show/hide loading indicator
   - When disabled, loading indicator is hidden during image loading
   - Default: true

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

## 🌐 Nextcloud WebDAV Integration

### Implementation Details

Image loading from Nextcloud has been implemented using the WebDAV API.

#### 1. Authentication
- Uses Basic Authentication with username and password
- Builds the WebDAV URL: `https://nextcloud.example.com/remote.php/dav/files/USERNAME/PATH`
- Credentials are included in the URL (Basic Auth)
- **Security recommendation**: Use app password instead of main password for better security

#### 2. File Listing (PROPFIND)
- Executes a PROPFIND request with `Depth=infinity` to list files recursively
- Includes all subfolders in the search
- Parses the XML response using regex to extract file paths
- Filters only image files (jpg, jpeg, png, gif, webp, bmp, svg, tiff)

#### 3. Image URL Construction
- Builds direct URLs for image download
- Adds authentication to the URL to allow download
- Format: `https://username:password@server.com/remote.php/dav/files/USERNAME/PATH/image.jpg`

#### 4. Image Download and Conversion
- Images are downloaded via `XMLHttpRequest` with Basic Authentication
- `responseType = "arraybuffer"` for binary data
- ArrayBuffer → Base64 conversion (manual, `btoa()` not available in QML)
- Creates data URL: `"data:image/jpeg;base64,..."`
- QML Image component doesn't support authenticated URLs directly, hence base64 conversion

#### 5. Supported Formats
- JPEG/JPG
- PNG
- GIF
- WebP
- BMP
- SVG
- TIFF

#### 6. Technical Notes
- Plugin loads images asynchronously
- Images are converted to base64 data URLs for QML compatibility
- WebDAV XML parsing uses regex (DOMParser might not be available in QML)

#### Troubleshooting

If images don't load:

1. **Verify credentials**: Username and password must be correct
2. **Verify path**: The photo path must exist in Nextcloud
3. **Verify permissions**: You must have access to the folder in Nextcloud
4. **Check logs**: 
   ```bash
   journalctl --user -b | grep -i "nextcloud\|carousel"
   ```
   Or enable QML debug logging:
   ```bash
   QT_LOGGING_RULES="qml.debug=true" plasmashell
   ```

#### Future Improvements
- ⏳ Local image cache
- ⏳ OAuth2 support
- ⏳ Improved error handling
- ⏳ Loading progress indicator

---

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
   - **StackView pattern:** ImageComponent created and added via `StackView.replace()`
   - **Result:** ✅ **Smooth transitions** - Fade, Slide, or Zoom animations
   - Image component loads in background, then transitions smoothly
   - `root.loading = false` (hides loading indicator when done)

### ✅ Current Status - All Features Implemented

- ✅ **Visual transitions** between images - All working (Fade, Slide, Zoom)
- ✅ **Smooth image changes** - Using StackView with replace() method
- ✅ `Behavior on opacity` used for blur opacity animation
- ✅ `StackView` fully implemented and working with transitions
- ✅ `TransitionDuration` setting controls all transition animations

### ✅ Transition System - Fully Implemented

The transition system has been successfully implemented using StackView (KDE official pattern):

1. ✅ **StackView System** - IMPLEMENTED
   - Uses `StackView` with `replace()` method (not push/pop)
   - `ImageComponent.qml` created for individual images
   - `pendingImage` pattern: loads image in background before replacing

2. ✅ **Transition Animations** - ALL IMPLEMENTED
   - ✅ Fade: OpacityAnimator (opacity 0→1 on new, 1→0 on old)
   - ✅ Slide: PropertyAnimation on x property (horizontal slide)
   - ✅ Zoom: PropertyAnimation on scale property (zoom in/out)

3. ✅ **Transition Coordination** - IMPLEMENTED
   - Load next image in background (`pendingImage`)
   - Wait for image to load (`statusChanged` signal)
   - Start transition animation via `StackView.replace()`
   - Clean up old image automatically via StackView signals

4. ✅ **TransitionType Implementation** - IMPLEMENTED
   - ✅ `TransitionType` setting mapped to actual transition behavior (0=Fade, 1=Slide, 2=Zoom)
   - ✅ `TransitionDuration` applied to all transition animations
   - ✅ `TransitionEnabled` to enable/disable transitions
   - ✅ `TransitionRandom` to randomize transition type per image

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
  - Note: Now controls all transition durations (Fade, Slide, Zoom)

**TransitionType (UI Implementation)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13
- **Status:** ✅ COMPLETE - All transitions (Fade, Slide, Zoom) fully implemented
- **Implementation:**
  - ✅ ComboBox added to config.qml (3 options: Fade, Slide, Zoom)
  - ✅ Translation strings added (EN/IT)
  - ✅ Property alias cfg_TransitionType configured
  - ✅ Backend: All transitions (Fade, Slide, Zoom) implemented and working
- **Technical details:**
  - ComboBox with 3 transition type options
  - Default: 0 (Fade)
  - Options: 0=Fade, 1=Slide, 2=Zoom
  - All transitions working using StackView with ParallelAnimation (KDE official pattern)
  - Fade: OpacityAnimator
  - Slide: PropertyAnimation on x property
  - Zoom: PropertyAnimation on scale property

**ShowLoadingIndicator (UI Implementation)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13
- **Status:** ✅ COMPLETE
- **Implementation:**
  - ✅ CheckBox added to config.qml for show/hide loading indicator
  - ✅ Translation strings added (EN/IT)
  - ✅ Property alias cfg_ShowLoadingIndicator configured
  - ✅ Backend: LoadingPlaceholder visibility controlled by setting
- **Technical details:**
  - CheckBox to enable/disable loading indicator visibility
  - Default: true (loading indicator visible by default)
  - Loading indicator only shows when both loading=true AND ShowLoadingIndicator=true
  - Allows users to have a cleaner wallpaper display without loading feedback

**Transition System Implementation (StackView - KDE Official Pattern)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13 (All transitions working)
- **Status:** ✅ ALL TRANSITIONS WORKING (Fade, Slide, Zoom)
- **Implementation:**
  - ✅ Created ImageComponent.qml following KDE StaticImageComponent pattern
  - ✅ Modified main.qml to use StackView with replace() method
  - ✅ Implemented pendingImage pattern (load in background before replacing)
  - ✅ Implemented replaceWhenLoaded() function following KDE pattern
  - ✅ Configured replaceEnter and replaceExit transitions with ParallelAnimation
  - ✅ Implemented Fade transition using OpacityAnimator
  - ✅ Implemented Slide transition using PropertyAnimation on x property
  - ✅ Implemented Zoom transition using PropertyAnimation on scale property
  - ✅ Fixed animator property errors (cannot use running: in PropertyAnimation inside Transition)
  - ✅ Images now visible and all transitions working
  - ✅ Added TransitionEnabled setting to enable/disable transitions
  - ✅ Added TransitionRandom setting to randomize transition type
- **Technical details:**
  - Uses QQC2.StackView with replace() method (not push/pop)
  - replaceEnter: ParallelAnimation with OpacityAnimator, PropertyAnimation (x), PropertyAnimation (scale)
  - replaceExit: ParallelAnimation with PauseAnimation, OpacityAnimator, PropertyAnimation (x), PropertyAnimation (scale)
  - Transition type determined by TransitionRandom (random) or TransitionType (fixed)
  - Initial position/scale set in ImageComponent based on transition type
  - Transition duration controlled by TransitionDuration setting
  - Following official KDE pattern from org.kde.slideshow plugin
  - All three transition types (Fade, Slide, Zoom) fully functional
- **Files modified:**
  - Created: nextcloud-carousel/contents/ui/ImageComponent.qml
  - Modified: nextcloud-carousel/contents/ui/main.qml (StackView implementation)
  - Modified: nextcloud-carousel/contents/config/main.xml (added TransitionEnabled, TransitionRandom)
  - Modified: nextcloud-carousel/contents/ui/config.qml (added UI controls)
  - Modified: nextcloud-carousel/contents/locale/it/LC_MESSAGES/org.nextcloud.carousel.po (added translations)

**Bug Fix: Animator Property Error (Qt 6 Compatibility)**
- **Date:** 2024-11-13
- **Status:** ✅ FIXED
- **Issue:**
  - Error in logs: `Cannot assign to non-existent property "enabled"` at lines 450, 458, 481, 489 in main.qml
  - `XAnimator` and `ScaleAnimator` components in Qt 6 do not support the `enabled` property
  - This caused the wallpaper plugin to fail loading with QML errors
- **Fix:**
  - Replaced `enabled:` with `running:` property in all animators (XAnimator and ScaleAnimator)
  - Fixed 4 occurrences in `replaceEnter` and `replaceExit` transitions
  - Lines affected: 450, 458, 481, 489 in main.qml
- **Technical details:**
  - In Qt 6, animators use `running` property to control execution (not `enabled`)
  - `Transition` component still supports `enabled` property (line 435 - correctly used)
  - Animators now properly conditionally run based on `transitionType` setting
  - Error detected via Plasma session logs: `journalctl --user -b | grep plasmashell`
- **Verification:**
  - Plugin now loads without QML errors
  - Animators correctly respond to `transitionType` configuration
  - Logs show no more "Cannot assign to non-existent property" errors

## 📝 Next Steps

1. ✅ Add Blur setting to configuration interface (COMPLETE)
2. ✅ Add FillMode and ImageScale to configuration interface (COMPLETE)
3. ✅ Add TransitionDuration to configuration interface (COMPLETE)
4. ✅ Add TransitionType to configuration interface (COMPLETE)
5. ✅ Implement transition system in backend - All transitions working (COMPLETE)
6. ✅ Implement Slide and Zoom transitions (COMPLETE)
7. ✅ Add TransitionEnabled and TransitionRandom settings (COMPLETE)
8. ✅ Implement automatic EXIF orientation detection and rotation (COMPLETE)
9. ✅ Add loading indicator visibility control (COMPLETE)
10. Improve validation and user feedback
11. Add settings preview
12. Optimize performance for large photo collections

## 🎯 What Needs to Be Done Now

### ✅ Transition System - COMPLETED (All transitions working)

The transition system has been successfully implemented using the KDE official StackView pattern:
- ✅ ImageComponent.qml created
- ✅ StackView with replace() method working
- ✅ Fade transitions working
- ✅ Slide transitions working
- ✅ Zoom transitions working
- ✅ Transition enable/disable control
- ✅ Transition randomization (random type per image)
- ✅ Images visible and displaying correctly

### Current Situation

**✅ COMPLETED:**
- All UI settings are now configurable from the interface
- All settings are saved correctly in configuration
- Plugin works and displays images correctly

**✅ COMPLETED:**
- ✅ **Visual transitions between images** - All transitions (Fade, Slide, Zoom) working
- ✅ The `TransitionType` and `TransitionDuration` settings are now used in the backend
- ✅ `TransitionEnabled` setting to enable/disable transitions
- ✅ `TransitionRandom` setting to randomize transition type

### ✅ Transition System - FULLY IMPLEMENTED

The transition system has been successfully implemented. When an image changes:
1. Timer triggers → `nextPhoto()` is called
2. New image is downloaded via `loadImageWithAuth()`
3. Image is converted to base64 data URL
4. **Transition type determined** (random or fixed based on settings)
5. **ImageComponent created** with initial position/scale based on transition type
6. **StackView.replace()** called with transition animation
7. **Smooth transition** (Fade/Slide/Zoom) displays the new image

**What's implemented:**
- ✅ `StackView` is used with replace() method
- ✅ `ImageComponent.qml` created and used for image display
- ✅ `TransitionType` setting is read and used (all types working: Fade, Slide, Zoom)
- ✅ `TransitionEnabled` setting to control transitions on/off
- ✅ `TransitionRandom` setting to randomize transition type per image
- ✅ All three transition types fully functional

### Implementation Details (Reference)

**📚 Official Documentation Analysis:**

After consulting the official KDE Plasma slideshow plugin (`org.kde.slideshow`) and Qt/QML documentation, we found:

1. **KDE Official Plugin Uses StackView:**
   - Location: `/usr/share/plasma/wallpapers/org.kde.slideshow/contents/ui/ImageStackView.qml`
   - Uses `QQC2.StackView` with `replace()` method (not push/pop)
   - Uses `replaceEnter` and `replaceExit` transitions with `OpacityAnimator`
   - Implements `pendingImage` pattern: loads image in background before replacing
   - Keeps old image visible until new image is fully faded in (prevents background showing through)

2. **Qt/QML Official Recommendations:**
   - StackView approach with ParallelAnimation is implemented and working for smooth transitions
   - `States` + `Transitions` can be used but is more complex (not used)
   - `Behavior on source` doesn't work well for images (source changes instantly)
   - `OpacityAnimator` is preferred over `NumberAnimation` for opacity (better performance) - ✅ Used

3. **Key Pattern from KDE Plugin:**
   ```qml
   // Load image in background
   pendingImage = component.createObject(view, {...});
   pendingImage.statusChanged.connect(replaceWhenLoaded);
   
   // Replace when loaded
   view.replace(pendingImage, {}, QQC2.StackView.Transition);
   
   // Transitions
   replaceEnter: Transition {
       OpacityAnimator {
           from: 0
           to: 1
           duration: Math.round(Kirigami.Units.veryLongDuration * 2.5)
       }
   }
   replaceExit: Transition {
       PauseAnimation {
           duration: replaceEnterOpacityAnimator.duration + 500
       }
   }
   ```

To make transitions work, we need to **replace the direct image loading** with a **transition system**. There are two main approaches:

#### **Option 1: Dual Image Layers (Simpler, Qt Recommended) - NOT CHOSEN**

**Note:** This option was considered but not implemented. Option 2 (StackView) was chosen instead.

**How it would work:**
- Two `Image` components: `currentImage` and `nextImage`
- When changing image:
  1. Load new image into `nextImage` (hidden, opacity=0)
  2. Start transition animation based on `TransitionType`:
     - **Fade:** `nextImage.opacity 0→1`, `currentImage.opacity 1→0`
     - **Slide:** `nextImage.x` animation (slide in), `currentImage.x` animation (slide out)
     - **Zoom:** `nextImage.scale` animation (zoom in), `currentImage.scale` animation (zoom out)
  3. After animation completes, swap: `currentImage = nextImage`, clear `nextImage`
  4. Repeat for next change

**Complexity:** Medium
**Estimated effort:** 2-3 hours
**Status:** Not implemented (Option 2 chosen instead)

#### **Option 2: StackView System (KDE Official Pattern - ✅ CHOSEN AND IMPLEMENTED)**

**How it works (based on official KDE slideshow plugin):**
- Use `StackView` with `replace()` method (not push/pop)
- Create image component in background (`pendingImage`)
- Wait for image to load (`statusChanged` signal)
- Replace current image with `view.replace(pendingImage, {}, QQC2.StackView.Transition)`
- Configure `replaceEnter` and `replaceExit` transitions
- Support different transition types (Fade/Slide/Zoom) via transition configuration

**Implementation steps (following KDE pattern) - ✅ COMPLETED:**
1. ✅ Fixed existing `StackView` - now properly used with replace() method
2. ✅ Created `ImageComponent.qml` for individual images (similar to KDE's `StaticImageComponent.qml`)
3. ✅ Modified `loadImageWithAuth()` to:
   - Create `pendingImage` component in background
   - Connect to `statusChanged` signal
   - Call `replaceWhenLoaded()` when ready
   - Determine transition type (random or fixed)
   - Set initial position/scale based on transition type
4. ✅ Implemented `replaceWhenLoaded()` function:
   - Disconnect `statusChanged` signal
   - Call `view.replace(pendingImage, {}, QQC2.StackView.Transition)`
   - Clean up old image via `onDeactivated` and `onRemoved` signals
5. ✅ Configured transitions based on `TransitionType`:
   - Fade: `OpacityAnimator` in `replaceEnter`, `PauseAnimation` in `replaceExit`
   - Slide: `PropertyAnimation` on x property for horizontal movement
   - Zoom: `PropertyAnimation` on scale property for zoom effect
6. ✅ Use `TransitionDuration` setting for animation duration
7. ✅ Handle edge cases (first image, errors, rapid changes)
8. ✅ Added `TransitionEnabled` to enable/disable transitions
9. ✅ Added `TransitionRandom` to randomize transition type per image

**Complexity:** Medium-High
**Estimated effort:** 3-4 hours
**Status:** ✅ COMPLETED
**Files modified:** `nextcloud-carousel/contents/ui/main.qml`, created `ImageComponent.qml`
**Advantages:**
- ✅ Follows official KDE pattern (proven, tested)
- ✅ Better memory management (automatic cleanup via StackView)
- ✅ Supports complex transitions (can combine multiple animators)
- ✅ StackView properly implemented and working

### ✅ Implementation Completed

**Option 2 (StackView System - KDE Official Pattern) was chosen and implemented:**
- ✅ **Follows official KDE Plasma pattern** (used in `org.kde.slideshow`)
- ✅ **Proven and tested** in production KDE codebase
- ✅ **Better memory management** (automatic cleanup via StackView signals)
- ✅ **Supports complex transitions** (can combine multiple animators for Slide/Zoom)
- ✅ **StackView properly implemented** and working correctly
- ✅ **Consistent with KDE ecosystem** (easier for future maintainers)
- ✅ **Handles edge cases** (rapid changes, errors) via built-in StackView mechanisms

### ✅ Detailed Implementation (Completed - Reference)

**✅ Step 1: Create ImageComponent.qml (COMPLETED)**
```qml
// nextcloud-carousel/contents/ui/ImageComponent.qml
import QtQuick
import QtQuick.Controls as QQC2

QQC2.StackView {
    // Component for individual images
    // Similar to KDE's StaticImageComponent.qml
    required property url source
    required property int fillMode
    required property color color
    required property bool blur
    required property real blurOpacity
    required property real imageScale
    
    Image {
        id: image
        anchors.fill: parent
        source: parent.source
        fillMode: parent.fillMode
        scale: parent.imageScale / 100.0
        transformOrigin: Item.Center
        opacity: parent.blur ? (parent.blurOpacity / 100.0) : 1.0
        asynchronous: true
        cache: true
        smooth: true
    }
    
    Rectangle {
        anchors.fill: parent
        color: parent.color
        z: -1
    }
}
```

**✅ Step 2: Fix StackView in main.qml (COMPLETED)**
- ✅ Removed unused `Image` component
- ✅ Fixed `StackView` configuration
- ✅ Added `pendingImage` property
- ✅ Added `replaceWhenLoaded()` function

**✅ Step 3: Modify loadImageWithAuth() (COMPLETED)**
- ✅ Instead of `imageView.source = dataUrl`
- ✅ Create `pendingImage` component using `ImageComponent.qml`
- ✅ Connect to `pendingImage.statusChanged` signal
- ✅ Call `replaceWhenLoaded()` when image is ready
- ✅ Determine transition type (random or fixed)
- ✅ Set initial position/scale based on transition type

**✅ Step 4: Implement replaceWhenLoaded() function (COMPLETED)**
```qml
function replaceWhenLoaded() {
    if (pendingImage.status === Image.Loading) {
        return;
    }
    
    pendingImage.statusChanged.disconnect(replaceWhenLoaded);
    
    // Cleanup old image when removed
    pendingImage.QQC2.StackView.onDeactivated.connect(pendingImage.destroy);
    pendingImage.QQC2.StackView.onRemoved.connect(pendingImage.destroy);
    
    // Replace with transition
    imageStack.replace(pendingImage, {}, QQC2.StackView.Transition);
    
    root.loading = false;
    pendingImage = null;
}
```

**✅ Step 5: Configure StackView transitions based on TransitionType (COMPLETED)**
```qml
QQC2.StackView {
    id: imageStack
    
    property int transitionType: root.configuration.TransitionType || 0
    property int transitionDuration: root.configuration.TransitionDuration || 1000
    
    replaceEnter: Transition {
        id: enterTransition
        enabled: !doesSkipAnimation
        
        // Fade transition
        OpacityAnimator {
            from: 0
            to: 1
            duration: imageStack.transitionDuration
        }
        
        // Slide transition (if type == 1)
        XAnimator {
            from: imageStack.width
            to: 0
            duration: imageStack.transitionDuration
            enabled: imageStack.transitionType === 1
        }
        
        // Zoom transition (if type == 2)
        ScaleAnimator {
            from: 0.8
            to: 1.0
            duration: imageStack.transitionDuration
            enabled: imageStack.transitionType === 2
        }
    }
    
    replaceExit: Transition {
        // Keep old image until new one is fully visible
        PauseAnimation {
            duration: imageStack.transitionDuration + 100
        }
        
        // Fade out old image
        OpacityAnimator {
            from: 1
            to: 0
            duration: imageStack.transitionDuration
        }
        
        // Slide out (if type == 1)
        XAnimator {
            from: 0
            to: -imageStack.width
            duration: imageStack.transitionDuration
            enabled: imageStack.transitionType === 1
        }
        
        // Zoom out (if type == 2)
        ScaleAnimator {
            from: 1.0
            to: 1.2
            duration: imageStack.transitionDuration
            enabled: imageStack.transitionType === 2
        }
    }
}
```

**Step 6: Update Connections**
- Add handler for `onTransitionTypeChanged()` to update transition configuration
- Add handler for `onTransitionDurationChanged()` to update animation duration

**Step 7: Testing**
- Test each transition type (Fade, Slide, Zoom)
- Test with different durations
- Test edge cases (first image, errors, rapid changes)
- Verify memory cleanup (old images are destroyed)

### Alternative: Simpler Improvements (If transitions are too complex)

If implementing transitions is too complex right now, we can focus on:

1. **Improve validation and user feedback**
   - Add input validation for all fields
   - Show error messages for invalid configurations
   - Add connection status indicator

2. **Optimize performance**
   - Preload next image in background
   - Cache images locally
   - Optimize WebDAV requests

3. **Add settings preview**
   - Live preview of settings changes
   - Preview transition types before applying

### ✅ Decision Made and Implemented

**Transition system implementation:**
- ✅ **Option 2 (StackView System) was chosen and fully implemented**
- ✅ All three transition types (Fade, Slide, Zoom) working
- ✅ Transition enable/disable control added
- ✅ Transition randomization added

**Next priorities:**
- **A)** Optimize performance (preload, cache, optimize WebDAV requests)
- **B)** Add settings preview (live preview of settings changes)
- **C)** Add photo information display (EXIF data, filename, path, date/time)

## 🔮 Planned Features

### Photo Information Display
- **EXIF Data Extraction:**
  - Photo name/filename
  - Folder/path information
  - Location (GPS coordinates if available)
  - Date and time (from EXIF)
  - Full EXIF metadata access

### Automatic Orientation - ✅ FULLY IMPLEMENTED AND TESTED
- **Smart Orientation Detection:**
  - ✅ Automatic EXIF orientation reading from JPEG images
  - ✅ Rotation based on EXIF orientation data (0°, 90°, -90°, 180°)
  - ✅ Support for all standard EXIF orientation values (1, 3, 6, 8)
  - ✅ Automatic rotation applied to images during display
  - ✅ Works with both Intel and Motorola byte order
  - ✅ Correct rotation direction (QML positive = counter-clockwise)
  - ✅ Tested and verified working with real images
  - ⏳ Optimal display based on image aspect ratio (future enhancement)
  - ⏳ Support for portrait and landscape modes detection (future enhancement)

## 🎯 Objective

Make all implemented features configurable from the user interface for a complete and customizable experience.
