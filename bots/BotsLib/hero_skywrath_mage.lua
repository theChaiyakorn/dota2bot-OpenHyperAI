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
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{2,1,1,3,2,6,1,1,3,3,6,3,2,2,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_blood_grenade",

	"item_magic_wand",
	"item_arcane_boots",
	"item_rod_of_atos",
	"item_glimmer_cape",--
	"item_aether_lens",--
	"item_aghanims_shard",
	"item_guardian_greaves",--
	"item_ultimate_scepter",
	"item_octarine_core",--
	"item_gungir",--
	"item_shivas_guard",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_blood_grenade",

	"item_magic_wand",
	"item_tranquil_boots",
	"item_glimmer_cape",--
	"item_pipe",
	"item_rod_of_atos",
	-- "item_aether_lens",--
	"item_aghanims_shard",
	"item_boots_of_bearing",--
	"item_ultimate_scepter",
	"item_octarine_core",--
	"item_gungir",--
	"item_sheepstick",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = {
	"item_crystal_maiden_outfit",
	"item_rod_of_atos",
--	"item_glimmer_cape",
    "item_kaya",
	"item_ultimate_scepter",
    "item_kaya_and_sange",--
	"item_aghanims_shard",
	"item_octarine_core",--
	"item_gungir",--
	"item_cyclone",
	"item_sheepstick",--
	"item_wind_waker",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_double_circlet",

	"item_bottle",
	'item_null_talisman',
	"item_magic_wand",
	'item_null_talisman',
	"item_arcane_boots",
	"item_rod_of_atos",
--	"item_glimmer_cape",
    "item_kaya",
	"item_ultimate_scepter",
    "item_kaya_and_sange",--
	"item_aghanims_shard",
	"item_dagon_2",
	"item_octarine_core",--
	"item_gungir",--
	-- "item_cyclone",
	"item_sheepstick",--
    "item_dagon_5",--
	-- "item_wind_waker",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
    "item_travel_boots_2",--
}


sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

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
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_skywrath_mage

"Ability1"		"skywrath_mage_arcane_bolt"
"Ability2"		"skywrath_mage_concussive_shot"
"Ability3"		"skywrath_mage_ancient_seal"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"skywrath_mage_mystic_flare"
"Ability10"		"special_bonus_movement_speed_20"
"Ability11"		"special_bonus_intelligence_8"
"Ability12"		"special_bonus_unique_skywrath"
"Ability13"		"special_bonus_unique_skywrath_2"
"Ability14"		"special_bonus_unique_skywrath_4"
"Ability15"		"special_bonus_unique_skywrath_3"
"Ability16"		"special_bonus_gold_income_50"
"Ability17"		"special_bonus_unique_skywrath_5"

modifier_skywrath_mage_concussive_shot_slow
modifier_skywrath_mage_ancient_seal
modifier_skywrath_mage_mystic_flare
modifier_skywrath_mystic_flare_aura_effect


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'skywrath_mage')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'skywrath_mage')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'skywrath_mage')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'skywrath_mage')


local castQDesire, castQTarget
local castWDesire
local castEDesire, castETarget
local castRDesire, castRLocation



local aetherRange = 0

local nLV, nKeepMana, nMP, nHP, hEnemyList

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
	nInRangeEnemyHeroList = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE )


	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return
	end

	castRDesire, castRLocation = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityR, castRLocation )
		return

	end

	castWDesire = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityW )
		return
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end



end

