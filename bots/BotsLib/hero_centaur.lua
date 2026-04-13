local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        ['t25'] = {10, 0},
                        ['t20'] = {10, 0},
                        ['t15'] = {10, 0},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
                        {1,2,2,1,2,6,2,1,1,3,3,6,3,3,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sUtility = {"item_crimson_guard", "item_pipe", "item_lotus_orb"}
local sCrimsonPipeLotus = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",
    "item_ring_of_protection",
    "item_magic_wand",

    "item_helm_of_iron_will",
    "item_phase_boots",
    "item_veil_of_discord",
    "item_blink",
    "item_pipe",--
    "item_shivas_guard",--
    sCrimsonPipeLotus,
    "item_aghanims_shard",
    "item_kaya_and_sange",--
    "item_heart",--
    "item_overwhelming_blink",--
    "item_travel_boots_2",--
    "item_moon_shard",
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_power_treads",
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

local HoofStomp     = SafeAbility(bot:GetAbilityByName('centaur_hoof_stomp'), 'centaur_hoof_stomp', 'centaur')
local DoubleEdge    = SafeAbility(bot:GetAbilityByName('centaur_double_edge'), 'centaur_double_edge', 'centaur')
-- local Retaliate     = bot:GetAbilityByName('centaur_return')
local WorkHorse     = SafeAbility(bot:GetAbilityByName('centaur_work_horse'), 'centaur_work_horse', 'centaur')
local HitchARide    = SafeAbility(bot:GetAbilityByName('centaur_mount'), 'centaur_mount', 'centaur')
local Stampede      = SafeAbility(bot:GetAbilityByName('centaur_stampede'), 'centaur_stampede', 'centaur')

local HoofStompDesire
local DoubleEdgeDesire, DoubleEdgeTarget
local WorkHorseDesire
local HitchARideDesire, HitchARideTarget
local StampedeDesire

local botTarget
local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = ctx.hp
	bInTeamFight = ctx.isTeamFight

    HitchARideDesire, HitchARideTarget = X.ConsiderHitchARide()
    if HitchARideDesire > 0
    then
        bot:Action_UseAbilityOnEntity(HitchARide, HitchARideTarget)
        return
    end

    WorkHorseDesire, HitchARideTarget = X.ConsiderWorkHorse()
    if WorkHorseDesire > 0
    then
        bot:Action_UseAbility(WorkHorse)
        return
    end

    StampedeDesire = X.ConsiderStampede()
    if StampedeDesire > 0
    then
        bot:Action_UseAbility(Stampede)
        return
    end

    HoofStompDesire = X.ConsiderHoofStomp()
    if HoofStompDesire > 0
    then
        bot:Action_UseAbility(HoofStomp)
        return
    end

    DoubleEdgeDesire, DoubleEdgeTarget = X.ConsiderDoubleEdge()
    if DoubleEdgeDesire > 0
    then
        bot:Action_UseAbilityOnEntity(DoubleEdge, DoubleEdgeTarget)
        return
    end
end

function X.ConsiderHoofStomp()
    if not HoofStomp:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRadius = HoofStomp:GetSpecialValueInt('radius')
	local nDamage = HoofStomp:GetSpecialValueInt('stomp_damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius - 100)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if Stampede:IsTrained()
                and Stampede:IsFullyCastable()
                then
                    if bot:GetMana() - HoofStomp:GetManaCost() > Stampede:GetManaCost()
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                else
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
		end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nRadius)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (bot:WasRecentlyDamagedByAnyHero(1.5)))
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
        and bAttacking
        and not Fu.IsDisabled(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderDoubleEdge()
	if not DoubleEdge:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, 0
	end

    local nStrength = bot:GetAttributeValue(ATTRIBUTE_STRENGTH)
	local nCastRange = DoubleEdge:GetCastRange()
    local nAttackRange = bot:GetAttackRange()
    local nStrengthDamageMul = DoubleEdge:GetSpecialValueInt("strength_damage") / 100
	local nDamage = DoubleEdge:GetSpecialValueInt("edge_damage") + (nStrength * nStrengthDamageMul)
	botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + nAttackRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        and bot:GetHealth() > nDamage * 1.2
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange * 2)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and bot:GetHealth() > nDamage * 1.5
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
		end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange * 2, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        and bAttacking
        and bot:GetHealth() > nDamage * 1.5
        and (bot:GetHealth() - nDamage) / bot:GetMaxHealth() > 0.5
        and Fu.GetHP(nEnemyLaneCreeps[1]) > 0.33
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
        end
    end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        and nBotHP > 0.3
        and bot:GetHealth() > nDamage * 1.5
        and (bot:GetHealth() - nDamage) / bot:GetMaxHealth() > 0.3
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange * 2)
            if nNeutralCreeps ~= nil and #nNeutralCreeps >= 1
            and Fu.GetHP(nNeutralCreeps[1]) > 0.33
            then
                return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange * 2, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            and Fu.GetHP(nEnemyLaneCreeps[1]) > 0.33
            then
                return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange * 2, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
            --     and Fu.CanBeAttacked(creep)
            --     and nBotHP > 0.3
            --     and bot:GetHealth() > nDamage * 1.5
            --     and (bot:GetHealth() - nDamage) / bot:GetMaxHealth() > 0.3
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH, creep
			-- 	end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                canKill = canKill + 1
                table.insert(creepList, creep)
            end
		end

        if canKill >= 2
        and Fu.CanBeAttacked(creepList[1])
        and nBotHP > 0.3
        and bot:GetHealth() > nDamage * 1.5
        and (bot:GetHealth() - nDamage) / bot:GetMaxHealth() > 0.3
        then
            return BOT_ACTION_DESIRE_HIGH, creepList[1]
        end

        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange + 75)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and Fu.IsValidTarget(nInRangeEnemy[1])
        and (bot:GetHealth() - nDamage) / bot:GetMaxHealth() > 0.65
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
        end
	end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange * 2)
        and bAttacking
        and bot:GetHealth() > nDamage * 1.5
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange * 2)
        and bAttacking
        and bot:GetHealth() > nDamage * 1.5
        and (bot:GetHealth() - nDamage) / bot:GetMaxHealth() > 0.45
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderStampede()
	if not Stampede:IsFullyCastable()
    or bot:HasModifier('modifier_centaur_cart')
    or bot:HasModifier('modifier_centaur_stampede')
    then
		return BOT_ACTION_DESIRE_NONE
	end

    if bInTeamFight
	then
        local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and nTeamFightLocation ~= nil
        then
            if Fu.GetLocationToLocationDistance(bot:GetLocation(), nTeamFightLocation) < 600
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 600)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and #nTargetInRangeAlly > #nInRangeAlly
            and #nTargetInRangeAlly >= 2
            and #nInRangeAlly <= 1
            and nBotHP < 0.5
            then
		        return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderWorkHorse()
    if not WorkHorse:IsTrained()
    or not WorkHorse:IsFullyCastable()
    or bot:HasModifier('modifier_centaur_stampede')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if bInTeamFight
	then
        local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and nTeamFightLocation ~= nil
        then
            if Fu.GetLocationToLocationDistance(bot:GetLocation(), nTeamFightLocation) < 600
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 600)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and #nTargetInRangeAlly > #nInRangeAlly
            and #nTargetInRangeAlly >= 2
            and #nInRangeAlly <= 1
            and nBotHP < 0.5
            then
		        return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderHitchARide()
    if HitchARide:IsHidden()
    or not HitchARide:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = HitchARide:GetCastRange()

    if bGoingOnSomeone
    or bInTeamFight
    then
        local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)
        for _, allyHero in pairs(nInRangeAlly)
        do
            if Fu.IsValidHero(allyHero)
            and allyHero:WasRecentlyDamagedByAnyHero(1.1)
            and Fu.GetHP(allyHero) < 0.5
            and not allyHero:IsIllusion()
            and not allyHero:HasModifier('modifier_arc_warden_tempest_double')
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)
        for _, allyHero in pairs(nInRangeAlly)
        do
            if Fu.IsValidHero(allyHero)
            and Fu.IsRetreating(allyHero)
            and allyHero:WasRecentlyDamagedByAnyHero(1.1)
            and not allyHero:IsIllusion()
            and not allyHero:HasModifier('modifier_arc_warden_tempest_double')
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X