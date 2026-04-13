-- Team/unit list queries: nearby heroes, creeps, counts
local function Init(Fu)

-- Frame-level cache for GetUnitList — valid for one game tick (~0.03s).
-- GetUnitList builds lists on-demand no more than once per frame (Valve docs),
-- but our wrapper filters (illusion removal etc.) still re-iterate every call.
-- This caches the FILTERED result so subsequent calls in the same tick are free.
local _unitListCache = {}
local _unitListCacheTime = -1

local function GetCachedUnitList(listType)
	local now = GameTime()
	-- Invalidate entire cache each frame (GameTime changes every frame)
	if now ~= _unitListCacheTime then
		_unitListCache = {}
		_unitListCacheTime = now
	end
	if _unitListCache[listType] then
		return _unitListCache[listType]
	end
	local result = GetUnitList(listType)
	_unitListCache[listType] = result
	return result
end
-- Expose for other modules
Fu.GetCachedUnitList = GetCachedUnitList

-- Pre-filtered enemy hero list: removes illusions/clones once per frame.
-- All functions that need "real enemy heroes" should use this instead of
-- iterating GetCachedUnitList(UNIT_LIST_ENEMY_HEROES) and filtering each time.
local _realEnemyHeroesCache = nil
local _realEnemyHeroesCacheTime = -1

function Fu.GetRealEnemyHeroes()
	local now = GameTime()
	if now == _realEnemyHeroesCacheTime and _realEnemyHeroesCache then
		return _realEnemyHeroesCache
	end
	local all = GetCachedUnitList(UNIT_LIST_ENEMY_HEROES)
	local real = {}
	for _, hero in pairs(all) do
		if Fu.IsValidHero(hero)
		and not Fu.IsSuspiciousIllusion(hero)
		and not Fu.IsMeepoClone(hero)
		and not hero:HasModifier('modifier_arc_warden_tempest_double')
		then
			table.insert(real, hero)
		end
	end
	_realEnemyHeroesCache = real
	_realEnemyHeroesCacheTime = now
	return real
end


--友军生物数量
function Fu.GetUnitAllyCountAroundEnemyTarget( target, nRadius )

	local targetLoc = target:GetLocation()
	local heroCount = Fu.GetNearbyAroundLocationUnitCount( false, true, nRadius, targetLoc )
	local creepCount = Fu.GetNearbyAroundLocationUnitCount( false, false, nRadius, targetLoc )

	return heroCount + creepCount

end


--敌军生物数量


--敌军生物数量
function Fu.GetAroundTargetEnemyUnitCount( target, nRadius )
	local targetLoc = target:GetLocation()
	return Fu.GetAroundTargetLocEnemyUnitCount( targetLoc, nRadius )
end


function Fu.GetAroundTargetLocEnemyUnitCount( targetLoc, nRadius )
	local heroCount = Fu.GetNearbyAroundLocationUnitCount( true, true, nRadius, targetLoc )
	local creepCount = Fu.GetNearbyAroundLocationUnitCount( true, false, nRadius, targetLoc )
	return heroCount + creepCount
end

--敌军英雄数量

--敌军英雄数量
function Fu.GetAroundTargetEnemyHeroCount( target, nRadius )

	return Fu.GetNearbyAroundLocationUnitCount( true, true, nRadius, target:GetLocation() )

end


--通用数量


--通用数量
function Fu.GetNearbyAroundLocationUnitCount( bEnemy, bHero, nRadius, vLoc )
	-- local cacheKey = 'GetNearbyAroundLocationUnitCount'..tostring(nRadius) ..'-'..tostring(bEnemy)..'-'..tostring(bHero)..'-'..tostring(Fu.ToNearest500(vLoc.x))..'-'..tostring(Fu.ToNearest500(vLoc.y))
	-- local cache = Fu.Utils.GetCachedVars(cacheKey, 0.5)
	-- if cache ~= nil then return cache end

	local nCount = 0

	if bHero
	then
		if bEnemy then
			nCount = #Fu.GetEnemiesNearLoc(vLoc, nRadius)
		else
			nCount = #Fu.GetAlliesNearLoc( vLoc, nRadius )
		end
	else
		if bEnemy then
			for _, unit in pairs(GetCachedUnitList(UNIT_LIST_ENEMIES))
			do
				if Fu.IsValid(unit)
				and GetUnitToLocationDistance(unit, vLoc) <= nRadius
				then
					nCount = nCount + 1
				end
			end
		else
			for _, unit in pairs(GetCachedUnitList(UNIT_LIST_ALLIES))
			do
				if Fu.IsValid(unit)
				and GetUnitToLocationDistance(unit, vLoc) <= nRadius
				then
					nCount = nCount + 1
				end
			end
		end
	end

	-- Fu.Utils.SetCachedVars(cacheKey, nCount)
	return nCount

