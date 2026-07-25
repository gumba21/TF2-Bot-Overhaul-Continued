# TF2 Bot Overhaul Continued

A continuation of the TF2 Bot Overhaul SourceMod and Stripper project, laid out as a deployment-ready Team Fortress 2 directory.

## Install or update

1. Install the required third-party runtime dependencies: Metamod:Source, SourceMod, and Stripper:Source.
2. Pull or download this repository.
3. Drag the repository's `tf` folder into the Team Fortress 2 installation directory.
4. Choose **Replace/Overwrite** when prompted.
5. Launch TF2 or restart the server.

The repository does not place project documentation or build tools inside the game directory. Everything under `tf/` is arranged at the path TF2 expects. See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) for the complete runtime path reference.

## Build plugins

```bash
tools/build_plugins.sh
```

```powershell
./tools/build_plugins.ps1
```

The SourceMod 1.12 manifest currently builds 24 active plugins and 2 disabled optional plugins directly into the deployable tree.

## Major Update 1 — Human Foundation

Shared human-like perception, reaction, memory, personality, decision cadence, and believable limitations beneath existing class behavior. See [`docs/HUMAN_FOUNDATION.md`](docs/HUMAN_FOUNDATION.md).

## Major Update 1.1 — Battlefield Knowledge

Observer-scoped battlefield facts, memory, stable groups, team state, front-line analysis, and a central query API. See [`docs/BATTLEFIELD_KNOWLEDGE.md`](docs/BATTLEFIELD_KNOWLEDGE.md).

## Major Update 1.2 — Tactical Navigation

`bot_navigation.smx` builds a cached tactical graph above TF2's existing `.nav` mesh, tracks decaying danger and friendly control, consumes fair Knowledge threats, calculates budgeted A* routes with general profiles, and exposes centralized movement requests through `bot_navigation.inc`.

The source-tracked `00_navmesh.smx` parser loads first; no platform-specific navigation extension is required. Core tracking runs in observation mode, while Medic safety, Scout flank, and emergency-retreat pilots remain disabled until live testing. See [`docs/TACTICAL_NAVIGATION.md`](docs/TACTICAL_NAVIGATION.md).

## Notes

- `tf/cfg/TF2_Bot_Overhaul.cfg` is loaded automatically by `bot_ai.smx` on map start.
- Runtime logs, Stripper dumps, compiler caches, and local server data are ignored by Git.
- Historical polish notes are stored under `docs/maintenance/`.
