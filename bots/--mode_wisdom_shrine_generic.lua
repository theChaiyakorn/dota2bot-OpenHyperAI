local bot = GetBot()
local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end

	-- Don't go to wisdom_shrine_ if enemies are nearby (dangerous pathing)
	local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	if nEnemyHeroes and #nEnemyHeroes >= 1 then
		return BOT_MODE_DESIRE_NONE
	end

	-- Don't go if low HP (should retreat instead)
	if Fu.GetHP(bot) < 0.5 then
		return BOT_MODE_DESIRE_NONE
	end

	-- Don't go if recently damaged (being chased)
	if bot:WasRecentlyDamagedByAnyHero(3.0) then
		return BOT_MODE_DESIRE_NONE
	end

	-- Radiant bot lane: wisdom_shrine_ is near Dire's bot T1 — don't walk into tower range
	if GetTeam() == TEAM_RADIANT then
		local enemyT1 = GetTower(TEAM_DIRE, TOWER_BOT_1)
		if enemyT1 ~= nil and enemyT1:IsAlive() and GetUnitToUnitDistance(bot, enemyT1) < 1600 then
			return BOT_MODE_DESIRE_NONE
		end
	end

	-- Dire top lane: wisdom_shrine_ is near Radiant's top T1 — don't walk into tower range
	if GetTeam() == TEAM_DIRE then
		local enemyT1 = GetTower(TEAM_RADIANT, TOWER_TOP_1)
		if enemyT1 ~= nil and enemyT1:IsAlive() and GetUnitToUnitDistance(bot, enemyT1) < 1600 then
			return BOT_MODE_DESIRE_NONE
		end
	end


end
