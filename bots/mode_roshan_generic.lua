local bot = GetBot()
local botName = bot:GetUnitName();
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local Customize = require( GetScriptDirectory()..'/Customize/general' )

local killTime = 0.0
local shouldKillRoshan = false
local DoingRoshanMessage = DotaTime()

-- Shared state across all bots
Fu.Utils.GameStates = Fu.Utils.GameStates or {}
Fu.Utils.GameStates.roshHandle = Fu.Utils.GameStates.roshHandle or nil

-- local rTwinGate = nil
-- local dTwinGate = nil
-- local rTwinGateLoc = Vector(5888, -7168, 256)
-- local dTwinGateLoc = Vector(6144, 7552, 256)

local sinceRoshAliveTime = 0
local roshTimeFlag = false
local initDPSFlag = false

local Roshan

-- Human team Roshan handling:
-- If human on team, bots stay outside pit (Valve Think behavior).
-- Instead: ping for 30s asking human to join, then drop desire for 10min/6min.
local hasHumanOnTeam = nil
local roshPingStartTime = 0
local roshCooldownUntil = 0
local ROSH_PING_DURATION = 15
local ROSH_COOLDOWN_NORMAL = 3 * 60
local ROSH_COOLDOWN_TURBO = 2 * 60

-- Roshan HP dip: when bot HP drops below threshold while being Roshan's target,
-- back off briefly so Roshan retargets another ally, then re-engage.
-- Uses a cooldown to prevent re-triggering the dip repeatedly.
local roshDipUntil = 0
local roshDipCooldown = 0     -- don't re-trigger dip until this time
local ROSH_DIP_DURATION = 1.5 -- seconds to back off so Rosh retargets
local ROSH_DIP_COOLDOWN = 8   -- seconds before same bot can dip again

local function DampenByBotHP(desire)
	if desire <= 0 then return desire end
	if botName == "npc_dota_hero_huskar" then return desire end

	local botHP = Fu.GetHP(bot)
	local roshBeingFought = Fu.Utils.IsValidUnit(Roshan) and Fu.GetHP(Roshan) < 0.9

	-- If being ganked by enemy heroes near Roshan, suppress desire — but not mid-fight
	if bot:WasRecentlyDamagedByAnyHero(2.0) and botHP < 0.4 and not roshBeingFought then
		return desire * RemapValClamped(botHP, 0.1, 0.4, 0.0, 0.5)
	end

	-- HP dip: only trigger for the bot that Roshan is actually hitting,
	-- and only once per cooldown window to prevent infinite back-and-forth.
	local isRoshTarget = Fu.Utils.IsValidUnit(Roshan)
		and Roshan:GetAttackTarget() == bot
	local nearRosh = Fu.Utils.IsValidUnit(Roshan)
		and GetUnitToUnitDistance(bot, Roshan) < 600

	if botHP < 0.5 and isRoshTarget and DotaTime() > roshDipCooldown then
		roshDipUntil = DotaTime() + ROSH_DIP_DURATION
		roshDipCooldown = DotaTime() + ROSH_DIP_COOLDOWN
	end

	bot._roshDipActive = DotaTime() < roshDipUntil

	-- Keep desire high so Roshan mode stays active during the fight
	if roshBeingFought and (bot._roshDipActive or nearRosh) then
		return math.max(desire, BOT_MODE_DESIRE_HIGH)
	end

	return desire
end

local nLastRoshLog = 0
local nLastRoshDiag = 0
function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end
	local res = GetDesireHelper()
	-- Diagnostic: per-bot local throttle, every 15s after 3min
	if DotaTime() > 3 * 60 and DotaTime() > nLastRoshDiag + 15 then
		nLastRoshDiag = DotaTime()
		local final = Clamp(DampenByBotHP(res), 0, BOT_MODE_DESIRE_VERYHIGH)
		log(string.format('[ROSH] t=%.0f %s raw=%.2f final=%.2f alive=%s dps=%s kill=%s hg=%s eA=%d aA=%d',
			DotaTime(), string.gsub(bot:GetUnitName(), 'npc_dota_hero_', ''),
			res, final,
			tostring(Fu.IsRoshanAlive()), tostring(initDPSFlag), tostring(shouldKillRoshan),
			tostring(Fu.Utils.IsTeamPushingSecondTierOrHighGround(bot)),
			Fu.GetNumOfAliveHeroes(true), Fu.GetNumOfAliveHeroes(false)
		))
	end
	res = DampenByBotHP(res)
	if res > 0.4 then Fu.ModeAnnounce(bot, 'say_roshan', 30) end
	-- Cap at VERYHIGH (0.6)
	return Clamp(res, 0, BOT_MODE_DESIRE_VERYHIGH)
