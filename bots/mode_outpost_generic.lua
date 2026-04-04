local bot = GetBot()
local botName = bot:GetUnitName()
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils')
local Customize = require( GetScriptDirectory()..'/Customize/general' )

local Outposts = {}
local DidWeGetOutpost = false
local ClosestOutpost = nil
local ClosestOutpostDist = 10000

local IsEnemyTier2Down = false
local hAbilityCapture = bot:GetAbilityByName('ability_capture')

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end
	-- local cacheKey = 'GetOutpostDesire'..tostring(bot:GetPlayerID())
	-- local cachedVar = Fu.Utils.GetCachedVars(cacheKey, 0.5 * (1 + Customize.ThinkLess))
	-- if DotaTime() > 30 and cachedVar ~= nil then return cachedVar end
	local res = GetDesireHelper()
	-- Fu.Utils.SetCachedVars(cacheKey, res)
	return GetAdjustedDesireValue(res)
end
function GetDesireHelper()
	if bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end

	if not IsEnemyTier2Down
	then
		if GetTower(GetOpposingTeam(), TOWER_TOP_2) == nil
		or GetTower(GetOpposingTeam(), TOWER_MID_2) == nil
		or GetTower(GetOpposingTeam(), TOWER_BOT_2) == nil
		then
			IsEnemyTier2Down = true
		end
	end

	if Fu.Utils.IsTeamPushingSecondTierOrHighGround(bot) then
		return BOT_MODE_DESIRE_NONE;
	end

	if Fu.GetEnemiesAroundAncient(bot, 3200) > 0 then
		return BOT_MODE_DESIRE_NONE
	end

	-- local botMode = bot:GetActiveMode()
	-- if (Fu.IsPushing(bot) or Fu.IsDefending(bot) or Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	-- or botMode == BOT_MODE_RUNE or botMode == BOT_MODE_SECRET_SHOP or botMode == BOT_MODE_WARD or botMode == BOT_MODE_ROAM)
	-- and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH then
	-- 	return BOT_MODE_DESIRE_NONE
	-- end

	----------
	-- Outpost
	----------

	if not IsEnemyTier2Down then return BOT_ACTION_DESIRE_NONE end

	if not DidWeGetOutpost
	then
		if botName == 'npc_dota_hero_invoker' then return BOT_ACTION_DESIRE_NONE end
		for _, unit in pairs(GetUnitList(UNIT_LIST_ALL))
		do
			if unit:GetUnitName() == '#DOTA_OutpostName_North'
			or unit:GetUnitName() == '#DOTA_OutpostName_South'
			then
				table.insert(Outposts, unit)
			end
		end

		DidWeGetOutpost = true
	end

	ClosestOutpost, ClosestOutpostDist = GetClosestOutpost()
	if ClosestOutpost ~= nil and ClosestOutpostDist < 3000
	and not IsEnemyCloserToOutpostLoc(ClosestOutpost:GetLocation(), ClosestOutpostDist)
	and IsSuitableToCaptureOutpost()
	then
		if GetUnitToUnitDistance(bot, ClosestOutpost) < 600
		then
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), bot:GetCurrentVisionRange())
			if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
			then
				return BOT_ACTION_DESIRE_NONE
			end
		end

		return RemapValClamped(GetUnitToUnitDistance(bot, ClosestOutpost), 3000, 0, BOT_ACTION_DESIRE_VERYLOW, BOT_ACTION_DESIRE_HIGH )
	end

	return BOT_ACTION_DESIRE_NONE
end

function OnStart()

end

function OnEnd()
	ClosestOutpost = nil
	ClosestOutpostDist = 10000
	ShouldWaitInBaseToHeal = false
end

function Think()
	if Fu.CanNotUseAction(bot) then return end
	if Fu.Utils.IsBotThinkingMeaningfulAction(bot, Customize.ThinkLess, "outpost") then return end

	if ClosestOutpost ~= nil
	then
		if GetUnitToUnitDistance(bot, ClosestOutpost) > 300
		then
			bot:Action_MoveToLocation(ClosestOutpost:GetLocation())
			return
		else
			if hAbilityCapture then
				bot:Action_UseAbilityOnEntity(hAbilityCapture, ClosestOutpost)
			else
				bot:Action_AttackUnit(ClosestOutpost, false)
			end
			return
		end
	end
end

function GetClosestOutpost()
	local closest = nil
	local dist = 10000

	for i = 1, 2
	do
		if Outposts[i] ~= nil
		and Outposts[i]:GetTeam() ~= GetTeam()
		and GetUnitToUnitDistance(bot, Outposts[i]) < dist
		and not Outposts[i]:IsNull()
		and not Outposts[i]:IsInvulnerable()
		then
			closest = Outposts[i]
			dist = GetUnitToUnitDistance(bot, Outposts[i])
		end
	end

	return closest, dist
end

function IsEnemyCloserToOutpostLoc(opLoc, botDist)
	for _, id in pairs(GetTeamPlayers(GetOpposingTeam()))
	do
		local info = GetHeroLastSeenInfo(id)

		if info ~= nil
		then
			local dInfo = info[1]
			if dInfo ~= nil
			then
				if dInfo ~= nil
				and dInfo.time_since_seen < 5
				and Fu.GetDistance(dInfo.location, opLoc) < botDist
				then
					return true
				end
			end
		end
	end

	return false
end

function IsSuitableToCaptureOutpost()
	local botTarget = Fu.GetProperTarget(bot)

	if (Fu.IsGoingOnSomeone(bot) and Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) < 700)
	or Fu.IsDefending(bot)
	or (Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget) and Fu.IsAttacking(bot))
	or (Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget) and Fu.IsAttacking(bot))
	or (Fu.IsRetreating(bot) and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH)
	or bot:WasRecentlyDamagedByAnyHero(5)
	or bot:GetActiveMode() == BOT_MODE_DEFEND_ALLY
	or Fu.GetNumOfAliveHeroes( false ) < Fu.GetNumOfAliveHeroes( true )
	then
		return false
	end

	return true
end
