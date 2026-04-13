// neutrals.ts — Fetch neutral item pick rates from Dotabuff
import fs from "node:fs";
import path from "node:path";
import puppeteer, { Page } from "puppeteer";
import * as cheerio from "cheerio";
import { hero_name_table, neutral_name_table, enhancement_name_table } from "./names";

type TierKey = number;
type ItemKey = string;

interface ItemsData {
    neutral: Record<TierKey, Record<ItemKey, number>>;
    enhancement: Record<TierKey, Record<ItemKey, number>>;
}

const USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36";
const DELAY_BETWEEN_HEROES = 2000;
const PAGE_LOAD_TIMEOUT = 15000;
// Use "year" — hardcoded patch versions break on every update
const DOTABUFF_DATE_QUERY = "year";

const OUT_PATH = path.resolve(__dirname, "../../bots/FretBots/neutrals_data.lua");

function sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function round2(n: number): number {
    return Math.round(n * 100) / 100;
}

async function fetchItemsPage(heroUrlName: string, page: Page): Promise<string> {
    const url = `https://www.dotabuff.com/heroes/${heroUrlName}/items?date=${DOTABUFF_DATE_QUERY}`;
    await page.goto(url, { waitUntil: "networkidle2", timeout: PAGE_LOAD_TIMEOUT });
    try {
        await page.waitForSelector("table", { timeout: 5000 });
    } catch {
        // no table — page might not have data
    }
    return await page.content();
}

function parseItemsTable(html: string): ItemsData | null {
    const $ = cheerio.load(html);
    let table = $("table.sortable").first();
    if (!table.length) table = $("article table").first();
    if (!table.length) table = $("table").first();
    if (!table.length) return null;

    const raw: ItemsData = { neutral: {}, enhancement: {} };

    const rows = table.find("tbody tr").toArray();
    if (rows.length === 0) rows.push(...table.find("tr").toArray().slice(1));

    for (const row of rows) {
        const cols = $(row).find("td");
        if (cols.length < 3) continue;

        const itemName = $(cols[1]).text().trim() || $(cols[0]).find("a").text().trim();
        const matchesTxt = $(cols[2]).text().trim().replace(/,/g, "");
        const matches = Number(matchesTxt);
        if (!Number.isFinite(matches) || !itemName) continue;

        // Try matching against neutral then enhancement tables
        for (const [tableSpec, key] of [
            [neutral_name_table, "neutral"],
            [enhancement_name_table, "enhancement"],
        ] as const) {
            for (const tierStr of Object.keys(tableSpec)) {
                const tier = Number(tierStr);
                for (const [itemKey, data] of Object.entries(tableSpec[tier])) {
                    if (data.visibleName.toLowerCase() === itemName.toLowerCase()) {
                        if (!raw[key][tier]) raw[key][tier] = {};
                        raw[key][tier][itemKey] = matches;
                    }
                }
            }
        }
    }

    // Normalize neutral items: per-tier percentages
    const items: ItemsData = { neutral: {}, enhancement: {} };

    for (const [tierStr, itemsInTier] of Object.entries(raw.neutral)) {
        const tier = Number(tierStr);
        const total = Object.values(itemsInTier).reduce((a, b) => a + b, 0);
        items.neutral[tier] = {};
        for (const [itemKey, m] of Object.entries(itemsInTier)) {
            items.neutral[tier][itemKey] = total > 0 ? round2((m / total) * 100) : 0;
        }
    }

    // Normalize enhancements: group by tier_unique, then normalize
    for (const [tierStr, itemsInTier] of Object.entries(raw.enhancement)) {
        const tier = Number(tierStr);
        items.enhancement[tier] = {};

        const itemKeyToTierUnique: Record<string, number> = {};
        for (const itemKey of Object.keys(itemsInTier)) {
            let found = false;
            for (const nameGroup of Object.values(enhancement_name_table)) {
                for (const [k, v] of Object.entries(nameGroup)) {
                    if (k === itemKey) {
                        itemKeyToTierUnique[itemKey] = v.tier_unique;
                        found = true;
                        break;
                    }
                }
                if (found) break;
            }
            if (!found) itemKeyToTierUnique[itemKey] = tier;
        }

        const tierUniqueTotals: Record<number, number> = {};
        for (const itemKey of Object.keys(itemsInTier)) {
            const tu = itemKeyToTierUnique[itemKey];
            if (!(tu in tierUniqueTotals)) {
                let sum = 0;
                const group = enhancement_name_table[tu] ?? {};
                for (const [k, v] of Object.entries(group)) {
                    if (v.tier_unique === tu) {
                        const rawForTier = raw.enhancement[tu] ?? {};
                        if (k in rawForTier) sum += rawForTier[k];
                    }
                }
                tierUniqueTotals[tu] = sum;
            }
        }

        for (const [itemKey, m] of Object.entries(itemsInTier)) {
            const total = tierUniqueTotals[itemKeyToTierUnique[itemKey]] ?? 0;
            items.enhancement[tier][itemKey] = total > 0 ? (m / total) * 100 : 0;
        }

        const subtotal = Object.values(items.enhancement[tier]).reduce((a, b) => a + b, 0);
        if (subtotal > 0) {
            for (const k of Object.keys(items.enhancement[tier])) {
                items.enhancement[tier][k] = round2((items.enhancement[tier][k] / subtotal) * 100);
            }
        }
    }

    const hasData = Object.keys(items.neutral).length > 0 || Object.keys(items.enhancement).length > 0;
    return hasData ? items : null;
}

