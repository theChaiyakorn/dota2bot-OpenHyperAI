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
						['t20'] = {10, 0},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
    ["pos_2"]= {1,3,1,2,1,6,1,2,2,6,2,3,3,3,6},
    ["pos_3"]= {1,3,1,2,1,6,1,2,2,6,2,3,3,3,6},
    ["pos_4"]= {1,3,1,2,1,6,1,2,3,3,6,3,2,6,2},
    ["pos_5"]= {1,3,1,2,1,6,1,2,3,3,6,3,2,6,2},
}

local nAbilityBuildList = tAllAbilityBuildList[sRole] or {1,3,2,2,2,6,2,3,3,3,1,6,1,1,6}

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sUtility = {"item_lotus_orb", "item_heavens_halberd"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_double_circlet",

    "item_bracer",
    "item_wraith_band",
    "item_magic_wand",
    "item_power_treads",
    "item_blink",
    "item_crimson_guard",
    "item_echo_sabre",
    "item_black_king_bar",--
    "item_harpoon",--
    nUtility,--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_arcane_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = {
    "item_quelling_blade",
    "item_double_branches",
    "item_tango",
    "item_circlet",
    "item_bottle",
    "item_wraith_band",
    "item_magic_wand",
    "item_power_treads",
    "item_blink",
    "item_echo_sabre",
    "item_black_king_bar",--
    "item_harpoon",--
    "item_greater_crit",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_moon_shard",
    "item_arcane_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
    "item_blink",
    "item_echo_sabre",
    "item_black_king_bar",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_arcane_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_pipe",--
    "item_blink",
    "item_echo_sabre",
    "item_black_king_bar",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_arcane_blink",--
    "item_travel_boots_2",--
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

local Shockwave         = bot:GetAbilityByName('magnataur_shockwave')
local Empower           = bot:GetAbilityByName('magnataur_empower')
local Skewer            = bot:GetAbilityByName('magnataur_skewer')
local HornToss          = bot:GetAbilityByName('magnataur_horn_toss')
local ReversePolarity   = bot:GetAbilityByName('magnataur_reverse_polarity')

local ShockwaveDesire, ShockwaveLocation
local EmpowerDesire, EmpowerTarget
local SkewerDesire, SkewerLocation
local HornTossDesire
local ReversePolarityDesire

local Blink
local BlinkLocation

local BlinkRPDesire

local BlinkSkewerDesire
local BlinkRPSkewerDesire

if bot.shouldBlink == nil then bot.shouldBlink = false end

local botTarget
local bGoingOnSomeone
local bRetreating
local nBotHP
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	nBotHP = Fu.GetHP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    BlinkRPSkewerDesire = X.ConsiderBlinkRPSkewer()
    if BlinkRPSkewerDesire > 0
    then
        bot:Action_ClearActions(false)

        if CanBKB()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
        end

        bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbility(ReversePolarity)
        bot:ActionQueue_Delay(0.3)

        SkewerDesire, SkewerLocation = X.ConsiderSkewer2()
        if SkewerDesire > 0
        then
            bot:ActionQueue_UseAbilityOnLocation(Skewer, SkewerLocation)
        end

        return
    end

    BlinkSkewerDesire = X.ConsiderBlinkForSkewer()
    if BlinkSkewerDesire > 0
    then
        bot:Action_ClearActions(false)

        if CanBKB()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
        end

        bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkLocation)
        bot:ActionQueue_Delay(0.1)

        SkewerDesire, SkewerLocation = X.ConsiderSkewer2()
        if SkewerDesire > 0
        then
            bot:ActionQueue_UseAbilityOnLocation(Skewer, SkewerLocation)
        end

        return
    end

    BlinkRPDesire = X.ConsiderBlinkRP()
    if BlinkRPDesire > 0
    then
        bot:Action_ClearActions(false)

        if CanBKB()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
        end

        bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbility(ReversePolarity)
        return
    end

    BlinkHornTossSkewerDesire = X.ConsiderBlinkForHornTossSkewer()
    if BlinkHornTossSkewerDesire > 0
    then
        bot:Action_ClearActions(false)

        if CanBKB()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
        end

        bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkLocation)

        HornTossDesire = X.ConsiderHornToss()
        if HornTossDesire > 0
        then
            bot:ActionQueue_UseAbility(HornToss)
            return
        end

        bot:ActionQueue_Delay(0.6)

        SkewerDesire, SkewerLocation = X.ConsiderSkewer2()
        if SkewerDesire > 0
        then
            bot:ActionQueue_UseAbilityOnLocation(Skewer, SkewerLocation)
        end

        return
    end

    ReversePolarityDesire = X.ConsiderReversePolarity()
    if ReversePolarityDesire > 0
    then
        bot:Action_UseAbility(ReversePolarity)
        return
    end

    HornTossDesire = X.ConsiderHornToss()
    if HornTossDesire > 0
    then
        bot:Action_UseAbility(HornToss)
        return
    end

    SkewerDesire, SkewerLocation = X.ConsiderSkewer()
    if SkewerDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Skewer, SkewerLocation)
        return
    end

    ShockwaveDesire, ShockwaveLocation = X.ConsiderShockwave()
    if ShockwaveDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Shockwave, ShockwaveLocation)
        return
    end

    EmpowerDesire, EmpowerTarget = X.ConsiderEmpower()
    if EmpowerDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Empower, EmpowerTarget)
        return
    end
