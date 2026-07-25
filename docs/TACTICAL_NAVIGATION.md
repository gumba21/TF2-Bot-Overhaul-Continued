# Major Update 1.2 — Tactical Navigation and Route Intelligence

Tactical Navigation is the shared movement-intelligence layer built above TF2's existing `.nav` mesh and the Battlefield Knowledge System.

It answers three related questions:

1. Where can the bot move?
2. What is happening along each possible route?
3. Which route profile fits the current bot and purpose?

It does **not** replace Valve's low-level locomotion. The system chooses tactical nav-area routes and intermediate traversal points; existing bot command movement remains responsible for ground movement, basic obstacle interaction, ordinary jumping, doors, and existing class behavior.

## Nav access decision

Major Update 1.2 does not use a platform-specific C++ extension or fragile engine detours.

The repository vendors the GPL-3.0 SourcePawn Navigation Mesh Parser from `KitRifty/sourcepawn-navmesh`, pinned to commit:

```text
2179f82ea57410a8840cef6f85b1f66e78f54657
```

Vendored files:

```text
tf/addons/sourcemod/scripting/bot overhaul/third_party/sourcepawn-navmesh/navmesh.sp
tf/addons/sourcemod/scripting/bot overhaul/third_party/sourcepawn-navmesh/LICENSE
tf/addons/sourcemod/scripting/bot overhaul/third_party/sourcepawn-navmesh/README.md
tf/addons/sourcemod/scripting/include/navmesh.inc
```

The parser reads Valve `.nav` files and exposes nav areas, IDs, bounds, adjacency, portals, grid lookup, blocked state, and related primitives through SourcePawn natives. A small documented compatibility patch updates native callback typing for SourcePawn 1.12 without changing the nav-file parser's behavior.

This design is platform-neutral at the SourceMod layer. The same SourcePawn plugins are deployed on supported SourceMod platforms.

If the parser is unavailable, a map has no `.nav` file, or parsing fails:

- Tactical Navigation marks itself unavailable.
- Existing overhaul behavior continues running.
- Active tactical routes are cancelled safely.
- A clear server log explains why observation and pilots are disabled.
- No extension or gamedata crash path exists.

`tf_bot_navigation_extension_required` is retained as a compatibility/configuration signal, but no native extension is required by the current implementation.

## Source organization

```text
tf/addons/sourcemod/scripting/bot overhaul/
├── bot_navigation.sp
├── navigation/
│   ├── navigation_core.inc
│   ├── navigation_graph.inc
│   ├── navigation_dynamic.inc
│   ├── navigation_math.inc
│   ├── navigation_routes.inc
│   ├── navigation_route_api.inc
│   ├── navigation_route_cost.inc
│   ├── navigation_pilots.inc
│   └── navigation_debug.inc
└── third_party/sourcepawn-navmesh/
```

Public API:

```text
tf/addons/sourcemod/scripting/include/bot_navigation.inc
```

Deployment binaries:

```text
tf/addons/sourcemod/plugins/bot overhaul/00_navmesh.smx
tf/addons/sourcemod/plugins/bot overhaul/bot_navigation.smx
```

The parser is named `00_navmesh.smx` so it loads before `bot_navigation.smx` in ordinary alphabetical plugin loading.

## Cached navigation graph

At map start, the system enumerates the parsed nav mesh and copies stable data into reusable fixed-size caches.

Each cached area includes:

- parser index and Valve area ID
- center and bounds
- width, length, and surface height
- outgoing directed edges
- edge distance and traversal direction
- static labels and scores
- per-team traffic, presence, damage heat, death heat, combat heat, and friendly control
- last dynamic update time

Each cached edge includes:

- source area through its edge range
- target area
- base distance
- traversal direction

The initial implementation stores up to:

```text
8192 nav areas
49152 directed connections
96 areas per client route
```

If a map exceeds a limit, the graph remains bounded rather than allocating without control. Debug logs report the cached area and edge counts.

## Static area analysis

Cheap geometry analysis runs immediately after graph construction. Trace-based analysis is staggered across later navigation ticks so map start does not perform every expensive sample at once.

Current scores:

