/**
 * Dispel System — centralized debuff detection and removal for all heroes.
 *
 * Pro-level decision making:
 * 1. Duration-aware — don't waste BKB on 0.5s stun
 * 2. Survival check — don't dispel if dead anyway
 * 3. Hero-type aware — silence on caster vs carry
 * 4. Preemptive — Lotus before enemy ults, not after
 * 5. Offensive purge — strip enemy buffs
 * 6. Protection-aware — don't dispel during Grave/False Promise
 * 7. Projectile dodging — Manta disjoint
 */

import { BotMode, Unit } from "bots/ts_libs/dota";

// ============================================================
// Debuff tables with metadata
// ============================================================

interface DebuffInfo {
    severity: number; // 1-10 score
    isDisable: boolean; // stun/hex — can't act at all
    isSilence: boolean; // can't cast spells
    isRoot: boolean; // can't move
    isDot: boolean; // damage over time
    isArmor: boolean; // armor reduction / damage amp
    basicDispel: boolean; // removable by basic dispel
    strongDispel: boolean; // removable by strong dispel only
}

const DEBUFFS: Record<string, DebuffInfo> = {
    // CRITICAL: complete disable
    modifier_stunned: { severity: 9, isDisable: true, isSilence: false, isRoot: false, isDot: false, isArmor: false, basicDispel: false, strongDispel: true },
    modifier_bashed: { severity: 9, isDisable: true, isSilence: false, isRoot: false, isDot: false, isArmor: false, basicDispel: false, strongDispel: true },
    modifier_sheepstick_debuff: { severity: 9, isDisable: true, isSilence: false, isRoot: false, isDot: false, isArmor: false, basicDispel: false, strongDispel: true },
    modifier_lion_voodoo: { severity: 9, isDisable: true, isSilence: false, isRoot: false, isDot: false, isArmor: false, basicDispel: false, strongDispel: true },
    modifier_shadow_shaman_voodoo: {
        severity: 9,
        isDisable: true,
        isSilence: false,
        isRoot: false,
        isDot: false,
        isArmor: false,
        basicDispel: false,
        strongDispel: true,
    },
    modifier_bane_nightmare: { severity: 8, isDisable: true, isSilence: false, isRoot: false, isDot: false, isArmor: false, basicDispel: false, strongDispel: true },

    // HIGH: silence / major debuff
    modifier_doom_bringer_doom: { severity: 10, isDisable: false, isSilence: true, isRoot: false, isDot: true, isArmor: false, basicDispel: false, strongDispel: true },
    modifier_orchid_malevolence_debuff: {
        severity: 7,
        isDisable: false,
        isSilence: true,
        isRoot: false,
        isDot: false,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_bloodthorn_debuff: { severity: 8, isDisable: false, isSilence: true, isRoot: false, isDot: false, isArmor: false, basicDispel: true, strongDispel: true },
    modifier_silencer_last_word: { severity: 6, isDisable: false, isSilence: true, isRoot: false, isDot: false, isArmor: false, basicDispel: true, strongDispel: true },
    modifier_skywrath_mage_ancient_seal: {
        severity: 7,
        isDisable: false,
        isSilence: true,
        isRoot: false,
        isDot: false,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_death_prophet_silence: {
        severity: 6,
        isDisable: false,
        isSilence: true,
        isRoot: false,
        isDot: false,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_night_stalker_crippling_fear: {
        severity: 6,
        isDisable: false,
        isSilence: true,
        isRoot: false,
        isDot: false,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_riki_smoke_screen: { severity: 6, isDisable: false, isSilence: true, isRoot: false, isDot: false, isArmor: false, basicDispel: false, strongDispel: false },
    modifier_disruptor_static_storm: {
        severity: 7,
        isDisable: false,
        isSilence: true,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: false,
        strongDispel: false,
    },

    // ROOT
    modifier_rod_of_atos_debuff: { severity: 5, isDisable: false, isSilence: false, isRoot: true, isDot: false, isArmor: false, basicDispel: true, strongDispel: true },
    modifier_crystal_maiden_frostbite: {
        severity: 5,
        isDisable: false,
        isSilence: false,
        isRoot: true,
        isDot: true,
        isArmor: false,
        basicDispel: false,
        strongDispel: true,
    },
    modifier_treant_overgrowth: { severity: 6, isDisable: false, isSilence: false, isRoot: true, isDot: false, isArmor: false, basicDispel: false, strongDispel: true },

    // ARMOR/DAMAGE AMP
    modifier_slardar_amplify_damage: {
        severity: 5,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: false,
        isArmor: true,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_bounty_hunter_track: { severity: 4, isDisable: false, isSilence: false, isRoot: false, isDot: false, isArmor: true, basicDispel: true, strongDispel: true },
    modifier_spirit_vessel_damage: { severity: 5, isDisable: false, isSilence: false, isRoot: false, isDot: true, isArmor: false, basicDispel: true, strongDispel: true },
    modifier_item_spirit_vessel_damage: {
        severity: 5,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_razor_static_link_debuff: {
        severity: 5,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: false,
        isArmor: true,
        basicDispel: true,
        strongDispel: true,
    },

    // SLOWS / DOTS
    modifier_viper_viper_strike_slow: {
        severity: 4,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_axe_battle_hunger_self: {
        severity: 3,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_venomancer_venomous_gale: {
        severity: 3,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_bristleback_viscous_nasal_goo: {
        severity: 2,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: false,
        isArmor: true,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_phoenix_fire_spirit_burn: {
        severity: 2,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_earth_spirit_magnetize: {
        severity: 3,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: true,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_warlock_fatal_bonds: { severity: 3, isDisable: false, isSilence: false, isRoot: false, isDot: false, isArmor: false, basicDispel: true, strongDispel: true },
    modifier_life_stealer_open_wounds: {
        severity: 3,
        isDisable: false,
        isSilence: false,
        isRoot: false,
        isDot: false,
        isArmor: false,
        basicDispel: true,
        strongDispel: true,
    },
    modifier_ice_blast: { severity: 4, isDisable: false, isSilence: false, isRoot: false, isDot: true, isArmor: false, basicDispel: false, strongDispel: false },
};

/** Enemy buffs worth stripping with offensive purge */
const ENEMY_BUFFS_TO_STRIP: string[] = [
    "modifier_ghost_state",
    "modifier_item_ghost",
    "modifier_windrunner_windrun",
    "modifier_ogre_magi_bloodlust",
    "modifier_ursa_overpower",
    "modifier_legion_commander_press_the_attack",
    "modifier_omniknight_repel",
    "modifier_haste_rune_speed",
    "modifier_double_damage",
    "modifier_ember_spirit_flame_guard",
    "modifier_abaddon_aphotic_shield",
];

/** Modifiers that mean the ally is already protected — don't dispel */
const PROTECTED_MODIFIERS: string[] = [
    "modifier_dazzle_shallow_grave",
    "modifier_oracle_false_promise_timer",
    "modifier_abaddon_borrowed_time",
    "modifier_skeleton_king_reincarnation_scepter_active",
    "modifier_item_aeon_disk_buff",
];

// ============================================================
// Core analysis functions
// ============================================================

/**
 * Analyze all debuffs on a unit. Returns total severity score
 * and the worst debuff info for decision making.
 */
export function AnalyzeDebuffs(unit: Unit): {
    score: number;
    worstSeverity: number;
    hasSilence: boolean;
    hasDisable: boolean;
    hasRoot: boolean;
    canBasicDispel: boolean;
    canStrongDispel: boolean;
} {
    let score = 0;
    let worstSeverity = 0;
    let hasSilence = false;
    let hasDisable = false;
    let hasRoot = false;
    let canBasicDispel = false;
    let canStrongDispel = false;

    for (const [mod, info] of Object.entries(DEBUFFS)) {
        if (unit.HasModifier(mod)) {
            // Duration check: don't count very short debuffs (< 1s remaining)
            const remaining = (unit as any).GetModifierRemainingDuration ? (unit as any).GetModifierRemainingDuration(mod) : 999; // assume long if we can't check

            if (remaining < 0.5) continue; // Too short to react to

            score += info.severity;
            if (info.severity > worstSeverity) worstSeverity = info.severity;
            if (info.isSilence) hasSilence = true;
            if (info.isDisable) hasDisable = true;
            if (info.isRoot) hasRoot = true;
            if (info.basicDispel) canBasicDispel = true;
            if (info.strongDispel) canStrongDispel = true;
        }
    }

    return { score, worstSeverity, hasSilence, hasDisable, hasRoot, canBasicDispel, canStrongDispel };
}

/**
 * Check if a unit is currently protected (Grave, False Promise, etc.)
 * If protected, don't waste a dispel on them.
 */
export function IsProtected(unit: Unit): boolean {
    for (const mod of PROTECTED_MODIFIERS) {
        if (unit.HasModifier(mod)) return true;
    }
    return false;
}

/**
 * Check if silence matters for this hero.
 * Silence on a right-click carry is low priority.
 * Silence on a spellcaster is critical.
 */
function IsSilenceCriticalForHero(bot: Unit): boolean {
    // Check if hero has castable abilities (not just passives)
    for (let i = 0; i < 6; i++) {
        const ability = bot.GetAbilityInSlot(i);
        if (ability && ability.IsTrained() && !(ability as any).IsPassive() && (ability as any).IsCooldownReady()) {
            return true; // Has a ready active spell — silence hurts
        }
    }
    return false; // All spells passive or on cooldown — silence doesn't matter much
}

/**
 * Check if the bot can realistically survive after dispelling.
 * Don't waste BKB if dead in 1 second regardless.
 */
function CanSurviveAfterDispel(bot: Unit): boolean {
    // Always try to dispel human players and core heroes (pos 1-2)
    if (!(bot as any).IsBot() || ((bot as any).GetPosition && (bot as any).GetPosition() <= 2)) {
        return true;
    }

    const hp = (bot as any).GetHealth() / (bot as any).GetMaxHealth();
    const enemies = bot.GetNearbyHeroes(1200, true, BotMode.None);
    const allies = bot.GetNearbyHeroes(1200, false, BotMode.None);

    // At very low HP with many enemies and few allies — probably dead anyway
    if (hp < 0.1 && enemies && enemies.length >= 3 && (!allies || allies.length <= 1)) {
        return false;
    }

    return true;
}

// ============================================================
// Self-dispel item usage
// ============================================================

/**
 * Check if the bot should use a dispel item on itself.
 * Returns the item slot to use, or -1 if no action needed.
 *
 * Pro-level logic:
 * - Checks debuff duration (don't waste on 0.5s stuns)
 * - Checks survival likelihood
 * - Checks if silence matters for this hero
 * - Won't dispel during existing protection
 */
export function ShouldUseSelfDispelItem(bot: Unit): number {
    if (IsProtected(bot)) return -1;
    if (!CanSurviveAfterDispel(bot)) return -1;

    const analysis = AnalyzeDebuffs(bot);
    if (analysis.score < 4) return -1; // Not worth dispelling

    // If silenced but we're a right-clicker with no ready spells, lower priority
    if (analysis.hasSilence && !analysis.hasDisable && !IsSilenceCriticalForHero(bot)) {
        if (analysis.score < 7) return -1; // Only dispel silence if other debuffs compound it
    }

    const needsStrong = analysis.hasDisable || !analysis.canBasicDispel;

    // Priority order: strong dispels first for disables, basic for slows/silences
    const itemPriority = needsStrong
        ? ["item_black_king_bar", "item_satanic", "item_aeon_disk", "item_manta", "item_cyclone", "item_guardian_greaves"]
        : ["item_manta", "item_cyclone", "item_guardian_greaves", "item_lotus_orb", "item_black_king_bar"];

    for (const itemName of itemPriority) {
        const slot = bot.FindItemSlot(itemName);
        if (slot >= 0) {
            const item = bot.GetItemInSlot(slot);
            if (item && (item as any).IsFullyCastable()) {
                // Special: don't waste BKB on weak debuffs
                if (itemName === "item_black_king_bar" && analysis.worstSeverity < 6) continue;
                // Special: don't Eul's in team fight (removes you from fight)
                if (itemName === "item_cyclone") {
                    const enemies = bot.GetNearbyHeroes(900, true, BotMode.None);
                    if (enemies && enemies.length >= 2) continue;
                }
                return slot;
            }
        }
    }

    return -1;
}

// ============================================================
// Ally dispel (items)
// ============================================================

/**
 * Check if the bot should use Lotus Orb on a debuffed ally.
 * Also considers preemptive usage — Lotus before enemy casts.
 */
export function ShouldUseAllyDispelItem(bot: Unit): LuaMultiReturn<[number, Unit | null]> {
    const lotusSlot = bot.FindItemSlot("item_lotus_orb");
    if (lotusSlot < 0) return $multi(-1, null);
    const lotusItem = bot.GetItemInSlot(lotusSlot);
    if (!lotusItem || !(lotusItem as any).IsFullyCastable()) return $multi(-1, null);

    const allies = bot.GetNearbyHeroes(900, false, BotMode.None);
    if (!allies) return $multi(-1, null);

    let bestAlly: Unit | null = null;
    let bestScore = 0;

    for (const ally of allies) {
        if (ally === bot || !ally.IsAlive() || IsProtected(ally)) continue;

        const analysis = AnalyzeDebuffs(ally);
        if (analysis.score > bestScore && analysis.score >= 5) {
            bestScore = analysis.score;
            bestAlly = ally;
        }

        // Preemptive: if ally is being chased by a hero known for targeted disables
        // and ally has no Lotus buff yet
        if (!ally.HasModifier("modifier_item_lotus_orb_active")) {
            const enemiesNearAlly = ally.GetNearbyHeroes(800, true, BotMode.None);
            if (enemiesNearAlly) {
                for (const enemy of enemiesNearAlly) {
                    if (enemy && !enemy.IsNull() && enemy.IsAlive()) {
                        const eName = enemy.GetUnitName();
                        // Heroes with dangerous targeted ults
                        if (
                            eName === "npc_dota_hero_doom_bringer" ||
                            eName === "npc_dota_hero_lion" ||
                            eName === "npc_dota_hero_lina" ||
                            eName === "npc_dota_hero_necrolyte" ||
                            eName === "npc_dota_hero_bane"
                        ) {
                            if ((enemy as any).IsFacingLocation(ally.GetLocation(), 30)) {
                                bestAlly = ally;
                                bestScore = 10; // Preemptive is high priority
                            }
                        }
                    }
                }
            }
        }
    }

    if (bestAlly) return $multi(lotusSlot, bestAlly);
    return $multi(-1, null);
}

// ============================================================
// Manta projectile dodge
// ============================================================

/**
 * Check if bot should Manta-dodge an incoming targeted projectile.
 * Returns item slot or -1.
 */
export function ShouldMantaDodge(bot: Unit): number {
    const mantaSlot = bot.FindItemSlot("item_manta");
    if (mantaSlot < 0) return -1;
    const item = bot.GetItemInSlot(mantaSlot);
    if (!item || !(item as any).IsFullyCastable()) return -1;

    // Check if there's an incoming targeted projectile
    const incoming = (bot as any).GetIncomingTrackingProjectiles();
    if (incoming) {
        for (const proj of incoming) {
            if (proj && proj.is_attack === false && proj.is_dodgeable) {
                // Calculate time to impact
                const dist = GetUnitToLocationDistance(bot, proj.location);
                const speed = proj.speed || 1000;
                const timeToImpact = dist / speed;

                // Dodge if impact within 0.3s (Manta has 0.1s invulnerability)
                if (timeToImpact < 0.3 && timeToImpact > 0.05) {
                    return mantaSlot;
                }
            }
        }
    }

    return -1;
}

// ============================================================
// Offensive purge (strip enemy buffs)
// ============================================================

/**
 * Check if an enemy has a buff worth stripping.
 * For use with Eul's on enemy, Nullifier, Demonic Purge, etc.
 */
export function HasStrippableBuff(enemy: Unit): boolean {
    for (const mod of ENEMY_BUFFS_TO_STRIP) {
        if (enemy.HasModifier(mod)) return true;
    }
    return false;
}

/**
 * Get the best enemy to offensively purge within range.
 */
export function GetBestEnemyToPurge(bot: Unit, range: number): Unit | null {
    const enemies = bot.GetNearbyHeroes(range, true, BotMode.None);
    if (!enemies) return null;

    for (const enemy of enemies) {
        if (enemy && !enemy.IsNull() && enemy.IsAlive() && !enemy.IsMagicImmune()) {
            if (HasStrippableBuff(enemy)) {
                return enemy;
            }
        }
    }
    return null;
}

// ============================================================
// Hero ability-based dispel helpers
// ============================================================

/**
 * For heroes with ally-dispel abilities (Abaddon, LC, Oracle, Omni):
 * Returns the best ally to dispel.
 */
export function GetBestAllyToDispel(bot: Unit, castRange: number, isStrongDispel: boolean = false): Unit | null {
    const allies = bot.GetNearbyHeroes(castRange, false, BotMode.None);
    if (!allies) return null;

    let bestAlly: Unit | null = null;
    let bestScore = 0;

    for (const ally of allies) {
        if (ally === bot || !ally.IsAlive() || IsProtected(ally)) continue;

        const analysis = AnalyzeDebuffs(ally);
        if (analysis.score < 4) continue;
        if (!isStrongDispel && !analysis.canBasicDispel) continue;
        if (analysis.score > bestScore) {
            bestScore = analysis.score;
            bestAlly = ally;
        }
    }

    return bestAlly;
}

/**
 * For heroes with self-dispel abilities (Slark, Ursa, Lifestealer, etc.):
 * Returns true if the bot should self-dispel now.
 */
export function ShouldSelfDispel(bot: Unit, isStrongDispel: boolean): boolean {
    if (IsProtected(bot)) return false;

    const analysis = AnalyzeDebuffs(bot);

    if (isStrongDispel) {
        // Strong: use for disables (stuns, hexes) or Doom
        return analysis.hasDisable || analysis.worstSeverity >= 9;
    }

    // Basic: use for silences (if caster) or high-severity debuffs
    if (analysis.hasSilence && IsSilenceCriticalForHero(bot)) return true;
    return analysis.score >= 5 && analysis.canBasicDispel;
}

// Backward compatibility aliases
export function GetDebuffSeverity(unit: Unit): number {
    return AnalyzeDebuffs(unit).score;
}

export function HasDispellableDebuff(unit: Unit, minSeverity: number = 1): boolean {
    return GetDebuffSeverity(unit) >= minSeverity;
}

export function NeedsStrongDispel(unit: Unit): boolean {
    return AnalyzeDebuffs(unit).hasDisable;
}
