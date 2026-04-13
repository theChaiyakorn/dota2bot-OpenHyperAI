local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
							['t25'] = {0, 10},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {10, 0},
}


local tAllAbilityBuildList = {
							{2,1,2,3,2,6,2,3,3,3,6,1,1,1,6},--pos1,3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_gauntlets",
	"item_gauntlets",
	"item_quelling_blade",

	"item_magic_wand",
	"item_phase_boots",
	"item_armlet",
	"item_radiance",--
	"item_blink",
	"item_aghanims_shard",
	"item_assault",--
	"item_ultimate_scepter",
	"item_overwhelming_blink",--
	"item_ultimate_scepter_2",
	"item_abyssal_blade",--
	"item_travel_boots",
	"item_moon_shard",
	"item_refresher",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_quelling_blade",
	"item_gauntlets",
	"item_magic_stick",
	"item_branches",

	"item_magic_wand",
	"item_bracer",
	"item_phase_boots",
	"item_radiance",--
	"item_blink",
	"item_ultimate_scepter",
	"item_assault",--
	"item_aghanims_shard",
	"item_overwhelming_blink",--
	"item_refresher",--
	"item_ultimate_scepter_2",
	"item_nullifier",--
	"item_travel_boots_2",--
	"item_moon_shard",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_heavens_halberd", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )


X['bDeafaultAbility'] = true
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
		and hMinionUnit:GetUnitName() ~= "npc_dota_wraith_king_skeleton_warrior"
	then
		Minion.IllusionThink( hMinionUnit )
	end

end

--[[

npc_dota_hero_skeleton_king

"Ability1"		"skeleton_king_hellfire_blast"
"Ability2"		"skeleton_king_vampiric_aura"
"Ability3"		"skeleton_king_mortal_strike"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"skeleton_king_reincarnation"
"Ability10"		"special_bonus_unique_wraith_king_7"
"Ability11"		"special_bonus_attack_speed_20"
"Ability12"		"special_bonus_strength_15"
"Ability13"		"special_bonus_unique_wraith_king_6"
"Ability14"		"special_bonus_unique_wraith_king_1"
"Ability15"		"special_bonus_unique_wraith_king_8"
"Ability16"		"special_bonus_unique_wraith_king_2"
"Ability17"		"special_bonus_unique_wraith_king_4"

modifier_skeleton_king_hellfire_blast
modifier_skeleton_king_vampiric_aura
modifier_skeleton_king_vampiric_aura_buff
modifier_skeleton_king_mortal_strike_summon_thinker
modifier_skeleton_king_mortal_strike
modifier_skeleton_king_mortal_strike_summon
modifier_skeleton_king_reincarnation
modifier_skeleton_king_reincarnate_slow
modifier_skeleton_king_reincarnation_scepter
modifier_skeleton_king_reincarnation_scepter_active

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName('skeleton_king_hellfire_blast'), 'skeleton_king_hellfire_blast', 'skeleton_king')
local abilityW = SafeAbility(bot:GetAbilityByName('skeleton_king_spectral_blade'), 'skeleton_king_spectral_blade', 'skeleton_king')
local abilityE = SafeAbility(bot:GetAbilityByName('skeleton_king_mortal_strike'), 'skeleton_king_mortal_strike', 'skeleton_king')
local abilityR = SafeAbility(bot:GetAbilityByName('skeleton_king_reincarnation'), 'skeleton_king_reincarnation', 'skeleton_king')
local talent5 = SafeAbility(bot:GetAbilityByName(sTalentList[5]), 'sTalentList[5]', 'skeleton_king')
local talent6 = SafeAbility(bot:GetAbilityByName(sTalentList[6]), 'sTalentList[6]', 'skeleton_king')

local castQDesire, castQTarget
local castWDesire
local castEDesire

local nKeepMana, nMP, nHP, nLV, hEnemyHeroList

function X.SkillsComplement()


	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end
    if not abilityW or abilityW:IsHidden() then abilityW = SafeAbility(bot:GetAbilityByName('skeleton_king_bone_guard'), 'skeleton_king_bone_guard', 'skeleton_king') end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 160
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	hEnemyHeroList = ctx.enemies


	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end

	castWDesire = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityW )
		return

	end

end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable()
		or X.ShouldSaveMana( abilityQ )
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = abilityQ:GetCastRange()
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nSkillLV = abilityQ:GetLevel()
	local nDamage = 40 * ( nSkillLV - 1 ) + 100
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local allyList =  Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE )

	local nEnemysHerosInView = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )

	if #nEnemysHerosInView == 1
		and Fu.IsValidHero( nEnemysHerosInView[1] )
		and Fu.IsInRange( nEnemysHerosInView[1], bot, nCastRange + 350 )
		and nEnemysHerosInView[1]:IsFacingLocation( bot:GetLocation(), 30 )
		and nEnemysHerosInView[1]:GetAttackRange() > nCastRange
		and nEnemysHerosInView[1]:GetAttackRange() < 1250
	then
		nCastRange = nCastRange + 260
	end

	local nEnemysHerosInRange = Fu.GetNearbyHeroes(bot, nCastRange + 43, true, BOT_MODE_NONE )
	local nEnemysHerosInBonus = Fu.GetNearbyHeroes(bot, nCastRange + 330, true, BOT_MODE_NONE )

	--打断和击杀
	for _, npcEnemy in pairs( nEnemysHerosInBonus )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end

			if GetUnitToUnitDistance( bot, npcEnemy ) <= nCastRange + 80
				and Fu.CanKillTarget( npcEnemy, nDamage * 1.68, nDamageType )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end

		end
	end

	--团战中对战力最高的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_PHYSICAL )
				if ( npcEnemyDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = npcEnemyDamage
					npcMostDangerousEnemy = npcEnemy
				end
			end
		end

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end

	--对线期间对敌方英雄使用
	if bot:GetActiveMode() == BOT_MODE_LANING or nLV <= 5
	then
		for _, npcEnemy in pairs( nEnemysHerosInBonus )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and Fu.GetAttackEnemysAllyCreepCount( npcEnemy, 1400 ) >= 4
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end


	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.CanCastOnTargetAdvanced( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange + 80 )
			and not Fu.IsDisabled( npcTarget )
			and not npcTarget:IsDisarmed()
		then
			if nSkillLV >= 3 or nMP > 0.68 or Fu.GetHP( npcTarget ) < 0.38 or nHP < 0.25
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget
			end
		end
	end

	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
						or nMP > 0.8
						or GetUnitToUnitDistance( bot, npcEnemy ) <= 400 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and ( bot:GetAttackDamage() < 200 or nMP > 0.88 )
		and nMP > 0.71 and #hEnemyHeroList == 0
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 100 )

		local targetCreep = Fu.GetMostHpUnit( nCreeps )

		if Fu.IsValid( targetCreep )
			and bot:IsFacingLocation( targetCreep:GetLocation(), 46 )
			and ( #nCreeps >= 2 or GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
			and not Fu.IsRoshan( targetCreep )
			and not Fu.IsOtherAllysTarget( targetCreep )
			and targetCreep:GetMagicResist() < 0.3
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 1.68, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( targetCreep, nDamage, nDamageType )
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep
		end
	end

	--打肉的时候输出
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 600
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
			and not Fu.IsDisabled( npcTarget )
			and not npcTarget:IsDisarmed()
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	--受到伤害时保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and not bot:IsInvisible()
		and #nEnemysHerosInRange >= 1
		and nLV >= 6
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 45 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	--通用消耗敌人或受到伤害时保护自己
	if ( #nEnemysHerosInView > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #allyList >= 2 )
		and #nEnemysHerosInRange >= 1
		and nLV >= 7
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	

	return 0

end

function X.ConsiderW()
	if not abilityW:IsFullyCastable()
		or not bot:HasModifier( "modifier_skeleton_king_bone_guard" )
		or X.ShouldSaveMana( abilityW )
		or abilityW:GetName() ~= "skeleton_king_bone_guard"
	then return 0 end

	local nStack = 0
	local modIdx = bot:GetModifierByName( "modifier_skeleton_king_bone_guard" )
	if modIdx > -1 then
		nStack = bot:GetModifierStackCount( modIdx )
	end
	local maxStack = abilityW:GetSpecialValueInt( "max_skeleton_charges" )

	local nEnemysHerosInView = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
	local npcTarget = Fu.GetProperTarget( bot )

	--辅助进攻
	if Fu.IsValidHero( npcTarget )
		and #nEnemysHerosInView == 1
		and Fu.IsInRange( npcTarget, bot, 650 )
		and ( nStack / maxStack >= 0.6 or talent6:IsTrained() )
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	--buff叠满了靠近兵线的时候
	if ( nStack == maxStack or talent6:IsTrained() )
		and nLV >= 4
		and ( X.IsNearLaneFront( bot ) or Fu.IsFarming( bot ) )
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	return 0
end

function X.IsNearLaneFront( bot )
	local testDist = 600
	local laneList = {LANE_TOP, LANE_MID, LANE_BOT}
	for _, lane in pairs( laneList )
	do
		local tFLoc = GetLaneFrontLocation( GetTeam(), lane, 0 )
		if GetUnitToLocationDistance( bot, tFLoc ) <= testDist
		then
			return true
		end
	end
	return false
end

function X.ShouldSaveMana( nAbility )

--	if talent5:IsTrained() then return false end

	if nLV >= 6
	and nAbility ~= nil
	and abilityR ~= nil
	and abilityR:GetCooldownTimeRemaining() <= 3.0
	and ( bot:GetMana() - nAbility:GetManaCost() < abilityR:GetManaCost() )
	then
		return true
	end

	return false
end


return X
