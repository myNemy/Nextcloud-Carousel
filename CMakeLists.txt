cmake_minimum_required(VERSION 3.16)
project(nextcloud-carousel VERSION 1.0.0 LANGUAGES)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(FeatureSummary)

set(PLUGIN_NAME "org.nextcloud.carousel")
set(PLUGIN_DIR "${KDE_INSTALL_FULL_DATADIR}/plasma/wallpapers/${PLUGIN_NAME}")

# Install wallpaper plugin files
install(DIRECTORY nextcloud-carousel/
    DESTINATION ${PLUGIN_DIR}
    FILES_MATCHING
    PATTERN "*.qml"
    PATTERN "*.xml"
    PATTERN "*.json"
    PATTERN "*.desktop"
)

# Install all files recursively
install(DIRECTORY nextcloud-carousel/
    DESTINATION ${PLUGIN_DIR}
    USE_SOURCE_PERMISSIONS
)

