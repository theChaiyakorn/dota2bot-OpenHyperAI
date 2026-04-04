--------------------------------------------------------------------
-- rubick.lua — Smart stolen spell usage for Rubick
--
-- Strategy: classify stolen spells by behavior flags and use
-- situationally rather than requiring per-hero logic for every
-- possible stolen spell.
--------------------------------------------------------------------
local X = {}
local bot = GetBot()

-- Hero-specific handlers (for spells that need special logic)
local Abaddon = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/abaddon')
local AbyssalUnderlord = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/abyssal_underlord')
local Alchemist = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/alchemist')
local AncientApparition = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/ancient_apparition')
local Antimage = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/antimage')
local ArcWarden = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/arc_warden')
local Axe = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/axe')
local Bane = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/bane')
local Batrider = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/batrider')
local Beastmaster = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/beastmaster')
local Bloodseeker = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/bloodseeker')
local BountyHunter = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/bounty_hunter')
local Brewmaster = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/brewmaster')
local Bristleback = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/bristleback')
local Broodmother = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/broodmother')
local Centaur = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/centaur')
local ChaosKnight = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/chaos_knight')
local Chen = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/chen')
local Clinkz = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/clinkz')
local CrystalMaiden = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/crystal_maiden')
local Clockwerk = require(GetScriptDirectory()..'/FuncLib/hero/rubick_hero/rattletrap')

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local botTarget = nil

