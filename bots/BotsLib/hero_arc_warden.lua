local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local sTempList = {}
local flag1 = RandomInt(1, 2) == 1 and 'Physical' or 'Magical'

local tTalentTreeList = {
						{--pos1
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {10, 0},
						},
						{--pos2M
							['t25'] = {10, 0},
							['t20'] = {0, 10},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						},
						{--pos2P
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {0, 10},
						}
}

local tAllAbilityBuildList = {
						{3,1,3,1,3,6,3,1,1,2,6,2,2,2,6},--pos1
						{3,1,1,3,1,6,1,3,3,2,6,2,2,2,6},--pos2M
						{3,1,3,1,3,6,3,1,1,2,6,2,2,2,6},--pos2P
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_1' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_2'
then
	if flag1 == 'Magical'  then nAbilityBuildList = tAllAbilityBuildList[2] end
	if flag1 == 'Physical' then nAbilityBuildList = tAllAbilityBuildList[3] end
end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
if sRole == 'pos_1' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_2'
then
	if flag1 == 'Magical'  then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end
	if flag1 == 'Physical' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[3]) end
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_slippers",
	"item_circlet",
	"item_magic_wand",

	"item_wraith_band",
	"item_boots",
	"item_hand_of_midas",
	"item_diffusal_blade",
	"item_maelstrom",
	"item_mjollnir",--
	"item_travel_boots",
	"item_manta",--
	"item_orchid",
	"item_black_king_bar",--
	"item_bloodthorn",--
	"item_moon_shard",
	"item_sheepstick",--
	"item_disperser",--
	-- "item_skadi",--
	"item_travel_boots_2",--
	"item_aghanims_shard",
	"item_ultimate_scepter_2",
}

if flag1 == 'Magical'
then
	sTempList = {
		"item_tango",
		"item_double_branches",
		"item_circlet",
		"item_faerie_fire",

		"item_bottle",
		"item_magic_wand",
		"item_spirit_vessel",
		"item_boots",
		"item_hand_of_midas",
		"item_mjollnir",--
		"item_travel_boots",
		"item_blink",
		"item_octarine_core",--
		"item_ultimate_scepter",
		"item_orchid",
		"item_sheepstick",--
		"item_overwhelming_blink",--
		"item_bloodthorn",--
		"item_moon_shard",
		"item_travel_boots_2",--
		"item_ultimate_scepter_2",
		"item_aghanims_shard",
	}
else
	sTempList = {
		"item_tango",
		"item_double_branches",
		"item_faerie_fire",

		"item_bottle",
		"item_spirit_vessel",
		"item_magic_wand",
		"item_boots",
		"item_hand_of_midas",
		"item_mjollnir",--
		"item_travel_boots",
		"item_orchid",
		"item_manta",--
		"item_greater_crit",--
		"item_bloodthorn",--
		"item_moon_shard",
		"item_skadi",--
		"item_travel_boots_2",--
		"item_aghanims_shard",
		"item_ultimate_scepter_2",
	}
end

sRoleItemsBuyList['pos_2'] = sTempList

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	'item_travel_boots',
	'item_magic_wand',

	"item_sheepstick",
	"item_hand_of_midas",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_ranged_carry' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local Flux 			= bot:GetAbilityByName('arc_warden_flux')
local MagneticField = bot:GetAbilityByName('arc_warden_magnetic_field')
local SparkWraith 	= bot:GetAbilityByName('arc_warden_spark_wraith')
local TempestDouble = bot:GetAbilityByName('arc_warden_tempest_double')

local FluxDesire, FluxTarget
local MagneticFieldDesire, MagneticFieldTarget
local SparkWraithDesire, SparkWraithLocation
local TempestDoubleDesire, TempestDoubleLocation

local npcDouble = nil

local botTarget

