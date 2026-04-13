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
						{1,3,1,2,1,6,1,2,3,3,6,2,2,3,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_blood_grenade",

	"item_magic_wand",
	"item_arcane_boots",
	"item_aghanims_shard",
	"item_glimmer_cape",--
	"item_ultimate_scepter",
	"item_guardian_greaves",--
	"item_aether_lens",--
	"item_octarine_core",--
	"item_black_king_bar",--
	"item_refresher",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_blood_grenade",

	"item_magic_wand",
	"item_tranquil_boots",
	"item_aghanims_shard",
	"item_pipe",--
	"item_glimmer_cape",--
	"item_ultimate_scepter",
	"item_boots_of_bearing",--
	"item_aether_lens",--
	"item_octarine_core",--
	-- "item_black_king_bar",--
	"item_refresher",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = {
	
	"item_crystal_maiden_outfit",
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_glimmer_cape",
	"item_force_staff",
	"item_cyclone",
	"item_sheepstick",
	"item_wind_waker",
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_refresher",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_cyclone",
	"item_magic_wand",

	"item_ultimate_scepter",
	"item_magic_wand",
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

npc_dota_hero_shadow_shaman

"Ability1"		"shadow_shaman_ether_shock"
"Ability2"		"shadow_shaman_voodoo"
"Ability3"		"shadow_shaman_shackles"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"shadow_shaman_mass_serpent_ward"
"Ability10"		"special_bonus_hp_200"
"Ability11"		"special_bonus_exp_boost_20"
"Ability12"		"special_bonus_cast_range_125"
"Ability13"		"special_bonus_unique_shadow_shaman_5"
"Ability14"		"special_bonus_unique_shadow_shaman_2"
"Ability15"		"special_bonus_unique_shadow_shaman_1"
"Ability16"		"special_bonus_unique_shadow_shaman_3"
"Ability17"		"special_bonus_unique_shadow_shaman_4"

modifier_shadow_shaman_ethershock
modifier_shadow_shaman_voodoo
modifier_shadow_shaman_shackles
modifier_shadow_shaman_serpent_ward

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'shadow_shaman')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'shadow_shaman')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'shadow_shaman')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'shadow_shaman')
local Urnaconda = SafeAbility(bot:GetAbilityByName('shadow_shaman_urnaconda'), 'shadow_shaman_urnaconda', 'shadow_shaman')
local talent3 = SafeAbility(bot:GetAbilityByName(sTalentList[3]), 'sTalentList[3]', 'shadow_shaman')
local talent7 = SafeAbility(bot:GetAbilityByName(sTalentList[7]), 'sTalentList[7]', 'shadow_shaman')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRLocation
local UrnacondaDesire, UrnacondaLocation


local aetherRange = 0
local talent7Damage = 0



local bAttacking
function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	bAttacking = Fu.IsAttacking(bot)

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
--	if talent3:IsTrained() then aetherRange = aetherRange + talent3:GetSpecialValueInt( "value" ) end
	if talent7:IsTrained() then talent7Damage = talent7:GetSpecialValueInt( "value" ) end


	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end

	UrnacondaDesire, UrnacondaLocation = X.ConsiderUrnaconda()
	if UrnacondaDesire > 0
	then
		Fu.SetQueuePtToINT( bot, true )
		bot:ActionQueue_UseAbilityOnLocation( Urnaconda, UrnacondaLocation )
		return
	end


	castRDesire, castRLocation = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityR, castRLocation )
		return

	end


	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end


	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return
	end


