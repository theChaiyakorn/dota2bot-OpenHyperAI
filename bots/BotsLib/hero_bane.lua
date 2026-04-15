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
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,2,3,2,6,2,3,3,1,1,6,1,1,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {

	"item_crystal_maiden_outfit",
	"item_point_booster",
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_shadow_amulet",
	"item_rod_of_atos",
	"item_invis_sword", 
	"item_black_king_bar",
	"item_silver_edge",
	"item_shivas_guard",
	"item_gungir",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_sheepstick",

}

sRoleItemsBuyList['pos_2'] = {
	
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_pipe",
	"item_aghanims_shard",
	"item_shivas_guard",
	"item_ultimate_scepter",
	"item_wind_waker",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_sheepstick",

}

sRoleItemsBuyList['pos_3'] = {
	
	"item_crystal_maiden_outfit",
	"item_point_booster",
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_shadow_amulet",
	"item_rod_of_atos",
	"item_invis_sword", 
	"item_black_king_bar",
	"item_silver_edge",
	"item_shivas_guard",
	"item_gungir",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_sheepstick",
}

sRoleItemsBuyList['pos_4'] = {
	"item_priest_outfit",
	"item_mekansm",
	"item_shadow_amulet",
--	"item_aghanims_shard",
	"item_guardian_greaves",
	"item_spirit_vessel",
	"item_glimmer_cape",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_mystic_staff",
	"item_sheepstick",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	"item_blood_grenade",

	'item_mage_outfit',
	'item_ancient_janggo',
	'item_glimmer_cape',
	'item_boots_of_bearing',
	'item_pipe',
	"item_shivas_guard",
	'item_mystic_staff',
	'item_sheepstick',
	"item_octarine_core",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_circlet",
	"item_magic_wand"
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_priest' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[


npc_dota_hero_bane


"Ability1"		"bane_nightmare"
"Ability2"		"bane_brain_sap"
"Ability3"		"bane_enfeeble"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"bane_fiends_grip"
"Ability7"		"bane_nightmare_end"
"Ability10"		"special_bonus_armor_6"
"Ability11"		"special_bonus_magic_resistance_15"
"Ability12"		"special_bonus_spell_amplify_7"
"Ability13"		"special_bonus_cast_range_125"
"Ability14"		"special_bonus_unique_bane_5"
"Ability15"		"special_bonus_movement_speed_40"
"Ability16"		"special_bonus_unique_bane_2"
"Ability17"		"special_bonus_unique_bane_3"


modifier_bane_enfeeble
modifier_bane_nightmare
modifier_bane_nightmare_invulnerable
modifier_bane_fiends_grip
modifier_bane_fiends_grip_self


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'bane')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'bane')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'bane')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'bane')
local talent4 = SafeAbility(bot:GetAbilityByName(sTalentList[4]), 'sTalentList[4]', 'bane')
local talent7 = SafeAbility(bot:GetAbilityByName(sTalentList[7]), 'sTalentList[7]', 'bane')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget

local aetherRange = 0
local talent7Damage = 0

local abilityWFirstType = nil


local nLV, nKeepMana, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()

	if abilityWFirstType == nil
		and abilityW:IsTrained()
	then
		abilityWFirstType = abilityW:GetTargetType()
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
--	if talent4:IsTrained() then aetherRange = aetherRange + talent4:GetSpecialValueInt( "value" ) end
	if talent7:IsTrained() then talent7Damage = talent7:GetSpecialValueInt( "value" ) end

	
	castQDesire, castQTarget = X.ConsiderQ()
	if castQDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end



	castWDesire, castWTarget = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		if abilityWFirstType ~= nil
			and abilityWFirstType ~= abilityW:GetTargetType()
		then
			bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget:GetLocation() )
		else
			bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		end
		return
	end


	castRDesire, castRTarget = X.ConsiderR()
	if castRDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		Fu.SetQueueToInvisible( bot )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return
	end


	castEDesire, castETarget = X.ConsiderE()
	if castEDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return
	end
	



end