end
-- How many allies need to be near the pit before we engage Roshan.
local function GetRequiredAlliesForRoshan()
	if Fu.IsLateGame() then
		return Fu.IsCore(bot) and 1 or 2
	elseif Fu.IsMidGame() then
		return 3
	else
		return 4
	end
end

-- Try to find Roshan handle: check local, then shared, then scan nearby
local function FindRoshan()
	-- Use shared handle if valid
	local shared = Fu.Utils.GameStates.roshHandle
	if Fu.Utils.IsValidUnit(shared) then
		Roshan = shared
		return
	end
	-- Scan nearby neutral creeps
	local nCreeps = bot:GetNearbyNeutralCreeps(1600)
	for _, c in pairs(nCreeps) do
		if c:GetUnitName() == "npc_dota_roshan" then
			Roshan = c
			Fu.Utils.GameStates.roshHandle = c
			return
		end
	end
end

function GetDesireHelper()
	if bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
	if not Fu.Utils.IsValidUnit(Roshan) then
		FindRoshan()
	end

	local roshLoc = Fu.GetCurrentRoshanLocation()
	local nTeam = GetTeam()
	local aliveAlly = Fu.GetNumOfAliveHeroes(false)
	local aliveEnemy = Fu.GetNumOfAliveHeroes(true)

	-- Build alive heroes list for DPS check
	local aliveHeroesList = {}
	for _, h in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
		if h:IsAlive() then
			table.insert(aliveHeroesList, h)
		end
	end

	-- Track Roshan alive time for desire multiplier
	shouldKillRoshan = Fu.IsRoshanAlive()
	if shouldKillRoshan and not roshTimeFlag then
		sinceRoshAliveTime = DotaTime()
		roshTimeFlag = true
	elseif not shouldKillRoshan then
		sinceRoshAliveTime = 0
		roshTimeFlag = false
	end

	if Fu.HasEnoughDPSForRoshan(aliveHeroesList) then
		initDPSFlag = true
	end

	-- Don't Roshan if enemies are threatening our base
	if Fu.GetEnemiesAroundAncient(bot, 2000) > 2 or Fu.GetHP(GetAncient(bot:GetTeam())) < 0.6 then
		return BOT_MODE_DESIRE_NONE
	end

	-- If Roshan is being fought (HP dropping), commit — don't abandon mid-fight
	if Fu.Utils.IsValidUnit(Roshan) then
		local roshHP = Roshan:GetHealth() / Roshan:GetMaxHealth()
		if roshHP < 0.8 then
			return RemapValClamped(roshHP, 0.8, 0.0, 0.9, 1.0)
		end
	end

	-- Must have at least as many allies alive as enemies
	if aliveAlly < aliveEnemy then
		return BOT_ACTION_DESIRE_NONE
	end

	-- Detect human on team (cache once)
	if hasHumanOnTeam == nil then
		hasHumanOnTeam = Fu.Utils.IsHumanPlayerInTeam(GetTeam())
	end

	-- Human team: ping to gather, then cooldown if they don't join
	if hasHumanOnTeam then
		if Fu.IsEarlyGame() then return BOT_ACTION_DESIRE_NONE end
		if DotaTime() < roshCooldownUntil then return BOT_ACTION_DESIRE_NONE end

		local human, humanPing = Fu.GetHumanPing()
		local humanPingedRosh = human ~= nil and humanPing ~= nil
			and humanPing.normal_ping
			and Fu.GetDistance(humanPing.location, Fu.GetCurrentRoshanLocation()) < 600
			and DotaTime() < humanPing.time + 5.0

		if not humanPingedRosh then
			if Fu.IsRoshanAlive() and initDPSFlag then
				if roshPingStartTime == 0 then roshPingStartTime = DotaTime() end
				local timePinging = DotaTime() - roshPingStartTime
				if timePinging < ROSH_PING_DURATION then
					Fu.ModeAnnounce(bot, 'say_roshan', 10)
					return BOT_MODE_DESIRE_MODERATE
				else
					roshPingStartTime = 0
					roshCooldownUntil = DotaTime() + (Fu.IsModeTurbo() and ROSH_COOLDOWN_TURBO or ROSH_COOLDOWN_NORMAL)
					return BOT_MODE_DESIRE_NONE
				end
			else
				roshPingStartTime = 0
			end
		else
			roshPingStartTime = 0
			roshCooldownUntil = 0
		end
	end

	if shouldKillRoshan and initDPSFlag then
		-- Human pinged Roshan: max desire
		local human, humanPing = Fu.GetHumanPing()
		if human ~= nil and DotaTime() > 5.0 then
			if humanPing ~= nil and humanPing.normal_ping
			and GetUnitToLocationDistance(human, roshLoc) < 4500
			and Fu.GetDistance(humanPing.location, roshLoc) < 600
			and DotaTime() < humanPing.time + 5.0
			then
				return 0.95
			end
		end

		if DotaTime() < (Fu.IsModeTurbo() and 15 * 60 or 20 * 60) then
			return BOT_MODE_DESIRE_NONE
		end

		-- Core desire: Valve's GetRoshanDesire scaled by time since Roshan spawned
		local mul = RemapValClamped(DotaTime(), sinceRoshAliveTime, sinceRoshAliveTime + (2.5 * 60), 1, 2)
		local nRoshanDesire = RemapValClamped(GetRoshanDesire() * mul, 0, 1, 0, BOT_MODE_DESIRE_ABSOLUTE)

		-- 4+ allies near pit: override to high desire (like reference)
		local nAlliesNearRosh = Fu.GetAlliesNearLoc(roshLoc, 1600)
		if #nAlliesNearRosh >= 4 then
			nRoshanDesire = 0.9
		end

		-- Reduce (not block) if actively pushing HG
		local bPushingHG = Fu.Utils.IsTeamPushingSecondTierOrHighGround(bot)
		if bPushingHG and #nAlliesNearRosh < 3 then
			nRoshanDesire = nRoshanDesire * 0.6
		end

		return Clamp(nRoshanDesire, 0, BOT_MODE_DESIRE_VERYHIGH)
	end

	return BOT_ACTION_DESIRE_NONE
