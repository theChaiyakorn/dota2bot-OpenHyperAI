local X = {}

local bot = GetBot()
if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not string.find(bot:GetUnitName(), "hero") then return end

local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')

local AttackingWards = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/attacking_wards')
local PrimalSplit = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/primal_split')
local Familiars = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/familiars')
local Illusion = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/illusions')
local MinionWithSkill = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/minion_with_skill')
local VengefulSprit = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/vengeful_spirit')
local Jugg = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/jugg')
local Customize = require(GetScriptDirectory()..'/Customize/general')

--------------------------------------------------------------------
-- Tiered think frequency for minions.
-- High-tier units (with abilities, worth gold) think frequently.
-- Low-tier units (generic illusions, summons) think less often.
-- All units get to think immediately on first tick (spawn).
--------------------------------------------------------------------

local TIER_HIGH    = 0.3   -- Primal Split, VS scepter illusion, hero illusions with skills
local TIER_MEDIUM  = 0.6   -- Familiars, attacking wards, minions with skills
local TIER_LOW     = 1.1   -- Generic hero illusions, no-skill minions
local TIER_LOWEST  = 1.5   -- Everything else (dominated creeps, etc.)

-- Classify a minion into a think-frequency tier
local function GetMinionTier(hMinionUnit)
	-- Primal Split: high priority (has abilities, time-limited)
	if U.IsPrimalSplit(hMinionUnit) then
		return TIER_HIGH
	end

	-- Vengeful Spirit scepter illusion: high (full hero abilities)
	if hMinionUnit:IsHero() and hMinionUnit:IsIllusion()
	and hMinionUnit:GetUnitName() == 'npc_dota_hero_vengefulspirit' then
		return TIER_HIGH
	end

	-- Familiars: medium (has stun ability)
	if U.IsFamiliar(hMinionUnit) then
		return TIER_MEDIUM
	end

	-- Attacking wards (serpent wards, etc.): medium
	if U.IsAttackingWard(hMinionUnit) then
		return TIER_MEDIUM
	end

	-- Minions with castable skills: medium
	if U.IsMinionWithSkill(hMinionUnit) then
		return TIER_MEDIUM
	end

	-- Hero illusions (PL, Naga, CK, etc.) or no-skill minions: low
	if hMinionUnit:IsHero() and hMinionUnit:IsIllusion() then
		return TIER_LOW
	end
	if U.IsMinionWithNoSkill(hMinionUnit) then
		return TIER_LOW
	end

	-- Everything else
	return TIER_LOWEST
end

-- Quick fallback action for low-tier minions: attack what the owner attacks,
-- or the nearest enemy hero, or the nearest enemy unit.
local function QuickAttack(owner, hMinionUnit)
	-- Follow owner's attack target
	local ownerTarget = owner:GetAttackTarget()
	if ownerTarget and not ownerTarget:IsNull() and ownerTarget:IsAlive()
	and not ownerTarget:IsInvulnerable() and not ownerTarget:IsAttackImmune() then
		local dist = GetUnitToUnitDistance(hMinionUnit, ownerTarget)
		if dist < 1200 then
			hMinionUnit:Action_AttackUnit(ownerTarget, false)
			return
		end
	end

	-- Attack nearest enemy hero
	local enemies = hMinionUnit:GetNearbyHeroes(1000, true, BOT_MODE_NONE)
	if enemies and #enemies > 0 and enemies[1] and not enemies[1]:IsInvulnerable() then
		hMinionUnit:Action_AttackUnit(enemies[1], false)
		return
	end

	-- Attack nearest enemy creep
	local creeps = hMinionUnit:GetNearbyCreeps(800, true)
	if creeps and #creeps > 0 and creeps[1] then
		hMinionUnit:Action_AttackUnit(creeps[1], false)
		return
	end

	-- Nothing to attack — follow owner
	hMinionUnit:Action_MoveToLocation(owner:GetLocation())
end

--------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------

function X.IllusionThink(hMinionUnit)
	return X.MinionThink(hMinionUnit)
end

function X.IsValidUnit(hMinionUnit)
	return U.IsValidUnit(hMinionUnit)
end

function X.HealingWardThink(minion)
	Jugg.HealingWardThink(minion)
end

-- MINION THINK — tiered frequency
function X.MinionThink(hMinionUnit)
	if not hMinionUnit or hMinionUnit:IsNull() or not hMinionUnit:IsAlive() then return end

	-- Determine tier and think frequency
	local tier = hMinionUnit._minionTier
	if tier == nil then
		-- First tick: classify and think immediately (no delay on spawn)
		tier = GetMinionTier(hMinionUnit)
		hMinionUnit._minionTier = tier
		hMinionUnit._minionThinkTime = 0
	end

	-- Throttle by tier
	local lastThink = hMinionUnit._minionThinkTime or 0
	local thinkInterval = tier * (1 + (Customize.ThinkLess or 0))
	if DotaTime() - lastThink < thinkInterval then
		return
	end
	hMinionUnit._minionThinkTime = DotaTime()

	local owner = GetBot()
	if owner == nil then return end

	if not U.IsValidUnit(hMinionUnit) then return end

	if U.CantBeControlled(hMinionUnit) or U.IsShamanFowlPlayChicken(hMinionUnit) then
		return
	end

	-- For lowest tier: just do quick attack, skip full Think logic
	if tier >= TIER_LOWEST then
		QuickAttack(owner, hMinionUnit)
		return
	end

	-- Full Think for higher tiers

	-- Generic illusions / no-skill minions
	if (hMinionUnit:IsHero() and hMinionUnit:IsIllusion() and hMinionUnit:GetUnitName() ~= 'npc_dota_hero_vengefulspirit')
	or U.IsMinionWithNoSkill(hMinionUnit)
	then
		Illusion.Think(owner, hMinionUnit)
		return
	end

	-- Vengeful Spirit Aghanim's Scepter Illusion
	if hMinionUnit:IsHero() and hMinionUnit:IsIllusion()
	and hMinionUnit:GetUnitName() == 'npc_dota_hero_vengefulspirit'
	then
		VengefulSprit.Think(owner, hMinionUnit)
		return
	end

	-- Attacking Wards
	if U.IsAttackingWard(hMinionUnit) then
		AttackingWards.Think(owner, hMinionUnit)
		return
	end

	-- Brewmaster's PrimalSplit
	if U.IsPrimalSplit(hMinionUnit) then
		PrimalSplit.MinionThink(owner, hMinionUnit)
		return
	end

	-- Visage's Familiars
	if U.IsFamiliar(hMinionUnit) then
		Familiars.Think(owner, hMinionUnit)
		return
	end

	-- Spell Casting Minions
	MinionWithSkill.Think(owner, hMinionUnit)
end

return X
