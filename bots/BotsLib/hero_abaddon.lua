local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
	{-- pos1/2
		['t25'] = {10, 0},
		['t20'] = {0, 10},
		['t15'] = {0, 10},
		['t10'] = {10, 0},
	},
	{-- pos3
		['t25'] = {0, 10},
		['t20'] = {10, 0},
		['t15'] = {0, 10},
		['t10'] = {10, 0},
	},
	{-- pos4/5
		['t25'] = {10, 0},
		['t20'] = {0, 10},
		['t15'] = {10, 0},
		['t10'] = {10, 0},
	},
}

local tAllAbilityBuildList = {
	{2,3,2,3,2,6,2,3,3,1,6,1,1,1,6},-- pos1/2/3: max W, then E, then Q
	{2,3,2,1,2,6,2,1,1,1,6,3,3,3,6},-- pos4/5: max W, then Q, then E
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_1" or sRole == "pos_2" then
	nAbilityBuildList = tAllAbilityBuildList[1]
	nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
elseif sRole == "pos_3" then
	nAbilityBuildList = tAllAbilityBuildList[1]
	nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
else
	nAbilityBuildList = tAllAbilityBuildList[2]
	nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[3])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_circlet",
	"item_mantle",

	"item_magic_wand",
	"item_null_talisman",
	"item_phase_boots",
	"item_echo_sabre",
	"item_manta",--
	"item_harpoon",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_bloodthorn",--
	"item_abyssal_blade",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_magic_stick",
	"item_faerie_fire",

	"item_phase_boots",
	"item_magic_wand",
	"item_blade_mail",
	"item_radiance",--
	"item_pipe",--
	"item_aghanims_shard",
	"item_assault",--
	"item_lotus_orb",--
	"item_ultimate_scepter_2",
	"item_abyssal_blade",--
	"item_travel_boots_2",--
	"item_moon_shard",
}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_magic_stick",
	"item_faerie_fire",

	"item_tranquil_boots",
	"item_magic_wand",
	"item_blade_mail",
	"item_solar_crest",--
	"item_glimmer_cape",--
	"item_boots_of_bearing",--
	"item_ultimate_scepter",
	"item_aghanims_shard",
	"item_lotus_orb",--
	"item_sheepstick",--
	"item_ultimate_scepter_2",
	"item_wind_waker",--
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_magic_stick",
	"item_faerie_fire",

	"item_arcane_boots",
	"item_magic_wand",
	"item_blade_mail",
	"item_solar_crest",--
	"item_glimmer_cape",--
	"item_guardian_greaves",--
	"item_ultimate_scepter",
	"item_aghanims_shard",
	"item_lotus_orb",--
	"item_sheepstick",--
	"item_ultimate_scepter_2",
	"item_wind_waker",--
	"item_moon_shard",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_black_king_bar", "item_quelling_blade",
	"item_lotus_orb", "item_magic_wand",
	"item_wind_waker", "item_blade_mail",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local MistCoil          = SafeAbility(bot:GetAbilityByName('abaddon_death_coil'), 'abaddon_death_coil', 'abaddon')
local AphoticShield     = SafeAbility(bot:GetAbilityByName('abaddon_aphotic_shield'), 'abaddon_aphotic_shield', 'abaddon')

local MistCoilDesire, MistCoilTarget
local AphoticShieldDesire, AphoticShieldTarget

local bAttacking = false
local botTarget, botHP
local nAllyHeroes, nEnemyHeroes

function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	-- Re-fetch ability handles each tick for Aghs safety
	MistCoil = SafeAbility(bot:GetAbilityByName('abaddon_death_coil'), 'abaddon_death_coil', 'abaddon')
	AphoticShield = SafeAbility(bot:GetAbilityByName('abaddon_aphotic_shield'), 'abaddon_aphotic_shield', 'abaddon')

	bAttacking = Fu.IsAttacking(bot)
	botHP = Fu.GetHP(bot)
	botTarget = Fu.GetProperTarget(bot)
	nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
	nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	AphoticShieldDesire, AphoticShieldTarget = X.ConsiderAphoticShield()
	if AphoticShieldDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnEntity(AphoticShield, AphoticShieldTarget)
		return
	end

	MistCoilDesire, MistCoilTarget = X.ConsiderMistCoil()
	if MistCoilDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnEntity(MistCoil, MistCoilTarget)
		return
	end
end

