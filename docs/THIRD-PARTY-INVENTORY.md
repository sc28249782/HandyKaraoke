# Third-Party Dependency Inventory

This is a recovery-build inventory, not a complete licence determination.
Before publishing a new installer, verify each component's current licence,
redistribution conditions, attribution requirements, and version.

| Component | Evidence in repository | Role | Recovery action |
| --- | --- | --- | --- |
| Qt | `HandyKaraoke.pro` uses Core, Gui, SQL, Widgets, and WinExtras | Desktop UI, SQLite driver, resources | Build first against Qt 5.15.x; plan a separately tested Qt 6 migration |
| BASS | `BASS/BASS_version.txt` reports 2.4.14 | Core audio engine | Validate import libraries and runtime DLL redistribution terms |
| BASSMIDI | version 2.4.12.1 | SoundFont/MIDI synthesis | Validate import libraries and runtime DLL redistribution terms |
| BASS FX | version 2.4.12.1 | Audio effects | Validate import libraries and runtime DLL redistribution terms |
| BASSmix | version 2.4.9 | Audio mixing | Validate import libraries and runtime DLL redistribution terms |
| BASS_VST | version 2.4.1 | Windows VST/VSTi hosting | Keep optional; audit plug-in safety and licence implications |
| RtMidi | `Midi/rtmidi` plus legacy Linux packaging | MIDI I/O outside WinMM path | Windows build uses the bundled source; revisit Linux separately |
| WinSparkle | `3rdParty/WinSparkle` | Legacy Windows update flow | Do not activate updates until signing and feed ownership are confirmed |
| Inno Setup | `_iss_setup/*.iss` | Legacy Windows installer | Replace hard-coded build-machine paths in the packaging phase |

## Non-code assets

Song files, SoundFonts, VST/VSTi plug-ins, and HNK samples must not be committed
or redistributed unless the project holds an explicit right to do so. Test
fixtures must be original or otherwise redistributable.

## HNK exception

The public source references HNK reader code but excludes it through
`.gitignore`. This is both a build blocker and a compatibility/licensing
decision; it is not a dependency that may be silently replaced.
