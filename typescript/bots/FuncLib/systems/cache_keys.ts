/**
 * Cache Key Registry
 * Numeric keys for fast cache lookups (avoids string concat overhead).
 * Each function gets a base key. Per-bot caches add playerID (0-9).
 * Per-lane caches add lane (1=top, 2=mid, 3=bot).
 * Per-team caches add team (2=radiant, 3=dire).
 *
 * Key formula: BASE + offset
 * Reserved range per function: 10 slots (enough for 10 players or 3 lanes + padding)
 *
 * IMPORTANT: When adding new keys, use the next available multiple of 10.
 * Never reuse a key range. Both TS and Lua code import the compiled output.
 *
 * Usage in TS:  import { CK } from "bots/FuncLib/systems/cache_keys";
 * Usage in Lua: local CK = require(GetScriptDirectory()..'/FuncLib/systems/cache_keys')
 */

// Global (no offset needed)
export const TEAM_FIGHT_LOCATION = 10; // +team
export const NUM_ALIVE_HEROES_ALLY = 20;
export const NUM_ALIVE_HEROES_ENEMY = 21;
export const IS_EARLY_GAME = 26;
export const IS_MID_GAME = 27;
export const IS_LATE_GAME = 28;
export const IS_LANING_PHASE = 29;
export const HAS_AEGIS = 30;
export const IS_ROSHAN_ALIVE = 32;

// Per-bot (base + playerID 0-9)
export const WE_ARE_STRONGER = 100; // +playerID
export const IS_IN_TEAM_FIGHT = 110; // +playerID
export const GET_HP = 120; // +playerID
export const GET_MP = 130; // +playerID
export const GET_POSITION = 140; // +playerID
export const HAS_HEALING_ITEM = 180; // +playerID

// Per-lane (base + lane 1-3)
export const DEFEND_DESIRE = 200; // +lane
export const PUSH_DESIRE = 210; // +lane
export const GET_DEFEND_LANE_DESIRE = 220; // +lane
export const GET_PUSH_LANE_DESIRE = 230; // +lane

// Hardcoded keys in compiled Lua (DO NOT change — must match utils.lua/defend.lua)
export const IS_BOT_THINKING_ACTION = 50000; // +playerID*10+type (utils.lua)
export const COUNT_ENEMY_ON_HG = 60000; // +team (utils.lua)
export const IS_TEAM_PUSHING_HG = 61000; // +team (utils.lua)
export const HAS_CRITICAL_SPELL_CD = 62000; // +team (utils.ts)
export const COUNT_MISSING_ENEMY = 63000; // +team (utils.ts)
export const HAS_CRITICAL_ITEM_CD = 64000; // +team (utils.ts)
export const NUM_TEAM_TOTAL_KILLS = 65000; // +team (team_info.lua)
export const IS_OTHER_ALLY_CAN_KILL = 66000; // +targetPlayerID (combat.lua)
export const FURTHEST_BUILDING = 70000; // +team*10+lane (defend.ts)
export const NUM_ALIVE_HEROES_CACHED = 80000; // +team (team_info.lua)
export const PUSH_SPECIAL_CREEPS = 90000; // +playerID (push.ts)
