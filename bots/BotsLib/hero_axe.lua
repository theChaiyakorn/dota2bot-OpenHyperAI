local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
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
	{2,3,1,3,3,6,3,2,2,2,6,1,1,1,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_sven_outfit",
	"item_blade_mail",--
	"item_blink",
	"item_aghanims_shard",
	"item_black_king_bar",--
	"item_ultimate_scepter",
	"item_travel_boots",
	"item_overwhelming_blink",--
	"item_abyssal_blade",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_heart",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {

	"item_tank_outfit",
	"item_crimson_guard",--
	"item_blade_mail",--
	"item_blink",
	"item_aghanims_shard",
	"item_heavens_halberd",--
	"item_travel_boots",
	"item_assault",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_heart",--
	"item_overwhelming_blink",--
	"item_travel_boots_2",--

}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']


X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_travel_boots",
	"item_quelling_blade",

	"item_abyssal_blade",
	"item_magic_wand",
}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_heavens_halberd", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_axe

"Ability1"		"axe_berserkers_call"
"Ability2"		"axe_battle_hunger"
"Ability3"		"axe_counter_helix"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"axe_culling_blade"
"Ability10"		"special_bonus_strength_8"
"Ability11"		"special_bonus_movement_speed_20"
"Ability12"		"special_bonus_mp_regen_2"
"Ability13"		"special_bonus_attack_speed_35"
"Ability14"		"special_bonus_hp_regen_20"
"Ability15"		"special_bonus_unique_axe_3"
"Ability16"		"special_bonus_unique_axe_2"
"Ability17"		"special_bonus_unique_axe"

modifier_axe_berserkers_call
modifier_axe_berserkers_call_armor
modifier_axe_battle_hunger
modifier_axe_battle_hunger_self
modifier_axe_counter_helix
modifier_axe_culling_blade_boost


--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent7 = bot:GetAbilityByName( sTalentList[7] )
local talent5 = bot:GetAbilityByName( sTalentList[5] )

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget

local aetherRange = 0


