local X = {}

local bot
local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')

-- handle attacking special units

function X.GetDesire(bot__)
    bot = bot__

    if Fu.CanNotUseAction(bot) or bot:IsDisarmed() then
        return 0
    end

    local botHealth = bot:GetHealth()
    local botHP = Fu.GetHP(bot)
    local botLocation = bot:GetLocation()
	local botAttackRange = bot:GetAttackRange()
    local botLevel = bot:GetLevel()
    local bMagicImmune = bot:IsMagicImmune()
    local botTarget = Fu.GetProperTarget(bot)
    local botName = bot:GetUnitName()
    local botHealthRegen = bot:GetHealthRegen()

    local tAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 1600)
	local tEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)

    local tAllyHeroes_all = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes_all = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    local bOutnumbered = #tEnemyHeroes > #tAllyHeroes

    local unitList = GetUnitList(UNIT_LIST_ALL)
    for _, unit in pairs(unitList)
	do
		if Fu.IsValid(unit)
        and Fu.IsInRange(bot, unit, 1600)
		then
            bot.special_unit_target = unit
            local sUnitName = unit:GetUnitName()
            local botAttackDamage = X.GetUnitAttackDamageWithinTime(bot, 5.0)
            local unitHealth = unit:GetHealth()
            local unitHealthRegen = unit:GetHealthRegen()
            local unitLocation = unit:GetLocation()
            local withinAttackRange = GetUnitToUnitDistance(bot, unit) <= botAttackRange

            if string.find(sUnitName, 'rattletrap_cog')
            then
                -- Expanded Armature
                -- seems? facet have a frame hit when inside
                if string.find(botName, 'rattletrap') and withinAttackRange and false then
                    if Fu.IsGoingOnSomeone(bot) then
                        if Fu.IsValidHero(botTarget)
                        and Fu.CanCastOnNonMagicImmune(botTarget)
                        and Fu.IsInRange(bot, botTarget, 800)
                        and not Fu.IsInRange(bot, botTarget, 400)
                        and not (Fu.IsInRange(bot, botTarget, 800) and Fu.IsChasingTarget(bot, botTarget))
                        then
                            local tResult = PointToLineDistance(botLocation, botTarget:GetLocation(), unitLocation)
                            if tResult ~= nil and tResult.within and tResult.distance <= 185 then
                                return BOT_MODE_DESIRE_VERYHIGH * 1.5
                            end
                        end
                    end

                    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
                        for _, enemyHero in pairs(tEnemyHeroes) do
                            if Fu.IsValidHero(enemyHero) and Fu.IsInRange(bot, enemyHero, 800) and not Fu.IsInRange(bot, enemyHero, 400) and Fu.IsChasingTarget(enemyHero, bot) then
                                local tResult = PointToLineDistance(botLocation, botTarget:GetLocation(), unitLocation)
                                if tResult ~= nil and tResult.within and tResult.distance <= 185 then
                                    return BOT_MODE_DESIRE_VERYHIGH * 1.5
                                end
                            end
                        end
                    end
                else
                    if bot:IsFacingLocation(unit:GetLocation(), 60) and Fu.IsInRange(bot, unit, 300) then
                        if Fu.IsGoingOnSomeone(bot) then
                            if Fu.IsValidHero(botTarget) and not Fu.IsInRange(bot, botTarget, botAttackRange) then
                                return BOT_MODE_DESIRE_VERYHIGH * 1.5
                            end
                        end

                        return BOT_MODE_DESIRE_ABSOLUTE
                    end
                end
            end

            if bot:GetTeam() ~= unit:GetTeam()
            then
                if string.find(sUnitName, 'juggernaut_healing_ward')
                or string.find(sUnitName, 'invoker_forged_spirit')
                or string.find(sUnitName, 'venomancer_plague_ward')
                or string.find(sUnitName, 'clinkz_skeleton_archer')
                or string.find(sUnitName, 'tinker_turret')
                then
                    if Fu.IsInRange(bot, unit, botAttackRange + 300) then
                        return RemapValClamped(botLevel, 1, 6, BOT_MODE_DESIRE_MODERATE - 0.05, BOT_MODE_DESIRE_MODERATE + 0.05)
                    end

                    if #tEnemyHeroes == 0 then
                        if botHP > 0.6 then
                            return BOT_MODE_DESIRE_VERYHIGH
                        else
                            return BOT_MODE_DESIRE_HIGH
                        end
                    end
                elseif string.find(sUnitName, 'shadow_shaman_ward') and not bOutnumbered
                then
                    local tSerpents = Fu.GetSameUnitType(bot, 1600, sUnitName, false)
                    local unitsAttackDamage = bot:GetActualIncomingDamage(Fu.GetUnitListTotalAttackDamage(bot, tSerpents, 5.0), DAMAGE_TYPE_PHYSICAL) - botHealthRegen * 5.0

                    if not Fu.IsInTeamFight(bot, 1200) and not (Fu.IsRetreating(bot) and Fu.IsRealInvisible(bot)) then
                        if unitsAttackDamage / botHealth < 0.4
                        or Fu.IsInRange(bot, unit, botAttackRange) and not Fu.IsInRange(bot, unit, unit:GetAttackRange()) then
                            return BOT_MODE_DESIRE_VERYHIGH + 0.05
                        end
                    end
                elseif string.find(sUnitName, 'pugna_nether_ward') and not bOutnumbered
                then
                    if Fu.IsInRange(bot, unit, botAttackRange + 150) then
                        if Fu.IsGoingOnSomeone(bot) and (not X.IsHeroWithinRadius(tEnemyHeroes, 800) or not X.IsBeingAttackedByHero(bot)) then
                            return BOT_MODE_DESIRE_HIGH
                        else
                            if not X.IsBeingAttackedByHero(bot) then
                                return BOT_MODE_DESIRE_VERYHIGH
                            end
                        end
                    else
                        return BOT_MODE_DESIRE_MODERATE
                    end
                elseif string.find(sUnitName, 'grimstroke_ink_creature')
                    or string.find(sUnitName, 'weaver_swarm')
                then
                    if #tEnemyHeroes == 0 then
                        return BOT_MODE_DESIRE_VERYHIGH + 0.05
                    end

                    if Fu.IsGoingOnSomeone(bot) and (not X.IsHeroWithinRadius(tEnemyHeroes, 600) or not X.IsBeingAttackedByHero(bot))
                    then
                        return BOT_MODE_DESIRE_VERYHIGH
                    else
                        if not X.IsHeroWithinRadius(tEnemyHeroes, 600) then
                            return BOT_MODE_DESIRE_HIGH
                        end
                    end
                elseif string.find(sUnitName, 'gyrocopter_homing_missile')
                then
                    if not Fu.IsInTeamFight(bot, 1200)
                    and withinAttackRange
                    and not (Fu.IsRetreating(bot) and Fu.IsRealInvisible(bot))
                    and not X.IsBeingAttackedByHero(bot)
                    then
                        if not Fu.IsRunning(unit)
                        or not Fu.IsInRange(bot, unit, 250)
                        then
                            return BOT_MODE_DESIRE_VERYHIGH
                        end
                    end
                elseif string.find(sUnitName, 'ignis_fatuss')
                    or string.find(sUnitName, 'zeus_cloud')
                then
                    if #tAllyHeroes > #tEnemyHeroes or #tEnemyHeroes_all == 0
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange + 500) then return BOT_MODE_DESIRE_VERYHIGH end
                        return BOT_MODE_DESIRE_HIGH
                    end
                elseif unit:HasModifier('modifier_dominated')
                    or unit:HasModifier('modifier_chen_holy_persuasion')
                    or unit:IsDominated()
                    or string.find(sUnitName, 'visage_familiar')
                    or string.find(sUnitName, 'chen_zealot_goodguys')
                then
                    if not bOutnumbered and Fu.IsInRange(bot, unit, botAttackRange + 500) then
                        local unitAttackDamage = bot:GetActualIncomingDamage(X.GetUnitAttackDamageWithinTime(unit, 5.0), DAMAGE_TYPE_PHYSICAL) - botHealthRegen * 5.0
                        botAttackDamage = unit:GetActualIncomingDamage(botAttackDamage, DAMAGE_TYPE_PHYSICAL) - unitHealthRegen * 5.0

                        if not Fu.IsInTeamFight(bot, 1200)
                        and not (Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot))
                        and botAttackDamage / unitHealth > 0.5 and unitAttackDamage / botHealth < 0.4
                        then
                            return BOT_MODE_DESIRE_VERYHIGH
                        end
                    end
                elseif string.find(sUnitName, 'lycan_wolf')
                    or string.find(sUnitName, 'eidolon')
                    or string.find(sUnitName, 'beastmaster_boar')
                    or string.find(sUnitName, 'beastmaster_greater_boar')
                    or string.find(sUnitName, 'furion_treant')
                    or string.find(sUnitName, 'broodmother_spiderling')
                    or string.find(sUnitName, 'skeleton_warrior')
                then
                    if not bOutnumbered and Fu.IsInRange(bot, unit, botAttackRange + 300) and not Fu.IsRetreating(bot) then
                        local tUnits = Fu.GetSameUnitType(bot, 1600, sUnitName, true)
                        local unitsAttackDamage = bot:GetActualIncomingDamage(Fu.GetUnitListTotalAttackDamage(bot, tUnits, 5.0), DAMAGE_TYPE_PHYSICAL) - botHealthRegen * 5.0
                        local totalUnitHealth = X.GetTotalUnitHealth(tUnits)
                        local totalDmgToUnits = X.GetTotalAttackDamageToUnits(botAttackDamage, tUnits, DAMAGE_TYPE_PHYSICAL) - unitHealthRegen * 5.0

                        if not Fu.IsInTeamFight(bot, 1200)
                        and unitsAttackDamage / botHealth < 0.34
                        and totalDmgToUnits / totalUnitHealth > 0.65
                        then
                            return BOT_MODE_DESIRE_VERYHIGH
                        end
                    end
                elseif string.find(sUnitName, 'observer_wards')
                    or string.find(sUnitName, 'sentry_wards')
                then
                    if not X.IsBeingAttackedByHero(bot) or #tEnemyHeroes <= 1
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange + 500) then return BOT_MODE_DESIRE_VERYHIGH + 0.05 end
                        return BOT_MODE_DESIRE_HIGH
                    end
                elseif string.find(sUnitName, 'phoenix_sun') and not bOutnumbered
                then
                    if (#tAllyHeroes >= #tEnemyHeroes or Fu.WeAreStronger(bot, 1600))
                    and not bot:HasModifier('modifier_phoenix_fire_spirit_burn')
                    and not Fu.IsRetreating(bot)
                    and botHP > 0.45
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange + 300) then return BOT_MODE_DESIRE_VERYHIGH + 0.05 end
                        return BOT_MODE_DESIRE_HIGH
                    end
                elseif string.find(sUnitName, 'ice_spire') and not bOutnumbered
                then
                    if (#tAllyHeroes >= #tEnemyHeroes or Fu.WeAreStronger(bot, 1600))
                    and (botHP > 0.80 or bMagicImmune)
                    and not Fu.IsRetreating(bot)
                    and not X.IsBeingAttackedByHero(bot)
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange + 300) then return BOT_MODE_DESIRE_VERYHIGH end
                        return BOT_MODE_DESIRE_HIGH
                    end
                elseif string.find(sUnitName, 'tombstone') and not bOutnumbered
                then
                    if #tAllyHeroes_all >= #tEnemyHeroes_all and not Fu.IsRetreating(bot) and botHP > 0.45
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange + 300) then return BOT_MODE_DESIRE_VERYHIGH + 0.05 end
                        return BOT_MODE_DESIRE_HIGH
                    end
                elseif string.find(sUnitName, 'warlock_golem') and not bOutnumbered
                then
                    local tGolems = Fu.GetSameUnitType(bot, 1600, sUnitName, false)
                    local unitAttackDamage = bot:GetActualIncomingDamage(Fu.GetUnitListTotalAttackDamage(bot, tGolems, 5.0), DAMAGE_TYPE_PHYSICAL) - botHealthRegen * 5.0
                    botAttackDamage = unit:GetActualIncomingDamage(X.GetUnitAttackDamageWithinTime(bot, 5.0), DAMAGE_TYPE_PHYSICAL) - unitHealthRegen * 5.0

                    if not Fu.IsInTeamFight(bot, 1200)
                    and #tAllyHeroes_all >= #tEnemyHeroes_all
                    and not Fu.IsRetreating(bot)
                    then
                        local canKillGolem = botAttackDamage / unitHealth > 0.75 and unitAttackDamage / botHealth < 0.4

                        if Fu.IsInRange(bot, unit, botAttackRange + 300) then
                            if not X.IsUnitAfterUnit(unit, bot)
                            or (X.IsUnitAfterUnit(unit, bot) and canKillGolem)
                            then
                                return BOT_MODE_DESIRE_VERYHIGH + 0.05
                            else
                                return BOT_MODE_DESIRE_HIGH
                            end
                        else
                            if not X.IsUnitAfterUnit(unit, bot)
                            or (X.IsUnitAfterUnit(unit, bot) and canKillGolem)
                            then
                                return BOT_MODE_DESIRE_HIGH
                            end
                        end
                    end
                end
            end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.Think()
    if Fu.CanNotUseAction(bot) then return end

    if Fu.IsValid(bot.special_unit_target) and not bot:IsDisarmed() then
        bot:Action_AttackUnit(bot.special_unit_target, true)
        return
    end