--虚弱 'modifier_bane_enfeeble'
function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetSpecialValueInt( 'damage' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil


	--打断
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				hCastTarget = npcEnemy
				sCastMotive = 'E-打断'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end



	--撤退时保护自己
	if Fu.IsRetreating( bot )
		and ( bot:WasRecentlyDamagedByAnyHero( 3.0 ) or bot:GetActiveModeDesire() > 0.7 )
	then
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				hCastTarget = npcEnemy
				sCastMotive = 'E-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	--团战中对最能输出的人使用
	if Fu.IsInTeamFight( bot, 1200 ) 
	then
		local npcStrongestEnemy = nil
		local nStrongestPower = 0
		local nEnemyCount = 0
		
		for _, npcEnemy in pairs( hEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				nEnemyCount = nEnemyCount + 1
				if Fu.CanCastOnTargetAdvanced( npcEnemy )
					and not Fu.IsDisabled( npcEnemy )
					and not npcEnemy:IsDisarmed()
				then
					local npcEnemyPower = npcEnemy:GetEstimatedDamageToTarget( true, bot, 6.0, DAMAGE_TYPE_ALL )
					if ( npcEnemyPower > nStrongestPower )
					then
						nStrongestPower = npcEnemyPower
						npcStrongestEnemy = npcEnemy
					end
				end
			end
		end

		if npcStrongestEnemy ~= nil and nEnemyCount >= 2
			and Fu.IsInRange( bot, npcStrongestEnemy, nCastRange + 150 )
		then
			hCastTarget = npcStrongestEnemy
			sCastMotive = 'E-团战控制'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	--打架时对目标之外的人或目标使用
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, 1200 )
		then
			for _, npcEnemy in pairs( nInRangeEnemyList )
			do
				if Fu.IsValid( npcEnemy )
					and npcEnemy:GetPlayerID() ~= botTarget:GetPlayerID()
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
					and Fu.CanCastOnTargetAdvanced( npcEnemy )
					and not Fu.IsDisabled( npcEnemy )
					and not npcEnemy:IsDisarmed()
				then
					hCastTarget = npcEnemy
					sCastMotive = 'E-睡眠:'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
			
			if Fu.IsInRange( bot, botTarget, nCastRange )
				and not Fu.IsInRange( bot, botTarget, 530 )
				and Fu.IsRunning( botTarget )
				and bot:IsFacingLocation( botTarget:GetLocation(), 20 )
				and not botTarget:IsFacingLocation( bot:GetLocation(), 150 )
				and Fu.CanCastOnNonMagicImmune( botTarget )
				and Fu.CanCastOnTargetAdvanced( botTarget )
			then
				local allyList = Fu.GetNearbyHeroes(botTarget,  500, true, BOT_MODE_NONE )
				if #allyList == 0
				then
					hCastTarget = botTarget
					sCastMotive = 'E-留人'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
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
	local nDamage = abilityW:GetSpecialValueInt( 'brain_sap_damage' ) + talent7Damage
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	local nLostHealth = bot:GetMaxHealth() - bot:GetHealth()


	--对线时回血并补刀远程兵


	--击杀敌人
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			if Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-击杀敌人'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end

		end
	end


	--7级以下如果不能给自己恢复对应的生命值则先不用
	if nLV <= 7 and nMP < 0.72
		and nLostHealth < nDamage * 0.8
	then return BOT_ACTION_DESIRE_NONE end

	--团战中对最弱的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nWeakestEnemy = nil
		local nWeakestEnemyHealth = 99999

		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				local npcEnemyHealth = npcEnemy:GetHealth()
				if ( npcEnemyHealth < nWeakestEnemyHealth )
				then
					nWeakestEnemyHealth = npcEnemyHealth
					nWeakestEnemy = npcEnemy
				end
			end
		end

		if ( nWeakestEnemy ~= nil )
		then
			hCastTarget = nWeakestEnemy
			sCastMotive = 'W-团战最弱'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	--进攻敌人
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
		then
			if nSkillLV >= 2 or nMP > 0.78 or Fu.GetHP( botTarget ) < 0.38
			then
				hCastTarget = botTarget
				sCastMotive = 'W-攻击'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	--受到伤害时保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 10
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
		and nLostHealth >= nDamage
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 45 )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-自我保护'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end

	--撤退时回血
	if Fu.IsRetreating( bot ) and nLostHealth > nDamage
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 ) or nLostHealth > nDamage * 2 )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-通过敌人回血'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end

		if #hEnemyList == 0 and nLV >= 10
			and not bot:WasRecentlyDamagedByAnyHero( 3.0 )
			and nLostHealth > nDamage * 1.5
		then
			local creepList = bot:GetNearbyCreeps( 1000, true )
			for _, creep in pairs( creepList )
			do
				if Fu.IsValid( creep )
					and Fu.CanCastOnNonMagicImmune( creep )
				then
					hCastTarget = creep
					sCastMotive = 'W-通过小兵回血'
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end
	end


	--发育时对野怪输出
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local targetCreep = botTarget

		if Fu.IsValid( targetCreep )
			and Fu.IsInRange( bot, targetCreep, nCastRange + 100 )
			and targetCreep:GetTeam() == TEAM_NEUTRAL
			and not Fu.IsRoshan( targetCreep )
			and ( targetCreep:GetMagicResist() < 0.3 or nMP > 0.8 )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 2, DAMAGE_TYPE_PHYSICAL )
		then
			hCastTarget = targetCreep
			sCastMotive = 'W-打野'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and nSkillLV >= 3 and DotaTime() > 8 * 60
		and #hAllyList <= 2 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( 1200, true )
		local keyWord = "ranged"
		for _, creep in pairs( laneCreepList )
		do
			if Fu.IsValid( creep )
				and ( Fu.IsKeyWordUnit( keyWord, creep ) or nMP > 0.6 )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				and not Fu.CanKillTarget( creep, bot:GetAttackDamage() * 1.38, DAMAGE_TYPE_PHYSICAL )
			then
				hCastTarget = creep
				sCastMotive = 'W-带线'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	--肉山
	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and not Fu.IsDisabled(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	--通用消耗敌人或受到伤害时保护自己
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 12
		and nLostHealth > nDamage
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-通用情况'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	--进攻敌人
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and not botTarget:HasModifier( 'modifier_bane_enfeeble' )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
		then
			if nSkillLV >= 2 or nMP > 0.6
			then
				hCastTarget = botTarget
				sCastMotive = 'Q-攻击'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
		
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_bane_enfeeble' )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'Q-虚弱其他人'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderR()


	if not abilityR:IsFullyCastable()
	then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetSpecialValueInt( 'fiend_grip_damage' ) * 6
	local nDamageType = DAMAGE_TYPE_PURE
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	--打断和击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				hCastTarget = npcEnemy
				sCastMotive = 'R-打断'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end

			if Fu.IsInRange( bot, npcEnemy, nCastRange + 80 )
				and Fu.CanKillTarget( npcEnemy, nDamage, nDamageType )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'R-击杀'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end

		end
	end


	if abilityW:IsFullyCastable() and bot:GetMana() > abilityR:GetManaCost() + abilityW:GetManaCost()
	then return 0 end


	--团战中控制
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcStrongestEnemy = nil
		local nStrongestPower = 0

		for _, npcEnemy in pairs( hEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				local npcEnemyPower = npcEnemy:GetEstimatedDamageToTarget( true, bot, 6.0, DAMAGE_TYPE_ALL )
				if ( npcEnemyPower > nStrongestPower )
				then
					nStrongestPower = npcEnemyPower
					npcStrongestEnemy = npcEnemy
				end
			end
		end

		if npcStrongestEnemy ~= nil
			and Fu.IsInRange( bot, npcStrongestEnemy, nCastRange + 100 )
		then
			hCastTarget = npcStrongestEnemy
			sCastMotive = 'R-团战控制'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	--进攻敌人
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'R-攻击'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


return X