-- Behavior flag constants (fallback if Valve doesn't define them)
if DOTA_ABILITY_BEHAVIOR_UNIT_TARGET == nil then DOTA_ABILITY_BEHAVIOR_UNIT_TARGET = 8 end
if DOTA_ABILITY_BEHAVIOR_NO_TARGET == nil then DOTA_ABILITY_BEHAVIOR_NO_TARGET = 4 end
if DOTA_ABILITY_BEHAVIOR_POINT == nil then DOTA_ABILITY_BEHAVIOR_POINT = 16 end
if DOTA_ABILITY_BEHAVIOR_AOE == nil then DOTA_ABILITY_BEHAVIOR_AOE = 32 end
if DOTA_UNIT_TARGET_HERO == nil then DOTA_UNIT_TARGET_HERO = 1 end
if DOTA_UNIT_TARGET_TEAM_FRIENDLY == nil then DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1 end
if DOTA_UNIT_TARGET_TEAM_ENEMY == nil then DOTA_UNIT_TARGET_TEAM_ENEMY = 2 end
if DOTA_UNIT_TARGET_TEAM_BOTH == nil then DOTA_UNIT_TARGET_TEAM_BOTH = 3 end

--------------------------------------------------------------------
-- Main entry: try hero-specific handler first, then smart generic
--------------------------------------------------------------------
function X.ConsiderStolenSpell(ability)
    if ability:GetName() == 'rubick_empty1' or ability:GetName() == 'rubick_empty2'
        or not ability:IsFullyCastable()
    then return end

    botTarget = Fu.GetProperTarget(bot)

    -- Try hero-specific handlers (these know exact spell mechanics)
    Abaddon.ConsiderStolenSpell(ability)
    AbyssalUnderlord.ConsiderStolenSpell(ability)
    Alchemist.ConsiderStolenSpell(ability)
    AncientApparition.ConsiderStolenSpell(ability)
    Antimage.ConsiderStolenSpell(ability)
    ArcWarden.ConsiderStolenSpell(ability)
    Axe.ConsiderStolenSpell(ability)
    Bane.ConsiderStolenSpell(ability)
    Batrider.ConsiderStolenSpell(ability)
    Beastmaster.ConsiderStolenSpell(ability)
    Bloodseeker.ConsiderStolenSpell(ability)
    BountyHunter.ConsiderStolenSpell(ability)
    Brewmaster.ConsiderStolenSpell(ability)
    Bristleback.ConsiderStolenSpell(ability)
    Broodmother.ConsiderStolenSpell(ability)
    Centaur.ConsiderStolenSpell(ability)
    ChaosKnight.ConsiderStolenSpell(ability)
    Chen.ConsiderStolenSpell(ability)
    Clinkz.ConsiderStolenSpell(ability)
    CrystalMaiden.ConsiderStolenSpell(ability)
    Clockwerk.ConsiderStolenSpell(ability)

    -- Smart generic usage based on ability classification
    local props = X.ClassifyAbility(ability)
    local castDesire, castTarget = X.SmartCast(ability, props)
    if castDesire > 0 then
        Fu.SetQueuePtToINT(bot, true)
        if props.isNoTarget then
            bot:ActionQueue_UseAbility(ability)
        elseif props.isUnitTarget and castTarget and type(castTarget) ~= "number" then
            bot:ActionQueue_UseAbilityOnEntity(ability, castTarget)
        elseif (props.isPointTarget or props.isAOE) and castTarget then
            bot:ActionQueue_UseAbilityOnLocation(ability, castTarget)
        else
            bot:ActionQueue_UseAbility(ability)
        end
    end
end

--------------------------------------------------------------------
-- Classify ability by its behavior flags
--------------------------------------------------------------------
function X.ClassifyAbility(ability)
    local behavior = ability:GetBehavior()
    local targetTeam = ability:GetTargetTeam()
    local targetType = ability:GetTargetType()

    return {
        name         = ability:GetName(),
        castRange    = ability:GetCastRange(),
        manaCost     = ability:GetManaCost(),
        damage       = ability:GetAbilityDamage(),
        aoeRadius    = ability:GetAOERadius() or 0,
        isUltimate   = ability:IsUltimate(),

        -- Targeting
        isNoTarget   = bit.band(DOTA_ABILITY_BEHAVIOR_NO_TARGET, behavior) ~= 0,
        isUnitTarget = bit.band(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, behavior) ~= 0,
        isPointTarget= bit.band(DOTA_ABILITY_BEHAVIOR_POINT, behavior) ~= 0,
        isAOE        = bit.band(DOTA_ABILITY_BEHAVIOR_AOE, behavior) ~= 0,

        -- Team
        targetsEnemy = bit.band(DOTA_UNIT_TARGET_TEAM_ENEMY, targetTeam) ~= 0,
        targetsAlly  = bit.band(DOTA_UNIT_TARGET_TEAM_FRIENDLY, targetTeam) ~= 0,
        targetsHero  = bit.band(DOTA_UNIT_TARGET_HERO, targetType) ~= 0,
    }
end

--------------------------------------------------------------------
-- Smart cast: decide when/where/whom based on classification
--------------------------------------------------------------------
function X.SmartCast(ability, props)
    local nCastRange = props.castRange + 200
    local nRadius = props.aoeRadius > 0 and props.aoeRadius or 300
    local enemies = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE) or {}
    local allies = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE) or {}
    local botHP = Fu.GetHP(bot)
    local isTeamFight = Fu.IsInTeamFight(bot, 1200)
    local isEngaging = Fu.IsGoingOnSomeone(bot)
    local isRetreating = Fu.IsRetreating(bot)

    -- ULTIMATE SPELLS: save for team fights or high-value situations
    if props.isUltimate then
        return X.ConsiderUltimate(ability, props, enemies, allies, nCastRange, nRadius, isTeamFight)
    end

    -- ENEMY-TARGETING SPELLS
    if props.targetsEnemy or (not props.targetsAlly and not props.isNoTarget) then

        -- Priority 1: Interrupt channeling enemies
        for _, enemy in pairs(enemies) do
            if Fu.IsValidHero(enemy) and enemy:IsChanneling()
            and Fu.IsInRange(bot, enemy, nCastRange) and not enemy:IsMagicImmune() then
                if props.isUnitTarget then
                    return BOT_ACTION_DESIRE_HIGH, enemy
                elseif props.isPointTarget or props.isAOE then
                    return BOT_ACTION_DESIRE_HIGH, enemy:GetLocation()
                elseif props.isNoTarget and Fu.IsInRange(bot, enemy, nRadius) then
                    return BOT_ACTION_DESIRE_HIGH, nil
                end
            end
        end

        -- Priority 2: Interrupt TP
        local tpTarget = Fu.GetTPTarget(bot, nCastRange)
        if tpTarget and not tpTarget:IsMagicImmune() then
            if props.isUnitTarget then
                return BOT_ACTION_DESIRE_HIGH, tpTarget
            elseif props.isPointTarget or props.isAOE then
                return BOT_ACTION_DESIRE_HIGH, tpTarget:GetLocation()
            end
        end

        -- Priority 3: Kill potential (spell can finish off a low HP enemy)
        if props.damage > 0 then
            for _, enemy in pairs(enemies) do
                if Fu.IsValidHero(enemy) and Fu.IsInRange(bot, enemy, nCastRange)
                and not enemy:IsMagicImmune()
                and enemy:GetHealth() < props.damage * 0.8 then
                    if props.isUnitTarget then
                        return BOT_ACTION_DESIRE_HIGH, enemy
                    elseif props.isPointTarget then
                        return BOT_ACTION_DESIRE_HIGH, enemy:GetExtrapolatedLocation(0.3)
                    end
                end
            end
        end

        -- Priority 4: Team fight usage
        if isTeamFight and #enemies >= 2 then
            if props.isAOE or props.isPointTarget then
                local aoe = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
                if aoe.count >= 2 then
                    return BOT_ACTION_DESIRE_HIGH, aoe.targetloc
                end
            end
            if props.isNoTarget and #enemies >= 2 then
                return BOT_ACTION_DESIRE_HIGH, nil
            end
        end

        -- Priority 5: Engaging a target
        if isEngaging and Fu.IsValidHero(botTarget) and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanBeAttacked(botTarget) and not botTarget:IsMagicImmune() then
            if props.isUnitTarget then
                return BOT_ACTION_DESIRE_MODERATE, botTarget
            elseif props.isPointTarget then
                return BOT_ACTION_DESIRE_MODERATE, botTarget:GetExtrapolatedLocation(0.3)
            elseif props.isNoTarget then
                return BOT_ACTION_DESIRE_MODERATE, nil
            end
        end

        -- Priority 6: Retreating — use for self-defense
        if isRetreating and #enemies >= 1 and botHP < 0.5 then
            local closest = enemies[1]
            if Fu.IsValidHero(closest) and Fu.IsInRange(bot, closest, nCastRange) then
                if props.isUnitTarget then
                    return BOT_ACTION_DESIRE_HIGH, closest
                elseif props.isPointTarget then
                    return BOT_ACTION_DESIRE_HIGH, closest:GetLocation()
                elseif props.isNoTarget then
                    return BOT_ACTION_DESIRE_HIGH, nil
                end
            end
        end
    end

    -- ALLY-TARGETING SPELLS (heals, buffs, shields, saves)
    if props.targetsAlly and props.isUnitTarget then
        -- Save: ally being focused and low HP
        for _, ally in pairs(allies) do
            if Fu.IsValidHero(ally) and ally ~= bot
            and Fu.IsInRange(bot, ally, nCastRange) then
                local allyHP = Fu.GetHP(ally)

                -- Ally about to die
                if allyHP < 0.3 and ally:WasRecentlyDamagedByAnyHero(2.0) then
                    return BOT_ACTION_DESIRE_HIGH, ally
                end

                -- Ally in fight and hurt
                if allyHP < 0.5 and isTeamFight then
                    return BOT_ACTION_DESIRE_MODERATE, ally
                end
            end
        end

        -- Self-cast if we're the one in danger
        if botHP < 0.35 and bot:WasRecentlyDamagedByAnyHero(2.0) then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
    end

    -- NO-TARGET ALLY SPELLS (auras, team buffs)
    if props.isNoTarget and props.targetsAlly and isTeamFight then
        return BOT_ACTION_DESIRE_MODERATE, nil
    end

    return BOT_ACTION_DESIRE_NONE