end




function Fu.GetAttackEnemysAllyCreepCount( target, nRadius )

	local bot = GetBot()
	local nAllyCreeps = bot:GetNearbyCreeps( nRadius, false )
	local nAttackEnemyCount = 0
	for _, creep in pairs( nAllyCreeps )
	do
		if creep:IsAlive()
			and creep:CanBeSeen()
			and creep:GetAttackTarget() == target
		then
			nAttackEnemyCount = nAttackEnemyCount + 1
		end
	end

	return nAttackEnemyCount

end



function Fu.GetRetreatingAlliesNearLoc( vLoc, nRadius )
	-- local cacheKey = 'GetRetreatingAlliesNearLoc'..tostring(nRadius) ..tostring(Fu.ToNearest500(vLoc.x))..tostring(Fu.ToNearest500(vLoc.y))
	-- local cache = Fu.Utils.GetCachedVars(cacheKey, 0.5)
	-- if cache ~= nil then return cache end

	local allies = {}
	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local member = GetTeamMember( i )
		if member ~= nil
			and member:IsAlive()
			and GetUnitToLocationDistance( member, vLoc ) <= nRadius
			and Fu.IsRetreating( member )
		then
			table.insert( allies, member )
		end
	end

	-- Fu.Utils.SetCachedVars(cacheKey, allies)

	return allies

end


function Fu.GetAlliesNearLoc( vLoc, nRadius )
	local allies = {}

	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local member = GetTeamMember( i )
		if member ~= nil
			and member:IsAlive()
			and GetUnitToLocationDistance( member, vLoc ) <= nRadius
		then
			table.insert( allies, member )
		end
	end

	return allies
end


function Fu.GetEnemiesNearLoc(vLoc, nRadius)
	local enemies = {}
	-- Use pre-filtered list (illusions/clones already removed, cached per frame)
	for _, enemyHero in pairs(Fu.GetRealEnemyHeroes())
	do
		if GetUnitToLocationDistance(enemyHero, vLoc) <= nRadius
		then
			table.insert(enemies, enemyHero)
		end
	end

	return enemies
end


function Fu.GetIllusionsNearLoc(vLoc, nRadius)
	-- local cacheKey = 'GetIllusionsNearLoc'..tostring(nRadius) ..tostring(Fu.ToNearest500(vLoc.x))..'-'..tostring(Fu.ToNearest500(vLoc.y))
	-- local cache = Fu.Utils.GetCachedVars(cacheKey, 0.5)
	-- if cache ~= nil then return cache end

	local illusions = {}
	for _, enemyHero in pairs(GetCachedUnitList(UNIT_LIST_ENEMY_HEROES))
	do
		if Fu.IsValidHero(enemyHero)
		and GetUnitToLocationDistance(enemyHero, vLoc) <= nRadius
		and Fu.IsSuspiciousIllusion(enemyHero)
		and not Fu.IsMeepoClone(enemyHero)
		then
			table.insert(illusions, enemyHero)
		end
	end

	-- Fu.Utils.SetCachedVars(cacheKey, illusions)

	return illusions
end




function Fu.GetHeroesTargetingUnit(tUnits, hUnit)
    local tAttackingUnits = {}
    for _, enemyHero in pairs(tUnits) do
        if Fu.IsValidHero(enemyHero)
		and not Fu.IsSuspiciousIllusion(enemyHero)
        and (enemyHero:GetAttackTarget() == hUnit or Fu.IsChasingTarget(enemyHero, hUnit))
        then
            table.insert(tAttackingUnits, enemyHero)
        end
    end

    return tAttackingUnits
end


function Fu.GetSameUnitType(hUnit, nRadius, sUnitName, bAttacking)
    local tAttackingUnits = {}
    local unitList = GetCachedUnitList(UNIT_LIST_ALL)
    for _, unit in pairs(unitList) do
        if Fu.IsValid(unit)
        and unit:GetUnitName() == sUnitName
        and GetUnitToUnitDistance(unit, hUnit) <= nRadius
        then
			if bAttacking then
				if (unit:GetAttackTarget() == hUnit or Fu.IsChasingTarget(unit, hUnit)) then
					table.insert(tAttackingUnits, unit)
				end
			else
				table.insert(tAttackingUnits, unit)
			end
        end
    end

    return tAttackingUnits
