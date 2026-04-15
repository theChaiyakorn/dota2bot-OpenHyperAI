local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {10, 0},
						['t20'] = {10, 0},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,1,2,3,6,1,1,3,3,6,2,2,2,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
	"item_blood_grenade",
	"item_priest_outfit",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_blink",
	"item_guardian_greaves",--
	"item_aghanims_shard",
	"item_spirit_vessel",--
	"item_ultimate_scepter",
--	"item_wraith_pact",
	"item_shivas_guard",--
	"item_moon_shard",
	"item_octarine_core",--
	"item_overwhelming_blink",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_pipe",
	"item_blink",
    "item_ultimate_scepter",
	-- "item_cyclone",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_sheepstick",
	"item_moon_shard",
	"item_overwhelming_blink",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_double_null_talisman",
    "item_power_treads",
    "item_magic_wand",
    "item_kaya",
    "item_ultimate_scepter",
    "item_kaya_and_sange",--
	"item_force_staff",
	"item_hurricane_pike",--
	"item_orchid",
	"item_aghanims_shard",
	"item_bloodthorn",--
	"item_sheepstick",--
	"item_moon_shard",
	"item_octarine_core",--
	"item_overwhelming_blink",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_double_null_talisman",
    "item_power_treads",
    "item_magic_wand",
    "item_kaya",
    "item_ultimate_scepter",
    "item_kaya_and_sange",--
    "item_aether_lens",
    "item_black_king_bar",--
    "item_shivas_guard",--
    "item_aghanims_shard",
	"item_octarine_core",--
    -- "item_sheepstick",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_2']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

	"item_octarine_core",--
	"item_hand_of_midas",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_lion

"Ability1"		"lion_impale"
"Ability2"		"lion_voodoo"
"Ability3"		"lion_mana_drain"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"lion_finger_of_death"
"Ability10"		"special_bonus_cast_range_100"
"Ability11"		"special_bonus_attack_damage_90"
"Ability12"		"special_bonus_unique_lion_3"
"Ability13"		"special_bonus_gold_income_25"
"Ability14"		"special_bonus_hp_500"
"Ability15"		"special_bonus_unique_lion"
"Ability16"		"special_bonus_unique_lion_2"
"Ability17"		"special_bonus_unique_lion_4"

modifier_lion_impale
modifier_lion_voodoo
modifier_lion_mana_drain
modifier_lion_finger_of_death_kill_counter
modifier_lion_finger_of_death
modifier_lion_finger_of_death_delay
modifier_lion_arcana_kill_effect

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'lion')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'lion')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'lion')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'lion')
local talent4 = SafeAbility(bot:GetAbilityByName(sTalentList[4]), 'sTalentList[4]', 'lion')
local talent5 = SafeAbility(bot:GetAbilityByName(sTalentList[5]), 'sTalentList[5]', 'lion')
local talent8 = SafeAbility(bot:GetAbilityByName(sTalentList[8]), 'sTalentList[8]', 'lion')

local castQDesire, castQLocation
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget

local aetherRange = 0
local lastCastQTime = -99


local nLV, nKeepMana, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()

	if X.ConsiderStopDrain() > 0
	then
		bot:Action_ClearActions( true )
		return
	end

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies
	

	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		bot:Action_ClearActions( false )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return
	end


	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return

	end


	castQDesire, castQLocation = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQLocation )
		lastCastQTime = DotaTime()
		return
	end


	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		if talent8:IsTrained()
		then
			bot:ActionQueue_UseAbilityOnLocation( abilityW, castWTarget )
		else
			bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		end
		return
	end


end

function X.ConsiderStopDrain()

	if X.IsAbilityEChanneling()
		and Fu.IsRetreating( bot )
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	return BOT_ACTION_DESIRE_NONE

end


