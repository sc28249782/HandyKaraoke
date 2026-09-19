# HNK3 Package Format RFC

**Status:** Draft 0.1 — clean-room design baseline  
**Extension:** .hnk3  
**Scope:** new HandyKaraoke song package; no legacy HNK compatibility  
**Updated:** 2026-09-17

## Purpose

HNK3 combines the content traditionally kept as an NCN MIDI file, lyric file,
and cursor file into a single, versioned package. It is designed to provide
fast library indexing, reliable playback data, publisher attribution, and
detectable modification.

Legacy HNK remains disabled. HNK3 does not decode, import, or claim
compatibility with that undocumented format.

## Design principles

| Decision | Reason |
|---|---|
| Use a new extension and Songs/HNK3 directory | Keeps it distinct from the unavailable legacy HNK reader. |
| Start with signed packages | Gives authorship and tamper evidence without a licence server. |
| Make metadata public but signed | Scans can be fast without opening the protected song payload. |
| Use a chunked container | Enables range validation, lazy loading, future seek indexes, and safe evolution. |
| Defer encryption and DRM | A key embedded in an open-source application is not meaningful protection. |
| Import NCN only in the first tool | Creates a controlled, testable migration path from MID/LYR/CUR. |

## Security model

### HNK3 provides

- Publisher identity through an Ed25519 digital signature.
- A signed, immutable package identifier and attribution manifest.
- Rejection of modified headers, metadata, directories, or payload bytes.
- Optional future licensed encryption with a per-package content key.

### HNK3 does not provide

- Impossible copy prevention. Audio can be recorded and a determined user may
  alter a player or inspect decrypted memory.
- A legal judgement of copyright ownership.
- A substitute for a content-distribution agreement.

The practical objective is to make casual alteration and false redistribution
detectable, preserve technical provenance, and support a later commercial
licence service if justified.

## Package profiles

| Profile | ID | Contents | Use |
|---|---|---|---|
| Signed | S | Plain payload chunks plus signature | First implementation and author distribution |
| Licensed | L | AES-GCM payload chunks plus signature and external licence | Deferred commercial option |
| Development | D | Signed, explicit test-only package | Test fixtures only |

Release builds must reject D packages unless a documented developer option is
enabled.

## Logical format

All fixed-width integers are little-endian. The parser must reject integer
overflow, out-of-file offsets, overlapping chunk ranges, unknown mandatory
flags, and allocation requests above explicit limits.

~~~text
+----------------------------+
| Fixed header               |
+----------------------------+
| META: public JSON          |
+----------------------------+
| MIDI / LYRC / CURS chunks  |
| optional future chunks     |
+----------------------------+
| Table of contents          |
+----------------------------+
| SIGN: final chunk          |
+----------------------------+
~~~

### Header

The fixed header contains:

| Field | Description |
|---|---|
| magic | Eight bytes: HNK3PKG followed by a zero byte |
| format major/minor | Starts at 3.0; readers reject unsupported major versions |
| profile and flags | S, L, or D and feature flags |
| package UUID | Random immutable 128-bit package identity |
| metadata range | Offset and length of META |
| TOC range | Offset and length of the table of contents |
| signature range | Offset and length of SIGN; SIGN must be final |

Exact byte sizes and constants are frozen only with the first binary fixture
set. Until then this document is a format contract, not a byte-layout release.

### Chunk directory

Each TOC entry contains:

| Field | Description |
|---|---|
| FourCC | META, MIDI, LYRC, CURS, EVNT, INDX, THMB, or a registered future value |
| flags | Mandatory/optional, encrypted, and compression codec |
| offset, stored size, plain size | Validated 64-bit ranges |
| stored SHA-256 | Hash of exact stored bytes |
| plain SHA-256 | Hash after decryption/decompression when applicable |
| nonce/tag data | Present only for encrypted chunks |

The first writer creates META, MIDI, LYRC, CURS, and SIGN. Future reader
versions may support EVNT, INDX, LYRT, CURT, and THMB.

### Signature

SIGN is always the final chunk and contains:

- algorithm identifier: Ed25519;
- publisher key ID;
- signature bytes;
- optional signer display or certificate-chain data.

The signature covers every byte preceding SIGN: header, META, payload chunks,
and TOC. Therefore reordering chunks, altering attributes, or replacing
ciphertext is detectable. The reader verifies the signature before adding a
song to the normal library index and revalidates a chunk before playback.

## Metadata

META is UTF-8 JSON without a BOM. Verification always uses the original stored
bytes; the reader never parse-and-reserializes JSON before checking SIGN.

~~~json
{
  "schema": "hnk3-meta/1",
  "package_id": "UUID",
  "content_id": "publisher immutable catalog ID",
  "title": "song title",
  "artist": "display artist",
  "composer": "optional",
  "lyricist": "optional",
  "arranger": "optional",
  "publisher": "publisher display name",
  "publisher_key_id": "key identifier",
  "language": "th",
  "tempo_bpm": 120,
  "duration_ticks": 0,
  "created_utc": "2026-09-17T00:00:00Z",
  "rights_notice": "publisher supplied notice",
  "source_profile": "NCN",
  "content_revision": 1
}
~~~

