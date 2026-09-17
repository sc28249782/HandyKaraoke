# P3 — CI and Packaging

## First delivery: Windows x64 stage artifact

The first P3 increment introduces a GitHub Actions workflow at
`.github/workflows/windows-recovery.yml`.

It runs on `windows-2022` and deliberately mirrors the verified recovery
toolchain:

1. check out the source;
2. enable the MSVC x64 developer environment;
3. install Qt 5.15.2 `win64_msvc2019_64` plus WinExtras;
4. configure the CMake/Ninja Release build;
5. build the `stage-smoke` target, which validates the deployable runtime
   manifest; and
6. generate the two legal KAR regression fixtures and upload the complete staged
   runtime as a workflow artifact.

The artifact is named `HandyKaraoke-windows-x64-stage` and is retained for
14 days.  It is a portable test runtime, **not** an installer or signed release.

## What CI proves

- The repository contains enough x64 source, import libraries, runtime DLLs,
  Qt dependencies, and CMake logic to configure and build on a fresh hosted
  Windows VM.
- `windeployqt` and the explicit BASS/WinSparkle deployment produce the
  expected stage manifest.
- The staged folder has the regression fixtures required for manual KAR tests.

CI does not launch the GUI: hosted Windows runners have no reliable audio,
MIDI, display, SoundFont, or VST environment.  Launch/playback verification
remains the documented manual P1c gate.

## Deliberately out of scope

- An Inno Setup installer is not generated yet.  Its scripts still contain
  former-workstation paths and must first be converted to repository-relative
  inputs.
- The Visual C++ Redistributable, code signing, publisher identity,
  installer upgrade semantics, and clean-VM installer launch test are separate
  packaging work.
- Auto-update remains disabled until signing-key and update-endpoint ownership
  are explicitly approved.
- No media, SoundFont, or VST plug-in is placed in the artifact.

## How to use an artifact

After a successful workflow run, download
`HandyKaraoke-windows-x64-stage`, extract it, add only content that you are
authorised to use, and launch `HandyKaraoke.exe` from the extracted folder.
For release-quality verification, use the P1c manual matrix and the generated
KAR fixtures.

## Next P3 increments

1. Make the Inno Setup inputs relative and fail clearly when required release
   inputs are absent.
2. Build an unsigned installer artifact in CI.
3. Test installer install/launch/uninstall in a clean Windows VM.
4. Decide publisher certificate, signing process, release channel, and update
   endpoint before enabling auto-update.
