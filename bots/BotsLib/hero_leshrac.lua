local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos2
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos3
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {10, 0},
                            ['t10'] = {10, 0},
                        }
}

local tAllAbilityBuildList = {
						{3,1,3,1,3,6,3,2,2,2,2,6,1,1,6},--pos2
                        {3,2,2,1,2,6,2,1,1,1,6,3,3,3,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sUtility = {"item_pipe", "item_lotus_orb", "item_crimson_guard"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_mantle",
    "item_circlet",
    "item_faerie_fire",

    "item_bottle",
    "item_null_talisman",
    "item_magic_wand",
    "item_arcane_boots",
    "item_cyclone",
    "item_kaya_and_sange",--
    "item_bloodstone",--
    -- "item_eternal_shroud",--
    "item_shivas_guard",--
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_wind_waker",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_enchanted_mango",

    "item_null_talisman",
    "item_magic_wand",
    "item_arcane_boots",
    "item_kaya",
    "item_bloodstone",--
    "item_black_king_bar",--
    nUtility,--
    "item_kaya_and_sange",--
    "item_aghanims_shard",
    "item_travel_boots",
    "item_shivas_guard",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

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

local SplitEarth        = bot:GetAbilityByName('leshrac_split_earth')
local DiabolicEdict     = bot:GetAbilityByName('leshrac_diabolic_edict')
local LightningStorm    = bot:GetAbilityByName('leshrac_lightning_storm')
local Nihilism          = bot:GetAbilityByName('leshrac_greater_lightning_storm')
local PulseNova         = bot:GetAbilityByName('leshrac_pulse_nova')

local SplitEarthDesire, SplitEarthLocation
local DiabolicEdictDesire
local LightningStormDesire, LightningStormTarget
local NihilismDesire
local PulseNovaDesire

local botTarget

if bot.edictPushing == nil then bot.edictPushing = false end

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotMP
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = Fu.GetMP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    botTarget = Fu.GetProperTarget(bot)
    if not bot:HasModifier('modifier_leshrac_diabolic_edict')
    then
        bot.edictPushing = false
    end

    PulseNovaDesire = X.ConsiderPulseNova()
    if PulseNovaDesire > 0
    then
        bot:Action_UseAbility(PulseNova)
        return
    end

    LightningStormDesire, LightningStormTarget = X.ConsiderLightningStorm()
    if LightningStormDesire > 0
    then
        bot:Action_UseAbilityOnEntity(LightningStorm, LightningStormTarget)
        return
    end

    SplitEarthDesire, SplitEarthLocation = X.ConsiderSplitEarth()
    if SplitEarthDesire > 0
    then
        bot:Action_UseAbilityOnLocation(SplitEarth, SplitEarthLocation)
        return
    end

    DiabolicEdictDesire = X.ConsiderDiabolicEdict()
    if DiabolicEdictDesire > 0
    then
        bot:Action_UseAbility(DiabolicEdict)
        return
    end

    NihilismDesire = X.ConsiderNihilism()
    if NihilismDesire > 0
    then
        bot:Action_UseAbility(Nihilism)
        return
    end
end

function X.ConsiderSplitEarth()
    if not SplitEarth:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SplitEarth:GetCastRange())
    local nCastPoint = SplitEarth:GetCastPoint()
    local nRadius = SplitEarth:GetSpecialValueInt('radius')
    local nDelay = SplitEarth:GetSpecialValueFloat('delay')
    local nDamage = SplitEarth:GetAbilityDamage()
    local nManaCost = SplitEarth:GetManaCost()
    local nAbilityLevel = SplitEarth:GetLevel()

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                if not Fu.IsInRange(bot, enemyHero, nCastRange)
                then
                    local loc = Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetExtrapolatedLocation(nDelay + nCastPoint), nCastRange)
                    local nInRangeEnemy = Fu.GetEnemiesNearLoc(loc, nRadius)
                    if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                    then
                        return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                    end

                    return BOT_ACTION_DESIRE_HIGH, loc
                end

                local nInRangeEnemy = Fu.GetEnemiesNearLoc(enemyHero:GetExtrapolatedLocation(nDelay + nCastPoint), nRadius)
                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                end

                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay + nCastPoint)
            end
        end
    end

    if bInTeamFight
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nDelay, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsDisabled(botTarget)

        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if Fu.IsChasingTarget(bot, botTarget)
                then
                    nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetExtrapolatedLocation(nDelay + nCastPoint), nRadius)
                else
                    nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
                end

                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    if not Fu.IsInRange(bot, botTarget, nCastRange)
                    then
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                        else
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        end
                    end
                end

                if not Fu.IsInRange(bot, botTarget, nCastRange)
                then
                    if Fu.IsChasingTarget(bot, botTarget)
                    then
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetExtrapolatedLocation(nDelay + nCastPoint), nCastRange)
                    else
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                    end
                else
                    if Fu.IsChasingTarget(bot, botTarget)
                    then
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nDelay + nCastPoint)
                    else
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                    end
                end

            end
        end
    end

    if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay + nCastPoint)
                end
            end
        end
	end

    if Fu.IsFarming(bot)
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)

        if bAttacking
        then
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyHeroes)
            end
        end
    end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and nLocationAoE.count >= 3
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nDelay + nCastPoint, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsLaning(bot)
    and nAbilityLevel >= 2
	then
        local creepList = {}
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		for _, creep in pairs(nEnemyLaneCreeps)
		do
            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                table.insert(creepList, creep)
            end
		end

        if Fu.GetManaAfter(nManaCost) > 0.25
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and #creepList >= 2
        and Fu.CanBeAttacked(creepList[1])
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
        and not Fu.IsDisabled(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nAllyInRangeEnemy)
        do
            if Fu.IsValidHero(allyHero)
            and Fu.IsRetreating(allyHero)
            and Fu.GetManaAfter(nManaCost) > 0.4
            and allyHero:WasRecentlyDamagedByAnyHero(2)
            and not Fu.IsSuspiciousIllusion(allyHero)
            then
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and Fu.IsChasingTarget(enemyHero, allyHero)
                and not Fu.IsDisabled(enemyHero)
                and not Fu.IsTaunted(enemyHero)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                and not enemyHero:HasModifier('modifier_leshrac_lightning_storm_slow')
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nDelay + nCastPoint)
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderDiabolicEdict()
    if not DiabolicEdict:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = DiabolicEdict:GetSpecialValueInt('radius')
    local nManaCost = DiabolicEdict:GetManaCost()

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius + 100)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsFarming(bot)
    and Fu.GetManaAfter(nManaCost) > 0.35
    and not bot:HasModifier('modifier_leshrac_pulse_nova')
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
        if nNeutralCreeps ~= nil
        and #nNeutralCreeps > 0
        and ((#nNeutralCreeps < 3)
            or (#nNeutralCreeps <= 2 and nNeutralCreeps[1]:IsAncientCreep()))
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps <= 3
        and #nEnemyLaneCreeps > 0
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsPushing(bot)
    and Fu.GetManaAfter(nManaCost) > 0.25
    then
        local nEnemyTowers = bot:GetNearbyTowers(1000, true)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(800, true)
        if nEnemyTowers ~= nil and #nEnemyTowers >= 1
        and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps <= 2
        then
            bot.edictPushing = true
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderLightningStorm()
    if not LightningStorm:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, LightningStorm:GetCastRange())
    local nDamage = LightningStorm:GetSpecialValueInt('damage')
    local nJumpDist = LightningStorm:GetSpecialValueInt('radius')

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
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    if bInTeamFight
    then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)
        local target = nil
        local hp = 100000

        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and not enemyHero:HasModifier('modifier_item_sphere_target')
            then
                local nTargetInRangeAlly = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nJumpDist)
                local currHP = enemyHero:GetHealth()

                if nTargetInRangeAlly ~= nil and #nTargetInRangeAlly >= 1
                and currHP < hp
                then
                    hp = currHP
                    target = enemyHero
                end
            end
        end

        if target ~= nil
        then
            return BOT_ACTION_DESIRE_HIGH, target
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
        end
    end

    if bRetreating
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.35
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
        if nNeutralCreeps ~= nil
        and ((#nNeutralCreeps >= 2)
            or (#nNeutralCreeps >= 1 and nNeutralCreeps[1]:IsAncientCreep()))
        then
            return BOT_ACTION_DESIRE_HIGH, nNeutralCreeps[1]
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
        end
    end

    if Fu.IsLaning(bot)
	then
        local creepList = {}
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
            -- and Fu.CanBeAttacked(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage
            -- and nBotMP > 0.3
			-- then
			-- 	nInRangeEnemy = creep:GetNearbyHeroes(800, false, BOT_MODE_NONE)

			-- 	if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
			-- 	and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) < nInRangeEnemy[1]:GetAttackRange()
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH, creep
			-- 	end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                table.insert(creepList, creep)
            end
		end

        if nBotMP > 0.25
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and #creepList >= 2
        and Fu.CanBeAttacked(creepList[1])
        then
            return BOT_ACTION_DESIRE_HIGH, creepList[1]
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_roshan_spell_block')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nAllyInRangeEnemy)
        do
            if Fu.IsValidHero(allyHero)
            and Fu.IsRetreating(allyHero)
            and nBotMP > 0.45
            and allyHero:WasRecentlyDamagedByAnyHero(1.5)
            and not Fu.IsSuspiciousIllusion(allyHero)
            then
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and Fu.IsChasingTarget(enemyHero, allyHero)
                and not Fu.IsDisabled(enemyHero)
                and not Fu.IsTaunted(enemyHero)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderPulseNova()
    if not PulseNova:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRadius = PulseNova:GetSpecialValueInt('radius')

    if bInTeamFight
	then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius + 150)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            if PulseNova:GetToggleState() == false
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                if nBotMP < 0.25
                and PulseNova:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
	end

	if bGoingOnSomeone
	then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius + 150)
        and not Fu.IsSuspiciousIllusion(botTarget)
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            and (#nInRangeEnemy >= 1
                or (#nInRangeEnemy == 0
                    and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
                    and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')))
            then
                if PulseNova:GetToggleState() == false
                then
                    return BOT_ACTION_DESIRE_HIGH
                else
                    if nBotMP < 0.25
                    and PulseNova:GetToggleState() == true
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end

                    return BOT_ACTION_DESIRE_NONE
                end
            end
        end
	end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil
        then
            if #nEnemyLaneCreeps >= 1
            and PulseNova:GetToggleState() == false
            and bAttacking
            and nBotMP > 0.5
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                if (#nEnemyLaneCreeps == 0 or nBotMP < 0.25)
                and PulseNova:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsFarming(bot)
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
        if nNeutralCreeps ~= nil
        and ((#nNeutralCreeps >= 3)
            or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
        then
            if #nNeutralCreeps >= 3
            and PulseNova:GetToggleState() == false
            and bAttacking
            and nBotMP > 0.5
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                if (#nNeutralCreeps == 0 or nBotMP < 0.25)
                and PulseNova:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        if nEnemyLaneCreeps ~= nil
        then
            if #nEnemyLaneCreeps >= 3
            and PulseNova:GetToggleState() == false
            and bAttacking
            and nBotMP > 0.5
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                if (#nEnemyLaneCreeps == 0 or nBotMP < 0.25)
                and PulseNova:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            if PulseNova:GetToggleState() == false
            and nBotMP > 0.7
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                if nBotMP < 0.25
                and PulseNova:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            if PulseNova:GetToggleState() == false
            and nBotMP > 0.75
            then
                return BOT_ACTION_DESIRE_HIGH
            else
                if nBotMP < 0.25
                and PulseNova:GetToggleState() == true
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if PulseNova:GetToggleState() == true
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot, nRadius + 220, true, BOT_MODE_NONE)
        if #nInRangeEnemy <= 0 then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderNihilism()
    if not Nihilism:IsTrained()
    or not Nihilism:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = Nihilism:GetSpecialValueInt('radius')

    if Fu.IsWithoutTarget(bot)
    and Fu.GetAttackProjectileDamageByRange(bot, 1200) >= bot:GetHealth()
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if bRetreating
	then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

		if bot:WasRecentlyDamagedByAnyHero(2)
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

return X