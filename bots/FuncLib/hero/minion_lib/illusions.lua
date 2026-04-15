local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')

local X = {}
local bot

local nLanes = {
    LANE_TOP,
    LANE_MID,
    LANE_BOT,
}

function X.Think(ownerBot, hMinionUnit)
    if not U.IsValidUnit(hMinionUnit) then return end

    bot = ownerBot

    if hMinionUnit.isIllusion then
        if X.ConfuseEnemyWithIllusions(ownerBot, hMinionUnit) > 0 then
            return
        end
    end

	hMinionUnit.attack_desire, hMinionUnit.attack_target = X.ConsiderAttack(hMinionUnit)
    if X.ConsiderRetreat(hMinionUnit, hMinionUnit.attack_target) then return end

    if hMinionUnit.attack_desire > 0 then
        if U.IsValidTarget(hMinionUnit.attack_target) then
            hMinionUnit:Action_AttackUnit(hMinionUnit.attack_target, false)
            return
        end
    end

    -- Per-minion move throttle (was module-level, which cross-pollinated in shared-scope)
    local nNextMoveTime = hMinionUnit._nextMoveTime or 0
    if DotaTime() >= nNextMoveTime then
        hMinionUnit.move_desire, hMinionUnit.move_location = X.ConsiderMove(hMinionUnit)
        if hMinionUnit.move_desire > 0 then
            if GetUnitToLocationDistance(hMinionUnit, hMinionUnit.move_location) > 400 then
                hMinionUnit:Action_MoveToLocation(hMinionUnit.move_location)
            else
                hMinionUnit:Action_AttackMove(Fu.GetRandomLocationWithinDist(hMinionUnit.move_location, 0, 300))
            end
            hMinionUnit._nextMoveTime = DotaTime() + 0.2
            return
        end

        -- Default
        if bot:IsAlive()
        then
            hMinionUnit:Action_MoveToLocation(Fu.GetRandomLocationWithinDist(bot:GetLocation(), 400, 800))
        else
            hMinionUnit:Action_MoveToLocation(Fu.GetClosestTeamLane(hMinionUnit))
        end
        hMinionUnit._nextMoveTime = DotaTime() + 0.2
    end
end

-- 镜像迷惑对手
function X.ConfuseEnemyWithIllusions(bot, hMinionUnit)
    if Fu.GetHP(bot) < 0.4 and Fu.IsRetreating(bot) and not Fu.WeAreStronger(bot, 1200) then
        local retreatDirection = bot:GetFacing()
        local oppositeDirection = (retreatDirection + 180) % 360
        local confuseDistance = 800 -- distance illusions will move
        local confuseLocation = hMinionUnit:GetLocation() +
            Vector(confuseDistance * math.cos(math.rad(oppositeDirection)), confuseDistance * math.sin(math.rad(oppositeDirection))) + RandomVector(50)
        hMinionUnit:Action_MoveToLocation(confuseLocation)
        return 1
    end
    return 0
end

function X.ConsiderRetreat(hMinionUnit, hTarget)
    if hMinionUnit:IsIllusion() then return nil end
    if ((U.IsValidUnit(hTarget) and Fu.GetHP(hTarget) > 0.5 and hTarget:IsFacingLocation( hMinionUnit:GetLocation(), 20 ))
        or Fu.GetHP(hMinionUnit) < 0.25)
    and Fu.GetHP(hMinionUnit) < 0.3
    and hMinionUnit:GetHealth() < 300
     then
        hMinionUnit:Action_MoveToLocation(Fu.GetTeamFountain())
        return 1
    end
    return nil
end

function X.IsTargetInShouldAimToAttackRange(hMinionUnit, target, nMaxRange)
    if not U.IsValidUnit(hTarget) then return false end
    return GetUnitToUnitDistance(hMinionUnit, target) <= hMinionUnit:GetAttackRange()
        or (not U.CantMove(hMinionUnit) and GetUnitToUnitDistance(hMinionUnit, target) < math.min(hMinionUnit:GetAttackRange() * 3, nMaxRange))
end

