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
							['t20'] = {0, 10},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						},
						{--pos4,5
							['t25'] = {10, 0},
							['t20'] = {0, 10},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						}
}

local tAllAbilityBuildList = {
						{2,1,3,1,1,6,1,3,3,3,6,2,2,2,6},--pos2
						{1,3,1,2,1,6,1,3,3,3,6,2,2,2,6},--pos4,5
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_2' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_4' then nAbilityBuildList = tAllAbilityBuildList[2] end
if sRole == 'pos_5' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
if sRole == 'pos_2' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_4' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end
if sRole == 'pos_5' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_enchanted_mango",

	"item_bottle",
	"item_magic_wand",
	"item_power_treads",
	"item_double_null_talisman",
	"item_witch_blade",
	"item_force_staff",
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_hurricane_pike",--
	"item_devastator",--
	"item_sheepstick",--
	"item_bloodthorn",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_enchanted_mango",

	"item_power_treads",
	"item_magic_wand",
	"item_witch_blade",
    "item_force_staff",
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_black_king_bar",--
	"item_sheepstick",--
	"item_devastator",--
	"item_travel_boots",
	"item_orchid",
	"item_bloodthorn",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {
	"item_crystal_maiden_outfit",
	"item_dragon_lance",
	"item_witch_blade",
	"item_hurricane_pike",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_orchid",
	"item_bloodthorn",--
	"item_devastator",--
	"item_sheepstick",--
	"item_moon_shard",
	"item_travel_boots",
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_enchanted_mango",
	"item_enchanted_mango",
	"item_blood_grenade",

	"item_arcane_boots",
	"item_magic_wand",
	"item_force_staff",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
	"item_aghanims_shard",
	"item_hurricane_pike",--
	"item_refresher",--
	"item_orchid",
	"item_bloodthorn",--
	"item_sheepstick",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_enchanted_mango",
	"item_enchanted_mango",
	"item_blood_grenade",

	"item_tranquil_boots",
	"item_magic_wand",
	"item_force_staff",
	"item_glimmer_cape",--
	"item_pipe",
	"item_boots_of_bearing",--
    "item_pavise",
    "item_solar_crest",--
	"item_aghanims_shard",
	"item_hurricane_pike",--
	"item_sheepstick",--
	"item_orchid",
	"item_bloodthorn",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_shivas_guard",
	"item_magic_wand",

	"item_sheepstick",
	"item_magic_wand",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_priest' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )


X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local abilityQ = SafeAbility(bot:GetAbilityByName('silencer_curse_of_the_silent'), 'silencer_curse_of_the_silent', 'silencer')
local abilityW = SafeAbility(bot:GetAbilityByName('silencer_glaives_of_wisdom'), 'silencer_glaives_of_wisdom', 'silencer')
local abilityE = SafeAbility(bot:GetAbilityByName('silencer_last_word'), 'silencer_last_word', 'silencer')
local abilityR = SafeAbility(bot:GetAbilityByName('silencer_global_silence'), 'silencer_global_silence', 'silencer')

local talent20Left = nil

local castQDesire, castQLocation = 0
local castWDesire, castWTarget = 0
local castEDesire, castETarget = 0
local castRDesire = 0

local nKeepMana, nMP, nHP, nLV, hEnemyHeroList
local aetherRange = 0

local botTarget
function X.SkillsComplement()
	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	talent20Left = SafeAbility(bot:GetAbilityByName('special_bonus_unique_silencer_4'), 'special_bonus_unique_silencer_4', 'silencer')

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 300
	aetherRange = ctx.aetherRange
	nMP = ctx.mp
	nHP = ctx.hp
	nLV = ctx.level
	hEnemyHeroList = ctx.enemies


	castRDesire			 = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end

	castQDesire, castQLocation = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQLocation )
		return
	end

	castEDesire, castETarget, AoE = X.ConsiderE()
	if ( castEDesire > 0 )
	then
		Fu.SetQueuePtToINT( bot, false )
		if AoE then
			bot:ActionQueue_UseAbilityOnLocation(abilityE, castETarget)
		else
			bot:ActionQueue_UseAbilityOnEntity(abilityE, castETarget)
		end
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end


end

function X.ConsiderQ()

	if ( not Fu.CanCastAbility(abilityQ) ) then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = abilityQ:GetSpecialValueInt( 'radius' )
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( "duration" ) * abilityQ:GetSpecialValueInt( "damage" )
	local nSkillLV = abilityQ:GetLevel()							 

	local nEnemysHeroesInRange = bot:GetNearbyHeroes( nCastRange + nRadius, true, BOT_MODE_NONE )
	local nEnemysHeroesInBonus = bot:GetNearbyHeroes( nCastRange + nRadius + 80, true, BOT_MODE_NONE )
	local nEnemysHeroesInView = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE )
	local nWeakestEnemyHeroInRange, nWeakestEnemyHeroInRangeHealth = X.sil_GetWeakestUnit( nEnemysHeroesInRange )
	local nWeakestEnemyHeroInBonus, nWeakestEnemyHeroInBonusHealth = X.sil_GetWeakestUnit( nEnemysHeroesInBonus )

	local nEnemysLaneCreepsInRange = bot:GetNearbyLaneCreeps( nCastRange + nRadius, true )
	local nEnemysLaneCreepsInBonus = bot:GetNearbyLaneCreeps( nCastRange + nRadius + 80, true )
	local nEnemysWeakestLaneCreepsInRange, nEnemysWeakestLaneCreepsInRangeHealth = X.sil_GetWeakestUnit( nEnemysLaneCreepsInRange )
	local nEnemysWeakestLaneCreepsInBonus, nEnemysWeakestLaneCreepsInBonusHealth = X.sil_GetWeakestUnit( nEnemysLaneCreepsInBonus )

	local nTowers = bot:GetNearbyTowers( 1000, true )

	local nCanKillHeroLocationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius , 0, 0.7 * nDamage )
	local nCanHurtHeroLocationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius , 0, 0 )
	local nCanKillCreepsLocationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, nDamage )
	local nCanHurtCreepsLocationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 )


	if nCanHurtCreepsLocationAoE == nil
		or Fu.GetInLocLaneCreepCount( bot, 1600, nRadius, nCanHurtCreepsLocationAoE.targetloc ) <= 2
	then
		 nCanHurtCreepsLocationAoE.count = 0
	end


	if nCanKillHeroLocationAoE.count ~= nil
		and nCanKillHeroLocationAoE.count >= 1
	then
		if Fu.IsValidHero( nWeakestEnemyHeroInBonus )
			and Fu.CanCastOnNonMagicImmune( nWeakestEnemyHeroInBonus )
		then
			local nTargetLocation = Fu.GetCastLocation( bot, nWeakestEnemyHeroInBonus, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation
			end
		end
	end


	if bot:GetActiveMode() == BOT_MODE_LANING
		and nHP >= 0.4
	then
		if nCanHurtHeroLocationAoE.count >= 2
			and Fu.IsValidHero( nWeakestEnemyHeroInBonus )
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoE.targetloc
		end
	end


	if bot:GetActiveMode() == BOT_MODE_RETREAT
	then
		local nCanHurtHeroLocationAoENearby = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange - 300, nRadius, 0.8, 0 )
		if nCanHurtHeroLocationAoENearby.count >= 1
			and Fu.IsValidHero( nWeakestEnemyHeroInBonus )
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoENearby.targetloc
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then

		if nCanHurtHeroLocationAoE.count >= 2
			and GetUnitToLocationDistance( bot, nCanHurtHeroLocationAoE.targetloc ) <= nCastRange
			and Fu.IsValidHero( nWeakestEnemyHeroInBonus )
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoE.targetloc
		end

		local npcEnemy = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
		then

			if nMP > 0.8
				or bot:GetMana() > nKeepMana * 2
			then
				local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation
				end
			end

			if ( npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.4 )
				and GetUnitToUnitDistance( npcEnemy, bot ) <= nRadius + nCastRange
			then
				local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
				if nTargetLocation ~= nil
				then
					return BOT_ACTION_DESIRE_HIGH, nTargetLocation
				end
			end

		end

		npcEnemy = nWeakestEnemyHeroInRange
		if npcEnemy ~= nil and npcEnemy:IsAlive()
			and ( npcEnemy:GetHealth()/npcEnemy:GetMaxHealth() < 0.4 )
			and GetUnitToUnitDistance( npcEnemy, bot ) <= nRadius + nCastRange
		then
			local nTargetLocation = Fu.GetCastLocation( bot, npcEnemy, nCastRange, nRadius )
			if nTargetLocation ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation
			end
		end

		if nCanHurtCreepsLocationAoE.count >= 5
			and nEnemysWeakestLaneCreepsInBonus ~= nil
			and #nEnemysHeroesInBonus <= 0
			and bot:GetActiveMode() ~= BOT_MODE_ATTACK
			and nSkillLV >= 3
			and DotaTime() >= 10 * 60
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtCreepsLocationAoE.targetloc
		end

		if nCanKillCreepsLocationAoE.count >= 3
			and ( nEnemysWeakestLaneCreepsInRange ~= nil or nLV == 25 )
			and #nEnemysHeroesInBonus <= 0
			and bot:GetActiveMode() ~= BOT_MODE_ATTACK
			and nSkillLV >= 3
			and DotaTime() >= 10 * 60
		then
			return BOT_ACTION_DESIRE_HIGH, nCanKillCreepsLocationAoE.targetloc
		end
	end


	if bot:GetActiveMode() ~= BOT_MODE_RETREAT
	then
		if Fu.IsValidHero( nWeakestEnemyHeroInBonus )
		then

			if nCanHurtHeroLocationAoE.count >= 3
				and GetUnitToLocationDistance( bot, nCanHurtHeroLocationAoE.targetloc ) <= nCastRange
			then
				return BOT_ACTION_DESIRE_VERYHIGH, nCanHurtHeroLocationAoE.targetloc
			end

			if nCanHurtHeroLocationAoE.count >= 2
				and GetUnitToLocationDistance( bot, nCanHurtHeroLocationAoE.targetloc ) <= nCastRange
				and bot:GetMana() > nKeepMana
			then
				return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoE.targetloc
			end

			if Fu.IsValidHero( nWeakestEnemyHeroInBonus )
			then
				if nMP > 0.8
					or bot:GetMana() > nKeepMana * 2
				then
					local nTargetLocation = Fu.GetCastLocation( bot, nWeakestEnemyHeroInBonus, nCastRange, nRadius )
					if nTargetLocation ~= nil
					then
						return BOT_ACTION_DESIRE_HIGH, nTargetLocation
					end
				end

				if ( nWeakestEnemyHeroInBonus:GetHealth()/nWeakestEnemyHeroInBonus:GetMaxHealth() <= 0.4 )
					and GetUnitToUnitDistance( nWeakestEnemyHeroInBonus, bot ) <= nRadius + nCastRange
				then
					local nTargetLocation = Fu.GetCastLocation( bot, nWeakestEnemyHeroInBonus, nCastRange, nRadius )
					if nTargetLocation ~= nil
					then
						return BOT_ACTION_DESIRE_HIGH, nTargetLocation
					end
				end
			end
		end
	end


	if bot:GetActiveMode() == BOT_MODE_FARM
		and nSkillLV >= 3
	then

		if nCanKillCreepsLocationAoE.count >= 3
			and nEnemysWeakestLaneCreepsInRange ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nCanKillCreepsLocationAoE.targetloc
		end

		if nCanHurtCreepsLocationAoE.count >= 5
			and nEnemysWeakestLaneCreepsInRange ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtCreepsLocationAoE.targetloc
		end

	end


	if ( bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_TOP or
		 bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_MID or
		 bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_BOT or
		 bot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_TOP or
		 bot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_MID or
		 bot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_BOT )
		and nSkillLV >= 3
		and DotaTime() >= 10 * 60
	then

		if nCanHurtCreepsLocationAoE.count >= 5
			and nEnemysWeakestLaneCreepsInRange ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtCreepsLocationAoE.targetloc
		end

		if nCanKillCreepsLocationAoE.count >= 3
			and nEnemysWeakestLaneCreepsInRange ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nCanKillCreepsLocationAoE.targetloc
		end
	end


	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN )
		and bot:GetMana() >= 600
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget:GetLocation()
		end
	end


	if #nEnemysHeroesInView == 0
		and DotaTime() > 9 * 60
		and bot:GetActiveMode() ~= BOT_MODE_ATTACK
		and nSkillLV > 2
	then

		if nCanKillCreepsLocationAoE.count >= 3
			and ( nEnemysWeakestLaneCreepsInBonus ~= nil or nLV >= 20 )
		then
			return BOT_ACTION_DESIRE_HIGH, nCanKillCreepsLocationAoE.targetloc
		end

		if nCanHurtCreepsLocationAoE.count >= 5
			and nEnemysWeakestLaneCreepsInBonus ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtCreepsLocationAoE.targetloc
		end

	end

	return BOT_ACTION_DESIRE_NONE, 0

