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
						['t20'] = {10, 0},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,3,2,2,2,2,6,3,3,6,1,1,1,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
    "item_double_branches",
	"item_quelling_blade",
	"item_slippers",
	"item_circlet",
	
    "item_wraith_band",
    "item_magic_wand",
    "item_power_treads",
    "item_dragon_lance",
    "item_manta",--
    "item_skadi",--
    "item_black_king_bar",--
    "item_greater_crit",--
    "item_butterfly",--
    "item_force_staff",
    "item_hurricane_pike",--
    "item_moon_shard",
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
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

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		if Fu.IsValidHero(hMinionUnit) and hMinionUnit:IsIllusion()
		then
			Minion.IllusionThink( hMinionUnit )
		end
	end

end

local Reflection    = bot:GetAbilityByName( "terrorblade_reflection" )
local ConjureImage  = bot:GetAbilityByName( "terrorblade_conjure_image" )
local Metamorphosis = bot:GetAbilityByName( "terrorblade_metamorphosis" )
local DemonZeal     = bot:GetAbilityByName( "terrorblade_demon_zeal" )
local TerrorWave    = bot:GetAbilityByName( "terrorblade_terror_wave" )
local Sunder        = bot:GetAbilityByName( "terrorblade_sunder" )

local ReflectionDesire, ReflectionLocation
local ConjureImageDesire
local MetamorphosisDesire
local DemonZealDesire
local TerrorWaveDesire
local SunderDesire, SunderTarget

local botTarget
local bGoingOnSomeone
local nBotHP
local bInTeamFight
function X.SkillsComplement()

    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	nBotHP = Fu.GetHP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

	SunderDesire, SunderTarget = X.ConsiderSunder()
    if (SunderDesire > 0)
	then
		bot:Action_UseAbilityOnEntity(Sunder, SunderTarget)
		return
	end

	ReflectionDesire, ReflectionLocation = X.ConsiderReflection()
	if (ReflectionDesire > 0)
	then
		bot:Action_UseAbilityOnLocation(Reflection, ReflectionLocation)
		return
	end

	ConjureImageDesire = X.ConsiderConjureImage()
	if (ConjureImageDesire > 0)
	then
		bot:Action_UseAbility(ConjureImage)
		return
	end

	TerrorWaveDesire = X.ConsiderTerrorWave()
    if (TerrorWaveDesire > 0)
	then
		bot:Action_UseAbility(TerrorWave)
		return
	end

	MetamorphosisDesire = X.ConsiderMetamorphosis()
	if (MetamorphosisDesire > 0)
	then
        bot:Action_UseAbility(Metamorphosis)
		return
	end

    DemonZealDesire = X.ConsiderDemonZeal()
	if (DemonZealDesire > 0)
	then
		bot:Action_UseAbility(DemonZeal)
		return
	end
end

function X.ConsiderReflection()
	if not Reflection:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = Reflection:GetSpecialValueInt('range')
	local nCastRange = Reflection:GetCastRange()
	local nCastPoint = Reflection:GetCastPoint()
	botTarget = Fu.GetProperTarget(bot)

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

		if nLocationAoE.count >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and nInRangeAlly ~= nil and nInRangeEnemy
		and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if Fu.IsRetreating(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (nBotHP < 0.6 and bot:WasRecentlyDamagedByAnyHero(2)))
		and Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		and not Fu.IsDisabled(nInRangeEnemy[1])
		then
			return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
		end
	end

	local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
	for _, allyHero in pairs(nAllyHeroes)
	do
		local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

		if (Fu.IsRetreating(allyHero)
			and Fu.GetHP(allyHero) < 0.6
			and allyHero:WasRecentlyDamagedByAnyHero(2.5))
		and Fu.IsValidHero(nAllyInRangeEnemy[1])
		and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
		and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
		and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
		and not Fu.IsDisabled(nAllyInRangeEnemy[1])
		then
			return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderConjureImage()
	if not ConjureImage:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nMana = bot:GetMana() / bot:GetMaxMana()
	botTarget = Fu.GetProperTarget(bot)

	if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 50)
		and not Fu.IsInEtherealForm(botTarget)
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsRetreating(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (nBotHP < 0.5 and bot:WasRecentlyDamagedByAnyHero(2)))
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	if Fu.IsDefending(bot) or Fu.IsPushing(bot)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(700, true)
		local nEnemyTowers = bot:GetNearbyTowers(700, true)

		if ((nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3)
			or (nEnemyTowers ~= nil and #nEnemyTowers >= 1))
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsFarming(bot)
	and nMana > 0.4
	then
		if Fu.IsValid(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and botTarget:IsCreep()
		then
			return BOT_ACTION_DESIRE_HIGH
		end
    end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderMetamorphosis()
	if not Metamorphosis:IsFullyCastable()
	or bot:HasModifier('modifier_terrorblade_metamorphosis')
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = bot:GetAttackRange() + Metamorphosis:GetSpecialValueInt('bonus_range')
	botTarget = Fu.GetProperTarget(bot)

	if bInTeamFight
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 150, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		-- and Fu.IsCore(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsInEtherealForm(botTarget)
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and nInRangeAlly ~= nil and nInRangeEnemy
		and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and DotaTime() < 30 * 60
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSunder()
	if not Sunder:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Sunder:GetCastRange()

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
	local nSunderTarget = Fu.GetMostHPPercent(nEnemyHeroes, true)

	if nBotHP < 0.35
	and nSunderTarget ~= nil
	and not Fu.IsSuspiciousIllusion(nSunderTarget)
	then
		return BOT_ACTION_DESIRE_HIGH, nSunderTarget
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderDemonZeal()
    if not DemonZeal:IsTrained()
	or not DemonZeal:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

    local nHealthCost = bot:GetHealth() * DemonZeal:GetSpecialValueFloat('value')
    local nRadius = bot:GetAttackRange() + Metamorphosis:GetSpecialValueInt('bonus_range')
	botTarget = Fu.GetProperTarget(bot)

	if (((bot:GetHealth() - nHealthCost) / bot:GetMaxHealth()) > 0.5)
	and bot:HasModifier('modifier_terrorblade_metamorphosis_transform')
	then
		if bInTeamFight
		then
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

			if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		if bGoingOnSomeone
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 150, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

			if Fu.IsValidTarget(botTarget)
			and Fu.IsInRange(bot, botTarget, nRadius)
			-- and Fu.IsCore(botTarget)
			and not Fu.IsSuspiciousIllusion(botTarget)
			and not Fu.IsInEtherealForm(botTarget)
			and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
			and nInRangeAlly ~= nil and nInRangeEnemy
			and #nInRangeAlly >= #nInRangeEnemy
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderTerrorWave()
	if not bot:HasScepter()
    or not TerrorWave:IsFullyCastable()
	or bot:HasModifier('modifier_terrorblade_metamorphosis_transform')
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = bot:GetAttackRange() + Metamorphosis:GetSpecialValueInt('bonus_range')
	botTarget = Fu.GetProperTarget(bot)

	if bInTeamFight
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 150, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		-- and Fu.IsCore(botTarget)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsInEtherealForm(botTarget)
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and nInRangeAlly ~= nil and nInRangeEnemy
		and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and DotaTime() < 30 * 60
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X