# Plan: Ability Draft Mode Support

**Status:** Not started
**Priority:** Feature request
**Date:** 2026-04-09
**Reference:** https://dota2.fandom.com/wiki/Ability_Draft

## Overview

Add bot support for Ability Draft (AD) mode. In AD, 12 players get random hero bodies, then draft abilities from a shared pool (4 per hero = 48 total). Each player picks 4 non-ultimate + 1 ultimate ability. The hero's base stats, attack type (melee/ranged), and innate ability stay with the body.

The core challenge: all hero-specific logic (`BotsLib/hero_*.lua`) assumes hardcoded abilities. In AD, a Sven body might have Blink Strike, Ball Lightning, Overcharge, and Rearm.

## Key Insight: Rubick System = 80% of the Solution

The Rubick spell-steal system (`FuncLib/hero/rubick.lua`) already solves generic ability usage:
- **`ClassifyAbility(ability)`** (lines 100-124): Takes any ability handle, returns targeting type, team targeting, damage, AOE radius, etc. via `GetBehavior()`, `GetTargetTeam()`, `GetTargetType()`, `GetAOERadius()`, `GetAbilityDamage()`.
- **`SmartCast(ability, props)`** (lines 129-258): Priority-based generic casting -- handles enemy-targeting, ally-targeting, no-target, and ultimate spells.
- **21 hero-specific handler files** in `FuncLib/hero/rubick_hero/`: Per-ability `ConsiderStolenSpell()` logic for ~60+ abilities that need special treatment (Culling Blade kill threshold, Black Hole positioning, etc.).

The plan generalizes this from "1 stolen spell at a time" to "5 drafted spells permanently."

## Feasibility Assessment

| Area | Feasibility | Notes |
|------|------------|-------|
| Draft phase (picking abilities) | **Likely impossible** | No bot API function exists for ability selection. `HERO_PICK_STATE_ABILITY_DRAFT_SELECT` (value 53) exists as a constant but no `SelectAbility()` or `DraftAbility()` call. Bots will get auto-assigned abilities by the engine. |
| Runtime ability detection | **Easy** | `GetAbilityInSlot()` works regardless of mode. Existing `FuncLib/systems/skill.lua` `GetAbilityList()` (lines 82-125) already does dynamic slot scanning. |
| Generic ability usage | **Medium** | Rubick system provides the foundation. Need to wire it up for 5 abilities instead of 1. |
| Item builds | **Easy** | `FuncLib/systems/item_strategy.lua` already has position-based fallback builds keyed by melee/ranged. |
| Skill leveling | **Easy** | ARDM fallback pattern already exists. Combine with `spell_prob_list.lua` weights. |
| Mode detection | **Trivial** | `GetGameMode() == 18` |

## Implementation Steps

### Step 1: Mode Detection

Add to `FuncLib/systems/global_overrides.lua`:
```lua
if GAMEMODE_ABILITY_DRAFT == nil then GAMEMODE_ABILITY_DRAFT = 18 end
```

Add helper to `FuncLib/func_utils.lua` (or a mixin):
```lua
function Fu.IsAbilityDraft()
    return GetGameMode() == GAMEMODE_ABILITY_DRAFT
end
```

The constant already exists in `bots/ts_libs/dota/enums.lua` line 386 but may not be loaded at runtime.

### Step 2: New File -- `bots/FuncLib/systems/ability_draft_usage.lua`

This is the central module (~300-500 lines estimated). It returns a `BotBuild`-compatible table so the existing `ability_item_usage_generic.lua` pipeline works without changes.

**Functions to implement:**

#### `CreateBuild(bot)`
Returns a table matching the `BotBuild` interface that `ability_item_usage_generic.lua` expects:
```lua
{
    SkillsComplement = function() ... end,  -- ability casting logic
    sBuyList = { ... },                      -- item build
    sSellList = { ... },                     -- items to sell
    sSkillList = { ... },                    -- level-up order
    bDeafaultAbility = false,                -- use our logic, not Valve's
    bDeafaultItem = false,                   -- use our logic, not Valve's
}
```

#### `ADSkillsComplement(bot, abilityList)`
Core ability usage function, called every frame when the bot has an active combat mode:

1. Get all drafted abilities via `GetAbilityList()` from `skill.lua`
2. For each ability that is castable (`IsFullyCastable()`):
   a. Check if a Rubick hero handler exists for this ability name in `FuncLib/hero/rubick_hero/`
   b. If yes: use its `ConsiderStolenSpell()` for smart ability-specific logic
   c. If no: use `ClassifyAbility()` + `SmartCast()` from `rubick.lua` for generic casting
3. Priority order: stuns/disables > nukes > buffs/heals > ultimates (conservative)
4. Return the highest-desire ability + target

#### `GenerateSkillBuild(bot, abilityList, talentList)`
Generate level-up order:

1. Look up each ability's weight in `FuncLib/data/spell_prob_list.lua` (flat `ability_name -> weight` map)
2. Sort non-ultimate abilities by weight (highest = primary spell)
3. Build order:
   - Levels 1-5: Max primary spell, alternate with secondary
   - Levels 6, 12, 18: Ultimate (if drafted)
   - Remaining: Third and fourth abilities
   - Levels 10, 15, 20, 25: Talents (default to alternating left/right)
