local X = {}

local bot = GetBot()
local botName = bot:GetUnitName()
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local Localization = require( GetScriptDirectory()..'/FuncLib/systems/localization' )

local Tormentor = nil
local TormentorLocation = 0
local vWaitingLocation = 0

local tormentorMessageTime = 0
local canDoTormentor = false

if bot.tormentor_state == nil then bot.tormentor_state = false end
if bot.tormentor_kill_time == nil then bot.tormentor_kill_time = 0 end

local nCoreCountInLoc = 0
local nSuppCountInLoc = 0
local bHumanInTeam = false

local tormentorAttemptStart = 0
local tormentorGiveUpUntil = 0
local TORMENTOR_ATTEMPT_TIMEOUT = 60
local TORMENTOR_GIVEUP_COOLDOWN = 5 * 60

local nLastTorLog = 0

local fNextMovementTime = 0
local fStillAlive = 0
local bTormentorAlive = false

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end
	local res, reason = GetDesireHelper()

	if IsDebug and DotaTime() > 60 and DotaTime() > nLastTorLog + 15 then
		nLastTorLog = DotaTime()
		log('[TORMENTOR] %s t=%.0f desire=%.2f state=%s killTime=%.0f canDo=%s reason=%s',
			bot:GetUnitName(), DotaTime(), res,
			tostring(bot.tormentor_state), bot.tormentor_kill_time or 0, tostring(canDoTormentor),
			tostring(reason or 'none'))
	end

	return RemapValClamped(Fu.GetHP(bot), 0, 0.8, 0, res)
end

