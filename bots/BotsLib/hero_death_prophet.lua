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
							['t20'] = {10, 0},
							['t15'] = {0, 10},
							['t10'] = {10, 0},
						},
						{--pos3
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {0, 10},
							['t10'] = {10, 0},
						}
}

local tAllAbilityBuildList = {
						{1,3,1,3,1,6,1,3,3,2,6,2,2,2,6},--pos2
						{1,3,3,1,3,6,3,2,1,1,6,2,2,2,6},--pos3
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


sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_circlet",

	"item_bottle",
	"item_magic_wand",
	"item_boots",
	"item_ring_of_basilius",
	"item_arcane_boots",
	"item_shivas_guard",--
	"item_cyclone",
	"item_crellas_crozier",--
	"item_bloodstone",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_kaya_and_sange",--
	"item_octarine_core",--
	"item_refresher",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
	"item_lotus_orb",
	"item_shivas_guard",--
	"item_cyclone",
	"item_aghanims_shard",
	"item_gungir",--
	"item_travel_boots",
	"item_assault",--
	"item_heart",--
	"item_moon_shard",
    "item_wind_waker",--
    "item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_circlet",

	"item_magic_wand",
	"item_boots",
	"item_ring_of_basilius",
	"item_arcane_boots",
	"item_guardian_greaves",--
	"item_shivas_guard",--
	"item_cyclone",
	"item_bloodstone",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_heavens_halberd", --
    "item_wind_waker",
	"item_refresher",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_circlet",

	"item_boots",
	"item_ring_of_basilius",
	"item_magic_wand",
	"item_arcane_boots",
	"item_pipe",--
	"item_shivas_guard",--
	"item_cyclone",
	"item_bloodstone",--
	"item_black_king_bar",--
	"item_aghanims_shard",
    "item_wind_waker",
	"item_refresher",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_ultimate_scepter",
	"item_magic_wand",

	"item_black_king_bar",
	"item_magic_wand",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_priest' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = true
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		local sUnitName = hMinionUnit:GetUnitName()
		if sUnitName ~= "npc_dota_death_prophet_torment"
			and sUnitName ~= "dota_death_prophet_exorcism_spirit"
		then
			Minion.IllusionThink( hMinionUnit )
		end
	end

end

--[[

"npc_dota_hero_death_prophet"

"Ability1"		"death_prophet_carrion_swarm"
"Ability2"		"death_prophet_silence"
"Ability3"		"death_prophet_spirit_siphon"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"death_prophet_exorcism"
"Ability10"		"special_bonus_attack_damage_40"
"Ability11"		"special_bonus_magic_resistance_15"
"Ability12"		"special_bonus_unique_death_prophet_3"
"Ability13"		"special_bonus_cast_range_175"
"Ability14"		"special_bonus_hp_500"
"Ability15"		"special_bonus_unique_death_prophet_2"
"Ability16"		"special_bonus_unique_death_prophet_4"
"Ability17"		"special_bonus_unique_death_prophet"

modifier_death_prophet_witchcraft
modifier_death_prophet_spirit_siphon_charge_counter
modifier_death_prophet_spirit_siphon
modifier_death_prophet_spirit_siphon_slow
modifier_death_prophet_exorcism



--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent4 = bot:GetAbilityByName( sTalentList[4] )


local castQDesire, castQLocation
local castWDesire, castWLocation
local castEDesire, castETarget
local castRDesire


local aetherRange = 0
local talentDamage = 0


function X.SkillsComplement()


	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	talentDamage = 0
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies

	castWDesire, castWLocation = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWLocation )
		return
	end

	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end

	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return
	end

	castQDesire, castQLocation = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQLocation )
		return
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange + 100
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nRadius = abilityQ:GetSpecialValueInt( "end_radius" )
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange - 50, true, BOT_MODE_NONE )
	local nTargetLocation = nil

	--击杀
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
		then
			nTargetLocation = npcEnemy:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-击杀'..Fu.Chat.GetNormName( npcEnemy )
		end
	end

	--消耗
	local nCanHurtEnemyAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius + 50, 0, 0 )
	if nCanHurtEnemyAoE.count >= 3 and bot:GetActiveMode() ~= BOT_MODE_RETREAT
	then
		nTargetLocation = nCanHurtEnemyAoE.targetloc
		return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-Aoe:'..( nCanHurtEnemyAoE.count )
	end


	--对线消耗或补刀
	if Fu.IsLaning( bot )
	then
		--对线消耗
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange - 80, nRadius, 2 )
		if nAoeLoc ~= nil and nMP > 0.58
		then
			nTargetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q对线消耗'
		end

		--对线补刀
		if #hAllyList == 1 and nMP > 0.38
		then
			local locationAoEKill = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 50, 0, nDamage )
			if locationAoEKill.count >= 3
			then
				nTargetLocation = locationAoEKill.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q对线补刀"..locationAoEKill.count
			end
		end
	end


	--团战
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius, 2 )
		if nAoeLoc ~= nil
		then
			nTargetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q团战'
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
				nTargetLocation = botTarget:GetExtrapolatedLocation( nCastPoint )
				if Fu.IsInLocRange( bot, nTargetLocation, nCastRange )
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q打架'..Fu.Chat.GetNormName( botTarget )
				end
			end
		end
	end


	--撤退时消耗
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 30 )
			then
				nTargetLocation = npcEnemy:GetLocation()
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q撤退:'..Fu.Chat.GetNormName( npcEnemy )
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
			and bot:IsFacingLocation( botTarget:GetLocation(), 45 )
			and ( botTarget:GetMagicResist() < 0.4 or nMP > 0.9 )
		then
			local nShouldHurtCount = nMP > 0.6 and 2 or 3
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
			if ( locationAoE.count >= nShouldHurtCount )
			then
				nTargetLocation = locationAoE.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q打钱"..locationAoE.count
			end
		end
	end


	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and nSkillLV >= 2 and DotaTime() > 8 * 60
		and #hAllyList <= 3 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 400, true )
		if #laneCreepList >= 3
			and Fu.IsValid( laneCreepList[1] )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			local locationAoEKill = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, nDamage )
			if locationAoEKill.count >= 2
	 			and #hAllyList == 1
			then
				nTargetLocation = locationAoEKill.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q带线1"..locationAoEKill.count
			end

			local locationAoEHurt = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 50, 0, 0 )
			if ( locationAoEHurt.count >= 3 and #laneCreepList >= 4 )
			then
				nTargetLocation = locationAoEHurt.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q带线2"..locationAoEHurt.count
			end
		end
	end


	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan( botTarget )
        and Fu.GetHP( botTarget ) > 0.15
		and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor( botTarget )
		and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	--通用消耗敌人或受到伤害时保护自己
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 15 and false --there be bug
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy ) 
				and Fu.IsInRange( bot, npcEnemy, nCastRange - 200 )
			then
				nTargetLocation = npcEnemy:GetLocation()
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q通用'
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange() + aetherRange
	local nRadius	 = abilityW:GetSpecialValueInt( 'radius' )
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nTargetLocation = nil

	for _, npcEnemy in pairs( hEnemyList )
	do
		if npcEnemy:IsChanneling()
			and not npcEnemy:HasModifier( 'modifier_teleporting' )
			and Fu.IsInRange( bot, npcEnemy, nCastRange + nRadius )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then
			nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "W-Check:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		--AOE
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius, 2 )
		if nAoeLoc ~= nil
		then
			nTargetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'W-Aoe'
		end

		--攻击
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + nRadius - 200 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and ( Fu.IsInRange( bot, botTarget, 700 ) or botTarget:IsFacingLocation( bot:GetLocation(), 40 ) )
			and not Fu.IsDisabled( botTarget )
		then
			nTargetLocation = Fu.GetCastLocation( bot, botTarget, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "W-Attack:"..Fu.Chat.GetNormName( botTarget )
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange() + aetherRange + 99
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and not botTarget:HasModifier( "modifier_death_prophet_spirit_siphon_slow" )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "E-Attack:"..Fu.Chat.GetNormName( botTarget )
		end
	end


	if Fu.IsInTeamFight( bot, 1200 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not npcEnemy:HasModifier( "modifier_death_prophet_spirit_siphon_slow" )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E-Battle:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not npcEnemy:HasModifier( "modifier_death_prophet_spirit_siphon_slow" )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderR()

	if not abilityR:IsFullyCastable()
		or bot:HasModifier( 'modifier_death_prophet_exorcism' )
	then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange()
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and ( Fu.IsInRange( bot, botTarget, 700 )
					or ( #hEnemyList >= 3 and Fu.IsInRange( bot, botTarget, 1200 ) ) )
			and Fu.CanCastOnMagicImmune( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, "R-Attack:"..Fu.Chat.GetNormName( botTarget )
		end
	end

	local nAllyCreepList = bot:GetNearbyLaneCreeps( 1000, false )
	if Fu.IsPushing( bot ) and #nAllyCreepList >= 1
	then
		if Fu.IsValidBuilding( botTarget )
			and Fu.IsInRange( bot, botTarget, 800 )
			and not botTarget:HasModifier( 'modifier_fountain_glyph' )
			and not botTarget:HasModifier( 'modifier_backdoor_protection' )
		then
			return BOT_ACTION_DESIRE_HIGH, "R-Push"
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


return X



