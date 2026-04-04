local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {--pos1
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						-- {1,3,3,2,3,2,3,2,2,1,1,1,6,6,6},--pos1
						{1,3,1,3,1,6,1,3,3,2,6,2,2,2,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_slippers",
	"item_circlet",
	"item_quelling_blade",
	"item_magic_wand",

	"item_wraith_band",
	"item_power_treads",
	"item_mask_of_madness",
	"item_manta",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_angels_demise",--
	"item_satanic",--
	"item_moon_shard",
	"item_butterfly",--
	"item_hydras_breath",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_ranged_carry' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local LucentBeam 	= bot:GetAbilityByName('luna_lucent_beam')
local MoonGlaives 	= bot:GetAbilityByName('luna_moon_glaive')
local LunarOrbit    = bot:GetAbilityByName("luna_lunar_orbit")
-- local LunarBlessing = bot:GetAbilityByName('luna_lunar_blessing')
local Eclipse 		= bot:GetAbilityByName('luna_eclipse')
local talent6 		= bot:GetAbilityByName(sTalentList[6])

local LucentBeamDesire, LucentBeamTarget
local MoonGlaivesDesire
local LunarOrbitDesire
local EclipseDesire

local talent6BonusDamage = 0

local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)

	botTarget = Fu.GetProperTarget(bot)
	Fu.ConsiderTarget()

	if talent6:IsTrained() then talent6BonusDamage = talent6:GetSpecialValueInt('value') end

	MoonGlaivesDesire = X.ConsiderMoonGlaives()
	if MoonGlaivesDesire > 0
	then
		bot:Action_UseAbility(MoonGlaives)
		return
	end
	LunarOrbitDesire = X.ConsiderLunarOrbit()
	if LunarOrbitDesire > 0
	then
		bot:Action_UseAbility(LunarOrbit)
		return
	end

	EclipseDesire = X.ConsiderEclipse()
	if EclipseDesire > 0
	then
		if Fu.HasPowerTreads(bot)
		then
			Fu.SetQueuePtToINT(bot, false)

			if bot:HasScepter()
			then
				bot:ActionQueue_UseAbilityOnEntity(Eclipse, bot)
			else
				bot:ActionQueue_UseAbility(Eclipse)
			end
		else
			if bot:HasScepter()
			then
				bot:Action_UseAbilityOnEntity(Eclipse, bot)
			else
				bot:Action_UseAbility(Eclipse)
			end
		end

		return
	end

	LucentBeamDesire, LucentBeamTarget = X.ConsiderLucentBeam()
	if LucentBeamDesire > 0
	then
		if Fu.HasPowerTreads(bot)
		then
			Fu.SetQueuePtToINT(bot, false)
			bot:ActionQueue_UseAbilityOnEntity(LucentBeam, LucentBeamTarget)
		else
			bot:Action_UseAbilityOnEntity(LucentBeam, LucentBeamTarget)
		end

		return
	end
end

function X.ConsiderLucentBeam()
	if not LucentBeam:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, LucentBeam:GetCastRange())
	local nAbilityLevel = LucentBeam:GetLevel()
	local nDamage = LucentBeam:GetSpecialValueInt('beam_damage') + talent6BonusDamage

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 300, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.CanCastOnTargetAdvanced(enemyHero)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end

			if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end

		end
	end

	if Fu.IsInTeamFight(bot, 1200)
	then
		local npcWeakestEnemy = nil
		local npcWeakestEnemyHealth = 10000

		for _, enemyHero in pairs(nEnemyHeroes)
		do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			then
				local npcEnemyHealth = enemyHero:GetHealth()
				if npcEnemyHealth < npcWeakestEnemyHealth
				then
					npcWeakestEnemyHealth = npcEnemyHealth
					npcWeakestEnemy = enemyHero
				end
			end
		end

		if npcWeakestEnemy ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, npcWeakestEnemy
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.CanCastOnTargetAdvanced(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange + 75)
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget
			end
		end
	end

	if bRetreating
	and bot:GetActiveModeDesire() > 0.5
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
			and not Fu.IsRealInvisible(bot)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

	if Fu.IsLaning(bot)
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + 200, true)
		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			and not Fu.IsInRange(bot, creep, bot:GetAttackRange() + 80)
			then
				return BOT_ACTION_DESIRE_HIGH, creep
			end
		end

		if nAbilityLevel >= 2
		or Fu.GetMP(bot) > 0.9
		then
			for _, creep in pairs(nEnemyLaneCreeps)
			do
				if Fu.IsValid(creep)
				and Fu.CanBeAttacked(creep)
				and Fu.IsKeyWordUnit('melee', creep)
				and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
				and not Fu.IsInRange(bot, creep, bot:GetAttackRange() + 80)
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end

	if Fu.IsFarming(bot)
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange + 100)
		local targetCreep = Fu.GetMostHpUnit(nNeutralCreeps)

		if Fu.IsValid(targetCreep)
		and (#nNeutralCreeps >= 2 or GetUnitToUnitDistance(targetCreep, bot) <= 400)
		and not Fu.IsRoshan(targetCreep)
		and not Fu.CanKillTarget(targetCreep, bot:GetAttackDamage() * 1.68, DAMAGE_TYPE_PHYSICAL)
		and not Fu.CanKillTarget(targetCreep, nDamage - 10, DAMAGE_TYPE_MAGICAL)
		and Fu.GetManaAfter(LucentBeam:GetManaCost()) * bot:GetMana() > Eclipse:GetManaCost() * 2
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep
		end
	end

	if Fu.IsDoingRoshan(bot)
    then
		-- Remove Spell Block
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
        and not Fu.IsDisabled(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

	local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and Fu.IsCore(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2)
        and allyHero:GetActiveModeDesire() >= 0.5
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsChasingTarget(nAllyInRangeEnemy[1], bot)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end
function X.ConsiderLunarOrbit()
	if not LunarOrbit:IsTrained()
	or not LunarOrbit:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = LunarOrbit:GetSpecialValueInt('rotating_glaives_movement_radius')
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,700, true, BOT_MODE_NONE)

	if Fu.GetHP(bot) < 0.5
	and bot:WasRecentlyDamagedByAnyHero(1)
	and nEnemyHeroes ~= nil and #nEnemyHeroes >= 1
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and bot:WasRecentlyDamagedByAnyHero(1)
		and not Fu.IsDisabled(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if bRetreating
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
			and Fu.IsInRange(bot, enemyHero, 700)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1.5))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

	if Fu.IsFarming(bot)
	then
		local nCreeps = bot:GetNearbyCreeps(nRadius, true)

		if nCreeps ~= nil
		and (#nCreeps >= 3 or (#nCreeps >= 2 and nCreeps[1]:IsAncientCreep()))
		and Fu.CanBeAttacked(nCreeps[1])
		and bAttacking
		and Fu.GetManaAfter(LunarOrbit:GetManaCost()) * bot:GetMana() > Eclipse:GetManaCost() * 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderMoonGlaives()
	if not MoonGlaives:IsTrained()
	or not MoonGlaives:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = 175
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,700, true, BOT_MODE_NONE)

	if Fu.GetHP(bot) < 0.5
	and bot:WasRecentlyDamagedByAnyHero(1)
	and nEnemyHeroes ~= nil and #nEnemyHeroes >= 1
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and bot:WasRecentlyDamagedByAnyHero(1)
		and not Fu.IsDisabled(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if bRetreating
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
			and Fu.IsInRange(bot, enemyHero, 700)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1.5))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

	if Fu.IsFarming(bot)
	then
		local nCreeps = bot:GetNearbyCreeps(nRadius, true)

		if nCreeps ~= nil
		and (#nCreeps >= 3 or (#nCreeps >= 2 and nCreeps[1]:IsAncientCreep()))
		and Fu.CanBeAttacked(nCreeps[1])
		and bAttacking
		and Fu.GetManaAfter(MoonGlaives:GetManaCost()) * bot:GetMana() > Eclipse:GetManaCost() * 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderEclipse()
	if not Eclipse:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = Eclipse:GetSpecialValueInt('radius')
	local nDamage = LucentBeam:GetSpecialValueInt('beam_damage')

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius + 75)
		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			local canKillACore = false
			for _, enemyHero in pairs(nInRangeEnemy)
			do
				if Fu.IsValidHero(enemyHero)
				and Fu.CanCastOnNonMagicImmune(enemyHero)
				and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
				-- and Fu.IsCore(enemyHero)
				and not Fu.IsSuspiciousIllusion(enemyHero)
				and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
				and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
				and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
				and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
				then
					canKillACore = true
					break
				end
			end

			if canKillACore
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and not (botTarget:GetHealth() <= bot:GetAttackDamage() * 4)
		then
			local nInRangeEnemy = Fu.GetNearbyHeroes(bot, nRadius + 75, true, BOT_MODE_NONE)
			local nInRangeAlly = Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE)

			if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
			and nInRangeAlly ~= nil and #nInRangeAlly >= #nInRangeEnemy
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X