function X.ConsiderMistCoil()
	if not Fu.CanCastAbility(MistCoil) then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, MistCoil:GetCastRange())
	local nCastPoint = MistCoil:GetCastPoint()
	local nDamage = MistCoil:GetSpecialValueInt('target_damage')
	local nSpeed = MistCoil:GetSpecialValueInt('missile_speed')
	local nManaCost = MistCoil:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {AphoticShield})

	-- Kill check with projectile ETA
	for _, enemyHero in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange)
		and Fu.CanCastOnMagicImmune(enemyHero)
		and Fu.CanCastOnTargetAdvanced(enemyHero)
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end

	-- Heal lowest HP ally
	local hTargetAlly = nil
	local hTargetAllyHealth = math.huge
	for _, allyHero in pairs(nAllyHeroes) do
		if Fu.IsValidHero(allyHero)
		and Fu.CanBeAttacked(allyHero)
		and Fu.IsInRange(bot, allyHero, nCastRange + 200)
		and allyHero ~= bot
		and not allyHero:IsIllusion()
		and not allyHero:HasModifier('modifier_doom_bringer_doom_aura_enemy')
		and not allyHero:HasModifier('modifier_ice_blast')
		and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not allyHero:HasModifier('modifier_fountain_aura_buff')
		and not allyHero:HasModifier('modifier_rune_regen')
		then
			local allyHP = Fu.GetHP(allyHero)
			if allyHP < hTargetAllyHealth and allyHP <= 0.8 then
				hTargetAlly = allyHero
				hTargetAllyHealth = allyHP
			end

			-- Priority: heal disabled ally that's taking damage
			if allyHero:WasRecentlyDamagedByAnyHero(2.0) and Fu.IsDisabled(allyHero) and allyHP < 0.8 then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end
		end
	end

	if hTargetAlly then
		return BOT_ACTION_DESIRE_HIGH, hTargetAlly
	end

	-- Laning last-hits with MistCoil
	if Fu.IsLaning(bot) and Fu.IsEarlyGame() and fManaAfter > fManaThreshold1 + 0.1 then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(math.min(nCastRange + 300, 1600), true)

		for _, creep in pairs(nEnemyLaneCreeps) do
			if Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and not Fu.IsOtherAllysTarget(creep)
			then
				local eta = (GetUnitToUnitDistance(bot, creep) / nSpeed) + nCastPoint
				if Fu.WillKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
					local sCreepName = creep:GetUnitName()
					local nLocationAoE = bot:FindAoELocation(true, true, creep:GetLocation(), 0, 800, 0, 0)
					if string.find(sCreepName, 'ranged') then
						if nLocationAoE.count > 0 or Fu.IsUnitTargetedByTower(creep, false) then
							return BOT_ACTION_DESIRE_HIGH, creep
						end
					end

					if Fu.IsEnemyTargetUnit(creep, 1200) and fManaAfter > fManaThreshold1 + 0.2 then
						return BOT_ACTION_DESIRE_HIGH, creep
					end
				end
			end
		end
	end

	-- Roshan
	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
		and fManaAfter > 0.5
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	-- Tormentor
	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
		and fManaAfter > 0.5
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAphoticShield()
	if not Fu.CanCastAbility(AphoticShield) then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, AphoticShield:GetCastRange())
	local nManaCost = AphoticShield:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {MistCoil})

	for _, allyHero in pairs(nAllyHeroes) do
		if Fu.IsValidHero(allyHero)
		and Fu.CanBeAttacked(allyHero)
		and Fu.IsInRange(bot, allyHero, nCastRange + 300)
		and not allyHero:IsIllusion()
		and not allyHero:HasModifier('modifier_abaddon_aphotic_shield')
		and not allyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not allyHero:HasModifier('modifier_doom_bringer_doom_aura_enemy')
		and not allyHero:HasModifier('modifier_ice_blast')
		and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not allyHero:HasModifier('modifier_fountain_aura_buff')
		and not allyHero:HasModifier('modifier_rune_regen')
		then
			local allyHP = Fu.GetHP(allyHero)

			-- Duel: immediate
			if allyHero:HasModifier('modifier_legion_commander_duel') then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end

			-- Disabled: immediate
			if Fu.IsDisabled(allyHero) then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end

			-- Going on someone: shield engaging ally
			if Fu.IsGoingOnSomeone(allyHero) then
				local allyTarget = Fu.GetProperTarget(allyHero)
				if Fu.IsValidHero(allyTarget)
				and Fu.IsInRange(allyHero, allyTarget, allyHero:GetAttackRange() + 300)
				and not Fu.IsSuspiciousIllusion(allyTarget)
				then
					if allyHP < 0.4 or fManaAfter > fManaThreshold1 + 0.1 then
						return BOT_ACTION_DESIRE_HIGH, allyHero
					end
				end
			end

			-- Retreating ally: shield if taking damage
			if Fu.IsRetreating(allyHero) and not Fu.IsRealInvisible(allyHero) then
				if allyHero:WasRecentlyDamagedByAnyHero(2.0) and allyHP < 0.75 then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end

			-- Roshan: shield lowest HP ally
			if Fu.IsDoingRoshan(bot) then
				if Fu.IsRoshan(botTarget)
				and Fu.IsInRange(bot, botTarget, 800)
				and bAttacking
				and allyHP < 0.5
				then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end

			-- Tormentor: shield lowest HP ally
			if Fu.IsDoingTormentor(bot) then
				if Fu.IsTormentor(botTarget)
				and Fu.IsInRange(bot, botTarget, 800)
				and bAttacking
				and allyHP < 0.5
				then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end

			-- Generic: ally taking damage and low
			if allyHero:WasRecentlyDamagedByAnyHero(2.0) and allyHP < 0.4 and fManaAfter > fManaThreshold1 + 0.1 then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end
		end
	end

	-- Self-shield when retreating
	if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
		if bot:WasRecentlyDamagedByAnyHero(2.0) and botHP < 0.75 then
			return BOT_ACTION_DESIRE_HIGH, bot
		end
	end

	-- Self-shield when farming with low HP
	if Fu.IsFarming(bot) and bAttacking and fManaAfter > fManaThreshold1 + 0.1 then
		local nEnemyCreeps = bot:GetNearbyCreeps(1600, true)
		if #nEnemyCreeps > 0
		and botHP < 0.5
		and not bot:HasModifier('modifier_abaddon_aphotic_shield')
		and not bot:HasModifier('modifier_abaddon_borrowed_time')
		then
			return BOT_ACTION_DESIRE_HIGH, bot
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

return X
