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
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{2,3,3,1,3,6,3,1,1,1,6,2,2,2,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
	"item_echo_sabre",
	"item_crimson_guard",--
	"item_ultimate_scepter",
	"item_heavens_halberd",--
	"item_assault",--
	"item_travel_boots",
	"item_aghanims_shard",
	"item_satanic",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_heart",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = {
	"item_bristleback_outfit",
	"item_bracer",
	"item_echo_sabre",
	"item_ultimate_scepter",
	"item_blink",
	"item_black_king_bar",--
	"item_harpoon",--
	"item_travel_boots",
	"item_aghanims_shard",
	"item_orchid",
	"item_bloodthorn",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_heart",--
	"item_overwhelming_blink",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_power_treads",
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

npc_dota_hero_slardar

"Ability1"		"slardar_sprint"
"Ability2"		"slardar_slithereen_crush"
"Ability3"		"slardar_bash"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"slardar_amplify_damage"
"Ability10"		"special_bonus_hp_regen_6"
"Ability11"		"special_bonus_attack_damage_20"
"Ability12"		"special_bonus_hp_275"
"Ability13"		"special_bonus_unique_slardar_2"
"Ability14"		"special_bonus_lifesteal_25"
"Ability15"		"special_bonus_night_vision_800"
"Ability16"		"special_bonus_unique_slardar_4"
"Ability17"		"special_bonus_unique_slardar_3"

modifier_slardar_sprint
modifier_slardar_sprint_river
modifier_slithereen_crush
modifier_slardar_bash_active
modifier_slardar_amplify_damage


--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent2 = bot:GetAbilityByName( sTalentList[2] )
local talent6 = bot:GetAbilityByName( sTalentList[6] )

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


	castWDesire, castWTarget = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityW )
		return
	end


	castRDesire, castRTarget = X.ConsiderR()
	if castRDesire > 0
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return
	end


	castQDesire, castQTarget = X.ConsiderQ()
	if castQDesire > 0
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityQ )
		return
	end

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

	
	--攻击敌人时
	if Fu.IsGoingOnSomeone( bot )
		and Fu.IsRunning( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, 1600 )
			and not Fu.IsInRange( bot, botTarget, 200 )
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-进攻:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--逃跑时
	if Fu.IsRetreating( bot ) 
		and Fu.IsRunning( bot ) 
		and bot:WasRecentlyDamagedByAnyHero( 5.0 )
		and #hEnemyList >= 1
	then
		hCastTarget = bot
		sCastMotive = 'Q-撤退了'
		return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive	
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetSpecialValueInt( 'crush_radius' )
	local nRadius = abilityW:GetSpecialValueInt( 'crush_radius' )
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange - 30 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange - 100 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	--击杀打断敌人
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and ( Fu.CanKillTarget( npcEnemy, nDamage, nDamageType )
					or npcEnemy:IsChanneling() )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'W-击杀打断'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	
	end
		
	
	--打架攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nRadius - 99 )
			and Fu.CanCastOnMagicImmune( botTarget )	
			and not Fu.IsDisabled( botTarget )
		then			
			hCastTarget = botTarget
			sCastMotive = 'W-攻击'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--团战AOE
	if Fu.IsInTeamFight( bot, 1000 )
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInBonusEnemyList )
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
			sCastMotive = 'W-团战AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
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
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	
	--带线AOE
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and #hAllyList <= 2
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange , true )
		if ( #laneCreepList >= 4 or ( #laneCreepList >= 3 and nMP > 0.82 ) )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			hCastTarget = creep
			sCastMotive = 'W-带线AOE'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	
	--打野AOE
	if Fu.IsFarming( bot )
		and DotaTime() > 6 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius )

		if #creepList >= 3
			and Fu.IsValid( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'W-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	    end
	end
	
	
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 400
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
			and not Fu.IsDisabled( npcTarget )
			and not npcTarget:IsDisarmed()
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			hCastTarget = botTarget
			sCastMotive = 'W-打肉山'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
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
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and not botTarget:HasModifier( 'modifier_slardar_amplify_damage' )
		then			
			hCastTarget = botTarget
			sCastMotive = 'R-攻击:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--团战中对护甲最低的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcWeakestEnemy = nil
		local npcWeakestEnemyHealth = 100000

		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_slardar_amplify_damage' )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				local npcEnemyHealth = npcEnemy:GetArmor()
				if ( npcEnemyHealth < npcWeakestEnemyHealth )
				then
					npcWeakestEnemyHealth = npcEnemyHealth
					npcWeakestEnemy = npcEnemy
				end
			end
		end

		if npcWeakestEnemy ~= nil
		then
			hCastTarget = npcWeakestEnemy
			sCastMotive = 'R-团战'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--打野时
	if Fu.IsFarming( bot )
		and nSkillLV >= 2
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then		

		local targetCreep = bot:GetAttackTarget()
		if Fu.IsValid( targetCreep )
			and Fu.IsInRange( bot, targetCreep, nCastRange )
			and not targetCreep:HasModifier( 'modifier_slardar_amplify_damage' )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 3, DAMAGE_TYPE_PHYSICAL )
		then
			hCastTarget = targetCreep
			sCastMotive = 'R-打野'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	    end
	end
	
	
	--打肉 
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and not botTarget:HasModifier( 'modifier_slardar_amplify_damage' )
		then
			hCastTarget = botTarget
			sCastMotive = 'R-肉山'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end
	
	
	--通用标记敌人
	if nLV >= 12
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 3 )
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_slardar_amplify_damage' )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'R-标记'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


return X

