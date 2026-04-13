local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
					{--pos1
                        ['t25'] = {10, 0},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
                    },
                    {--pos2
                        ['t25'] = {10, 0},
                        ['t20'] = {0, 10},
                        ['t15'] = {10, 0},
                        ['t10'] = {10, 0},
                    },
}

local tAllAbilityBuildList = {
						{3,1,3,2,3,6,3,1,1,1,6,2,2,2,6},--pos1
                        {3,1,1,2,1,6,1,2,2,2,6,3,3,3,6},--pos2
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_1"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_quelling_blade",
    "item_slippers",
    "item_circlet",
    "item_double_branches",

    "item_wraith_band",
    "item_magic_wand",
    "item_hand_of_midas",
    "item_power_treads",
    "item_echo_sabre",
    "item_blink",
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_greater_crit",--
    "item_butterfly",--
    "item_satanic",--
    "item_moon_shard",
    "item_swift_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_quelling_blade",

    "item_bottle",
    "item_power_treads",
    "item_magic_wand",
    "item_blink",
    "item_echo_sabre",
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_greater_crit",--
    "item_assault",--
    "item_moon_shard",
    "item_satanic",--
    "item_swift_blink",--
    "item_travel_boots_2",--

    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
    "item_tango",
    "item_quelling_blade",
    "item_slippers",
    "item_circlet",
    "item_double_branches",

    "item_wraith_band",
    "item_magic_wand",
    "item_hand_of_midas",
    "item_power_treads",
    "item_echo_sabre",
    "item_blink",
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_greater_crit",--
    "item_butterfly",--
    "item_satanic",--
    "item_moon_shard",
    "item_swift_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_4']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_4']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local Avalanche     = SafeAbility(bot:GetAbilityByName("tiny_avalanche"), 'tiny_avalanche', 'tiny')
local Toss          = SafeAbility(bot:GetAbilityByName("tiny_toss"), 'tiny_toss', 'tiny')
local TreeGrab      = SafeAbility(bot:GetAbilityByName("tiny_tree_grab"), 'tiny_tree_grab', 'tiny')
local TreeThrow     = SafeAbility(bot:GetAbilityByName("tiny_toss_tree"), 'tiny_toss_tree', 'tiny')
local TreeVolley    = SafeAbility(bot:GetAbilityByName("tiny_tree_channel"), 'tiny_tree_channel', 'tiny')

local AvalancheDesire, AvalancheTarget
local TossDesire, TossTarget
local TreeGrabDesire, TreeGrabTarget
local TreeThrowDesire, TreeThrowTarget
local TreeVolleyDesire, TreeVolleyTarget

local BlinkTossDesire, BlinkTossTarget

local Blink
local BlinkLocation

local botTarget
local bGoingOnSomeone
local bRetreating
local nBotHP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	nBotHP = Fu.GetHP(bot)

	-- Not sure why not tossing to ally..?
	BlinkTossDesire, BlinkTossTarget = X.ConsiderBlinkToss()
	if BlinkTossDesire > 0
	then
		bot:Action_ClearActions(false)
		bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkLocation)
		bot:ActionQueue_Delay(0.1)
		bot:ActionQueue_UseAbilityOnEntity(Toss, BlinkTossTarget)
		return
	end

	AvalancheDesire, AvalancheTarget = X.ConsiderAvalanche()
	if AvalancheDesire > 0
	then
		bot:Action_UseAbilityOnLocation(Avalanche, AvalancheTarget)
		return
	end

	TossDesire, TossTarget = X.ConsiderToss()
	if TossDesire > 0
	then
		bot:Action_UseAbilityOnEntity(Toss, TossTarget)
		return
	end

	TreeGrabDesire, TreeGrabTarget = X.ConsiderTreeGrab()
	if TreeGrabDesire > 0
	then
		bot:Action_UseAbilityOnTree(TreeGrab, TreeGrabTarget)
		return
	end

	TreeThrowDesire, TreeThrowTarget = X.ConsiderTreeThrow()
	if TreeThrowDesire > 0
	then
		bot:Action_UseAbilityOnEntity(TreeThrow, TreeThrowTarget)
		return
	end

	TreeVolleyDesire, TreeVolleyTarget = X.ConsiderTreeVolley()
	if TreeVolleyDesire > 0
	then
		bot:Action_UseAbilityOnLocation(TreeVolley, TreeVolleyTarget)
		return
	end
end

