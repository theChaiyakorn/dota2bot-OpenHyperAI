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
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,2,1,2,1,6,1,2,2,3,6,3,3,3,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_bottle",
    "item_soul_ring",
    "item_magic_wand",
    "item_blink",
	"item_kaya_and_sange",--
	"item_angels_demise",--
    "item_shivas_guard",--
	"item_ultimate_scepter",
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_sheepstick",--
    "item_overwhelming_blink",--
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_magic_wand",
    "item_soul_ring",
    "item_blink",
	"item_kaya_and_sange",--
	"item_angels_demise",--
    "item_shivas_guard",--
	"item_ultimate_scepter",
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_sheepstick",--
    "item_overwhelming_blink",--
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_blood_grenade",

	"item_magic_wand",
	"item_arcane_boots",
	"item_rod_of_atos",
	"item_glimmer_cape",--
	"item_aether_lens",--
	"item_aghanims_shard",
	"item_guardian_greaves",--
	"item_ultimate_scepter",
	"item_octarine_core",--
	"item_gungir",--
	"item_shivas_guard",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_clarity",
    "item_blood_grenade",

    "item_boots",
    "item_urn_of_shadows", -- Alternative: item_essence_distiller (if not going spirit_vessel)
    "item_tranquil_boots",
	"item_pipe",
    "item_spirit_vessel",--
    "item_glimmer_cape",--
    "item_pavise",
    "item_solar_crest",--
    "item_boots_of_bearing",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
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

local Laser                 = bot:GetAbilityByName('tinker_laser')
-- local HeatSeekingMissile    = bot:GetAbilityByName('tinker_heat_seeking_missile')
local MarchOfTheMachines    = bot:GetAbilityByName('tinker_march_of_the_machines')
-- 7.41: Defense Matrix may have been replaced by Deploy Turrets. Try both names.
local DeployTurrets         = bot:GetAbilityByName('tinker_deploy_turrets')
                              or bot:GetAbilityByName('tinker_defense_matrix')
                              or (sAbilityList[3] and bot:GetAbilityByName(sAbilityList[3]))
local WarpFlare             = bot:GetAbilityByName('tinker_warp_grenade')
local KeenConveyance        = bot:GetAbilityByName('tinker_keen_teleport')
local Rearm                 = bot:GetAbilityByName('tinker_rearm')

local lastMarchCastTime     = -999

local LaserDesire, LaserTarget
-- local HeatSeekingMissileDesire
local MarchOfTheMachinesDesire, MarchOfTheMachinesLocation
local DeployTurretsDesire, DeployTurretsLocation
local WarpFlareDesire, WarpFlareTarget
local KeenConveyanceDesire, KeenConveyanceTargetLocation
local KeenConveyanceCastTime = DotaTime()
local RearmDesire

local botTarget

local Blink = nil
local BlinkLocation

local SoulRing = nil
local ShivasGuard = nil
local EtherealBlade = nil
local ScytheOfVyse = nil

local ComboDesire, ComboTarget
local ClearCreepsDesire, ClearCreepsTarget

