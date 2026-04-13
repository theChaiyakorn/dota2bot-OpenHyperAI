local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
    {-- pos1/2: right-click focused
        ['t25'] = {10, 0},
        ['t20'] = {10, 0},
        ['t15'] = {0, 10},
        ['t10'] = {0, 10},
    },
    {-- pos3: offlane/utility
        ['t25'] = {10, 0},
        ['t20'] = {10, 0},
        ['t15'] = {0, 10},
        ['t10'] = {0, 10},
    },
    {-- pos4/5: support
        ['t25'] = {0, 10},
        ['t20'] = {0, 10},
        ['t15'] = {10, 0},
        ['t10'] = {10, 0},
    }
}

local tAllAbilityBuildList = {
    {1,2,1,2,1,6,1,2,2,3,6,3,3,3,6},-- pos1/2: Sprout max first (damage scales for right-click)
    {3,1,3,2,3,6,3,2,2,2,6,1,1,1,6},-- pos3: Nature's Call max first (push/pressure)
    {2,1,1,2,1,6,1,2,2,3,6,3,3,3,6},-- pos4/5: Early TP at 1, then Sprout max (ganking)
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_1" or sRole == "pos_2" then
    nAbilityBuildList = tAllAbilityBuildList[1]
    nTalentBuildList  = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
elseif sRole == "pos_3" then
    nAbilityBuildList = tAllAbilityBuildList[2]
    nTalentBuildList  = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
else
    nAbilityBuildList = tAllAbilityBuildList[3]
    nTalentBuildList  = Fu.Skill.GetTalentBuild(tTalentTreeList[3])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_faerie_fire",
    "item_double_branches",
    "item_circlet",
    "item_mantle",

    "item_null_talisman",
    "item_magic_wand",
    "item_power_treads",
    "item_maelstrom",
    "item_orchid",
    "item_black_king_bar",--
    "item_mjollnir",--
    "item_aghanims_shard",
    "item_hurricane_pike",--
    "item_satanic",--
    "item_bloodthorn",--
    "item_greater_crit",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_bottle",
    "item_null_talisman",
    "item_magic_wand",
    "item_power_treads",
    "item_maelstrom",
    "item_orchid",
    "item_black_king_bar",--
    "item_mjollnir",--
    "item_aghanims_shard",
    "item_hurricane_pike",--
    "item_satanic",--
    "item_bloodthorn",--
    "item_greater_crit",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_blight_stone",
    "item_tango",
    "item_faerie_fire",
    "item_double_branches",

    "item_magic_wand",
    "item_power_treads",
    "item_maelstrom",
    "item_rod_of_atos",  -- root + Sprout synergy for lockdown
    "item_black_king_bar",--
    "item_mjollnir",--
    "item_aghanims_shard",
    "item_assault",--
    "item_hurricane_pike",--
    "item_sheepstick",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
    "item_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_double_circlet",

    "item_tranquil_boots",
    "item_magic_wand",
    "item_urn_of_shadows",
    "item_solar_crest",--
    "item_aghanims_shard",
    "item_ancient_janggo",
    "item_spirit_vessel",
    "item_boots_of_bearing",--
    "item_ultimate_scepter",
    "item_orchid",
    "item_heavens_halberd",--
    "item_bloodthorn",--
    "item_ultimate_scepter_2",
    "item_sheepstick",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_double_circlet",

    "item_tranquil_boots",
    "item_magic_wand",
    "item_urn_of_shadows",
    "item_solar_crest",--
    "item_aghanims_shard",
    "item_mekansm",
    "item_spirit_vessel",--
    "item_guardian_greaves",--
    "item_ultimate_scepter",
    "item_orchid",
    "item_heavens_halberd",--
    "item_bloodthorn",--
    "item_ultimate_scepter_2",
    "item_sheepstick",--
    "item_moon_shard",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_black_king_bar",
	"item_quelling_blade",
	"item_null_talisman",
	"item_ultimate_scepter",
	"item_magic_wand",
	"item_cyclone",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

-- Re-fetch ability handles each tick for safety (Aghs upgrades, etc.)
local Sprout, Teleportation, NaturesCall, CurseOfTheOldGrowth, WrathOfNature

local function RefreshAbilities()
    Sprout              = SafeAbility(bot:GetAbilityByName('furion_sprout'), 'furion_sprout', 'furion')
    Teleportation       = SafeAbility(bot:GetAbilityByName('furion_teleportation'), 'furion_teleportation', 'furion')
    NaturesCall         = SafeAbility(bot:GetAbilityByName('furion_force_of_nature'), 'furion_force_of_nature', 'furion')
    CurseOfTheOldGrowth = SafeAbility(bot:GetAbilityByName('furion_curse_of_the_forest'), 'furion_curse_of_the_forest', 'furion')
    WrathOfNature       = SafeAbility(bot:GetAbilityByName('furion_wrath_of_nature'), 'furion_wrath_of_nature', 'furion')
end

-- Cached per-tick variables
local botTarget, botHP, nAllyHeroes, nEnemyHeroes, bAttacking

local bGoingOnSomeone
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    RefreshAbilities()
    botTarget = Fu.GetProperTarget(bot)
    botHP = Fu.GetHP(bot)
    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    bAttacking = Fu.IsAttacking(bot)

    -- External TP request
    if  bot.useProphetTP
    and bot.ProphetTPLocation ~= nil
    and Fu.CanCastAbility(Teleportation)
    then
        bot:Action_UseAbilityOnLocation(Teleportation, bot.ProphetTPLocation)
        bot.useProphetTP = false
        return
    end

    -- Sprout+NaturesCall combo for farming/pushing
    local scDesire, scTarget, scLoc = X.ConsiderSproutCall()
    if scDesire > 0 and scTarget ~= nil then
        bot:Action_ClearActions(true)
        bot:ActionQueue_UseAbilityOnEntity(Sprout, scTarget)
        bot:ActionQueue_Delay(0.35 + 0.44)
        bot:ActionQueue_UseAbilityOnLocation(NaturesCall, scLoc)
        return
    end

    local tpDesire, tpLoc = X.ConsiderTeleportation()
    if tpDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(Teleportation, tpLoc)
        bot.useProphetTP = false
        return
    end

    local sproutDesire, sproutTarget = X.ConsiderSprout()
    if sproutDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(Sprout, sproutTarget)
        return
    end

    local ncDesire, ncLoc = X.ConsiderNaturesCall()
    if ncDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(NaturesCall, GetTreeLocation(ncLoc))
        return
    end

    local curseDesire = X.ConsiderCurseOfTheOldGrowth()
    if curseDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbility(CurseOfTheOldGrowth)
        return
    end

    local wonDesire, wonTarget = X.ConsiderWrathOfNature()
    if wonDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(WrathOfNature, wonTarget)
        return
    end
end

function X.ConsiderSprout()
    if not Fu.CanCastAbility(Sprout) then return BOT_ACTION_DESIRE_NONE, nil end

    local nCastRange = Fu.GetProperCastRange(false, bot, Sprout:GetCastRange())
    local nDuration = Sprout:GetSpecialValueInt('duration')

    -- Tree-walkers negate Sprout entirely
    local function CanBeSprouted(target)
        return Fu.IsValidTarget(target)
            and not Fu.IsSuspiciousIllusion(target)
            and not target:HasModifier('modifier_hoodwink_scurry_active')
            and not target:HasModifier('modifier_item_spider_legs_active')
            and not target:HasModifier('modifier_enigma_black_hole_pull')
            and not target:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not target:HasModifier('modifier_legion_commander_duel')
            and not target:HasModifier('modifier_necrolyte_reapers_scythe')
    end

    -- Teamfight: target highest-threat enemy
    if bInTeamFight then
        local bestTarget, bestDmg = nil, 0
        for _, enemy in pairs(nEnemyHeroes) do
            if CanBeSprouted(enemy)
            and not Fu.IsDisabled(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange) then
                local dmg = enemy:GetEstimatedDamageToTarget(true, bot, 5, DAMAGE_TYPE_ALL)
                if dmg > bestDmg then
                    bestTarget = enemy
                    bestDmg = dmg
                end
            end
        end
        if bestTarget then return BOT_ACTION_DESIRE_HIGH, bestTarget end
    end

    -- Going on someone
    if bGoingOnSomeone then
        if CanBeSprouted(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget) then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    -- Retreating: sprout closest chaser (per-hero damage check, self-safety)
    if Fu.IsRetreating(bot)
    and not Fu.IsRealInvisible(bot) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnMagicImmune(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and not Fu.IsInRange(bot, enemy, Sprout:GetSpecialValueInt('radius'))  -- don't trap self
            and Fu.IsChasingTarget(enemy, bot)
            and bot:WasRecentlyDamagedByHero(enemy, 2.0) then
                return BOT_ACTION_DESIRE_HIGH, enemy
            end
        end
    end

    -- Ally defense: sprout enemies chasing retreating allies
    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(5)
        and not allyHero:IsIllusion()
        and (not Fu.IsCore(bot) or Fu.GetMP(bot) > 0.5) then
            local nAllyEnemies = allyHero:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
            if Fu.IsValidHero(nAllyEnemies[1])
            and CanBeSprouted(nAllyEnemies[1])
            and Fu.IsInRange(bot, nAllyEnemies[1], nCastRange)
            and Fu.IsChasingTarget(nAllyEnemies[1], allyHero) then
                return BOT_ACTION_DESIRE_HIGH, nAllyEnemies[1]
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTeleportation()
    if not Fu.CanCastAbility(Teleportation) then return BOT_ACTION_DESIRE_NONE, 0 end

    local nChannelTime = Teleportation:GetCastPoint()
    local nMoveSpeed = bot:GetCurrentMovementSpeed()

    -- Projectile interrupt check: don't TP if stun is incoming
    if Fu.IsStunProjectileIncoming and Fu.IsStunProjectileIncoming(bot, 1200) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    -- Stuck
    if Fu.IsStuck(bot) then
        return BOT_ACTION_DESIRE_HIGH, Fu.GetTeamFountain()
    end

    -- Teamfight TP
    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
    if nTeamFightLocation ~= nil
    and (not Fu.IsCore(bot) or not Fu.IsInLaningPhase() or bot:GetNetWorth() > 3500) then
        local dist = GetUnitToLocationDistance(bot, nTeamFightLocation)
        local walkTime = dist / nMoveSpeed
        if walkTime > nChannelTime + 2 then
            local allies = Fu.GetAlliesNearLoc(nTeamFightLocation, 1200)
            if allies ~= nil and #allies >= 1 and Fu.IsValidHero(allies[#allies]) then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(allies[#allies], nChannelTime)
            end
        end
    end

    -- Ally gank TP
    for i = 1, #GetTeamPlayers(GetTeam()) do
        local allyHero = GetTeamMember(i)
        if Fu.IsValidHero(allyHero)
        and Fu.IsGoingOnSomeone(allyHero)
        and not allyHero:IsIllusion()
        and (not Fu.IsCore(bot) or not Fu.IsInLaningPhase() or bot:GetNetWorth() > 3500) then
            local dist = GetUnitToUnitDistance(bot, allyHero)
            local walkTime = dist / nMoveSpeed
            if walkTime > nChannelTime + 2 then
                local allyTarget = allyHero:GetAttackTarget()
                if Fu.IsValidTarget(allyTarget)
                and Fu.IsInRange(allyHero, allyTarget, 800)
                and Fu.GetHP(allyHero) > 0.25
                and not Fu.IsSuspiciousIllusion(allyTarget) then
                    local nTargetAllies = allyTarget:GetNearbyHeroes(800, false, BOT_MODE_NONE)
                    local nAllyAllies = allyHero:GetNearbyHeroes(800, false, BOT_MODE_NONE)
                    if nAllyAllies and nTargetAllies
                    and #nAllyAllies + 1 >= #nTargetAllies
                    and not Fu.IsLocationInChrono(Fu.GetCorrectLoc(allyHero, nChannelTime)) then
                        return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(allyHero, nChannelTime)
                    end
                end
            end
        end
    end

    -- Retreat TP: only when no one can interrupt
    if Fu.IsRetreating(bot)
    and not Fu.IsRealInvisible(bot)
    and bot:WasRecentlyDamagedByAnyHero(4)
    and bot:GetActiveModeDesire() > 0.75
    and bot:GetLevel() >= 6 then
        if #nEnemyHeroes == 0 then  -- safe to channel
            local fTimeToFountain = GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) / nMoveSpeed
            if fTimeToFountain > nChannelTime + 1 then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetTeamFountain()
            end
        end
    end

    -- Push TP: TP to lane front when pushing and far away
    if Fu.IsPushing(bot) and not bAttacking and #nEnemyHeroes == 0 then
        local nLane = bot:GetAssignedLane()
        if nLane ~= nil and nLane > 0 then
            local pushLoc = GetLaneFrontLocation(GetTeam(), nLane, 0)
            local dist = GetUnitToLocationDistance(bot, pushLoc)
            local walkTime = dist / nMoveSpeed
            if walkTime > nChannelTime * 2 and IsLocationPassable(pushLoc) then
                return BOT_ACTION_DESIRE_MODERATE, pushLoc
            end
        end
    end

    -- Defend TP: TP behind the front line
    if Fu.IsDefending(bot) and #nEnemyHeroes == 0 then
        local nDefendLane, _ = Fu.GetMostDefendLaneDesire()
        if nDefendLane ~= nil then
            local defendLoc = GetLaneFrontLocation(GetTeam(), nDefendLane, -1000)
            local dist = GetUnitToLocationDistance(bot, defendLoc)
            local walkTime = dist / nMoveSpeed
            if walkTime > nChannelTime * 2 and IsLocationPassable(defendLoc) then
                return BOT_ACTION_DESIRE_MODERATE, defendLoc
            end
        end
    end

    -- Roshan/Tormentor TP
    if Fu.IsDoingRoshan(bot) then
        local loc = Fu.GetCurrentRoshanLocation()
        local allies = Fu.GetAlliesNearLoc(loc, 700)
        local dist = GetUnitToLocationDistance(bot, loc)
        if allies and #allies >= 2 and dist / nMoveSpeed > nChannelTime + 1 then
            return BOT_ACTION_DESIRE_HIGH, loc
        end
    end

    if Fu.IsDoingTormentor(bot) then
        local loc = Fu.GetTormentorLocation(GetTeam())
        local allies = Fu.GetAlliesNearLoc(loc, 700)
        local dist = GetUnitToLocationDistance(bot, loc)
        if allies and #allies >= 2 and dist / nMoveSpeed > nChannelTime + 1 then
            return BOT_ACTION_DESIRE_HIGH, loc
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderNaturesCall()
    if not Fu.CanCastAbility(NaturesCall) then return BOT_ACTION_DESIRE_NONE, 0 end

    local nCastRange = Fu.GetProperCastRange(false, bot, NaturesCall:GetCastRange())
    local nInRangeTrees = bot:GetNearbyTrees(nCastRange)

    if nInRangeTrees == nil or #nInRangeTrees < 1 then return BOT_ACTION_DESIRE_NONE, 0 end

    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

    -- Teamfight: summon treants for extra damage/body block
    if bInTeamFight then
        return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
    end

    -- Going on someone
    if bGoingOnSomeone then
        if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 900)
        and Fu.CanBeAttacked(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze') then
            return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
        end
    end

    -- Push/Defend
    if Fu.IsPushing(bot) or Fu.IsDefending(bot) then
        if nEnemyLaneCreeps and #nEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        and #nAllyHeroes <= 3 then  -- don't waste treants when grouped
            return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
        end
    end

    -- Farming
    if Fu.IsFarming(bot) and Fu.GetManaAfter(NaturesCall:GetManaCost()) > 0.35 and bAttacking then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
        if nNeutralCreeps and Fu.IsValid(nNeutralCreeps[1])
        and (#nNeutralCreeps >= 3 or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep())) then
            return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
        end
        if nEnemyLaneCreeps and #nEnemyLaneCreeps >= 3 and Fu.CanBeAttacked(nEnemyLaneCreeps[1]) then
            return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
        end
    end

    -- Laning
    if Fu.IsLaning(bot) and Fu.GetManaAfter(NaturesCall:GetManaCost()) > 0.3 and bAttacking then
        if nEnemyLaneCreeps and #nEnemyLaneCreeps >= 2 and Fu.CanBeAttacked(nEnemyLaneCreeps[1]) then
            return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
        end
    end

    -- Roshan/Tormentor
    if Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget)
    and not botTarget:IsAttackImmune() and Fu.IsInRange(bot, botTarget, bot:GetAttackRange()) and bAttacking then
        return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
    end

    if Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget)
    and Fu.IsInRange(bot, botTarget, bot:GetAttackRange()) and bAttacking then
        return BOT_ACTION_DESIRE_HIGH, nInRangeTrees[1]
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderWrathOfNature()
    if not Fu.CanCastAbility(WrathOfNature) then return BOT_ACTION_DESIRE_NONE, nil end

    local nDamage = WrathOfNature:GetSpecialValueInt('damage')

    -- Global kill-securing (FIXED: was UNIT_LIST_ALLIED_HEROES, now ENEMY)
    for _, enemyHero in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb') then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    -- Teamfight: lowest HP enemy
    if bInTeamFight then
        local hTarget, hp = nil, 99999
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidTarget(enemyHero)
            and Fu.GetHP(enemyHero) < 0.5
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer') then
                if enemyHero:GetHealth() < hp then
                    hTarget = enemyHero
                    hp = enemyHero:GetHealth()
                end
            end
        end
        if hTarget then return BOT_ACTION_DESIRE_HIGH, hTarget end
    end

    -- Going on someone: cast when attacking or have scepter (treants on hit)
    if bGoingOnSomeone and (bAttacking or bot:HasScepter()) then
        if Fu.IsValidHero(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_oracle_false_promise_timer') then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderCurseOfTheOldGrowth()
    if not Fu.CanCastAbility(CurseOfTheOldGrowth) then return BOT_ACTION_DESIRE_NONE end

    local nRadius = CurseOfTheOldGrowth:GetSpecialValueInt('range')
    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

    -- Teamfight or going on someone with 2+ enemies
    if (bInTeamFight or bGoingOnSomeone)
    and #nInRangeEnemy >= 2 then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

-- Sprout + Nature's Call combo: create trees then convert to treants
function X.CanDoSproutCall()
    return Fu.CanCastAbility(Sprout) and Fu.CanCastAbility(NaturesCall)
        and Fu.GetMP(bot) > 0.5
end

function X.ConsiderSproutCall()
    if not X.CanDoSproutCall() then return BOT_ACTION_DESIRE_NONE, nil, 0 end

    local nCastRange = Fu.GetProperCastRange(false, bot, Sprout:GetCastRange())
    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

    -- Push/Defend: 4+ creeps
    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and nEnemyLaneCreeps and #nEnemyLaneCreeps >= 4
    and Fu.CanBeAttacked(nEnemyLaneCreeps[1]) then
        local loc = Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        return BOT_ACTION_DESIRE_HIGH, bot, loc
    end

    -- Farming: 3+ creeps or ancients
    if Fu.IsFarming(bot) and bAttacking then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
        if nNeutralCreeps and Fu.IsValid(nNeutralCreeps[1])
        and (#nNeutralCreeps >= 3 or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep())) then
            return BOT_ACTION_DESIRE_HIGH, bot, bot:GetLocation()
        end
        if nEnemyLaneCreeps and #nEnemyLaneCreeps >= 3 and Fu.CanBeAttacked(nEnemyLaneCreeps[1]) then
            local loc = Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            return BOT_ACTION_DESIRE_HIGH, bot, loc
        end
    end

    -- Laning: 2+ creeps
    if Fu.IsLaning(bot) and bAttacking then
        if nEnemyLaneCreeps and #nEnemyLaneCreeps >= 2 and Fu.CanBeAttacked(nEnemyLaneCreeps[1]) then
            return BOT_ACTION_DESIRE_HIGH, bot, bot:GetLocation()
        end
    end

    -- Roshan/Tormentor
    if Fu.IsDoingRoshan(bot) and Fu.IsRoshan(botTarget) and bAttacking then
        return BOT_ACTION_DESIRE_HIGH, bot, bot:GetLocation()
    end
    if Fu.IsDoingTormentor(bot) and Fu.IsTormentor(botTarget) and bAttacking then
        return BOT_ACTION_DESIRE_HIGH, bot, bot:GetLocation()
    end

    return BOT_ACTION_DESIRE_NONE, nil, 0
end

return X
