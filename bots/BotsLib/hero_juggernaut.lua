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
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,2,1,3,1,6,1,2,2,2,6,3,3,3,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_slippers",
	"item_circlet",
	"item_quelling_blade",

	"item_wraith_band",
	"item_magic_wand",
	"item_power_treads",
	"item_maelstrom",
	"item_manta",--
	"item_mjollnir",--
	"item_skadi",--
	"item_aghanims_shard",
	"item_basher",
	"item_butterfly",--
	"item_moon_shard",
	"item_abyssal_blade",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_melee_carry' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		if hMinionUnit:GetUnitName() == 'npc_dota_juggernaut_healing_ward'
		then
			Minion.HealingWardThink( hMinionUnit )
		else
			Minion.IllusionThink( hMinionUnit )
		end
	end

end

--[[

npc_dota_hero_juggernaut

"Ability1"		"juggernaut_blade_fury"
"Ability2"		"juggernaut_healing_ward"
"Ability3"		"juggernaut_blade_dance"
"Ability4"		"juggernaut_swift_slash"
"Ability5"		"generic_hidden"
"Ability6"		"juggernaut_omni_slash"
"Ability10"		"special_bonus_all_stats_5"
"Ability11"		"special_bonus_movement_speed_20"
"Ability12"		"special_bonus_unique_juggernaut_4"
"Ability13"		"special_bonus_attack_speed_20"
"Ability14"		"special_bonus_armor_8"
"Ability15"		"special_bonus_unique_juggernaut_3"
"Ability16"		"special_bonus_hp_475"
"Ability17"		"special_bonus_unique_juggernaut_2"

modifier_juggernaut_blade_fury
modifier_juggernaut_healing_ward_aura
modifier_juggernaut_healing_ward_tracker
modifier_juggernaut_healing_ward_heal
modifier_juggernaut_blade_dance
modifier_juggernaut_omnislash
modifier_juggernaut_omnislash_invulnerability


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'juggernaut')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'juggernaut')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'juggernaut')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'juggernaut')
local abilityD = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'juggernaut')
local talent2 = SafeAbility(bot:GetAbilityByName(sTalentList[2]), 'sTalentList[2]', 'juggernaut')
local talent6 = SafeAbility(bot:GetAbilityByName(sTalentList[6]), 'sTalentList[6]', 'juggernaut')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget
local castDDesire, castDTarget

local aetherRange = 0