function X.IsAbilityEChanneling()

	if bot:IsChanneling()
	then
		local nEnemyCreepList = bot:GetNearbyCreeps( 1200, true )
		for _, nCreep in pairs( nEnemyCreepList )
		do
			if nCreep:HasModifier( "modifier_lion_mana_drain" )
			then
				return true
			end
		end

		local nEnemyHeroList = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE )
		for _, npcEnemy in pairs( nEnemyHeroList )
		do
			if npcEnemy:HasModifier( "modifier_lion_mana_drain" )
			then
				return true
			end
		end
	end

	return false

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange + 20
	local nRadius	 = abilityQ:GetSpecialValueInt( "width" )
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )

	local nTargetLocation = nil

	--击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, 5.0 )
		then
			nTargetLocation = npcEnemy:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-击杀'..Fu.Chat.GetNormName( npcEnemy )
		end
	end

	--Aoe
	local nCanHurtEnemyAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius + 10, 0, 0 )
	if nCanHurtEnemyAoE.count >= 3
	then
		nTargetLocation = nCanHurtEnemyAoE.targetloc
		return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-Aoe:'..( nCanHurtEnemyAoE.count )
	end

	--团战
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius + 20, 2 )
		if nAoeLoc ~= nil
		then
			nTargetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-团控'
		end
	end


	--攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 300 )
		then
			if nSkillLV >= 2 or nMP > 0.68 or Fu.GetHP( botTarget ) < 0.5
			then
				local nDelayTime = nCastPoint + GetUnitToUnitDistance( bot, botTarget )/1600
				nTargetLocation = Fu.GetDelayCastLocation( bot, botTarget, nCastRange, 260, nDelayTime )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-攻击:'..Fu.Chat.GetNormName( botTarget )
				end
			end
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 ) or bot:GetActiveModeDesire() > 0.7 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				nTargetLocation = npcEnemy:GetLocation()
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-撤退:'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--Farm
	if Fu.IsFarming( bot )
		and nSkillLV >= 2
		and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nCastRange )
		if #nNeutralCreeps >= 3
		then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 50, 0, 0 )
			if locationAoE.count >= 2
			then
				nTargetLocation = locationAoE.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q-打钱:"..locationAoE.count
			end
		end
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange, true )
		if #nLaneCreeps >= 3
		then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 50, 0, 0 )
			if locationAoE.count >= 3
			then
				nTargetLocation = locationAoE.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q-Farm:"..locationAoE.count
			end
		end
	end


	--Push
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and nSkillLV >= 4 and DotaTime() > 9 * 60
		and #hAllyList <= 2 and #hEnemyList == 0
		and not bot:HasScepter()
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( 1300, true )
		if #laneCreepList >= 5
			and Fu.IsValid( laneCreepList[1] )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			local locationAoEHurt = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 90, 0, 0 )
			if locationAoEHurt.count >= 3
			then
				nTargetLocation = locationAoEHurt.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q-推线"..locationAoEHurt.count
			end
		end
	end


	--Roshan
	if Fu.IsDoingRoshan( bot )
		and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			nTargetLocation = botTarget:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), ''
		end
	end

	--常规
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 15
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy ) 
				and Fu.IsInRange( bot, npcEnemy, nCastRange )
			then
				nTargetLocation = npcEnemy:GetLocation()
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-常规'
			end
		end
	end

	--Farming: use Earth Spike on neutral creeps
	if Fu.IsFarming( bot )
		and Fu.GetManaAfter( nManaCost ) > 0.3
		and nSkillLV >= 2
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nCastRange )
		if nNeutralCreeps ~= nil and #nNeutralCreeps >= 3
		then
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 50, 0, 0 )
			if locationAoE.count >= 3
			then
				return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc, 'Q-Farm neutrals'
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable()
		or lastCastQTime > DotaTime() - 0.8
	then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange() + aetherRange
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 300, true, BOT_MODE_NONE )

	--打断
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and ( Fu.CanCastOnTargetAdvanced( npcEnemy ) or talent8:IsTrained() )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				if talent8:IsTrained()
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation(), 'W-打断吟唱:'..Fu.Chat.GetNormName( npcEnemy )
				else
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W-打断吟唱:'..Fu.Chat.GetNormName( npcEnemy )
				end
			end

			if npcEnemy:IsCastingAbility()
				and Fu.IsInRange( bot, npcEnemy, nCastRange + 50 )
			then
				if talent8:IsTrained()
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation(), 'W-打断施法:'..Fu.Chat.GetNormName( npcEnemy )
				else
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W-打断施法:'..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end


	--团战中对最强的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
		and ( #nInBonusEnemyList >= 2 or #hAllyList >= 3 )
	then

		if talent8:IsTrained()
		then
			local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, 250, 2 )
			if nAoeLoc ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nAoeLoc, 'W-团控'
			end
		end


		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and ( Fu.CanCastOnTargetAdvanced( npcEnemy ) or talent8:IsTrained() )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
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

		if npcMostDangerousEnemy ~= nil
			and Fu.IsInRange( bot, npcMostDangerousEnemy, nCastRange + 50 )
		then
			if talent8:IsTrained()
			then
				return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy:GetLocation(), 'W-团战:'..Fu.Chat.GetNormName( npcMostDangerousEnemy )
			else
				return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, 'W-团战:'..Fu.Chat.GetNormName( npcMostDangerousEnemy )
			end
		end

	end


	--攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and ( Fu.CanCastOnTargetAdvanced( botTarget ) or talent8:IsTrained() )
			and Fu.IsInRange( bot, botTarget, nCastRange + 150 )
			and not Fu.IsDisabled( botTarget )
			and not Fu.IsTaunted( botTarget )
			and not botTarget:IsDisarmed()
		then
			if talent8:IsTrained()
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), 'W-进攻:'..Fu.Chat.GetNormName( botTarget )
			else
				return BOT_ACTION_DESIRE_HIGH, botTarget, 'W-进攻:'..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	--保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 10
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and ( Fu.CanCastOnTargetAdvanced( npcEnemy ) or talent8:IsTrained() )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				if talent8:IsTrained()
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation(), 'W-保护自己:'..Fu.Chat.GetNormName( npcEnemy )
				else
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W-保护自己'
				end
			end
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 4.0 )
						or GetUnitToUnitDistance( bot, npcEnemy ) <= 600 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and ( Fu.CanCastOnTargetAdvanced( npcEnemy ) or talent8:IsTrained() )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				if talent8:IsTrained()
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation(), 'W-撤退:'..Fu.Chat.GetNormName( npcEnemy )
				else
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, "W-撤退:"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end

	--roshan
	if Fu.IsDoingRoshan( bot ) and nMP > 0.6
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			if talent8:IsTrained()
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), 'W-肉山:'..Fu.Chat.GetNormName( botTarget )
			else
				return BOT_ACTION_DESIRE_HIGH, botTarget, "W-肉山"
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange() + aetherRange
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	local nDuration = abilityE:GetSpecialValueFloat( 'duration' )
	local nManaDrain = abilityE:GetSpecialValueInt( 'mana_per_second' ) * nDuration
	local nLostMana = bot:GetMaxMana() - bot:GetMana()

	local nEnemyTowers = bot:GetNearbyTowers( 1000, true )

	--缺蓝的时候抽蓝
	if #hEnemyList == 0 and #nEnemyTowers == 0
		and not Fu.IsRetreating( bot )
		and not bot:WasRecentlyDamagedByAnyHero( 2.0 )
		and ( nLostMana > nManaDrain + bot:GetManaRegen() * nDuration + 50
				or nLostMana > 500 )
	then
		local nEnemyCreepList = bot:GetNearbyCreeps( 1600, true )
		for _, nCreep in pairs( nEnemyCreepList )
		do
			if Fu.IsValid( nCreep )
				and ( nCreep:GetMana() > nManaDrain * 0.8 or nCreep:GetMana() > 349 )
				and Fu.CanCastOnNonMagicImmune( nCreep )
			then
				return BOT_ACTION_DESIRE_HIGH, nCreep, 'E-补篮'
			end
		end
	end


	--秒杀幻像
	if #hEnemyList >= 1
	then
		local nTargetIllusion = nil
		local nMaxHealth = 0
		local nIllusionCount = 0
		for _, npcEnemy in pairs( hEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and npcEnemy:GetUnitName() ~= "npc_dota_hero_chaos_knight"
				and npcEnemy:GetUnitName() ~= "npc_dota_hero_vengefulspirit"
				and Fu.IsInRange( npcEnemy, bot, nCastRange + 300 )
				and Fu.IsSuspiciousIllusion( npcEnemy )
			then
				nIllusionCount = nIllusionCount + 1
				if npcEnemy:GetHealth() > nMaxHealth
				then
					nTargetIllusion = npcEnemy
					nMaxHealth = npcEnemy:GetHealth()
				end
			end
		end

		if nTargetIllusion ~= nil
			and ( nIllusionCount >= 2 or Fu.GetHP( nTargetIllusion ) > 0.9 )
		then
			return BOT_ACTION_DESIRE_HIGH, nTargetIllusion, 'E-清理幻像:'..Fu.Chat.GetNormName( nTargetIllusion )
		end
	end


	if X.IsOtherAbilityFullyCastable() or nSkillLV <= 1 then return 0 end

	--团战吸蓝
	if Fu.IsInTeamFight( bot, 1000 )
	then
		for _, npcEnemy in pairs( hEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.IsInRange( bot, npcEnemy, nCastRange )
				and not npcEnemy:HasModifier( "modifier_lion_finger_of_death" )
				and npcEnemy:GetMana() > 200
				and Fu.CanCastOnMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and ( not Fu.IsValidHero( botTarget ) or not X.MayKillTarget( botTarget ) )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'E-团战吸篮:'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--打架抽蓝
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and not botTarget:HasModifier( "modifier_lion_finger_of_death" )
			and botTarget:GetMana() > 200
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and not Fu.IsDisabled( botTarget )
			and not X.MayKillTarget( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'E-抽篮:'..Fu.Chat.GetNormName( botTarget )
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nRadius	 = 0
	local nCastRange = abilityR:GetCastRange() + aetherRange
	if nCastRange > 1200 then nCastRange = 1200 end
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamageBonus = X.GetAbilityRDamageBonus()
	local nRawDamage = 475 + 125 * nSkillLV
	if bot:HasScepter()
	then
		nRadius = abilityR:GetSpecialValueInt( 'splash_radius_scepter' )
		nRawDamage = 575 + 125 * nSkillLV
	end

	local nDamage = nRawDamage + nDamageBonus
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 400, true, BOT_MODE_NONE )

	--击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and X.CanCastAbilityROnTarget( npcEnemy )
		then
			if Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint + 0.25 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'R击杀'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end

	--团战对最弱的敌人
	if Fu.IsInTeamFight( bot, 600 )
		or ( nHP < 0.4 and nSkillLV >= 2 )
	then
		local npcWeakestEnemy = nil
		local npcWeakestEnemyHealth = 10000

		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and X.CanCastAbilityROnTarget( npcEnemy )
			then
				local npcEnemyHealth = npcEnemy:GetHealth()
				if ( npcEnemyHealth < npcWeakestEnemyHealth )
				then
					npcWeakestEnemyHealth = npcEnemyHealth
					npcWeakestEnemy = npcEnemy
				end
			end
		end

		if npcWeakestEnemy ~= nil
			and Fu.WillMagicKillTarget( bot, npcWeakestEnemy, nDamage , nCastPoint + 0.25 )
		then
			return BOT_ACTION_DESIRE_HIGH, npcWeakestEnemy, 'R团战'..Fu.Chat.GetNormName( npcWeakestEnemy )
		end

		--有A后的团战Aoe
		if bot:HasScepter()
		then
			local hNearbyEnemyList = Fu.GetEnemyList( bot, nCastRange + nRadius + 200 )
			local nMaxAoeCount = 1
			local nBestAoeEnemy = nil
			for _, npcEnemy in pairs( nInBonusEnemyList )
			do
				if Fu.IsValidHero( npcEnemy )
					and Fu.IsInRange( bot, npcEnemy, nCastRange + 150 )
					and not npcEnemy:IsMagicImmune()
					and not npcEnemy:IsInvulnerable()
				then
					local nAoeCount = 0
					for _, nEnemy in pairs( hNearbyEnemyList )
					do
						if Fu.IsInRange( npcEnemy, nEnemy, nRadius )
							and not nEnemy:IsMagicImmune()
							and not nEnemy:IsInvulnerable()
						then
							nAoeCount = nAoeCount + 1
						end
					end
					if nAoeCount > nMaxAoeCount
					then
						nMaxAoeCount = nAoeCount
						nBestAoeEnemy = npcEnemy
					end
				end
			end

			if nBestAoeEnemy ~= nil
				and ( nMaxAoeCount >= 4
					or ( nMaxAoeCount >= 3 and nHP < 0.46 ) )
			then
				return BOT_ACTION_DESIRE_HIGH, nBestAoeEnemy, 'R团战Aoe:'..Fu.Chat.GetNormName( nBestAoeEnemy )
			end
		end

	end


	--打架
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 200 )
			and X.CanCastAbilityROnTarget( botTarget )
		then
			if Fu.WillMagicKillTarget( bot, botTarget, nDamage , nCastPoint + 0.25 ) or ( nHP < 0.2 and nSkillLV >= 2 )
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget, "R打架"..Fu.Chat.GetNormName( botTarget )
			end
		end
	end





	--撤退
	if Fu.IsRetreating( bot ) and nSkillLV >= 2
		and nHP < 0.3 and bot:WasRecentlyDamagedByAnyHero( 3.0 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and X.CanCastAbilityROnTarget( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "R死前大"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--带线
	if bot:HasScepter()
		and ( Fu.IsPushing( bot ) or Fu.IsFarming( bot ) or Fu.IsDefending( bot ) )
		and nSkillLV >= 3
		and #hEnemyList == 0
		and #hAllyList <= 2
	then
		local nEnemyCreepList = bot:GetNearbyLaneCreeps( 1200, true )
		if #nEnemyCreepList >= 5
			and not nEnemyCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			local nMaxAoeCount = 4
			local nBestCreep = nil
			for _, nCreep in pairs( nEnemyCreepList )
			do
				local nAoeCount = Fu.GetNearbyAroundLocationUnitCount( true, false, nRadius, nCreep:GetLocation() )
				if nAoeCount > nMaxAoeCount
				then
					nBestCreep = nCreep
					nMaxAoeCount = nAoeCount
				end
			end
			if nBestCreep ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nBestCreep, "R-带线"
			end
		end
	end

	--roshan
	if Fu.IsDoingRoshan( bot )
		and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		if Fu.IsRoshan( botTarget ) and Fu.GetHP( botTarget ) > 0.2
			and Fu.IsInRange( bot, botTarget, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.GetAbilityRDamageBonus()

	local nTalantDamage = talent5:IsTrained() and talent5:GetSpecialValueInt( 'value' ) or 0
	local nDamageBonus = abilityR:GetSpecialValueInt( 'damage_per_kill' ) + nTalantDamage
	local sModifierName = "modifier_lion_finger_of_death_kill_counter"
	local nModifierCount = Fu.GetModifierCount( bot, sModifierName )
	

	return nModifierCount * nDamageBonus

end


function X.CanCastAbilityROnTarget( nTarget )

	if Fu.CanCastOnTargetAdvanced( nTarget )
		and not nTarget:HasModifier( "modifier_arc_warden_tempest_double" )
		and not Fu.IsHaveAegis( nTarget )
	then
		return Fu.CanCastOnNonMagicImmune( nTarget )
	end

	return false

end


function X.IsOtherAbilityFullyCastable()

	return abilityQ:IsFullyCastable() or abilityW:IsFullyCastable() or abilityR:IsFullyCastable()

end


function X.MayKillTarget( nTarget )

	if nTarget:HasModifier( "modifier_lion_finger_of_death" )
	then
		return true
	end

	local nDamageToTarget = bot:GetEstimatedDamageToTarget( true, botTarget, 9.0, DAMAGE_TYPE_PHYSICAL )
	if Fu.CanKillTarget( botTarget, nDamageToTarget, DAMAGE_TYPE_PHYSICAL )
	then
		return true
	end

	return false

end

return X
