/**
 * Hero: Io (Wisp)
 *
 * Io is a support hero that tethers to allies, sharing HP/mana regen
 * and boosting attack speed via Overcharge. Relocate enables global
 * presence for ganks and saves.
 *
 * Ability priority: Tether > Overcharge > Spirits > Relocate
 */

import * as Fu from "bots/FuncLib/func_utils";
import { BotActionDesire, BotMode, Location, Unit, UnitType } from "bots/ts_libs/dota";
import { hero_is_healing } from "bots/FuncLib/data/buff";
import { GetTeamFountainTpPoint, HasAnyEffect, IsValidHero } from "bots/FuncLib/systems/utils";
import { buildHeroConfig, buildHeroExport } from "bots/FuncLib/hero/hero_builder";

// ============================================================
// Constants
// ============================================================

/** HP threshold below which Relocate activates for self or ally escape. */
const RELOCATE_HP_THRESHOLD = 0.2;

/** HP ratio of ally below which Tether becomes desirable for healing. */
const TETHER_ALLY_HP_THRESHOLD = 0.75;

/** Mana ratio above which Tether activates to share regen. */
const TETHER_MANA_SHARE_THRESHOLD = 0.8;

/** HP threshold below which bot prioritizes Tether for retreat. */
const TETHER_RETREAT_HP_THRESHOLD = 0.25;

/** Minimum distance to ally before considering Relocate to join a fight. */
const RELOCATE_MIN_DISTANCE = 3000;

/** Minimum neutral creeps to justify Spirits for farming. */
const SPIRITS_FARM_CREEP_COUNT = 2;

/** Mana ratio required to use Spirits for farming. */
const SPIRITS_FARM_MANA_THRESHOLD = 0.4;

// ============================================================
// Bot initialization
// ============================================================

const bot = GetBot();
// @ts-ignore — minion is hand-written Lua, loaded via dofile for per-bot isolation
const minion = dofile("bots/FuncLib/hero/minion");

// ============================================================
// Builds — role-specific items, shared skill/talent builds
// ============================================================

const hero = buildHeroConfig(bot, {
    skills: {
        default: [1, 3, 1, 3, 1, 6, 1, 3, 3, 2, 6, 2, 2, 2, 6],
    },
    talents: {
        default: { t25: [10, 0], t20: [10, 0], t15: [0, 10], t10: [0, 10] },
    },
    items: {
        pos_1: [
            "item_tango",
            "item_faerie_fire",
            "item_gauntlets",
            "item_gauntlets",
            "item_gauntlets",
            "item_boots",
            "item_armlet",
            "item_black_king_bar",
            "item_sange",
            "item_ultimate_scepter",
            "item_heavens_halberd",
            "item_travel_boots",
            "item_satanic",
            "item_aghanims_shard",
            "item_assault",
            "item_travel_boots_2",
            "item_ultimate_scepter_2",
            "item_moon_shard",
        ],
        pos_4: [
            "item_priest_outfit",
            "item_mekansm",
            "item_glimmer_cape",
            "item_guardian_greaves",
            "item_spirit_vessel",
            "item_shivas_guard",
            "item_sheepstick",
            "item_moon_shard",
            "item_ultimate_scepter_2",
        ],
        pos_5: [
            "item_blood_grenade",
            "item_mage_outfit",
            "item_ancient_janggo",
            "item_glimmer_cape",
            "item_pipe",
            "item_boots_of_bearing",
            "item_shivas_guard",
            "item_cyclone",
            "item_sheepstick",
            "item_wind_waker",
            "item_moon_shard",
            "item_ultimate_scepter_2",
        ],
    },
    sell: ["item_black_king_bar", "item_quelling_blade"],
});

// ============================================================
// Ability handles
// ============================================================

const abilityTether = bot.GetAbilityByName("wisp_tether");
const abilitySpirits = bot.GetAbilityByName("wisp_spirits");
const abilityOvercharge = bot.GetAbilityByName("wisp_overcharge");
const abilityRelocate = bot.GetAbilityByName("wisp_relocate");
const abilityBreakTether = bot.GetAbilityByName("wisp_tether_break");

