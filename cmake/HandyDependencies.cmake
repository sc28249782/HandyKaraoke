# Third-party dependency validation for the Windows recovery build.
#
# The legacy repository includes BASS 2.4 import libraries.  This module uses
# those exact files only to reproduce the old application.  Upgrading BASS or
# redistributing the resulting package requires a separate licence review.

set(HK_BASS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/BASS" CACHE PATH
    "Root directory containing the legacy BASS SDK files")
set(HK_WINSPARKLE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/3rdParty/WinSparkle" CACHE PATH
    "Root directory containing the legacy WinSparkle SDK files")

function(hk_import_legacy_library logical_name alias_name header_dir library_dir library_name)
    find_path(HK_${logical_name}_INCLUDE_DIR
        NAMES ${header_dir}
        PATHS "${HK_BASS_ROOT}/${library_dir}"
        NO_DEFAULT_PATH
    )
    find_file(HK_${logical_name}_LIBRARY
        NAMES ${library_name}.lib
        PATHS "${HK_BASS_ROOT}/${library_dir}/x64"
        NO_DEFAULT_PATH
    )

    if(NOT HK_${logical_name}_INCLUDE_DIR OR NOT HK_${logical_name}_LIBRARY)
        message(FATAL_ERROR
            "Missing legacy dependency ${logical_name}. Expected header ${header_dir} "
            "under ${HK_BASS_ROOT}/${library_dir} and x64 import library "
            "${library_name}.lib under ${HK_BASS_ROOT}/${library_dir}/x64.")
    endif()

    add_library(${logical_name} UNKNOWN IMPORTED GLOBAL)
    set_target_properties(${logical_name} PROPERTIES
        IMPORTED_LOCATION "${HK_${logical_name}_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${HK_${logical_name}_INCLUDE_DIR}"
    )
    add_library(${alias_name} ALIAS ${logical_name})
endfunction()

if(WIN32)
    hk_import_legacy_library(HK_BASS     HandyKaraoke::BASS     bass.h      bass24       bass)
    hk_import_legacy_library(HK_BASSMIDI HandyKaraoke::BASSMIDI bassmidi.h  bassmidi24   bassmidi)
    hk_import_legacy_library(HK_BASSFX   HandyKaraoke::BASSFX   bass_fx.h   bass_fx24    bass_fx)
    hk_import_legacy_library(HK_BASSMIX  HandyKaraoke::BASSMIX  bassmix.h   bassmix24   bassmix)
    hk_import_legacy_library(HK_BASSVST  HandyKaraoke::BASSVST  bass_vst.h  bass_vst24   bass_vst)

    find_path(HK_WINSPARKLE_INCLUDE_DIR
        NAMES winsparkle.h
        PATHS "${HK_WINSPARKLE_ROOT}/include"
        NO_DEFAULT_PATH
    )
    find_file(HK_WINSPARKLE_LIBRARY
        NAMES WinSparkle.lib
        PATHS "${HK_WINSPARKLE_ROOT}/x64"
        NO_DEFAULT_PATH
    )
    if(NOT HK_WINSPARKLE_INCLUDE_DIR OR NOT HK_WINSPARKLE_LIBRARY)
        message(FATAL_ERROR
            "Missing WinSparkle x64 import library or headers under "
            "${HK_WINSPARKLE_ROOT}.")
    endif()

    add_library(HK_WinSparkle UNKNOWN IMPORTED GLOBAL)
    set_target_properties(HK_WinSparkle PROPERTIES
        IMPORTED_LOCATION "${HK_WINSPARKLE_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${HK_WINSPARKLE_INCLUDE_DIR}"
    )
    add_library(HandyKaraoke::WinSparkle ALIAS HK_WinSparkle)
else()
    message(FATAL_ERROR
        "The CMake recovery build currently supports Windows x64 only. "
        "Linux packaging will be restored after the Windows verification gates pass.")
endif()
