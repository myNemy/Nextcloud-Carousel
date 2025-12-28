/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef IMAGEPROVIDER_H
#define IMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QUrl>
#include <QHash>
#include <QMutex>

// QQuickImageProvider already inherits from QObject (via QQmlImageProviderBase)
class ImageProvider : public QQuickImageProvider
{
    Q_OBJECT

public:
    explicit ImageProvider();
    ~ImageProvider();

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;

    // QML-invocable methods
    Q_INVOKABLE QString downloadAndCache(const QString &url, const QString &username, const QString &password);
    Q_INVOKABLE void clearCache();
    Q_INVOKABLE bool isAvailable() const { return true; }
    Q_INVOKABLE QString getCacheKey(const QString &url);

signals:
    void imageReady(const QString &cacheKey, const QString &filePath);

private slots:
    void downloadFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
    QHash<QString, QString> m_cache;  // URL -> temp file path
    QHash<QNetworkReply*, QString> m_downloads;  // Reply -> URL
    QMutex m_mutex;
    QString m_tempDir;

    QString createTempFile(const QByteArray &data, const QString &extension);
};

#endif // IMAGEPROVIDER_H

