local X = {}
local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local Customize = require(GetScriptDirectory()..'/FuncLib/systems/custom_loader')
Customize.ThinkLess = Customize.Enable and Customize.ThinkLess or 1

local bot = GetBot()

local minute = 0
local second = 0

local bBottle = false

local nRuneList = {
	RUNE_BOUNTY_1,
	RUNE_BOUNTY_2,
	RUNE_POWERUP_1,
	RUNE_POWERUP_2,
}

local botHP, botMP, botPos, botActiveMode, botActiveModeDesire, botAssignedLane
local nAllyHeroes, nEnemyHeroes

local nHumanClaimedRuneTime = {}

local function IsHumanClaimingRune(nRune)
	local vRuneLoc = GetRuneSpawnLocation(nRune)
	if nHumanClaimedRuneTime[nRune] and GameTime() - nHumanClaimedRuneTime[nRune] < 5 then
		return true
	end
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local member = GetTeamMember(i)
		if member ~= nil and member:IsAlive() and not member:IsBot() then
			if GetUnitToLocationDistance(member, vRuneLoc) < 2000 then
				nHumanClaimedRuneTime[nRune] = GameTime()
				return true
			end
			local ping = member:GetMostRecentPing()
			if ping ~= nil and ping.normal_ping
			and Fu.GetDistance(ping.location, vRuneLoc) < 800
			and GameTime() - ping.time < 5 then
				nHumanClaimedRuneTime[nRune] = GameTime()
				return true
			end
		end
	end
	return false
end

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end
	return GetDesireRaw()
end

