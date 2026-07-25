# TF2 Bot Overhaul Continued

A continuation of the TF2 Bot Overhaul SourceMod and Stripper project, laid out as a deployment-ready Team Fortress 2 directory.

## Install or update

1. Install the required third-party runtime dependencies: Metamod:Source, SourceMod, and Stripper:Source.
2. Pull or download this repository.
3. Drag the repository's `tf` folder into the Team Fortress 2 installation directory.
4. Choose **Replace/Overwrite** when prompted.
5. Launch TF2 or restart the server.

The repository does not place project documentation or build tools inside the game directory. Everything under `tf/` is arranged at the path TF2 expects. See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for the complete runtime path reference.

## Repository layout

```text
TF2-Bot-Overhaul-Continued/
├── tf/
│   ├── cfg/TF2_Bot_Overhaul.cfg
│   ├── scripts/
│   └── addons/
│       ├── metamod/
│       ├── sourcemod/
│       │   ├── configs/
│       │   ├── gamedata/
│       │   ├── plugins/
│       │   └── scripting/
│       ├── stripper/
│       ├── stripper_missions/
│       └── stripper_missions_invasion/
├── docs/
├── tools/
└── README.md
```

## Build plugins

Linux/macOS:

```bash
tools/build_plugins.sh
```

Windows PowerShell:

```powershell
./tools/build_plugins.ps1
```

Both scripts download SourceMod 1.12 when `spcomp` is not already available, compile every tracked SourcePawn source, and write the resulting `.smx` files directly into the deployable `tf/addons/sourcemod/plugins/` tree. The complete manifest currently contains 24 active plugins and 2 disabled optional plugins.

The original active plugin set remains active. `sd_doomsday_bots.smx` and `tf2botchatter.smx` compile into `plugins/disabled/` because they were source-only in the supplied package. The original upstream sources for `GiveBotsCosmetics` and `tf_bot_medic_fix` are tracked in the repository, so every deployed plugin is reproducibly buildable without opaque binary-only exceptions.

The Tactical Navigation nav-access dependency is also tracked as source. `00_navmesh.smx` is built from a pinned GPL-3.0 SourcePawn parser and loads before `bot_navigation.smx`; no platform-specific native extension is required.

## Major Update 1 — Human Foundation

The current development branch adds a universal human-like layer underneath existing class behavior: configurable sight and hearing, reaction and thinking delays, last-known-position investigation, per-life personality traits, risk/reward intents, believable emergent mistakes, and an optional Unfair baseline. See [`docs/HUMAN_FOUNDATION.md`](docs/HUMAN_FOUNDATION.md).

## Major Update 1.1 — Battlefield Knowledge

`bot_knowledge.smx` adds a shared, perception-aware information layer for future class, weapon, personality, communication, coordination, and Team Director behavior.

It separates authoritative world truth from observer-scoped bot knowledge, preserves lost enemies as decaying memories with positional uncertainty, caches players/buildings/objectives, detects stable groups, estimates the front line, publishes team battlefield states, and exposes a central native query API. Existing combat behavior remains unchanged in observation mode. The Mad Milk pilot is present but disabled by default. See [`docs/BATTLEFIELD_KNOWLEDGE.md`](docs/BATTLEFIELD_KNOWLEDGE.md).

## Major Update 1.2 — Tactical Navigation

`bot_navigation.smx` builds a reusable tactical graph above TF2's existing `.nav` mesh. It caches areas and connections, analyzes geometry, tracks per-team traffic and decaying danger, consumes observer-scoped Knowledge threats, calculates budgeted A* routes with general route profiles, and exposes centralized movement requests through `bot_navigation.inc`.

Core graph and overlay tracking run in observation mode by default. The visible Medic safety, Scout flank, and emergency-retreat pilots are compiled but disabled until live TF2 testing. See [`docs/TACTICAL_NAVIGATION.md`](docs/TACTICAL_NAVIGATION.md).

## Notes

- `tf/cfg/TF2_Bot_Overhaul.cfg` is loaded automatically by `bot_ai.smx` on map start.
- Runtime logs, Stripper dumps, compiler caches, and local server data are ignored by Git.
- Historical polish notes are stored under `docs/maintenance/`.
