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
		-- Attack override already uses compressed BOT_MODE_DESIRE_* constants (max 0.7)
		-- so no GetAdjustedDesireValue needed. But enforce a hard cap just in case.
		return math.min(local_mode_attack_generic.GetDesire(), BOT_MODE_DESIRE_ABSOLUTE)
	end
	function Think()
		if ShouldSkipBotThink(bot) then return end
		return local_mode_attack_generic.Think()
	end
	function OnStart() return local_mode_attack_generic.OnStart() end
	function OnEnd() return local_mode_attack_generic.OnEnd() end
end

-- SafeCall wrapping for error protection
if SafeCall then
  local _origGetDesire = GetDesire
  local _origThink = Think
  if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'ATTACK_GetDesire') end
  if _origThink then Think = SafeCall(_origThink, nil, 'ATTACK_Think') end
end
