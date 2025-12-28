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
        
        # Install plugin in correct Qt6 QML path
        # Qt6 automatically searches in:
        # - /usr/lib/qt6/qml/ (system installation)
        # - ~/.local/lib/qt6/qml/ (user installation) - NOT ~/.local/share/qml/
        # This is the standard Qt6 QML plugin path according to official documentation
        if(CMAKE_INSTALL_PREFIX STREQUAL "/usr" OR CMAKE_INSTALL_PREFIX MATCHES "^/usr/")
            # System installation
            set(QML_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib/qt6/qml/org/nextcloud/carousel")
        else()
            # User installation - use ~/.local/lib/qt6/qml/ (Qt6 standard path)
            set(QML_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib/qt6/qml/org/nextcloud/carousel")
        endif()
        set(PLUGIN_CAROUSEL_NAME "org.nextcloud.carousel")
        set(PLUGIN_CAROUSEL_DIR_TEMP "${CMAKE_INSTALL_PREFIX}/share/plasma/wallpapers/${PLUGIN_CAROUSEL_NAME}")
        set(QML_PLUGIN_DIR "${PLUGIN_CAROUSEL_DIR_TEMP}/contents/code")
        
        # Install plugin to user QML import path
        install(TARGETS nextcloudimageprovider
            DESTINATION ${QML_INSTALL_DIR}
        )
        
        # Install qmldir to user QML import path
        install(FILES nextcloud-carousel/contents/code/qmldir
            DESTINATION ${QML_INSTALL_DIR}
        )
        
        # Also install in wallpaper plugin directory (backup location)
        install(TARGETS nextcloudimageprovider
            DESTINATION ${QML_PLUGIN_DIR}
        )
        
        install(FILES nextcloud-carousel/contents/code/qmldir
            DESTINATION ${QML_PLUGIN_DIR}
        )
        
        message(STATUS "✅ ImageProvider C++ component will be built")
        message(STATUS "   Install directory: ${QML_INSTALL_DIR}")
        message(STATUS "   Qt6 automatically searches in ~/.local/lib/qt6/qml/ for user installations")
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
