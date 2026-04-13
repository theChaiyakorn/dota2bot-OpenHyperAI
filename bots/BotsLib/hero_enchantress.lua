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
                            ['t25'] = {0, 10},
                            ['t20'] = {0, 10},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos4,5
                            ['t25'] = {0, 10},
                            ['t20'] = {0, 10},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        }
}

local tAllAbilityBuildList = {
                        {1,3,1,3,1,6,1,2,3,3,6,2,2,2,6},--pos3
						{2,3,2,3,2,6,2,1,1,1,1,6,3,3,6},--pos4,5
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_3' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_4' then nAbilityBuildList = tAllAbilityBuildList[2] end
if sRole == 'pos_5' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) 
if sRole == 'pos_3' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_4' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end
if sRole == 'pos_5' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end

local sUtility = {"item_heavens_halberd", "item_crimson_guard"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_magic_stick",
    "item_double_branches",
    "item_circlet",

    "item_magic_wand",
    "item_bracer",
    "item_power_treads",
    "item_mage_slayer",--
    "item_force_staff",
    "item_hurricane_pike",--
    nUtility,--
    "item_pipe",--
    "item_assault",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_magic_wand",
    "item_boots",
    "item_force_staff",
    "item_guardian_greaves",--
    "item_hurricane_pike",--
    "item_aghanims_shard",
    "item_mage_slayer",--
    "item_moon_shard",--
    "item_bloodthorn",--
    "item_sheepstick",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_magic_wand",
    "item_boots",
    "item_force_staff",
    "item_pavise",
    "item_pipe",
    "item_solar_crest",--
    "item_hurricane_pike",--
    "item_aghanims_shard",
    "item_boots_of_bearing",--
    "item_moon_shard",--
    "item_bloodthorn",--
    "item_sheepstick",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {
	"item_ranged_carry_outfit",
	"item_dragon_lance",
	"item_point_booster",
    "item_force_staff",
	"item_hurricane_pike", --
	"item_black_king_bar",--
	"item_travel_boots",
    "item_mage_slayer",--
	"item_bloodthorn",--
	"item_sheepstick",--
    "item_aghanims_shard",
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

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

local Impetus           = SafeAbility(bot:GetAbilityByName('enchantress_impetus'), 'enchantress_impetus', 'enchantress')
local Enchant           = SafeAbility(bot:GetAbilityByName('enchantress_enchant'), 'enchantress_enchant', 'enchantress')
local NaturesAttendant  = SafeAbility(bot:GetAbilityByName('enchantress_natures_attendants'), 'enchantress_natures_attendants', 'enchantress')
local Sproink           = SafeAbility(bot:GetAbilityByName('enchantress_bunny_hop'), 'enchantress_bunny_hop', 'enchantress')
local LittleFriends     = SafeAbility(bot:GetAbilityByName('enchantress_little_friends'), 'enchantress_little_friends', 'enchantress')
-- local Untouchable       = bot:GetAbilityByName('enchantress_untouchable')

local ImpetusDesire
local EnchantDesire, EnchantTarget
local NaturesAttendantDesire
local SproinkDesire
local LittleFriendsDesire, LittleFriendsTarget

local botTarget
local bGoingOnSomeone
local bRetreating
local nBotMP
function X.SkillsComplement()

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	nBotMP = ctx.mp
	if Fu.CanNotUseAbility(bot)
    then
        return
    end

    LittleFriendsDesire, LittleFriendsTarget = X.ConsiderLittleFriends()
    if LittleFriendsDesire > 0
    then
        bot:Action_UseAbilityOnEntity(LittleFriends, LittleFriendsTarget)
        return
    end

    ImpetusDesire = X.ConsiderImpetus()
    if ImpetusDesire > 0
    then
        return
    end

    SproinkDesire = X.ConsiderSproink()
    if SproinkDesire > 0
    then
        bot:Action_UseAbility(Sproink)
        return
    end

    NaturesAttendantDesire = X.ConsiderNaturesAttendant()
    if NaturesAttendantDesire > 0
    then
        bot:Action_UseAbility(NaturesAttendant)
        return
    end

    EnchantDesire, EnchantTarget = X.ConsiderEnchant()
    if EnchantDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Enchant, EnchantTarget)
        return
    end
end

function X.ConsiderImpetus()
    if not Impetus:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nAttackRange = bot:GetAttackRange()
    local nAbilityLevel = Impetus:GetLevel()
    botTarget = Fu.GetProperTarget(bot)

    if bGoingOnSomeone
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)

        and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeAlly >= #nInRangeEnemy
        then
            if not Impetus:GetAutoCastState()
            then
                Impetus:ToggleAutoCast()
                return BOT_ACTION_DESIRE_HIGH
            else
                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsFarming(bot)
    and nAbilityLevel == 4
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nAttackRange)

        if nNeutralCreeps ~= nil and #nNeutralCreeps >= 1
        and Fu.IsValid(nNeutralCreeps[1])
        then
            if not Impetus:GetAutoCastState()
            then
                Impetus:ToggleAutoCast()
                return BOT_ACTION_DESIRE_HIGH
            else
                if Impetus:GetAutoCastState()
                and nBotMP < 0.25
                then
                    Impetus:ToggleAutoCast()
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.IsAttacking(bot)
        then
            if not Impetus:GetAutoCastState()
            then
                Impetus:ToggleAutoCast()
                return BOT_ACTION_DESIRE_HIGH
            else
                if Impetus:GetAutoCastState()
                and nBotMP < 0.25
                then
                    Impetus:ToggleAutoCast()
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
        then
            if not Impetus:GetAutoCastState()
            then
                Impetus:ToggleAutoCast()
                return BOT_ACTION_DESIRE_HIGH
            else
                if Impetus:GetAutoCastState()
                and nBotMP < 0.25
                then
                    Impetus:ToggleAutoCast()
                    return BOT_ACTION_DESIRE_HIGH
                end

                return BOT_ACTION_DESIRE_NONE
            end
        end
    end

    if Impetus:GetAutoCastState()
    then
        Impetus:ToggleAutoCast()
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderEnchant()
    if not Enchant:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Enchant:GetCastRange()
    local nMaxLevel = Enchant:GetSpecialValueInt('level_req')
    local nDamage = Enchant:GetSpecialValueInt('enchant_damage')
    local nDuration = Enchant:GetSpecialValueFloat('slow_duration')
	local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
    botTarget = Fu.GetProperTarget(bot)

    -- local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    -- for _, enemyHero in pairs(nEnemyHeroes)
    -- do
    --     if Fu.IsValidHero(enemyHero)
    --     and Fu.CanCastOnNonMagicImmune(enemyHero)
    --     and Fu.CanKillTarget(enemyHero, nDamage * nDuration, DAMAGE_TYPE_ALL)
    --     and not Fu.IsSuspiciousIllusion(enemyHero)
    --     then
    --         return BOT_ACTION_DESIRE_HIGH, enemyHero
    --     end
    -- end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and Fu.IsValidHero(nAllyInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
        and not Fu.IsDisabled(nAllyInRangeEnemy[1])
        then
            if Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    if bGoingOnSomeone
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 100, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)

        and not botTarget:HasModifier('modifier_faceless_void_chronosphere')
        and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and ((#nInRangeAlly >= #nInRangeEnemy) or (#nInRangeEnemy > #nInRangeAlly and Fu.WeAreStronger(bot, nCastRange + 100)))
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    local nGoodCreep = {
        "npc_dota_neutral_alpha_wolf",
        "npc_dota_neutral_centaur_khan",
        "npc_dota_neutral_polar_furbolg_ursa_warrior",
        "npc_dota_neutral_dark_troll_warlord",
        "npc_dota_neutral_satyr_hellcaller",
        "npc_dota_neutral_enraged_wildkin",
        "npc_dota_neutral_warpine_raider",
    }

    for _, creep in pairs(nNeutralCreeps)
    do
        if Fu.IsValid(creep)
        and creep:GetLevel() <= nMaxLevel
        then
            for _, gCreep in pairs(nGoodCreep)
            do
                if creep:GetUnitName() == gCreep
                then
                    return BOT_ACTION_DESIRE_HIGH, creep
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderNaturesAttendant()
    if not NaturesAttendant:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bRetreating
    then
        if Fu.GetHP(bot) < 0.65
        and bot:DistanceFromFountain() > 800
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSproink()
    if not Sproink:IsTrained()
    or not Sproink:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nAttackRange = bot:GetAttackRange()

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nAttackRange + 100, false, BOT_MODE_NONE)
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nAttackRange, true, BOT_MODE_NONE)
    local nImpetusMul = Impetus:GetSpecialValueFloat('value') / 100
    botTarget = Fu.GetProperTarget(bot)

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanKillTarget(enemyHero, nImpetusMul * GetUnitToUnitDistance(bot, enemyHero), DAMAGE_TYPE_PURE)
        and bot:IsFacingLocation(enemyHero:GetLocation(), 15)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidTarget(botTarget)
        and bot:IsFacingLocation(botTarget:GetLocation(), 15)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bRetreating
    then
        if nAllyHeroes ~= nil and nEnemyHeroes ~= nil
        and #nEnemyHeroes > #nAllyHeroes
        and Fu.IsValidHero(nEnemyHeroes[1])
        and bot:IsFacingLocation(nEnemyHeroes[1]:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nEnemyHeroes[1])
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderLittleFriends()
    if not LittleFriends:IsTrained()
    or not LittleFriends:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = LittleFriends:GetCastRange()
    local nRadius = LittleFriends:GetSpecialValueInt('radius')
    local nDuration = LittleFriends:GetSpecialValueInt('duration')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.GetHP(enemyHero) < 0.33
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_faceless_void_chronosphere')
        then
            bot:SetTarget(enemyHero)
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    if Fu.IsGoingOnSomeone(bot, 1200)
    then
        if Fu.IsValidTarget(npcTarget)
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        and #nTargetInRangeEnemy >= 1
        and not Fu.IsSuspiciousIllusion(npcTarget)
        and not npcTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not npcTarget:HasModifier('modifier_faceless_void_chronosphere')
        then
            local botTarget = Fu.GetStrongestUnit(nCastRange, bot, true, false, nDuration)
            local nTargetInRangeEnemy = Fu.GetNearbyHeroes(botTarget, nRadius, true, BOT_MODE_NONE)
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 150, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 150, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeEnemy > #nInRangeAlly
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        local botTarget = bot:GetAttackTarget()

        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X