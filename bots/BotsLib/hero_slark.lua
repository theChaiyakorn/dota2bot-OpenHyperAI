local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10}, -- 7.41a: Essence Shift agi/stack swapped from L20 to L25
						['t20'] = {10, 0}, -- 7.41a: Essence Shift duration swapped from L25 to L20
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,2,3,1,1,6,1,4,2,2,6,2,4,4,6},--pos1: Q>W>E early, Depth Shroud from 8
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	
	"item_melee_carry_outfit",
--	"item_wraith_band",
	"item_diffusal_blade",
	"item_yasha",
	"item_broadsword",
	"item_blitz_knuckles",
	"item_invis_sword",
	"item_sange_and_yasha",--
	"item_aghanims_shard",
	"item_black_king_bar",--
	"item_travel_boots",
	"item_abyssal_blade",--
	"item_silver_edge",--
    "item_disperser",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_butterfly",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_slippers",
	"item_circlet",

	"item_magic_wand",
	"item_wraith_band",
	"item_power_treads",
	"item_diffusal_blade",
	"item_echo_sabre",
	"item_ultimate_scepter",
	"item_aghanims_shard",
	"item_black_king_bar",--
	"item_skadi",--
	"item_basher",
	"item_disperser",--
	"item_abyssal_blade",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_orchid",
	"item_bloodthorn",--
	"item_nullifier",--
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_2']

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
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_slark


"Ability1"		"slark_dark_pact"
"Ability2"		"slark_pounce"
"Ability3"		"slark_essence_shift"
"Ability4"		"slark_depth_shroud"
"Ability5"		"generic_hidden"
"Ability6"		"slark_shadow_dance"
"Ability10"		"special_bonus_strength_9"
"Ability11"		"special_bonus_agility_6"
"Ability12"		"special_bonus_attack_speed_20"
"Ability13"		"special_bonus_lifesteal_15"
"Ability14"		"special_bonus_unique_slark_2"
"Ability15"		"special_bonus_unique_slark"
"Ability16"		"special_bonus_unique_slark_3"
"Ability17"		"special_bonus_unique_slark_4"


modifier_slark_dark_pact
modifier_slark_dark_pact_pulses
modifier_slark_pounce
modifier_slark_pounce_leash
modifier_slark_essence_shift
modifier_slark_essence_shift_debuff_counter
modifier_slark_essence_shift_debuff
modifier_slark_essence_shift_buff
modifier_slark_essence_shift_permanent_buff
modifier_slark_essence_shift_permanent_debuff
modifier_slark_shadow_dance_aura
modifier_slark_shadow_dance_passive
modifier_slark_shadow_dance_passive_regen
modifier_slark_shadow_dance
modifier_slark_shadow_dance_visual


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'slark')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'slark')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'slark')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'slark')
local abilityAS = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'slark')
local talent2 = SafeAbility(bot:GetAbilityByName(sTalentList[2]), 'sTalentList[2]', 'slark')
local talent6 = SafeAbility(bot:GetAbilityByName(sTalentList[6]), 'sTalentList[6]', 'slark')
local SaltwaterShiv = SafeAbility(bot:GetAbilityByName('slark_saltwater_shiv'), 'slark_saltwater_shiv', 'slark')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget
local castASDesire, castASTarget
local SaltwaterShivDesire, SaltwaterShivTarget

local aetherRange = 0


function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies

	castQDesire = X.ConsiderQ()
	if castQDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityQ )
		return
	end

	castWDesire = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityW )
		return
	end

	SaltwaterShivDesire, SaltwaterShivTarget = X.ConsiderSaltwaterShiv()
	if SaltwaterShivDesire > 0 then
		bot:Action_UseAbilityOnEntity(SaltwaterShiv, SaltwaterShivTarget)
		return
	end

	castASDesire, castASTarget = X.ConsiderAS()
	if castASDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityAS, castASTarget )
		return
	end

	castRDesire = X.ConsiderR()
	if castRDesire > 0
	then

--		Fu.SetQueuePtToINT( bot, true )

		bot:Action_UseAbility( abilityR )
		return
	end

end

