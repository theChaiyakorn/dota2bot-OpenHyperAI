local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,1,3,1,2,1,6,2,2,2,6,3,3,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

local sUtility = {"item_lotus_orb", "item_crimson_guard", "item_heavens_halberd"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

sRoleItemsBuyList['pos_1'] = {
	"item_bristleback_outfit",
	"item_blade_mail",--
	"item_heavens_halberd",--
	"item_lotus_orb",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_travel_boots",
	"item_abyssal_blade",--
	-- "item_heart",--
	"item_moon_shard",
    "item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
	"item_crimson_guard",
	"item_heavens_halberd",
	"item_lotus_orb",
	"item_aghanims_shard",
	"item_gungir",--
	"item_travel_boots",
	"item_assault",
	"item_heart",
	"item_moon_shard",
    "item_ultimate_scepter_2",
	"item_travel_boots_2",
}

sRoleItemsBuyList['pos_4'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",
    "item_double_gauntlets",

    "item_bracer",
    "item_helm_of_iron_will",
    "item_soul_ring",
    "item_arcane_boots",
    "item_magic_wand",
    "item_veil_of_discord",
    "item_mekansm",
    "item_pipe",--
    "item_guardian_greaves",--
    nUtility,--
    "item_aghanims_shard",
    "item_shivas_guard",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_mage_outfit',
	"item_ancient_janggo",
	"item_glimmer_cape",--
	"item_boots_of_bearing",--
	"item_pipe",--
	"item_aghanims_shard",
	"item_cyclone",
    "item_shivas_guard",--
	"item_sheepstick",--
    "item_heart",--
	"item_octarine_core",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_travel_boots",
	"item_quelling_blade",

	"item_abyssal_blade",
	"item_magic_wand",

	"item_shivas_guard",
	"item_bracer",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local Firestorm     = bot:GetAbilityByName('abyssal_underlord_firestorm')
local PitOfMalice   = bot:GetAbilityByName('abyssal_underlord_pit_of_malice')
-- local AtrophyAura   = bot:GetAbilityByName('abyssal_underlord_atrophy_aura')
local FiendsGate    = bot:GetAbilityByName('abyssal_underlord_dark_portal')

local FirestormDesire, FirestormLocation
local PitOfMaliceDesire, PitOfMaliceLocation
local FiendsGateDesire, FiendsGateLocation

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

    PitOfMaliceDesire, PitOfMaliceLocation = X.ConsiderPitOfMalice()
    if PitOfMaliceDesire > 0
    then
        bot:Action_UseAbilityOnLocation(PitOfMalice, PitOfMaliceLocation)
        return
    end

    FirestormDesire, FirestormLocation = X.ConsiderFirestorm()
    if FirestormDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Firestorm, FirestormLocation)
        return
    end

    FiendsGateDesire, FiendsGateLocation = X.ConsiderFiendsGate()
    if FiendsGateDesire > 0
    then
        bot:Action_UseAbilityOnLocation(FiendsGate, FiendsGateLocation)
        return
    end
end

function X.ConsiderFirestorm()
    if not Firestorm:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Firestorm:GetCastRange())
    local nRadius = Firestorm:GetSpecialValueInt('radius')
    local nCastPoint = Firestorm:GetCastPoint()

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange + nRadius, nRadius, nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nLocationAoE.targetloc, nCastRange)
        end
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nCastRange + nRadius)

                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                end

                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
            end
		end
	end

    if Fu.IsPushing(bot)
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + nRadius, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
	end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange + nRadius)
            if nNeutralCreeps ~= nil and #nNeutralCreeps >= 3
            and nBotMP > 0.3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nBotMP > 0.3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + nRadius, true)

        if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and bAttacking
        and nBotMP > 0.5
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderPitOfMalice()
    if not PitOfMalice:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, PitOfMalice:GetCastRange())
	local nRadius = PitOfMalice:GetSpecialValueInt('radius')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and enemyHero:IsChanneling()
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetLocation(), nCastRange)
        end
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nCastRange + nRadius)

                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                end

                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
            end
		end
	end

	if Fu.IsRetreating(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
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
                    or bot:WasRecentlyDamagedByAnyHero(2.5))
                and GetUnitToUnitDistance(bot, enemyHero) < nRadius + 100
                then
                    return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
                end
            end
        end
    end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange + nRadius, nRadius, 0, 0)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeEnemy >= 1
        and not (#nInRangeAlly > #nInRangeEnemy + 1)
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderFiendsGate()
    if not FiendsGate:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

    if nTeamFightLocation ~= nil
    and GetUnitToLocationDistance(bot, nTeamFightLocation) > 2500
    and not bGoingOnSomeone
    and not Fu.IsRetreating(bot)
    and not Fu.IsInLaningPhase()
    then
        local nInRangeAlly = Fu.GetAlliesNearLoc(nTeamFightLocation, 1200)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nTeamFightLocation, 1200)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeAlly + 1 >= #nInRangeEnemy
        and #nInRangeEnemy >= 1
        then
            local targetLoc = Fu.GetCenterOfUnits(nInRangeAlly)

            if IsLocationPassable(targetLoc)
            and not Fu.IsLocationInChrono(targetLoc)
            and not Fu.IsLocationInBlackHole(targetLoc)
            and not Fu.IsLocationInArena(targetLoc, 600)
            then
                bot:SetTarget(nInRangeEnemy[1])
                return BOT_ACTION_DESIRE_HIGH, targetLoc
            end
        end
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and GetUnitToUnitDistance(bot, botTarget) > 2500
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsInLaningPhase()
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)
            local nEnemyTowers = bot:GetNearbyTowers(700, true)

			if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and nInRangeEnemy ~= nil and nEnemyTowers ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            and #nInRangeEnemy == 0 and #nEnemyTowers == 0
            then
                local targetLoc = Fu.GetCenterOfUnits(nInRangeAlly)

                if IsLocationPassable(targetLoc)
                and not Fu.IsLocationInChrono(targetLoc)
                and not Fu.IsLocationInBlackHole(targetLoc)
                and not Fu.IsLocationInArena(targetLoc, 600)
                then
                    bot:SetTarget(botTarget)
                    return BOT_ACTION_DESIRE_HIGH, targetLoc
                end
            end
		end
	end

    local aveDist = {0,0,0}
    local pushCount = {0,0,0}
    for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsGoingOnSomeone(allyHero)
        and GetUnitToUnitDistance(bot, allyHero) > 2500
        and not allyHero:IsIllusion()
        and not Fu.IsInLaningPhase()
        then
            local allyTarget = allyHero:GetAttackTarget()
            local nAllyInRangeAlly = Fu.GetNearbyHeroes(allyHero, 800, false, BOT_MODE_NONE)

            if Fu.IsValidTarget(allyTarget)
            and Fu.IsInRange(allyHero, allyTarget, 800)
            and Fu.GetHP(allyHero) > 0.5
            -- and Fu.IsCore(allyTarget)
            and not Fu.IsSuspiciousIllusion(allyTarget)
            then
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(allyTarget, 800, false, BOT_MODE_NONE)
                local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)
                local nEnemyTowers = bot:GetNearbyTowers(700, true)

                if nAllyInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nAllyInRangeAlly + 1 >= #nTargetInRangeAlly
                and #nTargetInRangeAlly >= 1
                and nInRangeEnemy ~= nil and nEnemyTowers ~= nil
                and #nInRangeEnemy == 0 and #nEnemyTowers == 0
                then
                    local targetLoc = Fu.GetCenterOfUnits(allyHero:GetExtrapolatedLocation(1))

                    if IsLocationPassable(targetLoc)
                    and not Fu.IsLocationInChrono(targetLoc)
                    and not Fu.IsLocationInBlackHole(targetLoc)
                    and not Fu.IsLocationInArena(targetLoc, 600)
                    then
                        bot:SetTarget(allyTarget)
                        return BOT_ACTION_DESIRE_HIGH, targetLoc
                    end
                end
            end
        end

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
            return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_TOP, 0)
        end
    elseif pushCount[2] ~= nil and pushCount[2] >= 3 and (aveDist[2] / pushCount[2]) <= 1200
    then
        if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), LANE_MID, 0)) > 4000
        then
            return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_MID, 0)
        end
    elseif pushCount[3] ~= nil and pushCount[3] >= 3 and (aveDist[3] / pushCount[3]) <= 1200
    then
        if GetUnitToLocationDistance(bot, GetLaneFrontLocation(GetTeam(), LANE_BOT, 0)) > 4000
        then
            return BOT_ACTION_DESIRE_HIGH, GetLaneFrontLocation(GetTeam(), LANE_BOT, 0)
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

return X