local bAttacking
function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	bAttacking = Fu.IsAttacking(bot)

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

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end

	

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	
	local nRadius = abilityQ:GetSpecialValueInt( 'radius' )
	if talent7:IsTrained() then nRadius = nRadius + talent7:GetSpecialValueInt( 'value' ) end
	
	local nCastRange = nRadius
	
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nRadius - 50 )
--	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nRadius + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	--打断敌人施法
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do 
		if npcEnemy:IsChanneling()
			and not npcEnemy:IsMagicImmune()
		then
			hCastTarget = npcEnemy
			sCastMotive = 'Q-打断'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive		
		end
	end
	
	
	--攻击敌人时
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nRadius - 90 )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and not Fu.IsDisabled( botTarget )
		then			
			hCastTarget = botTarget
			sCastMotive = 'Q-先手'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	


	--带线时嘲讽小兵攻击自己
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and bot:GetAttackTarget() ~= nil
		and DotaTime() > 6 * 60
		and #hAllyList <= 2 
		and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nRadius - 50, true )
		if #laneCreepList >= 4
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			hCastTarget = creep
			sCastMotive = 'Q-带线'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if  Fu.IsRoshan(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:IsDisarmed()
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	--farming: taunt 3+ neutral creeps when healthy
	if Fu.IsFarming( bot )
		and #hEnemyList == 0
		and nHP > 0.5
		and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nRadius - 50 )
		if #nNeutralCreeps >= 3
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	--Roshan: taunt Roshan to absorb hits
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and Fu.GetManaAfter( nManaCost ) > 0.3
		and nHP > 0.3
	then
		if Fu.IsRoshan( botTarget )
			and not Fu.IsDisabled( botTarget )
			and Fu.IsInRange( bot, botTarget, nRadius )
			and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange() + aetherRange
	local nRadius = 600
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	
	local nDuration = abilityW:GetSpecialValueInt( 'duration' )
	local nDamage = abilityW:GetSpecialValueInt( 'damage_per_second' ) * nDuration
	
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--击杀低血量敌人
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage , nDuration )
			and not npcEnemy:HasModifier( 'modifier_axe_battle_hunger_self' )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'W-击杀'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	
	end
	
	
	--攻击敌人时
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and not botTarget:HasModifier( 'modifier_axe_battle_hunger_self' )
		then			
			hCastTarget = botTarget
			sCastMotive = 'W-先手'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--团战中对血量最低的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcWeakestEnemy = nil
		local npcWeakestEnemyHealth = 100000

		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_axe_battle_hunger_self' )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
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
		then
			hCastTarget = npcWeakestEnemy
			sCastMotive = 'W-团战'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--对线期间消耗
	if Fu.IsLaning( bot ) and nMP > 0.5
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do 
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and npcEnemy:GetAttackTarget() == nil
				and not npcEnemy:HasModifier( 'modifier_axe_battle_hunger_self' )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-对线消耗:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		
		end	
	end
	
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_axe_battle_hunger_self' )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-撤退:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	--打野时
	if Fu.IsFarming( bot )
		and nSkillLV >= 2
		and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		local neutralCreepList = bot:GetNearbyNeutralCreeps( nCastRange + 100 )

		local targetCreep = Fu.GetMostHpUnit( neutralCreepList )

		if Fu.IsValid( targetCreep )
			and not Fu.IsRoshan( targetCreep )
			and not targetCreep:HasModifier( 'modifier_axe_battle_hunger_self' )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 2.88, DAMAGE_TYPE_PHYSICAL )
		then
			hCastTarget = targetCreep
			sCastMotive = 'W-打野'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	    end
	end


	if Fu.IsDoingRoshan(bot)
	then
		if  Fu.IsRoshan(botTarget)
        and not Fu.IsDisabled(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not botTarget:HasModifier('modifier_axe_battle_hunger_self')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if  Fu.IsTormentor(botTarget)
        and not Fu.IsDisabled(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not botTarget:HasModifier('modifier_axe_battle_hunger_self')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
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
	
	local nKillDamage = 150 + 100 * nSkillLV
	if talent5:IsTrained() then nKillDamage = nKillDamage + talent5:GetSpecialValueInt( 'value' ) end
	
	local nDamageType = DAMAGE_TYPE_PURE
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--直接斩杀血量低于斩杀线的敌人
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do 
		if Fu.IsValidHero( npcEnemy )
			and npcEnemy:CanBeSeen()
			and npcEnemy:GetHealth() + npcEnemy:GetHealthRegen() * 0.8 < nKillDamage
			and not Fu.IsHaveAegis( npcEnemy )
			and not npcEnemy:IsInvulnerable()
			and not npcEnemy:IsMagicImmune() --V BUG
			and not X.HasSpecialModifier( npcEnemy )
			and not X.IsKillBotAntiMage( npcEnemy )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'R-击杀'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive			
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.HasSpecialModifier( npcEnemy )

	if npcEnemy:HasModifier( 'modifier_winter_wyvern_winters_curse' )
		or npcEnemy:HasModifier( 'modifier_winter_wyvern_winters_curse_aura' )
		or npcEnemy:HasModifier( 'modifier_antimage_spell_shield' )
		or npcEnemy:HasModifier( 'modifier_item_lotus_orb_active' )
		or npcEnemy:HasModifier( 'modifier_item_aeon_disk_buff' )
		or npcEnemy:HasModifier( 'modifier_item_sphere_target' )
		or npcEnemy:HasModifier( 'modifier_illusion' )
	then
		return true
	else
		return false	
	end

end


function X.IsKillBotAntiMage( npcEnemy )

	if not npcEnemy:IsBot() 
		or npcEnemy:GetUnitName() ~= 'npc_dota_hero_antimage'
		or npcEnemy:IsStunned()
		or npcEnemy:IsHexed()
		or npcEnemy:IsNightmared()
		or npcEnemy:IsChanneling()
		or Fu.IsTaunted( npcEnemy )
	then
		return false
	end
	
	return true

end


return X
