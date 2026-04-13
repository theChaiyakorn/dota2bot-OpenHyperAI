if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or GetBot():IsIllusion() then
	return;
end

local Utils = require( GetScriptDirectory()..'/FuncLib/systems/utils' )
local Version = require(GetScriptDirectory()..'/FuncLib/systems/version')
local Localization = require( GetScriptDirectory()..'/FuncLib/systems/localization' )
local Customize = require( GetScriptDirectory()..'/Customize/general' )

local bot = GetBot();
local X = {}
local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils')
local RB = Vector(-7174.000000, -6671.00000, 0.000000)
local DB = Vector(7023.000000, 6450.000000, 0.000000)

local botName = bot:GetUnitName();
local sec = 0;
local preferedCamp = nil;
local nLastFarmDesireLog = 0;
local availableCamp = {};
local hLaneCreepList = {};
local farmState = 0;
local FARM_STATE_NONE = 0;
local FARM_STATE_FARM = 1;
local teamPlayers = nil;
local nLaneList = {LANE_TOP, LANE_MID, LANE_BOT};
local assembleTime = 0;
local teamTime = 0;

local countTime = 0;
local countCD = 5.0;
local allyKills = 0;
local enemyKills = 0;

local nLostCount = RandomInt(35,45);
local nWinCount = RandomInt(24,34);

local bInitDone = false;
local beNormalFarmer = false;
local beHighFarmer = false;
local beVeryHighFarmer = false;
local team = GetTeam()
local isChangePosMessageDone = false
local nH, nB = Fu.Utils.NumHumanBotPlayersInTeam(GetOpposingTeam())
local lastAnnouncePrintedTime = 0
local numberAnnouncePrinted = 1
local announcementGap = 6
local hasPickedOneAnnouncer = false
local CleanupCachedVarsTime = -100

-- Map bot mode to localization key
local modeLocaleMap = {
	[BOT_MODE_LANING] = 'mode_laning',
	[BOT_MODE_FARM] = 'mode_farming',
	[BOT_MODE_PUSH_TOWER_TOP] = 'mode_pushing',
	[BOT_MODE_PUSH_TOWER_MID] = 'mode_pushing',
	[BOT_MODE_PUSH_TOWER_BOT] = 'mode_pushing',
	[BOT_MODE_DEFEND_TOWER_TOP] = 'mode_defending',
	[BOT_MODE_DEFEND_TOWER_MID] = 'mode_defending',
	[BOT_MODE_DEFEND_TOWER_BOT] = 'mode_defending',
	[BOT_MODE_RETREAT] = 'mode_retreating',
	[BOT_MODE_ROSHAN] = 'mode_roshan',
	[BOT_MODE_ATTACK] = 'mode_fighting',
	[BOT_MODE_ROAM] = 'mode_roaming',
	[BOT_MODE_TEAM_ROAM] = 'mode_fighting',
	[BOT_MODE_SIDE_SHOP] = 'mode_tormentor',
}
if BOT_MODE_WATCHER then modeLocaleMap[BOT_MODE_WATCHER] = 'mode_tormentor' end
function X.GetModeLocaleKey(mode)
	return modeLocaleMap[mode] or 'mode_other'
end

