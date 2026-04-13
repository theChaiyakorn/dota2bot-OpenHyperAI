#!/usr/bin/env npx ts-node
/**
 * Obfuscate bots/ Lua files.
 *
 * Flow:
 * 1. Delete bots-raw/ if exists
 * 2. Copy bots/ → bots-raw/ (backup of raw source)
 * 3. Obfuscate all Lua files in bots/ in-place
 *
 * After: bots/ = obfuscated (Dota loads this), bots-raw/ = raw source backup
 *
 * Usage: npx ts-node typescript/post-process/obfuscator/obfuscate.ts
 */

import * as fs from "fs";
import * as path from "path";

// eslint-disable-next-line @typescript-eslint/no-var-requires
const luamin = require("luamin");

const ROOT = path.join(__dirname, "..", "..", "..");
const BOTS_DIR = path.join(ROOT, "bots");
const RAW_DIR = path.join(ROOT, "bots-raw");

// Dirs to skip obfuscation (user config — must remain readable)
const SKIP_OBFUSCATE = ["Customize"];

const stats = { total: 0, minified: 0, stripped: 0, skipped: 0, errors: 0 };

// ---------------------------------------------------------------------------
// Post-minification hardening transforms
// ---------------------------------------------------------------------------

/**
 * Encode string literals as string.char(...) calls.
 * Skips: require/dofile paths, very short strings (<=2), and strings that
 * are already inside a string.char call.
 */
