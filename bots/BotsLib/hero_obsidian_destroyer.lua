local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
	{--pos1/2
		['t25'] = {0, 10},
		['t20'] = {10, 0},
		['t15'] = {10, 0},
		['t10'] = {10, 0},
	},
}

local tAllAbilityBuildList = {
	{2,1,3,2,2,6,2,1,1,1,6,3,3,3,6},--pos1: astral>orb>equilibrium
	{2,1,3,2,2,6,2,1,1,1,6,3,3,3,6},--pos2: astral>orb>equilibrium
}

local nAbilityBuildList
local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])

if sRole == "pos_1" then
    nAbilityBuildList = tAllAbilityBuildList[1]
else
    nAbilityBuildList = tAllAbilityBuildList[2]
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_magic_wand",
    "item_double_null_talisman",
    "item_power_treads",
    "item_witch_blade",
    "item_force_staff",
    "item_hurricane_pike",--
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_devastator",--
    "item_sheepstick",--
    "item_shivas_guard",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_mantle",

    "item_magic_wand",
    "item_double_null_talisman",
    "item_power_treads",
    "item_witch_blade",
    "item_force_staff",
    "item_hurricane_pike",--
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_devastator",--
    "item_sheepstick",--
    "item_shivas_guard",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_2']
sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_2']
sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_2']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
    "item_magic_wand",
    "item_black_king_bar",

    "item_null_talisman",
    "item_sheepstick",

    "item_null_talisman",
    "item_shivas_guard",
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

local ArcaneOrb             = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_arcane_orb'), 'obsidian_destroyer_arcane_orb', 'obsidian_destroyer')
local AstralImprisonment    = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_astral_imprisonment'), 'obsidian_destroyer_astral_imprisonment', 'obsidian_destroyer')
local EssenceFlux           = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_equilibrium'), 'obsidian_destroyer_equilibrium', 'obsidian_destroyer')
local Objurgation           = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_objurgation'), 'obsidian_destroyer_objurgation', 'obsidian_destroyer')
local SanitysEclipse        = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_sanity_eclipse'), 'obsidian_destroyer_sanity_eclipse', 'obsidian_destroyer')

local ArcaneOrbDesire, ArcaneOrbTarget
local AstralImprisonmentDesire, AstralImprisonmentTarget
local SanitysEclipseDesire, SanitysEclipseLocation
local ObjurgationDesire

local bAttacking = false
local botTarget, botHP
local nAllyHeroes, nEnemyHeroes

function X.SkillsComplement()
    bot = GetBot()

    if Fu.CanNotUseAbility(bot) then return end

    ArcaneOrb             = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_arcane_orb'), 'obsidian_destroyer_arcane_orb', 'obsidian_destroyer')
    AstralImprisonment    = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_astral_imprisonment'), 'obsidian_destroyer_astral_imprisonment', 'obsidian_destroyer')
    EssenceFlux           = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_equilibrium'), 'obsidian_destroyer_equilibrium', 'obsidian_destroyer')
    Objurgation           = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_objurgation'), 'obsidian_destroyer_objurgation', 'obsidian_destroyer')
    SanitysEclipse        = SafeAbility(bot:GetAbilityByName('obsidian_destroyer_sanity_eclipse'), 'obsidian_destroyer_sanity_eclipse', 'obsidian_destroyer')

    bAttacking = Fu.IsAttacking(bot)
    botHP = Fu.GetHP(bot)
    botTarget = Fu.GetProperTarget(bot)
    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    ObjurgationDesire = X.ConsiderObjurgation()
    if ObjurgationDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbility(Objurgation)
        return
    end

    SanitysEclipseDesire, SanitysEclipseLocation = X.ConsiderSanitysEclipse()
    if SanitysEclipseDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(SanitysEclipse, SanitysEclipseLocation)
        return
    end

    AstralImprisonmentDesire, AstralImprisonmentTarget = X.ConsiderAstralImprisonment()
    if AstralImprisonmentDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(AstralImprisonment, AstralImprisonmentTarget)
        return
    end

    ArcaneOrbDesire, ArcaneOrbTarget = X.ConsiderArcaneOrb()
    if ArcaneOrbDesire > 0 then
        bot:Action_UseAbilityOnEntity(ArcaneOrb, ArcaneOrbTarget)
        return
    end