function X.ConsiderAvalanche()
    if not Avalanche:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, Avalanche:GetCastRange())
	local nRadius = Avalanche:GetSpecialValueInt('radius')
	local nDamage = Avalanche:GetSpecialValueInt('value') * (1 + bot:GetSpellAmp())
	local nManaCost = Avalanche:GetManaCost()
	botTarget = Fu.GetProperTarget(bot)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			if (enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero))
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end

			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
			and not enemyHero:HasModifier('modifier_abaddon_aphotic_shield')
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
			end
		end
	end

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange - 50)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_aphotic_shield')
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (nBotHP < 0.58 and bot:WasRecentlyDamagedByAnyHero(2)))
		and Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
		and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		and not Fu.IsDisabled(nInRangeEnemy[1])
		then
			return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
		end
	end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	and Fu.CanSpamSpell(bot, nManaCost)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)

		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
		and nLocationAoE.count >= 4
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if Fu.IsFarming(bot)
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
		local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)

		if nNeutralCreeps ~= nil and #nNeutralCreeps >= 3
		and nLocationAoE.count >= 3
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if Fu.IsLaning(bot)
	and Fu.IsAllowedToSpam(bot, nManaCost)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep))
			and creep:GetHealth() <= nDamage
			then
				local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) <= 600
				then
					return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
				end
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderToss()
    if not Toss:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, Toss:GetCastRange())
	local nDamage = Toss:GetSpecialValueInt('toss_damage') * (1 + bot:GetSpellAmp())
	local nRadius = Toss:GetSpecialValueInt('grab_radius')
	botTarget = Fu.GetProperTarget(bot)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			if (enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero))
			and Avalanche:IsTrained() and not Avalanche:IsCooldownReady()
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end

			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
			and not enemyHero:HasModifier('modifier_abaddon_aphotic_shield')
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end

	if bGoingOnSomeone
	and not CanDoBlinkToss()
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_legion_commander_duel')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		then
			if Fu.IsInRange(bot, botTarget, nRadius)
			then
				local chronodTarget = nil
				local nInRangeEnemy2 = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
				for _, enemyHero in pairs(nInRangeEnemy2)
				do
					if Fu.IsValidHero(enemyHero)
					and Fu.CanCastOnNonMagicImmune(enemyHero)
					and Fu.IsInRange(bot, enemyHero, nCastRange)
					and not Fu.IsSuspiciousIllusion(enemyHero)
					and enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
					then
						chronodTarget = enemyHero
						break
					end
				end

				if chronodTarget ~= nil
				then
					for _, enemyHero in pairs(nInRangeEnemy2)
					do
						if Fu.IsValidHero(enemyHero)
						and Fu.CanCastOnNonMagicImmune(enemyHero)
						and Fu.IsInRange(bot, enemyHero, nRadius)
						and not Fu.IsSuspiciousIllusion(enemyHero)
						then
							return BOT_ACTION_DESIRE_HIGH, chronodTarget
						end
					end
				end

				return BOT_ACTION_DESIRE_HIGH, botTarget
			else
				if Fu.IsInRange(bot, botTarget, nCastRange)
				then
					local nAllyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, false)
					local nCreeps = bot:GetNearbyCreeps(nRadius, true)

					if (nAllyLaneCreeps ~= nil and #nAllyLaneCreeps >= 1)
					or (nCreeps ~= nil and #nCreeps >= 1)
					then
						return BOT_ACTION_DESIRE_HIGH, botTarget
					end

					local nTargetAllies = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
					if nTargetAllies ~= nil and #nTargetAllies <= 1
					then
						local nInRangeAllyToToss = Fu.GetNearbyHeroes(bot,nRadius, false, BOT_MODE_NONE)
						if nInRangeAllyToToss ~= nil and #nInRangeAllyToToss >= 1
						and GetUnitToUnitDistance(bot, botTarget) > nRadius + 75
						then
							return BOT_ACTION_DESIRE_HIGH, botTarget
						end
					end
				end
			end
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (nBotHP and bot:WasRecentlyDamagedByAnyHero(2)))
		and Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		and not Fu.IsDisabled(nInRangeEnemy[1])
		then
			local loc = Fu.GetEscapeLoc()
			local furthestTarget = Fu.GetFurthestUnitToLocationFrommAll(bot, nCastRange, loc)

			if furthestTarget ~= nil
			and GetUnitToUnitDistance(bot, furthestTarget) > nRadius
			then
				local tTarget = Fu.GetClosestUnitToLocationFrommAll2(bot, nRadius, bot:GetLocation())

				if Fu.IsValidTarget(tTarget)
				and tTarget:GetTeam() ~= bot:GetTeam()
				then
					return BOT_ACTION_DESIRE_MODERATE, furthestTarget
				end
			elseif furthestTarget ~= nil and GetUnitToUnitDistance(furthestTarget, bot) <= nRadius
			then
				local tTarget = Fu.GetClosestUnitToLocationFrommAll2(bot, nRadius, bot:GetLocation())

				if Fu.IsValidTarget(tTarget)
				and tTarget:GetTeam() ~= bot:GetTeam()
				then
					return BOT_ACTION_DESIRE_MODERATE, tTarget
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTreeGrab()
	if not TreeGrab:IsFullyCastable()
	or bot:HasModifier('modifier_tiny_tree_grab')
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,700, true, BOT_MODE_NONE)

	if not bRetreating
	and bot:GetHealth() > 0.15
	and bot:DistanceFromFountain() > 800
	and nEnemyHeroes ~= nil and #nEnemyHeroes == 0
	then
		local nTrees = bot:GetNearbyTrees(1200)

		if nTrees ~= nil and #nTrees > 0
		and (IsLocationVisible(GetTreeLocation(nTrees[1]))
			or IsLocationPassable(GetTreeLocation(nTrees[1])))
		then
			return BOT_ACTION_DESIRE_HIGH, nTrees[1]
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTreeThrow()
	if not TreeThrow:IsFullyCastable()
	or not bot:HasModifier('modifier_tiny_tree_grab')
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = TreeThrow:GetSpecialValueInt('range')
	local nDamage = bot:GetAttackDamage()
	local nAttackCount = bot:GetModifierStackCount(bot:GetModifierByName('modifier_tiny_tree_grab'))
	botTarget = Fu.GetProperTarget(bot)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			if (Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PHYSICAL)
				or bRetreating and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PHYSICAL))
			and not enemyHero:HasModifier('modifier_abaddon_aphotic_shield')
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 100, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 50)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_aphotic_shield')
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		and nAttackCount <= 2
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if bRetreating
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 100, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
		local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, nCastRange)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (nBotHP < 0.65 and bot:WasRecentlyDamagedByAnyHero(2)))
		and Fu.IsValidTarget(weakestTarget)
		and not Fu.IsSuspiciousIllusion(weakestTarget)
		and not weakestTarget:HasModifier('modifier_abaddon_aphotic_shield')
		and not weakestTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not weakestTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not weakestTarget:HasModifier('modifier_oracle_false_promise_timer')
		and not weakestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			return BOT_ACTION_DESIRE_HIGH, weakestTarget
		end
	end

	if Fu.IsLaning(bot)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep))
			and creep:GetHealth() <= nDamage
			then
				local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) <= 600
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTreeVolley()
	if bot:HasScepter()
	or not TreeVolley:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, TreeVolley:GetCastRange())
	local nCastPoint = TreeVolley:GetCastPoint()
	local nRadius = TreeVolley:GetSpecialValueInt('tree_grab_radius')
	local nSplashRadius = TreeVolley:GetSpecialValueInt('splash_radius')
	botTarget = Fu.GetProperTarget(bot)

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nTrees = bot:GetNearbyTrees(nRadius)

		if #nTrees >= 3
		then
			local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nSplashRadius, nCastPoint, 0)

			if nLocationAoE.count >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
	end

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 100, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsValidTarget(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_aphotic_shield')
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		and GetUnitToUnitDistance(bot, botTarget) >= 500
		then
			local nTrees = bot:GetNearbyTrees(nRadius)

			if #nTrees >= 3
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderBlinkToss()
    if CanDoBlinkToss()
    then
		local nCastRange = Fu.GetProperCastRange(false, bot, Toss:GetCastRange())
		local nRadius = Toss:GetSpecialValueInt('grab_radius')
		botTarget = Fu.GetProperTarget(bot)

		if bGoingOnSomeone
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

			if Fu.IsValidTarget(botTarget)
			and Fu.CanCastOnNonMagicImmune(botTarget)
			and not Fu.IsSuspiciousIllusion(botTarget)
			and not Fu.IsDisabled(botTarget)
			and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
			and not botTarget:HasModifier('modifier_legion_commander_duel')
			and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			and #nInRangeAlly >= 1
			then
				if Fu.IsInRange(bot, botTarget, nCastRange)
				and GetUnitToUnitDistance(bot, botTarget) > nRadius
				then
					BlinkLocation = botTarget:GetLocation()
					return BOT_ACTION_DESIRE_HIGH, nInRangeAlly[#nInRangeAlly]
				end
			end
		end
    end

    return BOT_ACTION_DESIRE_NONE
end

function CanDoBlinkToss()
    if Toss:IsFullyCastable()
    and Blink ~= nil and Blink:IsFullyCastable()
    then
        local manaCost = Toss:GetManaCost()

        if bot:GetMana() >= manaCost
        then
            return true
        end
    end

    return false
end

function HasBlink()
    local blink = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil
        and (item:GetName() == "item_blink" or item:GetName() == "item_overwhelming_blink" or item:GetName() == "item_arcane_blink" or item:GetName() == "item_swift_blink")
        then
			blink = item
			break
		end
	end

    if blink ~= nil
    and blink:IsFullyCastable()
	then
        Blink = blink
        return true
	end

    return false
end

return X