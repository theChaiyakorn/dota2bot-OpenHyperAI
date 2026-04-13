local bot = GetBot()
local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )

function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end

	-- Don't evade from serpent wards — they're stationary and not worth fleeing from.
	local hasSerpentWard = false
	for _, u in pairs(GetUnitList(UNIT_LIST_ENEMIES)) do
		if Fu.IsValid(u) and GetUnitToUnitDistance(bot, u) < 1200
		and string.find(u:GetUnitName(), 'shadow_shaman_ward') then
			hasSerpentWard = true
			break
		end
	end
	if hasSerpentWard then
		return BOT_MODE_DESIRE_NONE
	end
end
