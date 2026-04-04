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
							['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
							{2,1,1,2,1,6,1,2,2,3,6,3,3,3,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sUtility = {"item_pipe", "item_lotus_orb", "item_heavens_halberd", "item_crimson_guard"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
	"item_double_branches",
    "item_quelling_blade",

	"item_magic_wand",
	"item_double_bracer",
	"item_boots",
    "item_phase_boots",
	"item_soul_ring",
    "item_blink",
	"item_cyclone",
    "item_black_king_bar",--
    "item_aghanims_shard",
    nUtility,--
    "item_octarine_core",--
	"item_wind_waker",--
    "item_travel_boots",
    "item_overwhelming_blink",--
	"item_travel_boots_2",--
    "item_moon_shard",
    "item_ultimate_scepter_2"
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",

	"item_double_bracer",
	"item_bottle",
	"item_boots",
	"item_magic_wand",
	"item_phase_boots",
	"item_desolator",--
	"item_blink",
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_assault",--
	"item_satanic",--
	"item_travel_boots",
	"item_moon_shard",
	"item_overwhelming_blink",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local SpearOfMars 	= bot:GetAbilityByName('mars_spear')
local GodsRebuke 	= bot:GetAbilityByName('mars_gods_rebuke')
local Bulwark 		= bot:GetAbilityByName('mars_bulwark')
local ArenaOfBlood 	= bot:GetAbilityByName('mars_arena_of_blood')

local SpearOfMarsDesire, SpearOfMarsLocation
local GodsRebukeDesire, GodsRebukeLocation
local BulwarkDesire
local ArenaOfBloodDesire, ArenaOfBloodLocation

local SpearToAllyDesire, SpearToAllyLocation
local ArenaOfBloodCastTime = 0

local nAllyHeroes, nEnemyHeroes
local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotMP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = Fu.GetMP(bot)

	SpearOfMars = bot:GetAbilityByName('mars_spear')
	GodsRebuke = bot:GetAbilityByName('mars_gods_rebuke')
	Bulwark = bot:GetAbilityByName('mars_bulwark')
	ArenaOfBlood = bot:GetAbilityByName('mars_arena_of_blood')

	botTarget = Fu.GetProperTarget(bot)
	nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
	nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	SpearToAllyDesire, SpearToAllyLocation, BlinkLocation = X.ConsiderSpearToAlly()
	if SpearToAllyDesire > 0
	then
		bot:Action_ClearActions(false)
		bot:ActionQueue_UseAbilityOnLocation(bot.Blink, BlinkLocation)
		bot:ActionQueue_Delay(0.1)
		bot:ActionQueue_UseAbilityOnLocation(SpearOfMars, SpearToAllyLocation)
		return
	end

	ArenaOfBloodDesire, ArenaOfBloodLocation = X.ConsiderArenaOfBlood()
	if ArenaOfBloodDesire > 0
	then
		bot:Action_UseAbilityOnLocation(ArenaOfBlood, ArenaOfBloodLocation)
		ArenaOfBloodCastTime = DotaTime()
		return
	end

	GodsRebukeDesire, GodsRebukeLocation = X.ConsiderGodsRebuke()
	if GodsRebukeDesire > 0
	then
		bot:Action_UseAbilityOnLocation(GodsRebuke, GodsRebukeLocation)
		return
	end

	SpearOfMarsDesire, SpearOfMarsLocation = X.ConsiderSpearOfMars()
	if SpearOfMarsDesire > 0
	then
		bot:Action_UseAbilityOnLocation(SpearOfMars, SpearOfMarsLocation)
		return
	end

	BulwarkDesire = X.ConsiderBulwark()
	if BulwarkDesire > 0
	then
		bot:Action_UseAbility(Bulwark)
		return
	end
end

function X.ConsiderSpearOfMars()
	if not Fu.CanCastAbility(SpearOfMars)
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, SpearOfMars:GetSpecialValueInt('spear_range'))
	local nCastPoint = SpearOfMars:GetCastPoint()
	local nRadius = SpearOfMars:GetSpecialValueInt('spear_width')
	local nSpeed = SpearOfMars:GetSpecialValueInt('spear_speed')
	local nDamage = SpearOfMars:GetSpecialValueInt('damage')
	local nManaAfter = Fu.GetManaAfter(SpearOfMars:GetManaCost())
	local nAbilityLevel = SpearOfMars:GetLevel()

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if  Fu.IsValidHero(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		then
			if enemyHero:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end

			if  Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise')
			and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
			then
				local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
				return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(enemyHero, eta)
			end
		end
	end

	if bGoingOnSomeone then
		if  Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			local target_loc = X.GetSpearToLocation(nCastRange, nRadius, nCastPoint, nSpeed, botTarget)
			if Fu.IsInLaningPhase() then
				local nInRangeAlly = Fu.GetSpecialModeAllies(bot, 1200, BOT_MODE_ATTACK)
				if X.GetTotalEstimatedDamageToTarget(nInRangeAlly, botTarget, 5.0) > botTarget:GetHealth() * 1.2
				then
					if target_loc then
						return BOT_ACTION_DESIRE_HIGH, target_loc
					end
				end
			else
				if target_loc then
					return BOT_ACTION_DESIRE_HIGH, target_loc
				end
			end
		end
	end

	if bRetreating
	and not Fu.IsRealInvisible(bot)
	and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
		for _, enemyHero in pairs(nEnemyHeroes)
        do
			if  Fu.IsValidHero(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.IsChasingTarget(enemyHero, bot)
			and Fu.IsInRange(bot, enemyHero, nCastRange - 150)
			and not Fu.IsDisabled(enemyHero)
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end
        end
	end

	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

	if ((Fu.IsPushing(bot) and not Fu.IsLateGame()) or Fu.IsDefending(bot))
	and #nAllyHeroes <= 2
	and nAbilityLevel >= 3
	and nManaAfter > 0.5
	and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
	and not Fu.IsRunning(nEnemyLaneCreeps[1])
	then
		local nLocationAoE = bot:FindAoELocation(true, false, nEnemyLaneCreeps[1]:GetLocation(), 0, nRadius, nCastPoint, 0)
		if #nEnemyLaneCreeps >= 4 and nLocationAoE.count >= 4 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if Fu.IsLaning(bot) and bot:GetLevel() < 6
	then
		for _, creep in pairs(nEnemyLaneCreeps) do
			if  Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			and not Fu.IsRunning(creep)
			then
				if Fu.IsValidHero(nEnemyHeroes[1])
                and GetUnitToUnitDistance(nEnemyHeroes[1], creep) < 500
				and nBotMP > 0.75
				then
					return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
				end
			end
		end
	end

	if Fu.IsFarming(bot) and nManaAfter > 0.35 and not Fu.IsLateGame() then
		local nEnemyCreeps = bot:GetNearbyCreeps(nCastRange, true)
		if Fu.IsValid(nEnemyCreeps[1])
		and Fu.CanBeAttacked(nEnemyCreeps[1])
		and not Fu.IsRunning(nEnemyCreeps[1])
		then
			local nLocationAoE = bot:FindAoELocation(true, false, nEnemyCreeps[1]:GetLocation(), 0, nRadius, nCastPoint, 0)
			if ((#nEnemyCreeps >= 4 and nLocationAoE.count >= 4) or (#nEnemyCreeps >= 2 and nLocationAoE.count >= 2 and nEnemyCreeps[1]:IsAncientCreep()))
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
	end

    for _, allyHero in pairs(nAllyHeroes) do
        if  Fu.IsValidHero(allyHero)
		and Fu.IsRetreating(allyHero)
		and bot ~= allyHero
        and allyHero:WasRecentlyDamagedByAnyHero(3)
        and not allyHero:IsIllusion()
		and nBotMP > 0.5
        then
			local nAllyInRangeEnemy = Fu.GetEnemiesNearLoc(allyHero:GetLocation(), 1600)
            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
				local vToAlly = (allyHero:GetLocation() - bot:GetLocation()):Normalized()
				local vToEnemy = (nAllyInRangeEnemy[1]:GetLocation() - bot:GetLocation()):Normalized()

				if Fu.DotProduct(vToAlly, vToEnemy) < 0 then
					local eta = (GetUnitToUnitDistance(bot, nAllyInRangeEnemy[1]) / nSpeed) + nCastPoint
					return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetExtrapolatedLocation(eta)
				end
            end
        end
    end

	if Fu.IsDoingRoshan(bot)
    then
        if  Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderGodsRebuke()
    if not Fu.CanCastAbility(GodsRebuke)
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nRadius = GodsRebuke:GetSpecialValueInt('radius')
	local nDamage = bot:GetAttackDamage() * GodsRebuke:GetSpecialValueInt('crit_mult') / 100
	local nAbilityLevel = GodsRebuke:GetLevel()

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if  Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nRadius)
		and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PHYSICAL)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
		end
	end

	if bGoingOnSomeone
	then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius - 75)
        and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_aphotic_shield')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local nLocationAoE = bot:FindAoELocation(true, true, botTarget:GetLocation(), 0, nRadius, 0, 0)
			if nLocationAoE.count >= 1 then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
	end

	if bRetreating
	and not Fu.IsRealInvisible(bot)
	then
        for _, enemyHero in pairs(nEnemyHeroes) do
			if  Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nRadius)
			and Fu.IsChasingTarget(enemyHero, bot)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and not Fu.CanCastAbility(SpearOfMars)
			and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end
        end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(nRadius + 150, true)

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	and nAbilityLevel >= 3
	and nBotMP > 0.5
	and bAttacking
	then
		if nEnemyCreeps ~= nil and #nEnemyCreeps >= 4
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyCreeps)
		end
	end

	if  Fu.IsFarming(bot)
	and nAbilityLevel >= 3
	and nBotMP > 0.5
	and bAttacking
	then
		if Fu.CanBeAttacked(nEnemyCreeps[1])
		and (#nEnemyCreeps >= 3 or (#nEnemyCreeps >= 2 and nEnemyCreeps[1]:IsAncientCreep()))
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyCreeps)
		end
	end

	if  Fu.IsLaning(bot)
	and nBotMP > 0.33
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
		local aveCreepHealth = 0
		local creepList = {}

		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2
		then
			for _, creep in pairs(nEnemyLaneCreeps)
			do
				if  Fu.IsValid(creep)
				and Fu.CanBeAttacked(creep)
				then
					aveCreepHealth = aveCreepHealth + creep:GetHealth()
					table.insert(creepList, creep)

					local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
					if  nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
					and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_PHYSICAL)
					then
						return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
					end
				end
			end

			if  #creepList >= 1
			and (aveCreepHealth / #creepList) <= nDamage
			then
				return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
			end
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if  Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderBulwark()
    if not Fu.CanCastAbility(Bulwark)
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRange = Bulwark:GetSpecialValueInt('soldier_offset')

	if bRetreating
	and not Fu.IsRealInvisible(bot)
	then
		local nInRangeAlly = bot:GetNearbyHeroes(800, false, BOT_MODE_NONE)

		if #nInRangeAlly >= 1
		then
			local numFacing = 0
			local nInRangeEnemy = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

			for _, enemyHero in pairs(nInRangeEnemy)
			do
				if  Fu.IsValidHero(enemyHero)
				and Fu.CanCastOnMagicImmune(enemyHero)
				and bot:IsFacingLocation(enemyHero:GetLocation(), 15)
				and not Fu.IsSuspiciousIllusion(enemyHero)
				and not Fu.IsDisabled(enemyHero)
				then
					numFacing = numFacing + 1
				end
			end

			if  numFacing >= 1
			and nInRangeEnemy ~= nil
			and #nInRangeEnemy > #nInRangeAlly
			then
				if Bulwark:GetToggleState() == false then
					return BOT_ACTION_DESIRE_HIGH
				end

				return BOT_ACTION_DESIRE_NONE
			end
		end
	end

	if bGoingOnSomeone
	and Fu.IsInRange(bot, botTarget, nRange)
	then
		if bot:HasScepter()
		then
			if Bulwark:GetToggleState() == false then
				return BOT_ACTION_DESIRE_HIGH
			end

			return BOT_ACTION_DESIRE_NONE
		end
	end

	if Bulwark:GetToggleState() == true then
		return BOT_ACTION_DESIRE_HIGH
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderArenaOfBlood()
    if not Fu.CanCastAbility(ArenaOfBlood)
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, ArenaOfBlood:GetCastRange())
	local nCastPoint = ArenaOfBlood:GetCastPoint()
	local nRadius = ArenaOfBlood:GetSpecialValueInt('radius')
	local nDuration = ArenaOfBlood:GetSpecialValueInt('duration')

	if Fu.IsInTeamFight(bot, 1300)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if  nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
		and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
		and not Fu.IsLocationInArena(nLocationAoE.targetloc, nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone
	then
		if  Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
		and Fu.IsCore(botTarget)
		and (bAttacking or Fu.IsChasingTarget(bot, botTarget))
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsLocationInChrono(botTarget:GetLocation())
		and not Fu.IsLocationInBlackHole(botTarget:GetLocation())
		and not Fu.IsLocationInArena(botTarget:GetLocation(), nRadius)
		then
			local nInRangeAlly = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
			local nInRangeEnemy = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)

			if  nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			and not (#nInRangeAlly >= #nInRangeEnemy + 2)
			and bot:GetEstimatedDamageToTarget(true, botTarget, nDuration, DAMAGE_TYPE_ALL) >= botTarget:GetHealth()
			then
				return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
			end
		end
	end

	if bRetreating
	then
        local nInRangeAlly = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nInRangeEnemy)
        do
			if  nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and Fu.IsValidHero(enemyHero)
			and Fu.IsChasingTarget(enemyHero, bot)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and not nInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
			and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				local nTargetInRangeAlly = nInRangeEnemy[1]:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

				if  nTargetInRangeAlly ~= nil
				and #nTargetInRangeAlly > #nInRangeAlly + 2
				and #nInRangeAlly <= 1
				then
					local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
					local nTargetLocInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

					if  nTargetLocInRangeEnemy ~= nil and #nTargetLocInRangeEnemy >= 1
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

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSpearToAlly()
    if X.CanSpearToAlly()
    then
		local nCastRange = SpearOfMars:GetCastRange()
		local nCastPoint = SpearOfMars:GetCastPoint()
		local nSpeed = SpearOfMars:GetSpecialValueInt('spear_speed')

		if bGoingOnSomeone then
			if  Fu.IsValidTarget(botTarget)
			and Fu.CanCastOnNonMagicImmune(botTarget)
			and Fu.IsInRange(bot, botTarget, 1199)
			and not Fu.IsInRange(bot, botTarget, 500)
			and not Fu.IsDisabled(botTarget)
			and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				local nInRangeAlly = Fu.GetAlliesNearLoc(botTarget:GetLocation(), nCastRange)
				local nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nCastRange)
				local hAllyTarget = X.GetFurthestAllyFromBot(nInRangeAlly)

				if #nInRangeAlly >= #nInRangeEnemy
				and #nInRangeAlly >= 2
				and hAllyTarget ~= nil
				then
					local eta = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) / nCastPoint
					return BOT_ACTION_DESIRE_HIGH, hAllyTarget:GetLocation(), Fu.GetCorrectLoc(botTarget, eta)
				end
			end
		end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.CanSpearToAlly()
    if Fu.CanCastAbility(SpearOfMars)
    and Fu.CanBlinkDagger(bot)
    then
        local nManaCost = SpearOfMars:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

