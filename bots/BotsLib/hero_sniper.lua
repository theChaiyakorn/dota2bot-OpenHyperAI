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
						{2,3,2,3,1,6,1,1,1,2,2,3,6,3,6},--pos1,2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_ranged_carry_outfit",
	"item_dragon_lance",
	"item_mask_of_madness",
	"item_aghanims_shard",
	"item_maelstrom",
    "item_force_staff",
	"item_hurricane_pike",--
	"item_ultimate_scepter",
	"item_travel_boots",
	"item_monkey_king_bar",--
	"item_mjollnir",--
	"item_broken_satanic",--
	"item_moon_shard",
	"item_hydras_breath",--
	"item_skadi",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
	"item_mid_outfit",
	"item_dragon_lance",
	"item_mask_of_madness",
	"item_aghanims_shard",
	"item_maelstrom",
    "item_force_staff",
	"item_hurricane_pike",--
	"item_ultimate_scepter",
	"item_travel_boots",
	"item_monkey_king_bar",--
	"item_mjollnir",--
	"item_broken_satanic",--
	"item_moon_shard",
	"item_hydras_breath",--
	"item_skadi",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_mjollnir",
	"item_magic_wand",

	"item_greater_crit", 
	"item_hand_of_midas",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_sniper

"Ability1"		"sniper_shrapnel"
"Ability2"		"sniper_headshot"
"Ability3"		"sniper_take_aim"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"sniper_assassinate"
"Ability10"		"special_bonus_cooldown_reduction_25"
"Ability11"		"special_bonus_attack_damage_20"
"Ability12"		"special_bonus_attack_speed_40"
"Ability13"		"special_bonus_unique_sniper_5"
"Ability14"		"special_bonus_unique_sniper_3"
"Ability15"		"special_bonus_unique_sniper_4"
"Ability16"		"special_bonus_attack_range_125"
"Ability17"		"special_bonus_unique_sniper_2"

modifier_sniper_shrapnel_charge_counter
modifier_sniper_shrapnel_thinker
modifier_sniper_shrapnel_slow
modifier_sniper_headshot
modifier_sniper_headshot_slow
modifier_sniper_take_aim
modifier_sniper_take_aim_bonus
modifier_sniper_assassinate_caster
modifier_sniper_assassinate

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'sniper')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'sniper')
local abilityAS = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'sniper')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'sniper')


local castQDesire, castQLocation 
local castEDesire 
local castRDesire, castRTarget 
local castASDesire, castASTarget


local nKeepMana, nMP, nHP, nLV, hEnemyHeroList
local lastAbilityQTime = 0
local lastAbilityQLocation = Vector( 0, 0 )
local botTarget

function X.SkillsComplement()


	X.ConsiderTarget()
	Fu.ConsiderForMkbDisassembleMask( bot )

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 280
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyHeroList = ctx.enemies
	hAllyList = ctx.allies

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return

	end

	castEDesire = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		bot:Action_ClearActions( false )

		bot:ActionQueue_UseAbility( abilityE )
		return

	end

	castQDesire, castQLocation = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQLocation )
		lastAbilityQTime = DotaTime()
		lastAbilityQLocation = castQLocation
		return
	end
	
	castASDesire, castASTarget = X.ConsiderAS()
	if ( castASDesire > 0 )
	then
		
		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityAS, castASTarget )
		return

	end


end

function X.ConsiderTarget()
	if not Fu.IsRunning( bot )
		or bot:HasModifier( "modifier_item_hurricane_pike_range" )
	then return  end

	local nAttackRange = bot:GetAttackRange() + 60
	if nAttackRange > 1600 then nAttackRange = 1600 end
	local nInAttackRangeWeakestEnemyHero = Fu.GetAttackableWeakestUnit( bot, nAttackRange, true, true )

	local nTargetUint = nil

	if Fu.IsValidHero( botTarget )
		and GetUnitToUnitDistance( botTarget, bot ) >  nAttackRange
		and Fu.IsValidHero( nInAttackRangeWeakestEnemyHero )
	then
		nTargetUint = nInAttackRangeWeakestEnemyHero
		bot:SetTarget( nTargetUint )
		return
	end

