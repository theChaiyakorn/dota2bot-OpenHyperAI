local Defend = require( GetScriptDirectory()..'/FuncLib/systems/defend')

local bot = GetBot()
local botName = bot:GetUnitName()

function GetDesire()
	if ShouldSkipBotThink(bot) then return 0 end
	return Defend.GetDefendDesire(bot, LANE_BOT)
end
-- function Think()
-- 	if ShouldSkipBotThink(bot) then return end
-- 	Defend.DefendThink(bot, LANE_BOT)
-- end

if SafeCall then
  local _origGetDesire = GetDesire
  local _origThink = Think
  if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'DEFEND_TOWER_BOT_GetDesire') end
  if _origThink then Think = SafeCall(_origThink, nil, 'DEFEND_TOWER_BOT_Think') end
end
