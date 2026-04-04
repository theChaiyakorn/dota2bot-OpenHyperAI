local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')
local I = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/illusions')

local X = {}

X.ConsiderSpellUsage = {}

local bot

local botHP, botTarget
local thisMinionHP, nAllyHeroes, nEnemyHeroes

function X.Think(ownerBot, hMinionUnit)
    bot = ownerBot

	if U.CanNotUseAbility(hMinionUnit) then I.Think(bot, hMinionUnit) return end
	if hMinionUnit.abilities == nil then U.InitiateAbility(hMinionUnit) end
    if #hMinionUnit.abilities <= 0 then I.Think(bot, hMinionUnit) return end

	for i = 1, #hMinionUnit.abilities
	do
        local ability = hMinionUnit:GetAbilityByName(hMinionUnit.abilities[i]:GetName())
		if Fu.CanCastAbility(ability)
		then
            botTarget = Fu.GetProperTarget(bot)
            thisMinionHP = Fu.GetHP(hMinionUnit)
            nAllyHeroes = hMinionUnit:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
            nEnemyHeroes = hMinionUnit:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

            local considerFunc = X.ConsiderSpellUsage[ability:GetName()] or X.ConsiderSpellUsage['default']
            hMinionUnit.cast_desire, hMinionUnit.cast_target, hMinionUnit.cast_type = considerFunc(hMinionUnit, ability)
            if hMinionUnit.cast_desire > 0
            then
                if hMinionUnit.cast_type == 'unit'
                then
                    hMinionUnit:Action_UseAbilityOnEntity(ability, hMinionUnit.cast_target)
                    return
                elseif hMinionUnit.cast_type == 'point'
                then
                    hMinionUnit:Action_UseAbilityOnLocation(ability, hMinionUnit.cast_target)
                    return
                elseif hMinionUnit.cast_type == 'none'
                then
                    hMinionUnit:Action_UseAbility(ability)
                    return
                end
            end

            if Fu.CheckBitfieldFlag(ability:GetBehavior(), ABILITY_BEHAVIOR_UNIT_TARGET)
			then
                hMinionUnit.cast_desire, hMinionUnit.cast_target = X.ConsiderUnitTarget(hMinionUnit, ability)
                if hMinionUnit.cast_desire > 0
                then
                    hMinionUnit:Action_UseAbilityOnEntity(ability, hMinionUnit.cast_target)
                    return
                end
            end
		end
	end

    -- Attack, Move
    -- TODO: Personalize for select minions.
	I.Think(bot, hMinionUnit)
end

function X.ConsiderUnitTarget(hMinionUnit, ability)
	local bAttacking = Fu.IsAttacking(hMinionUnit)
	local nUnitHP = Fu.GetHP(hMinionUnit)
	local nCastRange = ability:GetCastRange()

    -- break linken
    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        -- and (enemyHero:HasModifier('modifier_item_sphere_target') or enemyHero:HasModifier('modifier_mirror_shield_delay'))
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end

-- Cast Spells

X.ConsiderSpellUsage['default'] = function (hMinionUnit, ability)
    print("[WARN] No function for the usage of ability: " .. ability:GetName() .. ', for unit owned by: ' .. bot:GetUnitName())
    return 0, nil, nil
end

-- Tornado
X.ConsiderSpellUsage['enraged_wildkin_tornado'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and not Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), 'point'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Hurricane
X.ConsiderSpellUsage['enraged_wildkin_hurricane'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and not Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Thunder Clap
X.ConsiderSpellUsage['polar_furbolg_ursa_warrior_thunder_clap'] = function (hMinionUnit, ability)
    local nRadius = ability:GetSpecialValueInt('radius')

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nRadius)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nRadius, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nRadius)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.IsInRange(hMinionUnit, enemy, nRadius)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            if  Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nRadius)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

X.ConsiderSpellUsage['ogre_bruiser_ogre_smash'] = function (hMinionUnit, ability)
    return BOT_ACTION_DESIRE_NONE, nil, ''
end

X.ConsiderSpellUsage['ogre_magi_frost_armor'] = function (hMinionUnit, ability)
    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Ensnare
