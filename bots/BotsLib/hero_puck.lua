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
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,2,2,2,6,3,3,3,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local nItemRand = RandomInt(1, 2) == 1 and "item_black_king_bar" or "item_sphere"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_double_branches",
    "item_faerie_fire",

    "item_bottle",
    "item_power_treads",
    "item_magic_wand",
    "item_witch_blade",
    "item_cyclone",
    "item_blink",
    "item_aghanims_shard",
    "item_devastator",--
    "item_ultimate_scepter",
    "item_mjollnir",--
    nItemRand,--
    "item_overwhelming_blink",--
    "item_travel_boots",
    "item_ultimate_scepter_2",
    "item_wind_waker",--
    "item_travel_boots_2",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_double_branches",

    "item_power_treads",
    "item_magic_wand",
    "item_witch_blade",
    "item_cyclone",
    "item_blink",
    "item_aghanims_shard",
    "item_devastator",--
    "item_ultimate_scepter",
    "item_mjollnir",--
    nItemRand,--
    "item_overwhelming_blink",--
    "item_travel_boots",
    "item_ultimate_scepter_2",
    "item_wind_waker",--
    "item_travel_boots_2",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

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

local IllusoryOrb   = SafeAbility(bot:GetAbilityByName('puck_illusory_orb'), 'puck_illusory_orb', 'puck')
local WaningRift    = SafeAbility(bot:GetAbilityByName('puck_waning_rift'), 'puck_waning_rift', 'puck')
local PhaseShift    = SafeAbility(bot:GetAbilityByName('puck_phase_shift'), 'puck_phase_shift', 'puck')
local EtherealJaunt = SafeAbility(bot:GetAbilityByName('puck_ethereal_jaunt'), 'puck_ethereal_jaunt', 'puck')
local DreamCoil     = SafeAbility(bot:GetAbilityByName('puck_dream_coil'), 'puck_dream_coil', 'puck')

local IllusoryOrbDesire, IllusoryOrbLocation
local WaningRiftDesire, WaningRiftLocation
local PhaseShiftDesire
local EtherealJauntDesire
local DreamCoilDesire, DreamCoilLocation

local PhaseOrbDesire, PhaseOrbLocation