end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange()
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( "damage" ) + talent7Damage
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 220, true, BOT_MODE_NONE )


	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint )
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'Q-kill'..Fu.Chat.GetNormName( npcEnemy )
		end
	end


	if Fu.IsInTeamFight( bot, 1200 ) and nLV >= 5
	then
		local nWeakestEnemy = nil
		local nWeakestEnemyHealth = 9999

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
			return BOT_ACTION_DESIRE_HIGH, nWeakestEnemy, "Q-Battle-Weakest:"..Fu.Chat.GetNormName( nWeakestEnemy )
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
		then
			if nSkillLV >= 2 or nMP > 0.7 or Fu.GetHP( botTarget ) < 0.5 or nHP < 0.4
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q-attack:'..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 4.0 )
						or nMP > 0.68
						or GetUnitToUnitDistance( bot, npcEnemy ) <= 400 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 30 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "Q-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	if Fu.IsLaning( bot )
	then
		if nMP > 0.5
		then
			for _, npcEnemy in pairs( nInRangeEnemyList )
			do
				if Fu.IsValid( npcEnemy )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
					and Fu.CanCastOnTargetAdvanced( npcEnemy )
					and Fu.GetAttackEnemysAllyCreepCount( npcEnemy, 1400 ) >= 3
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy, "Q-Laning:"..Fu.Chat.GetNormName( npcEnemy )
				end
			end
		end

		
		if #hAllyList <= 1 or Fu.IsCore(bot) then
			local nEnemyCreeps = bot:GetNearbyLaneCreeps( 800, true )
			for _, creep in pairs( nEnemyCreeps )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( 'modifier_fountain_glyph' )
					and not Fu.IsAllysTarget( creep )
				then
					if Fu.IsKeyWordUnit( 'ranged', creep )
						and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
					then
						return BOT_ACTION_DESIRE_HIGH, creep, "Q-LaneRanged"
					end

					if bot:GetMana() > 320
						and Fu.IsKeyWordUnit( 'melee', creep )
						and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
						and not Fu.WillKillTarget( creep, nDamage * 0.5, nDamageType, nCastPoint )
					then
						return BOT_ACTION_DESIRE_HIGH, creep, "Q-LaneMelee"
					end
				end
			end
		end
	end


	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, 30 )
		and nSkillLV >= 3
		and #hEnemyList == 0
		and #hAllyList <= 3
	then
		local nEnemyCreeps = bot:GetNearbyLaneCreeps( 999, true )
		local nAllyCreeps = bot:GetNearbyLaneCreeps( 888, false )

		for _, creep in pairs( nEnemyCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsInRange( creep, bot, nCastRange + 300 )
			then

				if #nAllyCreeps == 0
					and Fu.GetAroundTargetEnemyUnitCount( creep, 380 ) >= 2
					and #nEnemyCreeps >= 4
				then
					return BOT_ACTION_DESIRE_HIGH, creep, "Q-PushAoe"
				end

				if Fu.IsKeyWordUnit( 'ranged', creep )
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, "Q-PushRanged"
				end

				if Fu.IsKeyWordUnit( 'melee', creep )
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
					and ( Fu.GetAroundTargetEnemyUnitCount( creep, 380 ) >= 2 or nMP > 0.8 )
				then
					return BOT_ACTION_DESIRE_HIGH, creep, "Q-PushMelee"
				end

			end
		end

	end


	if Fu.IsFarming( bot ) and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and #hEnemyList == 0
		and #hAllyList <= 2
		and not ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) )
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 200 )
		if #nNeutralCreeps >= 2 or nMP >= 0.5
		then
			local targetCreep = nNeutralCreeps[1]
			if Fu.IsValid( targetCreep )
				and bot:IsFacingLocation( targetCreep:GetLocation(), 30 )
				and targetCreep:GetHealth() >= 500
				and targetCreep:GetMagicResist() < 0.3
				and Fu.GetAroundTargetEnemyUnitCount( targetCreep, 300 ) >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, targetCreep, "Q-Farm:"..( #nNeutralCreeps )
			end
		end
	end

	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan( botTarget )
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.CanBeAttacked(botTarget)
		and bAttacking
		and not botTarget:HasModifier('modifier_roshan_spell_block')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end

    if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
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
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 240, true, BOT_MODE_NONE )



	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W-Check1:'..Fu.Chat.GetNormName( npcEnemy )
			end

			if npcEnemy:IsCastingAbility()
				and Fu.IsInRange( bot, npcEnemy, nCastRange + 50 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W-Check2:'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end



	if Fu.IsInTeamFight( bot, 1200 )
		and ( #nInBonusEnemyList >= 2 or #hAllyList >= 3 )
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
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

		if npcMostDangerousEnemy ~= nil
			and Fu.IsInRange( bot, npcMostDangerousEnemy, nCastRange + 50 )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, 'W-Battle:'..Fu.Chat.GetNormName( npcMostDangerousEnemy )
		end

	end



	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 32 )
			and not Fu.IsDisabled( botTarget )
			and not Fu.IsTaunted( botTarget )
			and not botTarget:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'W-Attack:'..Fu.Chat.GetNormName( botTarget )
		end
	end



	if bot:WasRecentlyDamagedByAnyHero( 3.0 ) and nLV >= 10
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nInRangeEnemyList >= 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W-protect'
			end
		end
	end



	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 4.0 )
						or GetUnitToUnitDistance( bot, npcEnemy ) <= 500 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "W-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	if Fu.IsDoingRoshan( bot ) and nMP > 0.6
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, "W-Roshan"
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
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
	local nDamage = nSkillLV * 100 - 40 + bot:GetAttackDamage() * 2
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 240, true, BOT_MODE_NONE )


	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then
			if npcEnemy:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'E-Check1:'..Fu.Chat.GetNormName( npcEnemy )
			end

			if #hAllyList >= 2
				and npcEnemy:IsCastingAbility()
				and Fu.IsInRange( bot, npcEnemy, nCastRange + 30 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'E-Check2:'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	if Fu.IsInTeamFight( bot, 1200 ) and nLV >= 5
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
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

		if npcMostDangerousEnemy ~= nil
			and Fu.IsInRange( bot, npcMostDangerousEnemy, nCastRange + 50 )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, 'E-Battle:'..Fu.Chat.GetNormName( npcMostDangerousEnemy )
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 30 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and not Fu.IsDisabled( botTarget )
			and not Fu.IsTaunted( botTarget )
			and not botTarget:IsDisarmed()
		then
			if nSkillLV >= 2 or nMP > 0.68 or Fu.GetHP( botTarget ) < 0.35 or nHP < 0.28
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget, "E-Attack:"..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	if Fu.IsRetreating( bot )
		and nSkillLV >= 3
		and #hEnemyList == 1
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not Fu.IsTaunted( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "E-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 800
	then
		if Fu.IsRoshan( botTarget )
			and Fu.GetHP( botTarget ) > 0.2
			and Fu.IsInRange( bot, botTarget, nCastRange + 100 )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange() + aetherRange + 100
	local nRadius	 = 150
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local targetLocation = nil

	if Fu.IsGoingOnSomeone( bot )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange + 100, nRadius, 2 )
		if nAoeLoc ~= nil
		then
			targetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, targetLocation, 'R-Aoe'
		end

		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnMagicImmune( botTarget )
			and botTarget:GetHealth() > bot:GetAttackDamage() * 3
		then
			targetLocation = botTarget:GetExtrapolatedLocation( nCastPoint )
			return BOT_ACTION_DESIRE_HIGH, targetLocation, "R-Attack:"..Fu.Chat.GetNormName( botTarget )
		end
	end


	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnMagicImmune( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 )
			then
				targetLocation = npcEnemy:GetExtrapolatedLocation( nCastPoint )
				return BOT_ACTION_DESIRE_HIGH, targetLocation, "R-Retreat:"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end

	if Fu.IsPushing( bot )
	then
		local nTowerList = bot:GetNearbyTowers( 1100, true )
		local nBarrackList = bot:GetNearbyBarracks( 1100, true )
		local nEnemyAcient = GetAncient( GetOpposingTeam() )
		local hBuildingList = {
			nTowerList[1],
			nBarrackList[1],
			nEnemyAcient, 
		}

		for _, nBuilding in pairs( hBuildingList )
		do
			if Fu.IsValidBuilding( nBuilding )
				and Fu.IsInRange( bot, nBuilding, nCastRange + 500 )
				and not nBuilding:HasModifier( 'modifier_fountain_glyph' )
				and not nBuilding:HasModifier( 'modifier_invulnerable' )
				and not nBuilding:HasModifier( 'modifier_backdoor_protection' )
			then
				targetLocation = Fu.GetUnitTowardDistanceLocation( nBuilding, bot, 240 )
				if GetUnitToLocationDistance( bot, targetLocation ) < 180
				then
					targetLocation = Fu.GetUnitTowardDistanceLocation( bot, nBuilding, 240 )
				end
				if targetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, targetLocation, "R-Pushing"
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderUrnaconda()
	if not Fu.CanCastAbility(Urnaconda) then
		return BOT_ACTION_DESIRE_NONE
	end

	local nCastRange = Urnaconda:GetCastRange()
	local nCastPoint = Urnaconda:GetCastPoint()
	local nDamage = Urnaconda:GetSpecialValueInt('impact_damage')
	local nSpeed = Urnaconda:GetSpecialValueInt('speed')
	local nRadius = Urnaconda:GetSpecialValueInt('impact_radius')
	local nManaCost = Urnaconda:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {abilityQ, abilityW, abilityE, abilityR})

	local nEnemyHeroes = bot:GetNearbyHeroes(nCastRange + 300, true, BOT_MODE_NONE)
	local nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

	for _, enemyHero in pairs(nEnemyHeroes) do
		if  Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
		and not Fu.IsInRange(bot, enemyHero, 300)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not Fu.IsChasingTarget(bot, enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end
		end
	end

	if Fu.IsGoingOnSomeone(bot) then
		if  Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + 300)
		and not Fu.IsChasingTarget(bot, botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			if (Fu.IsDisabled(botTarget) and not (botTarget:HasModifier('modifier_enigma_black_hole_pull') or botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')))
			or botTarget:GetCurrentMovementSpeed() <= 250
			then
				if Fu.GetHP(botTarget) > 0.4 then
					if Fu.GetTotalEstimatedDamageToTarget(nAllyHeroes, botTarget, 8.0) > botTarget:GetHealth() then
						return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
					end
				end
			end

			if Fu.IsInTeamFight(bot, 1200) then
				return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
			end
		end
	end

	if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and not Fu.CanCastAbilitySoon(abilityW, 5.0) and not Fu.IsInTeamFight(bot, 1200) and Fu.IsRunning(bot) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if  Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and not Fu.IsInRange(bot, enemyHero, nRadius)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and Fu.IsChasingTarget(enemyHero, bot)
			and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	if Fu.IsPushing(bot) and #nAllyHeroes >= #nEnemyHeroes and fManaAfter > fManaThreshold1 then
		local radius = Min(nCastRange + bot:GetAttackRange(), 1600)
		local nEnemyTowers = bot:GetNearbyTowers(radius, true)
		local nEnemyBarracks = bot:GetNearbyBarracks(radius, true)
		local hEnemyAncient = GetAncient(GetOpposingTeam())
		local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 800)

		local hBuildingList = {
			botTarget,
			nEnemyTowers[1],
			nEnemyBarracks[1],
			hEnemyAncient,
		}

		for _, building in pairs(hBuildingList) do
			if  Fu.IsValidBuilding(building)
			and Fu.CanBeAttacked(building)
			and Fu.IsInRange(bot, building, nCastRange + bot:GetAttackRange())
			and not Fu.IsKeyWordUnit('DOTA_Outpost', building)
			then
				local sBuildingName = building:GetUnitName()
				if #nInRangeAlly <= 3 or string.find(sBuildingName, 'barracks') or building == hEnemyAncient then
					if (building:GetHealthRegen() == 0)
					or (bot:GetAttackTarget() == building)
					then
						return BOT_ACTION_DESIRE_HIGH, Fu.VectorTowards(building:GetLocation(), bot:GetLocation(), nRadius)
					end
				end
			end
		end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange + 300, 1600), true)

	if Fu.IsFarming(bot) and bAttacking and fManaAfter > fManaThreshold1 + 0.1 and #nAllyHeroes <= 1 then
		for _, creep in pairs(nEnemyCreeps) do
			if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
				local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
				if (nLocationAoE.count >= 3)
				or (nLocationAoE.count >= 2 and creep:IsAncientCreep())
				or (nLocationAoE.count >= 1 and creep:GetHealth() >= 1000)
				then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X
