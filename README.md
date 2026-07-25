# TF2 Bot Overhaul Continued

A continuation and maintenance workspace for the TF2 Bot Overhaul SourceMod/Stripper project.

This repository preserves the editable SourcePawn source, configuration files, map logic, MvM population scripts, and maintenance notes so future changes can be reviewed and developed through Git.

## Main AI modules

- `addons/sourcemod/scripting/bot overhaul/bot_ai.sp` — general bot behavior
- `addons/sourcemod/scripting/bot overhaul/bot_rocketjump.sp` — Soldier/Demoman movement behavior
- `addons/sourcemod/scripting/bot overhaul/bot_teamplay.sp` — following and team coordination
- `addons/sourcemod/scripting/bot overhaul/tf_bot_voice.sp` and `tf2botchatter.sp` — bot voice/chatter behavior
- MvM, class-restriction, loadout, naming, truce, setup-time, and gamemode support plugins

## Initial polish patch

The initial import includes a conservative polish pass to `bot_ai.sp`:

- fixed enhanced-AI activation being overwritten while scanning humans
- stopped scanning after finding a qualifying player
- cached the bot position used by the activation scan
- enabled the intended RED MvM activation path
- fixed an invalid disguised-Spy condition call
- cached `tf_bot_difficulty`
- clarified the expert spy-check condition grouping

See `POLISH_PATCH_NOTES.txt` and `POLISH_PATCH.diff` for exact details.

## Building

Compile the `.sp` files against the matching SourceMod and extension include set. Precompiled `.smx` plugins and bundled third-party Stripper `.dll` files are intentionally excluded from source control.

## Major Update 1 — Human Foundation

The first major update builds a universal human-like layer underneath the existing class logic: configurable sight and hearing, reaction and thinking delays, last-known-position investigation, per-life personality traits, risk/reward intents, believable emergent mistakes, and an optional Unfair baseline. See [`docs/HUMAN_FOUNDATION.md`](docs/HUMAN_FOUNDATION.md).
