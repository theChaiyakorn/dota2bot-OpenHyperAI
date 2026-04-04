local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        {--pos1
                            ['t25'] = {0, 10},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        },
                        {--pos2
                            ['t25'] = {0, 10},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        }
}

local tAllAbilityBuildList = {
                        {2,3,2,3,3,6,2,2,1,1,6,1,1,3,6},--pos1
                        {2,3,2,3,3,6,2,2,1,1,1,6,1,3,6},--pos2
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_1"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_magic_wand",
    "item_falcon_blade",
    "item_power_treads",
    "item_desolator",--
    "item_orchid",
    "item_dragon_lance",
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_bloodthorn",--
    "item_force_staff",
    "item_hurricane_pike",--
    "item_greater_crit",--
    "item_moon_shard",
    "item_butterfly",--
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
	"item_mid_outfit",
	"item_dragon_lance",
    "item_desolator",--
    "item_orchid",
    "item_dragon_lance",
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_bloodthorn",--
    "item_force_staff",
    "item_hurricane_pike",--
    "item_sheepstick",--
    "item_moon_shard",
    "item_butterfly",--
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
    "item_hurricane_pike",
    "item_urn_of_shadows",

    "item_mjollnir",
    "item_magic_wand",

    "item_hand_of_midas",
    "item_urn_of_shadows",

    "item_greater_crit", 
    "item_hand_of_midas",

    "item_greater_crit",
    "item_falcon_blade",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local Strafe            = bot:GetAbilityByName('clinkz_strafe')
local TarBomb           = bot:GetAbilityByName('clinkz_tar_bomb')
local DeathPact         = bot:GetAbilityByName('clinkz_death_pact')
local BurningBarrage    = bot:GetAbilityByName('clinkz_burning_barrage')
local BurningArmy       = bot:GetAbilityByName('clinkz_burning_army')
local SkeletonWalk      = bot:GetAbilityByName('clinkz_wind_walk')
local SearingArrows     = bot:GetAbilityByName('clinkz_searing_arrows')

local StrafeDesire
local TarBombDesire, TarBombTarget
local DeathPactDesire, DeathPactTarget
local BurningBarrageDesire, BurningBarrageLocation
local BurningArmyDesire, BurningArmyLocation
local SkeletonWalkDesire
local SearingArrowsDesire, SearingArrowsTarget

local botTarget

local bGoingOnSomeone
local bAttacking
local nBotMP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = ctx.mp

    botTarget = ctx.target

    SkeletonWalkDesire = X.ConsiderSkeletonWalk()
    if SkeletonWalkDesire > 0
    then
        bot:Action_UseAbility(SkeletonWalk)
        return
    end

    TarBombDesire, TarBombTarget = X.ConsiderTarBomb()
    if TarBombDesire > 0
    then
        bot:Action_UseAbilityOnEntity(TarBomb, TarBombTarget)
        return
    end

    SearingArrowsDesire, SearingArrowsTarget = X.ConsiderSearingArrows()
    if SearingArrowsDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SearingArrows, SearingArrowsTarget)
        return
    end

    BurningBarrageDesire, BurningBarrageLocation = X.ConsiderBurningBarrage()
    if BurningBarrageDesire > 0
    then
        bot:Action_UseAbilityOnLocation(BurningBarrage, BurningBarrageLocation)
        return
    end

    StrafeDesire = X.ConsiderStrafe()
    if StrafeDesire > 0
    then
        bot:Action_UseAbility(Strafe)
        return
    end

    DeathPactDesire, DeathPactTarget = X.ConsiderDeathPact()
    if DeathPactDesire > 0
    then
        bot:Action_UseAbilityOnEntity(DeathPact, DeathPactTarget)
        return
    end

    BurningArmyDesire, BurningArmyLocation = X.ConsiderBurningArmy()
    if BurningArmyDesire > 0
    then
        bot:Action_UseAbilityOnLocation(BurningArmy, BurningArmyLocation)
        return
    end
end