end

function X.ConsiderShockwave()
    if not Shockwave:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, Shockwave:GetCastRange())
	local nCastPoint = Shockwave:GetCastPoint()
    local nRadius = Shockwave:GetSpecialValueInt('shock_width')
	local nDamage = Shockwave:GetSpecialValueInt('shock_damage')
	local nSpeed = Shockwave:GetSpecialValueInt('shock_speed')
    local nMana = bot:GetMana() / bot:GetMaxMana()
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nDelay = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay)
        end
    end

	if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange - 200)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        then
            local nDelay = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nDelay)
        end
	end

	if (Fu.IsDefending(bot) or Fu.IsPushing(bot))
	then
		local nEnemyLanecreeps = bot:GetNearbyLaneCreeps(nCastRange - 200, true)
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange - 200, nRadius, 0, 0)

		if nEnemyLanecreeps ~= nil and #nEnemyLanecreeps >= 4
        and nLocationAoE.count >= 4
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange - 200, nRadius, 0, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
	end

    if Fu.IsFarming(bot)
    then
        local nEnemyLanecreeps = bot:GetNearbyLaneCreeps(800, true)
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), 800, nRadius, 0, 0)

        if Fu.IsAttacking(bot)
        then
            if nEnemyLanecreeps ~= nil and #nEnemyLanecreeps >= 3
            and nLocationAoE.count >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end

            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(600)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nLocationAoE.count >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            and nMana > 0.27
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if Fu.IsLaning(bot)
    and nMana > 0.39
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and creep:GetHealth() <= nDamage
			then
				local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) <= 500
				then
					return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
				end
			end
		end
	end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
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
        and nMana > 0.48
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
                local nDelay = (GetUnitToUnitDistance(bot, nAllyInRangeEnemy[1]) / nSpeed) + nCastPoint
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetExtrapolatedLocation(nDelay + nCastPoint)
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderEmpower()
    if not Empower:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Empower:GetCastRange())
	local nAttackRange = bot:GetAttackRange()
    botTarget = Fu.GetProperTarget(bot)

    -- 7.41: Empower can no longer target self (Magnus always has 30% bonus passively)
    local buffAllyUnit = nil
	local nMaxDamage = 0
    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
	for _, allyHero in pairs(nAllyHeroes)
	do
		if Fu.IsValidHero(allyHero)
        and allyHero ~= bot
        and Fu.IsCore(allyHero)
        and not allyHero:IsIllusion()
        and not Fu.IsDisabled(allyHero)
        and not Fu.IsWithoutTarget(allyHero)
        and not allyHero:HasModifier('modifier_magnataur_empower')
        and (allyHero:GetAttackDamage() * allyHero:GetAttackSpeed()) > nMaxDamage
		then
			buffAllyUnit = allyHero
			nMaxDamage = allyHero:GetAttackDamage() * allyHero:GetAttackSpeed()
		end
	end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
		then
            if buffAllyUnit ~= nil
            and Fu.IsInRange(buffAllyUnit, botTarget, buffAllyUnit:GetAttackRange() + 100)
            and Fu.IsInRange(bot, buffAllyUnit, nCastRange)
            then
                return BOT_ACTION_DESIRE_HIGH, buffAllyUnit
            end
		end
	end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(600, true)
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and buffAllyUnit ~= nil
        then
			return BOT_ACTION_DESIRE_HIGH, buffAllyUnit
		end

		local nEnemyTowers = bot:GetNearbyTowers(700, true)
		if nEnemyTowers ~= nil and #nEnemyTowers > 0
        and buffAllyUnit ~= nil
        and Fu.IsInRange(buffAllyUnit, nEnemyTowers[1], buffAllyUnit:GetAttackRange() + 100)
        and Fu.IsInRange(bot, buffAllyUnit, nCastRange)
        then
            return BOT_ACTION_DESIRE_HIGH, buffAllyUnit
		end
	end

    -- 7.41: Removed farming/laning self-cast (Magnus has passive 30% bonus)

	if Fu.IsDoingRoshan(bot)
    and buffAllyUnit ~= nil
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, 500)
        and Fu.IsAttacking(buffAllyUnit)
		then
			return BOT_ACTION_DESIRE_HIGH, buffAllyUnit
		end
	end

    if Fu.IsDoingTormentor(bot)
    and buffAllyUnit ~= nil
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(buffAllyUnit)
        then
            return BOT_ACTION_DESIRE_HIGH, buffAllyUnit
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSkewer()
    if not Skewer:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nDist = Skewer:GetSpecialValueInt('range')
	local nCastPoint = Skewer:GetCastPoint()
	local nSpeed = Skewer:GetSpecialValueInt('skewer_speed')
    local nRadius = Skewer:GetSpecialValueInt('skewer_radius')
    botTarget = Fu.GetProperTarget(bot)

	if Fu.IsStuck(bot)
	then
		local loc = Fu.GetEscapeLoc()
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nDist)
	end

	if bGoingOnSomeone
    and (not CanDoBlinkSkewer() or not CanDoBlinkRPSkewer() or not CanDoBlinkHornTossSkewer())
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        then
            if Fu.IsEnemyBetweenMeAndLocation(bot, Fu.GetEscapeLoc(), nDist)
            and Fu.IsInRange(bot, botTarget, nRadius)
            then
                if #nInRangeAlly >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nInRangeAlly[#nInRangeAlly]:GetLocation(), nDist)
                else
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nDist)
                end
            end

            if Fu.IsRunning(bot)
            and Fu.IsRunning(botTarget)
            and Fu.IsInRange(bot, botTarget, nDist)
            and bot:IsFacingLocation(botTarget:GetLocation(), 30)
            and not botTarget:IsFacingLocation(bot:GetLocation(), 30)
            then
                local nDelay = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nDelay)
            end
        end
	end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (nBotHP < 0.68 and bot:WasRecentlyDamagedByAnyHero(1.9)))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 575)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not Fu.IsTaunted(nInRangeEnemy[1])
        then
            local loc = Fu.GetEscapeLoc()
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nDist)
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderReversePolarity()
    if not ReversePolarity:IsFullyCastable()
    or bot:HasModifier('modifier_magnataur_skewer_movement')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = ReversePolarity:GetSpecialValueInt('pull_radius')
	local nDamage = ReversePolarity:GetSpecialValueInt('polarity_damage')

    if bInTeamFight
    and (not CanDoBlinkRP() or not CanDoBlinkRPSkewer())
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

            if realEnemyCount ~= nil and #realEnemyCount >= 2
            and not Fu.IsLocationInChrono(nInRangeEnemy[1]:GetLocation())
            and not Fu.IsLocationInBlackHole(nInRangeEnemy[1]:GetLocation())
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (nBotHP < 0.5 and bot:WasRecentlyDamagedByAnyHero(1.6)))
        then
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nRadius)
                and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                and not Fu.IsTaunted(enemyHero)
                and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
                and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
                and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
                and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderHornToss()
    if not HornToss:IsTrained()
    or not HornToss:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = HornToss:GetSpecialValueInt('radius')
    botTarget = Fu.GetProperTarget(bot)

    if bGoingOnSomeone
    and not CanDoBlinkHornTossSkewer()
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bot:IsFacingLocation(botTarget:GetLocation(), 15)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (nBotHP < 0.61 and bot:WasRecentlyDamagedByAnyHero(2)))
        then
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nRadius)
                and Fu.IsEnemyBetweenMeAndLocation(bot, Fu.GetEscapeLoc(), nRadius)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderBlinkRP()
    if CanDoBlinkRP()
    then
        local nCastRange = 1199
        local nCastPoint = Skewer:GetCastPoint() + ReversePolarity:GetCastPoint()
        local nRadius = ReversePolarity:GetSpecialValueInt('pull_radius')

        if bInTeamFight
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

            if nLocationAoE.count >= 2
            then
                local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

                if realEnemyCount ~= nil and #realEnemyCount >= 2
                and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
                and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
                then
                    BlinkLocation = nLocationAoE.targetloc
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function CanDoBlinkRP()
    if ReversePolarity:IsFullyCastable()
    and HasBlink()
    then
        local nManaCost = ReversePolarity:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            bot.shouldBlink = true
            return true
        end
    end

    bot.shouldBlink = false
    return false
