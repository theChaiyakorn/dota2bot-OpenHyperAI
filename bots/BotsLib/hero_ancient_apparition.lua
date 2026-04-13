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
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{3,1,3,2,3,6,2,1,3,1,6,2,1,2,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {

	"item_crystal_maiden_outfit",
	"item_force_staff",
	"item_hand_of_midas",
	"item_ultimate_scepter",
	"item_aghanims_shard",
	"item_orchid",
	"item_black_king_bar",--
	"item_hurricane_pike",--
	"item_travel_boots",
	"item_ultimate_scepter_2",
	"item_bloodthorn",--
	"item_travel_boots_2",--
	"item_mystic_staff",--
	"item_sheepstick",--

}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
    "item_blood_grenade",

	'item_priest_outfit',
	"item_mekansm",
	"item_glimmer_cape",--
	"item_aghanims_shard",
	"item_guardian_greaves",--
	"item_spirit_vessel",--
	--"item_holy_locket",
	"item_ultimate_scepter",
	"item_sheepstick",--
	"item_mystic_staff",--
	"item_ultimate_scepter_2",
	"item_shivas_guard",--

}

sRoleItemsBuyList['pos_5'] = {

	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",--
	"item_boots_of_bearing",--
	"item_pipe",--
	--"item_holy_locket",
	"item_ultimate_scepter",
	"item_aghanims_shard",
	"item_mystic_staff",--
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_cyclone",
    "item_wind_waker",--
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

Pos4SellList = {
	"item_magic_wand",
}

Pos5SellList = {
	"item_magic_wand",
}

X['sSellList'] = {
	"item_ultimate_scepter",
	"item_magic_wand",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local ColdFeet          = SafeAbility(bot:GetAbilityByName('ancient_apparition_cold_feet'), 'ancient_apparition_cold_feet', 'ancient_apparition')
local IceVortex         = SafeAbility(bot:GetAbilityByName('ancient_apparition_ice_vortex'), 'ancient_apparition_ice_vortex', 'ancient_apparition')
local ChillingTouch     = SafeAbility(bot:GetAbilityByName('ancient_apparition_chilling_touch'), 'ancient_apparition_chilling_touch', 'ancient_apparition')
local IceBlast          = SafeAbility(bot:GetAbilityByName('ancient_apparition_ice_blast'), 'ancient_apparition_ice_blast', 'ancient_apparition')
local IceBlastRelease   = SafeAbility(bot:GetAbilityByName('ancient_apparition_ice_blast_release'), 'ancient_apparition_ice_blast_release', 'ancient_apparition')

local ColdFeetAoETalent = SafeAbility(bot:GetAbilityByName('special_bonus_unique_ancient_apparition_7'), 'special_bonus_unique_ancient_apparition_7', 'ancient_apparition')

local ColdFeetDesire, ColdFeetTarget
local IceVortexDesire, IceVortextLocation
local ChillingTouchDesire, ChillingTouchTarget
local IceBlastDesire, IceBlastLocation
local IceBlastReleaseDesire

local IceBlastReleaseLocation

local botTarget
local bGoingOnSomeone
local bRetreating
local bAttacking
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)

    IceBlastReleaseDesire = X.ConsiderIceBlastRelease()
    if IceBlastReleaseDesire > 0
    then
        bot:Action_UseAbility(IceBlastRelease)
        return
    end

    IceBlastDesire, IceBlastLocation = X.ConsiderIceBlast()
    if IceBlastDesire > 0
    then
        bot:Action_UseAbilityOnLocation(IceBlast, IceBlastLocation)
        IceBlastReleaseLocation = IceBlastLocation
        return
    end

    IceVortexDesire, IceVortextLocation = X.ConsiderIceVortex()
    if IceVortexDesire > 0
    then
        bot:Action_UseAbilityOnLocation(IceVortex, IceVortextLocation)
        return
    end

    ColdFeetDesire, ColdFeetTarget = X.ConsiderColdFeet()
    if ColdFeetDesire > 0
    then
        if ColdFeetAoETalent:IsTrained()
        then
            local nAoERadius = 450
            local nCastRange = Fu.GetProperCastRange(false, bot, ColdFeet:GetCastRange())
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nAoERadius, 0, 0)

            if nLocationAoE.count >= 2
            then
                bot:Action_UseAbilityOnLocation(ColdFeet, nLocationAoE.targetloc)
            else
                bot:Action_UseAbilityOnEntity(ColdFeet, ColdFeetTarget)
            end
        else
            bot:Action_UseAbilityOnEntity(ColdFeet, ColdFeetTarget)
        end

        return
    end

    ChillingTouchDesire, ChillingTouchTarget = X.ConsiderChillingTouch()
    if ChillingTouchDesire > 0
    then
        bot:Action_UseAbilityOnEntity(ChillingTouch, ChillingTouchTarget)
        return
    end