function GetDesireHelper()
	TormentorLocation = Fu.GetTormentorLocation(GetTeam())
	vWaitingLocation = Fu.GetTormentorWaitingLocation(GetTeam())

	local tAllyInTormentorLocation = Fu.GetAlliesNearLoc(TormentorLocation, 900)
	local tAllyInTormentorWaitLocation = Fu.GetAlliesNearLoc(vWaitingLocation, 900)
	local nAliveAlly = 0

	local nTormentorSpawnInterval = Fu.IsModeTurbo() and 5 or 10
	local nTormentorSpawnTime = Fu.IsModeTurbo() and 10 or 20

	local nHumanCountInLoc = 0
	local nAttackingTormentorCount = 0

	local nAveCoreLevel = 0
	local nAveSuppLevel = 0

	nCoreCountInLoc = 0
	nSuppCountInLoc = 0

	-- Gather team info
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if member ~= nil then
			local memberLevel = member:GetLevel()

			if member:IsAlive() then
				nAliveAlly = nAliveAlly + 1

				if not member:IsBot() then
					-- Human near tormentor: detect tormentor alive
					if bot.tormentor_state == false and Fu.IsValidHero(member) then
						if GetUnitToLocationDistance(member, TormentorLocation) <= 1300
						and IsLocationVisible(TormentorLocation)
						then
							local nNeutralCreeps = member:GetNearbyNeutralCreeps(1300)
							for j = #nNeutralCreeps, 1, -1 do
								if Fu.IsValid(nNeutralCreeps[j]) and string.find(nNeutralCreeps[j]:GetUnitName(), 'miniboss') then
									bot.tormentor_state = true
								end
							end
						end
					end

					if GetUnitToLocationDistance(member, TormentorLocation) <= 1600
					or GetUnitToLocationDistance(member, vWaitingLocation) <= 1600
					then
						nHumanCountInLoc = nHumanCountInLoc + 1
					end
				end

				-- Count bots attacking tormentor
				local memberTarget = Fu.GetProperTarget(member)
				if Fu.IsTormentor(memberTarget) and Fu.IsAttacking(member) then
					nAttackingTormentorCount = nAttackingTormentorCount + 1
				end

				if member.tormentor_team_healthy == nil then member.tormentor_team_healthy = false end
				if member.tormentor_team_healthy == true then
					bot.tormentor_team_healthy = true
				end

				if Fu.IsCore(member) then
					if GetUnitToLocationDistance(member, TormentorLocation) <= 900
					or GetUnitToLocationDistance(member, vWaitingLocation) <= 900
					then
						nCoreCountInLoc = nCoreCountInLoc + 1
					end
				else
					if GetUnitToLocationDistance(member, TormentorLocation) <= 900
					or GetUnitToLocationDistance(member, vWaitingLocation) <= 900
					then
						nSuppCountInLoc = nSuppCountInLoc + 1
					end
				end
			end

			-- Average levels: gate individual heroes at minimum threshold
			if Fu.IsCore(member) then
				if memberLevel < 13 then
					nAveCoreLevel = 0
				else
					nAveCoreLevel = nAveCoreLevel + memberLevel
				end
			else
				if memberLevel < 11 then
					nAveSuppLevel = 0
				else
					nAveSuppLevel = nAveSuppLevel + memberLevel
				end
			end

			-- Sync tormentor state across team
			if member.tormentor_state == true then
				bot.tormentor_state = true
			end

			-- Sync kill time
			if member.tormentor_kill_time ~= nil
			and member.tormentor_kill_time > 0
			and member.tormentor_kill_time > bot.tormentor_kill_time
			then
				bot.tormentor_kill_time = member.tormentor_kill_time
			end

			if not member:IsBot() and not bHumanInTeam then
				bHumanInTeam = true
			end
		end
	end

	-- Late game with no allies near: skip
	if #tAllyInTormentorLocation <= 1 and nHumanCountInLoc == 0
	and DotaTime() > (Fu.IsModeTurbo() and (25 * 60) or (40 * 60)) then
		return BOT_MODE_DESIRE_NONE, 'late_no_allies'
	end

	-- Near enemy ancient or doing Roshan: skip
	local hEnemyAncient = GetAncient(GetOpposingTeam())
	if #tAllyInTormentorLocation <= 1 and nHumanCountInLoc == 0
	and GetUnitToLocationDistance(bot, TormentorLocation) > 1600
	and (GetUnitToUnitDistance(bot, hEnemyAncient) < 4000
		and #Fu.GetEnemiesNearLoc(hEnemyAncient:GetLocation(), 4000) > 0
		or (Fu.IsDoingRoshan(bot) and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH)
	) then
		return BOT_MODE_DESIRE_NONE, 'near_enemy_ancient_or_rosh'
	end

	-- Enemies at our base or T3 fallen: skip
	if #Fu.GetEnemiesNearLoc(GetAncient(GetTeam()):GetLocation(), 2000) >= 2
	or (GetTower(GetTeam(), TOWER_TOP_3) == nil or GetTower(GetTeam(), TOWER_MID_3) == nil or GetTower(GetTeam(), TOWER_BOT_3) == nil)
	then
		return BOT_MODE_DESIRE_NONE, 'base_threatened'
	end

	nAveCoreLevel = nAveCoreLevel / 3
	nAveSuppLevel = nAveSuppLevel / 2

	-- Support level gate
	if nAveSuppLevel < 11 then
		return BOT_MODE_DESIRE_NONE, 'supp_lvl_low'
	end

	local bGoodRightClickDamage = X.IsGoodRighClickDamage()

	-- Scout phase: send closest bot to check if tormentor is alive
	if DotaTime() >= nTormentorSpawnTime * 60 and (DotaTime() - bot.tormentor_kill_time) >= nTormentorSpawnInterval * 60 then
		if not X.IsTormentorAlive() and bot.tormentor_state ~= true then
			if (nAveCoreLevel >= 13 and nAveSuppLevel >= 11)
			and GetUnitToUnitDistance(bot, hEnemyAncient) > 4000
			and GetUnitToLocationDistance(bot, TormentorLocation) <= 9200
			and bGoodRightClickDamage
			then
				local ally = nil
				local allyDist = 100000
				for i = 1, 5 do
					local member = GetTeamMember(i)
					if Fu.IsValidHero(member) and member:IsBot() then
						local memberDist = GetUnitToLocationDistance(member, TormentorLocation)
						if memberDist < allyDist and (not Fu.IsCore(member) or memberDist < 2800) then
							ally = member
							allyDist = memberDist
						end
					end
				end

				if ally ~= nil and bot == ally and bot.tormentor_state == false then
					if not bot:WasRecentlyDamagedByAnyHero(15) then
						return BOT_MODE_DESIRE_VERYHIGH, 'scout_go'
					end
				end
			end
		else
			bot.tormentor_state = true
		end
	else
		bot.tormentor_state = false
	end

	-- Tormentor attempt timeout: if spending > 60s without killing, give up for 5 min
	if DotaTime() < tormentorGiveUpUntil then
		bot.tormentor_state = false
		return BOT_MODE_DESIRE_NONE, 'tormentor_cooldown'
	end
	if bot.tormentor_state == true and tormentorAttemptStart == 0 then
		tormentorAttemptStart = DotaTime()
	end
	if tormentorAttemptStart > 0 and DotaTime() - tormentorAttemptStart > TORMENTOR_ATTEMPT_TIMEOUT then
		-- Took too long: mark tormentor as killed so ALL bots reset (syncs via tormentor_kill_time)
		local tor = nil
		local torCreeps = bot:GetNearbyNeutralCreeps(1600)
		for _, c in pairs(torCreeps) do
			if Fu.IsValid(c) and Fu.IsTormentor(c) then tor = c; break end
		end
		if tor == nil or Fu.GetHP(tor) > 0.3 then
			-- Set kill_time to force ALL bots to reset (they sync via tormentor_kill_time)
			bot.tormentor_kill_time = DotaTime()
			bot.tormentor_state = false
			bot.tormentor_team_healthy = false
			tormentorAttemptStart = 0
			canDoTormentor = false
			return BOT_MODE_DESIRE_NONE, 'tormentor_timeout'
		end
	end
	if bot.tormentor_state == false then
		tormentorAttemptStart = 0
	end

	-- Main tormentor desire: all conditions must be met
	if bot.tormentor_state == true
	and bGoodRightClickDamage
	and nAveCoreLevel >= 13
	and nAveSuppLevel >= 11
	and (not bHumanInTeam or (bHumanInTeam and X.DidHumanPingedOrAtLocation()))
	and (  (bot.tormentor_kill_time == 0 and nAliveAlly >= 5)
		or (bot.tormentor_kill_time == 0 and nAliveAlly >= 4 and nCoreCountInLoc >= 3 and nSuppCountInLoc >= 1)
		or (bot.tormentor_kill_time > 0 and nAliveAlly >= 3 and Fu.GetAliveAllyCoreCount() >= 2)
		or (nAttackingTormentorCount >= 2 and nCoreCountInLoc >= 2)
	) then
		-- Team health gate: first bot checks, then propagates
		if bot.tormentor_state == true and bot.tormentor_team_healthy == false and bot == Fu.GetFirstBotInTeam() then
			if X.IsTeamHealthy() then
				bot.tormentor_team_healthy = true
			end
		end

		if bot.tormentor_team_healthy == false then
			return BOT_MODE_DESIRE_NONE, 'team_not_healthy'
		end

		canDoTormentor = true

		-- Low HP bot backs off unless tormentor is low (< 15% or bot HP > tormentor HP)
		if Fu.GetHP(bot) < 0.3
		and not bot:HasModifier('modifier_item_crimson_guard_extra')
		and Fu.IsTormentor(Tormentor)
		then
			local torHP = Fu.GetHP(Tormentor)
			if torHP > 0.15 and Fu.GetHP(bot) < torHP then
				return BOT_MODE_DESIRE_NONE, 'bot_low_hp'
			end
		end

		local nDesire = BOT_MODE_DESIRE_VERYHIGH

		if (#tAllyInTormentorLocation >= 2 or #tAllyInTormentorWaitLocation >= 2)
		or nCoreCountInLoc >= 1
		or nSuppCountInLoc >= 2
		or nHumanCountInLoc >= 1 then
			nDesire = BOT_MODE_DESIRE_VERYHIGH
		else
			nDesire = BOT_MODE_DESIRE_HIGH
		end

		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

		return nDesire - (#nInRangeEnemy * (BOT_MODE_DESIRE_VERYHIGH / 5)), 'do_tormentor'
	end

	if bot.tormentor_state == false then
		bot.tormentor_team_healthy = false
	end

	canDoTormentor = false
	return BOT_MODE_DESIRE_NONE, 'state_false_or_conditions_unmet'
end

function Think()
	if Fu.CanNotUseAction(bot) then return end

	-- Farm lane creeps while walking to tormentor area
	if bot.tormentor_state == true and GetUnitToLocationDistance(bot, TormentorLocation) > 800 and GetUnitToLocationDistance(bot, TormentorLocation) < 1800 then
		local nLaneCreeps = bot:GetNearbyLaneCreeps(Min(1600, bot:GetAttackRange() + 300), true)
		if Fu.IsValid(nLaneCreeps[1])
		and Fu.CanBeAttacked(nLaneCreeps[1])
		then
			bot:Action_AttackUnit(nLaneCreeps[1], false)
			return
		end
	end

	-- Not enough allies gathered at waiting location: wait or scout
	if bot.tormentor_state == true and not X.IsEnoughAllies(vWaitingLocation, 1600) then
		-- Closest bot scouts tormentor location to confirm alive
		if X.GetClosestBot() == bot and DotaTime() > fStillAlive + 15.0 then
			if GetUnitToLocationDistance(bot, TormentorLocation) <= 350 then
				local nNeutralCreeps = bot:GetNearbyNeutralCreeps(900)
				for i = #nNeutralCreeps, 1, -1 do
					if Fu.IsValid(nNeutralCreeps[i]) and string.find(nNeutralCreeps[i]:GetUnitName(), 'miniboss') then
						fStillAlive = DotaTime()
						bTormentorAlive = true
					end
				end
				if not bTormentorAlive then
					bot.tormentor_kill_time = DotaTime()
					bot.tormentor_state = false
					bTormentorAlive = false
				end
			end

			bot:Action_MoveToLocation(TormentorLocation)
			return
		end

		-- Others wait at waiting location (NOT at tormentor)
		if DotaTime() >= fNextMovementTime then
			bot:Action_MoveToLocation(vWaitingLocation + RandomVector(300))
			fNextMovementTime = DotaTime() + RandomFloat(0.05, 0.2)
			return
		end
	else
		-- Enough allies gathered: move to tormentor
		if GetUnitToLocationDistance(bot, TormentorLocation) > bot:GetAttackRange() + 50 then
			bot:Action_MoveToLocation(TormentorLocation)
			return
		else
			local tCreeps = bot:GetNearbyNeutralCreeps(900)
			for _, c in pairs(tCreeps) do
				if Fu.IsValid(c) and string.find(c:GetUnitName(), 'miniboss') then
					Tormentor = c
					if GetUnitToUnitDistance(bot, c) > bot:GetAttackRange() + 50 then
						bot:Action_MoveDirectly(TormentorLocation)
						return
					else
						-- Only attack when enough allies at tormentor or tormentor HP < 25%
						if X.IsEnoughAllies(TormentorLocation, 900) or Fu.GetHP(c) < 0.25 then
							bot:Action_AttackUnit(c, true)
							return
						end
					end

					-- Ping team to gather
					if Fu.GetFirstBotInTeam() == bot and canDoTormentor and (DotaTime() > tormentorMessageTime + 15) then
						tormentorMessageTime = DotaTime()
						bot:ActionImmediate_Chat(Localization.Get('can_try_tormentor'), false)
						bot:ActionImmediate_Ping(c:GetLocation().x, c:GetLocation().y, true)
						return
					end
				end
			end
		end
	end
end

function X.IsTormentorAlive()
	if IsLocationVisible(TormentorLocation) then
		for i = 1, 5 do
			local member = GetTeamMember(i)
			if member ~= nil and member:IsAlive() then
				if GetUnitToLocationDistance(member, TormentorLocation) <= 350 then
					local nNeutralCreeps = member:GetNearbyNeutralCreeps(900)
					for j = #nNeutralCreeps, 1, -1 do
						if Fu.IsValid(nNeutralCreeps[j]) and string.find(nNeutralCreeps[j]:GetUnitName(), 'miniboss') then
							return true
						end
					end

					member.tormentor_kill_time = DotaTime()
				end
			end
		end
	end

	return false
end

function X.IsEnoughAllies(vLocation, nRadius)
	local nAllyCount = 0
	local nCoreCountInLoc2 = 0
	local nSuppCountInLoc2 = 0
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if member ~= nil and member:IsAlive() then
			if GetUnitToLocationDistance(member, vLocation) <= nRadius then
				nAllyCount = nAllyCount + 1
				if Fu.IsCore(member) then
					nCoreCountInLoc2 = nCoreCountInLoc2 + 1
				else
					nSuppCountInLoc2 = nSuppCountInLoc2 + 1
				end
			end
		end
	end

	return ((bot.tormentor_kill_time == 0 and nAllyCount >= 5)
		 or (bot.tormentor_kill_time == 0 and nAllyCount >= 4 and nCoreCountInLoc2 >= 3 and nSuppCountInLoc2 >= 1)
		 or (bot.tormentor_kill_time > 0 and nAllyCount >= 3))
	and nCoreCountInLoc2 >= 2
end

function X.GetClosestBot()
	local hUnitList = Fu.GetAlliesNearLoc(vWaitingLocation, 2800)
	local hTarget = nil
	local hTargetDistance = math.huge
	for _, unit in pairs(hUnitList) do
		if Fu.IsValidHero(unit) and GetUnitToLocationDistance(unit, TormentorLocation) < 2000 then
			local unitDistance = GetUnitToLocationDistance(unit, TormentorLocation)
			if hTargetDistance > unitDistance * (1 - Fu.GetHP(unit)) then
				hTargetDistance = unitDistance
				hTarget = unit
			end
		end
	end

	return hTarget
end

function X.IsTeamHealthy()
	local nHealthyAlly = 0
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if Fu.IsValid(member) and (Fu.GetHP(member) > 0.5 or not member:IsBot()) then
			nHealthyAlly = nHealthyAlly + 1
		end
	end

	return nHealthyAlly >= Fu.GetNumOfAliveHeroes(false)
end

-- Right-click DPS threshold check
local tTeamDamage = {}
local fThresholdChatTime = 0
function X.IsGoodRighClickDamage()
	if bot.tormentor_kill_time > 0 then return true end

	for i = 1, 5 do
		local member = GetTeamMember(i)
		if member ~= nil
		and member:CanBeSeen()
		and Fu.IsCore(member)
		and not Fu.DoesUnitHaveTemporaryBuff(member)
		then
			local memberPosition = Fu.GetPosition(member)
			local attackDamage = member:GetAttackDamage() * member:GetAttackSpeed()
			if memberPosition == 1 then
				attackDamage = attackDamage * 0.50
			elseif memberPosition == 2 then
				attackDamage = attackDamage * 0.25
			elseif memberPosition == 3 then
				attackDamage = attackDamage * 0.25
			end

			local id = member:GetPlayerID()
			if tTeamDamage[id] == nil then tTeamDamage[id] = 0 end
			if tTeamDamage[id] < attackDamage then
				tTeamDamage[id] = attackDamage
			end
		end
	end

	local totalAttackDamage = 0
	for _, damage in pairs(tTeamDamage) do totalAttackDamage = totalAttackDamage + damage end

	if not Fu.IsDoingTormentor(bot) and Fu.GetFirstBotInTeam() == bot and bot.tormentor_state == true and DotaTime() - fThresholdChatTime < 30 and totalAttackDamage >= 500.0 then
		bot:ActionImmediate_Chat("Tormentor threshold met..", false)
		fThresholdChatTime = DotaTime()
	end

	return totalAttackDamage >= 500.0
end

local bHumanPinged = false
function X.DidHumanPingedOrAtLocation()
	local human, ping = Fu.GetHumanPing()
	if bot.tormentor_state == true and human and ping and not bHumanPinged then
		if Fu.GetDistance(ping.location, vWaitingLocation) <= 800
		or Fu.GetDistance(ping.location, TormentorLocation) <= 800
		then
			if GameTime() < ping.time + 15 then
				bHumanPinged = true
			end
		end
	end

	if bot.tormentor_state == false then
		bHumanPinged = false
	elseif bot.tormentor_state == true and bHumanPinged then
		return true
	end

	return false
end

-- SafeCall wrapping for error protection
if SafeCall then
	local _origGetDesire = GetDesire
	local _origThink = Think
	if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'WATCHER_GetDesire') end
	if _origThink then Think = SafeCall(_origThink, nil, 'WATCHER_Think') end
end
