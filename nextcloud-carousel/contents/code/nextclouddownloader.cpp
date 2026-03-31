/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: AGPL-3.0-or-later
*/

#include "nextclouddownloader.h"
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDebug>
#include <QUrl>
#include <QFile>
#include <QThread>
#include <QCoreApplication>
#include <QDateTime>
#include <QSet>
#include <QTimer>
#include <QVariantMap>
#include <QStringList>
#include <QList>
#include <QUuid>
#include <algorithm>
#include <memory>
#include <limits>

NextcloudDownloader::NextcloudDownloader(QObject *parent)
    : QObject(parent)
{
    // Ensure we're in the main thread (QNetworkAccessManager requirement)
    Q_ASSERT(QThread::currentThread() == QCoreApplication::instance()->thread());
    
    m_networkManager = new QNetworkAccessManager(this);
    
    // Create temp directory in user cache (QStandardPaths: CacheLocation — Qt doc)
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    m_tempDir = cacheDir + "/nextcloud-carousel";
    QDir().mkpath(m_tempDir);

    // Orphans on disk are invisible to m_cache after restart; sweep must not depend only on new downloads.
    m_orphanSweepTimer = new QTimer(this);
    m_orphanSweepTimer->setInterval(4 * 60 * 1000);
    connect(m_orphanSweepTimer, &QTimer::timeout, this, [this]() {
        performOrphanSweep(false);
    });
    m_orphanSweepTimer->start();
    QTimer::singleShot(0, this, [this]() {
        performOrphanSweep(true);
    });
}

NextcloudDownloader::~NextcloudDownloader()
{
    QList<QNetworkReply *> replies;
    QList<PendingDownload *> pendings;
    {
        QMutexLocker locker(&m_mutex);
        for (auto it = m_pending.constBegin(); it != m_pending.constEnd(); ++it) {
            replies.append(it.key());
            pendings.append(it.value());
        }
        m_pending.clear();
    }
    for (PendingDownload *pd : pendings) {
        if (!pd) {
            continue;
        }
        if (pd->file) {
            pd->file->close();
        }
        QFile::remove(pd->filePath);
        delete pd;
    }
    for (QNetworkReply *reply : replies) {
        if (reply) {
            reply->abort();
            reply->deleteLater();
        }
    }
    
    clearCache();
}

QString NextcloudDownloader::downloadImage(const QString &url, 
                                           const QString &username, 
                                           const QString &password,
                                           int maxSizeMB)
{
    QString cacheKey = getCacheKey(url);
    
    // Check if already cached (with lock)
    {
        QMutexLocker locker(&m_mutex);
        if (m_cache.contains(cacheKey)) {
            QString filePath = m_cache.value(cacheKey);
            if (QFileInfo::exists(filePath)) {
                touchCacheKeyUnlocked(cacheKey);
                qDebug() << "✅ NextcloudDownloader: Image already cached:" << filePath;
                return filePath;
            }
            removeCacheEntryUnlocked(cacheKey);
        }
    }
    
    // Start download (must be in main thread)
    QUrl qurl(url);
    QNetworkRequest request(qurl);
    
    // Set timeout (60 seconds, same as QML fallback)
    // QNetworkRequest doesn't have direct timeout, but we can use QNetworkAccessManager's timeout
    // For Qt 6, we set the attribute
    request.setAttribute(QNetworkRequest::HttpPipeliningAllowedAttribute, false);
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    
    // Set authentication
    if (!username.isEmpty() && !password.isEmpty()) {
        QString auth = username + ":" + password;
        request.setRawHeader("Authorization", "Basic " + auth.toUtf8().toBase64());
    }
    
    QNetworkReply *reply = m_networkManager->get(request);
    
    // Stream to disk: QNetworkReply is a sequential QIODevice; readyRead + finished (Qt 6 doc).
    const QString partPath = m_tempDir + "/img_" + QUuid::createUuid().toString(QUuid::WithoutBraces) + QStringLiteral(".part");
    auto *pd = new PendingDownload;
    pd->originalUrl = url;
    pd->maxSizeMB = maxSizeMB;
    pd->filePath = partPath;
    pd->file = std::make_unique<QFile>(partPath);
    if (!pd->file->open(QIODevice::WriteOnly)) {
        qWarning() << "❌ NextcloudDownloader: Cannot open temp file for write:" << partPath;
        delete pd;
        reply->abort();
        reply->deleteLater();
        emit downloadFailed(url, QStringLiteral("Failed to create temporary file"));
        return QString();
    }
    
    {
        QMutexLocker locker(&m_mutex);
        m_pending.insert(reply, pd);
    }
    
    connect(reply, &QNetworkReply::readyRead, this, [this, reply]() {
        onDownloadReadyRead(reply);
    });
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onDownloadFinished(reply);
    });
    
    QPointer<QNetworkReply> replyPtr(reply);
    QPointer<NextcloudDownloader> selfPtr(this);
    QTimer::singleShot(60000, reply, [replyPtr, selfPtr, url]() {
        if (!selfPtr || !replyPtr) {
            return;
        }
        if (replyPtr->isRunning()) {
            qWarning() << "⏱️  NextcloudDownloader: Download timeout for" << url;
            replyPtr->abort();
        }
    });
    
    qDebug() << "⏳ NextcloudDownloader: Starting streaming download for" << url;
    return QString();
}

qint64 NextcloudDownloader::maxSizeBytesForMb(int maxSizeMB) const
{
    if (maxSizeMB > 0) {
        return static_cast<qint64>(maxSizeMB) * 1024 * 1024;
    }
    // 0 (or less) means "no limit"
    return std::numeric_limits<qint64>::max();
}