function X.ConsiderStrafe()
    if not Strafe:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE
	end

    local nAttackRange = bot:GetAttackRange()

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nAttackRange)
        and not Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
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

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(1000)
            if nNeutralCreeps ~= nil
            and (#nNeutralCreeps >= 3
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                if SkeletonWalk:IsTrained()
                then
                    if Fu.GetManaAfter(Strafe:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                else
                    if nBotMP > 0.25
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
            then
                if SkeletonWalk:IsTrained()
                then
                    if Fu.GetManaAfter(Strafe:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                else
                    if nBotMP > 0.25
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end
        end
    end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        then
            if SkeletonWalk:IsTrained()
            then
                if Fu.GetManaAfter(Strafe:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            else
                if nBotMP > 0.25
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

	if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	then
		if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, nAttackRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderTarBomb()
    if not TarBomb:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

    local nLevel = TarBomb:GetLevel()
    local nCastRange = TarBomb:GetCastRange()
    local nDamage = 40 + (20 * nLevel - 1)
    local nRadius = 325
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidTarget(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if bAttacking
                or (Fu.IsChasingTarget(bot, botTarget)
                    and bot:GetCurrentMovementSpeed() < botTarget:GetCurrentMovementSpeed())
                then
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end
        end
    end

	if Fu.IsRetreating(bot)
    and bot:GetActiveModeDesire() > 0.5
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
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
                and bot:GetCurrentMovementSpeed() < enemyHero:GetCurrentMovementSpeed()
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
	end

    if Fu.IsPushing(bot)
    then
        if Fu.IsValidBuilding(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(1000)
            if nNeutralCreeps ~= nil and #nNeutralCreeps >= 1
            and nNeutralCreeps[1]:GetHealth() >= 600
            then
                if SkeletonWalk:IsTrained()
                then
                    if Fu.GetManaAfter(TarBomb:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
                    then
                        return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]
                    end
                else
                    if nBotMP > 0.4
                    then
                        return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]
                    end
                end
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 1
            and nEnemyLaneCreeps[1]:GetHealth() >= 550
            then
                if SkeletonWalk:IsTrained()
                then
                    if Fu.GetManaAfter(TarBomb:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
                    then
                        return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
                    end
                else
                    if nBotMP > 0.4
                    then
                        return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
                    end
                end
            end
        end
    end

    if Fu.IsLaning(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and creep:GetHealth() <= nDamage
			then
				local nCreepInRangeHero = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)

				if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
                and GetUnitToUnitDistance(creep, nCreepInRangeHero[1]) < 600
                and botTarget ~= creep
                and nBotMP > 0.3
                and Fu.CanBeAttacked(creep)
                and Fu.IsInLaningPhase()
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
    end

	if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	then
		if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
		then
            if SkeletonWalk:IsTrained()
            then
                if Fu.GetManaAfter(TarBomb:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
                then
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            else
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
		end
	end

    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and allyHero:GetCurrentMovementSpeed() < nAllyInRangeEnemy[1]:GetCurrentMovementSpeed()
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

function X.ConsiderDeathPact()
    if not DeathPact:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = DeathPact:GetCastRange()
    local nMaxLevel = DeathPact:GetSpecialValueInt('creep_level')
    local nCreeps = bot:GetNearbyCreeps(nCastRange, true)

    if Fu.IsInLaningPhase()
    then
        if Fu.IsLaning(bot)
        then
            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

            for _, creep in pairs(nEnemyLaneCreeps)
            do
                if Fu.IsValid(creep)
                and Fu.CanBeAttacked(creep)
                and Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep)
                and creep:GetLevel() <= nMaxLevel
                then
                    local nCreepInRangeHero = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)

                    if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
                    and GetUnitToUnitDistance(creep, nCreepInRangeHero[1]) < 600
                    and botTarget ~= creep
                    and not bot:HasModifier('modifier_clinkz_death_pact')
                    then
                        return BOT_ACTION_DESIRE_HIGH, creep
                    end
                end
            end
        end
    else
        local creep = GetMostHPCreepLevel(nCreeps, nMaxLevel)
        if creep ~= nil
        and not bot:HasModifier('modifier_clinkz_death_pact')
        and not creep:IsAncientCreep()
        then
            return BOT_ACTION_DESIRE_HIGH, creep
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSkeletonWalk()
    if not SkeletonWalk:IsFullyCastable()
    or bot:HasModifier('modifier_clinkz_wind_walk')
    or Fu.IsRealInvisible(bot)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local RoshanLocation = Fu.GetCurrentRoshanLocation()
    local TormentorLocation = Fu.GetTormentorLocation(GetTeam())
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

    if bGoingOnSomeone
    and bot:GetActiveModeDesire() > 0.65
	then
		if Fu.IsValidTarget(botTarget)
        and GetUnitToUnitDistance(bot, botTarget) > 1600
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetAlliesNearLoc(botTarget:GetLocation(), 1200)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), 1200)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if Fu.IsRetreating(bot)
    and bot:GetActiveModeDesire() > 0.5
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
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

    -- if Fu.IsPushing(bot)
    -- then
    --     if bot.laneToPush ~= nil
    --     then
    --         if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), bot.laneToPush, 0)) > 3200
    --         and bot:GetActiveModeDesire() > 0.65
    --         then
    --             return  BOT_ACTION_DESIRE_HIGH
    --         end
    --     end
    -- end

    -- if Fu.IsDefending(bot)
    -- then
    --     if bot.laneToDefend ~= nil
    --     then
    --         if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), bot.laneToDefend, 0)) > 3200
    --         and bot:GetActiveModeDesire() > 0.65
    --         then
    --             return  BOT_ACTION_DESIRE_HIGH
    --         end
    --     end
    -- end

    if Fu.IsFarming(bot)
    then
        if bot.farmLocation ~= nil
        then
            if GetUnitToLocationDistance(bot, bot.farmLocation) > 3200
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsLaning(bot)
	then
		if Fu.GetManaAfter(SkeletonWalk:GetManaCost()) > 0.8
		and bot:DistanceFromFountain() > 100
		and bot:DistanceFromFountain() < 6000
		and Fu.IsInLaningPhase()
		and nEnemyHeroes ~= nil and #nEnemyHeroes == 0
		then
			local nLane = bot:GetAssignedLane()
			local nLaneFrontLocation = GetLaneFrontLocation(GetTeam(), nLane, 0)
			local nDistFromLane = GetUnitToLocationDistance(bot, nLaneFrontLocation)

			if nDistFromLane > 1600
			then
                return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if GetUnitToLocationDistance(bot, RoshanLocation) > 4000
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if GetUnitToLocationDistance(bot, TormentorLocation) > 4000
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSearingArrows()
    if not Fu.CanCastAbility(SearingArrows)
    or bot:IsDisarmed()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = bot:GetAttackRange()
    local nManaCost = SearingArrows:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Strafe, DeathPact, BurningBarrage, BurningArmy, SkeletonWalk})

    local bIsAutoCasted = SearingArrows:GetAutoCastState()

	if bGoingOnSomeone then
		if  Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + 300)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:IsMagicImmune()
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            if fManaAfter > fManaThreshold1 + 0.1 then
                if not bIsAutoCasted then
                    SearingArrows:ToggleAutoCast()
                end

                return BOT_ACTION_DESIRE_NONE
            end
		end
	end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot) or Fu.IsFarming(bot) then
        if  Fu.IsValid(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.CanKillTarget(botTarget, bot:GetAttackDamage() * 3, DAMAGE_TYPE_PHYSICAL)
        and not Fu.IsRoshan(botTarget)
        and not Fu.IsTormentor(botTarget)
        then
            if fManaAfter > fManaThreshold1 + 0.15 then
                if not bIsAutoCasted then
                    SearingArrows:ToggleAutoCast()
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

	if Fu.IsDoingRoshan(bot) then
        if  Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        then
            if fManaAfter > fManaThreshold1 + 0.15 then
                if not bIsAutoCasted and bAttacking then
                    SearingArrows:ToggleAutoCast()
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        then
            if fManaAfter > fManaThreshold1 + 0.15 then
                if not bIsAutoCasted and bAttacking then
                    SearingArrows:ToggleAutoCast()
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if bIsAutoCasted then
        SearingArrows:ToggleAutoCast()
    end

    return BOT_ACTION_DESIRE_NONE, nil
end


--Aghanim's Shard
function X.ConsiderBurningBarrage()
    if not BurningBarrage:IsTrained()
    or not BurningBarrage:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, BurningBarrage:GetCastRange())
    local nRadius = BurningBarrage:GetSpecialValueInt('radius')

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange - 125)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetAlliesNearLoc(botTarget:GetLocation(), 1200)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), 1200)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius - 75)
                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(0.5)
                end
            end
		end
	end

    if Fu.IsFarming(bot)
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(1000)
        if nNeutralCreeps ~= nil and #nNeutralCreeps >= 1
        and bAttacking
        and Fu.GetManaAfter(BurningBarrage:GetManaCost()) * bot:GetMana() > SkeletonWalk:GetManaCost()
        then
            if Fu.IsBigCamp(nNeutralCreeps)
            or nNeutralCreeps[1]:IsAncientCreep()
            then
                if #nNeutralCreeps >= 2
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
                end
            else
                if #nNeutralCreeps >= 3
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
                end
            end
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end
    end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end
    end

    if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	then
		if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

