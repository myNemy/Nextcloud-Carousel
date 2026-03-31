/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: AGPL-3.0-or-later
*/

#include "imageprovider.h"
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QAuthenticator>
#include <QUrl>
#include <QFile>
#include <QThread>
#include <QCoreApplication>

ImageProvider::ImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
    // Ensure we're in the main thread (QNetworkAccessManager requirement)
    Q_ASSERT(QThread::currentThread() == QCoreApplication::instance()->thread());
    
    m_networkManager = new QNetworkAccessManager(this);
    
    // Create temp directory in user cache
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    m_tempDir = cacheDir + "/nextcloud-carousel";
    QDir().mkpath(m_tempDir);
    
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &ImageProvider::downloadFinished);
}

ImageProvider::~ImageProvider()
{
    // Cleanup temp files
    clearCache();
}

QPixmap ImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    QMutexLocker locker(&m_mutex);
    
    // Check cache
    if (m_cache.contains(id)) {
        QString filePath = m_cache.value(id);
        if (QFileInfo::exists(filePath)) {
            QPixmap pixmap(filePath);
            if (size) *size = pixmap.size();
            return pixmap;
        } else {
            // File was deleted, remove from cache
            m_cache.remove(id);
        }
    }
    
    // Return empty pixmap if not cached
    return QPixmap();
}

QString ImageProvider::downloadAndCache(const QString &url, const QString &username, const QString &password)
{
    QString cacheKey = getCacheKey(url);
    
    // Check if already cached (with lock)
    {
        QMutexLocker locker(&m_mutex);
        if (m_cache.contains(cacheKey)) {
            QString filePath = m_cache.value(cacheKey);
            if (QFileInfo::exists(filePath)) {
                return "image://nextcloud/" + cacheKey;
            } else {
                m_cache.remove(cacheKey);
            }
        }
    }  // Release lock before network call
    
    // Start download (must be in main thread)
    QUrl qurl(url);
    QNetworkRequest request(qurl);
    
    // Set authentication
    if (!username.isEmpty() && !password.isEmpty()) {
        QString auth = username + ":" + password;
        request.setRawHeader("Authorization", "Basic " + auth.toUtf8().toBase64());
    }
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Add to downloads (with lock)
    {
        QMutexLocker locker(&m_mutex);
        m_downloads[reply] = cacheKey;
    }
    
    // Return empty string - will be updated when download finishes
    return "";
}

void ImageProvider::downloadFinished(QNetworkReply *reply)
{
    // Protect access to m_downloads with mutex (thread safety)
    QString cacheKey;
    {
        QMutexLocker locker(&m_mutex);
        if (!m_downloads.contains(reply)) {
            // Reply not in our tracking - might have been cancelled
            reply->deleteLater();
            return;
        }
        cacheKey = m_downloads.take(reply);
    }
    
    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "ImageProvider: Download failed:" << reply->errorString();
        reply->deleteLater();
        return;
    }
    
    // Read data and headers BEFORE deleteLater() (reply will be deleted)
    QByteArray data = reply->readAll();
    QString extension = "jpg";
    QString contentType = reply->header(QNetworkRequest::ContentTypeHeader).toString();
    if (contentType.contains("png")) extension = "png";
    else if (contentType.contains("webp")) extension = "webp";
    else if (contentType.contains("gif")) extension = "gif";
    
    // Now safe to delete reply
    reply->deleteLater();
    
    if (cacheKey.isEmpty()) {
        return;
    }
    
    // Create temp file
    QString filePath = createTempFile(data, extension);
    
    if (!filePath.isEmpty()) {
        {
            QMutexLocker locker(&m_mutex);
            m_cache[cacheKey] = filePath;
        }  // Release lock BEFORE emitting signal to avoid potential deadlock
        emit imageReady(cacheKey, filePath);
    }
}

QString ImageProvider::getCacheKey(const QString &url)
{
    // Use URL as cache key (simple approach)
    return QString::fromUtf8(QUrl::toPercentEncoding(url));
}

QString ImageProvider::createTempFile(const QByteArray &data, const QString &extension)
{
    QTemporaryFile tempFile(m_tempDir + "/img_XXXXXX." + extension);
    tempFile.setAutoRemove(false);  // Keep file until explicit cleanup
    
    if (tempFile.open()) {
        tempFile.write(data);
        tempFile.close();
        return tempFile.fileName();
    }
    
    return QString();
}

void ImageProvider::clearCache()
{
    QMutexLocker locker(&m_mutex);
    
    // Delete all cached files
    for (const QString &filePath : m_cache.values()) {
        QFile::remove(filePath);
    }
    
    m_cache.clear();
}

