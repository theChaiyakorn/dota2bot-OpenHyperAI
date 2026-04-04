local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        {--pos3
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        },
                        {--pos4,5
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        }
}

local tAllAbilityBuildList = {
						{2,1,2,1,2,6,2,1,1,3,6,3,3,3,6},--pos3
                        {2,1,2,1,2,6,2,1,1,3,6,3,3,3,6},--pos4,5
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_3' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_4' then nAbilityBuildList = tAllAbilityBuildList[2] end
if sRole == 'pos_5' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
if sRole == 'pos_3' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_4' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end
if sRole == 'pos_5' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end

local sUtility = {"item_pipe", "item_lotus_orb"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_double_circlet",

    "item_magic_wand",
    "item_vladmir",
    "item_boots",
    "item_blink",
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_octarine_core",--
    nUtility,--
    "item_refresher",--
    "item_travel_boots",
    "item_arcane_blink",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_4'] = {
    "item_enchanted_mango",
    "item_double_tango",
    "item_circlet",
    "item_double_branches",
    "item_blood_grenade",

    "item_magic_wand",
    "item_boots",
    "item_vladmir",--
    "item_arcane_boots",
    "item_blink",
    "item_guardian_greaves",--
    "item_black_king_bar",--
	"item_lotus_orb",
	"item_gungir",--
    "item_refresher",--
    "item_arcane_blink",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_enchanted_mango",
    "item_double_tango",
    "item_circlet",
    "item_double_branches",
    "item_blood_grenade",

    "item_magic_wand",
    "item_boots",
    "item_vladmir",--
    "item_tranquil_boots",
    "item_pipe",--
    "item_blink",
    "item_boots_of_bearing",--
    "item_black_king_bar",--
    "item_refresher",--
    "item_arcane_blink",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]


X['sSellList'] = {

	"item_ultimate_scepter",
	"item_magic_wand",

	"item_cyclone",
	"item_magic_wand",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local Malefice          = bot:GetAbilityByName('enigma_malefice')
local DemonicSummoning  = bot:GetAbilityByName('enigma_demonic_conversion')
local MidnightPulse     = bot:GetAbilityByName('enigma_midnight_pulse')
local BlackHole         = bot:GetAbilityByName('enigma_black_hole')

local MaleficeAdditionalInstanceTalent = bot:GetAbilityByName('special_bonus_unique_enigma_2')
local MidnightPulseRadiusTalent = bot:GetAbilityByName('special_bonus_unique_enigma_6')

local MaleficeDesire, MaleficeTarget
local DemonicSummoningDesire, DemonicSummoningLocation
local MidnightPulseDesire, MidnightPulseLocation
local BlackHoleDesire, BlackHoleLocation

local BlinkHoleDesire, BlinkHoleLocation
local BlinkPulseHoleDesire, BlinkPulseHoleLocation

local Blink
local BlackKingBar

local botTarget

local bGoingOnSomeone
local bAttacking
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bAttacking = Fu.IsAttacking(bot)
	bInTeamFight = ctx.isTeamFight

    botTarget = ctx.target

    -- if near by enemy hero is pulled by black hole, don't do anything
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and (enemyHero:HasModifier('modifier_enigma_black_hole_pull')
        or enemyHero:HasModifier('modifier_enigma_black_hole_pull_scepter'))
        then
            return
        end
    end
    
    BlinkPulseHoleDesire, BlinkPulseHoleLocation = X.ConsiderBlinkPulseHole()
    if BlinkPulseHoleDesire > 0
    then
        bot:Action_ClearActions(false)

        if X.CanBKB()
        and not bot:IsMagicImmune()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
            bot:ActionQueue_Delay(0.1)
        end

        bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkPulseHoleLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbilityOnLocation(MidnightPulse, BlinkPulseHoleLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbilityOnLocation(BlackHole, BlinkPulseHoleLocation)
        return
    end

    BlinkHoleDesire, BlinkHoleLocation = X.ConsiderBlinkHole()
    if BlinkHoleDesire > 0
    then
        bot:Action_ClearActions(false)

        if X.CanBKB()
        and not bot:IsMagicImmune()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
            bot:ActionQueue_Delay(0.1)
        end

        bot:ActionQueue_UseAbilityOnLocation(Blink, BlinkHoleLocation)
        bot:ActionQueue_Delay(0.1)
        bot:ActionQueue_UseAbilityOnLocation(BlackHole, BlinkHoleLocation)
        return
    end

    MidnightPulseDesire, MidnightPulseLocation = X.ConsiderMidnightPulse()
    if MidnightPulseDesire > 0
    then
        bot:Action_UseAbilityOnLocation(MidnightPulse, MidnightPulseLocation)
        return
    end

    BlackHoleDesire, BlackHoleLocation = X.ConsiderBlackHole()
    if BlackHoleDesire > 0
    then
        if X.CanBKB()
        and not bot:IsMagicImmune()
        then
            bot:ActionQueue_UseAbility(BlackKingBar)
            bot:ActionQueue_Delay(0.1)
            bot:ActionQueue_UseAbilityOnLocation(BlackHole, BlackHoleLocation)
            return
        end

        bot:Action_UseAbilityOnLocation(BlackHole, BlackHoleLocation)
        return
    end

    MaleficeDesire, MaleficeTarget = X.ConsiderMalefice()
    if MaleficeDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Malefice, MaleficeTarget)
        return
    end

    DemonicSummoningDesire, DemonicSummoningLocation = X.ConsiderDemonicSummoning()
    if DemonicSummoningDesire > 0
    then
        bot:Action_UseAbilityOnLocation(DemonicSummoning, DemonicSummoningLocation)
        return
    end
end

function X.ConsiderMalefice()
    if not Malefice:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, Malefice:GetCastRange())
    local nStunInstances = Malefice:GetSpecialValueInt('value')

    if MaleficeAdditionalInstanceTalent:IsTrained()
    then
        nStunInstances = nStunInstances + Malefice:GetSpecialValueInt('value')
    end

	local nDamage = Malefice:GetSpecialValueInt('damage') * nStunInstances

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 150, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
		then
            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_aphotic_shield')
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
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
        and Fu.IsInRange(bot, botTarget, nCastRange + 150)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1400, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1400, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
		end
	end

	if Fu.IsRetreating(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

        if Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.CanCastOnTargetAdvanced(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not Fu.IsRealInvisible(bot)
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and (#nTargetInRangeAlly > #nInRangeAlly
                or bot:WasRecentlyDamagedByAnyHero(2))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
            end
		end
	end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1600, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and (not Fu.IsCore(bot) or Fu.IsCore(bot) and Fu.GetManaAfter(Malefice:GetManaCost()) > 0.66)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

	if Fu.IsDoingRoshan(bot)
	then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
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

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderDemonicSummoning()
    if not DemonicSummoning:IsFullyCastable() or Fu.GetHP(bot) < 0.25
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, DemonicSummoning:GetCastRange())
    local nHPCost = 75 + (25 * (DemonicSummoning:GetLevel() - 1))

    if bGoingOnSomeone
    and Fu.GetHP(bot) > 0.5
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1400, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1400, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                if DotaTime() < 10 * 60
                then
                    local nEnemyTowers = botTarget:GetNearbyTowers(800, false)
                    if nEnemyTowers ~= nil
                    then
                        if Fu.IsChasingTarget(bot, botTarget)
                        then
                            if Fu.IsInRange(bot, botTarget, nCastRange)
                            and #nEnemyTowers == 0
                            then
                                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                            else
                                if #nEnemyTowers == 0
                                then
                                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                                end
                            end
                        else
                            if Fu.IsInRange(bot, botTarget, nCastRange)
                            then
                                return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + botTarget:GetLocation()) / 2
                            end
                        end
                    end
                else
                    if Fu.IsChasingTarget(bot, botTarget)
                    then
                        if Fu.IsInRange(bot, botTarget, nCastRange)
                        then
                            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                        else
                            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                        end
                    else
                        if Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
                        then
                            return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + botTarget:GetLocation()) / 2
                        end
                    end
                end
            end
		end
	end

	if Fu.IsDefending(bot) or Fu.IsPushing(bot)
	then
        if bAttacking
        then
            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            end

            local nEnemyTowers = bot:GetNearbyTowers(800, true)
            local nEnemyBarracks = bot:GetNearbyBarracks(800,true)
            local nEnemyFillers = bot:GetNearbyFillers(800, true)

            if Fu.IsValidBuilding(bot:GetAttackTarget())
            and (nEnemyTowers ~= nil and #nEnemyTowers >= 1
                or nEnemyBarracks ~= nil and #nEnemyBarracks >= 1
                or nEnemyFillers ~= nil and #nEnemyFillers >= 1)
            then
                return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            end
        end
	end

    if Fu.IsFarming(bot)
    and Fu.GetHealthAfter(nHPCost) > 0.5
    and Fu.GetManaAfter(DemonicSummoning:GetManaCost()) > 0.33
    and bAttacking
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end

        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
        if nNeutralCreeps ~= nil and #nNeutralCreeps >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
    end

    if Fu.IsLaning(bot)
    and Fu.GetHealthAfter(nHPCost) > 0.61
    and Fu.GetManaAfter(DemonicSummoning:GetManaCost()) > 0.5
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(800, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
    end

    if Fu.IsDoingRoshan(bot)
    and Fu.GetHealthAfter(nHPCost) > 0.5
	then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
	end

    if Fu.IsDoingTormentor(bot)
    and Fu.GetHealthAfter(nHPCost) > 0.63
	then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderMidnightPulse()
    if not MidnightPulse:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, MidnightPulse:GetCastRange())
    local nRadius = MidnightPulse:GetSpecialValueInt('radius')

    if MidnightPulseRadiusTalent:IsTrained()
    then
        nRadius = nRadius + MidnightPulse:GetSpecialValueInt('value')
    end

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius / 2, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius * 0.8)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)

		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1400, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1400, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius * 0.66)
                if Fu.IsInRange(bot, botTarget, nCastRange)
                then
                    if not Fu.IsChasingTarget(bot, botTarget)
                    then
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        else
                            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                        end
                    else
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(1)
                    end
                else
                    if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
                    and not Fu.IsInRange(bot, botTarget, nCastRange)
                    and not Fu.IsChasingTarget(bot, botTarget)
                    then
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                    end
                end
            end
		end
	end

    if Fu.IsDoingRoshan(bot)
	then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
	end

    if Fu.IsDoingTormentor(bot)
	then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderBlackHole()
    if not BlackHole:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, BlackHole:GetCastRange())
    local nRadius = BlackHole:GetSpecialValueInt('radius')
    local nDamage = BlackHole:GetSpecialValueInt('value')
    local nDuration = BlackHole:GetSpecialValueInt('duration')

	if bInTeamFight
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius * 0.8, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not botTarget:HasModifier('modifier_item_aeon_disk_buff')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            then
                if #nInRangeEnemy >= #nInRangeAlly
                and #nInRangeEnemy <= 1
                then
                    if Fu.CanKillTarget(botTarget, nDamage * nDuration, DAMAGE_TYPE_PURE)
                    -- and Fu.IsCore(botTarget)
                    and botTarget:GetHealth() > 200
                    then
                        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        else
                            if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
                            and not Fu.IsInRange(bot, botTarget, nCastRange)
                            then
                                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                            else
                                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                            end
                        end
                    end
                end

                if #nInRangeAlly >= #nInRangeEnemy
                -- and Fu.IsCore(botTarget)
                then
                    if #nInRangeAlly <= 1
                    and Fu.CanKillTarget(botTarget, nDamage * 1.1 * nDuration, DAMAGE_TYPE_PURE)
                    then
                        return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                    else
                        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
                        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        else
                            if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
                            and not Fu.IsInRange(bot, botTarget, nCastRange)
                            then
                                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
                            else
                                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
                            end
                        end
                    end
                end
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderBlinkHole()
    if X.CanDoBlinkHole()
    then
        local nRadius = BlackHole:GetSpecialValueInt('radius')

        if bInTeamFight
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 1199, nRadius, 0, 0)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.CanDoBlinkHole()
    if BlackHole:IsFullyCastable()
    and Blink ~= nil and Blink:IsFullyCastable()
    then
        local nManaCost = BlackHole:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end
