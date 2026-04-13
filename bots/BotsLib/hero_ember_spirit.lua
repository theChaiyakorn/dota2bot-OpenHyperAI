-- Credit goes to Furious Puppy for Bot Experiment

local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

-- Build variant: 1 = magic, 2 = physical
local nBuildVariant = RandomInt(1, 2)

local tAllTalentTreeList = {
	{-- magic
		['t25'] = {0, 10},
		['t20'] = {10, 0},
		['t15'] = {0, 10},
		['t10'] = {10, 0},
	},
	{-- physical
		['t25'] = {0, 10},
		['t20'] = {10, 0},
		['t15'] = {0, 10},
		['t10'] = {0, 10},
	},
}

local tAllAbilityBuildList = {
	{3,2,2,3,2,6,2,1,1,1,1,3,3,6,6},--magic
	{2,1,2,1,2,6,2,1,1,3,6,3,3,3,6},--physical
}

local nAbilityBuildList = tAllAbilityBuildList[nBuildVariant]

local nTalentBuildList = Fu.Skill.GetTalentBuild( tAllTalentTreeList[nBuildVariant] )

local sRoleItemsBuyList = {}
local sRoleSellList = {}

sRoleItemsBuyList['pos_1'] = {
	[1] = {-- magic
		"item_tango",
		"item_double_branches",
		"item_quelling_blade",
		"item_circlet",
		"item_slippers",

		"item_magic_wand",
		"item_phase_boots",
		"item_wraith_band",
		"item_maelstrom",
		"item_kaya_and_sange",--
		"item_black_king_bar",--
		"item_mjollnir",--
		"item_shivas_guard",--
		"item_ultimate_scepter",
		"item_octarine_core",--
		"item_ultimate_scepter_2",
		"item_aghanims_shard",
		"item_moon_shard",
		"item_travel_boots_2",--
	},
	[2] = {-- physical
		"item_tango",
		"item_double_branches",
		"item_quelling_blade",
		"item_circlet",
		"item_slippers",

		"item_magic_wand",
		"item_phase_boots",
		"item_wraith_band",
		"item_bfury",--
		"item_desolator",--
		"item_black_king_bar",--
		"item_greater_crit",--
		"item_aghanims_shard",
		"item_skadi",--
		"item_moon_shard",
		"item_ultimate_scepter_2",
		"item_travel_boots_2",--
	},
}

sRoleSellList['pos_1'] = {
	[1] = {-- magic
		"item_quelling_blade", "item_black_king_bar",
		"item_wraith_band", "item_shivas_guard",
		"item_magic_wand", "item_ultimate_scepter",
	},
	[2] = {-- physical
		"item_wraith_band", "item_greater_crit",
		"item_magic_wand", "item_skadi",
	},
}

sRoleItemsBuyList['pos_2'] = {
	[1] = {-- magic
		"item_tango",
		"item_double_branches",
		"item_faerie_fire",
		"item_quelling_blade",

		"item_bottle",
		"item_magic_wand",
		"item_phase_boots",
		"item_maelstrom",
		"item_mage_slayer",
		"item_kaya",
		"item_black_king_bar",--
		"item_mjollnir",--
		"item_kaya_and_sange",--
		"item_shivas_guard",--
		"item_ultimate_scepter_2",
		"item_octarine_core",--
		"item_aghanims_shard",
		"item_moon_shard",
		"item_travel_boots_2",--
	},
	[2] = {-- physical
		"item_tango",
		"item_double_branches",
		"item_faerie_fire",
		"item_quelling_blade",

		"item_bottle",
		"item_magic_wand",
		"item_boots",
		"item_blight_stone",
		"item_phase_boots",
		"item_bfury",--
		"item_desolator",--
		"item_black_king_bar",--
		"item_greater_crit",--
		"item_aghanims_shard",
		"item_skadi",--
		"item_ultimate_scepter_2",
		"item_moon_shard",
		"item_travel_boots_2",--
	},
}