end

--------------------------------------------------------------------
-- Ultimate handling: more conservative, save for high-value usage
--------------------------------------------------------------------
function X.ConsiderUltimate(ability, props, enemies, allies, nCastRange, nRadius, isTeamFight)
    -- Only use ultimates in team fights or for guaranteed kills
    if not isTeamFight and #enemies < 2 then
        -- Exception: kill potential on a lone enemy
        if props.damage > 0 and Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and botTarget:GetHealth() < props.damage * 0.8
        and not botTarget:IsMagicImmune() then
            if props.isUnitTarget then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            elseif props.isPointTarget then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(0.3)
            end
        end
        return BOT_ACTION_DESIRE_NONE
    end

    -- Team fight: validate we have advantage before committing
    if not Fu.IsSafeToUseUltimate(bot, bot:GetLocation(), 1200) then
        return BOT_ACTION_DESIRE_NONE
    end

    -- AoE ultimates: use FindAoELocation
    if props.isAOE or props.isPointTarget then
        local aoe = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        if aoe.count >= 2 then
            return BOT_ACTION_DESIRE_HIGH, aoe.targetloc
        end
    end

    -- Single-target ultimates on highest-threat enemy
    if props.isUnitTarget then
        local bestTarget = nil
        local bestHP = 1
        for _, enemy in pairs(enemies) do
            if Fu.IsValidHero(enemy) and Fu.IsInRange(bot, enemy, nCastRange)
            and not enemy:IsMagicImmune() and Fu.CanBeAttacked(enemy)
            and Fu.GetHP(enemy) < bestHP then
                bestHP = Fu.GetHP(enemy)
                bestTarget = enemy
            end
        end
        if bestTarget then
            return BOT_ACTION_DESIRE_HIGH, bestTarget
        end
    end

    -- No-target ultimates in team fights with 2+ enemies
    if props.isNoTarget and #enemies >= 2 then
        return BOT_ACTION_DESIRE_HIGH, nil
    end

    return BOT_ACTION_DESIRE_NONE
end

--------------------------------------------------------------------
-- Utility
--------------------------------------------------------------------
function X.CanCastAbilityROnTarget(nTarget)
    if Fu.CanCastOnTargetAdvanced(nTarget)
        and not nTarget:HasModifier("modifier_arc_warden_tempest_double")
    then
        return Fu.CanCastOnNonMagicImmune(nTarget)
    end
    return false
end

return X
