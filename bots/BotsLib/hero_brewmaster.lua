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
						{1,2,3,3,3,6,3,2,2,2,6,1,1,1,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

local sUtility = {"item_crimson_guard", "item_pipe"} --, "item_lotus_orb"}
local sCrimsonPipeLotus = sUtility[RandomInt(1, #sUtility)]

sRoleItemsBuyList['pos_1'] = {
	"item_bristleback_outfit",
    "item_hand_of_midas",
    "item_radiance",--
	"item_heavens_halberd",--
	"item_black_king_bar",--
	"item_travel_boots",
	"item_abyssal_blade",--
	"item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_heart",--
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_magic_wand",
    "item_double_bracer",
    "item_boots",
    "item_radiance",--
    "item_assault",--
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_travel_boots",
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_magic_wand",
    "item_double_bracer",
    "item_boots",
    "item_radiance",--
    "item_pipe",--
    "item_black_king_bar",--
    sCrimsonPipeLotus,--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_shivas_guard",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
    "item_aghanims_shard",
	"item_assault",--
	"item_heavens_halberd",--
    "item_shivas_guard",--
    "item_refresher",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_pipe",--
    "item_aghanims_shard",
	"item_assault",--
	"item_heavens_halberd",--
    "item_shivas_guard",--
    "item_refresher",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_heavens_halberd",
	"item_quelling_blade",

	"item_assault",
	"item_quelling_blade",

	"item_abyssal_blade",
	"item_magic_wand",

	"item_assault",
	"item_ancient_janggo",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local ThunderClap       = bot:GetAbilityByName('brewmaster_thunder_clap')
local CinderBrew        = bot:GetAbilityByName('brewmaster_cinder_brew')
local DrunkenBrawler    = bot:GetAbilityByName('brewmaster_drunken_brawler')
local PrimalCompanion   = bot:GetAbilityByName('brewmaster_primal_companion')
local PrimalSplit       = bot:GetAbilityByName('brewmaster_primal_split')
local LiquidCourage     = bot:GetAbilityByName('brewmaster_liquid_courage')

local ThunderClapDesire
local CinderBrewDesire, CinderBrewLocation
local DrunkenBrawlerDesire, ActionType
local PrimalCompanionDesire
local PrimalSplitDesire
local LiquidCourageDesire, LiquidCourageTarget


local drunkenBrawlerState = 1

local botTarget
local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotMP
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = ctx.mp
	bInTeamFight = ctx.isTeamFight

    CinderBrewDesire, CinderBrewLocation = X.ConsiderCinderBrew()
    if CinderBrewDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(CinderBrew, CinderBrewLocation)
        return
    end

    ThunderClapDesire = X.ConsiderThunderClap()
    if ThunderClapDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbility(ThunderClap)
        return
    end

    PrimalSplitDesire = X.ConsiderPrimalSplit()
    if PrimalSplitDesire > 0
    then
        bot:Action_UseAbility(PrimalSplit)
        return
    end

    DrunkenBrawlerDesire, State = X.ConsiderDrunkenBrawler()
    if DrunkenBrawlerDesire > 0
    then
        if drunkenBrawlerState ~= State then
            bot:Action_UseAbility(DrunkenBrawler)
            drunkenBrawlerState = (drunkenBrawlerState % 3) + 1
        end
    end
    
    LiquidCourageDesire, LiquidCourageTarget = X.ConsiderLiquidCourage()
    if LiquidCourageDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(LiquidCourage, LiquidCourageTarget)
        return
    end

    PrimalCompanionDesire = X.ConsiderPrimalCompanion()
    if PrimalCompanionDesire > 0
    then
        bot:Action_UseAbility(PrimalSplit)
        return
    end
end

function X.ConsiderThunderClap()
    if not Fu.CanCastAbility(ThunderClap)
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRadius = ThunderClap:GetSpecialValueInt('radius')
    local nDamage = ThunderClap:GetSpecialValueInt('damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nRadius - 75)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius - 75)
        and not Fu.IsDisabled(botTarget)
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
	then
        if Fu.IsValidHero(nEnemyHeroes[1])
        and bot:WasRecentlyDamagedByAnyHero(1.5)
        and Fu.IsInRange(bot, nEnemyHeroes[1], nRadius)
        and Fu.IsChasingTarget(nEnemyHeroes[1], bot)
        and not Fu.IsDisabled(nEnemyHeroes[1])
        and not nEnemyHeroes[1]:HasModifier('modifier_brewmaster_cinder_brew')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        and nBotMP > 0.4
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and Fu.IsValid(nNeutralCreeps[1])
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and creep:GetHealth() <= nDamage
			then
				if Fu.IsValidHero(nEnemyHeroes[1])
                and GetUnitToUnitDistance(nEnemyHeroes[1], creep) < 500
                and nBotMP > 0.35
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                canKill = canKill + 1
                table.insert(creepList, creep)
            end
		end

        if canKill >= 2
        and nBotMP > 0.33
        and nEnemyHeroes ~= nil and #nEnemyHeroes >= 1
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        if Fu.IsInLaningPhase()
        then
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
            and Fu.GetManaAfter(ThunderClap:GetManaCost()) > 0.5
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and not botTarget:IsDisarmed()
        and Fu.CanCastOnMagicImmune(botTarget)
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

function X.ConsiderCinderBrew()
    if not Fu.CanCastAbility(CinderBrew)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nRadius = CinderBrew:GetSpecialValueInt('radius')
    local nCastRange = Fu.GetProperCastRange(false, bot, CinderBrew:GetCastRange())
    local nCastPoint = CinderBrew:GetCastPoint()
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)

	if bInTeamFight
	then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsDisabled(botTarget)

        and not botTarget:HasModifier('modifier_brewmaster_cinder_brew')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nTargetLoc = botTarget:GetLocation()
            if not Fu.IsInRange(bot, botTarget, nCastRange)
            then
                nTargetLoc = Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
            else
                if Fu.IsChasingTarget(bot, botTarget) then nTargetLoc = Fu.GetCorrectLoc(botTarget, nCastPoint) end
            end

            return BOT_ACTION_DESIRE_HIGH, nTargetLoc
		end
	end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
	then
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and bot:WasRecentlyDamagedByHero(enemyHero, 2)
            and Fu.IsInRange(bot, enemyHero, nRadius)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_brewmaster_cinder_brew')
            then
                return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        and not Fu.IsRunning(nEnemyLaneCreeps[1])
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end

        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        and nBotMP > 0.45
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(600)
            if nNeutralCreeps ~= nil
            and Fu.IsValid(nNeutralCreeps[1])
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
            end

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
            and not Fu.IsRunning(nEnemyLaneCreeps[1])
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and not botTarget:IsInvulnerable()
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderDrunkenBrawler()
    if not Fu.CanCastAbility(DrunkenBrawler)
    then
        return BOT_ACTION_DESIRE_NONE, -1
    end

    botTarget = Fu.GetProperTarget(bot)
    local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if Fu.GetHP(bot) < 0.33 and Fu.IsValidHero(nEnemyHeroes[1]) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        return BOT_ACTION_DESIRE_HIGH, 1
    end

    if bGoingOnSomeone then
        return BOT_ACTION_DESIRE_HIGH, 3
    end

    if bRetreating and not Fu.IsRealInvisible(bot) then
        return BOT_ACTION_DESIRE_HIGH, 2
    end

    if Fu.IsLaning(bot) or Fu.IsFarming(bot) then
        return BOT_ACTION_DESIRE_HIGH, 3
    end

    if Fu.IsDoingRoshan(bot) then
        if Fu.IsRoshan(botTarget) and Fu.CanBeAttacked(botTarget) and Fu.IsInRange(bot, botTarget, 600) then
            return BOT_ACTION_DESIRE_HIGH, 3
        else
            return BOT_ACTION_DESIRE_HIGH, 2
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget) and Fu.IsInRange(bot, botTarget, 600) then
            return BOT_ACTION_DESIRE_HIGH, 3
        else
            return BOT_ACTION_DESIRE_HIGH, 2
        end
    end

    return BOT_ACTION_DESIRE_NONE, -1
end

function X.ConsiderLiquidCourage()
    if not Fu.CanCastAbility(LiquidCourage) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = LiquidCourage:GetCastRange()

    for _, allyHero in pairs(nAllyHeroes) do
        if  Fu.IsValidHero(allyHero)
        and Fu.IsInRange(bot, allyHero, nCastRange)
        and not allyHero:IsIllusion()
        and not allyHero:IsChanneling()
        and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not Fu.IsAttacking(allyHero)
        and Fu.IsRunning(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2.0)
        then
            if (Fu.IsGoingOnSomeone(allyHero))
            or (Fu.IsRetreating(allyHero) and Fu.GetHP(allyHero) < 0.75)
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderPrimalCompanion()
    if not bot:HasScepter()
    or not Fu.CanCastAbility(PrimalCompanion)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local _, PrimalSplit = Fu.HasAbility(bot, 'brewmaster_primal_split')
    local nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
    botTarget = Fu.GetProperTarget(bot)

    if PrimalSplit ~= nil and (PrimalSplit:IsFullyCastable() or PrimalSplit:GetCooldownTimeRemaining() < 5)
    then
        return BOT_ACTION_DESIRE_NONE
    end

	if bInTeamFight
	then
        if nEnemyHeroes ~= nil and #nEnemyHeroes >= 2
        then
			return BOT_ACTION_DESIRE_HIGH
        end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and not botTarget:IsAttackImmune()
        and Fu.IsInRange(bot, botTarget, 600)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsMeepoClone(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not Fu.IsLocationInChrono(botTarget:GetLocation())
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderPrimalSplit()
    if not Fu.CanCastAbility(PrimalSplit)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
    botTarget = Fu.GetProperTarget(bot)

    if nAllyHeroes ~= nil and #nAllyHeroes == 0
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.GetHP(bot) < 0.33
    and nEnemyHeroes ~= nil and #nEnemyHeroes >= 2
    and nAllyHeroes ~= nil and #nAllyHeroes == 0
    then
        return BOT_ACTION_DESIRE_HIGH
    end

	if bInTeamFight
	then
        if nEnemyHeroes ~= nil and #nEnemyHeroes >= 2
        then
			return BOT_ACTION_DESIRE_HIGH
        end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and not botTarget:IsAttackImmune()
        and Fu.IsInRange(bot, botTarget, 888)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsMeepoClone(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not Fu.IsLocationInChrono(botTarget:GetLocation())
		then
            if nAllyHeroes ~= nil and nEnemyHeroes ~= nil
            and (#nAllyHeroes >= #nEnemyHeroes or Fu.WeAreStronger(bot, 1200))
            and Fu.IsCore(botTarget)
            and not (#nAllyHeroes >= 2 and #nEnemyHeroes <= 1)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
	then
		if nEnemyHeroes ~= nil and nAllyHeroes ~= nil
        and #nEnemyHeroes >= 3 and #nAllyHeroes <= 1
        then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

return X