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
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,2,2,2,6,3,3,3,6},--pos2
						{2,1,2,3,2,6,2,1,1,1,6,3,3,3,6},--pos4,5
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_2' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_4' then nAbilityBuildList = tAllAbilityBuildList[2] end
if sRole == 'pos_5' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)
if sRole == 'pos_2' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList) end
if sRole == 'pos_4' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList) end
if sRole == 'pos_5' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList) end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",

	"item_bottle",
	"item_magic_wand",
	"item_arcane_boots",
	"item_phylactery",
	"item_aghanims_shard",
	"item_kaya_and_sange",--
	"item_travel_boots",
	"item_black_king_bar",--
	"item_ultimate_scepter",
	"item_angels_demise",--
	"item_octarine_core",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
	"item_mage_outfit",
	"item_soul_ring",
	"item_glimmer_cape",--
	"item_aghanims_shard",
	"item_kaya_and_sange",--
	"item_shivas_guard",--
	"item_cyclone",
	"item_ultimate_scepter",
	"item_sheepstick",--
	"item_wind_waker",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_octarine_core",--
}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",

	"item_magic_wand",
	"item_arcane_boots",
	"item_phylactery",
	"item_aghanims_shard",
	"item_kaya_and_sange",--
	"item_travel_boots",
	"item_black_king_bar",--
	"item_ultimate_scepter",
	"item_angels_demise",--
	"item_octarine_core",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = {
	"item_priest_outfit",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_aghanims_shard",
	"item_guardian_greaves",--
	"item_spirit_vessel",--
--	"item_wraith_pact",
	"item_ultimate_scepter",
	"item_shivas_guard",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_sheepstick",--
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",--
	"item_pipe",--
	"item_boots_of_bearing",--
    "item_ultimate_scepter",
	"item_cyclone",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_sheepstick",--
	'item_wind_waker',
	"item_moon_shard",
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
		and hMinionUnit:GetUnitName() ~= 'npc_dota_zeus_cloud'
	then
		Minion.IllusionThink( hMinionUnit )
	end

end

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityD = bot:GetAbilityByName( sAbilityList[4] )
local abilityAS = bot:GetAbilityByName( sAbilityList[5] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )

local talent5 = bot:GetAbilityByName( sTalentList[5] )
local talent7 = bot:GetAbilityByName( sTalentList[7] )
local talent8 = bot:GetAbilityByName( sTalentList[8] )

local castQDesire, castQTarget
local castWDesire, castWTarget
local castW2Desire, castWLocation
local castDDesire, castDLocation
local castRDesire
local castEDesire, castETarget


local nKeepMana, nMP, nHP, nLV, hEnemyHeroList
local aetherRange = 0
local talentDamage = 0


local abilityASBonus = 0


local botTarget
function X.SkillsComplement()


	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	talentDamage = 0
	abilityASBonus = 0
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	nManaPercentage = ctx.mp
	nHealthPercentage = ctx.hp
	hEnemyHeroList = ctx.enemies
	if abilityAS:IsTrained() then abilityASBonus = 0.09 end
	if talent8:IsTrained() then talentDamage = talentDamage + talent8:GetSpecialValueInt( "value" ) end

	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end

	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )
		
		
		if talent7:IsTrained() 
		then
			bot:ActionQueue_UseAbilityOnLocation( abilityW, castWTarget:GetLocation() )
		else
			bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		end
		
		return
	end

	castW2Desire, castWLocation = X.ConsiderW2()
	if ( castW2Desire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWLocation )
		return
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end

	castDDesire, castDLocation = X.ConsiderD()
	if ( castDDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityD, castDLocation )
		return
	end
	
	castEDesire = X.ConsiderE()
	if ( castEDesire > 0 )
	then
	
		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityE )
		return

	end

