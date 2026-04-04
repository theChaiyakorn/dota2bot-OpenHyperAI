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
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,3,2,3,6,3,2,2,1,6,1,1,1,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_quelling_blade",
    "item_enchanted_mango",
    "item_double_branches",

    "item_magic_wand",
    "item_falcon_blade",
    "item_power_treads",
    "item_lesser_crit",
    "item_ultimate_scepter",
    "item_black_king_bar",--
    "item_satanic",--
    "item_greater_crit",--
    "item_skadi",--
    "item_moon_shard",
    "item_monkey_king_bar",--
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

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

local RocketBarrage = bot:GetAbilityByName('gyrocopter_rocket_barrage')
local HomingMissile = bot:GetAbilityByName('gyrocopter_homing_missile')
local FlakCannon    = bot:GetAbilityByName('gyrocopter_flak_cannon')
local CallDown      = bot:GetAbilityByName('gyrocopter_call_down')

local RocketBarrageDesire
local HomingMissileDesire, HomingMissileTarget
local FlakCannonDesire
local CallDownDesire, CallDownLocation

local botTarget
local bGoingOnSomeone
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility( bot ) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    HomingMissileDesire, HomingMissileTarget = X.ConsiderHomingMissile()
    if HomingMissileDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:Action_UseAbilityOnEntity(HomingMissile, HomingMissileTarget)
        return
    end

    FlakCannonDesire = X.ConsiderFlakCannon()
    if FlakCannonDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:Action_UseAbility(FlakCannon)
        return
    end

    CallDownDesire, CallDownLocation = X.ConsiderCallDown()
    if CallDownDesire > 0
    then
        bot:Action_UseAbilityOnLocation(CallDown, CallDownLocation)
        return
    end

    RocketBarrageDesire = X.ConsiderRocketBarrage()
    if RocketBarrageDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:Action_UseAbility(RocketBarrage)
        return
    end
end

function X.ConsiderRocketBarrage()
    if not RocketBarrage:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRadius = RocketBarrage:GetSpecialValueInt('radius')
    local nDamage = RocketBarrage:GetSpecialValueInt('value')
    local nRocketsPerSecond = RocketBarrage:GetSpecialValueInt('rockets_per_second')
    local nDuration = 3
    local nAbilityLevel = RocketBarrage:GetLevel()
    local nMana = bot:GetMana() / bot:GetMaxMana()
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        local nCreeps = bot:GetNearbyCreeps(nRadius, true)

        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage * nRocketsPerSecond * nDuration, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        and nCreeps ~= nil and #nCreeps <= 1
        then
            bot:SetTarget(enemyHero)
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bInTeamFight
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius - 75, true, BOT_MODE_NONE)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
        local nCreeps = bot:GetNearbyCreeps(nRadius, true)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 150, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius - 75, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        and nCreeps ~= nil and #nCreeps <= 1
		then
            bot:SetTarget(botTarget)
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsRetreating(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius - 25, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (Fu.GetHP(bot) < 0.7 and bot:WasRecentlyDamagedByAnyHero(2)))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nRadius)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsFarming(bot)
    and nMana > 0.5
    and nAbilityLevel >= 2
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)

        if nNeutralCreeps ~= nil and #nNeutralCreeps >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end


    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderHomingMissile()
    if not HomingMissile:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = HomingMissile:GetCastRange()
    local nLaunchDelay = HomingMissile:GetSpecialValueFloat('pre_flight_time')
	local nDamage = HomingMissile:GetAbilityDamage()
    local nMana = bot:GetMana() / bot:GetMaxMana()
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, nLaunchDelay)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

	if bInTeamFight
	then
        local strongestEnemy = Fu.GetStrongestUnit(nCastRange, bot, true, false, 5)

        if strongestEnemy ~= nil
        and Fu.IsValidHero(strongestEnemy)
        and Fu.IsInRange(bot, strongestEnemy, nCastRange)
        and not Fu.IsSuspiciousIllusion(strongestEnemy)
        and not Fu.IsDisabled(strongestEnemy)
        and not Fu.IsTaunted(strongestEnemy)
        and not strongestEnemy:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not strongestEnemy:HasModifier('modifier_enigma_black_hole_pull')
        then
            return BOT_ACTION_DESIRE_HIGH, strongestEnemy
        end
	end

	if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

        if Fu.IsValidHero(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeAlly >= #nInRangeEnemy
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
	end

	if Fu.IsRetreating(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (Fu.GetHP(bot) < 0.6 and bot:WasRecentlyDamagedByAnyHero(2)))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not Fu.IsTaunted(nInRangeEnemy[1])
		then
			return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
		end
	end

    if Fu.IsLaning(bot)
    and nMana > 0.45
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep))
			and creep:GetHealth() <= nDamage
			then
				local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) <= 500
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end

    local nAllyHeroes  = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and nMana > 0.4
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderFlakCannon()
    if not FlakCannon:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRadius = FlakCannon:GetSpecialValueInt('radius')
    local nMana = bot:GetMana() / bot:GetMaxMana()
    local nAbilityLevel = FlakCannon:GetLevel()
    botTarget = Fu.GetProperTarget(bot)
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

	if bInTeamFight
	then
		if nEnemyHeroes ~= nil and #nEnemyHeroes >= 2
        then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 100, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
		then
            if #nInRangeEnemy == 1
            then
                return BOT_ACTION_DESIRE_LOW
            else
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and nAbilityLevel >= 2
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot)
    and nAbilityLevel >= 2
    and nMana > 0.35
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        nEnemyHeroes = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)

        if nEnemyHeroes ~= nil and #nEnemyHeroes == 0
        then
            if nNeutralCreeps ~= nil
            and (#nNeutralCreeps >= 3
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderCallDown()
    if not CallDown:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = CallDown:GetCastRange()
	local nCastPoint = CallDown:GetCastPoint()
	local nRadius = CallDown:GetSpecialValueInt('radius')
    local nDamage = CallDown:GetSpecialValueInt('damage_first')

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius / 2, nCastPoint, 0)

		if nLocationAoE.count >= 2
		then
            local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
		end
	end

    if bGoingOnSomeone
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius / 2, nCastPoint, 0)

        if nLocationAoE.count >= 2
        then
            local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(1 + nCastPoint)
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 5
        then
            local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius / 2, nCastPoint, 0)

            if nLocationAoE.count >= 4
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

return X