- openness
- cover
- choke likelihood
- relative high-ground value

Current labels:

- open or enclosed
- narrow or wide
- corridor
- choke
- intersection
- dead end
- high ground or low ground
- cover and peek area
- exposed crossing
- long sightline
- defensive position
- ambush position
- main route
- flank connection
- objective approach
- spawn approach

These classifications are intentionally conservative heuristics. They provide reusable route weights without claiming perfect automatic semantic map understanding.

## Optional map metadata

Unknown maps work without custom metadata. Authors may add optional corrections or tactical labels under:

```text
tf/addons/sourcemod/data/bot_overhaul/navigation/<map>.cfg
```

Example:

```text
"NavigationMetadata"
{
    "badlands_second_choke"
    {
        "area_id"  "312"
        "labels"   "main objective cover"
    }

    "badlands_valley_flank"
    {
        "area_id"  "418"
        "labels"   "flank"
    }
}
```

Recognized metadata words:

```text
main
flank
objective
spawn
cover
avoid
```

`avoid` currently applies the dead-end/high-penalty behavior and should be reserved for areas that should not be chosen as ordinary idle or retreat destinations.

## Dynamic tactical overlay

Dynamic values update and decay instead of being permanently written into `.nav` files.

### Player-to-area tracking

Living players cache their current nav area. Area lookup runs when:

- the player moved far enough
- the cached area is missing
- the periodic fallback expires
- lifecycle events reset the client

Per-area occupant presence and team traffic are rebuilt or smoothed from these cached assignments.

### Damage and death heat

`player_hurt` and `player_death` add danger to the affected team's current area.

Heat propagation:

- event area: full contribution
- directly connected areas: reduced contribution

Damage and death use separate configurable half-lives. A route therefore becomes usable again after old combat evidence decays.

### Friendly control

Fair route control is calculated from:

- friendly local presence
- friendly presence in adjacent areas
- friendly traffic
- the team's recent damage and death outcomes

It intentionally does not subtract exact hidden enemy presence. Enemy danger enters a fair bot's route through observer-scoped Battlefield Knowledge and legitimate team evidence.

Control values are not forced to sum to `1.0`; RED and BLU may both have weak control, strong contest pressure, or incomplete information.

### Known Sentries and other threats

The route planner samples `BK_GetThreatAtPosition(observer, areaCenter)`. That Knowledge query includes only threats the observer is allowed to know, including known enemy buildings.

Tactical Navigation does not scan hidden Sentry world truth for fair route requests.

### Known Sniper exposure

For each route calculation, known or remembered enemy Snipers are obtained through:

```sourcepawn
BK_GetKnownEnemies(...)
BK_GetLastKnownPosition(...)
```

Open areas, long sightlines, and exposed crossings near those remembered positions receive a temporary directional penalty scaled by confidence and positional uncertainty.

## Route planner

Routes are calculated with a budgeted A* search over the cached directed graph.

A route request contains:

- bot
- world-space goal and resolved goal area
- route profile
- tactical purpose
- priority
- minimum ownership duration
- expiration time
- interruptibility

A route result contains:

- status
- nav-area sequence
- next traversal point
- base distance
- average known danger
- tactical cost
- confidence
- creation time
- failure or recalculation reason

Search behavior:

- queued route requests
- configurable requests processed per navigation tick
- configurable maximum expanded nodes
- reusable search arrays and binary heap
- route reuse for unchanged recent requests
- nearest reachable fallback when the exact goal is not reached but a useful connected area is found
- graceful failure to existing movement when no route is available

## Route profiles

### Fastest

Strongly values distance. It still applies smaller danger penalties and rejects impossible edges.

### Safest

Strongly penalizes known danger, exposed crossings, recent deaths, and weak control. Rewards cover and friendly control.

### Retreat

Uses the strongest danger avoidance and friendly-control rewards. Strongly rejects dead ends and prefers cover.

### Flank

Penalizes friendly traffic, chokes, and known danger. Rewards side-route metadata, low congestion, and covered approaches.

### Push

Accepts more danger, rewards supported/direct objective approaches, and can follow friendly traffic rather than avoiding it.

