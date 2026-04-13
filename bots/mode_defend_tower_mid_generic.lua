local Defend = require( GetScriptDirectory()..'/FuncLib/systems/defend')

local bot = GetBot()

function GetDesire()
	if ShouldSkipBotThink(bot) then return 0 end
	return Defend.GetDefendDesire(bot, LANE_MID)
end
-- function Think()
-- 	if ShouldSkipBotThink(bot) then return end
-- 	Defend.DefendThink(bot, LANE_MID)
-- end

if SafeCall then
  local _origGetDesire = GetDesire
  local _origThink = Think
  if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'DEFEND_TOWER_MID_GetDesire') end
  if _origThink then Think = SafeCall(_origThink, nil, 'DEFEND_TOWER_MID_Think') end
end
