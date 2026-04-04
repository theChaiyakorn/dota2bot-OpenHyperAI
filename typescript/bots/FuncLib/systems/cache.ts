/**
 * Global Performance Cache System
 * Provides shared caching across all bot modules to reduce redundant API calls
 */

import { Lane, Team, Unit, UnitType, Vector } from "bots/ts_libs/dota";

interface GlobalCacheEntry {
    lastUpdate: number;
    data: any;
}

interface GlobalGameState {
    lastUpdate: number;
    currentTime: number;
    gameMode: number;
    team: Team;
    enemyTeam: Team;
    ourAncient: Unit | null;
    enemyAncient: Unit | null;
    aliveAllyCount: number;
    aliveEnemyCount: number;
    aliveAllyCoreCount: number;
    aliveEnemyCoreCount: number;
    teamNetworth: number;
    enemyNetworth: number;
    averageLevel: number;
    hasAegis: boolean;
    isEarlyGame: boolean;
    isMidGame: boolean;
    isLateGame: boolean;
    isLaningPhase: boolean;
}

interface GlobalUnitState {
    lastUpdate: number;
    enemyBuildings: Unit[];
    alliedHeroes: Unit[];
    enemyHeroes: Unit[];
    alliedCreeps: Unit[];
    enemyCreeps: Unit[];
}

interface GlobalLocationState {
    lastUpdate: number;
    laneFronts: Record<Lane, Vector>;
    teamFountain: Vector;
    enemyFountain: Vector;
    roshanLocation: Vector;
    tormentorLocation: Vector;
    tormentorWaitingLocation: Vector;
}

// Global cache storage — supports both string and numeric keys
const globalCache: Record<string | number, GlobalCacheEntry> = {};
const GLOBAL_CACHE_TTL = 0.5; // 500ms TTL for global cache

// Specific cache objects
let globalGameStateCache: GlobalGameState | null = null;
let globalUnitStateCache: GlobalUnitState | null = null;
let globalLocationStateCache: GlobalLocationState | null = null;

// Import Fu here to avoid circular dependencies
import * as Fu from "bots/FuncLib/func_utils";

/**
 * Get or update global game state cache
 */
export function getGlobalGameState(): GlobalGameState {
    const now = DotaTime();
    if (globalGameStateCache && now - globalGameStateCache.lastUpdate < GLOBAL_CACHE_TTL) {
        return globalGameStateCache;
    }

    const team = GetTeam();
    const enemyTeam = GetOpposingTeam();
    const currentTime = DotaTime();
    const gameMode = GetGameMode();

    // Adjust time for turbo mode
    const adjustedTime = gameMode === 23 ? currentTime * 2 : currentTime;

    const [teamNetworth, enemyNetworth] = Fu.GetInventoryNetworth();
    globalGameStateCache = {
        lastUpdate: now,
        currentTime: adjustedTime,
        gameMode,
        team,
        enemyTeam,
        ourAncient: GetAncient(team),
        enemyAncient: GetAncient(enemyTeam),
        aliveAllyCount: Fu.GetNumOfAliveHeroes(false),
        aliveEnemyCount: Fu.GetNumOfAliveHeroes(true),
        aliveAllyCoreCount: Fu.GetAliveCoreCount(false),
        aliveEnemyCoreCount: Fu.GetAliveCoreCount(true),
        teamNetworth: teamNetworth,
        enemyNetworth: enemyNetworth,
        averageLevel: Fu.GetAverageLevel(false),
        hasAegis: Fu.DoesTeamHaveAegis(),
        isEarlyGame: Fu.IsEarlyGame(),
        isMidGame: Fu.IsMidGame(),
        isLateGame: Fu.IsLateGame(),
        isLaningPhase: Fu.IsInLaningPhase(),
    };

    return globalGameStateCache;
}

/**
 * Get or update global unit state cache
 */
