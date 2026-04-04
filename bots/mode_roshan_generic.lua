local bot = GetBot()
local botName = bot:GetUnitName();
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local Customize = require( GetScriptDirectory()..'/Customize/general' )

local killTime = 0.0
local shouldKillRoshan = false
local DoingRoshanMessage = DotaTime()

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
local ROSH_PING_DURATION = 30
local ROSH_COOLDOWN_NORMAL = 10 * 60
local ROSH_COOLDOWN_TURBO = 6 * 60

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end
	local res = GetDesireHelper()
	if res > 0.6 then Fu.ModeAnnounce(bot, 'say_roshan', 30) end
	return GetAdjustedDesireValue(res)
end
function GetDesireHelper()
	if bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end
    if Roshan == nil then
        local nCreeps = bot:GetNearbyNeutralCreeps(700)
        for _, creepOrRoshan in pairs(nCreeps)
        do
            if creepOrRoshan:GetUnitName() == "npc_dota_roshan"
            then
                Roshan = creepOrRoshan
            end
        end
    end

	-- 如果在打高地 就别撤退去干别的
	if Fu.Utils.IsTeamPushingSecondTierOrHighGround(bot) then
		return BOT_MODE_DESIRE_NONE
	end

	if Fu.GetEnemiesAroundAncient(bot, 3200) > 0 or Fu.GetHP(GetAncient(bot:GetTeam())) < 0.8 then
		return BOT_MODE_DESIRE_NONE
	end

    local timeOfDay = Fu.CheckTimeOfDay()

    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
    if nTeamFightLocation ~= nil
    then
        if timeOfDay == 'day'
        and GetUnitToLocationDistance(bot, Fu.Utils.RadiantRoshanLoc) < 1600
        and GetUnitToLocationDistance(bot, nTeamFightLocation) < 2000
        then
            return BOT_ACTION_DESIRE_NONE
        else
            if timeOfDay == 'night'
            and GetUnitToLocationDistance(bot, Fu.Utils.DireRoshanLoc) < 1600
            and GetUnitToLocationDistance(bot, nTeamFightLocation) < 2000
            then
                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    local lEnemyHeroesAroundLoc = Fu.GetLastSeenEnemiesNearLoc(bot:GetLocation(), 1200)
    if #lEnemyHeroesAroundLoc >= 2 then
        return BOT_ACTION_DESIRE_NONE
    end

    -- if Roshan is about to get killed, kill it unless there are other absolute actions.
    if Fu.Utils.IsValidUnit(Roshan) then
        local roshHP = Roshan:GetHealth() / Roshan:GetMaxHealth()
        if roshHP < 0.5 and #lEnemyHeroesAroundLoc == 0 then
            return RemapValClamped(roshHP, 100, 0, BOT_MODE_DESIRE_MODERATE, BOT_MODE_DESIRE_ABSOLUTE )
        end
    end

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
    -- Instead: ping to gather for 30s, then give up for a cooldown period.
    if hasHumanOnTeam then
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

    if Fu.HasEnoughDPSForRoshan(aliveHeroesList)
    then
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

    local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1300)
    if nEnemyHeroes ~= nil and #nEnemyHeroes > 0
    then
        return BOT_ACTION_DESIRE_NONE
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

        if hasSameOrMoreHero or (not hasSameOrMoreHero and Fu.HasEnoughDPSForRoshan(aliveHeroesList)) then
            return Clamp(nRoshanDesire, 0, 0.95)
        end
    end

    return BOT_ACTION_DESIRE_NONE
end
