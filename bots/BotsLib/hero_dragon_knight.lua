local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos2
							['t25'] = {10, 0},
							['t20'] = {0, 10},
							['t15'] = {10, 0},
							['t10'] = {0, 10},
						},
						{--pos3
							['t25'] = {10, 0},
							['t20'] = {0, 10},
							['t15'] = {10, 0},
							['t10'] = {0, 10},
						},
}

local tAllAbilityBuildList = {
	{1,2,1,3,3,6,3,3,1,1,6,2,2,2,6},--pos2
	{1,2,3,3,3,6,3,1,1,1,6,2,2,2,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_circlet",
	"item_gauntlets",

	"item_bottle",
	"item_magic_wand",
	"item_bracer",
	"item_power_treads",
	"item_maelstrom",
	"item_dragon_lance",
	"item_black_king_bar",--
	"item_mjollnir",--
	"item_aghanims_shard",
	"item_greater_crit",--
	"item_hurricane_pike",--
	"item_assault",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_circlet",
	"item_gauntlets",

	"item_magic_wand",
	"item_bracer",
	"item_power_treads",
	"item_armlet",
	"item_yasha",
	"item_black_king_bar",--
	"item_sange_and_yasha",--
	"item_greater_crit",--
	"item_aghanims_shard",
	"item_satanic",--
	"item_ultimate_scepter_2",
	"item_bloodthorn",--
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_circlet",
	"item_gauntlets",

	"item_magic_wand",
	"item_bracer",
	"item_power_treads",
	"item_orchid",
	"item_crimson_guard",--
	"item_black_king_bar",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
	"item_overwhelming_blink",--
	"item_bloodthorn",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_travel_boots_2",--
}

X['sBuyList'] = sRoleItemsBuyList[sRole]
X['sSellList'] = {

	"item_power_treads", "item_quelling_blade",

	"item_crimson_guard", "item_quelling_blade",
	"item_black_king_bar", "item_magic_wand",
	"item_heavens_halberd", "item_bracer",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )


X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_dragon_knight

"Ability1"		"dragon_knight_breathe_fire"
"Ability2"		"dragon_knight_dragon_tail"
"Ability3"		"dragon_knight_dragon_blood"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"dragon_knight_elder_dragon_form"
"Ability10"		"special_bonus_mp_regen_3"
"Ability11"		"special_bonus_unique_dragon_knight_3"
"Ability12"		"special_bonus_attack_damage_30"
"Ability13"		"special_bonus_hp_350"
"Ability14"		"special_bonus_gold_income_30"
"Ability15"		"special_bonus_strength_25"
"Ability16"		"special_bonus_unique_dragon_knight"
"Ability17"		"special_bonus_unique_dragon_knight_2"

modifier_dragonknight_breathefire_reduction
modifier_dragon_knight_dragon_blood_aura
modifier_dragon_knight_dragon_blood
modifier_dragon_knight_dragon_form
modifier_dragon_knight_corrosive_breath
modifier_dragon_knight_corrosive_breath_dot
modifier_dragon_knight_splash_attack
modifier_dragon_knight_frost_breath
modifier_dragon_knight_frost_breath_slow

--]]
local BreatheFire = SafeAbility(bot:GetAbilityByName('dragon_knight_breathe_fire'), 'dragon_knight_breathe_fire', 'dragon_knight')
local DragonTail = SafeAbility(bot:GetAbilityByName('dragon_knight_dragon_tail'), 'dragon_knight_dragon_tail', 'dragon_knight')
-- local WrymsWrath = bot:GetAbilityByName('dragon_knight_dragon_blood')
local Fireball = SafeAbility(bot:GetAbilityByName('dragon_knight_fireball'), 'dragon_knight_fireball', 'dragon_knight')
local ElderDragonForm = SafeAbility(bot:GetAbilityByName('dragon_knight_elder_dragon_form'), 'dragon_knight_elder_dragon_form', 'dragon_knight')

local BreatheFireDesire, BreatheFireLocation
local DragonTailDesire, DragonTailTarget
local FireballDesire, FireballLocation
local ElderDragonFormDesire

local bInDragonForm = false
local bAttacking = false
local botTarget, botHP
local nAllyHeroes, nEnemyHeroes

