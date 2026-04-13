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
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,2,3,3,3,6,3,2,2,2,6,1,1,1,6},--pos1,3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_bristleback_outfit",
	"item_armlet",
	"item_aghanims_shard",
--	"item_blade_mail",
	"item_heavens_halberd",--
	"item_manta",--
	"item_orchid",
	"item_bloodthorn",--
	"item_travel_boots",
	"item_heart",--
	"item_satanic",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
	"item_aghanims_shard",
	"item_crimson_guard",--
	"item_armlet",
	"item_heavens_halberd",--
	"item_assault",--
	"item_travel_boots",
	"item_manta",--
	"item_heart",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
    "item_basher",
    "item_monkey_king_bar",--
	"item_assault",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
    "item_abyssal_blade",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_pipe",--
    "item_basher",
    "item_monkey_king_bar",--
	"item_assault",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
    "item_abyssal_blade",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_power_treads",
	"item_quelling_blade",

	'item_travel_boots',
	'item_armlet',
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )


X['bDeafaultAbility'] = true
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_chaos_knight

"Ability1"		"chaos_knight_chaos_bolt"
"Ability2"		"chaos_knight_reality_rift"
"Ability3"		"chaos_knight_chaos_strike"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"chaos_knight_phantasm"
"Ability10"		"special_bonus_all_stats_5"
"Ability11"		"special_bonus_movement_speed_20"
"Ability12"		"special_bonus_strength_15"
"Ability13"		"special_bonus_cooldown_reduction_12"
"Ability14"		"special_bonus_gold_income_25"
"Ability15"		"special_bonus_unique_chaos_knight"
"Ability16"		"special_bonus_unique_chaos_knight_2"
"Ability17"		"special_bonus_unique_chaos_knight_3"

modifier_chaos_knight_reality_rift_debuff
modifier_chaos_knight_reality_rift_buff
modifier_chaos_knight_reality_rift
modifier_chaos_knight_chaos_strike
modifier_chaos_knight_chaos_strike_debuff
modifier_chaos_knight_phantasm
modifier_chaos_knight_phantasm_illusion

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'chaos_knight')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'chaos_knight')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'chaos_knight')
local talent6 = SafeAbility(bot:GetAbilityByName(sTalentList[6]), 'sTalentList[6]', 'chaos_knight')
local abilityArmlet = nil

local castQDesire, castQTarget = 0
local castWDesire, castWTarget = 0
local castRDesire = 0
local botTarget

local nKeepMana, nMP, nHP, nLV, hEnemyHeroList


function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	botTarget = ctx.target
	nKeepMana = 240
	nMP = ctx.mp
	nHP = ctx.hp
	nLV = ctx.level
	hEnemyHeroList = ctx.enemies
	abilityArmlet = Fu.IsItemAvailable( "item_armlet" )

	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		if abilityArmlet ~= nil
			and abilityArmlet:IsFullyCastable()
			and abilityArmlet:GetToggleState() == false
		then
			bot:ActionQueue_UseAbility( abilityArmlet )
		end

		bot:ActionQueue_UseAbility( abilityR )
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end



end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = abilityQ:GetCastRange()
	local nCastPoint = abilityQ:GetCastPoint()
	local nSkillLV = abilityQ:GetLevel()
	local nDamage = 30 + nSkillLV * 30 + 120 * 0.38

	local nEnemysHeroesInCastRange = Fu.GetNearbyHeroes(bot, nCastRange + 99, true, BOT_MODE_NONE )
	local nEnemysHeroesInView = Fu.GetNearbyHeroes(bot, 880, true, BOT_MODE_NONE )

	--击杀
	if #nEnemysHeroesInCastRange > 0 then
		for i=1, #nEnemysHeroesInCastRange do
			if Fu.IsValid( nEnemysHeroesInCastRange[i] )
				and Fu.CanCastOnNonMagicImmune( nEnemysHeroesInCastRange[i] )
				and Fu.CanCastOnTargetAdvanced( nEnemysHeroesInCastRange[i] )
				and nEnemysHeroesInCastRange[i]:GetHealth() < nEnemysHeroesInCastRange[i]:GetActualIncomingDamage( nDamage, DAMAGE_TYPE_MAGICAL )
				and not ( GetUnitToUnitDistance( nEnemysHeroesInCastRange[i], bot ) <= bot:GetAttackRange() + 60 )
				and not Fu.IsDisabled( nEnemysHeroesInCastRange[i] )
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysHeroesInCastRange[i]
			end
		end
	end

	--打断
	if #nEnemysHeroesInView > 0 then
		for i=1, #nEnemysHeroesInView do
			if Fu.IsValid( nEnemysHeroesInView[i] )
				and Fu.CanCastOnNonMagicImmune( nEnemysHeroesInView[i] )
				and Fu.CanCastOnTargetAdvanced( nEnemysHeroesInView[i] )
				and nEnemysHeroesInView[i]:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysHeroesInView[i]
			end
		end
	end


	--团战
	if Fu.IsInTeamFight( bot, 1200 )
		and DotaTime() > 4 * 60
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, npcEnemy in pairs( nEnemysHeroesInCastRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_ALL )
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


	--常规
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	--对线期间


	if Fu.IsRetreating( bot )
	then
		if Fu.IsValid( nEnemysHeroesInCastRange[1] )
			and Fu.CanCastOnNonMagicImmune( nEnemysHeroesInCastRange[1] )
			and Fu.CanCastOnTargetAdvanced( nEnemysHeroesInCastRange[1] )
			and not Fu.IsDisabled( nEnemysHeroesInCastRange[1] )
			and not nEnemysHeroesInCastRange[1]:IsDisarmed()
			and GetUnitToUnitDistance( bot, nEnemysHeroesInCastRange[1] ) <= nCastRange - 60
		then
			return BOT_ACTION_DESIRE_HIGH, nEnemysHeroesInCastRange[1]
		end
	end


	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() > 400
	then
		local target =  bot:GetAttackTarget()

		if target ~= nil and target:IsAlive()
			and Fu.GetHP( target ) > 0.2
			and not Fu.IsDisabled( target )
			and not target:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_LOW, target
		end
	end

	return BOT_ACTION_DESIRE_NONE
