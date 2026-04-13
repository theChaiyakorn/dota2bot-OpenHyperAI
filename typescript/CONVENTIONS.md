# TypeScript to Lua Conventions

## Array Indexing (0 vs 1)

TypeScript arrays are 0-indexed. Lua tables are 1-indexed. TSTL converts automatically:

-   TS `arr[0]` compiles to Lua `arr[1]` — correct
-   TS `arr.length` compiles to Lua `#arr` — correct
-   TS `for...of` loops compile correctly

**However, bugs happen at the boundary between TS code and Valve's Lua API.**

### Rules

**1. Use `for...of` for array iteration, not manual indexing:**

```typescript
// GOOD — TSTL handles indexing:
for (const enemy of enemies) { ... }

// RISKY — works but confusing to read:
const first = enemies[0]; // TSTL converts to [1], correct but looks wrong
```

**2. Use `$range(1, n)` when iterating with Valve's 1-based APIs:**

```typescript
// GOOD — matches Valve's GetTeamMember(1..5):
for (const i of $range(1, 5)) {
    const member = GetTeamMember(i);
}

// BAD — off by one:
for (let i = 0; i < 5; i++) {
    const member = GetTeamMember(i); // GetTeamMember(0) is invalid!
}
```

**3. Name constants for ability indices instead of using raw numbers:**

```typescript
// GOOD:
const abilityQ = bot.GetAbilityByName("hero_ability_name");

// RISKY:
const abilityQ = bot.GetAbilityByName(abilities[0]); // works but confusing
```

**4. Valve API slot numbers are 1-based — don't subtract 1:**

```typescript
// Valve's FindItemSlot returns a Lua 1-based index (0-5 for main, 6-8 backpack, etc.)
// TSTL does NOT adjust this — it's a number, not an array index
const slot = bot.FindItemSlot("item_blink"); // Returns raw Lua number
const item = bot.GetItemInSlot(slot); // Pass directly, don't adjust
```

**5. `GetQueuedActionType(index)` is 1-based:**

```typescript
// GOOD:
for (const index of $range(1, bot.NumQueuedActions())) {
    const actionType = bot.GetQueuedActionType(index);
}
```

**6. CRITICAL: `any`-typed variables bypass TSTL index conversion:**

TSTL only converts `arr[0]` → `arr[1]` when it **knows** the type is an array. If the type is `any`, TSTL emits `[0]` directly into Lua — which is **nil** in Lua.

```typescript
// BUG: entry is 'any', so entry[0] compiles to Lua entry[0] (nil!)
const entry = someAnyTypedTable[key];
const time = entry[0]; // nil in Lua!

// FIX: use named properties instead of array indices
const entry = someAnyTypedTable[key];
const time = entry.t; // works correctly
```

This bug caused all bots to have 0 desire (crashed `IsBotThinkingMeaningfulAction` every frame).

### How to verify

Run the index safety checker after building:

```
node typescript/post-process/check-lua-index.js
```

This scans compiled Lua for patterns that suggest incorrect 0-based access to Valve APIs.

## File Structure

See `hero_wisp.ts` as the reference template for new hero files:

1. File-level JSDoc (hero name, description, ability priority)
2. Imports
3. Constants (`UPPER_SNAKE_CASE`)
4. Bot initialization
5. Builds (`buildHeroConfig()` call)
6. Ability handles
7. Per-tick state
8. Helper functions (prefixed with `_`)
9. Consider functions (one per ability, JSDoc)
10. Main entry points (`SkillsComplement`, `MinionThink`)
11. Export (`buildHeroExport()`)

## TSTL Self/Colon Pitfalls

TSTL compiles `obj.method(arg)` to Lua `obj:method(arg)` (colon = passes `obj` as implicit `self`). This breaks when calling Lua module functions that don't expect `self`.

**Problem:** `Fu.Item.GetRoleItemsBuyList(bot)` compiles to `Fu.Item:GetRoleItemsBuyList(bot)` — passes `Fu.Item` as `self`, `bot` becomes second arg. Result: role is nil, item/skill builds empty.

**Fix options:**

1. Use `require()` directly: `const Item = require(...); Item.GetRoleItemsBuyList(bot);`
2. Use standalone exported functions instead of static class methods
3. Never use classes for utilities that bridge TS↔Lua

**Rule: Avoid `static` class methods** — TSTL compiles them with a `self` parameter even though they shouldn't have one. Use standalone exported functions instead. (`@noSelf` annotation on inline interface properties does NOT reliably prevent this.)

**Rule: When calling Fu sub-modules** (Fu.Item, Fu.Skill, etc.), verify the compiled Lua uses dot (.) not colon (:). If it uses colon, switch to `require()` directly.

## Caching

### Safe to cache (bounded key space)

These functions have a fixed, small number of possible keys. Cache on the bot handle with appropriate TTL:

| Function                      | Max keys | TTL  | Why safe                |
| ----------------------------- | -------- | ---- | ----------------------- |
| `GetNumOfAliveHeroes(bEnemy)` | 2        | 1.0s | Only true/false param   |
| `GetAliveCoreCount(bEnemy)`   | 2        | 1.0s | Only true/false param   |
| `GetAverageLevel(bEnemy)`     | 2        | 2.0s | Only true/false param   |
| `IsInTeamFight(bot, radius)`  | 1        | 0.2s | Always called with 1200 |
| `GetCoresAverageNetworth()`   | 1        | 2.0s | No params               |
| `DoesTeamHaveAegis()`         | 1        | 2.0s | No params               |
| `WeAreStronger(bot, radius)`  | ~3       | 0.5s | Few distinct radii      |

