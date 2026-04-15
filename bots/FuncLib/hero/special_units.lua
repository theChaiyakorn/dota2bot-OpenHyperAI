local X = {}

local bot
local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')

-- handle attacking special units.
-- Target is stored per-bot (`bot.special_unit_target`) instead of a module-level
-- variable so shared-scope (online) environments don't cross-pollinate targets
-- between bots — that race caused bots to attack one another's targets, and
-- combined with UNIT_LIST_ALL iteration in a prior rewrite, friendly minions.

function X.GetDesire(bot__)
	local nBotHP = Fu.GetHP(bot)
	local bRetreating = Fu.IsRetreating(bot)
	local bRealInvis = Fu.IsRealInvisible(bot)
	local bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
    bot = bot__

    if Fu.CanNotUseAction(bot) or bot:IsDisarmed() then
        return 0
    end

    -- Clear stale target from prior tick so a 0-desire frame doesn't leave
    -- a target that downstream Think paths could pick up.
    bot.special_unit_target = nil

    local botHealth = bot:GetHealth()
    local botHP = nBotHP
    local botLocation = bot:GetLocation()
	local botAttackRange = bot:GetAttackRange()

    local tAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 1600)
	local tEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)

    local tAllyHeroes_all = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes_all = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	local botTarget = Fu.GetProperTarget(bot)
    local botName = bot:GetUnitName()
	local isClockwerkInTeam = false

	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local allyHero = GetTeamMember(i)
		if allyHero ~= nil and allyHero:GetUnitName() == 'npc_dota_hero_rattletrap'
		then
			isClockwerkInTeam = true
			break
		end
	end

	for _, unit in pairs(GetUnitList(UNIT_LIST_ENEMIES))
	do
		if Fu.IsValid(unit)
        and Fu.CanBeAttacked(unit)
        and Fu.IsInRange(bot, unit, 1600)
		then
            bot.special_unit_target = unit
            local unitName = unit:GetUnitName()
            local botAttackDamage = X.GetUnitAttackDamageWithinTime(bot, 8.0)
            local unitHP = Fu.GetHP(unit)
            local unitLocation = unit:GetLocation()
            local withinAttackRange = GetUnitToUnitDistance(bot, unit) <= botAttackRange

            if string.find(unitName, 'rattletrap_cog')
            then
                -- Expanded Armature
                -- seems? facet have a frame hit when inside
                if string.find(botName, 'rattletrap') and withinAttackRange then
                    if bGoingOnSomeone then
                        if Fu.IsValidHero(botTarget)
                        and Fu.CanCastOnNonMagicImmune(botTarget)
                        and Fu.IsInRange(bot, botTarget, 800)
                        and not Fu.IsInRange(bot, botTarget, 400)
                        and not (Fu.IsInRange(bot, botTarget, 800) and Fu.IsChasingTarget(bot, botTarget))
                        then
                            local tResult = PointToLineDistance(botLocation, botTarget:GetLocation(), unitLocation)
                            if tResult ~= nil and tResult.within and tResult.distance <= 185 then
                                return 2
                            end
                        end
                    end

                    if bRetreating and bRealInvis then
                        for _, enemyHero in pairs(tEnemyHeroes) do
                            if Fu.IsValidHero(enemyHero) and Fu.IsInRange(bot, enemyHero, 800) and not Fu.IsInRange(bot, botTarget, 400) and Fu.IsChasingTarget(enemyHero, bot) then
                                local tResult = PointToLineDistance(botLocation, botTarget:GetLocation(), unitLocation)
                                if tResult ~= nil and tResult.within and tResult.distance <= 185 then
                                    return 2
                                end
                            end
                        end
                    end
                else
                    local cogsCount1 = Fu.GetPowerCogsCountInLoc(botLocation, 1000)
                    local cogsCount2 = Fu.GetPowerCogsCountInLoc(botLocation, 216)

                    if #tEnemyHeroes_all >= 1
                    then
                        local nInRangeEnemy = Fu.GetEnemiesNearLoc(botLocation, 800)

                        -- Is stuck inside?
                        if cogsCount1 == 8 and cogsCount2 >= 4 and withinAttackRange
                        then
                            if #nInRangeEnemy == 0
                            or bGoingOnSomeone
                            or (bRetreating and not bRealInvis and #nInRangeEnemy >= 1)
                            or #tAllyHeroes < #tEnemyHeroes
                            then
                                return 0.95
                            else
                                return 0.55
                            end
                        end
                    end

                    if #tEnemyHeroes == 0 then
                        if cogsCount1 == 8 and cogsCount2 >= 4 and withinAttackRange then
                            return 0.90
                        else
                            if bot:GetTeam() ~= unit:GetTeam()
                            and Fu.IsInRange(bot, unit, botAttackRange + 350)
                            and not Fu.IsInLaningPhase()
                            then
                                return 0.75
                            else
                                return 0.50
                            end
                        end
                    end
                end
            end


            if bot:GetTeam() ~= unit:GetTeam()
            then
                if string.find(unitName, 'juggernaut_healing_ward')
                or string.find(unitName, 'roshans_banner')
                or string.find(unitName, 'land_mine')
                or string.find(unitName, 'ignis_fatuus')
                then
                    if Fu.IsInRange(bot, unit, botAttackRange) then return 1 end
                    if Fu.IsInRange(bot, unit, botAttackRange + 200) then return RemapValClamped(nBotHP, 0.1, 0.9, 0, 0.96) end
                    if #tEnemyHeroes_all == 0 then return RemapValClamped(nBotHP, 0.2, 0.9, 0, 0.9) end
                    if #tAllyHeroes >= #tEnemyHeroes then return RemapValClamped(nBotHP, 0.2, 0.9, 0, 0.7) end
                end

                if string.find(unitName, 'siege') then
                    if #tEnemyHeroes_all == 0 and Fu.GetDistanceFromAncient(bot, false) < 3000 then
                        return 0.5
                    end
                end

                if string.find(unitName, 'shadow_shaman_ward')
                or string.find(unitName, 'invoker_forged_spirit')
                or string.find(unitName, 'venomancer_plague_ward')
                or string.find(unitName, 'clinkz_skeleton_archer') then
                    if nBotHP > 0.7 and Fu.IsInRange(bot, unit, botAttackRange) then
                        if #tEnemyHeroes == 0 then return RemapValClamped(nBotHP, 0.3, 0.9, 0, 0.75) end
                        if #tAllyHeroes >= #tEnemyHeroes then return 0.4 end
                    end
                    if nBotHP < 0.7 and Fu.IsStuck( bot ) then return RemapValClamped(nBotHP, 0.2, 0.8, 0.7, 0.3) end

                    local tSerpents = X.GetUnitTypeAttackingBot(botLocation, 1600, unitName)
                    local unitsAttackDamage = X.GetTotalAttackDamage(tSerpents, 8.0)
                    botAttackDamage = X.GetUnitAttackDamageWithinTime(bot, 5.0)

                    if not Fu.IsInTeamFight(bot, 900)
                    and not (bRetreating and bRealInvis)
                    then
                        if unitsAttackDamage < botHealth
                        or Fu.IsInRange(bot, unit, botAttackRange) and not Fu.IsInRange(bot, unit, unit:GetAttackRange()) then
                            return 0.31
                        end
                    end
                end

                if string.find(unitName, 'pugna_nether_ward')
                then
                    if Fu.IsInRange(bot, unit, botAttackRange + 150) then
                        if (bGoingOnSomeone
                        and Fu.IsValidHero(botTarget)
                        and Fu.IsInRange(bot, botTarget, botAttackRange - 130)
                        and Fu.GetHP(botTarget) < 0.5)
                        or (X.IsBeingAttackedByHero(bot) and botHP < 0.5)
                        then
                            return 0.35
                        else
                            if not X.IsBeingAttackedByHero(bot) then
                                return 0.60
                            end
                        end
                    else
                        return 0.35
                    end
                end

                if string.find(unitName, 'grimstroke_ink_creature')
                or string.find(unitName, 'weaver_swarm')
                or string.find(unitName, 'tidehunter_anchor')
                then
                    if #tEnemyHeroes == 0 then
                        return 0.9
                    end
                    if (bGoingOnSomeone
                        and Fu.IsValidHero(botTarget)
                        and Fu.IsInRange(bot, botTarget, botAttackRange - 130)
                        and Fu.GetHP(botTarget) < 0.5)
                        or (X.IsBeingAttackedByHero(bot) and botHP < 0.5)
                    then
                        return 0.35
                    end
                    if not X.IsHeroWithinRadius(tEnemyHeroes, botAttackRange - 130)
                    then
                        return 0.96
                    end
                    if not X.IsBeingAttackedByHero(bot)
                    then
                        return 0.8
                    else
                    end
                end

                if string.find(unitName, 'gyrocopter_homing_missile')
                then
                    if not Fu.IsInTeamFight(bot, 900)
                    and withinAttackRange
                    and not (bRetreating and bRealInvis)
                    then
                        if not Fu.IsRunning(unit)
                        or not Fu.IsInRange(bot, unit, 250)
                        then
                            return 0.9
                        end
                    end
                end

                if string.find(unitName, 'zeus_cloud')
                then
                    if #tAllyHeroes >= #tEnemyHeroes or #tEnemyHeroes_all == 0
                    then
                        if withinAttackRange then return 0.7 end
                        return RemapValClamped(nBotHP, 0.3, 0.9, 0, 0.65)
                    end
                end

                if string.find(unitName, 'lone_druid_bear')
                or string.find(unitName, 'npc_dota_brewmaster')
                then
                    if #tAllyHeroes >= 2 and #tAllyHeroes_all > #tEnemyHeroes_all
                    then
                        return 0.45
                    end

                    if not X.IsUnitAfterUnit(unit, bot)
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end

                    if unitHP < 0.25
                    then
                        if X.IsUnitAfterUnit(unit, bot)
                        then
                            return RemapValClamped(botHP, 0.25, 0.9, 0.2, 0.9)
                        else
                            return 0.45
                        end
                    end
                end

                if unit:HasModifier('modifier_dominated')
                or unit:HasModifier('modifier_chen_holy_persuasion')
                or string.find(unitName, 'visage_familiar') then
                    local unitAttackDamage = X.GetUnitAttackDamageWithinTime(unit, 5.5)
                    botAttackDamage = X.GetUnitAttackDamageWithinTime(bot, 5.0)

                    if not Fu.IsInTeamFight(bot, 1200)
                    and not (bRetreating and not bRealInvis)
                    and withinAttackRange
                    and botAttackDamage > unitHP and unitAttackDamage < botHealth
                    then
                        return 0.5
                    end
                end

                if string.find(unitName, 'lycan_wolf')
                or string.find(unitName, 'eidolon')
                or string.find(unitName, 'beastmaster_boar')
                or string.find(unitName, 'beastmaster_greater_boar')
                or string.find(unitName, 'furion_treant')
                or string.find(unitName, 'broodmother_spiderling')
                or string.find(unitName, 'skeleton_warrior')
                then
                    local tUnits = X.GetUnitTypeAttackingBot(botLocation, 1600, unitName)
                    local unitAttackDamage = X.GetTotalAttackDamage(tUnits, 4.0)
                    local totalUnitHP = X.GetTotalUnitHealth(tUnits)
                    botAttackDamage = X.GetUnitAttackDamageWithinTime(bot, 4.0)

                    if not Fu.IsInTeamFight(bot, 1200)
                    and withinAttackRange
                    and botAttackDamage > totalUnitHP and unitAttackDamage < botHealth
                    then
                        return RemapValClamped(botHP, 0.25, 0.9, 0.2, 0.5)
                    end
                end

                if (string.find(unitName, 'observer_wards')
                or string.find(unitName, 'sentry_wards'))
                and X.IsThereSentry(unit:GetLocation())
                then
                    if not X.IsBeingAttackedByHero(bot) or #tEnemyHeroes <= 1
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange * 1.5) then return 0.6 end
                        return 0.5
                    end
                end

                if string.find(unitName, 'phoenix_sun')
                then
                    if (#tAllyHeroes >= #tEnemyHeroes or Fu.WeAreStronger(bot, 1600))
                    and not bot:HasModifier('modifier_phoenix_fire_spirit_burn')
                    and not bRetreating
                    then
                        local tCloseAllyHeroes = Fu.GetAlliesNearLoc(unit:GetLocation(), 900)
                        if Fu.IsInRange(bot, unit, botAttackRange + 200) and #tCloseAllyHeroes >= 2 then return 1.2 end
                        if Fu.IsInRange(bot, unit, botAttackRange + 300) and #tCloseAllyHeroes >= 2 then return 1.1 end
                        if Fu.IsInRange(bot, unit, botAttackRange + 400) then return RemapValClamped(nBotHP, 0.2, 0.9, 0.4, 0.97) end
                        return RemapValClamped(nBotHP, 0.2, 0.9, 0, 0.9)
                    end
                end

                if string.find(unitName, 'tombstone')
                then
                    if #tAllyHeroes_all >= #tEnemyHeroes_all and not bRetreating
                    then
                        if Fu.IsInRange(bot, unit, botAttackRange + 200) then return RemapValClamped(nBotHP, 0.25, 0.9, 0.4, 0.96) end
                        return 0.56
                    end
                end

                if string.find(unitName, 'undying_zombie')
                then
                    if #tAllyHeroes_all >= #tEnemyHeroes_all and not bRetreating
                    then
                        if withinAttackRange then return 0.6 end
                        return 0.25
                    end
                end

                if string.find(unitName, 'warlock_golem')
                then
                    botAttackDamage = X.GetUnitAttackDamageWithinTime(bot, 5)
                    local unitAttackDamage = X.GetUnitAttackDamageWithinTime(unit, 5)

                    if not Fu.IsInTeamFight(bot, 1600)
                    and #tAllyHeroes_all >= #tEnemyHeroes_all
                    then
                        local canKillGolem = botAttackDamage > unitHP and unitAttackDamage * 1.2 < botHP

                        if Fu.IsInRange(bot, unit, botAttackRange + 300)
                        then
                            if not X.IsUnitAfterUnit(unit, bot)
                            or (X.IsUnitAfterUnit(unit, bot) and canKillGolem)
                            then
                                return 0.35
                            else
                                return 0.25
                            end
                        else
                            if not X.IsUnitAfterUnit(unit, bot)
                            or (X.IsUnitAfterUnit(unit, bot) and canKillGolem)
                            then
                                return 0.25
                            end
                        end
                    end
                end
            end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

-- Accept the running bot as an arg. The module-level `bot` is shared in
-- shared-scope environments, so relying on it would cross-pollinate.
function X.Think(bot__)
    local runningBot = bot__ or bot
    if runningBot == nil or Fu.CanNotUseAction(runningBot) then return end

    local target = runningBot.special_unit_target
    if Fu.IsValid(target) and not runningBot:IsDisarmed() then
        runningBot:Action_AttackUnit(target, true)
        return
    end
end

function X.IsUnitAfterUnit(unit_1, unit_2)
    return unit_1:GetAttackTarget() == unit_2 or Fu.IsChasingTarget(unit_1, unit_2)
end

function X.GetTotalAttackDamage(tUnits, nTime)
    local dmg = 0

	for _, unit in pairs(tUnits)
	do
		if Fu.IsValid(unit)
		then
            dmg = dmg + unit:GetAttackDamage() * unit:GetAttackSpeed() * nTime
		end
	end

	return dmg
end

function X.GetUnitTypeAttackingBot(vLoc, nRadius, hName)
    local tAttackingUnits = {}

    for _, unit in pairs(GetUnitList(UNIT_LIST_ENEMIES))
    do
        if Fu.IsValid(unit)
        and unit:GetUnitName() == hName
        and GetUnitToLocationDistance(unit, vLoc) <= nRadius
        and (unit:GetAttackTarget() == bot or Fu.IsChasingTarget(unit, bot))
        then
            table.insert(tAttackingUnits, unit)
        end
    end

    return tAttackingUnits
end

function X.GetUnitAttackDamageWithinTime(unit, nTime)
    return unit:GetAttackDamage() * unit:GetAttackSpeed() * nTime
end

function X.GetTotalUnitHealth(tUnits)
    local hp = 0
    for i = 1, #tUnits
    do
        hp = hp + tUnits[i]:GetHealth()
    end

    return hp
end

function X.IsBeingAttackedByHero(unit)
    for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMIES))
    do
        if Fu.IsValidHero(enemy)
        and enemy:GetAttackTarget() == unit
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

function X.IsThereSentry(loc)
	local nWardList = GetUnitList(UNIT_LIST_ALLIED_WARDS)

	for _, ward in pairs(nWardList)
    do
		if ward ~= nil
		and ward:GetUnitName() == "npc_dota_sentry_wards"
        and GetUnitToLocationDistance(ward, loc) <= 600
        then
			return true
		end
	end

	return false
end

return X