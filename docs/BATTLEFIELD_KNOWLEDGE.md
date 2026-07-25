# Major Update 1.1 — Battlefield Knowledge System

The Battlefield Knowledge System is the shared information layer beneath future class, weapon, personality, communication, team-coordination, and Team Director behavior.

It is implemented as one active SourceMod plugin, `bot_knowledge.smx`, with modular source files under:

```text
tf/addons/sourcemod/scripting/bot overhaul/knowledge/
```

A public include is available at:

```text
tf/addons/sourcemod/scripting/include/bot_knowledge.inc
```

## Fairness boundary

The plugin separates authoritative server truth from information a bot is permitted to use.

Normal bot-facing knowledge is produced by:

- direct field-of-view and line-of-sight confirmation
- weapon and damage sounds
- damage received
- nearby teammate observations
- team reports
- decaying memory
- group and movement inference
- objective events

`tf_bot_knowledge_unfair_access 0` is the default. When it is disabled, exact unseen positions remain private to the World Registry. Lost enemies retain a last-known position whose confidence decays and whose uncertainty radius grows; their live position is not copied into memory.

## Data layers

### World Registry

Tracks authoritative player, building, and objective state. Player indexes are cached by team, class, alive state, burning state, critical-health state, and spatial cell.

### Event Cache

Updates damage, weapon-sound, lifecycle, building, objective, and round facts immediately from Source events. Polling is reserved for state that events do not provide cleanly, including movement, line of sight, groups, and battlefield interpretation.

### Bot Perception and Memory

Each bot has observer-scoped records for known players and buildings. Player records contain:

- source and scope
- last-known position and velocity
- confidence
- uncertainty radius
- first-observed, confirmed, updated, and expiry times
- visible or remembered state
- tactical labels

### Groups

The group analyzer builds connected player groups using distance and recent movement direction. Records publish:

- stable group ID
- team and membership
- centroid and radius
- average velocity
- cohesion
- confidence
- advancing, retreating, flanking, or holding state

Previous membership overlap preserves group IDs across small temporary separations.

### Battlefield analysis

The Director layer currently publishes interpretations rather than commands:

- main RED and BLU groups
- grouped, split, scattered, pushing, holding, or retreating team state
- approximate front-line position and confidence
- isolated, grouped, exposed, high-value, and overextended player labels

## Query API

Consumers include `bot_knowledge.inc` and use observer-scoped natives:

```sourcepawn
BK_GetKnownEnemies(...)
BK_GetBurningTeammates(...)
BK_GetLastKnownPosition(...)
BK_GetLargestEnemyCluster(...)
BK_GetTeamState(...)
BK_GetFrontLine(...)
BK_GetThreatAtPosition(...)
BK_FindBestMadMilkTarget(...)
```

Queries read cached registry and group data. Weapon modules should not maintain duplicate player registries or scan the whole server independently.

## Mad Milk pilot

The first consumer scores three generic opportunities:

- self-extinguish
- extinguish nearby teammates
- hit a known enemy cluster with friendly follow-up potential

The pilot uses only centralized Knowledge queries and scoring. It is disabled by default:

```text
tf_bot_knowledge_mad_milk 0
```

Enable it only after observation-mode data has been checked in live matches.

## Debugging

Administrative commands:

```text
sm_bk_inspect [target]
sm_bk_memory [target]
sm_bk_groups
```

They expose visible and remembered enemies, confidence, uncertainty, source, labels, stable group records, cohesion, team state, and front-line estimates.

Set `tf_bot_knowledge_debug 1` for additional server logging, including Mad Milk utility selections. Debug output is disabled by default.

## Scheduling and performance

The system uses staggered update tiers:

- immediate event updates for lifecycle, damage, sounds, buildings, and objectives
- high-frequency observer perception updates with a configurable per-tick observer budget
- medium-frequency group analysis
- lower-frequency battlefield and Director analysis

Key settings:

```text
tf_bot_knowledge_update_rate 0.10
tf_bot_knowledge_group_update_rate 0.50
tf_bot_knowledge_director_update_rate 0.75
tf_bot_knowledge_spatial_cell_size 768.0
tf_bot_knowledge_max_queries_per_frame 6
```

## Safety and lifecycle

Records are cleared or corrected on:

- disconnect
- spawn and death
- team or class change
- entity destruction and index reuse
- round reset
- map start and map end

The system remains observation-first. Existing class and combat behavior does not consume its results unless a feature explicitly opts in.

## Validation status

The full SourceMod 1.12 deployment manifest compiles successfully and produces 22 active plugins plus 2 disabled optional plugins. The compiled `bot_knowledge.smx` is committed inside the drop-in `tf/` tree.

Live TF2 validation is still required for perception tuning, group stability on real maps, front-line usefulness, runtime cost at full player counts, and the disabled Mad Milk pilot before it should be enabled by default.
