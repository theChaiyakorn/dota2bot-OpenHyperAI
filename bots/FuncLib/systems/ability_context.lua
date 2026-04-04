--------------------------------------------------------------------
-- ability_context.lua
-- Shared precomputed context for hero ability decision-making.
-- Called once per SkillsComplement() tick to avoid redundant API calls.
--------------------------------------------------------------------
local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')

local AbilityContext = {}

-- Build a context table with common queries precomputed.
-- Pass this to Consider functions instead of each one querying independently.
function AbilityContext.Build(bot)
	local ctx = {
		bot         = bot,
		target      = Fu.GetProperTarget(bot),
		enemies     = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE) or {},
		allies      = Fu.GetNearbyHeroes(bot, 1600, false, BOT_MODE_NONE) or {},
		hp          = Fu.GetHP(bot),
		mp          = Fu.GetMP(bot),
		level       = bot:GetLevel(),
		mana        = bot:GetMana(),
		maxMana     = bot:GetMaxMana(),
		attackRange = bot:GetAttackRange(),
		isRetreating = Fu.IsRetreating(bot),
		isTeamFight  = Fu.IsInTeamFight(bot, 1200),
		isEngaging   = Fu.IsGoingOnSomeone(bot),
	}

	-- Aether lens range bonus (common check across many heroes)
	ctx.aetherRange = 0
	local aether = Fu.IsItemAvailable("item_aether_lens")
	if aether ~= nil then ctx.aetherRange = 250 end

	return ctx
end

return AbilityContext
