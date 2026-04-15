local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils')
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion')
local sTalentList = Fu.Skill.GetTalentList(bot)
local sAbilityList = Fu.Skill.GetAbilityList(bot)
local sRole = Fu.Item.GetRoleItemsBuyList(bot)

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{3,1,1,2,3,6,3,3,2,2,6,2,1,1,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",

	'item_null_talisman',
	"item_bottle",
	"item_magic_wand",
	'item_null_talisman',
	"item_boots",
	"item_power_treads",
	"item_witch_blade",
	"item_kaya_and_sange",--
	"item_ultimate_scepter",
	"item_black_king_bar",--
	"item_shivas_guard",--
	"item_aghanims_shard",
	"item_travel_boots",
	"item_devastator",--
	"item_cyclone",
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_wind_waker",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",

	"item_magic_wand",
	"item_boots",
	"item_power_treads",
	"item_witch_blade",
	"item_kaya_and_sange",--
	"item_ultimate_scepter",
	"item_black_king_bar",--
	"item_shivas_guard",--
	"item_aghanims_shard",
	"item_travel_boots",
	"item_devastator",--
	"item_cyclone",
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_wind_waker",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_enchanted_mango",
	"item_blood_grenade",

	"item_magic_wand",
	"item_boots",
	"item_arcane_boots",
	"item_glimmer_cape",--
	"item_aether_lens",--
	"item_aghanims_shard",
	"item_force_staff",--
	"item_guardian_greaves",--
	"item_cyclone",
    "item_lotus_orb",--
	"item_gungir",--
	"item_moon_shard",
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
	"item_pipe",
	"item_aether_lens",--
	"item_aghanims_shard",
	"item_force_staff",--
	"item_boots_of_bearing",--
	"item_cyclone",
    -- "item_lotus_orb",--
	"item_gungir",--
	"item_moon_shard",
	"item_wind_waker",--
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	'item_null_talisman',
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'],X['sSellList'] = { 'PvN_mage' }, {} end

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'] = Fu.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList']);

X['sSkillList'] = Fu.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit(hMinionUnit) 
	then
		Minion.IllusionThink(hMinionUnit)	
	end

end

--[[

npc_dota_hero_queenofpain

"Ability1"		"queenofpain_shadow_strike"
"Ability2"		"queenofpain_blink"
"Ability3"		"queenofpain_scream_of_pain"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"queenofpain_sonic_wave"
"Ability10"		"special_bonus_attack_damage_20"
"Ability11"		"special_bonus_strength_8"
"Ability12"		"special_bonus_cooldown_reduction_10"
"Ability13"		"special_bonus_attack_speed_30"
"Ability14"		"special_bonus_spell_lifesteal_25"
"Ability15"		"special_bonus_unique_queen_of_pain"
"Ability16"		"special_bonus_unique_queen_of_pain_2"
"Ability17"		"special_bonus_spell_block_18"

modifier_queenofpain_shadow_strike
modifier_queenofpain_scream_of_pain_fear

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'queenofpain')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'queenofpain')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'queenofpain')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'queenofpain')
local talent6 = SafeAbility(bot:GetAbilityByName(sTalentList[6]), 'sTalentList[6]', 'queenofpain')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget


local aetherRange = 0


