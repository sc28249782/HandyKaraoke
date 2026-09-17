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

## First hosted result

GitHub Actions workflow run **16** passed on 2026-09-17 for commit
`0492ac120258fd19497a57cd65c921bf240cef54`.  The following steps all
completed successfully: Qt installation, CMake configure, Release build,
`stage-smoke`, fixture generation, and artifact upload.

The initial run failed only because the workflow requested a nonexistent
separate `qtwinextras` package.  Removing that request was correct: the
desktop Qt 5.15.2 kit already supplies the WinExtras component required by the
build.

GitHub Actions run **28** subsequently verified P3.1: the same Release build
and stage checks passed with no MSVC compiler warnings. The remaining workflow
annotation is the Node 20 deprecation warning emitted by third-party actions;
it does not originate in HandyKaraoke.

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
