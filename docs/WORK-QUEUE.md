# Phase 0 Work Queue

GitHub Issues are currently disabled for this repository. This file is the
temporary, reviewable work queue. Move each item to an Issue after Issues are
enabled.

## P0 — HNK compatibility decision

**Why:** The public source references missing HNK reader files and cannot fully
build without a decision.

- Contact the original maintainer for the missing source, format documentation,
  and permission.
- Record the decision in `docs/`.
- Either restore and test HNK support, or remove/feature-gate it from the
  recovery build.

**Done when:** the build never references missing source files.

## P1 — Reproducible Windows x64 build

- Inventory the existing build and runtime dependencies.
- Introduce CMake + Ninja targeting MSVC 2022 and a supported Qt 6 release.
- Keep qmake only as a legacy reference during migration.
- Write `BUILDING.md` with clean-checkout instructions.

**Done when:** a clean Windows 11 environment builds the application from the
documented instructions.

## P2 — MIDI configuration resilience

- Bounds-check persisted MIDI device selections.
- Fall back safely when a device is missing or reordered.
- Add a reset-settings/safe-mode entry point.
- Test startup with no device and stale settings.

**Done when:** stale MIDI settings cannot prevent the application from starting.

## P3 — CI and packaging

- Replace absolute developer-machine paths in the Inno Setup scripts.
- Add a Windows GitHub Actions build/test workflow.
- Produce a PR artifact and package-launch smoke test.
- Keep auto-update disabled until signing and endpoint ownership are verified.

**Done when:** CI produces an installable Windows x64 artifact without paths
from a developer workstation.
