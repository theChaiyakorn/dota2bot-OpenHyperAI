-- Credit goes to Furious Puppy for Bot Experiment

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
						['t20'] = {10, 0},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{3,2,2,3,2,6,2,1,1,1,1,3,3,6,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_quelling_blade",

	"item_bottle",
    "item_magic_wand",
	"item_boots",
    "item_phase_boots",
	"item_mage_slayer",
    "item_maelstrom",
	"item_kaya_and_sange",--
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_ultimate_scepter",
    "item_mjollnir",--
    "item_travel_boots",
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_octarine_core",--
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_quelling_blade",

    "item_magic_wand",
	"item_boots",
    "item_phase_boots",
	"item_mage_slayer",
    "item_maelstrom",
	"item_kaya_and_sange",--
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_ultimate_scepter",
    "item_mjollnir",--
    "item_travel_boots",
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_octarine_core",--
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3'] 

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_ultimate_scepter",
	"item_magic_wand",

	"item_cyclone",
	"item_magic_wand",
	
	"item_travel_boots",
	"item_quelling_blade",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		Minion.IllusionThink( hMinionUnit )
	end
end

local SearingChains 		= SafeAbility(bot:GetAbilityByName("ember_spirit_searing_chains"), 'ember_spirit_searing_chains', 'ember_spirit')
local SleightOfFist 		= SafeAbility(bot:GetAbilityByName("ember_spirit_sleight_of_fist"), 'ember_spirit_sleight_of_fist', 'ember_spirit')
local FlameGuard 			= SafeAbility(bot:GetAbilityByName("ember_spirit_flame_guard"), 'ember_spirit_flame_guard', 'ember_spirit')
local ActivateFireRemnant 	= SafeAbility(bot:GetAbilityByName("ember_spirit_activate_fire_remnant"), 'ember_spirit_activate_fire_remnant', 'ember_spirit')
local FireRemnant 			= SafeAbility(bot:GetAbilityByName("ember_spirit_fire_remnant"), 'ember_spirit_fire_remnant', 'ember_spirit')

local SearingChainsDesire
local SleightOfFistDesire, SoFLocation
local FlameGuardDesire
local ActivateFireRemnantDesire, ActivateRemnantLocation
local FireRemnantDesire, FireRemnantLocation

local SleightChainsDesire, SCLocation

local remnantCastTime = -100
local remnantCastGap  = 0.5

local botTarget
local bGoingOnSomeone
local bRetreating
local nBotHP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	nBotHP = ctx.hp

	SleightChainsDesire, SCLocation = X.ConsiderSleightChains()
	if SleightChainsDesire > 0
	then
		bot:Action_ClearActions(false)
		bot:ActionQueue_UseAbilityOnLocation(SleightOfFist, SCLocation)
		bot:ActionQueue_UseAbility(SearingChains)
		return
	end

	SleightOfFistDesire, SoFLocation = X.ConsiderSleightOfFist()
	if SleightOfFistDesire > 0
	then
		bot:Action_UseAbilityOnLocation(SleightOfFist, SoFLocation)
		return
	end

	SearingChainsDesire = X.ConsiderSearingChains()
	if SearingChainsDesire > 0
	then
		bot:Action_UseAbility(SearingChains)
		return
	end

	FireRemnantDesire, FireRemnantLocation = X.ConsiderFireRemnant()
    if FireRemnantDesire > 0
	then
		bot:Action_UseAbilityOnLocation(FireRemnant, FireRemnantLocation)
		remnantCastTime = DotaTime()
		return
	end

	ActivateFireRemnantDesire, ActivateRemnantLocation = X.ConsiderActivateFireRemnant()
	if ActivateFireRemnantDesire > 0
	then
		bot:Action_UseAbilityOnLocation(ActivateFireRemnant, ActivateRemnantLocation)
		return
	end

	FlameGuardDesire = X.ConsiderFlameGuard()
	if FlameGuardDesire > 0
	then
		bot:Action_UseAbility(FlameGuard)
		return
	end
end

function X.ConsiderSearingChains()
	if not SearingChains:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = SearingChains:GetSpecialValueInt('radius')
	local nDamage = SearingChains:GetSpecialValueInt('damage_per_second')
	local nEnemyHeroes = Fu.GetAroundEnemyHeroList(nRadius)
	botTarget = Fu.GetProperTarget(bot)

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nRadius)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not Fu.IsDisabled(enemyHero)
		then
			if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
			then
				return BOT_ACTION_DESIRE_HIGH
			end

			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius + 50, true, BOT_MODE_NONE)

		if Fu.IsValidHero(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and Fu.CanCastOnNonMagicImmune(botTarget )
		and Fu.CanCastOnTargetAdvanced(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		then
			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValidHero(enemyHero)
			then
				if enemyHero:HasModifier('modifier_item_glimmer_cape')
				or enemyHero:HasModifier('modifier_invisible')
				or enemyHero:HasModifier('modifier_item_shadow_amulet_fade')
				then
					if not enemyHero:HasModifier('modifier_item_dustofappearance')
					and not enemyHero:HasModifier('modifier_slardar_amplify_damage')
					and not enemyHero:HasModifier('modifier_bloodseeker_thirst_vision')
					and not enemyHero:HasModifier('modifier_sniper_assassinate')
					and not enemyHero:HasModifier('modifier_bounty_hunter_track')
					then
						return BOT_ACTION_DESIRE_HIGH
					end
				end
			end
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius + 50, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeEnemy > #nInRangeAlly
		and (#nInRangeEnemy >= 2 or (nBotHP < 0.6 or bot:WasRecentlyDamagedByAnyHero(2)))
		then
			if Fu.IsValidHero(nInRangeEnemy[1])
			and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
			and not Fu.IsDisabled(nInRangeEnemy[1])
			and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
			and not nInRangeEnemy[1]:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and not Fu.IsDisabled(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSleightOfFist()
	if not SleightOfFist:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = SleightOfFist:GetSpecialValueInt('radius')
	local nCastRange = SleightOfFist:GetCastRange()
	local nCastPoint = SleightOfFist:GetCastPoint()
	local nManaCost = SleightOfFist:GetManaCost()
	local nDamage = bot:GetAttackDamage() + SleightOfFist:GetSpecialValueInt('bonus_hero_damage')
	local nAbilityLevel = SleightOfFist:GetLevel()
	botTarget = Fu.GetProperTarget(bot)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnMagicImmune(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange)
		and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
		end
	end

	if Fu.IsStunProjectileIncoming(bot, bot:GetAttackRange())
	then
		local nInRangeCreeps = bot:GetNearbyCreeps(nCastRange, true)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if nInRangeCreeps ~= nil and #nInRangeCreeps >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, nInRangeCreeps[1]:GetLocation()
		elseif nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
		end
	end

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nLocationAoE.count >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 100, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere')
		then
			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and ((#nInRangeAlly >= #nInRangeEnemy) or (#nInRangeEnemy > #nInRangeAlly and Fu.WeAreStronger(bot, 1000)))
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
			end
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 250, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange + 100, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeEnemy > #nInRangeAlly
		and (#nInRangeEnemy >= 2 or (nBotHP < 0.6 or bot:WasRecentlyDamagedByAnyHero(2.5)))
		then
			if Fu.IsValidHero(nInRangeEnemy[1])
			and Fu.CanCastOnMagicImmune(nInRangeEnemy[1])
			and not Fu.IsDisabled(nInRangeEnemy[1])
			and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
			and not nInRangeEnemy[1]:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
			end
		end
	end

    if Fu.IsFarming(bot)
	and nAbilityLevel >= 3
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nLocationAoE.count >= 3 and #nNeutralCreeps >= 3
		then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if Fu.IsLaning(bot) and Fu.AllowedToSpam(bot, nManaCost)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		local creepDamage = bot:GetAttackDamage()

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep))
			and creep:GetHealth() <= creepDamage
			then
				local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) <= 500
				then
					return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
				end
			end
		end
	end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	and nAbilityLevel >= 3
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		local nLocationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
		and nLocationAoE.count >= 4
		then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderFlameGuard()
	if not FlameGuard:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = FlameGuard:GetSpecialValueInt('radius')
	botTarget = Fu.GetProperTarget(bot)

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if nEnemyHeroes ~= nil and #nEnemyHeroes >= 2
		and Fu.IsInRange(bot, nEnemyHeroes[1], nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)

		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeEnemy > #nInRangeAlly
		and #nInRangeEnemy >= 2 or (nBotHP < 0.7 and bot:WasRecentlyDamagedByAnyHero(2))
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	if Fu.IsFarming(bot)
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)

		if nNeutralCreeps ~= nil and #nNeutralCreeps >= 3
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderActivateFireRemnant()
	if not ActivateFireRemnant:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	if DotaTime() < remnantCastTime + remnantCastGap + 1
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	botTarget = Fu.GetProperTarget(bot)

	if bGoingOnSomeone
	and not CanDoSleightChains()
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
		local closestRemnantToTarget = nil
		local targetDist = 100000

		for _, u in pairs(GetUnitList(UNIT_LIST_ALLIES))
		do
			if u ~= nil
			and Fu.IsValidTarget(botTarget)
			and u:GetUnitName() == 'npc_dota_ember_spirit_remnant'
			then
				local dist = GetUnitToUnitDistance(u, botTarget)
				if dist < targetDist
				then
					targetDist = dist
					closestRemnantToTarget = u
				end
			end
		end

		if closestRemnantToTarget ~= nil
		and nInRangeAlly ~= nil and nInRangeAlly ~= nil
		and ((#nInRangeAlly >= #nInRangeEnemy) or (#nInRangeEnemy > #nInRangeAlly and Fu.WeAreStronger(bot, 1200)))
		then
			return BOT_ACTION_DESIRE_HIGH, closestRemnantToTarget:GetLocation()
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
		local closestRemnantToAncient = nil
		local targetDist = 100000

		for _, u in pairs(GetUnitList(UNIT_LIST_ALLIES))
		do
			if u ~= nil
			and u:GetUnitName() == 'npc_dota_ember_spirit_remnant'
			then
				local dist = GetUnitToUnitDistance(u, GetAncient(GetTeam()))
				if dist < targetDist
				then
					targetDist = dist
					closestRemnantToAncient = u
				end
			end
		end

		if closestRemnantToAncient ~= nil
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and (#nInRangeEnemy >= #nInRangeAlly)
		and (#nInRangeEnemy >= 2 or nBotHP < 0.7)
		then
			return BOT_ACTION_DESIRE_HIGH, closestRemnantToAncient:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderFireRemnant()
	if not FireRemnant:IsFullyCastable()
	or not ActivateFireRemnant:IsFullyCastable()
	or bot:IsRooted()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	if DotaTime() < remnantCastTime + remnantCastGap
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local remnantCount = 0
	for _, u in pairs(GetUnitList(UNIT_LIST_ALLIES))
	do
		if u ~= nil
		and u:GetUnitName() == 'npc_dota_ember_spirit_remnant'
		and GetUnitToUnitDistance(bot, u) < 1600
		then
			remnantCount = remnantCount + 1
		end
	end

	if remnantCount > 0
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = FireRemnant:GetCastRange()
	local nCastPoint = FireRemnant:GetCastPoint()
	local nDamage = FireRemnant:GetSpecialValueInt('damage')
	local nSpeed = bot:GetCurrentMovementSpeed() * (FireRemnant:GetSpecialValueInt('speed_multiplier') / 100)
	botTarget = Fu.GetProperTarget(bot)

	if nCastRange > 1600 then nCastRange = 1600 end

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_faceless_void_chronosphere')
		and GetUnitToUnitDistance(bot, enemyHero) > bot:GetAttackRange() - 25
		then
			local nDelay = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay)
		end
	end

	if bGoingOnSomeone
	and not CanDoSleightChains()
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere')
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, nCastRange + 100, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, nCastRange, true, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			and GetUnitToUnitDistance(bot, botTarget) > 600
			then
				local nDelay = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
				return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nDelay)
			end
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

		if bot:WasRecentlyDamagedByAnyHero(2.5)
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and (#nInRangeEnemy >= #nInRangeAlly)
		and (#nInRangeEnemy >= 2 or nBotHP < 0.7)
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		then
			local loc = Fu.GetEscapeLoc()
			local dist = nCastRange * (1 - nBotHP)

			if dist < 600 then dist = 600 end

			return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, dist)
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSleightChains()
	if CanDoSleightChains()
	then
		local nCastRange = SleightOfFist:GetCastRange()
		botTarget = Fu.GetProperTarget(bot)

		if bGoingOnSomeone
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 100, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

			if Fu.IsValidTarget(botTarget)
			and Fu.CanCastOnMagicImmune(botTarget)
			and Fu.IsInRange(bot, botTarget, nCastRange)
			and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 75)
			and not Fu.IsSuspiciousIllusion(botTarget)
			and not Fu.IsDisabled(botTarget)
			and not botTarget:HasModifier('modifier_faceless_void_chronosphere')
			then
				if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
				and ((#nInRangeAlly >= #nInRangeEnemy) or (#nInRangeEnemy > #nInRangeAlly and Fu.WeAreStronger(bot, 1000)))
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
				end
			end
		end

		if bRetreating
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 250, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange + 100, true, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeEnemy > #nInRangeAlly
			and (#nInRangeEnemy >= 2 or (nBotHP < 0.6 or bot:WasRecentlyDamagedByAnyHero(2)))
			then
				if Fu.IsValidHero(nInRangeEnemy[1])
				and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
				and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
				and not Fu.IsInRange(bot, nInRangeEnemy[1], bot:GetAttackRange() + 75)
				and not Fu.IsDisabled(nInRangeEnemy[1])
				and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
				and not nInRangeEnemy[1]:IsDisarmed()
				then
					return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
				end
			end
		end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function CanDoSleightChains()
	if SleightOfFist:IsFullyCastable()
    and SearingChains:IsFullyCastable()
    then
        local manaCost = SleightOfFist:GetManaCost() + SearingChains:GetManaCost()

        if bot:GetMana() >= manaCost
        then
            return true
        end
    end

    return false
end

return X