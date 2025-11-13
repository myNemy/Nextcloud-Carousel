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
   - ✅ **Transitions IMPLEMENTED** - Fade transitions working using StackView (KDE official pattern)
   - ✅ FillMode implemented (Stretch, Fit, Crop, Tile) - backend + UI
   - ✅ Blur implemented - simplified (opacity reduction, not true blur) - backend + UI
   - ✅ ImageScale implemented - backend + UI

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

All major settings are now implemented in both backend and UI. The following are complete:

1. **TransitionDuration** - ✅ COMPLETE
   - Fully implemented in UI and backend
   - Controls fade transition duration between images
   - Default: 1000ms
   - Range: 100-10000ms

2. **TransitionType** - ✅ UI COMPLETE - Backend partially implemented
   - UI fully implemented (ComboBox with Fade/Slide/Zoom options)
   - Backend: Fade transition working, Slide and Zoom pending
   - Current implementation uses StackView with OpacityAnimator (KDE pattern)
   - Slide and Zoom transitions will be implemented in future updates

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
- **Status:** ✅ UI COMPLETE - Backend partially implemented (Fade working)
- **Implementation:**
  - ✅ ComboBox added to config.qml (3 options: Fade, Slide, Zoom)
  - ✅ Translation strings added (EN/IT)
  - ✅ Property alias cfg_TransitionType configured
  - ✅ Backend: Fade transition implemented and working
- **Technical details:**
  - ComboBox with 3 transition type options
  - Default: 0 (Fade)
  - Options: 0=Fade, 1=Slide, 2=Zoom
  - Fade transition working using StackView with OpacityAnimator (KDE official pattern)
  - Slide and Zoom transitions pending (will use different approach than conditional animators)

**Transition System Implementation (StackView - KDE Official Pattern)**
- **Started:** 2024-11-13
- **Completed:** 2024-11-13 (Fade transition)
- **Status:** ✅ FADE TRANSITION WORKING
- **Implementation:**
  - ✅ Created ImageComponent.qml following KDE StaticImageComponent pattern
  - ✅ Modified main.qml to use StackView with replace() method
  - ✅ Implemented pendingImage pattern (load in background before replacing)
  - ✅ Implemented replaceWhenLoaded() function following KDE pattern
  - ✅ Configured replaceEnter and replaceExit transitions with OpacityAnimator
  - ✅ Fixed animator property errors (removed XAnimator/ScaleAnimator with running: from Transition)
  - ✅ Images now visible and transitions working
- **Technical details:**
  - Uses QQC2.StackView with replace() method (not push/pop)
  - replaceEnter: OpacityAnimator (fade in from 0 to 1)
  - replaceExit: PauseAnimation (keeps old image visible during enter transition)
  - Transition duration controlled by TransitionDuration setting
  - Following official KDE pattern from org.kde.slideshow plugin
  - Slide and Zoom transitions will be implemented later using a different approach
- **Files modified:**
  - Created: nextcloud-carousel/contents/ui/ImageComponent.qml
  - Modified: nextcloud-carousel/contents/ui/main.qml (StackView implementation)

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
5. ✅ Implement transition system in backend - Fade working (COMPLETE)
6. 🔄 Implement Slide and Zoom transitions (pending - will use different approach)
7. Improve validation and user feedback
8. Add settings preview
8. Optimize performance for large photo collections

## 🎯 What Needs to Be Done Now

### ✅ Transition System - COMPLETED (Fade working)

The transition system has been successfully implemented using the KDE official StackView pattern:
- ✅ ImageComponent.qml created
- ✅ StackView with replace() method working
- ✅ Fade transitions working
- ✅ Images visible and displaying correctly
- 🔄 Slide and Zoom transitions pending (will be implemented in future update)

### Current Situation

**✅ COMPLETED:**
- All UI settings are now configurable from the interface
- All settings are saved correctly in configuration
- Plugin works and displays images correctly

**❌ MISSING:**
- ✅ **Visual transitions between images** - Fade transitions working
- ✅ The `TransitionType` and `TransitionDuration` settings are now used in the backend
- 🔄 Slide and Zoom transitions pending (Fade is working)

### The Problem

Currently, when an image changes:
1. Timer triggers → `nextPhoto()` is called
2. New image is downloaded via `loadImageWithAuth()`
3. Image is converted to base64 data URL
4. **`imageView.source = dataUrl`** ← **INSTANT CHANGE, NO ANIMATION**
5. Image appears immediately

**What's in the code but NOT USED:**
- ✅ `StackView` is now used with replace() method
- ✅ `ImageComponent.qml` created and used for image display
- ✅ `TransitionType` setting is read and used (Fade working, Slide/Zoom pending)

### Solution: Implement Transition System

**📚 Official Documentation Analysis:**

After consulting the official KDE Plasma slideshow plugin (`org.kde.slideshow`) and Qt/QML documentation, we found:

1. **KDE Official Plugin Uses StackView:**
   - Location: `/usr/share/plasma/wallpapers/org.kde.slideshow/contents/ui/ImageStackView.qml`
   - Uses `QQC2.StackView` with `replace()` method (not push/pop)
   - Uses `replaceEnter` and `replaceExit` transitions with `OpacityAnimator`
   - Implements `pendingImage` pattern: loads image in background before replacing
   - Keeps old image visible until new image is fully faded in (prevents background showing through)

