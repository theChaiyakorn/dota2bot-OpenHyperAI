local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')
local I = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/illusions')

local X = {}
local bot

local nAllyHeroes, nEnemyHeroes

function X.Think(ownerBot, hMinionUnit)
    bot = ownerBot

    if not U.IsValidUnit(hMinionUnit) or Fu.CanNotUseAbility(hMinionUnit) then return end

	if hMinionUnit.abilities == nil then U.InitiateAbility(hMinionUnit) end

    nAllyHeroes = hMinionUnit:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = hMinionUnit:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if hMinionUnit.abilities[1]:GetName() == 'vengefulspirit_magic_missile'
    then
        hMinionUnit.cast_desire, hMinionUnit.cast_target = X.ConsiderMagicMissile(hMinionUnit, hMinionUnit.abilities[1])
        if hMinionUnit.cast_desire > 0
        then
            hMinionUnit:Action_UseAbilityOnEntity(hMinionUnit.abilities[1], hMinionUnit.cast_target)
            return
        end
    end

    if hMinionUnit.abilities[2]:GetName() == 'vengefulspirit_wave_of_terror'
    then
        hMinionUnit.cast_desire, hMinionUnit.cast_location = X.ConsiderWaveOfTerror(hMinionUnit, hMinionUnit.abilities[2])
        if hMinionUnit.cast_desire > 0
        then
            hMinionUnit:Action_UseAbilityOnLocation(hMinionUnit.abilities[2], hMinionUnit.cast_location)
            return
        end
    end

    if hMinionUnit.abilities[6]:GetName() == 'vengefulspirit_nether_swap'
    then
        hMinionUnit.cast_desire, hMinionUnit.cast_target = X.ConsiderNetherSwap(hMinionUnit, hMinionUnit.abilities[6])
        if hMinionUnit.cast_desire > 0
        then
            hMinionUnit:Action_UseAbilityOnEntity(hMinionUnit.abilities[6], hMinionUnit.cast_target)
            return
        end
    end

    I.Think(bot, hMinionUnit)
end

function X.ConsiderMagicMissile(hMinionUnit, ability)
    if not Fu.CanCastAbility(ability)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, hMinionUnit, ability:GetCastRange())
    local nDamage = ability:GetSpecialValueInt('magic_missile_damage')

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        then
            if enemyHero:IsChanneling()
            and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange + 300)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if  Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange + 150)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes)
    do
        if  Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(3.0)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

	local target = nil
	local dmg = 0

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if  Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
		and not Fu.IsDisabled(enemyHero)
		and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
		and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			local currDmg = enemyHero:GetEstimatedDamageToTarget(false, hMinionUnit, 5, DAMAGE_TYPE_ALL)

			if dmg < currDmg
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

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderWaveOfTerror(hMinionUnit, ability)
    if not Fu.CanCastAbility(ability)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, hMinionUnit, ability:GetCastRange())
    local nCastPoint = ability:GetCastPoint()
	local nRadius = ability:GetSpecialValueInt('wave_width')
    local nSpeed = ability:GetSpecialValueInt('wave_speed')
    local nDamage = ability:GetAbilityDamage()

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and Fu.IsChasingTarget(hMinionUnit, enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        then
            local nLocationAoE = hMinionUnit:FindAoELocation(true, true, enemyHero:GetLocation(), nRadius, nRadius, 0, 0)

            if nLocationAoE.count >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            else
                local eta = (GetUnitToUnitDistance(hMinionUnit, enemyHero) / nSpeed) + nCastPoint
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(enemyHero, eta)
            end
        end
    end

	local target = nil
	local dmg = 0

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if  Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not Fu.IsDisabled(enemyHero)
		and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
		and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			local currDmg = enemyHero:GetEstimatedDamageToTarget(false, hMinionUnit, 5, DAMAGE_TYPE_ALL)

			if dmg < currDmg
			then
				dmg = currDmg
				target = enemyHero
			end
		end
	end

	if target ~= nil
	then
        local nLocationAoE = hMinionUnit:FindAoELocation(true, true, target:GetLocation(), nRadius, nRadius, 0, 0)

        if nLocationAoE.count >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        else
            local eta = (GetUnitToUnitDistance(hMinionUnit, target) / nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(target, eta)
        end
	end

    local nEnemyLaneCreeps = hMinionUnit:GetNearbyLaneCreeps(nCastRange, true)

    if #nEnemyLaneCreeps >= 3
    and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
    and not Fu.IsRunning(nEnemyLaneCreeps[1])
    and not Fu.IsThereCoreNearby(1200)
    then
        return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderNetherSwap(hMinionUnit, ability)
    if not Fu.CanCastAbility(ability)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, hMinionUnit, ability:GetCastRange())

    for _, allyHero in pairs(nAllyHeroes)
    do
        if  Fu.IsValidHero(allyHero)
        and Fu.IsInRange(hMinionUnit, allyHero, nCastRange + 300)
        and Fu.IsCore(allyHero)
        and not Fu.IsSuspiciousIllusion(allyHero)
        then
            if Fu.IsInTeamFight(allyHero, 1200)
            and not Fu.IsInRange(hMinionUnit, allyHero, nCastRange)
            and U.CantMove(allyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end

            if allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            or allyHero:HasModifier('modifier_enigma_black_hole_pull')
            or (allyHero:HasModifier('modifier_mars_arena_of_blood_leash')
                and not hMinionUnit:HasModifier('modifier_mars_arena_of_blood_leash'))
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

	local target = nil
	local dmg = 0

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
		and not Fu.IsInRange(hMinionUnit, enemyHero, nCastRange / 2)
		and not Fu.IsDisabled(enemyHero)
		and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
		and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not enemyHero:HasModifier('modifier_legion_commander_duel')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:WasRecentlyDamagedByAnyHero(2.0)
		then
			local currDmg = enemyHero:GetEstimatedDamageToTarget(false, hMinionUnit, 5, DAMAGE_TYPE_ALL)

			if #nAllyHeroes >= #nEnemyHeroes
			and #nAllyHeroes >= 1
			and not (#nAllyHeroes > #nEnemyHeroes + 2)
			and dmg < currDmg
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

    return BOT_ACTION_DESIRE_NONE, nil
end

return X