end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable()
		or DotaTime() - lastAbilityQTime < 1.5
	then return 0 end

	local nCastRange = 1600	--abilityQ:GetCastRange()
	local nSkillLV = abilityQ:GetLevel()
	local nDamage = ( 15 + 20 * ( nSkillLV -1 ) ) * 11
	local nRadius = abilityQ:GetAOERadius()
	local nCastPoint = abilityQ:GetCastPoint()
	local botLocation = bot:GetLocation()

	local nEnemysLaneCreepsInSkillRange = bot:GetNearbyLaneCreeps( 1600, true )
	local nEnemysHeroesInSkillRange = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )

	local nCanHurtCreepsLocationAoE = bot:FindAoELocation( true, false, botLocation, nCastRange, nRadius, 0.8, 0 )
	local nCanHurtCreepCount = nCanHurtCreepsLocationAoE.count
	if nCanHurtCreepsLocationAoE == nil
		or Fu.GetInLocLaneCreepCount( bot, 1600, nRadius, nCanHurtCreepsLocationAoE.targetloc ) <= 2	--检查半径内是否真的有小兵
	then
		 nCanHurtCreepCount = 0
	end
	local nCanHurtHeroLocationAoE = bot:FindAoELocation( true, true, botLocation, nCastRange, nRadius-30, 0.8, 0 )

	--对多个敌方英雄使用
	if #nEnemysHeroesInSkillRange >= 2
		and ( nCanHurtHeroLocationAoE.cout ~= nil and nCanHurtHeroLocationAoE.cout >= 2 )
		and bot:GetActiveMode() ~= BOT_MODE_LANING
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or ( bot:GetActiveMode() == BOT_MODE_RETREAT and bot:GetActiveModeDesire() < 0.6 ) )
		and not X.IsAbiltyQCastedHere( nCanHurtHeroLocationAoE.targetloc, nRadius )
	then
		return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoE.targetloc
	end

	--对当前目标英雄使用
	if Fu.IsValidHero( botTarget )
		and not botTarget:HasModifier( "modifier_sniper_shrapnel_slow" )
		and Fu.CanCastOnNonMagicImmune( botTarget )
		and Fu.IsInRange( botTarget, bot, nCastRange + 300 )
		and ( nSkillLV >= 3 or bot:GetMana() >= nKeepMana )
		and not X.IsAbiltyQCastedHere( botTarget:GetLocation(), nRadius )
	then

		if botTarget:IsFacingLocation( Fu.GetEnemyFountain(), 30 )
			and Fu.GetHP( botTarget ) < 0.4
			and Fu.IsRunning( botTarget )
		then
			--追击减速当前目标
			for i=0, 800, 200
			do
				local nCastLocation = Fu.GetLocationTowardDistanceLocation( botTarget, Fu.GetEnemyFountain(), nRadius + 800 - i )
				if GetUnitToLocationDistance( bot, nCastLocation ) <= nCastRange + 200
				then
					return BOT_ACTION_DESIRE_HIGH, nCastLocation
				end
			end
		end

		--对当前目标使用技能
		local npcTargetLocInFuture = Fu.GetCorrectLoc( botTarget, nCastPoint + 1.8 )
		if Fu.GetLocationToLocationDistance( botTarget:GetLocation(), npcTargetLocInFuture ) > 300
			and botTarget:GetMovementDirectionStability() > 0.4
		then
			return BOT_ACTION_DESIRE_HIGH, npcTargetLocInFuture
		end

		--近处预测将到近处来的目标
		local castDistance = GetUnitToUnitDistance( bot, botTarget )
		if botTarget:IsFacingLocation( botLocation, 30 ) and Fu.IsMoving( botTarget )
		then
			if castDistance > 400
			then
				castDistance = castDistance - 200
			end
			return BOT_ACTION_DESIRE_HIGH, Fu.GetUnitTowardDistanceLocation( bot, botTarget, castDistance )
		end

		--远处预测将到远处去的目标
		if bot:IsFacingLocation( botTarget:GetLocation(), 30 )
		then
			if castDistance <= nCastRange - 200
			then
				castDistance = castDistance + 400
			else
				castDistance = nCastRange + 300
			end
			return BOT_ACTION_DESIRE_HIGH, Fu.GetUnitTowardDistanceLocation( bot, botTarget, castDistance )
		end

		--目标位置无规律
		return BOT_ACTION_DESIRE_HIGH, Fu.GetLocationTowardDistanceLocation( botTarget, Fu.GetEnemyFountain(), nRadius/2 )

	end

	--撤退时减速
	if Fu.IsRetreating( bot )
		and not bot:IsInvisible()
	then
		local nCanHurtHeroLocationAoENearby = bot:FindAoELocation( true, true, botLocation, nCastRange - 400, nRadius, 1.5, 0 )
		if nCanHurtHeroLocationAoENearby.count >= 2
			and not X.IsAbiltyQCastedHere( nCanHurtHeroLocationAoENearby.targetloc, nRadius )
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoENearby.targetloc
		end

		if bot:GetActiveModeDesire() > 0.8
		then
			local nEnemyNearby = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE )
			for _, npcEnemy in pairs( nEnemyNearby )
			do
				if Fu.IsValid( npcEnemy )
					and bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
				then
					local nCastLocation = ( botLocation + npcEnemy:GetLocation() )/2
					if not X.IsAbiltyQCastedHere( nCastLocation, nRadius )
					then
						--对特定位置使用技能
						return BOT_ACTION_DESIRE_HIGH, nCastLocation
					end
				end
			end
		end
	end

	if #hEnemyHeroList == 0
		and nSkillLV >= 3
		and bot:GetActiveMode() ~= BOT_MODE_ATTACK
		and bot:GetActiveMode() ~= BOT_MODE_LANING
		and bot:GetMana() >= nKeepMana
		and #nEnemysLaneCreepsInSkillRange >= 2
		and nCanHurtCreepCount >= 5
		and ( nLV < 25 or nCanHurtCreepCount >= 7 )
		and ( nLV < 20 or GetUnitToLocationDistance( bot, nCanHurtCreepsLocationAoE.targetloc ) >= 1100 )
		and not X.IsAbiltyQCastedHere( nCanHurtCreepsLocationAoE.targetloc, nRadius )
	then
		return BOT_ACTION_DESIRE_HIGH, nCanHurtCreepsLocationAoE.targetloc
	end

	if Fu.IsFarming( bot ) and bot:GetMana() >= nKeepMana
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( 800 )
		if #nNeutralCreeps >= 4
			and Fu.IsValid( botTarget )
			and not Fu.CanKillTarget( botTarget, bot:GetAttackDamage() * 3.88 , DAMAGE_TYPE_PHYSICAL )
		then
			local nAoE = bot:FindAoELocation( true, false, botLocation, nCastRange, nRadius, 0.8, 0 )
			if nAoE.count >= 5
			then
				return BOT_ACTION_DESIRE_HIGH, nAoE.targetloc
			end
		end
	end

	if Fu.IsDoingRoshan( bot )
	then
		local nAttackTarget = bot:GetAttackTarget()
		if Fu.IsValid( nAttackTarget )
			and Fu.IsRoshan( nAttackTarget )
			and Fu.IsInRange( nAttackTarget, bot, nCastRange )
			and Fu.GetManaAfter( abilityQ:GetManaCost() ) > 0.4
			and not nAttackTarget:HasModifier( "modifier_sniper_shrapnel_slow" )
			and not X.IsAbiltyQCastedHere( nAttackTarget:GetLocation(), nRadius )
		then
			return BOT_ACTION_DESIRE_HIGH, nAttackTarget:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, nRadius )
        and Fu.IsAttacking(bot)
		and not botTarget:HasModifier( "modifier_sniper_shrapnel_slow" )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	--farming: shrapnel neutral creep camps with 3+ creeps (conserve charges, higher mana threshold)
	if Fu.IsFarming( bot )
		and #hEnemyHeroList == 0
		and Fu.GetManaAfter( abilityQ:GetManaCost() ) > 0.4
		and abilityQ:GetCurrentCharges() >= 2
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nCastRange )
		if #nNeutralCreeps >= 3
		then
			local nFarmAoE = bot:FindAoELocation( true, false, botLocation, nCastRange, nRadius, 0.8, 0 )
			if nFarmAoE.count >= 3
				and not X.IsAbiltyQCastedHere( nFarmAoE.targetloc, nRadius )
			then
				return BOT_ACTION_DESIRE_HIGH, nFarmAoE.targetloc
			end
		end
	end

	return 0
