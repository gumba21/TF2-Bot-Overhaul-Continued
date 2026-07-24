# Human Awareness v1

This pass adds a shared perception layer to `bot_ai.sp` so every improved combat bot follows the same basic human limitations before class-specific behavior runs.

## Behavior

- **Reaction delay:** a newly noticed enemy is held as a pending stimulus before class logic may attack it.
- **Damage awareness:** being hurt reveals the attacker's last known position, including attacks from outside the current field of view, but still uses a shortened reaction delay.
- **Target commitment:** bots prefer their current visible threat for a short randomized period rather than switching every command tick.
- **Line-of-sight memory:** after losing sight, bots remember only the enemy's last visible position for a limited duration. The class code no longer receives the live player entity while it is hidden.
- **Humanized turning:** view rotation is rate-limited by bot difficulty, with slower turning while reacting or checking a last-known position.
- **Small aim variance:** combat aim receives subtle, slowly changing error instead of perfectly stable tracking.
- **Snap interception:** large stock-AI aim snaps made while firing are treated as unconfirmed stimuli and receive a reaction delay.
- **Individual variance:** each bot gets a small persistent skill multiplier when its awareness state is reset.

## ConVars

| ConVar | Default | Purpose |
| --- | ---: | --- |
| `tf_bot_human_awareness` | `1` | Enables the awareness layer. |
| `tf_bot_human_reaction_min` | `0.12` | Minimum visual reaction delay. |
| `tf_bot_human_reaction_max` | `0.42` | Maximum visual reaction delay. |
| `tf_bot_human_memory_min` | `0.65` | Minimum last-known-position memory. |
| `tf_bot_human_memory_max` | `1.85` | Maximum last-known-position memory. |
| `tf_bot_human_target_lock_min` | `0.80` | Minimum visible-target commitment. |
| `tf_bot_human_target_lock_max` | `2.20` | Maximum visible-target commitment. |

Difficulty still matters: easier bots react and turn more slowly and forget sooner; expert bots are faster and retain last-known positions longer. Medics and Engineers keep primary fire during reaction windows so healing, repairing, and building are not interrupted.

## Test focus

This is the first general pass, not final class balancing. In-game testing should focus on:

- whether reaction delay is visible without feeling unresponsive;
- whether Soldiers and Demomen retain useful projectile leading;
- whether target commitment causes sensible focus rather than tunnel vision;
- whether memory looks natural around corners without wall tracking;
- whether the angle limiter fights scripted rocket jumps or Spy behavior;
- CPU cost with a full server of improved bots.