local IsRetreatOrb = false

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

    PhaseOrbDesire, PhaseOrbLocation, PhaseDuration = X.ConsiderPhaseOrb()
    if PhaseOrbDesire > 0
    then
        bot:Action_ClearActions(false)
        bot:ActionQueue_UseAbilityOnLocation(IllusoryOrb, PhaseOrbLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbility(PhaseShift)
        bot:ActionQueue_Delay(PhaseDuration - 0.3)
        bot:ActionQueue_UseAbility(EtherealJaunt)
        return
    end

    IllusoryOrbDesire, IllusoryOrbLocation = X.ConsiderIllusoryOrb()
    if IllusoryOrbDesire > 0
    then
        bot:Action_UseAbilityOnLocation(IllusoryOrb, IllusoryOrbLocation)
        return
    end

    PhaseShiftDesire = X.ConsiderPhaseShift()
    if PhaseShiftDesire > 0
    then
        bot:Action_UseAbility(PhaseShift)
        return
    end

    EtherealJauntDesire = X.ConsiderEtherealJaunt()
    if EtherealJauntDesire > 0
    then
        bot:Action_UseAbility(EtherealJaunt)
        return
    end

    DreamCoilDesire, DreamCoilLocation = X.ConsiderDreamCoil()
    if DreamCoilDesire > 0
    then
        bot:Action_UseAbilityOnLocation(DreamCoil, DreamCoilLocation)
        return
    end

    WaningRiftDesire, WaningRiftLocation = X.ConsiderWaningRift()
    if WaningRiftDesire > 0
    then
        bot:Action_UseAbilityOnLocation(WaningRift, WaningRiftLocation)
        return
    end
end

function X.ConsiderIllusoryOrb()
    if not IllusoryOrb:IsFullyCastable()
    or bot:HasModifier('modifier_puck_phase_shift')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, IllusoryOrb:GetCastRange())
    local nCastPoint = IllusoryOrb:GetCastPoint()
	local nRadius = IllusoryOrb:GetSpecialValueInt('radius')
    local nDamage = IllusoryOrb:GetSpecialValueInt('damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
        end
    end

	if Fu.IsStuck(bot)
	then
		local loc = Fu.GetEscapeLoc()
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nCastRange)
	end

    if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
            end
        end
	end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1000, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and #nTargetInRangeAlly > #nInRangeAlly
            then
                IsRetreatOrb = true
                local loc = Fu.GetEscapeLoc()
		        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nCastRange)
            else
                IsRetreatOrb = false
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsFarming(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

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
			-- 		return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
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
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderWaningRift()
    if not WaningRift:IsFullyCastable()
    or bot:HasModifier('modifier_puck_phase_shift')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastPoint = WaningRift:GetCastPoint()
	local nRadius = WaningRift:GetSpecialValueInt('radius')
    local nDamage = WaningRift:GetSpecialValueInt('damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius + 200, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
        end
    end

	if Fu.IsStuck(bot)
	then
		local loc = Fu.GetEscapeLoc()
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nRadius)
	end

    if Fu.IsInTeamFight(bot, 1200)
    then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
    end

    if bGoingOnSomeone
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
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
                or (Fu.GetHP(bot) < 0.65 and bot:WasRecentlyDamagedByAnyHero(2)))
            then
                local loc = Fu.GetEscapeLoc()
		        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nRadius)
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), bot:GetAttackRange() + 150, nRadius, 0, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsFarming(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), bot:GetAttackRange() + 150, nRadius, 0, 0)

        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and creep:GetHealth() <= nDamage
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
            --     and nBotMP > 0.35
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
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
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderPhaseShift()
    if not PhaseShift:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nDuration = PhaseShift:GetSpecialValueInt('duration')

    if Fu.IsStunProjectileIncoming(bot, 600)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if Fu.IsUnitTargetProjectileIncoming(bot, 400)
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if not bot:HasModifier('modifier_sniper_assassinate')
	and not bot:IsMagicImmune()
	then
		if Fu.IsWillBeCastUnitTargetSpell(bot, 400)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bRetreating
	then
		local blink = bot:GetItemInSlot(bot:FindItemSlot('item_blink'))
		if blink ~= nil
        and blink:GetCooldownTimeRemaining() < nDuration
        then
			return BOT_ACTION_DESIRE_HIGH
		end

		local nProjectiles = GetLinearProjectiles()
		for _, p in pairs(nProjectiles)
		do
			if p ~= nil
            and p.ability:GetName() == 'puck_illusory_orb'
            then
				if GetUnitToLocationDistance(bot, p.location) < 300
                then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

    local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)
    local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

    if realEnemyCount ~= nil and #realEnemyCount >= 2
    and nInRangeAlly ~= nil and #realEnemyCount > #nInRangeAlly
    and bot:WasRecentlyDamagedByAnyHero(1.5)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderEtherealJaunt()
    if not EtherealJaunt:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nAttackRange = bot:GetAttackRange()
    botTarget = Fu.GetProperTarget(bot)

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and not Fu.IsInRange(bot, botTarget, nAttackRange)
		then
			local nProjectiles = GetLinearProjectiles()

            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)
            local nTargetInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)

            if nTargetInRangeEnemy ~= nil and nTargetInRangeAlly ~= nil
            and #nTargetInRangeEnemy >= #nTargetInRangeAlly
            then
                local nTargetInRangeTower = botTarget:GetNearbyTowers(700, false)

                for _, p in pairs(nProjectiles)
                do
                    if p ~= nil
                    and p.ability:GetName() == 'puck_illusory_orb'
                    and not Fu.IsLocationInChrono(p.location)
                    then
                        if Fu.IsInLaningPhase()
                        then
                            if nTargetInRangeTower ~= nil and #nTargetInRangeTower == 0
                            then
                                if GetUnitToLocationDistance(botTarget, p.location) < nAttackRange * 1.15
                                then
                                    return BOT_ACTION_DESIRE_HIGH
                                end
                            end
                        else
                            if GetUnitToLocationDistance(botTarget, p.location) < nAttackRange * 1.15
                            then
                                local nInRangeAlly = Fu.GetAlliesNearLoc(p.location, 700)
                                local nInRangeEnemy = Fu.GetEnemiesNearLoc(p.location, 700)

                                if #nInRangeAlly >= #nInRangeEnemy
                                then
                                    if #nInRangeAlly <= 1 and #nInRangeEnemy == 1
                                    and nTargetInRangeTower ~= nil and #nTargetInRangeAlly == 0
                                    then
                                        return BOT_ACTION_DESIRE_HIGH
                                    end

                                    if #nInRangeAlly >= 2
                                    then
                                        return BOT_ACTION_DESIRE_HIGH
                                    end
                                end
                            end
                        end
                    end
                end
            end
		end
	end

    if bRetreating
    and IsRetreatOrb
	then
		local nProjectiles = GetLinearProjectiles()

		for _, p in pairs(nProjectiles)
        do
            if p.ability:GetName() == 'puck_illusory_orb'
            and not Fu.IsLocationInChrono(p.location)
            then
                if GetUnitToLocationDistance(bot, p.location) > 600
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderDreamCoil()
    if not DreamCoil:IsFullyCastable()
    or bot:HasModifier('modifier_puck_phase_shift')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, DreamCoil:GetCastRange())
	local nRadius = DreamCoil:GetSpecialValueInt('coil_radius')
    local nDuration = DreamCoil:GetSpecialValueInt('coil_duration')

    if Fu.IsInTeamFight(bot, 1200)
    then
		local nLocationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0 )
        local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
        and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
	end

	if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local strongestTarget = Fu.GetStrongestUnit(nCastRange, bot, true, false, nDuration)

		if Fu.IsValidTarget(strongestTarget)
		and Fu.CanCastOnNonMagicImmune(strongestTarget)
        and not Fu.IsSuspiciousIllusion(strongestTarget)
        and not Fu.IsDisabled(strongestTarget)
        and not Fu.IsLocationInChrono(strongestTarget:GetLocation())
        and not Fu.IsLocationInBlackHole(strongestTarget:GetLocation())
        and not strongestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not strongestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not strongestTarget:HasModifier('modifier_oracle_false_promise_timer')
		then
			local nTargetInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                if #nInRangeAlly == 1 and #nTargetInRangeAlly == 0
                and Fu.GetHP(strongestTarget) > 0.55
                and bAttacking
                then
                    return BOT_ACTION_DESIRE_HIGH, strongestTarget:GetLocation()
                end

                if #nInRangeAlly == 2 and #nTargetInRangeAlly == 0
                and Fu.GetHP(strongestTarget) > 0.2
                and Fu.IsRunning(strongestTarget)
                and not strongestTarget:IsFacingLocation(bot:GetLocation(), 90)
                then
                    return BOT_ACTION_DESIRE_HIGH, strongestTarget:GetLocation()
                end
            end
		end
	end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local realEnemyCount = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
        local nInRangeTower = bot:GetNearbyTowers(700, false)

        if nInRangeAlly ~= nil and realEnemyCount ~= nil
        then
            if nInRangeTower ~= nil and #nInRangeTower == 0
            and #realEnemyCount > #nInRangeAlly
            and #realEnemyCount >= 3 and #nInRangeAlly <= 1
            and GetUnitToLocationDistance(bot, nLocationAoE.targetloc) < 700
            and GetUnitToLocationDistance(bot, GetAncient(GetTeam()):GetLocation()) > 3200
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function CanDoPhaseOrb()
    if PhaseShift:IsFullyCastable()
    and IllusoryOrb:IsFullyCastable()
    then
        local nManaCost = PhaseShift:GetManaCost() + IllusoryOrb:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

function X.ConsiderPhaseOrb()
    if CanDoPhaseOrb()
    then
        local nCastRange = Fu.GetProperCastRange(false, bot, IllusoryOrb:GetCastRange())
        local nDuration = PhaseShift:GetSpecialValueInt('duration')

        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        and nInRangeAlly ~= nil and #realEnemyCount >= #nInRangeAlly
        then
            local loc = Fu.GetEscapeLoc()
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nCastRange), nDuration
        end

        if bRetreating
        then
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and Fu.IsValidHero(nInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
            then
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1000, false, BOT_MODE_NONE)

                if nTargetInRangeAlly ~= nil
                and #nTargetInRangeAlly > #nInRangeAlly
                then
                    local loc = Fu.GetEscapeLoc()
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nCastRange), nDuration
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

return X