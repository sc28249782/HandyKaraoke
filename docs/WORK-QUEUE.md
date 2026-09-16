# Phase 0 Work Queue

GitHub Issues are currently disabled for this repository. This file is the
temporary, reviewable work queue. Move each item to an Issue after Issues are
enabled.

## P0 — HNK compatibility decision

**Why:** The public source references missing HNK reader files and cannot fully
build without a decision.

- [x] Feature-gate HNK and disable it by default in CMake, qmake, scanning,
      playback, medley loading, and Settings.
- [ ] Contact the original maintainer for the missing source, format
      documentation, and permission.
- [ ] Record the outcome in `docs/`.
- [ ] Restore and test HNK support only if the legal and technical requirements
      are met.

**Done when:** the default build never references missing HNK source files and
the optional path has a documented compatibility decision.

## P1 — Reproducible Windows x64 build

- [x] Inventory existing build and runtime dependencies in
      `docs/THIRD-PARTY-INVENTORY.md`.
- [x] Add a CMake + Ninja recovery manifest for the legacy Windows x64 source.
- [x] Keep qmake as the legacy reference and document the first configure
      command in `BUILDING.md`.
- [x] Feature-gate HNK code so the default build does not require missing
      source files.
- [x] Run the first real Windows 11 x64 configure and compilation
      (2026-09-16, VS 2022 + Qt 5.15.2 MSVC 2019 x64).
- [x] Resolve the initial compiler and launch blockers: bundled RtMidi include
      path, QPainterPath include, ANSI/Unicode WinMM device names, debug
      deployment, VSTi metadata initialization, and English translation assets.
- [x] Launch the deployed Debug build and switch Thai/English successfully.
- [ ] Smoke-test startup with no MIDI device, SQLite database creation, and
      legally redistributable MID/KAR/NCN fixtures.
- [ ] Migrate to Qt 6 only after a verified Qt 5.15 recovery build.

**Done when:** a clean Windows 11 environment builds the application from the
documented instructions.

## P1b — Runtime staging baseline

- [x] Record the HandyKaraoke 2.4.1 installed-folder layout and release history
      as a compatibility reference.
- [x] Add the `stage-runtime` CMake target, which creates a release-like
      runtime layout without copying user media.
- [ ] Generate a Release-stage folder and verify its runtime manifest.
- [x] Manually verify NCN/MIDI playback and SoundFont synthesis (maintainer
      test, 2026-09-16).
- [ ] Confirm the same smoke test is launched from the staged folder and record
      its runtime manifest.
- [ ] Build or deliberately replace the legacy VST checker before enabling
      VST scanning in a staged release.

**Done when:** a fresh staged folder has the supported runtime files and empty
song, SoundFont, and VST locations ready for smoke testing.

## P2 — MIDI configuration resilience

- [ ] Bounds-check persisted MIDI device selections.
- [ ] Fall back safely when a device is missing or reordered.
- [ ] Add a reset-settings/safe-mode entry point.
- [ ] Test startup with no device and stale settings.

**Done when:** stale MIDI settings cannot prevent the application from starting.

## P3 — CI and packaging

- [ ] Replace absolute developer-machine paths in the Inno Setup scripts.
- [ ] Add a Windows GitHub Actions build/test workflow.
- [ ] Produce a PR artifact and package-launch smoke test.
- [ ] Keep auto-update disabled until signing and endpoint ownership are verified.

**Done when:** CI produces an installable Windows x64 artifact without paths
from a developer workstation.