function GetDesireRaw()
	X.InitRune()

	if (DotaTime() > 2 * 60 and DotaTime() < 6 * 60 and GetUnitToLocationDistance(bot, GetRuneSpawnLocation(RUNE_POWERUP_2)) < 80) then
		return BOT_MODE_DESIRE_NONE
	end

	bBottle = bot:FindItemSlot('item_bottle') >= 0
	botHP = Fu.GetHP(bot)
	botMP = Fu.GetMP(bot)
	botPos = Fu.GetPosition(bot)
	botActiveMode = bot:GetActiveMode()
	botActiveModeDesire = bot:GetActiveModeDesire()
	botAssignedLane = bot:GetAssignedLane()
	nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE) or {}
	nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE) or {}

	if bot:IsInvulnerable() and botHP > 0.9 and bot:DistanceFromFountain() < 500 then
		return BOT_MODE_DESIRE_ABSOLUTE
	end

	-- Drop rune desire when outnumbered so attack/retreat can take over.
	-- This prevents bots from walking into ambushes at rune spots.
	-- During laning 1v1 mid, don't suppress — runes are part of the lane.
	if DotaTime() > 0 and #nEnemyHeroes > 0 then
		if #nEnemyHeroes > #nAllyHeroes then
			return BOT_MODE_DESIRE_NONE
		end
		if bot:WasRecentlyDamagedByAnyHero(2.0) and botHP < 0.4 then
			return BOT_MODE_DESIRE_NONE
		end
	end

	-- Removed: idle check was preventing rune pickup when bot had no other action
	-- if (DotaTime() > -10 and bot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE) then
	-- 	return BOT_MODE_DESIRE_NONE
	-- end

	-- Don't leave team when pushing or defending together
	if Fu.Utils.IsTeamPushingSecondTierOrHighGround(bot) then
		return BOT_MODE_DESIRE_NONE
	end
	local enemiesAtAncient = Fu.Utils.CountEnemyHeroesNear(GetAncient(GetTeam()):GetLocation(), 3200)
	if enemiesAtAncient >= 1 then
		return BOT_MODE_DESIRE_NONE
	end
	-- Enemies pushing our HG: don't leave the base for runes
	if Fu.Utils.CountEnemyHeroesOnHighGround(GetTeam()) >= 2 then
		return BOT_MODE_DESIRE_NONE
	end

	-- Mid/late game: never walk far for runes, only grab if nearby
	if not Fu.IsInLaningPhase() then
		-- If pushing or defending, no rune desire at all
		if Fu.IsPushing(bot) or Fu.IsDefending(bot) then
			return BOT_MODE_DESIRE_NONE
		end
		-- Suppress if any ally is pushing with the team
		local mode = bot:GetActiveMode()
		if mode == BOT_MODE_PUSH_TOWER_TOP or mode == BOT_MODE_PUSH_TOWER_MID or mode == BOT_MODE_PUSH_TOWER_BOT then
			return BOT_MODE_DESIRE_NONE
		end
	end
	-- 1-7 min: laning rune logic (water runes + role-based bounty)
	-- If already in rune mode walking to a rune, commit — don't oscillate with laning
	if DotaTime() >= 60 and DotaTime() < 7 * 60 then
		local nCheckDist = 2500
		if botActiveMode == BOT_MODE_RUNE
		and bot.rune and bot.rune.normal
		and bot.rune.normal.location ~= nil and bot.rune.normal.location ~= -1
		and GetUnitToLocationDistance(bot, GetRuneSpawnLocation(bot.rune.normal.location)) < nCheckDist
		then
			local commitStatus = GetRuneStatus(bot.rune.normal.location)
			if commitStatus == RUNE_STATUS_AVAILABLE or commitStatus == RUNE_STATUS_UNKNOWN then
				return BOT_MODE_DESIRE_VERYHIGH
			end
		end

		local laningDesire = X.GetLaningRuneDesire(nCheckDist)
		if laningDesire > 0 then return laningDesire end
	end

	-- Core rune logic using bot.rune state
	if bot.rune and bot.rune.normal then
		local nProximityRadius = Fu.IsInLaningPhase() and 1600 or 1200
		local rune = bot.rune.normal

		rune.location, rune.distance = X.GetBestRune()

		-- Hard distance cap: never walk far for runes
		if rune.distance > 4000 and DotaTime() >= 60 * 2 then
			return BOT_MODE_DESIRE_NONE
		end

		-- Pre-game: move toward rune with moderate desire
		if DotaTime() < 0 and not bot:WasRecentlyDamagedByAnyHero(10.0) then
			return BOT_MODE_DESIRE_MODERATE
		end

		-- Mid/late: only grab runes if very close
		if not Fu.IsInLaningPhase() and rune.distance > 2000 then
			return BOT_MODE_DESIRE_NONE
		end

		if rune.location ~= -1 then
			rune.type = GetRuneType(rune.location)
			rune.status = GetRuneStatus(rune.location)

			local vRuneLocation = GetRuneSpawnLocation(rune.location)

			-- Defer to human players nearby (local addition)
			if rune.distance < 1200 then
				for _, ally in pairs(nAllyHeroes) do
					if ally ~= nil and not ally:IsBot() and GetUnitToLocationDistance(ally, vRuneLocation) < 2000 then
						return BOT_MODE_DESIRE_NONE
					end
				end
			end

			if rune.location == RUNE_BOUNTY_1 or rune.location == RUNE_BOUNTY_2 then
				if rune.status == RUNE_STATUS_AVAILABLE
				and (X.IsTeamMustSaveRune(rune.location) or not Fu.IsInLaningPhase() or GetUnitToLocationDistance(bot, vRuneLocation) <= 500)
				then
					if X.IsEnemyPickRune(rune.location) then return BOT_MODE_DESIRE_NONE end

					if bBottle or (botPos >= 4 and not X.IsThereAllyWithBottle(vRuneLocation, 1600)) then
						return X.GetScaledDesire(BOT_MODE_DESIRE_VERYHIGH, rune.distance, 3500)
					else
						return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, 3500)
					end
				elseif rune.status == RUNE_STATUS_UNKNOWN
					and rune.distance <= nProximityRadius * 1.5
					and DotaTime() > 3 * 60 + 50
					and ((minute % 4 == 0) or (minute % 4 == 3) and second > 45)
				then
					return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius)
				elseif rune.status == RUNE_STATUS_MISSING
					and rune.distance <= nProximityRadius * 1.5
					and DotaTime() > 3 * 60 + 50
					and ((minute % 4 == 3) or second > 52)
				then
					return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius * 2.5)
				end
			else
				-- Power rune / water rune
				if rune.status == RUNE_STATUS_AVAILABLE then
					if X.IsEnemyPickRune(rune.location) then return BOT_MODE_DESIRE_NONE end

					local nRuneType = rune.type
					-- Water rune support (local addition)
					if nRuneType == RUNE_WATER and (bBottle or botHP < 0.6 or botMP < 0.5) then
						return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, 3200)
					elseif nRuneType == RUNE_WATER and not bBottle then
						return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius)
					end

					-- Mid laner with bottle: high priority for river runes
					local bMidLaner = botAssignedLane == LANE_MID and Fu.IsInLaningPhase()
					if bBottle or (not Fu.IsEarlyGame() and botPos <= 3) then
						local baseDesire = bMidLaner and BOT_MODE_DESIRE_VERYHIGH or BOT_MODE_DESIRE_HIGH
						return X.GetScaledDesire(baseDesire, rune.distance, nProximityRadius * 2.5)
					else
						return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius * 2.5)
					end
				elseif rune.status == RUNE_STATUS_UNKNOWN and DotaTime() > 113 then
					if bBottle or (not Fu.IsEarlyGame() and botPos <= 3) then
						return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius * 2.5)
					else
						return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius)
					end
				elseif rune.status == RUNE_STATUS_MISSING and DotaTime() > 60 and (minute % 2 == 1 and second > 53) then
					return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius)
				elseif rune.status == RUNE_STATUS_UNKNOWN and X.IsTeamMustSaveRune(rune.location) and DotaTime() > 113 and rune.distance <= nProximityRadius * 2 then
					return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, rune.distance, nProximityRadius * 2)
				end
			end
		end
	end

	return BOT_MODE_DESIRE_NONE
