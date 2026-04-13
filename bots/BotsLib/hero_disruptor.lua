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
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{2,1,2,3,2,6,2,3,3,3,6,1,1,1,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_magic_wand",
    "item_arcane_boots",
    "item_glimmer_cape",--
    "item_force_staff",
	"item_guardian_greaves",--
    "item_hurricane_pike",--
    "item_sheepstick",--
	"item_shivas_guard",
    "item_wind_waker",--
    "item_aghanims_shard",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_magic_wand",
    "item_tranquil_boots",
    "item_glimmer_cape",--
    "item_pavise",
    "item_force_staff",
	"item_pipe",--
    "item_solar_crest",--
    "item_boots_of_bearing",--
    "item_hurricane_pike",--
    "item_sheepstick",--
    -- "item_wind_waker",--
    "item_aghanims_shard",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_double_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_magic_wand",
    "item_arcane_boots",
    "item_glimmer_cape",--
    "item_force_staff",
    "item_maelstrom",
	"item_gungir",--
	"item_shivas_guard",
    "item_hurricane_pike",--
    "item_sheepstick",--
    "item_wind_waker",--
    "item_aghanims_shard",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]


X['sSellList'] = {

	"item_ultimate_scepter",
	"item_magic_wand",

	"item_cyclone",
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

local ThunderStrike = SafeAbility(bot:GetAbilityByName('disruptor_thunder_strike'), 'disruptor_thunder_strike', 'disruptor')
local Glimpse       = SafeAbility(bot:GetAbilityByName('disruptor_glimpse'), 'disruptor_glimpse', 'disruptor')
local KineticField  = SafeAbility(bot:GetAbilityByName('disruptor_kinetic_field'), 'disruptor_kinetic_field', 'disruptor')
local KineticFence  = SafeAbility(bot:GetAbilityByName('disruptor_kinetic_fence'), 'disruptor_kinetic_fence', 'disruptor')
local StaticStorm   = SafeAbility(bot:GetAbilityByName('disruptor_static_storm'), 'disruptor_static_storm', 'disruptor')

local ThunderStrikeDesire, ThunderStrikeTarget
local GlimpseDesire, GlimpseTarget
local KineticFieldDesire, KineticFieldLocation
local KineticFenceDesire, KineticFenceLocation
local StaticStormDesire, StaticStormLocation
local KineticFenceUsedTime = 0

local KineticStormDesire, KineticStormLocation

local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)
	bInTeamFight = ctx.isTeamFight

    botTarget = ctx.target

    KineticStormDesire, KineticStormLocation = X.ConsiderKineticStorm()
    if KineticStormDesire > 0
    then
        bot:Action_ClearActions(false)
        bot:ActionQueue_UseAbilityOnLocation(StaticStorm, KineticStormLocation)
        bot:ActionQueue_Delay(0.05)
        bot:ActionQueue_UseAbilityOnLocation(KineticField, KineticStormLocation)
        bot:ActionQueue_Delay(0.05)
        return
    end

    StaticStormDesire, StaticStormLocation = X.ConsiderStaticStorm()
    if StaticStormDesire > 0
    then
        bot:Action_UseAbilityOnLocation(StaticStorm, StaticStormLocation)
        return
    end

    KineticFieldDesire, KineticFieldLocation = X.ConsiderKineticField()
    if KineticFieldDesire > 0
    then
        bot:Action_UseAbilityOnLocation(KineticField, KineticFieldLocation)
        return
    end

    KineticFenceDesire, KineticFenceLocation = X.ConsiderKineticFence()
    if KineticFenceDesire > 0
    then
        bot:Action_UseAbilityOnLocation(KineticFence, KineticFenceLocation)
        KineticFenceUsedTime = DotaTime()
        return
    end

    ThunderStrikeDesire, ThunderStrikeTarget = X.ConsiderThunderStrike()
    if ThunderStrikeDesire > 0
    then
        bot:Action_UseAbilityOnEntity(ThunderStrike, ThunderStrikeTarget)
        return
    end

    GlimpseDesire, GlimpseTarget = X.ConsiderGlimpse()
    if GlimpseDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Glimpse, GlimpseTarget)
        return
    end
end