end
function Fu.IsTargetedByEnemyWithModifier(tUnits, sModifierName)
    for _, enemyHero in pairs(tUnits) do
        if Fu.IsValidHero(enemyHero)
        and enemyHero:HasModifier(sModifierName)
        and (enemyHero:GetAttackTarget() == bot or Fu.IsChasingTarget(enemyHero, bot))
        then
            return true
        end
    end

    return false
end



function Fu.GetInvUnitInLocCount( bot, nRadius, nFindRadius, vLocation, pierceImmune )

	local nUnits = 0
	if nRadius > 1600 then nRadius = 1600 end
	local unitList = Fu.GetNearbyHeroes(bot, nRadius, true, BOT_MODE_NONE )
	for _, u in pairs( unitList ) do
		if ( ( pierceImmune and Fu.CanCastOnMagicImmune( u ) )
			 or ( not pierceImmune and Fu.CanCastOnNonMagicImmune( u ) ) )
			and GetUnitToLocationDistance( u, vLocation ) <= nFindRadius
		then
			nUnits = nUnits + 1
		end
	end

	return nUnits

end




function Fu.GetInLocLaneCreepCount( bot, nRadius, nFindRadius, vLocation )

	local nUnits = 0
	if nRadius > 1600 then nRadius = 1600 end
	local unitList = bot:GetNearbyLaneCreeps( nRadius, true )
	for _, u in pairs( unitList ) do
		if GetUnitToLocationDistance( u, vLocation ) <= nFindRadius
		then
			nUnits = nUnits + 1
		end
	end

	return nUnits

end




function Fu.GetInvUnitCount( pierceImmune, unitList )

	local nUnits = 0
	if unitList ~= nil
	then
		for _, u in pairs( unitList )
		do
			if ( pierceImmune and Fu.CanCastOnMagicImmune( u ) )
				or ( not pierceImmune and Fu.CanCastOnNonMagicImmune( u ) )
			then
				nUnits = nUnits + 1
			end
		end
	end

	return nUnits

end



function Fu.GetAroundTargetAllyHeroCount( target, nRadius )

	local heroList = Fu.GetAlliesNearLoc( target:GetLocation(), nRadius )

	return #heroList

end




function Fu.GetAroundTargetOtherAllyHeroCount( bot, target, nRadius )

	local heroList = Fu.GetAlliesNearLoc( target:GetLocation(), nRadius )

	if GetUnitToUnitDistance( bot, target ) <= nRadius
	then
		return #heroList - 1
	end

	return #heroList

end




function Fu.GetAllyCreepNearLoc( bot, vLoc, nRadius )

	local AllyCreepsAll = bot:GetNearbyCreeps( 1600, false )
	local allyCreepList = { }

	for _, creep in pairs( AllyCreepsAll )
	do
		if creep ~= nil
			and creep:IsAlive()
			and GetUnitToLocationDistance( creep, vLoc ) <= nRadius
		then
			table.insert( allyCreepList, creep )
		end
	end

	return allyCreepList

end




function Fu.GetAllyUnitCountAroundEnemyTarget( bot, target, nRadius )

	local heroList = Fu.GetAlliesNearLoc( target:GetLocation(), nRadius )
	local creepList = Fu.GetAllyCreepNearLoc( bot, target:GetLocation(), nRadius )

	return #heroList + #creepList

end


-- local NearbyHeroMap = {
	-- 'hero_unit_name' = {
	-- 	'enemy' = {
	-- 		'1600' = { 
	-- 			'time' = DotaTime(),
	-- 			'heroes' = {}
	-- 		},
	-- 		'1000' = { },
	-- 	},
	-- 	'ally' = {
	-- 		'1600' = { },
	-- 		'1000' = { },
	-- 	}
	-- }
-- }
-- Lightweight per-bot cache: stores results on the bot handle itself.
-- Key format: _c_{funcName}_{radius}_{enemy} → { time, result }
-- Cache TTL: 0.15s (enough for one full mode cycle, short enough for responsiveness)
local CACHE_TTL = 0.15

local function _getCached(bot, key, ttl)
	if bot._fc == nil then return nil end
	local entry = bot._fc[key]
	if entry and DotaTime() - entry[1] <= (ttl or CACHE_TTL) then
		return entry[2]
	end
	return nil
end

local function _setCache(bot, key, value)
	if bot._fc == nil then bot._fc = {} end
	bot._fc[key] = { DotaTime(), value }
end

