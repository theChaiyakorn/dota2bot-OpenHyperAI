----------------------------------------------------------------------------------------------------
--- Shared hybrid laning policy for ALL heroes: last-hit (step-up) + deny + HP-trade.
---
--- The features are hero-agnostic on purpose -- they use ratios (damage/creepHP, range
--- advantage, HP fractions, counts), so ONE shared model per decision serves every hero and
--- pools training data across all of them. No per-hero weights.
---
--- The RULE layer (mode_laning_generic.lua) still owns:
---   - GUARANTEED last-hits (WillKillTarget with current damage) -> always taken, never gated
---   - candidate SELECTION (which creep / which enemy) and hard gates
--- The LEARNED layer here answers only the judgement calls where rules are crude:
---   - LastHitCommit: step forward into harass for a not-yet-guaranteed last hit?
---   - DenyCommit:    step up to deny this ally creep now?
---   - TradeCommit:   trade HP / harass this enemy hero now?
---
--- Safety: missing weights -> Commit returns nil -> caller keeps the original heuristic.
----------------------------------------------------------------------------------------------------

local NN = require(GetScriptDirectory()..'/FunLib/ml/nn')

local function loadModel(name)
	local ok, w = pcall(function()
		return require(GetScriptDirectory()..'/FunLib/ml/'..name)
	end)
	if ok and type(w) == 'table' and w.layers ~= nil then return w end
	return nil
end

local lastHitModel = loadModel('laning_lasthit_weights')
local denyModel    = loadModel('laning_deny_weights')
local tradeModel   = loadModel('laning_trade_weights')

local Policy = {}

-- Which heroes use the shared ML laning policy. '*' = all heroes. To curate instead, set
-- ENABLED_HEROES = { ['npc_dota_hero_pangolier'] = true, ['npc_dota_hero_riki'] = true, ... }
Policy.ENABLED_HEROES = { ['*'] = true }

function Policy.IsHeroEnabled(name)
	return Policy.ENABLED_HEROES['*'] == true or Policy.ENABLED_HEROES[name] == true
end

local function clamp01(x)
	if x < 0 then return 0 end
	if x > 1 then return 1 end
	return x
end

function Policy.IsLastHitEnabled() return lastHitModel ~= nil end
function Policy.IsDenyEnabled()    return denyModel ~= nil end
function Policy.IsTradeEnabled()   return tradeModel ~= nil end

----------------------------------------------------------------------------------------------------
--- LAST-HIT step-up features (order must match ml/train_laning_ml.py):
---  1 creepHP  2 dmgRatio  3 enemiesNear  4 alliesNear  5 myHP  6 timeNorm
----------------------------------------------------------------------------------------------------
function Policy.BuildLastHitFeatures(J, bot, creep, ctx)
	local dmg = (ctx and ctx.attackDamage) or bot:GetAttackDamage()
	local enemies = J.GetNearbyHeroes(bot, 900, true, BOT_MODE_NONE)
	local allies  = J.GetNearbyHeroes(bot, 900, false, BOT_MODE_NONE)
	return {
		clamp01(J.GetHP(creep)),
		clamp01((dmg / math.max(1, creep:GetHealth())) / 2),
		clamp01(#enemies / 3),
		clamp01(#allies / 3),
		clamp01(bot:GetHealth() / bot:GetMaxHealth()),
		clamp01(DotaTime() / 900),
	}
end

----------------------------------------------------------------------------------------------------
--- DENY features:  1 creepHP  2 dmgRatio  3 enemiesNear  4 myHP  5 timeNorm
----------------------------------------------------------------------------------------------------
function Policy.BuildDenyFeatures(J, bot, creep, ctx)
	local dmg = (ctx and ctx.attackDamage) or bot:GetAttackDamage()
	local enemies = J.GetNearbyHeroes(bot, 900, true, BOT_MODE_NONE)
	return {
		clamp01(J.GetHP(creep)),
		clamp01((dmg / math.max(1, creep:GetHealth())) / 2),
		clamp01(#enemies / 3),
		clamp01(bot:GetHealth() / bot:GetMaxHealth()),
		clamp01(DotaTime() / 900),
	}
end

----------------------------------------------------------------------------------------------------
--- HP-TRADE (harass) features:
---  1 myHP  2 enemyHP  3 rangeAdv  4 distNorm  5 enemyCreepsNear
---  6 enemiesNear  7 alliesNear  8 enemyBusy  9 timeNorm
----------------------------------------------------------------------------------------------------
function Policy.BuildTradeFeatures(J, bot, target, ctx)
	local enemyCreeps = bot:GetNearbyLaneCreeps(400, true)
	local enemies     = J.GetNearbyHeroes(bot, 900, true, BOT_MODE_NONE)
	local allies      = J.GetNearbyHeroes(bot, 900, false, BOT_MODE_NONE)

	local rangeAdv = clamp01(((bot:GetAttackRange() - target:GetAttackRange()) / 600) + 0.5)
	local at = target.GetAttackTarget and target:GetAttackTarget() or nil
	local enemyBusy = (at ~= nil and not at:IsHero()) and 1 or 0

	return {
		clamp01(bot:GetHealth() / bot:GetMaxHealth()),
		clamp01(J.GetHP(target)),
		rangeAdv,
		clamp01(GetUnitToUnitDistance(bot, target) / 900),
		clamp01(#enemyCreeps / 4),
		clamp01(#enemies / 3),
		clamp01(#allies / 3),
		enemyBusy,
		clamp01(DotaTime() / 900),
	}
end

local function gate(model, features)
	if model == nil then return nil end
	local d = NN.Forward(model, features)
	if d == nil then return nil end
	if d >= (model.threshold or 0.5) then return d end
	return 0
end

function Policy.LastHitCommit(J, bot, creep, ctx)
	if lastHitModel == nil then return nil end
	return gate(lastHitModel, Policy.BuildLastHitFeatures(J, bot, creep, ctx))
end

function Policy.DenyCommit(J, bot, creep, ctx)
	if denyModel == nil then return nil end
	return gate(denyModel, Policy.BuildDenyFeatures(J, bot, creep, ctx))
end

function Policy.TradeCommit(J, bot, target, ctx)
	if tradeModel == nil then return nil end
	return gate(tradeModel, Policy.BuildTradeFeatures(J, bot, target, ctx))
end

return Policy