2. **Qt/QML Official Recommendations:**
   - Dual Image approach with opacity animation is recommended for smooth transitions
   - `States` + `Transitions` can be used but is more complex
   - `Behavior on source` doesn't work well for images (source changes instantly)
   - `OpacityAnimator` is preferred over `NumberAnimation` for opacity (better performance)

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

#### **Option 1: Dual Image Layers (Simpler, Qt Recommended)**

**How it works:**
- Two `Image` components: `currentImage` and `nextImage`
- When changing image:
  1. Load new image into `nextImage` (hidden, opacity=0)
  2. Start transition animation based on `TransitionType`:
     - **Fade:** `nextImage.opacity 0→1`, `currentImage.opacity 1→0`
     - **Slide:** `nextImage.x` animation (slide in), `currentImage.x` animation (slide out)
     - **Zoom:** `nextImage.scale` animation (zoom in), `currentImage.scale` animation (zoom out)
  3. After animation completes, swap: `currentImage = nextImage`, clear `nextImage`
  4. Repeat for next change

**Implementation steps:**
1. Replace single `Image` component with two `Image` components
2. Modify `loadImageWithAuth()` to load into `nextImage` instead of `imageView`
3. Add transition logic based on `root.configuration.TransitionType`:
   - Read `TransitionType` (0=Fade, 1=Slide, 2=Zoom)
   - Apply appropriate animations using `NumberAnimation` or `ParallelAnimation`
   - Use `TransitionDuration` for animation duration
4. Add completion handler to swap images after animation
5. Handle edge cases (first image, errors, etc.)

**Complexity:** Medium
**Estimated effort:** 2-3 hours
**Files to modify:** `nextcloud-carousel/contents/ui/main.qml`

#### **Option 2: StackView System (KDE Official Pattern - Recommended)**

**How it works (based on official KDE slideshow plugin):**
- Use `StackView` with `replace()` method (not push/pop)
- Create image component in background (`pendingImage`)
- Wait for image to load (`statusChanged` signal)
- Replace current image with `view.replace(pendingImage, {}, QQC2.StackView.Transition)`
- Configure `replaceEnter` and `replaceExit` transitions
- Support different transition types (Fade/Slide/Zoom) via transition configuration

**Implementation steps (following KDE pattern):**
1. Fix existing `StackView` (lines 374-397) - currently defined but not used correctly
2. Create `ImageComponent.qml` for individual images (similar to KDE's `StaticImageComponent.qml`)
3. Modify `loadImageWithAuth()` to:
   - Create `pendingImage` component in background
   - Connect to `statusChanged` signal
   - Call `replaceWhenLoaded()` when ready
4. Implement `replaceWhenLoaded()` function:
   - Disconnect `statusChanged` signal
   - Call `view.replace(pendingImage, {}, QQC2.StackView.Transition)`
   - Clean up old image via `onDeactivated` and `onRemoved` signals
5. Configure transitions based on `TransitionType`:
   - Fade: `OpacityAnimator` in `replaceEnter`, `PauseAnimation` in `replaceExit`
   - Slide: `XAnimator` or `YAnimator` for horizontal/vertical movement
   - Zoom: `ScaleAnimator` for zoom effect
6. Use `TransitionDuration` setting for animation duration
7. Handle edge cases (first image, errors, rapid changes)

**Complexity:** Medium-High
**Estimated effort:** 3-4 hours
**Files to modify:** `nextcloud-carousel/contents/ui/main.qml`, create `ImageComponent.qml`
**Advantages:**
- ✅ Follows official KDE pattern (proven, tested)
- ✅ Better memory management (automatic cleanup via StackView)
- ✅ Supports complex transitions (can combine multiple animators)
- ✅ Already have StackView defined (just need to fix it)

### Recommended Approach

**Choose Option 2 (StackView System - KDE Official Pattern)** because:
- ✅ **Follows official KDE Plasma pattern** (used in `org.kde.slideshow`)
- ✅ **Proven and tested** in production KDE codebase
- ✅ **Better memory management** (automatic cleanup via StackView signals)
- ✅ **Supports complex transitions** (can combine multiple animators for Slide/Zoom)
- ✅ **StackView already defined** in our code (just needs to be fixed/used correctly)
- ✅ **Consistent with KDE ecosystem** (easier for future maintainers)
- ✅ **Handles edge cases** (rapid changes, errors) via built-in StackView mechanisms

**Note:** Option 1 (Dual Image Layers) is simpler and also valid (Qt recommended), but Option 2 aligns better with KDE Plasma standards and our existing code structure.

### Detailed Implementation Plan (Option 2: StackView - KDE Official Pattern)

**Step 1: Create ImageComponent.qml**
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

**Step 2: Fix StackView in main.qml**
- Remove unused `Image` component (lines 400-443)
- Fix `StackView` configuration (lines 374-397)
- Add `pendingImage` property
- Add `loadImage()` and `replaceWhenLoaded()` functions

**Step 3: Modify loadImageWithAuth()**
- Instead of `imageView.source = dataUrl`
- Create `pendingImage` component using `ImageComponent.qml`
- Connect to `pendingImage.statusChanged` signal
- Call `replaceWhenLoaded()` when image is ready

**Step 4: Implement replaceWhenLoaded() function**
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

**Step 5: Configure StackView transitions based on TransitionType**
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

### Decision Needed

**Which approach do you prefer?**
- **A)** Implement transition system (Option 1: Dual Image Layers) - **RECOMMENDED**
- **B)** Implement transition system (Option 2: StackView)
- **C)** Focus on simpler improvements first (validation, performance, preview)
- **D)** Something else?

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