end

-- 7.41: Take Aim now has passive attack range (160/240/320/400)
-- plus an active component that grants bonus range (75/150/225/300) for a duration.
function X.ConsiderE()

	if not abilityE:IsFullyCastable()
		or bot:IsDisarmed()
	then return 0 end

	local nAttackRange = bot:GetAttackRange()
	local nSkillLV = abilityE:GetLevel()
	local nDamage = bot:GetAttackDamage()

	local npcTarget = bot:GetAttackTarget()
	
	if Fu.IsValidHero( npcTarget )
		and not npcTarget:IsAttackImmune()
		and Fu.IsInRange( bot, npcTarget, nAttackRange )
	then
		--低地打高地
		if GetHeightLevel( bot:GetLocation() ) < GetHeightLevel( npcTarget:GetLocation() )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
		
		--增加爆头几率
		if Fu.IsInRange( bot, npcTarget, nAttackRange - 100 )
			and Fu.IsAttacking( bot )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderR()

	if not abilityR:IsFullyCastable() then return 0 end

	local nCastRange = abilityR:GetCastRange()
	local nCastPoint = abilityR:GetCastPoint()
	local nAttackRange = bot:GetAttackRange()
	if nAttackRange > 1550 then nAttackRange = 1550 end
	local nDamage	 = abilityR:GetSpecialValueInt('damage')
	local nSpeed     = abilityR:GetSpecialValueInt('projectile_speed')
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nEnemysHerosCanSeen = GetUnitList( UNIT_LIST_ENEMY_HEROES )
	local nEnemysHerosInAttackRange = Fu.GetNearbyHeroes(bot, math.min(nAttackRange + 50, 1600), true, BOT_MODE_NONE )

	local nTempTarget = nEnemysHerosInAttackRange[1]
	if Fu.IsValidHero( botTarget )
		and Fu.IsInRange( bot, botTarget, nAttackRange + 50 )
	then nTempTarget = botTarget end

	local nWeakestEnemyHeroInCastRange = X.GetWeakestUnitInRangeExRadius( nEnemysHerosCanSeen, nCastRange, nAttackRange -300, bot )
	local nChannelingEnemyHeroInCastRange = X.GetChannelingUnitInRange( nEnemysHerosCanSeen, nCastRange, bot )
	local castRTarget = nil

	-- Kill fleeing low HP enemy outside attack range
	for _, enemy in pairs( nEnemysHerosCanSeen ) do
		local eta = nCastPoint
		if nSpeed > 0 then eta = (GetUnitToUnitDistance(bot, enemy) / nSpeed) + nCastPoint end
		if Fu.IsValidHero( enemy )
		and Fu.CanBeAttacked( enemy )
		and Fu.CanCastOnNonMagicImmune( enemy )
		and Fu.IsInRange( bot, enemy, nCastRange )
		and not Fu.IsInRange( bot, enemy, nAttackRange )
		and Fu.WillMagicKillTarget( bot, enemy, nDamage, eta )
		and not enemy:HasModifier( 'modifier_abaddon_borrowed_time' )
		and not enemy:HasModifier( 'modifier_dazzle_shallow_grave' )
		and not enemy:HasModifier( 'modifier_oracle_false_promise_timer' )
		then
			return BOT_ACTION_DESIRE_HIGH, enemy
		end
	end

	if Fu.IsValid( nWeakestEnemyHeroInCastRange ) then
		local eta = nCastPoint
		if nSpeed > 0 then eta = (GetUnitToUnitDistance(bot, nWeakestEnemyHeroInCastRange) / nSpeed) + nCastPoint end
		if Fu.WillMagicKillTarget( bot, nWeakestEnemyHeroInCastRange, nDamage, eta )
			or ( X.ShouldUseR( nTempTarget, nWeakestEnemyHeroInCastRange, nDamage ) and ( bot:GetMana() > nKeepMana * 1.28 or bot:HasScepter() ) )
		then
			castRTarget = nWeakestEnemyHeroInCastRange
			return BOT_ACTION_DESIRE_HIGH, castRTarget
		end
	end

	if Fu.IsValid( nChannelingEnemyHeroInCastRange )
		and not bot:IsInvisible()
		and not Fu.IsRetreating( bot )
	then
		castRTarget = nChannelingEnemyHeroInCastRange
		return BOT_ACTION_DESIRE_HIGH, castRTarget
	end

	return 0