function X.ConsiderBlinkPulseHole()
    if X.CanDoBlinkPulseHole()
    then
        local nRadius = BlackHole:GetSpecialValueInt('radius')

        if bInTeamFight
        then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), 1199, nRadius, 0, 0)
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.CanDoBlinkPulseHole()
    if BlackHole:IsFullyCastable()
    and MidnightPulse:IsFullyCastable()
    and Blink ~= nil and Blink:IsFullyCastable()
    then
        local nManaCost = BlackHole:GetManaCost() + MidnightPulse:GetManaCost()

        if bot:GetMana() >= nManaCost
        then
            return true
        end
    end

    return false
end

function X.HasBlink()
    local blink = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil
        and (item:GetName() == "item_blink" or item:GetName() == "item_overwhelming_blink" or item:GetName() == "item_arcane_blink" or item:GetName() == "item_swift_blink")
        then
			blink = item
			break
		end
	end

    if blink ~= nil
    and blink:IsFullyCastable()
	then
        Blink = blink
        return true
	end

    return false
end

function X.CanBKB()
    local bkb = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil
        and item:GetName() == "item_black_king_bar"
        then
			bkb = item
			break
		end
	end

    if bkb ~= nil
    and bkb:IsFullyCastable()
	then
        BlackKingBar = bkb
        return true
	end

    return false
end

return X