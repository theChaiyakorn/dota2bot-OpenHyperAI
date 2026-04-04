local Push = require( GetScriptDirectory()..'/FuncLib/systems/push')
local bot = GetBot()
if bot.PushLaneDesire == nil then bot.PushLaneDesire = {0, 0, 0} end

function GetDesire()
    if ShouldSkipBotThink(bot) then return 0 end
    bot.PushLaneDesire[LANE_MID] = Push.GetPushDesire(bot, LANE_MID)
    return GetAdjustedDesireValue(bot.PushLaneDesire[LANE_MID])
end
function Think()
    if ShouldSkipBotThink(bot) then return end
    Push.PushThink(bot, LANE_MID)
end
