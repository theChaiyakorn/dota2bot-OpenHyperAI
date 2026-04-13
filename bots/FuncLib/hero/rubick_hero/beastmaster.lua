local bot = GetBot()
local X = {}
local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')

local WildAxes
local CallOfTheWildBoar
local CallOfTheWildHawk
local PrimalRoar

local botTarget

local Blink
local BlackKingBar

function X.ConsiderStolenSpell(ability)
    bot = GetBot()

    if Fu.CanNotUseAbility(bot) then return end

    botTarget = Fu.GetProperTarget(bot)
    local abilityName = ability:GetName()

    if X.HasBlink()
    and abilityName == 'beastmaster_primal_roar'
    then
        PrimalRoar = ability
        BlinkRoarDesire, BlinkRoarTarget = X.ConsiderBlinkRoar()
        if BlinkRoarDesire > 0
        then
            bot:Action_ClearActions(false)

            if X.CanBKB()
            then
                bot:ActionQueue_UseAbility(BlackKingBar)
                bot:ActionQueue_Delay(0.1)
            end

            bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkLocation)
            bot:ActionQueue_Delay(0.1)
            bot:ActionQueue_UseAbilityOnEntity(PrimalRoar, BlinkRoarTarget)
            return
        end
    end

    if abilityName == 'beastmaster_primal_roar'
    then
        PrimalRoar = ability
        PrimalRoarDesire, PrimalRoarTarget = X.ConsiderPrimalRoar()
        if PrimalRoarDesire > 0
        then
            bot:Action_UseAbilityOnEntity(PrimalRoar, PrimalRoarTarget)
            return
        end
    end

    if abilityName == 'beastmaster_summon_razorback'
    then
        CallOfTheWildBoar = ability
        CallOfTheWildBoarDesire = X.ConsiderCallOfTheWildBoar()
        if CallOfTheWildBoarDesire > 0
        then
            bot:Action_UseAbility(CallOfTheWildBoar)
            return
        end
    end

    if abilityName == 'beastmaster_summon_raptor'
    then
        CallOfTheWildHawk = ability
        CallOfTheWildHawkDesire = X.ConsiderCallOfTheWildHawk()
        if CallOfTheWildHawkDesire > 0
        then
            bot:Action_UseAbility(CallOfTheWildHawk)
            return
        end
    end

    if abilityName == 'beastmaster_wild_axes'
    then
        WildAxes = ability
        WildAxesDesire, WildAxesLocation = X.ConsiderWildAxes()
        if WildAxesDesire > 0
        then
            bot:Action_UseAbilityOnLocation(WildAxes, WildAxesLocation)
            return
        end
    end
end