local bGoingOnSomeone
local bRetreating
local bInTeamFight
function X.SkillsComplement()
	bot = GetBot()

	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bInTeamFight = ctx.isTeamFight

	BreatheFire = SafeAbility(bot:GetAbilityByName('dragon_knight_breathe_fire'), 'dragon_knight_breathe_fire', 'dragon_knight')
	DragonTail = SafeAbility(bot:GetAbilityByName('dragon_knight_dragon_tail'), 'dragon_knight_dragon_tail', 'dragon_knight')
	Fireball = SafeAbility(bot:GetAbilityByName('dragon_knight_fireball'), 'dragon_knight_fireball', 'dragon_knight')
	ElderDragonForm = SafeAbility(bot:GetAbilityByName('dragon_knight_elder_dragon_form'), 'dragon_knight_elder_dragon_form', 'dragon_knight')

	bInDragonForm = bot:HasModifier('modifier_dragon_knight_dragon_form')
	bAttacking = Fu.IsAttacking(bot)
    botHP = ctx.hp
    botTarget = ctx.target
    nAllyHeroes = ctx.allies
    nEnemyHeroes = ctx.enemies

	ElderDragonFormDesire = X.ConsiderElderDragonForm()
	if ElderDragonFormDesire> 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbility(ElderDragonForm)
		return
	end

	BreatheFireDesire, BreatheFireLocation = X.ConsiderBreatheFire()
	if BreatheFireDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(BreatheFire, BreatheFireLocation)
		return
	end

	DragonTailDesire, DragonTailTarget = X.ConsiderDragonTail()
	if DragonTailDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnEntity(DragonTail, DragonTailTarget)
		return
	end

	FireballDesire, FireballLocation = X.ConsiderFireball()
	if FireballDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(Fireball, FireballLocation)
		return
	end
end