end

function X.ConsiderBlinkForSkewer()
    if CanDoBlinkSkewer()
    then
        botTarget = Fu.GetProperTarget(bot)

        if bGoingOnSomeone
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

            if Fu.IsValidTarget(botTarget)
            and Fu.CanCastOnNonMagicImmune(botTarget)
            and Fu.IsInRange(bot, botTarget, 1199)
            and not Fu.IsSuspiciousIllusion(botTarget)
            and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
            and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and nInRangeAlly ~= nil and nInRangeEnemy
            and #nInRangeAlly >= #nInRangeEnemy
            then
                BlinkLocation = botTarget:GetLocation()
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSkewer2()
    local nRadius = Skewer:GetSpecialValueInt('skewer_radius')
    local nDist = Skewer:GetSpecialValueInt('range')

    local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
    local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)
    local nInRangeEnemy2 = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nInRangeEnemy2)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
        and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        then
            if Fu.IsEnemyBetweenMeAndLocation(bot, Fu.GetEscapeLoc(), nDist)
            and Fu.IsInRange(bot, enemyHero, nRadius)
            then
                if #nInRangeAlly >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nInRangeAlly[#nInRangeAlly]:GetLocation(), nDist)
                else
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nDist)
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function CanDoBlinkSkewer()
    if Skewer:IsFullyCastable()
    and HasBlink()
    then
        local nManaCost = Skewer:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            bot.shouldBlink = true
            return true
        end
    end

    bot.shouldBlink = false
    return false
