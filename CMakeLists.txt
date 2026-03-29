cmake_minimum_required(VERSION 3.16)
project(nextcloud-plasma-addon VERSION 1.0.0 LANGUAGES CXX)

# ============================================================================
# Optional C++ ImageProvider (for file temporanei optimization)
# ============================================================================
option(BUILD_IMAGEPROVIDER "Build optional C++ ImageProvider for file temporanei" ON)

if(BUILD_IMAGEPROVIDER)
    # Find Qt6 and KF6 directly (without ECM to avoid conflicts)
    # Note: QQuickImageProvider is in QtQuick, not QtQml
    find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Network)
    # Try to find KF6CoreAddons directly (more reliable across distributions)
    find_package(KF6CoreAddons REQUIRED)
    
    if(Qt6_FOUND AND KF6CoreAddons_FOUND)
        # Build NextcloudDownloader plugin (Livello 1: solo download)
        set(IMAGEPROVIDER_SOURCES
            nextcloud-carousel/contents/code/nextclouddownloader.cpp
            nextcloud-carousel/contents/code/plugin.cpp
        )
        
        # Create QML plugin library
        # CMake adds 'lib' prefix automatically on Linux for MODULE libraries
        add_library(nextcloudimageprovider MODULE ${IMAGEPROVIDER_SOURCES})
        
        target_link_libraries(nextcloudimageprovider
            Qt6::Core
            Qt6::Qml
            Qt6::Quick
            Qt6::Network
            KF6::CoreAddons
        )
        
        set_target_properties(nextcloudimageprovider PROPERTIES
            AUTOMOC ON
            CXX_STANDARD 17
            PREFIX "lib"  # Force 'lib' prefix - Qt6 QML plugins require this
            LIBRARY_OUTPUT_NAME "nextcloudimageprovider"
        )
        
        # Install plugin in standard Qt6 QML path (qmltooling, qmake --install, etc.)
        # Also install a copy under …/plasma/wallpapers/…/contents/ui/org/nextcloud/carousel (see QML_PLUGIN_DIR_WALLPAPER_UI).
        if(CMAKE_INSTALL_PREFIX STREQUAL "/usr" OR CMAKE_INSTALL_PREFIX MATCHES "^/usr/")
            # System installation
            set(QML_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib/qt6/qml/org/nextcloud/carousel")
        else()
            # User installation - use ~/.local/lib/qt6/qml/ (Qt6 standard path)
            set(QML_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib/qt6/qml/org/nextcloud/carousel")
        endif()
        set(PLUGIN_CAROUSEL_NAME "org.nextcloud.carousel")
        set(PLUGIN_CAROUSEL_DIR_TEMP "${CMAKE_INSTALL_PREFIX}/share/plasma/wallpapers/${PLUGIN_CAROUSEL_NAME}")
        # Plasmashell loads main.qml from contents/ui/; the engine adds that directory to QML import paths,
        # so org/nextcloud/carousel must live under contents/ui/ (no QML_IMPORT_PATH needed for wallpaper).
        set(QML_PLUGIN_DIR_WALLPAPER_UI "${PLUGIN_CAROUSEL_DIR_TEMP}/contents/ui/org/nextcloud/carousel")
        
        # Install plugin to standard Qt QML path (qmake/cmake user prefix, system /usr, etc.)
        install(TARGETS nextcloudimageprovider
            DESTINATION ${QML_INSTALL_DIR}
        )
        
        install(FILES nextcloud-carousel/contents/code/qmldir
            DESTINATION ${QML_INSTALL_DIR}
        )
        
        # Same module inside the wallpaper package — plasmashell resolves import org.nextcloud.carousel here
        install(TARGETS nextcloudimageprovider
            DESTINATION ${QML_PLUGIN_DIR_WALLPAPER_UI}
        )
        
        install(FILES nextcloud-carousel/contents/code/qmldir
            DESTINATION ${QML_PLUGIN_DIR_WALLPAPER_UI}
        )
        
        message(STATUS "✅ ImageProvider C++ component will be built")
        message(STATUS "   Install directory: ${QML_INSTALL_DIR}")
        message(STATUS "   Wallpaper-resolved module: ${QML_PLUGIN_DIR_WALLPAPER_UI}")
    else()
        message(WARNING "⚠️  Qt6 or KF6 not found - ImageProvider will be skipped")
        set(BUILD_IMAGEPROVIDER OFF)
    endif()
else()
    message(STATUS "ℹ️  ImageProvider build disabled")
endif()

# ============================================================================
# ECM for plugin file installation (only if needed)
# ============================================================================
# Set default install directory first (fallback)
if(NOT DEFINED KDE_INSTALL_FULL_DATADIR)
    set(KDE_INSTALL_FULL_DATADIR "${CMAKE_INSTALL_PREFIX}/share")
endif()

find_package(ECM QUIET NO_MODULE)
if(ECM_FOUND)
    set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
    include(KDEInstallDirs)
    include(KDECMakeSettings)
    include(KDECompilerSettings NO_POLICY_SCOPE)
    include(FeatureSummary)
    # KDEInstallDirs may override KDE_INSTALL_FULL_DATADIR, that's fine
endif()

# ============================================================================
# Nextcloud Carousel Plugin (Images)
# ============================================================================
set(PLUGIN_CAROUSEL_NAME "org.nextcloud.carousel")
set(PLUGIN_CAROUSEL_DIR "${KDE_INSTALL_FULL_DATADIR}/plasma/wallpapers/${PLUGIN_CAROUSEL_NAME}")

# Install wallpaper plugin files
install(DIRECTORY nextcloud-carousel/
    DESTINATION ${PLUGIN_CAROUSEL_DIR}
    USE_SOURCE_PERMISSIONS
)

# ============================================================================
# Nextcloud Video Plugin
# ============================================================================
set(PLUGIN_VIDEO_NAME "org.nextcloud.video")
set(PLUGIN_VIDEO_DIR "${KDE_INSTALL_FULL_DATADIR}/plasma/wallpapers/${PLUGIN_VIDEO_NAME}")

# Install wallpaper plugin files
install(DIRECTORY nextcloud-video/
    DESTINATION ${PLUGIN_VIDEO_DIR}
    USE_SOURCE_PERMISSIONS
)
