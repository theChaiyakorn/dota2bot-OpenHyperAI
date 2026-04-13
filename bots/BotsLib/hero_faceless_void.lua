local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,2,3,3,3,6,3,1,1,1,2,6,2,2,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_wraith_band",
    "item_power_treads",
    "item_magic_wand",
    "item_mask_of_madness",
    "item_mjollnir",--
    "item_black_king_bar",--
    "item_skadi",--
    "item_aghanims_shard",
	"item_butterfly",--
    "item_moon_shard",
    "item_refresher",--
    "item_travel_boots",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']


X['sBuyList'] = sRoleItemsBuyList[sRole]


X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local TimeWalk 			= SafeAbility(bot:GetAbilityByName('faceless_void_time_walk'), 'faceless_void_time_walk', 'faceless_void')
local TimeDilation 		= SafeAbility(bot:GetAbilityByName('faceless_void_time_dilation'), 'faceless_void_time_dilation', 'faceless_void')
local Chronosphere 		= SafeAbility(bot:GetAbilityByName('faceless_void_chronosphere'), 'faceless_void_chronosphere', 'faceless_void')
local TimeWalkReverse 	= SafeAbility(bot:GetAbilityByName('faceless_void_time_walk_reverse'), 'faceless_void_time_walk_reverse', 'faceless_void')
local Timezone 			= SafeAbility(bot:GetAbilityByName('faceless_void_time_zone'), 'faceless_void_time_zone', 'faceless_void')

local TimeWalkDesire, TimeWalkLocation
local TimeDilationDesire
local ChronosphereDesire, ChronosphereLocation
local TimeWalkReverseDesire
local TimezoneDesire, TimezoneLocation

local TimeWalkPrevLocation

local announceCount, lastAnnouncedTime = 0, GameTime()

local botTarget

local bGoingOnSomeone
local bRetreating
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
    if not Chronosphere or Chronosphere:IsHidden() then Chronosphere = SafeAbility(bot:GetAbilityByName('faceless_void_time_zone'), 'faceless_void_time_zone', 'faceless_void') end

	botTarget = Fu.GetProperTarget(bot)

	TimeWalkReverseDesire = X.ConsiderTimeWalkReverse()
	if TimeWalkReverseDesire > 0
	then
		bot:Action_UseAbility(TimeWalkReverse)
		return
	end

	TimeWalkDesire, TimeWalkLocation = X.ConsiderTimeWalk()
    if TimeWalkDesire > 0
	and IsAllowedToCast(TimeWalk:GetManaCost())
	then
        Fu.SetQueuePtToINT(bot, false)

		bot:Action_UseAbilityOnLocation(TimeWalk, TimeWalkLocation)
		TimeWalkPrevLocation = TimeWalkLocation
		return
	end

	TimeDilationDesire = X.ConsiderTimeDilation()
	if TimeDilationDesire > 0
	and IsAllowedToCast(TimeDilation:GetManaCost())
	then
        Fu.SetQueuePtToINT(bot, false)

		bot:Action_UseAbility(TimeDilation)
		return
	end

	-- Chronosphere = bot:GetAbilityByName('faceless_void_chronosphere')
	if Chronosphere and not Chronosphere:IsNull() and not Chronosphere:IsHidden() then
		if bot.needRefreshAbilitiesFor737 then
			Chronosphere = SafeAbility(bot:GetAbilityByName('faceless_void_chronosphere'), 'faceless_void_chronosphere', 'faceless_void')
			sAbilityList = Fu.Skill.GetAbilityList( bot )
			X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )
			bot:ActionImmediate_Chat( "I now have my Chronosphere back. Thanks!", true )
			bot.needRefreshAbilitiesFor737 = false
		end

		ChronosphereDesire, ChronosphereLocation = X.ConsiderChronosphere()
		if ChronosphereDesire > 0
		then
			bot:Action_UseAbilityOnLocation(Chronosphere, ChronosphereLocation)
			return
		end
	else
		bot.needRefreshAbilitiesFor737 = true
		if announceCount <= 2 and GameTime() - lastAnnouncedTime > 15 + bot:GetPlayerID() then
			lastAnnouncedTime = GameTime()
			announceCount = announceCount + 1
			bot:ActionImmediate_Chat( "Due to Valve bug in 7.37. I lost Chronosphere. Please enable Fretbots mode in this script to fix this problem. Check Workshop page if you need help.", true )
		end
	end

	TimezoneDesire, TimezoneLocation = X.ConsiderTimezone()
	if TimezoneDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(Timezone, TimezoneLocation)
		return
	end