QString NextcloudDownloader::extensionFromContentType(const QString &contentType)
{
    const QString ct = contentType.toLower();
    if (ct.contains(QLatin1String("png"))) {
        return QStringLiteral("png");
    }
    if (ct.contains(QLatin1String("webp"))) {
        return QStringLiteral("webp");
    }
    if (ct.contains(QLatin1String("gif"))) {
        return QStringLiteral("gif");
    }
    if (ct.contains(QLatin1String("tiff")) || ct.contains(QLatin1String("tif"))) {
        return QStringLiteral("tiff");
    }
    return QStringLiteral("jpg");
}

void NextcloudDownloader::onDownloadReadyRead(QNetworkReply *reply)
{
    const QByteArray chunk = reply->readAll();
    if (chunk.isEmpty()) {
        return;
    }
    
    QMutexLocker locker(&m_mutex);
    PendingDownload *pd = m_pending.value(reply, nullptr);
    if (!pd || !pd->file || !pd->file->isOpen()) {
        return;
    }
    const qint64 maxB = maxSizeBytesForMb(pd->maxSizeMB);
    const qint64 newTotal = pd->bytesWritten + chunk.size();
    if (newTotal > maxB) {
        const int mbLimit = pd->maxSizeMB;
        locker.unlock();
        if (mbLimit > 0) {
            failPendingDownload(reply, QStringLiteral("Image too large (max %1 MB)").arg(mbLimit));
        } else {
            failPendingDownload(reply, QStringLiteral("Image too large"));
        }
        return;
    }
    const qint64 w = pd->file->write(chunk);
    if (w != chunk.size()) {
        locker.unlock();
        failPendingDownload(reply, QStringLiteral("Write error while saving download"));
        return;
    }
    pd->bytesWritten = newTotal;
}

void NextcloudDownloader::failPendingDownload(QNetworkReply *reply, const QString &errorString)
{
    QString originalUrl;
    {
        QMutexLocker locker(&m_mutex);
        PendingDownload *pd = m_pending.take(reply);
        if (pd) {
            originalUrl = pd->originalUrl;
            if (pd->file) {
                pd->file->close();
            }
            QFile::remove(pd->filePath);
            delete pd;
        }
    }
    if (!originalUrl.isEmpty()) {
        qWarning() << "❌ NextcloudDownloader:" << errorString << "for" << originalUrl;
        emit downloadFailed(originalUrl, errorString);
    }
    if (reply && reply->isRunning()) {
        reply->abort();
    }
}

void NextcloudDownloader::onDownloadFinished(QNetworkReply *reply)
{
    const QByteArray remainder = reply->readAll();
    
    PendingDownload *pd = nullptr;
    {
        QMutexLocker locker(&m_mutex);
        pd = m_pending.take(reply);
    }
    
    if (!pd) {
        reply->deleteLater();
        return;
    }
    
    const QString originalUrl = pd->originalUrl;
    
    if (reply->error() != QNetworkReply::NoError) {
        if (pd->file) {
            pd->file->close();
        }
        QFile::remove(pd->filePath);
        delete pd;
        reply->deleteLater();
        qWarning() << "❌ NextcloudDownloader: Download failed for" << originalUrl << ":" << reply->errorString();
        emit downloadFailed(originalUrl, reply->errorString());
        return;
    }
    
    if (!remainder.isEmpty()) {
        const qint64 maxB = maxSizeBytesForMb(pd->maxSizeMB);
        if (pd->bytesWritten + remainder.size() > maxB) {
            if (pd->file) {
                pd->file->close();
            }
            QFile::remove(pd->filePath);
            delete pd;
            reply->deleteLater();
            if (pd->maxSizeMB > 0) {
                emit downloadFailed(originalUrl, QStringLiteral("Image too large (max %1 MB)").arg(pd->maxSizeMB));
            } else {
                emit downloadFailed(originalUrl, QStringLiteral("Image too large"));
            }
            return;
        }
        if (pd->file->write(remainder) != remainder.size()) {
            if (pd->file) {
                pd->file->close();
            }
            QFile::remove(pd->filePath);
            delete pd;
            reply->deleteLater();
            emit downloadFailed(originalUrl, QStringLiteral("Write error while saving download"));
            return;
        }
        pd->bytesWritten += remainder.size();
    }
    
    if (pd->file) {
        pd->file->flush();
        pd->file->close();
    }
    
    const qint64 maxB = maxSizeBytesForMb(pd->maxSizeMB);
    if (pd->bytesWritten > maxB) {
        QFile::remove(pd->filePath);
        delete pd;
        reply->deleteLater();
        if (pd->maxSizeMB > 0) {
            emit downloadFailed(originalUrl, QStringLiteral("Image too large (max %1 MB)").arg(pd->maxSizeMB));
        } else {
            emit downloadFailed(originalUrl, QStringLiteral("Image too large"));
        }
        return;
    }
    
    QString contentType = reply->header(QNetworkRequest::ContentTypeHeader).toString();
    const QString ext = extensionFromContentType(contentType);
    QString finalPath = pd->filePath;
    if (pd->filePath.endsWith(QLatin1String(".part"))) {
        const QString renamed = pd->filePath.chopped(5) + QLatin1Char('.') + ext;
        if (QFile::rename(pd->filePath, renamed)) {
            finalPath = renamed;
        }
    }
    
    reply->deleteLater();
    delete pd;
    
    const QString cacheKey = getCacheKey(originalUrl);
    insertCacheEntryAndEvict(cacheKey, finalPath);
    
    qDebug() << "✅ NextcloudDownloader: Image streamed to" << finalPath;

    performOrphanSweep(false);

    emit imageDownloaded(finalPath, originalUrl);
}

