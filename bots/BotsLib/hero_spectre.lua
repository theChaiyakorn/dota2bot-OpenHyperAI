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
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,3,3,3,6,2,2,2,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_wraith_band",
    "item_power_treads",
    "item_blade_mail",
    "item_magic_wand",
    "item_radiance",--
    "item_manta",--
    "item_ultimate_scepter",
    "item_orchid",
    "item_skadi",--
    "item_basher",
    "item_aghanims_shard",
    "item_bloodthorn",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_abyssal_blade",--
    "item_travel_boots_2",--
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
    Minion.MinionThink(hMinionUnit)
end

local SpectralDagger    = bot:GetAbilityByName('spectre_spectral_dagger')
-- local Desolate          = bot:GetAbilityByName('spectre_desolate')
local Dispersion        = bot:GetAbilityByName('spectre_dispersion')
local ShadowStep        = bot:GetAbilityByName('spectre_shadow_step')
local Haunt             = bot:GetAbilityByName('spectre_haunt')
local Reality           = bot:GetAbilityByName('spectre_reality')

local SpectralDaggerDesire, SpectralDaggerTarget, DaggerType
local DispersionDesire
local ShadowStepDesire, ShadowStepTarget
local HauntDesire
local RealityDesire, RealityLocation

local ShadowStepCastTime = -1
local ShadowStepDuration = 0
local ShadowStepEnemyTarget = nil

local HauntCastTime = -1
local HauntDuration = 0

local botTarget
local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotMP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = Fu.GetMP(bot)

    RealityDesire, RealityLocation = X.ConsiderReality()
    if RealityDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Reality, RealityLocation)
        return
    end

    ShadowStepDesire, ShadowStepTarget = X.ConsiderShadowStep()
    if ShadowStepDesire > 0
    then
        bot:Action_UseAbilityOnEntity(ShadowStep, ShadowStepTarget)
        ShadowStepCastTime = DotaTime()
        return
    end

    HauntDesire = X.ConsiderHaunt()
    if HauntDesire > 0
    then
        bot:Action_UseAbility(Haunt)
        HauntCastTime = DotaTime()
        return
    end

    SpectralDaggerDesire, SpectralDaggerTarget, DaggerType = X.ConsiderSpectralDagger()
    if SpectralDaggerDesire > 0
    then
        if DaggerType == 'unit'
        then
            bot:Action_UseAbilityOnEntity(SpectralDagger, SpectralDaggerTarget)
        else
            bot:Action_UseAbilityOnLocation(SpectralDagger, SpectralDaggerTarget)
        end

        return
    end

    DispersionDesire = X.ConsiderDispersion()
    if DispersionDesire > 0
    then
        bot:Action_UseAbility(Dispersion)
        return
    end
end

function X.ConsiderSpectralDagger()
    if not SpectralDagger:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SpectralDagger:GetCastRange())
    local nCastPoint = SpectralDagger:GetCastPoint()
    local nRadius = SpectralDagger:GetSpecialValueInt('path_radius')
    local nDamage = SpectralDagger:GetSpecialValueInt('damage')
    local nSpeed = SpectralDagger:GetSpecialValueInt('speed')
    botTarget = Fu.GetProperTarget(bot)

    if Fu.IsStuck(bot)
    then
        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nCastRange), 'loc'
    end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PURE)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            then
                local loc = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint

                if Fu.IsInRange(bot, enemyHero, nCastRange / 2 - 150)
                then
                    loc = enemyHero:GetLocation()
                end

                return BOT_ACTION_DESIRE_HIGH, loc, 'loc'
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PURE)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
            end
        end
    end

    if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'loc'
		end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
            end
		end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (bot:WasRecentlyDamagedByAnyHero(1.5)))
            then
		        return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1], 'unit'
            end
        end

        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.IsChasingTarget(enemyHero, bot)
            and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
                then
                    local loc = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint

                    if Fu.IsInRange(bot, enemyHero, nCastRange / 2 - 150)
                    then
                        loc = enemyHero:GetLocation()
                    end

                    return BOT_ACTION_DESIRE_HIGH, loc, 'loc'
                end

                if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PURE)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero, 'unit'
                end
            end
        end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'loc'
        end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'loc'
        end
    end

    if Fu.IsFarming(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)

        if bAttacking
        and nBotMP > 0.45
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'loc'
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc, 'loc'
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
            --     and nBotMP > 0.35
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH, creep:GetLocation(), 'loc'
			-- 	end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                canKill = canKill + 1
                table.insert(creepList, creep)
            end
		end

        if canKill >= 2
        and nBotMP > 0.25
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), 'loc'
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation(), 'loc'
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil, nil
end

