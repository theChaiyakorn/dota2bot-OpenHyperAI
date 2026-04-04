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
							{1,3,2,3,3,6,3,1,1,1,6,2,2,2,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRandomItem_1 = RandomInt( 1, 9 ) > 5 and "item_monkey_king_bar" or "item_abyssal_blade"
local sAbyssalBloodthorn = RandomInt( 1, 9 ) > 4 and "item_bloodthorn" or "item_butterfly"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_slippers",
	"item_circlet",

	"item_magic_wand",
	"item_wraith_band",
	"item_power_treads",
	"item_diffusal_blade",
	"item_manta",--
	"item_heart",--
	"item_skadi",--
	"item_ultimate_scepter",
	"item_disperser",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	sRandomItem_1,--
	sAbyssalBloodthorn,--
	"item_aghanims_shard",
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

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_PL' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		if hMinionUnit:IsIllusion() then hMinionUnit.isIllusion = true end
		if hMinionUnit:HasModifier( 'modifier_phantom_lancer_phantom_edge_boost' ) then return end

		Minion.IllusionThink( hMinionUnit )
	end

end

--[[

npc_dota_hero_phantom_lancer

phantom_lancer_spirit_lance
phantom_lancer_doppelwalk
phantom_lancer_phantom_edge
phantom_lancer_juxtapose
special_bonus_unique_phantom_lancer_2
special_bonus_attack_speed_20
special_bonus_all_stats_8
special_bonus_cooldown_reduction_15
special_bonus_magic_resistance_15
special_bonus_evasion_15
special_bonus_strength_20
special_bonus_unique_phantom_lancer

modifier_phantom_lancer_spirit_lance
modifier_phantomlancer_dopplewalk_phase
modifier_phantom_lancer_doppelwalk_illusion
modifier_phantom_lancer_juxtapose
modifier_phantom_lancer_phantom_edge
modifier_phantom_lancer_phantom_edge_boost
modifier_phantom_lancer_phantom_edge_agility
modifier_phantom_lancer_juxtapose_illusion

--]]


local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent4 = bot:GetAbilityByName( sTalentList[4] )
local talent5 = bot:GetAbilityByName( sTalentList[5] )


local castQDesire, castQTarget
local castWDesire, castWLocation
local castRDesire


local talent4Damage = 0
local aetherRange = 0

local boostRange = 0


function X.SkillsComplement()


	if Fu.CanNotUseAbility( bot )
		or bot:IsInvisible()
		or bot:HasModifier( 'modifier_phantom_lancer_phantom_edge_boost' )
	then return end


	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	talent4Damage = 0
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies


	if abilityE:IsTrained() then boostRange = abilityE:GetSpecialValueInt( "max_distance" ) end
--	if talent4:IsTrained() then talent4Damage = talent4:GetSpecialValueInt( "value" ) end
	if talent5:IsTrained() then boostRange = boostRange + talent5:GetSpecialValueInt( "value" ) end


	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end


	castWDesire, castWLocation = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWLocation )
		return
	end

	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityR )
		return
	end

end

