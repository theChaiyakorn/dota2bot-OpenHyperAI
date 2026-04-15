/**
 * Type declarations for bots/FuncLib/func_utils.lua
 * Mirrors the Fu table: sub-module references + mixin functions from general_utils/.
 */
import { BotMode, Lane, Ping, Talent, Team, Unit, Vector } from "bots/ts_libs/dota";
import { BotRole, TalentTreeBuild } from "bots/ts_libs/bots";
import * as Util from "bots/FuncLib/systems/utils";

// Sub-modules (Fu.Site, Fu.Item, etc.)
export const Site: any;
export const Item: { /** @noSelf */ GetRoleItemsBuyList(bot: Unit): BotRole };
export const Buff: any;
export const Role: any;
export const Skill: {
    /** @noSelf */ GetRandomBuild(builds: number[][]): number[];
    /** @noSelf */ GetTalentBuild(talents: TalentTreeBuild): number[];
    /** @noSelf */ GetTalentList(bot: Unit): Talent[];
    /** @noSelf */ GetAbilityList(bot: Unit): string[];
    /** @noSelf */ GetSkillList(abilities: string[], abilityBuild: number[], talentList: Talent[], talentBuild: number[]): string[];
};
export const Chat: any;
export const Utils: typeof Util;
export const Customize: any;

// Mixin functions from general_utils/ — only those actually used by TS files

// unit_check
export function IsValid(target: any): boolean;
export function IsValidHero(unit: any): boolean;
export function IsValidBuilding(unit: any): boolean;
export function CanBeAttacked(unit: Unit): boolean;
export function IsSuspiciousIllusion(unit: Unit): boolean;
export function IsMeepoClone(unit: any): boolean;
export function IsTormentor(unit: any): boolean;
export function IsRoshan(unit: any): boolean;
export function IsInRange(unit: any, target: any, range: number): boolean;
export function CanCastAbility(ability: any): boolean;

// hero_state
export function GetHP(bot: Unit): number;
export function GetMP(bot: Unit): number;
export function IsRetreating(bot: Unit): boolean;
export function IsGoingOnSomeone(bot: Unit): boolean;
export function IsDefending(bot: Unit): boolean;
export function IsDoingRoshan(bot: Unit): boolean;
export function IsRoshanAlive(): boolean;
export function IsDoingTormentor(bot: Unit): boolean;
export function CanNotUseAbility(bot: Unit): boolean;
export function CanNotUseAction(bot: Unit): boolean;
export function TryDropTowerAggro(bot: Unit): boolean;
export function TryDenyTower(bot: Unit): boolean;
export function TryDenyAllyHero(bot: Unit): boolean;
export function HasDamageOverTimeDebuff(bot: Unit): boolean;
export function IsCore(unit: any): boolean;
export function GetPosition(bot: Unit | null): number;
export function GetExpectedLane(bot: Unit): Lane;
export function IsChasingTarget(unit: any, target: any): boolean;

// combat
export function WeAreStronger(bot: Unit, radius: number): boolean;
export function IsInTeamFight(bot: Unit, radius: number): boolean;
export function GetRetreatingAlliesNearLoc(location: Vector, radius: number): Unit[];

// targeting
export function GetProperTarget(bot: Unit): Unit;
export function GetNearbyHeroes(unit: Unit, radius: number, includeEnemies: boolean, mode: BotMode): Unit[];
export function GetItem(bot: Unit, itemName: string): any;
export function GetItem2(bot: Unit, itemName: string): any;

// positioning
export function GetTeamFountain(): Vector;
export function AdjustLocationWithOffsetTowardsFountain(vector: Vector, distance: number): Vector;
export function RandomForwardVector(distance: number): Vector;
export function GetDistance(location1: Vector, location2: Vector): number;
export function GetRandomLocationWithinDist(location: Vector, minDist: number, maxDist: number): Vector;

// team_info
export function GetAlliesNearLoc(location: Vector, radius: number): Unit[];
export function GetEnemiesNearLoc(location: Vector, radius: number): Unit[];
export function GetLastSeenEnemiesNearLoc(location: Vector, radius: number): Unit[];
export function GetNumOfAliveHeroes(isEnemy: boolean): number;
export function GetNumOfTeamTotalKills(isEnemy: boolean): number;
export function GetAliveCoreCount(isEnemy: boolean): number;
export function GetEnemiesAroundLoc(location: Vector, radius: number): number;
export function GetHumanPing(): LuaMultiReturn<[any, any]>;
export function DoesTeamHaveAegis(): boolean;
export function GetAverageLevel(bEnemy: boolean): number;
export function GetInventoryNetworth(): LuaMultiReturn<[any, any]>;

// bot_mode
export function IsPingCloseToValidTower(team: Team, ping: Ping, radius: number, duration: number): LuaMultiReturn<[false, null] | [true, Lane]>;
export function IsAnyAllyDefending(bot: Unit, lane: Lane): boolean;

// map_info
export function GetCurrentRoshanLocation(): Vector;
export function GetTormentorLocation(team: Team): Vector;
export function GetTormentorWaitingLocation(team: Team): Vector;

// lane_strategy
export function IsInLaningPhase(): boolean;
export function IsEarlyGame(): boolean;
export function IsMidGame(): boolean;
export function IsLateGame(): boolean;
