cmake_minimum_required(VERSION 3.16)
project(nextcloud-plasma-addon VERSION 1.0.0 LANGUAGES)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

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