end

local ROSH_GATHER_RADIUS = 1000  -- how close counts as "gathered"
local ROSH_GATHER_DIST   = 900 -- wait this far from pit center (outside pit)
local ROSH_PIT_RADIUS    = 200   -- must be within this distance of roshLoc to count as "inside pit"

function Think()
	if not bot:IsAlive() or Fu.CanNotUseAction(bot) then return end

	local roshLoc = Fu.GetCurrentRoshanLocation()
	if roshLoc == nil then return end

	-- HP dip: back off briefly so Roshan retargets another ally
	if bot._roshDipActive then
		-- Move away from Roshan but stay near pit (not 500 units away)
		local awayDir = Fu.AdjustLocationWithOffsetTowardsFountain(roshLoc, 300)
		bot:Action_MoveToLocation(awayDir)
		return
	end

	-- Find Roshan handle (shared across team)
	if not Fu.Utils.IsValidUnit(Roshan) then
		FindRoshan()
	end

	local distToRosh = GetUnitToLocationDistance(bot, roshLoc)
	local insidePit = distToRosh <= ROSH_PIT_RADIUS
	local roshBeingAttacked = Fu.Utils.IsValidUnit(Roshan) and Fu.GetHP(Roshan) < 0.9

	-- Helper: walk into pit center (used by multiple phases)
	local function EnterPit()
		bot:Action_MoveToLocation(roshLoc)
	end

	-- Helper: attack Roshan (only if inside pit)
	local function AttackRoshan()
		if insidePit and Fu.Utils.IsValidUnit(Roshan) and Fu.CanBeAttacked(Roshan) then
			bot:Action_AttackUnit(Roshan, true)
		else
			EnterPit()
		end
	end

	-- If Roshan is already being fought (HP < 90%), skip gather — enter pit and attack
	if roshBeingAttacked then
		AttackRoshan()
		return
	end

	-- Count gathered allies near gather point
	local gatherPoint = Fu.AdjustLocationWithOffsetTowardsFountain(roshLoc, ROSH_GATHER_DIST)
	local alliesNearGather = Fu.GetAlliesNearLoc(gatherPoint, ROSH_GATHER_RADIUS)
	local alliesCount = 0
	for _, ally in pairs(alliesNearGather) do
		if Fu.IsValidHero(ally) and ally:IsAlive() and not ally:IsIllusion() then
			alliesCount = alliesCount + 1
		end
	end

	local requiredAllies = GetRequiredAlliesForRoshan()
	local distToGather = GetUnitToLocationDistance(bot, gatherPoint)

	-- PHASE 1: GATHER outside pit — wait for team
	if alliesCount < requiredAllies then
		if distToGather > 50 then
			bot:Action_MoveToLocation(gatherPoint + RandomVector(100))
		end
		if DotaTime() > (bot._lastRoshGatherPing or 0) + 8 then
			bot._lastRoshGatherPing = DotaTime()
			Fu.ModeAnnounce(bot, 'say_roshan', 8)
		end
		return
	end

	-- PHASE 2: ENTER pit — enough allies gathered, walk into pit
	-- Must reach within ROSH_PIT_RADIUS of roshLoc before attacking
	if not insidePit then
		EnterPit()
		return
	end

	-- PHASE 3: ATTACK — inside pit, hit Roshan
	if Fu.Utils.IsValidUnit(Roshan) and Fu.CanBeAttacked(Roshan) then
		bot:Action_AttackUnit(Roshan, true)
	else
		-- Roshan not visible yet, walk around pit center to find him
		bot:Action_MoveToLocation(roshLoc + RandomVector(50))
	end
end
