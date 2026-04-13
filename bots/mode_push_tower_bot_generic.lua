local Push = require( GetScriptDirectory()..'/FuncLib/systems/push')
local bot = GetBot()
if bot.PushLaneDesire == nil then bot.PushLaneDesire = {0, 0, 0} end

function GetDesire()
    if ShouldSkipBotThink(bot) then return 0 end
	return Push.GetPushDesire(bot, LANE_BOT)
end
function Think()
    if ShouldSkipBotThink(bot) then return end
    Push.PushThink(bot, LANE_BOT)
end

if SafeCall then
  local _origGetDesire = GetDesire
  local _origThink = Think
  if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'PUSH_TOWER_BOT_GetDesire') end
  if _origThink then Think = SafeCall(_origThink, nil, 'PUSH_TOWER_BOT_Think') end
end
