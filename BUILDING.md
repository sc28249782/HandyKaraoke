# Building HandyKaraoke (Recovery Build)

> Status: the public source snapshot is incomplete. CMake deliberately stops
> before compilation while the HNK reader files are missing. This is expected
> and prevents a misleading partial release.

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

## Expected result today

Configuration stops with the names of these required missing files:

- `Midi/HNKFile.cpp`
- `Midi/HNKFile.h`
- `Midi/HNKFileComp.h`

Do **not** bypass that check for a release. The application contains direct
HNK reader calls and needs a deliberate compatibility decision first. See
`docs/WORK-QUEUE.md`.

## After the HNK decision

1. Restore authorised source or explicitly remove/feature-gate HNK code.
2. Re-run configure and fix the first actual compiler error.
3. Build a Debug binary, then run the smoke tests in
   `docs/PHASE-0-BUILD-RECOVERY.md`.
4. Only then add CI and the installer packaging step.

## Clean build

```powershell
Remove-Item -Force -Recurse build\msvc-x64
```

The `build/` directory is generated content and must not be committed.
