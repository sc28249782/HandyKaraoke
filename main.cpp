#include "MainWindow.h"

#include <QApplication>
#include <QCommandLineParser>
#include <QMessageBox>
#include <QSplashScreen>
#include <QDirIterator>
#include <QMetaType>
#include <QStyleFactory>

#include "BASSFX/VSTFX.h"
#include "version.h"
#include "Config.h"
#include "Utils.h"

#ifdef __linux__
#include <QFontDatabase>
#endif

void registerMetaType();

void checkDatabase(QSplashScreen *splash, SongDatabase *db);
void loadSoundfonts(QSplashScreen *splash, MidiSynthesizer *synth);

#ifndef __linux__
void loadVSTi(QSplashScreen *splash, MidiSynthesizer *synth);
void makeVSTList(QSplashScreen *splash, MidiSynthesizer *synth);
#endif

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);

    QCoreApplication::setApplicationName(VER_PRODUCTNAME_STR);
    QCoreApplication::setApplicationVersion(VER_FILEVERSION_STR);
    QCoreApplication::setOrganizationName(VER_COMPANYNAME_STR);
    QCoreApplication::setOrganizationDomain(VER_COMPANYDOMAIN_STR);

    QCommandLineParser parser;
    parser.setApplicationDescription(
                "HandyKaraoke recovery and troubleshooting options");
    parser.addHelpOption();
    const QCommandLineOption safeModeOption(
                "safe-mode",
                "Start with temporary default settings and skip VST loading.");
    const QCommandLineOption resetSettingsOption(
                "reset-settings",
                "Back up and reset HandyKaraoke settings, then exit.");
    parser.addOption(safeModeOption);
    parser.addOption(resetSettingsOption);
    parser.process(a);

    const bool safeMode = parser.isSet(safeModeOption);
    const bool resetSettings = parser.isSet(resetSettingsOption);

    registerMetaType();

    QPixmap *pixmap = new QPixmap(":/Icons/App/splash.png");
    QSplashScreen *splash = new QSplashScreen(*pixmap);
    splash->show();
    qApp->processEvents();

    splash->showMessage("กำลังเริ่มโปรแกรม...", Qt::AlignBottom|Qt::AlignRight);
    qApp->processEvents();

    { // Config Dir
        Config::initConfigDataPath();

        QDir dir(TEMP_DIR_PATH);
        if (!dir.exists())
            dir.mkpath(TEMP_DIR_PATH);

        dir.setPath(ALL_DATA_DIR_PATH);
        if (!dir.exists())
            dir.mkpath(ALL_DATA_DIR_PATH);

        dir.setPath(Config::CONFIG_DIR_PATH);
        if (!dir.exists())
            dir.mkpath(Config::CONFIG_DIR_PATH);
    }

    if (resetSettings) {
        QString backupDirectory;
        QString errorMessage;
        if (!Config::resetSettings(&backupDirectory, &errorMessage)) {
            QMessageBox::critical(nullptr, "HandyKaraoke",
                                  "ไม่สามารถรีเซ็ตการตั้งค่าได้\n" + errorMessage);
            return 1;
        }

        const QString message = backupDirectory.isEmpty()
                ? "ไม่พบการตั้งค่าเดิมให้รีเซ็ต"
                : "รีเซ็ตการตั้งค่าแล้ว\nสำรองไฟล์เดิมไว้ที่\n" + backupDirectory;
        QMessageBox::information(nullptr, "HandyKaraoke", message);
        return 0;
    }

    if (safeMode) {
        Config::enableSafeMode();
        splash->showMessage("Safe mode: ใช้ค่าเริ่มต้นชั่วคราว",
                            Qt::AlignBottom|Qt::AlignRight);
        qApp->processEvents();
    }

    { // set style
        QSettings *s = new QSettings("Style.ini", QSettings::IniFormat);

        #ifdef __linux__
        bool useFusion = s->value("Fusion", true).toBool();
        #else
        bool useFusion = s->value("Fusion", false).toBool();
        #endif

        delete s;

        if (useFusion)
            a.setStyle(QStyleFactory::create("Fusion"));
    }


    // Add font for linux
    #ifdef __linux__
    QFontDatabase::addApplicationFont(":/Fonts/THSarabunNew/THSarabunNew Bold.ttf");
    #endif
    //----------------------------------

    MainWindow w;
    w.setWindowIcon(QIcon(":/Icons/App/icon.png"));
    if (safeMode)
        w.setWindowTitle(w.windowTitle() + " [Safe Mode]");

    checkDatabase(splash, w.database());
    loadSoundfonts(splash, w.midiPlayer()->midiSynthesizer());

    #ifndef __linux__
    if (!safeMode) {
        loadVSTi(splash, w.midiPlayer()->midiSynthesizer());
        makeVSTList(splash, w.midiPlayer()->midiSynthesizer());
        w.synthMixerDialog()->setVSTVendorMenu();
    }
    #endif
    w.synthMixerDialog()->setFXToSynth();

    w.show();

    splash->finish(&w);

    delete splash;
    delete pixmap;

    return a.exec();
}

