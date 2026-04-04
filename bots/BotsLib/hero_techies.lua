local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local TU            = require( GetScriptDirectory()..'/FuncLib/hero/techies' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {--pos4,5
                        ['t25'] = {10, 0},
                        ['t20'] = {10, 0},
                        ['t15'] = {0, 10},
                        ['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,3,3,3,6,2,2,2,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_circlet",

    "item_boots",
    "item_magic_wand",
    "item_arcane_boots",
    "item_glimmer_cape",--
    "item_guardian_greaves",--
    "item_force_staff",--
    "item_lotus_orb",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_circlet",

    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
    "item_glimmer_cape",--
    "item_pipe",--
    "item_force_staff",--
    "item_boots_of_bearing",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_aghanims_shard",
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
    "item_glimmer_cape",--
    "item_kaya",
    "item_force_staff",--
    "item_kaya_and_sange",--
    "item_boots_of_bearing",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {
	"item_crystal_maiden_outfit",
    "item_kaya",
    "item_kaya_and_sange",--
    "item_aether_lens",
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_aghanims_shard",
	"item_octarine_core",--
    -- "item_sheepstick",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

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

local StickyBomb        = bot:GetAbilityByName('techies_sticky_bomb')
local ReactiveTazer     = bot:GetAbilityByName('techies_reactive_tazer')
local ReactiveTazerStop = bot:GetAbilityByName('techies_reactive_tazer_stop')
local BlastOff          = bot:GetAbilityByName('techies_suicide')
local MineFieldSign     = bot:GetAbilityByName('techies_minefield_sign')
local ProximityMines    = bot:GetAbilityByName('techies_land_mines')

local StickyBombDesire, StickyBombLocation
local ReactiveTazerDesire
-- local ReactiveTazerStopDesire
local BlastOffDesire, BlastOffLocation
local MineFieldSignDesire, MineFieldSignLocation
local ProximityMinesDesire, ProximityMinesLocation

local MineCooldownTime = 0

local ComboDesire, ComboLocation

local botTarget, nBlastOffDamage, nPMineDamage, nPMineTotalDmg, nComboDmg

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = ctx.hp

    botTarget = ctx.target

    nBlastOffDamage = BlastOff:GetSpecialValueInt('damage')
    nPMineDamage = ProximityMines:GetSpecialValueInt('damage')
    nPMineTotalDmg = nPMineDamage * 2 -- ProximityMines:GetCurrentCharges()
    nComboDmg = nBlastOffDamage + nPMineTotalDmg

    ComboDesire, ComboLocation, Flag = X.ConsiderCombo()
    if ComboDesire > 0
    then
        bot:Action_ClearActions(false)
        local nCastPoint = BlastOff:GetCastPoint()
        local nLeapDuration = BlastOff:GetSpecialValueInt('stun_radius')

        if Flag == 1
        then
            if Fu.CheckBitfieldFlag(ReactiveTazer:GetBehavior(), ABILITY_BEHAVIOR_UNIT_TARGET)
            then
                bot:ActionQueue_UseAbilityOnEntity(ReactiveTazer, bot)
            else
                bot:ActionQueue_UseAbility(ReactiveTazer)
            end

            bot:ActionQueue_Delay(0.6)
            bot:ActionQueue_UseAbilityOnLocation(BlastOff, ComboLocation)
            bot:ActionQueue_Delay(nCastPoint + nLeapDuration)
            if not ReactiveTazerStop:IsHidden()
            then
                bot:ActionQueue_UseAbility(ReactiveTazerStop)
            end
        end

        return
    end

    StickyBombDesire, StickyBombLocation = X.ConsiderStickyBomb()
    if StickyBombDesire > 0
    then
        bot:Action_UseAbilityOnLocation(StickyBomb, StickyBombLocation)
        return
    end

    ReactiveTazerDesire = X.ConsiderReactiveTazer()
    if ReactiveTazerDesire > 0
    then
        if Fu.CheckBitfieldFlag(ReactiveTazer:GetBehavior(), ABILITY_BEHAVIOR_UNIT_TARGET)
        then
            bot:Action_UseAbilityOnEntity(ReactiveTazer, bot)
        else
            bot:Action_UseAbility(ReactiveTazer)
        end

        return
    end

    BlastOffDesire, BlastOffLocation = X.ConsiderBlastOff()
    if BlastOffDesire > 0
    then
        bot:Action_UseAbilityOnLocation(BlastOff, BlastOffLocation)
        return
    end

    ProximityMinesDesire, ProximityMinesLocation = X.ConsiderProximityMines()
    if ProximityMinesDesire > 0
    then
        bot:Action_UseAbilityOnLocation(ProximityMines, ProximityMinesLocation)
        MineCooldownTime = DotaTime()
        return
    end

    MineFieldSignDesire, MineFieldSignLocation = X.ConsiderMineFieldSign()
    if MineFieldSignDesire > 0
    then
        bot:Action_UseAbilityOnLocation(MineFieldSign, MineFieldSignLocation)
        return
    end
end

function X.ConsiderStickyBomb()
    if not StickyBomb:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, StickyBomb:GetCastRange())
    local nDamage = StickyBomb:GetSpecialValueInt('damage')
    local nSpeed = StickyBomb:GetSpecialValueInt('speed')
    local nAcceleration = StickyBomb:GetSpecialValueInt('acceleration')
    local nAbilityLevel = StickyBomb:GetLevel()

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
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
        then
            local eta = Fu.GetETAWithAcceleration(GetUnitToUnitDistance(bot, enemyHero), nSpeed, nAcceleration)
            if Fu.IsChasingTarget(bot, enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(eta)
            else
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nAllyInRangeEnemy)
        do
            if Fu.IsValidHero(allyHero)
            and Fu.IsRetreating(allyHero)
            and allyHero:WasRecentlyDamagedByAnyHero(1.5)
            and not allyHero:IsIllusion()
            then
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and Fu.IsChasingTarget(enemyHero, allyHero)
                and not Fu.IsDisabled(enemyHero)
                and not Fu.IsTaunted(enemyHero)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    local eta = Fu.GetETAWithAcceleration(GetUnitToUnitDistance(bot, enemyHero), nSpeed, nAcceleration)
                    if Fu.IsChasingTarget(enemyHero, allyHero)
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(eta)
                    else
                        return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                    end
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
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                local eta = Fu.GetETAWithAcceleration(GetUnitToUnitDistance(bot, botTarget), nSpeed, nAcceleration)
                if Fu.IsChasingTarget(bot, botTarget)
                then
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(eta)
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                end
            end
		end
	end

	if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
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
                    return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
                end
            end
        end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and nAbilityLevel >= 3
    and not Fu.IsThereNonSelfCoreNearby(1000)
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and Fu.GetMP(bot) > 0.5
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
	end

    if Fu.IsFarming(bot) and Fu.GetManaAfter(StickyBomb:GetManaCost()) > 0.3
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
        if nNeutralCreeps ~= nil
        then
            if #nNeutralCreeps >= 2
            or (#nNeutralCreeps >= 1 and Fu.IsValid(nNeutralCreeps[1]) and nNeutralCreeps[1]:IsAncientCreep())
            then
                return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]:GetLocation()
            end
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if nEnemyLaneCreeps ~= nil
        then
            if #nEnemyLaneCreeps >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                local nTowers = enemyHero:GetNearbyTowers(600, true)
                if nTowers ~= nil and #nTowers >= 1
                and Fu.IsValidBuilding(nTowers[1])
                and nTowers[1]:GetAttackTarget() == enemyHero
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                end
            end
        end

		for _, creep in pairs(nEnemyLaneCreeps)
		do
            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                table.insert(creepList, creep)
            end
		end

        if #creepList >= 2
        and Fu.GetMP(bot) > 0.35
        and Fu.CanBeAttacked(creepList[1])
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
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

    local creepList = {}
    local nCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
    for _, creep in pairs(nCreeps)
    do
        if Fu.IsValid(creep)
        and creep:GetHealth() <= nDamage
        then
            table.insert(creepList, creep)
        end
    end

    if #creepList >= 3
    and Fu.CanBeAttacked(creepList[1])
    and not Fu.IsThereNonSelfCoreNearby(1200)
    then
        return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderReactiveTazer()
    if not ReactiveTazer:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = ReactiveTazer:GetSpecialValueInt('stun_radius')

    if bGoingOnSomeone
    and not CanDoCombo1()
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if bRetreating
    and bot:GetActiveModeDesire() > BOT_ACTION_DESIRE_HIGH
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
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
                    or bot:WasRecentlyDamagedByAnyHero(1.5))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderBlastOff()
    if not BlastOff:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, BlastOff:GetCastRange())
	local nCastPoint = BlastOff:GetCastPoint()
    local nRadius = BlastOff:GetSpecialValueInt('radius')
    local nLeapDuration = BlastOff:GetSpecialValueFloat('duration')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if enemyHero:IsChanneling()
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                end
            end
        end
    end

	if Fu.IsInTeamFight(bot, 1200)
    and not CanDoCombo1()
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius * 0.8)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and not Fu.IsLocationInChrono(Fu.GetCenterOfUnits(nInRangeEnemy))
        then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
		end
	end

	if bGoingOnSomeone
    and not CanDoCombo1()
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                local flag = false
                local eta = nCastPoint + nLeapDuration
                local nEnemyTowers = botTarget:GetNearbyTowers(700, false)

                if Fu.IsChasingTarget(bot, botTarget)
                then
                    if Fu.IsInLaningPhase()
                    then
                        if nEnemyHeroes ~= nil and #nEnemyTowers >= 1
                        then
                            flag = true
                        end
                    end

                    if not flag
                    then
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(eta)
                    end
                else
                    if Fu.IsInLaningPhase()
                    then
                        if nEnemyHeroes ~= nil and #nEnemyTowers >= 1
                        then
                            flag = true
                        end
                    end

                    if not flag
                    then
                        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        else
                            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                        end
                    end
                end
            end
		end
	end

    if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    if nBotHP < 0.5
                    and Fu.CanCastOnNonMagicImmune(enemyHero)
                    and bot:GetHealth() < Fu.GetTotalEstimatedDamageToTarget(nInRangeEnemy, bot)
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                    else
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nCastRange)
                    end
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderMineFieldSign()
    if not ProximityMines:IsTrained()
    or not MineFieldSign:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nRadius = MineFieldSign:GetSpecialValueInt('aura_radius')
    local nSpots = TU.GetAvailableSpot()
    MineLocation, MineLocationDistance = TU.GetClosestSpot(bot, nSpots)

    if MineLocation ~= nil
    and GetUnitToLocationDistance(bot, MineLocation) <= bot:GetCurrentVisionRange()
    and not IsEnemyCloserToWardLocation(MineLocation, MineLocationDistance)
    then
        -- Try 50 times
        for i = 0, 50
        do
            local loc = Fu.GetRandomLocationWithinDist(MineLocation, 0, nRadius * 3 + 100)
            if IsLocationPassable(loc)
            then
                local nMineList = Fu.GetTechiesMinesInLoc(loc, nRadius)
                if #nMineList >= 3
                then
                    return BOT_ACTION_DESIRE_HIGH, loc
                end
            end

            i = i + 1
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderProximityMines()
    if not ProximityMines:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, ProximityMines:GetCastRange())
    local nAffectRange = 400
    local nPManaCost = ProximityMines:GetManaCost()

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + nAffectRange)
        -- and bAttacking
        and not Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if Fu.CanKillTarget( botTarget, nPMineTotalDmg, DAMAGE_TYPE_MAGICAL )
                or (nInRangeAlly ~= nil and nInRangeEnemy ~= nil and #nInRangeAlly >= #nInRangeEnemy)
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), TU.nMinMineDistance)
                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    local desire, loc = TU.GetGoodPlaceForMiningNear(Fu.GetCenterOfUnits(nInRangeEnemy))
                    if desire > 0
                    then
                        return BOT_ACTION_DESIRE_HIGH, loc
                    end
                else
                    local desire, loc = TU.GetGoodPlaceForMiningNear(botTarget:GetLocation())
                    if desire > 0
                    then
                        return BOT_ACTION_DESIRE_HIGH, loc
                    end
                end
            end
		end
	end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot, nCastRange + nAffectRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.GetManaAfter(nPManaCost) > 0.5
        and not bRetreating
        and nBotHP > Fu.GetHP(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)
            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil and #nInRangeAlly >= #nInRangeEnemy then
                local loc = enemyHero:GetExtrapolatedLocation(0.5)
                if GetUnitToLocationDistance(bot, loc) < nCastRange + 100 then
                    return BOT_ACTION_DESIRE_HIGH, loc
                end
                loc = Fu.Utils.GetOffsetLocationTowardsTargetLocation(bot:GetLocation(), enemyHero:GetLocation(), nCastRange)
                if GetUnitToLocationDistance(bot, loc) < nCastRange + 100 then
                    return BOT_ACTION_DESIRE_HIGH, loc
                end
            end
        end
    end

	if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1))
                and Fu.CanKillTarget(enemyHero, nPMineDamage, DAMAGE_TYPE_MAGICAL)
                then
                    local loc = (bot:GetLocation() + enemyHero:GetLocation()) / 2
                    if GetUnitToLocationDistance(bot, loc) <= nCastRange
                    then
                        return BOT_ACTION_DESIRE_HIGH, loc
                    else
                        return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
                    end
                end
            end
        end
	end

	if Fu.IsPushing(bot)
	then
		local nEnemyTowers = bot:GetNearbyTowers(1200, true)
		if nEnemyTowers ~= nil and #nEnemyTowers >= 1
        and Fu.IsValidBuilding(nEnemyTowers[1])
        and Fu.CanBeAttacked(nEnemyTowers[1])
        then
            local nInRangeAlly = Fu.GetAlliesNearLoc(nEnemyTowers[1]:GetLocation(), bot:GetAttackRange())
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nEnemyTowers[1]:GetLocation(), 1600)

            if nInRangeAlly ~= nil and #nInRangeAlly >= 1
            and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
            then
                return BOT_ACTION_DESIRE_HIGH, nEnemyTowers[1]:GetLocation() + RandomVector(200)
            end
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nAffectRange)
        and bAttacking
        and not TU.IsOtherMinesClose(botTarget:GetLocation())
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not TU.IsOtherMinesClose(botTarget:GetLocation())
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsFarming(bot)
    and Fu.GetManaAfter(nPManaCost) > 0.3
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nAffectRange)
        if nNeutralCreeps ~= nil
        then
            if #nNeutralCreeps > 1
            then
                return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]:GetLocation()
            end
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nAffectRange, true)
        if nEnemyLaneCreeps ~= nil
        then
            if #nEnemyLaneCreeps > 1
            then
                return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]:GetLocation()
            end
        end
    end

    -- General Mines
    local nManaCost = ReactiveTazer:GetManaCost() + BlastOff:GetManaCost()

    if DotaTime() > MineCooldownTime + 1.5
    and Fu.GetManaAfter(nManaCost) * bot:GetMana() > ProximityMines:GetManaCost() * 2
    and IsSuitableToPlaceMine()
    then
		local nSpots = TU.GetAvailableSpot()
		MineLocation, MineLocationDistance = TU.GetClosestSpot(bot, nSpots)

		if MineLocation ~= nil
        and GetUnitToLocationDistance(bot, MineLocation) <= 2000
		and not IsEnemyCloserToWardLocation(MineLocation, MineLocationDistance)
		then
            for i = 0, 10
            do
                local loc = Fu.GetRandomLocationWithinDist(MineLocation, 0, TU.nMinMineDistance * 3 + 100)
                if IsLocationPassable(loc)
                and not TU.IsOtherMinesClose(loc)
                then
                    local nMineList = Fu.GetTechiesMinesInLoc(loc, TU.nMinMineDistance * 3 + 100) --☠️, fine..
                    if #nMineList < 3
                    then
                        return BOT_ACTION_DESIRE_HIGH, loc
                    end
                end

                i = i + 1
            end
		end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- Helper Funcs