-- Filter camps to only safe ones (closer to our base, near our towers)
function X.GetSafeCamps(bot, campTable)
	if campTable == nil or #campTable == 0 then return campTable end

	local nTeam = GetTeam()
	local teamFountain = Fu.GetTeamFountain()
	local enemyFountain = nTeam == TEAM_RADIANT
		and Vector(7023, 6450, 0) or Vector(-7174, -6671, 0)
	local aliveEnemyCount = Fu.GetNumOfAliveHeroes(true)

	-- Find nearest alive tower for distance check
	local towerIds = {TOWER_TOP_1, TOWER_MID_1, TOWER_BOT_1, TOWER_TOP_2, TOWER_MID_2, TOWER_BOT_2}
	local nearestTowerDist = 99999
	local nearestTowerTier = 0
	for _, tid in pairs(towerIds) do
		local tower = GetTower(nTeam, tid)
		if tower ~= nil and tower:IsAlive() then
			local dist = GetUnitToUnitDistance(bot, tower)
			if dist < nearestTowerDist then
				nearestTowerDist = dist
				-- T1 = first 3, T2 = last 3
				nearestTowerTier = (tid <= TOWER_BOT_1) and 1 or 2
			end
		end
	end

	local safeCamps = {}
	for _, camp in pairs(campTable) do
		if camp ~= nil and camp.cattr ~= nil and camp.cattr.location ~= nil then
			local campLoc = camp.cattr.location
			local distToOurFountain = Fu.GetDistance(campLoc, teamFountain)
			local distToEnemyFountain = Fu.GetDistance(campLoc, enemyFountain)

			-- Camp must be closer to our base than enemy base
			local bCloserToUs = distToOurFountain < distToEnemyFountain

			-- Distance from nearest tower: T1 alive = within 2000, T2 alive = within 4000
			local bNearTower = true
			if nearestTowerTier == 1 then
				bNearTower = Fu.GetDistance(campLoc, teamFountain) < 9000
			elseif nearestTowerTier == 2 then
				bNearTower = Fu.GetDistance(campLoc, teamFountain) < 11000
			end

			-- If enemies outnumber nearby allies, skip camps on enemy side
			local bSafe = true
			if not bCloserToUs then
				local aliveAllyCount = Fu.GetNumOfAliveHeroes(false)
				local nAlliesNearCamp = Fu.GetAlliesNearLoc(campLoc, 2500)
				-- Safe on enemy side if: allies outnumber enemies, or 2+ allies near camp
				if aliveEnemyCount >= 3 and #nAlliesNearCamp < 2 and aliveAllyCount <= aliveEnemyCount then
					bSafe = false
				end
			end

			-- Skip ancient camps if bot can't handle them
			local bCanFarmCamp = true
			if Fu.Site.IsAncientCamp(camp) then
				if bot:GetLevel() < 10 or bot:GetArmor() < 6 then
					bCanFarmCamp = false
				end
			end

			if bSafe and bNearTower and bCanFarmCamp then
				table.insert(safeCamps, camp)
			end
		end
	end

	-- If filtering removed everything, return original (don't leave bot with nothing)
	if #safeCamps == 0 then return campTable end
	return safeCamps
end


if bot.farmLocation == nil then bot.farmLocation = bot:GetLocation() end

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end

	-- Bear without scepter: match hero's farm mode.
	-- When hero IS farming → bear gets same farm desire (so bear farms too).
	-- When hero is NOT farming → normal desire computation (other modes compete).
	if bot.isBear or string.find(bot:GetUnitName(), 'lone_druid_bear') then
		local hasScepter = bot:HasModifier('modifier_item_ultimate_scepter_consumed')
			or bot:FindItemSlot('item_ultimate_scepter') >= 0
		if not hasScepter then
			local Utils = require(GetScriptDirectory()..'/FuncLib/systems/utils')
			local ld = Utils.GetLoneDruid(bot)
			if ld and ld.hero and Fu.IsValidHero(ld.hero) and ld.hero:IsAlive() then
				if ld.hero:GetActiveMode() == BOT_MODE_FARM then
					-- Hero is farming: bear should farm too (match hero's desire)
					return ld.hero:GetActiveModeDesire() + 0.05
				end
			end
		end
	end

	local ok, res = pcall(GetDesireHelper)
	if not ok then
		if IsDebug then log('[FARM-ERROR] %s %s', bot:GetUnitName(), tostring(res)) end
		return BOT_MODE_DESIRE_VERYLOW
	end

	-- If defend ping active but farm still winning, announce what bot is doing
	Fu.Utils['GameStates'] = Fu.Utils['GameStates'] or {}
	Fu.Utils['GameStates']['defendPings'] = Fu.Utils['GameStates']['defendPings'] or { pingedTime = GameTime() }
	if res > 0.5
	   and GameTime() - Fu.Utils['GameStates']['defendPings'].pingedTime <= 5.0
	   and (bot._lastDefIgnoreChat or 0) + 15 < DotaTime() then
		bot._lastDefIgnoreChat = DotaTime()
		local modeKey = X.GetModeLocaleKey(bot:GetActiveMode())
		local modeName = Localization.Get(modeKey) or modeKey
		local msg = Localization.Get('say_not_defending')
		if msg then
			bot:ActionImmediate_Chat(string.format(msg, modeName), false)
		end
	end
	-- Diagnostic
	if IsDebug and DotaTime() > 3 * 60 and DotaTime() > nLastFarmDesireLog + 10 then
		nLastFarmDesireLog = DotaTime()
		log('[FARM-DESIRE] %s t=%.0f raw=%.2f exit=%s mode=%s pos=%d prefCamp=%s',
			bot:GetUnitName(), DotaTime(), res,
			tostring(bot._farmExitReason or 'normal'),
			tostring(bot:GetActiveMode()), Fu.GetPosition(bot),
			tostring(preferedCamp ~= nil))
	end

	-- Scale farm desire by HP (low HP = farm less, retreat instead). Huskar excluded.
	if res > 0 and bot:GetUnitName() ~= 'npc_dota_hero_huskar' then
		res = res * RemapValClamped(Fu.GetHP(bot), 0.3, 0.7, 0, 1)
	end

	-- Reduce farm during teamfight (let attack/defend take over)
	if res > 0 and Fu.IsInTeamFight(bot, 1200) then
		res = res * 0.4
	end

	-- Suppress farm when any lane needs defending (prevents TP-out while enemies push HG)
	if res > 0.3 then
		local maxDefend = math.max(GetDefendLaneDesire(LANE_TOP), GetDefendLaneDesire(LANE_MID), GetDefendLaneDesire(LANE_BOT))
		if maxDefend > 0.4 then
			res = res * RemapValClamped(maxDefend, 0.4, 0.8, 1, 0.3)
		end
	end

	-- After laning: boost farm when lane front is pushed toward enemy (safe to farm)
	-- Reduce farm when lane front is pushed toward us (should push back instead)
	if res > 0 and not Fu.IsInLaningPhase() then
		local assignedLane = bot:GetAssignedLane()
		local laneFront = GetLaneFrontLocation(GetTeam(), assignedLane, 0)
		local ourFountain = Fu.GetTeamFountain()
		local enemyFountain = Fu.GetEnemyFountain()
		local frontToUs = Fu.GetDistance(laneFront, ourFountain)
		local frontToThem = Fu.GetDistance(laneFront, enemyFountain)
		-- >1 = pushed toward enemy (safe), <1 = pushed toward us (should push)
		local laneRatio = frontToThem > 0 and (frontToUs / frontToThem) or 1
		local farmBoost = RemapValClamped(laneRatio, 0.8, 1.5, 0.5, 1.2)
		res = res * farmBoost
	end

	-- Farm commitment: once farming, maintain desire floor for 3 seconds
	-- Prevents oscillation when walking between lane front (enemies visible) and jungle
	if res > 0.15 then
		bot._farmCommitUntil = DotaTime() + 3.0
		bot._farmCommitFloor = res * 0.7
	end
	if bot._farmCommitUntil and DotaTime() <= bot._farmCommitUntil then
		res = math.max(res, bot._farmCommitFloor or 0)
	end

	return res
end

function GetDesireHelper()
	bot._farmExitReason = nil -- track which path returns
	if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp) end

	if DotaTime() - CleanupCachedVarsTime > Utils.CachedVarsCleanTime then
		Utils.CleanupCachedVars()
		CleanupCachedVarsTime = DotaTime()
	end

    -- Defend ping: suppress farm when T2+ under attack by 2+ enemies
    Fu.Utils['GameStates'] = Fu.Utils['GameStates'] or {}
    Fu.Utils['GameStates']['defendPings'] = Fu.Utils['GameStates']['defendPings'] or { pingedTime = GameTime() }
    local defendPingActive = GameTime() - Fu.Utils['GameStates']['defendPings'].pingedTime <= 5.0
    if defendPingActive then
		local bT2PlusUnderAttack = false
		local nTeam = GetTeam()
		local t2Plus = {TOWER_TOP_2, TOWER_MID_2, TOWER_BOT_2, TOWER_TOP_3, TOWER_MID_3, TOWER_BOT_3}
		for _, tid in pairs(t2Plus) do
			local tower = GetTower(nTeam, tid)
			if tower ~= nil and tower:IsAlive() then
				local nEnemiesNear = Fu.GetEnemiesNearLoc(tower:GetLocation(), 1200)
				if #nEnemiesNear >= 2 then
					bT2PlusUnderAttack = true
					break
				end
			end
		end
		if bT2PlusUnderAttack then
			bot._farmExitReason = 'defend_ping'; return BOT_MODE_DESIRE_VERYLOW
		end
	end

	if not bInitDone
	then
		bInitDone = true
		beNormalFarmer = Fu.GetPosition(bot) == 3
		beHighFarmer = Fu.GetPosition(bot) == 2
		beVeryHighFarmer = Fu.GetPosition(bot) == 1
	end

	if DotaTime() < 50 then bot._farmExitReason = 'too_early'; return 0.0 end

	-- Suppress farm when serious defense is needed
	-- Check if any lane has high defend desire — means enemies are pushing hard
	local maxDefendDesire = math.max(GetDefendLaneDesire(LANE_TOP), GetDefendLaneDesire(LANE_MID), GetDefendLaneDesire(LANE_BOT))
	if maxDefendDesire > 0.5 then
		-- Check if 3+ allies are already defending (serious fight) or 4+ enemies visible
		local nDefendLane, _ = Fu.GetMostDefendLaneDesire()
		local defendFront = GetLaneFrontLocation(GetTeam(), nDefendLane, 0)
		local alliesAtDefend = Fu.GetAlliesNearLoc(defendFront, 2500)
		if #alliesAtDefend >= 3 then
			bot._farmExitReason = 'serious_defend'; return BOT_MODE_DESIRE_VERYLOW
		end
	end

	local LoneDruid = Fu.CheckLoneDruid()
    local botActiveMode = bot:GetActiveMode()
	local botActiveModeDesire = bot:GetActiveModeDesire()
    local bAlive = bot:IsAlive()
	local bNotClone = not bot:HasModifier('modifier_arc_warden_tempest_double') and not Fu.IsMeepoClone(bot)

	local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)

	local nInRangeAlly_tormentor = Fu.GetAlliesNearLoc(Fu.GetTormentorLocation(GetTeam()), 1600)
	local nInRangeAlly_roshan_early = Fu.GetAlliesNearLoc(Fu.GetCurrentRoshanLocation(), 1200)
	local bRoshanAliveEarly = Fu.IsRoshanAlive()
	local teamNetworth, enemyNetworth = Fu.GetInventoryNetworth()
	local networthAdvantage = teamNetworth - enemyNetworth
	local nAliveEnemyCountEarly = Fu.GetNumOfAliveHeroes(true)
	local nAliveAllyCountEarly = Fu.GetNumOfAliveHeroes(false)

	if not bAlive
	or Fu.IsInLaningPhase()
	or (Fu.IsDefending(bot) and botActiveModeDesire > BOT_MODE_DESIRE_LOW)
	or (Fu.IsDoingRoshan(bot) and bNotClone)
	or (Fu.IsDoingTormentor(bot) and bNotClone)
	or DotaTime() < 50
    or ((botActiveMode == BOT_MODE_SECRET_SHOP
		or botActiveMode == BOT_MODE_RUNE
		or botActiveMode == BOT_MODE_WARD
		or botActiveMode == BOT_MODE_RETREAT
		or botActiveMode == BOT_MODE_OUTPOST) and botActiveModeDesire > 0)
	or (#nInRangeAlly_tormentor >= 2 and bot.tormentor_state == true)
	or (#nInRangeAlly_roshan_early >= 2 and bRoshanAliveEarly and bNotClone)
	or (Fu.DoesTeamHaveAegis() and Fu.IsLateGame() and nAliveAllyCountEarly >= 4)
	or X.IsUnitAroundLocation(GetAncient(GetTeam()):GetLocation(), 3200)
	or #nEnemyHeroes > 0
	or (nAliveEnemyCountEarly <= 1 and networthAdvantage > 10000)
    then
		if DotaTime() > 10 * 60 and DotaTime() > (bot._lastFarmEarlyLog or 0) + 15 then
			bot._lastFarmEarlyLog = DotaTime()
			log(string.format('[FARM-EARLY] %s t=%.0f laning=%s defend=%s rosh=%s tor=%s enemies=%d ancient=%s aegis=%s nwAdv=%s alive=%dv%d',
				bot:GetUnitName(), DotaTime(),
				tostring(Fu.IsInLaningPhase()),
				tostring(Fu.IsDefending(bot) and botActiveModeDesire > BOT_MODE_DESIRE_MODERATE),
				tostring(Fu.IsDoingRoshan(bot) and bNotClone),
				tostring(Fu.IsDoingTormentor(bot) and bNotClone),
				#nEnemyHeroes,
				tostring(X.IsUnitAroundLocation(GetAncient(GetTeam()):GetLocation(), 3200)),
				tostring(Fu.DoesTeamHaveAegis() and Fu.IsLateGame() and nAliveAllyCountEarly >= 4),
				tostring(nAliveEnemyCountEarly <= 1 and networthAdvantage > 10000),
				nAliveAllyCountEarly, nAliveEnemyCountEarly))
		end
        bot._farmExitReason = 'early_exit'
        return BOT_MODE_DESIRE_NONE
    end

    if not bAlive then
        bot._farmExitReason = 'dead'; return BOT_MODE_DESIRE_NONE
    end

	-- Retreating allies
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local member = GetTeamMember(i)
		if bot ~= member and Fu.IsValidHero(member) and Fu.IsInRange(bot, member, 2000) and Fu.IsRetreating(member) then
			local nEnemyHeroesTargetingAlly = Fu.GetHeroesTargetingUnit(nEnemyHeroes, member)
			if #nEnemyHeroesTargetingAlly >= 2 or member:WasRecentlyDamagedByAnyHero(1.0) then
				bot._farmExitReason = 'retreating_ally'; return BOT_MODE_DESIRE_NONE
			end
		end
	end

	local vTeamFightLocation = Fu.GetTeamFightLocation(bot)
	if vTeamFightLocation ~= nil and GetUnitToLocationDistance(bot, vTeamFightLocation) < 2500 then
		if bot:GetLevel() >= 18 or not Fu.IsCore(bot) then
			bot._farmExitReason = 'teamfight_nearby'; return BOT_MODE_DESIRE_NONE
		end
	end

    local nAliveEnemyCount = Fu.GetNumOfAliveHeroes(true)
    local nAliveAllyCount  = Fu.GetNumOfAliveHeroes(false)
    local bRoshanAlive = Fu.IsRoshanAlive()
    local nInRangeAlly_roshan = Fu.GetAlliesNearLoc(Fu.GetCurrentRoshanLocation(), 1200)

	if teamPlayers == nil then teamPlayers = GetTeamPlayers(GetTeam()) end
	
	if X.IsUnitAroundLocation(GetAncient(GetTeam()):GetLocation(), 3000)
	-- and aliveAllyCount >= aliveEnemyCount
	then
		bot._farmExitReason = 'enemies_at_ancient'; return BOT_MODE_DESIRE_NONE;
	end
	
	sec = math.floor(DotaTime()) % 60;
	
	if not Fu.Role.IsCampRefreshDone()
	   and Fu.Role.GetAvailableCampCount() < Fu.Role.GetCampCount()
	   and ( DotaTime() > 20 and  sec > 0 and sec < 2 )  
	then
		Fu.Role['availableCampTable'], Fu.Role['campCount'] = Fu.Site.RefreshCamp(bot);
		Fu.Role['hasRefreshDone'] = true;
	end
	
	if Fu.Role.IsCampRefreshDone() and sec > 52
	then
		Fu.Role['hasRefreshDone'] = false;
	end
	
	availableCamp = X.GetSafeCamps(bot, Fu.Role['availableCampTable']);

    if bAlive and bot:HasModifier('modifier_arc_warden_tempest_double') then
        if bRoshanAlive then
            for _, ally in pairs(nInRangeAlly_roshan) do
                if ally ~= bot
                and Fu.IsValidHero(ally)
                and ally:GetUnitName() == 'npc_dota_hero_arc_warden'
				and Fu.IsDoingRoshan(ally)
                then
                    local hTarget = ally:GetAttackTarget()
                    if (Fu.IsRoshan(hTarget) and Fu.GetHP(hTarget) < 0.4)
                    or (botActiveMode == BOT_MODE_ITEM)
                    then
						if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp) end
                        return RemapValClamped(Fu.GetHP(bot), 0.2, 0.7, BOT_MODE_DESIRE_MODERATE, BOT_MODE_DESIRE_VERYHIGH)
					end
                end
            end
        end
    end

    if bAlive and Fu.IsMeepoClone(bot) then
        if bRoshanAlive then
            for _, ally in pairs(nInRangeAlly_roshan) do
                if ally ~= bot
                and Fu.IsValidHero(ally)
				and not Fu.IsMeepoClone(ally)
                and ally:GetUnitName() == 'npc_dota_hero_meepo'
                and Fu.IsDoingRoshan(ally)
                then
                    local hTarget = ally:GetAttackTarget()
                    if (Fu.IsRoshan(hTarget) and Fu.GetHP(hTarget) < 0.25)
                    or (botActiveMode == BOT_MODE_ITEM)
                    then
						if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp) end
                        return RemapValClamped(Fu.GetHP(bot), 0.2, 0.7, BOT_MODE_DESIRE_MODERATE, BOT_MODE_DESIRE_VERYHIGH)
                    end
                end
            end
        end
    end
	
	if Fu.DoesTeamHaveAegis() and nAliveAllyCount >= 4 then
		bot._farmExitReason = 'aegis_push'; return BOT_MODE_DESIRE_VERYLOW;
	end
		
	if DotaTime() > countTime + countCD
	then
		countTime  = DotaTime();
		allyKills  = Fu.GetNumOfTeamTotalKills(false);
		enemyKills = Fu.GetNumOfTeamTotalKills(true);

		
		if enemyKills > allyKills + nLostCount and Fu.Role.NotSayRate() 
		then
			Fu.Role['sayRate'] = true;
			if RandomInt(1,6) < 3 
			then
				bot:ActionImmediate_Chat(Localization.Get('say_will_lose'),true);
			else
				bot:ActionImmediate_Chat(Localization.Get('say_will_lose_2'),true);
			end
		end
		if allyKills > enemyKills + nWinCount and Fu.Role.NotSayRate() 
		then
		    Fu.Role['sayRate'] = true;
			if RandomInt(1,6) < 3 
			then
				bot:ActionImmediate_Chat(Localization.Get('say_will_win'),true);
			else
				bot:ActionImmediate_Chat(Localization.Get('say_will_win_2'),true);
			end
		end
	
	end
	if allyKills > enemyKills + 20 and nAliveAllyCount >= 4
	then bot._farmExitReason = 'winning_push'; return BOT_MODE_DESIRE_VERYLOW; end

	local nAlliesCount = Fu.GetAllyCount(bot,1400);
	if nAlliesCount >= 4
	   or (bot:GetLevel() >= 23 and nAlliesCount >= 3)
	   or GetRoshanDesire() > BOT_MODE_DESIRE_VERYHIGH
	then
		local nNeutrals = bot:GetNearbyNeutralCreeps( bot:GetAttackRange() ); 
		if #nNeutrals == 0 
		then 
		    teamTime = DotaTime();
		end
	end

    local hItem = Fu.IsItemAvailable('item_hand_of_midas')
    if Fu.IsInAllyArea(bot) and Fu.CanCastAbility(hItem) then
        if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp) end;
        return RemapValClamped(Fu.GetHP(bot), 0.2, 0.7, BOT_MODE_DESIRE_MODERATE, BOT_MODE_DESIRE_VERYHIGH)
    end

	if Fu.IsDefending(bot) and botActiveModeDesire >= 0.75 then
		local nDefendLane, nDefendDesire = Fu.GetMostDefendLaneDesire()
		local vDefendLocation  = GetLaneFrontLocation(GetTeam(), nDefendLane, -600)
		local nDefendAllies = Fu.GetAlliesNearLoc(vDefendLocation, 2200)

		local nNeutrals = bot:GetNearbyNeutralCreeps(Min(bot:GetAttackRange(), 1600))

		if #nNeutrals == 0 and #nDefendAllies >= 2 and (not beVeryHighFarmer or bot:GetLevel() >= 15 or Fu.IsLateGame()) then
		    teamTime = DotaTime()
		end
	end

	if teamTime > DotaTime() - 3.0 then bot._farmExitReason = 'team_activity'; return BOT_MODE_DESIRE_VERYLOW end

	-- local aAliveCount = Fu.GetNumOfAliveHeroes(false)
    -- local eAliveCount = Fu.GetNumOfAliveHeroes(true)
    -- local aAliveCoreCount = Fu.GetAliveCoreCount(false)
    -- local eAliveCoreCount = Fu.GetAliveCoreCount(true)
	-- Count allies actively pushing
	local nAlliesPushing = 0
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local member = GetTeamMember(i)
		if member ~= nil and member ~= bot and member:IsAlive() then
			local mode = member:GetActiveMode()
			if mode == BOT_MODE_PUSH_TOWER_TOP or mode == BOT_MODE_PUSH_TOWER_MID or mode == BOT_MODE_PUSH_TOWER_BOT then
				nAlliesPushing = nAlliesPushing + 1
			end
		end
	end

	-- Only suppress farm when the whole team should push together
	if beNormalFarmer then
		if bot:GetActiveMode() == BOT_MODE_ASSEMBLE then assembleTime = DotaTime() end
		if DotaTime() - assembleTime < 5 then bot._farmExitReason = 'assemble'; return BOT_MODE_DESIRE_VERYLOW end
		if Fu.IsTeamActivityCount(bot, 3) then bot._farmExitReason = 'team_activity_3'; return BOT_MODE_DESIRE_VERYLOW end
	end

	-- If 4+ allies are pushing, everyone should join (including pos 1)
	if nAlliesPushing >= 4 then
		bot._farmExitReason = '4_allies_pushing'; return BOT_MODE_DESIRE_VERYLOW
	end


	-- local nFarmTimeThreshold = Fu.IsModeTurbo() and 4 * 60 or 7 * 60
	-- local nFarmLevelThreshold = Fu.IsModeTurbo() and 5 or 8
	-- local nFarmMeleeLevelThreshold = Fu.IsModeTurbo() and 4 or 6
	-- Log why farm block is skipped
	local bIsTimeToFarm = Fu.Site.IsTimeToFarm(bot)
	local bIsDefending = Fu.IsDefending(bot)
	local nArmor = bot:GetArmor()
	local bFarmBlockEntered = GetGameMode() ~= GAMEMODE_MO
		and bIsTimeToFarm
		and (not bIsDefending or botActiveModeDesire < 0.2)
		and (bot:GetUnitName() ~= 'npc_dota_hero_lone_druid_bear' or (bot:HasScepter() and not Fu.IsValid(LoneDruid.hero)))

	if IsDebug and DotaTime() > 3 * 60 and not bFarmBlockEntered and DotaTime() > (bot._lastFarmBlockLog or 0) + 10 then
		bot._lastFarmBlockLog = DotaTime()
		log('[FARM-BLOCK] %s t=%.0f SKIPPED: isTimeToFarm=%s defending=%s armor=%.0f pos=%s',
			bot:GetUnitName(), DotaTime(),
			tostring(bIsTimeToFarm), tostring(bIsDefending), nArmor,
			tostring(Fu.GetPosition(bot)))
	end

	if bFarmBlockEntered then

	-- Always keep a camp ready so bot can switch to jungle when lane creeps die
	if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp) end

	if Fu.GetDistanceFromEnemyFountain(bot) > 4000
		then
			hLaneCreepList = bot:GetNearbyLaneCreeps(1600, true);
			if #hLaneCreepList == 0
			   and Fu.IsInAllyArea( bot )
			   and X.IsNearLaneFront( bot )
			then
				hLaneCreepList = bot:GetNearbyLaneCreeps(1600, false);
			end
		end;

		if #hLaneCreepList > 0
		then
			-- Only farm lane creeps if no enemy heroes nearby (like reference)
			local nEnemiesNearCreeps = Fu.GetEnemiesNearLoc(Fu.GetCenterOfUnits(hLaneCreepList), 1600)
			if #nEnemiesNearCreeps == 0 then
				bot.farmLocation = Fu.GetCenterOfUnits(hLaneCreepList)
				return BOT_MODE_DESIRE_VERYHIGH;
			end
		end

		-- Lane priority: if a lane front is pushed toward our base, go farm there
		-- instead of staying in jungle. Creep waves give more gold/XP than camps.
		if #hLaneCreepList == 0 then
			local ourFountain = Fu.GetTeamFountain()
			local enemyFountain = Fu.GetEnemyFountain()
			local bestLane = nil
			local bestScore = 0
			for _, lane in pairs({LANE_TOP, LANE_MID, LANE_BOT}) do
				local laneFront = GetLaneFrontLocation(GetTeam(), lane, 0)
				local distToUs = GetUnitToLocationDistance(bot, laneFront)
				-- Only consider lanes where front is closer to our base than enemy base
				local frontToOur = Fu.GetDistance(laneFront, ourFountain)
				local frontToEnemy = Fu.GetDistance(laneFront, enemyFountain)
				if frontToOur < frontToEnemy and distToUs < 6000 then
					local nEnemiesNear = Fu.GetLastSeenEnemiesNearLoc(laneFront, 1600)
					if #nEnemiesNear == 0 then
						-- Score: closer lanes and more pushed-in lanes rank higher
						local score = (1 / math.max(1, distToUs)) * (frontToEnemy / math.max(1, frontToOur))
						if score > bestScore then
							bestScore = score
							bestLane = lane
						end
					end
				end
			end
			if bestLane ~= nil then
				local farmLoc = GetLaneFrontLocation(GetTeam(), bestLane, 0)
				-- Ensure passable; nudge toward fountain if not
				if not IsLocationPassable(farmLoc) then
					farmLoc = Fu.AdjustLocationWithOffsetTowardsFountain(farmLoc, 200)
				end
				if IsLocationPassable(farmLoc) then
					bot.farmLocation = farmLoc
					return BOT_MODE_DESIRE_VERYHIGH
				end
			end
		end

		if #hLaneCreepList == 0 then
			if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp);end

			if IsDebug then
				log('[FARM-CAMP] %s t=%.0f prefCamp=%s farmState=%d',
					bot:GetUnitName(), DotaTime(), tostring(preferedCamp ~= nil), farmState)
			end

			if preferedCamp ~= nil then
				if not Fu.Site.IsModeSuitableToFarm(bot)
				then
					preferedCamp = nil;
					bot._farmExitReason = 'mode_not_suitable_'..tostring(botActiveMode)
					return BOT_MODE_DESIRE_VERYLOW;
				elseif bot:GetHealth() <= 200
					then
						preferedCamp = nil;
						teamTime = DotaTime();
						bot._farmExitReason = 'low_hp'
						return BOT_MODE_DESIRE_VERYLOW;
				elseif farmState == FARM_STATE_FARM
					then
						bot._farmExitReason = 'farming_camp'
						return BOT_MODE_DESIRE_VERYHIGH;
				else
					local farmDistance = GetUnitToLocationDistance(bot, preferedCamp.cattr.location);
					bot.farmLocation = preferedCamp.cattr.location
					bot._farmExitReason = 'walk_to_camp_'..string.format('%.0f', farmDistance)
					return math.floor(RemapValClamped(farmDistance, 6000, 0, BOT_MODE_DESIRE_MODERATE, BOT_MODE_DESIRE_ABSOLUTE) * 10) / 10;
				end
			end
		end
	end

	-- Fallback: ensure preferedCamp is set so Think always has a target
	if preferedCamp == nil then
		preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp)
		if preferedCamp ~= nil then
			bot.farmLocation = preferedCamp.cattr.location
		end
	end

	-- Post-laning fallback: cores always farm, supports farm in late game
	if not Fu.IsInLaningPhase() and (Fu.IsCore(bot) or Fu.IsLateGame() or bot:GetLevel() >= 18) then
		if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp) end
		if preferedCamp ~= nil then
			return BOT_MODE_DESIRE_LOW
		end
	end

	-- If all other modes have near-zero desire, give farm enough to win
	if botActiveModeDesire < 0.1 and DotaTime() > 5 * 60 then
		if preferedCamp ~= nil then
			return BOT_MODE_DESIRE_MODERATE
		end
		hLaneCreepList = bot:GetNearbyLaneCreeps(1600, true)
		if #hLaneCreepList > 0 then
			return BOT_MODE_DESIRE_MODERATE
		end
	end

	bot._farmExitReason = 'end_fallback'
	return BOT_MODE_DESIRE_VERYLOW
