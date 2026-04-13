--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
--- Cache Key Registry
-- Numeric keys for fast cache lookups (avoids string concat overhead).
-- Each function gets a base key. Per-bot caches add playerID (0-9).
-- Per-lane caches add lane (1=top, 2=mid, 3=bot).
-- Per-team caches add team (2=radiant, 3=dire).
-- 
-- Key formula: BASE + offset
-- Reserved range per function: 10 slots (enough for 10 players or 3 lanes + padding)
-- 
-- IMPORTANT: When adding new keys, use the next available multiple of 10.
-- Never reuse a key range. Both TS and Lua code import the compiled output.
-- 
-- Usage in TS:  import { CK } from "bots/FuncLib/systems/cache_keys";
-- Usage in Lua: local CK = require(GetScriptDirectory()..'/FuncLib/systems/cache_keys')
____exports.TEAM_FIGHT_LOCATION = 10
____exports.NUM_ALIVE_HEROES_ALLY = 20
____exports.NUM_ALIVE_HEROES_ENEMY = 21
____exports.IS_EARLY_GAME = 26
____exports.IS_MID_GAME = 27
____exports.IS_LATE_GAME = 28
____exports.IS_LANING_PHASE = 29
____exports.HAS_AEGIS = 30
____exports.IS_ROSHAN_ALIVE = 32
____exports.WE_ARE_STRONGER = 100
____exports.IS_IN_TEAM_FIGHT = 110
____exports.GET_HP = 120
____exports.GET_MP = 130
____exports.GET_POSITION = 140
____exports.HAS_HEALING_ITEM = 180
____exports.DEFEND_DESIRE = 200
____exports.PUSH_DESIRE = 210
____exports.GET_DEFEND_LANE_DESIRE = 220
____exports.GET_PUSH_LANE_DESIRE = 230
____exports.IS_BOT_THINKING_ACTION = 50000
____exports.COUNT_ENEMY_ON_HG = 60000
____exports.IS_TEAM_PUSHING_HG = 61000
____exports.HAS_CRITICAL_SPELL_CD = 62000
____exports.COUNT_MISSING_ENEMY = 63000
____exports.HAS_CRITICAL_ITEM_CD = 64000
____exports.NUM_TEAM_TOTAL_KILLS = 65000
____exports.IS_OTHER_ALLY_CAN_KILL = 66000
____exports.FURTHEST_BUILDING = 70000
____exports.NUM_ALIVE_HEROES_CACHED = 80000
____exports.PUSH_SPECIAL_CREEPS = 90000
return ____exports
