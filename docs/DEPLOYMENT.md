# Deployment layout

Copy the top-level `tf` folder into the Team Fortress 2 installation and choose **Replace/Overwrite**.

Runtime source and APIs:

- SourcePawn: `tf/addons/sourcemod/scripting/bot overhaul/`
- Battlefield Knowledge API: `tf/addons/sourcemod/scripting/include/bot_knowledge.inc`
- Tactical Navigation API: `tf/addons/sourcemod/scripting/include/bot_navigation.inc`
- Nav parser API: `tf/addons/sourcemod/scripting/include/navmesh.inc`

Runtime binaries:

- Active plugins: `tf/addons/sourcemod/plugins/bot overhaul/`
- Disabled optional plugins: `tf/addons/sourcemod/plugins/disabled/`
- `00_navmesh.smx` loads before `bot_navigation.smx`

No platform-specific navigation extension is required. A missing or invalid map nav mesh disables Tactical Navigation while preserving existing behavior.

Build with `tools/build_plugins.sh` or `tools/build_plugins.ps1`. The SourceMod 1.12 manifest produces 24 active plugins and 2 disabled optional plugins, and permanent GitHub Actions verifies the complete deployment set.