function X.ConsiderThunderStrike()
    if not ThunderStrike:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, ThunderStrike:GetCastRange())
    local nRadius = ThunderStrike:GetSpecialValueInt('radius')
	local nDamage = ThunderStrike:GetSpecialValueInt('strike_damage')
    local nStikesCount = ThunderStrike:GetSpecialValueInt('strikes')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidTarget(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage * nStikesCount, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and Fu.IsCore(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2)
        and allyHero:GetActiveModeDesire() >= 0.5
        and not allyHero:IsIllusion()
        and not Glimpse:IsFullyCastable()
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

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + 300)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
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
    and bot:GetActiveModeDesire() > 0.5
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
	end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        then
            for _, creep in pairs(nEnemyLaneCreeps)
            do
                if Fu.IsValid(creep)
                and Fu.CanBeAttacked(creep)
                then
                    local nCreepCountAround = Fu.GetNearbyAroundLocationUnitCount(true, false, nRadius, creep:GetLocation())
                    if nCreepCountAround >= 3
                    then
                        return BOT_ACTION_DESIRE_HIGH, creep
                    end
                end
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
	then
        -- Remove Spell Block
		if Fu.IsRoshan(botTarget)
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
    if Fu.IsDoingTormentor(bot)
    then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
    for _, creep in pairs(nNeutralCreeps)
    do
        if Fu.IsValid(creep)
        and Fu.CanBeAttacked(creep)
        and creep:GetHealth() > nDamage * nStikesCount / 2
        and creep:GetHealth() <= nDamage * nStikesCount
        then
            return BOT_ACTION_DESIRE_HIGH, creep
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderGlimpse()
    if not Glimpse:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Glimpse:GetCastRange())
    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and (enemyHero:IsChanneling()
		or (bot:GetActiveMode() == BOT_MODE_ATTACK
            and (nAllyHeroes ~= nil and #nAllyHeroes <= 3 and #nEnemyHeroes <= 2)
            and bot:IsFacingLocation(enemyHero:GetLocation(), 30)
            and enemyHero:IsFacingLocation(Fu.GetEnemyFountain(), 30)))
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
		then
            if enemyHero:HasModifier('modifier_teleporting')
            or enemyHero:HasModifier('modifier_fountain_aura_buff')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if bGoingOnSomeone
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)
                if Fu.IsChasingTarget(bot, enemyHero)
                and enemyHero:GetCurrentMovementSpeed() > bot:GetCurrentMovementSpeed()
                and nInRangeAlly ~= nil and #nInRangeAlly >= #nEnemyHeroes
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
		end
	end

    if bRetreating
    and bot:GetActiveModeDesire() >= 0.75
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsRealInvisible(bot)
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
	end

    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and Fu.IsCore(allyHero)
        and allyHero:GetActiveModeDesire() >= 0.75
        and allyHero:WasRecentlyDamagedByAnyHero(2)
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

    local realHeroCount = 0
    local illuHeroCount = 0
    local illuTarget = nil

    for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and Glimpse:GetLevel() >= 3
		then
            if Fu.IsSuspiciousIllusion(enemyHero)
            then
                illuHeroCount = illuHeroCount + 1
                illuTarget = enemyHero
            else
                realHeroCount = realHeroCount + 1
            end
        end
    end

    if realHeroCount == 0 and illuHeroCount >= 1
    then
        return BOT_ACTION_DESIRE_HIGH, illuTarget
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderKineticFence()
    if not Fu.CanCastAbility(KineticFence)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end
    local nDuration = KineticFence:GetSpecialValueInt('duration')
    if not Fu.CanCastAbility(KineticFence) or DotaTime() < KineticFenceUsedTime + nDuration then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, KineticFence:GetCastRange())
	local nCastPoint = KineticFence:GetCastPoint()
	local nRadius = KineticFence:GetSpecialValueInt('radius')
    local nDelay = KineticFence:GetSpecialValueInt('formation_time')

	local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if bInTeamFight then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint + nDelay, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
		if #nInRangeEnemy >= 2 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
    end

    if bGoingOnSomeone then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nLocationAoE = bot:FindAoELocation(true, true, botTarget:GetLocation(), 0, nRadius, nCastPoint, 0)
            local vAoELocation = nLocationAoE.targetloc
            local botTargetLocation = Fu.GetCorrectLoc(botTarget, nDelay)

            if #nEnemyHeroes <= 1 then
                if Fu.IsChasingTarget(bot, botTarget) then
                    if nLocationAoE.count >= 2 then
                        return BOT_ACTION_DESIRE_HIGH, vAoELocation
                    else
                        return BOT_ACTION_DESIRE_HIGH, botTargetLocation
                    end
                end
            else
                if nLocationAoE.count >= 2 then
                    return BOT_ACTION_DESIRE_HIGH, vAoELocation
                else
                    return BOT_ACTION_DESIRE_HIGH, botTargetLocation
                end
            end
		end
	end

    if  bRetreating
    and not Fu.IsRealInvisible(bot)
    and bot:GetActiveModeDesire() > 0.9
	then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if  Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + Fu.GetCorrectLoc(enemyHero, nDelay)) / 2
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderKineticField()
    if not Fu.CanCastAbility(KineticField)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, KineticField:GetCastRange())
	local nCastPoint = KineticField:GetCastPoint()
	local nRadius = KineticField:GetSpecialValueInt('radius')

	if bInTeamFight
    and not CanCastKineticStorm()
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius * 0.8, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius * 0.8)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:IsMagicImmune()
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1400, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1400, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if #nInRangeEnemy == 0
                then
                    if Fu.IsChasingTarget(bot, botTarget)
                    then
                        if Fu.IsInRange(bot, botTarget, nCastRange)
                        then
                            return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
                        end

                        if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
                        and not Fu.IsInRange(bot, botTarget, nCastRange)
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                        end
                    end
                else
                    if Fu.IsInRange(bot, botTarget, nCastRange)
                    then
                        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius * 0.8)
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        else
                            return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
                        end
                    end

                    if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
                    and not Fu.IsInRange(bot, botTarget, nCastRange)
                    then
                        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius * 0.8)
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                        else
                            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                        end
                    end
                end
            end
		end
	end

    local desireCheck = RemapValClamped(KineticField:GetLevel(), 1, 4, 0.75, 0.5)
    if bRetreating
    and bot:GetActiveModeDesire() >= desireCheck
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        then
            if Fu.IsValidHero(nInRangeEnemy[1])
            and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
            and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
            and not Fu.IsDisabled(nInRangeEnemy[1])
            and not nInRangeEnemy[1]:IsMagicImmune()
            and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    if GetUnitToLocationDistance(bot, nInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)) > nRadius
                    then
                        return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
                    else
                        return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + nInRangeEnemy[1]:GetLocation()) / 2
                    end
                end
            end
        end
	end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and Fu.IsCore(allyHero)
        and allyHero:GetActiveModeDesire() >= 0.75
        and allyHero:WasRecentlyDamagedByAnyHero(2)
        and not allyHero:IsIllusion()
        and not bGoingOnSomeone
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsChasingTarget(nAllyInRangeEnemy[1], bot)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:IsMagicImmune()
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            and GetUnitToUnitDistance(allyHero, nAllyInRangeEnemy[1]) < GetUnitToUnitDistance(bot, nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, (allyHero:GetLocation() + nAllyInRangeEnemy[1]:GetLocation()) / 2
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderStaticStorm()
	if not StaticStorm:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = StaticStorm:GetSpecialValueInt('radius')
	local nCastRange = StaticStorm:GetCastRange()

	if bInTeamFight
    and not CanCastKineticStorm()
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius * 0.8, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius * 0.8)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nCastRange
        and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
        and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderKineticStorm()
    if CanCastKineticStorm()
    then
	    local nCastRange = Fu.GetProperCastRange(false, bot, KineticField:GetCastRange())
        local nRadius = KineticField:GetSpecialValueInt('radius')

        if bInTeamFight
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius * 0.8, 0, 0)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius * 0.8)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
            and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nCastRange
            and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
            and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function CanCastKineticStorm()
    if Fu.CanCastAbility(KineticField)
    and StaticStorm:IsFullyCastable()
    then
        local nManaCost = KineticField:GetManaCost() + StaticStorm:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

return X