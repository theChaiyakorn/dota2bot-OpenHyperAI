# Hybrid ML experiment — Sniper Assassinate (proof of concept)

A first step toward "real AI": keep the hand-written rules as a **safety scaffold**, and
let a small **learned model** make one judgment call. Here that call is *"is now a good
moment to fire Sniper's ultimate, and on this target?"*

Nothing here calls out to a GPU or an external server (Valve's bot sandbox forbids that).
The model is trained **offline** and exported as a plain Lua table that runs inside the game.

## What was built

| Piece | File | Role |
|---|---|---|
| In-game NN forward pass | `bots/FunLib/ml/nn.lua` | Pure-Lua MLP (relu + sigmoid). No deps. |
| Sniper ult policy | `bots/FunLib/ml/sniper_assassinate_policy.lua` | Builds the feature vector, returns a desire in `[0,1]`. Falls back to rules if no weights. |
| Trained weights | `bots/FunLib/ml/sniper_assassinate_weights.lua` | **Auto-generated.** Do not edit. |
| Offline trainer + exporter | `ml/train_sniper_assassinate.py` | numpy-only MLP, exports Lua, self-tests parity. |
| Injection point | `bots/BotLib/hero_sniper.lua` → `X.GateUltDesire` | Rules pick the target + pass hard gates; the model gates *whether to fire now*. |

## Division of labour (why it's safe)

- **Rules keep:** `IsFullyCastable`, valid target, cast range, target **selection**.
  The model can never make the bot do something illegal or cast on nothing.
- **Model decides:** the desire scalar. Above `threshold` → fire (and the value competes
  in `SkillsComplement` priority); below → hold and save the ult.
- **Fallback:** if `sniper_assassinate_weights.lua` is missing, `GetUltDesire` returns `nil`
  and `GateUltDesire` returns the original `BOT_ACTION_DESIRE_HIGH`. Bot is never worse off.

## Feature vector (order is contractual)

Defined identically in the Python trainer and `policy.lua : BuildFeatures`:

```
1 targetHP   2 myMana   3 myHP   4 distNorm   5 enemiesNear
6 alliesNear 7 willKill 8 targetChanneling 9 targetRetreating 10 timeNorm
```

## Reproduce

```bash
python3 ml/train_sniper_assassinate.py     # trains, exports Lua, prints parity check
```

Verify the in-game Lua matches the trainer (needs a standalone `lua`):

```bash
cd bots && lua /tmp/test_nn.lua            # see ml/README "parity test" snippet
```

Last run: `max |numpy - lua_replica| = 2.2e-16` (bit-exact), and the policy already
out-judges the binary rule, e.g. it **holds** the ult in *"low-HP target but I'm dying with
3 enemies around"* (desire 0.05) where the original rule would have wasted it.

## Real outcome data (implemented)

The sandbox can't write files, but `print()` is captured by Dota's `console.log` when the
client runs with `-condebug`. That is the data path:

```
in-game print()  ->  console.log  ->  parse_console_log.py  ->  data/*.jsonl  ->  trainer
```

| Piece | File | Role |
|---|---|---|
| In-game logger | `bots/FunLib/ml/datalog.lua` | Emits `OHA_ML\|…\|DECIDE` on every ult fire and `…\|OUTCOME` ~6s later (target died? self died? target HP at end?). |
| Hook | `hero_sniper.lua` (`SkillsComplement` calls `DataLog.Tick()`, `GateUltDesire` calls `RecordUltFire`) | Logs only actual casts. No-op unless enabled. |
| Parser | `ml/parse_console_log.py` | Joins DECIDE+OUTCOME by id, turns outcome into a reward + `[0,1]` label, writes `ml/data/sniper_assassinate.jsonl`. |
| Format sample | `ml/data/sniper_assassinate.sample.jsonl` | 4 real rows produced by running `datalog.lua` — shows the schema. |

**Collect a dataset:**

1. Launch Dota with `-condebug`.
2. Enable logging: set the global `OHA_ML_LOG = true` before bots load, or edit
   `DataLog.ENABLED = true` in `datalog.lua`. (Off by default so normal play stays quiet.)
3. Play / simulate many games with Sniper, then:
   ```bash
   python3 ml/parse_console_log.py "<dota>/game/dota/console.log"
   python3 ml/train_sniper_assassinate.py     # auto-detects the .jsonl, retrains, re-exports
   ```
   No Lua edits needed — the new weights file is picked up in-game on next load.

**Reward shaping** (in `parse_console_log.py : reward_and_label`): securing a kill `+1`,
finishing an escaper `+0.4`, fast execute `+0.3`; dying without the kill `−1`, target walks
away near-full `−0.6`. Tune to taste.

> ⚠️ **Volume matters.** The 4-row sample overfits badly (it starts firing on full-HP
> targets). Need on the order of hundreds–thousands of labelled casts before the learned
> policy beats the synthetic one. Until then the shipped weights stay synthetic.

## Second experiment — shared laning policy (ALL heroes): last-hit + deny + HP-trade

Same recipe, laning-CS domain, injected into `mode_laning_generic.lua`. The three heads are
**hero-agnostic** — features use ratios (`attackDamage/creepHP`, `myRange − enemyRange`, HP
fractions, counts), so **one shared model per decision serves every hero** and pools training
data across all of them. No per-hero weights.

| Piece | File |
|---|---|
| Three shared heads (step-up last-hit, deny, HP-trade) | `bots/FunLib/ml/laning_ml_policy.lua` |
| Weights | `laning_lasthit_weights.lua`, `laning_deny_weights.lua`, `laning_trade_weights.lua` |
| Trainer (all heads) | `ml/train_laning_ml.py` |
| Injection | `mode_laning_generic.lua` → `Think()` (gated by `MLLaning.IsHeroEnabled(botName)`) |
| Outcome logging | `datalog.lua : RecordCS` (CS tally up, minus HP lost) and `RecordTrade` (net enemy-vs-self HP over 2.5 s) |

**Enabling per hero:** `laning_ml_policy.lua` has `ENABLED_HEROES = { ['*'] = true }` (all heroes).
To curate, replace with a set like `{ ['npc_dota_hero_pangolier'] = true, ['npc_dota_hero_riki'] = true }`.
A hero not enabled keeps the original laning code paths byte-for-byte. *(Note: enabling a hero
routes its laning through OHA's custom `Think()` — the guaranteed-last-hit + lane-front logic —
instead of Valve's default. The ML only gates the step-up CS / deny / trade judgement on top.)*

**HP-trade head:** decides *"is harassing the enemy hero worth the HP right now?"*. The rule picks
a valid enemy already in attack reach (`GetBestHarassTarget`, no chasing); the model weighs
range advantage (out-ranging ≈ free trade), whether the enemy is distracted last-hitting, creep
aggro, gank risk and own HP. Verified judgement: harass when out-ranging a last-hitting enemy
(0.76 → commit) but **hold** when creeps would aggro (0.10), at 25% HP (0.19), or under gank
threat (0.44). Outcome label = net HP fraction taken off the enemy minus what we lost.

**Safety split unique to last-hitting:** *guaranteed* last-hits (the rule's `WillKillTarget`
with current damage) are **never** gated — the model only judges the **risky step-up** CS
(`moveToCreep`, where you walk into harass) and **denies**. So the bot can never lose a free
last hit to the model; ML only decides "is this contested CS worth the risk right now".

Example learned judgement (verified in-game Lua): step up for a dying creep on a safe lane
(0.91 → commit), but **hold** the same creep when at 25% HP (0.43 → hold) or skip a deny when
you're at 20% HP under contest. Collect real data exactly as above (the parser writes
`pangolier_lasthit.jsonl` / `pangolier_deny.jsonl`), then `python3 ml/train_pangolier_cs.py`.

## Extending to other heroes / decisions

The `nn.lua` runtime is generic. For a new decision:
1. Copy `sniper_assassinate_policy.lua`, change `BuildFeatures` to the relevant state.
2. Add a trainer that emits a weights table in the same format.
3. Gate one `ConsiderX` in that hero file, keeping the rule's hard gates + `nil` fallback.

Good next candidates (fire often, rules are crude): blink-initiation timing, BKB activation,
teamfight target selection, retreat-vs-commit desire.
