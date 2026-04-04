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
						{1,3,3,2,3,6,3,2,2,2,6,1,1,1,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_crystal_maiden_outfit",
--	"item_glimmer_cape",
    "item_kaya",
    "item_dagon_2",
	"item_rod_of_atos",
	"item_glimmer_cape",
	"item_kaya_and_sange",--
	"item_force_staff",
	"item_dagon_5",--
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_shivas_guard",--
	-- "item_sheepstick",--
	"item_gungir",--
	"item_moon_shard",
	"item_ultimate_scepter",
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	"item_priest_outfit",
	"item_mekansm",
	"item_glimmer_cape",
	"item_aghanims_shard",
	"item_guardian_greaves",
	"item_spirit_vessel",
--	"item_wraith_pact",
	"item_ultimate_scepter",
	"item_shivas_guard",
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_sheepstick",
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_pipe",
    "item_ultimate_scepter",
	"item_cyclone",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_sheepstick",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

	"item_shivas_guard",--
	"item_glimmer_cape",--
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = true
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_oracle

"Ability1"		"oracle_fortunes_end"
"Ability2"		"oracle_fates_edict"
"Ability3"		"oracle_purifying_flames"
"Ability4"		"oracle_rain_of_destiny"
"Ability5"		"generic_hidden"
"Ability6"		"oracle_false_promise"
"Ability10"		"special_bonus_unique_oracle_2"
"Ability11"		"special_bonus_intelligence_12"
"Ability12"		"special_bonus_unique_oracle_9"
"Ability13"		"special_bonus_unique_oracle_5"
"Ability14"		"special_bonus_unique_oracle_6"
"Ability15"		"special_bonus_unique_oracle_8"
"Ability16"		"special_bonus_unique_oracle_7"
"Ability17"		"special_bonus_unique_oracle"

modifier_oracle_fortunes_end_channel_target
modifier_oracle_fortunes_end_purge
modifier_oracle_fates_edict
modifier_oracle_purifying_flames
modifier_oracle_false_promise_timer
modifier_oracle_false_promise_invis
modifier_oracle_false_promise

--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent3 = bot:GetAbilityByName( sTalentList[3] )
local abilityD = bot:GetAbilityByName( sAbilityList[4] )

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

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return

	end

	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
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

		if abilityE:IsFullyCastable()
		then
			bot:ActionQueue_UseAbilityOnEntity( abilityE, castQTarget )
		end

		return
	end

	castDDesire, castDTarget = X.ConsiderD()
	if ( castDDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityD, castDTarget )
		return
	end

end




function X.ConsiderD()


	if not abilityD:IsTrained()	or not abilityD:IsFullyCastable() then return 0 end

	local nSkillLV = abilityD:GetLevel()
	local nCastRange = 650 + aetherRange
	local nCastPoint = abilityD:GetCastPoint()
	local nManaCost = abilityD:GetManaCost()
	local nDamage = abilityD:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nRadius = 650


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and ( botTarget:GetAttackTarget() ~= nil or bot:GetAttackTarget() ~= nil )
		then			
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), "D-Attack"..Fu.Chat.GetNormName( botTarget )
		end
	end
	

	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nRadius = 300
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "Q-Attack"..Fu.Chat.GetNormName( botTarget )
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
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	if Fu.IsInTeamFight( bot, 900 ) and #hEnemyList >= 3
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, npcEnemy in pairs( nInRangeEnemyList )
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
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, "W-Battle"..Fu.Chat.GetNormName( npcMostDangerousEnemy )
		end

	end

	--撤退时缴械攻击自己的( 远程 )敌人


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsAttacking( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "W-Attack"..Fu.Chat.GetNormName( botTarget )
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange() + aetherRange
	
	if nCastRange >= 1500 then nCastRange = 1500 end
	
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetSpecialValueInt( 'damage' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )

	--击杀
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E-击杀"..Fu.Chat.GetNormName( npcEnemy )
		end
	end

	--治疗队友
	for _, npcAlly in pairs( hAllyList )
	do
		if Fu.IsValidHero( npcAlly )
			and Fu.IsInRange( bot, npcAlly, nCastRange )
			and Fu.CanCastOnNonMagicImmune( npcAlly )
		then
			if npcAlly:GetMagicResist() > 0.42
				and Fu.GetHP( npcAlly ) < 0.8
				and ( #hEnemyList == 0 or npcAlly:GetHealth() > 999 )
				and Fu.GetUniqueModifierCount( bot, "modifier_oracle_purifying_flames" ) < 3
			then
				return BOT_ACTION_DESIRE_HIGH, npcAlly, "E-治疗"..Fu.Chat.GetNormName( npcAlly )
			end
		end

		if npcAlly:HasModifier( 'modifier_oracle_false_promise_timer' )
			and Fu.GetModifierTime( npcAlly, 'modifier_oracle_false_promise_timer' ) > 3.8
			and Fu.IsInRange( bot, npcAlly, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcAlly, "E-支援抢救"..Fu.Chat.GetNormName( npcAlly )
		end


	end


	--攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 50 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and botTarget:GetMagicResist() < 0.6
		then
			local nProjectList = botTarget:GetIncomingTrackingProjectiles()
			for _, p in pairs( nProjectList )
			do
				if not p.is_attack
					and p.ability ~= nil
					and p.ability:GetName() == "oracle_fortunes_end"
					and GetUnitToLocationDistance( botTarget, p.location ) > 330
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget, "E-弹道前进攻"..Fu.Chat.GetNormName( botTarget )
				end
			end

			if Fu.WillMagicKillTarget( bot, botTarget, nDamage * 1.6, nCastPoint )
			then
				local nNearTargetAllyList = Fu.GetAlliesNearLoc( botTarget:GetLocation(), 550 )
				if #nNearTargetAllyList >= 3
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget, "E-击杀前进攻"..Fu.Chat.GetNormName( botTarget )
				end
			end

		end
	end


	--对线补刀


	--推进
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and #hAllyList <= 2 and nSkillLV >= 3 and Fu.IsAllowedToSpam( bot, 30 )
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 350, true )
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( 'modifier_fountain_glyph' )
				and creep:GetHealth() > nDamage * 0.6
				and not Fu.IsOtherAllysTarget( creep )
			then
				if Fu.IsKeyWordUnit( 'ranged', creep )
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, "E-补刀远程兵"
				end

				if bot:GetMana() > abilityR:GetManaCost() * 2 and nSkillLV >= 4
					and Fu.IsKeyWordUnit( 'melee', creep )
					and creep:GetHealth() > nDamage * 0.7
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, "E-补刀近战兵"
				end

			end

		end

		if #hAllyList <= 1
		then
			local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 150 )
			for _, creep in pairs( nCreeps )
			do
				if Fu.IsValid( creep )
					and creep:GetHealth() > nDamage * 0.45
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastRange )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, "E-补刀野怪"
				end
			end
		end

	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange() + aetherRange
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )


	for _, ally in pairs( hAllyList )
	do
		if Fu.IsInRange( bot, ally, nCastRange + 50 )
			and ally:WasRecentlyDamagedByAnyHero( 2.0 )
			and Fu.GetHP( ally ) < 0.55
		then
			if Fu.IsRetreating( ally )
				and ( ally ~= bot or nHP < 0.25 )
			then
				return BOT_ACTION_DESIRE_HIGH, ally, "R-protect"..Fu.Chat.GetNormName( ally )
			end

			if Fu.IsGoingOnSomeone( ally ) and Fu.GetHP( ally ) < 0.3
			then
				local allyTarget = Fu.GetProperTarget( ally )
				if Fu.IsValidHero( allyTarget )
					and Fu.IsInRange( ally, allyTarget, 600 )
				then
					return BOT_ACTION_DESIRE_HIGH, ally, "R-support"..Fu.Chat.GetNormName( ally )
				end
			end
			
			if not ally:IsBot()
				and Fu.GetHP( ally ) <= 0.6
				and ally:GetAttackTarget() ~= nil
				and ally:GetAttackTarget():IsHero()
				and ally:WasRecentlyDamagedByAnyHero( 2.0 )
				and #hEnemyList >= 2
				and ( Fu.IsGoingOnSomeone( bot ) or Fu.IsGoingOnSomeone( ally ) )
			then			
				return BOT_ACTION_DESIRE_HIGH, ally, "R-ally"..Fu.Chat.GetNormName( ally )
			end
				
			
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


return X




