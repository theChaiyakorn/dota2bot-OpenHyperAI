----------------------------------------------------------------------------------------------------
--- Hybrid policy for Sniper's ultimate (Assassinate / sniper_assassinate).
---
--- The RULE layer (in hero_sniper.lua : ConsiderR) still owns:
---   - hard gates: IsFullyCastable, a valid target, cast range
---   - target SELECTION (weakest in range / channeling enemy)
--- The LEARNED layer here only answers ONE question:
---   "Given the situation, how good is firing the ult on this target right now?"  -> desire in [0,1]
---
--- Safety: if no trained weights are present, GetUltDesire returns nil and the caller
--- falls back to the original hand-written heuristic. The bot is never worse than before.
----------------------------------------------------------------------------------------------------

local NN = require(GetScriptDirectory()..'/FunLib/ml/nn')

-- Weights are an optional generated file. pcall so a missing file never crashes the bot.
local model = nil
do
	local ok, w = pcall(function()
		return require(GetScriptDirectory()..'/FunLib/ml/sniper_assassinate_weights')
	end)
	if ok and type(w) == 'table' and w.layers ~= nil then
		model = w
	end
end

local Policy = {}

-- Fire only when the learned desire clears this bar. Tunable / can be exported with the model.
Policy.THRESHOLD = (model and model.threshold) or 0.5

function Policy.IsEnabled()
	return model ~= nil
end

local function clamp01(x)
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

----------------------------------------------------------------------------------------------------
--- FEATURE ORDER -- must match ml/train_sniper_assassinate.py exactly.
---  1 targetHP            target health fraction        0..1
---  2 myMana              caster mana fraction          0..1
---  3 myHP                caster health fraction        0..1
---  4 distNorm            caster->target dist / 3000    0..1
---  5 enemiesNear         #enemy heroes <=1600 / 5      0..1
---  6 alliesNear          #ally heroes  <=1600 / 5      0..1
---  7 willKill            ult lethal on target          0/1
---  8 targetChanneling    target is channeling          0/1
---  9 targetRetreating    target is retreating          0/1
--- 10 timeNorm            DotaTime / 3000               0..1
----------------------------------------------------------------------------------------------------
function Policy.BuildFeatures(J, bot, target, ctx)
	local enemies = J.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE)
	local allies  = J.GetNearbyHeroes(bot, 1600, false, BOT_MODE_NONE)

	local willKill = 0
	if ctx and ctx.damage and ctx.castPoint
		and J.WillMagicKillTarget(bot, target, ctx.damage, ctx.castPoint) then
		willKill = 1
	end

	local channeling = (target.IsChanneling and target:IsChanneling()) and 1 or 0
	local retreating = J.IsRetreating(target) and 1 or 0

	return {
		clamp01(J.GetHP(target)),
		clamp01(bot:GetMana() / bot:GetMaxMana()),
		clamp01(bot:GetHealth() / bot:GetMaxHealth()),
		clamp01(GetUnitToUnitDistance(bot, target) / 3000),
		clamp01(#enemies / 5),
		clamp01(#allies / 5),
		willKill,
		channeling,
		retreating,
		clamp01(DotaTime() / 3000),
	}
end

--- Returns:
---   desire (0..1) if the model says FIRE,
---   0              if the model says HOLD,
---   nil            if no model is loaded (caller must use the heuristic).
function Policy.GetUltDesire(J, bot, target, ctx)
	if model == nil then return nil end
	local features = Policy.BuildFeatures(J, bot, target, ctx)
	local desire = NN.Forward(model, features)
	if desire == nil then return nil end
	if desire >= Policy.THRESHOLD then
		return desire
	end
	return 0
end

return Policy
