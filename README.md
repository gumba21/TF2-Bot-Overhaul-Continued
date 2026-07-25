# TF2 Bot Overhaul Continued

A continuation of the TF2 Bot Overhaul SourceMod and Stripper project, laid out as a deployment-ready Team Fortress 2 directory.

## Install or update

1. Install the required third-party runtime dependencies: Metamod:Source, SourceMod, and Stripper:Source.
2. Pull or download this repository.
3. Drag the repository's `tf` folder into the Team Fortress 2 installation directory.
4. Choose **Replace/Overwrite** when prompted.
5. Launch TF2 or restart the server.

The repository does not place project documentation or build tools inside the game directory. Everything under `tf/` is arranged at the path TF2 expects.

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

Both scripts download SourceMod 1.12 when `spcomp` is not already available, compile every tracked SourcePawn source, and write the resulting `.smx` files directly into the deployable `tf/addons/sourcemod/plugins/` tree.

The original active plugin set remains active. `sd_doomsday_bots.smx` and `tf2botchatter.smx` compile into `plugins/disabled/` because they were source-only in the supplied package. The original upstream sources for `GiveBotsCosmetics` and `tf_bot_medic_fix` are now tracked in the repository, so every deployed plugin is reproducibly buildable without opaque binary-only exceptions.

## Major Update 1 — Human Foundation

The current development branch adds a universal human-like layer underneath existing class behavior: configurable sight and hearing, reaction and thinking delays, last-known-position investigation, per-life personality traits, risk/reward intents, believable emergent mistakes, and an optional Unfair baseline. See [`docs/HUMAN_FOUNDATION.md`](docs/HUMAN_FOUNDATION.md).

## Notes

- `tf/cfg/TF2_Bot_Overhaul.cfg` is loaded automatically by `bot_ai.smx` on map start.
- Runtime logs, Stripper dumps, compiler caches, and local server data are ignored by Git.
- Historical polish notes are stored under `docs/maintenance/`.