function Fu.GetNearbyHeroes(bot, nRadius, bEnemy, bBotMode)
	if not bBotMode then bBotMode = BOT_MODE_NONE end

	local nearby = bot:GetNearbyHeroes(nRadius, bEnemy, bBotMode)
	if not nearby then
		return nearby
	end

	local heroes = {}
	for _, hero in pairs( nearby )
	do
		if Fu.IsValidHero(hero)
		and not Fu.IsMeepoClone(hero)
		and not bot:HasModifier('modifier_arc_warden_tempest_double') then
			table.insert(heroes, hero)
		end
	end

	return heroes

    -- Cap the radius to a maximum value
    -- if nRadius > 1600 then nRadius = 1600 end

    -- -- Initialize the bot's cache table if it doesn't exist
    -- bot.nearbyHeroes = bot.nearbyHeroes or { ally = {}, enemy = {} }

    -- -- Select the appropriate cache based on whether we're looking for enemies or allies
    -- cacheNearbyTable = bEnemy and bot.nearbyHeroes.enemy or bot.nearbyHeroes.ally

    -- -- Check the current time
    -- currentTime = DotaTime()

    -- -- Initialize or update the cache for the specific radius
	-- if cacheNearbyTable[nRadius] == nil or
	-- 	currentTime - cacheNearbyTable[nRadius].time >= nearByHeroCacheDuration
	-- then
	-- 	cacheNearbyTable[nRadius] = {
	-- 		time = currentTime,
	-- 		heroes = bot:GetNearbyHeroes(nRadius, bEnemy, BOT_MODE_NONE)
	-- 	}
	-- end

	-- -- Fu.Utils.PrintTable(cacheNearbyTable[nRadius].heroes)
    -- -- Return the cached nearby heroes
    -- return cacheNearbyTable[nRadius].heroes
end


function Fu.GetAroundBotUnitList( bot, nRadius, bEnemy )

	if nRadius > 1600 then nRadius = 1600 end

	local heroList = Fu.GetNearbyHeroes(bot, nRadius, bEnemy, BOT_MODE_NONE )
	local creepList = bot:GetNearbyCreeps( nRadius, bEnemy )
	local unitList = {}

	if #heroList > 0 and #creepList > 0
	then
		unitList = heroList
		for i = 1, #creepList
		do
			table.insert( unitList, creepList[1] )
		end
	elseif #heroList == 0
	then
		unitList = creepList
	elseif #creepList == 0
	then
		unitList = heroList
	end

	return unitList

end



function Fu.GetAllyList( bot, nRadius )

	if nRadius > 1600 then nRadius = 1600 end

	local nRealAllyList = {}
	local nCandidate = Fu.GetNearbyHeroes(bot, nRadius, false, BOT_MODE_NONE )
	if #nCandidate <= 1 then return nCandidate end

	for _, ally in pairs( nCandidate )
	do
		if ally ~= nil and ally:IsAlive()
			and not ally:IsIllusion()
		then
			table.insert( nRealAllyList, ally )
		end
	end

	return nRealAllyList

end




function Fu.GetAllyCount( bot, nRadius )

	local nRealAllyList = Fu.GetAllyList( bot, nRadius )

	return #nRealAllyList

end




function Fu.GetAroundEnemyHeroList( nRadius )

	if nRadius > 1600 then nRadius = 1600 end

	return Fu.GetNearbyHeroes(GetBot(), nRadius, true, BOT_MODE_NONE )

end




function Fu.GetEnemyList( bot, nRadius )

	if nRadius > 1600 then nRadius = 1600 end
	local nRealEnemyList = {}
	local nCandidate = Fu.GetNearbyHeroes(bot, nRadius, true, BOT_MODE_NONE )
	if nCandidate[1] == nil then return nCandidate end

	for _, enemy in pairs( nCandidate )
	do
		if enemy ~= nil and type(enemy) == "table" and enemy:IsAlive()
			and not Fu.IsSuspiciousIllusion( enemy )
		then
			table.insert( nRealEnemyList, enemy )
		end
	end

	return nRealEnemyList

end




function Fu.GetEnemyCount( bot, nRadius )

	local nRealEnemyList = Fu.GetEnemyList( bot, nRadius )

	return #nRealEnemyList

end


function Fu.GetLastSeenEnemiesNearLoc(vLoc, nRadius)
	local enemies = {}

	for i, id in pairs( GetTeamPlayers( GetOpposingTeam() ) )
	do
		if IsHeroAlive( id ) then
			local info = GetHeroLastSeenInfo( id )
			if info ~= nil then
				local dInfo = info[1]
				if dInfo ~= nil
					and Fu.GetLocationToLocationDistance( vLoc, dInfo.location ) <= nRadius
					and dInfo.time_since_seen < 5.0
				then
					table.insert(enemies, id)
				end
			end
		end
	end

	return enemies