sRoleSellList['pos_2'] = {
	[1] = {-- magic
		"item_quelling_blade", "item_kaya",
		"item_magic_wand", "item_black_king_bar",
		"item_bottle", "item_shivas_guard",
		"item_mage_slayer", "item_octarine_core",
	},
	[2] = {-- physical
		"item_magic_wand", "item_greater_crit",
		"item_bottle", "item_skadi",
	},
}

X['sBuyList'] = sRoleItemsBuyList[sRole] and sRoleItemsBuyList[sRole][nBuildVariant] or nil
X['sSellList'] = sRoleSellList[sRole] and sRoleSellList[sRole][nBuildVariant] or {}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	if Minion.IsValidUnit( hMinionUnit )
	then
		Minion.IllusionThink( hMinionUnit )
	end
end

local SearingChains 		= SafeAbility(bot:GetAbilityByName("ember_spirit_searing_chains"), 'ember_spirit_searing_chains', 'ember_spirit')
local SleightOfFist 		= SafeAbility(bot:GetAbilityByName("ember_spirit_sleight_of_fist"), 'ember_spirit_sleight_of_fist', 'ember_spirit')
local FlameGuard 			= SafeAbility(bot:GetAbilityByName("ember_spirit_flame_guard"), 'ember_spirit_flame_guard', 'ember_spirit')
local ActivateFireRemnant 	= SafeAbility(bot:GetAbilityByName("ember_spirit_activate_fire_remnant"), 'ember_spirit_activate_fire_remnant', 'ember_spirit')
local FireRemnant 			= SafeAbility(bot:GetAbilityByName("ember_spirit_fire_remnant"), 'ember_spirit_fire_remnant', 'ember_spirit')

local SearingChainsDesire
local SleightOfFistDesire, SleightOfFistLocation
local FlameGuardDesire
local ActivateFireRemnantDesire, ActivateRemnantLocation
local FireRemnantDesire, FireRemnantLocation

-- Combo tracking state
local remnantCast = { time = -100, initialLocation = nil, targetLocation = nil }
local sofCast = { time = -100, location = nil }

local bHasFarmingItem = false
local bAttacking = false
local botTarget
local bGoingOnSomeone
local bRetreating
local nBotHP
local nAllyHeroes, nEnemyHeroes

function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) and not bot:HasModifier('modifier_ember_spirit_sleight_of_fist_caster') then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	nBotHP = ctx.hp

	bHasFarmingItem = Fu.HasItem(bot, 'item_maelstrom') or Fu.HasItem(bot, 'item_mjollnir') or Fu.HasItem(bot, 'item_bfury') or Fu.HasItem(bot, 'item_radiance')
	bAttacking = Fu.IsAttacking(bot)
	botTarget = Fu.GetProperTarget(bot)
	nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE) or {}
	nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE) or {}

	-- SoF returns a combo flag: if true, queue Searing Chains during SoF animation
	local bTrySearingChains
	SleightOfFistDesire, SleightOfFistLocation, bTrySearingChains = X.ConsiderSleightOfFist()
	if SleightOfFistDesire > 0
	then
		sofCast.time = DotaTime()
		sofCast.location = bTrySearingChains and SleightOfFistLocation or nil

		bot:ActionQueue_UseAbilityOnLocation(SleightOfFist, SleightOfFistLocation)
		return
	end

	SearingChainsDesire = X.ConsiderSearingChains()
	if SearingChainsDesire > 0
	then
		bot:Action_UseAbility(SearingChains)
		return
	end

	ActivateFireRemnantDesire, ActivateRemnantLocation = X.ConsiderActivateFireRemnant()
	if ActivateFireRemnantDesire > 0
	then
		bot:ActionQueue_UseAbilityOnLocation(ActivateFireRemnant, ActivateRemnantLocation)
		return
	end

	FireRemnantDesire, FireRemnantLocation = X.ConsiderFireRemnant()
    if FireRemnantDesire > 0
	then
		remnantCast.time = DotaTime()
		remnantCast.initialLocation = bot:GetLocation()
		remnantCast.targetLocation = FireRemnantLocation
		bot:Action_UseAbilityOnLocation(FireRemnant, FireRemnantLocation)
		return
	end

	FlameGuardDesire = X.ConsiderFlameGuard()
	if FlameGuardDesire > 0
	then
		bot:ActionQueue_UseAbility(FlameGuard)
		return
	end
