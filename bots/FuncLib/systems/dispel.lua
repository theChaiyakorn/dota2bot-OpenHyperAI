--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__ObjectEntries(obj)
    local result = {}
    local len = 0
    for key in pairs(obj) do
        len = len + 1
        result[len] = {key, obj[key]}
    end
    return result
end

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
end
-- End of Lua Library inline imports
local ____exports = {}
local ____dota = require("bots.ts_libs.dota.index")
local BotMode = ____dota.BotMode
local DEBUFFS = {
    modifier_stunned = {
        severity = 9,
        isDisable = true,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_bashed = {
        severity = 9,
        isDisable = true,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_sheepstick_debuff = {
        severity = 9,
        isDisable = true,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_lion_voodoo = {
        severity = 9,
        isDisable = true,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_shadow_shaman_voodoo = {
        severity = 9,
        isDisable = true,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_bane_nightmare = {
        severity = 8,
        isDisable = true,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_doom_bringer_doom = {
        severity = 10,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_orchid_malevolence_debuff = {
        severity = 7,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_bloodthorn_debuff = {
        severity = 8,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_silencer_last_word = {
        severity = 6,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_skywrath_mage_ancient_seal = {
        severity = 7,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_death_prophet_silence = {
        severity = 6,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_night_stalker_crippling_fear = {
        severity = 6,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_riki_smoke_screen = {
        severity = 6,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = false
    },
    modifier_disruptor_static_storm = {
        severity = 7,
        isDisable = false,
        isSilence = true,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = false,
        strongDispel = false
    },
    modifier_rod_of_atos_debuff = {
        severity = 5,
        isDisable = false,
        isSilence = false,
        isRoot = true,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_crystal_maiden_frostbite = {
        severity = 5,
        isDisable = false,
        isSilence = false,
        isRoot = true,
        isDot = true,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_treant_overgrowth = {
        severity = 6,
        isDisable = false,
        isSilence = false,
        isRoot = true,
        isDot = false,
        isArmor = false,
        basicDispel = false,
        strongDispel = true
    },
    modifier_slardar_amplify_damage = {
        severity = 5,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = true,
        basicDispel = true,
        strongDispel = true
    },
    modifier_bounty_hunter_track = {
        severity = 4,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = true,
        basicDispel = true,
        strongDispel = true
    },
    modifier_spirit_vessel_damage = {
        severity = 5,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_item_spirit_vessel_damage = {
        severity = 5,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_razor_static_link_debuff = {
        severity = 5,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = true,
        basicDispel = true,
        strongDispel = true
    },
    modifier_viper_viper_strike_slow = {
        severity = 4,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_axe_battle_hunger_self = {
        severity = 3,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_venomancer_venomous_gale = {
        severity = 3,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_bristleback_viscous_nasal_goo = {
        severity = 2,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = true,
        basicDispel = true,
        strongDispel = true
    },
    modifier_phoenix_fire_spirit_burn = {
        severity = 2,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_earth_spirit_magnetize = {
        severity = 3,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_warlock_fatal_bonds = {
        severity = 3,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_life_stealer_open_wounds = {
        severity = 3,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = false,
        isArmor = false,
        basicDispel = true,
        strongDispel = true
    },
    modifier_ice_blast = {
        severity = 4,
        isDisable = false,
        isSilence = false,
        isRoot = false,
        isDot = true,
        isArmor = false,
        basicDispel = false,
        strongDispel = false
    }
}
--- Enemy buffs worth stripping with offensive purge
local ENEMY_BUFFS_TO_STRIP = {
    "modifier_ghost_state",
    "modifier_item_ghost",
    "modifier_windrunner_windrun",
    "modifier_ogre_magi_bloodlust",
    "modifier_ursa_overpower",
    "modifier_legion_commander_press_the_attack",
    "modifier_omniknight_repel",
    "modifier_haste_rune_speed",
    "modifier_double_damage",
    "modifier_ember_spirit_flame_guard",
    "modifier_abaddon_aphotic_shield"
}
--- Modifiers that mean the ally is already protected — don't dispel
local PROTECTED_MODIFIERS = {
    "modifier_dazzle_shallow_grave",
    "modifier_oracle_false_promise_timer",
    "modifier_abaddon_borrowed_time",
    "modifier_skeleton_king_reincarnation_scepter_active",
    "modifier_item_aeon_disk_buff"
}
--- Analyze all debuffs on a unit. Returns total severity score
-- and the worst debuff info for decision making.
function ____exports.AnalyzeDebuffs(unit)
    local score = 0
    local worstSeverity = 0
    local hasSilence = false
    local hasDisable = false
    local hasRoot = false
    local canBasicDispel = false
    local canStrongDispel = false
    for ____, ____value in ipairs(__TS__ObjectEntries(DEBUFFS)) do
        local mod = ____value[1]
        local info = ____value[2]
        do
            local __continue3
            repeat
                if unit:HasModifier(mod) then
                    local ____table_GetModifierRemainingDuration_0
                    if unit.GetModifierRemainingDuration then
                        ____table_GetModifierRemainingDuration_0 = unit.GetModifierRemainingDuration(mod)
                    else
                        ____table_GetModifierRemainingDuration_0 = 999
                    end
                    local remaining = ____table_GetModifierRemainingDuration_0
                    if remaining < 0.5 then
                        __continue3 = true
                        break
                    end
                    score = score + info.severity
                    if info.severity > worstSeverity then
                        worstSeverity = info.severity
                    end
                    if info.isSilence then
                        hasSilence = true
                    end
                    if info.isDisable then
                        hasDisable = true
                    end
                    if info.isRoot then
                        hasRoot = true
                    end
                    if info.basicDispel then
                        canBasicDispel = true
                    end
                    if info.strongDispel then
                        canStrongDispel = true
                    end
                end
                __continue3 = true
            until true
            if not __continue3 then
                break
            end
        end
    end
    return {
        score = score,
        worstSeverity = worstSeverity,
        hasSilence = hasSilence,
        hasDisable = hasDisable,
        hasRoot = hasRoot,
        canBasicDispel = canBasicDispel,
        canStrongDispel = canStrongDispel
    }
end
--- Check if a unit is currently protected (Grave, False Promise, etc.)
-- If protected, don't waste a dispel on them.
function ____exports.IsProtected(unit)
    for ____, mod in ipairs(PROTECTED_MODIFIERS) do
        if unit:HasModifier(mod) then
            return true
        end
    end
    return false
end
--- Check if silence matters for this hero.
-- Silence on a right-click carry is low priority.
-- Silence on a spellcaster is critical.
local function IsSilenceCriticalForHero(bot)
    do
        local i = 0
        while i < 6 do
            local ability = bot:GetAbilityInSlot(i)
            if ability and ability:IsTrained() and not ability.IsPassive() and ability.IsCooldownReady() then
                return true
            end
            i = i + 1
        end
    end
    return false
end
--- Check if the bot can realistically survive after dispelling.
-- Don't waste BKB if dead in 1 second regardless.
local function CanSurviveAfterDispel(bot)
    if not bot.IsBot() or bot.GetPosition and bot.GetPosition() <= 2 then
        return true
    end
    local hp = bot.GetHealth() / bot.GetMaxHealth()
    local enemies = bot:GetNearbyHeroes(1200, true, BotMode.None)
    local allies = bot:GetNearbyHeroes(1200, false, BotMode.None)
    if hp < 0.1 and enemies and #enemies >= 3 and (not allies or #allies <= 1) then
        return false
    end
    return true
end
--- Check if the bot should use a dispel item on itself.
-- Returns the item slot to use, or -1 if no action needed.
-- 
-- Pro-level logic:
-- - Checks debuff duration (don't waste on 0.5s stuns)
-- - Checks survival likelihood
-- - Checks if silence matters for this hero
-- - Won't dispel during existing protection
function ____exports.ShouldUseSelfDispelItem(bot)
    if ____exports.IsProtected(bot) then
        return -1
    end
    if not CanSurviveAfterDispel(bot) then
        return -1
    end
    local analysis = ____exports.AnalyzeDebuffs(bot)
    if analysis.score < 4 then
        return -1
    end
    if analysis.hasSilence and not analysis.hasDisable and not IsSilenceCriticalForHero(bot) then
        if analysis.score < 7 then
            return -1
        end
    end
    local needsStrong = analysis.hasDisable or not analysis.canBasicDispel
    local itemPriority = needsStrong and ({
        "item_black_king_bar",
        "item_satanic",
        "item_aeon_disk",
        "item_manta",
        "item_cyclone",
        "item_guardian_greaves"
    }) or ({
        "item_manta",
        "item_cyclone",
        "item_guardian_greaves",
        "item_lotus_orb",
        "item_black_king_bar"
    })
    for ____, itemName in ipairs(itemPriority) do
        do
            local __continue29
            repeat
                local slot = bot:FindItemSlot(itemName)
                if slot >= 0 then
                    local item = bot:GetItemInSlot(slot)
                    if item and item.IsFullyCastable() then
                        if itemName == "item_black_king_bar" and analysis.worstSeverity < 6 then
                            __continue29 = true
                            break
                        end
                        if itemName == "item_cyclone" then
                            local enemies = bot:GetNearbyHeroes(900, true, BotMode.None)
                            if enemies and #enemies >= 2 then
                                __continue29 = true
                                break
                            end
                        end
                        return slot
                    end
                end
                __continue29 = true
            until true
            if not __continue29 then
                break
            end
        end
    end
    return -1
end
--- Check if the bot should use Lotus Orb on a debuffed ally.
-- Also considers preemptive usage — Lotus before enemy casts.
function ____exports.ShouldUseAllyDispelItem(bot)
    local lotusSlot = bot:FindItemSlot("item_lotus_orb")
    if lotusSlot < 0 then
        return -1, nil
    end
    local lotusItem = bot:GetItemInSlot(lotusSlot)
    if not lotusItem or not lotusItem.IsFullyCastable() then
        return -1, nil
    end
    local allies = bot:GetNearbyHeroes(900, false, BotMode.None)
    if not allies then
        return -1, nil
    end
    local bestAlly = nil
    local bestScore = 0
    for ____, ally in ipairs(allies) do
        do
            local __continue40
            repeat
                if ally == bot or not ally:IsAlive() or ____exports.IsProtected(ally) then
                    __continue40 = true
                    break
                end
                local analysis = ____exports.AnalyzeDebuffs(ally)
                if analysis.score > bestScore and analysis.score >= 5 then
                    bestScore = analysis.score
                    bestAlly = ally
                end
                if not ally:HasModifier("modifier_item_lotus_orb_active") then
                    local enemiesNearAlly = ally:GetNearbyHeroes(800, true, BotMode.None)
                    if enemiesNearAlly then
                        for ____, enemy in ipairs(enemiesNearAlly) do
                            if enemy and not enemy:IsNull() and enemy:IsAlive() then
                                local eName = enemy:GetUnitName()
                                if eName == "npc_dota_hero_doom_bringer" or eName == "npc_dota_hero_lion" or eName == "npc_dota_hero_lina" or eName == "npc_dota_hero_necrolyte" or eName == "npc_dota_hero_bane" then
                                    if enemy.IsFacingLocation(
                                        ally:GetLocation(),
                                        30
                                    ) then
                                        bestAlly = ally
                                        bestScore = 10
                                    end
                                end
                            end
                        end
                    end
                end
                __continue40 = true
            until true
            if not __continue40 then
                break
            end
        end
    end
    if bestAlly then
        return lotusSlot, bestAlly
    end
    return -1, nil
end
--- Check if bot should Manta-dodge an incoming targeted projectile.
-- Returns item slot or -1.
function ____exports.ShouldMantaDodge(bot)
    local mantaSlot = bot:FindItemSlot("item_manta")
    if mantaSlot < 0 then
        return -1
    end
    local item = bot:GetItemInSlot(mantaSlot)
    if not item or not item.IsFullyCastable() then
        return -1
    end
    local incoming = bot.GetIncomingTrackingProjectiles()
    if incoming then
        for ____, proj in __TS__Iterator(incoming) do
            if proj and proj.is_attack == false and proj.is_dodgeable then
                local dist = GetUnitToLocationDistance(bot, proj.location)
                local speed = proj.speed or 1000
                local timeToImpact = dist / speed
                if timeToImpact < 0.3 and timeToImpact > 0.05 then
                    return mantaSlot
                end
            end
        end
    end
    return -1
end
--- Check if an enemy has a buff worth stripping.
-- For use with Eul's on enemy, Nullifier, Demonic Purge, etc.
function ____exports.HasStrippableBuff(enemy)
    for ____, mod in ipairs(ENEMY_BUFFS_TO_STRIP) do
        if enemy:HasModifier(mod) then
            return true
        end
    end
    return false
end
--- Get the best enemy to offensively purge within range.
function ____exports.GetBestEnemyToPurge(bot, range)
    local enemies = bot:GetNearbyHeroes(range, true, BotMode.None)
    if not enemies then
        return nil
    end
    for ____, enemy in ipairs(enemies) do
        if enemy and not enemy:IsNull() and enemy:IsAlive() and not enemy:IsMagicImmune() then
            if ____exports.HasStrippableBuff(enemy) then
                return enemy
            end
        end
    end
    return nil
end
--- For heroes with ally-dispel abilities (Abaddon, LC, Oracle, Omni):
-- Returns the best ally to dispel.
function ____exports.GetBestAllyToDispel(bot, castRange, isStrongDispel)
    if isStrongDispel == nil then
        isStrongDispel = false
    end
    local allies = bot:GetNearbyHeroes(castRange, false, BotMode.None)
    if not allies then
        return nil
    end
    local bestAlly = nil
    local bestScore = 0
    for ____, ally in ipairs(allies) do
        do
            local __continue72
            repeat
                if ally == bot or not ally:IsAlive() or ____exports.IsProtected(ally) then
                    __continue72 = true
                    break
                end
                local analysis = ____exports.AnalyzeDebuffs(ally)
                if analysis.score < 4 then
                    __continue72 = true
                    break
                end
                if not isStrongDispel and not analysis.canBasicDispel then
                    __continue72 = true
                    break
                end
                if analysis.score > bestScore then
                    bestScore = analysis.score
                    bestAlly = ally
                end
                __continue72 = true
            until true
            if not __continue72 then
                break
            end
        end
    end
    return bestAlly
end
--- For heroes with self-dispel abilities (Slark, Ursa, Lifestealer, etc.):
-- Returns true if the bot should self-dispel now.
function ____exports.ShouldSelfDispel(bot, isStrongDispel)
    if ____exports.IsProtected(bot) then
        return false
    end
    local analysis = ____exports.AnalyzeDebuffs(bot)
    if isStrongDispel then
        return analysis.hasDisable or analysis.worstSeverity >= 9
    end
    if analysis.hasSilence and IsSilenceCriticalForHero(bot) then
        return true
    end
    return analysis.score >= 5 and analysis.canBasicDispel
end
function ____exports.GetDebuffSeverity(unit)
    return ____exports.AnalyzeDebuffs(unit).score
end
function ____exports.HasDispellableDebuff(unit, minSeverity)
    if minSeverity == nil then
        minSeverity = 1
    end
    return ____exports.GetDebuffSeverity(unit) >= minSeverity
end
function ____exports.NeedsStrongDispel(unit)
    return ____exports.AnalyzeDebuffs(unit).hasDisable
end
return ____exports
