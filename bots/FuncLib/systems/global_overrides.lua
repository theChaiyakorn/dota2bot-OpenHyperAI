
-- macOS compatibility: Valve's VScript on Mac resolves require() paths differently.
-- Extend package.path to include the script directory so both path styles work.
if package and package.path then
	local scriptPath = GetScriptDirectory()
	if not string.find(package.path, scriptPath, 1, true) then
		package.path = package.path .. ";" .. scriptPath .. "/?.lua"
		package.path = package.path .. ";" .. scriptPath .. "/?/init.lua"
	end
end

local Utils = require( GetScriptDirectory()..'/FuncLib/systems/utils')

-- Fast check: should this bot skip all mode logic (illusions, invulnerable, dead).
-- The idle state check runs separately BEFORE this in mode files that need it.
function ShouldSkipBotThink(bot)
	return bot:IsInvulnerable()
		or not bot:IsHero()
		or not bot:IsAlive()
		or bot:IsIllusion()
end

-- Check and handle idle/stuck bots — runs BEFORE ShouldSkipBotThink so it
-- catches invulnerable fountain bots. Returns true if bot was idle and action taken.
function HandleIdleBotState(bot)
	local ok, result = pcall(function()
		return _HandleIdleBotStateInner(bot)
	end)
	if ok then return result end
	return false
end

function _HandleIdleBotStateInner(bot)
	if not bot:IsHero() or not bot:IsAlive() or bot:IsIllusion() then return false end

	-- Init per-bot state
	if bot._idleCheck == nil then
		bot._idleCheck = { lastTime = DotaTime(), lastPos = bot:GetLocation(), idleSince = 0 }
	end

	local state = bot._idleCheck
	local now = DotaTime()

	-- Only check every 1 second
	if now - state.lastTime < 1.0 then return false end
	state.lastTime = now

	local currentPos = bot:GetLocation()
	if not currentPos then return false end
	local dist = GetUnitToLocationDistance(bot, state.lastPos)
	state.lastPos = currentPos

	-- Bot hasn't moved more than 50 units in 1 second
	if dist < 50 and bot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE then
		if state.idleSince == 0 then
			state.idleSince = now
		end

		local idleDuration = now - state.idleSince

		-- Idle in fountain for > 3 seconds after spawn — move to lane
		if bot:IsInvulnerable() and bot:DistanceFromFountain() < 500 and idleDuration > 3 then
			local lane = bot:GetAssignedLane() or LANE_MID
			local laneFront = GetLaneFrontLocation(GetTeam(), lane, 0)
			bot:Action_MoveToLocation(laneFront)
			state.idleSince = 0
			return true
		end

		-- Idle anywhere for > 5 seconds — move to assigned lane
		if idleDuration > 5 and not bot:IsInvulnerable() then
			local lane = bot:GetAssignedLane() or LANE_MID
			local laneFront = GetLaneFrontLocation(GetTeam(), lane, 0)
			bot:Action_MoveToLocation(laneFront)
			state.idleSince = 0
			return true
		end
	else
		state.idleSince = 0
	end

	return false
end

-- 7.41 new bot mode constants (not yet defined by Valve)
if BOT_MODE_WATCHER == nil then BOT_MODE_WATCHER = 28 end
if BOT_MODE_WISDOM_SHRINE == nil then BOT_MODE_WISDOM_SHRINE = 29 end
if BOT_MODE_LOTUS_POOL == nil then BOT_MODE_LOTUS_POOL = 30 end

-- 7.41 patch: Valve capped attack mode desire at ~0.65.
-- Redefine desire constants to compressed range so custom modes compete
-- properly with Valve's built-in modes. Non-overridden modes (Valve's)
-- still use [0,1] internally but our modes now stay within [0,0.7].
BOT_MODE_DESIRE_NONE 		= 0
BOT_MODE_DESIRE_VERYLOW 	= 0.05
BOT_MODE_DESIRE_LOW 		= 0.175
BOT_MODE_DESIRE_MODERATE 	= 0.35
BOT_MODE_DESIRE_HIGH		= 0.525
BOT_MODE_DESIRE_VERYHIGH 	= 0.6
BOT_MODE_DESIRE_ABSOLUTE 	= 0.7

