local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {10, 0},
						['t20'] = {10, 0},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,2,1,3,1,6,1,3,3,3,6,2,2,2,6},--pos3
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
    "item_double_gauntlets",

    "item_magic_wand",
    "item_double_bracer",
    "item_phase_boots",
    "item_echo_sabre",
    "item_blink",
    "item_aghanims_shard",
    "item_black_king_bar",--
    nUtility,--
    "item_basher",
    "item_assault",--
    "item_abyssal_blade",--
    "item_travel_boots",
    "item_overwhelming_blink",--
    "item_travel_boots_2",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",
	"item_aghanims_shard",
	"item_guardian_greaves",
	"item_spirit_vessel",
	"item_lotus_orb",
	"item_mjollnir",--
	--"item_holy_locket",
	"item_ultimate_scepter",
	"item_sheepstick",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_shivas_guard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_mage_outfit',
	"item_hand_of_midas",
	"item_glimmer_cape",

    "item_pavise",
	"item_pipe",--
    "item_solar_crest",--
	"item_lotus_orb",--
	"item_aghanims_shard",
	"item_spirit_vessel",--
	"item_ultimate_scepter",
	"item_shivas_guard",--
	"item_mystic_staff",
	"item_ultimate_scepter_2",
    "item_moon_shard",
	"item_sheepstick",--
}

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

local Void              = SafeAbility(bot:GetAbilityByName('night_stalker_void'), 'night_stalker_void', 'night_stalker')
local CripplingFear     = SafeAbility(bot:GetAbilityByName('night_stalker_crippling_fear'), 'night_stalker_crippling_fear', 'night_stalker')
local HunterInTheNight  = SafeAbility(bot:GetAbilityByName('night_stalker_hunter_in_the_night'), 'night_stalker_hunter_in_the_night', 'night_stalker')
local MidnightFeast     = SafeAbility(bot:GetAbilityByName('night_stalker_midnight_feast'), 'night_stalker_midnight_feast', 'night_stalker')
local DarkAscension     = SafeAbility(bot:GetAbilityByName('night_stalker_darkness'), 'night_stalker_darkness', 'night_stalker')

local VoidDesire, VoidTarget
local CripplingFearDesire
local HunterInTheNightDesire, HunterInTheNightTarget
local MidnightFeastDesire, MidnightFeastTarget
local DarkAscensionDesire

local botTarget
local bGoingOnSomeone
local bAttacking
local nBotMP
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = Fu.GetMP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    DarkAscensionDesire = X.ConsiderDarkAscension()
    if DarkAscensionDesire > 0
    then
        bot:Action_UseAbility(DarkAscension)
        return
    end

    CripplingFearDesire = X.ConsiderCripplingFear()
    if CripplingFearDesire > 0
    then
        bot:Action_UseAbility(CripplingFear)
        return
    end

    VoidDesire, VoidTarget = X.ConsiderVoid()
    if VoidDesire > 0
    then
        if bot:HasScepter()
        then
            bot:Action_UseAbilityOnLocation(Void, VoidTarget)
        else
            bot:Action_UseAbilityOnEntity(Void, VoidTarget)
        end

        return
    end

    HunterInTheNightDesire, HunterInTheNightTarget = X.ConsiderHunterInTheNight()
    if HunterInTheNightDesire > 0
    then
        bot:Action_UseAbilityOnEntity(HunterInTheNight, HunterInTheNightTarget)
        return
    end

    MidnightFeastDesire, MidnightFeastTarget = X.ConsiderMidnightFeast()
    if MidnightFeastDesire > 0
    then
        bot:Action_UseAbilityOnEntity(MidnightFeast, MidnightFeastTarget)
        return
    end
end

