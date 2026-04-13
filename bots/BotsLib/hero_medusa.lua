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
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,1,2,6,1,1,3,3,3,6,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )


local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	'item_tango',
	'item_double_branches',
	'item_null_talisman',
	'item_null_talisman',
	"item_magic_wand",

	"item_ring_of_basilius",
	"item_power_treads",
	"item_manta",--
	"item_ultimate_scepter",
	"item_skadi",--
    "item_force_staff",
	"item_hurricane_pike",--
	"item_butterfly",--
	"item_hydras_breath",--
	"item_greater_crit",--
	"item_travel_boots",
	"item_aghanims_shard",
	"item_disperser",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
	"item_medusa_outfit",
	"item_ultimate_scepter",
	"item_aghanims_shard",
	"item_dragon_lance",
	"item_manta",--
	"item_mjollnir",--
    "item_force_staff",
	"item_hurricane_pike", --
	"item_travel_boots",
	"item_skadi",--
--	"item_sphere",	
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_butterfly",--
	"item_hydras_breath",--
	"item_travel_boots_2",--

}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_2']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
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

npc_dota_hero_medusa

"Ability1"		"medusa_split_shot"
"Ability2"		"medusa_mystic_snake"
"Ability3"		"medusa_mana_shield"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"medusa_stone_gaze"
"Ability10"		"special_bonus_attack_damage_15"
"Ability11"		"special_bonus_evasion_15"
"Ability12"		"special_bonus_attack_speed_30"
"Ability13"		"special_bonus_unique_medusa_3"
"Ability14"		"special_bonus_unique_medusa_5"
"Ability15"		"special_bonus_unique_medusa"
"Ability16"		"special_bonus_mp_1000"
"Ability17"		"special_bonus_unique_medusa_4"

modifier_medusa_split_shot
modifier_medusa_mana_shield
modifier_medusa_stone_gaze_tracker
modifier_medusa_stone_gaze
modifier_medusa_stone_gaze_slow
modifier_medusa_stone_gaze_facing
modifier_medusa_stone_gaze_stone


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'medusa')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'medusa')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'medusa')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'medusa')
local abilityM = nil
local GorgonGrasp = SafeAbility(bot:GetAbilityByName('medusa_gorgon_grasp'), 'medusa_gorgon_grasp', 'medusa')

local castQDesire
local castWDesire, castWTarget
local castEDesire
local castRDesire
local GorgonGraspDesire, GorgonGraspLocation

local nKeepMana, nMP, nHP, nLV, hEnemyHeroList
local lastToggleTime = 0


local botTarget
function X.SkillsComplement()

	Fu.ConsiderForMkbDisassembleMask( bot )
	Fu.ConsiderTarget()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	hEnemyHeroList = ctx.enemies


	castWDesire, castWTarget = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end


	castRDesire = X.ConsiderR()
	if castRDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end

	GorgonGraspDesire, GorgonGraspLocation = X.ConsiderGorgonGrasp()
	if GorgonGraspDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(GorgonGrasp, GorgonGraspLocation)
		return
	end

	castQDesire = X.ConsiderQ()
	if castQDesire > 0
	then
		bot:Action_UseAbility( abilityQ )
		return
	end

	castEDesire = X.ConsiderE()
	if castEDesire > 0
	then
		bot:Action_UseAbility( abilityE )
		return
	end

end