function X.ConsiderSaltwaterShiv()
	if not Fu.CanCastAbility(SaltwaterShiv) then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = SaltwaterShiv:GetCastRange()

	-- Attack target
	if Fu.IsGoingOnSomeone(bot) or Fu.IsInTeamFight(bot, 1200) then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.HasForbiddenModifier(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	-- Retreat: slow the closest chaser
	if Fu.IsRetreating(bot) and nHP < 0.6 then
		local chasers = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE)
		for _, enemy in pairs(chasers) do
			if Fu.IsValidHero(enemy) and Fu.CanBeAttacked(enemy)
			and enemy:IsFacingLocation(bot:GetLocation(), 30)
			then
				return BOT_ACTION_DESIRE_HIGH, enemy
			end
		end
	end

	-- Roshan/Tormentor
	if (Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot))
	and Fu.IsValid(botTarget) and Fu.IsInRange(bot, botTarget, nCastRange)
	then
		return BOT_ACTION_DESIRE_HIGH, botTarget
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange()
	local nRadius = abilityQ:GetSpecialValueInt( 'radius' )
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = 0
	local nDelay = abilityQ:GetSpecialValueInt( 'delay' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nRadius )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( 800 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	local vCastLocation = bot:GetExtrapolatedLocation( nDelay )
	
	
	--团战AOE
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do 
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnMagicImmune( npcEnemy )
			then
				local enemyLocation = npcEnemy:GetExtrapolatedLocation( nDelay )
				if Fu.GetLocationToLocationDistance( vCastLocation, enemyLocation ) < nRadius - 30
				then
					nAoeCount = nAoeCount + 1
				end
			end
		end

		if nAoeCount >= 2
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-团战AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	--攻击时
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( bot, botTarget, 400 )
		then
			local enemyLocation = botTarget:GetExtrapolatedLocation( nDelay )
			
			if Fu.GetLocationToLocationDistance( vCastLocation, enemyLocation ) < nRadius - 50
			then
				hCastTarget = botTarget
				sCastMotive = 'Q-攻击:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, sCastMotive			
			end
		end
	end
	
	
	
	--逃跑时移除状态
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnMagicImmune( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 ) 
						or bot:GetCurrentMovementSpeed() < 200 
						or bot:IsRooted() )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'Q-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, sCastMotive
			end
		end
	end
	
	
	--带线时 (also use Q to farm lane creeps more aggressively)
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nRadius + 50 , true )
		if ( #laneCreepList >= 3 or ( #laneCreepList >= 2 and nMP > 0.7 ) )
			and Fu.IsValid(laneCreepList[1])
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			sCastMotive = 'Q-带线AOE'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	--打野时
	if Fu.IsFarming( bot )
		and DotaTime() > 6 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius + 300 )

		if (#creepList >= 3 or (#creepList >= 2 and Fu.IsValid(creepList[1]) and creepList[1]:IsAncientCreep()))
			and Fu.IsValid( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
	    end
	end

	-- Self-dispel when debuffed (Disarmed, Rooted, Blinded)
	if bot:IsDisarmed() or bot:IsRooted() or bot:IsBlind() then
		return BOT_ACTION_DESIRE_HIGH, 'Q-self-dispel'
	end

	-- Roshan/Tormentor: use Q for extra damage
	if (Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot))
		and Fu.IsAttacking(bot) and Fu.IsAllowedToSpam(bot, nManaCost)
	then
		return BOT_ACTION_DESIRE_HIGH, 'Q-roshan/tormentor'
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable() or bot:IsRooted() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetSpecialValueInt( 'pounce_distance' )
	local nRadius = nCastRange
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil


	--攻击没被控制的敌人时
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nRadius - 80 )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:HasModifier('modifier_slark_pounce_leash')
			and bot:IsFacingLocation( botTarget:GetLocation(), 10 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'W-控制:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	
	--残血逃跑
	if Fu.IsRetreating( bot )
		and Fu.IsRunning( bot )
		and ( nSkillLV >= 2 or nHP < 0.7 )
	then
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 ) or #nInBonusEnemyList >= 3 )
			then
				local neastEnemyHero = nInBonusEnemyList[1]
				if bot:IsFacingLocation( GetAncient(GetTeam()):GetLocation(), 20 )
					and not Fu.IsInRange( bot, neastEnemyHero, 100 )
				then
					hCastTarget = npcEnemy
					sCastMotive = 'W-逃离:'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, sCastMotive
				end
			end
		end
	end
	
	
	--被卡地形时
	if Fu.IsStuck( bot )
	then
		hCastTarget = bot
		sCastMotive = 'W-卡住了'..Fu.Chat.GetNormName( hCastTarget )
		return BOT_ACTION_DESIRE_HIGH, sCastMotive
	end

	-- Mobility: pounce toward destination when no enemies nearby and far from target
	if #nInRangeEnemyList == 0 and nSkillLV >= 2 then
		local mode = bot:GetActiveMode()
		if (mode == BOT_MODE_PUSH_TOWER_TOP or mode == BOT_MODE_PUSH_TOWER_MID or mode == BOT_MODE_PUSH_TOWER_BOT
			or mode == BOT_MODE_DEFEND_TOWER_TOP or mode == BOT_MODE_DEFEND_TOWER_MID or mode == BOT_MODE_DEFEND_TOWER_BOT
			or mode == BOT_MODE_ROSHAN or mode == BOT_MODE_RUNE)
			and bot:GetCurrentMovementSpeed() > 0
			and bot:GetMovementDirectionStability() > 0.9
		then
			return BOT_ACTION_DESIRE_LOW, 'W-mobility'
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderAS()

	if not abilityAS:IsTrained()
		or not abilityAS:IsFullyCastable()
		or bot:HasModifier("modifier_slark_shadow_dance")
		or bot:HasModifier("modifier_slark_depth_shroud")
	then return 0 end

	local nCastRange = abilityAS:GetCastRange() + aetherRange
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList(600)
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList(800)

	-- Protect low-HP allies (primary use case)
	for _, npcAlly in pairs(hAllyList) do
		if Fu.IsValidHero(npcAlly) and not npcAlly:IsIllusion()
		and Fu.GetHP(npcAlly) < 0.5
		and Fu.IsInRange(bot, npcAlly, nCastRange)
		and npcAlly:WasRecentlyDamagedByAnyHero(2.0)
		and not npcAlly:HasModifier("modifier_slark_depth_shroud")
		then
			-- Ally is disabled, low HP and being attacked, or stun incoming
			if Fu.IsDisabled(npcAlly)
			or Fu.GetHP(npcAlly) < 0.3
			or Fu.IsStunProjectileIncoming(npcAlly, 1000)
			then
				return BOT_ACTION_DESIRE_HIGH, npcAlly:GetLocation(), 'AS-protect-'..Fu.Chat.GetNormName(npcAlly)
			end
		end
	end

	-- Self-use when fighting and taking damage
	if Fu.IsGoingOnSomeone(bot) and nHP < 0.7 then
		if Fu.IsValidHero(botTarget)
			and Fu.IsInRange(botTarget, bot, 300)
			and bot:GetAttackTarget() == botTarget
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation(), 'AS-fight'
		end
	end

	-- Self-use when retreating
	if Fu.IsRetreating(bot) and nHP < 0.6
		and bot:WasRecentlyDamagedByAnyHero(1.5)
	then
		for _, npcEnemy in pairs(nInBonusEnemyList) do
			if Fu.IsValid(npcEnemy) and npcEnemy:GetAttackTarget() == bot then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation(), 'AS-retreat'
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end


