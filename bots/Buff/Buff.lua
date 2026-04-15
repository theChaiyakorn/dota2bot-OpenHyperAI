-- Install global `log(fmt, ...)` for this (Buff) sandbox. Must be required
-- before any log(...) call. Buff has no existing debug flag and previously
-- printed unconditionally, so default IsDebug=true here to preserve behavior.
require('bots/FuncLib/systems/log')
IsDebug = true
-- Version information
local Version = require 'bots.FuncLib.systems.version'
if GetScriptDirectory == nil then GetScriptDirectory = function() return "bots" end end
-- Print version to console
log('Starting Buff. Version: %s', Version.number)

-- Bust require cache so script_reload_code picks up edits to submodules.
if package and package.loaded then
    package.loaded['bots/Buff/Timers']       = nil
    package.loaded['bots/Buff/Experience']   = nil
    package.loaded['bots/Buff/GPM']          = nil
    package.loaded['bots/Buff/NeutralItems'] = nil
    package.loaded['bots/Buff/Helper']       = nil
    package.loaded['bots.Buff.Timers']       = nil
    package.loaded['bots.Buff.Experience']   = nil
    package.loaded['bots.Buff.GPM']          = nil
    package.loaded['bots.Buff.NeutralItems'] = nil
    package.loaded['bots.Buff.Helper']       = nil
end

require('bots/Buff/Timers')
require('bots/Buff/Experience')
require('bots/Buff/GPM')
require('bots/Buff/NeutralItems')
require('bots/Buff/Helper')
local Chat = require('bots.FretBots.Chat')

local InitTimerName = 'InitTimer'
local initDelay = 0
local initDelayDuration = 5

if Buff == nil
then
    Buff = {}
end

local Colors =
{
	good				= '#00ff00',
	warning			= '#fbff00',
	bad					= '#ff0000',
	consoleGood = '#1ce8b5',
	consoleBad  = '#e68d39',
}

local botTable = {
    [DOTA_TEAM_GOODGUYS]    = {},
    [DOTA_TEAM_BADGUYS]     = {}
}

function Buff:AddBotsToTable()
    for nTeam = 0, 3 do
        local pNum = PlayerResource:GetPlayerCountForTeam(nTeam)
        for i = 0, pNum do
            local playerID = PlayerResource:GetNthPlayerIDOnTeam(nTeam, i)
            local player = PlayerResource:GetPlayer(playerID)
            -- local connectionState = PlayerResource:GetConnectionState(playerID)
            -- log('Setting up Buff for player: '..playerID..', connection state: '..tostring(connectionState))
            if player then
                local hero = player:GetAssignedHero()
                local team = player:GetTeam()
                if hero ~= nil then
                    if PlayerResource:GetSteamID(hero:GetMainControllingPlayer()) == PlayerResource:GetSteamID(100) then
                        -- log('Instering bot player: '..hero:GetUnitName()..', to team: '..team)
                        table.insert(botTable[team], hero)
                    end
                else
                    -- log('[WARN] Failed to add player '.. playerID .. ' to bots list. Spectator?')
                end
            else
                -- log('[WARN] Failed to add player '.. playerID .. ' to bots list. Spectator?')
            end
        end
    end
end

function Buff:Init()
    local turbo = Helper.IsTurboMode()
    log('[Buff][Init] tick: IsTurboMode=%s, GameState=%s, initDelay=%s', tostring(turbo), tostring(GameRules:State_Get()), tostring(initDelay))
    if turbo == nil then
        log('[Buff][Init] courier not found yet -- retrying')
        return 1
    end

    if initDelay < initDelayDuration then
        if GameRules:State_Get() > 6 then initDelay = initDelay + 1 end
        log('[Buff][Init] waiting for heroes to load (initDelay=%s/%s)', tostring(initDelay), tostring(initDelayDuration))
        return 1
    end
    Timers:RemoveTimer(InitTimerName)
    log('[Buff][Init] Initing Buff... (turbo=%s)', tostring(turbo))

    Buff:AddBotsToTable()
    local TeamRadiant = botTable[DOTA_TEAM_GOODGUYS]
    local TeamDire = botTable[DOTA_TEAM_BADGUYS]
    log('[Buff][Init] Number of bots in TeamRadiant: %s', #TeamRadiant)
    log('[Buff][Init] Number of bots in TeamDire: %s', #TeamDire)

    Chat:SendHttpRequest('start', Utilities:GetPInfo(), Chat.StartCallback)
    log('[Buff][Init] scheduling gold/xp tick timer')
    local tickCount = 0
    Timers:CreateTimer(function()
        tickCount = tickCount + 1
        local turboNow = Helper.IsTurboMode()
        if tickCount <= 5 or tickCount % 30 == 0 then
            log('[Buff][Tick] #%s turbo=%s radiant=%s dire=%s', tostring(tickCount), tostring(turboNow), #TeamRadiant, #TeamDire)
        end

        local function safeStep(label, fn)
            local ok, err = pcall(fn)
            if not ok then
                log('[Buff][Tick][ERR] %s: %s', label, tostring(err))
            end
        end

        safeStep('NeutralItems.GiveNeutralItems', function()
            NeutralItems.GiveNeutralItems(TeamRadiant, TeamDire)
        end)

        if not turboNow
        then
            for _, h in pairs(TeamRadiant) do
                if Helper.IsCore(h, TeamRadiant)
                then
                    safeStep('GPM Radiant '..tostring(h:GetUnitName()), function() GPM.UpdateBotGold(h) end)
                    if tickCount <= 3 then
                        log('[Buff][Tick] gave gold to radiant core %s', tostring(h:GetUnitName()))
                    end
                end
                safeStep('XP Radiant '..tostring(h:GetUnitName()), function() XP.UpdateXP(h, TeamRadiant) end)
            end
            for _, h in pairs(TeamDire) do
                if Helper.IsCore(h, TeamDire)
                then
                    safeStep('GPM Dire '..tostring(h:GetUnitName()), function() GPM.UpdateBotGold(h) end)
                    if tickCount <= 3 then
                        log('[Buff][Tick] gave gold to dire core %s', tostring(h:GetUnitName()))
                    end
                end
                safeStep('XP Dire '..tostring(h:GetUnitName()), function() XP.UpdateXP(h, TeamDire) end)
            end
        else
            if tickCount <= 3 then
                log('[Buff][Tick] turbo mode detected -- skipping gold/xp')
            end
        end
        return 1
    end)
end

function Buff:Print(msg, color)
	local message = msg
    if color ~= nil then
      message = Buff:ColorString(msg, color)
    end
	GameRules:SendCustomMessage(message, 0, 0)
end

-- returns html encoding to change the text of msg the appropriate color
function Buff:ColorString(msg, color)
	return '<font color="'..color..'">'..msg..'</font>'
end

Buff:Print('Buff mode initialized. Version: ' .. Version.number, Colors.good)
Buff:Print("Bot link for any feedback: https://github.com/forest0xia/dota2bot-OpenHyperAI . Kudos to BeginnerAI, Fretbots, and ryndrb@; and thanks all for sharing your ideas.", Colors.consoleGood)
Timers:CreateTimer(InitTimerName, {endTime = 1, callback = Buff['Init']} )