-- Original uncapped absolute (1.0). Use this for override desires that must bypass
-- the GetAdjustedDesireValue cap, e.g. BOT_DESIRE_OVERRIDE * 1.1 = 1.1 > 1.0.
BOT_DESIRE_OVERRIDE = 1.0

-- Cap desire at BOT_MODE_DESIRE_ABSOLUTE without remapping.
-- Values > 1 are left untouched (intentional override desires like BOT_DESIRE_OVERRIDE * 1.1).
function GetAdjustedDesireValue(num)
	if num < 1 then return RemapValClamped(num, 0, 1, 0, BOT_MODE_DESIRE_ABSOLUTE) end
	return num
end

-- Nil-safe ability proxy: when GetAbilityByName returns nil (ability removed/renamed/innate),
-- calling :IsFullyCastable() etc. on nil crashes the entire SkillsComplement.
-- This proxy returns safe fallback values so the hero's other abilities still work.
-- Usage: local abilityQ = SafeAbility(bot:GetAbilityByName('some_ability'))
--        abilityQ:IsFullyCastable() returns false instead of crashing
_G.NIL_ABILITY = {}
setmetatable(_G.NIL_ABILITY, { __index = function(_, key)
	local falseMethods = {
		IsFullyCastable=true, IsTrained=true, IsHidden=true, IsActivated=true,
		IsStealable=true, IsInAbilityPhase=true, IsChanneling=true, IsUltimate=true,
	}
	if falseMethods[key] then return function() return false end end
	local zeroMethods = {
		GetLevel=true, GetCastRange=true, GetCastPoint=true, GetManaCost=true,
		GetCooldown=true, GetCooldownTimeRemaining=true, GetDuration=true,
		GetAbilityDamage=true, GetSpecialValueInt=true, GetSpecialValueFloat=true,
		GetCurrentCharges=true, GetToggleState=true, GetAutoCastState=true,
	}
	if zeroMethods[key] then return function() return 0 end end
	return function() return nil end
end })

function SafeAbility(ability, abilityName, heroName)
	if ability == nil then
		if abilityName then
			log('[WARN] %s ability "%s" is nil (removed/renamed/innate?) — using safe proxy', heroName or 'unknown', abilityName)
		end
		return _G.NIL_ABILITY
	end
	return ability
end

-- Override this func for the script to use
local orig_GetTeamPlayers = GetTeamPlayers
local direTeamPlaters = nil
function GetTeamPlayers(nTeam, bypass)
	if bypass then return orig_GetTeamPlayers(nTeam) end
	-- local cacheKey = 'GetTeamPlayers'..tostring(nTeam)
	-- local cache = Utils.GetCachedVars(cacheKey, 5)
	-- if cache ~= nil then return cache end

	local nIDs = orig_GetTeamPlayers(nTeam)
	if nTeam == TEAM_DIRE then
		if direTeamPlaters ~= nil then
			return direTeamPlaters
		end
		
		local sHuman = {}
		for idx, id in pairs(nIDs) do
			if not IsPlayerBot(id)
			then
				table.insert(sHuman, id)
			end
		end

		if #sHuman > 0 then
			local nBotIDs = {5, 6, 7, 8, 9}
			nIDs = {}

			for i = 1, #nBotIDs do table.insert(nIDs, nBotIDs[i]) end

			-- Map it directly
			for i = 1, #sHuman do
				for j = 1, 5 do
					if sHuman[i] + 5 == nBotIDs[j]
					then
						nIDs[j] = sHuman[i]
					end
				end
			end

			-- "Shift" > 4
			for i = #nIDs, 1, -1 do
				local hCount = 0
				if nIDs[i] > 4 then
					for j = 1, #nIDs do
						if nIDs[j + i] ~= nil and nIDs[j + i] < 5 then
							hCount = hCount + 1
						end
					end
					nIDs[i] = nIDs[i] + hCount
				end
			end
		end
		direTeamPlaters = nIDs
	end
	-- Utils.SetCachedVars(cacheKey, nIDs)
	return nIDs
