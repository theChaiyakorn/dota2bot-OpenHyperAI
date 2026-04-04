local Defend = require( GetScriptDirectory()..'/FuncLib/systems/defend')

local bot = GetBot()

function GetDesire()
	if ShouldSkipBotThink(bot) then return 0 end
	return GetAdjustedDesireValue(Defend.GetDefendDesire(bot, LANE_MID))
end
function Think()
	if ShouldSkipBotThink(bot) then return end
	Defend.DefendThink(bot, LANE_MID)
end
