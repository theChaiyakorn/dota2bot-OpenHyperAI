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
        ['t15'] = {10, 0},
        ['t10'] = {0, 10},
    },
    {--pos3
        ['t25'] = {10, 0},
        ['t20'] = {10, 0},
        ['t15'] = {10, 0},
        ['t10'] = {0, 10},
    }
}

local tAllAbilityBuildList = {
    {1,3,2,2,2,6,2,3,3,3,1,6,1,1,6},--pos1
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
    "item_faerie_fire",
    "item_branches",
    "item_branches",
    "item_quelling_blade",
    "item_circlet",
    "item_magic_wand",

    "item_phase_boots",
    "item_soul_ring",
    -- "item_echo_sabre",
    "item_basher",
    "item_greater_crit",--
    "item_black_king_bar",--
    "item_monkey_king_bar",--
    "item_abyssal_blade",--
    "item_satanic",--
    "item_ultimate_scepter",
    "item_moon_shard",
    "item_travel_boots",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
	"item_crimson_guard",--
    "item_basher",
	"item_heavens_halberd",--
	"item_travel_boots",
    "item_monkey_king_bar",--
	"item_assault",--
	-- "item_sheepstick",--
	"item_aghanims_shard",
	"item_ultimate_scepter",
    "item_abyssal_blade",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
	-- "item_octarine_core",--
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

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
}

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

    SpecialDeliveryDesire = X.ConsiderSpecialDelivery()
    if SpecialDeliveryDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbility(SpecialDelivery)
        return
    end
end

function X.ConsiderSpecialDelivery()
    return 0
end

function X.ConsiderBodyguard()
    if not Fu.CanCastAbility(Bodyguard) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Bodyguard:GetCastRange())

    local tEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1200, true)

    if bGoingOnSomeone
    or Fu.IsPushing(bot)
    or Fu.IsDefending(bot)
    or (Fu.IsLaning(bot) and #tEnemyLaneCreeps >= 3)
    or (Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget) and Fu.IsInRange(bot, botTarget, 800) and bAttacking and Fu.CanBeAttacked(botTarget))
    or (Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget) and Fu.IsInRange(bot, botTarget, 800) and bAttacking and Fu.CanBeAttacked(botTarget))
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

function X.ConsiderDispose()
    if not Fu.CanCastAbility(Dispose)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Dispose:GetCastRange())
    local nDamage = Dispose:GetSpecialValueInt('impact_damage')

    local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        then
            if enemyHero:HasModifier('modifier_teleporting') then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
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

	if bGoingOnSomeone
	then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            if GetUnitToLocationDistance(bot, Fu.GetEnemyFountain()) > GetUnitToLocationDistance(botTarget, Fu.GetEnemyFountain()) then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
        end
	end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if  Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and bot:IsFacingLocation(Fu.GetTeamFountain(), 30)
            and bot:IsFacingLocation(enemyHero:GetLocation(), 30)
            and enemyHero:GetAttackTarget() == bot
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
	end

    -- ally save ..

    return BOT_ACTION_DESIRE_NONE
end

