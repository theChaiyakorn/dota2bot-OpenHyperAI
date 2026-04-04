local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {--pos4,5
                        ['t25'] = {0, 10},
                        ['t20'] = {10, 0},
                        ['t15'] = {10, 0},
                        ['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,3,2,3,6,3,2,2,2,6,1,1,1,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_mage_outfit",
	"item_shadow_amulet",
	"item_shivas_guard",
	"item_cyclone",
	"item_glimmer_cape",
    "item_ultimate_scepter",
	"item_sheepstick",
    "item_aghanims_shard",
	"item_bloodthorn",
	"item_wind_waker",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_circlet",

	"item_magic_wand",
	"item_boots",
	"item_ring_of_basilius",
	"item_arcane_boots",
	"item_shivas_guard",--
	"item_rod_of_atos",
	"item_gungir",--
	"item_cyclone",
	"item_bloodstone",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	'item_heavens_halberd',--
    "item_wind_waker",
	"item_refresher",--
    "item_travel_boots",
    "item_travel_boots_2",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
    "item_blood_grenade",
	"item_priest_outfit",
	"item_mekansm",
	"item_glimmer_cape",
	"item_guardian_greaves",
    "item_ultimate_scepter",
	"item_spirit_vessel",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_sheepstick",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_pipe",
    "item_ultimate_scepter",
	"item_spirit_vessel",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_sheepstick",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

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

local StrokeOfFate      = bot:GetAbilityByName('grimstroke_dark_artistry')
local PhantomsEmbrace   = bot:GetAbilityByName('grimstroke_ink_creature')
local InkSwell          = bot:GetAbilityByName('grimstroke_spirit_walk')
local InkExplosion      = bot:GetAbilityByName('grimstroke_return')
local DarkPortrait      = bot:GetAbilityByName('grimstroke_dark_portrait')
local SoulBind          = bot:GetAbilityByName('grimstroke_soul_chain')

local StrokeOfFateDesire, StrokeOfFateLocation
local PhantomsEmbraceDesire, PhantomsEmbraceTarget
local InkSwellDesire, InkSwellTarget
local InkExplosionDesire
local DarkPortraitDesire, DarkPortraitTarget
local SoulBindDesire, SoulBindTarget

local InkSwellCastTime = -1

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

    botTarget = ctx.target

    InkSwellDesire, InkSwellTarget = X.ConsiderInkSwell()
    if InkSwellDesire > 0
    then
        bot:Action_UseAbilityOnEntity(InkSwell, InkSwellTarget)
        InkSwellCastTime = DotaTime()
        return
    end

    InkExplosionDesire = X.ConsiderInkExplosion()
    if InkExplosionDesire > 0
    then
        bot:Action_UseAbility(InkExplosion)
        return
    end

    SoulBindDesire, SoulBindTarget = X.ConsiderSoulBind()
    if SoulBindDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SoulBind, SoulBindTarget)
        return
    end

    PhantomsEmbraceDesire, PhantomsEmbraceTarget = X.ConsiderPhantomsEmbrace()
    if PhantomsEmbraceDesire > 0
    then
        bot:Action_UseAbilityOnEntity(PhantomsEmbrace, PhantomsEmbraceTarget)
        return
    end

    StrokeOfFateDesire, StrokeOfFateLocation = X.ConsiderStrokeOfFate()
    if StrokeOfFateDesire > 0
    then
        bot:Action_UseAbilityOnLocation(StrokeOfFate, StrokeOfFateLocation)
        return
    end

    DarkPortraitDesire, DarkPortraitTarget = X.ConsiderDarkPortrait()
    if DarkPortraitDesire > 0
    then
        bot:Action_UseAbilityOnEntity(DarkPortrait, DarkPortraitTarget)
        return
    end
end

function X.ConsiderStrokeOfFate()
    if not StrokeOfFate:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, StrokeOfFate:GetCastRange())
	local nCastPoint = StrokeOfFate:GetCastPoint()
	local nRadius = StrokeOfFate:GetSpecialValueInt('end_radius')
	local nSpeed = StrokeOfFate:GetSpecialValueInt('projectile_speed')
    local nDamage = StrokeOfFate:GetSpecialValueInt('damage')
    local nAbilityLevel = StrokeOfFate:GetLevel()

	local nEnemyHeroes = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nDelay = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay)
		end
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
		then
            local nInRangeAlly = botTarget:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = botTarget:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and (#nInRangeAlly >= #nInRangeEnemy or Fu.WeAreStronger(bot, 1600))
            then
                local nDelay = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)

                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
                and not Fu.IsRunning(botTarget)
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nDelay)
                end
            end
		end
	end

    if bRetreating
    then
        local nInRangeAlly = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
        local nInRangeEnemy = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and (#nInRangeEnemy > #nInRangeAlly or not Fu.WeAreStronger(bot, 1600))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and not Fu.IsInRange(bot, nInRangeEnemy[1], 300)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
        end
    end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and Fu.GetManaAfter(StrokeOfFate:GetManaCost()) > 0.4
    and nAbilityLevel >= 3
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
		if nLocationAoE.count >= 2
        then
            local weakTarget = Fu.GetVulnerableUnitNearLoc(bot, true, true, nCastRange, nRadius, nLocationAoE.targetloc)
            if weakTarget ~= nil
            then
                local nDelay = (GetUnitToUnitDistance(bot, weakTarget) / nSpeed) + nCastPoint
                return BOT_ACTION_DESIRE_HIGH, weakTarget:GetExtrapolatedLocation(nDelay)
            end
		end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        and nEnemyHeroes ~= nil and #nEnemyHeroes == 0
        and not Fu.IsRunning(nEnemyLaneCreeps[1])
        and not Fu.IsThereNonSelfCoreNearby(1000)
        then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end
	end

    local nAllyHeroes = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:GetActiveModeDesire() >= 0.5
        and not allyHero:IsIllusion()
        then
            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsChasingTarget(nAllyInRangeEnemy[1], bot)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nDelay = (GetUnitToUnitDistance(bot, nAllyInRangeEnemy[1]) / nSpeed) + nCastPoint
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetExtrapolatedLocation(nDelay)
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and Fu.GetHP(botTarget) < 0.5
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderPhantomsEmbrace()
    if not PhantomsEmbrace:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, PhantomsEmbrace:GetCastRange())
    local nDuration = PhantomsEmbrace:GetSpecialValueInt('latch_duration')
    local nDamagePerSec = PhantomsEmbrace:GetSpecialValueInt('damage_per_second')
    local nRendDamage = PhantomsEmbrace:GetSpecialValueInt('pop_damage')

    local nEnemyHeroes = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamagePerSec * nDuration + nRendDamage, DAMAGE_TYPE_PHYSICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not StrokeOfFate:IsFullyCastable()
		then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
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
		then
            local nInRangeAlly = botTarget:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = botTarget:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and (#nInRangeAlly >= #nInRangeEnemy or Fu.WeAreStronger(bot, 1600))
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
		end
	end

    if bRetreating
	then
        local nInRangeEnemy = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
        if Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.CanCastOnTargetAdvanced(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nInRangeAlly = nInRangeEnemy[1]:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = nInRangeEnemy[1]:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly or not Fu.WeAreStronger(bot, 1200))
                or bot:WasRecentlyDamagedByAnyHero(1))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
            end
        end
	end

    local nAllyHeroes = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsChasingTarget(nAllyInRangeEnemy[1], bot)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderInkSwell()
    if not InkSwell:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, InkSwell:GetCastRange())
	local nRadius = InkSwell:GetSpecialValueInt('radius')

    local nEnemyHeroes = bot:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and enemyHero:IsChanneling()
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not Fu.IsDisabled(enemyHero)
		then
            return BOT_ACTION_DESIRE_HIGH, bot
		end
    end

    local nAllyHeroes = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nInRangeAllyEnemy = allyHero:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and not Fu.IsSuspiciousIllusion(allyHero)
        then
            for _, allyEnemyHero in pairs(nInRangeAllyEnemy)
            do
                if Fu.IsValidHero(allyEnemyHero)
                and Fu.CanCastOnNonMagicImmune(allyEnemyHero)
                and allyEnemyHero:IsChanneling()
                and not Fu.IsSuspiciousIllusion(allyEnemyHero)
                and not Fu.IsDisabled(allyEnemyHero)
                and not allyEnemyHero:HasModifier('modifier_enigma_black_hole_pull')
                and not allyEnemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not allyEnemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end
    end

    local dist = 1600
    local targetAlly = nil

    for _, allyHero in pairs(nAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsValidTarget(botTarget)
        and not Fu.IsSuspiciousIllusion(allyHero)
        and GetUnitToUnitDistance(allyHero, botTarget) < dist
        then
            targetAlly = allyHero
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nInRangeAlly = botTarget:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            local nInRangeEnemy = botTarget:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and (#nInRangeAlly >= #nInRangeEnemy or Fu.WeAreStronger(bot, 1600))
            and targetAlly ~= nil
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(targetAlly:GetLocation(), nRadius)
                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, targetAlly
                end
            end
        end
    end

    if bRetreating
    and bot:GetActiveModeDesire() > 0.75
    and not StrokeOfFate:IsFullyCastable()
	then
        local nInRangeEnemy = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
        if Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nInRangeAlly = nInRangeEnemy[1]:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = nInRangeEnemy[1]:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly or not Fu.WeAreStronger(bot, 1600))
                or bot:WasRecentlyDamagedByAnyHero(1) and Fu.GetHP(bot) < 0.75)
            then
                return BOT_ACTION_DESIRE_HIGH, bot
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
            return BOT_ACTION_DESIRE_HIGH, bot
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderInkExplosion()
    if InkExplosion:IsHidden()
    or not InkExplosion:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = InkSwell:GetSpecialValueInt('radius')
    local nDuration = InkSwell:GetSpecialValueInt('buff_duration')

    if DotaTime() < InkSwellCastTime + nDuration
    then
        local nEnemyHeroes = bot:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and enemyHero:IsChanneling()
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and bot:HasModifier('modifier_grimstroke_spirit_walk_buff')
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end

        for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
        do
            local nInRangeAllyEnemy = allyHero:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE)
            if Fu.IsValidHero(allyHero)
            then
                for _, allyEnemyHero in pairs(nInRangeAllyEnemy)
                do
                    if Fu.IsValidHero(allyEnemyHero)
                    and Fu.CanCastOnNonMagicImmune(allyEnemyHero)
                    and allyEnemyHero:IsChanneling()
                    and not Fu.IsSuspiciousIllusion(allyEnemyHero)
                    and not Fu.IsDisabled(allyEnemyHero)
                    and allyHero:HasModifier('modifier_grimstroke_spirit_walk_buff')
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSoulBind()
    if not SoulBind:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nRadius = SoulBind:GetSpecialValueInt('chain_latch_radius')
    local nDuration = SoulBind:GetSpecialValueInt('chain_duration')

    if bGoingOnSomeone
    then
        local strongestTarget = Fu.GetStrongestUnit(1200, bot, true, true, nDuration)
        if strongestTarget == nil
        then
            strongestTarget = Fu.GetStrongestUnit(1200, bot, true, false, nDuration)
        end

        if Fu.IsValidHero(strongestTarget)
        and not Fu.IsSuspiciousIllusion(strongestTarget)
        and not strongestTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not strongestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nInRangeAlly = strongestTarget:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            local nInRangeEnemy = strongestTarget:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetEnemiesNearLoc(strongestTarget:GetLocation(), nRadius)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and (#nInRangeAlly >= #nInRangeEnemy or Fu.WeAreStronger(bot, 1600))
            and nTargetInRangeAlly ~= nil and #nTargetInRangeAlly >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, strongestTarget
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderDarkPortrait()
    if not DarkPortrait:IsTrained()
    or not DarkPortrait:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if bGoingOnSomeone
    then
        local strongestTarget = Fu.GetStrongestUnit(1600, bot, true, true, 5)
        if strongestTarget == nil
        then
            strongestTarget = Fu.GetStrongestUnit(1600, bot, true, false, 5)
        end

        if Fu.IsValidHero(strongestTarget)
        and not Fu.IsSuspiciousIllusion(strongestTarget)
        and not Fu.IsDisabled(strongestTarget)
        and not strongestTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not strongestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nInRangeAlly = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            local nInRangeEnemy = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and (#nInRangeAlly >= #nInRangeEnemy or Fu.WeAreStronger(bot, 1600))
            then
                return BOT_ACTION_DESIRE_HIGH, strongestTarget
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X