end


function Fu.GetNumOfAliveHeroes( bEnemy )
	-- Bounded key: 2 possible values (ally=80002, enemy=80003)
	local bot = GetBot()
	local nTeam = GetTeam()
	if bEnemy then nTeam = GetOpposingTeam() end
	local cKey = 80000 + nTeam
	local cached = _getCached(bot, cKey, 1.0)
	if cached then return cached end

	local count = 0
	for i, id in pairs( GetTeamPlayers( nTeam ) )
	do
		if IsHeroAlive( id )
		then
			count = count + 1
		end
	end

	_setCache(bot, cKey, count)
	return count

end


function Fu.GetHeroesNearLocation( bEnemy, location, distance )
	local heroes = { }
	local heroList = bEnemy and GetCachedUnitList( UNIT_LIST_ENEMY_HEROES ) or GetCachedUnitList( UNIT_LIST_ALLIED_HEROES )
	for _, hero in pairs( heroList )
	do
		if hero ~= nil and hero:IsAlive() and hero:CanBeSeen() and GetUnitToLocationDistance(hero, location) <= distance then
			table.insert(heroes, hero)
		end
	end
	return heroes

end


function Fu.GetAverageLevel( bEnemy )
	-- Bounded key: 2 possible values
	local bot = GetBot()
	local nTeam = GetTeam()
	if bEnemy then nTeam = GetOpposingTeam() end
	local cKey = 81000 + nTeam
	local cached = _getCached(bot, cKey, 2.0)
	if cached then return cached end

	local count = 0
	local sum = 0
	for i, id in pairs( GetTeamPlayers( nTeam ) )
	do
		sum = sum + GetHeroLevel( id )
		count = count + 1
	end

	local res = sum / count
	_setCache(bot, cKey, res)
	return res

end


function Fu.GetNumOfTeamTotalKills( bEnemy )

	local count = 0
	local nTeam = GetOpposingTeam()
	if bEnemy then nTeam = GetTeam() end

	local CK = Fu.CK
	if CK then
		local cache = Fu.Utils.GetCachedVars(CK.NUM_TEAM_TOTAL_KILLS + nTeam, 1)
		if cache ~= nil then return cache end
	end

	for i, id in pairs( GetTeamPlayers( nTeam ) )
	do
		count = count + GetHeroDeaths( id )
	end

	if CK then Fu.Utils.SetCachedVars(CK.NUM_TEAM_TOTAL_KILLS + nTeam, count) end
	return count

end


function Fu.GetUnitWithMinDistanceToLoc(hUnit, hUnits, cUnits, fMinDist, vLoc)
	local minUnit = cUnits;
	local minVal = fMinDist;
	
	for i=1, #hUnits do
		if hUnits[i] ~= nil and hUnits[i] ~= hUnit and Fu.CanCastOnNonMagicImmune(hUnits[i]) 
		then
			local dist = GetUnitToLocationDistance(hUnits[i], vLoc);
			if dist < minVal then
				minVal = dist;
				minUnit = hUnits[i];	
			end
		end	
	end
	
	return minVal, minUnit;
end


function Fu.GetUnitWithMaxDistanceToLoc(hUnit, hUnits, cUnits, fMinDist, vLoc)
	local maxUnit = cUnits
	local maxVal = fMinDist
	
	for i=1, #hUnits do
		if hUnits[i] ~= nil and hUnits[i] ~= hUnit and Fu.CanCastOnNonMagicImmune(hUnits[i])
		then
			local dist = GetUnitToLocationDistance(hUnits[i], vLoc)
			if dist > maxVal then
				maxVal = dist
				maxUnit = hUnits[i]
			end
		end	
	end
	
	return maxVal, maxUnit
end