### Support

Favors cover, friendly control, and routes that remain near teammates. Medics also receive extra exposed-crossing penalties.

### Defensive

Rewards cover, defensive/high-ground labels, objective approaches, and stable controlled territory.

### Stealth

Penalizes main routes, traffic, known danger, and exposed crossings while rewarding cover and side connections.

Class behavior may select or modify a general profile without implementing another pathfinder.

## Traversal points and existing locomotion

A tactical route is an area sequence, but movement targets are not always area centers.

For each transition, the plugin asks the parser for the nearest point in the shared area portal. It then applies a small deterministic lateral offset by client index and clamps the result back onto the destination nav area.

This reduces multiple bots stacking on one coordinate while keeping traversal targets walkable.

Pilot movement uses the next tactical traversal point through `OnPlayerRunCmd`. It does not replace:

- Valve's nav mesh
- existing class logic
- ordinary ground locomotion
- doors
- ladders
- obstacle avoidance
- existing unstuck behavior
- rocket-jump or sticky-jump navigation

A stalled pilot route is queued for recalculation after a minimum no-progress period.

## Central movement ownership

`BN_RequestRoute` resolves competing requests through:

- priority
- minimum ownership duration
- interruptibility
- route age and expiration

A lower-priority flank or support request cannot replace an active emergency retreat. Consumers do not directly own the A* state or movement buffers.

## Public API

Important natives include:

```sourcepawn
BN_IsAvailable()
BN_GetAreaFromPosition(...)
BN_GetCurrentAreaForClient(...)
BN_GetAreaCenter(...)
BN_GetAreaBounds(...)
BN_GetAreaLabels(...)
BN_GetAreaDanger(...)
BN_GetAreaControl(...)
BN_GetAreaTraffic(...)

BN_RequestRoute(...)
BN_CancelRoute(...)
BN_GetRouteStatus(...)
BN_GetNextTraversalPoint(...)
BN_GetRouteMetrics(...)

BN_GetSafestNearbyArea(...)
BN_GetRetreatDestination(...)
BN_GetBestFlankApproach(...)
```

Example future behavior:

```sourcepawn
#include <bot_navigation>

void ProtectObjective(int bot, const float objective[3])
{
    if (!BN_IsAvailable())
    {
        return; // Preserve the behavior's existing movement fallback.
    }

    BN_RequestRoute(
        bot,
        objective,
        BNProfile_Safest,
        BNPurpose_Protect,
        60,
        0.75,
        7.0,
        true
    );
}
```

The behavior requests an outcome and profile. It does not enumerate nav areas or implement A*.

## Battlefield Knowledge integration

The dependency direction is intentionally controlled:

1. Battlefield Knowledge publishes observer-scoped players, memories, groups, front lines, and positional threat.
2. Tactical Navigation interprets those facts against the map graph.
3. Navigation publishes route status, safety, area data, and traversal results through `bot_navigation.inc`.

The first implementation does not copy every changing route score back into Knowledge, avoiding a circular update loop. Future consumers may treat the Navigation API's stable outputs as derived route facts.

Examples:

- Sentry avoidance uses observer-scoped positional threat.
- Sniper exposure uses known or remembered Snipers.
- Scout flank goals use known enemy clusters.
- Medic safety uses the known friendly front line and nearby teammates.
- Retreat destinations reward friendly control and avoid known danger.

## Pilot behaviors

Every visible pilot is disabled by default.

### Generic emergency retreat

When enabled, a participating bot with critical health or high known local threat requests a high-priority Retreat route toward friendly control and cover.

### Medic safety routing

When enabled, Medic bots may request Support or Retreat routes when:

- injured
- in high known danger
- separated far from nearby teammates
- exposed near the front line

The pilot does not make Medics permanently passive. It only creates a route request when safety pressure crosses the pilot thresholds.

### Scout flank routing

When enabled, Scout bots consider a Flank route when:

- their current friendly route is congested
- Battlefield Knowledge has a useful known enemy cluster
- local threat is not already too high
- a lower-traffic side approach can be found

Scouts do not flank constantly. The request is abandoned or replaced when survival pressure becomes more important.

