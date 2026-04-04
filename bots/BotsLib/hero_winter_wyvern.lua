local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {--pos4,5
                        ['t25'] = {10, 0},
                        ['t20'] = {10, 0},
                        ['t15'] = {10, 0},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,2,2,3,2,6,2,1,1,1,6,3,3,3,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sUtility = {"item_lotus_orb", "item_shivas_guard"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_circlet",

    "item_boots",
    "item_magic_wand",
    "item_arcane_boots",
    "item_guardian_greaves",--
	"item_glimmer_cape",--
    "item_force_staff",
    "item_aether_lens",--
    nUtility,--
    "item_aghanims_shard",
    "item_refresher",--
    -- "item_arcane_blink",--
    "item_hurricane_pike",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_circlet",

    "item_magic_wand",
    "item_boots",
    "item_pipe",
    "item_tranquil_boots",
    "item_boots_of_bearing",--
	"item_glimmer_cape",--
    "item_force_staff",
    "item_aether_lens",--
    nUtility,--
    "item_aghanims_shard",
    "item_refresher",--
    -- "item_arcane_blink",--
    "item_hurricane_pike",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_double_tango",
    "item_double_branches",
    "item_circlet",

    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
    "item_blink",
    "item_force_staff",
    "item_aether_lens",--
    "item_boots_of_bearing",--
    nUtility,--
    "item_aghanims_shard",
    "item_refresher",--
    "item_arcane_blink",--
    "item_hurricane_pike",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
	"item_mid_outfit",
	-- "item_falcon_blade",
    "item_witch_blade",
    "item_ultimate_scepter",
    "item_force_staff",
    "item_hurricane_pike",--
    "item_orchid",
    "item_yasha_and_kaya",--
    -- "item_black_king_bar",--
	"item_bloodthorn",--
    "item_sphere",--
    "item_aghanims_shard",
    "item_skadi",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_2']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

	"item_skadi",--
    "item_witch_blade",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local ArcticBurn    = bot:GetAbilityByName('winter_wyvern_arctic_burn')
local SplinterBlast = bot:GetAbilityByName('winter_wyvern_splinter_blast')
local ColdEmbrace   = bot:GetAbilityByName('winter_wyvern_cold_embrace')
local WintersCurse  = bot:GetAbilityByName('winter_wyvern_winters_curse')

local ArcticBurnDesire
local SplinterBlastDesire, SplinterBlastTarget
local ColdEmbraceDesire, ColdEmbraceTarget
local WintersCurseDesire, WintersCurseTarget

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

    botTarget = ctx.target

    WintersCurseDesire, WintersCurseTarget = X.ConsiderWintersCurse()
    if WintersCurseDesire > 0
    then
        bot:Action_UseAbilityOnEntity(WintersCurse, WintersCurseTarget)
        return
    end

    ColdEmbraceDesire, ColdEmbraceTarget = X.ConsiderColdEmbrace()
    if ColdEmbraceDesire > 0
    then
        bot:Action_UseAbilityOnEntity(ColdEmbrace, ColdEmbraceTarget)
        return
    end

    SplinterBlastDesire, SplinterBlastTarget = X.ConsiderSplinterBlast()
    if SplinterBlastDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SplinterBlast, SplinterBlastTarget)
        return
    end

    ArcticBurnDesire = X.ConsiderArcticBurn()
    if ArcticBurnDesire > 0
    then
        bot:Action_UseAbility(ArcticBurn)
        return
    end
end

function X.ConsiderArcticBurn()
    if not ArcticBurn:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nBonusRange = ArcticBurn:GetSpecialValueInt('attack_range_bonus')
	local nAttackRange = bot:GetAttackRange()
    local nNewAttackRange = nAttackRange + nBonusRange

	if not bot:HasScepter()
    then
		if Fu.IsStuck(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		if bGoingOnSomeone
		then
			if Fu.IsValidTarget(botTarget)
            and Fu.CanCastOnNonMagicImmune(botTarget)
            and Fu.IsInRange(bot, botTarget, nNewAttackRange)
            and not Fu.IsSuspiciousIllusion(botTarget)
            and not Fu.IsDisabled(botTarget)
            and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
			then
                local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
                local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
                and #nInRangeAlly >= #nInRangeEnemy
                then
                    if Fu.IsInLaningPhase()
                    then
                        if Fu.IsChasingTarget(bot, botTarget)
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
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.IsChasingTarget(enemyHero, bot)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                then
                    local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                    local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                    if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                    and ((#nTargetInRangeAlly > #nInRangeAlly)
                        or bot:WasRecentlyDamagedByAnyHero(2))
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end
        end
	else
		if Fu.IsStuck(bot)
        and not ArcticBurn:GetToggleState() == false
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		if bGoingOnSomeone
		then
			if Fu.IsValidTarget(botTarget)
            and Fu.CanCastOnNonMagicImmune(botTarget)
            and Fu.IsInRange(bot, botTarget, nNewAttackRange)
            and not Fu.IsSuspiciousIllusion(botTarget)
            and not Fu.IsDisabled(botTarget)
            and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
			then
                if ArcticBurn:GetToggleState() == false
                then
                    return BOT_ACTION_DESIRE_HIGH
                else
                    return BOT_ACTION_DESIRE_NONE
                end
			end
		end

        if Fu.IsInTeamFight(bot, nNewAttackRange)
        then
            local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nNewAttackRange)
            if realEnemyCount ~= nil and #realEnemyCount >= 1
            then
                if ArcticBurn:GetToggleState() == false
                then
                    return BOT_ACTION_DESIRE_HIGH
                else
                    return BOT_ACTION_DESIRE_NONE
                end
            end
        end

        if bRetreating
        then
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

            if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
            then
                if ArcticBurn:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end

            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.IsChasingTarget(enemyHero, bot)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                then
                    local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                    local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                    if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                    and ((#nTargetInRangeAlly > #nInRangeAlly)
                        or bot:WasRecentlyDamagedByAnyHero(2))
                    then
                        if ArcticBurn:GetToggleState() == false
                        then
                            return BOT_ACTION_DESIRE_HIGH
                        else
                            return BOT_ACTION_DESIRE_NONE
                        end
                    end
                end
            end
        end

        if ArcticBurn:GetToggleState() == true
        then
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot, 1500, true, BOT_MODE_NONE)
            if #nInRangeEnemy <= 0 then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSplinterBlast()
    if not SplinterBlast:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SplinterBlast:GetCastRange())
	local nDamage = SplinterBlast:GetSpecialValueInt('damage')
	local nRadius = SplinterBlast:GetSpecialValueInt('split_radius')
    local nManaCost = SplinterBlast:GetManaCost()

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsInRange(bot, enemyHero, nCastRange)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nTargetInRangeCreeps = enemyHero:GetNearbyCreeps(nRadius, true)
            for _, creep in pairs(nTargetInRangeCreeps)
            do
                if Fu.IsValid(creep)
                and Fu.CanCastOnNonMagicImmune(creep)
                then
                    return BOT_ACTION_DESIRE_HIGH, creep
                end
            end

            local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, nRadius, false, BOT_MODE_NONE)
            for _, enemyHero2 in pairs(nTargetInRangeAlly)
            do
                if Fu.IsValidHero(enemyHero2)
                and Fu.CanCastOnNonMagicImmune(enemyHero2)
                and Fu.IsNotSelf(enemyHero, enemyHero2)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero2
                end
            end
        end
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                local nTargetInRangeCreeps = botTarget:GetNearbyCreeps(nRadius, true)
                for _, creep in pairs(nTargetInRangeCreeps)
                do
                    if Fu.IsValid(creep)
                    and Fu.CanCastOnNonMagicImmune(creep)
                    then
                        return BOT_ACTION_DESIRE_HIGH, creep
                    end
                end

                local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, nRadius, false, BOT_MODE_NONE)
                for _, enemyHero in pairs(nTargetInRangeAlly)
                do
                    if Fu.IsValidHero(enemyHero)
                    and Fu.CanCastOnNonMagicImmune(enemyHero)
                    and Fu.IsNotSelf(botTarget, enemyHero)
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end
                end
            end
		end
	end

    if bRetreating
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_winter_wyvern_arctic_burn_slow')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    local nTargetInRangeCreeps = enemyHero:GetNearbyCreeps(nRadius, true)
                    for _, creep in pairs(nTargetInRangeCreeps)
                    do
                        if Fu.IsValid(creep)
                        and Fu.CanCastOnNonMagicImmune(creep)
                        then
                            return BOT_ACTION_DESIRE_HIGH, creep
                        end
                    end

                    nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, nRadius, false, BOT_MODE_NONE)
                    for _, enemyHero2 in pairs(nTargetInRangeAlly)
                    do
                        if Fu.IsValidHero(enemyHero2)
                        and Fu.CanCastOnNonMagicImmune(enemyHero2)
                        and Fu.IsNotSelf(enemyHero, enemyHero2)
                        then
                            return BOT_ACTION_DESIRE_HIGH, enemyHero2
                        end
                    end
                end
            end
        end
    end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
        local creepList = {}
        local creepTarget = nil
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
        for _, creep in pairs(nEnemyLaneCreeps)
        do
            if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            then
                if creep:GetHealth() <= nDamage
                then
                    table.insert(creepList, creep)
                end

                if creep:GetHealth() > nDamage
                then
                    creepTarget = creep
                end
            end
        end

        if creepTarget ~= nil
        and #creepList >= 3
        and Fu.GetManaAfter(nManaCost) > 0.4
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH, creepTarget
        end

        if creepTarget == nil
        and #creepList >= 4
        and Fu.GetManaAfter(nManaCost) > 0.4
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH, creepList[1]
        end

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and Fu.GetManaAfter(nManaCost) > 0.4
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
        end

        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 1600, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and Fu.Utils.IsValidUnit(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
        end
	end

    if Fu.IsLaning(bot)
    then
        local creepList = {}
        local creepTarget = nil
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
        for _, creep in pairs(nEnemyLaneCreeps)
        do
            if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            then
                if creep:GetHealth() <= nDamage
                then
                    table.insert(creepList, creep)
                end

                if creep:GetHealth() > nDamage
                then
                    creepTarget = creep
                end
            end
        end

        if creepTarget ~= nil
        and #creepList >= 3
        and Fu.GetManaAfter(nManaCost) > 0.5
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH, creepTarget
        end

        if creepTarget == nil
        and #creepList >= 4
        and Fu.GetManaAfter(nManaCost) > 0.5
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH, creepList[1]
        end

        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.GetManaAfter(nManaCost) > 0.35
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_winter_wyvern_arctic_burn_slow')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
                for _, allyHero in pairs(nInRangeAlly)
                do
                    if Fu.IsValidHero(allyHero)
                    and (Fu.IsChasingTarget(enemyHero, allyHero) or enemyHero:GetAttackTarget() == allyHero)
                    and not Fu.IsSuspiciousIllusion(allyHero)
                    then
                        local nTargetInRangeCreeps = enemyHero:GetNearbyCreeps(nRadius, true)
                        for _, creep in pairs(nTargetInRangeCreeps)
                        do
                            if Fu.IsValid(creep)
                            and Fu.CanCastOnNonMagicImmune(creep)
                            then
                                return BOT_ACTION_DESIRE_HIGH, creep
                            end
                        end

                        local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, nRadius, false, BOT_MODE_NONE)
                        for _, enemyHero2 in pairs(nTargetInRangeAlly)
                        do
                            if Fu.IsValidHero(enemyHero2)
                            and Fu.CanCastOnNonMagicImmune(enemyHero2)
                            and Fu.IsNotSelf(enemyHero, enemyHero2)
                            then
                                return BOT_ACTION_DESIRE_HIGH, enemyHero2
                            end
                        end
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderColdEmbrace()
    if not ColdEmbrace:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ColdEmbrace:GetCastRange())
    local nDuration = ColdEmbrace:GetSpecialValueFloat('duration')
    local nBaseHealPerSec = ColdEmbrace:GetSpecialValueInt('heal_additive')
    local nMaxHPHealPercentage = ColdEmbrace:GetSpecialValueInt('heal_percentage') / 100

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsCore(allyHero)
        and not Fu.IsSuspiciousIllusion(allyHero)
        and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1600, true, BOT_MODE_NONE)
            for _, enemyHero in pairs(nAllyInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and enemyHero:GetAttackTarget() == allyHero
                and not Fu.IsSuspiciousIllusion(enemyHero)
                then
                    if (allyHero:HasModifier('modifier_legion_commander_duel') and Fu.GetHP(allyHero) < 0.25)
                    or allyHero:HasModifier('modifier_enigma_black_hole_pull')
                    or allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                    then
                        return BOT_ACTION_DESIRE_HIGH, allyHero
                    end
                end
            end
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetCurrentVisionRange())
        and not Fu.IsSuspiciousIllusion(botTarget)
        then
            local nInRangeAlly2 = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly2 ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly2 >= #nInRangeEnemy
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
                -- Core
                for _, allyHero in pairs(nInRangeAlly)
                do
                    if Fu.IsValidHero(allyHero)
                    and Fu.GetHP(allyHero) < 0.3
                    and Fu.IsCore(allyHero)
                    and not Fu.IsSuspiciousIllusion(allyHero)
                    and not Fu.IsInEtherealForm(allyHero)
                    and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                    and not allyHero:HasModifier('modifier_necrolyte_sadist_active')
                    then
                        return BOT_ACTION_DESIRE_HIGH, allyHero
                    end
                end

                -- Support
                for _, allyHero in pairs(nInRangeAlly)
                do
                    if Fu.IsValidHero(allyHero)
                    and Fu.GetHP(allyHero) < 0.25
                    and not Fu.IsCore(allyHero)
                    and not Fu.IsSuspiciousIllusion(allyHero)
                    and not Fu.IsInEtherealForm(allyHero)
                    and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                    then
                        return BOT_ACTION_DESIRE_HIGH, allyHero
                    end
                end
            end
        end
    end

    if bRetreating
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and nBotHP < 0.25
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not not enemyHero:HasModifier('modifier_fountain_aura_buff')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1))
                then
                    return BOT_ACTION_DESIRE_HIGH, bot
                end
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.GetHP(allyHero) < 0.25
        and not Fu.IsSuspiciousIllusion(allyHero)
        and not Fu.IsInEtherealForm(allyHero)
        and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not not allyHero:HasModifier('modifier_fountain_aura_buff')
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        then
            if nBotHP < 0.2
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end

            local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
            for _, allyHero in pairs(nInRangeAlly)
            do
                if Fu.IsValidHero(allyHero)
                and Fu.GetHP(allyHero) < 0.3
                and not allyHero:IsIllusion()
                and not allyHero:HasModifier('modifier_abaddon_borrowed_time')
                and not allyHero:HasModifier('modifier_dazzle_shallow_grave')
                and not allyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
                and not allyHero:HasModifier('modifier_obsidian_destroyer_astral_imprisonment_prison')
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end
    end

    if nBotHP < 0.2
    then
        return BOT_ACTION_DESIRE_HIGH, bot
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderWintersCurse()
    if not WintersCurse:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, WintersCurse:GetCastRange())
    local nRadius = WintersCurse:GetSpecialValueInt('radius')
    local nDuration = WintersCurse:GetSpecialValueFloat('duration')

    if Fu.IsInTeamFight(bot, nCastRange + 200)
	then
		local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange + 200)

        if realEnemyCount ~= nil and #realEnemyCount >= 3
        then
            local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1000)
            if nInRangeAlly ~= nil and #nInRangeAlly <= #realEnemyCount then
                local nWeakestEnemyHero = Fu.GetAttackableWeakestUnit( bot, nCastRange + 200, true, true )
                if nWeakestEnemyHero ~= nil then
                    local nInRangeAlly = Fu.GetNearbyHeroes(nWeakestEnemyHero, 400, true, BOT_MODE_NONE)
                    if nInRangeAlly == nil or #nInRangeAlly <= 0 then
                        if Fu.IsValidHero(nWeakestEnemyHero)
                        and Fu.GetHP(nWeakestEnemyHero) >= 0.5
                        and not Fu.IsSuspiciousIllusion(nWeakestEnemyHero)
                        and not Fu.IsDisabled(nWeakestEnemyHero)
                        and not nWeakestEnemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                        and not Fu.IsUnderLongDurationStun(nWeakestEnemyHero) then
                            return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyHero
                        end
                    end
                end
            end
        end
	end

	if bGoingOnSomeone
	then
		local target = nil
		local dmg = 0

		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), bot:GetCurrentVisionRange())
		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 3
        then
			for _, enemyHero in pairs(nInRangeEnemy)
			do
				if Fu.IsValidHero(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                and Fu.GetHP(enemyHero) >= 0.5
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                and not Fu.IsUnderLongDurationStun(enemyHero) then
					local nInRangeAlly = Fu.GetAlliesNearLoc(enemyHero:GetLocation(), 400)
                    local nTargetInRangeAlly = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), 1200)
                    local currDmg = enemyHero:GetEstimatedDamageToTarget(true, bot, nDuration, DAMAGE_TYPE_ALL)

                    if (nInRangeAlly == nil or #nInRangeAlly <= 0)
                    and nTargetInRangeAlly ~= nil
                    and currDmg > dmg
                    then
                        nTargetInRangeAlly = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nRadius)
                        if nTargetInRangeAlly ~= nil and #nTargetInRangeAlly >= 2
                        then
                            dmg = currDmg
                            target = enemyHero
                        end
                    end
				end
			end

			if target ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, target
			end
		end
	end

    if bRetreating
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and nBotHP < 0.5
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.GetHP(enemyHero) > 0.5
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not Fu.IsUnderLongDurationStun(enemyHero)
            then
                local nInRangeAlly = Fu.GetAlliesNearLoc(enemyHero:GetLocation(), 1200)
                local nTargetInRangeAlly = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), 1200)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2.5))
                and #nInRangeAlly >= 2
                then
                    nTargetInRangeAlly = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nRadius)
                    if nTargetInRangeAlly ~= nil and #nTargetInRangeAlly >= 1
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end
                end
            end
        end
    end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnMagicImmune(enemyHero)
        and enemyHero:IsChanneling()
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and Fu.GetHP(enemyHero) >= 0.4
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not Fu.IsUnderLongDurationStun(enemyHero)
		then
            local nInRangeAlly = Fu.GetAlliesNearLoc(enemyHero:GetLocation(), 400)
            local nInRangeRetreatingAlly = Fu.GetRetreatingAlliesNearLoc(enemyHero:GetLocation(), 400)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nRadius)
            if (nInRangeAlly == nil or #nInRangeAlly <= 0 or #nInRangeRetreatingAlly > 0)
            and nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X