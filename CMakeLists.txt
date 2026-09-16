cmake_minimum_required(VERSION 3.21)

project(HandyKaraoke VERSION 3.0.0 LANGUAGES CXX RC)

# This CMake project is the recovery build. The legacy qmake project remains
# authoritative until this target builds and passes its smoke tests.
option(HK_ENABLE_HNK
       "Build the optional HNK reader (requires the missing HNK source files)" OFF)
set(HK_QT_MAJOR_VERSION "5" CACHE STRING
    "Qt major version for the recovery build (currently 5)")
set_property(CACHE HK_QT_MAJOR_VERSION PROPERTY STRINGS 5 6)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

if(NOT HK_QT_MAJOR_VERSION MATCHES "^[56]$")
    message(FATAL_ERROR "HK_QT_MAJOR_VERSION must be 5 or 6.")
endif()

find_package(Qt${HK_QT_MAJOR_VERSION} 5.15 REQUIRED COMPONENTS Core Gui Widgets Sql)
if(HK_QT_MAJOR_VERSION STREQUAL "5")
    # Included by the legacy qmake project on Windows.
    find_package(Qt5 5.15 REQUIRED COMPONENTS WinExtras)
endif()

set(HK_REQUIRED_HNK_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/Midi/HNKFile.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/Midi/HNKFile.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/Midi/HNKFileComp.h"
)

if(HK_ENABLE_HNK)
    foreach(required_file IN LISTS HK_REQUIRED_HNK_FILES)
        if(NOT EXISTS "${required_file}")
            message(FATAL_ERROR
                "Required HNK source is missing: ${required_file}\n"
                "Set HK_ENABLE_HNK=OFF to build without optional HNK support, or\n"
                "see docs/PHASE-0-BUILD-RECOVERY.md and docs/WORK-QUEUE.md.")
        endif()
    endforeach()
endif()

include(cmake/HandyDependencies.cmake)

