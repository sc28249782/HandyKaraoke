#include "Config.h"

#include <QApplication>
#include <QDateTime>
#include <QFile>
#include <QFileInfo>

QString Config::DATABASE_DIR_PATH       = ALL_DATA_DIR_PATH + "/Data";
QString Config::DATABASE_FILE_PATH      = Config::DATABASE_DIR_PATH + "/Database.db3";

QString Config::CONFIG_DIR_PATH         = ALL_DATA_DIR_PATH + "/Config";
QString Config::CONFIG_APP_FILE_PATH    = Config::CONFIG_DIR_PATH + "/HandyKaraoke.conf";
QString Config::CONFIG_SYNTH_FILE_PATH  = Config::CONFIG_DIR_PATH + "/SynthMixer.conf";

void Config::initConfigDataPath()
{
    QDir dir(qApp->applicationDirPath() + "/Data");
    if (dir.exists()) {
        DATABASE_DIR_PATH = qApp->applicationDirPath() + "/Data";
        DATABASE_FILE_PATH = DATABASE_DIR_PATH + "/Database.db3";
    }

    dir.setPath(qApp->applicationDirPath() + "/Config");
    if (dir.exists()) {
        CONFIG_DIR_PATH = qApp->applicationDirPath() + "/Config";
        CONFIG_APP_FILE_PATH = CONFIG_DIR_PATH + "/HandyKaraoke.conf";
        CONFIG_SYNTH_FILE_PATH = CONFIG_DIR_PATH + "/SynthMixer.conf";
    }
}


void Config::enableSafeMode()
{
    QDir dir(TEMP_DIR_PATH + "/safe-mode");
    if (!dir.exists())
        dir.mkpath(".");

    CONFIG_APP_FILE_PATH = dir.filePath("HandyKaraoke.conf");
    CONFIG_SYNTH_FILE_PATH = dir.filePath("SynthMixer.conf");

    // Do not allow a previous safe-mode session to become another source of
    // startup problems.
    QFile::remove(CONFIG_APP_FILE_PATH);
    QFile::remove(CONFIG_SYNTH_FILE_PATH);
}

bool Config::resetSettings(QString *backupDirectory, QString *errorMessage)
{
    QDir configDir(CONFIG_DIR_PATH);
    if (!configDir.exists() && !configDir.mkpath(".")) {
        if (errorMessage)
            *errorMessage = QString("Cannot create configuration directory: %1")
                    .arg(CONFIG_DIR_PATH);
        return false;
    }

    const QString stamp = QDateTime::currentDateTime()
            .toString("yyyyMMdd-HHmmsszzz");
    const QString backupPath = configDir.filePath("backup-" + stamp);
    const QStringList files = {
        CONFIG_APP_FILE_PATH,
        CONFIG_SYNTH_FILE_PATH
    };

    bool movedAnyFile = false;
    for (const QString &filePath : files) {
        if (!QFile::exists(filePath))
            continue;

        if (!QDir().mkpath(backupPath)) {
            if (errorMessage)
                *errorMessage = QString("Cannot create backup directory: %1")
                        .arg(backupPath);
            return false;
        }

        const QString destination = QDir(backupPath)
                .filePath(QFileInfo(filePath).fileName());
        if (!QFile::rename(filePath, destination)) {
            if (errorMessage)
                *errorMessage = QString("Cannot back up configuration file: %1")
                        .arg(filePath);
            return false;
        }

        movedAnyFile = true;
    }

    if (backupDirectory)
        *backupDirectory = movedAnyFile ? backupPath : QString();

    return true;
}