function X.ConsiderGorgonGrasp()
	if not GorgonGrasp:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, GorgonGrasp:GetCastRange())
	local nCastPoint = GorgonGrasp:GetCastPoint()
	-- local nRadius = GorgonGrasp:GetSpecialValueInt('radius')
	-- local nRadiusGrow = GorgonGrasp:GetSpecialValueInt('radius_grow')
	local nDelay = GorgonGrasp:GetSpecialValueInt('delay')
	-- local nVolleyInterval = GorgonGrasp:GetSpecialValueInt('volley_interval')
	local nDamage = GorgonGrasp:GetSpecialValueInt('damage')
	local nDPS = GorgonGrasp:GetSpecialValueInt('damage_pers')
	local nDuration = GorgonGrasp:GetSpecialValueInt('duration')
	botTarget = Fu.GetProperTarget(bot)

	local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
	local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	local eta = nCastPoint + nDelay

	for _, enemyHero in pairs(tEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		then
			if enemyHero:HasModifier('modifier_teleporting') then
				if Fu.GetModifierTime(enemyHero, 'modifier_teleporting') > nDelay + nCastPoint then
					return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
				end
			elseif enemyHero:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end

			if Fu.CanKillTarget(enemyHero, nDamage + nDPS * nDuration, DAMAGE_TYPE_PHYSICAL)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
			and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end
		end
	end

	if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsRetreating(bot)
	and not Fu.IsRealInvisible(bot)
	then
		for _, enemyHero in pairs(tEnemyHeroes)
		do
			if Fu.IsValidHero(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and bot:WasRecentlyDamagedByHero(enemyHero, 2.5)
			and (Fu.IsChasingTarget(enemyHero, bot) or Fu.GetHP(bot) < 0.5)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
			and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
			end
		end
	end

	for _, allyHero in pairs(tAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:GetActiveModeDesire() >= 0.7
        and allyHero:WasRecentlyDamagedByAnyHero(3)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(nAllyInRangeEnemy[1], eta)
            end
        end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable() then return 0 end

	local nCastRange = bot:GetAttackRange() + 150
	local nSkillLv = abilityQ:GetLevel()
	
	local nInRangeEnemyHeroList = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	local nInRangeEnemyCreepList = bot:GetNearbyCreeps(nCastRange, true)
	local nInRangeEnemyLaneCreepList = bot:GetNearbyLaneCreeps(nCastRange, true)
	local nAllyLaneCreepList = bot:GetNearbyLaneCreeps(800, false)
	botTarget = Fu.GetProperTarget(bot)
	
	--关闭分裂的情况
	if Fu.IsLaning( bot )
		or ( #nInRangeEnemyHeroList == 1 )
		or ( Fu.IsGoingOnSomeone(bot) and Fu.IsValidHero(botTarget) and nSkillLv <= 2 and #nInRangeEnemyHeroList == 2 )
		or ( #nInRangeEnemyHeroList == 0 and #nInRangeEnemyCreepList <= 1 )
		or ( #nInRangeEnemyHeroList == 0 and #nInRangeEnemyLaneCreepList >= 2 and #nAllyLaneCreepList >= 1 and nSkillLv <= 3 )
	then
		if abilityQ:GetToggleState()
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	else
		if not abilityQ:GetToggleState()
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end
	

	return BOT_ACTION_DESIRE_NONE
		
end


function X.ConsiderE()

	if not abilityE:IsFullyCastable() then return 0 end

	if nHP > 0.8 and nMP < 0.88 and nLV < 15
	  and Fu.GetEnemyCount( bot, 1600 ) <= 1
	  and lastToggleTime + 3.0 < DotaTime()
	then
		if abilityE:GetToggleState()
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	else
		if not abilityE:GetToggleState()
		then
			lastToggleTime = DotaTime()
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

-- Calculate the best target for Mystic Snake
local function GetBestSnakeTarget(nCastRange, nSnakeJumpRadius, nSnakeJumps)
	local bestTarget = nil
	local possibleTargets = 0
	local nSnakeSearchRange = nSnakeJumpRadius * 1.2

	local tableNearbyEnemyCreeps = bot:GetNearbyCreeps(nCastRange + nSnakeSearchRange, true)
	if #tableNearbyEnemyCreeps < nSnakeJumps then
		local creep = tableNearbyEnemyCreeps[1]
		if Fu.IsValid(creep) then
			-- Check if the creep is a valid starting target and maximize hero jumps
			local nEnemies = #Fu.GetEnemiesNearLoc(creep:GetLocation(), nSnakeSearchRange)
			if nEnemies >= 1 then
				bestTarget = creep
				possibleTargets = math.min(#tableNearbyEnemyCreeps + nEnemies, nSnakeJumps)
			end
		end
	elseif #tableNearbyEnemyCreeps >= nSnakeJumps then
		if (Fu.IsFarming(bot) or Fu.IsPushing(bot)) and Fu.IsValid(tableNearbyEnemyCreeps[1]) then
			return tableNearbyEnemyCreeps[1], #tableNearbyEnemyCreeps
		end
	end

	return bestTarget, possibleTargets
end

function X.ConsiderW()

	if not abilityW:IsFullyCastable() then return 0 end

	local nCastRange = abilityW:GetCastRange() + 20
	local nSnakeJumps = abilityW:GetSpecialValueInt( 'snake_jumps' )
	local nSnakeDamage = abilityW:GetSpecialValueInt( 'snake_damage' )
	local nSnakeJumpRadius = abilityW:GetSpecialValueInt( 'radius' )
	local nSkillLv = abilityW:GetLevel()

	if Fu.IsRetreating( bot )
	then
		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, nCastRange - 200, true, BOT_MODE_NONE )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if Fu.IsValidHero( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy
			end
		end
	end

	if Fu.IsInTeamFight( bot, 1200 )
	then

		local npcMaxManaEnemy = nil
		local nEnemyMaxMana = 0

		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				local nMaxMana = npcEnemy:GetMaxMana()
				if ( nMaxMana > nEnemyMaxMana )
				then
					nEnemyMaxMana = nMaxMana
					npcMaxManaEnemy = npcEnemy
				end
			end
		end

		if ( npcMaxManaEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMaxManaEnemy
		end

	end

	if Fu.IsGoingOnSomeone( bot )
	then
		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.CanCastOnTargetAdvanced( npcTarget )
		then
			local snakeTarget, possibleTargets = GetBestSnakeTarget(nCastRange, nSnakeJumpRadius, nSnakeJumps)
			if snakeTarget
			and Fu.IsInRange( snakeTarget, bot, nCastRange + 50 ) then
				return BOT_ACTION_DESIRE_HIGH, snakeTarget
			end
			if Fu.IsInRange( npcTarget, bot, nCastRange + 50 ) then
				return BOT_ACTION_DESIRE_HIGH, snakeTarget
			end
		end
	end

	local snakeTarget, possibleTargets = GetBestSnakeTarget(nCastRange, nSnakeJumpRadius, nSnakeJumps)
	if snakeTarget
	and Fu.IsInRange( snakeTarget, bot, nCastRange + 50 ) then
		return BOT_ACTION_DESIRE_HIGH, snakeTarget
	end


	if nSkillLv >= 3 then
		local nAoe = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange * 2, nSnakeJumpRadius * 1.2, 0, 0 )
		local nShouldAoeCount = 5
		local nCreeps = bot:GetNearbyCreeps( nCastRange, true )
		local nLaneCreeps = bot:GetNearbyLaneCreeps( 1600, true )

		if nSkillLv == 4 then nShouldAoeCount = 4 end
		if bot:GetLevel() >= 20 or Fu.GetMP( bot ) > 0.88 then nShouldAoeCount = 3 end

		if nAoe.count >= nShouldAoeCount
		then
			if Fu.IsValid( nCreeps[1] )
				and Fu.CanCastOnNonMagicImmune( nCreeps[1] )
				and not ( nCreeps[1]:GetTeam() == TEAM_NEUTRAL and #nLaneCreeps >= 1 )
				and Fu.GetAroundTargetEnemyUnitCount( nCreeps[1], 470 ) >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nCreeps[1]
			end
		end

		if #nCreeps >= 2 and nSkillLv >= 3
		then
			local creeps = bot:GetNearbyCreeps( 1400, true )
			local heroes = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE )
			if Fu.IsValid( nCreeps[1] )
				and #creeps + #heroes >= 4
				and Fu.CanCastOnNonMagicImmune( nCreeps[1] )
				and not ( nCreeps[1]:GetTeam() == TEAM_NEUTRAL and #nLaneCreeps >= 1 )
				and Fu.GetAroundTargetEnemyUnitCount( nCreeps[1], 470 ) >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nCreeps[1]
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0

end


function X.ConsiderR()

	if not abilityR:IsFullyCastable() then return 0	end

	local nCastRange = abilityR:GetSpecialValueInt( "radius" )
	local nAttackRange = bot:GetAttackRange()

	--如果射程内无面对自己的真身则不开大
	local bRealHeroFace = false
	local realHeroList = Fu.GetEnemyList( bot, nAttackRange + 100 )
	for _, npcEnemy in pairs( realHeroList )
	do 
		if npcEnemy:IsFacingLocation( bot:GetLocation(), 50 )
		then
			bRealHeroFace = true
			break
		end
	end
	
	if not bRealHeroFace then return 0 end 
	

	if Fu.IsRetreating( bot )
	then
		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE )
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and npcEnemy:IsFacingLocation( bot:GetLocation(), 20 ) )
			then
				return BOT_ACTION_DESIRE_MODERATE
			end
		end
	end


	if Fu.IsInTeamFight( bot, 1200 ) or Fu.IsGoingOnSomeone( bot )
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nAttackRange, 400, 0, 0 )
		if ( locationAoE.count >= 2 )
		then
			local nInvUnit = Fu.GetInvUnitInLocCount( bot, nAttackRange + 200, 400, locationAoE.targetloc, true )
			if nInvUnit >= locationAoE.count then
				return BOT_ACTION_DESIRE_MODERATE
			end
		end

		local nEnemysHerosInSkillRange = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE )
		if #nEnemysHerosInSkillRange >= 3
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		local nAoe = bot:FindAoELocation( true, true, bot:GetLocation(), 10, 700, 1.0, 0 )
		if nAoe.count >= 3
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and not Fu.IsDisabled( npcTarget )
			and GetUnitToUnitDistance( npcTarget, bot ) <= bot:GetAttackRange()
			and npcTarget:GetHealth() > 600
			and npcTarget:GetPrimaryAttribute() ~= ATTRIBUTE_INTELLECT
			and npcTarget:IsFacingLocation( bot:GetLocation(), 30 )
		then
			return BOT_ACTION_DESIRE_HIGH
		end

	end

	return BOT_ACTION_DESIRE_NONE

end


function X.GetHurtCount( nUnit, nCount )

	local nHeroes = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
	local nCreeps = bot:GetNearbyCreeps( 1600, true, BOT_MODE_NONE )
	local nTable = {}
	table.insert( nTable, nUnit )
	local nHurtCount = 1

	for i=1, nCount
	do
		local nNeastUnit = X.GetNearestUnit( nUnit, nHeroes, nCreeps, nTable )

		if nNeastUnit ~= nil
			and GetUnitToUnitDistance( nUnit, nNeastUnit ) <= 475
		then
			nHurtCount = nHurtCount + 1
			table.insert( nTable, nNeastUnit )
		else
			break
		end
	end


	return nHurtCount

end

function X.GetNearestUnit( nUnit, nHeroes, nCreeps, nTable )

	local NearestUnit = nil
	local NearestDist = 9999
	for _, unit in pairs( nHeroes )
	do
		if unit ~= nil
			and unit:IsAlive()
			and not X.IsExistInTable( unit, nTable )
			and GetUnitToUnitDistance( nUnit, unit ) < NearestDist
		then
			NearestUnit = unit
			NearestDist = GetUnitToUnitDistance( nUnit, unit )
		end
	end

	for _, unit in pairs( nCreeps )
	do
		if unit ~= nil
			and unit:IsAlive()
			and not X.IsExistInTable( unit, nTable )
			and GetUnitToUnitDistance( nUnit, unit ) < NearestDist
		then
			NearestUnit = unit
			NearestDist = GetUnitToUnitDistance( nUnit, unit )
		end
	end

	return NearestUnit

end

function X.IsExistInTable( u, tUnit )
	for _, t in pairs( tUnit )
	do
		if t == u
		then
			return true
		end
	end
	return false
end

return X
