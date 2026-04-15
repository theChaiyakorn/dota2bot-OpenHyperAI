-- mode_laning_generic.lua (override for weak/buggy heroes)
local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils')

BotsInit = require( "game/botsinit" )
local X = BotsInit.CreateGeneric()

local bot = GetBot()

function X.OnStart() end
function X.OnEnd() end

local assignedLane
local tangoDesire, tangoTarget, tangoSlot
local fNextMovementTime = 0

function X.GetDesire()
	-- Bear: drop laning desire when hero is fighting — bear should join, not lane.
	local isBear = bot.isBear or string.find(bot:GetUnitName(), 'lone_druid_bear')
	if isBear then
		local Utils = require(GetScriptDirectory()..'/FuncLib/systems/utils')
		local ld = Utils.GetLoneDruid(bot)
		if ld and ld.hero and Fu.IsValidHero(ld.hero) and ld.hero:IsAlive() then
			local heroMode = ld.hero:GetActiveMode()
			-- Hero is doing something: bear should follow, not lane independently
			if heroMode == BOT_MODE_ATTACK
			or heroMode == BOT_MODE_DEFEND_ALLY
			or heroMode == BOT_MODE_TEAM_ROAM
			or heroMode == BOT_MODE_ROSHAN
			or heroMode == BOT_MODE_FARM then
				return BOT_MODE_DESIRE_NONE
			end
			-- Hero has an attack target nearby: bear should help
			local heroTarget = Fu.GetProperTarget(ld.hero)
			if Fu.IsValidHero(heroTarget) and GetUnitToUnitDistance(bot, heroTarget) < 1200 then
				return BOT_MODE_DESIRE_NONE
			end
		end
	end

	tangoDesire, tangoTarget = ConsiderTango()
	if tangoDesire > 0 then
		return BOT_MODE_DESIRE_ABSOLUTE
	end

	if not assignedLane then assignedLane = GetBotTargetLane() end

	if GetGameMode() == GAMEMODE_1V1MID or GetGameMode() == GAMEMODE_MO then return 1 end

	local currentTime = DotaTime()
	local botLV = bot:GetLevel()

	if GetGameMode() == 23 then currentTime = currentTime * 1.65 end
	if currentTime <= 10 then return 0.268 end
	if currentTime <= 9 * 60 and botLV <= 7 then return 0.446 end
	if currentTime <= 12 * 60 and botLV <= 11 then return 0.369 end
	if botLV <= 15 and Fu.GetCoresAverageNetworth() < 12000 then return 0.228 end

	return BOT_MODE_DESIRE_VERYLOW
end

function GetBotTargetLane()
	-- LAN: trust engine-assigned lane (reflects !pos in sandbox). Online:
	-- trust position-derived lane (stable against Valve's dynamic balancer,
	-- and correct post-!pos because shared scope sees the RoleAssignment
	-- update). Re-computed each tick — no sticky cache — so !pos swaps
	-- that reach us via position change are picked up promptly.
	if IsLanMode and IsLanMode() then
		local engineLane = bot:GetAssignedLane()
		if engineLane == LANE_TOP or engineLane == LANE_MID or engineLane == LANE_BOT then
			assignedLane = engineLane
			return assignedLane
		end
	end

	local pos = Fu.GetPosition(bot)
	if GetTeam() == TEAM_RADIANT then
		if pos == 2 then assignedLane = LANE_MID
		elseif pos == 1 or pos == 5 then assignedLane = LANE_BOT
		elseif pos == 3 or pos == 4 then assignedLane = LANE_TOP
		end
	else
		if pos == 2 then assignedLane = LANE_MID
		elseif pos == 1 or pos == 5 then assignedLane = LANE_TOP
		elseif pos == 3 or pos == 4 then assignedLane = LANE_BOT
		end
	end
	return assignedLane
end