if bot.healInBase == nil then bot.healInBase = false end
if bot.shouldBlink == nil then bot.shouldBlink = false end

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
local nBotMP
local bInTeamFight
function X.SkillsComplement()

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = Fu.GetHP(bot)
	nBotMP = Fu.GetMP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)
    if nBotMP > 0.8
    or bot:HasModifier('modifier_fountain_invulnerability')
    then
        bot.healInBase = false
    end

    -- Re-fetch ability handles each tick for safety against Aghs upgrades
    Laser = bot:GetAbilityByName('tinker_laser')
    MarchOfTheMachines = bot:GetAbilityByName('tinker_march_of_the_machines')
    DeployTurrets = bot:GetAbilityByName('tinker_deploy_turrets')
                    or bot:GetAbilityByName('tinker_defense_matrix')
                    or (sAbilityList[3] and bot:GetAbilityByName(sAbilityList[3]))
    WarpFlare = bot:GetAbilityByName('tinker_warp_grenade')
    KeenConveyance = bot:GetAbilityByName('tinker_keen_teleport')
    Rearm = bot:GetAbilityByName('tinker_rearm')

    if Fu.CanNotUseAbility(bot)
    or Rearm ~= nil and Rearm:IsInAbilityPhase()
    or KeenConveyance ~= nil and KeenConveyance:IsInAbilityPhase()
    or bot:HasModifier('modifier_tinker_rearm')
    or bot:HasModifier('modifier_teleporting')
    then
        return
    end

    -- Cache per-tick variables
    botTarget = Fu.GetProperTarget(bot)

    if not bGoingOnSomeone
    and not Fu.IsDoingRoshan(bot)
    and not Fu.IsDoingTormentor(bot)
    then
        if not bot.healInBase
        then
            if Fu.IsInLaningPhase()
            then
                if Rearm ~= nil and Rearm:GetManaCost() > bot:GetMana()
                or nBotHP < 0.35
                then
                    bot.healInBase = true
                end
            else
                if nBotMP < 0.3
                or (nBotHP < 0.35 and nBotMP < 0.5)
                then
                    bot.healInBase = true
                end
            end
        end
    end

    DeployTurretsDesire, DeployTurretsLocation = X.ConsiderDeployTurrets()
    if DeployTurretsDesire > 0
    then
        bot:Action_UseAbilityOnLocation(DeployTurrets, DeployTurretsLocation)
        return
    end

    MarchOfTheMachinesDesire, MarchOfTheMachinesLocation = X.ConsiderMarchOfTheMachines()
    if MarchOfTheMachinesDesire > 0
    then
        bot:Action_UseAbilityOnLocation(MarchOfTheMachines, MarchOfTheMachinesLocation)
        lastMarchCastTime = DotaTime()
        return
    end

    LaserDesire, LaserTarget = X.ConsiderLaser()
    if LaserDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Laser, LaserTarget)
        return
    end

    WarpFlareDesire, WarpFlareTarget = X.ConsiderWarpFlare()
    if WarpFlareDesire > 0
    then
        bot:ActionQueue_UseAbilityOnEntity(WarpFlare, WarpFlareTarget)
        return
    end

    RearmDesire = X.ConsiderRearm()
    if RearmDesire > 0
    then
        bot:Action_UseAbility(Rearm)
        return
    end

    KeenConveyanceDesire, KeenConveyanceTargetLocation, Type = X.ConsiderKeenConveyance()
    if KeenConveyanceDesire > 0
    then
        if Type == 'unit'
        then
            bot:Action_UseAbilityOnEntity(KeenConveyance, KeenConveyanceTargetLocation)
        else
            bot:Action_UseAbilityOnLocation(KeenConveyance, KeenConveyanceTargetLocation)
        end

        KeenConveyanceCastTime = DotaTime()
        return
    end

end