// ============================================================
// Per-tick state (refreshed each SkillsComplement call)
// ============================================================

let nearbyEnemies: Unit[] = [];

// Persistent state across ticks (stored on bot handle)
bot.stateTetheredHero = bot.stateTetheredHero;

// ============================================================
// Helper functions (private — not exported)
// ============================================================

/** Returns true if the unit has any healing-over-time modifier active. */
function _hasHealingEffect(unit: Unit): boolean {
    return HasAnyEffect(unit, "modifier_tango_heal", ...hero_is_healing);
}

/** Returns true if the ally is actively fighting and would benefit from Overcharge. */
function _shouldUseOvercharge(ally: Unit): boolean {
    const isAttacking = GameTime() - ally.GetLastAttackTime() < 0.33;
    const attackTarget = ally.GetAttackTarget();
    return (
        Fu.IsGoingOnSomeone(ally) || (attackTarget !== null && attackTarget.GetTeam() === GetOpposingTeam() && isAttacking) || ally.GetNearbyCreeps(200, true).length > 2
    );
}

/** Returns true if the bot currently has an active Tether link. */
function _isTethered(): boolean {
    return bot.HasModifier("modifier_wisp_tether");
}

// ============================================================
// Consider functions — each returns desire (+ optional target)
// ============================================================

/**
 * Tether (Q): Link to an ally to share regen and enable Overcharge/Relocate.
 * - Retreat: tether to a retreating ally for shared escape
 * - Heal: tether when ally is low or bot has excess mana to share
 * - Fight: tether when ally is actively engaging
 */
function considerTether(): LuaMultiReturn<[number, Unit | null]> {
    if (!_isTethered()) {
        bot.stateTetheredHero = null;
    }
    if (!abilityTether.IsFullyCastable() || !abilityBreakTether.IsHidden()) {
        return $multi(BotActionDesire.None, null);
    }

    const castRange = abilityTether.GetCastRange();
    const allies = bot.GetNearbyHeroes(castRange, false, BotMode.None);

    for (const ally of allies) {
        if (ally == bot || !ally.IsAlive() || ally.IsMagicImmune()) continue;

        // Retreat: tether to retreating ally for shared escape speed
        if (Fu.IsRetreating(bot) || Fu.GetHP(bot) < TETHER_RETREAT_HP_THRESHOLD) {
            if (Fu.IsRetreating(ally)) {
                return $multi(BotActionDesire.High, ally);
            }
            continue;
        }

        // Heal / fight: tether when ally needs HP, bot has excess mana, or ally is fighting
        if (Fu.GetHP(ally) < TETHER_ALLY_HP_THRESHOLD || Fu.GetMP(bot) > TETHER_MANA_SHARE_THRESHOLD || _hasHealingEffect(bot) || _shouldUseOvercharge(ally)) {
            return $multi(BotActionDesire.High, ally);
        }
    }

    return $multi(BotActionDesire.None, null);
}

/**
 * Overcharge (E): Toggle attack speed / spell amp boost while tethered.
 * Only activates when tethered ally is actively fighting.
 */
function considerOvercharge(): number {
    if (!abilityOvercharge.IsFullyCastable()) {
        return BotActionDesire.None;
    }
    if (_isTethered() && bot.stateTetheredHero !== null && _shouldUseOvercharge(bot.stateTetheredHero)) {
        return BotActionDesire.High;
    }
    return BotActionDesire.None;
}

/**
 * Spirits (W): Summon orbiting spirits that damage nearby enemies.
 * - Fight: cast when any enemy hero is nearby
 * - Farm: cast on 2+ neutral creeps when mana is sufficient
 */
function considerSpirits(): number {
    if (!abilitySpirits.IsFullyCastable()) {
        return BotActionDesire.None;
    }
    if (nearbyEnemies.length >= 1) {
        return BotActionDesire.High;
    }
    if (bot.GetNearbyNeutralCreeps(500, true).length >= SPIRITS_FARM_CREEP_COUNT && Fu.GetMP(bot) > SPIRITS_FARM_MANA_THRESHOLD) {
        return BotActionDesire.Moderate;
    }
    return BotActionDesire.None;
}

