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
						{1,3,1,2,1,6,1,3,3,3,6,2,2,2,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local utilityItems = {"item_crimson_guard", "item_pipe", "item_heavens_halberd"}
local sCrimsonPipeHalberd = utilityItems[RandomInt(1, #utilityItems)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",

	"item_magic_wand",
	"item_bracer",
	"item_phase_boots",
	"item_blade_mail",
	"item_blink",
	"item_black_king_bar",--
	sCrimsonPipeHalberd,--
	"item_assault",--
	"item_greater_crit",--
	"item_overwhelming_blink",--
	"item_travel_boots_2",--
	"item_moon_shard",
	"item_aghanims_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

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

npc_dota_hero_legion_commander

"Ability1"		"legion_commander_overwhelming_odds"
"Ability2"		"legion_commander_press_the_attack"
"Ability3"		"legion_commander_moment_of_courage"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"legion_commander_duel"
"Ability10"		"special_bonus_strength_7"
"Ability11"		"special_bonus_mp_regen_150"
"Ability12"		"special_bonus_attack_speed_25"
"Ability13"		"special_bonus_unique_legion_commander_6"
"Ability14"		"special_bonus_movement_speed_30"
"Ability15"		"special_bonus_unique_legion_commander_3"
"Ability16"		"special_bonus_unique_legion_commander"
"Ability17"		"special_bonus_unique_legion_commander_5"

modifier_legion_commander_overwhelming_odds
modifier_legion_commander_press_the_attack
modifier_legion_commander_moment_of_courage
modifier_legion_commander_moment_of_courage_lifesteal
modifier_legion_commander_duel_damage_boost
modifier_legion_commander_duel


--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent2 = bot:GetAbilityByName( sTalentList[2] )
local talent5 = bot:GetAbilityByName( sTalentList[5] )

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget

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

	
	castRDesire, castRTarget = X.ConsiderR()
	if castRDesire > 0
	then

		--Fu.SetQueuePtToINT( bot, true )

		--释放强攻给自己 (7.41: abilities can now be used during Duel)
		if abilityW:IsTrained()
			and abilityW:IsFullyCastable()
			and bot:GetMana() > abilityW:GetManaCost() + abilityR:GetManaCost()
		then
			if talent5:IsTrained()
			then
				bot:ActionQueue_UseAbilityOnLocation( abilityW, bot:GetLocation() )
			else
				bot:ActionQueue_UseAbilityOnEntity( abilityW, bot )
			end
		end

		--释放刃甲
		local abilityBM = Fu.IsItemAvailable( "item_blade_mail" )
		if abilityBM ~= nil
			and abilityBM:IsFullyCastable()
			and bot:GetMana() > abilityBM:GetManaCost() + abilityR:GetManaCost()
		then
			bot:ActionQueue_UseAbility( abilityBM )
		end

		bot:Action_UseAbilityOnEntity( abilityR, castRTarget )
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

		if talent5:IsTrained()
		then
			bot:ActionQueue_UseAbilityOnLocation( abilityW, castWTarget:GetLocation() )
		else
			bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		end
		return
	end
	


end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = 600
	local nRadius = 600
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( 'damage' ) * 2
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	--击杀
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
		then
			hCastTarget = npcEnemy:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, 'Q-击杀'..Fu.Chat.GetNormName( npcEnemy )
		end
	end

	--消耗
	local nCanHurtEnemyAoE = bot:FindAoELocation( true, true, bot:GetLocation(), 10, 590, 0, 0 )
	if nCanHurtEnemyAoE.count >= 3
	then
		hCastTarget = nCanHurtEnemyAoE.targetloc
		return BOT_ACTION_DESIRE_HIGH, hCastTarget, 'Q-消耗'
	end


	--对线消耗或补刀
	if Fu.IsLaning( bot )
	then
		--对线消耗
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, 50, 450, 2 )
		if nAoeLoc ~= nil and nMP > 0.38
		then
			hCastTarget = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, 'Q-对线消耗'
		end
	end


	--团战
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, 49, 499, 2 )
		if nAoeLoc ~= nil
		then
			hCastTarget = nAoeLoc
			return BOT_ACTION_DESIRE_ABSOLUTE, hCastTarget, 'Q-团战'
		end
	end


	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange -80 )
		then
			if nSkillLV >= 2 or nMP > 0.68 or Fu.GetHP( botTarget ) < 0.38
			then
				hCastTarget = Fu.GetCastLocation( bot, botTarget, 10, 490 )
				if hCastTarget ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, 'Q-攻击'..Fu.Chat.GetNormName( botTarget )
				end
			end
		end
	end


	--撤退前加速
	if Fu.IsRetreating( bot ) 
		and not bot:HasModifier( 'modifier_legion_commander_overwhelming_odds' )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				--and bot:IsFacingLocation( npcEnemy:GetLocation(), 40 )
			then
				hCastTarget = npcEnemy:GetLocation()
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, 'Q-撤退'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--打钱
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		if Fu.IsValid( botTarget )
			and botTarget:GetTeam() == TEAM_NEUTRAL
			and Fu.IsInRange( bot, botTarget, 1000 )
			and ( botTarget:GetMagicResist() < 0.4 or nMP > 0.9 )
		then
			local nShouldHurtCount = nMP > 0.55 and 3 or 4
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), 40, 400, 0, 0 )
			if ( locationAoE.count >= nShouldHurtCount )
			then
				hCastTarget = locationAoE.targetloc
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, "Q-打钱"..locationAoE.count
			end
		end
	end


	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and nSkillLV >= 2 and DotaTime() > 6 * 60
		and #hAllyList <= 3 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( 1400, true )
		if #laneCreepList >= 4
			and Fu.IsValid( laneCreepList[1] )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then

			local locationAoEHurt = bot:FindAoELocation( true, false, bot:GetLocation(), 30, 400, 0, 0 )
			if locationAoEHurt.count >= 4 
			then
				hCastTarget = locationAoEHurt.targetloc
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, "Q-带线"..locationAoEHurt.count
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange()
	local nRadius = 400
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local hCastTarget = nil
	local sCastMotive = nil

	
	
	for _, npcAlly in pairs( hAllyList )
	do 
		if Fu.IsValidHero( npcAlly )
			and Fu.IsInRange( bot, npcAlly, nCastRange )
			and not npcAlly:HasModifier( 'modifier_legion_commander_press_the_attack' )
			and not npcAlly:IsMagicImmune()
			and not npcAlly:IsInvulnerable()
			and npcAlly:CanBeSeen()
		then
		
		
			--为加攻速
			if not npcAlly:IsBot()
				and npcAlly:GetLevel() >= 6
				and npcAlly:GetAttackTarget() ~= nil
				and npcAlly:GetMaxHealth() - npcAlly:GetHealth() >= 120
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-加攻速:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive	
			end
		
			--为被控制队友解状态
			if Fu.IsDisabled( npcAlly )
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-解状态:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive			
			end

			--为撤退中的队友加移速
			if Fu.IsRetreating( npcAlly )
				and Fu.IsRunning( npcAlly )
				and npcAlly:GetMaxHealth() - npcAlly:GetHealth() >= 300
				and npcAlly:WasRecentlyDamagedByAnyHero( 5.0 )
				and npcAlly:IsFacingLocation( GetAncient( GetTeam() ):GetLocation(), 30 )
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-加移速:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
			
			--为准备打架的队友辅助
			if Fu.IsGoingOnSomeone( npcAlly )
			then
				local allyTarget = Fu.GetProperTarget( npcAlly )
				if Fu.IsValidHero( allyTarget )
					and npcAlly:IsFacingLocation( allyTarget:GetLocation(), 20 )
					and Fu.IsInRange( npcAlly, allyTarget, npcAlly:GetAttackRange() + 100 )
				then
					hCastTarget = npcAlly
					sCastMotive = 'W-进攻辅助:'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
			
			--为残血队友buff
			if Fu.GetHP( npcAlly ) < 0.3
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-为队友回血:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive			
			end			
		end
	end


	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	
	local nDuration = abilityR:GetSpecialValueInt( 'duration' ) - 0.3
	local nDamage = bot:GetAttackDamage() * ( nDuration / bot:GetSecondsPerAttack() )
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( 350 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( 650 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	--激进的决斗
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and botTarget:CanBeSeen()
			and not botTarget:IsMagicImmune()
			and not botTarget:IsInvulnerable()
			and not Fu.IsSuspiciousIllusion( botTarget )
			and not Fu.HasForbiddenModifier( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 100 )
		then
			local attackDamage = botTarget:GetActualIncomingDamage( nDamage, nDamageType )
			
			--纠正估算错误
			if attackDamage > nDamage then attackDamage = nDamage * 0.6 end
			
			local allyDamage = X.GetAllyToTargetDamage( botTarget, nDuration ) 
			local totallyDamage = attackDamage * 0.8 + allyDamage * 1.2
			
			if totallyDamage > botTarget:GetHealth() + botTarget:GetHealthRegen() * nDuration
			then						
				hCastTarget = botTarget
				sCastMotive = 'R-激进的决斗:'..Fu.Chat.GetNormName( hCastTarget ).." 攻击:"..attackDamage.."队友:"..allyDamage
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive	
			end			
	
		end
	end
	
	
	
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do 
		
		--打断施法
		if npcEnemy:IsChanneling()
			and not npcEnemy:IsMagicImmune()
			and npcEnemy:IsBot()
		then
			hCastTarget = npcEnemy
			sCastMotive = 'R-打断'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_ABSOLUTE, hCastTarget, sCastMotive		
		end
		
		--保守的决斗
		if Fu.IsValidHero( npcEnemy )
			and npcEnemy:CanBeSeen()
			and not npcEnemy:IsMagicImmune()
			and not npcEnemy:IsInvulnerable()
			and not Fu.IsSuspiciousIllusion( npcEnemy )
			and not Fu.HasForbiddenModifier( npcEnemy )
		then
		
			local attackDamage = npcEnemy:GetActualIncomingDamage( nDamage, DAMAGE_TYPE_PHYSICAL )
			
			--纠正估算错误
			if attackDamage > nDamage then attackDamage = nDamage * 0.5 end
			
			local allyDamage = X.GetAllyToTargetDamage( npcEnemy, nDuration ) 
			local totallyDamage = attackDamage * 0.6 + allyDamage * 0.9
			
			if totallyDamage > npcEnemy:GetHealth()
			then
				local ememyPower = npcEnemy:GetEstimatedDamageToTarget( true, bot, 3.0, DAMAGE_TYPE_PHYSICAL )
				local botPower = bot:GetEstimatedDamageToTarget( true, npcEnemy, 3.0, DAMAGE_TYPE_PHYSICAL )
			
				if bot:GetHealth() * 1.1 / ememyPower > npcEnemy:GetHealth() / botPower
				then			
					hCastTarget = npcEnemy
					sCastMotive = 'R-保守的决斗:'..Fu.Chat.GetNormName( hCastTarget ).." 攻击:"..attackDamage.."队友:"..allyDamage
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive	
				end
			end
		
		end
		
	end
	
	

	return BOT_ACTION_DESIRE_NONE


end


function X.GetAllyToTargetDamage( npcEnemy, nDuration )

	local nTotalDamage = 0
	local nDamageType = DAMAGE_TYPE_PHYSICAL

	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local ally = GetTeamMember( i )
		if ally ~= nil
			and ally ~= bot
			and ally:IsAlive()
			and Fu.GetProperTarget( ally ) == npcEnemy
			and not Fu.IsDisabled( ally )
			and ally:IsFacingLocation( npcEnemy:GetLocation(), 25 )
			and GetUnitToUnitDistance( ally, npcEnemy ) <= ally:GetAttackRange() + 80
		then			
			nTotalDamage = nTotalDamage + ally:GetEstimatedDamageToTarget( true, npcEnemy, nDuration, nDamageType )
		end
	end

	return nTotalDamage

end


return X