### NEVER cache (unbounded key space)

These functions take **location parameters** that change every tick as units move, creating infinite unique keys. Caching these caused game crashes from unbounded table growth:

| Function                                    | Why NOT safe                              |
| ------------------------------------------- | ----------------------------------------- |
| `GetNearbyHeroes(bot, radius, enemy, mode)` | Called from different locations each tick |
| `GetAlliesNearLoc(vLoc, radius)`            | Location changes continuously             |
| `GetEnemiesNearLoc(vLoc, radius)`           | Location changes continuously             |
| `GetLastSeenEnemiesNearLoc(vLoc, radius)`   | Location changes continuously             |
| `GetHeroesNearLocation(enemy, loc, dist)`   | Location changes continuously             |

Even with grid-snapped keys (floor(x/500)), bots moving across grid boundaries create new entries every few seconds, and old entries are never cleaned up.

### Cache storage pattern

For Lua-side caching, store directly on the bot handle:

```lua
-- GOOD: bounded key, stored on bot handle
if bot._tfCache and DotaTime() - bot._tfCache[1] <= 0.2 then
    return bot._tfCache[2]
end
-- ... compute ...
bot._tfCache = { DotaTime(), result }
```

For TS-side caching, use `{t, v}` named properties (NOT array indices):

```typescript
// GOOD: named properties compile correctly regardless of type
GameStates.cachedVars[key] = { t: DotaTime(), v: value };
// read:
if (DotaTime() - entry.t <= withinTime) return entry.v;

// BAD: array indices on 'any' type — entry[0] is nil in Lua!
GameStates.cachedVars[key] = [DotaTime(), value];
if (DotaTime() - entry[0] <= withinTime) return entry[1]; // CRASH
```

Use numeric keys instead of string concatenation:

```typescript
// GOOD: numeric key, zero string allocation
const cacheKey = 50000 + bot.GetPlayerID() * 10 + typeHash;

// BAD: string concat on every call
const cacheKey = "IsBotThinking" + bot.GetPlayerID() + "_" + type;
```

## dofile vs require

-   Use `require()` for shared libraries, data tables, utilities (cached by Lua)
-   Use `dofile()` for per-bot modules that call `GetBot()` at module level (minion.lua, override modes, hero builds loaded by bot_generic.lua)
-   `require()` caching is per-VM. If bots share a VM, the cached module has the first bot's `GetBot()` — wrong for subsequent bots.

## Known Bugs & Lessons Learned

### 1. `entry[0]` on `any`-typed variable (CRITICAL)

**Symptom:** All bots stuck at 0 desire, all modes broken.
**Cause:** TS cache stored `[DotaTime(), value]` (array), read `entry[0]`. TSTL did not convert `[0]→[1]` because type was `any`. Lua `entry[0]` is nil → `DotaTime() - nil` → crash every frame in `IsBotThinkingMeaningfulAction`.
**Fix:** Use `{t, v}` named properties instead of array indices.

### 2. Static class methods compiled with `self` (CRITICAL)

**Symptom:** Wisp didn't buy items or learn skills.
**Cause:** `HeroBuilder.export()` static method compiled to `HeroBuilder.export(self, ...)`. Call `HeroBuilder:export(hero, ...)` passed HeroBuilder as self, shifting all args.
**Fix:** Use standalone exported functions, not static class methods.

### 3. `Fu.Item:GetRoleItemsBuyList` colon call (CRITICAL)

**Symptom:** Hero role always nil, builds empty.
**Cause:** TSTL compiled `Fu.Item.GetRoleItemsBuyList(bot)` as `Fu.Item:GetRoleItemsBuyList(bot)` despite `@noSelf`. Passed `Fu.Item` as self.
**Fix:** Use `require()` directly for the Item module.

### 4. Location-based cache keys cause game crash

**Symptom:** Dota freezes/crashes when bots start laning.
**Cause:** `GetAlliesNearLoc`/`GetEnemiesNearLoc` cached with `math.floor(vLoc.x/500)` keys. As bots move, new keys created every tick, `bot._fc` table grows unbounded.
**Fix:** Only cache functions with bounded key space (see table above).

### 5. Cache key collision between BOT_MODE_NONE and BOT_MODE_ATTACK

**Symptom:** Bots stuck in attack mode or wrong desire values.
**Cause:** `GetNearbyHeroes` cache key didn't include `bBotMode` parameter. `BOT_MODE_NONE` and `BOT_MODE_ATTACK` shared the same key, returning wrong filtered results.
**Fix:** Include all parameters in cache key (removed location-based caching entirely).

### 6. `GetNearbyHeroes` returns nil (global_overrides)

**Symptom:** `#enemies` crashes with nil error, modes return 0 desire.
**Cause:** `global_overrides.lua` overrides `GetNearbyHeroes` to return nil when `bot:CanBeSeen()` is false. At game start, bots in fountain may not be "seen".
**Fix:** Always use `or {}` when storing the result: `local enemies = bot:GetNearbyHeroes(...) or {}`

### 7. Missing Consider() assignments in SkillsComplement (22 heroes)

**Symptom:** Heroes never cast abilities.
**Cause:** PR-140 refactor from `J.` to `Fu.` accidentally removed `castQDesire = X.ConsiderQ()` assignment lines. The `if castQDesire > 0` checks remained but desire was always nil.
**Fix:** Added assignments back for all 22 affected heroes.