end


function X.ConsiderW()

	if not abilityW:IsFullyCastable() or bot:IsRooted() then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = abilityW:GetCastRange()
	local nCastPoint = abilityW:GetCastPoint()
	local nSkillLV = abilityW:GetLevel()
	local nDamage = 0
	local bIgnoreMagicImmune = talent6:IsTrained()

	local nEnemysHeroesInCastRange = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
			and ( not Fu.IsInRange( bot, botTarget, 200 ) or not botTarget:HasModifier( 'modifier_chaos_knight_reality_rift' ) )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and not Fu.IsDisabled( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end


	if Fu.IsRetreating( bot )
	then
		local enemies = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE )
		local creeps = bot:GetNearbyLaneCreeps( nCastRange, true )

		if enemies[1] ~= nil and creeps[1] ~= nil
		then
			for _, creep in pairs( creeps )
			do
				if enemies[1]:IsFacingLocation( bot:GetLocation(), 30 )
					and bot:IsFacingLocation( creep:GetLocation(), 30 )
					and GetUnitToUnitDistance( bot, creep ) >= 650
				then
					return BOT_ACTION_DESIRE_LOW, creep
				end
			end
		end
	end


	if hEnemyHeroList[1] == nil
		and bot:GetAttackDamage() >= 150
	then
		local nCreeps = bot:GetNearbyLaneCreeps( 1000, true )
		for i=1, #nCreeps
		do
			local creep = nCreeps[#nCreeps -i + 1]
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( "ranged", creep )
				and GetUnitToUnitDistance( bot, creep ) >= 350
			then
				return BOT_ACTION_DESIRE_LOW, creep
			end
		end
	end

	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, 800)
		and Fu.CanBeAttacked(botTarget)
		and Fu.GetHP(botTarget) > 0.5
		and Fu.IsAttacking(bot)
		and (Fu.IsEarlyGame() or Fu.IsMidGame())
		and Fu.GetManaAfter(abilityR:GetManaCost()) > 0.35
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, 800)
		and Fu.CanBeAttacked(botTarget)
		and Fu.GetHP(botTarget) > 0.5
		and Fu.IsAttacking(bot)
		and (Fu.IsEarlyGame() or Fu.IsMidGame())
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

function X.ConsiderR()

	if not abilityR:IsFullyCastable() or bot:DistanceFromFountain() < 500 then return BOT_ACTION_DESIRE_NONE end

	local nNearbyAllyHeroes = Fu.GetAlliesNearLoc( bot:GetLocation(), 1200 )
	local nNearbyEnemyHeroes = Fu.GetEnemyList( bot, 1600 )
	local nNearbyEnemyTowers = bot:GetNearbyTowers( 700, true )
	local nNearbyEnemyBarracks = bot:GetNearbyBarracks( 400, true )
	local nNearbyAlliedCreeps = bot:GetNearbyLaneCreeps( 1000, false )
	local nCastRange = abilityW:IsFullyCastable() and 1200 or 900

	-- if #nNearbyAllyHeroes + #nNearbyEnemyHeroes >= 3
		-- and  #hEnemyHeroList - #nNearbyAllyHeroes <= 2
		-- and  ( #nNearbyEnemyHeroes >= 2 or ( #hEnemyHeroList <= 1 and #nNearbyEnemyHeroes >= 1 ) )
	-- then
	  	-- return BOT_ACTION_DESIRE_HIGH
	-- end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnMagicImmune( botTarget )
			--and #nNearbyAllyHeroes - #nNearbyEnemyHeroes <= 2
			and ( Fu.GetHP( botTarget ) > 0.5
				  or nHP < 0.7
				  or #nNearbyEnemyHeroes >= 2 )

		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end


	if Fu.IsInTeamFight( bot, 1200 )
	then
		if #nNearbyEnemyHeroes >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end


	if Fu.IsPushing( bot )
		and DotaTime() > 8 * 30
	then
		if ( #nNearbyEnemyTowers >= 1 or #nNearbyEnemyBarracks >= 1 )
			and #nNearbyAlliedCreeps >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end


	if bot:GetActiveMode() == BOT_MODE_RETREAT
		and nHP >= 0.5
		and Fu.IsValidHero( nNearbyEnemyHeroes[1] )
		and GetUnitToUnitDistance( bot, nNearbyEnemyHeroes[1] ) <= 700
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	return BOT_ACTION_DESIRE_NONE
end


return X