end

-- Debug logging. Replaces print() across the codebase.
-- Usage: log('[FARM] %s t=%.0f', bot:GetUnitName(), DotaTime())
-- For hot paths, wrap in "if IsDebug then log(...) end" to skip argument evaluation.
local orig_print = print
IsDebug = Utils.DebugMode
function log(fmt, ...)
    if not IsDebug then return end
    if select('#', ...) == 0 then
        orig_print(fmt)
    else
        orig_print(string.format(fmt, ...))
    end
end

-- Safe function wrapper: catches errors, logs them, returns fallback value.
-- Usage: local safeGetDesire = SafeCall(GetDesireHelper, 0, 'FarmDesire')
--        local result = safeGetDesire()
-- Or wrap inline: SafeCall(fn, fallback, label)(args...)
-- For wrapping mode GetDesire/Think: wrap once at file load, use everywhere.
function SafeCall(fn, fallback, label)
    return function(...)
        local ok, a, b, c = pcall(fn, ...)
        if ok then return a, b, c end
        local botName = ''
        pcall(function() botName = GetBot():GetUnitName() .. ' ' end)
        log('[ERROR] %s%s: %s', botName, label or 'unknown', tostring(a))
        return fallback
    end
end

local original_GetUnitToUnitDistance = GetUnitToUnitDistance
function GetUnitToUnitDistance(unit1, unit2)
	if not unit1 then
		return 1000
	end
	if unit2 == nil or (pcall(function() return unit2:GetLocation() end) == false) then
		return 1000
	end
	return original_GetUnitToUnitDistance(unit1, unit2)
end

local originalWasRecentlyDamagedByAnyHero = CDOTA_Bot_Script.WasRecentlyDamagedByAnyHero
function CDOTA_Bot_Script:WasRecentlyDamagedByAnyHero(fInterval)
    if not self:IsHero() then
		-- log("WasRecentlyDamagedByAnyHero has been called on non hero")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end
    return originalWasRecentlyDamagedByAnyHero(self, fInterval)
end

local originalGetNearbyTowers = CDOTA_Bot_Script.GetNearbyTowers
function CDOTA_Bot_Script:GetNearbyTowers(nRadius, bEnemies)
    if not self:IsHero() then
		-- log("GetNearbyTowers has been called on non hero")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end
    return originalGetNearbyTowers(self, math.min(nRadius, 1600), bEnemies)
end

local originalIsIllusion = CDOTA_Bot_Script.IsIllusion
function CDOTA_Bot_Script:IsIllusion()
    if not self:IsHero() then
		-- log("IsIllusion has been called on non hero")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end
    if not self:CanBeSeen() then
		-- log("IsIllusion has been called on non hero")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end

	-- TODO: add is-teammate check.
    return originalIsIllusion(self)
end