void NextcloudDownloader::insertCacheEntryAndEvict(const QString &cacheKey, const QString &filePath)
{
    QMutexLocker locker(&m_mutex);
    if (m_cache.contains(cacheKey)) {
        removeCacheEntryUnlocked(cacheKey);
    }
    while (m_cache.size() >= kMaxCachedImageFiles) {
        if (!m_cacheLruOrder.isEmpty()) {
            const QString victimKey = m_cacheLruOrder.first();
            removeCacheEntryUnlocked(victimKey);
            continue;
        }
        if (!m_cache.isEmpty()) {
            removeCacheEntryUnlocked(m_cache.constBegin().key());
            continue;
        }
        break;
    }
    m_cache.insert(cacheKey, filePath);
    touchCacheKeyUnlocked(cacheKey);
}

void NextcloudDownloader::touchCacheKeyUnlocked(const QString &cacheKey)
{
    if (!m_cache.contains(cacheKey)) {
        return;
    }
    m_cacheLruOrder.removeAll(cacheKey);
    m_cacheLruOrder.append(cacheKey);
}

void NextcloudDownloader::removeCacheEntryUnlocked(const QString &cacheKey)
{
    const QString path = m_cache.take(cacheKey);
    m_cacheLruOrder.removeAll(cacheKey);
    if (!path.isEmpty()) {
        QFile::remove(path);
    }
}

QString NextcloudDownloader::getCacheKey(const QString &url)
{
    // Use URL as cache key (simple approach)
    return QString::fromUtf8(QUrl::toPercentEncoding(url));
}

void NextcloudDownloader::clearCache()
{
    QMutexLocker locker(&m_mutex);
    
    // Delete all cached files
    for (const QString &filePath : m_cache.values()) {
        QFile::remove(filePath);
    }
    
    m_cache.clear();
    m_cacheLruOrder.clear();
    qDebug() << "🧹 NextcloudDownloader: Cache cleared";
}

void NextcloudDownloader::cleanupOldFiles()
{
    performOrphanSweep(false);
}

void NextcloudDownloader::performOrphanSweep(bool bypassThrottle)
{
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    if (!bypassThrottle) {
        constexpr qint64 kMinIntervalMs = 30 * 1000;
        if (m_lastOrphanSweepMs != 0 && (nowMs - m_lastOrphanSweepMs) < kMinIntervalMs) {
            return;
        }
    }
    m_lastOrphanSweepMs = nowMs;

    QDir cacheDir(m_tempDir);
    if (!cacheDir.exists()) {
        return;
    }

    QSet<QString> activeFiles;
    {
        QMutexLocker locker(&m_mutex);
        for (const QString &filePath : m_cache.values()) {
            activeFiles.insert(filePath);
        }
    }

    // Orphans: not referenced by in-memory LRU (e.g. after eviction, crash, or plasmashell restart).
    const QDateTime orphanCutoff = QDateTime::currentDateTime().addSecs(-900); // 15 min
    const QDateTime partCutoff = QDateTime::currentDateTime().addSecs(-3600);   // stale .part

    QStringList filters;
    filters << QStringLiteral("*.jpg") << QStringLiteral("*.jpeg") << QStringLiteral("*.png")
            << QStringLiteral("*.webp") << QStringLiteral("*.gif") << QStringLiteral("*.tiff")
            << QStringLiteral("*.part");

    const QFileInfoList fileList = cacheDir.entryInfoList(filters, QDir::Files);

    int removedCount = 0;
    qint64 freedSpace = 0;

    QVector<QPair<QDateTime, QString>> youngOrphans;
    youngOrphans.reserve(64);

    for (const QFileInfo &fileInfo : fileList) {
        const QString filePath = fileInfo.absoluteFilePath();
        if (activeFiles.contains(filePath)) {
            continue;
        }

        if (filePath.endsWith(QLatin1String(".part"))) {
            if (fileInfo.lastModified() < partCutoff) {
                const qint64 size = fileInfo.size();
                if (QFile::remove(filePath)) {
                    removedCount++;
                    freedSpace += size;
                }
            }
            continue;
        }

        if (fileInfo.lastModified() < orphanCutoff) {
            const qint64 size = fileInfo.size();
            if (QFile::remove(filePath)) {
                removedCount++;
                freedSpace += size;
            }
        } else {
            youngOrphans.append({fileInfo.lastModified(), filePath});
        }
    }

    // If many fresh orphans pile up (burst of unique URLs), trim oldest by mtime regardless of age.
    constexpr int kMaxYoungOrphans = kMaxCachedImageFiles * 3;
    if (youngOrphans.size() > kMaxYoungOrphans) {
        std::sort(youngOrphans.begin(), youngOrphans.end(), [](const auto &a, const auto &b) {
            return a.first < b.first;
        });
        const int toRemove = static_cast<int>(youngOrphans.size()) - kMaxCachedImageFiles;
        for (int i = 0; i < toRemove; ++i) {
            const QString &p = youngOrphans.at(i).second;
            const QFileInfo fi(p);
            const qint64 size = fi.size();
            if (QFile::remove(p)) {
                removedCount++;
                freedSpace += size;
            }
        }
    }

    if (removedCount > 0) {
        qDebug() << "🧹 NextcloudDownloader: Orphan sweep removed" << removedCount << "file(s), freed"
                 << (freedSpace / 1024 / 1024) << "MB";
    }
}