function X.ConsiderDispersion()
    if Dispersion:IsPassive()
    or Dispersion:IsHidden()
    or not Dispersion:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    botTarget = Fu.GetProperTarget(bot)

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bRetreating
    and bot:WasRecentlyDamagedByAnyHero(1.5)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderReality()
    if Reality:IsHidden()
    or not Reality:IsTrained()
    or not Reality:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    HauntDuration = Haunt:GetSpecialValueFloat('duration')
    ShadowStepDuration = ShadowStep:GetSpecialValueFloat('duration')

    if DotaTime() < ShadowStepCastTime + ShadowStepDuration
    then
        if ShadowStepEnemyTarget ~= nil
        and Fu.IsValidTarget(ShadowStepEnemyTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, ShadowStepEnemyTarget:GetLocation()
        end

        for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
        do
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
            if (nInRangeEnemy ~= nil and #nInRangeEnemy == 0)
            or (bot:WasRecentlyDamagedByAnyHero(2.5))
            then
                local targetIlu = nil
                local maxDist = 100000

                if Fu.IsValidHero(allyHero)
                and allyHero:GetUnitName() == 'npc_dota_hero_spectre'
                and (allyHero:IsIllusion()
                    or Fu.IsSuspiciousIllusion(allyHero))
                and Fu.IsNotSelf(bot, allyHero)
                then
                    local dist = GetUnitToLocationDistance(allyHero, Fu.GetEscapeLoc())

                    if dist < maxDist
                    then
                        maxDist = dist
                        targetIlu = allyHero
                    end
                end

                if targetIlu ~= nil
                then
                    return BOT_ACTION_DESIRE_HIGH, targetIlu:GetLocation()
                end
            end
        end
    end

    if DotaTime() < HauntCastTime + HauntDuration
    then
        for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
        do
            if Fu.IsValidHero(allyHero)
            and not Fu.IsSuspiciousIllusion(allyHero)
            and not Fu.IsMeepoClone(allyHero)
            then
                local allyTarget = allyHero:GetAttackTarget()

                if Fu.IsGoingOnSomeone(allyHero)
                and not Fu.IsInRange(bot, allyHero, 1300)
                and not bRetreating
                and not bGoingOnSomeone
                and Fu.IsValidTarget(allyTarget)
                and not Fu.IsSuspiciousIllusion(allyTarget)
                and not Fu.IsLocationInChrono(allyTarget:GetLocation())
                and not Fu.IsLocationInBlackHole(allyTarget:GetLocation())
                and not (GetUnitToLocationDistance(allyTarget, GetAncient(GetOpposingTeam()):GetLocation()) < 200)
                then
                    local nInRangeAlly = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)
                    local nTargetInRangeAlly = Fu.GetNearbyHeroes(allyHero, 1200, false, BOT_MODE_NONE)

                    if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                    and #nInRangeAlly + 1 >= #nTargetInRangeAlly
                    and not (#nInRangeAlly + 1 >= 2 and #nTargetInRangeAlly <= 1)
                    then
                        return BOT_ACTION_DESIRE_HIGH, allyTarget:GetLocation()
                    end
                end
            end

            local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
            if (nInRangeEnemy ~= nil and #nInRangeEnemy == 0)
            or (bot:WasRecentlyDamagedByAnyHero(2.5))
            then
                local targetIlu = nil
                local maxDist = 100000

                if Fu.IsValidHero(allyHero)
                and allyHero:GetUnitName() == 'npc_dota_hero_spectre'
                and (allyHero:IsIllusion()
                    or Fu.IsSuspiciousIllusion(allyHero))
                and Fu.IsNotSelf(bot, allyHero)
                then
                    local dist = GetUnitToLocationDistance(allyHero, Fu.GetEscapeLoc())

                    if dist < maxDist
                    then
                        maxDist = dist
                        targetIlu = allyHero
                    end
                end

                if targetIlu ~= nil
                then
                    return BOT_ACTION_DESIRE_HIGH, targetIlu:GetLocation()
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderShadowStep()
    if not ShadowStep:IsFullyCastable()
    or Fu.IsInLaningPhase()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    ShadowStepDuration = ShadowStep:GetSpecialValueFloat('duration')
    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

    if bGoingOnSomeone
    then
        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, 1600)

        if Fu.IsValidTarget(weakestTarget)
        and GetUnitToUnitDistance(bot, weakestTarget) > 600
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        and not Fu.IsLocationInChrono(weakestTarget:GetLocation())
        and not Fu.IsLocationInBlackHole(weakestTarget:GetLocation())
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            and not (#nInRangeAlly >= 2 and #nTargetInRangeAlly <= 1)
            then
                ShadowStepEnemyTarget = weakestTarget
                return BOT_ACTION_DESIRE_HIGH, weakestTarget
            end
        end
    end

    if nTeamFightLocation ~= nil
    and GetUnitToLocationDistance(bot, nTeamFightLocation) > 1600
    and bot:GetLevel() >= 6
    and bot:GetNetWorth() > 5000
    and not bRetreating
    and not bGoingOnSomeone
    then
        local nHealth = 99999
        local weakestTarget = nil
        local nEnemyHeroes = Fu.GetEnemiesNearLoc(nTeamFightLocation, 1200)

        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsLocationInChrono(enemyHero:GetLocation())
            and not Fu.IsLocationInBlackHole(enemyHero:GetLocation())
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nInRangeEnemy = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nHealth > enemyHero:GetHealth()
                and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
                and #nInRangeAlly >= #nInRangeEnemy
                then
                    nHealth = enemyHero:GetHealth()
                    weakestTarget = enemyHero
                end
            end
        end

        if weakestTarget ~= nil
        then
            ShadowStepEnemyTarget = weakestTarget
            return BOT_ACTION_DESIRE_HIGH, weakestTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderHaunt()
    if not Haunt:IsTrained()
    or not Haunt:IsFullyCastable()
    or Haunt:IsHidden()
    or ShadowStep:IsFullyCastable()
    or Fu.IsInLaningPhase()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    HauntDuration = Haunt:GetSpecialValueFloat('duration')

    for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
    do
        if Fu.IsValidHero(allyHero)
        and not Fu.IsSuspiciousIllusion(allyHero)
        and not Fu.IsMeepoClone(allyHero)
        then
            local allyTarget = allyHero:GetAttackTarget()

            if Fu.IsGoingOnSomeone(allyHero)
            and not Fu.IsInRange(bot, allyHero, 1300)
            and not bRetreating
            and not bGoingOnSomeone
            and Fu.IsValidTarget(allyTarget)
            and not Fu.IsSuspiciousIllusion(allyTarget)
            and not Fu.IsLocationInChrono(allyTarget:GetLocation())
            and not Fu.IsLocationInBlackHole(allyTarget:GetLocation())
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(allyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly + 1 >= #nTargetInRangeAlly
                and not (#nInRangeAlly + 1 >= 2 and #nTargetInRangeAlly <= 1)
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X