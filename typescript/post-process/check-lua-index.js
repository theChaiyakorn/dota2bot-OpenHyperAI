/**
 * check-lua-index.js
 *
 * Scans compiled Lua files (from TSTL) for patterns that suggest
 * incorrect 0-based indexing, self/colon issues, and other common
 * TSTL pitfalls.
 *
 * Usage: node typescript/post-process/check-lua-index.js
 *
 * This is a warning tool — not all matches are bugs, but each
 * should be reviewed.
 */

const fs = require("fs");
const path = require("path");

const luaRootDirectory = path.join(__dirname, "../../bots");

// Only scan TSTL-generated files (skip hand-written Lua)
const TSTL_GENERATED_DIRS = [
    "FuncLib/systems",
    "FuncLib/data",
    "FuncLib/hero",
    "BotsLib/hero_wisp.lua", // TS-generated hero
    "ts_libs",
    "Customize/general.lua",
];

function isTSTLGenerated(filePath) {
    const rel = path.relative(luaRootDirectory, filePath).replace(/\\/g, "/");
    // Check if file is in a TSTL-generated directory
    for (const dir of TSTL_GENERATED_DIRS) {
        if (rel.startsWith(dir) || rel === dir) return true;
    }
    // Also check for TSTL header comment
    try {
        const head = fs.readFileSync(filePath, "utf8").substring(0, 200);
        if (head.includes("Generated with") && head.includes("TypeScriptToLua")) return true;
    } catch (e) {}
    return false;
}