end

function X.ConsiderColdFeet()
    if not ColdFeet:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ColdFeet:GetCastRange())
    botTarget = Fu.GetProperTarget(bot)

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 150, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1.5)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_cold_feet')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
        end
    end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        then
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if (#nInRangeAlly > #nInRangeEnemy
                    or bot:WasRecentlyDamagedByHero(enemyHero, 1.5))
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.CanCastOnTargetAdvanced(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                and not enemyHero:HasModifier('modifier_cold_feet')
                and not enemyHero:HasModifier('modifier_ice_vortex')
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not botTarget:HasModifier('modifier_cold_feet')
        and not botTarget:HasModifier('modifier_ice_vortex')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not botTarget:HasModifier('modifier_cold_feet')
        and not botTarget:HasModifier('modifier_ice_vortex')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderIceVortex()
    if not IceVortex:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, IceVortex:GetCastRange())
    local nRadius = IceVortex:GetSpecialValueInt('radius')
    local nCastPoint = IceVortex:GetCastPoint()
    botTarget = Fu.GetProperTarget(bot)

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nCastRange
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_ice_vortex')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        then
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if (#nInRangeAlly > #nInRangeEnemy
                    or bot:WasRecentlyDamagedByHero(enemyHero, 1.5))
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                and not enemyHero:HasModifier('modifier_cold_feet')
                and not enemyHero:HasModifier('modifier_ice_vortex')
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
                end
            end
        end
    end

    if (Fu.IsDefending(bot) or Fu.IsPushing(bot))
    and not Fu.IsThereNonSelfCoreNearby(1000)
	then
		local nEnemyLanecreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nEnemyLanecreeps ~= nil and #nEnemyLanecreeps >= 4
        and nLocationAoE.count >= 4 and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nCastRange
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        if nLocationAoE.count >= 2 and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nCastRange
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderChillingTouch()
    if not ChillingTouch:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ChillingTouch:GetCastRange()) + ChillingTouch:GetSpecialValueInt('attack_range_bonus')
    local nDamage = ChillingTouch:GetSpecialValueInt('damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 50, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 50, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1.5)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
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

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        then
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if (#nInRangeAlly > #nInRangeEnemy
                    or bot:WasRecentlyDamagedByHero(enemyHero, 1.2))
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.CanCastOnTargetAdvanced(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderIceBlast()
    if not IceBlast:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nMinRadius = IceBlast:GetSpecialValueInt('radius_min')
    local nGrowSpeed = IceBlast:GetSpecialValueInt('radius_grow')
    local nMaxRadius = IceBlast:GetSpecialValueInt('radius_max')

    if Fu.IsInTeamFight(bot, 1600)
    then
        local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

        if nTeamFightLocation ~= nil
        then
            local dist = GetUnitToLocationDistance(bot, nTeamFightLocation)
            local nRadius = math.min(nMinRadius + (dist * nGrowSpeed), nMaxRadius)
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 1600, nRadius, 0, 0)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

    if nTeamFightLocation ~= nil
    then
        local dist = GetUnitToLocationDistance(bot, nTeamFightLocation)
        local nRadius = math.min(nMinRadius + (dist * nGrowSpeed), nMaxRadius)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nTeamFightLocation, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nTeamFightLocation
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderIceBlastRelease()
    if IceBlastRelease:IsHidden()
    or not IceBlastRelease:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nProjectiles = GetLinearProjectiles()

    for _, p in pairs(nProjectiles)
	do
		if p ~= nil and p.ability:GetName() == "ancient_apparition_ice_blast"
        then
			if IceBlastReleaseLocation ~= nil
            and Fu.GetLocationToLocationDistance(IceBlastReleaseLocation, p.location) < 100
            then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

return X