## Configuration

Core defaults:

```text
tf_bot_navigation_enabled 1
tf_bot_navigation_debug 0
tf_bot_navigation_extension_required 0
tf_bot_navigation_update_rate 0.10
tf_bot_navigation_area_update_rate 0.20
tf_bot_navigation_control_update_rate 0.50
tf_bot_navigation_route_budget 2
tf_bot_navigation_max_nodes 1400
tf_bot_navigation_route_cache_time 2.0
tf_bot_navigation_damage_half_life 7.0
tf_bot_navigation_death_half_life 14.0
tf_bot_navigation_sentry_danger 3.0
tf_bot_navigation_sniper_danger 2.2
```

Pilot/debug defaults:

```text
tf_bot_navigation_medic_pilot 0
tf_bot_navigation_scout_pilot 0
tf_bot_navigation_retreat_pilot 0
tf_bot_navigation_draw_routes 0
tf_bot_navigation_log_routes 0
```

Core graph and overlay observation are enabled. Movement changes require an explicit pilot convar.

## Debugging

Commands:

```text
sm_bn_inspect [target]
sm_bn_area [target]
sm_bn_route [target]
sm_bn_danger [target]
sm_bn_control [target]
sm_bn_groups
sm_bn_rebuild
```

They expose:

- graph availability
- current area ID and cached slot
- area bounds, labels, geometry scores, traffic, danger, and control
- request owner fields: status, profile, purpose, priority
- route sequence, cursor, goal, and next traversal point
- route distance, danger, cost, confidence, age, and failure/recalculation reason
- Battlefield Knowledge team states and front-line estimates

`tf_bot_navigation_draw_routes 1` draws short-lived route beams. Debug rendering and logging are disabled by default.

Profiling state tracks:

- total route calculations
- total and maximum route calculation time
- nodes expanded for the current search
- route-cache hits

The values are retained in plugin state for inspection and future expanded profiler output.

## Observation mode

With all pilot convars set to `0`, Tactical Navigation:

- parses the map nav mesh
- builds and analyzes the graph
- tracks player areas and traffic
- accumulates and decays danger
- estimates friendly control
- accepts explicit debug/API route requests
- exposes inspectors
- does not alter bot movement

This is the default until live matches validate the data.

## Build and deployment

The deployment manifest compiles:

```text
third_party/sourcepawn-navmesh/navmesh.sp -> 00_navmesh.smx
bot_navigation.sp                         -> bot_navigation.smx
```

Both binaries are committed under the drop-in `tf/` hierarchy. Compilation uses the repository's SourceMod 1.12 build scripts and permanent GitHub Actions verification.

## Known limitations

- Static geometry labels are heuristic, not semantic map understanding.
- The first graph does not model custom rocket-jump or sticky-jump edges.
- Ladders remain under existing Valve locomotion rather than custom tactical traversal.
- Sentry danger is consumed through the current generalized Knowledge threat query rather than a dedicated building-coverage polygon API.
- Sniper exposure is an area/sightline heuristic rather than exact aim-ray prediction.
- Pilot steering can still conflict with unusual legacy movement plugins and requires live testing.
- Full-server CPU cost has not yet been measured in a real TF2 server.
- Map-specific metadata is optional and no full metadata library ships with the initial implementation.

## Validation status

Structurally verified:

- pinned nav parser source and license are tracked
- safe missing-nav fallback exists
- graph, edges, static analysis, dynamic heat/control, route API, profiles, movement requests, pilots, and inspectors compile under SourceMod 1.12
- all existing deployment plugins remain in the complete build manifest
- behavior pilots are disabled by default
- the drop-in `tf/` layout is preserved

Still requires actual TF2 testing:

- map-load parser behavior across common TF2 nav versions
- graph counts and connectivity on real maps
- shortest-versus-safest route differences
- dynamic heat decay
- observer fairness around hidden Sentries and Snipers
- Medic safety behavior
- Scout flank usefulness
- emergency retreat behavior
- stuck recovery and locomotion interaction
- round/map lifecycle cleanup
- full-server timing and memory cost

Compilation and CI are not treated as gameplay validation.