function Fu.GetFurthestUnitToLocationFrommAll(hUnit, nRange, vLoc)
	local aHeroes = Fu.GetNearbyHeroes(hUnit,nRange, false, BOT_MODE_NONE)
	local eHeroes = Fu.GetNearbyHeroes(hUnit,nRange, true, BOT_MODE_NONE)
	local aCreeps = hUnit:GetNearbyLaneCreeps(nRange, false)
	local eCreeps = hUnit:GetNearbyLaneCreeps(nRange, true)

	local botDist = GetUnitToLocationDistance(hUnit, vLoc)
	local furthestUnit = hUnit
	botDist, furthestUnit = Fu.GetUnitWithMaxDistanceToLoc(hUnit, aHeroes, furthestUnit, botDist, vLoc)
	botDist, furthestUnit = Fu.GetUnitWithMaxDistanceToLoc(hUnit, eHeroes, furthestUnit, botDist, vLoc)
	botDist, furthestUnit = Fu.GetUnitWithMaxDistanceToLoc(hUnit, aCreeps, furthestUnit, botDist, vLoc)
	botDist, furthestUnit = Fu.GetUnitWithMaxDistanceToLoc(hUnit, eCreeps, furthestUnit, botDist, vLoc)

	if furthestUnit ~= hUnit then
		return furthestUnit
	end

	return nil

end


function Fu.GetClosestUnitToLocationFrommAll(hUnit, nRange, vLoc)
	local aHeroes = Fu.GetNearbyHeroes(hUnit,nRange, false, BOT_MODE_NONE);
	local eHeroes = Fu.GetNearbyHeroes(hUnit,nRange, true, BOT_MODE_NONE);
	local aCreeps = hUnit:GetNearbyLaneCreeps(nRange, false);
	local eCreeps = hUnit:GetNearbyLaneCreeps(nRange, true);
		
	local botDist = GetUnitToLocationDistance(hUnit, vLoc);
	local closestUnit = hUnit;
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, aHeroes, closestUnit, botDist, vLoc);
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, eHeroes, closestUnit, botDist, vLoc);
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, aCreeps, closestUnit, botDist, vLoc);
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, eCreeps, closestUnit, botDist, vLoc);
	
	if closestUnit ~= hUnit then
		return closestUnit;
	end
	
	return nil;
	
end


function Fu.GetClosestUnitToLocationFrommAll2(hUnit, nRange, vLoc)
	local aHeroes = Fu.GetNearbyHeroes(hUnit,nRange, false, BOT_MODE_NONE);
	local eHeroes = Fu.GetNearbyHeroes(hUnit,nRange, true, BOT_MODE_NONE);
	local aCreeps = hUnit:GetNearbyLaneCreeps(nRange, false);
	local eCreeps = hUnit:GetNearbyLaneCreeps(nRange, true);
		
	local botDist = 10000;
	local closestUnit = nil;
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, aHeroes, closestUnit, botDist, vLoc);
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, eHeroes, closestUnit, botDist, vLoc);
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, aCreeps, closestUnit, botDist, vLoc);
	botDist, closestUnit = Fu.GetUnitWithMinDistanceToLoc(hUnit, eCreeps, closestUnit, botDist, vLoc);
	
	if closestUnit ~= nil then
		return closestUnit;
	end
	
	return nil;
	
end


function Fu.GetAliveAllyCoreCount()
	local count = 0
	for _, allyHero in pairs(GetCachedUnitList(UNIT_LIST_ALLIED_HEROES))
	do
		if Fu.IsValidHero(allyHero)
		and Fu.IsCore(allyHero)
		and not allyHero:IsIllusion()
		then
			count = count + 1
		end
	end

	return count
end


function Fu.GetMeepos()
	local Meepos = {}

	for _, allyHero in pairs(GetCachedUnitList(UNIT_LIST_ALLIED_HEROES))
	do
		if Fu.IsValidHero(allyHero)
		and allyHero:GetUnitName() == 'npc_dota_hero_meepo'
		and not Fu.IsSuspiciousIllusion(allyHero)
		then
			table.insert(Meepos, allyHero)
		end
	end

	return Meepos
end


-- count the number of human vs bot players in the team. returns: #humen, #bots
function Fu.NumHumanBotPlayersInTeam()
	local nHuman, nBot = 0, 0
	for _, member in pairs(GetTeamPlayers(GetTeam()))
	do
		if not IsPlayerBot(member)
		then
			nHuman = nHuman + 1
		else
			nBot = nBot + 1
		end
	end

	return nHuman, nBot
end


function Fu.GetEnemiesAroundAncient(bot, nRadius)
	if bot == nil then bot = GetBot() end
	return Fu.GetEnemiesAroundLoc(GetAncient(bot:GetTeam()):GetLocation(), nRadius)
end

