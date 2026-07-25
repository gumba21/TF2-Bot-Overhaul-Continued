# Deployment layout

This repository mirrors Team Fortress 2's runtime directory structure under the top-level `tf/` folder.

## Updating an installation

1. Ensure Metamod:Source, SourceMod, and Stripper:Source are installed.
2. Close TF2 or stop the server.
3. Copy this repository's `tf` folder into the Team Fortress 2 installation directory.
4. Choose **Replace/Overwrite** when prompted.
5. Launch TF2 or restart the server.

This is intended as a drop-in update for an installation that already has the required third-party runtime dependencies. Project documentation and build tools remain outside `tf/` and are not copied into the game.

## Runtime paths

- SourcePawn source: `tf/addons/sourcemod/scripting/bot overhaul/`
- Shared Knowledge API: `tf/addons/sourcemod/scripting/include/bot_knowledge.inc`
- Tactical Navigation API: `tf/addons/sourcemod/scripting/include/bot_navigation.inc`
- Nav parser API: `tf/addons/sourcemod/scripting/include/navmesh.inc`
- Active plugins: `tf/addons/sourcemod/plugins/bot overhaul/`
- Disabled optional plugins: `tf/addons/sourcemod/plugins/disabled/`
- SourceMod configuration: `tf/addons/sourcemod/configs/`
- Optional navigation metadata: `tf/addons/sourcemod/data/bot_overhaul/navigation/`
- SourceMod gamedata: `tf/addons/sourcemod/gamedata/`
- Main overhaul configuration: `tf/cfg/TF2_Bot_Overhaul.cfg`
- Stripper configuration: `tf/addons/stripper*/`
- MvM population scripts and TF2 scripts: `tf/scripts/`

`bot_knowledge.smx`, `00_navmesh.smx`, `bot_navigation.smx`, and their public includes are part of the drop-in tree. No local compile is required before installation.

Tactical Navigation does not require a platform-specific native extension. When a map has no usable `.nav` mesh, it disables itself safely and leaves the existing behavior active.

## Build verification

Run either:

```bash
tools/build_plugins.sh
```

or:

```powershell
./tools/build_plugins.ps1
```

The build manifest is `tools/plugin-layout.txt`. It currently produces 24 active plugins and 2 disabled optional plugins. GitHub Actions repeats the full build on pushes and pull requests, preserves compiler diagnostics, and verifies that the complete deployment plugin set is produced.
