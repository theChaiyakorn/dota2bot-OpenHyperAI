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
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,1,4,2,2,6,2,1,1,1,6,4,4,4,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_double_null_talisman",
    "item_power_treads",
    "item_magic_wand",
    "item_witch_blade",
    "item_blink",
    "item_dragon_lance",
    "item_black_king_bar",--
    "item_force_staff",
    "item_hurricane_pike",--
    "item_aghanims_shard",
    "item_devastator",--
    "item_travel_boots",
    "item_moon_shard",
    "item_sheepstick",--
    "item_arcane_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_2']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
    "item_null_talisman",
    "item_magic_wand",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		Minion.IllusionThink( hMinionUnit )
	end
end

local ArcaneOrb             = bot:GetAbilityByName('obsidian_destroyer_arcane_orb')
local AstralImprisonment    = bot:GetAbilityByName('obsidian_destroyer_astral_imprisonment')
local EssenceAura           = bot:GetAbilityByName('obsidian_destroyer_essence_aura')
local SanitysEclipse        = bot:GetAbilityByName('obsidian_destroyer_sanity_eclipse')
local Objurgation           = bot:GetAbilityByName('obsidian_destroyer_objurgation')

local ArcaneOrbDesire, ArcaneOrbTarget
local AstralImprisonmentDesire, AstralImprisonmentTarget
local SanitysEclipseDesire, SanitysEclipseLocation
local ObjurgationDesire

local botTarget
local bGoingOnSomeone
local nBotHP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	nBotHP = Fu.GetHP(bot)

	if ArcaneOrb:IsTrained()
	and ArcaneOrb:GetAutoCastState( ) == false
	and bot:GetLevel() >= 9
	then
		ArcaneOrb:ToggleAutoCast()
	end

    ObjurgationDesire = X.ConsiderObjurgation()
    if ObjurgationDesire > 0
    then
        bot:Action_UseAbility(Objurgation)
        return
    end

    SanitysEclipseDesire, SanitysEclipseLocation = X.ConsiderSanitysEclipse()
    if SanitysEclipseDesire > 0
    then
        bot:Action_UseAbilityOnLocation(SanitysEclipse, SanitysEclipseLocation)
        return
    end

    AstralImprisonmentDesire, AstralImprisonmentTarget = X.ConsiderAstralImprisonment()
    if AstralImprisonmentDesire > 0
    then
        bot:Action_UseAbilityOnEntity(AstralImprisonment, AstralImprisonmentTarget)
        return
    end

    ArcaneOrbDesire, ArcaneOrbTarget = X.ConsiderArcaneOrb()
    if ArcaneOrbDesire > 0
    then
        bot:Action_UseAbilityOnEntity(ArcaneOrb, ArcaneOrbTarget)
        return
    end
end

