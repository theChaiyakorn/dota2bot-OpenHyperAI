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
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,6,2,3,3,3,1,6,1,1,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

local sUtility = {"item_crimson_guard", "item_lotus_orb", "item_heavens_halberd"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_quelling_blade",
    "item_enchanted_mango",

    "item_magic_wand",
    "item_arcane_boots",
    "item_veil_of_discord",
    "item_crimson_guard", --
    "item_blink",
    "item_ultimate_scepter",
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_sheepstick",--
    "item_arcane_blink",--
    "item_travel_boots",
    "item_moon_shard",
    "item_travel_boots_2",
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_quelling_blade",
    "item_enchanted_mango",

    "item_magic_wand",
    "item_arcane_boots",
    "item_veil_of_discord",
    "item_guardian_greaves",--
    "item_blink",
    nUtility,--
    "item_ultimate_scepter",
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_sheepstick",--
    "item_arcane_blink",--
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_quelling_blade",
    "item_enchanted_mango",

    "item_magic_wand",
    "item_arcane_boots",
    "item_veil_of_discord",
    "item_pipe",--
    "item_blink",
    nUtility,--
    "item_ultimate_scepter",
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_sheepstick",--
    "item_arcane_blink",--
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
    "item_moon_shard",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

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

local Vacuum            = bot:GetAbilityByName('dark_seer_vacuum')
local IonShell          = bot:GetAbilityByName('dark_seer_ion_shell')
local Surge             = bot:GetAbilityByName('dark_seer_surge')
-- local NormalPunch       = bot:GetAbilityByName('dark_seer_normal_punch')
local WallOfReplica     = bot:GetAbilityByName('dark_seer_wall_of_replica')

local VacuumDesire, VacuumLocation
local IonShellDesire, IonShellTarget
local SurgeDesire, SurgeTarget
local WallOfReplicaDesire, WallOfReplicaLocation

local VacuumWallDesire, VacuumwallLocation
local Blink

local botTarget

if bot.shouldBlink == nil then bot.shouldBlink = false end

local bGoingOnSomeone
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bInTeamFight = ctx.isTeamFight

    botTarget = ctx.target

    VacuumWallDesire, VacuumwallLocation = X.ConsiderVacuumWall()
    if VacuumWallDesire > 0
    then
        bot:Action_ClearActions(false)
        bot:ActionQueue_UseAbilityOnLocation(Blink, VacuumwallLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbilityOnLocation(Vacuum, VacuumwallLocation)
        bot:ActionQueue_Delay(0.8)
        bot:ActionQueue_UseAbilityOnLocation(WallOfReplica, VacuumwallLocation)
        bot:ActionQueue_Delay(0.93)
        return
    end

    VacuumDesire, VacuumLocation = X.ConsiderVacuum()
    if VacuumDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Vacuum, VacuumLocation)
        return
    end

    WallOfReplicaDesire, WallOfReplicaLocation = X.ConsiderWallOfReplica()
    if WallOfReplicaDesire > 0
    then
        bot:Action_UseAbilityOnLocation(WallOfReplica, WallOfReplicaLocation)
        return
    end

    SurgeDesire, SurgeTarget = X.ConsiderSurge()
    if SurgeDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Surge, SurgeTarget)
        return
    end

    IonShellDesire, IonShellTarget = X.ConsiderIonShell()
    if IonShellDesire > 0
    then
        bot:Action_UseAbilityOnEntity(IonShell, IonShellTarget)
        return
    end
end

