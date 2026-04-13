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
        ['t20'] = {10, 0},
        ['t15'] = {0, 10},
        ['t10'] = {0, 10},
    },
    {--pos3
        ['t25'] = {10, 0},
        ['t20'] = {10, 0},
        ['t15'] = {0, 10},
        ['t10'] = {10, 0},
    }
}

local tAllAbilityBuildList = {
    {1,3,3,2,3,6,3,2,2,2,6,1,1,1,6},--pos1
    {1,3,3,2,3,6,3,2,2,2,6,1,1,1,6},--pos3
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
    "item_double_branches",
    "item_faerie_fire",
    "item_magic_stick",
    "item_quelling_blade",

    "item_phase_boots",
    "item_magic_wand",
    "item_armlet",
    "item_bfury",--
    "item_black_king_bar",--
    "item_basher",
    "item_greater_crit",--
    "item_satanic",--
    "item_abyssal_blade",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_aghanims_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_magic_stick",
    "item_quelling_blade",

    "item_phase_boots",
    "item_magic_wand",
    "item_bfury",--
    "item_heavens_halberd",--
    "item_black_king_bar",--
    "item_assault",--
    "item_nullifier",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
    "item_basher",
    "item_monkey_king_bar",--
	"item_assault",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
    "item_abyssal_blade",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_pipe",--
    "item_basher",
    "item_monkey_king_bar",--
	"item_assault",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
    "item_abyssal_blade",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

local sRoleSellList = {}

sRoleSellList['pos_1'] = {
    "item_magic_wand", "item_greater_crit",
    "item_armlet", "item_abyssal_blade",
}

sRoleSellList['pos_2'] = sRoleSellList['pos_1']

sRoleSellList['pos_3'] = {
    "item_magic_wand", "item_nullifier",
}

sRoleSellList['pos_4'] = {
    "item_quelling_blade",
}

sRoleSellList['pos_5'] = {
    "item_quelling_blade",
}

X['sSellList'] = sRoleSellList[sRole] or {}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then
    X['sBuyList'], X['sSellList'] = { 'PvN_marci' }, {}
end

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

local Dispose          = SafeAbility(bot:GetAbilityByName("marci_grapple"), 'marci_grapple', 'marci')
local Rebound          = SafeAbility(bot:GetAbilityByName("marci_companion_run"), 'marci_companion_run', 'marci')
local Sidekick         = SafeAbility(bot:GetAbilityByName("marci_guardian"), 'marci_guardian', 'marci')
local Unleash          = SafeAbility(bot:GetAbilityByName("marci_unleash"), 'marci_unleash', 'marci')
local Bodyguard        = SafeAbility(bot:GetAbilityByName('marci_bodyguard'), 'marci_bodyguard', 'marci')
local SpecialDelivery  = SafeAbility(bot:GetAbilityByName('marci_special_delivery'), 'marci_special_delivery', 'marci')

local DisposeDesire, DisposeTaret
local ReboundDesire, ReboundTarget
local SidekickDesire, SidekickTarget
local UnleashDesire
local BodyguardDesire, BodyguardTarget
local SpecialDeliveryDesire

local bAttacking = false
local botTarget, botHP
local nAllyHeroes, nEnemyHeroes

function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

    bAttacking = Fu.IsAttacking(bot)
    botHP = Fu.GetHP(bot)
    botTarget = Fu.GetProperTarget(bot)
    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    UnleashDesire = X.ConsiderUnleash()
    if UnleashDesire > 0 then
        bot:Action_UseAbility(Unleash)
        return
    end

    DisposeDesire, DisposeTaret = X.ConsiderDispose()
    if DisposeDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(Dispose, DisposeTaret)
        return
    end

    ReboundDesire, ReboundTarget = X.ConsiderRebound()
    if ReboundDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(Rebound, ReboundTarget)
        return
    end

    SidekickDesire, SidekickTarget = X.ConsiderSidekick()
    if SidekickDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(Sidekick, SidekickTarget)
        return
    end

    BodyguardDesire, BodyguardTarget = X.ConsiderBodyguard()
    if BodyguardDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(Bodyguard, BodyguardTarget)
        return
    end

    -- SpecialDeliveryDesire = X.ConsiderSpecialDelivery()
end

function X.ConsiderBodyguard()
    if not Fu.CanCastAbility(Bodyguard) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Bodyguard:GetCastRange())

    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1200, true)

    if (Fu.IsGoingOnSomeone(bot) and bot:WasRecentlyDamagedByAnyHero(5.0))
    or (Fu.IsPushing(bot) and #nEnemyHeroes > 0)
    or (Fu.IsDefending(bot) and #nEnemyHeroes > 0)
    or (Fu.IsLaning(bot) and #nEnemyLaneCreeps >= 3)
    or (Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget) and Fu.IsInRange(bot, botTarget, 800) and bAttacking and Fu.CanBeAttacked(botTarget))
    or (Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget) and Fu.IsInRange(bot, botTarget, 800) and bAttacking and Fu.CanBeAttacked(botTarget))
    then
        local target = nil
        local targetHealth = math.huge
        for _, ally in pairs(nAllyHeroes) do
            if Fu.IsValidHero(ally)
            and bot ~= ally
            and Fu.IsInRange(bot, ally, nCastRange)
            and not ally:IsIllusion()
            and not ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not ally:HasModifier('modifier_marci_guardian_buff')
            and not ally:HasModifier('modifier_necrolyte_reapers_scythe')
            and not Fu.IsMeepoClone(ally)
            then
                local allyHealth = ally:GetHealth()
                if targetHealth > allyHealth then
                    target = ally
                    targetHealth = allyHealth
                end
            end
        end

        if target ~= nil then
            return BOT_ACTION_DESIRE_HIGH, target
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderDispose()
    if not Fu.CanCastAbility(Dispose) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Dispose:GetCastRange())
    local nCastPoint = Dispose:GetCastPoint()
    local nDamage = Dispose:GetSpecialValueInt('impact_damage')
    local fDuration = Dispose:GetSpecialValueInt('air_duration')

    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        then
            if Fu.GetModifierTime(enemyHero, 'modifier_teleporting') > fDuration + nCastPoint then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, fDuration + nCastPoint)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + 300)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and bot:IsFacingLocation(Fu.GetTeamFountain(), 30)
            and bot:IsFacingLocation(enemyHero:GetLocation(), 15)
            and not Fu.IsDisabled(enemyHero)
            and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
            then
                if GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) > GetUnitToLocationDistance(enemyHero, Fu.GetTeamFountain()) then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

