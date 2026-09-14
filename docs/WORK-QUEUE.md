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
- [ ] Run the first real clean-checkout configure and compilation.
- [ ] Resolve the compiler and runtime findings from that build.
- [ ] Migrate to Qt 6 only after a verified Qt 5.15 recovery build.

**Done when:** a clean Windows 11 environment builds the application from the
documented instructions.

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