function X.Think()
	if not bot:IsAlive() or Fu.CanNotUseAction(bot) or bot:IsChanneling() or bot:IsDisarmed() then return end

	local botAttackRange = bot:GetAttackRange()
	local botAssignedLane = assignedLane or bot:GetAssignedLane()
	local nAllyCreeps = bot:GetNearbyLaneCreeps(1200, false)
	local nEnemyCreeps = bot:GetNearbyLaneCreeps(1200, true)
	local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	local tEnemyTowers = bot:GetNearbyTowers(1200, true)

	-- Tango usage (local addition)
	if tangoDesire and tangoDesire > 0 and tangoTarget then
		local hItem = bot:GetItemInSlot(tangoSlot)
		bot:Action_UseAbilityOnTree(hItem, tangoTarget)
		return
	end

	-- Safety: retreat if being targeted by heroes, tower, or heavy creep damage.
	-- During laning: back off 500 toward base (don't run to fountain).
	if (bot:WasRecentlyDamagedByAnyHero(2.0) and #Fu.GetHeroesTargetingUnit(tEnemyHeroes, bot) >= 1)
	or (Fu.IsValidBuilding(tEnemyTowers[1]) and tEnemyTowers[1]:GetAttackTarget() == bot)
	or (bot:WasRecentlyDamagedByCreep(2.0) and not (bot:HasModifier('modifier_tower_aura') or bot:HasModifier('modifier_tower_aura_bonus')) and #nAllyCreeps > 0) then
		local safeLoc = Fu.AdjustLocationWithOffsetTowardsFountain(bot:GetLocation(), 500)
		bot:Action_MoveToLocation(safeLoc + RandomVector(50))
		return
	end

	-- Drop tower aggro
	if bot:WasRecentlyDamagedByTower(1.0) and #nEnemyCreeps > 0 then
		local nEnemyTowersClose = bot:GetNearbyTowers(750, true)
		if #nEnemyTowersClose > 0 then
			for _, creep in pairs(nEnemyCreeps) do
				if Fu.IsValid(creep) and GetUnitToUnitDistance(creep, nEnemyTowersClose[1]) < 700 then
					bot:Action_AttackUnit(creep, true)
					return
				end
			end
		end
	end

	-- Stay away from enemy tower if few creeps 
	if Fu.IsValidBuilding(tEnemyTowers[1]) then
		local dist = GetUnitToUnitDistance(bot, tEnemyTowers[1])
		if dist < 800 and #nEnemyCreeps < 3 then
			bot:Action_MoveToLocation(Fu.VectorAway(bot:GetLocation(), tEnemyTowers[1]:GetLocation(), 950) + RandomVector(75))
			return
		end
		-- Don't last-hit creeps that are under enemy tower unless safe
		if dist < 900 and bot:WasRecentlyDamagedByTower(2.0) then
			bot:Action_MoveToLocation(Fu.VectorAway(bot:GetLocation(), tEnemyTowers[1]:GetLocation(), 950))
			return
		end
	end

	-- Last-hit with support suppression
	-- Bear always last-hits freely — same player as hero, no CS conflict.
	local hitCreep = GetBestLastHitCreep(nEnemyCreeps)
	if Fu.IsValid(hitCreep) then
		local isBear = bot.isBear or string.find(bot:GetUnitName(), 'lone_druid_bear')
		local nLanePartner = Fu.GetLanePartner(bot)
		if isBear
		or nLanePartner == nil
		or Fu.IsCore(bot)
		or (not Fu.IsCore(bot) and Fu.IsCore(nLanePartner)
			and (not nLanePartner:IsAlive() or not Fu.IsInRange(bot, nLanePartner, 800)))
		then
			if GetUnitToUnitDistance(bot, hitCreep) > botAttackRange then
				bot:Action_MoveToUnit(hitCreep)
			else
				bot:Action_AttackUnit(hitCreep, true)
			end
			return
		end
	end

	-- Deny
	local denyCreep = GetBestDenyCreep(nAllyCreeps)
	if Fu.IsValid(denyCreep) then
		bot:Action_AttackUnit(denyCreep, true)
		return
	end

	-- Support harass: only when few enemy creeps nearby (low aggro risk)
	-- Bear never harasses — always prioritize last-hits
	local isBear = bot.isBear or string.find(bot:GetUnitName(), 'lone_druid_bear')
	local nCloseEnemyCreeps = bot:GetNearbyLaneCreeps(600, true)
	if #nCloseEnemyCreeps <= 1 and not Fu.IsCore(bot) and not isBear then
		local harassTarget = GetHarassTarget(tEnemyHeroes)
		if Fu.IsValidHero(harassTarget) then
			bot:Action_AttackUnit(harassTarget, true)
			return
		end
	end

	-- Positioning
	local nFurthestEnemyAttackRange = GetFurthestEnemyAttackRange(tEnemyHeroes)
	if nFurthestEnemyAttackRange == 0 then
		nFurthestEnemyAttackRange = math.max(botAttackRange, 330)
	end

	local fLaneFrontAmount = GetLaneFrontAmount(GetTeam(), botAssignedLane, false)
	local fLaneFrontAmount_enemy = GetLaneFrontAmount(GetOpposingTeam(), botAssignedLane, false)

	local target_loc = GetLaneFrontLocation(GetTeam(), botAssignedLane, -nFurthestEnemyAttackRange)
	if fLaneFrontAmount_enemy < fLaneFrontAmount then
		target_loc = GetLaneFrontLocation(GetOpposingTeam(), botAssignedLane, -nFurthestEnemyAttackRange)
	end

	if DotaTime() >= fNextMovementTime then
		bot:Action_MoveToLocation(target_loc + RandomVector(300))
		fNextMovementTime = DotaTime() + RandomFloat(0.05, 0.2)
	end
end

-- Helper functions
function GetBestLastHitCreep(hCreepList)
	local attackDamage = bot:GetAttackDamage()
	if bot:GetItemSlotType(bot:FindItemSlot("item_quelling_blade")) == ITEM_SLOT_TYPE_MAIN then
		if bot:GetAttackRange() > 310 or bot:GetUnitName() == "npc_dota_hero_templar_assassin" then
			attackDamage = attackDamage + 4
		else
			attackDamage = attackDamage + 8
		end
	end

	for _, creep in pairs(hCreepList) do
		if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
			local nDelay = Fu.GetAttackProDelayTime(bot, creep)
			if Fu.WillKillTarget(creep, attackDamage, DAMAGE_TYPE_PHYSICAL, nDelay) then
				return creep
			end
		end
	end
	return nil
end

function GetBestDenyCreep(hCreepList)
	for _, creep in pairs(hCreepList) do
		if Fu.IsValid(creep)
		and Fu.GetHP(creep) < 0.49
		and Fu.CanBeAttacked(creep)
		and creep:GetHealth() <= bot:GetAttackDamage()
		then
			return creep
		end
	end
	return nil
end

function GetHarassTarget(hEnemyList)
	for _, enemyHero in pairs(hEnemyList) do
		if Fu.IsValidHero(enemyHero)
		and Fu.IsInRange(bot, enemyHero, bot:GetAttackRange() + 150)
		and Fu.CanBeAttacked(enemyHero)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			return enemyHero
		end
	end
	return nil
end

function GetFurthestEnemyAttackRange(enemyList)
	local attackRange = 0
	for _, enemy in pairs(enemyList) do
		if Fu.IsValidHero(enemy) and not Fu.IsSuspiciousIllusion(enemy) then
			local enemyAttackRange = enemy:GetAttackRange()
			if enemyAttackRange > attackRange then
				attackRange = enemyAttackRange
			end
		end
	end
	return attackRange
end

function ConsiderTango()
	if bot:HasModifier('modifier_tango_heal') then return BOT_ACTION_DESIRE_NONE, nil end

	tangoDesire = 0
	tangoSlot = Fu.FindItemSlotNotInNonbackpack(bot, "item_tango")
	if tangoSlot < 0 then
		tangoSlot = Fu.FindItemSlotNotInNonbackpack(bot, "item_tango_single")
	end
	if tangoSlot >= 0
	and bot:OriginalGetMaxHealth() - bot:OriginalGetHealth() > 250
	and Fu.GetHP(bot) > 0.15
	and not Fu.IsAttacking(bot)
	and not bot:WasRecentlyDamagedByAnyHero(2) then
		local trees = bot:GetNearbyTrees(800)
		local targetTree = trees[1]
		local nearEnemyList = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE)
		local nearestEnemy = nearEnemyList[1]
		local nearTowerList = bot:GetNearbyTowers(1400, true)
		local nearestTower = nearTowerList[1]
		if targetTree ~= nil then
			local targetTreeLoc = GetTreeLocation(targetTree)
			if IsLocationVisible(targetTreeLoc)
			and IsLocationPassable(targetTreeLoc)
			and (#nearEnemyList == 0 or GetUnitToLocationDistance(bot, targetTreeLoc) * 1.6 < GetUnitToUnitDistance(bot, nearestEnemy))
			and (#nearTowerList == 0 or GetUnitToLocationDistance(nearestTower, targetTreeLoc) > 920)
			then
				return BOT_ACTION_DESIRE_HIGH, targetTree
			end
		end
	end
	return BOT_ACTION_DESIRE_NONE
end

return X