local bAttacking
local nLV, nKeepMana, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()
	
	if Fu.CanNotUseAbility(bot) or bot:IsInvisible() then return end

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
	
	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, true)

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWTarget )
		return;
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, true)

		if bot:HasScepter()
		and castQTarget ~= nil
		then
			bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQTarget:GetLocation() )
			return
		end

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return;
	end

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, true)

		bot:ActionQueue_UseAbilityOnLocation( abilityR, castRTarget )
		return;

	end

	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, true)

		bot:ActionQueue_UseAbility( abilityE )
		return;
	end
	

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityQ:GetLevel()
	local nCastRange  = abilityQ:GetCastRange()
	local nCastPoint  = abilityQ:GetCastPoint()
	local nManaCost   = abilityQ:GetManaCost()
	
	local nDamage = 75 + 125 * nSkillLV
	
	local nDamageType = DAMAGE_TYPE_MAGICAL 
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 20 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 100 )
	local hCastTarget = nil
	local sCastMotive = nil


	for _, npcEnemy in pairs( nInBonusEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and not npcEnemy:HasModifier( 'modifier_queenofpain_shadow_strike' )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.CanKillTarget( npcEnemy, nDamage , nDamageType )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'Q-击杀'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	
	end
	
	

	if Fu.IsGoingOnSomeone( bot ) or (Fu.IsLaning( bot ) and Fu.IsAllowedToSpam(bot, nManaCost))
	then
	
		if Fu.IsValidHero( botTarget )
			and not botTarget:HasModifier( 'modifier_queenofpain_shadow_strike' )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and Fu.CanCastOnTargetAdvanced( botTarget )
		then			
			hCastTarget = botTarget
			sCastMotive = 'Q-先手'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
		
		
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do 
			if Fu.IsValid( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_queenofpain_shadow_strike' )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'Q-标'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end	
		
	end
			
	
	

	if Fu.IsRetreating( bot )
--		and bot:WasRecentlyDamagedByAnyHero( 5.0 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.IsInRange( bot, npcEnemy, nCastRange - 100 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'Q-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	
	

	if Fu.IsFarming( bot )
		-- and DotaTime() > 4 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nCastRange )

		local targetCreep = Fu.GetMostHpUnit( creepList )

		if Fu.IsValid( targetCreep )
			and #creepList >= 2 
			and not Fu.IsOtherAllysTarget( targetCreep )
			and targetCreep:GetMagicResist() < 0.4
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 5, DAMAGE_TYPE_PHYSICAL )
		then
			hCastTarget = targetCreep
			sCastMotive = 'Q-打野:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan( botTarget )
		and Fu.IsInRange( botTarget, bot, nCastRange )
		and Fu.CanBeAttacked(botTarget)
		and bAttacking
		and not botTarget:HasModifier('modifier_roshan_spell_block')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, nCastRange )
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() 
		or bot:IsRooted()
		or bot:HasModifier( "modifier_bloodseeker_rupture" )
	then return 0 end
	
	local nSkillLV    = abilityW:GetLevel() 
	local nCastRange  = 1000 + nSkillLV * 75
	local nAttackRange  = bot:GetAttackRange()
	local nCastPoint  = abilityW:GetCastPoint()
	local nManaCost   = abilityW:GetManaCost()
	local nDamage     = abilityW:GetAbilityDamage()
	local ScreamOfPainDamage     = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local hCastTarget = nil
	local sCastMotive = nil
	

	if Fu.IsStuck( bot )
	then
		hCastTarget = Fu.GetEscapeLoc()
		sCastMotive = 'W-被卡住'
		return BOT_ACTION_DESIRE_ABSOLUTE, hCastTarget, sCastMotive
	end
	

	if Fu.IsRetreating( bot ) 
		or ( bot:GetActiveMode() == BOT_MODE_RETREAT and nHP < 0.2 and bot:DistanceFromFountain() > 1100 )
	then
		if Fu.ShouldEscape( bot ) 
			or ( bot:DistanceFromFountain() > 600 and  bot:DistanceFromFountain() < 3800 )
		then
			hCastTarget = Fu.GetEscapeLoc()
			sCastMotive = 'W-逃跑'
			return BOT_ACTION_DESIRE_ABSOLUTE, hCastTarget, sCastMotive
		end
	end
	
	

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 500 )
			and not Fu.IsInRange( bot, botTarget, nAttackRange + 50 )
			and Fu.CanCastOnMagicImmune( botTarget )
			and not botTarget:IsAttackImmune()
		then
			local enemyList = Fu.GetNearbyHeroes(botTarget,  1100, false, BOT_MODE_NONE )
			local allyList = Fu.GetNearbyHeroes(botTarget,  1000, true, BOT_MODE_NONE )
			local aliveEnemyCount = Fu.GetNumOfAliveHeroes( true )
			
			if aliveEnemyCount <= 1
				or #enemyList <= 1
				or #enemyList < #allyList
				or Fu.WillKillTarget( botTarget, bot:GetAttackDamage() * 2, DAMAGE_TYPE_PHYSICAL, 2.0 )
			then
			
				hCastTarget = Fu.Site.GetXUnitsTowardsLocation( botTarget, bot:GetLocation(), 330 )
				sCastMotive = 'W-进攻:'..Fu.Chat.GetNormName( botTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				
			end		
		end	
	end
	
	

	local nEnemysTowers = bot:GetNearbyTowers( 1600, true )
	if ( bot:GetActiveMode() == BOT_MODE_LANING or nLV <= 7 )
		and #hEnemyList == 0 and #nEnemysTowers == 0 and DotaTime() < 12 * 60
	then
		
		if nMP > 0.96
			and bot:DistanceFromFountain() > 60
			and bot:DistanceFromFountain() < 6000
			and bot:GetAttackTarget() == nil
			and bot:GetActiveMode() == BOT_MODE_LANING
		then
			local nLane = bot:GetAssignedLane()
			local nLaneFrontLocation = GetLaneFrontLocation( GetTeam(), nLane, 0 )
			local nDist = GetUnitToLocationDistance( bot, nLaneFrontLocation )

			if nDist > 2000
			then
				local location = Fu.Site.GetXUnitsTowardsLocation( bot, nLaneFrontLocation, nCastRange )
				if IsLocationPassable( location )
				then
					hCastTarget = location
					sCastMotive = 'W-对线赶路'
					
					if Fu.IsValidHero(bot:GetTarget())
					then
						if Fu.CanKillTarget( bot:GetTarget(), ScreamOfPainDamage, DAMAGE_TYPE_MAGICAL ) and abilityE.IsFullyCastable()
						then
							return BOT_ACTION_DESIRE_VERYHIGH
						end
					end
					
					return BOT_ACTION_DESIRE_MODERATE, hCastTarget, sCastMotive
				end
			end
		end
	end
	


	if Fu.IsFarming( bot ) and nLV >= 6
	then
		if botTarget ~= nil and botTarget:IsAlive()
			and not Fu.IsInRange( bot, botTarget, 900 )
			and Fu.IsInRange( bot, botTarget, 1600 )
			--and ( nLV > 11 or not botTarget:IsAncientCreep() )
		then
			hCastTarget = botTarget:GetLocation()
			sCastMotive = 'W-打钱赶路'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end

	

	local nAttackAllys = Fu.GetNearbyHeroes(bot, 1600, false, BOT_MODE_ATTACK )
	if #hEnemyList == 0 
		and not bot:WasRecentlyDamagedByAnyHero( 3.0 ) 
		and nLV >= 9
		and #nAttackAllys == 0 
		and #hAllyList <= 3
		--and abilityE:IsFullyCastable()
		and ( botTarget ~= nil and not botTarget:IsHero() )
	then
		local nAOELocation = bot:FindAoELocation( true, false, bot:GetLocation(), 1400, 400, 0, 0 )
		local nLaneCreeps = bot:GetNearbyLaneCreeps( 1400, true )
		if nAOELocation.count >= 3
			and #nLaneCreeps >= 3
		then
			local bCenter = Fu.GetCenterOfUnits( nLaneCreeps )
			local bDist = GetUnitToLocationDistance( botTarget, bCenter )
			
			if bDist <= 500
				and IsLocationPassable( bCenter )
				and IsLocationVisible( bCenter )
				and GetUnitToLocationDistance( bot, bCenter ) >= 700
			then
				hCastTarget = bCenter
				sCastMotive = 'W-跳兵堆'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityE:GetLevel()
	local nCastRange  = abilityE:GetCastRange()
	local nCastPoint  = abilityE:GetCastPoint()
	local nRadius  = abilityE:GetSpecialValueInt( 'area_of_effect' )
	local nManaCost   = abilityE:GetManaCost()
	local nDamage = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nRadius - 30 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nRadius + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	

	for _, npcEnemy in pairs( nInRangeEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanKillTarget( npcEnemy, nDamage, nDamageType )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'E-击杀'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	
	end
		
	

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nRadius - 20 )
			and Fu.CanCastOnMagicImmune( botTarget )			
		then			
			hCastTarget = botTarget
			sCastMotive = 'E-攻击'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	

	if Fu.IsInTeamFight( bot, 1000 )
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInRangeEnemyList )
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
			sCastMotive = 'E-团战AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	

	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'E-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	

	if Fu.IsLaning( bot ) and Fu.IsAllowedToSpam(bot, nManaCost)
	then
		local nCanKillMeleeCount = 0
		local nCanKillRangedCount = 0
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nRadius, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and not Fu.IsOtherAllysTarget( creep )
			then
				local lastHitDamage = nDamage
				local nDelay = nCastPoint + GetUnitToUnitDistance( bot, creep )/900
						
				if Fu.WillKillTarget( creep, lastHitDamage, nDamageType, nDelay )
				then
					if Fu.IsKeyWordUnit( 'ranged', creep )
					then
						nCanKillRangedCount = nCanKillRangedCount + 1
					end

					if Fu.IsKeyWordUnit( 'melee', creep )
					then
						nCanKillMeleeCount = nCanKillMeleeCount + 1
					end

				end
			end
		end

		if nCanKillMeleeCount + nCanKillRangedCount >= 3
		then
			return BOT_ACTION_DESIRE_HIGH, bot, 'E对线1'
		end

		if nCanKillRangedCount >= 1 and nCanKillMeleeCount >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, bot, 'E对线2'
		end

		if #hLaneCreepList == 0
			and Fu.IsValidHero( nInRangeEnemyList[1] )
			and Fu.CanCastOnNonMagicImmune( nInRangeEnemyList[1] )
			and nMP > 0.5
		then
			return BOT_ACTION_DESIRE_HIGH, bot, 'E消耗'	
		end
	end
	

	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and #hAllyList <= 3
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nRadius , true )
		if ( #laneCreepList >= 4 or ( #laneCreepList >= 3 and nMP > 0.82 ) )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then			
			hCastTarget = creep
			sCastMotive = 'E-带线AOE'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	

	if Fu.IsFarming( bot )
	and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius )

		if #creepList >= 2
			and Fu.IsValid( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'E-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	    end
	end
	
	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan( botTarget )
		and Fu.IsInRange( botTarget, bot, nRadius )
		and Fu.CanBeAttacked(botTarget)
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, nRadius )
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityR:GetLevel()
	local nCastRange  = abilityR:GetCastRange()
	local nCastPoint  = abilityR:GetCastPoint()
	local nManaCost   = abilityR:GetManaCost()
	local nDamage     = abilityR:GetSpecialValueInt( 'damage' )
	
	local nRadius = abilityR:GetSpecialValueInt( 'final_aoe' ) * 0.88
	
	if bot:HasScepter() then nDamage = abilityR:GetSpecialValueInt( 'damage_scepter' ) end
	
	local nDamageType = DAMAGE_TYPE_PURE
	
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--团战AOE
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius, 2 )
		if nAoeLoc ~= nil
		then
			hCastTarget = nAoeLoc
			sCastMotive = 'R-团战AOE'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + nRadius * 0.5 )
			and Fu.CanCastOnMagicImmune( botTarget )
		then
			local nearbyEnemyList = Fu.GetNearbyHeroes(botTarget,  nRadius, false, BOT_MODE_NONE )
			if Fu.CanKillTarget( botTarget, nDamage * 1.3, nDamageType )
				or #nearbyEnemyList >= 2
			then
				local nTargetLocation = Fu.GetCastLocation( bot, botTarget, nCastRange, nRadius )
				if nTargetLocation ~= nil
				then
					hCastTarget = nTargetLocation
					sCastMotive = 'R-攻击目标:'..Fu.Chat.GetNormName( botTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end	
		end
	end
	
	
	--撤退时保护团队
	if Fu.IsRetreating( bot ) 
		and #hAllyList >= 2
		and #hEnemyList >= 2
		and bot:WasRecentlyDamagedByAnyHero( 3.0 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )				
			then
				hCastTarget = npcEnemy:GetExtrapolatedLocation( nCastPoint )
				sCastMotive = 'R-保护团队撤退'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end	
	end
	
	
	--带线AOE
	-- local laneCreepList = bot:GetNearbyLaneCreeps( 1400, true )
	-- if bot:HasScepter() and #hEnemyList == 0
	-- 	and #laneCreepList >= 12
	-- 	and Fu.IsAllowedToSpam( bot, nManaCost )
	-- 	and ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
	-- then
	-- 	local locationAoEHurt = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange - 50 , nRadius + 50 , 0, 0 )
	-- 	if locationAoEHurt.count >= 11
	-- 	then
	-- 		hCastTarget = locationAoEHurt.targetloc
	-- 		sCastMotive = 'R-清兵'
	-- 		return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	-- 	end
	-- end
	
	
	return BOT_ACTION_DESIRE_NONE
	
	
end


return X

