# Phase 0 — Build Recovery

## Objective

Create a reproducible Windows x64 development build before any feature work.
The baseline is commit `dd0eaa1` (3.0.0-alpha), inherited from the original project.

## Current blockers

1. The qmake project references files that are absent from this repository:

   - `Midi/HNKFile.cpp`
   - `Midi/HNKFile.h`
   - `Midi/HNKFileComp.h`

   These files are needed by the HNK import/playback path.  Therefore a full build
   cannot succeed from the public source as it stands.

2. Linux releases depend on an old `librtmidi.so.4` and have reported startup
   failures on current distributions.

3. The Inno Setup scripts contain absolute paths from the former maintainer's
   workstation, so the installer cannot be reproduced.

## Scope and decisions

- Windows 11 x64 is the first supported target.
- Keep the existing Qt Widgets UI during recovery; do not rewrite the application.
- Use CMake + Ninja and a supported Qt 6 toolchain for new build automation, while
  retaining the existing qmake project as the historical reference.
- Treat HNK support as blocked until the original source, a documented legal format
  specification, or explicit permission is obtained.
- The first preview may support only formats whose reader source is present
  (MID/KAR/NCN, subject to verification).
- Do not redistribute song files, SoundFonts, VST plug-ins, or other media without
  an explicit redistribution right.

## Deliverables

- [ ] A clean Windows x64 build from a fresh checkout.
- [ ] A documented dependency and licence inventory.
- [ ] A CMake build that generates the application and tests.
- [ ] GitHub Actions build artifacts for pull requests.
- [ ] A portable Windows package assembled without workstation-specific paths.
- [ ] A smoke-test checklist and a small, redistributable test fixture set.
- [ ] A documented decision for the HNK feature.

## Verification gates

1. Configure and build in a clean environment.
2. Launch with an empty configuration and no MIDI output device.
3. Create and reopen the SQLite song database.
4. Scan a test library and play a known MID/KAR fixture.
5. Restart after changing MIDI output and after resetting settings.
6. Package the executable and verify it launches on a clean Windows 11 VM.

## Out of scope

Remote control, UI redesign, mobile use, VST3, Rust migration, and new song
features are deferred until the recovery gates pass.