--Aghanim's Scepter
function X.ConsiderBurningArmy()
    if not BurningBarrage:IsTrained()
    or not BurningBarrage:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nAttackRange = bot:GetAttackRange()
	local nCastRange = BurningArmy:GetCastRange()
    local nSpawnRange = 900

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange + (nSpawnRange / 2), nSpawnRange, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nSpawnRange)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            if GetUnitToLocationDistance(bot, Fu.GetCenterOfUnits(nInRangeEnemy)) > nCastRange
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
            else
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
            end
		end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetAlliesNearLoc(botTarget:GetLocation(), 1200)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), 1200)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nSpawnRange)
                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    if GetUnitToLocationDistance(bot, Fu.GetCenterOfUnits(nInRangeEnemy)) > nCastRange
                    then
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                    else
                        return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                    end
                else
                    if GetUnitToUnitDistance(bot, botTarget) > nCastRange
                    then
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                    else
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(0.5)
                    end
                end
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- Helper Funcs
function GetMostHPCreepLevel(creeList, level)
	local mostHpCreep = nil
	local maxHP = 0

	for _, creep in pairs(creeList)
	do
		local uHp = creep:GetHealth()
        local lvl = creep:GetLevel()

		if uHp > maxHP
        and lvl <= level
        and not Fu.IsKeyWordUnit("flagbearer", creep)
		then
			mostHpCreep = creep
			maxHP = uHp
		end
	end

	return mostHpCreep
end

return X