function X.ConsiderR()

	if not abilityR:IsFullyCastable()
		or not bot:HasScepter()
		or true
	then
		return BOT_ACTION_DESIRE_NONE
	end

	if Fu.IsRetreating(bot)
	and Fu.GetHP(bot) < 0.4
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
		and Fu.IsInRange( bot, botTarget, 1200 )
		and not Fu.IsInRange( bot, botTarget, 650 )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange

	if #hEnemyList <= 1 then nCastRange = nCastRange + 200 end

	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( 'lance_damage' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )


	local nAttackDamage = bot:GetAttackDamage()

	--击杀
	if ( not Fu.IsValidHero( botTarget ) or Fu.GetHP( botTarget ) > 0.2 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "Q击杀"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--对线
	if bot:GetActiveMode() == BOT_MODE_LANING
		and #hAllyList <= 2
	then
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 90, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( "ranged", creep )
				and not Fu.IsAllysTarget( creep )
				and not Fu.IsInRange( bot, creep, 300 )
			then
				local nDelay = nCastPoint + GetUnitToUnitDistance( bot, creep )/1000
				if Fu.WillKillTarget( creep, nDamage, nDamageType, nDelay * 0.95 )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, 'Q对线'
				end
			end
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
		and ( bot:WasRecentlyDamagedByAnyHero( 2.0 ) or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "Q撤退"..npcEnemy:GetUnitName()
			end
		end
	end


	--打钱
	if Fu.IsFarming( bot ) and nLV > 5
		and Fu.IsAllowedToSpam( bot, 30 )
	then
		if Fu.IsValid( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and botTarget:GetTeam() == TEAM_NEUTRAL
			and ( botTarget:GetMagicResist() < 0.3 or nMP > 0.9 )
			and not Fu.CanKillTarget( botTarget, nAttackDamage * 1.38, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( botTarget, nDamage -10, nDamageType )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q打野'
		end
	end

	--打架
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q进攻'..Fu.Chat.GetNormName( botTarget )
		end

		--团战
		if Fu.IsInTeamFight( bot, 900 ) and nLV > 5
		then
			for _, npcEnemy in pairs( nInRangeEnemyList )
			do
				if Fu.IsValidHero( npcEnemy )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
					and Fu.CanCastOnTargetAdvanced( npcEnemy )
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q团战'..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end
	end


	--推线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and #hAllyList <= 2 and nLV >= 8
		and Fu.IsAllowedToSpam( bot, 30 )
	then
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 220, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and ( Fu.IsKeyWordUnit( "ranged", creep )
						or ( nMP > 0.6 and Fu.IsKeyWordUnit( "melee", creep ) ) )
				and not Fu.IsAllysTarget( creep )
				and creep:GetHealth() > nDamage * 0.88
			then

				local nDelay = nCastPoint + GetUnitToUnitDistance( bot, creep )/1000
				if Fu.WillKillTarget( creep, nDamage, nDamageType, nDelay * 0.98 )
					and not Fu.WillKillTarget( creep, nAttackDamage, DAMAGE_TYPE_PHYSICAL, nDelay )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, 'Q推线1'
				end

				local hAllyCreepList = bot:GetNearbyLaneCreeps( 1200, false )
				if #hAllyCreepList == 0
				then
					return BOT_ACTION_DESIRE_HIGH, creep, 'Q推线2'
				end

			end
		end
	end


	--肉山
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and nLV > 15 and nMP > 0.4
	then
		if Fu.IsRoshan( botTarget )
			and Fu.GetHP( botTarget ) > 0.2
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q肉山'
		end
	end

	--通用


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable() or bot:DistanceFromFountain() < 600 then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange() + aetherRange
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	local vEscapeLoc = Fu.GetLocationTowardDistanceLocation( bot, Fu.GetTeamFountain(), nCastRange )


	--躲避
	if Fu.IsNotAttackProjectileIncoming( bot, 500 )
		or ( Fu.IsWithoutTarget( bot ) and Fu.GetAttackProjectileDamageByRange( bot, 1600 ) >= bot:GetHealth() )
	then
		return BOT_ACTION_DESIRE_HIGH, vEscapeLoc, 'W躲避'
	end

	--撤退
	if Fu.IsRetreating( bot )
		and ( bot:WasRecentlyDamagedByAnyHero( 2.0 ) or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH )
		and #hEnemyList >= 1
	then
		return BOT_ACTION_DESIRE_HIGH, vEscapeLoc, 'W撤退'
	end

	--打架
	if Fu.IsGoingOnSomeone( bot )
		and not bot:HasModifier( 'modifier_phantom_lancer_phantom_edge_agility' )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnMagicImmune( botTarget )
			and not Fu.IsDisabled( botTarget )
			and ( X.IsEnemyCastAbility() or nHP < 0.2 )
			and ( nSkillLV >= 3 or nMP > 0.6 or nHP < 0.4 or Fu.GetHP( botTarget ) < 0.4 or DotaTime() > 9 * 60 )
		then

			--迷惑目标
			local vBestCastLoc = nil
			local nDistMin = 9999
			local vTargetLoc = Fu.GetCorrectLoc( botTarget, 1.0 )
			for i = 30, nCastRange, 30
			do
				local vFirstLoc = Fu.GetFaceTowardDistanceLocation( bot, i )
				local nDistance = Fu.GetLocationToLocationDistance( vTargetLoc, vFirstLoc )
				if nDistance > 300
					and ( nDistance < boostRange - 300 or nDistance < 500 )
					and nDistance < nDistMin
				then
					nDistMin = nDistance
					vBestCastLoc = vFirstLoc
				end
			end
			if vBestCastLoc ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, vBestCastLoc, 'W迷惑'..Fu.Chat.GetNormName( botTarget )
			end

			--追击目标
			local vSecondLoc = Fu.GetUnitTowardDistanceLocation( bot, botTarget, nCastRange )
			if nSkillLV >= 4
				and not Fu.IsInRange( bot, botTarget, boostRange + 400 )
				and Fu.IsInRange( bot, botTarget, boostRange + 1000 )
				and bot:IsFacingLocation( botTarget:GetLocation(), 30 )
				and botTarget:IsFacingLocation( Fu.GetEnemyFountain(), 30 )
			then
				return BOT_ACTION_DESIRE_HIGH, vSecondLoc, 'W追击'..Fu.Chat.GetNormName( botTarget )
			end

		end
	end

	--打钱和推线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and #hAllyList <= 2 and nLV >= 9
		and Fu.IsAllowedToSpam( bot, 100 )
	then
		if Fu.IsValid( botTarget )
			and not Fu.IsInRange( bot, botTarget, boostRange + 300 )
			and Fu.IsInRange( bot, botTarget, boostRange + 1200 )
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetUnitTowardDistanceLocation( bot, botTarget, nCastRange ), 'W打钱'
		end
	end

	--通用

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
			and npcEnemy:IsFacingLocation( bot:GetLocation(), 25 )
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






