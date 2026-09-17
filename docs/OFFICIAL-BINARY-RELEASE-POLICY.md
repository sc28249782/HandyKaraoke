# Official Binary Release Policy

**Status:** adopted 2026-09-17

## Purpose and scope

This policy applies only to prebuilt HandyKaraoke binaries that the project maintainer publishes as an **official release** from this repository. It does not apply to a user's independent exercise of rights granted by the repository's GPLv3 licence.

## Official-release commitment

The project will publish official binaries only for non-commercial use. In particular, an official binary release must not be sold or used to generate income through advertising, subscriptions, paid features, paid access, or a bundled commercial service.

This policy is intended to keep official releases within the free non-commercial-use condition of the BASS components currently bundled with the Windows runtime. It does not include songs, SoundFonts, VST plug-ins, or any other third-party user content.

## GPL and third-party boundaries

The repository remains licensed under GPLv3. This policy is a maintainer release policy, **not** an additional software licence or EULA. It neither changes GPLv3 nor attempts to remove rights that GPLv3 grants to recipients of the source code.

BASS, BASSMIDI, BASSmix, BASS FX, BASS_VST, Qt, WinSparkle, and other bundled or referenced dependencies have their own licence terms. A released binary does not sublicense those components. Recipients and redistributors remain responsible for complying with the applicable third-party terms.

## Commercial requests

The project will not publish an official commercial binary while it uses BASS under its non-commercial terms. A future commercial product requires, before publication:

- the appropriate BASS licence held by the product developer/publisher;
- review of the licence and copyright status of all dependencies and inherited source; and
- a separate release decision and documented distribution plan.

## Release checklist

Before creating an official binary release, the maintainer must confirm:

- the release has no sales, advertising, subscription, paid feature, or paid-service revenue;
- the release contains no unlicensed songs, SoundFonts, VST plug-ins, or other media;
- the required source and notices for GPLv3 distribution are available; and
- the P1c/P4a stage and CI gates have passed for the exact release commit.

## Non-endorsement and warranty

Official binaries are provided without warranty, subject to the repository's GPLv3 terms and the applicable third-party licence terms.