end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable() then	return BOT_ACTION_DESIRE_NONE, nil	end

	local nCastRange = abilityQ:GetCastRange()
	local nCastPoint = abilityQ:GetCastPoint()
	local manaCost = abilityQ:GetManaCost()
	local nRadius = abilityQ:GetSpecialValueInt( "radius" )
	local nDamage = abilityQ:GetSpecialValueInt( "arc_damage" )
	local nEnemyHeroesInSkillRange = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	for _, npcEnemy in pairs( nEnemyHeroesInSkillRange )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.GetHP( npcEnemy ) <= 0.2
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy
		end
	end


	--对线期的使用
	if bot:GetActiveMode() == BOT_MODE_LANING
	then
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 50, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsEnemyTargetUnit( creep, 1400 )
				and Fu.WillKillTarget( creep, nDamage, DAMAGE_TYPE_MAGICAL, nCastPoint )
			then
				return BOT_ACTION_DESIRE_HIGH, creep
			end
		end

	end


	if Fu.IsRetreating( bot ) and bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		local target = Fu.GetVulnerableWeakestUnit( bot, true, true, nCastRange )
		if target ~= nil
			and Fu.CanCastOnTargetAdvanced( target )
			and bot:IsFacingLocation( target:GetLocation(), 45 )
		then
			return BOT_ACTION_DESIRE_HIGH, target
		end
	end

	if Fu.IsInTeamFight( bot, 1300 )
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
		if ( locationAoE.count >= 2 ) then
			local target = Fu.GetVulnerableUnitNearLoc( bot, true, true, nCastRange, nRadius, locationAoE.targetloc )
			if target ~= nil and Fu.CanCastOnTargetAdvanced( target ) then
				return BOT_ACTION_DESIRE_HIGH, target
			end
		end
	end

	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) ) and Fu.IsAllowedToSpam( bot, manaCost )
	then
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
		if ( locationAoE.count >= 3 ) then
			local target = Fu.GetVulnerableUnitNearLoc( bot, false, true, nCastRange, nRadius, locationAoE.targetloc )
			if target ~= nil then
				return BOT_ACTION_DESIRE_HIGH, target
			end
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		local target = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( target )
			and Fu.CanCastOnNonMagicImmune( target )
			and Fu.CanCastOnTargetAdvanced( target )
			and Fu.IsInRange( target, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, target
		end
	end

	--Farming: use Arc Lightning on neutral/lane creeps
	if Fu.IsFarming( bot ) and Fu.GetManaAfter( manaCost ) > 0.3
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nCastRange )
		if #nNeutralCreeps >= 2
			or ( #nNeutralCreeps >= 1 and Fu.IsValid( nNeutralCreeps[1] ) and nNeutralCreeps[1]:IsAncientCreep() )
		then
			return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]
		end
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange, true )
		if #nLaneCreeps >= 3
		then
			return BOT_ACTION_DESIRE_HIGH, nLaneCreeps[1]
		end
	end

	--Roshan: use Arc Lightning on Roshan
	if Fu.IsDoingRoshan( bot )
	then
		local botTarget = Fu.GetProperTarget( bot )
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.GetManaAfter( manaCost ) > 0.3
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderW()

	if not abilityW:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE, nil end

	local nCastRange = abilityW:GetCastRange()
	local nCastPoint = abilityW:GetCastPoint()
	local manaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage() * ( 1 + bot:GetSpellAmp() )

	if Fu.IsRetreating( bot ) and bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		local target = Fu.GetVulnerableWeakestUnit( bot, true, true, nCastRange )
		if target ~= nil and Fu.CanCastOnTargetAdvanced( target ) then
			return BOT_ACTION_DESIRE_HIGH, target
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		local target = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( target )
			and Fu.CanCastOnNonMagicImmune( target )
			and Fu.CanCastOnTargetAdvanced( target )
			and Fu.IsInRange( target, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, target
		end
	end

	local targetRanged = X.GetRanged( bot, nCastRange )
	if targetRanged ~= nil
		and targetRanged:GetHealth() < targetRanged:GetActualIncomingDamage( nDamage + targetRanged:GetHealth() * abilityASBonus , DAMAGE_TYPE_MAGICAL )
	then
		return BOT_ACTION_DESIRE_HIGH, targetRanged
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderW2()

	if not abilityW:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = abilityW:GetCastRange()
	local nCastPoint = abilityW:GetCastPoint()
	local manaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nRadius = 325

	local nAllies = Fu.GetNearbyHeroes(bot, 800, false, BOT_MODE_NONE )

	local nEnemyHeroesInSkillRange = Fu.GetNearbyHeroes(bot, nCastRange + nRadius, true, BOT_MODE_NONE )
	local nWeakestEnemyHeroInSkillRange = Fu.GetVulnerableWeakestUnit( bot, true, true, nCastRange + nRadius )
	local nCanKillHeroLocationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius , 0.3, nDamage )

	if nCanKillHeroLocationAoE.count >= 1
	then
		if Fu.IsValid( nWeakestEnemyHeroInSkillRange )
		then
			local nTargetLocation = Fu.GetCastLocation( bot, nWeakestEnemyHeroInSkillRange, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation
			end
		end
	end

	for _, npcEnemy in pairs( nEnemyHeroesInSkillRange )
	do
		if Fu.IsValid( npcEnemy )
			and npcEnemy:IsChanneling()
			and not npcEnemy:IsMagicImmune()
		then
			local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation
			end
		end
	end

	if bot:GetActiveMode() == BOT_MODE_RETREAT
		and ( bot:WasRecentlyDamagedByAnyHero( 2.0 ) or #nAllies >= 3 )
	then
		local nCanHurtHeroLocationAoENearby = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange -200, nRadius -20, 0.8, 0 )
		if nCanHurtHeroLocationAoENearby.count >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoENearby.targetloc
		end
	end


	if bot:GetActiveMode() ~= BOT_MODE_RETREAT
	then
		local npcEnemy = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and GetUnitToUnitDistance( npcEnemy, bot ) <= nRadius + nCastRange
		then

			if nManaPercentage > 0.65
				or bot:GetMana() > nKeepMana * 2
			then
				local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation
				end
			end

			if npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.45 or #nAllies >= 3
			then
				local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation
				end
			end

		end

		local npcEnemy = nWeakestEnemyHeroInSkillRange
		if Fu.IsValid( npcEnemy ) and DotaTime() > 0
			and ( npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.4 or bot:GetMana() > nKeepMana * 2.3 or #nAllies >= 3 )
			and GetUnitToUnitDistance( npcEnemy, bot ) <= nRadius + nCastRange
		then
			local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderD()

	if not bot:HasScepter()
		or not abilityD:IsFullyCastable()
		or bot:IsInvisible()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local numPlayer =  GetTeamPlayers( GetTeam() )
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember( i )
		if Fu.IsValid( member )
			and Fu.IsGoingOnSomeone( member )
		then
			local target = Fu.GetProperTarget( member )
			if Fu.IsValidHero( target )
				and Fu.IsInRange( member, target, 1200 )
				and Fu.CanCastOnNonMagicImmune( target )
			then
				return BOT_ACTION_DESIRE_HIGH, target:GetExtrapolatedLocation( 1.0 )
			end
		end
	end

	--撤退时
	if Fu.IsRetreating( bot )
	then
		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( Fu.IsValid( npcEnemy ) and bot:WasRecentlyDamagedByHero( npcEnemy, 1.0 ) and Fu.CanCastOnNonMagicImmune( npcEnemy ) )
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderR()

	if not abilityR:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE
	end

	local nCastRange = 1600
	local nCastPoint = abilityR:GetCastPoint()
	local manaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetSpecialValueInt( 'damage' )
	
	if talent5:IsTrained() then nDamage = nDamage + talent5:GetSpecialValueInt('value') end
	
	local nDamageType = DAMAGE_TYPE_MAGICAL


	if Fu.IsRetreating( bot ) and bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		if bot:GetRespawnTime() > abilityR:GetCooldown()
			and nHealthPercentage <= 0.28
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsInTeamFight( bot, 1400 )
	then
		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, 1400, true, BOT_MODE_NONE )
		local nInvUnit = Fu.GetInvUnitCount( false, tableNearbyEnemyHeroes )
		if nInvUnit >= 5 then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	-- modifier_warlock_fatal_bonds
	local lowHPCount = 0
	local fatalCount = 0
	local fatalBonus = false
	local gEnemies = GetUnitList( UNIT_LIST_ENEMY_HEROES )
	for _, e in pairs ( gEnemies )
	do
		if e ~= nil
			and Fu.CanCastOnNonMagicImmune( e )
		then
			local nEstDamage = nDamage + e:GetHealth() * abilityASBonus
			if Fu.WillMagicKillTarget( bot, e, nEstDamage, nCastPoint )
				and not Fu.IsOtherAllyCanKillTarget( bot, e )
			then
				lowHPCount = lowHPCount + 1
			end

			if e:HasModifier( "modifier_warlock_fatal_bonds" )
			then
				fatalCount = fatalCount + 1
				if e:GetHealth() <= e:GetActualIncomingDamage( nEstDamage * 2.28, nDamageType )
				then
					fatalBonus = true
				end
			end
		end
	end
	if lowHPCount >= 1
		or ( fatalCount >= 3 and fatalBonus == true )
	then
		return BOT_ACTION_DESIRE_MODERATE
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.GetRanged( bot, nRadius )
	local mode = bot:GetActiveMode()
	local enemys = Fu.GetNearbyHeroes(bot, 1400, true, BOT_MODE_NONE )
	local allies = Fu.GetNearbyHeroes(bot, 800, false, BOT_MODE_NONE )

	if mode == BOT_MODE_TEAM_ROAM
		or mode == BOT_MODE_ATTACK
		or mode == BOT_MODE_DEFEND_ALLY
		or mode == BOT_MODE_RETREAT
		or #enemys >= 1
		or #allies >= 3
		or nManaPercentage <= 0.15
		or bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		return nil
	end

	if mode == BOT_MODE_LANING or nManaPercentage >= 0.56
	then
		local nTowers = bot:GetNearbyTowers( 1600, false )
		if nTowers[1] ~= nil
		then
			local nTowerTarget = nTowers[1]:GetAttackTarget()
			if Fu.IsValid( nTowerTarget )
				and not nTowerTarget:HasModifier( 'modifier_fountain_glyph' )
				and Fu.IsKeyWordUnit( "ranged", nTowerTarget )
				and GetUnitToUnitDistance( nTowerTarget, bot ) <= 1400
				and not Fu.IsAllysTarget( nTowerTarget )
			then
				return nTowerTarget
			end
		end

		if nManaPercentage > 0.4 and bot:GetMana() > 400
		then
			local nLaneCreeps = bot:GetNearbyLaneCreeps( 990, true )
			for _, creep in pairs( nLaneCreeps )
			do
				if Fu.IsValid( creep )
					and Fu.IsKeyWordUnit( "ranged", creep )
					and not creep:HasModifier( 'modifier_fountain_glyph' )
					and not Fu.IsAllysTarget( creep )
					and creep:GetHealth() < bot:GetAttackDamage()
				then
					return creep
				end
			end
		end
	end

	return nil

end


function X.ConsiderE()

	if not abilityE:IsFullyCastable() 
		or bot:IsRooted()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nJumpDistance = 450
	local nSkillLV = abilityE:GetLevel()
	local nCastRange = 600 + nSkillLV * 100
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()

	local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	

	if Fu.IsRetreating( bot )
	then
		if Fu.IsRunning( bot )
		then
			local targetHero = tableNearbyEnemyHeroes[1]
			if Fu.IsValidHero( targetHero )
				and Fu.CanCastOnNonMagicImmune( targetHero )
				and not bot:IsFacingLocation( targetHero:GetLocation(), 120 )
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end
	
	

	if Fu.IsGoingOnSomeone( bot )
	then
		local targetHero = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( targetHero )
			and Fu.IsInRange( bot, targetHero, nCastRange )
			and Fu.CanCastOnNonMagicImmune( targetHero )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	
	return BOT_ACTION_DESIRE_NONE

end


return X