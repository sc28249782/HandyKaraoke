# Release roadmap — HandyKaraoke 3.0

## Decision

`feat/build-recovery` is the recovery line for the inherited `3.0.0-alpha` snapshot. It is not yet a public-stable release. The next official tag should be **`v3.0.0-alpha.1`**, not `v3.0.0`, after the first staged-runtime installer is built and tested.

The project follows Semantic Versioning-style release numbers. A prerelease suffix communicates risk and avoids promising compatibility that has not yet been verified.

## Version and channel model

| Version | Channel | Intended audience | Required outcome |
| --- | --- | --- | --- |
| `3.0.0-alpha.1` | Recovery checkpoint | Maintainers/testers | P1/P1b/P1c/P2/P3.1/P4a verified; source and staged runtime reproducible; no claim that installer is ready. |
| `3.0.0-alpha.2` | Installer preview | Maintainers/testers | First unsigned staged-runtime installer passes clean-machine install, launch, uninstall, and user-data preservation tests. |
| `3.0.0-beta.1` | Public non-commercial preview | Community testers | CI produces installer artifact; public release notes, known limitations, and recovery instructions are complete. |
| `3.0.0-beta.2` | Hardware regression preview | Community + MIDI hardware testers | Real MIDI connect/reorder/reconnect test passes; supported SoundFont/MIDI behaviour is documented. |
| `3.0.0-rc.1` | Release candidate | Wider non-commercial users | Clean-machine installer regression, P1c matrix, upgrade/uninstall test, and release artifact checks pass on the exact tag. |
| `3.0.0` | Stable | Public non-commercial users | No blocking regressions from RC; release notes, notices, package verification, and maintainer sign-off complete. |

Prerelease numbers may advance without promising complete backward compatibility. Patch releases use `3.0.1`, `3.0.2`, and so on only after `3.0.0` is stable.

## Current status

| Area | Status at 2026-09-17 |
| --- | --- |
| Reproducible Windows x64 build and staged runtime | Passed locally and in GitHub Actions. |
| MID/KAR/NCN, SoundFont, SQLite, Safe Mode, Reset Settings | Passed documented local gates. |
| BASS stack refresh | Passed local regression and GitHub Actions run 51. |
| Installer | New stage-based script exists; first local Inno Setup build and clean-machine test are pending. |
| Physical MIDI hardware reconnect/reorder | Pending hardware test. |
| Legacy HNK | Disabled; not a 3.0 compatibility claim. |
| HNK3 | Future clean-room work; not included in 3.0.0. |
| VST validation / VST3 | Not included in the 3.0.0 release gate. |

## Required release controls

### One source of truth for the version

Before `alpha.1`, add a small version manifest consumed by CMake, Inno Setup, Windows resource metadata, and release notes. Do not manually edit several version strings for a release. The manifest should hold:

- numeric product version: `3.0.0`;
- prerelease channel/number: for example `alpha.1`;
- display version: `3.0.0-alpha.1`; and
- Git tag/commit used to build the artifact.

### Tag and artifact rules

- Build every official artifact from an annotated tag such as `v3.0.0-alpha.1`.
- Record the exact commit and SHA-256 checksum in the GitHub Release notes.
- Never retag or overwrite a published artifact; publish a new prerelease number.
- Keep auto-update disabled through all 3.0 prereleases and stable 3.0.0 until signing and endpoint ownership have a separate approval.

### Public binary policy

Every official binary release must follow [Official Binary Release Policy](OFFICIAL-BINARY-RELEASE-POLICY.md). This is a maintainer release policy for official binaries; it does not alter GPLv3 rights in the inherited source.

## 3.0.0 scope boundary

`3.0.0` is a reliability and distributability release for the existing Windows/x64 MID, KAR, NCN, BASS MIDI/SoundFont path. It is not a promise to restore legacy HNK, add HNK3, migrate to Qt 6, support VST3, or provide ASIO/WASAPI.

Those capabilities should be scheduled only in later minor/major lines after separate design and compatibility work:

- `3.1.x`: HNK3 standalone tools and feature-gated reader, if its clean-room security and rights gates pass;
- `3.2.x`: modern hardware/MIDI adapter work, subject to physical-device testing; and
- `4.0.0`: potential Qt 6 and modern plug-in-host architecture, because that migration is a compatibility break.

## Immediate next sequence

1. Test `scripts\Build-Installer.ps1` locally with Inno Setup 6.
2. Install, launch, uninstall, and reinstall on a clean Windows test environment.
3. Add the shared version manifest and set the first planned display version to `3.0.0-alpha.1`.
4. Tag `v3.0.0-alpha.1` only after those checks pass; publish it as a prerelease, not as `Latest`.
5. Add an unsigned installer artifact to CI for `alpha.2` after the local installer is proven.

## Exit criteria for `v3.0.0`

- all `rc.1` release gates remain green on the final tagged commit;
- the installer is tested on a clean Windows x64 environment;
- known limitations explicitly include HNK disabled, VST scope, and physical-MIDI support status;
- the official-binary policy and required GPL/third-party notices accompany the release; and
- a maintainer approves the exact tag, checksum, and release notes.