function X.ConsiderVoid()
    if not Void:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Void:GetCastRange()
    local nCastPoint = Void:GetCastPoint()
    local nRadius = 450
    local nDamage = Void:GetSpecialValueInt('damage')
    local nDuration = Void:GetSpecialValueFloat('duration_day')
    local timeOfDay = Fu.CheckTimeOfDay()
    botTarget = Fu.GetProperTarget(bot)

    if timeOfDay == 'night'
    then
        nDuration = Void:GetSpecialValueFloat('duration_night')
    end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            and timeOfDay == 'night'
            then
                if bot:HasScepter()
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                else
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                if bot:HasScepter()
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
                else
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

	if bInTeamFight
	then
        local strongestTarget = Fu.GetStrongestUnit(nCastRange, bot, true, false, nDuration)

        if bot:HasScepter()
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
            local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        else
            if strongestTarget == nil
            then
                strongestTarget = Fu.GetStrongestUnit(nCastRange, bot, true, true, nDuration)
            end

            if Fu.IsValidTarget(strongestTarget)
            and Fu.CanCastOnNonMagicImmune(strongestTarget)
            and not Fu.IsSuspiciousIllusion(strongestTarget)
            and not Fu.IsDisabled(strongestTarget)
            and not Fu.IsTaunted(strongestTarget)
            and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, strongestTarget
            end
        end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                if bot:HasScepter()
                and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
                and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not botTarget:HasModifier('modifier_legion_commander_duel')
                and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end
        end
	end

    if Fu.IsRetreating(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (Fu.GetHP(bot) < 0.52 and bot:WasRecentlyDamagedByAnyHero(2)))
            then
                if bot:HasScepter()
                then
                    return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)
                else
                    return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
                end
            end
        end
    end

    -- if Fu.IsLaning(bot)
	-- then
	-- 	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

	-- 	for _, creep in pairs(nEnemyLaneCreeps)
	-- 	do
	-- 		if Fu.IsValid(creep)
	-- 		and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
	-- 		and creep:GetHealth() <= nDamage
	-- 		then
	-- 			local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

	-- 			if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
    --             and nBotMP > 0.33
	-- 			then
	-- 				return BOT_ACTION_DESIRE_HIGH, creep
	-- 			end
	-- 		end
	-- 	end
	-- end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            if bot:HasScepter()
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            else
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            if bot:HasScepter()
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            else
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2.1)
        and not allyHero:IsIllusion()
        and nBotMP > 0.5
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(allyHero, nAllyInRangeEnemy[1], 400)
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsRunning(allyHero)
            and nAllyInRangeEnemy[1]:IsFacingLocation(allyHero:GetLocation(), 30)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                if bot:HasScepter()
                then
                    return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetLocation()
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderCripplingFear()
    if not CripplingFear:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = CripplingFear:GetSpecialValueInt('radius')
    botTarget = Fu.GetProperTarget(bot)

    if bInTeamFight
	then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius * 2)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius + 150)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if bAttacking
        and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.25
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
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

function X.ConsiderHunterInTheNight()
    if HunterInTheNight:IsPassive()
    or not HunterInTheNight:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = HunterInTheNight:GetSpecialValueInt('shard_cast_range')
    local timeOfDay = Fu.CheckTimeOfDay()

    if Fu.IsFarming(bot)
    then
        local nCreeps = bot:GetNearbyCreeps(nCastRange, true)
        if nCreeps ~= nil and #nCreeps >= 1
        then
            if Fu.IsValid(nCreeps[1])
            and (not nCreeps[1]:IsAncientCreep()
                or (timeOfDay == 'night' and nCreeps[1]:IsAncientCreep()))
            and (Fu.GetHP(bot) < 0.65 or nBotMP < 0.5)
            then
                return BOT_ACTION_DESIRE_HIGH, nCreeps[1]
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderDarkAscension()
    if not DarkAscension:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    botTarget = Fu.GetProperTarget(bot)

    if bInTeamFight
    then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1000)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 600)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderMidnightFeast()
    if not Fu.CanCastAbility(MidnightFeast)
    or (Fu.IsRetreating(bot) and Fu.IsRealInvisible(bot)
        and #Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE) > 0)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nEnemyCreeps = bot:GetNearbyCreeps(650, true)

    if  Fu.IsValid(nEnemyCreeps[1])
    and Fu.CanBeAttacked(nEnemyCreeps[1])
    and Fu.CanCastOnTargetAdvanced(nEnemyCreeps[1])
    and not nEnemyCreeps[1]:IsAncientCreep()
    and not nEnemyCreeps[1]:IsDominated()
    then
        if Fu.GetHP(bot) < 0.5 or (nBotMP < 0.5 and Fu.GetHP(bot) < 0.75) then
            return BOT_ACTION_DESIRE_HIGH, nEnemyCreeps[1]
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X