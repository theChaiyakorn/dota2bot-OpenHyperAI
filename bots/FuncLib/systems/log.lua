-- Shared log module. Installs a global `log(fmt, ...)` usable in any sandbox
-- that requires this file (bot-script, FretBots, Buff — each sandbox has its
-- own `_G`, so each must require it once).
--
-- The global `IsDebug` flag gates output. Set it before or after requiring:
--   IsDebug = true
--   log('hero %s picked', name)
-- When IsDebug is false, log returns immediately without formatting, so
-- callers can pass expensive args as format placeholders with no cost.

local orig_print = print

function _G.log(fmt, ...)
    if not IsDebug then return end
    if select('#', ...) == 0 then
        orig_print(fmt)
    else
        orig_print(string.format(fmt, ...))
    end
end

return { log = _G.log }