X.ConsiderSpellUsage['dark_troll_warlord_ensnare'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and (enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero))
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
	end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.IsInRange(hMinionUnit, enemy, nCastRange)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, enemy, 'unit'
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            if  Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1], 'unit'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Raise Dead
X.ConsiderSpellUsage['dark_troll_warlord_raise_dead'] = function (hMinionUnit, ability)

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, 700)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
	end

    if Fu.IsPushing(bot) then
        if Fu.IsValidBuilding(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, 700)
        and Fu.CanBeAttacked(botTarget) then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, 800)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Hurl Boulder
X.ConsiderSpellUsage['mud_golem_hurl_boulder'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and (enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero))
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.IsInRange(hMinionUnit, enemy, nCastRange)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, enemy, 'unit'
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            if  Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1], 'unit'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Slam
X.ConsiderSpellUsage['big_thunder_lizard_slam'] = function (hMinionUnit, ability)
    local nRadius = ability:GetSpecialValueInt('radius')

    if Fu.IsGoingOnSomeone(bot) then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nRadius)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(hMinionUnit:GetLocation(), nRadius)
            if #nInRangeEnemy >= 1 then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.IsInRange(hMinionUnit, enemy, nRadius)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            if  Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nRadius)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Frenzy
X.ConsiderSpellUsage['big_thunder_lizard_frenzy'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    local target = nil
    local targetDamage = 0

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and not allyHero:IsIllusion()
        and Fu.IsInRange(hMinionUnit, allyHero, nCastRange)
        then
            if Fu.IsGoingOnSomeone(allyHero)
            or (Fu.IsDoingRoshan(allyHero) and Fu.IsRoshan(allyHero:GetAttackTarget()) and Fu.IsAttacking(allyHero) and Fu.GetHP(allyHero:GetAttackTarget()) > 0.4)
            or (Fu.IsDoingTormentor(allyHero) and Fu.IsTormentor(allyHero:GetAttackTarget()) and Fu.IsAttacking(allyHero) and Fu.GetHP(allyHero:GetAttackTarget()) > 0.4)
            then
                local allyHeroDamage = allyHero:GetAttackDamage() * allyHero:GetAttackSpeed()
                if allyHeroDamage > targetDamage then
                    target = allyHero
                    targetDamage = allyHeroDamage
                end
            end
        end
    end

    if target ~= nil then
        return BOT_ACTION_DESIRE_HIGH, target, 'unit'
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Incendiary Bomb
X.ConsiderSpellUsage['ice_shaman_incendiary_bomb'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    if Fu.IsGoingOnSomeone(bot) then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and Fu.GetHP(botTarget) > 0.4
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    if Fu.IsPushing(bot) then
        if Fu.IsValidBuilding(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, 700)
        and Fu.GetHP(botTarget) > 0.35
        and Fu.CanBeAttacked(botTarget) then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Fireball
X.ConsiderSpellUsage['black_dragon_fireball'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()
    local nRadius = ability:GetSpecialValueInt('radius')

    if Fu.IsGoingOnSomeone(bot) then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nLocationAoE = hMinionUnit:FindAoELocation(true, true, botTarget:GetLocation(), 0, nRadius, 0, 0)
            if nLocationAoE.count >= 1 then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'point'
            end
        end
    end

    local nLocationAoE = hMinionUnit:FindAoELocation(true, true, hMinionUnit:GetLocation(), nCastRange, nRadius, 0, 0)
    local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
    if #nInRangeEnemy >= 2 then
        return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'point'
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Seed Shot
X.ConsiderSpellUsage['warpine_raider_seed_shot'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()
    local nDamage = ability:GetSpecialValueInt('damage')
    local nBounceRange = ability:GetSpecialValueInt('bounce_range')

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and Fu.IsChasingTarget(bot, botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nLocationAoE = hMinionUnit:FindAoELocation(true, true, botTarget:GetLocation(), 0, nBounceRange, 0, 0)
            if nLocationAoE.count >= 2 then
                return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
            end

            nLocationAoE = hMinionUnit:FindAoELocation(true, false, botTarget:GetLocation(), 0, nBounceRange, 0, 0)
            if nLocationAoE.count >= 2 then
                return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
            end
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.IsInRange(hMinionUnit, enemy, nCastRange)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, enemy, 'unit'
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            if  Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1], 'unit'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Vex
X.ConsiderSpellUsage['fel_beast_haunt'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    if Fu.IsGoingOnSomeone(bot)
    and Fu.IsInRange(bot, hMinionUnit, 1600)
    then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    if Fu.IsRetreating(bot)
    and Fu.IsInRange(bot, hMinionUnit, 1600)
    then
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if  Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Take Off
X.ConsiderSpellUsage['harpy_scout_take_off'] = function (hMinionUnit, ability)
    if Fu.IsStuck(hMinionUnit)
    then
        if ability:GetToggleState() == false
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        else
            return BOT_ACTION_DESIRE_NONE, nil, 'none'
        end
    end

    if ability:GetToggleState() == true
    then
        return BOT_ACTION_DESIRE_HIGH, nil, 'none'
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Chain Lightning
X.ConsiderSpellUsage['harpy_storm_chain_lightning'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()
    local nDamage = ability:GetSpecialValueInt('initial_damage')
    local nJumpDist = ability:GetSpecialValueInt('jump_range')

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    if Fu.IsGoingOnSomeone(bot)
    and Fu.IsInRange(bot, hMinionUnit, 1600)
    then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    if Fu.IsRetreating(bot)
    and Fu.IsInRange(bot, hMinionUnit, 1600)
    then
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if  Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsDisabled(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
            end
        end
    end

    if Fu.IsFarming(bot)
    and Fu.IsInRange(bot, hMinionUnit, 1600)
    then
        local nCreeps = bot:GetNearbyCreeps(1600, true)
        if  nCreeps ~= nil
        and ((#nCreeps >= 3)
            or (#nCreeps >= 2 and nCreeps[1]:IsAncientCreep()))
        and Fu.IsAttacking(bot)
        then
            for _, creep in pairs(nCreeps)
            do
                if  Fu.IsValid(creep)
                and Fu.CanBeAttacked(creep)
                then
                    local nCreepCountAround = Fu.GetNearbyAroundLocationUnitCount(true, false, nJumpDist, creep:GetLocation())
                    if nCreepCountAround >= 2
                    then
                        return BOT_ACTION_DESIRE_HIGH, creep, 'unit'
                    end
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        -- Remove Spell Block
        if  Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Mana Burn
X.ConsiderSpellUsage['satyr_soulstealer_mana_burn'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange + 300)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.GetMP(enemyHero) > 0.5
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Purge
X.ConsiderSpellUsage['satyr_trickster_purge'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()

    for _, ally in pairs(nAllyHeroes) do
        if Fu.IsValidHero(ally)
        and Fu.IsInRange(hMinionUnit, ally, nCastRange + 300)
        and not ally:IsIllusion()
        and Fu.IsDisabled(ally)
        then
            return BOT_ACTION_DESIRE_HIGH, ally, 'unit'
        end
    end

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange + 300)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        then
            if enemyHero:HasModifier('modifier_flask_healing')
            or enemyHero:HasModifier('modifier_clarity_potion')
            or enemyHero:HasModifier('modifier_item_pavise_shield')
            or enemyHero:HasModifier('modifier_item_solar_crest_armor_addition')
            or enemyHero:HasModifier('modifier_disperser_movespeed_buff')
            -- more
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Shockwave
X.ConsiderSpellUsage['satyr_hellcaller_shockwave'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()
    local nCastPoint = ability:GetCastPoint()
    local nSpeed = ability:GetSpecialValueInt('speed')
    local nDamage = ability:GetSpecialValueInt('#AbilityDamage')

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local eta = (GetUnitToUnitDistance(hMinionUnit, enemyHero) / nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(hMinionUnit, eta), 'point'
        end
    end

    if Fu.IsGoingOnSomeone(bot) and Fu.IsInRange(bot, hMinionUnit, 1300) then
        local nLocationAoE = hMinionUnit:FindAoELocation(true, true, hMinionUnit:GetLocation(), nCastRange, 200, nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, 200)
        if #nInRangeEnemy >= 1 then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'point'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Intimidate
X.ConsiderSpellUsage['giant_wolf_intimidate'] = function (hMinionUnit, ability)
    local nRadius = ability:GetSpecialValueInt('radius')

    if Fu.IsGoingOnSomeone(bot) then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if  Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(hMinionUnit, enemyHero, nRadius)
            and Fu.CanBeAttacked(enemyHero)
            and not Fu.IsChasingTarget(bot, enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    local nInRangeEnemy = Fu.GetEnemiesNearLoc(hMinionUnit:GetLocation(), nRadius)
    if #nInRangeEnemy >= 2 then
        return BOT_ACTION_DESIRE_HIGH, nil, 'none'
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- War Stomp
X.ConsiderSpellUsage['centaur_khan_war_stomp'] = function (hMinionUnit, ability)
    local nRadius = ability:GetSpecialValueInt('radius')

    if Fu.IsGoingOnSomeone(bot) then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(hMinionUnit, botTarget, nRadius)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.IsInRange(hMinionUnit, enemy, nRadius)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and not Fu.IsRealInvisible(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            if  Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(hMinionUnit, nAllyInRangeEnemy[1], nRadius)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    local nInRangeEnemy = Fu.GetEnemiesNearLoc(hMinionUnit:GetLocation(), nRadius)
    if #nInRangeEnemy >= 2 then
        return BOT_ACTION_DESIRE_HIGH, nil, 'none'
    end

    return BOT_ACTION_DESIRE_NONE, nil, ''
end

-- Forest Troll High Priest: Heal allies
X.ConsiderSpellUsage['forest_troll_high_priest_heal'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetSpecialValueInt('AbilityCastRange')
    local bot = GetBot()
    local nAllyHeroes = hMinionUnit:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE) or {}

    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.CanBeAttacked(allyHero)
        and Fu.IsInRange(hMinionUnit, allyHero, nCastRange)
        and not allyHero:IsIllusion()
        and not allyHero:HasModifier('modifier_abaddon_borrowed_time')
        and Fu.GetHP(allyHero) < 0.5
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

-- Chen Martyrdom (heals dominated creep on death)
X.ConsiderSpellUsage['chen_martyrdom'] = function (hMinionUnit, ability)
    -- Only use when the creep is about to die and allies are nearby
    local bot = GetBot()
    local minionHP = Fu.GetHP(hMinionUnit)
    local nAllyHeroes = hMinionUnit:GetNearbyHeroes(900, false, BOT_MODE_NONE) or {}

    if minionHP < 0.2 and #nAllyHeroes >= 1 then
        for _, ally in pairs(nAllyHeroes) do
            if Fu.IsValidHero(ally) and Fu.GetHP(ally) < 0.6 then
                return BOT_ACTION_DESIRE_HIGH, nil, 'none'
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

-- Necronomicon Archer Purge
X.ConsiderSpellUsage['necronomicon_archer_purge'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()
    local nEnemyHeroes = hMinionUnit:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE) or {}

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and not enemyHero:IsMagicImmune()
        -- Purge is most useful on hasted/buffed enemies
        and (enemyHero:GetCurrentMovementSpeed() > 400
            or enemyHero:HasModifier('modifier_ghost_state')
            or enemyHero:HasModifier('modifier_item_ghost'))
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

-- Spawnlord Master Freeze (root)
X.ConsiderSpellUsage['spawnlord_master_freeze'] = function (hMinionUnit, ability)
    local nCastRange = ability:GetCastRange()
    local nEnemyHeroes = hMinionUnit:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE) or {}

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nCastRange)
        and not enemyHero:IsMagicImmune()
        and not Fu.IsDisabled(enemyHero)
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

-- Spawnlord Master Stomp (AoE stun)
X.ConsiderSpellUsage['spawnlord_master_stomp'] = function (hMinionUnit, ability)
    local nRadius = ability:GetSpecialValueInt('radius')
    local nEnemyHeroes = hMinionUnit:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE) or {}

    if #nEnemyHeroes >= 2 then
        return BOT_ACTION_DESIRE_HIGH, nil, 'none'
    end

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(hMinionUnit, enemyHero, nRadius)
        and enemyHero:IsChanneling()
        then
            return BOT_ACTION_DESIRE_HIGH, nil, 'none'
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X