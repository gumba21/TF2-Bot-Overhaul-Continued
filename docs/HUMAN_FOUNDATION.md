# Major Update 1 — Human Foundation

The Human Foundation is a shared layer underneath the existing class-specific code. It changes what information a bot receives, how quickly it accepts that information, and how it commits to a response. Scout, Medic, Spy, Engineer, and every other class keep their existing specialist logic for now.

## Perception

- Configurable horizontal field of view and line-of-sight checks discover visible enemies.
- Gunfire and fast nearby movement create sound memories even without visual confirmation.
- Sounds produce an investigation position, not a live enemy entity, so bots cannot track through walls.
- Enemies can be discovered, lost, investigated, and rediscovered.
- Human difficulty `4` is the optional **Unfair** baseline. With `tf_bot_human_unfair_omniscience 1`, it may ignore FOV and line of sight.

## Reaction and thinking

- Visual targets require a difficulty- and skill-scaled reaction delay before class logic may attack.
- Major intent changes use a separate thinking delay before they are committed.
- Aim turns are rate-limited, and large stock-AI snap attacks are intercepted.
- Medics and Engineers keep support-fire exemptions so healing, repairing, and building are not interrupted.

## Memory and investigation

- Visual sightings store only the last observed position.
- Gunfire and movement store separate sound positions.
- Personality affects how long memories last and whether the bot pushes toward them or holds the angle.
- Near the remembered location, bots perform a small search sweep rather than staring at one exact point.

## Personality

Each bot receives new traits on spawn:

- confidence
- aggression
- patience
- teamwork
- creativity
- greed
- mechanical skill
- gamesense

Style traits remain varied across all difficulties. Mechanical skill, gamesense, and teamwork trend upward with difficulty; Unfair sets those execution traits to their maximum.

## Emergent mistakes

There is no generic `make mistake` dice roll. Mistakes arise from interacting traits and imperfect information:

- high aggression + confidence + weak gamesense can delay retreat;
- high greed extends commitment to wounded targets;
- low patience shortens memory and causes early abandonment;
- low mechanical skill creates slower turns, larger aim drift, and longer reactions;
- weak teamwork gives less priority to enemies threatening allied clusters;
- high creativity and aggression investigate uncertain positions more strongly, which can become a greedy chase.

## Intent layer

The foundation currently exposes four broad intents:

- `Hold`
- `Engage`
- `Investigate`
- `Retreat`

Risk/reward scoring considers health, enemy class and buffs, nearby allies, target health, and personality. The intent layer modifies the final movement proposal without replacing class logic.

## Difficulty

Set `tf_bot_human_difficulty` to:

| Value | Behavior |
| ---: | --- |
| `-1` | Follow `tf_bot_difficulty` (default). |
| `0` | Strong human limitations. |
| `1` | Slower casual-player foundation. |
| `2` | Competent foundation. |
| `3` | Fast expert foundation. |
| `4` | Unfair baseline with near-perfect execution and optional omniscience. |

Lower levels use the same perception, memory, personality, and intent systems. They are not separate dumb behavior trees.

## ConVars

| ConVar | Default | Purpose |
| --- | ---: | --- |
| `tf_bot_human_awareness` | `1` | Enable the shared foundation. |
| `tf_bot_human_difficulty` | `-1` | Difficulty override; `4` is Unfair. |
| `tf_bot_human_fov` | `155` | Base discovery FOV. |
| `tf_bot_human_hearing` | `1050` | Base sound radius. |
| `tf_bot_human_reaction_min` | `0.12` | Minimum visual reaction delay. |
| `tf_bot_human_reaction_max` | `0.42` | Maximum visual reaction delay. |
| `tf_bot_human_memory_min` | `0.65` | Minimum sight-memory duration. |
| `tf_bot_human_memory_max` | `1.85` | Maximum sight-memory duration. |
| `tf_bot_human_target_lock_min` | `0.80` | Minimum target commitment. |
| `tf_bot_human_target_lock_max` | `2.20` | Maximum target commitment. |
| `tf_bot_human_think_min` | `0.10` | Minimum major-decision delay. |
| `tf_bot_human_think_max` | `0.38` | Maximum major-decision delay. |
| `tf_bot_human_personality_spread` | `0.32` | Per-bot trait variation. |
| `tf_bot_human_unfair_omniscience` | `1` | Permit FOV/LOS bypass on difficulty `4`. |

## Test focus

- bots hearing combat through a corner without tracking the shooter through the wall;
- searching the last known location and eventually giving up;
- cautious and reckless bots visibly disagreeing about retreat;
- wounded-target greed creating believable tunnel vision;
- projectile leading, rocket jumps, Spy logic, healing, and building remaining intact;
- CPU cost with a full server.