end

function X.CanUseRefresherShard()
	local nCastRange = 1000
	local sCastType = 'none'
	local hEffectTarget = nil
	local sCastMotive = '刷新技能'
	local nInRangeEnmyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	if #nInRangeEnmyList > 0
		and ( bGoingOnSomeone or Fu.IsInTeamFight( bot ) )
		and Fu.CanUseRefresherShard( bot )
		and not bot:HasModifier("modifier_faceless_void_chronosphere_speed")
	then
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, sCastMotive
	end

	return false
end

function X.ConsiderTimeWalk()
	if not TimeWalk:IsFullyCastable()
	or bot:HasModifier("modifier_faceless_void_chronosphere_speed")
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = TimeWalk:GetSpecialValueInt('range')
	local nCastPoint = TimeWalk:GetCastPoint()
	local nSpeed = TimeWalk:GetSpecialValueInt('speed')
	local nDamageWindow = TimeWalk:GetSpecialValueInt('backtrack_duration')
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

	if Fu.IsStuck(bot)
	then
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nCastRange)
	end

	if Fu.IsStunProjectileIncoming(bot, 600)
	or Fu.IsUnitTargetProjectileIncoming(bot, 400)
    then
        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nCastRange)
    end

	if not bot:HasModifier('modifier_sniper_assassinate')
	and not bot:IsMagicImmune()
	then
		if Fu.IsWillBeCastUnitTargetSpell(bot, 400)
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nCastRange)
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:IsAttackImmune()
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)
			local eta = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
			local loc = Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetExtrapolatedLocation(eta), nCastRange)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			and IsLocationPassable(loc)
			and not Fu.IsLocationInArena(loc, 600)
			then
				if GetUnitToLocationDistance(bot, loc) > bot:GetAttackRange() * 2
				then
					if Fu.IsInLaningPhase()
					then
						-- In laning: only time walk aggressively if low HP (backtrack value)
						-- or target is killable in 1-3 hits
						local nBotHP = Fu.GetHP(bot)
						local nTargetHP = botTarget:GetHealth()
						local nBotDmg = bot:GetAttackDamage()
						local bLowHP = nBotHP < 0.3
						local bCanKill = nTargetHP <= nBotDmg * 3
						local nEnemyTowers = botTarget:GetNearbyTowers(700, false)
						if (bLowHP or bCanKill)
						and nEnemyTowers ~= nil and #nEnemyTowers == 0
						then
							return BOT_ACTION_DESIRE_HIGH, loc
						end
					else
						return BOT_ACTION_DESIRE_HIGH, loc
					end
				end
			end
		end
	end

	if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
        do
			if Fu.IsValidHero(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and not Fu.IsRealInvisible(bot)
			then
				local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
				local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

				if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
				and ((#nTargetInRangeAlly > #nInRangeAlly)
					or bot:WasRecentlyDamagedByHero(enemyHero, nDamageWindow))
				then
					return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nCastRange)
				end
			end
        end
	end

	if Fu.IsPushing(bot)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
		and GetUnitToLocationDistance(bot, Fu.GetCenterOfUnits(nEnemyLaneCreeps)) > 500
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end
	end

	if Fu.IsFarming(bot)
	then
		if Fu.IsValid(botTarget)
		and GetUnitToUnitDistance(bot, botTarget) > 500
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsLaning(bot)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		-- for _, creep in pairs(nEnemyLaneCreeps)
		-- do
		-- 	if Fu.IsValid(creep)
		-- 	and Fu.CanBeAttacked(creep)
		-- 	and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
		-- 	and GetUnitToUnitDistance(creep, bot) > 500
		-- 	then
		-- 		local nCreepInRangeHero = creep:GetNearbyHeroes(creep:GetCurrentVisionRange(), false, BOT_MODE_NONE)
		-- 		local nCreepInRangeTower = creep:GetNearbyTowers(700, false)
		-- 		local nTime = (GetUnitToUnitDistance(bot, creep) / nSpeed) + nCastPoint
		-- 		local nDamage = bot:GetAttackDamage()

		-- 		if Fu.WillKillTarget(creep, nDamage, DAMAGE_TYPE_PHYSICAL, nTime)
		-- 		and nCreepInRangeHero ~= nil and #nCreepInRangeHero == 0
		-- 		and nCreepInRangeTower ~= nil and #nCreepInRangeTower == 0
		-- 		then
		-- 			bot:SetTarget(creep)
		-- 			return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
		-- 		end
		-- 	end
		-- end

		if ((bot:GetMana() - TimeWalk:GetManaCost()) / bot:GetMaxMana()) > 0.85
		and bot:DistanceFromFountain() > 100
		and bot:DistanceFromFountain() < 6000
		and Fu.IsInLaningPhase()
		and #nEnemyHeroes == 0
		then
			local nLane = bot:GetAssignedLane()
			local nLaneFrontLocation = GetLaneFrontLocation(GetTeam(), nLane, 0)
			local nDistFromLane = GetUnitToLocationDistance(bot, nLaneFrontLocation)

			if nDistFromLane > nCastRange
			then
				local nLocation = Fu.Site.GetXUnitsTowardsLocation(bot, nLaneFrontLocation, nCastRange)
				if IsLocationPassable(nLocation)
				then
					return BOT_ACTION_DESIRE_HIGH, nLocation
				end
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
    then
		local roshLoc = Fu.GetCurrentRoshanLocation()
        if GetUnitToLocationDistance(bot, roshLoc) > nCastRange
        then
			local targetLoc = Fu.Site.GetXUnitsTowardsLocation(bot, roshLoc, nCastRange)
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(roshLoc, 1600)

			if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
			and IsLocationPassable(targetLoc)
			then
				return BOT_ACTION_DESIRE_HIGH, targetLoc
			end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
		local tormentorLoc = Fu.GetTormentorLocation(GetTeam())
        if GetUnitToLocationDistance(bot, tormentorLoc) > nCastRange
        then
			local targetLoc = Fu.Site.GetXUnitsTowardsLocation(bot, tormentorLoc, nCastRange)
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(targetLoc, 1600)

			if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
			and IsLocationPassable(targetLoc)
			then
				return BOT_ACTION_DESIRE_HIGH, targetLoc
			end

        end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderTimeDilation()
	if not TimeDilation:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = TimeDilation:GetSpecialValueInt('radius')

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bRetreating
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			then
				local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
				local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

				if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
				and (#nInRangeAlly >= #nTargetInRangeAlly
					or bot:WasRecentlyDamagedByHero(enemyHero, 2.5))
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderChronosphere()
	if not Chronosphere:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Chronosphere:GetCastRange()
	local nCastPoint = Chronosphere:GetCastPoint()
	local nRadius = Chronosphere:GetSpecialValueInt('radius')
	local nDuration = Chronosphere:GetSpecialValueInt('duration')
	local nAttackDamage = bot:GetAttackDamage()
	local nAttackSpeed = bot:GetAttackSpeed()
	local nBotKills = GetHeroKills(bot:GetPlayerID())
	local nBotDeaths = GetHeroDeaths(bot:GetPlayerID())

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius / 1.2, nCastPoint, 0)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius / 1.2)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			local targetHero = nil
			local currHeroHP = 10000

			for _, enemyHero in pairs(nInRangeEnemy)
			do
				if Fu.IsValidHero(enemyHero)
				and not Fu.IsSuspiciousIllusion(enemyHero)
				and not enemyHero:IsAttackImmune()
				and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
				and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
				and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
				and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
				and enemyHero:GetHealth() < currHeroHP
				then
					currHeroHP = enemyHero:GetHealth()
					targetHero = enemyHero
				end
			end

			if targetHero ~= nil
			then
				bot:SetTarget(targetHero)
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end

		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:IsAttackImmune()
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			and #nInRangeAlly <= 1 and #nInRangeEnemy <= 1
			then
				local loc = Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)

				if Fu.CanKillTarget(botTarget, nAttackDamage * nAttackSpeed * nDuration, DAMAGE_TYPE_PHYSICAL)
				and not Fu.IsLocationInChrono(loc)
				and not Fu.IsLocationInBlackHole(loc)
				and not Fu.IsLocationInArena(loc, nRadius)
				then
					bot:SetTarget(botTarget)
					return BOT_ACTION_DESIRE_HIGH, loc
					-- if Fu.IsCore(botTarget)
					-- then
					-- 	bot:SetTarget(botTarget)
					-- 	return BOT_ACTION_DESIRE_HIGH, loc
					-- end

					-- if not Fu.IsCore(botTarget)
					-- and nBotDeaths > nBotKills + 4
					-- then
					-- 	bot:SetTarget(botTarget)
					-- 	return BOT_ACTION_DESIRE_HIGH, loc
					-- end
				end
			end
		end
	end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nInRangeEnemy)
        do
			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and Fu.IsValidHero(enemyHero)
			and Fu.IsChasingTarget(enemyHero, bot)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and not nInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
			and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

				if nTargetInRangeAlly ~= nil
				and #nTargetInRangeAlly > #nInRangeAlly + 2
				and #nInRangeAlly <= 1
				then
					local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
					local nTargetLocInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

					if nTargetLocInRangeEnemy ~= nil and #nTargetLocInRangeEnemy >= 1
					and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
					and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
					and not Fu.IsLocationInArena(nLocationAoE.targetloc, nRadius)
					then
						return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
					end
				end
			end
        end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderTimeWalkReverse()
	if not TimeWalkReverse:IsTrained()
	or not TimeWalkReverse:IsFullyCastable()
	or not TimeWalkReverse:IsActivated()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	if Fu.IsStunProjectileIncoming(bot, 600)
	or Fu.IsUnitTargetProjectileIncoming(bot, 400)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

	if not bot:HasModifier('modifier_sniper_assassinate')
	and not bot:IsMagicImmune()
	then
		if Fu.IsWillBeCastUnitTargetSpell(bot, 400)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if not bot:HasModifier('modifier_faceless_void_chronosphere_speed')
	and Fu.IsValidTarget(botTarget)
	and Fu.IsInRange(bot, botTarget, bot:GetCurrentVisionRange())
	and not Fu.IsSuspiciousIllusion(botTarget)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		then
			if #nInRangeEnemy > #nInRangeAlly
			and GetUnitToLocationDistance(bot, TimeWalkPrevLocation) > GetUnitToLocationDistance(botTarget, TimeWalkPrevLocation)
			and GetUnitToLocationDistance(bot, TimeWalkPrevLocation) > GetUnitToUnitDistance(bot, botTarget)
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		-- if TimeDilation:IsTrained() and TimeDilation:IsFullyCastable()
		-- and bGoingOnSomeone
		-- then
		-- 	return BOT_ACTION_DESIRE_HIGH
		-- end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderTimezone()
	if not Timezone or Timezone:IsNull() or not Timezone:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, Timezone:GetCastRange())
	local nRadius = Timezone:GetSpecialValueInt('radius')

	if Fu.IsInTeamFight(bot, 1600)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
		local nInRangeAlly = Fu.GetAlliesNearLoc(nLocationAoE.targetloc, nRadius)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= 2 and #nInRangeEnemy >= 2
		then
			local nGoodEnemies = 0
			for _, enemyHero in pairs(nInRangeEnemy)
			do
				if Fu.IsValidHero(enemyHero)
				and not Fu.IsSuspiciousIllusion(enemyHero)
				and Fu.GetHP(enemyHero) > 0.25
				and Fu.CanBeAttacked(enemyHero)
				and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
				and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				then
					nGoodEnemies = nGoodEnemies + 1
				end
			end

			if nGoodEnemies >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

--Helper Funcs
function IsAllowedToCast(manaCost)
	if Chronosphere ~= nil
	and not Chronosphere:IsNull()
	and Chronosphere:IsTrained()
	and Chronosphere:IsFullyCastable()
	then
		local ultCost = Chronosphere:GetManaCost()
		if bot:GetMana() - manaCost * 2 > ultCost
		then
			return true
		else
			return false
		end
	end

	return true
end

return X