local originalHasModifier = CDOTA_Bot_Script.HasModifier
function CDOTA_Bot_Script:HasModifier(sModifierName)
    if not self:CanBeSeen() then
		return false
		-- log("HasModifier has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
	end
    -- if not self:IsHero() then
	-- 	print("HasModifier has been called on non hero")
	-- 	print("Stack Trace:", debug.traceback())
	-- end
    return originalHasModifier(self, sModifierName)
end

local originalGetLocation = CDOTA_Bot_Script.GetLocation
function CDOTA_Bot_Script:GetLocation()
    if self == nil or (not self:IsBuilding() and not self:CanBeSeen()) then
		return nil
		-- log("GetLocation has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
	end
    return originalGetLocation(self)
end
local originalGetMagicResist = CDOTA_Bot_Script.GetMagicResist
function CDOTA_Bot_Script:GetMagicResist()
    if self == nil or not self:CanBeSeen() then
		return 1
		-- log("GetMagicResist has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
	end
    return originalGetMagicResist(self)
end

local originalIsInvulnerable = CDOTA_Bot_Script.IsInvulnerable
function CDOTA_Bot_Script:IsInvulnerable()
    if not self:CanBeSeen() then
		-- log("IsInvulnerable has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return false
	end
	if self:HasModifier('modifier_dazzle_nothl_projection_soul_debuff') then
		return false
	end
    return originalIsInvulnerable(self)
end

local originalIsAttackImmune = CDOTA_Bot_Script.IsAttackImmune
function CDOTA_Bot_Script:IsAttackImmune()
    if not self:CanBeSeen() then
		-- log("IsAttackImmune has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return false
	end
    return originalIsAttackImmune(self)
end

local originalIsUsingAbility = CDOTA_Bot_Script.IsUsingAbility
function CDOTA_Bot_Script:IsUsingAbility()
    if not self:CanBeSeen() or not self:IsHero() then
		-- log("IsUsingAbility has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return false
	end
    return originalIsUsingAbility(self)
end

local originalIsChanneling = CDOTA_Bot_Script.IsChanneling
function CDOTA_Bot_Script:IsChanneling()
    if not self:CanBeSeen() then
		-- log("IsChanneling has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return false
	end
    return originalIsChanneling(self)
end

local originalGetAttackTarget = CDOTA_Bot_Script.GetAttackTarget
function CDOTA_Bot_Script:GetAttackTarget()
    if not self:CanBeSeen() then
		-- log("GetAttackTarget has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end
    return originalGetAttackTarget(self)
end

local originalGetNearbyHeroes = CDOTA_Bot_Script.GetNearbyHeroes
function CDOTA_Bot_Script:GetNearbyHeroes(nRadius, bEnemies, nMode)
    if not self:CanBeSeen() then
		-- log("GetNearbyHeroes has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end
    return originalGetNearbyHeroes(self, math.min(nRadius, 1600), bEnemies, nMode)
end

local originalIsMagicImmune = CDOTA_Bot_Script.IsMagicImmune
function CDOTA_Bot_Script:IsMagicImmune()
	if not self then return false end
	-- local cacheKey = 'IsMagicImmune'..self:GetUnitName()
	-- local cache = Utils.GetCachedVars(cacheKey, 0.15)
	-- if cache ~= nil then return cache end

	if self:CanBeSeen() then
        if originalIsMagicImmune(self)
        or self:HasModifier('modifier_magic_immune')
        or self:HasModifier('modifier_juggernaut_blade_fury')
        or self:HasModifier('modifier_life_stealer_rage')
        or self:HasModifier('modifier_black_king_bar_immune')
        or self:HasModifier('modifier_huskar_life_break_charge')
        or self:HasModifier('modifier_grimstroke_scepter_buff')
        or self:HasModifier('modifier_pangolier_rollup')
        or self:HasModifier('modifier_lion_mana_drain_immunity')
        or self:HasModifier('modifier_dawnbreaker_fire_wreath_magic_immunity_tooltip')
        or self:HasModifier('modifier_rattletrap_cog_immune')
        or self:HasModifier('modifier_legion_commander_press_the_attack_immunity')
        then
			-- Utils.SetCachedVars(cacheKey, true)
            return true
        end
    end
	-- Utils.SetCachedVars(cacheKey, false)
    return false
end

local o_RandomFloat = RandomFloat
local epsilon = 0.00000001
function RandomFloat(fMin, fMax)
	return fMin + math.random() * (fMax - fMin + epsilon)
end

local originalGetNearbyNeutralCreeps = CDOTA_Bot_Script.GetNearbyNeutralCreeps
function CDOTA_Bot_Script:GetNearbyNeutralCreeps( nRadius)
    return originalGetNearbyNeutralCreeps(self, math.min(nRadius, 1600))
end

local originalGetNearbyLaneCreeps = CDOTA_Bot_Script.GetNearbyLaneCreeps
function CDOTA_Bot_Script:GetNearbyLaneCreeps( nRadius, bEnemies)
    -- if not self or not self:IsBot() then
	-- 	print("GetNearbyLaneCreeps has been called on unit is not a bot")
	-- 	print("Stack Trace:", debug.traceback())
	-- 	return nil
	-- end
    return originalGetNearbyLaneCreeps(self, math.min(nRadius, 1600), bEnemies)
end

local originalGetNearbyCreeps = CDOTA_Bot_Script.GetNearbyCreeps
function CDOTA_Bot_Script:GetNearbyCreeps( nRadius, bEnemies)
    return originalGetNearbyCreeps(self, math.min(nRadius, 1600), bEnemies)
end

local originalGetUnitName = CDOTA_Bot_Script.GetUnitName
function CDOTA_Bot_Script:GetUnitName()
	local uName = originalGetUnitName(self)
	if string.find( uName, "lone_druid_bear" ) then
		uName = 'npc_dota_hero_lone_druid_bear'
	end
	return uName
end

-- Override GetCastRange to include item/ability cast range bonuses
-- that Valve's API doesn't account for
local o_GetCastRange = CDOTABaseAbility_BotScript.GetCastRange
function CDOTABaseAbility_BotScript:GetCastRange()
	local bot = GetBot()

	if self then
		local nCastRange = self:GetSpecialValueInt('AbilityCastRange')
		if nCastRange == 0 then
			nCastRange = o_GetCastRange(self)
		end

		if bot then
			-- Hero ability cast range bonuses
			for i = 0, 7 do
				local hAbility = bot:GetAbilityInSlot(i)
				if hAbility and hAbility:IsTrained() then
					local sAbilityName = hAbility:GetName()
					if sAbilityName == 'keeper_of_the_light_spirit_form' then
						if bot:HasModifier('modifier_keeper_of_the_light_spirit_form') then
							nCastRange = nCastRange + hAbility:GetSpecialValueInt('cast_range')
						end
					elseif sAbilityName == 'rubick_arcane_supremacy' then
						nCastRange = nCastRange + hAbility:GetSpecialValueInt('cast_range')
					end
				end
			end

			-- Item cast range bonuses (main inventory + neutral slot)
			local itemSlots = { 0, 1, 2, 3, 4, 5, 16, 17 }
			for i = 1, #itemSlots do
				local hItem = bot:GetItemInSlot(itemSlots[i])
				if hItem then
					local sItemName = hItem:GetName()
					if sItemName == 'item_aether_lens' then
						nCastRange = nCastRange + hItem:GetSpecialValueInt('cast_range_bonus')
					elseif sItemName == 'item_ethereal_blade' then
						nCastRange = nCastRange + hItem:GetSpecialValueInt('bonus_cast_range')
					elseif sItemName == 'item_magnifying_monocle' then
						nCastRange = nCastRange + hItem:GetSpecialValueInt('bonus_cast_range')
					elseif sItemName == 'item_enhancement_keen_eyed' then
						nCastRange = nCastRange + hItem:GetSpecialValueInt('cast_range_bonus')
					elseif sItemName == 'item_enhancement_mystical' then
						nCastRange = nCastRange + hItem:GetSpecialValueInt('bonus_cast_range')
					elseif sItemName == 'item_enhancement_boundless' then
						nCastRange = nCastRange + hItem:GetSpecialValueInt('bonus_cast_range')
					elseif string.find(sItemName, 'item_dagon') then
						-- Dagon cast range bonus only if no aether lens (they don't stack)
						local bHasAether = false
						for j = 0, 5 do
							local hItem2 = bot:GetItemInSlot(j)
							if hItem2 and hItem2 ~= hItem and string.find(hItem2:GetName(), 'item_aether_lens') then
								bHasAether = true
								break
							end
						end
						if not bHasAether then
							nCastRange = nCastRange + hItem:GetSpecialValueInt('cast_range_bonus')
						end
					end
				end
			end
		end

		return nCastRange
	end

	return o_GetCastRange(self)
end

local originalGetAbilityByName = CDOTA_Bot_Script.GetAbilityByName
function CDOTA_Bot_Script:GetAbilityByName(sAbilityName)
	if sAbilityName == nil or sAbilityName == '' then
		return nil
	end
	return originalGetAbilityByName(self, sAbilityName)
end

local originalFindAbilityByName = FindAbilityByName
if originalFindAbilityByName then
	function FindAbilityByName(sAbilityName)
		if sAbilityName == nil or sAbilityName == '' then
			return nil
		end
		return originalFindAbilityByName(sAbilityName)
	end
end

local originalAction_UseAbility = CDOTA_Bot_Script.Action_UseAbility
function CDOTA_Bot_Script:Action_UseAbility(hAbility)
    if hAbility == nil or hAbility:IsHidden() then
		log("[WARN] Action_UseAbility called on nil/hidden ability for %s", self:GetUnitName())
		return nil
	end
    return originalAction_UseAbility(self, hAbility)
end

local originalActionPush_UseAbility = CDOTA_Bot_Script.ActionPush_UseAbility
function CDOTA_Bot_Script:ActionPush_UseAbility(hAbility)
    if hAbility == nil or hAbility:IsHidden() then
		log("[WARN] ActionPush_UseAbility called on nil/hidden ability for %s", self:GetUnitName())
		return nil
	end
    return originalActionPush_UseAbility(self, hAbility)
end

-- local originalAction_AttackUnit = CDOTA_Bot_Script.Action_AttackUnit
-- function CDOTA_Bot_Script:Action_AttackUnit(hUnit, bOnce)
--     if hUnit:GetUnitName() == 'npc_dota_warlock_minor_imp' then
-- 		print("Action_AttackUnit has been called on entity npc_dota_warlock_minor_imp")
-- 		print("Stack Trace:", debug.traceback())
-- 		return nil
-- 	end
--     return originalAction_AttackUnit(self, hUnit, bOnce)
-- end

local originalGetTarget = CDOTA_Bot_Script.GetTarget
function CDOTA_Bot_Script:GetTarget()
    if not self or not self:IsBot() then
		-- log("GetTarget has been called on unit is not a bot")
		-- log("Stack Trace:", debug.traceback())
		return nil
	end
    return originalGetTarget(self)
end

local originalGetAttackRange = CDOTA_Bot_Script.GetAttackRange
function CDOTA_Bot_Script:GetAttackRange()
    if not self:CanBeSeen() then
		-- log("GetAttackRange has been called on unit can't be seen")
		-- log("Stack Trace:", debug.traceback())
		return 200
	end
    return originalGetAttackRange(self)
end

-- local original_Action_AttackMove = CDOTA_Bot_Script.Action_AttackMove
-- function CDOTA_Bot_Script:Action_AttackMove(vLocation)
-- 	if self.isBuggyHero == nil then
-- 		self.isBuggyHero = Utils.BuggyHeroesDueToValveTooLazy[self:GetUnitName()] ~= nil
-- 	end
-- 	if self.isBuggyHero
-- 	then
-- 		self:Action_ClearActions(true);
-- 		print('Override buggy hero movement, make it go assigned lane front with Action_AttackMove.'..self:GetUnitName())
-- 		local assignedLaneLoc = GetLaneFrontLocation(GetTeam(), self:GetAssignedLane(), 0)
-- 		if Utils.GetLocationToLocationDistance(assignedLaneLoc, vLocation) > 1000 and DotaTime() < 2*60 then
-- 			return original_Action_AttackMove(self, assignedLaneLoc )
-- 		end
-- 	end
--     return original_Action_AttackMove(self, vLocation )
-- end


-- CDOTA_AttackRecordManager::GetRecordByIndex - Could not find attack record (-1)!
-- local originalGetRecordByIndex = CDOTA_AttackRecordManager.GetRecordByIndex
-- function CDOTA_AttackRecordManager:GetRecordByIndex(idx)
--     if idx < 0 then
-- 		print("GetRecordByIndex has been called on unit can't be seen")
-- 		print("Stack Trace:", debug.traceback())
-- 	end
--     return originalGetRecordByIndex(self)
-- end

local originalActionImmediate_SwapItems = CDOTA_Bot_Script.ActionImmediate_SwapItems
local itemSwapGapTime = 6 + 5 -- 6s item cd after swap, 5s delta time for item usage reaction.
function CDOTA_Bot_Script:ActionImmediate_SwapItems(intnSlot1, intnSlot2)
	local unitName = self:GetUnitName()
	-- log(unitName.." swaps items: "..tostring(intnSlot1)..', '..tostring(intnSlot2))
	if self.itemSwapTime == nil then
		self.itemSwapTime = 0
	end
	-- log("ActionImmediate_SwapItems has been called on unit: "..unitName)
	-- log("Stack Trace:", debug.traceback())
	if #(self:GetNearbyHeroes(1000, true, BOT_MODE_NONE) or {}) == 0 and DotaTime() - self.itemSwapTime > itemSwapGapTime then
		self.itemSwapTime = DotaTime()
		return originalActionImmediate_SwapItems(self, intnSlot1, intnSlot2)
	else
		-- log('[WARN] '..unitName..' failed to swap items due to trying too frequently.')
	end
    return nil
end

local originalGetUnitToLocationDistance = CDOTA_Bot_Script.GetUnitToLocationDistance
-- Override the GetUnitToLocationDistance function with caching
function CDOTA_Bot_Script:GetUnitToLocationDistance(unit, location)
    if location == nil then
		log("[WARN] GetUnitToLocationDistance nil location for %s", self:GetUnitName())
		return 200
	end
    return originalGetUnitToLocationDistance(self, unit, location)
end

local original_GetHealth = CDOTA_Bot_Script.GetHealth
function CDOTA_Bot_Script:GetHealth()
    if self == nil or not self:CanBeSeen() then
		return 666
	end

	local nCurHealth = original_GetHealth(self)
    if self ~= nil and self:GetUnitName() == 'npc_dota_hero_medusa' and nCurHealth > 0
    then
		local mana = self:GetMana()
		-- Assuming max level Mana Shield (95% absorption and 2.5 damage absorbed per point of mana)
		local manaAbsorptionRate = 0.95
		if self:GetLevel() < 12 then manaAbsorptionRate = 0.5 end -- workaround e.g. to not retreat too often due to low mana.
		local damagePerMana = 2.6
		-- Calculate how much damage her current mana can absorb
		local manaEffectiveHP = mana * damagePerMana * manaAbsorptionRate
		-- Effective HP is her base HP plus the effective HP from her mana shield
		return nCurHealth + manaEffectiveHP
    end
    return nCurHealth
end

local originalGetMaxHealth = CDOTA_Bot_Script.GetMaxHealth
function CDOTA_Bot_Script:GetMaxHealth()
    if self ~= nil and self:GetUnitName() == 'npc_dota_hero_medusa'
    then
		-- Assuming max level Mana Shield (95% absorption and 2.5 damage absorbed per point of mana)
		local manaAbsorptionRate = 0.95
		if self:GetLevel() < 12 then manaAbsorptionRate = 0.5 end -- workaround e.g. to not retreat too often due to low mana.
		local damagePerMana = 2.6
		local maxManaEffectiveHP = self:GetMaxMana() * damagePerMana * manaAbsorptionRate
		-- Total max effective HP
        return originalGetMaxHealth(self) + maxManaEffectiveHP
    end
    return originalGetMaxHealth(self)
end
function CDOTA_Bot_Script:OriginalGetHealth()
    return original_GetHealth(self)
end
function CDOTA_Bot_Script:OriginalGetMaxHealth()
    return originalGetMaxHealth(self)
end

local originalGetMana = CDOTA_Bot_Script.GetMana
function CDOTA_Bot_Script:GetMana()
    if self ~= nil and (self:GetUnitName() == 'npc_dota_hero_huskar')
    then
        return 0
    end
    return originalGetMana(self)
end
local originalGetMaxMana = CDOTA_Bot_Script.GetMaxMana
function CDOTA_Bot_Script:GetMaxMana()
    if self ~= nil and (self:GetUnitName() == 'npc_dota_hero_huskar')
    then
        return 0
    end
    return originalGetMaxMana(self)
end

local X = {
	orig_GetTeamPlayers = orig_GetTeamPlayers,
	GetTeamPlayers = GetTeamPlayers
}

return X