function X.SkillsComplement()

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


	castDDesire, castDTarget = X.ConsiderD()
	if castDDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityD, castDTarget )
		return
	end

	castRDesire, castRTarget = X.ConsiderR()
	if castRDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if castQDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityQ )
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWTarget )
		return
	end
	

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() 
		or bot:HasModifier('modifier_juggernaut_blade_fury')
		or bot:HasModifier('modifier_juggernaut_omnislash')
	then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetSpecialValueInt( 'blade_fury_radius' )
	local nRadius = abilityQ:GetSpecialValueInt( 'blade_fury_radius' )
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nRadius )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nRadius + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	--防御眩晕弹道
	if nHP < 0.85 
		and Fu.IsStunProjectileIncoming( bot, 1000 )
	then		
		hCastTarget = bot
		sCastMotive = 'Q-防御眩晕弹道'
		return BOT_ACTION_DESIRE_HIGH, sCastMotive		
	end	
	
	--打架攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nRadius )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
		then			
			hCastTarget = botTarget
			sCastMotive = 'Q-攻击:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	--团战AOE
	if Fu.IsInTeamFight( bot, 1000 )
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do 
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				nAoeCount = nAoeCount + 1	
			end
		end

		if nAoeCount >= 2
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-团战AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( hEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.IsInRange( bot, npcEnemy, 1200 )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 )
				and Fu.CanCastOnMagicImmune( npcEnemy )
				and ( Fu.IsInRange( bot, npcEnemy, nRadius - 120 ) 
					or ( nLV >= 9 and bot:GetCurrentMovementSpeed() < 220 ) )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'Q-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, sCastMotive
			end
		end
		
		if Fu.IsNotAttackProjectileIncoming( bot, 700 )
		then
			hCastTarget = bot
			sCastMotive = 'Q-躲避'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end		
	end
		
	
	--带线AOE
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and #hAllyList <= 2 
		and Fu.IsItemAvailable( "item_bfury" ) == nil
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange , true )
		if ( #laneCreepList >= 4 or ( #laneCreepList >= 3 and nMP > 0.82 ) )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			hCastTarget = creep
			sCastMotive = 'Q-带线AOE'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	
	--打野AOE
	if Fu.IsFarming( bot )
		and DotaTime() > 6 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
		and Fu.IsItemAvailable( "item_bfury" ) == nil
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius )

		if #creepList >= 4
			and Fu.IsValid( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
	    end
	end



	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetSpecialValueInt( 'dam' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	--团战回血
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local lostHP = 0
		for _, npcAlly in pairs( hAllyList )
		do 
			if Fu.IsValidHero( npcAlly )
				and Fu.IsInRange( bot, npcAlly, 1000 )
			then
				lostHP = lostHP + 1 - npcAlly:GetHealth()/npcAlly:GetMaxHealth()
			end
		end
		
		if lostHP >= 0.6
		then
			hCastTarget = Fu.GetFaceTowardDistanceLocation( bot, 16 )
			sCastMotive = 'W-团战辅助'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive			
		end
	end	
	
	
	
	--攻击敌人时
	if Fu.IsGoingOnSomeone( bot )
		and nHP < 0.6
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, 900 )
			and Fu.CanCastOnMagicImmune( botTarget )
		then
			hCastTarget = Fu.GetFaceTowardDistanceLocation( bot, 16 )
			sCastMotive = 'W-辅助进攻:'..Fu.Chat.GetNormName( botTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive	
		end
	end
	
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot ) 
		and nHP < 0.5
		and bot:DistanceFromFountain() > 800
	then
		hCastTarget = Fu.GetFaceTowardDistanceLocation( bot, 16 )
		sCastMotive = 'W-撤退回血'
		return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive	
	end
	
	

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderR()


	if not abilityR:IsFullyCastable() 
		or bot:HasModifier('modifier_juggernaut_blade_fury')
		or bot:HasModifier('modifier_juggernaut_omnislash')
	then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange() 
	local nRadius = 600
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetSpecialValueInt( 'damage' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 50 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--防御眩晕弹道
	if Fu.IsStunProjectileIncoming( bot, 1000 )
	then
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'R-防御:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end	
	end
	
	
	--攻击敌人时
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, 900 )
			and ( botTarget:GetHealth() > bot:GetAttackDamage() * 4 
					or nHP < 0.2
					or #nInBonusEnemyList >= 2 )
		then
			for _, npcEnemy in pairs( nInRangeEnemyList )
			do
				if Fu.IsValid( npcEnemy )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
					and Fu.CanCastOnTargetAdvanced( npcEnemy )
				then
					hCastTarget = npcEnemy
					sCastMotive = 'R-攻击:'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
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
			then
				hCastTarget = npcEnemy
				sCastMotive = 'R-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end



	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderD()


	if	not bot:HasScepter()
		or not abilityD:IsFullyCastable() 
		or bot:HasModifier('modifier_juggernaut_blade_fury')
		or bot:HasModifier('modifier_juggernaut_omnislash')
	then return 0 end

	local nSkillLV = abilityD:GetLevel()
	local nCastRange = abilityD:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityD:GetCastPoint()
	local nManaCost = abilityD:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	--攻击敌人时
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, 1400 )
		then
			for _, npcEnemy in pairs( nInRangeEnemyList )
			do
				if Fu.IsValid( npcEnemy )
					and Fu.IsInRange( botTarget, npcEnemy, 425 )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
					and Fu.CanCastOnTargetAdvanced( npcEnemy )
				then
					hCastTarget = npcEnemy
					sCastMotive = 'D-攻击:'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end
	end
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'D-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


return X

