--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local Fu = require(GetScriptDirectory().."/FuncLib/func_utils")
local ____dota = require(GetScriptDirectory().."/ts_libs/dota/index")
local BotActionDesire = ____dota.BotActionDesire
local BotMode = ____dota.BotMode
local UnitType = ____dota.UnitType
local ____buff = require(GetScriptDirectory().."/FuncLib/data/buff")
local hero_is_healing = ____buff.hero_is_healing
local ____utils = require(GetScriptDirectory().."/FuncLib/systems/utils")
local GetTeamFountainTpPoint = ____utils.GetTeamFountainTpPoint
local HasAnyEffect = ____utils.HasAnyEffect
local IsValidHero = ____utils.IsValidHero
local ____hero_builder = require(GetScriptDirectory().."/FuncLib/hero/hero_builder")
local buildHeroConfig = ____hero_builder.buildHeroConfig
local buildHeroExport = ____hero_builder.buildHeroExport
--- HP threshold below which Relocate activates for self or ally escape.
local RELOCATE_HP_THRESHOLD = 0.2
--- HP ratio of ally below which Tether becomes desirable for healing.
local TETHER_ALLY_HP_THRESHOLD = 0.75
--- Mana ratio above which Tether activates to share regen.
local TETHER_MANA_SHARE_THRESHOLD = 0.8
--- HP threshold below which bot prioritizes Tether for retreat.
local TETHER_RETREAT_HP_THRESHOLD = 0.25
--- Minimum distance to ally before considering Relocate to join a fight.
local RELOCATE_MIN_DISTANCE = 3000
--- Minimum neutral creeps to justify Spirits for farming.
local SPIRITS_FARM_CREEP_COUNT = 2
--- Mana ratio required to use Spirits for farming.
local SPIRITS_FARM_MANA_THRESHOLD = 0.4
local bot = GetBot()
local minion = dofile(GetScriptDirectory().."/FuncLib/hero/minion")
local hero = buildHeroConfig(bot, {skills = {default = {
    1,
    3,
    1,
    3,
    1,
    6,
    1,
    3,
    3,
    2,
    6,
    2,
    2,
    2,
    6
}}, talents = {default = {t25 = {10, 0}, t20 = {10, 0}, t15 = {0, 10}, t10 = {0, 10}}}, items = {pos_1 = {
    "item_tango",
    "item_faerie_fire",
    "item_gauntlets",
    "item_gauntlets",
    "item_gauntlets",
    "item_boots",
    "item_armlet",
    "item_black_king_bar",
    "item_sange",
    "item_ultimate_scepter",
    "item_heavens_halberd",
    "item_travel_boots",
    "item_satanic",
    "item_aghanims_shard",
    "item_assault",
    "item_travel_boots_2",
    "item_ultimate_scepter_2",
    "item_moon_shard"
}, pos_4 = {
    "item_priest_outfit",
    "item_mekansm",
    "item_glimmer_cape",
    "item_guardian_greaves",
    "item_spirit_vessel",
    "item_shivas_guard",
    "item_sheepstick",
    "item_moon_shard",
    "item_ultimate_scepter_2"
}, pos_5 = {
    "item_blood_grenade",
    "item_mage_outfit",
    "item_ancient_janggo",
    "item_glimmer_cape",
    "item_pipe",
    "item_boots_of_bearing",
    "item_shivas_guard",
    "item_cyclone",
    "item_sheepstick",
    "item_wind_waker",
    "item_moon_shard",
    "item_ultimate_scepter_2"
}}, sell = {"item_black_king_bar", "item_quelling_blade"}})
local abilityTether = bot:GetAbilityByName("wisp_tether")
local abilitySpirits = bot:GetAbilityByName("wisp_spirits")
local abilityOvercharge = bot:GetAbilityByName("wisp_overcharge")
local abilityRelocate = bot:GetAbilityByName("wisp_relocate")
local abilityBreakTether = bot:GetAbilityByName("wisp_tether_break")
local nearbyEnemies = {}
bot.stateTetheredHero = bot.stateTetheredHero
--- Returns true if the unit has any healing-over-time modifier active.
local function _hasHealingEffect(unit)
    return HasAnyEffect(
        unit,
        "modifier_tango_heal",
        unpack(hero_is_healing)
    )
end
--- Returns true if the ally is actively fighting and would benefit from Overcharge.
local function _shouldUseOvercharge(ally)
    local isAttacking = GameTime() - ally:GetLastAttackTime() < 0.33
    local attackTarget = ally:GetAttackTarget()
    return Fu.IsGoingOnSomeone(ally) or attackTarget ~= nil and attackTarget:GetTeam() == GetOpposingTeam() and isAttacking or #ally:GetNearbyCreeps(200, true) > 2
end
--- Returns true if the bot currently has an active Tether link.
local function _isTethered()
    return bot:HasModifier("modifier_wisp_tether")
