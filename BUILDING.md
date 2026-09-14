# Building HandyKaraoke (Recovery Build)

> Status: HNK support is disabled by default while its reader source is absent.
> This lets the recovery build proceed for MID/KAR/NCN without claiming HNK
> compatibility.

## Supported recovery target

- Windows 11 x64
- Visual Studio 2022 Build Tools (MSVC x64)
- CMake 3.21 or later
- Ninja
- Qt 5.15.x for MSVC x64, with Core, Gui, Widgets, SQL, and WinExtras
- Legacy BASS/WinSparkle files already present in this repository

Qt 6 is a later migration target; it is not yet considered verified for this
legacy source.

## Configure

From a Developer PowerShell for Visual Studio:

```powershell
cmake -S . -B build\msvc-x64 -G Ninja -DCMAKE_PREFIX_PATH="C:\Qt\5.15.2\msvc2019_64"
```

Then build:

```powershell
cmake --build build\msvc-x64 --parallel
```

Adjust `CMAKE_PREFIX_PATH` to your installed Qt kit. An MSVC 2019-built Qt
kit is normally usable with the MSVC 2022 toolset, but use a matching Qt/MSVC
kit when available.

## HNK option

The default is:

```text
HK_ENABLE_HNK=OFF
```

This means HNK files are not indexed or played, and the Settings dialog marks
their path as unavailable. To enable the option later:

```powershell
cmake -S . -B build\msvc-x64 -G Ninja -DHK_ENABLE_HNK=ON
```

That configuration intentionally fails until all authorised HNK source files
are present. See [HNK option](docs/HNK-OPTION.md).

## First verification

1. Configure and build with HNK left disabled.
2. Launch with an empty configuration and no MIDI output device.
3. Create and reopen the SQLite song database.
4. Scan only legally redistributable MID/KAR/NCN test fixtures.
5. Record every compiler, DLL-deployment, or runtime failure in the work queue.

## Clean build

```powershell
Remove-Item -Force -Recurse build\msvc-x64
```

The `build/` directory is generated content and must not be committed.
