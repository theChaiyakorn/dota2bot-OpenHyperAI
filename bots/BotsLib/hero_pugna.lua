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
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,2,2,2,3,6,3,3,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_enchanted_mango",
	"item_blood_grenade",

	"item_magic_wand",
	"item_boots",
	"item_arcane_boots",
	"item_essence_distiller",--
	"item_glimmer_cape",--
	"item_aether_lens",--
	"item_aghanims_shard",
	"item_force_staff",--
	"item_guardian_greaves",--
	"item_cyclone",
	"item_moon_shard",
	"item_sheepstick",
	"item_wind_waker",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_enchanted_mango",
	"item_blood_grenade",

	"item_magic_wand",
	"item_boots",
	"item_tranquil_boots",
	"item_glimmer_cape",--
	"item_pipe",--
	"item_aether_lens",--
	"item_aghanims_shard",
	"item_force_staff",--
	"item_boots_of_bearing",--
	"item_cyclone",
    -- "item_lotus_orb",--
	"item_moon_shard",
	"item_sheepstick",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_boots",
    "item_magic_wand",
    "item_kaya",
    "item_dagon_2",
    "item_travel_boots",
    "item_aghanims_shard",
    "item_cyclone",
    "item_ultimate_scepter",
    "item_octarine_core",--
    "item_dagon_5",--
    "item_kaya_and_sange",--
    "item_crellas_crozier",--
    "item_ultimate_scepter_2",
    "item_shivas_guard",
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_wind_waker",--
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_bottle",
    "item_boots",
    "item_magic_wand",
    "item_kaya",
    "item_dagon_2",
    "item_travel_boots",
    "item_aghanims_shard",
    "item_cyclone",
    "item_ultimate_scepter",
    "item_octarine_core",--
    "item_dagon_5",--
    "item_crellas_crozier",--
    "item_kaya_and_sange",--
    "item_ultimate_scepter_2",
    "item_shivas_guard",
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_wind_waker",--
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_ring_of_protection",

    "item_magic_wand",
    "item_boots",
    "item_phase_boots",
    "item_lotus_orb",--
    "item_veil_of_discord",
    "item_crellas_crozier",--
	"item_gungir",--
    "item_bloodstone",--
    "item_ultimate_scepter",
    "item_shivas_guard",--
	"item_sheepstick",
    "item_travel_boots",
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		if Fu.IsKeyWordUnit( 'pugna_nether_ward', hMinionUnit )
		then
			hNetherWard = hMinionUnit
			return
		end

		Minion.IllusionThink( hMinionUnit )
	end

end

--[[

"npc_dota_hero_pugna"

"Ability1"		"pugna_nether_blast"
"Ability2"		"pugna_decrepify"
"Ability3"		"pugna_nether_ward"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"pugna_life_drain"
"Ability10"		"special_bonus_movement_speed_20"
"Ability11"		"special_bonus_hp_225"
"Ability12"		"special_bonus_unique_pugna_4"
"Ability13"		"special_bonus_unique_pugna_6"
"Ability14"		"special_bonus_unique_pugna_1"
"Ability15"		"special_bonus_unique_pugna_5"
"Ability16"		"special_bonus_unique_pugna_2"
"Ability17"		"special_bonus_unique_pugna_3"

modifier_pugna_nether_blast_thinker
modifier_pugna_decrepify
modifier_pugna_nether_ward
modifier_pugna_nether_ward_aura
modifier_pugna_life_drain

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'pugna')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'pugna')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'pugna')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'pugna')
local talent7 = SafeAbility(bot:GetAbilityByName(sTalentList[7]), 'sTalentList[7]', 'pugna')

local castQDesire, castQLocation
local castWDesire, castWTarget
local castEDesire, castELocation
local castRDesire, castRTarget


local aetherRange = 0
local talent7Damage = 0

local hNetherWard = nil

