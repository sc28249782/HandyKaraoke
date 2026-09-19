# P3 — Reproducible Windows installer packaging

## Objective

Build an x64 Inno Setup installer from the same clean staged runtime that `stage-smoke` validates. The installer must never read from a developer-specific directory.

## New packaging boundary

| Input | Producer | Consumer |
| --- | --- | --- |
| `build\msvc-x64-release\stage\HandyKaraoke` | CMake `stage-smoke` | Inno Setup installer |
| `_iss_setup\handykaraoke-stage-x64.iss` | repository | Inno Setup |
| `scripts\Build-Installer.ps1` | repository | maintainer/CI |

The legacy `handy-x64.iss` contains hard-coded developer paths and is retained only as historical reference. Do not use it to make releases.

## Prerequisites

- Windows x64 CMake release build already configured;
- Inno Setup 7 or 6 installed (`ISCC.exe` on `PATH`, or in its standard Program Files location). Inno Setup 7 x64 is the current recommended installer compiler; and
- a successful `stage-smoke` build.

## Build

From the repository root:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Build-Installer.ps1
~~~

The script runs `stage-smoke`, checks essential runtime files, and invokes Inno Setup with the stage path and output directory as explicit parameters. It detects the standard machine-wide and per-user Inno Setup 7/6 locations. If Inno Setup is installed elsewhere, pass its compiler explicitly with `-IsccPath`. The default output is:

~~~text
build\msvc-x64-release\package\HandyKaraoke-3.0.0-alpha-recovery-x64-setup.exe
~~~

To identify a planned version without editing the script:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Build-Installer.ps1 -Version 3.0.0-alpha.1
~~~

For example:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Build-Installer.ps1 -IsccPath "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe"
~~~

## Installer behaviour

- Copies application files only from the verified stage;
- excludes `Data`, `Songs`, `SoundFonts`, and `VST` from the payload;
- preserves those user-generated folders when uninstalling;
- installs the Microsoft VC runtime bundled by `windeployqt` when available;
- shows GPLv3 and the official-binary release policy during setup; and
- provides Start Menu entries for normal launch, Safe Mode, and Reset Settings.

## Release gate

Before publishing an installer, verify a clean Windows test machine:

1. Install the generated setup.
2. Start from the installed directory; do not test the build tree.
3. Confirm `stage-smoke`/P1c manual matrix equivalently: SoundFont MIDI/NCN, KAR `FF 01`, KAR `FF 05`, settings recovery, and SQLite creation.
4. Uninstall, verify user media/configuration is retained as intended, then reinstall.
5. Publish only under `docs/OFFICIAL-BINARY-RELEASE-POLICY.md`.

## CI follow-up

The current GitHub Actions workflow publishes the staged runtime artifact. Adding Inno Setup to hosted CI and uploading the installer is a follow-up after a maintainer has produced and tested the first local installer.


## First local installer result

On 2026-09-18, the Windows x64 maintainer built the installer with
`scripts\\Build-Installer.ps1` using Inno Setup 7.1.0. The installer was
created below `build\\msvc-x64-release\\package`, installed successfully,
and launched with behaviour equivalent to the verified staged runtime.

This proves the local build/install/launch path. The remaining gate is a clean
machine (or isolated VM) install, uninstall, and reinstall test, including
confirmation that user data and media are retained as documented.


## Install/uninstall/reinstall result — 2026-09-18

The Windows x64 maintainer completed the full local installer cycle: install,
launch and verify MIDI/SoundFont/KAR, create small user data, uninstall, verify
that `Data`, `Songs`, `SoundFonts`, and `VST` remain, then reinstall and
launch again. Playback remained normal and the earlier user data was retained.

The installer executable carries the application icon. The initial Installed
apps/Programs and Features entry used the generic uninstaller icon because the
script lacked `UninstallDisplayIcon`. The installer now explicitly uses the
installed `HandyKaraoke.exe` as its uninstall display icon; rebuild and
reinstall once to refresh that Windows registry entry.


## Installed apps icon result — 2026-09-18

After rebuilding with `UninstallDisplayIcon={app}\\HandyKaraoke.exe` and
installing again, the maintainer confirmed that Windows Installed apps displays
the HandyKaraoke icon correctly.