end

function X.GetWeakestUnitInRangeExRadius( nUnits, nRange, nRadius, bot )
	if nUnits[1] == nil then return nil end

	local nAttackRange = bot:GetAttackRange()
	local nAttackDamage = bot:GetAttackDamage()
	local weakestUnit = nil
	local weakestHealth = 9999
	for _, unit in pairs( nUnits )
	do
		if Fu.IsInRange( unit, bot, nRange )
			and not Fu.IsInRange( unit, bot, nRadius )
			and Fu.CanCastOnNonMagicImmune( unit )
			and not Fu.IsOtherAllyCanKillTarget( bot, unit )
			and unit:GetHealth() < weakestHealth
			and not unit:HasModifier( "modifier_teleporting" )
			and not ( Fu.IsInRange( unit, bot, nAttackRange )
					  and Fu.CanKillTarget( unit, nAttackDamage, DAMAGE_TYPE_PHYSICAL ) )
		then
			weakestUnit = unit
			weakestHealth = unit:GetHealth()
		end
	end

	return weakestUnit
end

function X.GetChannelingUnitInRange( nUnits, nRange, bot )

	if nUnits[1] == nil then return nil end

	local channelingUnit = nil
	for _, unit in pairs( nUnits )
	do
		if Fu.IsInRange( unit, bot, nRange )
			and not unit:IsMagicImmune()
			and unit:IsChanneling()
			and not ( unit:HasModifier( "modifier_teleporting" )
					  and X.GetCastPoint( bot, unit ) > Fu.GetModifierTime( unit, "modifier_teleporting" ) )
		then
			channelingUnit = unit
			break
		end
	end

	return channelingUnit
