local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos1
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos2
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        }
}

local tAllAbilityBuildList = {
						{1,4,4,2,4,2,2,2,6,1,1,1,4,2,6,6},--pos1
                        {4,1,4,2,4,1,4,1,1,6,2,2,2,2,6,6},--pos2
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
    "item_orb_of_frost",

    "item_boots",
    "item_orb_of_corrosion",
    "item_power_treads",
    "item_magic_wand",
    "item_echo_sabre",
    "item_desolator",--
    "item_black_king_bar",--
    "item_harpoon",--
    "item_basher",
    "item_skadi",--
    "item_travel_boots",
    "item_abyssal_blade",--
    "item_satanic",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",
    "item_orb_of_frost",

    "item_power_treads",
    "item_orb_of_corrosion",
    "item_magic_wand",
    "item_echo_sabre",
    "item_desolator",--
    "item_black_king_bar",--
    "item_harpoon",--
    "item_basher",
    "item_skadi",--
    "item_travel_boots",
    "item_abyssal_blade",--
    "item_satanic",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
    "item_satanic",
    "item_desolator"
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local BoundlessStrike   = SafeAbility(bot:GetAbilityByName('monkey_king_boundless_strike'), 'monkey_king_boundless_strike', 'monkey_king')
local TreeDance         = SafeAbility(bot:GetAbilityByName('monkey_king_tree_dance'), 'monkey_king_tree_dance', 'monkey_king')
local PrimalSpring      = SafeAbility(bot:GetAbilityByName('monkey_king_primal_spring'), 'monkey_king_primal_spring', 'monkey_king')
local SpringEarly       = SafeAbility(bot:GetAbilityByName('monkey_king_primal_spring_early'), 'monkey_king_primal_spring_early', 'monkey_king')
-- local JinguMastery      = bot:GetAbilityByName('monkey_king_jingu_mastery')
local Mischief          = SafeAbility(bot:GetAbilityByName('monkey_king_mischief'), 'monkey_king_mischief', 'monkey_king')
local RevertForm        = SafeAbility(bot:GetAbilityByName('monkey_king_untransform'), 'monkey_king_untransform', 'monkey_king')
local WukongsCommand    = SafeAbility(bot:GetAbilityByName('monkey_king_wukongs_command'), 'monkey_king_wukongs_command', 'monkey_king')
local ChangingOfTheGuard = SafeAbility(bot:GetAbilityByName('monkey_king_transfiguration'), 'monkey_king_transfiguration', 'monkey_king')

local BoundlessStrikeDesire, BoundlessStrikeLocation
local TreeDanceDesire, TreeDanceTarget
local PrimalSpringDesire, PrimalSpringLocation
local SpringEarlyDesire
local MischiefDesire
local WukongsCommandDesire, WukongsCommandLocation
local ChangingOfTheGuardDesire, ChangingOfTheGuardLocation

local botTarget
local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
local nBotMP
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = Fu.GetHP(bot)
	nBotMP = Fu.GetMP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    WukongsCommandDesire, WukongsCommandLocation = X.ConsiderWukongsCommand()
    if WukongsCommandDesire > 0
    then
        bot:Action_UseAbilityOnLocation(WukongsCommand, WukongsCommandLocation)
        return
    end

    BoundlessStrikeDesire, BoundlessStrikeLocation = X.ConsiderBoundlessStrike()
    if BoundlessStrikeDesire > 0
    then
        bot:Action_UseAbilityOnLocation(BoundlessStrike, BoundlessStrikeLocation)
        return
    end

    MischiefDesire = X.ConsiderMischief()
    if MischiefDesire > 0
    then
        bot:Action_ClearActions(false)
        bot:ActionQueue_UseAbility(Mischief)

        if not RevertForm:IsHidden()
        or RevertForm:IsFullyCastable()
        then
            bot:ActionQueue_Delay(0.2)
            bot:ActionQueue_UseAbility(RevertForm)
        end

        return
    end

    TreeDanceDesire, TreeDanceTarget = X.ConsiderTreeDance()
    if TreeDanceDesire > 0
    then
        bot:Action_UseAbilityOnTree(TreeDance, TreeDanceTarget)
        return
    end

    PrimalSpringDesire, PrimalSpringLocation = X.ConsiderPrimalSpring()
    if PrimalSpringDesire > 0
    then
        bot:Action_UseAbilityOnLocation(PrimalSpring, PrimalSpringLocation)
        return
    end

    -- SpringEarlyDesire = X.ConsiderSpringEarly()

    -- RevertFormDesire = X.ConsiderRevertForm()

    ChangingOfTheGuardDesire, ChangingOfTheGuardLocation = X.ConsiderChangingOfTheGuard()
    if ChangingOfTheGuardDesire > 0
    then
        bot:Action_UseAbilityOnLocation(ChangingOfTheGuard, ChangingOfTheGuardLocation)
        return
    end
end

function X.ConsiderBoundlessStrike()
    if not BoundlessStrike:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, BoundlessStrike:GetCastRange())
    local nCastPoint = BoundlessStrike:GetCastPoint()
    local nRadius = BoundlessStrike:GetSpecialValueInt('strike_radius')
    local nDamage = bot:GetAttackDamage() * (BoundlessStrike:GetSpecialValueInt('strike_crit_mult') / 100)
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            if bot:HasModifier('modifier_monkey_king_quadruple_tap_bonuses')
            and Fu.GetHP(enemyHero) < 0.5
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
            end

            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
            end
        end
	end

    if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nLocationAoE.count >= 2
		then
            local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
		end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
            end
		end
	end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.65 and bot:WasRecentlyDamagedByAnyHero(2.2)))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsFarming(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
            --     and nBotMP > 0.33
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
			-- 	end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                canKill = canKill + 1
                table.insert(creepList, creep)
            end
		end

        if canKill >= 2
        and nBotMP > 0.25
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
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
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2.1)
        and not allyHero:IsIllusion()
        and nBotMP > 0.59
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
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderTreeDance()
    if not TreeDance:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = TreeDance:GetCastRange()
    botTarget = Fu.GetProperTarget(bot)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
	if nEnemyHeroes == nil
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	if bGoingOnSomeone
    and PrimalSpring:IsFullyCastable()
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local nTrees = bot:GetNearbyTrees(nCastRange)

            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            and nTrees ~= nil and #nTrees >= 1
            and (IsLocationVisible(GetTreeLocation(nTrees[1]))
			    or IsLocationPassable(GetTreeLocation(nTrees[1])))
            then
                return BOT_ACTION_DESIRE_HIGH, nTrees[1]
            end
		end
	end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.65 and bot:WasRecentlyDamagedByAnyHero(2.2)))
            and bot:DistanceFromFountain() > 1000
            then
                local nTrees = bot:GetNearbyTrees(nCastRange)
                local furthest = GetFurthestTree(nTrees)

                if furthest ~= nil
                and (IsLocationVisible(GetTreeLocation(furthest))
			        or IsLocationPassable(GetTreeLocation(furthest)))
                then
                    return BOT_ACTION_DESIRE_HIGH, furthest
                end
            end
        end
	end

    if Fu.IsFarming(bot)
    and nBotMP > 0.35
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
        if nNeutralCreeps ~= nil
        and ((#nNeutralCreeps >= 3)
            or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
        then
            local nTrees = nNeutralCreeps[1]:GetNearbyTrees(nCastRange)

            if nTrees ~= nil and #nTrees >= 1
            and (IsLocationVisible(GetTreeLocation(nTrees[1]))
			    or IsLocationPassable(GetTreeLocation(nTrees[1])))
            then
                return BOT_ACTION_DESIRE_HIGH, nTrees[1]
            end
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        then
            local nTrees = nEnemyLaneCreeps[1]:GetNearbyTrees(nCastRange)

            if nTrees ~= nil and #nTrees >= 1
            and (IsLocationVisible(GetTreeLocation(nTrees[1]))
			    or IsLocationPassable(GetTreeLocation(nTrees[1])))
            then
                return BOT_ACTION_DESIRE_HIGH, nTrees[1]
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderPrimalSpring()
    if PrimalSpring:IsHidden()
    or not PrimalSpring:IsFullyCastable()
    or not PrimalSpring:IsActivated()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nMaxDistance = PrimalSpring:GetSpecialValueInt('max_distance')
	local nChannelTime = PrimalSpring:GetChannelTime()
	local nRadius = PrimalSpring:GetSpecialValueInt('impact_radius')

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nMaxDistance, nRadius, nChannelTime, 0)
		if nLocationAoE.count >= 2
		then
            local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
		end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local weakestTarget = Fu.GetAttackableWeakestUnit(bot, nMaxDistance, true, true)

        if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        and not weakestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not weakestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not weakestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not Fu.IsLocationInChrono(weakestTarget:GetLocation())
        and not Fu.IsLocationInBlackHole(weakestTarget:GetLocation())
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, weakestTarget:GetExtrapolatedLocation(nChannelTime)
            end
		end
	end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nMaxDistance)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.71 and bot:WasRecentlyDamagedByAnyHero(2.2)))
            then
                local loc = Fu.GetEscapeLoc()
		        return BOT_ACTION_DESIRE_MODERATE, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nMaxDistance)
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nMaxDistance, nRadius, nChannelTime, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nMaxDistance, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.35
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nMaxDistance, nRadius, nChannelTime, 0)

        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nMaxDistance)
        if nNeutralCreeps ~= nil
        and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
            or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nMaxDistance, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and nLocationAoE.count >= 3
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsLaning(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nMaxDistance, nRadius, nChannelTime, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nMaxDistance, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2
        and nLocationAoE.count >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderMischief()
    if not Mischief:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsStunProjectileIncoming(bot, 600)
	then
		return BOT_ACTION_DESIRE_HIGH
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderWukongsCommand()
    if not WukongsCommand:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = WukongsCommand:GetSpecialValueInt('cast_range')
	local nRadius = WukongsCommand:GetSpecialValueInt('second_radius')
    botTarget = Fu.GetProperTarget(bot)

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius / 2, 1, 0)
		if nLocationAoE.count >= 2
		then
            local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
            if realEnemyCount ~= nil and #realEnemyCount >= 2
            and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
            and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
		end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        -- and Fu.IsCore(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not Fu.IsLocationInChrono(botTarget:GetLocation())
        and not Fu.IsLocationInBlackHole(botTarget:GetLocation())
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(1)
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- Helper Funcs
function GetFurthestTree(nTrees)
	if GetAncient(GetTeam()) == nil then return nil end

	local furthest = nil
	local fDist = 10000

	for _, tree in pairs(nTrees)
	do
		local dist = GetUnitToLocationDistance(GetAncient(GetTeam()), GetTreeLocation(tree))

		if dist < fDist
        then
			furthest = tree
			fDist = dist
		end
	end

	return furthest
end

function X.ConsiderChangingOfTheGuard()
    if not Fu.CanCastAbility(ChangingOfTheGuard)
    or bot:IsRooted()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bot:HasModifier('modifier_monkey_king_fur_army_bonus_damage') then
        local nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE)
        local nAllyHeroes = Fu.GetNearbyHeroes(bot, 1600, false, BOT_MODE_NONE)
        if (Fu.IsStunProjectileIncoming(bot, 550) and #nEnemyHeroes > #nAllyHeroes)
        or (Fu.GetAttackProjectileDamageByRange(bot, 900) > bot:GetHealth())
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X