function X.ConsiderLaser()
    if not Fu.CanCastAbility(Laser)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Laser:GetCastRange())
    local nDamage = Laser:GetSpecialValueInt('laser_damage')
    local nRadius = Laser:GetSpecialValueInt('radius_explosion')
    local nManaCost = Laser:GetManaCost()

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PURE)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    -- Teamfight: blind the highest DPS enemy
    if bInTeamFight
    then
        local bestTarget = nil
        local bestDPS = 0

        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsMeepoClone(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            then
                local currDPS = enemyHero:GetAttackDamage() * enemyHero:GetAttackSpeed()
                if currDPS > bestDPS
                then
                    bestDPS = currDPS
                    bestTarget = enemyHero
                end
            end
        end

        if bestTarget ~= nil
        then
            return BOT_ACTION_DESIRE_HIGH, bestTarget
        end
    end

	if bGoingOnSomeone
    -- and (not CanDoCombo1()
    --     and not CanDoCombo2()
    --     and not CanDoCombo3()
    --     and not CanDoCombo4()
    --     and not CanDoCombo5())
	then
        local target = nil
        local dmg = 0

        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsMeepoClone(enemyHero)
            then
                local currDMG = enemyHero:GetAttackDamage() * enemyHero:GetAttackSpeed()
                if dmg < currDMG
                then
                    dmg = currDMG
                    target = enemyHero
                end
            end
        end

        if target ~= nil
        then
            return BOT_ACTION_DESIRE_HIGH, target
        end
	end

	if bRetreating
    and not Fu.IsRealInvisible(bot)
	then
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and not Fu.IsInRange(bot, enemyHero, nCastRange / 2.5)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and (bot:WasRecentlyDamagedByHero(enemyHero, 3.5) or nBotHP < 0.4)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
	end

    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and nBotMP > 0.35
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        if bAttacking
        then
            if Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            and not Fu.IsRunning(nEnemyLaneCreeps[1])
            and #nEnemyLaneCreeps >= 2 and nLocationAoE.count >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
            end
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.3
    then
        if bAttacking
        then
            local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), 1200, nRadius, 0, 0)
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(1000)

            if Fu.IsValid(nNeutralCreeps[1])
            and ((#nNeutralCreeps >= 2 and nLocationAoE.count >= 2) or (#nNeutralCreeps == 1 and (nNeutralCreeps[1]:IsAncientCreep() or Fu.GetHP(nNeutralCreeps[1]) > 0.5)))
            then
                return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]
            end

            if Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            and not Fu.IsRunning(nEnemyLaneCreeps[1])
            and #nEnemyLaneCreeps >= 2 and nLocationAoE.count >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
            end
        end
    end

    if Fu.IsLaning(bot)
    and (Fu.IsCore(bot) or not Fu.IsCore(bot) and not Fu.IsThereNonSelfCoreNearby(1200))
	then
        local creepList = {}

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
            and Fu.IsInRange(bot, creep, nCastRange)
            and Fu.CanBeAttacked(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and creep:GetHealth() <= nDamage
			then
				if Fu.IsValidHero(nEnemyHeroes[1])
                and GetUnitToUnitDistance(creep, nEnemyHeroes[1]) < 600
                and nBotMP > 0.3
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end

            if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            then
                creepList = Fu.GetCreepListAroundTargetCanKill(creep, nRadius, nDamage, true, false, true)

                if #creepList >= 2
                and nBotMP > 0.25
                then
                    return BOT_ACTION_DESIRE_HIGH, creep
                end
            end
		end

        if Fu.IsValidHero(nEnemyHeroes[1])
        and Fu.IsInLaningPhase(bot)
        then
            local nAllyTowers = bot:GetNearbyTowers(1600, false)
            if nAllyTowers ~= nil and #nAllyTowers >= 1
            and Fu.IsValidBuilding(nAllyTowers[1])
            and Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange)
            and Fu.CanCastOnNonMagicImmune(nEnemyHeroes[1])
            and Fu.CanCastOnTargetAdvanced(nEnemyHeroes[1])
            and Fu.GetManaAfter(nManaCost) > 0.45
            and not nEnemyHeroes[1]:HasModifier('modifier_abaddon_borrowed_time')
            and not nEnemyHeroes[1]:HasModifier('modifier_dazzle_shallow_grave')
            and not nEnemyHeroes[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            and not nEnemyHeroes[1]:HasModifier('modifier_templar_assassin_refraction_absorb')
            and GetUnitToUnitDistance(nEnemyHeroes[1], nAllyTowers[1]) < 600
            and nAllyTowers[1]:GetAttackTarget() == nEnemyHeroes[1]
            then
                return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
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

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderMarchOfTheMachines()
    if not Fu.CanCastAbility(MarchOfTheMachines)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, MarchOfTheMachines:GetCastRange())
    local nCastPoint = MarchOfTheMachines:GetCastPoint()
    local nDistance = MarchOfTheMachines:GetSpecialValueInt('distance')
    local nRadius = MarchOfTheMachines:GetSpecialValueInt('radius')
    local nDuration = MarchOfTheMachines:GetSpecialValueInt('duration')
    local nDamage = MarchOfTheMachines:GetSpecialValueInt('damage')

    -- Overlap prevention: don't recast if previous March is still covering the area
    if DotaTime() < lastMarchCastTime + nDuration / 2
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nDistance)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage * nDuration, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsChasingTarget(enemyHero, bot)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetLocation(), nCastRange)
        end
    end

	if bGoingOnSomeone
	then
        local nLocationAoE__A = bot:FindAoELocation(false, true, bot:GetLocation(), nDistance / 2, nRadius, 0, 0)
        local nLocationAoE__E = bot:FindAoELocation(true, true, bot:GetLocation(), nDistance / 2, nRadius, 0, 0)
        if not Fu.IsCore(bot)
        then
            if nLocationAoE__A.count > 0
            and Fu.GetDistance(nLocationAoE__A.targetloc, nLocationAoE__E.targetloc) <= nDistance
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nLocationAoE__A.targetloc, nCastRange)
            end
        end

        if #nEnemyHeroes <= 1
        and Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nDistance)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
		end

        if nLocationAoE__E.count > 0
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nLocationAoE__E.targetloc, nCastRange)
        end
	end

    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and nBotMP > 0.35
    then
        if #nEnemyLaneCreeps >= 2
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nEnemyLaneCreeps), nCastRange)
        end

        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nDistance / 2, nRadius, nCastPoint, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nLocationAoE.targetloc, nCastRange)
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.3
    then
        if bAttacking
        then
            local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), 1200, nRadius, 0, 0)
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(1000)

            if Fu.CanBeAttacked(nNeutralCreeps[1])
            and ((#nNeutralCreeps >= 2 and nLocationAoE.count >= 2)
                or (#nNeutralCreeps == 1 and (nNeutralCreeps[1]:IsAncientCreep() or Fu.GetHP(nNeutralCreeps[1]) > 0.5)))
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nNeutralCreeps), nCastRange)
            end

            if #nEnemyLaneCreeps >= 2
            and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nEnemyLaneCreeps), nCastRange)
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nDistance)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nDistance)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderDeployTurrets()
    if not Fu.CanCastAbility(DeployTurrets)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, DeployTurrets:GetCastRange())
    local nManaCost = DeployTurrets:GetManaCost()
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE)

    -- Mana management: reserve mana for Rearm + TP combo (exception: always deploy in teamfight)
    if not bInTeamFight
    and Fu.GetManaAfter(nManaCost) < 0.25
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    -- When going on someone: deploy turrets at the target's location
    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    -- When retreating: deploy turrets near approaching enemies to slow their chase
    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    -- In teamfights: deploy turrets near the cluster of enemy heroes
    if bInTeamFight
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, 400, 0, 0)
        if nLocationAoE.count >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        if Fu.IsValidHero(nEnemyHeroes[1])
        and Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange)
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]:GetLocation()
        end
    end

    -- When pushing: deploy turrets near enemy towers
    if Fu.IsPushing(bot)
    then
        local nEnemyTowers = bot:GetNearbyTowers(nCastRange, true)
        if nEnemyTowers ~= nil and #nEnemyTowers >= 1
        and Fu.IsValidBuilding(nEnemyTowers[1])
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyTowers[1]:GetLocation()
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if #nEnemyLaneCreeps >= 3
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
    end

    -- When defending: deploy turrets near approaching enemies
    if Fu.IsDefending(bot)
    then
        if Fu.IsValidHero(nEnemyHeroes[1])
        and Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange)
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]:GetLocation()
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if #nEnemyLaneCreeps >= 3
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
    end

    -- When doing Roshan or Tormentor: deploy turrets at the target
    if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
    then
        if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

