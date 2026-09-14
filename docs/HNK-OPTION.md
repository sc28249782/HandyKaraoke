# HNK Compatibility Option

HNK support is intentionally disabled in the recovery build. The public source
snapshot does not include the HNK reader implementation, so this fork must not
claim HNK compatibility or silently ship a non-working parser.

## Default behaviour

Without HNK support:

- HNK files are not scanned into the song database.
- Existing HNK records display a clear “not enabled” message if selected.
- HNK paths appear disabled in Settings.
- MID/KAR/NCN code remains available for recovery and testing.
- HNK medley loading is skipped.

## Enabling later

HNK may be enabled only after authorised source or a lawful replacement
implementation and suitable regression fixtures are available.

### CMake

```powershell
cmake -S . -B build\msvc-x64 -G Ninja -DHK_ENABLE_HNK=ON
```

CMake verifies that all of the following files exist before continuing:

- `Midi/HNKFile.cpp`
- `Midi/HNKFile.h`
- `Midi/HNKFileComp.h`

### qmake

```powershell
qmake CONFIG+=hnk
```

The qmake project performs the same file checks and defines
`HANDYKARAOKE_ENABLE_HNK` only when HNK is requested.

## Code boundary

All HNK-only paths are guarded by `HANDYKARAOKE_ENABLE_HNK`. New HNK code
must stay behind that boundary and must not change the behaviour of the
default build without a deliberate review.
