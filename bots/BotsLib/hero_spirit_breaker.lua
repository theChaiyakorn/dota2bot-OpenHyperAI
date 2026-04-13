local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{3,1,2,3,3,6,3,1,1,1,6,2,2,2,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

local sUtility = {"item_pipe", "item_lotus_orb", "item_crimson_guard", "item_heavens_halberd"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

sRoleItemsBuyList['pos_3'] = {
    "item_quelling_blade",
    "item_tango",
    "item_double_branches",

    "item_bracer",
    "item_wind_lace",
    "item_phase_boots",
    "item_magic_wand",
    "item_hand_of_midas",
    "item_yasha_and_kaya",--
	"item_invis_sword",
    "item_black_king_bar",--
    -- nUtility,--
    "item_ultimate_scepter_2",
    "item_octarine_core",--
    "item_silver_edge",--
    "item_aghanims_shard",
    "item_cyclone",
    "item_wind_waker",--
    "item_moon_shard",
    "item_travel_boots",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

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

local ChargeOfDarkness  = SafeAbility(bot:GetAbilityByName('spirit_breaker_charge_of_darkness'), 'spirit_breaker_charge_of_darkness', 'spirit_breaker')
local Bulldoze          = SafeAbility(bot:GetAbilityByName('spirit_breaker_bulldoze'), 'spirit_breaker_bulldoze', 'spirit_breaker')
local GreaterBash       = SafeAbility(bot:GetAbilityByName('spirit_breaker_greater_bash'), 'spirit_breaker_greater_bash', 'spirit_breaker')
local PlanarPocket      = SafeAbility(bot:GetAbilityByName('spirit_breaker_planar_pocket'), 'spirit_breaker_planar_pocket', 'spirit_breaker')
local NetherStrike      = SafeAbility(bot:GetAbilityByName('spirit_breaker_nether_strike'), 'spirit_breaker_nether_strike', 'spirit_breaker')

local ChargeOfDarknessDesire, ChargeOfDarknessTarget
local BulldozeDesire
local PlanarPocketDesire
local NetherStrikeDesire, NetherStrikeTarget
local nInRangeEnemy

if bot.chargeRetreat == nil then bot.chargeRetreat = false end

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

    nInRangeEnemy = ctx.enemies

    if bot:HasModifier('modifier_spirit_breaker_charge_of_darkness') or ChargeOfDarkness:IsInAbilityPhase() then
        if bot.chargeRetreat and #nInRangeEnemy == 0
        then
            bot:Action_MoveToLocation(bot:GetLocation() + RandomVector(150))
            bot.chargeRetreat = false
        end

        return
    end

    ChargeOfDarknessDesire, ChargeOfDarknessTarget = X.ConsiderChargeOfDarkness()
    if ChargeOfDarknessDesire > 0
    then
        if ChargeOfDarkness:GetLevel() >= 3
        and Bulldoze:IsTrained()
        and Bulldoze:IsFullyCastable()
        then
            bot:Action_UseAbility(Bulldoze)
        end

        bot:Action_UseAbilityOnEntity(ChargeOfDarkness, ChargeOfDarknessTarget)
        return
    end

    BulldozeDesire = X.ConsiderBulldoze()
    if BulldozeDesire > 0
    then
        bot:Action_UseAbility(Bulldoze)
        return
    end

    PlanarPocketDesire = X.ConsiderPlanarPocket()
    if PlanarPocketDesire > 0
    then
        bot:Action_UseAbility(PlanarPocket)
        return
    end

    NetherStrikeDesire, NetherStrikeTarget = X.ConsiderNetherStrike()
    if NetherStrikeDesire > 0
    then
        bot:Action_UseAbilityOnEntity(NetherStrike, NetherStrikeTarget)
        return
    end
end

function X.ConsiderChargeOfDarkness()
    if not ChargeOfDarkness:IsFullyCastable()
    or bot:HasModifier('modifier_spirit_breaker_charge_of_darkness')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if not bRetreating then
        bot.chargeRetreat = false
    end

    local nRadius = ChargeOfDarkness:GetSpecialValueInt('bash_radius')
    botTarget = Fu.GetProperTarget(bot)

    for _, enemyHero in pairs(nInRangeEnemy)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not Fu.IsLocationInChrono(enemyHero:GetLocation())
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1600, true, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if enemyHero:IsChanneling()
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
    if nTeamFightLocation ~= nil
    and GetUnitToLocationDistance(bot, nTeamFightLocation) > 1600
    and not Fu.IsInLaningPhase()
    then
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and not Fu.IsLocationInChrono(nTeamFightLocation)
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
        end
    end

	if bGoingOnSomeone
	then
        local target = nil
        local dmg = 0

        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsLocationInChrono(enemyHero:GetLocation())
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)
                local currDmg = enemyHero:GetEstimatedDamageToTarget(true, bot, 5, DAMAGE_TYPE_ALL)

                if nInRangeAlly ~= nil and nTargetInRangeAlly
                and #nInRangeAlly >= #nTargetInRangeAlly
                and currDmg > dmg
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

	if bRetreating
    and Fu.GetHP(bot) < 0.5
    and Fu.IsValidHero(nInRangeEnemy[1])
    and Fu.IsInRange(bot, nInRangeEnemy[1], 500)
	then
		for _, creep in pairs(GetUnitList(UNIT_LIST_ENEMY_CREEPS))
		do
			if Fu.IsValid(creep)
            and GetUnitToUnitDistance(creep, bot) > 1600
            then
                bot.chargeRetreat = true
                return BOT_ACTION_DESIRE_HIGH, creep
			end
		end

        for _, creep in pairs(GetUnitList(UNIT_LIST_NEUTRAL_CREEPS))
		do
			if Fu.IsValid(creep)
            and GetUnitToUnitDistance(creep, bot) > 1600
            then
                bot.chargeRetreat = true
                return BOT_ACTION_DESIRE_HIGH, creep
			end
		end
	end

    if Fu.IsPushing(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), bot:GetCurrentVisionRange(), nRadius, 0, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[4]
        end
    end

    if Fu.IsFarming(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), bot:GetCurrentVisionRange(), nRadius, 0, 0)

        if bAttacking
        and Fu.GetMP(bot) > 0.25
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
            then
                if Fu.CanBeAttacked(nNeutralCreeps[1])
                then
                    return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[2]
                end
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            then
                if Fu.CanBeAttacked(nEnemyLaneCreeps[1])
                then
                    return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[3]
                end
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
            if Fu.IsValid(creep)
            and Fu.GetHP(creep) <= 0.33
            then
                local nEnemyTowers = creep:GetNearbyTowers(700, false)

                if nEnemyTowers ~= nil and #nEnemyTowers == 0
                then
                    canKill = canKill + 1
                    table.insert(creepList, creep)
                end
            end
		end

        if canKill >= 2
        and Fu.GetMP(bot) > 0.25
        and Fu.CanBeAttacked(creepList[1])
        and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        and GreaterBash:IsTrained() and GreaterBash:GetLevel() >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, creepList[2]
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsGoingOnSomeone(allyHero)
        and not Fu.IsMeepoClone(allyHero)
        and not allyHero:IsIllusion()
        and not allyHero:HasModifier('modifier_arc_warden_tempest_double')
        then
            local allyTarget = allyHero:GetAttackTarget()
            if Fu.IsValidTarget(allyTarget)
            and Fu.CanCastOnNonMagicImmune(allyTarget)
            and not Fu.IsSuspiciousIllusion(allyTarget)
            and not Fu.IsLocationInChrono(allyTarget:GetLocation())
            then
                local distance = GetUnitToUnitDistance(bot, allyTarget)
                if (Fu.IsChasingTarget(allyHero, allyTarget) or Fu.IsAttacking(allyHero))
                and distance > 600
                and distance < 1900
                then
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderBulldoze()
    if not Bulldoze:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    botTarget = Fu.GetProperTarget(bot)

    if bot:HasModifier('modifier_spirit_breaker_charge_of_darkness')
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 600)
        and bot:WasRecentlyDamagedByAnyHero(1)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    if bRetreating
	then
        if Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 600)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderNetherStrike()
    if not NetherStrike:IsFullyCastable()
    or bot:HasModifier('modifier_spirit_breaker_charge_of_darkness')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = NetherStrike:GetCastRange()
	local nDamage = NetherStrike:GetAbilityDamage()

    for _, enemyHero in pairs(nInRangeEnemy)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not Fu.IsLocationInChrono(enemyHero:GetLocation())
        then
            if enemyHero:IsChanneling()
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
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
    end

	if bGoingOnSomeone
	then
        local target = nil
        local dmg = 0

        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsLocationInChrono(enemyHero:GetLocation())
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)
                local currDmg = enemyHero:GetEstimatedDamageToTarget(true, bot, 5, DAMAGE_TYPE_ALL)

                if nInRangeAlly ~= nil and nTargetInRangeAlly
                and #nInRangeAlly >= #nTargetInRangeAlly
                and currDmg > dmg
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

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderPlanarPocket()
    if not PlanarPocket:IsTrained()
    or not PlanarPocket:IsFullyCastable()
    or bot:HasModifier('modifier_spirit_breaker_charge_of_darkness')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = PlanarPocket:GetSpecialValueInt('radius')
    botTarget = Fu.GetProperTarget(bot)

    if Fu.IsInTeamFight(bot, 1200)
	then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and bot:WasRecentlyDamagedByAnyHero(1)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 600)
        and bot:WasRecentlyDamagedByAnyHero(1)
        and not Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 600)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (bot:WasRecentlyDamagedByAnyHero(1)))
            then
		        return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X