end


function OnStart()

end

function OnEnd()
	preferedCamp = nil;
	farmState = FARM_STATE_NONE;
	hLaneCreepList  = {};
	bot:SetTarget(nil);
end

local nLastFarmLog = 0
function Think()
	-- Diagnostic: log BEFORE any early returns so we always see it
	if IsDebug then
		local _farmLogNow = DotaTime()
		if _farmLogNow > nLastFarmLog + 3 then
			nLastFarmLog = _farmLogNow
			local _canNotUse = Fu.CanNotUseAction(bot)
			local _lc = bot:GetNearbyLaneCreeps(1200, true)
			local _nc = bot:GetNearbyNeutralCreeps(900)
			log('[FARM-THINK] %s t=%.0f desire=%.2f canNotUse=%s farmState=%d prefCamp=%s laneCreeps=%d neutrals=%d',
				bot:GetUnitName(), _farmLogNow, bot:GetActiveModeDesire(),
				tostring(_canNotUse), farmState,
				tostring(preferedCamp ~= nil), #(_lc or {}), #(_nc or {}))
		end
	end

	if Fu.CanNotUseAction(bot) then return end

	-- Safety: if low HP and enemies nearby, walk toward fountain — don't farm to death
	if Fu.GetHP(bot) < 0.35 and bot:WasRecentlyDamagedByAnyHero(3.0) then
		local fountain = Fu.GetTeamFountain()
		bot:Action_MoveToLocation(fountain)
		return
	end

	-- Join nearby ally push: if 3+ allies pushing within 5000, go join them
	local nPushingAllies = {}
	for i = 1, #GetTeamPlayers(GetTeam()) do
		local member = GetTeamMember(i)
		if member ~= nil and member ~= bot and member:IsAlive() then
			local mode = member:GetActiveMode()
			if mode == BOT_MODE_PUSH_TOWER_TOP or mode == BOT_MODE_PUSH_TOWER_MID or mode == BOT_MODE_PUSH_TOWER_BOT then
				if GetUnitToUnitDistance(bot, member) < 5000 then
					table.insert(nPushingAllies, member)
				end
			end
		end
	end
	if #nPushingAllies >= 3 then
		-- Move to the center of pushing allies, offset by half attack range
		local pushCenter = Fu.GetCenterOfUnits(nPushingAllies)
		local offset = math.max(bot:GetAttackRange() / 2, 150)
		local approachLoc = Fu.AdjustLocationWithOffsetTowardsFountain(pushCenter, offset)
		bot:Action_MoveToLocation(approachLoc)
		return
	end

	-- Bear: attack what the hero is attacking (farm same target)
	if bot.isBear or string.find(bot:GetUnitName(), 'lone_druid_bear') then
		local Utils = require(GetScriptDirectory()..'/FuncLib/systems/utils')
		local ld = Utils.GetLoneDruid(bot)
		if ld and ld.hero and Fu.IsValidHero(ld.hero) then
			local heroTarget = ld.hero:GetAttackTarget()
			if Fu.IsValid(heroTarget) and Fu.CanBeAttacked(heroTarget)
			and GetUnitToUnitDistance(bot, heroTarget) < 1200 then
				bot:Action_AttackUnit(heroTarget, true)
				return
			end
			-- No hero target: stay near hero
			local heroDist = GetUnitToUnitDistance(bot, ld.hero)
			if heroDist > 500 then
				bot:Action_MoveToLocation(ld.hero:GetLocation())
				return
			end
		end
	end
	sec = math.floor(DotaTime()) % 60

	-- Walk to farmLocation set by GetDesire (lane front pushed toward base)
	if bot.farmLocation and IsLocationPassable(bot.farmLocation) and GetUnitToLocationDistance(bot, bot.farmLocation) > 1200 then
		local nEnemyLaneCreepsNearby = bot:GetNearbyLaneCreeps(900, true)
		local nNeutralsNearby = bot:GetNearbyNeutralCreeps(500)
		-- Only walk to lane if not already fighting something
		if #nEnemyLaneCreepsNearby == 0 and #nNeutralsNearby == 0 then
			bot:Action_MoveToLocation(bot.farmLocation)
			return
		end
	end

	-- Lane creep farming: attack lowest HP creep (consistent with last-hit priority)
	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(900, true)
	if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps > 0 and farmState ~= FARM_STATE_FARM then
		-- Tower safety
		local nEnemyTowers = bot:GetNearbyTowers(1600, true)
		if Fu.IsValidBuilding(nEnemyTowers[1]) then
			if nEnemyTowers[1]:GetAttackTarget() == bot or bot:WasRecentlyDamagedByTower(5.0) then
				bot:Action_MoveToLocation(Fu.VectorAway(bot:GetLocation(), nEnemyTowers[1]:GetLocation(), 1600))
				return
			end
		end

		-- Attack lowest HP creep (kill fast, don't fight with last-hit targeting)
		local farmTarget = nil
		local farmTargetHealth = math.huge
		for _, creep in pairs(nEnemyLaneCreeps) do
			if Fu.IsValid(creep) and Fu.CanBeAttacked(creep)
			and not Fu.IsRoshan(creep) and not Fu.IsTormentor(creep) then
				local creepHealth = creep:GetHealth()
				if creepHealth < farmTargetHealth then
					farmTarget = creep
					farmTargetHealth = creepHealth
				end
			end
		end

		if Fu.IsValid(farmTarget) then
			local range = bot:GetAttackRange()
			if GetUnitToUnitDistance(bot, farmTarget) > range then
				bot:Action_MoveToLocation(farmTarget:GetLocation())
				return
			else
				bot:Action_AttackUnit(farmTarget, false)
				return
			end
		end
	end

	bot._farm_repick_at = bot._farm_repick_at or 0
	if GameTime() >= (bot._farm_repick_at or 0) then
		bot._farm_repick_at = GameTime() + 1.0

		local old = preferedCamp
		if old then
			local oldDist = old and GetUnitToLocationDistance(bot, old.cattr.location) or 9e9
	
			local avail = Fu.Role['availableCampTable']
			local nearest = Fu.Site.GetClosestNeutralSpwan(bot, avail)
	
			if nearest then
				local newDist = GetUnitToLocationDistance(bot, nearest.cattr.location)
				-- switch if we save >800 units or ETA improves a lot and danger isn’t worse
				if newDist + 200 < oldDist and not Fu.Site.IsCampDangerous(bot, nearest) then
					preferedCamp = nearest
				end
			end
		else
			preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp);
		end
	end
	
	
	if preferedCamp == nil then preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp);end
	if preferedCamp ~= nil then
		local targetFarmLoc = preferedCamp.cattr.location;
		local cDist = GetUnitToLocationDistance(bot, targetFarmLoc);

		-- Lane creep priority: if lane creeps are within 1000 distance more than camp,
		-- go kill lane creeps first (more gold/XP, prevents lane from pushing into base)
		local nLaneCreepsWider = bot:GetNearbyLaneCreeps(math.min(cDist + 1000, 1600), true)
		if #nLaneCreepsWider > 0 then
			local laneCenter = Fu.GetCenterOfUnits(nLaneCreepsWider)
			local laneDist = GetUnitToLocationDistance(bot, laneCenter)
			local nEnemiesNearLane = Fu.GetEnemiesNearLoc(laneCenter, 1600)
			-- Only prefer lane if no enemies and lane is reasonably close vs camp
			if #nEnemiesNearLane == 0 and laneDist < cDist + 1000 then
				local closestCreep = nLaneCreepsWider[1]
				if Fu.IsValid(closestCreep) and Fu.CanBeAttacked(closestCreep) then
					local range = bot:GetAttackRange()
					if GetUnitToUnitDistance(bot, closestCreep) > range then
						bot:Action_MoveToLocation(closestCreep:GetLocation())
					else
						bot:Action_AttackUnit(closestCreep, false)
					end
					return
				end
			end
		end

		local nNeutrals = bot:GetNearbyCreeps(900, true);

		-- Don't steal farm from an ally already at this camp
		local nAllyNearCamp = Fu.GetAlliesNearLoc(targetFarmLoc, 800)
		local bAllyFarming = false
		for _, ally in pairs(nAllyNearCamp) do
			if ally ~= bot and Fu.IsValidHero(ally) and not ally:IsIllusion()
			and Fu.IsFarming(ally) and Fu.IsAttacking(ally) then
				bAllyFarming = true
				break
			end
		end
		if bAllyFarming and cDist > 400 then
			-- Pick a different camp instead
			Fu.Role['availableCampTable'], preferedCamp = Fu.Site.UpdateAvailableCamp(bot, preferedCamp, Fu.Role['availableCampTable']);
			availableCamp = Fu.Role['availableCampTable']
			preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp)
		end
		if preferedCamp == nil then
			-- No camp available, skip jungle logic and fall to end-of-function fallback
		else
			targetFarmLoc = preferedCamp.cattr.location
			cDist = GetUnitToLocationDistance(bot, targetFarmLoc)
			nNeutrals = bot:GetNearbyCreeps(900, true)

		-- Empty camp detection: if we can see the camp and it's empty, repick
		if (X.IsLocCanBeSeen(targetFarmLoc) and cDist <= 600) or cDist <= 250 then
			local bHasNeutrals = false
			for _, creep in pairs(nNeutrals) do
				if Fu.IsValid(creep) and not Fu.IsRoshan(creep) and not Fu.IsTormentor(creep) then
					bHasNeutrals = true
					break
				end
			end
			if not bHasNeutrals then
				Fu.Role['availableCampTable'], preferedCamp = Fu.Site.UpdateAvailableCamp(bot, preferedCamp, Fu.Role['availableCampTable'])
				availableCamp = Fu.Role['availableCampTable']
				preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp)
				farmState = FARM_STATE_NONE
				-- Don't return — fall through to movement
			end
		end

		-- Neutrals nearby: select lowest HP target (kill one fast to reduce total DPS taken)
		if #nNeutrals > 0 then
			local farmTarget = nil
			local farmTargetHealth = math.huge
			local fallbackTarget = nil
			for _, creep in pairs(nNeutrals) do
				if Fu.IsValid(creep) and Fu.CanBeAttacked(creep)
				and not Fu.IsRoshan(creep) and not Fu.IsTormentor(creep) then
					if not creep:IsAncientCreep() or (bot:GetLevel() >= 10 and bot:GetArmor() >= 6) then
						local creepHealth = creep:GetHealth()
						if creepHealth < farmTargetHealth then
							farmTarget = creep
							farmTargetHealth = creepHealth
						end
					elseif GetUnitToUnitDistance(bot, creep) < 500 then
						fallbackTarget = creep
					end
				end
			end

			local target = farmTarget or fallbackTarget
			if Fu.IsValid(target) then
				farmState = FARM_STATE_FARM
				bot:SetTarget(target)
				bot:Action_AttackUnit(target, false)
				return
			else
				-- At camp but can't hit anything: move to camp center to aggro, or leave
				if cDist < 300 then
					-- Already at camp center, no valid targets: camp is empty or can't farm it
					farmState = FARM_STATE_NONE
					Fu.Role['availableCampTable'], preferedCamp = Fu.Site.UpdateAvailableCamp(bot, preferedCamp, Fu.Role['availableCampTable'])
					availableCamp = Fu.Role['availableCampTable']
					preferedCamp = Fu.Site.GetClosestNeutralSpwan(bot, availableCamp)
				else
					bot:Action_MoveToLocation(targetFarmLoc)
					return
				end
			end
		else
			-- No neutrals detected: walk to camp to pull them
			if cDist > 200 then
				bot:Action_AttackMove(targetFarmLoc)
				return
			end
		end

		end -- preferedCamp nil check
	end

	-- Fallback: all farm paths missed. Log and attack anything nearby.
	log('[FARM-FALLBACK] %s t=%.0f prefCamp=%s laneCreeps=%d',
		bot:GetUnitName(), DotaTime(), tostring(preferedCamp ~= nil), #(hLaneCreepList or {}))

	-- Nothing nearby: move toward nearest lane front
	local bestDist = 99999
	local bestLoc = nil
	for _, lane in pairs({LANE_TOP, LANE_MID, LANE_BOT}) do
		local laneFront = GetLaneFrontLocation(GetTeam(), lane, 0)
		local dist = GetUnitToLocationDistance(bot, laneFront)
		if dist < bestDist then
			bestDist = dist
			bestLoc = laneFront
		end
	end
	if bestLoc ~= nil then
		bot:Action_AttackMove(bestLoc)
	else
		bot:Action_AttackMove( ( RB + DB ) / 2 )
	end
	return;
end

function X.IsNearLaneFront( bot )
	local testDist = 1600;
	for _,lane in pairs(nLaneList)
	do
		local tFLoc = GetLaneFrontLocation(GetTeam(), lane, 0);
		if GetUnitToLocationDistance(bot,tFLoc) <= testDist
		then
		    return true;
		end		
	end
	return false;
end


function X.IsUnitAroundLocation(vLoc, nRadius)
	for i, id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) and i <= 3 then
			local info = GetHeroLastSeenInfo(id)
			if info ~= nil then
				local dInfo = info[1]
				if dInfo ~= nil and Fu.GetDistance(vLoc, dInfo.location) <= nRadius and dInfo.time_since_seen < 1.0 then
					return true
				end
			end
		end
	end
	return false;