/**
 * Relocate (R): Teleport self (and tethered ally) to a location.
 * - Escape: relocate to fountain when self or tethered ally is dying
 * - Join fight: relocate to a distant ally who is in a team fight
 */
function considerRelocate(): LuaMultiReturn<[number, Location | null]> {
    if (!abilityRelocate.IsFullyCastable()) {
        return $multi(BotActionDesire.None, null);
    }

    // Escape: save tethered ally or self by relocating to fountain
    if (_isTethered() && bot.stateTetheredHero !== null) {
        const allyHP = Fu.GetHP(bot.stateTetheredHero);
        const botHP = Fu.GetHP(bot);

        if (allyHP <= RELOCATE_HP_THRESHOLD || botHP <= RELOCATE_HP_THRESHOLD) {
            const allyNearbyEnemies = bot.stateTetheredHero.GetNearbyHeroes(1200, true, BotMode.None);
            const allyOutmatched = allyNearbyEnemies.length >= 1 && allyHP < Fu.GetHP(allyNearbyEnemies[0]);
            const selfOutmatched = nearbyEnemies.length >= 1 && botHP < Fu.GetHP(nearbyEnemies[0]);

            if (allyOutmatched || selfOutmatched) {
                return $multi(BotActionDesire.High, GetTeamFountainTpPoint());
            }
        }
    }

    // Self escape (untethered)
    if (!_isTethered() && nearbyEnemies.length >= 1 && Fu.GetHP(bot) < RELOCATE_HP_THRESHOLD) {
        return $multi(BotActionDesire.High, GetTeamFountainTpPoint());
    }

    // Join fight: relocate to a distant ally engaged in a team fight
    for (const ally of GetUnitList(UnitType.AlliedHeroes)) {
        if (IsValidHero(ally) && Fu.IsInTeamFight(ally, 1200) && GetUnitToUnitDistance(bot, ally) > RELOCATE_MIN_DISTANCE && ally.WasRecentlyDamagedByAnyHero(2)) {
            return $multi(BotActionDesire.High, ally.GetLocation());
        }
    }

    return $multi(BotActionDesire.None, null);
}

// ============================================================
// Main entry points
// ============================================================

/** Called each tick by ability_item_usage_generic to evaluate and cast abilities. */
function SkillsComplement(): void {
    if (Fu.CanNotUseAbility(bot) || bot.IsInvisible()) return;

    nearbyEnemies = bot.GetNearbyHeroes(1600, true, BotMode.None);

    // Priority 1: Tether
    const [tetherDesire, tetherTarget] = considerTether();
    if (tetherDesire > 0 && tetherTarget) {
        bot.Action_UseAbilityOnEntity(abilityTether, tetherTarget);
        bot.stateTetheredHero = tetherTarget;
        return;
    }

    // Priority 2: Overcharge (only useful while tethered)
    const overchargeDesire = considerOvercharge();
    if (overchargeDesire > 0) {
        bot.Action_UseAbility(abilityOvercharge);
        return;
    }

    // Priority 3: Spirits
    const spiritsDesire = considerSpirits();
    if (spiritsDesire > 0) {
        bot.Action_UseAbility(abilitySpirits);
        return;
    }

    // Priority 4: Relocate (lowest priority — high commitment)
    const [relocateDesire, relocateTarget] = considerRelocate();
    if (relocateDesire > 0 && relocateTarget !== null) {
        bot.Action_UseAbilityOnLocation(abilityRelocate, relocateTarget);
    }
}

/** Called by bot_generic for controlling summoned/illusion units. */
function MinionThink(hMinionUnit: any): void {
    if (minion.IsValidUnit(hMinionUnit)) {
        minion.IllusionThink(hMinionUnit);
    }
}

// ============================================================
// Export
// ============================================================

export = buildHeroExport(hero, SkillsComplement, MinionThink);