end

function X.ConsiderBlinkRPSkewer()
    if CanDoBlinkRPSkewer()
    then
        local nCastRange = 1199
        local nCastPoint = Skewer:GetCastPoint() + ReversePolarity:GetCastPoint()
        local nRPRadius = ReversePolarity:GetSpecialValueInt('pull_radius')

        if bInTeamFight
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRPRadius, nCastPoint, 0)

            if nLocationAoE.count >= 2
            then
                BlinkLocation = nLocationAoE.targetloc
                local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRPRadius)

                if realEnemyCount ~= nil and #realEnemyCount >= 2
                and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
                and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function CanDoBlinkRPSkewer()
    if Skewer:IsFullyCastable()
    and ReversePolarity:IsFullyCastable()
    and HasBlink()
    then
        local nManaCost = Skewer:GetManaCost() + ReversePolarity:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            bot.shouldBlink = true
            return true
        end
    end

    bot.shouldBlink = false
    return false
end

function X.ConsiderBlinkForHornTossSkewer()
    if CanDoBlinkHornTossSkewer()
    then
        botTarget = Fu.GetProperTarget(bot)

        if bGoingOnSomeone
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

            if Fu.IsValidTarget(botTarget)
            and Fu.CanCastOnNonMagicImmune(botTarget)
            and Fu.IsInRange(bot, botTarget, 1199)
            and not Fu.IsSuspiciousIllusion(botTarget)
            and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
            and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not botTarget:HasModifier('modifier_legion_commander_duel')
            and nInRangeAlly ~= nil and nInRangeEnemy
            and #nInRangeAlly >= #nInRangeEnemy
            then
                BlinkLocation = botTarget:GetLocation()
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function CanDoBlinkHornTossSkewer()
    if (HornToss:IsTrained() and HornToss:IsFullyCastable())
    and Skewer:IsFullyCastable()
    and ReversePolarity:IsFullyCastable()
    and HasBlink()
    then
        local nManaCost = Skewer:GetManaCost() + ReversePolarity:GetManaCost() + HornToss:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            bot.shouldBlink = true
            return true
        end
    end

    bot.shouldBlink = false
    return false
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

function CanBKB()
    local bkb = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil
        and item:GetName() == "item_black_king_bar"
        then
			bkb = item
			break
		end
	end

    if bkb ~= nil
    and bkb:IsFullyCastable()
    and bot:GetMana() >= 75
	then
        BlackKingBar = bkb
        return true
	end

    return false
end

return X