end

function X.GetCastPoint( bot, unit )

		local nCastTime = abilityR:GetCastPoint()

		local nDist = GetUnitToUnitDistance( bot, unit )
		local nDistTime = nDist/2500

		return nCastTime + nDistTime

end

function X.IsAbiltyQCastedHere( nLoc, nRadius )

	if Fu.GetLocationToLocationDistance( lastAbilityQLocation, nLoc ) > nRadius * 1.14
	then
		return false
	end

	return true
end

--判定是否在不能击杀目标的情况下对目标使用大招
--1, 该目标为队友准备攻击的目标且自己没有攻击范围内的攻击目标
--2, 能与宙斯合力击杀目标

function X.ShouldUseR( nAttackTarget, nEnemy, nDamage )
	if Fu.IsRetreating( bot )
		or ( Fu.IsValidHero( nAttackTarget ) and Fu.CanBeAttacked( nAttackTarget )
			and ( GetUnitToUnitDistance( bot, nAttackTarget ) <= bot:GetAttackRange() -300
					or Fu.CanKillTarget( nAttackTarget, bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL ) ) )
	then
		return false
	end

	if Fu.IsValid( nEnemy )
	then
		local numPlayer =  GetTeamPlayers( GetTeam() )
		for i = 1, #numPlayer
		do
			local member =  GetTeamMember( i )
			if Fu.IsValid( member )
				and member ~= bot
				and GetUnitToUnitDistance( member, nEnemy ) <= 600
				and ( member:IsFacingLocation( nEnemy:GetLocation(), 20 )
						or not ( Fu.IsValidHero( nAttackTarget ) and GetUnitToUnitDistance( bot, nAttackTarget ) <= bot:GetAttackRange() ) )
			then
				return true
			end

			if Fu.IsValid( member )
				and member:GetUnitName() == "npc_dota_hero_zuus"
				and not Fu.CanNotUseAbility( member )
			then
				local zAbility = member:GetAbilityByName( "zuus_thundergods_wrath" )
				if zAbility:IsFullyCastable()
				then
					local zAbilityDamage = zAbility:GetAbilityDamage()
					if nEnemy:GetHealth() + 66 < nEnemy:GetActualIncomingDamage( zAbilityDamage + nDamage, DAMAGE_TYPE_MAGICAL )
					then
						return true
					end
				end
			end
		end
	end

	return false
end


function X.ConsiderAS()

	if not abilityAS:IsTrained()
		or not abilityAS:IsFullyCastable() 
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = 375
	local nCastRange = abilityAS:GetCastRange()
	local nCastPoint = abilityAS:GetCastPoint()
	local nManaCost = abilityAS:GetManaCost()


	if Fu.IsRetreating( bot )
	then
		local enemyHeroList = Fu.GetNearbyHeroes(bot, nRadius, true, BOT_MODE_NONE )
		local targetHero = enemyHeroList[1]
		if Fu.IsValidHero( targetHero )
			and Fu.CanCastOnNonMagicImmune( targetHero )
			and not targetHero:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
		end		
	end
	

	if Fu.IsInTeamFight( bot, 1400 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius, 2 )
		if nAoeLoc ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nAoeLoc
		end		
	end
	

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0

end


return X