local bGoingOnSomeone
local bAttacking
local nBotMP
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility( bot ) or Fu.IsRealInvisible(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = ctx.mp
	bInTeamFight = ctx.isTeamFight

	botTarget = ctx.target

	TempestDoubleDesire, TempestDoubleLocation = X.ConsiderTempestDouble()
	if TempestDoubleDesire > 0
	then
		bot:Action_UseAbilityOnLocation(TempestDouble, TempestDoubleLocation)
		return
	end

	MagneticFieldDesire, MagneticFieldTarget = X.ConsiderMagneticField()
	if MagneticFieldDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		if Fu.CheckBitfieldFlag(MagneticField:GetBehavior(), ABILITY_BEHAVIOR_POINT) then
			bot:Action_UseAbilityOnLocation(MagneticField, MagneticFieldTarget)
		else
			bot:ActionQueue_UseAbility(MagneticField)
		end
		return
	end

	FluxDesire, FluxTarget = X.ConsiderFlux()
	if FluxDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnEntity(Flux, FluxTarget)
		return
	end

	SparkWraithDesire, SparkWraithLocation = X.ConsiderSparkWraith()
	if SparkWraithDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(SparkWraith, SparkWraithLocation)
		return
	end
end

function X.ConsiderFlux()
	if not Flux:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE, nil end

	local nCastRange = Fu.GetProperCastRange(false, bot, Flux:GetCastRange() + 75)
	local nDot = Flux:GetSpecialValueInt('damage_per_second')
	local nDuration = Flux:GetSpecialValueInt('duration')
	local nDamage = nDot * nDuration

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.CanCastOnTargetAdvanced(enemyHero)
		and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero
		end
	end

	if bInTeamFight
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange + 150, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValid(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				local dmg = enemyHero:GetEstimatedDamageToTarget(false, bot, nDuration, DAMAGE_TYPE_ALL)
				if dmg > nMostDangerousDamage
				then
					nMostDangerousDamage = dmg
					npcMostDangerousEnemy = enemyHero
				end
			end
		end

		if npcMostDangerousEnemy ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.CanCastOnTargetAdvanced(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + 75)
		and not Fu.IsSuspiciousIllusion(botTarget)
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1600, true, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1600, false, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget
			end
		end
	end

	if Fu.IsRetreating(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
		if Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
		and Fu.CanCastOnTargetAdvanced(nInRangeEnemy[1])
		and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		and not Fu.IsDisabled(nInRangeEnemy[1])
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, true, BOT_MODE_NONE)
			local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
			and ((#nTargetInRangeAlly > #nInRangeAlly)
				or bot:WasRecentlyDamagedByAnyHero(2))
			then
				return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.CanCastOnMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderMagneticField()
	if not MagneticField:IsFullyCastable()
	or X.IsDoubleCasting()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, MagneticField:GetCastRange())
	local nRadius = MagneticField:GetSpecialValueInt('radius')

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(false, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)

		if nLocationAoE.count >= 2
		and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= bot:GetAttackRange()
		then
			local nInRangeAlly = Fu.GetAlliesNearLoc(nLocationAoE.targetloc, nRadius)
			if Fu.IsValidHero(nInRangeAlly[1])
			and nInRangeAlly[1]:GetAttackTarget() ~= nil
			and GetUnitToUnitDistance(nInRangeAlly[1], nInRangeAlly[1]:GetAttackTarget()) <= nInRangeAlly[1]:GetAttackRange() + 50
			and not nInRangeAlly[1]:HasModifier('modifier_arc_warden_magnetic_field')
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		then
			local nInRangeAllyAttack = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_ATTACK)
			for _, allyHero in pairs(nInRangeAllyAttack)
			do
				local allyTarget = allyHero:GetAttackTarget()
				if Fu.IsValidHero(allyHero)
				and (Fu.IsInRange(bot, allyHero, nRadius) and not allyHero:HasModifier('modifier_arc_warden_magnetic_field'))
				and (Fu.IsValidTarget(allyTarget) and GetUnitToUnitDistance(allyHero, allyTarget) <= allyHero:GetAttackRange())
				and not Fu.IsSuspiciousIllusion(allyHero)
				and not Fu.IsSuspiciousIllusion(allyTarget)
				and not allyTarget:HasModifier('modifier_abaddon_borrowed_time')
				then
					local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1600, true, BOT_MODE_NONE)
					local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1600, false, BOT_MODE_NONE)

					if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
					and #nInRangeAlly >= #nInRangeEnemy
					then
						return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
					end
				end
			end
		end
	end

	if (Fu.IsDefending(bot) or Fu.IsPushing(bot))
	and not bot:HasModifier('modifier_arc_warden_magnetic_field')
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(888, true)
		local nEnemyTowers = bot:GetNearbyTowers(888, true)
		local nEnemyBarracks bot:GetNearbyBarracks(888, true)
		local sEnemyTowers bot:GetNearbyFillers(888, true)

		if bAttacking
		then
			if (nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3)
			or (nEnemyTowers ~= nil and #nEnemyTowers >= 1)
			or (nEnemyBarracks ~= nil and #nEnemyBarracks >= 1)
			or (sEnemyTowers ~= nil and #sEnemyTowers >= 1)
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if Fu.IsFarming(bot)
	and Fu.GetManaAfter(MagneticField:GetManaCost()) * bot:GetMana() > MagneticField:GetManaCost() * 1.5
	and not bot:HasModifier('modifier_arc_warden_magnetic_field')
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(888, true)

		if bAttacking
		then
			if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end

			local nNeutralCreeps = bot:GetNearbyNeutralCreeps(888)
			if nNeutralCreeps ~= nil
			and (#nNeutralCreeps >= 3 or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
	and not bot:HasModifier('modifier_arc_warden_magnetic_field')
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot)
	and not bot:HasModifier('modifier_arc_warden_magnetic_field')
	then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSparkWraith()
	if not SparkWraith:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE, 0 end

	local nCastRange = Fu.GetProperCastRange(false, bot, SparkWraith:GetCastRange())
	local nRadius = SparkWraith:GetSpecialValueInt('radius')
	local nDamage = SparkWraith:GetSpecialValueInt('spark_damage')
	local nCastPoint = SparkWraith:GetCastPoint()
	local nDelay = SparkWraith:GetSpecialValueInt('activation_delay') + nCastPoint

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay)
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		and not botTarget:HasModifier('modifier_item_aeon_disk_buff')
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1600, true, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1600, false, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			then
				if Fu.IsRunning(botTarget)
				then
					return BOT_ACTION_DESIRE_MODERATE, botTarget:GetExtrapolatedLocation(nDelay)
				else
					return BOT_ACTION_DESIRE_MODERATE, botTarget:GetLocation()
				end
			end
		end

		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 1400, nRadius, 2, 0)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
		and Fu.GetManaAfter(SparkWraith:GetManaCost()) * bot:GetMana() > Flux:GetManaCost() + MagneticField:GetManaCost() + SparkWraith:GetManaCost()
		and not bot:HasModifier('modifier_silencer_curse_of_the_silent')
		then
			local nCreep = Fu.GetVulnerableUnitNearLoc( bot, false, true, 1600, nRadius, nLocationAoE.targetloc )
			if nCreep == nil
			or bot:HasModifier('modifier_arc_warden_tempest_double')
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
	end

	if Fu.IsRetreating(bot)
	and bot:GetActiveModeDesire() > BOT_ACTION_DESIRE_HIGH
	and not bot:HasModifier('modifier_silencer_curse_of_the_silent')
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValid(enemyHero)
			and bot:WasRecentlyDamagedByHero(enemyHero, 1)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if Fu.IsPushing(bot)
	or Fu.IsDefending(bot)
	then
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), 1400, nRadius, 2, 0)
		if nLocationAoE.count > 2
		and not bot:HasModifier('modifier_silencer_curse_of_the_silent')
		then
			if bot:HasModifier('modifier_arc_warden_tempest_double')
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end

			local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1400, true)
			if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2
			then
				if nBotMP > 0.62
				then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
				end
			else
				if nBotMP > 0.75
				then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
				end
			end
		end
	end

	if Fu.IsFarming(bot)
	then
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), 1400, nRadius, 2, 0)
		if nLocationAoE.count >= 1
		and not bot:HasModifier('modifier_silencer_curse_of_the_silent')
		then
			if bot:HasModifier('modifier_arc_warden_tempest_double')
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end

			local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1400, true)
			if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 1
			then
				if nBotMP > 0.42
				then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
				end
			else
				if nBotMP > 0.55
				then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
				end
			end
		end
	end

	if Fu.IsLaning(bot)
	and Fu.IsInLaningPhase()
    and bot:GetLevel() < 7
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
			and Fu.IsKeyWordUnit('ranged', creep)
			and creep:GetHealth() <= nDamage
			and botTarget ~= creep
			and not Fu.IsRunning(creep)
			then
				return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
			end
		end
	end

	if SparkWraith:GetLevel() >= 3
	and Fu.GetManaAfter(SparkWraith:GetManaCost()) * bot:GetMana() > Flux:GetManaCost() + MagneticField:GetManaCost() + SparkWraith:GetManaCost()
	and not Fu.IsLaning(bot)
	then
		local nLocationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), 1400, nRadius, 2, 0)
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
		end
	end

	if bot:GetLevel() >= 10
	and ((Fu.GetManaAfter(SparkWraith:GetManaCost()) * bot:GetMana() > Flux:GetManaCost() + MagneticField:GetManaCost() + SparkWraith:GetManaCost())
		or bot:HasModifier('modifier_arc_warden_tempest_double'))
	and DotaTime() > 8 * 60
	then
		local nEnemysHerosCanSeen = GetUnitList(UNIT_LIST_ENEMY_HEROES)
		local nTargetHero = nil
		local nTargetHeroHealth = 99999
		for _, enemyHero in pairs( nEnemysHerosCanSeen )
		do
			if Fu.IsValidHero(enemyHero)
			and GetUnitToUnitDistance(bot, enemyHero) <= nCastRange
			and enemyHero:GetHealth() < nTargetHeroHealth
			then
				nTargetHero = enemyHero
				nTargetHeroHealth = enemyHero:GetHealth()
			end
		end

		if nTargetHero ~= nil
		then
			for i = 0, 350, 50
			do
				local nCastLocation = Fu.GetLocationTowardDistanceLocation(nTargetHero, Fu.GetEnemyFountain(), 350 - i)
				if GetUnitToLocationDistance(bot, nCastLocation) <= nCastRange
				then
					return BOT_ACTION_DESIRE_HIGH, nCastLocation
				end
			end
		end

		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
		then
			local targetCreep = nEnemyLaneCreeps[#nEnemyLaneCreeps]
			if Fu.IsValid(targetCreep)
			and Fu.CanBeAttacked(targetCreep)
			then
				local nCastLocation = Fu.GetFaceTowardDistanceLocation(targetCreep, 375)
				return BOT_ACTION_DESIRE_HIGH, nCastLocation
			end
		end

		local nEnemyHeroesInView = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
		local nEnemyLaneFront = Fu.GetNearestLaneFrontLocation(bot:GetLocation(), true, nRadius / 2)

		if nEnemyHeroesInView ~= nil and #nEnemyHeroesInView == 0 and nEnemyLaneFront ~= nil
		and GetUnitToLocationDistance(bot, nEnemyLaneFront) <= nCastRange + nRadius
		and GetUnitToLocationDistance(bot, nEnemyLaneFront) >= 800
		then
			local nCastLocation = Fu.GetLocationTowardDistanceLocation( bot, nEnemyLaneFront, nCastRange )
			if GetUnitToLocationDistance(bot, nEnemyLaneFront) < nCastRange
			then
				nCastLocation = nEnemyLaneFront
			end

			return BOT_ACTION_DESIRE_HIGH, nCastLocation
		end
	end

	local nCastLocation = Fu.GetLocationTowardDistanceLocation(bot, Fu.GetEnemyFountain(), nCastRange)
	if bot:HasModifier('modifier_arc_warden_tempest_double')
	or (nBotMP > 0.92 and bot:GetLevel() > 11 and not IsLocationVisible(nCastLocation))
	or (nBotMP > 0.38 and Fu.GetDistanceFromEnemyFountain(bot) < 4300)
	then
		if IsLocationPassable(nCastLocation)
		and not bot:HasModifier('modifier_silencer_curse_of_the_silent')
		then
			return BOT_ACTION_DESIRE_HIGH, nCastLocation
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.GetHP(botTarget) > 0.2
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.GetHP(botTarget) > 0.2
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderTempestDouble()
	X.UpdateDoubleStatus()

	if not TempestDouble:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, TempestDouble:GetCastRange())

	if Fu.IsDefending(bot) or Fu.IsPushing(bot) or Fu.IsFarming(bot)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps( 800, true )
		local nEnemyTowers = bot:GetNearbyTowers( 800, true )
		local nCreeps = bot:GetNearbyCreeps( 800, true )

		if bAttacking
		then
			if (nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2)
			or (nEnemyTowers ~= nil and #nEnemyTowers >= 1)
			or (nCreeps ~= nil and #nCreeps >= 2)
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if bInTeamFight
	then
		local target = nil
		local hp = 0
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValidHero(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
			then
				local currHP = enemyHero:GetHealth()
				if hp < currHP
				then
					hp = currHP
					target = enemyHero
				end
			end
		end

		if target ~= nil
		then
			if Fu.IsRunning(target)
			then
				return BOT_ACTION_DESIRE_HIGH, target:GetLocation()
			else
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and Fu.IsInRange(bot, botTarget, 1600)
		and not Fu.IsSuspiciousIllusion(botTarget)
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1600, true, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1600, false, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly + 1 >= #nInRangeEnemy
			then
				if botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
				then
					return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
				end

				if Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
				then
					if Fu.IsRunning(botTarget)
					then
						return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
					else
						return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
					end
				end

				if not Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
				then
					return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
				end
			end
		end
	end

	local Midas = Fu.GetComboItem(bot, 'item_hand_of_midas')
	if Midas ~= nil
	and X.IsDoubleMidasCooldown()
	and bot:DistanceFromFountain() > 600
	then
		local nCreeps = bot:GetNearbyCreeps(1600, true)
		if #nCreeps >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		and Fu.GetHP(botTarget) > 0.5
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.IsDoubleMidasCooldown()
	if npcDouble == nil then X.UpdateDoubleStatus() end

	if npcDouble ~= nil
	then
		local Midas = Fu.GetComboItem(npcDouble, 'item_hand_of_midas')
		if Midas ~= nil
		and (Midas:IsFullyCastable() or Midas:GetCooldownTimeRemaining() <= 3)
		then
			return true
		end
	end

	return false
end

function X.UpdateDoubleStatus()
	if npcDouble == nil
	and bot:GetLevel() >= 6
	then
		for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
		do
			if allyHero ~= nil
			and allyHero:IsAlive()
			and allyHero:HasModifier('modifier_arc_warden_tempest_double')
			then
				npcDouble = allyHero
			end
		end
	end
end

function X.IsDoubleCasting()
	if npcDouble == nil or not npcDouble:IsAlive()
	then
		return false
	end

	for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
	do
		if Fu.IsValid(allyHero)
		and allyHero ~= bot
		and allyHero:GetUnitName() == "npc_dota_hero_arc_warden"
		and (allyHero:IsCastingAbility() or allyHero:IsUsingAbility())
		then
			return true
		end
	end

	return false
end

return X