function IsSuitableToPlaceMine()
	local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 2000)

	local nMode = bot:GetActiveMode()
    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

	if (nMode == BOT_MODE_RETREAT
		and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH)
    or (nMode == BOT_MODE_RUNE and DotaTime() > 0)
    or nMode == BOT_MODE_DEFEND_ALLY
    or bGoingOnSomeone and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
    or Fu.IsPushing(bot) and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
	or Fu.IsDefending(bot)
    or Fu.IsDoingRoshan(bot)
    or Fu.IsDoingTormentor(bot)
    or bot:GetLevel() <= 6
    or nTeamFightLocation ~= nil
	or nEnemyHeroes ~= nil and #nEnemyHeroes >= 1
	then
		return false
	end

	return true
end

function IsIBecameTheTarget(nUnits)
	for _, u in pairs(nUnits)
	do
		if u ~= nil
        and u:CanBeSeen() and u:GetAttackTarget() == bot
		then
			return true
		end
	end

	return false
end

function IsEnemyCloserToWardLocation(wardLoc, botDist)
	for _, id in pairs(GetTeamPlayers(GetOpposingTeam()))
	do
		local info = GetHeroLastSeenInfo(id)

		if info ~= nil
		then
			local dInfo = info[1]

			if dInfo ~= nil
			and dInfo.time_since_seen < 5
			and Fu.GetDistance(dInfo.location, wardLoc) <  botDist
			then
				return true
			end
		end
	end

	return false