end

----------------------------------------------------------------------
-- Searing Chains (Q)
----------------------------------------------------------------------
function X.ConsiderSearingChains()
	if not Fu.CanCastAbility(SearingChains) then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = SearingChains:GetSpecialValueInt('radius')
	local nDPS = SearingChains:GetSpecialValueInt('damage_per_second')
	local nDuration = SearingChains:GetSpecialValueFloat('duration')
	local nTotalDamage = nDPS * nDuration

	-- During SoF animation: fire chains if near the SoF target location
	if bot:HasModifier('modifier_ember_spirit_sleight_of_fist_caster') and sofCast.location ~= nil then
		if GetUnitToLocationDistance(bot, sofCast.location) <= nRadius then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- Kill check with total damage (DPS * duration), not just per-second
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nRadius)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			if enemyHero:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH
			end

			if Fu.CanKillTarget(enemyHero, nTotalDamage, DAMAGE_TYPE_MAGICAL)
			and not Fu.CanCastAbility(SleightOfFist)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	-- Engaging: use chains when SoF is on cooldown (save for combo when SoF available)
	if bGoingOnSomeone and not Fu.CanCastAbilitySoon(SleightOfFist, 3.0)
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		for _, enemyHero in pairs(nEnemyHeroes)
		do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nRadius)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			then
				if enemyHero:HasModifier('modifier_item_glimmer_cape')
				or enemyHero:HasModifier('modifier_invisible')
				or enemyHero:HasModifier('modifier_item_shadow_amulet_fade')
				then
					if not enemyHero:HasModifier('modifier_item_dustofappearance')
					and not enemyHero:HasModifier('modifier_slardar_amplify_damage')
					and not enemyHero:HasModifier('modifier_bloodseeker_thirst_vision')
					and not enemyHero:HasModifier('modifier_sniper_assassinate')
					and not enemyHero:HasModifier('modifier_bounty_hunter_track')
					then
						return BOT_ACTION_DESIRE_HIGH
					end
				end
			end
		end
	end

	-- Retreating: root chasers
	if bRetreating and not Fu.IsRealInvisible(bot)
	then
		for _, enemy in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemy)
			and Fu.CanBeAttacked(enemy)
			and Fu.IsInRange(bot, enemy, nRadius)
			and Fu.CanCastOnNonMagicImmune(enemy)
			and not enemy:IsDisarmed()
			and not Fu.IsDisabled(enemy)
			and bot:WasRecentlyDamagedByHero(enemy, 3.0)
			then
				if Fu.IsChasingTarget(enemy, bot)
				or (#nEnemyHeroes > #nAllyHeroes)
				or #(bot:GetNearbyHeroes(nRadius - 50, true, BOT_MODE_NONE) or {}) >= 2
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	-- Farming: use chains on creeps when SoF not available and no flame guard active
	local nEnemyCreeps = bot:GetNearbyCreeps(nRadius, true)
	if not bHasFarmingItem and not Fu.CanCastAbility(SleightOfFist) and not bot:HasModifier('modifier_ember_spirit_flame_guard') then
		if Fu.IsPushing(bot) and #nAllyHeroes <= 2 and bAttacking and #nEnemyHeroes <= 1 then
			if #nEnemyCreeps >= 4 then
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		if Fu.IsDefending(bot) and #nAllyHeroes <= 3 and bAttacking and #nEnemyHeroes == 0 then
			if #nEnemyCreeps >= 4 then
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		if Fu.IsFarming(bot) and bAttacking then
			if (#nEnemyCreeps >= 3)
			or (#nEnemyCreeps >= 2 and Fu.IsValid(nEnemyCreeps[1]) and nEnemyCreeps[1]:IsAncientCreep())
			or (#nEnemyCreeps >= 1 and Fu.IsValid(nEnemyCreeps[1]) and nEnemyCreeps[1]:GetHealth() >= 1000)
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	-- Roshan
	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and not Fu.IsDisabled(botTarget)
		and Fu.GetHP(botTarget) > 0.2
		and bAttacking
		and #nEnemyHeroes == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- Tormentor
	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and bAttacking
		and #nEnemyHeroes == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

----------------------------------------------------------------------
-- Sleight of Fist (W) — returns desire, location, bTrySearingChains
----------------------------------------------------------------------
function X.ConsiderSleightOfFist()
	if not Fu.CanCastAbility(SleightOfFist)
	or bot:IsRooted()
	or bot:HasModifier('modifier_ember_spirit_sleight_of_fist_caster')
	then
		return BOT_ACTION_DESIRE_NONE, 0, false
	end

	local nCastRange = SleightOfFist:GetCastRange()
	local nCastPoint = SleightOfFist:GetCastPoint()
	local nRadius = SleightOfFist:GetSpecialValueInt('radius')
	local nBonusDamage = SleightOfFist:GetSpecialValueInt('bonus_hero_damage')
	local nRestoreTime = SleightOfFist:GetSpecialValueInt('AbilityChargeRestoreTime')
	local nHeroDamage = bot:GetAttackDamage() + nBonusDamage
	local nAbilityLevel = SleightOfFist:GetLevel()
	local nManaCost = SleightOfFist:GetManaCost()
	botTarget = Fu.GetProperTarget(bot)

	-- Check if we have enough mana for SoF + Chains combo
	local bHaveEnoughForCombo = false
	if Fu.CanCastAbility(SearingChains) then
		bHaveEnoughForCombo = bot:GetMana() > (SearingChains:GetManaCost() + nManaCost + 75)
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange, 1600), true)

	-- Kill check with protection modifiers
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange + nRadius)
		and Fu.CanKillTarget(enemyHero, nHeroDamage, DAMAGE_TYPE_PHYSICAL)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local vLocation = Fu.IsInRange(bot, enemyHero, nCastRange) and enemyHero:GetLocation() or Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetLocation(), nCastRange)
			return BOT_ACTION_DESIRE_HIGH, vLocation, false
		end
	end

	-- Dodge stun projectiles
	if Fu.IsStunProjectileIncoming(bot, 300)
	then
		if Fu.IsValid(nEnemyCreeps[1]) then
			return BOT_ACTION_DESIRE_HIGH, nEnemyCreeps[1]:GetLocation(), false
		end
		if Fu.IsValidHero(nEnemyHeroes[1]) and Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange + nRadius) then
			local vLocation = Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange) and nEnemyHeroes[1]:GetLocation() or Fu.Site.GetXUnitsTowardsLocation(bot, nEnemyHeroes[1]:GetLocation(), nCastRange)
			return BOT_ACTION_DESIRE_HIGH, vLocation, false
		end
	end

	-- Team fight
	if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
		if nLocationAoE.count >= 3 or #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, true
		end
	end

	-- Engaging: SoF + Chains combo logic
	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			local bShouldChains = not botTarget:IsMagicImmune() and not Fu.IsDisabled(botTarget)

			-- Wait for chains cooldown if target is healthy and we have combo mana
			if not Fu.CanCastAbility(SearingChains) and Fu.CanCastAbilitySoon(SearingChains, 3.0) and Fu.GetHP(botTarget) > 0.25 and bHaveEnoughForCombo then
				return BOT_ACTION_DESIRE_NONE, 0, false
			end

			-- Combo: SoF + Chains when both available
			if Fu.CanCastAbility(SearingChains) and bHaveEnoughForCombo then
				if Fu.IsInRange(bot, botTarget, nCastRange + nRadius / 2) then
					local vLocation = Fu.IsInRange(bot, botTarget, nCastRange) and botTarget:GetLocation() or Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
					return BOT_ACTION_DESIRE_HIGH, vLocation, bShouldChains
				end
			else
				if Fu.IsInRange(bot, botTarget, nCastRange) then
					return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), bShouldChains
				end
			end
		end
	end

	-- Retreating: harass chasers
	if bRetreating and not Fu.IsRealInvisible(bot)
	then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and not Fu.IsInRange(bot, enemyHero, 400)
			and not enemyHero:IsDisarmed()
			and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
			then
				local bShouldChains = not enemyHero:IsMagicImmune() and not Fu.IsDisabled(enemyHero)
				if (Fu.IsChasingTarget(enemyHero, bot) and not Fu.IsSuspiciousIllusion(enemyHero) and Fu.CanCastAbility(SearingChains) and bHaveEnoughForCombo)
				or (#nEnemyHeroes > #nAllyHeroes)
				then
					return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation(), bShouldChains
				end
			end
		end
	end

	-- Pushing: conserve charges (wait for half restore time)
	if Fu.IsPushing(bot) and #nAllyHeroes <= 3 and bAttacking and (DotaTime() >= (sofCast.time + (nRestoreTime / 2)))
	then
		for _, creep in pairs(nEnemyCreeps) do
			if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
				local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
				if nLocationAoE.count >= 4 then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, false
				end
			end
		end
	end

	-- Defending
	if Fu.IsDefending(bot) and bAttacking
	then
		if DotaTime() >= (sofCast.time + (nRestoreTime / 2)) then
			for _, creep in pairs(nEnemyCreeps) do
				if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
					local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
					if nLocationAoE.count >= 4 then
						return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, false
					end
				end
			end
		end

		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
		if nLocationAoE.count >= 3 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, false
		end
	end

	-- Farming: conserve charges, detect ancients
    if Fu.IsFarming(bot) and bAttacking and nAbilityLevel >= 3 and (DotaTime() >= (sofCast.time + (nRestoreTime / 2)))
	then
		for _, creep in pairs(nEnemyCreeps) do
			if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
				local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
				if (nLocationAoE.count >= 3)
				or (nLocationAoE.count >= 2 and creep:IsAncientCreep())
				then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, false
				end
			end
		end
	end

	-- Laning: ranged/siege creep last hits and harass
	if Fu.IsLaning(bot) and Fu.IsInLaningPhase() and Fu.AllowedToSpam(bot, nManaCost)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		for _, creep in pairs(nEnemyLaneCreeps) do
			if Fu.IsValid(creep) and Fu.CanBeAttacked(creep)
			and Fu.CanKillTarget(creep, nBonusDamage, DAMAGE_TYPE_PHYSICAL)
			then
				local sCreepName = creep:GetUnitName()
				if string.find(sCreepName, 'ranged') then
					local nLocationAoE = bot:FindAoELocation(true, true, creep:GetLocation(), 0, nRadius, 0, 0)
					if nLocationAoE.count > 0 or Fu.IsUnitTargetedByTower(creep, false) then
						return BOT_ACTION_DESIRE_HIGH, creep:GetLocation(), false
					end
				end
			end
		end

		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, bot:GetAttackDamage())
		if nLocationAoE.count >= 2 and #nEnemyHeroes > 0 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, false
		end
	end

	-- Roshan: conserve charges
	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.GetHP(botTarget) > 0.2
		and bAttacking
		and #nEnemyHeroes == 0
		and (DotaTime() >= (sofCast.time + (nRestoreTime / 1.5)))
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), false
		end
	end

	-- Tormentor: conserve charges
	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
		and #nEnemyHeroes == 0
		and (DotaTime() >= (sofCast.time + (nRestoreTime / 1.5)))
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), false
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0, false
end

