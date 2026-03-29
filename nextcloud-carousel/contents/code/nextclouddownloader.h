/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef NEXTCLOUDDOWNLOADER_H
#define NEXTCLOUDDOWNLOADER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrl>
#include <QHash>
#include <QList>
#include <QMutex>
#include <QVariantMap>
#include <QPointer>
#include <QFile>
#include <QTimer>
#include <memory>

/**
 * NextcloudDownloader - Livello 1: Gestisce solo il download da Nextcloud
 * 
 * Questo componente si occupa esclusivamente di:
 * - Scaricare immagini da Nextcloud con autenticazione
 * - Salvare in file temporanei locali
 * - Restituire il percorso del file locale
 * 
 * Non gestisce rendering o ottimizzazioni - quello è compito del livello 2 (QML)
 */
class NextcloudDownloader : public QObject
{
    Q_OBJECT

public:
    explicit NextcloudDownloader(QObject *parent = nullptr);
    ~NextcloudDownloader();

    /**
     * Avvia il download di un'immagine da Nextcloud
     * @param url URL dell'immagine su Nextcloud
     * @param username Username per autenticazione
     * @param password Password per autenticazione
     * @param maxSizeMB Dimensione massima in MB (0 = nessun limite, default 30MB)
     * @return Percorso del file locale se già in cache, stringa vuota se download in corso
     */
    Q_INVOKABLE QString downloadImage(const QString &url, 
                                      const QString &username, 
                                      const QString &password,
                                      int maxSizeMB = 30);

    /**
     * Pulisce la cache dei file temporanei
     */
    Q_INVOKABLE void clearCache();
    
    /**
     * Rimuove file orfani su disco (non più referenziati dalla LRU in RAM) e .part abbandonati.
     * Chiamata anche all'avvio e su timer; dopo ogni download (con throttle).
     */
    Q_INVOKABLE void cleanupOldFiles();

    /**
     * Verifica se un URL è già in cache
     */
    Q_INVOKABLE bool isCached(const QString &url);

    /**
     * Ottiene il percorso del file locale per un URL (se in cache)
     */
    Q_INVOKABLE QString getLocalFilePath(const QString &url);

    /**
     * Legge l'orientazione EXIF da un file immagine locale
     * @param filePath Percorso del file immagine
     * @return Angolo di rotazione in gradi (0, 90, -90, 180) o 0 se non trovato
     */
    Q_INVOKABLE int getExifOrientation(const QString &filePath);

    /**
     * Legge tutti i dati EXIF da un file immagine locale (come fa QML)
     * @param filePath Percorso del file immagine
     * @return QVariantMap con tutti i dati EXIF (orientation, dateTime, make, model, iso, fNumber, exposureTime, latitude, longitude, etc.)
     */
    Q_INVOKABLE QVariantMap getAllExifData(const QString &filePath);

signals:
    /**
     * Emesso quando un'immagine è stata scaricata e salvata
     * @param localFilePath Percorso del file locale salvato
     * @param originalUrl URL originale dell'immagine
     */
    void imageDownloaded(const QString &localFilePath, const QString &originalUrl);

    /**
     * Emesso quando un download fallisce
     * @param url URL dell'immagine che ha fallito
     * @param errorString Messaggio di errore
     */
    void downloadFailed(const QString &url, const QString &errorString);

private:
    /** Per-reply download state: stream network bytes to disk (Qt: QNetworkReply as QIODevice, readyRead). */
    struct PendingDownload {
        QString originalUrl;
        int maxSizeMB = 30;
        std::unique_ptr<QFile> file;
        QString filePath;
        qint64 bytesWritten = 0;
    };

    void onDownloadReadyRead(QNetworkReply *reply);
    void onDownloadFinished(QNetworkReply *reply);
    void failPendingDownload(QNetworkReply *reply, const QString &errorString);

    qint64 maxSizeBytesForMb(int maxSizeMB) const;
    static QString extensionFromContentType(const QString &contentType);
    void insertCacheEntryAndEvict(const QString &cacheKey, const QString &filePath);
    void touchCacheKeyUnlocked(const QString &cacheKey);
    void removeCacheEntryUnlocked(const QString &cacheKey);

    QNetworkAccessManager *m_networkManager;
    QHash<QString, QString> m_cache;       // cacheKey -> temp file path
    QList<QString> m_cacheLruOrder;        // front = LRU for eviction (see Qt cache patterns + project memory rules)
    QHash<QNetworkReply*, PendingDownload*> m_pending;  // active streaming downloads

    QMutex m_mutex;
    QString m_tempDir;

    QString getCacheKey(const QString &url);

    /** Disk sweep: orphans not in m_cache, stale .part; optional emergency trim of young orphans. */
    void performOrphanSweep(bool bypassThrottle);

    QTimer *m_orphanSweepTimer = nullptr;
    qint64 m_lastOrphanSweepMs = 0;

    static constexpr int kMaxCachedImageFiles = 48;
};

#endif // NEXTCLOUDDOWNLOADER_H