function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( "bolt_damage" ) + bot:GetAttributeValue( ATTRIBUTE_INTELLECT ) * 1.6
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyHeroList = Fu.GetNearbyHeroes(bot, math.min(nCastRange + 50, 1600), true, BOT_MODE_NONE )
	local nAttackDamage = bot:GetAttackDamage()

	local hAllyList = Fu.GetNearbyHeroes(bot, 1300, false, BOT_MODE_NONE )


	if ( not Fu.IsValidHero( botTarget ) or Fu.GetHP( botTarget ) > 0.2 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyHeroList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and Fu.GetHP( npcEnemy ) <= 0.2
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "Q击杀"..npcEnemy:GetUnitName()
			end
		end
	end

	--对线期的使用
	if Fu.IsLaning( bot ) then
		if not Fu.IsThereNonSelfCoreNearby(nCastRange) then
			local hLaneCreepList = bot:GetNearbyLaneCreeps( math.min(nCastRange + 50, 1600), true )
			for _, creep in pairs( hLaneCreepList )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and Fu.IsKeyWordUnit( "ranged", creep )
					and not Fu.IsOtherAllysTarget( creep )
					and creep:GetHealth() > nDamage * 0.68
				then
					local nDelay = nCastPoint + GetUnitToUnitDistance( bot, creep )/500
					if Fu.WillKillTarget( creep, nDamage, nDamageType, nDelay * 0.9 )
						and not Fu.WillKillTarget( creep, nAttackDamage, DAMAGE_TYPE_PHYSICAL, nDelay )
					then
						return BOT_ACTION_DESIRE_HIGH, creep, 'Q对线'
					end
				end
			end
		end
		if #nInRangeEnemyHeroList >= 1 and nMP > 0.5 and nSkillLV >= 2 then
			local npcEnemy = nInRangeEnemyHeroList[1]
			if Fu.IsValidHero(npcEnemy)
			and Fu.IsInRange(bot, npcEnemy, nCastRange) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "Q消耗"..npcEnemy:GetUnitName()
			end
		end
	end


	if Fu.IsRetreating( bot ) and bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		local target = Fu.GetVulnerableWeakestUnit( bot, true, true, nCastRange )
		if target ~= nil
			and bot:IsFacingLocation( target:GetLocation(), 30 )
			and Fu.CanCastOnTargetAdvanced( target )
		then
			return BOT_ACTION_DESIRE_HIGH, target, 'Q撤退'
		end
	end


	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and #hAllyList < 3 and nLV > 7
		and Fu.IsAllowedToSpam( bot, 30 )
	then
		local hLaneCreepList = bot:GetNearbyLaneCreeps( math.min(nCastRange + 150, 1600), true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and ( Fu.IsKeyWordUnit( "ranged", creep )
						or ( nMP > 0.5 and Fu.IsKeyWordUnit( "melee", creep ) ) )
				and not Fu.IsOtherAllysTarget( creep )
				and creep:GetHealth() > nDamage * 0.68
			then
				local nDelay = nCastPoint + GetUnitToUnitDistance( bot, creep )/500
				if Fu.WillKillTarget( creep, nDamage, nDamageType, nDelay * 0.8 )
					and not Fu.WillKillTarget( creep, nAttackDamage, DAMAGE_TYPE_PHYSICAL, nDelay )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, 'Q推进'
				end
			end
		end
	end


	if Fu.IsFarming( bot ) and nLV >= 3
	then
		if Fu.IsValid( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and botTarget:GetTeam() == TEAM_NEUTRAL
			and ( botTarget:GetMagicResist() < 0.3 or nMP > 0.7 )
			and nMP > 0.4
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q打野'
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 50 )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q进攻'
		end
	end


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

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end



	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = 1600
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nSkillTarget = hEnemyList[1]

	if Fu.IsValidHero( nSkillTarget )
		and Fu.CanCastOnNonMagicImmune( nSkillTarget )
	then
		local nDist = GetUnitToUnitDistance( bot, nSkillTarget )
		if Fu.WillMagicKillTarget( bot, nSkillTarget, nDamage, nCastPoint + nDist/1200 )
		then
			return BOT_ACTION_DESIRE_HIGH, 'W击杀'..Fu.Chat.GetNormName( nSkillTarget )
		end
	end

	--对线期的使用
	if Fu.IsLaning( bot ) then
		if #nInRangeEnemyHeroList >= 1 and nMP > 0.5 and (nSkillLV >= 2 or nLV <= 2) then
			local npcEnemy = nInRangeEnemyHeroList[1]
			if Fu.IsValidHero(npcEnemy)
			and Fu.IsInRange(bot, npcEnemy, nCastRange) then
				return BOT_ACTION_DESIRE_HIGH, "W消耗"..npcEnemy:GetUnitName()
			end
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsValidHero( nSkillTarget )
			and Fu.CanCastOnNonMagicImmune( nSkillTarget )
			and Fu.IsInRange( bot, nSkillTarget, nCastRange + 50 )
			and Fu.IsInRange( botTarget, nSkillTarget, 250 )
		then
			return BOT_ACTION_DESIRE_HIGH, 'W进攻'
		end
	end

	if Fu.IsRetreating( bot )
	then
		if Fu.IsValidHero( nSkillTarget )
			and Fu.CanCastOnNonMagicImmune( nSkillTarget )
			and Fu.IsInRange( bot, nSkillTarget, nCastRange + 50 )
			and ( bot:WasRecentlyDamagedByHero( nSkillTarget, 5.0 ) or nHP < 0.4 )
		then
			return BOT_ACTION_DESIRE_HIGH, 'W撤退'
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetCastRange() + aetherRange
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyHeroList = Fu.GetNearbyHeroes(bot, math.min(nCastRange + 50, 1600), true, BOT_MODE_NONE )


	for _, npcEnemy in pairs( nInRangeEnemyHeroList )
	do
		if ( npcEnemy:IsCastingAbility() or npcEnemy:IsChanneling() )
			and not npcEnemy:HasModifier( "modifier_teleporting" )
			and not npcEnemy:HasModifier( "modifier_boots_of_travel_incoming" )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E打断"
		end
	end


	if Fu.IsInTeamFight( bot, 700 )
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, math.min(nCastRange + 100, 1600), true, BOT_MODE_NONE )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsSilenced()
			then
				local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_MAGICAL )
				if ( npcEnemyDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = npcEnemyDamage
					npcMostDangerousEnemy = npcEnemy
				end
			end
		end

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, "E团战"
		end

	end


	if bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and nInRangeEnemyHeroList[1] ~= nil
		and #nInRangeEnemyHeroList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyHeroList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsSilenced()
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 40 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E自保"
			end
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsSilenced()
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "E进攻"
		end
	end


	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyHeroList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.1 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsSilenced()
				and Fu.IsInRange( npcEnemy, bot, nCastRange )
				and ( not Fu.IsInRange( npcEnemy, bot, 450 ) or bot:IsFacingLocation( npcEnemy:GetLocation(), 45 ) )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E撤退"
			end
		end
	end


	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 1200
		and abilityE:GetLevel() >= 3
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "E肉山"
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

	return BOT_ACTION_DESIRE_NONE


end

--modifier_skywrath_mage_concussive_shot_slow
function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end


	local nCastRange = abilityR:GetCastRange() + aetherRange
	
	if nCastRange > 1400 then nCastRange = 1400 end
	
	local nRadius = 170
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyHeroList = Fu.GetNearbyHeroes(bot, math.min(nCastRange + 200, 1600), true, BOT_MODE_NONE )


	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius, 2 )
		if nAoeLoc ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nAoeLoc, 'R团战'
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 200 )
		then
			if ( not Fu.IsRunning( botTarget ) and not Fu.IsMoving( botTarget ) )
				or Fu.IsDisabled( botTarget )
				or botTarget:GetCurrentMovementSpeed() < 180
			then
				return BOT_ACTION_DESIRE_HIGH, Fu.GetFaceTowardDistanceLocation( botTarget, 148 ), 'R进攻'
			end
		end
	end

	if Fu.IsRetreating( bot ) and nHP < 0.78
	then
		for _, npcEnemy in pairs( nInRangeEnemyHeroList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.1 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, Fu.GetFaceTowardDistanceLocation( npcEnemy, 168 ), 'R撤退'
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


return X