function Fu.GetEnemiesAroundLoc(vLoc, nRadius)
	if not nRadius then nRadius = 2000 end
	-- local cacheKey = 'GetEnemiesAroundLoc'..tostring(nRadius) ..'-'..tostring(Fu.ToNearest500(vLoc.x))..'-'..tostring(Fu.ToNearest500(vLoc.y))
	-- local cache = Fu.Utils.GetCachedVars(cacheKey, 0.5)
	-- if cache ~= nil then return cache end

	local nUnitCount = 0
	local ancientLoc = GetAncient(GetBot():GetTeam()):GetLocation()

	-- Check Heroes. 
	for _, id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id)
			if info ~= nil then
				local dInfo = info[1]
				if dInfo ~= nil
				and Fu.GetLocationToLocationDistance(vLoc, dInfo.location) <= nRadius
				and dInfo.time_since_seen < 5.0
				then
					nUnitCount = nUnitCount + GetHeroLevel(id) / 3
					if Fu.GetLocationToLocationDistance(ancientLoc, vLoc) < 1600 then
						nUnitCount = nUnitCount + 2 -- Increase weight for critical defense.
					end
				end
			end
		end
	end

	for _, unit in pairs(GetCachedUnitList(UNIT_LIST_ENEMIES))
	do
		if Fu.IsValid(unit)
		and GetUnitToLocationDistance(unit, vLoc) <= nRadius
		then
			local unitName = unit:GetUnitName()
			if unit:IsCreep() then
				nUnitCount = nUnitCount + 1
				if unit:IsAncientCreep()
				or unit:HasModifier('modifier_chen_holy_persuasion')
				or unit:HasModifier('modifier_dominated') then
					nUnitCount = nUnitCount + 1
				end
			elseif string.find(unit:GetUnitName(), 'spiderling') then nUnitCount = nUnitCount + 0.1
			elseif string.find(unit:GetUnitName(), 'eidolon') then nUnitCount = nUnitCount + 0.3
			elseif string.find(unitName, 'siege') and not string.find(unitName, 'upgraded') then
				nUnitCount = nUnitCount + 0.6
			elseif string.find(unitName, 'upgraded') then nUnitCount = nUnitCount + 1
			elseif string.find(unitName, 'warlock_golem') then
				if DotaTime() < 10 * 60 then nUnitCount = nUnitCount + 3
				elseif DotaTime() < 20 * 60 then nUnitCount = nUnitCount + 2.5
				elseif DotaTime() < 30 * 60 then nUnitCount = nUnitCount + 2
				else nUnitCount = nUnitCount + 1.5 end
			elseif string.find(unitName, 'lone_druid_bear') then nUnitCount = nUnitCount + 3
			elseif string.find(unitName, 'shadow_shaman_ward') then nUnitCount = nUnitCount + 2
			elseif string.find(unit:GetUnitName(), "tombstone") then nUnitCount = nUnitCount + 2
			elseif Fu.IsSuspiciousIllusion(unit) then
				if unit:HasModifier('modifier_arc_warden_tempest_double')
					or string.find(unit:GetUnitName(), 'chaos_knight')
					or string.find(unit:GetUnitName(), 'naga_siren') then nUnitCount = nUnitCount + 2 end
			elseif not (string.find(unitName, 'observer_wards') or string.find(unitName, 'sentry_wards')) then nUnitCount = nUnitCount + 1 end
			if Fu.GetLocationToLocationDistance(ancientLoc, vLoc) < 1600 then nUnitCount = nUnitCount + 2 end
		end
	end

	-- Fu.Utils.SetCachedVars('GetEnemiesAroundLoc'..cacheKey, nUnitCount)
	return nUnitCount
end

local hAllyTeamList = {}
local hEnemyTeamList = {}
function Fu.GetInventoryNetworth()
	local allyInventoryNet = 0
	local enemyInventoryNet = 0
	if math.floor(DotaTime()) % 2 == 0 then
		for i = 1, #GetTeamPlayers( GetTeam() ) do
			local ally = GetTeamMember(i)
			if ally then
				local itemsCost = 0
				for j = 0, 8 do
					local item = ally:GetItemInSlot(j)
					if item then
						itemsCost = itemsCost + GetItemCost(item:GetName())
					end
				end
				local id = ally:GetPlayerID()
				if hAllyTeamList[id] == nil then hAllyTeamList[id] = 0 end
				if hAllyTeamList[id] < itemsCost then
					hAllyTeamList[id] = itemsCost
				end
			end
		end
		for _, enemy in pairs(GetCachedUnitList(UNIT_LIST_ENEMY_HEROES)) do
			if Fu.IsValidHero(enemy)
			and not Fu.IsSuspiciousIllusion(enemy)
			and not enemy:HasModifier('modifier_arc_warden_tempest_double')
			and not string.find(enemy:GetUnitName(), 'lone_druid_bear')
			and not Fu.IsMeepoClone(enemy)
			then
				local id = enemy:GetPlayerID()
				local itemsCost = 0
				for i = 0, 8 do
					local item = enemy:GetItemInSlot(i)
					if item then
						itemsCost = itemsCost + GetItemCost(item:GetName())
					end
				end
				if hEnemyTeamList[id] == nil then hEnemyTeamList[id] = 0 end
				if hEnemyTeamList[id] < itemsCost then
					hEnemyTeamList[id] = itemsCost
				end
			end
		end
	end
	for _, networth in pairs(hAllyTeamList) do allyInventoryNet = allyInventoryNet + networth end
	for _, networth in pairs(hEnemyTeamList) do enemyInventoryNet = enemyInventoryNet + networth end

	return allyInventoryNet, enemyInventoryNet