Do not place a private key, user identity, entitlement token, or raw source
path in META.

## Initial content profile

| Chunk | Version 3.0 behaviour |
|---|---|
| MIDI | Standard MIDI bytes from the approved NCN input |
| LYRC | Lyric data normalized by the compiler to UTF-8 |
| CURS | Cursor data with a parser/version marker |
| META | Public, signed metadata |
| SIGN | Required Ed25519 signature |

The first reader should adapt existing parsers to an in-memory QIODevice or
byte-array source. It must not write decrypted content to predictable temporary
files.

### Performance evolution

Version 3.0 deliberately uses no compression. A later minor version may add:

| Chunk | Purpose |
|---|---|
| EVNT | Precompiled MIDI event timeline |
| INDX | Tick/time index for seeking and medley preload |
| LYRT | Parsed lyric timeline |
| CURT | Parsed cursor timeline |

This is the performance path, but it begins only after a MIDI/LYR/CUR
implementation has parity tests. Any future compression is per chunk and must
enforce a maximum decompressed size.

## Licensed encryption profile

The L profile is explicitly deferred. Its minimum rules are:

- AES-256-GCM with a unique nonce for every encrypted chunk.
- A random key per package; never a product-wide key compiled into the app.
- A separate signed licence bound to package_id and a key envelope or policy.
- Defined expiry, revocation, key rotation, offline-grace, and privacy rules.
- A missing licence is a clear not-authorised result; it must never crash the
  player or silently play another file.

Because the player source is public, this is access control and deterrence, not
a guarantee against extraction.

## HandyKaraoke integration

### Library scan

- Add song type HNK3; do not reuse HNK.
- Add a separate default path Songs/HNK3.
- Read only the bounded header, META, TOC, and SIGN during scanning.
- Index only successfully verified packages.
- Record invalid packages in a recoverable scan report with path, reason, and
  time; do not crash or block application startup.
- Do not decrypt MIDI, LYRC, or CURS merely to show a search result.

### Playback boundary

Introduce a SongContentSource boundary. NCN continues to provide three files;
HNK3 provides verified memory chunks. This keeps HNK3-specific logic out of
MidiPlayer, lyrics widgets, and medley code. Safe mode must remain able to
launch without HNK3 scanning.

## Compiler workflow

The first authoring component is a separate command-line tool named
hnk3-tool.

~~~text
hnk3-tool pack --ncn <Song/Lyrics/Cursor root> --song-id <ID>
               --metadata <metadata.json> --signing-key <secure key source>
               --output <song-id>.hnk3
~~~

The tool must:

1. Validate matching MID, LYR, and CUR inputs.
2. Decode legacy lyric encoding deliberately, then write UTF-8.
3. Verify duration, first tempo, and timeline consistency.
4. Generate a package UUID, hashes, TOC, and signature.
5. Re-open and verify its own output before reporting success.
6. Produce a machine-readable report without any private-key material.
7. Require confirmation that the operator has authority to package the input.

It intentionally does not read legacy HNK.

## Key management

- Release builds contain a small versioned trusted-publisher key list.
- Each key has a stable ID, display name, and status.
- Key-list updates are signed and atomically applied.
- User-imported keys, if later allowed, are displayed as locally trusted.
- Private signing keys never enter the repository, CI logs, packages, or issue
  comments.
- Key compromise needs a signed revocation and replacement-key procedure.

## Required test fixtures

| Test | Expected result |
|---|---|
| Valid signed package | Scan, search, and playback succeed |
| Modified header, metadata, content, or TOC byte | Signature/hash validation fails |
| Truncated file or invalid range | Rejected without crash or large allocation |
| Overlapping chunks | Rejected |
| Unsupported major version/mandatory flag | Explicit rejection |
| Thai and multilingual metadata | Correct UI display and search |
| NCN conversion fixture | Equivalent MIDI, lyric, and cursor timing |
| Fuzzed header/TOC corpus | No crash, hang, path traversal, or memory exhaustion |
| Future missing/invalid licence | Player remains usable and reports authorisation failure |

Benchmark first-play latency and library scan time against a representative NCN
library before implementing EVNT/INDX optimisation.

## Delivery milestones

| Milestone | Deliverable |
|---|---|
| H3.0 | RFC approval, fixture ownership, and signing-key procedure |
| H3.1 | Standalone parser/writer library plus signed fixtures |
| H3.2 | hnk3-tool NCN packer and verifier |
| H3.3 | Feature-gated HNK3 scan and basic playback |
| H3.4 | EVNT/INDX only if benchmark supports it |
| H3.5 | Separate licensed-encryption/service decision |

## Non-goals

- Decoding or emulating legacy HNK.
- A universal DRM guarantee.
- Storing VST, SoundFonts, executable code, or plug-ins in HNK3.
- Enabling HNK3 by default before fixtures and corruption tests pass.
- Combining HNK3 implementation with the deferred MIDI hardware work.

## Decisions needed before H3.1

1. Who is the first trusted publisher and where is its signing key stored?
2. Which metadata fields are mandatory for the intended catalog?
3. Is the first distribution signed-only, private-library, or commercial?
4. Will authoring stay CLI-only initially?
5. Which NCN files are authorised for automated test fixtures?
