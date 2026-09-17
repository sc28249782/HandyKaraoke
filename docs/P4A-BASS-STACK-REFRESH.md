# P4a — BASS stack refresh

## Purpose

Refresh the runtime audio/MIDI SDKs as one compatible BASS 2.4 stack, while preserving the established x64 build and staged-runtime behaviour.

This phase deliberately does **not** introduce WASAPI, ASIO, VST3 hosting, or a replacement audio architecture. Those are later, separately testable changes.

## Scope and target versions

| Component | Repository baseline | P4a target | Action |
| --- | ---: | ---: | --- |
| BASS | 2.4.14 | 2.4.18.3 | Update header, x64 import library, and x64 DLL |
| BASSMIDI | 2.4.12.1 | 2.4.16 | Update atomically with BASS |
| BASSmix | 2.4.9 | 2.4.13 | Update atomically with BASS |
| BASS FX | 2.4.12.1 | 2.4.12.6 | Update atomically with BASS |
| BASS_VST | 2.4.1 | 2.4.1 | Keep; current official release is unchanged |

The script updates only these three matching x64 SDK artifacts per selected component:

- public header in `BASS/<component>/`
- import library in `BASS/<component>/x64/`
- runtime DLL in `BASS/<component>/x64/`.

It does not touch the existing `BASS_VST` files.

## License gate

Before using `-Apply`, confirm that the intended distribution and revenue model complies with the current Un4seen BASS licence. The upstream site states that free use is for non-commercial use; commercial or money-making products require a commercial licence. Record that decision before publishing a binary release.

## Safe update procedure

From the repository root on Windows, first perform a download-and-validation only run:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Refresh-BassSdk.ps1
~~~

The dry run downloads official archives into `build\vendor-cache\bass-stack-refresh`, extracts them there, and verifies the expected header, x64 `.lib`, and x64 `.dll`. It makes no repository changes.

After the licence gate is approved, apply the atomic refresh:

~~~powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Refresh-BassSdk.ps1 -Apply
~~~

The script copies the current artifacts to `build\vendor-backups\bass-stack-<timestamp>` before replacement. Review the changed binary files before committing:

~~~powershell
git status -- BASS
~~~

## Required verification after applying

~~~powershell
cmake -S . -B build\msvc-x64-release
cmake --build build\msvc-x64-release --target stage-smoke --parallel
cmake --build build\msvc-x64-release --target stage-fixture --parallel
~~~

Then run the staged executable and verify:

- NCN/MIDI playback through the configured SoundFont and normal audio device;
- the two KAR regression fixtures: `FF 01` Words/Lyrics and `FF 05` Lyrics;
- transpose, tempo, 32-bit floating-point MIDI output, and reverb/chorus settings;
- reset settings and safe mode;
- opening the staged runtime recreates/uses the SQLite song database as documented in P1c.

Commit the refreshed SDK files only after these gates pass locally, then confirm the GitHub Actions Windows build/staging run also passes.

## Completion criteria

P4a is complete only when the approved SDK files are committed together, the local stage checks and manual audio regression checks pass, and CI passes. Preparation of this document and script alone is not an SDK upgrade.

## Execution record — 2026-09-17

A Windows x64 maintainer applied the refresh with
`Refresh-BassSdk.ps1 -Apply`. The pre-refresh files were retained at
`build\\vendor-backups\\bass-stack-20260917-203818`.

The repository diff contains updated BASS, BASSMIDI, and BASSmix headers,
x64 import libraries, and x64 DLLs, plus the BASS FX x64 DLL. The BASS FX
header and import library were validated from the official package but were
byte-identical to the repository copies and therefore do not appear as changed.
BASS_VST remains at 2.4.1.

Local verification passed:

- Release CMake configure;
- `stage-smoke`, including the staged runtime manifest;
- `stage-fixture`, which generated both synthetic KAR fixtures; and
- staged NCN/MIDI + SoundFont playback, KAR `FF 01` / `FF 05` lyrics, and
  tempo/transpose controls.

The remaining release gate is to commit the binary changes from the Windows
worktree, push them to this branch, and confirm the GitHub Actions Windows
workflow. The BASS distribution/licence decision must also be recorded before
publishing a binary release.

## CI record — 2026-09-17

The refreshed binary commit `ee7167401d57c153f1331f3c15e28f573215ea92`
passed GitHub Actions [Windows x64 recovery build run 51](https://github.com/sc28249782/HandyKaraoke/actions/runs/35232175350).
The hosted Windows job completed configure, Release build, staged runtime
validation, synthetic KAR fixture generation, and staged-artifact upload.

**Technical status: complete.** Keep the separate BASS distribution/licence
record as a prerequisite for any public binary release.