end

function X.ConsiderW()

	if not Fu.CanCastAbility(abilityW) or bot:IsDisarmed() then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nAttackRange = bot:GetAttackRange() + 50
	local nAttackDamage = bot:GetAttackDamage()
	local nAbilityDamage = abilityW:GetSpecialValueInt( "intellect_damage_pct" )/100 * bot:GetAttributeValue( ATTRIBUTE_INTELLECT ) * ( 1 + bot:GetSpellAmp() )
	local nCastRange = nAttackRange

	local nTowers = bot:GetNearbyTowers( 900, true )
	local nEnemysLaneCreepsInRange = bot:GetNearbyLaneCreeps( nAttackRange + 100, true )
	local nEnemysLaneCreepsInBonus = bot:GetNearbyLaneCreeps( 400, true )
	local nEnemysWeakestLaneCreepsInRange = Fu.GetVulnerableWeakestUnit( bot, false, true, nAttackRange + 100 )

	local nEnemysHerosInAttackRange = bot:GetNearbyHeroes( nAttackRange, true, BOT_MODE_NONE )
	local nEnemysWeakestHerosInAttackRange = Fu.GetVulnerableWeakestUnit( bot, true, true, nAttackRange )
	local nEnemysWeakestHero = Fu.GetVulnerableWeakestUnit( bot, true, true, nAttackRange + 40 )

	local nAllyLaneCreeps = bot:GetNearbyLaneCreeps( 350, false )

	local npcTarget = Fu.GetProperTarget( bot )

	if( bot:GetActiveMode() ~= BOT_MODE_RETREAT or bot:GetActiveModeDesire() < 0.6 )
	then
		if Fu.IsValidHero( nEnemysWeakestHerosInAttackRange )
		then
			if nEnemysWeakestHerosInAttackRange:GetHealth() <= X.sil_RealDamage( nAttackDamage, nAbilityDamage, nEnemysWeakestHerosInAttackRange )
			then
				return BOT_ACTION_DESIRE_HIGH, WeakestEnemy
			end
		end
	end


	-- if nLV > 9
	-- then
	-- 	if not abilityW:GetAutoCastState()
	-- 	then
	-- 		abilityW:ToggleAutoCast()
	-- 	end
	-- else
	-- 	if abilityW:GetAutoCastState()
	-- 	then
	-- 		abilityW:ToggleAutoCast()
	-- 	end
	-- end

	if nLV <= 9 and nHP > 0.55
		and Fu.IsValidHero( npcTarget )
		and ( not Fu.IsRunning( bot ) or Fu.IsInRange( bot, npcTarget, nAttackRange + 29 ) )
	then
		if not npcTarget:IsAttackImmune()
			and GetUnitToUnitDistance( bot, npcTarget ) < nAttackRange + 99
		then
			nTargetUint = npcTarget
			return BOT_ACTION_DESIRE_HIGH, nTargetUint
		end
	end


	if ( bot:GetActiveMode() == BOT_MODE_LANING and #nTowers == 0 )
	then
		if Fu.IsValid( nEnemysWeakestHero )
		then
			if nHP >= 0.62
				and #nEnemysLaneCreepsInBonus <= 6
				and #nAllyLaneCreeps >= 2
				and not bot:WasRecentlyDamagedByCreep( 1.5 )
				and not bot:WasRecentlyDamagedByAnyHero( 1.5 )
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysWeakestHero
			end


			if Fu.GetAllyUnitCountAroundEnemyTarget( bot, nEnemysWeakestHero, 500 ) >= 3
				and nHP >= 0.6
				and not bot:WasRecentlyDamagedByCreep( 1.5 )
				and not bot:WasRecentlyDamagedByAnyHero( 1.5 )
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysWeakestHero
			end

		end
	end


	if Fu.IsValidHero( npcTarget )
		and GetUnitToUnitDistance( npcTarget, bot ) > nAttackRange + 200
		and Fu.IsValidHero( nEnemysHerosInAttackRange[1] )
		and Fu.CanBeAttacked( nEnemysHerosInAttackRange[1] )
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
	then
		return BOT_ACTION_DESIRE_HIGH, nEnemysHerosInAttackRange[1]
	end


	if npcTarget == nil
		and  bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and  bot:GetActiveMode() ~= BOT_MODE_ATTACK
		and  bot:GetActiveMode() ~= BOT_MODE_ASSEMBLE
		and  Fu.GetTeamFightAlliesCount( bot ) <= 2
	then

		if Fu.IsValid( nEnemysWeakestLaneCreepsInRange )
			and not Fu.IsOtherAllysTarget( nEnemysWeakestLaneCreepsInRange )
		then
			local nCreep = nEnemysWeakestLaneCreepsInRange
			local nAttackProDelayTime = Fu.GetAttackProDelayTime( bot, nCreep )

			local otherAttackRealDamage = Fu.GetTotalAttackWillRealDamage( nCreep, nAttackProDelayTime )
			local silRealDamage = X.sil_RealDamage( nAttackDamage, nAbilityDamage, nCreep )

			if otherAttackRealDamage + silRealDamage > nCreep:GetHealth() + 1
				and not Fu.CanKillTarget( nCreep, nAttackDamage, DAMAGE_TYPE_PHYSICAL )
			then
				--[[
				local nTime = nAttackProDelayTime
				local rMessage = "生命:"..tostring( nCreep:GetHealth() ).."增益:"..tostring( Fu.GetOne( nAbilityDamage ) ).."额外:"..tostring( Fu.GetOne( otherAttackRealDamage ) ).."总共:"
				rMessage = rMessage..tostring( otherAttackRealDamage + silRealDamage )
				Fu.SetBotPrint( rMessage, nCreep:GetLocation(), true, true )
				--]]
				return BOT_ACTION_DESIRE_HIGH, nCreep
			end

		end

		if ( bot:HasScepter() or nAttackDamage > 160 )
			and #hEnemyHeroList == 0
		then
			local nEnemysCreeps = bot:GetNearbyCreeps( 800, true )
			if Fu.IsValid( nEnemysCreeps[1] )
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysCreeps[1]
			end
		end


		local nNeutrals = bot:GetNearbyNeutralCreeps( 800 )
		if DotaTime()%60>52 and DotaTime()%60 < 54.5
			and  Fu.IsValid( nNeutrals[1] )
			and not nNeutrals[1]:WasRecentlyDamagedByAnyHero( 3.0 )
		then
			return BOT_ACTION_DESIRE_HIGH, nNeutrals[1]
		end


		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( 1600 )
		local botMode = bot:GetActiveMode()
		if botMode ~= BOT_MODE_LANING
			and botMode ~= BOT_MODE_FARM
			and botMode ~= BOT_MODE_RUNE
			and botMode ~= BOT_MODE_ASSEMBLE
			and botMode ~= BOT_MODE_SECRET_SHOP
			and botMode ~= BOT_MODE_SIDE_SHOP
			and botMode ~= BOT_MODE_WATCHER
			and botMode ~= BOT_MODE_WARD
			and GetRoshanDesire() < BOT_MODE_DESIRE_HIGH
			and not bot:WasRecentlyDamagedByAnyHero( 2.0 )
			and #hEnemyHeroList == 0
			and nAttackDamage > 140
			and Fu.IsValid( nNeutralCreeps[1] )
			and not Fu.IsRoshan( nNeutralCreeps[1] )
			and ( not nNeutralCreeps[1]:IsAncientCreep() or nAttackDamage > 180 )
		then
			nTargetUint = nNeutralCreeps[1]
			return BOT_ACTION_DESIRE_HIGH, nTargetUint
		end

	end

	if Fu.IsGoingOnSomeone( bot ) and not abilityW:GetAutoCastState()
	then
		if Fu.IsValidHero( npcTarget )
			and not npcTarget:IsAttackImmune()
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nAttackRange + 80 )
		then
			return BOT_ACTION_DESIRE_MODERATE, npcTarget
		end
	end


	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN and not abilityW:GetAutoCastState() )
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nAttackRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil

