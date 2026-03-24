/*
    SPDX-FileCopyrightText: 2024 Nextcloud Carousel Developer
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef NEXTCLOUDDOWNLOADER_H
#define NEXTCLOUDDOWNLOADER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QTemporaryFile>
#include <QUrl>
#include <QHash>
#include <QMutex>
#include <QVariantMap>
#include <QPointer>

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
     * Pulisce i file vecchi (non in cache, più vecchi di 1 ora)
     * Chiamato automaticamente dopo ogni download
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

private slots:
    void downloadFinished(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
    QHash<QString, QString> m_cache;  // URL -> temp file path
    QHash<QNetworkReply*, QString> m_downloads;  // Reply -> URL
    QHash<QNetworkReply*, int> m_downloadMaxSizes;  // Reply -> maxSizeMB
    QMutex m_mutex;
    QString m_tempDir;

    QString createTempFile(const QByteArray &data, const QString &extension);
    QString getCacheKey(const QString &url);
};

#endif // NEXTCLOUDDOWNLOADER_H

