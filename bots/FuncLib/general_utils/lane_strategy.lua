-- Lane strategy: push, defend, farm desire
local function Init(Fu)


function Fu.ShouldGoFarmDuringLaning(bot)
	-- laning is too hard for the bot, try go farming somewhere else.
	local lane = bot:GetAssignedLane()
	return Fu.IsInLaningPhase()
	and GetHeroDeaths(bot:GetPlayerID()) >= 4
	and (GetHeroKills(bot:GetPlayerID()) == 0 or GetHeroKills(bot:GetPlayerID()) / GetHeroDeaths(bot:GetPlayerID()) < 0.5)
	and Fu.IsCore(bot)
	and bot:GetLevel() >= 4
	and bot:GetLevel() < 10
	and Fu.GetEnemyCountInLane(lane) >= 1
end

--------------------------------------------------ew functions 2018.12.7


function Fu.GetMostFarmLaneDesire(bot)

	local nTopDesire = GetFarmLaneDesire( LANE_TOP )
	local nMidDesire = GetFarmLaneDesire( LANE_MID )
	local nBotDesire = GetFarmLaneDesire( LANE_BOT )

	if nTopDesire > nMidDesire and nTopDesire > nBotDesire
	then
		return LANE_TOP, nTopDesire
	end

	if nBotDesire > nMidDesire and nBotDesire > nTopDesire
	then
		return LANE_BOT, nBotDesire
	end

	if DotaTime() < 8 * 60 then
		return bot:GetAssignedLane(), 0.667
	end

	return LANE_MID, nMidDesire

end




function Fu.GetMostDefendLaneDesire()

	local nTopDesire = Fu.GetDefendLaneDesire( LANE_TOP )
	local nMidDesire = Fu.GetDefendLaneDesire( LANE_MID )
	local nBotDesire = Fu.GetDefendLaneDesire( LANE_BOT )

	if nMidDesire > nTopDesire and nMidDesire > nBotDesire then
		return LANE_MID, nMidDesire
	end

	if nTopDesire > nMidDesire and nTopDesire > nBotDesire
	then
		return LANE_TOP, nTopDesire
	end

	if nBotDesire > nMidDesire and nBotDesire > nTopDesire
	then
		return LANE_BOT, nBotDesire
	end

	return LANE_MID, nMidDesire

end


function Fu.GetDefendLaneDesire(lane)
	local defaultDefDesire, newDefDesire = GetDefendLaneDesire(lane), GetBot().DefendLaneDesire
	if newDefDesire ~= nil and newDefDesire[lane] ~= nil and newDefDesire[lane] > defaultDefDesire
	then
		return newDefDesire[lane]
	end
	return defaultDefDesire
end


function Fu.IsPingCloseToValidTower(nTeam, ping, nRadius, fInterval)
	if ping and ping.location then
		local unitList = UNIT_LIST_ALLIED_BUILDINGS
		if nTeam == GetOpposingTeam() then
			unitList = UNIT_LIST_ENEMY_BUILDINGS
		end
		for _, unit in pairs(GetUnitList(unitList)) do
			if unit ~= nil
			and unit:IsAlive()
			and unit:CanBeSeen()
			and not unit:IsInvulnerable()
			and not unit:HasModifier('modifier_backdoor_protection')
			and not unit:HasModifier('modifier_backdoor_protection_in_base')
			and not unit:HasModifier('modifier_backdoor_protection_active')
			and not string.find(unit:GetUnitName(), 'fillers')
			then
				local sUnitName = unit:GetUnitName()
				if Fu.GetDistance(unit:GetLocation(), ping.location) <= nRadius and GameTime() < ping.time + fInterval then
					local nLane = LANE_MID
					if string.find(sUnitName, '_fort') then
						nLane = LANE_MID
					elseif string.find(sUnitName, '_top') then
						nLane = LANE_TOP
					elseif string.find(sUnitName, '_mid') then
						nLane = LANE_MID
					elseif string.find(sUnitName, '_bot') then
						nLane = LANE_BOT
					end
					return true, nLane
				end
			end
		end
	end

	return false, -1
end



function Fu.GetMostPushLaneDesire()

	local nTopDesire = GetPushLaneDesire( LANE_TOP )
	local nMidDesire = GetPushLaneDesire( LANE_MID )
	local nBotDesire = GetPushLaneDesire( LANE_BOT )

	if nTopDesire > nMidDesire and nTopDesire > nBotDesire
	then
		return LANE_TOP, nTopDesire
	end

	if nBotDesire > nMidDesire and nBotDesire > nTopDesire
	then
		return LANE_BOT, nBotDesire
	end

	return LANE_MID, nMidDesire

end


end

return Init
