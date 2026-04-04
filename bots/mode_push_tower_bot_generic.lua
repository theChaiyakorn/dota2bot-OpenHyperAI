local Push = require( GetScriptDirectory()..'/FuncLib/systems/push')
local bot = GetBot()
if bot.PushLaneDesire == nil then bot.PushLaneDesire = {0, 0, 0} end

function GetDesire()
    if ShouldSkipBotThink(bot) then return 0 end
    bot.PushLaneDesire[LANE_BOT] = Push.GetPushDesire(bot, LANE_BOT)
    return GetAdjustedDesireValue(bot.PushLaneDesire[LANE_BOT])
end
function Think()
    if ShouldSkipBotThink(bot) then return end
    Push.PushThink(bot, LANE_BOT)
end
