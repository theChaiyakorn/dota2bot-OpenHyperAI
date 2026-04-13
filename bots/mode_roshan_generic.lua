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
	-- Cap at VERYHIGH (0.6) like reference — no 0.7 scaling
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

	-- Reduce Roshan desire while team is pushing high ground (but don't hard-block —
	-- let desire system decide. Roshan after a won fight is often better than pushing into T3).
	local bPushingHG = Fu.Utils.IsTeamPushingSecondTierOrHighGround(bot)

	-- Don't Roshan if enemies are threatening our base
	if Fu.GetEnemiesAroundAncient(bot, 2000) > 2 or Fu.GetHP(GetAncient(bot:GetTeam())) < 0.6 then
		return BOT_MODE_DESIRE_NONE
	end

	local roshLoc = Fu.GetCurrentRoshanLocation()
	local nTeam = GetTeam()
	local aliveEnemy = Fu.GetNumOfAliveHeroes(true)

	-- Check if enemies are currently near our T3/HG — if so, don't Roshan
	-- This is a live check (not a timer), so it clears as soon as enemies leave or die
	if aliveEnemy >= 2 then
		local bEnemiesNearOurT3 = false
		local t3Towers = {
			GetTower(nTeam, TOWER_TOP_3), GetTower(nTeam, TOWER_MID_3), GetTower(nTeam, TOWER_BOT_3),
		}
		for _, tower in pairs(t3Towers) do
			if Fu.IsValidBuilding(tower) then
				local enemiesNearT3 = Fu.GetLastSeenEnemiesNearLoc(tower:GetLocation(), 2500)
				if #enemiesNearT3 >= 2 then
					bEnemiesNearOurT3 = true
					break
				end
			end
		end
		local ancientLoc = GetAncient(nTeam):GetLocation()
		if Fu.Utils.CountEnemyHeroesNear(ancientLoc, 3000) >= 2 then
			bEnemiesNearOurT3 = true
		end
		if bEnemiesNearOurT3 then
			return BOT_MODE_DESIRE_NONE
		end
	end

	-- Teamfight near Roshan pit — don't start
	local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
	if nTeamFightLocation ~= nil
	and Fu.Utils.GetLocationToLocationDistance(roshLoc, nTeamFightLocation) < 2500
	then
		return BOT_ACTION_DESIRE_NONE
	end

	-- Enemies camping Roshan pit
	local nEnemiesAtPit = Fu.GetLastSeenEnemiesNearLoc(roshLoc, 2000)
	if #nEnemiesAtPit >= 2 then
		local nAlliesAtPit = Fu.GetAlliesNearLoc(roshLoc, 2500)
		if #nAlliesAtPit < #nEnemiesAtPit then
			return BOT_ACTION_DESIRE_NONE
		end
	end

	-- If Roshan is being fought (HP dropping), commit — don't abandon mid-fight
	-- Return high raw values since GetDesire applies * 0.7
	if Fu.Utils.IsValidUnit(Roshan) then
		local roshHP = Roshan:GetHealth() / Roshan:GetMaxHealth()
		if roshHP < 0.8 and #nEnemiesAtPit == 0 then
			return RemapValClamped(roshHP, 0.8, 0.0, 0.9, 1.0)
		end
	end

	-- If team is already gathered near pit, boost desire so bots commit and don't waver
	local nAlliesNearRosh = Fu.GetAlliesNearLoc(roshLoc, ROSH_GATHER_RADIUS + ROSH_GATHER_DIST)
	local nGatheredCount = 0
	for _, ally in pairs(nAlliesNearRosh) do
		if Fu.IsValidHero(ally) and ally:IsAlive() and not ally:IsIllusion() then
			nGatheredCount = nGatheredCount + 1
		end
	end
	local bTeamGathered = nGatheredCount >= GetRequiredAlliesForRoshan()

    local aliveAlly = Fu.GetNumOfAliveHeroes(false)
    local aliveEnemy = Fu.GetNumOfAliveHeroes(true)
    local hasSameOrMoreHero = aliveAlly >= aliveEnemy

    if not hasSameOrMoreHero then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCoreWithNoEmptySlot = 0
    local aliveHeroesList = {}
    for _, h in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
        if h:IsAlive()
        then
            if Fu.Utils.CountBackpackEmptySpace(h) <= 0 and Fu.IsCore(h) then
                nCoreWithNoEmptySlot = nCoreWithNoEmptySlot + 1
            end

            -- do not take rosh if the cores do not have any empty slot, it may get dropped on ground.
            if nCoreWithNoEmptySlot >= 2 then
                return BOT_ACTION_DESIRE_NONE
            end
            table.insert(aliveHeroesList, h)
        end
    end

    -- Detect human on team (cache once)
    if hasHumanOnTeam == nil then
        hasHumanOnTeam = Fu.Utils.IsHumanPlayerInTeam(GetTeam())
    end

    -- Human team Roshan flow:
    -- Bots can't properly enter pit with Valve's Think when human is on team.
    -- In early game, don't attempt Roshan at all with humans — too risky without coordination.
    -- Instead: ping to gather for 30s, then give up for a cooldown period.
    if hasHumanOnTeam then
        if Fu.IsEarlyGame() then
            return BOT_ACTION_DESIRE_NONE
        end

        -- On cooldown — skip Roshan entirely
        if DotaTime() < roshCooldownUntil then
            return BOT_ACTION_DESIRE_NONE
        end

        -- If human pinged Roshan, let bots respond normally (handled below at line ~149)
        local human, humanPing = Fu.GetHumanPing()
        local humanPingedRosh = human ~= nil and humanPing ~= nil
            and humanPing.normal_ping
            and Fu.GetDistance(humanPing.location, Fu.GetCurrentRoshanLocation()) < 600
            and DotaTime() < humanPing.time + 5.0

        if not humanPingedRosh then
            -- Bot wants Roshan but human hasn't responded
            if Fu.IsRoshanAlive() and initDPSFlag and hasSameOrMoreHero then
                if roshPingStartTime == 0 then
                    -- Start pinging phase
                    roshPingStartTime = DotaTime()
                end

                local timePinging = DotaTime() - roshPingStartTime
                if timePinging < ROSH_PING_DURATION then
                    -- Ping and announce during the 30s window
                    Fu.ModeAnnounce(bot, 'say_roshan', 10)
                    return BOT_MODE_DESIRE_MODERATE -- Keep desire moderate to signal intent
                else
                    -- 30s passed, human didn't join — give up
                    roshPingStartTime = 0
                    local cooldown = Fu.IsModeTurbo() and ROSH_COOLDOWN_TURBO or ROSH_COOLDOWN_NORMAL
                    roshCooldownUntil = DotaTime() + cooldown
                    return BOT_MODE_DESIRE_NONE
                end
            else
                roshPingStartTime = 0 -- Reset if conditions no longer met
            end
        else
            -- Human pinged Roshan — reset cooldown and let normal logic handle
            roshPingStartTime = 0
            roshCooldownUntil = 0
        end
    end

    shouldKillRoshan = Fu.IsRoshanAlive()

    if shouldKillRoshan
    and not roshTimeFlag
    then
        sinceRoshAliveTime = DotaTime()
        roshTimeFlag = true
    else
        if not shouldKillRoshan
        then
            sinceRoshAliveTime = 0
            roshTimeFlag = false
        end
    end

    if Fu.HasEnoughDPSForRoshan(aliveHeroesList) then
        initDPSFlag = true
    end

    if Fu.IsRoshanCloseToChangingSides()
    then
        local botTarget = Fu.GetProperTarget(bot)
        if Fu.IsRoshan(botTarget) then
            return RemapValClamped(Fu.GetHP(botTarget), 1, 0, BOT_ACTION_DESIRE_NONE, BOT_ACTION_DESIRE_VERYHIGH )
        end
        if not Fu.IsValid(botTarget) or not Fu.IsRoshan(botTarget) then
            return BOT_ACTION_DESIRE_NONE
        end
    end

    if shouldKillRoshan
    and initDPSFlag
    then
        local human, humanPing = Fu.GetHumanPing()
        if human ~= nil and DotaTime() > 5.0 then
            if humanPing ~= nil
            and humanPing.normal_ping
            and GetUnitToLocationDistance(human, Fu.GetCurrentRoshanLocation()) < 4500
            and Fu.GetDistance(humanPing.location, Fu.GetCurrentRoshanLocation()) < 600
            and DotaTime() < humanPing.time + 5.0
            then
                return 0.95
            end
        end

        local mul = RemapValClamped(DotaTime(), sinceRoshAliveTime, sinceRoshAliveTime + (2.5 * 60), 1, 2)
        local nRoshanDesire = (GetRoshanDesire() * mul)

        -- If defend desire is very high (active base threat) AND we haven't gathered, suppress
        local maxDefendDesire = math.max(GetDefendLaneDesire(LANE_TOP), GetDefendLaneDesire(LANE_MID), GetDefendLaneDesire(LANE_BOT))
        if maxDefendDesire > 0.75 and not bTeamGathered then
            return BOT_ACTION_DESIRE_NONE
        end

        if hasSameOrMoreHero or (not hasSameOrMoreHero and Fu.HasEnoughDPSForRoshan(aliveHeroesList)) then
            local finalDesire = nRoshanDesire
            -- Team gathered near pit: high desire so all bots commit
            if bTeamGathered then
                finalDesire = math.max(finalDesire, 0.85)
            end
            -- Reduce if team is actively pushing HG (but don't zero — Rosh may be better)
            if bPushingHG and not bTeamGathered then
                finalDesire = finalDesire * 0.6
            end
            return Clamp(finalDesire, 0, 0.95)
        end
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