end

-- Combos
function X.ConsiderCombo()
    local ComboFlag = 0

    if CanDoCombo1()
    then
        ComboFlag = 1
    end

    if ComboFlag > 0
    then
        local nCastRange = Fu.GetProperCastRange(false, bot, BlastOff:GetCastRange())
        local nCastPoint = BlastOff:GetCastPoint()
        local nRadius = BlastOff:GetSpecialValueInt('radius')
        local nLeapDuration = BlastOff:GetSpecialValueFloat('duration')

        if Fu.IsInTeamFight(bot, 1200)
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
            and (Fu.IsValidHero(nInRangeEnemy[1]) and not nInRangeEnemy[1]:IsMagicImmune()
                or Fu.IsValidHero(nInRangeEnemy[2]) and not nInRangeEnemy[2]:IsMagicImmune())
            and not Fu.IsLocationInChrono(Fu.GetCenterOfUnits(nInRangeEnemy))
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy), ComboFlag
            end
        end

        if bGoingOnSomeone
        then
            if Fu.IsValidTarget(botTarget)
            and Fu.CanCastOnNonMagicImmune(botTarget)
            and Fu.IsInRange(bot, botTarget, nCastRange)
            and not Fu.IsSuspiciousIllusion(botTarget)
            and not botTarget:IsMagicImmune()
            and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
                local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
                and #nInRangeAlly >= #nInRangeEnemy
                then
                    local eta = nCastPoint + nLeapDuration
                    if Fu.IsChasingTarget(bot, botTarget) or Fu.CanKillTarget( botTarget, nComboDmg, DAMAGE_TYPE_MAGICAL )
                    then
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(eta), ComboFlag
                    else
                        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy), ComboFlag
                        else
                            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), ComboFlag
                        end
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0, 0
end

function CanDoCombo1()
    if ReactiveTazer:IsFullyCastable()
    and BlastOff:IsFullyCastable()
    then
        local nManaCost = ReactiveTazer:GetManaCost()
                        + BlastOff:GetManaCost()

        if bot:GetMana() >= nManaCost
        and nBotHP > 0.35
        then
            return true
        end
    end

    return false
end

return X