end

function X.ConsiderE()

	if ( not Fu.CanCastAbility(abilityE) ) then
		return BOT_ACTION_DESIRE_NONE, 0, false
	end


	local nCastRange = Fu.GetProperCastRange(false, bot, abilityE:GetCastRange())
	local nBaseDamage = abilityE:GetSpecialValueInt('damage')
	botTarget = Fu.GetProperTarget(bot)

	local nRadius = 0
	local bAoETalent = talent20Left ~= nil and talent20Left:IsTrained()
	if bAoETalent then nRadius = talent20Left:GetSpecialValueInt('value') end

	local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	for _, enemyHero in pairs (nEnemyHeroes) do
		if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
		and not enemyHero:HasModifier('modifier_ursa_enrage')
        then
			local nDamage = nBaseDamage + math.abs(bot:GetAttributeValue(ATTRIBUTE_INTELLECT) - enemyHero:GetAttributeValue(ATTRIBUTE_INTELLECT))
			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL) then
				if bAoETalent then
					local nLocationAoE = bot:FindAoELocation(true, true, enemyHero:GetLocation(), 0, nRadius, 0, 0)
					if nLocationAoE.count >= 2 then
						return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, true
					else
						return BOT_ACTION_DESIRE_HIGH, enemyHero, false
					end
				else
					return BOT_ACTION_DESIRE_HIGH, enemyHero, false
				end
			end
        end
	end

	if Fu.IsInTeamFight(bot, 1200) then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and not Fu.IsDisabled(enemyHero)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
			and not enemyHero:HasModifier('modifier_ursa_enrage')
			then
				local npcEnemyDamage = enemyHero:GetEstimatedDamageToTarget(false, bot, 3.0, DAMAGE_TYPE_ALL)
				if npcEnemyDamage > nMostDangerousDamage then
					nMostDangerousDamage = npcEnemyDamage
					npcMostDangerousEnemy = enemyHero
				end
			end
		end

		if npcMostDangerousEnemy ~= nil then
			if bAoETalent then
				local nLocationAoE = bot:FindAoELocation(true, true, npcMostDangerousEnemy:GetLocation(), 0, nRadius, 0, 0)
				if nLocationAoE.count >= 2 then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, true
				else
					return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, false
				end
			else
				return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy, false
			end
		end

	end

	if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and not botTarget:HasModifier('modifier_troll_warlord_battle_trance')
		and not botTarget:HasModifier('modifier_ursa_enrage')
        then
			if bAoETalent then
				local nLocationAoE = bot:FindAoELocation(true, true, botTarget:GetLocation(), 0, nRadius, 0, 0)
				if nLocationAoE.count >= 2 then
					return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, true
				else
					return BOT_ACTION_DESIRE_HIGH, botTarget, false
				end
			else
				return BOT_ACTION_DESIRE_HIGH, botTarget, false
			end
        end
    end

	if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			then
				if bAoETalent then
					local nLocationAoE = bot:FindAoELocation(true, true, enemyHero:GetLocation(), 0, nRadius, 0, 0)
					if nLocationAoE.count >= 2 then
						return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, true
					else
						return BOT_ACTION_DESIRE_HIGH, enemyHero, false
					end
				else
					return BOT_ACTION_DESIRE_HIGH, enemyHero, false
				end
			end
		end
	end

	if Fu.IsDoingRoshan(bot) and bot:GetMana() >= 500 then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, false
		end
	end

	if Fu.IsDoingTormentor(bot) and bot:GetMana() >= 500 then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, false
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0, false
end

