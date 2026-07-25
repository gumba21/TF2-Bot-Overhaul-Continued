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
- Active plugins: `tf/addons/sourcemod/plugins/bot overhaul/`
- Disabled optional plugins: `tf/addons/sourcemod/plugins/disabled/`
- SourceMod configuration: `tf/addons/sourcemod/configs/`
- SourceMod gamedata: `tf/addons/sourcemod/gamedata/`
- Main overhaul configuration: `tf/cfg/TF2_Bot_Overhaul.cfg`
- Stripper configuration: `tf/addons/stripper*/`
- MvM population scripts and TF2 scripts: `tf/scripts/`

`bot_knowledge.smx` and its public include are part of the drop-in tree; users do not need to compile Major Update 1.1 before installing it.

## Build verification

Run either:

```bash
tools/build_plugins.sh
```

or:

```powershell
./tools/build_plugins.ps1
```

The build manifest is `tools/plugin-layout.txt`. It currently produces 22 active plugins and 2 disabled optional plugins. GitHub Actions repeats the full build on pushes and pull requests and verifies that the complete deployment plugin set is produced.