-- vector targeted; not reliable
function X.ConsiderRebound()
    if not Fu.CanCastAbility(Rebound)
    or bot:IsRooted()
    or (bot:HasModifier('modifier_marci_unleash') and not Fu.IsRetreating(bot))
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Rebound:GetCastRange()
    local nDamage = Rebound:GetSpecialValueInt('impact_damage')
    local nRadius = Rebound:GetSpecialValueInt('landing_radius')
    local nJumpDistance = Rebound:GetSpecialValueInt('max_jump_distance')
    local nManaCost = Rebound:GetManaCost()
    local fManaAfter = Fu.GetManaAfter(nManaCost)
    local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Rebound, Bodyguard, Unleash})

    for _, ally in pairs(GetUnitList(UNIT_LIST_ALLIES)) do
        if Fu.IsValid(ally)
        and bot ~= ally
        and Fu.IsInRange(bot, ally, nCastRange)
        and (ally:IsHero() or ally:IsCreep())
        and not ally:HasModifier('modifier_enigma_black_hole_pull')
        and not ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
        then
            if Fu.IsGoingOnSomeone(bot) then
                if Fu.IsValidHero(botTarget)
                and Fu.CanBeAttacked(botTarget)
                and Fu.IsInRange(ally, botTarget, nRadius)
                and Fu.CanCastOnNonMagicImmune(botTarget)
                and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
                and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    return BOT_ACTION_DESIRE_HIGH, ally
                end
            end

            if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and not Fu.IsInRange(bot, ally, nCastRange / 2) and ally:DistanceFromFountain() < bot:DistanceFromFountain() then
                local targetDir = (Fu.GetTeamFountain() - bot:GetLocation()):Normalized()
                local allyDir = (ally:GetLocation() - bot:GetLocation()):Normalized()
                local dot = Fu.DotProduct(targetDir, allyDir)
                local nAngle = math.deg(math.acos(dot))

                if nAngle <= 40 then
                    for _, enemyHero in pairs(nEnemyHeroes) do
                        if Fu.IsValidHero(enemyHero)
                        and Fu.IsInRange(bot, enemyHero, 800)
                        and not Fu.IsSuspiciousIllusion(enemyHero)
                        and not Fu.IsDisabled(enemyHero)
                        then
                            if #nEnemyHeroes > #nAllyHeroes or bot:WasRecentlyDamagedByHero(enemyHero, 3.0) then
                                return BOT_ACTION_DESIRE_HIGH, enemyHero
                            end
                        end
                    end
                end
            end

            if ally:IsHero() then
                local nEnemyCreeps = ally:GetNearbyCreeps(nRadius, true)

                if Fu.IsPushing(bot) and bAttacking and fManaAfter > fManaThreshold1 and #nAllyHeroes <= 2 and #nEnemyHeroes == 0 then
                    if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) then
                        if (#nEnemyCreeps >= 4) then
                            return BOT_ACTION_DESIRE_HIGH, ally
                        end
                    end
                end

                if Fu.IsDefending(bot) and bAttacking and fManaAfter > fManaThreshold1 and #nAllyHeroes <= 3 and #nEnemyHeroes == 0 then
                    if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) then
                        if (#nEnemyCreeps >= 4) then
                            return BOT_ACTION_DESIRE_HIGH, ally
                        end
                    end
                end

                if Fu.IsFarming(bot) and bAttacking and fManaAfter > fManaThreshold1 then
                    if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) then
                        if (#nEnemyCreeps >= 3)
                        or (#nEnemyCreeps >= 2 and nEnemyCreeps[1]:IsAncientCreep())
                        or (#nEnemyCreeps >= 1 and nEnemyCreeps[1]:GetHealth() >= 550)
                        then
                            return BOT_ACTION_DESIRE_HIGH, ally
                        end
                    end
                end

                if Fu.IsLaning(bot) and Fu.IsEarlyGame() and fManaAfter > fManaThreshold1 and #nEnemyHeroes == 0 then
                    local nLocationAoE = bot:FindAoELocation(true, false, ally:GetLocation(), 0, nRadius - 75, 0, nDamage)
                    if nLocationAoE.count >= 3 then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end

                if Fu.IsDoingRoshan(bot) then
                    if Fu.IsRoshan(botTarget)
                    and Fu.CanBeAttacked(botTarget)
                    and Fu.IsInRange(ally, botTarget, nRadius)
                    and bAttacking
                    and fManaAfter > fManaThreshold1 + 0.1
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end

                if Fu.IsDoingTormentor(bot) then
                    if Fu.IsTormentor(botTarget)
                    and Fu.IsInRange(ally, botTarget, nRadius)
                    and bAttacking
                    and fManaAfter > fManaThreshold1 + 0.1
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end
            end

            local nInRangeEnemy = Fu.GetEnemiesNearLoc(ally:GetLocation(), nRadius)
            for _, enemy in pairs(nInRangeEnemy) do
                if Fu.IsValidHero(enemy)
                and Fu.CanBeAttacked(enemy)
                and Fu.CanCastOnNonMagicImmune(enemy)
                then
                    if enemy:HasModifier('modifier_teleporting') then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end

                    if Fu.CanKillTarget(enemy, nDamage, DAMAGE_TYPE_MAGICAL)
                    and not enemy:HasModifier('modifier_abaddon_borrowed_time')
                    and not enemy:HasModifier('modifier_dazzle_shallow_grave')
                    and not enemy:HasModifier('modifier_enigma_black_hole_pull')
                    and not enemy:HasModifier('modifier_faceless_void_chronosphere_freeze')
                    and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
                    and not enemy:HasModifier('modifier_oracle_false_promise_timer')
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSidekick()
    if not Fu.CanCastAbility(Sidekick) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Sidekick:GetCastRange())

    local tEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1200, true)

    if Fu.IsGoingOnSomeone(bot)
    or Fu.IsPushing(bot)
    or Fu.IsDefending(bot)
    or (Fu.IsLaning(bot) and #tEnemyLaneCreeps >= 3)
    or (Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget) and Fu.IsInRange(bot, botTarget, 800) and Fu.IsAttacking(bot) and Fu.CanBeAttacked(botTarget))
    or (Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget) and Fu.IsInRange(bot, botTarget, 800) and Fu.IsAttacking(bot) and Fu.CanBeAttacked(botTarget))
    then
        local nAllyHeroes = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)

        local target = nil
        local targetAttackDamage = 0
        for _, ally in pairs(nAllyHeroes) do
            if Fu.IsValidHero(ally)
            and bot ~= ally
            and Fu.IsInRange(bot, ally, nCastRange)
            and not ally:IsIllusion()
            and not Fu.IsMeepoClone(ally)
            and not ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not ally:HasModifier('modifier_marci_guardian_buff')
            and not ally:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local allyAttackDamage = ally:GetAttackDamage() * ally:GetAttackSpeed()
                if allyAttackDamage > targetAttackDamage then
                    targetAttackDamage = allyAttackDamage
                    target = ally
                end
            end
        end

        if target ~= nil then
            return BOT_ACTION_DESIRE_HIGH, target
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderUnleash()
    if not Fu.CanCastAbility(Unleash) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nPulseDamage = Unleash:GetSpecialValueInt('pulse_damage')
    local nPunchCount = Unleash:GetSpecialValueInt('charges_per_flurry')

    if Fu.IsInTeamFight(bot, 800) then
        local nCoreCount = 0
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy) and Fu.IsCore(enemy) then
                nCoreCount = nCoreCount + 1
            end
        end

        if nCoreCount > 0 or (Fu.IsLateGame() or bot:HasModifier('modifier_dazzle_shallow_grave') or bot:HasModifier('modifier_oracle_false_promise_timer')) then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and botTarget:GetHealth() > (nPulseDamage + bot:GetAttackDamage() * (nPunchCount + 2))
        and not Fu.IsChasingTarget(bot, botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_item_blade_mail_reflect')
        and not botTarget:HasModifier('modifier_item_aeon_disk_buff')
        then
            local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 800)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)
            if not (#nInRangeAlly >= #nInRangeEnemy + 2) then
                if (Fu.GetTotalEstimatedDamageToTarget(nInRangeAlly, botTarget) > botTarget:GetHealth())
                or (bAttacking and botHP < 0.35)
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X