end

function X.CouldBlade(bot,nLocation) 
	local blade = Fu.IsItemAvailable("item_quelling_blade");
	if blade == nil then blade = Fu.IsItemAvailable("item_bfury"); end
	
	if blade ~= nil 
	   and blade:IsFullyCastable() 
	then
		local trees = bot:GetNearbyTrees(380);
		local dist = GetUnitToLocationDistance(bot,nLocation);
		local vStart = Fu.Site.GetXUnitsTowardsLocation(bot, nLocation, 32 );
		local vEnd  = Fu.Site.GetXUnitsTowardsLocation(bot, nLocation, dist - 32 );
		for _,t in pairs(trees)
		do
			if t ~= nil
			then
				local treeLoc = GetTreeLocation(t);
				local tResult = PointToLineDistance(vStart, vEnd, treeLoc);
				if tResult ~= nil 
				   and tResult.within 
				   and tResult.distance <= 96
				   and Fu.GetLocationToLocationDistance(treeLoc,nLocation) < dist
				then
					bot:Action_UseAbilityOnTree(blade, t);
					return true;
				end
			end			
		end
	end
	
	return false;
end


function X.CouldBlink(bot,nLocation)
	
	
	local maxBlinkDist = 1199;
	local blink = Fu.IsItemAvailable("item_blink");
	
	if botName == "npc_dota_hero_antimage"
	then
		blink = bot:GetAbilityByName( "antimage_blink" );
		maxBlinkDist = blink:GetSpecialValueInt('AbilityCastRange')
	end
	
	if botName == "npc_dota_hero_queenofpain"
	then
		blink = bot:GetAbilityByName( "queenofpain_blink" );
		maxBlinkDist = Fu.GetProperCastRange(false, bot, blink:GetCastRange())
	end
	
	if blink ~= nil 
	   and blink:IsFullyCastable() 
       and Fu.IsRunning(bot)
	then
		local bDist = GetUnitToLocationDistance(bot,nLocation);
		local maxBlinkLoc = Fu.Site.GetXUnitsTowardsLocation(bot, nLocation, maxBlinkDist );
		if bDist <= 600  -- recommend by oyster 2019/4/16
		then
			return false;
		elseif bDist < maxBlinkDist +1
			then
				if botName == "npc_dota_hero_antimage"
				then
					bot:Action_ClearActions(true);
		
					if not Fu.IsPTReady(bot,ATTRIBUTE_INTELLECT) 
					then
						Fu.SetQueueSwitchPtToINT(bot);
					end
							
					bot:ActionQueue_UseAbilityOnLocation(blink, nLocation);
									
					return true;
				end
			
				bot:Action_UseAbilityOnLocation(blink, nLocation);
				return true;
		elseif IsLocationPassable(maxBlinkLoc)
			then
				
				if botName == "npc_dota_hero_antimage"
				then
					bot:Action_ClearActions(true);
		
					if not Fu.IsPTReady(bot,ATTRIBUTE_INTELLECT) 
					then
						Fu.SetQueueSwitchPtToINT(bot);
					end
							
					bot:ActionQueue_UseAbilityOnLocation(blink, maxBlinkLoc);
									
					return true;
				end
				
				bot:Action_UseAbilityOnLocation(blink, maxBlinkLoc);
				return true;
		end
	end

	return false;