function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	talent7Damage = 0
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies
	if talent7:IsTrained() then talent7Damage = talent7:GetSpecialValueInt( "value" ) end


	castQDesire, castQLocation = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQLocation )
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end

	castEDesire, castELocation = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityE, castELocation )
		return
	end

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return

	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	local nRadius 	 = abilityQ:GetSpecialValueInt( "radius" )
	local nCastPoint = abilityQ:GetCastPoint() + abilityQ:GetSpecialValueInt( "delay" )
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( "blast_damage" ) + talent7Damage
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + nRadius * 0.8, true, BOT_MODE_NONE )

	local nTargetLocation = nil


	--击杀
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then
			if Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
			then
				nTargetLocation = Fu.GetDelayCastLocation( bot, npcEnemy, nCastRange, nRadius, nCastPoint )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q击杀"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end


	--消耗
	local nCanHurtEnemyAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange + 50, nRadius + 20, 0, 0 )
	if nCanHurtEnemyAoE.count >= 3
	then
		nTargetLocation = nCanHurtEnemyAoE.targetloc
		return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q消耗'
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


	--打架
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + nRadius - 120 )
		then
			nTargetLocation = Fu.GetDelayCastLocation( bot, botTarget, nCastRange, nRadius -60, nCastPoint + 0.3 )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q打架"..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange -120, nRadius -30, 2 )
		if nAoeLoc ~= nil
		then
			nTargetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q撤退Aoe'
		end

		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 4.0 ) or bot:GetActiveModeDesire() > BOT_ACTION_DESIRE_VERYHIGH )
			then
				nTargetLocation = Fu.GetDelayCastLocation( bot, npcEnemy, nCastRange -140, nRadius, nCastPoint + 0.3 )
				if not bot:IsFacingLocation( npcEnemy:GetLocation(), 50 ) then nTargetLocation = bot:GetLocation() end
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q撤退消耗:"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end


	--自保
	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 6
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy ) 
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 60 )
			then
				nTargetLocation = Fu.GetDelayCastLocation( bot, npcEnemy, nCastRange, nRadius -30, nCastPoint + 0.2 )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q自保"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end

	--对线

	--打野
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		if Fu.IsValid( botTarget )
			and botTarget:GetTeam() == TEAM_NEUTRAL
			and Fu.IsInRange( bot, botTarget, 1000 )
			and ( botTarget:GetMagicResist() < 0.4 or nMP > 0.9 )
		then
			local nShouldHurtCount = nMP > 0.6 and 2 or 3
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange + 220, nRadius, 0, 0 )
			if ( locationAoE.count >= nShouldHurtCount )
			then
				nTargetLocation = locationAoE.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q打钱"..locationAoE.count
			end
		end
	end

	--带线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and nSkillLV >= 3 and DotaTime() > 9 * 60
		and #hAllyList <= 3 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 400, true )
		if #laneCreepList >= 4
			and Fu.IsValid( laneCreepList[1] )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			local locationAoEKill = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange + 220, nRadius, nCastPoint, nDamage )
			if locationAoEKill.count >= 3
			then
				nTargetLocation = locationAoEKill.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q带线补刀"..locationAoEKill.count
			end

			local locationAoEHurt = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange + 220, nRadius + 50, 0.8, 0 )
			if locationAoEHurt.count >= 4
			then
				nTargetLocation = locationAoEHurt.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q带线清兵"..locationAoEHurt.count
			end
		end
	end

	--肉山
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 600
	then
		if Fu.IsRoshan( botTarget ) and Fu.GetHP( botTarget ) > 0.2
			and Fu.IsInRange( botTarget, bot, nCastRange + 300 )
		then
			nTargetLocation = botTarget:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q肉山'
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end


	--推塔
	if Fu.IsAllowedToSpam( bot, 120 )
		and nSkillLV >= 4
		and ( nLV >= 8 or DotaTime() > 8 * 60 )
		and bot:GetMana() > abilityR:GetManaCost() + 200
	then
		local nTowerList = bot:GetNearbyTowers( 990, true )
		local nBarrackList = bot:GetNearbyBarracks( 990, true )
		local nEnemyAcient = GetAncient( GetOpposingTeam() )
		local hBuildingList = {
			botTarget,
			nTowerList[1],
			nBarrackList[1],
			nEnemyAcient, 
		}

		for _, nBuilding in pairs( hBuildingList )
		do
			if Fu.IsValidBuilding( nBuilding )
				and Fu.IsInRange( bot, nBuilding, nCastRange + nRadius - 50 )
				and not nBuilding:HasModifier( 'modifier_fountain_glyph' )
				and not nBuilding:HasModifier( 'modifier_invulnerable' )
				and not nBuilding:HasModifier( 'modifier_backdoor_protection' )
				and not Fu.IsKeyWordUnit( "DOTA_Outpost", nBuilding )
			then
				local nTargetLocation = nBuilding:GetLocation()
				if not Fu.IsInLocRange( bot, nTargetLocation, nCastRange )
				then
					nTargetLocation = Fu.GetUnitTowardDistanceLocation( bot, nBuilding, nCastRange )
				end
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q推塔"
				end
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
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )


	if Fu.IsValid( hNetherWard )
		and Fu.IsInRange( bot, hNetherWard, nCastRange )
		and Fu.GetHP( hNetherWard ) < 0.9
	then
		for _, npcEnemy in pairs( hEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and npcEnemy:GetAttackTarget() == hNetherWard
			then
				return BOT_ACTION_DESIRE_HIGH, hNetherWard, 'W-NetherWard'
			end
		end
	end


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

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange - 60 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsAttacking( botTarget )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "W-attack:"..Fu.Chat.GetNormName( botTarget )
		end
	end

	for _, npcAlly in pairs( hAllyList )
	do
		if Fu.IsValidHero( npcAlly )
			and Fu.IsRetreating( npcAlly )
			and Fu.IsRunning( npcAlly )
			and npcAlly:WasRecentlyDamagedByAnyHero( 4.0 )
		then
			local nNearbyEnemyList = Fu.GetEnemyList( npcAlly, 1000 )
			if #nNearbyEnemyList >= 2
			then
				for _, npcEnemy in pairs( hEnemyList )
				do
					if Fu.IsValidHero( npcEnemy )
						and Fu.IsInRange( npcAlly, npcEnemy, npcEnemy:GetAttackRange() + 60 )
						and ( npcEnemy:GetAttackTarget() == npcAlly
								or Fu.IsInRange( npcAlly, npcEnemy, 500 ) )
					then
						return BOT_ACTION_DESIRE_HIGH, npcAlly, "W-protect:"..Fu.Chat.GetNormName( npcAlly )
					end
				end
			else
				local npcEnemy = nNearbyEnemyList[1]
				if Fu.IsValidHero( npcEnemy )
					and Fu.IsInRange( bot, npcEnemy, nCastRange )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, "W-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange() + aetherRange
	local nRadius 	 = abilityE:GetSpecialValueInt( 'radius' )
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )

	local vCastLocation = Fu.GetLocationTowardDistanceLocation( bot, Fu.GetTeamFountain(), nCastRange * 0.8 )

	if Fu.IsInTeamFight( bot, 1400 )
	then
		if #nInRangeEnemyList >= 2
		then
			local vEnemyCenter = Fu.GetCenterOfUnits( nInRangeEnemyList )
			if Fu.GetLocationToLocationDistance( vCastLocation, vEnemyCenter ) < nRadius - 300
			then
				return BOT_ACTION_DESIRE_HIGH, vCastLocation, "E-Battle"
			end
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInLocRange( botTarget, vCastLocation, nRadius - 500 )
			and ( botTarget:IsFacingLocation( bot:GetLocation(), 50 )
				  or Fu.IsInLocRange( botTarget, vCastLocation, 800 ) )
			and Fu.CanCastOnNonMagicImmune( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, vCastLocation, "E-Attack:"..Fu.Chat.GetNormName( botTarget )
		end
	end

	if Fu.IsRetreating( bot ) and nLV >= 8
	then
		local vCastLocation = Fu.GetFaceTowardDistanceLocation( bot, nCastRange )
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.IsInLocRange( npcEnemy, vCastLocation, nRadius - 400 )
			then
				return BOT_ACTION_DESIRE_HIGH, vCastLocation, "E-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
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
	local nInWardRangeEnemyList = Fu.GetNearbyHeroes(bot, 1400, true, BOT_MODE_NONE )

	if Fu.IsInTeamFight( bot, 1400 )
	and Fu.HasAghanimsShard(bot)
	then
		if #nInWardRangeEnemyList >= 2
		then
			local nAllyUnits = GetUnitList(UNIT_LIST_ALLIES)

			for _, a in pairs(nAllyUnits)
			do
				if (string.find(a:GetUnitName(), "nether_ward"))
				and Fu.IsInRange(bot, a, nCastRange)
				then
					return BOT_ACTION_DESIRE_HIGH, a, "Nether Ward"..Fu.Chat.GetNormName( botTarget )
				end
			end
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "R-Attack:"..Fu.Chat.GetNormName( botTarget )
		end
	end

	if Fu.IsRetreating( bot )
	then
		local nAttackAllyList = Fu.GetNearbyHeroes(bot, 1400, false, BOT_MODE_ATTACK )
		local nDefendAllyList = Fu.GetNearbyHeroes(bot, 1600, false, BOT_MODE_DEFEND_ALLY )
		if #nAttackAllyList >= 1
			or #nDefendAllyList >= 1
			or #hEnemyList <= 1
		then
			for _, npcEnemy in pairs( nInRangeEnemyList )
			do
				if Fu.IsValidHero( npcEnemy )
					and Fu.IsInRange( bot, npcEnemy, nCastRange -100 )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
					and Fu.CanCastOnTargetAdvanced( npcEnemy )
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, "R-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


return X