end
--- Tether (Q): Link to an ally to share regen and enable Overcharge/Relocate.
-- - Retreat: tether to a retreating ally for shared escape
-- - Heal: tether when ally is low or bot has excess mana to share
-- - Fight: tether when ally is actively engaging
local function considerTether()
    if not _isTethered() then
        bot.stateTetheredHero = nil
    end
    if not abilityTether:IsFullyCastable() or not abilityBreakTether:IsHidden() then
        return BotActionDesire.None, nil
    end
    local castRange = abilityTether:GetCastRange()
    local allies = bot:GetNearbyHeroes(castRange, false, BotMode.None)
    for ____, ally in ipairs(allies) do
        do
            local __continue8
            repeat
                if ally == bot or not ally:IsAlive() or ally:IsMagicImmune() then
                    __continue8 = true
                    break
                end
                if Fu.IsRetreating(bot) or Fu.GetHP(bot) < TETHER_RETREAT_HP_THRESHOLD then
                    if Fu.IsRetreating(ally) then
                        return BotActionDesire.High, ally
                    end
                    __continue8 = true
                    break
                end
                if Fu.GetHP(ally) < TETHER_ALLY_HP_THRESHOLD or Fu.GetMP(bot) > TETHER_MANA_SHARE_THRESHOLD or _hasHealingEffect(bot) or _shouldUseOvercharge(ally) then
                    return BotActionDesire.High, ally
                end
                __continue8 = true
            until true
            if not __continue8 then
                break
            end
        end
    end
    return BotActionDesire.None, nil
end
--- Overcharge (E): Toggle attack speed / spell amp boost while tethered.
-- Only activates when tethered ally is actively fighting.
local function considerOvercharge()
    if not abilityOvercharge:IsFullyCastable() then
        return BotActionDesire.None
    end
    if _isTethered() and bot.stateTetheredHero ~= nil and _shouldUseOvercharge(bot.stateTetheredHero) then
        return BotActionDesire.High
    end
    return BotActionDesire.None
end
--- Spirits (W): Summon orbiting spirits that damage nearby enemies.
-- - Fight: cast when any enemy hero is nearby
-- - Farm: cast on 2+ neutral creeps when mana is sufficient
local function considerSpirits()
    if not abilitySpirits:IsFullyCastable() then
        return BotActionDesire.None
    end
    if #nearbyEnemies >= 1 then
        return BotActionDesire.High
    end
    if #bot:GetNearbyNeutralCreeps(500, true) >= SPIRITS_FARM_CREEP_COUNT and Fu.GetMP(bot) > SPIRITS_FARM_MANA_THRESHOLD then
        return BotActionDesire.Moderate
    end
    return BotActionDesire.None
end
--- Relocate (R): Teleport self (and tethered ally) to a location.
-- - Escape: relocate to fountain when self or tethered ally is dying
-- - Join fight: relocate to a distant ally who is in a team fight
local function considerRelocate()
    if not abilityRelocate:IsFullyCastable() then
        return BotActionDesire.None, nil
    end
    if _isTethered() and bot.stateTetheredHero ~= nil then
        local allyHP = Fu.GetHP(bot.stateTetheredHero)
        local botHP = Fu.GetHP(bot)
        if allyHP <= RELOCATE_HP_THRESHOLD or botHP <= RELOCATE_HP_THRESHOLD then
            local allyNearbyEnemies = bot.stateTetheredHero:GetNearbyHeroes(1200, true, BotMode.None)
            local allyOutmatched = #allyNearbyEnemies >= 1 and allyHP < Fu.GetHP(allyNearbyEnemies[1])
            local selfOutmatched = #nearbyEnemies >= 1 and botHP < Fu.GetHP(nearbyEnemies[1])
            if allyOutmatched or selfOutmatched then
                return BotActionDesire.High, GetTeamFountainTpPoint()
            end
        end
    end
    if not _isTethered() and #nearbyEnemies >= 1 and Fu.GetHP(bot) < RELOCATE_HP_THRESHOLD then
        return BotActionDesire.High, GetTeamFountainTpPoint()
    end
    for ____, ally in ipairs(GetUnitList(UnitType.AlliedHeroes)) do
        if IsValidHero(ally) and Fu.IsInTeamFight(ally, 1200) and GetUnitToUnitDistance(bot, ally) > RELOCATE_MIN_DISTANCE and ally:WasRecentlyDamagedByAnyHero(2) then
            return BotActionDesire.High, ally:GetLocation()
        end
    end
    return BotActionDesire.None, nil
end
--- Called each tick by ability_item_usage_generic to evaluate and cast abilities.
local function SkillsComplement()
    if Fu.CanNotUseAbility(bot) or bot:IsInvisible() then
        return
    end
    nearbyEnemies = bot:GetNearbyHeroes(1600, true, BotMode.None)
    local tetherDesire, tetherTarget = considerTether()
    if tetherDesire > 0 and tetherTarget then
        bot:Action_UseAbilityOnEntity(abilityTether, tetherTarget)
        bot.stateTetheredHero = tetherTarget
        return
    end
    local overchargeDesire = considerOvercharge()
    if overchargeDesire > 0 then
        bot:Action_UseAbility(abilityOvercharge)
        return
    end
    local spiritsDesire = considerSpirits()
    if spiritsDesire > 0 then
        bot:Action_UseAbility(abilitySpirits)
        return
    end
    local relocateDesire, relocateTarget = considerRelocate()
    if relocateDesire > 0 and relocateTarget ~= nil then
        bot:Action_UseAbilityOnLocation(abilityRelocate, relocateTarget)
    end
end
--- Called by bot_generic for controlling summoned/illusion units.
local function MinionThink(hMinionUnit)
    if minion.IsValidUnit(hMinionUnit) then
        minion.IllusionThink(hMinionUnit)
    end
end
local ____exports = buildHeroExport(hero, SkillsComplement, MinionThink)
return ____exports