function X.GetFurthestAllyFromBot(hAllyList)
	local target = nil
	local targetDist = 0
	for _, ally in pairs(hAllyList) do
		if Fu.IsValidHero(ally) and bot ~= ally then
			local allyDist = GetUnitToUnitDistance(bot, ally)
			if allyDist > targetDist then
				target = ally
				targetDist = allyDist
			end
		end
	end

	return target
end

function X.GetSpearToLocation(nCastRange, nRadius, nCastPoint, nSpeed, hTarget)
	local botLocation = bot:GetLocation()
	local hTargetLocation = Fu.GetCorrectLoc(hTarget, (GetUnitToUnitDistance(bot, hTarget) / nSpeed) + nCastPoint)
	-- local hTargetLocation = hTarget:GetLocation()
	local hTrees = bot:GetNearbyTrees(nCastRange * 0.6)

	if DotaTime() < ArenaOfBloodCastTime + 7 then
		return hTargetLocation
	end

	-- impale to tree
	for _, tree in pairs(hTrees) do
		if tree then
			local vTreeLocation = GetTreeLocation(tree)
			local tResult = PointToLineDistance(botLocation, vTreeLocation, hTargetLocation)
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius
			and (Fu.GetDistance(hTargetLocation, vTreeLocation) < GetUnitToLocationDistance(bot, vTreeLocation))
			then
				return vTreeLocation
			end
		end
	end

	-- impale to building
	for _, building in pairs(GetUnitList(UNIT_LIST_ALL)) do
		if Fu.IsValidBuilding(building)
		and Fu.IsInRange(bot, building, nCastRange * 0.6)
		then
			local vBuildingLocation = building:GetLocation()
			local tResult = PointToLineDistance(botLocation, vBuildingLocation, hTargetLocation)
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius
			and (Fu.GetDistance(hTargetLocation, vBuildingLocation) < GetUnitToLocationDistance(bot, vBuildingLocation))
			then
				return vBuildingLocation
			end
		end
	end

	-- spear to ally
	return X.GetAllySpearLocation(nCastRange, nRadius, nCastPoint, nSpeed, hTarget)