function writeLuaIncremental(itemsDict: Record<string, ItemsData>): void {
    const lines: string[] = [];
    lines.push("-----");
    lines.push("-- This file is generated by typescript/post-process/neutrals.ts");
    lines.push("-----\n");
    lines.push("local heroList = {");
    for (const [hero, itemData] of Object.entries(itemsDict)) {
        lines.push(`    ['${hero}'] = {`);
        for (const typeKey of ["neutral", "enhancement"] as const) {
            lines.push(`       ['${typeKey}'] = {`);
            for (const [tier, items2] of Object.entries(itemData[typeKey])) {
                const pairs = Object.entries(items2)
                    .map(([name, chance]) => `['${name}'] = ${round2(chance)}`)
                    .join(", ");
                lines.push(`           [${tier}] = {${pairs}},`);
            }
            lines.push("        },");
        }
        lines.push("    },");
    }
    lines.push("}\n\nreturn heroList\n");
    fs.writeFileSync(OUT_PATH, lines.join("\n"), "utf-8");
}

async function main() {
    const itemsDict: Record<string, ItemsData> = {};

    const browser = await puppeteer.launch({
        headless: true,
        args: ["--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage"],
    });

    const page = await browser.newPage();
    await page.setUserAgent(USER_AGENT);
    await page.setViewport({ width: 1920, height: 1080 });

    const heroEntries = Object.entries(hero_name_table);
    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < heroEntries.length; i++) {
        const [internalName, data] = heroEntries[i];
        console.log(`[${i + 1}/${heroEntries.length}] Fetching items for ${internalName}...`);

        let retries = 2;
        while (retries >= 0) {
            try {
                const html = await fetchItemsPage(data.urlName, page);
                const items = parseItemsTable(html);

                if (items) {
                    itemsDict[internalName] = items;
                    const nCount = Object.values(items.neutral).reduce((a, t) => a + Object.keys(t).length, 0);
                    console.log(`  ✓ ${nCount} neutral items`);
                    successCount++;
                    break;
                } else if (retries > 0) {
                    console.log(`  Retrying in 5s...`);
                    await sleep(5000);
                    retries--;
                } else {
                    console.warn(`  ✗ No items after retries`);
                    failCount++;
                    break;
                }
            } catch (e) {
                if (retries > 0) {
                    console.warn(`  Error: ${e}. Retrying in 5s...`);
                    await sleep(5000);
                    retries--;
                } else {
                    console.error(`  ✗ Failed: ${e}`);
                    failCount++;
                    break;
                }
            }
        }

        // Save after every hero
        writeLuaIncremental(itemsDict);

        if (i < heroEntries.length - 1) {
            await sleep(DELAY_BETWEEN_HEROES);
        }
    }

    await page.close();
    await browser.close();

    console.log(`\nDone! ${successCount} succeeded, ${failCount} failed.`);
    console.log(`Output: ${OUT_PATH}`);
}

if (require.main === module) {
    main().catch(e => {
        console.error("Fatal error:", e);
        process.exit(1);
    });
}