bool NextcloudDownloader::isCached(const QString &url)
{
    QMutexLocker locker(&m_mutex);
    QString cacheKey = getCacheKey(url);
    if (m_cache.contains(cacheKey)) {
        QString filePath = m_cache.value(cacheKey);
        if (QFileInfo::exists(filePath)) {
            touchCacheKeyUnlocked(cacheKey);
            return true;
        }
        removeCacheEntryUnlocked(cacheKey);
    }
    return false;
}

QString NextcloudDownloader::getLocalFilePath(const QString &url)
{
    QMutexLocker locker(&m_mutex);
    QString cacheKey = getCacheKey(url);
    if (m_cache.contains(cacheKey)) {
        QString filePath = m_cache.value(cacheKey);
        if (QFileInfo::exists(filePath)) {
            touchCacheKeyUnlocked(cacheKey);
            return filePath;
        }
        removeCacheEntryUnlocked(cacheKey);
    }
    return QString();
}

int NextcloudDownloader::getExifOrientation(const QString &filePath)
{
    if (filePath.isEmpty() || !QFileInfo::exists(filePath)) {
        return 0;
    }
    
    // Read first 64KB of file (EXIF data is always in first segments)
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        return 0;
    }
    
    QByteArray data = file.read(65536);  // Read first 64KB
    file.close();
    
    if (data.size() < 8) {
        return 0;
    }
    
    // Simple EXIF orientation parser (similar to QML version)
    // Look for JPEG APP1 marker (0xFFE1) with EXIF header
    const uchar *bytes = reinterpret_cast<const uchar*>(data.constData());
    int tiffOffset = -1;
    bool isIntel = false;
    
    // Check if JPEG
    if (data.size() >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
        // Search for APP1 marker (0xFFE1) with EXIF
        for (int i = 2; i < data.size() - 6; i++) {
            if (bytes[i] == 0xFF && bytes[i + 1] == 0xE1) {
                // Found APP1 segment
                int segmentLength = (bytes[i + 2] << 8) | bytes[i + 3];
                int segmentStart = i + 4;
                
                if (segmentStart + 6 <= data.size()) {
                    // Check for "Exif\0\0" header
                    if (data.mid(segmentStart, 6) == QByteArray("Exif\0\0", 6)) {
                        tiffOffset = segmentStart + 6;
                        break;
                    }
                }
                i += 2 + segmentLength;
            } else if (bytes[i] == 0xFF && bytes[i + 1] == 0xDA) {
                // Start of scan, no more segments
                break;
            }
        }
    }
    
    if (tiffOffset < 0 || tiffOffset + 8 > data.size()) {
        return 0;
    }
    
    // Check byte order
    isIntel = (bytes[tiffOffset] == 0x49 && bytes[tiffOffset + 1] == 0x49);
    
    // Read IFD0 offset
    int ifd0OffsetAddr = tiffOffset + 4;
    if (ifd0OffsetAddr + 4 > data.size()) {
        return 0;
    }
    
    quint32 ifd0Offset;
    if (isIntel) {
        ifd0Offset = bytes[ifd0OffsetAddr] | (bytes[ifd0OffsetAddr + 1] << 8) |
                     (bytes[ifd0OffsetAddr + 2] << 16) | (bytes[ifd0OffsetAddr + 3] << 24);
    } else {
        ifd0Offset = (bytes[ifd0OffsetAddr] << 24) | (bytes[ifd0OffsetAddr + 1] << 16) |
                     (bytes[ifd0OffsetAddr + 2] << 8) | bytes[ifd0OffsetAddr + 3];
    }
    
    int ifd0Addr = tiffOffset + ifd0Offset;
    if (ifd0Addr + 2 > data.size()) {
        return 0;
    }
    
    // Read number of entries
    quint16 numEntries;
    if (isIntel) {
        numEntries = bytes[ifd0Addr] | (bytes[ifd0Addr + 1] << 8);
    } else {
        numEntries = (bytes[ifd0Addr] << 8) | bytes[ifd0Addr + 1];
    }
    
    // Search for Orientation tag (0x0112)
    int entryOffset = ifd0Addr + 2;
    for (int e = 0; e < numEntries && entryOffset + 12 <= data.size(); e++) {
        quint16 tag;
        if (isIntel) {
            tag = bytes[entryOffset] | (bytes[entryOffset + 1] << 8);
        } else {
            tag = (bytes[entryOffset] << 8) | bytes[entryOffset + 1];
        }
        
        if (tag == 0x0112) {  // Orientation tag
            int valueOffset = entryOffset + 8;
            quint16 orientation;
            if (isIntel) {
                orientation = bytes[valueOffset] | (bytes[valueOffset + 1] << 8);
            } else {
                orientation = (bytes[valueOffset] << 8) | bytes[valueOffset + 1];
            }
            
            // Convert EXIF orientation to rotation angle
            switch (orientation) {
            case 1: return 0;      // Normal
            case 3: return 180;    // Rotated 180°
            case 6: return 90;     // Rotated 90° clockwise -> need 90° counter-clockwise
            case 8: return -90;    // Rotated 90° counter-clockwise -> need 90° clockwise
            default: return 0;
            }
        }
        
        entryOffset += 12;
    }
    
    return 0;  // Orientation not found
}