function X.ConsiderAttack(hMinionUnit)
	if U.CantAttack(hMinionUnit)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local hTarget = X.GetAttackTarget(hMinionUnit)

	if hTarget ~= nil and not U.IsNotAllowedToAttack(hTarget)
	then
		return BOT_ACTION_DESIRE_HIGH, hTarget
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.GetAttackTarget(hMinionUnit)
	local target = nil
    local hMinionUnitName = hMinionUnit:GetUnitName()

	if bot:HasModifier('modifier_bane_nightmare') and not bot:IsInvulnerable()
    and GetUnitToUnitDistance(bot, hMinionUnit) < 2000
    then
        target = bot
    end

    if Fu.IsInLaningPhase()
    then
        if (string.find(hMinionUnitName, 'forge_spirit')
            or string.find(hMinionUnitName, 'eidolon')
            or string.find(hMinionUnitName, 'beastmaster_boar')
            or string.find(hMinionUnitName, 'lycan_wolf')
        )
        and U.IsTargetedByTower(hMinionUnit)
        then
            return nil
        end
    end

    for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMIES))
    do
        if Fu.IsValid(enemy)
        then
            local enemyName = enemy:GetUnitName()
            local specialUnits = Fu.GetSpecialUnits()

            if specialUnits[enemyName]
            and enemy:GetTeam() ~= hMinionUnit:GetTeam()
            and GetUnitToUnitDistance(hMinionUnit, enemy) <= specialUnits[enemyName] * 1600
            and RandomInt(0, 100) <= specialUnits[enemyName] * 100
            then
                return enemy
            end
        end
    end

    if GetUnitToUnitDistance(bot, hMinionUnit) < 1600
    then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
        if #nInRangeEnemy > 0 then target = bot:GetAttackTarget() end
    end

	if target == nil
    or Fu.IsRetreating(bot)
    or (U.IsTargetedByHero(bot) and bot:GetAttackTarget() == nil)
	then
		target = U.GetWeakestHero(1600, hMinionUnit)
		if target == nil then target = U.GetWeakestCreep(1600, hMinionUnit) end
		if target == nil then target = U.GetWeakestTower(1600, hMinionUnit) end
	end

    if target ~= nil
    then
        if not target:IsBuilding()
        and not target:IsTower()
        and target ~= GetAncient(GetOpposingTeam())
        and X.IsTargetUnderEnemyTower(hMinionUnit, target)
        then
            if string.find(hMinionUnitName, 'warlock_golem')
            then
                local nDamage = hMinionUnit:GetAttackDamage()
                if Fu.IsChasingTarget(hMinionUnit, target)
                and not Fu.WillKillTarget(target, nDamage, DAMAGE_TYPE_PHYSICAL, 6.0)
                then
                    return bot:GetAttackTarget()
                end
            end

            if Fu.GetHP(target) > 0.25
            and bot:IsAlive()
            and not Fu.IsChasingTarget(bot, target)
            then
                return bot:GetAttackTarget()
            end
        end
    end

	return target
end

function X.ConsiderMove(hMinionUnit)
	if Fu.CanNotUseAction(hMinionUnit) or U.CantMove(hMinionUnit) then return BOT_MODE_DESIRE_NONE, nil end

    -- Have Naga or TB farm lanes
    local hMinionUnitName = hMinionUnit:GetUnitName()
    if string.find(hMinionUnitName, 'terrorblade')
    or string.find(hMinionUnitName, 'naga_siren')
    then
        for i = 1, #nLanes
        do
            local laneFrontLoc = Fu.GetClosestTeamLane(hMinionUnit)
            if not X.IsMinionInLane(hMinionUnit, nLanes[i])
            then
                laneFrontLoc = GetLaneFrontLocation(GetTeam(), nLanes[i], 0)
            end

            if not Fu.IsInLaningPhase()
            -- and GetUnitToLocationDistance(hMinionUnit, laneFrontLoc) <= 2500
            then
                hMinionUnit.to_farm_lane = nLanes[i]
                return BOT_ACTION_DESIRE_HIGH, laneFrontLoc
            end
        end
    end

    if GetUnitToUnitDistance(bot, hMinionUnit) > 1600
    or not bot:IsAlive()
    or bot:HasModifier('modifier_teleporting')
    then
        local nTeamFightLocation = Fu.GetTeamFightLocation(hMinionUnit)
        if nTeamFightLocation and GetUnitToLocationDistance(hMinionUnit, nTeamFightLocation) < 2200
        then
            return BOT_ACTION_DESIRE_HIGH, nTeamFightLocation
        end

        return BOT_ACTION_DESIRE_HIGH, Fu.GetClosestTeamLane(hMinionUnit)
    else
        return BOT_ACTION_DESIRE_HIGH, Fu.GetRandomLocationWithinDist(bot:GetLocation(), 400, 800)
    end
end

function X.IsTargetUnderEnemyTower(hMinionUnit, unit)
    local nEnemyTowers = hMinionUnit:GetNearbyTowers(1600, true)
    if nEnemyTowers then
        if Fu.IsValidBuilding(nEnemyTowers[1])
        and U.IsValidUnit(unit)
        and Fu.IsInRange(unit, nEnemyTowers[1], 880)
        then
            return true
        end
    end

    return false
end

function X.IsMinionInLane(hMinionUnit, lane)
    for _, ally in pairs(GetUnitList(UNIT_LIST_ALLIES))
    do
        if Fu.IsValid(ally)
        and hMinionUnit ~= ally
        and ally:IsIllusion()
        and string.find(bot:GetUnitName(), ally:GetUnitName())
        then
            if ally.to_farm_lane == lane
            or GetUnitToLocationDistance(ally, GetLaneFrontLocation(GetTeam(), lane, 0)) < 1600
            then
                return true
            end
        end
    end

    return false
end


return X
