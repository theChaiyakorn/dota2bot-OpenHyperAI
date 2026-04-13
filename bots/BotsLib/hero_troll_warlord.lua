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
						-- {2,1,4,2,2,6,2,1,1,1,6,4,4,4,6},--pos1, errored in 7.37
						{2,5,4,2,2,6,2,5,5,5,6,4,4,4,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_magic_wand",
    "item_wraith_band",
    "item_phase_boots",
    "item_bfury",--
    "item_yasha",
    "item_black_king_bar",--
    "item_sange_and_yasha",--
    "item_aghanims_shard",
    "item_satanic",--
    "item_moon_shard",
    "item_abyssal_blade",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

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

local BattleStance          = bot:GetAbilityInSlot(0)
local BerserkersRage        = SafeAbility(bot:GetAbilityByName('troll_warlord_berserkers_rage'), 'troll_warlord_berserkers_rage', 'troll_warlord')
local WhirlingAxesRanged    = SafeAbility(bot:GetAbilityByName('troll_warlord_whirling_axes_ranged'), 'troll_warlord_whirling_axes_ranged', 'troll_warlord')
local WhirlingAxesMelee     = SafeAbility(bot:GetAbilityByName('troll_warlord_whirling_axes_melee'), 'troll_warlord_whirling_axes_melee', 'troll_warlord')
-- local Fervor                = bot:GetAbilityByName('troll_warlord_fervor')
local BattleTrance          = SafeAbility(bot:GetAbilityByName('troll_warlord_battle_trance'), 'troll_warlord_battle_trance', 'troll_warlord')

local BerserkersRageDesire
local WhirlingAxesRangedDesire, WhirlingAxesRangedLocation
local WhirlingAxesMeleeDesire
local BattleTranceDesire

local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
local nBotMP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = Fu.GetHP(bot)
	nBotMP = Fu.GetMP(bot)

    botTarget = Fu.GetProperTarget(bot)

    BattleTranceDesire = X.ConsiderBattleTrance()
    if BattleTranceDesire > 0
    then
        bot:Action_UseAbility(BattleTrance)
        return
    end

    if BattleStance:IsFullyCastable() and BattleStance:IsTrained() then
        BerserkersRage = BattleStance
    end

    BerserkersRageDesire = X.ConsiderBerserkersRage(BerserkersRage)
    if BerserkersRageDesire > 0
    then
        bot:Action_UseAbility(BerserkersRage)
        return
    end

    WhirlingAxesRangedDesire, WhirlingAxesRangedLocation = X.ConsiderWhirlingAxesRanged()
    if WhirlingAxesRangedDesire > 0
    then
        bot:Action_UseAbilityOnLocation(WhirlingAxesRanged, WhirlingAxesRangedLocation)
        return
    end

    WhirlingAxesMeleeDesire = X.ConsiderWhirlingAxesMelee()
    if WhirlingAxesMeleeDesire > 0
    then
        bot:Action_UseAbility(WhirlingAxesMelee)
        return
    end
end

function X.ConsiderBerserkersRage(BerserkersRage)
    if not BerserkersRage:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nBonusRange = BerserkersRage:GetSpecialValueInt('bonus_range')
    local nBonusMS = BerserkersRage:GetSpecialValueInt('bonus_move_speed')
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
		then
            if Fu.IsChasingTarget(bot, botTarget)
            and not Fu.IsLocationInChrono(botTarget:GetLocation())
            then
                if BerserkersRage:GetToggleState() == false
                then
                    return BOT_ACTION_DESIRE_HIGH
                else
                    return BOT_ACTION_DESIRE_NONE
                end
            else
                if bAttacking
                and Fu.IsInRange(bot, botTarget, 150)
                and BerserkersRage:GetToggleState() == false
                and not Fu.IsChasingTarget(bot, botTarget)
                then
                    if BerserkersRage:GetToggleState() == false
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    else
                        return BOT_ACTION_DESIRE_NONE
                    end
                end
            end
		end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (bot:WasRecentlyDamagedByAnyHero(1.5)))
            then
                if nInRangeEnemy[1]:GetCurrentMovementSpeed() > bot:GetCurrentMovementSpeed()
                and nInRangeEnemy[1]:GetCurrentMovementSpeed() < bot:GetCurrentMovementSpeed() + nBonusMS
                then
                    if BerserkersRage:GetToggleState() == false
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    else
                        return BOT_ACTION_DESIRE_NONE
                    end
                end

            end
        end
    end

	if Fu.IsPushing(bot)
	then
		if nEnemyHeroes ~= nil and #nEnemyHeroes == 0
        then
            if BerserkersRage:GetToggleState() == false
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                return BOT_ACTION_DESIRE_NONE
            end
        else
            if BerserkersRage:GetToggleState() == true
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                return BOT_ACTION_DESIRE_NONE
            end
        end
	end

    if Fu.IsFarming(bot)
	then
        if BerserkersRage:GetToggleState() == false
        then
            return BOT_ACTION_DESIRE_HIGH
        else
            return BOT_ACTION_DESIRE_NONE
        end
	end

	if Fu.IsLaning(bot)
    then
		local enemyRange = 0

		for _, enemyHero in pairs(nEnemyHeroes)
		do
			if Fu.IsValidHero(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and enemyHero:GetAttackRange() > enemyRange
            then
                enemyRange = enemyHero:GetAttackRange()
            end
		end

		if enemyRange < 324
        then
            if BerserkersRage:GetToggleState() == false
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                return BOT_ACTION_DESIRE_NONE
            end
        end

		if enemyRange > 324
        then
            if BerserkersRage:GetToggleState() == true
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                return BOT_ACTION_DESIRE_NONE
            end
		end
	end

    if BerserkersRage:GetToggleState() == false
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderWhirlingAxesRanged()
    if not WhirlingAxesRanged:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WhirlingAxesRanged:GetCastRange())
    local nCastPoint = WhirlingAxesRanged:GetCastPoint()
    local nRadius = WhirlingAxesRanged:GetSpecialValueInt('axe_width')
    local nSpeed = WhirlingAxesRanged:GetSpecialValueInt('axe_speed')
    local nDamage = WhirlingAxesRanged:GetSpecialValueInt('axe_damage')

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
            local eta = (GetUnitToUnitDistance(bot, enemyHero)/ nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(eta)
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                local eta = (GetUnitToUnitDistance(bot, botTarget)/ nSpeed) + nCastPoint
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(eta)
            end
		end
	end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and bAttacking
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
        and not nInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not nInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or bot:WasRecentlyDamagedByAnyHero(1.5))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
            end
        end

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
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
	end

	if Fu.IsPushing(bot)
	then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
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
            and nBotMP > 0.3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            and nBotMP > 0.3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
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
            --     and nBotMP > 0.3
            --     and Fu.CanBeAttacked(creep)
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
        and Fu.CanBeAttacked(creepList[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
        end

        if nInRangeEnemy ~= nil and #nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsAttacking(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and nBotMP > 0.5
        and nBotHP < Fu.GetHP(nInRangeEnemy[1])
        and nInRangeEnemy[1]:GetAttackTarget() == bot
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
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

function X.ConsiderWhirlingAxesMelee()
    if not WhirlingAxesMelee:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = WhirlingAxesRanged:GetSpecialValueInt('max_range')
    local nDamage = WhirlingAxesRanged:GetSpecialValueInt('damage')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
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
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
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
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nRadius)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        and not nInRangeEnemy[1]:HasModifier('modifier_troll_warlord_whirling_axes_slow')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or bot:WasRecentlyDamagedByAnyHero(1.5))
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end

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
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

	if Fu.IsPushing(bot)
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            and nBotMP > 0.3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nBotMP > 0.3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
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
        and Fu.CanBeAttacked(creepList[1])
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        if nInRangeEnemy ~= nil and #nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsAttacking(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and nBotMP > 0.5
        and nBotHP < Fu.GetHP(nInRangeEnemy[1])
        and nInRangeEnemy[1]:GetAttackTarget() == bot
        then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderBattleTrance()
    if not BattleTrance:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	--团战
	if Fu.IsInTeamFight( bot, 1200 )
    and Fu.IsValidTarget(botTarget)
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)
        if nBotHP < 0.4
        and #nInRangeEnemy >= #nInRangeAlly then
            return BOT_ACTION_DESIRE_MODERATE
        end
	end

    local nDuration = BattleTrance:GetSpecialValueInt('trance_duration')

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, 600)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not botTarget:HasModifier('modifier_item_blade_mail_reflect')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)
            local nDamage = bot:GetEstimatedDamageToTarget(false, botTarget, nDuration, DAMAGE_TYPE_PHYSICAL)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            and not (#nInRangeAlly >= #nInRangeEnemy + 2)
            and nDamage >= botTarget:GetHealth()
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end

        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 600)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and nBotHP < 0.3
        and Fu.IsValidHero(nInRangeEnemy[1])
        and bAttacking
        and not Fu.IsLocationInChrono(nInRangeEnemy[1]:GetLocation())
        then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,600, false, BOT_MODE_NONE)

        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nInRangeAlly ~= nil and #nInRangeAlly >= 2
        and Fu.IsAttacking(nInRangeAlly[1])
        and Fu.IsAttacking(nInRangeAlly[2])
        and DotaTime() < 35 * 60
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nBotHP < 0.35
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bRetreating then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 500)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and nBotHP < 0.3
        and Fu.IsValidHero(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 35)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X