function X.ConsiderR()


	if ( not Fu.CanCastAbility(abilityR) ) then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1400, true, BOT_MODE_NONE )
	local tableNearbyAllyHeroes = bot:GetNearbyHeroes( 800, false, BOT_MODE_NONE )


	for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if Fu.IsValid( npcEnemy )
			and npcEnemy:IsChanneling()
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and not npcEnemy:HasModifier( "modifier_teleporting" )
			and npcEnemy:GetHealth() > 500
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsRetreating( bot )
	then
		if #tableNearbyEnemyHeroes >= 2
			and #tableNearbyAllyHeroes > 2
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	local numPlayer =  GetTeamPlayers( GetTeam() )
	for i = 1, #numPlayer
	do
		local member =  GetTeamMember( i )
		if member ~= nil and member:IsAlive()
		then
			if Fu.IsInTeamFight( member, 1200 )
			then
				local locationAoE = member:FindAoELocation( true, true, member:GetLocation(), 1400, 600, 0, 0 )
				if ( locationAoE.count >= 2 ) then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		local npcTarget = bot:GetTarget()
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.IsInRange( npcTarget, bot, 1200 )
			and not Fu.IsDisabled( npcTarget )
		then
			local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1600, false, BOT_MODE_NONE )
			if #tableNearbyEnemyHeroes >= 2
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

function X.sil_GetWeakestUnit( nEnemyUnits )

	local nWeakestUnit = nil
	local nWeakestUnitLowestHealth = 10000
	for _, unit in pairs( nEnemyUnits )
	do
		if 	Fu.IsValid(unit)
		and unit:IsAlive()
			and Fu.CanCastOnNonMagicImmune( unit )
			and Fu.CanCastOnTargetAdvanced( unit )
		then
			if unit:GetHealth() < nWeakestUnitLowestHealth
			then
				nWeakestUnitLowestHealth = unit:GetHealth()
				nWeakestUnit = unit
			end
		end
	end

	return nWeakestUnit, nWeakestUnitLowestHealth
end

function X.sil_RealDamage( nAttackDamage, nAbilityDamage, unit )

	local RealDamage = unit:GetActualIncomingDamage( nAttackDamage, DAMAGE_TYPE_PHYSICAL ) + unit:GetActualIncomingDamage( nAbilityDamage, DAMAGE_TYPE_PURE )

	return RealDamage
end


return X