end

function X.GetAllySpearLocation(nCastRange, nRadius, nCastPoint, nSpeed, hTarget)
	local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)
	local hTargetLocation = Fu.GetCorrectLoc(hTarget, (GetUnitToUnitDistance(bot, hTarget) / nSpeed) + nCastPoint)

	for _, ally in pairs(nInRangeAlly) do
		if Fu.IsValidHero(ally)
		and bot ~= ally
		and not Fu.IsRetreating(ally)
		and bot:DistanceFromFountain() > ally:DistanceFromFountain()
		then
			local nAllyInRangeAlly = ally:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
			local nAllyInRangeEnemy = ally:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
			local tResult = PointToLineDistance(bot:GetLocation(), ally:GetLocation(), hTargetLocation)

			if #nAllyInRangeAlly >= #nAllyInRangeEnemy
			and (tResult ~= nil and tResult.within and tResult.distance <= nRadius)
			and (GetUnitToUnitDistance(hTarget, ally) < GetUnitToUnitDistance(bot, ally))
			then
				return ally:GetLocation()
			end
		end
	end

	return nil
end

function X.GetTotalEstimatedDamageToTarget(hUnitList, hTarget, fDuration)
	local dmg = 0
	for _, unit in pairs(hUnitList) do
		local bCurrentlyAvailable = true
		if unit:GetTeam() ~= GetBot():GetTeam() then
			bCurrentlyAvailable = false
		end

		dmg = dmg + unit:GetEstimatedDamageToTarget(bCurrentlyAvailable, hTarget, fDuration, DAMAGE_TYPE_ALL)
	end

	return dmg
end

return X