end

function X.ConsiderArcaneOrb()
    if not ArcaneOrb:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local botAttackRange = bot:GetAttackRange()
    local nMul = ArcaneOrb:GetSpecialValueInt('mana_pool_damage_pct') / 100
    local nDamage = bot:GetAttackDamage() + bot:GetMana() * nMul
    local nAbilityLevel = ArcaneOrb:GetLevel()
    local bIsAutoCasted = ArcaneOrb:GetAutoCastState()
    local nManaCost = ArcaneOrb:GetManaCost()
    local fManaAfter = Fu.GetManaAfter(nManaCost)
    local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {AstralImprisonment, Objurgation, SanitysEclipse})

    if nAbilityLevel == 4 and not bIsAutoCasted then
        ArcaneOrb:ToggleAutoCast()
    end

    if bIsAutoCasted then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, botAttackRange + 300)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        then
            local eta = (GetUnitToUnitDistance(bot, enemyHero) / bot:GetAttackProjectileSpeed())
            if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, eta)
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

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, botAttackRange + 150)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    local nEnemyCreeps = bot:GetNearbyCreeps(Min(botAttackRange + 300, 1600), true)

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot) or Fu.IsFarming(bot)) and bAttacking and fManaAfter > fManaThreshold1 + 0.1 then
        if Fu.IsValid(botTarget) and Fu.CanBeAttacked(botTarget) and botTarget:IsCreep() then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if not Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
        if Fu.IsEarlyGame() then
            for _, enemyHero in pairs(nEnemyHeroes) do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanBeAttacked(enemyHero)
                and Fu.IsInRange(bot, enemyHero, botAttackRange + 150)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end

        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and (Fu.IsCore(bot) or not Fu.IsOtherAllysTarget(creep)) then
                local eta = (GetUnitToUnitDistance(bot, creep) / bot:GetAttackProjectileSpeed())
                if Fu.WillKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
                    return BOT_ACTION_DESIRE_HIGH, creep
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot) then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, botAttackRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, botAttackRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAstralImprisonment()
    if not AstralImprisonment:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = AstralImprisonment:GetCastRange()
    local nDamage = AstralImprisonment:GetSpecialValueInt('damage')
    local nDuration = AstralImprisonment:GetSpecialValueInt('prison_duration')
    local nManaCost = AstralImprisonment:GetManaCost()
    local fManaAfter = Fu.GetManaAfter(nManaCost)
    local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {SanitysEclipse})

    if #nAllyHeroes >= #nEnemyHeroes then
        if Fu.GetAttackProjectileDamageByRange(bot, 800) > bot:GetHealth() then
            return BOT_ACTION_DESIRE_HIGH, bot
        end

        if not bot:IsMagicImmune() then
            if Fu.IsStunProjectileIncoming(bot, 600) and botHP < 0.2 then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and fManaAfter > fManaThreshold1
        then
            if enemyHero:IsChanneling() then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            local nAllyHeroesTargetingTarget = Fu.GetHeroesTargetingUnit(nAllyHeroes, enemyHero)

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and #nAllyHeroesTargetingTarget <= 1
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

    if Fu.IsInTeamFight(bot, 1200) and fManaAfter > fManaThreshold1 then
        for _, allyHero in pairs(nAllyHeroes) do
            if Fu.IsValidHero(allyHero)
            and Fu.CanBeAttacked(allyHero)
            and Fu.IsInRange(bot, allyHero, nCastRange + 300)
            and not allyHero:IsIllusion()
            then
                if allyHero:HasModifier('modifier_enigma_black_hole_pull')
                or allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                or allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                or (allyHero:HasModifier('modifier_legion_commander_duel') and Fu.GetHP(allyHero) < 0.1)
                or (Fu.GetHP(allyHero) < 0.33 and Fu.IsRetreating(allyHero))
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end

        local hTarget = nil
        local hTargetDamage = 0
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                if enemyHero:HasModifier('modifier_abaddon_borrowed_time')
                or enemyHero:HasModifier('modifier_dazzle_shallow_grave')
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end

                local enemyHeroDamage = enemyHero:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_ALL)
                local nTotalAllyDamage = Fu.GetTotalEstimatedDamageToTarget(nAllyHeroes, enemyHero, 5.0)

                if enemyHeroDamage > hTargetDamage and nTotalAllyDamage < enemyHero:GetHealth() then
                    hTarget = enemyHero
                    hTargetDamage = enemyHeroDamage
                end
            end
        end

        if hTarget then
            return BOT_ACTION_DESIRE_HIGH, hTarget
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and fManaAfter > fManaThreshold1
        then
            local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 800)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)

            if not (#nInRangeAlly >= #nInRangeEnemy + 2) then
                if #nInRangeAlly <= 1 then
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end

                local nTotalDamage = 0
                for _, allyHero in pairs(nAllyHeroes) do
                    if Fu.IsValidHero(allyHero)
                    and bot ~= allyHero
                    and not allyHero:IsIllusion()
                    and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                    and not allyHero:HasModifier('modifier_teleporting')
                    and (allyHero:GetAttackTarget() == botTarget or Fu.IsChasingTarget(allyHero, botTarget))
                    then
                        nTotalDamage = nTotalDamage + allyHero:GetEstimatedDamageToTarget(true, botTarget, nDuration, DAMAGE_TYPE_ALL)
                    end
                end

                if nTotalDamage * 1.25 < botTarget:GetHealth() then
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and bot:WasRecentlyDamagedByHero(enemyHero, 5.0)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

    if not Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and not Fu.IsInTeamFight(bot, 1200) and fManaAfter > fManaThreshold1 then
        for _, allyHero in pairs(nAllyHeroes) do
            if Fu.IsValidHero(allyHero)
            and bot ~= allyHero
            and Fu.IsRetreating(allyHero)
            and not allyHero:IsIllusion()
            then
                for _, enemyHero in pairs(nEnemyHeroes) do
                    if Fu.IsValidHero(enemyHero)
                    and Fu.CanBeAttacked(enemyHero)
                    and Fu.IsInRange(bot, enemyHero, nCastRange)
                    and Fu.CanCastOnNonMagicImmune(enemyHero)
                    and Fu.CanCastOnTargetAdvanced(enemyHero)
                    and not Fu.IsDisabled(enemyHero)
                    and allyHero:WasRecentlyDamagedByHero(enemyHero, 5.0)
                    and Fu.IsChasingTarget(enemyHero, allyHero)
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end
                end
            end
        end
    end

    if Fu.IsLaning(bot) and Fu.IsEarlyGame() and fManaAfter > fManaThreshold1 then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange + 200)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsAttacking(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 800)
                local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)
                if not (#nInRangeAlly >= #nInRangeEnemy + 2) then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        then
            for _, allyHero in pairs(nAllyHeroes) do
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

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSanitysEclipse()
    if not SanitysEclipse:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = SanitysEclipse:GetCastRange()
    local nCastPoint = SanitysEclipse:GetCastPoint()
    local nMultiplier = SanitysEclipse:GetSpecialValueFloat('damage_multiplier')
    local nBaseDamage = SanitysEclipse:GetSpecialValueFloat('base_damage')

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
        and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not enemyHero:HasModifier('modifier_legion_commander_duel')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        then
            local eta = (GetUnitToUnitDistance(bot, enemyHero) / bot:GetCurrentMovementSpeed()) + nCastPoint
            local nManaDiff = math.abs(bot:GetMana() - enemyHero:GetMana())
            local nDamage = nManaDiff * nMultiplier

            if Fu.WillKillTarget(enemyHero, nBaseDamage + nDamage, DAMAGE_TYPE_MAGICAL, eta) then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderObjurgation()
    if not Objurgation:IsFullyCastable() then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(2.0) and botHP < 0.6 then
        if (#nEnemyHeroes > #nAllyHeroes)
        or (bot:IsRooted())
        or (Fu.GetTotalEstimatedDamageToTarget(nEnemyHeroes, bot, 6.0) > bot:GetHealth())
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(2.0) then
        if Fu.GetTotalEstimatedDamageToTarget(nEnemyHeroes, bot, 5.0) > bot:GetHealth() then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingRoshan(bot) then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and bAttacking
        and botHP < 0.3
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and bAttacking
        and botHP < 0.35
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X