----------------------------------------------------------------------
-- Flame Guard (E) — don't cast during SoF animation
----------------------------------------------------------------------
function X.ConsiderFlameGuard()
	if not Fu.CanCastAbility(FlameGuard)
	or bot:HasModifier('modifier_ember_spirit_sleight_of_fist_caster')
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = FlameGuard:GetSpecialValueInt('radius')
	botTarget = Fu.GetProperTarget(bot)

	if Fu.IsInTeamFight(bot, 1200)
	then
		if bot:WasRecentlyDamagedByAnyHero(1.0) then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		then
			if Fu.CanBeAttacked(botTarget)
			and Fu.CanCastOnNonMagicImmune(botTarget)
			and Fu.IsInRange(bot, botTarget, nRadius)
			and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
			then
				return BOT_ACTION_DESIRE_HIGH
			end

			if bot:WasRecentlyDamagedByAnyHero(2.0)
			or (nBotHP < 0.5 and bot:WasRecentlyDamagedByTower(2.0))
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
		if (nBotHP < 0.6)
		or (#nEnemyHeroes > #nAllyHeroes and bot:WasRecentlyDamagedByAnyHero(1.0))
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- Farming/pushing/defending: only when guard not already active
	local nEnemyCreeps = bot:GetNearbyCreeps(nRadius, true)
	if not bot:HasModifier('modifier_ember_spirit_flame_guard') then
		if Fu.IsPushing(bot) and #nAllyHeroes <= 2 and bAttacking and #nEnemyHeroes == 0 then
			if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) and not bHasFarmingItem then
				if #nEnemyCreeps >= 4 then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end

		if Fu.IsDefending(bot) and #nAllyHeroes <= 3 and bAttacking and #nEnemyHeroes == 0 then
			if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) then
				if (#nEnemyCreeps >= 4 and not bHasFarmingItem) or #nEnemyCreeps >= 6 then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end

		if Fu.IsFarming(bot) and bAttacking and #nEnemyHeroes <= 1 then
			if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) then
				if (#nEnemyCreeps >= 3 or (#nEnemyCreeps >= 2 and nEnemyCreeps[1]:IsAncientCreep()) and bHasFarmingItem)
				or (#nEnemyCreeps >= 5)
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end

			if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) and not bHasFarmingItem then
				if (#nEnemyCreeps >= 3)
				or (#nEnemyCreeps >= 2 and nEnemyCreeps[1]:IsAncientCreep())
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	-- Roshan
	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and bAttacking
		and #nEnemyHeroes == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- Tormentor
	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and bAttacking
		and #nEnemyHeroes == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

----------------------------------------------------------------------
-- Activate Fire Remnant (R2) — jump to placed remnants
----------------------------------------------------------------------
function X.ConsiderActivateFireRemnant()
	if not Fu.CanCastAbility(ActivateFireRemnant)
	or bot:IsRooted()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	-- Timing: don't activate before remnant has arrived at destination
	if remnantCast.initialLocation ~= nil and Fu.CanCastAbility(FireRemnant) then
		local nSpeed_1 = bot:GetCurrentMovementSpeed() * (FireRemnant:GetSpecialValueInt('speed_multiplier') / (bot:HasScepter() and 50 or 100))
		local nSpeed_2 = (ActivateFireRemnant:GetSpecialValueInt('speed')) * (ActivateFireRemnant:GetSpecialValueInt('speed_multiplier') / (bot:HasScepter() and 50 or 100))

		if DotaTime() < remnantCast.time + (Fu.GetDistance(remnantCast.initialLocation, remnantCast.targetLocation) / nSpeed_1) + FireRemnant:GetCastPoint()
							            - ((Fu.GetDistance(remnantCast.initialLocation, remnantCast.targetLocation) / nSpeed_2) + ActivateFireRemnant:GetCastPoint())
		then
			return BOT_ACTION_DESIRE_NONE, 0
		end
	end

	-- Engaging: jump to remnant near target
	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and GetUnitToLocationDistance(botTarget, Fu.GetEnemyFountain()) > 600
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
			local hTarget = nil
			local hTargetDistance = math.huge
			for _, unit in pairs(GetUnitList(UNIT_LIST_ALLIES)) do
				if Fu.IsValid(unit) and unit:GetUnitName() == 'npc_dota_ember_spirit_remnant' then
					local nUnitDistToTarget = GetUnitToUnitDistance(unit, botTarget)
					if hTargetDistance > nUnitDistToTarget
					and nUnitDistToTarget <= 600
					and GetUnitToUnitDistance(bot, unit) >= GetUnitToUnitDistance(bot, botTarget)
					then
						hTarget = unit
						hTargetDistance = nUnitDistToTarget
					end
				end
			end

			local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)

			if hTarget ~= nil then
				if Fu.IsEarlyGame() then
					if (Fu.GetHP(botTarget) < 0.3)
					or (Fu.GetHP(botTarget) < 0.5 and #nInRangeAlly >= 2)
					then
						return BOT_ACTION_DESIRE_HIGH, hTarget:GetLocation()
					end
				else
					return BOT_ACTION_DESIRE_HIGH, hTarget:GetLocation()
				end
			end
		end
	end

	-- Retreating: jump to remnant closer to fountain than bot
	if bRetreating and not Fu.IsRealInvisible(bot) then
		local hTarget = nil
		local hTargetDistance = -math.huge
		for _, unit in pairs(GetUnitList(UNIT_LIST_ALLIES)) do
			if Fu.IsValid(unit) and unit:GetUnitName() == 'npc_dota_ember_spirit_remnant' then
				local nUnitDistToFountain = GetUnitToLocationDistance(unit, Fu.GetTeamFountain())
				local nBotDistToFountain = GetUnitToLocationDistance(bot, Fu.GetTeamFountain())
				local nBotDistToUnit = GetUnitToUnitDistance(bot, unit)

				if nUnitDistToFountain < nBotDistToFountain and hTargetDistance < nBotDistToUnit then
					hTarget = unit
					hTargetDistance = nUnitDistToFountain
				end
			end
		end

		if hTarget ~= nil then
			for _, enemyHero in pairs(nEnemyHeroes) do
				if Fu.IsValidHero(enemyHero)
				and Fu.IsInRange(bot, enemyHero, 1600)
				and not Fu.IsSuspiciousIllusion(enemyHero)
				and not enemyHero:IsDisarmed()
				then
					if Fu.IsChasingTarget(enemyHero, bot)
					or (#nEnemyHeroes > #nAllyHeroes)
					or nBotHP < 0.5
					then
						return BOT_ACTION_DESIRE_HIGH, hTarget:GetLocation()
					end
				end
			end
		end
	end

	-- Check all remnants for opportunistic kills and fountain refill
	for _, unit in pairs(GetUnitList(UNIT_LIST_ALLIES)) do
		if Fu.IsValid(unit) and unit:GetUnitName() == 'npc_dota_ember_spirit_remnant' then
			local nInRangeAlly = Fu.GetAlliesNearLoc(unit:GetLocation(), 1200)
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(unit:GetLocation(), 1200)
			local nBotDistFromRemnant = GetUnitToUnitDistance(bot, unit)

			-- Kill with remnant pass-through damage
			if bGoingOnSomeone and #nInRangeAlly + 1 >= #nInRangeEnemy then
				local bCanKill = X.CanRemnantKill(unit)
				if bCanKill then
					return BOT_ACTION_DESIRE_HIGH, unit:GetLocation()
				end
			end

			-- Fountain refill: jump back from safe remnant
			if not bRetreating and bot:HasModifier('modifier_fountain_aura_buff') and nBotHP > 0.9 and Fu.GetMP(bot) > 0.9 then
				if #nInRangeEnemy == 0 and nBotDistFromRemnant > 4000 then
					return BOT_ACTION_DESIRE_HIGH, unit:GetLocation()
				end
			end

			-- Jump to remnant near team fight
			local vTeamFightLocation = Fu.GetTeamFightLocation(bot)
			if bGoingOnSomeone and #nEnemyHeroes == 0 and vTeamFightLocation ~= nil and GetUnitToLocationDistance(bot, vTeamFightLocation) > 1600 then
				if GetUnitToLocationDistance(unit, vTeamFightLocation) <= 1200 then
					return BOT_ACTION_DESIRE_HIGH, unit:GetLocation()
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------------------
-- Fire Remnant (R1) — place remnants with anti-stacking
----------------------------------------------------------------------
function X.ConsiderFireRemnant()
	if not Fu.CanCastAbility(FireRemnant)
	or not Fu.CanCastAbility(ActivateFireRemnant)
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = FireRemnant:GetCastRange()
	local nCastPoint = FireRemnant:GetCastPoint()
	local nDamage = FireRemnant:GetSpecialValueInt('damage')
	local nSpeed = bot:GetCurrentMovementSpeed() * (FireRemnant:GetSpecialValueInt('speed_multiplier') / (bot:HasScepter() and 50 or 100))

	-- Don't place new remnant before previous one arrives
	if remnantCast.initialLocation ~= nil then
		if DotaTime() < remnantCast.time + (Fu.GetDistance(remnantCast.initialLocation, remnantCast.targetLocation) / nSpeed) + nCastPoint then
			return BOT_ACTION_DESIRE_NONE, 0
		end
	end

	botTarget = Fu.GetProperTarget(bot)

	-- Kill check with protection modifiers and movement prediction
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and GetUnitToLocationDistance(enemyHero, Fu.GetTeamFountain()) > 1200
		and Fu.IsInRange(bot, enemyHero, 1400)
		and not Fu.IsInRange(bot, enemyHero, 400)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_faceless_void_chronosphere')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local nDelay = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
			then
				-- Place remnant ahead of fleeing target
				if Fu.IsChasingTarget(bot, enemyHero) and enemyHero:GetMovementDirectionStability() >= 0.9 then
					local vLocation = Fu.Site.GetXUnitsTowardsLocation(enemyHero, Fu.GetEnemyFountain(), 500)
					if GetUnitToLocationDistance(bot, vLocation) <= 1400 and not X.IsThereRemnantInLocation(vLocation, 500) then
						return BOT_ACTION_DESIRE_HIGH, vLocation
					end
				else
					if not X.IsThereRemnantInLocation(enemyHero:GetLocation(), 500) then
						return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
					end
				end
			end
		end
	end

	-- Engaging: place remnant for gap close + combo setup
	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and GetUnitToLocationDistance(botTarget, Fu.GetTeamFountain()) > 1200
		and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 150)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			local nDelay = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
			local nAllyHeroesTargetingEnemy = Fu.GetHeroesTargetingUnit(nAllyHeroes, botTarget)

			if (Fu.CanCastAbility(SearingChains) and Fu.CanCastAbility(SleightOfFist))
			or (#nAllyHeroesTargetingEnemy >= 2 and (Fu.IsChasingTarget(bot, botTarget) or not Fu.IsInRange(bot, botTarget, 550)))
			or (nBotHP > 0.3 and Fu.GetHP(botTarget) < 0.15)
			then
				local vLocation = botTarget:GetExtrapolatedLocation(nDelay)
				if GetUnitToLocationDistance(bot, vLocation) <= nCastRange and not X.IsThereRemnantInLocation(vLocation, 500) then
					return BOT_ACTION_DESIRE_HIGH, vLocation
				end
			end
		end
	end

	-- Retreating: place escape remnant toward fountain
	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(4.0)
	then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			then
				if Fu.IsChasingTarget(enemyHero, bot)
				or (#nEnemyHeroes > #nAllyHeroes)
				or (nBotHP < 0.4)
				then
					local vLocation = Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), RandomInt(math.floor(nCastRange * 0.75), nCastRange))
					if not X.IsThereRemnantInLocation(bot:GetLocation(), nCastRange) then
						return BOT_ACTION_DESIRE_HIGH, vLocation
					end
				end
			end
        end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

----------------------------------------------------------------------
-- Helper: check if any remnant exists near a location
----------------------------------------------------------------------
function X.IsThereRemnantInLocation(vLocation, nRadius)
	for _, unit in pairs(GetUnitList(UNIT_LIST_ALLIES)) do
		if unit ~= nil
		and unit:GetUnitName() == 'npc_dota_ember_spirit_remnant'
		and GetUnitToLocationDistance(unit, vLocation) <= nRadius
		then
			return true
		end
	end
	return false
end

----------------------------------------------------------------------
-- Helper: check if activating a specific remnant would kill an enemy
----------------------------------------------------------------------
function X.CanRemnantKill(unit)
	if not Fu.CanCastAbility(FireRemnant) then return false end
	local nCastPoint = FireRemnant:GetCastPoint()
	local nSpeed = ActivateFireRemnant:GetSpecialValueInt('speed')
	local nDamage = FireRemnant:GetSpecialValueInt('damage')
	local nDamageRadius = FireRemnant:GetSpecialValueInt('radius')

	for _, enemyHero in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and GetUnitToLocationDistance(enemyHero, Fu.GetTeamFountain()) > 600
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local nDelay = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL) then
				local distToPath = GetUnitToUnitDistance(enemyHero, unit)
				if distToPath <= nDamageRadius and GetUnitToUnitDistance(bot, enemyHero) <= 1400 then
					return true
				end
			end
		end
	end

	return false
end

return X
