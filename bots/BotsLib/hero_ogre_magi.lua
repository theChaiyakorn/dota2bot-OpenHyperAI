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
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						},
						{--pos3
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						}
}

local tAllAbilityBuildList = {
						{3,2,2,1,2,6,2,1,1,1,6,3,3,3,6},--pos2
						{2,1,2,3,2,6,3,1,1,1,6,3,3,2,6},--pos3
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

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
    "item_hand_of_midas",
	"item_crimson_guard",--
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_heavens_halberd",--
	"item_travel_boots",
	"item_assault",--
	"item_sheepstick",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
	"item_octarine_core",--
}

sRoleItemsBuyList['pos_1'] = {
	
	"item_bristleback_outfit",
	"item_hand_of_midas",
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_dagon_5",
	"item_travel_boots",
	"item_sheepstick", --
	"item_octarine_core",
	"item_moon_shard",
	"item_travel_boots_2",
	"item_ultimate_scepter_2",
	"item_bloodthorn",
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",

	"item_bracer",
	"item_bottle",
	"item_phase_boots",
	"item_soul_ring",
	"item_magic_wand",
	"item_hand_of_midas",
	"item_blade_mail",
	"item_heart",--
	"item_black_king_bar",--
	"item_shivas_guard",--
	"item_ultimate_scepter",
	"item_octarine_core",--
	"item_travel_boots",
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_travel_boots_2",--
	"item_moon_shard",
	"item_aghanims_shard",
}

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",
	"item_aghanims_shard",
	"item_guardian_greaves",
	"item_spirit_vessel",
	"item_lotus_orb",
	"item_gungir",--
	--"item_holy_locket",
	"item_ultimate_scepter",
	"item_sheepstick",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_shivas_guard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_mage_outfit',
	"item_hand_of_midas",
	"item_glimmer_cape",

    "item_pavise",
	"item_pipe",--
    "item_solar_crest",--
	"item_lotus_orb",--
	"item_aghanims_shard",
	"item_spirit_vessel",--
	"item_ultimate_scepter",
	"item_shivas_guard",--
	"item_mystic_staff",
	"item_ultimate_scepter_2",
    "item_moon_shard",
	"item_sheepstick",--
}


X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

	"item_sheepstick",
	"item_hand_of_midas",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_OM' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_ogre_magi

ogre_magi_fireblast
ogre_magi_ignite
ogre_magi_bloodlust
ogre_magi_unrefined_fireblast
ogre_magi_multicast
special_bonus_gold_income_10
special_bonus_cast_range_100
special_bonus_attack_damage_50
special_bonus_magic_resistance_8
special_bonus_hp_250
special_bonus_movement_speed_25
special_bonus_spell_amplify_15
special_bonus_unique_ogre_magi


modifier_ogre_magi_frost_armor
modifier_ogre_magi_frost_armor_slow
modifier_ogre_magi_fireblast_multicast
modifier_ogre_magi_ignite
modifier_ogre_magi_ignite_multicast
modifier_ogre_magi_bloodlust_autocast
modifier_ogre_magi_bloodlust

]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'ogre_magi')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'ogre_magi')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'ogre_magi')
local abilityD = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'ogre_magi')
local FireShield = SafeAbility(bot:GetAbilityByName(sAbilityList[5]), 'sAbilityList[5]', 'ogre_magi')
local talent2 = SafeAbility(bot:GetAbilityByName(sTalentList[2]), 'sTalentList[2]', 'ogre_magi')
local talent8 = SafeAbility(bot:GetAbilityByName(sTalentList[8]), 'sTalentList[8]', 'ogre_magi')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castDDesire, castDTarget
local FireShieldDesire, FireShieldTarget


local aetherRange = 0
local talent8Damage = 0


