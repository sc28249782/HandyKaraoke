# Development Status

This fork preserves the last public source snapshot of HandyKaraoke and starts
its maintenance recovery work on branch `feat/build-recovery`.  The consolidated
history, technical decisions, architecture, and verification record are in
[BUILD-RECOVERY-CHANGELOG.md](BUILD-RECOVERY-CHANGELOG.md).

## Technology inventory

| Area | Current implementation | Recovery direction |
| --- | --- | --- |
| Application/UI | C++11, Qt 5, qmake, Qt Widgets | Retain Widgets; introduce CMake and supported Qt 6 |
| Song library | Qt SQL with SQLite | Preserve schema; add migration and fixture tests |
| MIDI | WinMM on Windows; RtMidi on Unix | Validate unavailable or changed devices safely |
| Synth/effects | BASS 2.4 family and SoundFonts | Isolate behind adapters; audit licences before updates |
| Plug-ins | Windows VST/VSTi path | Treat as optional and untrusted native code |
| Installer | Inno Setup with absolute local paths | First Windows x64 stage-artifact CI added; installer portability remains P3 |
| Updates | WinSparkle/appcast references | Disable by default until signing and ownership are verified |

## Known source and runtime risks

- HNK reader files are absent, preventing a complete source build.
- Configuration persists a numeric MIDI device selection; device enumeration can
  change between runs, so every persisted selection must be bounds-checked.
- Linux builds were packaged against legacy RtMidi/Qt dependencies and have open
  reports of loader errors and a current Ubuntu segmentation fault.
- Loading a VST/VSTi executes third-party native code in the application process.
  The application needs a safe mode and a reset-config path before VST is enabled.
- The repository contains third-party binaries and source. Every release must
  publish an accurate notice and satisfy the relevant redistribution conditions.

## Working rules

- Keep feature work separate from recovery work until a clean build and smoke
  tests are available.
- Never use real copyrighted songs as repository fixtures.
- Changes to parsers and audio code require regression tests with legal fixtures.
- Treat HNK parsing as a separate legal and technical workstream.


## Release roadmap

The active recovery branch remains a prerelease line. See
[Release roadmap](RELEASE-ROADMAP.md) for the `3.0.0-alpha.1` through `3.0.0`
quality gates and the explicit out-of-scope boundary.