const patterns = [
    // ================================================================
    // 0-vs-1 INDEX BUGS (the #1 TSTL pitfall)
    // ================================================================
    {
        // Generic [0] access in compiled Lua — TSTL should convert but
        // fails when type is 'any'. This caught the critical cache bug.
        regex: /\w+\[0\]/g,
        message: "[0] access in Lua — Lua is 1-indexed. If this is TSTL-compiled code, entry[0] is nil. Use named properties or ensure proper typing.",
        severity: "WARN",
        tstlOnly: true,
    },
    {
        // GetTeamMember(0) — Valve uses 1-based player IDs
        regex: /GetTeamMember\s*\(\s*0\s*\)/g,
        message: "GetTeamMember(0) — Valve uses 1-based indices (1-5)",
        severity: "ERROR",
    },
    {
        // GetQueuedActionType(0)
        regex: /GetQueuedActionType\s*\(\s*0\s*\)/g,
        message: "GetQueuedActionType(0) — Valve uses 1-based indices",
        severity: "ERROR",
    },
    {
        // GetItemInSlot(-1)
        regex: /GetItemInSlot\s*\(\s*-1\s*\)/g,
        message: "GetItemInSlot(-1) — check if this is an error sentinel or actual slot",
        severity: "WARN",
    },
    {
        // for i = 0, ... GetTeamPlayers — should start at 1
        regex: /for\s+\w+\s*=\s*0\s*,\s*#?\s*GetTeamPlayers/g,
        message: "Loop starting at 0 over GetTeamPlayers — should start at 1",
        severity: "ERROR",
    },
    {
        // Valve API result accessed with [0]
        regex: /(?:GetNearbyHeroes|GetNearbyTowers|GetNearbyCreeps|GetNearbyLaneCreeps)\s*\([^)]*\)\s*\[0\]/g,
        message: "Valve API result accessed with [0] — should be [1] in Lua",
        severity: "ERROR",
    },
    {
        // Loop from 0 for NumQueuedActions
        regex: /for\s+\w+\s*=\s*0\s*,\s*\w+:NumQueuedActions/g,
        message: "Loop starting at 0 for NumQueuedActions — should start at 1",
        severity: "ERROR",
    },

    // ================================================================
    // SELF/COLON PITFALLS (TSTL method call issues)
    // ================================================================
    {
        // Static method compiled with self — e.g. ClassName.method(self, ...)
        // in TSTL output where the function shouldn't have self
        regex: /function\s+\w+\.(\w+)\s*\(\s*self\s*,/g,
        message: "Function with 'self' parameter — if this is a static method or module function, 'self' is wrong. Use standalone function instead of class static.",
        severity: "WARN",
        tstlOnly: true,
    },
    {
        // Fu.Item:method() or Fu.Skill:method() — colon on module tables
        // These should be dot calls since module functions don't have self
        regex: /Fu\.\w+:\w+\s*\(/g,
        message: "Fu.X:method() — colon call on Fu sub-module. Module functions don't expect 'self'. Use require() directly or verify @noSelf annotation.",
        severity: "ERROR",
        tstlOnly: true,
    },

    // ================================================================
    // NIL SAFETY (common runtime crashes)
    // ================================================================
    {
        // #variable where variable could be nil (from GetNearbyHeroes etc.)
        // Can't catch all cases, but flag obvious ones
        regex: /#\w+:GetNearbyHeroes/g,
        message: "#bot:GetNearbyHeroes(...) — GetNearbyHeroes can return nil (CanBeSeen check). Use 'or {}' or nil check.",
        severity: "WARN",
    },

    // ================================================================
    // TSTL TRUTHINESS (Lua treats 0 and "" as truthy)
    // ================================================================
    {
        // if (value) where value might be 0 — Lua treats 0 as truthy
        // Only flag explicit == 0 comparisons that suggest the code expects 0 to be falsy
        regex: /if\s+not\s+\w+\s+then.*--.*[Ff]alsy/g,
        message: "Lua truthiness: 0 and '' are truthy in Lua (only nil and false are falsy). If checking for 0, use explicit == 0.",
        severity: "WARN",
        tstlOnly: true,
    },

    // ================================================================
    // STRING CONCATENATION IN HOT PATHS
    // ================================================================
    {
        // String concat in cache keys — performance issue
        regex: /local\s+cacheKey\s*=\s*"[^"]*"\s*\.\./g,
        message: "String concatenation for cache key — consider numeric key encoding for performance.",
        severity: "WARN",
        tstlOnly: true,
    },

    // ================================================================
    // COMMON TSTL COMPILATION ISSUES
    // ================================================================
    {
        // ipairs on non-sequential table — TSTL sometimes uses ipairs
        // where pairs would be correct
        regex: /for\s+\w+\s*,\s*\w+\s+in\s+ipairs\s*\(\s*GetUnitList/g,
        message: "ipairs on GetUnitList — GetUnitList may have gaps. Use 'pairs' instead of 'ipairs' for safety.",
        severity: "WARN",
    },
    {
        // table.insert in a pairs loop over the same table (infinite loop risk)
        regex: /for\s+.*in\s+pairs\s*\(\s*(\w+)\s*\)[\s\S]{1,200}table\.insert\s*\(\s*\1/g,
        message: "table.insert into table being iterated with pairs — possible infinite loop.",
        severity: "WARN",
    },
];

let totalWarnings = 0;
let totalErrors = 0;
let filesScanned = 0;

function checkFile(filePath) {
    let content;
    try {
        content = fs.readFileSync(filePath, "utf8");
    } catch (e) {
        return;
    }

    const isTSTL = isTSTLGenerated(filePath);
    filesScanned++;
    const lines = content.split("\n");
    const relativePath = path.relative(luaRootDirectory, filePath).replace(/\\/g, "/");

    for (const { regex, message, severity, tstlOnly } of patterns) {
        // Skip TSTL-only patterns for hand-written Lua
        if (tstlOnly && !isTSTL) continue;

        regex.lastIndex = 0;

        for (let lineNum = 0; lineNum < lines.length; lineNum++) {
            const line = lines[lineNum];

            // Skip comments
            if (line.trim().startsWith("--")) continue;

            if (regex.test(line)) {
                const prefix = severity === "ERROR" ? "\x1b[31mERROR\x1b[0m" : "\x1b[33mWARN\x1b[0m";
                console.log(`  ${prefix}: ${relativePath}:${lineNum + 1} — ${message}`);
                console.log(`         ${line.trim()}`);
                if (severity === "ERROR") totalErrors++;
                else totalWarnings++;
            }
            regex.lastIndex = 0;
        }
    }
}

function processDirectory(directory) {
    const entries = fs.readdirSync(directory, { withFileTypes: true });
    for (const entry of entries) {
        const entryPath = path.join(directory, entry.name);
        if (entry.isDirectory()) {
            processDirectory(entryPath);
        } else if (entry.isFile() && entry.name.endsWith(".lua")) {
            checkFile(entryPath);
        }
    }
}

console.log("Scanning compiled Lua files for TSTL pitfalls...\n");
processDirectory(luaRootDirectory);

console.log(`\nScanned ${filesScanned} files.`);
if (totalErrors > 0) {
    console.log(`\x1b[31m${totalErrors} error(s)\x1b[0m found — likely bugs.`);
}
if (totalWarnings > 0) {
    console.log(`\x1b[33m${totalWarnings} warning(s)\x1b[0m found — review recommended.`);
}
if (totalErrors === 0 && totalWarnings === 0) {
    console.log("\x1b[32mNo issues found.\x1b[0m");
}

// Exit with error code if errors found (for CI integration)
if (totalErrors > 0) {
    process.exit(1);
}