end

function X.IsUnitAfterUnit(hUnit1, hUnit2)
    return hUnit1:GetAttackTarget() == hUnit2 or Fu.IsChasingTarget(hUnit1, hUnit2)
end

function X.GetUnitAttackDamageWithinTime(hUnit, fTimeInterval)
    return hUnit:GetAttackDamage() * hUnit:GetAttackSpeed() * fTimeInterval
end

function X.GetTotalUnitHealth(tUnits)
    local hp = 0
    for i = 1, #tUnits
    do
        hp = hp + tUnits[i]:GetHealth()
    end

    return hp
end

function X.GetTotalAttackDamageToUnits(nDamage, hUnitList, nDamageType)
    local damage = 0
    for _, unit in pairs(hUnitList) do
        damage = damage + unit:GetActualIncomingDamage(nDamage, nDamageType)
    end
    return damage
end

function X.IsBeingAttackedByHero(hUnit)
    local nEnemyHeroes = Fu.GetEnemiesNearLoc(hUnit:GetLocation(), 1600)
    for _, enemy in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemy)
        and not Fu.IsSuspiciousIllusion(enemy)
        and (enemy:GetAttackTarget() == hUnit or Fu.IsChasingTarget(enemy, hUnit))
        then
            return true
        end
    end

    return false
end

function X.IsHeroWithinRadius(tUnits, nRadius)
    if Fu.IsValidHero(tUnits[1]) and Fu.IsInRange(bot, tUnits[1], nRadius) then
        return true
    end

    return false
end

return X