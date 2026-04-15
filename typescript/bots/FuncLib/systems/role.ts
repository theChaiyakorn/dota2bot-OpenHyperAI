import { GameMode, GameState, Lane, Team, Unit } from "bots/ts_libs/dota";
import { NumHumanBotPlayersInTeam } from "bots/FuncLib/systems/utils";
import * as HeroRolesMap from "bots/FuncLib/data/hero_roles_map";
import { GetEnemyPosition } from "bots/FuncLib/hero/enemy_role_estimation";
import { HeroName } from "bots/ts_libs/dota/heroes";

export let RoleAssignment: { [key: string]: number[] } = {
    TEAM_RADIANT: [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
    TEAM_DIRE: [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5],
};

export const IsCarry = function (hero: HeroName) {
    return HeroRolesMap.IsCarry(hero);
};
export const IsDisabler = function (hero: HeroName) {
    return HeroRolesMap.IsDisabler(hero);
};
export const IsDurable = function (hero: HeroName) {
    return HeroRolesMap.IsDurable(hero);
};
export const HasEscape = function (hero: HeroName) {
    return HeroRolesMap.HasEscape(hero);
};
export const IsInitiator = function (hero: HeroName) {
    return HeroRolesMap.IsInitiator(hero);
};
export const IsJungler = function (hero: HeroName) {
    return HeroRolesMap.IsJungler(hero);
};
export const IsNuker = function (hero: HeroName) {
    return HeroRolesMap.IsNuker(hero);
};
export const IsSupport = function (hero: HeroName) {
    return HeroRolesMap.IsSupport(hero);
};
export const IsPusher = function (hero: HeroName) {
    return HeroRolesMap.IsPusher(hero);
};
export const IsRanged = function (hero: HeroName) {
    return HeroRolesMap.IsRanged(hero);
};
export const IsHealer = function (hero: HeroName) {
    return HeroRolesMap.IsHealer(hero);
};

export const IsMelee = function (attackRange: number) {
    return attackRange <= 326;
};

// OFFLANER
export const CanBeOfflaner = function (hero: HeroName) {
    return IsInitiator(hero) && IsDurable(hero);
};

// MIDLANER
export const CanBeMidlaner = function (hero: HeroName) {
    return HeroRolesMap.IsCarry(hero);
};

// SAFELANER
export const CanBeSafeLaneCarry = function (hero: HeroName) {
    return HeroRolesMap.IsCarry(hero);
};

// SUPPORT
export const CanBeSupport = function (hero: HeroName) {
    return HeroRolesMap.IsSupport(hero);
};

export const GetCurrentSuitableRole = function (bot: Unit, hero: HeroName) {
    const lane = bot.GetAssignedLane();
    if (CanBeSupport(hero) && lane !== Lane.Mid) {
        return "support";
    } else if (CanBeMidlaner(hero) && lane === Lane.Mid) {
        return "midlaner";
    } else if (CanBeSafeLaneCarry(hero) && ((GetTeam() === Team.Radiant && lane === Lane.Bot) || (GetTeam() === Team.Dire && lane === Lane.Top))) {
        return "carry";
    } else if (CanBeOfflaner(hero) && ((GetTeam() === Team.Radiant && lane === Lane.Top) || (GetTeam() === Team.Dire && lane === Lane.Bot))) {
        return "offlaner";
    } else {
        return "unknown";
    }
};

// best guess for e.g. enemy heroes
export const GetBestEffortSuitableRole = function (hero: HeroName) {
    if (CanBeSupport(hero)) {
        return 4;
    } else if (CanBeMidlaner(hero)) {
        return 2;
    } else if (CanBeSafeLaneCarry(hero)) {
        return 1;
    } else if (CanBeOfflaner(hero)) {
        return 3;
    } else {
        return 3;
    }
};

export let invisEnemyExist = false;
let globalEnemyCheck = false;
let lastCheck = -90;

export const UpdateInvisEnemyStatus = function (bot: Unit) {
    if (invisEnemyExist) return;

    if (globalEnemyCheck === false) {
        const players = GetTeamPlayers(GetOpposingTeam());
        for (let i = 0; i < players.length; i++) {
            if (HeroRolesMap.InvisHeroes[GetSelectedHeroName(players[i])] === 1) {
                invisEnemyExist = true;
                break;
            }
        }
        globalEnemyCheck = true;
    } else if (globalEnemyCheck === true && DotaTime() > 10 * 60 && DotaTime() > lastCheck + 3.0) {
        const enemies = bot.GetNearbyHeroes(1600, true, 0 /*BOT_MODE_NONE*/);
        if (enemies.length > 0) {
            for (let i = 0; i < enemies.length; i++) {
                const enemy = enemies[i];
                if (enemy != null && enemy.CanBeSeen()) {
                    const SASlot = enemy.FindItemSlot("item_shadow_amulet");
                    const GCSlot = enemy.FindItemSlot("item_glimmer_cape");
                    const ISSlot = enemy.FindItemSlot("item_invis_sword");
                    const SESlot = enemy.FindItemSlot("item_silver_edge");
                    if (SASlot >= 0 || GCSlot >= 0 || ISSlot >= 0 || SESlot >= 0) {
                        invisEnemyExist = true;
                        break;
                    }
                }
            }
        }
        lastCheck = DotaTime();
    }
};

export let supportExist: null | boolean = null;
export const UpdateSupportStatus = function (bot: Unit) {
    if (supportExist) {
        return true;
    }

    if (GetPosition(bot) >= 4) {
        supportExist = true;
        return true;
    }

    const TeamMember = GetTeamPlayers(GetTeam());
    for (let i = 0; i < TeamMember.length; i++) {
        const ally = GetTeamMember(i + 1);
        if (ally != null && ally.IsHero() && GetPosition(ally) >= 4) {
            supportExist = true;
            return true;
        }
    }

    return false;
};

export let sayRate = false;
export const NotSayRate = function () {
    return sayRate === false;
};

export let sayJiDi = false;
export const NotSayJiDi = function () {
    return sayJiDi === false;
};

export let replyMemberID: null | number = null;
export const GetReplyMemberID = function () {
    if (replyMemberID != null) return replyMemberID;

    const tMemberIDList = GetTeamPlayers(GetTeam());

    const nMemberCount = tMemberIDList.length;
    let nHumanCount = 0;
    for (let i = 0; i < tMemberIDList.length; i++) {
        if (!IsPlayerBot(tMemberIDList[i])) {
            nHumanCount = nHumanCount + 1;
        }
    }

    replyMemberID = tMemberIDList[RandomInt(nHumanCount + 1, nMemberCount)];
    return replyMemberID;
};

export let memberIDIndexTable: null | { [key: number]: boolean } = null;
export const IsAllyMemberID = function (nID: number) {
    if (memberIDIndexTable == null) {
        const tMemberIDList = GetTeamPlayers(GetTeam());
        if (tMemberIDList.length > 0) {
            memberIDIndexTable = {};
            for (let i = 0; i < tMemberIDList.length; i++) {
                memberIDIndexTable[tMemberIDList[i]] = true;
            }
        }
    }
    return memberIDIndexTable && memberIDIndexTable[nID] === true;
};

export let enemyIDIndexTable: null | { [key: number]: boolean } = null;
export const IsEnemyMemberID = function (nID: number) {
    if (enemyIDIndexTable == null) {
        const tEnemyIDList = GetTeamPlayers(GetOpposingTeam());
        if (tEnemyIDList.length > 0) {
            enemyIDIndexTable = {};
            for (let i = 0; i < tEnemyIDList.length; i++) {
                enemyIDIndexTable[tEnemyIDList[i]] = true;
            }
        } else {
            return false;
        }
    }

    return enemyIDIndexTable && enemyIDIndexTable[nID] === true;
};

export let sLastChatString = "-0";
export let sLastChatTime = -90;
export const SetLastChatString = function (sChatString: string) {
    sLastChatString = sChatString;
    sLastChatTime = DotaTime();
};

export const ShouldTpToDefend = function () {
    if (sLastChatString === "-都来守家" && sLastChatTime >= DotaTime() - 10.0) {
        return true;
    }
    return false;
};

export let fLastGiveTangoTime = -90;

export let aegisHero: null | Unit = null;
export const IsAllyHaveAegis = function () {
    if (aegisHero != null && aegisHero.FindItemSlot("item_aegis") < 0) {
        aegisHero = null;
    }

    return aegisHero != null;
};

export let lastbbtime = -90;
export const ShouldBuyBack = function () {
    return DotaTime() > lastbbtime + 1.0;
};

export let lastFarmTpTime = -90;
export const ShouldTpToFarm = function () {
    return DotaTime() > lastFarmTpTime + 4.0;
};

export let lastPowerRuneTime = 90;
export const IsPowerRuneKnown = function () {
    return Math.floor(lastPowerRuneTime / 120) === Math.floor(DotaTime() / 120);
};

export let campCount = 18;
export const GetCampCount = function () {
    return campCount;
};

export let hasRefreshDone = true;
export const IsCampRefreshDone = function () {
    return hasRefreshDone === true;
};

export let availableCampTable: number[] = [];
export const GetAvailableCampCount = function () {
    return availableCampTable.length;
};

export let nStopWaitTime = RandomInt(3, 8);
export const GetRuneActionTime = function () {
    return nStopWaitTime;
};

export const GetPositionForCM = function (bot: Unit) {
    let role: number | null = null;
    if (GetTeam() !== bot.GetTeam()) {
        role = GetEnemyPosition(bot.GetPlayerID());
        if (role != null) {
            return role;
        }
        // log("[WARNING] Cannot determine the role of an enemy bot. Return default pos as 3");
        // log("Stack Trace:", debug.traceback());
        return 3;
    }

    const lane = bot.GetAssignedLane();
    const heroName = bot.GetUnitName() as HeroName;

    if (lane === Lane.Mid) {
        role = 2;
    } else if (lane === Lane.Top) {
        if (bot.GetTeam() === Team.Radiant) {
            if (CanBeOfflaner(heroName)) {
                role = 3;
            } else {
                role = 4;
            }
        } else {
            if (CanBeSafeLaneCarry(heroName)) {
                role = 1;
            } else {
                role = 5;
            }
        }
    } else if (lane === Lane.Bot) {
        if (bot.GetTeam() === Team.Radiant) {
            if (CanBeSafeLaneCarry(heroName)) {
                role = 1;
            } else {
                role = 5;
            }
        } else {
            if (CanBeOfflaner(heroName)) {
                role = 3;
            } else {
                role = 4;
            }
        }
    }

    if (role == null) {
        role = 1;
        log("[ERROR] Failed to determine role for bot %s in CM. It got assigned lane#: %s. Set it to pos: %s", heroName, lane, role);
    }

    return role;
};

export const GetRoleFromId = function (bot: Unit) {
    const heroID = GetTeamPlayers(bot.GetTeam());
    const heroName = bot.GetUnitName();
    const team = bot.GetTeam() === Team.Radiant ? "TEAM_RADIANT" : "TEAM_DIRE";
    for (let i = 0; i < heroID.length; i++) {
        if (GetSelectedHeroName(heroID[i]) === heroName) {
            return RoleAssignment[team][i];
        }
    }
    return null;
};

export let HeroPositions: { [playerId: number]: number | null } = {};

// returns 1, 2, 3, 4, or 5 as the position of the hero in the team.
// For enemies, defers to GetEnemyPosition (estimated, not authoritative) —
// must run BEFORE any GetAssignedLane call to avoid the engine's "non-teammate" warning.
export const GetPosition = function (bot: Unit) {
    if (bot != null && bot.GetTeam() !== GetTeam()) {
        const eRole = GetEnemyPosition(bot.GetPlayerID());
        return eRole != null ? eRole : 3;
    }
    let role = bot.assignedRole;
    if (role == null && (GetGameMode() === GameMode.Cm || GetGameMode() === GameMode.ReverseCm)) {
        const [nH, _] = NumHumanBotPlayersInTeam(bot.GetTeam()); // assume it returns [number, number]
        if (nH === 0) {
            role = GetPositionForCM(bot);
        }
    }
    const playerId = bot.GetPlayerID();
    const unitName = bot.GetUnitName();

    // Lane change = !pos/!Xpos was applied by the engine. Invalidate caches
    // so the name-based / slot-based lookup below re-runs against the current
    // RoleAssignment. In online shared scope this picks up the new role; in
    // LAN sandbox it returns the same pre-swap role (unavoidable — mutation
    // doesn't cross sandbox boundaries). We deliberately do NOT call
    // GetPositionForCM here: it maps lane+hero suitability and collides when
    // two bots on the same lane both fail the suitability check (e.g. two
    // non-offlaners on offlane → both pos 4).
    const currentLane = bot.GetAssignedLane();
    if (bot.lastAssignedLane != null && bot.lastAssignedLane !== currentLane) {
        role = null;
        bot.assignedRole = null;
        if (playerId != null) {
            HeroPositions[playerId] = null;
        }
    }
    bot.lastAssignedLane = currentLane;

    if ((role == null || GetGameState() === GameState.PreGame) && playerId != null) {
        // HeroPositions is invalidated+updated by the lane-change path above
        // on any !pos / !Xpos swap (since the engine applies the new
        // tLaneAssignList, and bot:GetAssignedLane() reaches every scope
        // including LAN sandboxes). So trust the cache here.
        const cRole = HeroPositions[playerId];
        if (cRole != null) {
            role = cRole;
        } else {
            const heroID = GetTeamPlayers(bot.GetTeam());
            const team = bot.GetTeam() === Team.Radiant ? "TEAM_RADIANT" : "TEAM_DIRE";
            const heroName = bot.GetUnitName();
            // Prefer name-based lookup (honors
            // !pos / !Xpos swaps that hero_selection applies to RoleAssignment).
            // Only trust it when the roster is a full 5-player list — in LAN
            // per-bot sandboxes, GetTeamPlayers can return only the calling
            // bot, which would collapse every Dire bot to slot 1 → pos 1.
            if (heroID.length >= 5) {
                for (let i = 0; i < heroID.length; i++) {
                    if (GetSelectedHeroName(heroID[i]) === heroName) {
                        role = RoleAssignment[team][i];
                        break;
                    }
                }
            }
            // Sandbox / incomplete roster fallback: slot from PlayerID
            // (Radiant PIDs 0..4 → slot 1..5, Dire PIDs 5..9 → slot 1..5).
            // RoleAssignment is slot-keyed, so this still reflects any
            // !pos-driven swaps that reached the current scope.
            if (role == null) {
                const slot = bot.GetTeam() === Team.Radiant ? playerId + 1 : playerId - 4;
                if (slot >= 1 && slot <= 5) {
                    role = RoleAssignment[team][slot - 1];
                }
            }
            if (role != null) {
                HeroPositions[playerId] = role;
            }
        }
    }

    bot.assignedRole = role;

    if (role == null && GetGameState() !== GameState.PreGame) {
        role = GetPositionForCM(bot);
        log("[ERROR] Failed to match bot role for bot: %s, PlayerID: %s, fallback pos: %s", unitName, playerId, role);
        bot.assignedRole = role;
    }

    if (role == null) {
        // log("[ERROR] Failed to determine role for bot " + unitName + ". Set it to pos: 3.");
        role = 3;
    }

    return role;
};

export const IsPvNMode = function () {
    return IsAllShadow();
};

export const IsAllShadow = function () {
    return false;
};

// export const GetHighestValueRoles = function (bot: Unit) {
//     let maxVal = -1;
//     let role = "";
//     const heroName = bot.GetUnitName();
//     log("=========" + heroName + "=========");
//     const rolesForHero = export const hero_roles[heroName] || {};
//     for (const [key, value] of Object.entries(rolesForHero)) {
//         log(key + " : " + value);
//         const val = value as number;
//         if (val >= maxVal) {
//             maxVal = val;
//             role = key;
//         }
//     }

//     log("Highest value role => " + role + " : " + maxVal.toString());
// };