end


function Fu.GetAliveCoreCount(nEnemy)
	-- Bounded key: 2 possible values
	local bot = GetBot()
	local cKey = 82000 + (nEnemy and 1 or 0)
	local cached = _getCached(bot, cKey, 1.0)
	if cached then return cached end

	local count = 0
	if nEnemy then
		for _, enemyHero in pairs(GetCachedUnitList(UNIT_LIST_ENEMY_HEROES))
		do
			if Fu.IsValidHero(enemyHero) and not Fu.IsSuspiciousIllusion(enemyHero) and Fu.IsCore(enemyHero) then
				count = count + 1
			end
		end
	else
		for _, allyHero in pairs(GetCachedUnitList(UNIT_LIST_ALLIED_HEROES))
		do
			if Fu.IsValidHero(allyHero) and not allyHero:IsIllusion() and Fu.IsCore(allyHero) then
				count = count + 1
			end
		end
	end

	_setCache(bot, cKey, count)
	return count
end


function Fu.GetEnemyCountInLane(lane)
	local count = 0
	local laneFront = GetLaneFrontLocation(GetTeam(), lane, 0)
	for _, id in pairs( GetTeamPlayers( GetOpposingTeam()))
	do
		if IsHeroAlive(id)
		then
			local info = GetHeroLastSeenInfo(id)

			if info ~= nil
			then
				local dInfo = info[1]

				if dInfo ~= nil
				and Fu.GetDistance(laneFront, dInfo.location) < 1600
				and dInfo.time_since_seen < 6
				then
					count = count + 1
				end
			end
		end
	end

	return count
end


function Fu.GetCreepListAroundTargetCanKill(target, nRadius, damage, bEnemy, bNeutral, bLaneCreep)
	if nRadius > 1600 then nRadius = 1600 end
	local creepList = {}

	if target ~= nil
	then
		if bNeutral
		then
			for _, creep in pairs(GetUnitList(UNIT_LIST_NEUTRAL_CREEPS))
			do
				if Fu.IsValid(creep)
				and target ~= creep
				and GetUnitToUnitDistance(target, creep) <= nRadius
				and creep:GetHealth() <= damage
				then
					table.insert(creepList, creep)
				end
			end
		elseif bLaneCreep
		then
			local unitList = GetUnitList(UNIT_LIST_ALLIED_CREEPS)
			if bEnemy
			then
				unitList = GetUnitList(UNIT_LIST_ENEMY_CREEPS)
			end

			for _, creep in pairs(unitList)
			do
				if Fu.IsValid(creep)
				and target ~= creep
				and GetUnitToUnitDistance(target, creep) <= nRadius
				and creep:GetHealth() <= damage
				then
					table.insert(creepList, creep)
				end
			end
		else
			local unitList = GetUnitList(UNIT_LIST_ALLIED_CREEPS)
			if bEnemy
			then
				unitList = GetUnitList(UNIT_LIST_ENEMY_CREEPS)
			end

			for _, creep in pairs(unitList)
			do
				if Fu.IsValid(creep)
				and target ~= creep
				and GetUnitToUnitDistance(target, creep) <= nRadius
				and creep:GetHealth() <= damage
				then
					table.insert(creepList, creep)
				end
			end

			unitList = GetUnitList(UNIT_LIST_NEUTRAL_CREEPS)
			for _, creep in pairs(unitList)
			do
				if Fu.IsValid(creep)
				and target ~= creep
				and GetUnitToUnitDistance(target, creep) <= nRadius
				and creep:GetHealth() <= damage
				then
					table.insert(creepList, creep)
				end
			end			
		end
	end

	return creepList
end


end

return Init
