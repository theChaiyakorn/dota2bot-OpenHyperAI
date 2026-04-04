-- Bot mode checks and team activity queries
local function Init(Fu)


function Fu.IsInTeamFight( bot, nRadius )

	if nRadius == nil or nRadius > 1600 then nRadius = 1600 end

	-- Bounded key: per-bot, single radius value (always 1200 in practice)
	if bot._tfCache and DotaTime() - bot._tfCache[1] <= 0.2 then
		return bot._tfCache[2]
	end

	local attackModeAllyList = Fu.GetNearbyHeroes(bot, nRadius, false, BOT_MODE_ATTACK )
	local result = #attackModeAllyList >= 2
	bot._tfCache = { DotaTime(), result }
	return result

end


function Fu.IsRetreating( bot )

	local mode = bot:GetActiveMode()
	local modeDesire = bot:GetActiveModeDesire()
	local bDamagedByAnyHero = bot:WasRecentlyDamagedByAnyHero( 2.0 )

	return ( mode == BOT_MODE_RETREAT and modeDesire > BOT_MODE_DESIRE_MODERATE and bot:DistanceFromFountain() > 0 )
		 or ( mode == BOT_MODE_EVASIVE_MANEUVERS and bDamagedByAnyHero )
		 or ( bot:HasModifier( 'modifier_bloodseeker_rupture' ) and bDamagedByAnyHero )
		 or ( mode == BOT_MODE_FARM and modeDesire > BOT_MODE_DESIRE_ABSOLUTE )
		
end



function Fu.IsGoingOnSomeone( bot )

	local mode = bot:GetActiveMode()

	return mode == BOT_MODE_ROAM
		or mode == BOT_MODE_TEAM_ROAM
		or mode == BOT_MODE_GANK
		or mode == BOT_MODE_ATTACK
		or mode == BOT_MODE_DEFEND_ALLY

end


function Fu.IsDefending( bot )

	local mode = bot:GetActiveMode()

	return mode == BOT_MODE_DEFEND_TOWER_TOP
		or mode == BOT_MODE_DEFEND_TOWER_MID
		or mode == BOT_MODE_DEFEND_TOWER_BOT

end


function Fu.IsPushing( bot )

	local mode = bot:GetActiveMode()

	return mode == BOT_MODE_PUSH_TOWER_TOP
		or mode == BOT_MODE_PUSH_TOWER_MID
		or mode == BOT_MODE_PUSH_TOWER_BOT

end


function Fu.IsLaning( bot )
	local mode = bot:GetActiveMode()

	return mode == BOT_MODE_LANING

end


function Fu.IsDoingRoshan( bot )

	local mode = bot:GetActiveMode()

	return mode == BOT_MODE_ROSHAN

end




function Fu.IsFarming( bot )

	local mode = bot:GetActiveMode()
	local nTarget = Fu.GetProperTarget( bot )

	return mode == BOT_MODE_FARM
			or ( nTarget ~= nil
					and nTarget:IsAlive()
					and nTarget:GetTeam() == TEAM_NEUTRAL
					and not Fu.IsRoshan( nTarget ) )
end




function Fu.IsTeamActivityCount( bot, nCount )

	local numPlayer = GetTeamPlayers( GetTeam() )
	for i = 1, #numPlayer
	do
		local member = GetTeamMember( i )
		if member ~= nil and member:IsAlive()
		then
			if Fu.GetAllyCount( member, 1600 ) >= nCount
			then
				return true
			end
		end
	end

	return false

end




function Fu.GetSpecialModeAllies( bot, nDistance, nMode )

	local allyList = {}
	local numPlayer = GetTeamPlayers( GetTeam() )
	for i = 1, #numPlayer
	do
		local member = GetTeamMember( i )
		if member ~= nil and member:IsAlive()
		then
			if member:GetActiveMode() == nMode
				and GetUnitToUnitDistance( member, bot ) <= nDistance
			then
				table.insert( allyList, member )
			end
		end
	end

	return allyList

end




function Fu.GetSpecialModeAlliesCount( nMode )

	local allyList = Fu.GetSpecialModeAllies( GetBot(), 99999, nMode )

	return #allyList

end




function Fu.GetTeamFightLocation( bot )

	local team = GetTeam()

	-- local res = Fu.Utils.GetCachedVars('GetTeamFightLocation'..tostring(team), 0.5)
	-- if res ~= nil then return res end

	local targetLocation = nil
	local numPlayer = GetTeamPlayers( team )

	for i = 1, #numPlayer
	do
		local member = GetTeamMember( i )
		if member ~= nil and member:IsAlive()
			and Fu.IsInTeamFight( member, 1500 )
			and Fu.GetEnemyCount( member, 1400 ) >= 2
		then
			local allyList = Fu.GetSpecialModeAllies( member, 1400, BOT_MODE_ATTACK )
			targetLocation = Fu.GetCenterOfUnits( allyList )
			break
		end
	end

	-- Fu.Utils.SetCachedVars('GetTeamFightLocation', targetLocation)
	return targetLocation

end




function Fu.GetTeamFightAlliesCount( bot )

	local numPlayer = GetTeamPlayers( GetTeam() )
	local nCount = 0
	for i = 1, #numPlayer
	do
		local member = GetTeamMember( i )
		if member ~= nil and member:IsAlive()
			and Fu.IsInTeamFight( member, 1200 )
			and Fu.GetEnemyCount( member, 1400 ) >= 2
		then
			nCount = Fu.GetSpecialModeAlliesCount( BOT_MODE_ATTACK )
			break
		end
	end

	return nCount

end



function Fu.IsDoingTormentor(bot)
	return bot:GetActiveMode() == BOT_MODE_SIDE_SHOP
end


function Fu.IsAnyAllyDefending(bot, lane)
	for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
	do
		if Fu.IsValidHero(allyHero)
		and Fu.IsNotSelf(bot, allyHero)
		then
			local mode = allyHero:GetActiveMode()
			if (mode == BOT_MODE_DEFEND_TOWER_TOP and lane == LANE_TOP)
			or (mode == BOT_MODE_DEFEND_TOWER_MID and lane == LANE_MID)
			or (mode == BOT_MODE_DEFEND_TOWER_BOT and lane == LANE_BOT)
			then
				return true
			end
		end
	end
	return false
end

end

return Init