function X.ConsiderWildAxes()
    if not WildAxes:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WildAxes:GetCastRange())
    local nCastPoint = WildAxes:GetCastPoint()
    local nMana = bot:GetMana() / bot:GetMaxMana()
    local nRadius = WildAxes:GetSpecialValueInt('radius')
    local nDamage = WildAxes:GetSpecialValueInt('axe_damage')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
        end
    end

    if Fu.IsInTeamFight(bot, nCastRange)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nLocationAoE.count >= 2
        then
            local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
		end
	end

    if Fu.IsGoingOnSomeone(bot)
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
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

    if Fu.IsRetreating(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 600)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (Fu.GetHP(bot) < 0.57 and bot:WasRecentlyDamagedByAnyHero(2.7)))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	then
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

        if nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
		if nLocationAoE.count >= 2
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
            --     and Fu.GetMP(bot) > 0.33
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
        and Fu.GetMP(bot) > 0.25
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
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
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

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderCallOfTheWildBoar()
	if not CallOfTheWildBoar:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE
	end

    local nAttackRange = bot:GetAttackRange()

    if Fu.IsGoingOnSomeone(bot)
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and not Fu.IsInRange(bot, botTarget, nAttackRange)
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	then
        if Fu.IsAttacking(bot)
        then
            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(700, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyTowers = bot:GetNearbyTowers(700, true)
            if nEnemyTowers ~= nil and #nEnemyTowers > 0
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    if Fu.IsFarming(bot)
    and Fu.GetMP(bot) > 0.33
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nAttackRange + 75)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nAttackRange + 75, true)

        if Fu.IsAttacking(bot)
        then
            if nNeutralCreeps ~= nil
                and (#nNeutralCreeps >= 3
                    or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderCallOfTheWildHawk()
    if not CallOfTheWildHawk:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE
	end

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 500, 500, 0, 0)

        if nLocationAoE.count >= 2
        then
            local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, 500)
            if realEnemyCount ~= nil and #realEnemyCount >= 2
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsGoingOnSomeone(bot)
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 450)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if Fu.IsRetreating(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 450)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (Fu.GetHP(bot) < 0.57 and bot:WasRecentlyDamagedByAnyHero(2.7)))
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderPrimalRoar()
	if not PrimalRoar:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, PrimalRoar:GetCastRange())
    local nDuration = PrimalRoar:GetSpecialValueInt('duration')
    local nDamage = PrimalRoar:GetSpecialValueInt('damage')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            if Fu.IsCastingUltimateAbility(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and Fu.IsRunning(enemyHero)
            and bot:IsFacingLocation(enemyHero:GetLocation(), 30)
            and not enemyHero:IsFacingLocation(bot:GetLocation(), 30)
            and not WildAxes:IsFullyCastable()
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

	if Fu.IsInTeamFight(bot, 1200)
	then
        local strongestTarget = Fu.GetStrongestUnit(nCastRange, bot, true, false, nDuration)

        if strongestTarget == nil
        then
            strongestTarget = Fu.GetStrongestUnit(1199, bot, true, true, nDuration)
        end

        if Fu.IsValidTarget(strongestTarget)
        and Fu.CanCastOnMagicImmune(strongestTarget)
        and Fu.CanCastOnTargetAdvanced(strongestTarget)
        and Fu.GetHP(strongestTarget) > 0.5
        and not Fu.IsSuspiciousIllusion(strongestTarget)
        and not Fu.IsDisabled(strongestTarget)
        and not Fu.IsTaunted(strongestTarget)
        and not strongestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not strongestTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not strongestTarget:HasModifier('modifier_legion_commander_duel')
        and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
			return BOT_ACTION_DESIRE_HIGH, strongestTarget
		end
	end

    if Fu.IsGoingOnSomeone(bot)
    and not X.CanDoBlinkRoar()
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidTarget(enemyHero)
            and Fu.CanCastOnMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.GetHP(enemyHero) > 0.5
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsTaunted(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 800, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderBlinkRoar()
    if X.CanDoBlinkRoar()
    then
        local nDuration = PrimalRoar:GetSpecialValueInt('duration')

        if Fu.IsGoingOnSomeone(bot)
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
            local strongestTarget = Fu.GetStrongestUnit(1199, bot, true, false, nDuration)

            if strongestTarget == nil
            then
                strongestTarget = Fu.GetStrongestUnit(1199, bot, true, true, nDuration)
            end

            if Fu.IsValidTarget(strongestTarget)
            and Fu.CanCastOnNonMagicImmune(strongestTarget)
            and Fu.CanCastOnTargetAdvanced(strongestTarget)
            and Fu.IsInRange(bot, strongestTarget, 1199)
            and Fu.GetHP(strongestTarget) > 0.5
            and not Fu.IsSuspiciousIllusion(strongestTarget)
            and not Fu.IsDisabled(strongestTarget)
            and not Fu.IsTaunted(strongestTarget)
            and not strongestTarget:HasModifier('modifier_abaddon_borrowed_time')
            and not strongestTarget:HasModifier('modifier_dazzle_shallow_grave')
            and not strongestTarget:HasModifier('modifier_enigma_black_hole_pull')
            and not strongestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not strongestTarget:HasModifier('modifier_legion_commander_duel')
            and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(strongestTarget, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                then
                    bot.shouldBlink = true
                    BlinkLocation = strongestTarget:GetLocation()
                    return BOT_ACTION_DESIRE_HIGH, strongestTarget
                end
            end
        end
    end

    bot.shouldBlink = false
    return BOT_ACTION_DESIRE_NONE, nil
end

function X.CanDoBlinkRoar()
    if PrimalRoar:IsFullyCastable()
    and X.HasBlink()
    then
        local nManaCost = PrimalRoar:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

function X.HasBlink()
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

function X.CanBKB()
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