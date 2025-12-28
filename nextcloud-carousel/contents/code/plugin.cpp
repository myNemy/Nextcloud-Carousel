/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include <QQmlEngine>
#include <QQmlExtensionPlugin>
#include <QJSEngine>
#include <QThread>
#include <QCoreApplication>
#include "nextclouddownloader.h"

class NextcloudDownloaderSingleton
{
public:
    NextcloudDownloader *instance()
    {
        static NextcloudDownloader downloader;
        return &downloader;
    }
};

Q_GLOBAL_STATIC(NextcloudDownloaderSingleton, nextcloudDownloaderSingleton)

static QObject *nextcloudDownloaderProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(scriptEngine)
    Q_UNUSED(engine)
    
    // Ensure we're in the main thread (required for QNetworkAccessManager)
    Q_ASSERT(QThread::currentThread() == QCoreApplication::instance()->thread());
    
    NextcloudDownloader *downloader = nextcloudDownloaderSingleton->instance();
    return downloader;
}

class ImageProviderPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri) override
    {
        Q_ASSERT(uri == QLatin1String("org.nextcloud.carousel"));
        // Register NextcloudDownloader as singleton - Livello 1: solo download
        qmlRegisterSingletonType<NextcloudDownloader>(uri, 1, 0, "NextcloudDownloader",
                                                       nextcloudDownloaderProvider);
    }
};

#include "plugin.moc"