end

-- OnStart / OnEnd
local Bottle = nil
function OnStart()
	local nSlot = bot:FindItemSlot('item_bottle')
	if bot:GetItemSlotType(nSlot) == ITEM_SLOT_TYPE_MAIN then
		Bottle = bot:GetItemInSlot(nSlot)
	end
end

function OnEnd()
	Bottle = nil
end

local fNextMovementTime = -math.huge
function Think()
	if bot:IsInvulnerable() and bot:DistanceFromFountain() < 500 then
		bot:Action_MoveToLocation(bot:GetLocation() + RandomVector(500))
		return
	end

	if Fu.CanNotUseAction(bot)
	or bot:GetCurrentActionType() == BOT_ACTION_TYPE_PICK_UP_RUNE
	then
		return
	end

	-- Pre-game movement
	if DotaTime() < 0 then
		if Fu.IsModeTurbo() and DotaTime() < -50 then
			return
		end

		-- If outnumbered near rune spot, retreat to tower safety instead
		local preGameEnemies = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
		local preGameAllies = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
		if #preGameEnemies > #preGameAllies and #preGameEnemies >= 2 then
			local safeLoc = GetLaneFrontLocation(GetTeam(), botAssignedLane or bot:GetAssignedLane(), -1500)
			bot:Action_MoveToLocation(safeLoc)
			return
		end

		if DotaTime() < -10 then
			local vLocation = X.GetGoOutLocation()
			if GetUnitToLocationDistance(bot, vLocation) > 300 then
				bot:Action_MoveToLocation(vLocation)
				return
			else
				if DotaTime() >= fNextMovementTime then
					bot:Action_MoveToLocation(vLocation + RandomVector(150))
					fNextMovementTime = DotaTime() + RandomFloat(1, 3)
					return
				end
			end
			return
		end

		if GetTeam() == TEAM_RADIANT then
			if botAssignedLane == LANE_BOT then
				bot:Action_MoveToLocation(GetRuneSpawnLocation(RUNE_BOUNTY_2) + RandomVector(50))
				return
			else
				bot:Action_MoveToLocation(GetRuneSpawnLocation(RUNE_POWERUP_1) + RandomVector(50))
				return
			end
		else
			if botAssignedLane == LANE_TOP then
				bot:Action_MoveToLocation(GetRuneSpawnLocation(RUNE_BOUNTY_1) + RandomVector(50))
				return
			else
				bot:Action_MoveToLocation(GetRuneSpawnLocation(RUNE_POWERUP_2) + RandomVector(50))
				return
			end
		end
	end

	-- Post-horn rune pickup
	if bot.rune and bot.rune.normal then
		local botAttackRange = math.min(bot:GetAttackRange() + 150, 1200)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), botAttackRange)
		local nEnemyCreeps = bot:GetNearbyCreeps(botAttackRange, true)
		local rune = bot.rune.normal

		local vRuneLocation = GetRuneSpawnLocation(rune.location)

		-- River runes during 1-7 min: keep walking even without vision
		local bIsRiverRune = (rune.location == RUNE_POWERUP_1 or rune.location == RUNE_POWERUP_2)
		if bIsRiverRune and DotaTime() >= 60 and DotaTime() < 7 * 60
		and rune.status ~= RUNE_STATUS_AVAILABLE
		and not IsLocationVisible(vRuneLocation)
		then
			if GetUnitToLocationDistance(bot, vRuneLocation) > 50 then
				bot:Action_MoveToLocation(vRuneLocation)
				return
			end
		end

		if rune.status == RUNE_STATUS_AVAILABLE then
			if Bottle and Fu.CanCastAbility(Bottle) and rune.distance < 1200 then
				local nCharges = Bottle:GetCurrentCharges()
				if nCharges > 0 and (botHP ~= 1 or botMP ~= 1) then
					bot:Action_UseAbility(Bottle)
					return
				end
			end

			if rune.distance > 50 then
				for _, enemyHero in pairs(nInRangeEnemy) do
					if Fu.IsValidHero(enemyHero)
					and (1.5 * bot:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_ALL) > enemyHero:GetEstimatedDamageToTarget(true, bot, 5.0, DAMAGE_TYPE_ALL))
					and botHP > 0.3
					then
						bot:Action_AttackUnit(enemyHero, true)
						return
					end
				end

				if Fu.IsValid(nEnemyCreeps[1])
				and Fu.CanBeAttacked(nEnemyCreeps[1])
				and Fu.CanKillTarget(nEnemyCreeps[1], bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
				then
					bot:Action_AttackUnit(nEnemyCreeps[1], true)
					return
				end

				bot.rune.location = vRuneLocation
				bot:Action_MoveToLocation(vRuneLocation)
				return
			else
				bot:Action_PickUpRune(rune.location)
				return
			end
		else
			for _, enemyHero in pairs(nInRangeEnemy) do
				if Fu.IsValidHero(enemyHero)
				and (1.6 * bot:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_ALL) > enemyHero:GetEstimatedDamageToTarget(true, bot, 5.0, DAMAGE_TYPE_ALL))
				and botHP > 0.3
				then
					bot:Action_AttackUnit(enemyHero, true)
					return
				end
			end

			if Fu.IsValid(nEnemyCreeps[1])
			and Fu.CanBeAttacked(nEnemyCreeps[1])
			and Fu.CanKillTarget(nEnemyCreeps[1], bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
			then
				bot:Action_AttackUnit(nEnemyCreeps[1], true)
				return
			end

			bot.rune.location = vRuneLocation
			bot:Action_MoveToLocation(vRuneLocation)
			return
		end
	end
end

function X.InitRune()
	if bot.rune == nil then
		bot.rune = {
			normal = {
				time = 0,
				type = nil,
				location = nil,
				distance = 0,
				status = RUNE_STATUS_MISSING,
			},
			location = nil,
		}
	end
end

function X.IsSuitableToPickRune()
	if X.IsNearRune(bot, 550) then return true end

	local vRuneLocation = GetRuneSpawnLocation(bot.rune.normal.location)

	if (Fu.IsRetreating(bot) and botActiveModeDesire > BOT_MODE_DESIRE_HIGH)
	or (#nEnemyHeroes >= 1 and #Fu.GetHeroesTargetingUnit(nEnemyHeroes, bot) > 0)
	or (bot:WasRecentlyDamagedByAnyHero(5.0) and Fu.IsRetreating(bot))
	or (GetUnitToUnitDistance(bot, GetAncient(GetTeam())) < 2500 and DotaTime() > 0)
	or GetUnitToUnitDistance(bot, GetAncient(GetOpposingTeam())) < 4000
	or bot:HasModifier('modifier_item_shadow_amulet_fade')
	then
		return false
	end

	return true
end

function X.IsNearRune(hUnit, nRadius)
	nRadius = nRadius or 600
	for _, rune in pairs(nRuneList) do
		local vRuneLocation = GetRuneSpawnLocation(rune)
		if GetUnitToLocationDistance(hUnit, vRuneLocation) <= nRadius then
			return true
		end
	end
	return false
end

function X.GetBestRune()
	minute = math.floor(DotaTime() / 60)
	second = DotaTime() % 60

	local targetRune = -1
	local targetRuneDistance = math.huge
	for _, rune in pairs(nRuneList) do
		local vRuneLocation = GetRuneSpawnLocation(rune)

		if X.IsTheClosestAlly(bot, vRuneLocation)
		and not X.IsPingedByHumanPlayer(vRuneLocation, math.huge)
		and not IsHumanClaimingRune(rune)
		and not X.IsMissing(rune)
		then
			if (rune == RUNE_BOUNTY_1 or rune == RUNE_BOUNTY_2)
			or (Fu.IsCore(bot) or not Fu.IsThereCoreNearby(1200))
			then
				local dist = GetUnitToLocationDistance(bot, vRuneLocation)
				if dist < targetRuneDistance then
					targetRune = rune
					targetRuneDistance = dist
				end
			end
		end
	end

	return targetRune, targetRuneDistance
end

function X.IsTheClosestAlly(hUnit, vLocation)
	local targetAlly = hUnit
	local targetAllyDistance = GetUnitToLocationDistance(hUnit, vLocation)
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if Fu.IsValidHero(member) then
			local memberDistance = GetUnitToLocationDistance(member, vLocation)
			if memberDistance < targetAllyDistance then
				targetAlly = member
				targetAllyDistance = memberDistance
			end
		end
	end
	return targetAlly == hUnit
end

function X.IsThereAllyWithBottle(vLocation, nRadius)
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if Fu.IsValidHero(member)
		and member ~= bot
		and GetUnitToLocationDistance(member, vLocation) <= nRadius
		and member:FindItemSlot('item_bottle') >= 0
		then
			return true
		end
	end
	return false
end

function X.IsTherePosition(nPos, nRuneLoc, nRadius)
	local vRuneLocation = GetRuneSpawnLocation(nRuneLoc)
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if Fu.IsValidHero(member) and Fu.GetPosition(member) == nPos and bot ~= member then
			local dist1 = GetUnitToLocationDistance(bot, vRuneLocation)
			local dist2 = GetUnitToLocationDistance(member, vRuneLocation)
			if dist1 <= nRadius and dist2 <= nRadius then
				return true
			end
		end
	end
	return false
end

-- Utility functions
local pingTimeDelta = 30
function X.IsPingedByHumanPlayer(vLocation, nRadius)
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if Fu.IsValidHero(member)
		and not member:IsBot()
		and GetUnitToLocationDistance(member, vLocation) <= nRadius
		then
			local ping = member:GetMostRecentPing()
			if ping then
				if not ping.normal_ping
				and Fu.GetDistance(ping.location, vLocation) <= 800
				and GameTime() - ping.time < pingTimeDelta
				then
					return true
				end
			end
		end
	end
	return false
end

function X.IsPowerRune(nRuneLoc)
	local nRuneType = GetRuneType(nRuneLoc)
	if nRuneType == RUNE_DOUBLEDAMAGE
	or nRuneType == RUNE_HASTE
	or nRuneType == RUNE_ILLUSION
	or nRuneType == RUNE_INVISIBILITY
	or nRuneType == RUNE_REGENERATION
	or nRuneType == RUNE_ARCANE
	or nRuneType == RUNE_SHIELD
	then
		return true
	end
	return false
end

function X.IsMissing(nRune)
	if second < 52 and GetRuneStatus(nRune) == RUNE_STATUS_MISSING then
		return true
	end
	return false
end

function X.IsEnemyPickRune(nRune)
	local vRuneLocation = GetRuneSpawnLocation(nRune)

	if GetUnitToLocationDistance(bot, vRuneLocation) < 600 then return false end

	for _, enemy in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemy)
		and not Fu.IsSuspiciousIllusion(enemy)
		and (enemy:IsFacingLocation(vRuneLocation, 30) or GetUnitToLocationDistance(enemy, vRuneLocation) < 600)
		and (GetUnitToLocationDistance(enemy, vRuneLocation) < GetUnitToLocationDistance(bot, vRuneLocation) + 300)
		then
			return true
		end
	end

	return false
end

function X.IsUnitAroundLocation(vLoc, nRadius)
	for _, id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id)
			if info ~= nil then
				local dInfo = info[1]
				if dInfo ~= nil and Fu.GetDistance(vLoc, dInfo.location) <= nRadius and dInfo.time_since_seen < 1.0 then
					return true
				end
			end
		end
	end
	return false