function X.ConsiderArcaneOrb()
    if not ArcaneOrb:IsFullyCastable()
    or ArcaneOrb:GetAutoCastState()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nMul = ArcaneOrb:GetSpecialValueInt('mana_pool_damage_pct') / 100
    local nDamage = bot:GetAttackDamage() + bot:GetMana() * nMul
    local nAttackRange = bot:GetAttackRange()
    botTarget = Fu.GetProperTarget(bot)

    if bGoingOnSomeone
	then
        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, nAttackRange)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        and not weakestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not weakestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not weakestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not weakestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, weakestTarget
            end
		end
	end

    -- if Fu.IsLaning(bot)
	-- then
	-- 	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nAttackRange + 200, true)

	-- 	for _, creep in pairs(nEnemyLaneCreeps)
	-- 	do
	-- 		if Fu.IsValid(creep)
	-- 		and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_PURE)
	-- 		then
	-- 			local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

	-- 			if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
	-- 			then
	-- 				return BOT_ACTION_DESIRE_HIGH, creep
	-- 			end
	-- 		end
	-- 	end
	-- end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAstralImprisonment()
    if not AstralImprisonment:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = AstralImprisonment:GetCastRange()
	local nDamage = AstralImprisonment:GetSpecialValueInt('damage')
    local nDuration = AstralImprisonment:GetSpecialValueInt('prison_duration')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and nInRangeAlly ~= nil and #nInRangeAlly <= 1
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

	if Fu.IsInTeamFight(bot, 1200)
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
        for _, allyHero in pairs(nInRangeAlly)
        do
            if Fu.IsValidHero(allyHero)
            and not allyHero:IsIllusion()
            and allyHero:WasRecentlyDamagedByAnyHero(1)
            then
                if allyHero:HasModifier('modifier_enigma_black_hole_pull')
                or allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                or allyHero:HasModifier('modifier_legion_commander_duel')
                or allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                or Fu.GetHP(allyHero) < 0.33
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end

        local strongestTarget = Fu.GetStrongestUnit(nCastRange + 150, bot, true, false, nDuration)
        if strongestTarget == nil
        then
            strongestTarget = Fu.GetStrongestUnit(nCastRange + 250, bot, true, true, nDuration)
        end
        if Fu.IsValidTarget(strongestTarget) then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(strongestTarget, 800, false, BOT_MODE_NONE)
            if #nTargetInRangeAlly >= 2 then
                if Fu.IsInRange(bot, strongestTarget, nCastRange)
                and not Fu.IsSuspiciousIllusion(strongestTarget)
                and not Fu.IsDisabled(strongestTarget)
                and not Fu.IsTaunted(strongestTarget)
                and not strongestTarget:HasModifier('modifier_abaddon_borrowed_time')
                and not strongestTarget:HasModifier('modifier_dazzle_shallow_grave')
                and not strongestTarget:HasModifier('modifier_enigma_black_hole_pull')
                and not strongestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
                and not strongestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
                then
                    return BOT_ACTION_DESIRE_HIGH, strongestTarget
                end
            end
        end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot, 1000, false, BOT_MODE_NONE)
            -- 1v1
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1000, false, BOT_MODE_NONE)
            if #nInRangeAlly <= 1 and #nTargetInRangeAlly <= 1 then return BOT_ACTION_DESIRE_HIGH, botTarget end

            -- has more then 1 enemy and target has high hp
            if #nTargetInRangeAlly >= 2 and Fu.GetHP(botTarget) > 0.8 then return BOT_ACTION_DESIRE_HIGH, botTarget end

            local isChasing = Fu.IsChasingTarget(bot, botTarget)
            -- more ally v less enemy but target not running
            if #nInRangeAlly >= 2 and #nTargetInRangeAlly <= 1 and not isChasing then return BOT_ACTION_DESIRE_NONE, nil end
            if #nInRangeAlly > 2 and #nInRangeAlly > #nTargetInRangeAlly and not isChasing then return BOT_ACTION_DESIRE_NONE, nil end

            -- more ally v less enemy and target running
            if #nInRangeAlly >= #nTargetInRangeAlly and isChasing then return BOT_ACTION_DESIRE_HIGH, botTarget end
            local nInLongRangeAlly = Fu.GetNearbyHeroes(bot, 1600, false, BOT_MODE_NONE)
            if #nInLongRangeAlly > #nInRangeAlly
            and #nInLongRangeAlly > #nTargetInRangeAlly
            and Fu.IsRunning(botTarget)
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
		end
	end

    if Fu.IsRetreating(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
        and not nInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.72 and bot:WasRecentlyDamagedByAnyHero(1.9)))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
            end
        end
    end

    if Fu.IsLaning(bot)
    and Fu.IsInLaningPhase()
	then
		if Fu.GetMP(bot) > 0.65
        then
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsAttacking(enemyHero)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and (not enemyHero:IsDisarmed()
                    or not enemyHero:IsStunned()
                    or not enemyHero:IsHexed())
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
	end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        then
            if nBotHP < 0.2
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end

            local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
            for _, allyHero in pairs(nInRangeAlly)
            do
                if Fu.IsValidHero(allyHero)
                and Fu.GetHP(allyHero) < 0.3
                and not allyHero:IsIllusion()
                and not allyHero:HasModifier('modifier_abaddon_borrowed_time')
                and not allyHero:HasModifier('modifier_dazzle_shallow_grave')
                and not allyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1.6)
        and not allyHero:IsChanneling()
        and not allyHero:IsIllusion()
        and Fu.GetMP(bot) > 0.31
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(allyHero, nAllyInRangeEnemy[1], 400)
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsRunning(allyHero)
            and nAllyInRangeEnemy[1]:IsFacingLocation(allyHero:GetLocation(), 30)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSanitysEclipse()
    if not SanitysEclipse:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = SanitysEclipse:GetCastRange()
	local nMultiplier = SanitysEclipse:GetSpecialValueFloat('damage_multiplier')
    local nBaseDamage = SanitysEclipse:GetSpecialValueFloat('base_damage')

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)

        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidTarget(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            then
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)
                local nManaDiff = math.abs(bot:GetMana() - enemyHero:GetMana())
                local nDamage = nManaDiff * nMultiplier

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                and Fu.CanKillTarget(enemyHero, nBaseDamage + nDamage, DAMAGE_TYPE_MAGICAL)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderObjurgation()
    if not Objurgation:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nBarrierPct = Objurgation:GetSpecialValueFloat('mana_pool_to_barrier_pct') / 100
    local nBarrierFlat = Objurgation:GetSpecialValueFloat('barrier')
    local nBarrier = nBarrierFlat + bot:GetMana() * nBarrierPct

    if Fu.IsInTeamFight(bot, 1200)
    then
        if nBotHP < 0.7
        and bot:WasRecentlyDamagedByAnyHero(2)
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        local nInRangeEnemy = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE)
        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone
    then
        botTarget = Fu.GetProperTarget(bot)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 200)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsRetreating(bot)
    then
        if nBotHP < 0.5
        and bot:WasRecentlyDamagedByAnyHero(2)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X