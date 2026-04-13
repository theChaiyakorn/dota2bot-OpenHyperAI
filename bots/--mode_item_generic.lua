local bot = GetBot()
local botName = bot:GetUnitName()
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

--[[
 * Hey Valve team, if anyone from the official side is reading this,
 * could you please look into the rune pickup bugs?
 *
 * Action_PickUpRune() appears to fail silently with no error output,
 * and bots can randomly fail to pick up runes. The behavior is very
 * unstable and easy to reproduce.
 *
 * If bots rely only on mode_rune_generic for rune handling, they can
 * fail to pick up even the initial river runes.
 *
 * Right now, bots are still able to pick up runes because of the
 * built-in item mode in the engine. But that creates another problem:
 * it means we cannot properly override item mode ourselves.
 *
 * I noticed you have enabled bots to pick neutral items, which is 
 * smart, but can you please privde the APIs for the actions?
 *
 * The default item mode provided by the engine also has many issues
 * with inventory and item handling. For example, it can fail to swap
 * items correctly when a hero has 6 slots occupied, fail to handle
 * Cheese properly, and keep swapping items unnecessarily.
]]
function GetDesire()
	return BOT_MODE_DESIRE_NONE
end
