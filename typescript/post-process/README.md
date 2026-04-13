# Post-Process Scripts

Build tools and data generators for the bot project.

## Build Pipeline Scripts

These run automatically as part of `npm run build:lua`:

| Script                  | Purpose                                                                                                                                                                                                                                        |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `post-process-lua.js`   | Rewrites `require("bots.X")` paths to `require(GetScriptDirectory().."/X")` in TSTL output. Required because Dota 2 bot scripting uses a non-standard module resolution.                                                                       |
| `check-lua-index.js`    | Scans generated Lua for common TSTL pitfalls: `[0]` access on `any`-typed vars, static methods compiled with `self`, colon/dot call mismatches, `GetNearbyHeroes` nil safety, string concat cache keys. Prints warnings, doesn't modify files. |
| `custom-transformer.js` | TypeScript AST transformer for the TSTL compiler. Handles custom compilation rules.                                                                                                                                                            |
| `update-version.js`     | Stamps the current UTC date into `version.ts`. Run via `npm run update-version` or as part of `npm run release`.                                                                                                                               |

## Data Generators

These fetch external data and generate Lua files used by the bot at runtime.

### `matchups.ts` — Hero Counter Data

```
npm run matchups
```

-   **Source**: Dotabuff (`/heroes/{name}/counters?date=year`)
-   **Method**: Puppeteer (headless Chrome) scrapes the counter table
-   **Output**: `bots/FretBots/matchups_data.lua` — flat table: `hero[counter_hero] = advantage%`
-   **Used by**: `hero_selection.lua` for draft counter-picking
-   **Runtime**: ~20 min (127 heroes, sequential with page loads)

### `neutrals.ts` — Neutral Item Pick Rates (Dotabuff)

```
npm run neutrals
```

-   **Source**: Dotabuff (`/heroes/{name}/items?date=year`)
-   **Method**: Puppeteer scrapes the items table, normalizes per-tier percentages
-   **Output**: `bots/FretBots/neutrals_data.lua` — nested: `hero[type][tier][item] = pick%`
-   **Used by**: `FretBots/NeutralItems.lua` for item assignment preferences
-   **Runtime**: ~20 min (127 heroes)

### `static-neutrals-matchup.ts` — Neutral Item Stats (Stratz API)

```
npm run update-ne
```

-   **Source**: Stratz GraphQL API (`api.stratz.com/graphql`)
-   **Method**: API queries for Divine/Immortal bracket, past week
-   **Output**: `bots/FretBots/static_neutrals_matchup.lua`
-   **Requires**: `STRATZ_API_KEY` env variable (set in `.env` locally or GitHub Actions secret)
-   **Runtime**: ~5 min (API calls with 300ms throttle)

### `names.ts` — Name Mapping Data (NOT a generator)

Shared lookup tables used by the generators above:

-   `hero_name_table` — maps `npc_dota_hero_*` to Dotabuff URL names and display names
-   `neutral_name_table` — maps item internal names to display names, organized by tier
-   `enhancement_name_table` — maps enhancement names with `tier_unique` grouping

**When updating for a new patch**: update `names.ts` first (add/remove heroes and items), then re-run the generators.

## Environment Setup

```bash
# Install dependencies (puppeteer, cheerio, etc.)
npm install

# For Stratz API (static-neutrals-matchup only):
# Option 1: .env file (gitignored)
echo "STRATZ_API_KEY=your_key_here" > .env

# Option 2: export directly
export STRATZ_API_KEY=your_key_here
```

## npm Scripts Reference

| Command                  | What it does                                               |
| ------------------------ | ---------------------------------------------------------- |
| `npm run build:lua`      | TSTL compile → post-process paths → check Lua index safety |
| `npm run matchups`       | Regenerate hero counter data from Dotabuff                 |
| `npm run neutrals`       | Regenerate neutral item pick rates from Dotabuff           |
| `npm run update-ne`      | Regenerate neutral item stats from Stratz API              |
| `npm run update-version` | Stamp current date into version.ts                         |
| `npm run release`        | Update version → full build → prettier                     |