local tpDelta = 7
function X.ConsiderKeenConveyance()
    if not Fu.CanCastAbility(KeenConveyance)
    or (bot.healInBase and GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) < 1000)
    then
        return BOT_ACTION_DESIRE_NONE, nil, ''
    end

    local RoshanLocation = Fu.GetCurrentRoshanLocation()
    local TormentorLocation = Fu.GetTormentorLocation(GetTeam())
    local nAbilityLevel = KeenConveyance:GetLevel()
    local nMode = bot:GetActiveMode()
    local nChannelTime = KeenConveyance:GetChannelTime()
    local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), bot:GetCurrentVisionRange())

    if bot.healInBase
    and GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) > 3200
    and nEnemyHeroes ~= nil and #nEnemyHeroes == 0
    then
        if Fu.IsInLaningPhase()
        then
            if GetLaneFrontAmount(GetTeam(), LANE_MID, true) < 0.28
            then
                if bot:GetHealth() > Fu.GetTotalEstimatedDamageToTarget(nEnemyHeroes, bot)
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetTeamFountain(), 'loc'
                end
            end
        end

        return BOT_ACTION_DESIRE_HIGH, Fu.GetTeamFountain(), 'loc'
    end

    if bInTeamFight
    and not bRetreating
    then
        return BOT_ACTION_DESIRE_NONE, 0, ''
    end

    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
    if nTeamFightLocation ~= nil
    and nBotMP > 0.65
    and not bRetreating
    and not Fu.IsInLaningPhase()
    then
        local nInRangeAlly = Fu.GetAlliesNearLoc(nTeamFightLocation, 1200)

        if GetUnitToLocationDistance(bot, nTeamFightLocation) > 4100
        then
            if nAbilityLevel <= 2
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetNearbyLocationToTp(nTeamFightLocation), 'loc'
            else
                return BOT_ACTION_DESIRE_HIGH, nInRangeAlly[1], 'unit'
            end
        end
    end

    if DotaTime() < KeenConveyanceCastTime + tpDelta
    then
        return BOT_ACTION_DESIRE_NONE, 0, ''
    end

    if Fu.IsLaning(bot)
    and Fu.IsInLaningPhase()
    then
        local botAmount = GetAmountAlongLane(LANE_MID, bot:GetLocation())
        local laneFront = GetLaneFrontAmount(GetTeam(), LANE_MID, false)
        if botAmount.distance > 4100
        or botAmount.amount < laneFront / 5
        then
            return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_MID, -300), 'loc'
        end
    end

    local aveDist = {0,0,0}
    local pushCount = {0,0,0}
    for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
    do
        if Fu.IsValidHero(allyHero)
        and bot ~= allyHero
        and not Fu.IsSuspiciousIllusion(allyHero)
        and not Fu.IsMeepoClone(allyHero)
        then
            if allyHero:GetActiveMode() == BOT_MODE_PUSH_TOWER_TOP
            and bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_TOP
            then
                pushCount[1] = pushCount[1] + 1
                aveDist[1] = aveDist[1] + GetUnitToLocationDistance(allyHero, GetLaneFrontLocation(GetTeam(), LANE_TOP, 0))
            end

            if allyHero:GetActiveMode() == BOT_MODE_PUSH_TOWER_MID
            and bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_MID
            then
                pushCount[2] = pushCount[2] + 1
                aveDist[2] = aveDist[2] + GetUnitToLocationDistance(allyHero, GetLaneFrontLocation(GetTeam(), LANE_MID, 0))
            end

            if allyHero:GetActiveMode() == BOT_MODE_PUSH_TOWER_BOT
            and bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_BOT
            then
                pushCount[3] = pushCount[3] + 1
                aveDist[3] = aveDist[3] + GetUnitToLocationDistance(allyHero, GetLaneFrontLocation(GetTeam(), LANE_BOT, 0))
            end
        end
    end

    if pushCount[1] ~= nil and pushCount[1] >= 3 and (aveDist[1] / pushCount[1]) <= 1200
    then
        if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), LANE_TOP, 0)) > 4000
        then
            if nAbilityLevel == 3
            then
                return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_TOP, 0), 'loc'
            else
                local tpLoc = Fu.GetPushTPLocation(LANE_TOP)
                if tpLoc then return BOT_ACTION_DESIRE_HIGH, tpLoc, 'loc' end
            end
        end
    elseif pushCount[2] ~= nil and pushCount[2] >= 3 and (aveDist[2] / pushCount[2]) <= 1200
    then
        if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), LANE_MID, 0)) > 4000
        then
            if nAbilityLevel == 3
            then
                return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_MID, 0), 'loc'
            else
                local tpLoc = Fu.GetPushTPLocation(LANE_MID)
                if tpLoc then return BOT_ACTION_DESIRE_HIGH, tpLoc, 'loc' end
            end
        end
    elseif pushCount[3] ~= nil and pushCount[3] >= 3 and (aveDist[3] / pushCount[3]) <= 1200
    then
        if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), LANE_BOT, 0)) > 4000
        then
            if nAbilityLevel == 3
            then
                return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_BOT, 0), 'loc'
            else
                local tpLoc = Fu.GetPushTPLocation(LANE_BOT)
                if tpLoc then return BOT_ACTION_DESIRE_HIGH, tpLoc, 'loc' end
            end
        end
    end

    if Fu.IsDefending(bot)
    and nEnemyHeroes ~= nil and #nEnemyHeroes == 0
    and not Fu.IsInLaningPhase()
	then
		local nDefendLane = LANE_MID
		if nMode == BOT_MODE_DEFEND_TOWER_TOP then nDefendLane = LANE_TOP end
		if nMode == BOT_MODE_DEFEND_TOWER_BOT then nDefendLane = LANE_BOT end

		local botAmount = GetAmountAlongLane(nDefendLane, bot:GetLocation())
		local laneFront = GetLaneFrontAmount(GetTeam(), nDefendLane, false)
		if botAmount.distance > 3200
		or botAmount.amount < laneFront / 5
		then
			if GetUnitToLocationDistance(bot, Fu.GetDefendTPLocation(nDefendLane)) > 3200
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetDefendTPLocation(nDefendLane), 'loc'
            end
		end
	end

    if Fu.IsFarming(bot)
    then
        local farmLane, mostFarmDesire = Fu.GetMostFarmLaneDesire()

        if mostFarmDesire > 0.75
        then
            local farmTpLoc = GetLaneFrontLocation(GetTeam(), farmLane, 0)
            local bestTpLoc = Fu.GetNearbyLocationToTp(farmTpLoc)

            if bestTpLoc ~= nil and farmTpLoc ~= nil
            and GetUnitToLocationDistance( bot, bestTpLoc) > 4000
            then
                return BOT_ACTION_DESIRE_HIGH, farmTpLoc, 'loc'
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        local nInRangeAlly = Fu.GetAlliesNearLoc(RoshanLocation, 800)
        if nInRangeAlly ~= nil and #nInRangeAlly >= 1
        and GetUnitToLocationDistance(bot, RoshanLocation) > 3800
        and GetUnitToLocationDistance(bot, Fu.GetNearbyLocationToTp(RoshanLocation)) > 3800
        then
            if nAbilityLevel <= 2
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetNearbyLocationToTp(RoshanLocation), 'loc'
            else
                return BOT_ACTION_DESIRE_HIGH, nInRangeAlly[1], 'unit'
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        local nInRangeAlly = Fu.GetAlliesNearLoc(TormentorLocation, 800)
        if nInRangeAlly ~= nil and #nInRangeAlly >= 2
        and GetUnitToLocationDistance(bot, TormentorLocation) > 3800
        and GetUnitToLocationDistance(bot, Fu.GetNearbyLocationToTp(TormentorLocation)) > 3800
        then
            if nAbilityLevel <= 2
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetNearbyLocationToTp(TormentorLocation), 'loc'
            else
                return BOT_ACTION_DESIRE_HIGH, nInRangeAlly[1], 'unit'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