function X.ConsiderR()


	if not abilityR:IsFullyCastable() or nHP > 0.8 or Fu.IsRealInvisible(bot) then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( 600 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( 1000 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	--攻击多名敌人时
	if Fu.IsGoingOnSomeone( bot )
	then
		if nHP < 0.76
			and Fu.IsValidHero( botTarget )
			and Fu.CanCastOnMagicImmune( botTarget )
			and Fu.IsInRange( bot, botTarget, 300 )
			and ( #nInBonusEnemyList >= 2 or nHP < 0.55 )
		then
			hCastTarget = botTarget
			sCastMotive = 'R-攻击:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive		
		end	
	end
	
	
	
	
	--残血逃跑躲技能
	if Fu.IsRetreating( bot )
		and nHP < 0.6 and bot:WasRecentlyDamagedByAnyHero( 5.0 ) 
		and ( X.IsEnemyCastAbility() or nHP < 0.5 or Fu.IsStunProjectileIncoming( bot, 800 ) )
		and #nInBonusEnemyList >= 1
	then		
		hCastTarget = bot
		sCastMotive = 'R-跑路:'..Fu.Chat.GetNormName( hCastTarget )
		return BOT_ACTION_DESIRE_HIGH, sCastMotive		
	end
	

	return BOT_ACTION_DESIRE_NONE


end


local sIgnoreAbilityIndex = {

	["antimage_blink"] = true,
	["arc_warden_magnetic_field"] = true,
	["arc_warden_spark_wraith"] = true,
	["arc_warden_tempest_double"] = true,
	["chaos_knight_phantasm"] = true,
	["clinkz_burning_army"] = true,
	["death_prophet_exorcism"] = true,
	["dragon_knight_elder_dragon_form"] = true,
	["juggernaut_healing_ward"] = true,
	["necrolyte_death_pulse"] = true,
	["necrolyte_sadist"] = true,
	["omniknight_guardian_angel"] = true,
	["phantom_assassin_blur"] = true,
	["pugna_nether_ward"] = true,
	["skeleton_king_mortal_strike"] = true,
	["sven_warcry"] = true,
	["sven_gods_strength"] = true,
	["templar_assassin_refraction"] = true,
	["templar_assassin_psionic_trap"] = true,
	["windrunner_windrun"] = true,
	["witch_doctor_voodoo_restoration"] = true,

}


function X.IsEnemyCastAbility()

	local enemyList = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE )

	for _, npcEnemy in pairs( enemyList )
	do
		if npcEnemy ~= nil and npcEnemy:IsAlive()
			and ( npcEnemy:IsCastingAbility() or npcEnemy:IsUsingAbility() )
			and npcEnemy:IsFacingLocation( bot:GetLocation(), 30 )
		then
			local nAbility = npcEnemy:GetCurrentActiveAbility()
			if nAbility ~= nil
			then
				local nAbilityBehavior = nAbility:GetBehavior()
				local sAbilityName = nAbility:GetName()
				if nAbilityBehavior ~= ABILITY_BEHAVIOR_UNIT_TARGET
					and ( npcEnemy:IsBot() or npcEnemy:GetLevel() >= 5 )
					and sIgnoreAbilityIndex[sAbilityName] ~= true 
				then
					return true
				end

				if nAbilityBehavior == ABILITY_BEHAVIOR_UNIT_TARGET
					and not npcEnemy:IsBot()
					and npcEnemy:GetLevel() >= 6
					and not Fu.IsAllyUnitSpell( sAbilityName )
					and ( not Fu.IsProjectileUnitSpell( sAbilityName ) or Fu.IsInRange( bot, npcEnemy, 400 ) )
				then
					return true
				end
			end
		end
	end

	return false

end


return X
