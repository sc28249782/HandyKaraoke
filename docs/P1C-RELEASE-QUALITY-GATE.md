# P1c — Release Quality Gate

This gate verifies the packaged runtime that users execute, not the development
binary in a build directory. It deliberately does not copy songs, SoundFonts,
or VST plug-ins into the repository or staged package.

## 1. Build and validate the stage

Open a Visual Studio Developer Command Prompt in the repository root.

```bat
cmake -S . -B build\msvc-x64-release
cmake --build build\msvc-x64-release --target stage-smoke --parallel
```

The command first builds the Release executable, creates
`build\msvc-x64-release\stage\HandyKaraoke`, and then checks its runtime
manifest. The static check fails if a required Qt/BASS DLL, plug-in, recovery
launcher, language file, SQLite driver, or expected empty media directory is
missing.

Create the synthetic, redistributable KAR regression fixtures before the KAR
`FF 05` and `Words`/`FF 01` tests:

```bat
cmake --build build\msvc-x64-release --target stage-fixture
```

It writes `KAR-Words-FF01-Regression.kar` under the staged `Songs\KAR`
folder. The file has no commercial music or lyrics: it contains only three
short test lines, both `\\` and `/` markers, and short synthetic MIDI notes
throughout the lyric timeline to exercise normal playback.

Run the staged executable after the static check passes and the fixture exists:

```bat
build\msvc-x64-release\stage\HandyKaraoke\HandyKaraoke.exe
```

For a package-layout check without building, run:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Test-StageRuntime.ps1 -StageDir build\msvc-x64-release\stage\HandyKaraoke
```

## 2. Manual playback matrix

Use only fixtures that the tester is entitled to use. Do not commit commercial
songs, SoundFonts, or VST plug-ins to this repository.

| Check | Expected result |
|---|---|
| Fresh launch with no MIDI hardware | Starts with SoundFont/None fallback; no startup error |
| SQLite song database | Opens, creates/updates the song database, and restarts successfully |
| Language | Thai and English both switch without relaunch |
| NCN | Scan and play MIDI, lyric, and cursor data correctly |
| KAR with MIDI lyric events (`FF 05`) | Lyric text appears and advances with playback — **PASS** on the staged synthetic fixture (Windows x64 maintainer test, 2026-09-17) |
| KAR with a `Words`/`Lyrics` text track (`FF 01`) | Text appears; `\\` and `/` line markers advance to a new line |
| SoundFont | Built-in MIDI Synthesizer produces audio through the selected output |
| Safe mode | `HandyKaraoke-SafeMode.cmd` launches with recoverable defaults |
| Reset settings | `HandyKaraoke-ResetSettings.cmd` restores settings while preserving the song database |
| Staged relink | Close the app, rerun `stage-smoke`, and verify that no executable/DLL lock prevents the build |

Record the fixture provenance, Windows/Qt version, audio device, and any
failure in the execution log below.

## 3. Execution log template

```text
Date:
Commit:
Windows edition/build:
Visual Studio / MSVC:
Qt kit:
Stage path:
MIDI hardware present:
Audio output:
Fixtures and redistribution rights:
Static stage-smoke result: PASS / FAIL
Manual matrix result: PASS / FAIL
Notes or defects:
```

## Exit rule

P1c passes only when `stage-smoke` passes and every applicable manual matrix
item is recorded as passed on a clean staged folder. A failed optional item,
such as a VST plug-in not supplied for the test, must be marked **not tested**
rather than silently treated as passed.