function X.ConsiderVacuum()
    if not Vacuum:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Vacuum:GetCastRange())
    local nCastPoint = Vacuum:GetCastPoint()
    local nRadius = Vacuum:GetSpecialValueInt('radius')
    local nDamage = Vacuum:GetSpecialValueInt('damage')
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not bInTeamFight
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
        end
    end

	if bInTeamFight
    and not CanDoVacuumWall()
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier("modifier_legion_commander_duel")
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if not Fu.IsInRange(bot, botTarget, nCastRange)
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                end
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderIonShell()
	if not IonShell:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, IonShell:GetCastRange())
    local nRadius = IonShell:GetSpecialValueInt('radius')
    local nAbilityLevel = IonShell:GetLevel()

    if bGoingOnSomeone
	then
		local target = nil
		local maxTargetCount = 1

        local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
        if nAllyHeroes ~= nil and #nAllyHeroes >= 1
        then
            for _, allyHero in pairs(nAllyHeroes)
            do
                if Fu.IsValid(allyHero)
                and not allyHero:IsIllusion()
                and not allyHero:HasModifier('modifier_dark_seer_ion_shell')
                and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    local nAllyCount = 0
                    local nAllyEnemyHeroes = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)
                    local nAllyEnemyCreeps = allyHero:GetNearbyCreeps(1200, true)

                    for _, allyEnemyHero in pairs(nAllyEnemyHeroes)
                    do
                        if allyEnemyHero ~= nil
                        and allyEnemyHero:IsAlive()
                        and allyEnemyHero:GetAttackTarget() == allyHero
                        and not Fu.IsSuspiciousIllusion(allyEnemyHero)
                        and allyHero:GetAttackRange() <= 326
                        then
                            nAllyCount = nAllyCount + 1
                        end
                    end

                    for _, creep in pairs(nAllyEnemyCreeps)
                    do
                        if creep ~= nil
                        and creep:IsAlive()
                        and creep:GetAttackTarget() == allyHero
                        and creep:GetAttackRange() <= 326
                        then
                            nAllyCount = nAllyCount + 1
                        end
                    end

                    if nAllyCount > maxTargetCount
                    then
                        maxTargetCount = nAllyCount
                        target = allyHero
                    end
                end
            end
        else
            if Fu.IsValidTarget(botTarget)
            and Fu.IsInRange(bot, botTarget, nRadius)
            and not Fu.IsSuspiciousIllusion(botTarget)
            and not bot:HasModifier('modifier_dark_seer_ion_shell')
            then
                target = bot
            end
        end

        if target ~= nil
        then
            return BOT_ACTION_DESIRE_HIGH, target
        end
	end

    if Fu.IsRetreating(bot)
    and bot:GetActiveModeDesire() > 0.75
    and not Vacuum:IsFullyCastable()
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not bot:HasModifier('modifier_dark_seer_ion_shell')
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsRealInvisible(bot)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, bot
                end
            end
        end
	end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        then
            local nAllyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, false)
            if nAllyLaneCreeps ~= nil and #nAllyLaneCreeps >= 1
            then
                local targetCreep = nil
                local targetDis = 0

                for _, creep in pairs(nAllyLaneCreeps)
                do
                    if Fu.IsValid(creep)
                    and Fu.GetHP(creep) > 0.75
                    and creep:DistanceFromFountain() > targetDis
                    and creep:GetAttackRange() <= 326
                    and not creep:HasModifier('modifier_dark_seer_ion_shell')
                    then
                        targetCreep = creep
                        targetDis = creep:DistanceFromFountain()
                    end
                end

                if targetCreep ~= nil
                then
                    return BOT_ACTION_DESIRE_HIGH, targetCreep
                end
            end
        end
	end

    if Fu.IsFarming(bot)
    then
        local botAttackTarget = bot:GetAttackTarget()
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius + bot:GetAttackRange())

        if Fu.IsValid(botAttackTarget)
        and botAttackTarget:IsCreep()
        and nNeutralCreeps ~= nil and #nNeutralCreeps >= 2
        then
            if not bot:HasModifier('modifier_dark_seer_ion_shell')
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    if Fu.IsLaning(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        local nEnemyTowers = bot:GetNearbyTowers(700, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        and nEnemyTowers ~= nil and #nInRangeEnemy == 0
        and nAbilityLevel >= 2
        then
            if Fu.IsAttacking(bot)
            and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            and not bot:HasModifier('modifier_dark_seer_ion_shell')
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	then
		if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, nRadius)
        and Fu.IsAttacking(bot)
        and not bot:HasModifier('modifier_dark_seer_ion_shell')
		then
			return BOT_ACTION_DESIRE_HIGH, bot
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSurge()
	if not Surge:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, Surge:GetCastRange())
    local nAbilityLevel = Surge:GetLevel()
    local RoshanLocation = Fu.GetCurrentRoshanLocation()
    local TormentorLocation = Fu.GetTormentorLocation(GetTeam())

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 1200)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nAllyHeroes = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
			local tToMeDist = GetUnitToUnitDistance(bot, botTarget)
			local targetHero = bot

			for _, allyHero in pairs(nAllyHeroes)
            do
                local allyTarget = Fu.GetProperTarget(allyHero)
				local dist = GetUnitToUnitDistance(allyHero, botTarget)

				if dist < tToMeDist
                and dist < nCastRange
                and Fu.IsValidTarget(allyTarget)
                and not Fu.IsSuspiciousIllusion(allyTarget)
                and not allyTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not allyTarget:HasModifier('modifier_necrolyte_reapers_scythe')
                and allyHero:IsFacingLocation(allyTarget:GetLocation(), 30)
                then
					tToMeDist = dist
					targetHero = allyHero
				end
			end

			return BOT_ACTION_DESIRE_HIGH, targetHero
		end
	end

    if Fu.IsRetreating(bot)
    and bot:GetActiveModeDesire() > 0.75
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and Fu.IsInRange(bot, enemyHero, 600)
            and not bot:HasModifier('modifier_dark_seer_ion_shell')
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsRealInvisible(bot)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1.5))
                then
                    return BOT_ACTION_DESIRE_HIGH, bot
                end
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
	then
        if GetUnitToLocationDistance(bot, RoshanLocation) > 1600
        and Fu.GetManaAfter(Surge:GetManaCost()) * bot:GetMana() > Vacuum:GetManaCost()
        and Fu.GetManaAfter(Surge:GetManaCost()) * bot:GetMana() > WallOfReplica:GetManaCost()
        and nAbilityLevel >= 3
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

    if Fu.IsDoingTormentor(bot)
	then
        if GetUnitToLocationDistance(bot, TormentorLocation) > 1600
        and Fu.GetManaAfter(Surge:GetManaCost()) * bot:GetMana() > Vacuum:GetManaCost()
        and Fu.GetManaAfter(Surge:GetManaCost()) * bot:GetMana() > WallOfReplica:GetManaCost()
        and nAbilityLevel >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
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
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and allyHero:GetCurrentMovementSpeed() < nAllyInRangeEnemy[1]:GetCurrentMovementSpeed()
            and allyHero:IsFacingLocation(Fu.GetTeamFountain(), 30)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderWallOfReplica()
	if not WallOfReplica:IsFullyCastable()
    or CanDoVacuumWall()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, WallOfReplica:GetCastRange())
	local nCastPoint = WallOfReplica:GetCastPoint() + 0.73
	local nRadius = Vacuum:GetSpecialValueInt('radius')

	if bInTeamFight
	then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
        end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderVacuumWall()
    if CanDoVacuumWall()
    then
        local nWallOfReplicaCastPoint = WallOfReplica:GetCastPoint() + 0.73
        local nVacuumCastRange = Fu.GetProperCastRange(false, bot, Vacuum:GetCastRange())
        local nVacuumRadius = Vacuum:GetSpecialValueInt('radius')

        if Fu.IsInTeamFight(bot, 1600)
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nVacuumCastRange, nVacuumRadius, nWallOfReplicaCastPoint, 0)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nVacuumRadius)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function CanDoVacuumWall()
    if Vacuum:IsFullyCastable()
    and WallOfReplica:IsFullyCastable()
    and HasBlink()
    then
        local manaCost = Vacuum:GetManaCost() + WallOfReplica:GetManaCost()

        if bot:GetMana() >= manaCost
        then
            bot.shouldBlink = true
            return true
        end
    end

    bot.shouldBlink = true
    return false
end

function HasBlink()
    local blink = nil

    for i = 0, 5 do
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

return X