void registerMetaType()
{
    qRegisterMetaType<MidiEvent>("MidiEvent");
    qRegisterMetaType<InstrumentType>("InstrumentType");

    //<QList<int>>("QList<int>");
    qRegisterMetaTypeStreamOperators<QList<int>>("QList<int>");

    //qRegisterMetaType<QList<uint>>("QList<uint>");
    qRegisterMetaTypeStreamOperators<QList<uint>>("QList<uint>");

    //qRegisterMetaType<QList<float>>("QList<float>");
    qRegisterMetaTypeStreamOperators<QList<float>>("QList<float>");

    //qRegisterMetaType<QList<bool>>("QList<bool>");
    qRegisterMetaTypeStreamOperators<QList<bool>>("QList<bool>");

    //qRegisterMetaType<QList<QList<float>>>("QList<QList<float>>");
    qRegisterMetaTypeStreamOperators<QList<QList<float>>>("QList<QList<float>>");

    qRegisterMetaTypeStreamOperators<QList<QByteArray>>("QList<QByteArray>>");
}

void checkDatabase(QSplashScreen *splash, SongDatabase *db)
{
    if (db->isNewVersion())
        return;

    splash->showMessage("กำลังปรับปรุงฐานข้อมูลเพลง", Qt::AlignBottom|Qt::AlignRight);
    qApp->processEvents();

    db->updateToNewVersion();
}

void loadSoundfonts(QSplashScreen *splash, MidiSynthesizer *synth)
{
    QSettings settings(Config::CONFIG_APP_FILE_PATH, QSettings::IniFormat);

    synth->setLoadAllSoundfont(settings.value("SynthSoundfontsLoadAll", false).toBool());

    // set soundfont to synth
    QStringList sfList = settings.value("SynthSoundfonts", QStringList()).toStringList();
    settings.beginReadArray("SynthSoundfontsVolume");
    for (int i=0; i<sfList.count(); i++)
    {
        settings.setArrayIndex(i);
        int volume = settings.value("SoundfontVolume", 100).toInt();

        splash->showMessage("กำลังโหลด : " + QFileInfo(sfList.at(i)).fileName(), Qt::AlignBottom|Qt::AlignRight);
        qApp->processEvents();

        if (synth->addSoundfont(sfList.at(i)))
            synth->setSoundfontVolume(i, volume / 100.0f);
    }
    settings.endArray();


    // set Map soundfont
    for (int i = 0; i < SF_PRESET_COUNT; i++) {
        QString sfKey = "SynthSoundfontsMap";
        QString drKey = "SynthSoundfontsDrumMap";
        if (i > 0) {
            sfKey = sfKey + QString::number(i);
            drKey = drKey + QString::number(i);
        }
        QList<int> sfMap     = settings.value(sfKey).value<QList<int>>();
        QList<int> sfDrumMap = settings.value(drKey).value<QList<int>>();

        if (sfMap.count() == 0)
            sfMap = synth->getMapSoundfontIndex(i);
        if (sfDrumMap.count() == 0)
            sfDrumMap = synth->getDrumMapSfIndex(i);

        synth->setMapSoundfontIndex(i, sfMap, sfDrumMap);
    }
}

#ifndef __linux__

void loadVSTi(QSplashScreen *splash, MidiSynthesizer *synth)
{
    QSettings st(Config::CONFIG_SYNTH_FILE_PATH, QSettings::IniFormat);

    st.beginReadArray("VSTiGroup");

    for (int i=0; i<4; i++)
    {
        st.setArrayIndex(i);

        QString      filePath   = st.value("VstiFilePath", "").toString();
        int          program    = st.value("VstiPrograms", 0).toInt();
        QList<float> params     = st.value("VstiParams").value<QList<float>>();
        QByteArray   chunk      = st.value("VstiChunk", QByteArray()).toByteArray();

        if (filePath == "")
            continue;

        splash->showMessage("กำลังโหลด : " + QFileInfo(filePath).fileName(), Qt::AlignBottom|Qt::AlignRight);
        qApp->processEvents();

        DWORD vsti = synth->setVSTiFile(i, filePath);

        if (vsti != 0)
        {
            if (chunk.length() > 0)
                BASS_VST_SetChunk(vsti, false, chunk.constData(), chunk.length());

            BASS_VST_SetProgram(vsti, program);
            FX::setVSTParams(vsti, params);
        }
    }

    st.endArray();
}

void makeVSTList(QSplashScreen *splash, MidiSynthesizer *synth)
{
    QSettings st(Config::CONFIG_SYNTH_FILE_PATH, QSettings::IniFormat);
    QStringList dirs = st.value("VSTDirs", QStringList()).toStringList();

    QStringList vstDirs;
    vstDirs << QDir::currentPath() + "/VST";
    vstDirs += dirs;

    QMap<uint, VSTNamePath> vstList;

    for (const QString &dir : vstDirs)
    {
        QDirIterator it(dir, QStringList() << "*.DLL" << "*.dll",
                        QDir::Files|QDir::NoSymLinks, QDirIterator::Subdirectories);

        while(it.hasNext()) {

            it.next();

            splash->showMessage("กำลังตรวจสอบ : " + it.fileName(), Qt::AlignBottom|Qt::AlignRight);
            qApp->processEvents();

            VSTNamePath info;

            if (!Utils::vstInfo(it.filePath(), &info))
                continue;

            vstList[info.uniqueID] = info;
        }
    }

    synth->setVSTList(vstList);
}

#endif