end

function X.GetScaledDesire(nBase, nCurrDist, nMaxDist)
	-- Local enhancement: cap desire for distant runes in late game
	local maxDesire = 0.92
	if nCurrDist > 2000 and (Fu.IsLateGame() or Fu.GetDistanceFromEnemyFountain(bot) < 5500) then
		maxDesire = 0.55
	elseif nCurrDist > 1200 then
		maxDesire = 0.85
	end
	local hp = Fu.GetHP(bot)
	local resDesire = Clamp(nBase * RemapValClamped(nCurrDist, 0, nMaxDist, 1, 0.5), 0, maxDesire)
	if hp < 0.6 then
		resDesire = RemapValClamped(hp, 0, 0.8, 0, resDesire)
	end
	return resDesire
end

local vGoOutLoc = nil
function X.GetGoOutLocation()
	if vGoOutLoc then return vGoOutLoc end

	if GetTeam() == TEAM_RADIANT then
		if botPos == 1 or botPos == 5 then
			local locs = { Vector(526.370239, -3893.405762, 256.000000), Vector(1999.415894, -4838.790039, 256.000000) }
			vGoOutLoc = locs[RandomInt(1, #locs)]
		elseif botPos == 2 or botPos == 3 or botPos == 4 then
			local locs = { Vector(-3456.702637, 649.725403, 256.000000), Vector(-1945.830322, 60.404663, 128.000000) }
			vGoOutLoc = locs[RandomInt(1, #locs)]
		end
	elseif GetTeam() == TEAM_DIRE then
		if botPos == 1 or botPos == 5 then
			local locs = { Vector(-1051.021973, 3384.059082, 256.000000), Vector(-2415.422119, 4641.448242, 256.000000) }
			vGoOutLoc = locs[RandomInt(1, #locs)]
		elseif botPos == 2 or botPos == 3 or botPos == 4 then
			local locs = { Vector(2734.819580, -1155.105225, 256.000000), Vector(1142.979614, -337.891663, 128.000000) }
			vGoOutLoc = locs[RandomInt(1, #locs)]
		end
	end

	return vGoOutLoc
end

function X.CouldBlink(vLocation)
	local blinkSlot = bot:FindItemSlot("item_blink")
	if bot:GetItemSlotType(blinkSlot) == ITEM_SLOT_TYPE_MAIN
	or (bot:GetUnitName() == "npc_dota_hero_antimage" or bot:GetUnitName() == "npc_dota_hero_queenofpain")
	then
		local blink = bot:GetItemInSlot(blinkSlot)
		if bot:GetUnitName() == "npc_dota_hero_antimage" then
			blink = bot:GetAbilityByName("antimage_blink")
		end
		if bot:GetUnitName() == "npc_dota_hero_queenofpain" then
			blink = bot:GetAbilityByName("queenofpain_blink")
		end
		if Fu.CanCastAbility(blink) then
			local bDist = GetUnitToLocationDistance(bot, vLocation)
			local maxBlinkLoc = Fu.Site.GetXUnitsTowardsLocation(bot, vLocation, 1199)
			if bDist <= 500 then
				return false
			elseif bDist < 1200 then
				bot:Action_UseAbilityOnLocation(blink, vLocation)
				return true
			elseif IsLocationPassable(maxBlinkLoc) then
				bot:Action_UseAbilityOnLocation(blink, maxBlinkLoc)
				return true
			end
		end
	end
	return false
end

function X.IsTeamMustSaveRune(nRune)
	if GetTeam() == TEAM_DIRE then
		return nRune == RUNE_BOUNTY_1
			or nRune == RUNE_POWERUP_2
			or (DotaTime() > 1 * 60 + 45 and nRune == RUNE_POWERUP_1)
			or (DotaTime() > 10 * 60 + 45 and nRune == RUNE_BOUNTY_2)
	else
		return nRune == RUNE_BOUNTY_2
			or nRune == RUNE_POWERUP_1
			or (DotaTime() > 1 * 60 + 45 and nRune == RUNE_POWERUP_2)
			or (DotaTime() > 10 * 60 + 45 and nRune == RUNE_BOUNTY_1)
	end
end


function X.IsHumanDangerPingedRune(nRune)
	local vRuneLoc = GetRuneSpawnLocation(nRune)
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local member = GetTeamMember(i)
		if member ~= nil and member:IsAlive() and not member:IsBot() then
			local ping = member:GetMostRecentPing()
			if ping ~= nil and not ping.normal_ping
			and Fu.GetDistance(ping.location, vRuneLoc) <= 400
			and GameTime() - ping.time < 30
			then
				return true
			end
		end
	end
	return false
end

function X.IsAllyWithBottleCloser(nRune)
	local vRuneLoc = GetRuneSpawnLocation(nRune)
	local myDist = GetUnitToLocationDistance(bot, vRuneLoc)
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local member = GetTeamMember(i)
		if member ~= nil and member ~= bot and Fu.IsValidHero(member)
		and member:FindItemSlot('item_bottle') >= 0
		and GetUnitToLocationDistance(member, vRuneLoc) < myDist
		then
			return true
		end
	end
	return false
end

function X.ShouldCheckRuneStatus(nRune)
	local status = GetRuneStatus(nRune)
	return status == RUNE_STATUS_AVAILABLE or status == RUNE_STATUS_UNKNOWN
end

function X.GetLaningRuneDesire(nCheckDist)
	-- 1) River runes (before 6 min, only near spawn times: every 2 min at 2:00, 4:00)
	-- Check 5s before spawn, stop 5s after if not found
	local currentMinute = math.floor(DotaTime() / 60)
	local currentSecond = DotaTime() % 60
	local bNearRiverSpawn = DotaTime() < 6 * 60
		and (currentMinute % 2 == 1 and currentSecond >= 55
			or currentMinute % 2 == 0 and currentSecond <= 5)
	if bNearRiverSpawn then
		local waterRunes = { RUNE_POWERUP_1, RUNE_POWERUP_2 }
		local closestWater = nil
		local closestWaterDist = nCheckDist
		for _, rune in pairs(waterRunes) do
			local runeStatus = GetRuneStatus(rune)
			if (runeStatus == RUNE_STATUS_AVAILABLE or runeStatus == RUNE_STATUS_UNKNOWN)
			and not X.IsHumanDangerPingedRune(rune)
			and not X.IsAllyWithBottleCloser(rune)
			then
				local dist = GetUnitToLocationDistance(bot, GetRuneSpawnLocation(rune))
				if dist < closestWaterDist then
					closestWater = rune
					closestWaterDist = dist
				end
			end
		end
		if closestWater ~= nil then
			if bot.rune and bot.rune.normal then
				bot.rune.normal.location = closestWater
				bot.rune.normal.distance = closestWaterDist
				bot.rune.normal.status = GetRuneStatus(closestWater)
				bot.rune.normal.type = GetRuneType(closestWater)
			end
			return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, closestWaterDist, 3200)
		end
	end

	-- 2) Role-based bounty for supports
	if botPos >= 4 then
		local myTeam = GetTeam()
		local targetBounty = nil
		if (myTeam == TEAM_RADIANT and botPos == 4) or (myTeam == TEAM_DIRE and botPos == 5) then
			targetBounty = RUNE_BOUNTY_1
		elseif (myTeam == TEAM_RADIANT and botPos == 5) or (myTeam == TEAM_DIRE and botPos == 4) then
			targetBounty = RUNE_BOUNTY_2
		end
		if targetBounty ~= nil
		and X.ShouldCheckRuneStatus(targetBounty)
		and not X.IsHumanDangerPingedRune(targetBounty)
		then
			local dist = GetUnitToLocationDistance(bot, GetRuneSpawnLocation(targetBounty))
			if dist < nCheckDist then
				if bot.rune and bot.rune.normal then
					bot.rune.normal.location = targetBounty
					bot.rune.normal.distance = dist
					bot.rune.normal.status = GetRuneStatus(targetBounty)
					bot.rune.normal.type = GetRuneType(targetBounty)
				end
				return X.GetScaledDesire(BOT_MODE_DESIRE_VERYHIGH, dist, 3500)
			end
		end
	end

	-- 3) General: closest available rune
	local closestRune = nil
	local closestDist = nCheckDist
	local allRunes = { RUNE_BOUNTY_1, RUNE_BOUNTY_2, RUNE_POWERUP_1, RUNE_POWERUP_2 }
	for _, rune in pairs(allRunes) do
		if X.ShouldCheckRuneStatus(rune)
		and not X.IsHumanDangerPingedRune(rune)
		and not X.IsAllyWithBottleCloser(rune)
		then
			local dist = GetUnitToLocationDistance(bot, GetRuneSpawnLocation(rune))
			if dist < closestDist then
				closestRune = rune
				closestDist = dist
			end
		end
	end
	if closestRune ~= nil then
		if bot.rune and bot.rune.normal then
			bot.rune.normal.location = closestRune
			bot.rune.normal.distance = closestDist
			bot.rune.normal.status = GetRuneStatus(closestRune)
			bot.rune.normal.type = GetRuneType(closestRune)
		end
		return X.GetScaledDesire(BOT_MODE_DESIRE_HIGH, closestDist, nCheckDist)
	end

	return 0
end

-- SafeCall wrapping for error protection
if SafeCall then
  local _origGetDesire = GetDesire
  local _origThink = Think
  if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'RUNE_GetDesire') end
  if _origThink then Think = SafeCall(_origThink, nil, 'RUNE_Think') end
end
