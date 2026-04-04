local X = {}
local bot = GetBot()

local Utils = require( GetScriptDirectory()..'/FuncLib/systems/utils' )
local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

if Utils.GetLoneDruid(bot).hero == nil then Utils.GetLoneDruid(bot).hero = bot end

local tTalentTreeList = {--pos2
                        ['t25'] = {0, 10},
                        ['t20'] = {0, 10},
                        ['t15'] = {0, 10},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
                        -- {1,2,1,2,1,6,1,2,2,3,6,3,3,3,6},--pos2
                        {2,2,6,2,2,3,6,3,3,3,6,1,1,1,1},--no bear
}

local nAbilityBuildListWithBear = {1,2,1,3,1,6,1,2,2,2,6,3,3,3,6} --pos2

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

local sUtility = {"item_mjollnir", "item_radiance"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

sRoleItemsBuyList['pos_1'] = {
	"item_ranged_carry_outfit",
	-- "item_dragon_lance",
	"item_mask_of_madness",
    "item_maelstrom",
    "item_mjollnir",--
	-- "item_hurricane_pike",--
    "item_basher",
    "item_monkey_king_bar",--
    "item_black_king_bar",--
    "item_abyssal_blade",--
	"item_skadi",--
	"item_travel_boots",
	"item_moon_shard",
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
    
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1_w_bear'] = {
    "item_tango",
    "item_phase_boots",
    -- "item_quelling_blade",
    "item_magic_wand",
    "item_mask_of_madness",--1
    -- "item_maelstrom",
    'item_boots',
    nUtility,--1
    'item_boots',
    -- "item_basher",
    "item_abyssal_blade",--1
    "item_ultimate_scepter",
    "item_black_king_bar",--1
    "item_assault",--1
    "item_black_king_bar",--2
    "item_monkey_king_bar",--1
	"item_moon_shard",
    "item_moon_shard",
    "item_ultimate_scepter_2",
    "item_aghanims_shard",


    "item_travel_boots",
    "item_skadi",--2
    "item_monkey_king_bar",--2
    "item_satanic",--2
    "item_greater_crit",--2
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--2
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	-- "item_black_king_bar",
	-- "item_quelling_blade",
}

if Utils.GetLoneDruid(bot).roleType == nil then
    if RandomInt(1, 5) >= 0 then -- always with bear, for now.
        Utils.GetLoneDruid(bot).roleType = 'pos_1_w_bear'
    else
        Utils.GetLoneDruid(bot).roleType = 'pos_1'
    end
else
    if Utils.GetLoneDruid(bot).roleType == 'pos_1_w_bear' then
        X['sBuyList'] = sRoleItemsBuyList['pos_1_w_bear']
        nAbilityBuildList = nAbilityBuildListWithBear
    end
end


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local SummonSpiritBear  = bot:GetAbilityByName('lone_druid_spirit_bear')
-- local SpiritLink        = bot:GetAbilityByName('lone_druid_spirit_link')
local SavageRoar        = bot:GetAbilityByName('lone_druid_savage_roar')
local TrueForm          = bot:GetAbilityByName('lone_druid_true_form')

local SummonSpiritBearDesire
local SavageRoarDesire
local TrueFormDesire

local botTarget

local nBotHP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

    local ctx = AbilityCtx.Build(bot)
	nBotHP = ctx.hp

    botTarget = ctx.target

    TrueFormDesire = X.ConsiderTrueForm()
    if TrueFormDesire > 0
    then
        bot:Action_UseAbility(TrueForm)
        return
    end

    SavageRoarDesire = X.ConsiderSavageRoar()
    if SavageRoarDesire > 0
    then
        bot:Action_UseAbility(SavageRoar)
        return
    end

    SummonSpiritBearDesire = X.ConsiderSummonSpiritBear()
    if SummonSpiritBearDesire > 0
    then
        bot:Action_UseAbility(SummonSpiritBear)
        return
    end
end

function X.ConsiderSummonSpiritBear()
    if not SummonSpiritBear:IsFullyCastable() or Utils.GetLoneDruid(bot).roleType ~= 'pos_1_w_bear'
    then
        return BOT_ACTION_DESIRE_NONE
    end

	if Utils.GetLoneDruid(bot).bear == nil or not Utils.GetLoneDruid(bot).bear:IsAlive()
    then
		return BOT_ACTION_DESIRE_HIGH
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSavageRoar()
    if not SavageRoar:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = SavageRoar:GetSpecialValueInt('radius')
    local nInRangeEnemy = Fu.GetNearbyHeroes(bot, nRadius, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nInRangeEnemy) do
		if Fu.IsValidTarget(enemyHero)
        -- and Fu.IsInRange(bot, enemyHero, nRadius)
        and (Fu.IsChasingTarget(enemyHero, bot)
            or Fu.IsAttacking(enemyHero)
            or Fu.IsMoving(enemyHero)
            or enemyHero:IsChanneling()
            or enemyHero:IsUsingAbility())
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not Fu.IsDisabled(enemyHero)
        and Fu.CanCastOnNonMagicImmune( enemyHero )
        and Fu.CanCastOnTargetAdvanced( enemyHero )
		then
            return BOT_ACTION_DESIRE_HIGH
		end
    end

    if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderTrueForm()
    if TrueForm:IsHidden()
    or not TrueForm:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetCurrentVisionRange())
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            and nBotHP < 0.85
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if Fu.IsInTeamFight(bot, 1200) and nBotHP < 0.85 then
        return BOT_ACTION_DESIRE_HIGH
    end

    if Fu.IsRetreating(bot)
	then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1000)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and nBotHP < 0.45
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1.5))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE
end

return X