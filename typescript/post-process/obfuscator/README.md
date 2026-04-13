# Build & Obfuscation Scripts

Build pipeline for the dota2bot-OpenHyperAI project.

## Prerequisites

```bash
npm install luamin --save-dev --legacy-peer-deps
```

## Directory Structure

| Directory          | Contents                                 | When              |
| ------------------ | ---------------------------------------- | ----------------- |
| `bots/`            | **Active Lua files** that Dota 2 loads   | Always            |
| `bots-raw/`        | Raw source backup (created by obfuscate) | After obfuscation |
| `typescript/bots/` | TypeScript source files                  | Always            |

## Workflows

### Development (normal editing)

```
bots/          = raw Lua source (hand-written + TS-generated)
typescript/    = TypeScript source
```

Edit files in `bots/` and `typescript/bots/` directly. Dota loads `bots/`.

### Build TypeScript

Compiles TypeScript to Lua. Output goes to `bots/`, overwriting the TS-generated Lua files.

```bash
npx tstl -p tsconfig-tstl.json
```

**Note:** Only TS-generated files in `bots/` are overwritten. Hand-written Lua files are untouched.

### Obfuscate (for publishing)

Minifies all Lua files in `bots/` with variable renaming. Creates a raw backup first.

```bash
npx ts-node typescript/post-process/obfuscator/obfuscate.ts
```

**What happens:**

1. Deletes `bots-raw/` if it exists
2. Copies `bots/` to `bots-raw/` (backup of raw source)
3. Obfuscates all `.lua` files in `bots/` **in-place** using luamin
4. Files in `Customize/` are skipped (must remain readable for users)

**After:**

-   `bots/` = obfuscated (Dota loads this, publish this to workshop)
-   `bots-raw/` = raw source backup

**Size reduction:** ~39% (5.9MB to 3.6MB)

### De-obfuscate (restore for development)

Restores `bots/` from the raw backup.

```bash
npx ts-node typescript/post-process/obfuscator/deobfuscate.ts
```

**What happens:**

1. Verifies `bots/` contains obfuscated files (safety check)
2. Deletes obfuscated `bots/`
3. Copies `bots-raw/` to `bots/`

**After:**

-   `bots/` = raw source (editable)
-   `bots-raw/` = still exists as backup

**Safety:** Will refuse to delete `bots/` if it doesn't look obfuscated (prevents accidental deletion of raw source).

### Full Publish Workflow

```bash
# 1. Build TypeScript
npx tstl -p tsconfig-tstl.json

# 2. Obfuscate for publishing
npx ts-node typescript/post-process/obfuscator/obfuscate.ts

# 3. Publish to workshop (bots/ is now obfuscated)
# ... upload via Steam workshop tools ...

# 4. Restore for continued development
npx ts-node typescript/post-process/obfuscator/deobfuscate.ts
```

### Quick Reference

| Command                                                         | Result                                           |
| --------------------------------------------------------------- | ------------------------------------------------ |
| `npx tstl -p tsconfig-tstl.json`                                | Compile TS to Lua in `bots/`                     |
| `npx ts-node typescript/post-process/obfuscator/obfuscate.ts`   | Backup `bots/` to `bots-raw/`, obfuscate `bots/` |
| `npx ts-node typescript/post-process/obfuscator/deobfuscate.ts` | Restore `bots/` from `bots-raw/`                 |

## Obfuscation Details

-   **Engine:** [luamin](https://github.com/mathiasbynens/luamin) (Lua minifier)
-   **What it does:**
    -   Renames all **local** variables (`bot` to `a`, `nTarget` to `b`, etc.)
    -   Removes all comments (single-line `--` and block `--[[ ]]`)
    -   Removes whitespace and empty lines
    -   Collapses to single-line output
-   **What it preserves:**
    -   All **global** names (`GetBot()`, `BOT_MODE_FARM`, `GetTeamMember`, etc.)
    -   String literals (item names, ability names, chat messages)
    -   Function behavior (100% equivalent)
-   **Fallback:** If luamin fails on a file (rare), falls back to comment stripping only
-   **Skipped:** `Customize/` folder (user-configurable files)

## Git Notes

-   `bots-raw/` should be in `.gitignore` (it's a build artifact)
-   `bots/` is committed as raw source
-   Never commit obfuscated `bots/` to git