function X.ConsiderBreatheFire()
	if not Fu.CanCastAbility(BreatheFire) then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, BreatheFire:GetCastRange())
	local nCastPoint = BreatheFire:GetCastPoint()
	local nRadius = BreatheFire:GetSpecialValueInt('end_radius')
	local nDamage = BreatheFire:GetSpecialValueInt('damage')
	local nSpeed = BreatheFire:GetSpecialValueInt('speed')
	local nManaCost = BreatheFire:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {BreatheFire, DragonTail, Fireball, ElderDragonForm})
	local fManaThreshold2 = Fu.GetManaThreshold(bot, nManaCost, {DragonTail, ElderDragonForm})

	for _, enemyHero in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange + 150)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		then
			local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end
		end
	end

	if bInTeamFight then
		local hTarget = nil
		local hTargetDamage = 0
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange - 150)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_dragonknight_breathefire_reduction')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			then
				local enemyHeroDamage = enemyHero:GetEstimatedDamageToTarget(false, bot, 3.0, DAMAGE_TYPE_PHYSICAL)
				if enemyHeroDamage > hTargetDamage then
					hTarget = enemyHero
					hTargetDamage = enemyHeroDamage
				end
			end
		end

		if hTarget ~= nil then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(hTarget, nCastPoint)
		end

		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius - 30, 0, 0)
		if nLocationAoE.count >= 2 and fManaAfter > fManaThreshold2 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange - 150)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			if Fu.CanCastAbility(ElderDragonForm) then
				if fManaAfter > fManaThreshold2 then
					return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(botTarget, nCastPoint)
				end
			else
				return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(botTarget, nCastPoint)
			end
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(4.0) then
		for _, enemyHero in pairs(nEnemyHeroes) do
            if  Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not enemyHero:IsDisarmed()
			and not enemyHero:HasModifier('modifier_dragonknight_breathefire_reduction')
            then
                if Fu.IsChasingTarget(enemyHero, bot) or (#nEnemyHeroes > #nAllyHeroes and enemyHero:GetAttackTarget() == bot) then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                end
            end
        end

		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange - 100, nRadius, 0, 0)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
		if #nInRangeEnemy >= 2 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange + 300, 1600), true)

	if Fu.IsPushing(bot) and bAttacking and #nAllyHeroes <= 2 and fManaAfter > fManaThreshold1 and not bInDragonForm then
		for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 4) then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

	if Fu.IsDefending(bot) and bAttacking and #nEnemyHeroes == 0 and fManaAfter > fManaThreshold1 and not bInDragonForm then
		for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 4) then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

	if Fu.IsFarming(bot) and bAttacking and fManaAfter > fManaThreshold2 then
		for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 3 and not bInDragonForm)
				or (nLocationAoE.count >= 2 and creep:IsAncientCreep())
				or (nLocationAoE.count >= 2 and fManaAfter > fManaThreshold1)
				then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

	if Fu.IsLaning(bot) and not Fu.IsInLaningPhase() and fManaAfter > fManaThreshold2 then
		for _, creep in ipairs(nEnemyCreeps) do
			if  Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and (string.find(creep:GetUnitName(), 'range') or string.find(creep:GetUnitName(), 'flagbearer') or string.find(creep:GetUnitName(), 'siege'))
			then
				local eta = (GetUnitToUnitDistance(bot, creep) / nSpeed) + nCastPoint
				if Fu.WillKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
					if (Fu.IsValidHero(nEnemyHeroes[1]) and Fu.IsInRange(nEnemyHeroes[1], creep, nRadius) and not Fu.IsSuspiciousIllusion(nEnemyHeroes[1]))
					or Fu.IsUnitTargetedByTower(creep, false)
					then
						return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
					end
				end
			end
		end

		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, nDamage)
		if nLocationAoE.count >= 2 then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
        and bAttacking
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
        and bAttacking
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if fManaAfter > fManaThreshold2 and not Fu.IsLateGame() and bAttacking and not bInDragonForm then
		for _, creep in ipairs(nEnemyCreeps) do
			if Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and not Fu.IsRunning(creep)
			then
				local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, nDamage)
				if (nLocationAoE.count >= 3) then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderDragonTail()
	if not Fu.CanCastAbility(DragonTail) then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, DragonTail:GetCastRange())
	local nDamage = DragonTail:GetSpecialValueInt('damage')
	local nSpeed = DragonTail:GetSpecialValueInt('projectile_speed')
	local nManaCost = DragonTail:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {ElderDragonForm})

	for _, enemyHero in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			if enemyHero:HasModifier('modifier_teleporting') then
				local fModifierTime = Fu.GetModifierTime(enemyHero, 'modifier_teleporting')
				if not bInDragonForm then
					local eta = GetUnitToUnitDistance(bot, enemyHero) / bot:GetCurrentMovementSpeed()
					if eta < fModifierTime then
						return BOT_ACTION_DESIRE_HIGH, enemyHero
					end
				else
					local eta = GetUnitToUnitDistance(bot, enemyHero) / nSpeed
					if eta < fModifierTime then
						return BOT_ACTION_DESIRE_HIGH, enemyHero
					end
				end
			elseif enemyHero:IsChanneling() then
				if fManaAfter > fManaThreshold1 then
					return BOT_ACTION_DESIRE_HIGH, enemyHero
				end
			end

			local eta = GetUnitToUnitDistance(bot, enemyHero) / bot:GetCurrentMovementSpeed()
			if bInDragonForm then
				eta = GetUnitToUnitDistance(bot, enemyHero) / nSpeed
			end

			if not Fu.CanCastAbility(BreatheFire) then
				if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, eta)
				and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
				and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
				and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
				and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
				then
					return BOT_ACTION_DESIRE_HIGH, enemyHero
				end
			end
		end
	end

	if bInTeamFight then
		-- fire dragon
		if bInDragonForm and true then
			for _, enemyHero in pairs(nEnemyHeroes) do
				if Fu.IsValidHero(enemyHero)
				and Fu.CanBeAttacked(enemyHero)
				and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
				and Fu.CanCastOnNonMagicImmune(enemyHero)
				and Fu.CanCastOnTargetAdvanced(enemyHero)
				and not enemyHero:IsDisarmed()
				and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
				and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
				and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				then
					local nInRangeEnemy = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), 100)
					if #nInRangeEnemy >= 2 then
						return BOT_ACTION_DESIRE_HIGH, enemyHero
					end
				end
			end
		end

		local hTarget = nil
		local hTargetDamage = 0
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:IsDisarmed()
			and not enemyHero:HasModifier('modifier_dragonknight_breathefire_reduction')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			then
				local enemyHeroDamage = enemyHero:GetEstimatedDamageToTarget(false, bot, 3.0, DAMAGE_TYPE_ALL)
				if enemyHeroDamage > hTargetDamage then
					hTarget = enemyHero
					hTargetDamage = enemyHeroDamage
				end
			end
		end

		if hTarget ~= nil then
			return BOT_ACTION_DESIRE_HIGH, hTarget
		end
	end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + 300)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.CanCastOnTargetAdvanced(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:IsDisarmed()
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end


	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
			and not Fu.IsDisabled(enemyHero)
            and not enemyHero:IsDisarmed()
			and not enemyHero:HasModifier('modifier_dragonknight_breathefire_reduction')
			then
				if Fu.IsChasingTarget(enemyHero, bot)
				or #nEnemyHeroes > #nAllyHeroes and enemyHero:GetAttackTarget() == bot
				or botHP < 0.5
				then
					return BOT_ACTION_DESIRE_HIGH, enemyHero
				end
			end
		end
	end

	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.CanCastOnTargetAdvanced(botTarget)
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
        and bAttacking
		and fManaAfter > 0.4
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
        and bAttacking
		and fManaAfter > 0.4
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderFireball()
	if not Fu.CanCastAbility(Fireball) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Fireball:GetCastRange())
    local nRadius = Fireball:GetSpecialValueInt('radius')
	local nManaCost = Fireball:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {ElderDragonForm})

    if bInTeamFight then
        local vLocation = Fu.GetAoeEnemyHeroLocation(bot, nCastRange, nRadius, 2)
        if vLocation ~= nil and fManaAfter > fManaThreshold1 then
            return BOT_ACTION_DESIRE_HIGH, vLocation
        end
    end

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.GetHP(botTarget) > 0.15
		and not Fu.IsChasingTarget(bot, botTarget)
		and fManaAfter > fManaThreshold1
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange - 100)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.GetHP(enemyHero) < 0.5
			and not Fu.IsDisabled(enemyHero)
            and not enemyHero:IsDisarmed()
			and not enemyHero:HasModifier('modifier_dragonknight_breathefire_reduction')
			then
				if (Fu.IsChasingTarget(enemyHero, bot) and #nEnemyHeroes >= 2) then
					return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
				end

				if (#nEnemyHeroes > #nAllyHeroes and enemyHero:GetAttackTarget() == bot)
				then
					return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
				end
			end
		end
	end

	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.GetHP(botTarget) > 0.4
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
        and bAttacking
		and fManaAfter > 0.5
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not botTarget:HasModifier('modifier_dragonknight_breathefire_reduction')
        and bAttacking
		and fManaAfter > 0.5
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderElderDragonForm()
	if not Fu.CanCastAbility(ElderDragonForm) or botHP < 0.25 then
		return BOT_ACTION_DESIRE_NONE
	end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
		and Fu.CanBeAttacked(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		then
			local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
			if not (#nInRangeAlly >= #nInRangeEnemy + 2) then
				if #nInRangeEnemy >= 2 then
					return BOT_ACTION_DESIRE_HIGH
				else
					if not botTarget:HasModifier('modifier_necrolyte_reapers_scythe') then
						return BOT_ACTION_DESIRE_HIGH
					end
				end
			end
		end
	end

	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(800, true)

	if Fu.IsPushing(bot) then
		if Fu.IsValidBuilding(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.GetHP(botTarget) > 0.2
		and not botTarget:HasModifier('modifier_backdoor_protection')
		and not botTarget:HasModifier('modifier_backdoor_protection_active')
		and not botTarget:HasModifier('modifier_backdoor_protection_in_base')
		and #nEnemyLaneCreeps >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDefending(bot) then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
		if #nEnemyLaneCreeps >= 6 and #nInRangeEnemy == 0 then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingRoshan(bot) and bot:GetNetWorth() < 20000 then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, 600)
		and Fu.GetHP(botTarget) > 0.4
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingTormentor(bot) and bot:GetNetWorth() < 15000 then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, 600)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X