file(GLOB HK_ROOT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")
file(GLOB HK_MIDI_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Midi/*.cpp")
# The legacy qmake project does not compile archival backup sources.
list(FILTER HK_MIDI_SOURCES EXCLUDE REGEX ".*/Midi/_BK_.*\\.cpp$")
if(NOT HK_ENABLE_HNK)
    # Keep a future restored reader out of the default compatibility build.
    list(FILTER HK_MIDI_SOURCES EXCLUDE REGEX ".*/Midi/HNKFile\\.cpp$")
endif()
file(GLOB HK_BASSFX_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/BASSFX/*.cpp")
file(GLOB HK_WIDGET_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Widgets/*.cpp")
file(GLOB HK_DIALOG_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Dialogs/*.cpp")
file(GLOB HK_FX_DIALOG_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/FXDialogs/*.cpp")
file(GLOB HK_FORMS CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/*.ui"
    "${CMAKE_CURRENT_SOURCE_DIR}/Widgets/*.ui"
    "${CMAKE_CURRENT_SOURCE_DIR}/Dialogs/*.ui"
    "${CMAKE_CURRENT_SOURCE_DIR}/FXDialogs/*.ui"
)

set(HK_SOURCES
    ${HK_ROOT_SOURCES}
    ${HK_MIDI_SOURCES}
    ${HK_BASSFX_SOURCES}
    ${HK_WIDGET_SOURCES}
    ${HK_DIALOG_SOURCES}
    ${HK_FX_DIALOG_SOURCES}
    ${HK_FORMS}
    icons.qrc
    app.qrc
)

if(WIN32)
    list(APPEND HK_SOURCES
        Midi/rtmidi/RtMidi.cpp
        resources.rc
    )
else()
    # These files were Windows-only in the legacy qmake project.
    list(FILTER HK_SOURCES EXCLUDE REGEX ".*/BASSFX/VSTFX\\.cpp$")
    list(FILTER HK_SOURCES EXCLUDE REGEX ".*/Dialogs/VST(Dialog|DirsDialog)\\.cpp$")
endif()

add_executable(HandyKaraoke WIN32 ${HK_SOURCES})

target_include_directories(HandyKaraoke PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/Widgets"
    "${CMAKE_CURRENT_SOURCE_DIR}/Midi"
    "${CMAKE_CURRENT_SOURCE_DIR}/Midi/rtmidi"
)

if(HK_ENABLE_HNK)
    target_compile_definitions(HandyKaraoke PRIVATE HANDYKARAOKE_ENABLE_HNK=1)
endif()

target_link_libraries(HandyKaraoke PRIVATE
    Qt${HK_QT_MAJOR_VERSION}::Core
    Qt${HK_QT_MAJOR_VERSION}::Gui
    Qt${HK_QT_MAJOR_VERSION}::Widgets
    Qt${HK_QT_MAJOR_VERSION}::Sql
    HandyKaraoke::BASS
    HandyKaraoke::BASSMIDI
    HandyKaraoke::BASSFX
    HandyKaraoke::BASSMIX
)

if(WIN32)
    target_link_libraries(HandyKaraoke PRIVATE
        Winmm
        HandyKaraoke::BASSVST
        HandyKaraoke::WinSparkle
    )
    if(HK_QT_MAJOR_VERSION STREQUAL "5")
        target_link_libraries(HandyKaraoke PRIVATE Qt5::WinExtras)
    endif()

    # Linking verifies import libraries only.  Put every runtime DLL beside the
    # executable so that a freshly built recovery target can be launched.
    get_target_property(HK_QMAKE_EXECUTABLE
        Qt${HK_QT_MAJOR_VERSION}::qmake IMPORTED_LOCATION)
    get_filename_component(HK_QT_BIN_DIR "${HK_QMAKE_EXECUTABLE}" DIRECTORY)
    find_program(HK_WINDEPLOYQT_EXECUTABLE
        NAMES windeployqt.exe windeployqt
        HINTS "${HK_QT_BIN_DIR}"
        NO_DEFAULT_PATH)
    if(NOT HK_WINDEPLOYQT_EXECUTABLE)
        message(FATAL_ERROR
            "windeployqt was not found beside ${HK_QMAKE_EXECUTABLE}. "
            "Install a complete Qt desktop kit.")
    endif()

    set(HK_RUNTIME_DLLS
        "${HK_BASS_ROOT}/bass24/x64/bass.dll"
        "${HK_BASS_ROOT}/bassmidi24/x64/bassmidi.dll"
        "${HK_BASS_ROOT}/bass_fx24/x64/bass_fx.dll"
        "${HK_BASS_ROOT}/bassmix24/x64/bassmix.dll"
        "${HK_BASS_ROOT}/bass_vst24/x64/bass_vst.dll"
        "${HK_WINSPARKLE_ROOT}/x64/WinSparkle.dll"
    )
    set(HK_RUNTIME_SUPPORT_FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/Style.ini"
        "${CMAKE_CURRENT_SOURCE_DIR}/languages/en.qm"
    )
    foreach(runtime_file IN LISTS HK_RUNTIME_DLLS HK_RUNTIME_SUPPORT_FILES)
        if(NOT EXISTS "${runtime_file}")
            message(FATAL_ERROR "Missing runtime file: ${runtime_file}")
        endif()
    endforeach()

    add_custom_command(TARGET HandyKaraoke POST_BUILD
        COMMAND "${HK_WINDEPLOYQT_EXECUTABLE}"
                --no-translations
                --dir "$<TARGET_FILE_DIR:HandyKaraoke>"
                "$<TARGET_FILE:HandyKaraoke>"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                ${HK_RUNTIME_DLLS}
                "${CMAKE_CURRENT_SOURCE_DIR}/Style.ini"
                "$<TARGET_FILE_DIR:HandyKaraoke>"
        COMMAND "${CMAKE_COMMAND}" -E make_directory
                "$<TARGET_FILE_DIR:HandyKaraoke>/languages"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/languages/en.qm"
                "$<TARGET_FILE_DIR:HandyKaraoke>/languages/en.qm"
        COMMENT "Deploying Qt, legacy audio, and application runtime files"
        VERBATIM)

    # Create a disposable, release-like layout without copying user media or
    # touching a real installation.  This is the only location P1 smoke tests
    # should use once it has been staged.
    set(HK_STAGE_DIR "${CMAKE_BINARY_DIR}/stage/HandyKaraoke" CACHE PATH
        "Destination directory for the P1 runtime staging target")
    add_custom_target(stage-runtime
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "$<TARGET_FILE:HandyKaraoke>"
                "${HK_STAGE_DIR}"
        COMMAND "${HK_WINDEPLOYQT_EXECUTABLE}"
                --no-translations
                --dir "${HK_STAGE_DIR}"
                "$<TARGET_FILE:HandyKaraoke>"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                ${HK_RUNTIME_DLLS}
                "${CMAKE_CURRENT_SOURCE_DIR}/Style.ini"
                "${HK_STAGE_DIR}"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/languages"
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/languages/en.qm"
                "${HK_STAGE_DIR}/languages/en.qm"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/Songs/KAR"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/Songs/NCN/Song"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/Songs/NCN/Lyrics"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/Songs/NCN/Cursor"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/Songs/HNK"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/SoundFonts"
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${HK_STAGE_DIR}/VST"
        DEPENDS HandyKaraoke
        COMMENT "Staging a clean HandyKaraoke runtime layout"
        VERBATIM)
endif()

# Qt 6 support is an explicit migration goal. A successful Qt 5 recovery build
# is required before treating a Qt 6 build as a release candidate.