function X.ConsiderRearm()
    if not Fu.CanCastAbility(Rearm)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nChannelTime = Rearm:GetChannelTime()

    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
    if bot.healInBase
    and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
    and KeenConveyance ~= nil and KeenConveyance:IsTrained() and KeenConveyance:GetCooldownTimeRemaining() > nChannelTime
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if Laser ~= nil and Laser:IsTrained() and Laser:GetCooldownTimeRemaining() > nChannelTime
    or MarchOfTheMachines ~= nil and MarchOfTheMachines:IsTrained() and MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime
    then
        return BOT_ACTION_DESIRE_HIGH
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, 1500)
        and (MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime
            or not Fu.CanBlinkDagger(GetBot()))
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        -- if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), bot.laneToPush, 0)) > 4000
        -- and KeenConveyance ~= nil and KeenConveyance:IsTrained() and KeenConveyance:GetCooldownTimeRemaining() > 5
        -- then
        --     return BOT_ACTION_DESIRE_HIGH
        -- end

        if #nEnemyLaneCreeps >= 2
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 1600, 900, 0, 0)
        if nLocationAoE.count > 0
        and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) > 880
        and MarchOfTheMachines ~= nil and MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(800)
            if nNeutralCreeps ~= nil
            and (#nNeutralCreeps >= 2 or (#nNeutralCreeps >= 1 and nNeutralCreeps[1]:IsAncientCreep()))
            and nBotMP > 0.25
            and (Laser ~= nil and Laser:GetCooldownTimeRemaining() > nChannelTime
                or MarchOfTheMachines ~= nil and MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime)
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2
            and nBotMP > 0.25
            and (Laser ~= nil and Laser:GetCooldownTimeRemaining() > nChannelTime
                or MarchOfTheMachines ~= nil and MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and bAttacking
        and (DeployTurrets ~= nil and DeployTurrets:GetCooldownTimeRemaining() > nChannelTime
            or MarchOfTheMachines ~= nil and MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and bAttacking
        and (DeployTurrets ~= nil and DeployTurrets:GetCooldownTimeRemaining() > nChannelTime
            or MarchOfTheMachines ~= nil and MarchOfTheMachines:GetCooldownTimeRemaining() > nChannelTime)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderWarpFlare()
    if not Fu.CanCastAbility(WarpFlare)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WarpFlare:GetCastRange())

    if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

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
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeEnemy > #nInRangeAlly
        then
            local target = nil
            local dmg = 0

            nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
                and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    local currDmg = enemyHero:GetEstimatedDamageToTarget(true, bot, 5, DAMAGE_TYPE_ALL)
                    if currDmg > dmg
                    then
                        dmg = currDmg
                        target = enemyHero
                    end
                end
            end

            if target ~= nil
            then
                return BOT_ACTION_DESIRE_HIGH, target
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

---------
-- Combos
---------
function X.ConsiderCombos()
    local ComboFlag = 0

    if CanDoCombo5()
    then
        ComboFlag = 5
    elseif CanDoCombo4()
    then
        ComboFlag = 4
    elseif CanDoCombo3()
    then
        ComboFlag = 3
    elseif CanDoCombo2()
    then
        ComboFlag = 2
    elseif CanDoCombo1()
    then
        ComboFlag = 1
    end

    if bGoingOnSomeone
    then
        local target = nil
        local hp = 20000
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1199, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:IsMagicImmune()
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                and hp > enemyHero:GetHealth()
                then
                    hp = enemyHero:GetHealth()
                    target = enemyHero
                end
            end
        end

        if target ~= nil
        then
            bot.shouldBlink = true
            BlinkLocation = Fu.GetRandomLocationWithinDist(target:GetLocation(), Laser:GetCastRange() * 0.7, Laser:GetCastRange())
            return BOT_ACTION_DESIRE_HIGH, target, ComboFlag
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, 0
end

function CanDoCombo1()
    if HasBlink()
    and Laser:IsFullyCastable()
    and HeatSeekingMissile:IsFullyCastable()
    then
        local nManaCost = Laser:GetManaCost()
                        + HeatSeekingMissile:GetManaCost()
                        + Rearm:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            bot.shouldBlink = true
            return true
        end
    end

    bot.shouldBlink = false
    return false
end

function CanDoCombo2()
    if HasBlink()
    and Laser:IsFullyCastable()
    and HeatSeekingMissile:IsFullyCastable()
    then
        ShivasGuard = Fu.Utils.GetItem('item_shivas_guard')
        if ShivasGuard ~= nil and ShivasGuard:IsFullyCastable()
        then
            local nManaCost = Laser:GetManaCost()
                            + HeatSeekingMissile:GetManaCost()
                            + Rearm:GetManaCost()
                            + 75

            if bot:GetMana() >= nManaCost
            then
                bot.shouldBlink = true
                return true
            end
        end
    end

    bot.shouldBlink = false
    return false
end

function CanDoCombo3()
    if HasBlink()
    and Laser:IsFullyCastable()
    and HeatSeekingMissile:IsFullyCastable()
    then
        ScytheOfVyse = Fu.Utils.GetItem('item_sheepstick')
        if ScytheOfVyse ~= nil and ScytheOfVyse:IsFullyCastable()
        then
            local nManaCost = Laser:GetManaCost()
                            + HeatSeekingMissile:GetManaCost()
                            + Rearm:GetManaCost()
                            + 250

            if bot:GetMana() >= nManaCost
            then
                bot.shouldBlink = true
                return true
            end
        end
    end

    bot.shouldBlink = false
    return false
end

function CanDoCombo4()
    if HasBlink()
    and Laser:IsFullyCastable()
    and HeatSeekingMissile:IsFullyCastable()
    then
        EtherealBlade = Fu.Utils.GetItem('item_ethereal_blade')
        if EtherealBlade ~= nil and EtherealBlade:IsFullyCastable()
        then
            local nManaCost = Laser:GetManaCost()
                            + HeatSeekingMissile:GetManaCost()
                            + Rearm:GetManaCost()
                            + 100

            if bot:GetMana() >= nManaCost
            then
                bot.shouldBlink = true
                return true
            end
        end
    end

    bot.shouldBlink = false
    return false
end

function CanDoCombo5()
    if HasBlink()
    and Laser:IsFullyCastable()
    and HeatSeekingMissile:IsFullyCastable()
    then
        ScytheOfVyse = Fu.Utils.GetItem('item_sheepstick')
        EtherealBlade = Fu.Utils.GetItem('item_ethereal_blade')
        if EtherealBlade ~= nil and EtherealBlade:IsFullyCastable()
        and ScytheOfVyse ~= nil and ScytheOfVyse:IsFullyCastable()
        then
            local nManaCost = Laser:GetManaCost()
                            + HeatSeekingMissile:GetManaCost()
                            + Rearm:GetManaCost()
                            + 250
                            + 100

            if bot:GetMana() >= nManaCost
            then
                bot.shouldBlink = true
                return true
            end
        end
    end

    bot.shouldBlink = false
    return false
end

-- Clear Creeps
function X.ConsiderClearCreeps()
    local ClearCreepFlag = 0

    if CanClearCreeps2()
    then
        ClearCreepFlag = 2
    elseif CanClearCreeps1()
    then
        ClearCreepFlag = 1
    end

    local nCastRange = 1199

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local target = nil
        local range = 1000
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        for _, creep in pairs(nEnemyLaneCreeps)
        do
            if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            and range > creep:GetAttackRange()
            then
                range = creep:GetAttackRange()
                target = creep
            end
        end

        if target ~= nil
        then
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(target:GetLocation(), 1600)
            local nEnemyTowers = bot:GetNearbyTowers(1600, true)

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
            and nEnemyTowers ~= nil
                and (#nEnemyTowers == 0 or (#nEnemyTowers >= 1 and GetUnitToLocationDistance(nEnemyTowers[1], Fu.GetCenterOfUnits(nEnemyLaneCreeps)) > 750))
            then
                BlinkLocation = Fu.GetCenterOfUnits(nEnemyLaneCreeps)
                return BOT_ACTION_DESIRE_HIGH, target, ClearCreepFlag
            end
        end
    end

    if Fu.IsFarming(bot)
    then
        local target = nil
        local range = 1000
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        then
            for _, creep in pairs(nEnemyLaneCreeps)
            do
                if Fu.IsValid(creep)
                and Fu.CanBeAttacked(creep)
                and range > creep:GetAttackRange()
                then
                    range = creep:GetAttackRange()
                    target = creep
                end
            end

            if target ~= nil
            then
                local nInRangeEnemy = Fu.GetEnemiesNearLoc(target:GetLocation(), 1600)
                local nEnemyTowers = bot:GetNearbyTowers(1600, true)

                if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
                and GetUnitToLocationDistance(nEnemyTowers[1], Fu.GetCenterOfUnits(nEnemyLaneCreeps)) > 750
                and nEnemyTowers ~= nil
                    and (#nEnemyTowers == 0 or (#nEnemyTowers >= 1 and GetUnitToLocationDistance(nEnemyTowers[1], Fu.GetCenterOfUnits(nEnemyLaneCreeps)) > 750))
                then
                    BlinkLocation = Fu.GetCenterOfUnits(nEnemyLaneCreeps)
                    return BOT_ACTION_DESIRE_HIGH, target, ClearCreepFlag
                end
            end
        end

        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(800)
        if nNeutralCreeps ~= nil and (#nNeutralCreeps >= 2 or #nNeutralCreeps == 1 and nNeutralCreeps[1]:IsAncientCreep())
        then
            for _, creep in pairs(nNeutralCreeps)
            do
                if Fu.IsValid(creep)
                and Fu.CanBeAttacked(creep)
                and range < creep:GetAttackRange()
                then
                    range = creep:GetAttackRange()
                    target = creep
                end
            end

            if target ~= nil
            then
                local nInRangeEnemy = Fu.GetEnemiesNearLoc(target:GetLocation(), 1600)
                if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
                then
                    BlinkLocation = Fu.GetCenterOfUnits(nNeutralCreeps)
                    return BOT_ACTION_DESIRE_HIGH, target, ClearCreepFlag
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, 0
end

function CanClearCreeps1()
    if HasBlink()
    and Laser:IsFullyCastable()
    then
        local nManaCost = Laser:GetManaCost()
                        + Rearm:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

function CanClearCreeps2()
    if HasBlink()
    and Laser:IsFullyCastable()
    then
        ShivasGuard = Fu.Utils.GetItem('item_shivas_guard')
        local nManaCost = Laser:GetManaCost()
                        + Rearm:GetManaCost()
                        + 75

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

--------
-- Items
--------

-- Blink Dagger
function X.ConsiderBlink()
    if HasBlink()
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,500, true, BOT_MODE_NONE)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            BlinkLocation = Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), 1199)
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function HasBlink()
    local blink = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil
        and (item:GetName() == "item_blink" or item:GetName() == "item_overwhelming_blink" or item:GetName() == "item_arcane_blink" or item:GetName() == "item_swift_blink")
        then
			blink = item
			break
		end
	end

    if blink ~= nil
    and blink:IsFullyCastable()
	then
        Blink = blink
        return true
	end

    return false
end

-- Soul Ring
function X.ConsiderSoulRing()
    if not Rearm:IsTrained()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    SoulRing = Fu.Utils.GetItem('item_soul_ring')
    if SoulRing ~= nil and SoulRing:IsFullyCastable()
    then
        if nBotHP > 0.3
        and nBotMP < 0.8
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

-- Shiva's Guard
function X.ConsiderShivasGuard()
    if not Rearm:IsTrained()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    ShivasGuard = Fu.Utils.GetItem('item_shivas_guard')
    if ShivasGuard ~= nil and ShivasGuard:IsFullyCastable()
    then
        if bGoingOnSomeone
        and not CanDoCombo2()
        then
            if Fu.IsValidTarget(botTarget)
            and Fu.IsInRange(bot, botTarget, 900)
            and not Fu.IsSuspiciousIllusion(botTarget)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X
