local Customize = nil
function LoadCustomize()
	if Customize then return Customize end
	local sDir, tSet = "game/Customize/general", nil
	local status, _ = xpcall(function() tSet = require( sDir ) end, function( err ) if log then log('[WARN] When loading customized file: %s', err) else print('[WARN] When loading customized file: '..tostring(err)) end end )
	if status and tSet then
		Customize = tSet
	else
		if GetScriptDirectory() == 'bots' then Customize = require('bots.Customize.general')
		else Customize = require( GetScriptDirectory()..'/Customize/general' ) end
	end
	return Customize
end
return LoadCustomize()