QVariantMap NextcloudDownloader::getAllExifData(const QString &filePath)
{
    QVariantMap result;
    
    // Initialize with default values (matching QML currentExifData structure)
    result["orientation"] = 0;
    result["dateTime"] = "";
    result["make"] = "";
    result["model"] = "";
    result["iso"] = 0;
    result["fNumber"] = 0.0;
    result["exposureTime"] = "";
    result["latitude"] = 0.0;
    result["longitude"] = 0.0;
    result["latitudeRef"] = "";
    result["longitudeRef"] = "";
    result["hasData"] = false;
    
    qDebug() << "🔍 NextcloudDownloader::getAllExifData called for:" << filePath;
    
    if (filePath.isEmpty() || !QFileInfo::exists(filePath)) {
        qDebug() << "⚠️  File path is empty or file doesn't exist";
        return result;
    }
    
    // Read first 64KB of file (EXIF data is always in first segments)
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        return result;
    }
    
    QByteArray data = file.read(65536);  // Read first 64KB
    file.close();
    
    if (data.size() < 8) {
        return result;
    }
    
    const uchar *bytes = reinterpret_cast<const uchar*>(data.constData());
    int tiffOffset = -1;
    bool isIntel = false;
    
    // Check if JPEG (starts with 0xFFD8)
    if (data.size() >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
        // Search for APP1 marker (0xFFE1) with EXIF
        for (int i = 2; i < data.size() - 6; i++) {
            if (bytes[i] == 0xFF && bytes[i + 1] == 0xE1) {
                int segmentLength = (bytes[i + 2] << 8) | bytes[i + 3];
                int segmentStart = i + 4;
                
                if (segmentStart + 6 <= data.size()) {
                    if (data.mid(segmentStart, 6) == QByteArray("Exif\0\0", 6)) {
                        tiffOffset = segmentStart + 6;
                        break;
                    }
                }
                i += 2 + segmentLength;
            } else if (bytes[i] == 0xFF && bytes[i + 1] == 0xDA) {
                break;  // Start of scan
            }
        }
    } else if ((bytes[0] == 0x49 && bytes[1] == 0x49) || (bytes[0] == 0x4D && bytes[1] == 0x4D)) {
        // TIFF file (Intel: 0x4949, Motorola: 0x4D4D)
        tiffOffset = 0;
    } else {
        // Try to find "Exif\0\0" header (for WebP and other formats)
        for (int j = 0; j < data.size() - 6; j++) {
            if (bytes[j] == 0x45 && bytes[j + 1] == 0x78 && bytes[j + 2] == 0x69 && 
                bytes[j + 3] == 0x66 && bytes[j + 4] == 0x00 && bytes[j + 5] == 0x00) {
                tiffOffset = j + 6;
                break;
            }
        }
    }
    
    if (tiffOffset < 0 || tiffOffset + 8 > data.size()) {
        return result;
    }
    
    // Check byte order
    isIntel = (bytes[tiffOffset] == 0x49 && bytes[tiffOffset + 1] == 0x49);
    
    // Read IFD0 offset
    int ifd0OffsetAddr = tiffOffset + 4;
    if (ifd0OffsetAddr + 4 > data.size()) {
        return result;
    }
    
    quint32 ifd0Offset;
    if (isIntel) {
        ifd0Offset = bytes[ifd0OffsetAddr] | (bytes[ifd0OffsetAddr + 1] << 8) |
                     (bytes[ifd0OffsetAddr + 2] << 16) | (bytes[ifd0OffsetAddr + 3] << 24);
    } else {
        ifd0Offset = (bytes[ifd0OffsetAddr] << 24) | (bytes[ifd0OffsetAddr + 1] << 16) |
                     (bytes[ifd0OffsetAddr + 2] << 8) | bytes[ifd0OffsetAddr + 3];
    }
    
    int ifd0Addr = tiffOffset + ifd0Offset;
    if (ifd0Addr + 2 > data.size()) {
        return result;
    }
    
    // Read number of entries
    quint16 numEntries;
    if (isIntel) {
        numEntries = bytes[ifd0Addr] | (bytes[ifd0Addr + 1] << 8);
    } else {
        numEntries = (bytes[ifd0Addr] << 8) | bytes[ifd0Addr + 1];
    }
    
    int entryOffset = ifd0Addr + 2;
    int exifIFDOffset = -1;
    int gpsIFDOffset = -1;
    
    // First pass: Read IFD0 tags and find EXIF IFD and GPS IFD offsets
    for (int e = 0; e < numEntries && entryOffset + 12 <= data.size(); e++) {
        quint16 tag;
        if (isIntel) {
            tag = bytes[entryOffset] | (bytes[entryOffset + 1] << 8);
        } else {
            tag = (bytes[entryOffset] << 8) | bytes[entryOffset + 1];
        }
        
        quint16 type;
        if (isIntel) {
            type = bytes[entryOffset + 2] | (bytes[entryOffset + 3] << 8);
        } else {
            type = (bytes[entryOffset + 2] << 8) | bytes[entryOffset + 3];
        }
        
        quint32 count;
        if (isIntel) {
            count = bytes[entryOffset + 4] | (bytes[entryOffset + 5] << 8) |
                    (bytes[entryOffset + 6] << 16) | (bytes[entryOffset + 7] << 24);
        } else {
            count = (bytes[entryOffset + 4] << 24) | (bytes[entryOffset + 5] << 16) |
                    (bytes[entryOffset + 6] << 8) | bytes[entryOffset + 7];
        }
        
        int valueOffset = entryOffset + 8;
        
        // Read Orientation (0x0112) - Short type
        if (tag == 0x0112 && type == 3 && count == 1) {
            quint16 orientation;
            if (isIntel) {
                orientation = bytes[valueOffset] | (bytes[valueOffset + 1] << 8);
            } else {
                orientation = (bytes[valueOffset] << 8) | bytes[valueOffset + 1];
            }
            
            int rotationAngle = 0;
            switch (orientation) {
            case 1: rotationAngle = 0; break;
            case 3: rotationAngle = 180; break;
            case 6: rotationAngle = 90; break;
            case 8: rotationAngle = -90; break;
            default: rotationAngle = 0;
            }
            result["orientation"] = rotationAngle;
            result["hasData"] = true;
        }
        // Read DateTime (0x0132) - ASCII string
        else if (tag == 0x0132 && type == 2) {
            QString dateTime;
            if (count <= 4) {
                // Value stored directly
                for (quint32 c = 0; c < count - 1 && valueOffset + c < data.size(); c++) {
                    dateTime += QChar(bytes[valueOffset + c]);
                }
            } else {
                // Value stored at offset
                quint32 stringOffset;
                if (isIntel) {
                    stringOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) |
                                  (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24);
                } else {
                    stringOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) |
                                  (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3];
                }
                int stringAddr = tiffOffset + stringOffset;
                for (quint32 c = 0; c < count - 1 && stringAddr + c < data.size(); c++) {
                    dateTime += QChar(bytes[stringAddr + c]);
                }
            }
            if (!dateTime.isEmpty()) {
                result["dateTime"] = dateTime;
                result["hasData"] = true;
            }
        }
        // Read Make (0x010F) - ASCII string
        else if (tag == 0x010F && type == 2) {
            QString make;
            if (count <= 4) {
                for (quint32 c = 0; c < count - 1 && valueOffset + c < data.size(); c++) {
                    make += QChar(bytes[valueOffset + c]);
                }
            } else {
                quint32 stringOffset;
                if (isIntel) {
                    stringOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) |
                                  (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24);
                } else {
                    stringOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) |
                                  (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3];
                }
                int stringAddr = tiffOffset + stringOffset;
                for (quint32 c = 0; c < count - 1 && stringAddr + c < data.size(); c++) {
                    make += QChar(bytes[stringAddr + c]);
                }
            }
            if (!make.isEmpty()) {
                result["make"] = make;
                result["hasData"] = true;
            }
        }
        // Read Model (0x0110) - ASCII string
        else if (tag == 0x0110 && type == 2) {
            QString model;
            if (count <= 4) {
                for (quint32 c = 0; c < count - 1 && valueOffset + c < data.size(); c++) {
                    model += QChar(bytes[valueOffset + c]);
                }
            } else {
                quint32 stringOffset;
                if (isIntel) {
                    stringOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) |
                                  (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24);
                } else {
                    stringOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) |
                                  (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3];
                }
                int stringAddr = tiffOffset + stringOffset;
                for (quint32 c = 0; c < count - 1 && stringAddr + c < data.size(); c++) {
                    model += QChar(bytes[stringAddr + c]);
                }
            }
            if (!model.isEmpty()) {
                result["model"] = model;
                result["hasData"] = true;
            }
        }
        // Find ExifOffset (0x8769) - unsigned long
        else if (tag == 0x8769 && type == 4 && count == 1) {
            if (isIntel) {
                exifIFDOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) |
                               (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24);
            } else {
                exifIFDOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) |
                               (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3];
            }
        }
        // Find GPSInfo (0x8825) - unsigned long
        else if (tag == 0x8825 && type == 4 && count == 1) {
            if (isIntel) {
                gpsIFDOffset = bytes[valueOffset] | (bytes[valueOffset + 1] << 8) |
                              (bytes[valueOffset + 2] << 16) | (bytes[valueOffset + 3] << 24);
            } else {
                gpsIFDOffset = (bytes[valueOffset] << 24) | (bytes[valueOffset + 1] << 16) |
                              (bytes[valueOffset + 2] << 8) | bytes[valueOffset + 3];
            }
        }
        
        entryOffset += 12;
    }
    
    // Read EXIF IFD for ISO, FNumber, ExposureTime
    if (exifIFDOffset >= 0) {
        int exifIFDAddr = tiffOffset + exifIFDOffset;
        if (exifIFDAddr + 2 <= data.size()) {
            quint16 numExifEntries;
            if (isIntel) {
                numExifEntries = bytes[exifIFDAddr] | (bytes[exifIFDAddr + 1] << 8);
            } else {
                numExifEntries = (bytes[exifIFDAddr] << 8) | bytes[exifIFDAddr + 1];
            }
            
            int exifEntryOffset = exifIFDAddr + 2;
            for (int e3 = 0; e3 < numExifEntries && exifEntryOffset + 12 <= data.size(); e3++) {
                quint16 tag3;
                if (isIntel) {
                    tag3 = bytes[exifEntryOffset] | (bytes[exifEntryOffset + 1] << 8);
                } else {
                    tag3 = (bytes[exifEntryOffset] << 8) | bytes[exifEntryOffset + 1];
                }
                
                quint16 type3;
                if (isIntel) {
                    type3 = bytes[exifEntryOffset + 2] | (bytes[exifEntryOffset + 3] << 8);
                } else {
                    type3 = (bytes[exifEntryOffset + 2] << 8) | bytes[exifEntryOffset + 3];
                }
                
                quint32 count3;
                if (isIntel) {
                    count3 = bytes[exifEntryOffset + 4] | (bytes[exifEntryOffset + 5] << 8) |
                            (bytes[exifEntryOffset + 6] << 16) | (bytes[exifEntryOffset + 7] << 24);
                } else {
                    count3 = (bytes[exifEntryOffset + 4] << 24) | (bytes[exifEntryOffset + 5] << 16) |
                            (bytes[exifEntryOffset + 6] << 8) | bytes[exifEntryOffset + 7];
                }
                
                int valueOffset3 = exifEntryOffset + 8;
                
                // Read ISO (0x8827) - Short type
                if (tag3 == 0x8827 && type3 == 3 && count3 == 1) {
                    quint16 isoValue;
                    if (isIntel) {
                        isoValue = bytes[valueOffset3] | (bytes[valueOffset3 + 1] << 8);
                    } else {
                        isoValue = (bytes[valueOffset3] << 8) | bytes[valueOffset3 + 1];
                    }
                    result["iso"] = isoValue;
                    result["hasData"] = true;
                }
                // Read FNumber (0x829D) and ExposureTime (0x829A) - Rational type
                else if ((tag3 == 0x829D || tag3 == 0x829A) && type3 == 5 && count3 == 1) {
                    quint32 rationalOffset3;
                    if (isIntel) {
                        rationalOffset3 = bytes[valueOffset3] | (bytes[valueOffset3 + 1] << 8) |
                                         (bytes[valueOffset3 + 2] << 16) | (bytes[valueOffset3 + 3] << 24);
                    } else {
                        rationalOffset3 = (bytes[valueOffset3] << 24) | (bytes[valueOffset3 + 1] << 16) |
                                         (bytes[valueOffset3 + 2] << 8) | bytes[valueOffset3 + 3];
                    }
                    
                    int rationalAddr3 = tiffOffset + rationalOffset3;
                    if (rationalAddr3 + 8 <= data.size()) {
                        qint32 numerator3, denominator3;
                        if (isIntel) {
                            numerator3 = bytes[rationalAddr3] | (bytes[rationalAddr3 + 1] << 8) |
                                        (bytes[rationalAddr3 + 2] << 16) | (bytes[rationalAddr3 + 3] << 24);
                            denominator3 = bytes[rationalAddr3 + 4] | (bytes[rationalAddr3 + 5] << 8) |
                                          (bytes[rationalAddr3 + 6] << 16) | (bytes[rationalAddr3 + 7] << 24);
                        } else {
                            numerator3 = (bytes[rationalAddr3] << 24) | (bytes[rationalAddr3 + 1] << 16) |
                                        (bytes[rationalAddr3 + 2] << 8) | bytes[rationalAddr3 + 3];
                            denominator3 = (bytes[rationalAddr3 + 4] << 24) | (bytes[rationalAddr3 + 5] << 16) |
                                          (bytes[rationalAddr3 + 6] << 8) | bytes[rationalAddr3 + 7];
                        }
                        
                        if (denominator3 > 0) {
                            if (tag3 == 0x829D) {  // FNumber
                                double fNum = static_cast<double>(numerator3) / denominator3;
                                result["fNumber"] = fNum;
                                result["hasData"] = true;
                            } else if (tag3 == 0x829A) {  // ExposureTime
                                double expTime = static_cast<double>(numerator3) / denominator3;
                                QString expTimeStr = (expTime < 1.0) ? 
                                    QString("1/%1s").arg(qRound(1.0 / expTime)) : 
                                    QString("%1s").arg(expTime, 0, 'f', 1);
                                result["exposureTime"] = expTimeStr;
                                result["hasData"] = true;
                            }
                        }
                    }
                }
                
                exifEntryOffset += 12;
            }
        }
    }
    
    // Read GPS IFD for GPS coordinates
    if (gpsIFDOffset >= 0) {
        int gpsIFDAddr = tiffOffset + gpsIFDOffset;
        if (gpsIFDAddr + 2 <= data.size()) {
            quint16 numGpsEntries;
            if (isIntel) {
                numGpsEntries = bytes[gpsIFDAddr] | (bytes[gpsIFDAddr + 1] << 8);
            } else {
                numGpsEntries = (bytes[gpsIFDAddr] << 8) | bytes[gpsIFDAddr + 1];
            }
            
            int gpsEntryOffset = gpsIFDAddr + 2;
            QString gpsLatitudeRef, gpsLongitudeRef;
            QList<double> gpsLatitude, gpsLongitude;
            
            for (int e5 = 0; e5 < numGpsEntries && gpsEntryOffset + 12 <= data.size(); e5++) {
                quint16 tag5;
                if (isIntel) {
                    tag5 = bytes[gpsEntryOffset] | (bytes[gpsEntryOffset + 1] << 8);
                } else {
                    tag5 = (bytes[gpsEntryOffset] << 8) | bytes[gpsEntryOffset + 1];
                }
                
                quint16 type5;
                if (isIntel) {
                    type5 = bytes[gpsEntryOffset + 2] | (bytes[gpsEntryOffset + 3] << 8);
                } else {
                    type5 = (bytes[gpsEntryOffset + 2] << 8) | bytes[gpsEntryOffset + 3];
                }
                
                quint32 count5;
                if (isIntel) {
                    count5 = bytes[gpsEntryOffset + 4] | (bytes[gpsEntryOffset + 5] << 8) |
                            (bytes[gpsEntryOffset + 6] << 16) | (bytes[gpsEntryOffset + 7] << 24);
                } else {
                    count5 = (bytes[gpsEntryOffset + 4] << 24) | (bytes[gpsEntryOffset + 5] << 16) |
                            (bytes[gpsEntryOffset + 6] << 8) | bytes[gpsEntryOffset + 7];
                }
                
                int valueOffset5 = gpsEntryOffset + 8;
                
                // Read GPSLatitudeRef (0x0001) - ASCII string
                if (tag5 == 0x0001 && type5 == 2 && count5 == 2) {
                    gpsLatitudeRef = QChar(bytes[valueOffset5]);
                }
                // Read GPSLongitudeRef (0x0003) - ASCII string
                else if (tag5 == 0x0003 && type5 == 2 && count5 == 2) {
                    gpsLongitudeRef = QChar(bytes[valueOffset5]);
                }
                // Read GPSLatitude (0x0002) - Rational array (3 values: degrees, minutes, seconds)
                else if (tag5 == 0x0002 && type5 == 5 && count5 == 3) {
                    quint32 rationalOffset5;
                    if (isIntel) {
                        rationalOffset5 = bytes[valueOffset5] | (bytes[valueOffset5 + 1] << 8) |
                                         (bytes[valueOffset5 + 2] << 16) | (bytes[valueOffset5 + 3] << 24);
                    } else {
                        rationalOffset5 = (bytes[valueOffset5] << 24) | (bytes[valueOffset5 + 1] << 16) |
                                         (bytes[valueOffset5 + 2] << 8) | bytes[valueOffset5 + 3];
                    }
                    
                    int rationalAddr5 = tiffOffset + rationalOffset5;
                    for (int i = 0; i < 3 && rationalAddr5 + 8 <= data.size(); i++) {
                        qint32 num, den;
                        if (isIntel) {
                            num = bytes[rationalAddr5] | (bytes[rationalAddr5 + 1] << 8) |
                                  (bytes[rationalAddr5 + 2] << 16) | (bytes[rationalAddr5 + 3] << 24);
                            den = bytes[rationalAddr5 + 4] | (bytes[rationalAddr5 + 5] << 8) |
                                  (bytes[rationalAddr5 + 6] << 16) | (bytes[rationalAddr5 + 7] << 24);
                        } else {
                            num = (bytes[rationalAddr5] << 24) | (bytes[rationalAddr5 + 1] << 16) |
                                  (bytes[rationalAddr5 + 2] << 8) | bytes[rationalAddr5 + 3];
                            den = (bytes[rationalAddr5 + 4] << 24) | (bytes[rationalAddr5 + 5] << 16) |
                                  (bytes[rationalAddr5 + 6] << 8) | bytes[rationalAddr5 + 7];
                        }
                        if (den > 0) {
                            gpsLatitude.append(static_cast<double>(num) / den);
                        }
                        rationalAddr5 += 8;
                    }
                }
                // Read GPSLongitude (0x0004) - Rational array (3 values: degrees, minutes, seconds)
                else if (tag5 == 0x0004 && type5 == 5 && count5 == 3) {
                    quint32 rationalOffset5;
                    if (isIntel) {
                        rationalOffset5 = bytes[valueOffset5] | (bytes[valueOffset5 + 1] << 8) |
                                         (bytes[valueOffset5 + 2] << 16) | (bytes[valueOffset5 + 3] << 24);
                    } else {
                        rationalOffset5 = (bytes[valueOffset5] << 24) | (bytes[valueOffset5 + 1] << 16) |
                                         (bytes[valueOffset5 + 2] << 8) | bytes[valueOffset5 + 3];
                    }
                    
                    int rationalAddr5 = tiffOffset + rationalOffset5;
                    for (int i = 0; i < 3 && rationalAddr5 + 8 <= data.size(); i++) {
                        qint32 num, den;
                        if (isIntel) {
                            num = bytes[rationalAddr5] | (bytes[rationalAddr5 + 1] << 8) |
                                  (bytes[rationalAddr5 + 2] << 16) | (bytes[rationalAddr5 + 3] << 24);
                            den = bytes[rationalAddr5 + 4] | (bytes[rationalAddr5 + 5] << 8) |
                                  (bytes[rationalAddr5 + 6] << 16) | (bytes[rationalAddr5 + 7] << 24);
                        } else {
                            num = (bytes[rationalAddr5] << 24) | (bytes[rationalAddr5 + 1] << 16) |
                                  (bytes[rationalAddr5 + 2] << 8) | bytes[rationalAddr5 + 3];
                            den = (bytes[rationalAddr5 + 4] << 24) | (bytes[rationalAddr5 + 5] << 16) |
                                  (bytes[rationalAddr5 + 6] << 8) | bytes[rationalAddr5 + 7];
                        }
                        if (den > 0) {
                            gpsLongitude.append(static_cast<double>(num) / den);
                        }
                        rationalAddr5 += 8;
                    }
                }
                
                gpsEntryOffset += 12;
            }
            
            // Convert GPS coordinates from degrees/minutes/seconds to decimal degrees
            if (gpsLatitude.size() == 3 && gpsLongitude.size() == 3) {
                double lat = gpsLatitude[0] + gpsLatitude[1] / 60.0 + gpsLatitude[2] / 3600.0;
                if (gpsLatitudeRef == "S") lat = -lat;
                
                double lon = gpsLongitude[0] + gpsLongitude[1] / 60.0 + gpsLongitude[2] / 3600.0;
                if (gpsLongitudeRef == "W") lon = -lon;
                
                result["latitude"] = lat;
                result["longitude"] = lon;
                result["latitudeRef"] = gpsLatitudeRef;
                result["longitudeRef"] = gpsLongitudeRef;
                result["hasData"] = true;
            }
        }
    }
    
    qDebug() << "✅ NextcloudDownloader::getAllExifData returning:" 
             << "hasData=" << result["hasData"]
             << ", orientation=" << result["orientation"]
             << ", make=" << result["make"].toString()
             << ", model=" << result["model"].toString()
             << ", dateTime=" << result["dateTime"].toString();
    
    return result;
}

