#!/usr/bin/env npx ts-node
/**
 * De-obfuscate: restore bots/ from bots-raw/ backup.
 *
 * Flow:
 * 1. Verify bots/ contains obfuscated files (safety check)
 * 2. Delete bots/
 * 3. Copy bots-raw/ → bots/
 *
 * After: bots/ = raw source (editable), bots-raw/ = still exists as backup
 *
 * Usage: npx ts-node typescript/post-process/obfuscator/deobfuscate.ts
 */

import * as fs from "fs";
import * as path from "path";

const ROOT = path.join(__dirname, "..", "..", "..");
const BOTS_DIR = path.join(ROOT, "bots");
const RAW_DIR = path.join(ROOT, "bots-raw");

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

function isObfuscated(filePath: string): boolean {
    const content = fs.readFileSync(filePath, "utf-8");
    const firstLine = content.split("\n")[0] || "";
    return firstLine.length > 500;
}

function isRaw(filePath: string): boolean {
    const content = fs.readFileSync(filePath, "utf-8");
    return content.includes("--") || content.includes("\t") || content.split("\n")[0].length < 500;
}

function main(): void {
    console.log("=== De-obfuscate ===\n");

    if (!fs.existsSync(RAW_DIR)) {
        console.error("ERROR: bots-raw/ does not exist. Cannot restore.");
        console.error("Run obfuscate first to create the backup.");
        process.exit(1);
    }

    // Safety: verify bots-raw/ contains raw files
    const rawTestFile = path.join(RAW_DIR, "mode_farm_generic.lua");
    if (fs.existsSync(rawTestFile) && !isRaw(rawTestFile)) {
        console.error("ERROR: bots-raw/ does not appear to contain raw source files.");
        console.error("Aborting to prevent restoring obfuscated files as source.");
        process.exit(1);
    }

    // Safety: verify bots/ is obfuscated (don't delete raw source)
    if (fs.existsSync(BOTS_DIR)) {
        const testFile = path.join(BOTS_DIR, "mode_farm_generic.lua");
        if (fs.existsSync(testFile) && !isObfuscated(testFile)) {
            console.error("WARNING: bots/ does not appear to be obfuscated.");
            console.error("It may contain your raw source. Aborting to prevent data loss.");
            console.error("If you are sure, delete bots/ manually first, then run again.");
            process.exit(1);
        }

        console.log("Deleting obfuscated bots/ (verified as obfuscated)...");
        fs.rmSync(BOTS_DIR, { recursive: true });
    }

    // Copy bots-raw/ → bots/
    console.log("Restoring bots-raw/ → bots/ (verified as raw)...");
    copyDirSync(RAW_DIR, BOTS_DIR);

    console.log("\nDone: bots/ restored to raw source.");
    console.log("bots-raw/ still exists as backup (you can delete it if not needed).");
}

main();
