# P2 — MIDI Configuration Recovery Test

This test verifies that an old or unavailable MIDI device cannot block
HandyKaraoke at startup.

## What the recovery build does

The application still reads the legacy numeric settings (`MidiOut`, `MidiIn`,
and `MidiChannelMapper`) once for compatibility. After a successful start it
also saves the matching device names:

- `MidiOutName`
- `MidiInName`
- `MidiChannelMapperNames`

On later starts, a matching name is used even if Windows has reordered MIDI
ports. If the saved name is absent or a port cannot be opened, the recovery
defaults are:

- MIDI output: **Midi Synthesizer (SoundFont)**
- MIDI input: **None**
- invalid per-channel map: **Midi Synthesizer (SoundFont)**

## Build

Build the staged Release runtime from a VS 2022 x64 Native Tools prompt:

~~~bat
cd /d E:\Projects\HandyKaraoke
git pull --ff-only origin feat/build-recovery
cmake --build build\msvc-x64-release --target stage-runtime --parallel
~~~

Launch only:

~~~bat
build\msvc-x64-release\stage\HandyKaraoke\HandyKaraoke.exe
~~~

## No-hardware test

This is the appropriate test while no external MIDI controller is available.

1. In **Settings → Audio devices**, set MIDI output to
   `Midi Synthesizer (SoundFont)` and MIDI input to `None`.
2. Close the program normally, then start it again.
3. Confirm that Settings still shows those two values and play a known-good
   NCN/MIDI + SoundFont fixture.
4. Close the program. Back up then edit:
   `%USERPROFILE%\.HandyKaraoke\Config\HandyKaraoke.conf`.
5. Change `MidiOut` and `MidiIn` to a clearly invalid non-negative number,
   for example `999`. Delete `MidiOutName` and `MidiInName` to emulate
   an older numeric-only configuration.
6. Start HandyKaraoke. It must open without a crash and show SoundFont/None.
   Play the same fixture again.

Do not share SoundFont or song files in the repository unless their
redistribution licence permits it.

## Hardware test (deferred)

When a USB MIDI device becomes available, select it, exit the application,
then reconnect it to a different USB port or change its enumeration order.
The application should select the stored device name. If it is absent, it
must start using SoundFont/None instead.