4. Follow the same format as `tAllAbilityBuildList` in hero files

#### `GenerateItemBuild(bot, abilityList, position)`
Generate item build:

1. Base: Use `FuncLib/systems/item_strategy.lua` position-based fallback builds, keyed by:
   - Bot's assigned position (1-5)
   - Melee vs ranged (`bot:GetAttackRange()`)
2. Optional enhancement -- scan abilities for synergy tags:
   - Mana-hungry abilities (short cooldown, high mana cost) -> Arcane Boots, Aether Lens
   - Physical steroids (e.g., God's Strength) -> right-click items
   - Magic nukes -> Kaya, Veil of Discord
   - Mobility spells -> can skip Blink Dagger
3. For v1, just using strategy fallbacks without ability-synergy adjustments is fine

### Step 3: Modify `ability_item_usage_generic.lua`

Around line 12 where `BotBuild` is loaded from `BotsLib/hero_[name].lua`, add an AD branch:

```lua
local isAbilityDraft = Fu.IsAbilityDraft()
if isAbilityDraft then
    local ADUsage = require(GetScriptDirectory()..'/FuncLib/systems/ability_draft_usage')
    BotBuild = ADUsage.CreateBuild(bot)
end
```

Follow the existing ARDM handling pattern (lines 90-144 of that file) as a template.

### Step 4: Modify `item_purchase_generic.lua`

Add AD mode detection to use `item_strategy.lua` fallback builds instead of hero-specific `sRoleItemsBuyList` arrays. The ARDM pattern already present in this file shows how to branch.

### Step 5: Modify `hero_selection.lua`

Add `GAMEMODE_ABILITY_DRAFT` to the `Think()` function's mode dispatch (around line 946). In AD mode, the engine handles hero assignment, so just return early. May need a stub `AbilityDraftThink()` if the engine expects the bot script to acknowledge the draft phase.

### Step 6: Modify `bot_generic.lua`

Add AD mode detection to avoid loading hero-specific minion/illusion logic (e.g., Meepo clones, Lone Druid bear) since the hero body won't necessarily match the abilities.

## Files That Need No Changes (reuse as-is)

- All mode files (`mode_*_generic.lua`) -- behavior modes are hero-independent
- `FuncLib/func_utils.lua` and all mixin modules -- combat, targeting, positioning helpers
- `FuncLib/systems/skill.lua` -- `GetAbilityList()` dynamically scans slots, works in any mode
- `FuncLib/data/spell_prob_list.lua` -- ability weights already exist for every ability
- `FuncLib/data/spell_list.lua` -- ability metadata
- `FuncLib/hero/rubick.lua` -- `ClassifyAbility()` and `SmartCast()` are the core engine
- `FuncLib/hero/rubick_hero/*.lua` (21 files) -- per-ability handlers, directly reusable
- `FuncLib/systems/item_strategy.lua` -- position-based fallback builds

## Risks and Limitations

1. **Draft phase is almost certainly not automatable.** No known API call. Bots will get whatever the engine assigns them. If an undocumented API is found later, the stub can be filled in.

2. **Abilities without Rubick handlers get generic treatment.** `ClassifyAbility` + `SmartCast` provides reasonable but not optimal usage. Complex abilities (Meat Hook aiming, Meepo micro, Invoker combos) will be used poorly. This is acceptable -- even human AD players struggle with unfamiliar abilities.

3. **Combo detection is hard.** A bot with Aftershock + any low-cooldown spell should spam it, but detecting such synergies requires a combo-awareness layer beyond v1 scope.

4. **`GetAbilityList()` slot assumptions.** Verify that in AD mode, abilities land in slots 0-3 (regular) and 5 (ultimate) as expected. If the engine uses different slots, `GetAbilityList()` may need adjustment. Test this empirically.

5. **Talent selection.** In AD, the hero body's talents remain (not drafted). The generic left/right alternation is suboptimal but functional. A future enhancement could score talents against the drafted ability set.

## Testing Plan

1. Start a local AD lobby with bots
2. Verify bots don't crash during draft phase (auto-assignment)
3. Verify `GetAbilityList()` correctly detects drafted abilities at game start
4. Verify bots cast abilities (even if suboptimally)
5. Verify bots buy items and level up skills
6. Play a full game to check for runtime errors

## Estimated Effort

| Component | Lines of Code | Difficulty |
|-----------|--------------|------------|
| `ability_draft_usage.lua` (new) | 300-500 | Medium |
| `ability_item_usage_generic.lua` changes | 15-25 | Low |
| `item_purchase_generic.lua` changes | 10-15 | Low |
| `hero_selection.lua` changes | 5-10 | Low |
| `bot_generic.lua` changes | 5-10 | Low |
| `global_overrides.lua` constant | 1-2 | Trivial |
| Testing & iteration | -- | Medium |

**Total new code: ~350-550 lines, plus ~40-60 lines of modifications to existing files.**

## Dependencies

- Rubick system must be working and stable (`FuncLib/hero/rubick.lua` + `rubick_hero/`)
- `spell_prob_list.lua` must have weights for all draftable abilities
- `item_strategy.lua` fallback builds must cover all 5 positions for both melee and ranged