function encodeStrings(code: string): string {
    // Match quoted strings: "..." or '...'
    // We process the entire minified code (single line typically)
    return code.replace(/(?:require|dofile)\s*\(\s*(?:"[^"]*"|'[^']*')\s*\)|"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/g, match => {
        // Skip require("...") and dofile("...") — Dota needs these intact
        if (/^(?:require|dofile)\s*\(/.test(match)) return match;

        // Extract the quote char and inner content
        const quote = match[0]; // " or '
        const inner = match.slice(1, -1);

        // Skip very short strings — not worth encoding
        if (inner.length <= 2) return match;

        // Skip strings that contain backslash escapes (complex to re-encode)
        if (inner.includes("\\")) return match;

        // Skip empty strings
        if (inner.length === 0) return match;

        // Convert to string.char(b1,b2,b3,...)
        const bytes = [];
        for (let i = 0; i < inner.length; i++) {
            bytes.push(inner.charCodeAt(i));
        }
        return `string.char(${bytes.join(",")})`;
    });
}

/**
 * Split numeric constants into computed expressions.
 * Targets floats (0.35, 0.525) and integers (>= 10).
 * Skips: 0, 1, -1, small integers, and numbers inside string.char() calls.
 */
function splitConstantsInCode(code: string): string {
    // Protect string.char(...) content from being transformed
    const charCallPlaceholders: string[] = [];
    let protected_ = code.replace(/string\.char\([^)]+\)/g, match => {
        const idx = charCallPlaceholders.length;
        charCallPlaceholders.push(match);
        return `__CHAR_PLACEHOLDER_${idx}__`;
    });

    // Replace float constants like 0.35, 0.525, etc.
    protected_ = protected_.replace(/(?<![.\w])(\d+\.\d+)(?![.\w])/g, (_match, numStr: string) => {
        const num = parseFloat(numStr);
        if (num === 0 || num === 1 || num === 0.5) return numStr;
        if (Math.abs(num) < 0.01 || Math.abs(num) > 10000) return numStr;

        const decimals = (numStr.split(".")[1] || "").length;
        const scale = Math.pow(10, decimals);
        const numerator = Math.round(num * scale);
        const a = Math.floor(numerator * 0.6);
        const b = numerator - a;
        return `(${a}+${b})/${scale}`;
    });

    // Replace integer constants >= 10
    protected_ = protected_.replace(/(?<![.\w"'])(\d{2,})(?![.\w"'])/g, (_match, numStr: string) => {
        const num = parseInt(numStr, 10);
        if (num < 10 || num > 100000) return numStr;
        if (numStr.length > 5) return numStr;

        const a = Math.floor(num * 0.4 + 7);
        const b = num - a;
        return `(${a}+${b})`;
    });

    // Restore string.char() calls
    for (let i = 0; i < charCallPlaceholders.length; i++) {
        protected_ = protected_.replace(`__CHAR_PLACEHOLDER_${i}__`, charCallPlaceholders[i]);
    }

    return protected_;
}

/**
 * Split numeric constants only in module-level code (before first function def).
 * Constants inside function bodies are evaluated every call, so leave them alone.
 */
function splitConstants(code: string): string {
    // Find the first function definition: "function " or "function("
    const funcMatch = code.match(/\bfunction[\s(]/);
    if (!funcMatch || funcMatch.index === undefined) {
        // No functions — entire file is module-level
        return splitConstantsInCode(code);
    }

    const splitPos = funcMatch.index;
    const moduleLevel = code.substring(0, splitPos);
    const funcBodies = code.substring(splitPos);

    return splitConstantsInCode(moduleLevel) + funcBodies;
}

/**
 * Apply all hardening transforms to minified code.
 */
function hardenCode(code: string): string {
    code = encodeStrings(code);
    code = splitConstants(code);
    return code;
}

interface LuaFile {
    fullPath: string;
    relPath: string;
}

function shouldSkip(relPath: string): boolean {
    return SKIP_OBFUSCATE.some(s => relPath.startsWith(s));
}

function getAllLuaFiles(dir: string, base?: string): LuaFile[] {
    base = base || dir;
    let results: LuaFile[] = [];
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const fullPath = path.join(dir, entry.name);
        const relPath = path.relative(base, fullPath);
        if (entry.isDirectory()) {
            results = results.concat(getAllLuaFiles(fullPath, base));
        } else if (entry.name.endsWith(".lua")) {
            results.push({ fullPath, relPath });
        }
    }
    return results;
}

function copyDirSync(src: string, dest: string): void {
    fs.mkdirSync(dest, { recursive: true });
    for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
        const srcPath = path.join(src, entry.name);
        const destPath = path.join(dest, entry.name);
        if (entry.isDirectory()) {
            copyDirSync(srcPath, destPath);
        } else {
            fs.copyFileSync(srcPath, destPath);
        }
    }
}

function stripComments(content: string): string {
    content = content.replace(/--\[\[[\s\S]*?\]\]/g, "");
    const lines = content.split("\n");
    const result: string[] = [];
    for (const line of lines) {
        let stripped = line;
        const dashPos = stripped.indexOf("--");
        if (dashPos >= 0) {
            const before = stripped.substring(0, dashPos);
            const singles = (before.match(/'/g) || []).length;
            const doubles = (before.match(/"/g) || []).length;
            if (singles % 2 === 0 && doubles % 2 === 0) {
                stripped = stripped.substring(0, dashPos);
            }
        }
        stripped = stripped.trimEnd();
        if (stripped.length > 0) {
            result.push(stripped);
        }
    }
    return result.join("\n");
}

function obfuscateFile(file: LuaFile): void {
    stats.total++;

    if (shouldSkip(file.relPath)) {
        stats.skipped++;
        return;
    }

    const content = fs.readFileSync(file.fullPath, "utf-8");

    // Try luamin first (variable renaming + minification)
    try {
        let minified = luamin.minify(content);
        if (minified && minified.length > 0) {
            minified = hardenCode(minified);
            fs.writeFileSync(file.fullPath, minified, "utf-8");
            stats.minified++;
            return;
        }
    } catch {
        // luamin failed — fall back to comment stripping
    }

    try {
        let stripped = stripComments(content);
        stripped = hardenCode(stripped);
        fs.writeFileSync(file.fullPath, stripped, "utf-8");
        stats.stripped++;
    } catch (e: any) {
        console.error(`  ERROR: ${file.relPath}: ${e.message}`);
        stats.errors++;
    }
}

function isFileObfuscated(filePath: string): boolean {
    const content = fs.readFileSync(filePath, "utf-8");
    const firstLine = content.split("\n")[0] || "";
    return firstLine.length > 500;
}

function isFileRaw(filePath: string): boolean {
    const content = fs.readFileSync(filePath, "utf-8");
    // Raw files have comments, indentation, or short first lines
    return content.includes("--") || content.includes("\t") || content.split("\n")[0].length < 500;
}

function verifySafety(): void {
    // Check that bots/ contains raw files (not already obfuscated)
    const testFile = path.join(BOTS_DIR, "mode_farm_generic.lua");
    if (fs.existsSync(testFile) && isFileObfuscated(testFile)) {
        console.error("ERROR: bots/ appears to already be obfuscated.");
        console.error("Cannot backup obfuscated files as raw source.");
        console.error("Run deobfuscate first to restore raw source, then try again.");
        process.exit(1);
    }

    // If bots-raw/ exists, verify it contains raw files before deleting
    if (fs.existsSync(RAW_DIR)) {
        const rawTestFile = path.join(RAW_DIR, "mode_farm_generic.lua");
        if (fs.existsSync(rawTestFile) && isFileObfuscated(rawTestFile)) {
            console.error("ERROR: bots-raw/ appears to contain obfuscated files, not raw source.");
            console.error("Something is wrong. Aborting to prevent data loss.");
            console.error("Manually inspect bots-raw/ before proceeding.");
            process.exit(1);
        }
    }
}

function main(): void {
    console.log("=== Obfuscate ===\n");

    // Safety: verify bots/ is raw and bots-raw/ (if exists) is also raw
    verifySafety();

    // 1. Delete bots-raw/ if exists
    if (fs.existsSync(RAW_DIR)) {
        console.log("Deleting existing bots-raw/ (verified as raw)...");
        fs.rmSync(RAW_DIR, { recursive: true });
    }

    // 2. Copy bots/ → bots-raw/
    console.log("Backing up bots/ → bots-raw/...");
    copyDirSync(BOTS_DIR, RAW_DIR);

    // 3. Obfuscate bots/ in-place
    const files = getAllLuaFiles(BOTS_DIR);
    console.log(`Obfuscating ${files.length} Lua files in bots/...\n`);

    for (const file of files) {
        obfuscateFile(file);
        if (stats.total % 50 === 0) process.stdout.write(`  ${stats.total}/${files.length}...\n`);
    }

    // Size comparison
    let rawSize = 0;
    let obfSize = 0;
    for (const f of files) {
        const rawPath = path.join(RAW_DIR, f.relPath);
        if (fs.existsSync(rawPath)) rawSize += fs.statSync(rawPath).size;
        obfSize += fs.statSync(f.fullPath).size;
    }

    console.log(`\nDone:`);
    console.log(`  ${stats.minified} luamin minified`);
    console.log(`  ${stats.stripped} comment-stripped (fallback)`);
    console.log(`  ${stats.skipped} skipped (Customize)`);
    console.log(`  ${stats.errors} errors`);
    console.log(`  ${stats.total} total`);
    console.log(`\nSize: ${(rawSize / 1024 / 1024).toFixed(1)}MB → ${(obfSize / 1024 / 1024).toFixed(1)}MB (${Math.round((1 - obfSize / rawSize) * 100)}% reduction)`);
    console.log(`\nbots/     = obfuscated (Dota loads this)`);
    console.log(`bots-raw/ = raw source backup`);
}

main();
