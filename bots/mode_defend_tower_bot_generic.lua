local Defend = require( GetScriptDirectory()..'/FuncLib/systems/defend')

local bot = GetBot()
local botName = bot:GetUnitName()

function GetDesire()
	if ShouldSkipBotThink(bot) then return 0 end
	return GetAdjustedDesireValue(Defend.GetDefendDesire(bot, LANE_BOT))
end
function Think()
	if ShouldSkipBotThink(bot) then return end
	Defend.DefendThink(bot, LANE_BOT)
end