-- vector targeted; not reliable
function X.ConsiderRebound()
    if not Fu.CanCastAbility(Rebound)
    or bot:IsRooted()
    or (bot:HasModifier('modifier_marci_unleash') and not bRetreating)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nDamage = Rebound:GetSpecialValueInt('impact_damage')
    local nRadius = Rebound:GetSpecialValueInt('landing_radius')
    local nJumpDistance = Rebound:GetSpecialValueInt('max_jump_distance')
    local nManaAfter = Fu.GetManaAfter(Rebound:GetManaCost())

    local nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, ally in pairs(GetUnitList(UNIT_LIST_ALLIES)) do
        if Fu.IsValid(ally)
        and bot ~= ally
        and Fu.IsInRange(bot, ally, nJumpDistance)
        and (ally:IsHero() or ally:IsCreep())
        and not ally:HasModifier('modifier_enigma_black_hole_pull')
        and not ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
        then
            if bGoingOnSomeone and not Fu.IsInTeamFight(bot, 1600) then -- don't go jumping around teamfights
                if Fu.IsValidHero(botTarget)
                and Fu.CanBeAttacked(botTarget)
                and Fu.IsInRange(bot, ally, nRadius)
                and Fu.CanCastOnNonMagicImmune(botTarget)
                and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
                and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    return BOT_ACTION_DESIRE_HIGH, ally
                end
            end

            if bRetreating
            and not Fu.IsRealInvisible(bot)
            and bot:WasRecentlyDamagedByAnyHero(3.0)
            and GetUnitToUnitDistance(bot, ally) >= nJumpDistance - 300
            and ally:DistanceFromFountain() < bot:DistanceFromFountain()
            then
                local vAllyToFountain = (Fu.GetTeamFountain() - ally:GetLocation()):Normalized()
                local vBotToFountain = (Fu.GetTeamFountain() - bot:GetLocation()):Normalized()
                if Fu.DotProduct(vAllyToFountain, vBotToFountain) >= 0.5 then -- at least 45*
                    if #nEnemyHeroes > #nAllyHeroes + 1 and Fu.GetHP(bot) < 0.6 then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end

                    for _, enemy in pairs(nEnemyHeroes) do
                        if Fu.IsValidHero(enemy)
                        and Fu.IsChasingTarget(enemy, bot)
                        and not Fu.IsSuspiciousIllusion(enemy)
                        then
                            return BOT_ACTION_DESIRE_HIGH, ally
                        end
                    end
                end
            end

            if ally:IsHero() then
                local tEnemyLaneCreeps = ally:GetNearbyLaneCreeps(nRadius, true)

                if Fu.IsPushing(bot) and nManaAfter > 0.3 then
                    if #tEnemyLaneCreeps >= 4
                    and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
                    and not Fu.IsRunning(tEnemyLaneCreeps[1])
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end
    
                if Fu.IsDefending(bot) and nManaAfter > 0.3 then
                    if #tEnemyLaneCreeps >= 3
                    and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
                    and not Fu.IsRunning(tEnemyLaneCreeps[1])
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end
    
                local tCreeps = ally:GetNearbyCreeps(nRadius, true)
    
                if Fu.IsFarming(bot) and nManaAfter > 0.25 then
                    if (#tCreeps >= 3 or #tCreeps >= 2 and tCreeps[1]:IsAncientCreep())
                    and Fu.CanBeAttacked(tCreeps[1])
                    and not Fu.IsRunning(tCreeps[1])
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end
    
                if Fu.IsLaning(bot) and nManaAfter > 0.25 then
                    local nCanKillCreeps = 0
                    if Fu.IsCore(bot) or (not Fu.IsCore(bot) and not Fu.IsThereNonSelfCoreNearby(1200)) then
                        for _, creep in pairs(tCreeps) do
                            if Fu.IsValid(creep)
                            and Fu.CanBeAttacked(creep)
                            and not Fu.IsRunning(creep)
                            and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL) then
                                nCanKillCreeps = nCanKillCreeps + 1
                            end
                        end
    
                        if nCanKillCreeps >= 3 then
                            return BOT_ACTION_DESIRE_HIGH, ally
                        end
                    end
                end
            end

            if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot) then
                if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
                and Fu.CanBeAttacked(botTarget)
                and Fu.IsInRange(ally, botTarget, nRadius)
                and bAttacking
                then
                    return BOT_ACTION_DESIRE_HIGH, ally
                end
            end

            local tAllyEnemy = Fu.GetEnemiesNearLoc(ally:GetLocation(), nRadius)
            for _, enemy in pairs(tAllyEnemy) do
                if Fu.IsValidHero(enemy)
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

    if bGoingOnSomeone
    or Fu.IsPushing(bot)
    or Fu.IsDefending(bot)
    or (Fu.IsLaning(bot) and #tEnemyLaneCreeps >= 3)
    or (Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget) and Fu.IsInRange(bot, botTarget, 800) and bAttacking and Fu.CanBeAttacked(botTarget))
    or (Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget) and Fu.IsInRange(bot, botTarget, 800) and bAttacking and Fu.CanBeAttacked(botTarget))
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

    local nAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 800)
    local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

    if Fu.IsInTeamFight(bot, 1200) then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 600)
        local nCoreCount = 0
        for _, enemy in pairs(nInRangeEnemy) do
            if Fu.IsValidHero(enemy) and Fu.IsCore(enemy) then
                nCoreCount = nCoreCount + 1
            end
        end

        if nCoreCount > 0 then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange() * 1.5)
        and Fu.CanBeAttacked(botTarget)
        and botTarget:GetHealth() > (nPulseDamage + bot:GetAttackDamage() * (nPunchCount + 2))
        and not Fu.IsChasingTarget(bot, botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_item_blade_mail_reflect')
        and not botTarget:HasModifier('modifier_item_aeon_disk_buff')
        and not (#nAllyHeroes >= #nEnemyHeroes + 3)
        then
            if Fu.IsInLaningPhase() and #nAllyHeroes <= 2 and #nEnemyHeroes <= 1 then
                return BOT_ACTION_DESIRE_HIGH
            end
            if Fu.IsCore(botTarget) then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X