end


function X.IsLocCanBeSeen(vLoc)

	if GetUnitToLocationDistance(GetBot(),vLoc) < 180 then return true end
	
	local tempLocUp    = vLoc + Vector(5  ,0  );
	local tempLocDown  = vLoc + Vector(0  ,10 );
	local tempLocLeft  = vLoc + Vector(-15,0  );
	local tempLocRight = vLoc + Vector(0  ,-20);
	
	return IsLocationVisible(tempLocRight) 
		   and IsLocationVisible(tempLocLeft) 
	       and IsLocationVisible(tempLocUp) 
		   and IsLocationVisible(tempLocDown)
		   and IsRadiusVisible(vLoc,10)

end

function PickOneAnnouncer()
	if not hasPickedOneAnnouncer then
		for i, id in pairs(GetTeamPlayers(GetTeam())) do
			local hero = GetTeamMember(i)
			if hero ~= nil and hero.isAnnouncer then return end
		end
		bot.isAnnouncer = true
		hasPickedOneAnnouncer = true
		return
	end
end

function AnnounceMessages()
	if DotaTime() > 60 then return end

	local welcome_msgs = Localization.Get('welcome_msgs')
	if ((Fu.IsModeTurbo() and DotaTime() > -50 + team * 2) or (not Fu.IsModeTurbo() and DotaTime() > -75 + team * 2))
	and numberAnnouncePrinted < #welcome_msgs + 1
	and bot.isAnnouncer
	and DotaTime() < 0
	then
		if GameTime() - lastAnnouncePrintedTime >= announcementGap then
			local msg = welcome_msgs[numberAnnouncePrinted]
			local isFirstLine = numberAnnouncePrinted == 1
			if msg then
				bot:ActionImmediate_Chat(isFirstLine and msg .. Version.number or msg, nB == 0 or isFirstLine)
			end
			numberAnnouncePrinted = numberAnnouncePrinted + 1
			lastAnnouncePrintedTime = GameTime()
		end
	end

	if GetGameMode() ~= GAMEMODE_1V1MID and GetGameState() == GAME_STATE_PRE_GAME and bot.isBear == nil
	and (bot.announcedRole == nil or bot.announcedRole ~= Fu.GetPosition(bot)) then
		bot.announcedRole = Fu.GetPosition(bot)
		-- if GetTeam() == TEAM_DIRE then
		-- 	-- broken for 7.38 for now.
		-- 	return
		-- end
		bot:ActionImmediate_Chat(Localization.Get('say_play_pos')..Fu.GetPosition(bot), false)
	end
	if GetGameMode() ~= GAMEMODE_1V1MID
	and not isChangePosMessageDone
	and bot.isAnnouncer
	then
		local nH, nB = Fu.NumHumanBotPlayersInTeam()
		if DotaTime() >= 0 and nH > 0 and nB > 0
		then
			bot:ActionImmediate_Chat(Localization.Get('pos_select_closed'), true)
			isChangePosMessageDone = true
		end
	end
end

