local bot = GetBot()
local botName = bot:GetUnitName()

local Utils = require( GetScriptDirectory()..'/FuncLib/systems/utils')

local local_mode_attack_generic
if not ShouldSkipBotThink(bot) and Utils.BuggyHeroesDueToValveTooLazy[botName] then
	local_mode_attack_generic = dofile( GetScriptDirectory().."/FuncLib/systems/override_generic/mode_attack_generic" )
end

if local_mode_attack_generic ~= nil then
	function GetDesire()
		if ShouldSkipBotThink(bot) then return 0 end
		return local_mode_attack_generic.GetDesire()
	end
	function Think()
		if ShouldSkipBotThink(bot) then return end
		return local_mode_attack_generic.Think()
	end
	function OnStart() return local_mode_attack_generic.OnStart() end
	function OnEnd() return local_mode_attack_generic.OnEnd() end
end