local bAttacking
local nLV, nKeepMana, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()


	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	bAttacking = Fu.IsAttacking(bot)


	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 300
	aetherRange = ctx.aetherRange
	talent8Damage = 0
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies
--	if talent2:IsTrained() then aetherRange = aetherRange + talent2:GetSpecialValueInt( "value" ) end
	if talent8:IsTrained() then talent8Damage = talent8Damage + talent8:GetSpecialValueInt( "value" ) end


	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end

	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return
	end

	castDDesire, castDTarget = X.ConsiderD()
	if ( castDDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityD, castDTarget )
		return
	end

	FireShieldDesire, FireShieldTarget = X.ConsiderFireShield()
	if ( FireShieldDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( FireShield, FireShieldTarget )
		return

	end


end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange

	if #hEnemyList <= 1 then nCastRange = nCastRange + 200 end

	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( "fireblast_damage" ) + talent8Damage
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )

	--打断和击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q打断'..Fu.Chat.GetNormName( npcEnemy )
			end

			if Fu.IsInRange( bot, npcEnemy, nCastRange + 80 )
				and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage * 2.38, nCastPoint )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q击杀'..Fu.Chat.GetNormName( npcEnemy )
			end

		end
	end


	--团战中对战力最强的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcStrongestEnemy = nil
		local npcStrongestEnemyPower = 0

		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				local npcEnemyPower = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_PHYSICAL )
				if ( npcEnemyPower > npcStrongestEnemyPower )
				then
					npcStrongestEnemyPower = npcEnemyPower
					npcStrongestEnemy = npcEnemy
				end
			end
		end

		if ( npcStrongestEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcStrongestEnemy, 'Q团战'..Fu.Chat.GetNormName( npcStrongestEnemy )
		end
	end


	--受到伤害时保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 10
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 60 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q自保'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--对线期间对线上小兵使用
	if bot:GetActiveMode() == BOT_MODE_LANING
		or ( (#hAllyList <= 1 or Fu.IsCore(bot)) and #hEnemyList == 0 )
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 200, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and not Fu.IsOtherAllysTarget( creep )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				and GetUnitToUnitDistance( creep, bot ) > 280
			then
				return BOT_ACTION_DESIRE_HIGH, creep, 'Q补远'
			end
		end

		if nSkillLV >= 2
			and ( bot:GetMana() > nKeepMana or nMP > 0.9 )
		then
			local keyWord = "melee"
			for _, creep in pairs( nLaneCreeps )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and Fu.IsKeyWordUnit( keyWord, creep )
					and not Fu.IsOtherAllysTarget( creep )
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
					and GetUnitToUnitDistance( creep, bot ) > 350
				then
					return BOT_ACTION_DESIRE_HIGH, creep, 'Q补近'
				end
			end
		end
	end


	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			if nSkillLV >= 3 or nMP > 0.78 or Fu.GetHP( botTarget ) < 0.38 or nLV >= 7
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q先手'..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q撤退'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--发育时对野怪输出
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 100 )

		local targetCreep = Fu.GetMostHpUnit( nCreeps )

		if Fu.IsValid( targetCreep )
			and not Fu.IsRoshan( targetCreep )
			and ( #nCreeps >= 2 or GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
			and bot:IsFacingLocation( targetCreep:GetLocation(), 60 )
			and ( targetCreep:GetMagicResist() < 0.3 or nMP > 0.9 )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 2.28, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( targetCreep, nDamage - 10, nDamageType )
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep, 'Q打野'
		end
	end


	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and ( bot:GetAttackDamage() < 200 or nMP > 0.8 )
		and nSkillLV >= 2 and DotaTime() > 6 * 60
		and #hAllyList <= 2 and #hEnemyList == 0
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 50, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and ( Fu.IsKeyWordUnit( keyWord, creep ) or nMP > 0.6 )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				and not Fu.CanKillTarget( creep, bot:GetAttackDamage() * 1.38, DAMAGE_TYPE_PHYSICAL )
			then
				return BOT_ACTION_DESIRE_HIGH, creep, 'Q带线'
			end
		end
	end


	--打肉的时候输出
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 400
	then
		if Fu.IsRoshan( botTarget )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q肉山'
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, 800 )
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end

	--通用消耗敌人或受到伤害时保护自己
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 15
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.IsInRange( bot, npcEnemy, 600 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q通用'
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange() + aetherRange
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDuration = abilityW:GetSpecialValueInt( "duration" )
	local nDamage = abilityW:GetSpecialValueInt( "burn_damage" ) * nDuration
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 32, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )

	--击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nDuration )
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W击杀'..Fu.Chat.GetNormName( npcEnemy )
		end
	end


	--团战中对血量最多的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcMostHPEnemy = nil
		local npcMostHPEnemyHealth = 0

		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				local npcEnemyHealth = npcEnemy:GetHealth()
				if ( npcEnemyHealth > npcMostHPEnemyHealth )
				then
					npcMostHPEnemyHealth = npcEnemyHealth
					npcMostHPEnemy = npcEnemy
				end
			end
		end

		if ( npcMostHPEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostHPEnemy, 'W团战'..Fu.Chat.GetNormName( npcMostHPEnemy )
		end
	end


	--受到伤害时保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 10
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 30 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W保护'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'W先手'..Fu.Chat.GetNormName( botTarget )
		end
	end


	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W撤退'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--发育时对野怪输出
	if Fu.IsFarming( bot )
		and nSkillLV >= 2 and nLV >= 6
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 100 )

		local targetCreep = Fu.GetMostHpUnit( nCreeps )

		if Fu.IsValid( targetCreep )
			and not Fu.IsRoshan( targetCreep )
			and ( #nCreeps >= 2 or GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
			and bot:IsFacingLocation( targetCreep:GetLocation(), 40 )
			and ( targetCreep:GetMagicResist() < 0.3 or nMP > 0.8 )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 2.28, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( targetCreep, nDamage * 0.38, nDamageType )
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep, 'W打野'
		end
	end


	--推进时对远程兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and ( bot:GetAttackDamage() < 200 or nMP > 0.8 )
		and nSkillLV >= 2 and DotaTime() > 8 * 60
		and #hAllyList <= 2
	then
		local nLaneCreepsInView = bot:GetNearbyLaneCreeps( 1600, true )
		if #nLaneCreepsInView >= 3
		then
			local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 50, true )
			local nAllyCreeps = bot:GetNearbyLaneCreeps( 1000, false )
			local keyWord = "ranged"
			for _, creep in pairs( nLaneCreeps )
			do
				if Fu.IsValid( creep )
					and ( Fu.IsKeyWordUnit( keyWord, creep ) or #nAllyCreeps == 0 )
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and not Fu.CanKillTarget( creep, bot:GetAttackDamage() * 1.68, DAMAGE_TYPE_PHYSICAL )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, 'W带线'
				end
			end
		end
	end


	--通用消耗敌人或受到伤害时保护自己
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 18
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W通用'
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

--"modifier_ogre_magi_bloodlust"
function X.ConsiderE()

	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange() + aetherRange
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = bot:GetAttackDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nInRangeCreepList = bot:GetNearbyCreeps( nCastRange + 100, false )
	local nInRangeTowerList = bot:GetNearbyTowers( nCastRange + 50, false )
	local nInRangeAllyList = Fu.GetAlliesNearLoc( bot:GetLocation(), nCastRange + 52 )

	local bestTarget = nil
	local nMaxDamage = 0
	for _, ally in pairs( nInRangeAllyList )
	do
		if Fu.IsValidHero( ally )
			and not ally:HasModifier( "modifier_ogre_magi_bloodlust" )
			and not Fu.IsDisabled( ally )
			and not Fu.IsWithoutTarget( ally )
			and ally:GetAttackDamage() > nMaxDamage
		then
			bestTarget = ally
			nMaxDamage = ally:GetAttackDamage()
		end
	end

	--打架
	if Fu.IsGoingOnSomeone( bot )
		and Fu.IsValidHero( botTarget )
		and bestTarget ~= nil
	then
		if bestTarget == bot and Fu.IsInRange( bot, botTarget, 900 )
		then
			return BOT_ACTION_DESIRE_HIGH, bestTarget, 'E自己'
		end

		if bestTarget ~= bot and Fu.IsInRange( bot, botTarget, 2000 )
		then
			return BOT_ACTION_DESIRE_HIGH, bestTarget, 'E队友'..Fu.Chat.GetNormName( bestTarget )
		end
	end

	--撤退
	if #hEnemyList > 0
	then
		local bestAlly = nil
		local maxDist = 300

		for _, ally in pairs( nInRangeAllyList )
		do
			if Fu.IsValidHero( ally )
				and not ally:HasModifier( "modifier_ogre_magi_bloodlust" )
				and Fu.IsRetreating( ally )
				and ally:WasRecentlyDamagedByAnyHero( 5.0 )
				and ally:DistanceFromFountain() > maxDist
			then
				bestAlly = ally
				maxDist = ally:DistanceFromFountain()
			end
		end

		if bestAlly ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, bestAlly, 'E撤退'..Fu.Chat.GetNormName( bestAlly )
		end
	end

	--打钱推线
	if nLV >= 6
	then
		local bestAlly = nil
		local maxDamage = 108

		for _, ally in pairs( nInRangeAllyList )
		do
			if Fu.IsValidHero( ally )
				and not ally:HasModifier( "modifier_ogre_magi_bloodlust" )
				and ( Fu.IsFarming( ally ) or Fu.IsPushing( ally ) or Fu.IsDefending( ally ) )
				and ally:GetAttackDamage() > maxDamage
			then
				bestAlly = ally
				nMaxDamage = ally:GetAttackDamage()
			end
		end

		if bestAlly ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, bestAlly, 'E打钱'..Fu.Chat.GetNormName( bestAlly )
		end

		--防守塔
		local hTower = nInRangeTowerList[1]
		if Fu.IsValidBuilding( hTower )
			and not hTower:HasModifier( "modifier_ogre_magi_bloodlust" )
			and not Fu.IsWithoutTarget( hTower )
			and #hEnemyList >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, hTower, 'E守塔'
		end

		--辅助进攻
		if #nInRangeCreepList > 0
		then
			for _, creep in pairs( nInRangeCreepList )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( "modifier_ogre_magi_bloodlust" )
				then

					--给攻城车
					if Fu.IsKeyWordUnit( 'siege', creep )
						and not Fu.IsWithoutTarget( creep )
					then
						local creepTarget = creep:GetAttackTarget()
						if Fu.IsValidBuilding( creepTarget )
							and creepTarget:GetAttackTarget() ~= creep
						then
							return BOT_ACTION_DESIRE_HIGH, creep, 'E攻城车'
						end
					end

					--给地狱火
					if Fu.IsKeyWordUnit( 'warlock', creep )
						and #hEnemyList > 0
					then
						return BOT_ACTION_DESIRE_HIGH, creep, 'E地狱火'
					end

					--给远程兵带线
					if Fu.IsKeyWordUnit( 'ranged', creep )
						and Fu.GetHP( creep ) > 0.8
						and nLV >= 12
						and #hEnemyList == 0 and #hAllyList == 1
					then
						local nEnemyCreepList = bot:GetNearbyLaneCreeps( 1600, true )
						if #nEnemyCreepList == 0
						then
							return BOT_ACTION_DESIRE_HIGH, creep, 'E远程兵'
						end
					end

				end
			end
		end

	end

	if bot:GetActiveMode() == BOT_MODE_ROSHAN and bestTarget ~= nil
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, 1000 )
			and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, bestTarget, 'E打肉'..Fu.Chat.GetNormName( bestTarget )
		end
	end

	if Fu.IsDoingTormentor(bot) and bestTarget ~= nil then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, 800 )
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, bestTarget, ''
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderD()


	if abilityQ:IsFullyCastable() or not abilityD:IsFullyCastable() or not bot:HasScepter() then return 0 end

	local nSkillLV = abilityD:GetLevel()
	local nCastRange = abilityD:GetCastRange() + aetherRange

	if #hEnemyList <= 1 then nCastRange = nCastRange + 200 end

	local nCastPoint = abilityD:GetCastPoint()
	local nManaCost = abilityD:GetManaCost()
	local nDamage = abilityD:GetSpecialValueInt( "fireblast_damage" )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )

	if nManaCost/bot:GetMaxMana() > 0.45 and nHP > 0.25 then return 0 end

	--打断和击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'D打断'..Fu.Chat.GetNormName( npcEnemy )
			end

			if Fu.IsInRange( bot, npcEnemy, nCastRange + 80 )
				and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage * 2.38, nCastPoint )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'D击杀'..Fu.Chat.GetNormName( npcEnemy )
			end

		end
	end


	--团战中对血量最低的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcWeakestEnemy = nil
		local npcWeakestEnemyHealth = 10000

		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				local npcEnemyHealth = npcEnemy:GetHealth()
				if ( npcEnemyHealth < npcWeakestEnemyHealth )
				then
					npcWeakestEnemyHealth = npcEnemyHealth
					npcWeakestEnemy = npcEnemy
				end
			end
		end

		if ( npcWeakestEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcWeakestEnemy, 'D团战'..Fu.Chat.GetNormName( npcWeakestEnemy )
		end
	end


	--受伤
	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 15
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 45 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'D保护'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--打架
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
			and not Fu.IsDisabled( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'D打架'..Fu.Chat.GetNormName( botTarget )
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and ( #nInBonusEnemyList <= 2 or bot:IsFacingLocation( npcEnemy:GetLocation(), 30 ) )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'D撤退'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--打钱
	if Fu.IsFarming( bot )
		and nManaCost < bot:GetMaxMana() * 0.1
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 100 )

		local targetCreep = Fu.GetMostHpUnit( nCreeps )

		if Fu.IsValid( targetCreep )
			and not Fu.IsRoshan( targetCreep )
			and ( #nCreeps >= 2 or GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
			and bot:IsFacingLocation( targetCreep:GetLocation(), 40 )
			and ( targetCreep:GetMagicResist() < 0.3 or nMP > 0.9 )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 1.88, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( targetCreep, nDamage - 10, nDamageType )
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep, 'D打野'
		end
	end


	--推进
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and nManaCost < 120 and #hAllyList <= 2 and #hEnemyList == 0
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 50, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and ( Fu.IsKeyWordUnit( keyWord, creep ) or nMP > 0.6 )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				and not Fu.CanKillTarget( creep, bot:GetAttackDamage() * 1.38, DAMAGE_TYPE_PHYSICAL )
			then
				return BOT_ACTION_DESIRE_HIGH, creep, 'D带线'
			end
		end
	end


	--打肉
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and nManaCost < 100
	then
		if Fu.IsRoshan( botTarget )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'D肉山'
		end
	end


	--通用
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 15
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.IsInRange( bot, npcEnemy, 600 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'D通用'
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderFireShield()

	if not FireShield:IsTrained()
	or not FireShield:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = 600
	local nCastRange = FireShield:GetCastRange() + aetherRange
	local nCastPoint = FireShield:GetCastPoint()
	local nManaCost = FireShield:GetManaCost()

	for _, npcEnemy in pairs( hEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
		and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then
			local enemyTarget = npcEnemy:GetAttackTarget()

			if enemyTarget ~= nil
			and Fu.IsInRange( bot, enemyTarget, nCastRange )
			and not enemyTarget:HasModifier( 'modifier_fountain_glyph' )
			and not enemyTarget:HasModifier( 'modifier_ogre_magi_smash_buff' )
			then
				if enemyTarget:IsTower() and npcEnemy:IsBot()
				then
					return BOT_ACTION_DESIRE_HIGH, enemyTarget, "AS-守塔"
				end

				if enemyTarget:IsHero()
				and not enemyTarget:IsIllusion()
				then
					return BOT_ACTION_DESIRE_HIGH, enemyTarget, "AS-保护队友:"..Fu.Chat.GetNormName(enemyTarget)
				end
			end
		end	
	end

	return BOT_ACTION_DESIRE_NONE, 0

end


return X