export function getGlobalUnitState(): GlobalUnitState {
    const now = DotaTime();
    if (globalUnitStateCache && now - globalUnitStateCache.lastUpdate < GLOBAL_CACHE_TTL) {
        return globalUnitStateCache;
    }

    // Import Fu here to avoid circular dependencies
    const Fu = require("bots/FuncLib/func_utils");

    globalUnitStateCache = {
        lastUpdate: now,
        enemyBuildings: GetUnitList(UnitType.EnemyBuildings),
        alliedHeroes: GetUnitList(UnitType.AlliedHeroes),
        enemyHeroes: GetUnitList(UnitType.Enemies).filter(u => Fu.IsValidHero(u)),
        alliedCreeps: GetUnitList(UnitType.AlliedCreeps),
        enemyCreeps: GetUnitList(UnitType.Enemies).filter(u => u.IsCreep() || u.IsAncientCreep()),
    };

    return globalUnitStateCache;
}

/**
 * Get or update global location state cache
 */
export function getGlobalLocationState(): GlobalLocationState {
    const now = DotaTime();
    if (globalLocationStateCache && now - globalLocationStateCache.lastUpdate < GLOBAL_CACHE_TTL) {
        return globalLocationStateCache;
    }

    // Import Fu here to avoid circular dependencies
    const Fu = require("bots/FuncLib/func_utils");

    const team = GetTeam();

    globalLocationStateCache = {
        lastUpdate: now,
        laneFronts: {
            [Lane.Top]: GetLaneFrontLocation(team, Lane.Top, 0),
            [Lane.Mid]: GetLaneFrontLocation(team, Lane.Mid, 0),
            [Lane.Bot]: GetLaneFrontLocation(team, Lane.Bot, 0),
        },
        teamFountain: Fu.GetTeamFountain(),
        enemyFountain: Fu.GetTeamFountain(), // Note: GetEnemyFountain doesn't exist
        roshanLocation: Fu.GetCurrentRoshanLocation(),
        tormentorLocation: Fu.GetTormentorLocation(team),
        tormentorWaitingLocation: Fu.GetTormentorWaitingLocation(team),
    };

    return globalLocationStateCache;
}

/**
 * Generic cache function for arbitrary data
 */
export function getCachedData<T>(key: string | number, ttl: number, fetchFn: () => T): T {
    const now = DotaTime();
    const cached = globalCache[key];

    if (cached && now - cached.lastUpdate < ttl) {
        return cached.data as T;
    }

    const data = fetchFn();
    globalCache[key] = {
        lastUpdate: now,
        data: data,
    };

    return data;
}

/**
 * Clear old cache entries to prevent memory leaks
 */
export function cleanupGlobalCache(): void {
    const now = DotaTime();
    const maxAge = 10; // 10 seconds max age

    Object.keys(globalCache).forEach(key => {
        if (now - globalCache[key].lastUpdate > maxAge) {
            delete globalCache[key];
        }
    });
}

/**
 * Clear all caches (useful for testing or when game state changes significantly)
 */
export function clearAllCaches(): void {
    Object.keys(globalCache).forEach(key => {
        delete globalCache[key];
    });
    globalGameStateCache = null;
    globalUnitStateCache = null;
    globalLocationStateCache = null;
}

/**
 * Get cached allies near location.
 * Now delegates to Fu.GetAlliesNearLoc which has its own function-level
 * cache (0.15s TTL with grid-snapped numeric keys). No extra caching needed here.
 */
export function getCachedAlliesNearLoc(location: Vector, radius: number): Unit[] {
    const Fu = require("bots/FuncLib/func_utils");
    return Fu.GetAlliesNearLoc(location, radius);
}

/**
 * Get cached enemies near location.
 * Delegates to Fu.GetEnemiesNearLoc which has its own function-level cache.
 */
export function getCachedEnemiesNearLoc(location: Vector, radius: number): Unit[] {
    const Fu = require("bots/FuncLib/func_utils");
    return Fu.GetEnemiesNearLoc(location, radius);
}

// Auto-cleanup every 30 seconds
let lastCleanupTime = 0;
export function autoCleanupCache(): void {
    const now = DotaTime();
    if (now - lastCleanupTime > 30) {
        cleanupGlobalCache();
        lastCleanupTime = now;
    }
}
