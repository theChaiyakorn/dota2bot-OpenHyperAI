local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {--pos4,5
                        ['t25'] = {10, 0},
                        ['t20'] = {0, 10},
                        ['t15'] = {0, 10},
                        ['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{3,1,3,2,3,6,3,1,1,1,6,2,2,2,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
	"item_enchanted_mango",
	"item_blood_grenade",
	"item_priest_outfit",
	"item_mekansm",
	"item_glimmer_cape",--
    "item_rod_of_atos",
	"item_guardian_greaves",--
    "item_gungir",--
	"item_shivas_guard",--
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_moon_shard",
	"item_octarine_core",--
}

sRoleItemsBuyList['pos_5'] = {
	"item_blood_grenade",
	'item_mage_outfit',
	'item_ancient_janggo',
	'item_glimmer_cape',
	'item_boots_of_bearing',
	'item_pipe',
	"item_rod_of_atos",
    "item_gungir",--
	"item_shivas_guard",
	'item_cyclone',
	'item_sheepstick',
	"item_wind_waker",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_blight_stone",

    "item_tranquil_boots",
    "item_magic_wand",
    "item_maelstrom",
    "item_force_staff",
    "item_gungir",--
    "item_boots_of_bearing",--
	"item_shivas_guard",--
    "item_ultimate_scepter",
    "item_sheepstick",--
    "item_hurricane_pike",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_greater_crit",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = {
	"item_crystal_maiden_outfit",
	"item_rod_of_atos",
	"item_maelstrom",
    "item_aether_lens",
	"item_gungir",--
	"item_black_king_bar",--
	"item_travel_boots",
	"item_orchid",
	"item_bloodthorn",--
	"item_ultimate_scepter",
	"item_moon_shard",
    "item_sheepstick",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local TameTheBeasts         = SafeAbility(bot:GetAbilityByName('ringmaster_tame_the_beasts'), 'ringmaster_tame_the_beasts', 'ringmaster')
local TameTheBeastsCrack    = SafeAbility(bot:GetAbilityByName('ringmaster_tame_the_beasts_crack'), 'ringmaster_tame_the_beasts_crack', 'ringmaster')
local EscapeAct             = SafeAbility(bot:GetAbilityByName('ringmaster_the_box'), 'ringmaster_the_box', 'ringmaster')
local ImpalementArts        = SafeAbility(bot:GetAbilityByName('ringmaster_impalement'), 'ringmaster_impalement', 'ringmaster')
local Spotlight             = SafeAbility(bot:GetAbilityByName('ringmaster_spotlight'), 'ringmaster_spotlight', 'ringmaster')
local WheelOfWonder         = SafeAbility(bot:GetAbilityByName('ringmaster_wheel'), 'ringmaster_wheel', 'ringmaster')

-- Souvernirs
local EmptySouvenir         = SafeAbility(bot:GetAbilityByName('ringmaster_empty_souvenir'), 'ringmaster_empty_souvenir', 'ringmaster')
local FunhouseMirror        = SafeAbility(bot:GetAbilityByName('ringmaster_funhouse_mirror'), 'ringmaster_funhouse_mirror', 'ringmaster')
local StrongmanTonic        = SafeAbility(bot:GetAbilityByName('ringmaster_strongman_tonic'), 'ringmaster_strongman_tonic', 'ringmaster')
local WhoopeeCushion        = SafeAbility(bot:GetAbilityByName('ringmaster_whoopee_cushion'), 'ringmaster_whoopee_cushion', 'ringmaster')
local CrystalBall           = SafeAbility(bot:GetAbilityByName("ringmaster_crystal_ball"), 'ringmaster_crystal_ball', 'ringmaster')
local WeightedPie           = SafeAbility(bot:GetAbilityByName("ringmaster_weighted_pie"), 'ringmaster_weighted_pie', 'ringmaster')
local Unicycle              = SafeAbility(bot:GetAbilityByName("ringmaster_summon_unicycle"), 'ringmaster_summon_unicycle', 'ringmaster')

local TameTheBeastsDesire, TameTheBeastsLocation
local TameTheBeastsCrackDesire
local EscapeActDesire, EscapeActTarget
local ImpalementArtsDesire, ImpalementArtsLocation
local SpotlightDesire, SpotlightLocation
local WheelOfWonderDesire, WheelOfWonderLocation

local FunhouseMirrorDesire
local StrongmanTonicDesire, StrongmanTonicTarget
local WhoopeeCushionDesire
local CrystalBallDesire, CrystalBallLocation
local WeightedPieDesire, WeightedPieTarget
local UnicycleDesire

local TameTheBeastsCastTime

local botTarget, botLevel

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) or bot:IsCastingAbility() or bot:IsChanneling() then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = ctx.hp

    botTarget = ctx.target
    botLevel = bot:GetLevel()

    WhoopeeCushionDesire = X.ConsiderWhoopeeCushion()
    if WhoopeeCushionDesire > 0
    then
        bot:Action_UseAbility(WhoopeeCushion)
        return
    end

    WheelOfWonderDesire, WheelOfWonderLocation = X.ConsiderWheelOfWonder()
    if WheelOfWonderDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(WheelOfWonder, WheelOfWonderLocation)
        return
    end

    TameTheBeastsCrackDesire = X.ConsiderTameTheBeastsCrack()
    if TameTheBeastsCrackDesire > 0
    then
        bot:Action_UseAbility(TameTheBeastsCrack)
        bot.whip_to_cancel = false
        bot.whip_to_kill = false
        bot.whip_to_kill_target = nil
        bot.whip_to_engage = false
        bot.whip_to_retreat = false
        bot.whip_to_push = false
        bot.whip_to_defend = false
        bot.whip_to_farm = false
        bot.whip_to_miniboss = false
        bot.whip_to_aoe_kill = false
        return
    end

    TameTheBeastsDesire, TameTheBeastsLocation = X.ConsiderTameTheBeasts()
    if TameTheBeastsDesire > 0
    then
        Fu.SetQueuePtToINT(bot, true)
        bot:ActionQueue_UseAbilityOnLocation(TameTheBeasts, TameTheBeastsLocation)
        TameTheBeastsCastTime = DotaTime()
        return
    end

    EscapeActDesire, EscapeActTarget = X.ConsiderEscapeAct()
    if EscapeActDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(EscapeAct, EscapeActTarget)
    end

    ImpalementArtsDesire, ImpalementArtsLocation = X.ConsiderImpalementArts()
    if ImpalementArtsDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(ImpalementArts, ImpalementArtsLocation)
    end

    StrongmanTonicDesire, StrongmanTonicTarget = X.ConsiderStrongmanTonic()
    if StrongmanTonicDesire > 0
    then
        bot:Action_UseAbilityOnEntity(StrongmanTonic, StrongmanTonicTarget)
        return
    end

    SpotlightDesire, SpotlightLocation = X.ConsiderSpotlight()
    if SpotlightDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(Spotlight, SpotlightLocation)
        return
    end

    FunhouseMirrorDesire = X.ConsiderFunhouseMirror()
    if FunhouseMirrorDesire > 0
    then
        bot:Action_UseAbility(FunhouseMirror)
        return
    end

    CrystalBallDesire, CrystalBallLocation = X.ConsiderCrystalBall()
    if CrystalBallDesire > 0
    then
        bot:ActionQueue_UseAbilityOnLocation(CrystalBall, CrystalBallLocation)
        return
    end

    WeightedPieDesire, WeightedPieTarget = X.ConsiderWeightedPie()
    if WeightedPieDesire > 0
    then
        bot:Action_UseAbilityOnEntity(WeightedPie, WeightedPieTarget)
        return
    end

    UnicycleDesire = X.ConsiderUnicycle()
    if UnicycleDesire > 0
    then
        bot:Action_UseAbility(Unicycle)
        return
    end

end

function X.ConsiderTameTheBeasts()
    if not Fu.CanCastAbility(TameTheBeasts)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, TameTheBeasts:GetCastRange())
    local nCastPoint = TameTheBeasts:GetCastPoint()
    local nOuterRadius = TameTheBeasts:GetSpecialValueInt('start_width')
    local nInnerRadius = TameTheBeasts:GetSpecialValueInt('end_width')
    local nMinDamage = TameTheBeasts:GetSpecialValueInt('damage_min')
    local nMaxDamage = TameTheBeasts:GetSpecialValueInt('damage_max')
    local nManaCost = TameTheBeasts:GetManaCost()

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, enemy in pairs(tEnemyHeroes)
    do
        if Fu.IsValidHero(enemy)
        and Fu.IsInRange(bot, enemy, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemy)
        then
            if enemy:HasModifier('modifier_teleporting')
            then
                bot.whip_to_cancel = true
                return BOT_ACTION_DESIRE_HIGH, enemy:GetLocation()
            end

            if Fu.CanKillTarget(enemy, nMaxDamage, DAMAGE_TYPE_MAGICAL)
            and not enemy:HasModifier('modifier_abaddon_borrowed_time')
            and not enemy:HasModifier('modifier_dazzle_shallow_grave')
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemy:HasModifier('modifier_oracle_false_promise_timer')
            then
                bot.whip_to_kill = true
                bot.whip_to_kill_target = enemy
                return BOT_ACTION_DESIRE_HIGH, enemy:GetLocation()
            end
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and (not Fu.IsChasingTarget(bot, botTarget) or Fu.IsInRange(bot, botTarget, nInnerRadius))
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
        and not (#tAllyHeroes >= #tEnemyHeroes + 3)
        then
            local nLocationAoE = bot:FindAoELocation(true, true, botTarget:GetLocation(), nOuterRadius, nOuterRadius, 0, 0)
            local targetLoc = botTarget:GetLocation()
            if nLocationAoE.count > 1
            then
                targetLoc = nLocationAoE.targetloc
            end

            bot.whip_to_engage = true
            return BOT_ACTION_DESIRE_HIGH, targetLoc
        end
    end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemy in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nOuterRadius)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not Fu.IsDisabled(enemy)
            and bot:WasRecentlyDamagedByHero(enemy, 3.0)
            and (nBotHP < 0.65 or Fu.IsChasingTarget(enemy, bot))
            then
                local nLocationAoE = bot:FindAoELocation(true, true, enemy:GetLocation(), nOuterRadius, nOuterRadius, 0, 0)
                local targetLoc = (bot:GetLocation() + enemy:GetLocation()) / 2
                if nLocationAoE.count > 1
                then
                    targetLoc = nLocationAoE.targetloc
                end

                bot.whip_to_retreat = true
                return BOT_ACTION_DESIRE_HIGH, targetLoc
            end
        end
    end

    local tEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + 150, true)

    if Fu.IsPushing(bot)
    and Fu.GetManaAfter(nManaCost) > 0.45
    then
        if #tEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
        and not Fu.IsRunning(tEnemyLaneCreeps[1])
        and (Fu.IsCore(bot) or not Fu.IsThereNonSelfCoreNearby(1600))
        then
            local nLocationAoE = bot:FindAoELocation(true, false, tEnemyLaneCreeps[1]:GetLocation(), nInnerRadius, nInnerRadius, 0, 0)
            local targetLoc = Fu.GetCenterOfUnits(tEnemyLaneCreeps)
            if nLocationAoE.count >= 4
            then
                targetLoc = nLocationAoE.targetloc
            end

            bot.whip_to_push = true
            return BOT_ACTION_DESIRE_HIGH, targetLoc
        end
    end

    if Fu.IsDefending(bot)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nInnerRadius, 0, 0)
        if nLocationAoE.count >= 2
        then
            bot.whip_to_defend = true
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        if #tEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
        and not Fu.IsRunning(tEnemyLaneCreeps[1])
        and (Fu.IsCore(bot) or not Fu.IsThereNonSelfCoreNearby(1600))
        then
            nLocationAoE = bot:FindAoELocation(true, false, tEnemyLaneCreeps[1]:GetLocation(), nInnerRadius, nInnerRadius, 0, 0)
            local targetLoc = Fu.GetCenterOfUnits(tEnemyLaneCreeps)
            if nLocationAoE.count >= 4
            then
                targetLoc = nLocationAoE.targetloc
            end

            bot.whip_to_defend = true
            return BOT_ACTION_DESIRE_HIGH, targetLoc
        end
    end

    if Fu.IsFarming(bot)
    and Fu.GetManaAfter(nManaCost) > 0.33
    then
        local tCreeps = bot:GetNearbyCreeps(nCastRange + 150, true)
        if Fu.CanBeAttacked(tCreeps[1])
        and not Fu.IsRunning(tCreeps[1])
        and (#tCreeps >= 2 or #tCreeps >= 1 and tCreeps[1]:IsAncientCreep())
        then
            local nLocationAoE = bot:FindAoELocation(true, false, tCreeps[1]:GetLocation(), nInnerRadius, nInnerRadius, 0, 0)
            local targetLoc = Fu.GetCenterOfUnits(tCreeps)
            if nLocationAoE.count >= 4
            then
                targetLoc = nLocationAoE.targetloc
            end

            bot.whip_to_farm = true
            return BOT_ACTION_DESIRE_HIGH, targetLoc
        end
    end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
		then
            bot.whip_to_miniboss = true
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
		then
            bot.whip_to_miniboss = true
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    -- this part self-interrupts Q
    if Fu.IsCore(bot) or not Fu.IsThereNonSelfCoreNearby(1600)
    then
        local tCreeps = bot:GetNearbyCreeps(nCastRange, true)
        local tCreepsCanKill = {}
        for _, creep in pairs(tCreeps)
        do
            if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            and not Fu.IsRunning(creep)
            and Fu.CanKillTarget(creep, nMaxDamage, DAMAGE_TYPE_MAGICAL)
            then
                table.insert(tCreepsCanKill, creep)
            end
        end

        if Fu.IsValid(tCreepsCanKill[1])
        then
            local nLocationAoE = bot:FindAoELocation(true, false, tCreepsCanKill[1]:GetLocation(), nInnerRadius, nInnerRadius, 0, 0)
            if Fu.IsLaning(bot)
            then
                if #tCreepsCanKill >= 2
                or (#tCreepsCanKill == 1
                    and Fu.GetManaAfter(nManaCost) > 0.18
                    and string.find(tCreepsCanKill[1]:GetUnitName(), 'ranged')
                    and Fu.IsValidHero(tEnemyHeroes[1])
                    and Fu.IsInRange(tCreepsCanKill[1], tEnemyHeroes[1], nOuterRadius))
                then
                    bot.whip_to_aoe_kill = true
                    return BOT_ACTION_DESIRE_HIGH, tCreepsCanKill[1]:GetLocation()
                end
            end

            if nLocationAoE.count >= 4 and #tCreepsCanKill >= 3
            then
                bot.whip_to_aoe_kill = true
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderTameTheBeastsCrack()
    if not Fu.CanCastAbility(TameTheBeastsCrack)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nChannelTime = TameTheBeasts:GetChannelTime()
    local nCastRange = Fu.GetProperCastRange(bot, false, TameTheBeasts:GetCastRange())
    local nCastPoint = TameTheBeasts:GetCastPoint()
    local nOuterRadius = TameTheBeasts:GetSpecialValueInt('start_width')
    local nInnerRadius = TameTheBeasts:GetSpecialValueInt('end_width')
    local nMinDamage = TameTheBeasts:GetSpecialValueInt('damage_min')
    local nMaxDamage = TameTheBeasts:GetSpecialValueInt('damage_max')
    local nManaCost = TameTheBeasts:GetManaCost()

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    local nDamageWindow = math.min(DotaTime() - TameTheBeastsCastTime, nChannelTime)
    local nDamage = RemapValClamped(nDamageWindow, 0, 1, nMinDamage, nMaxDamage)

    if bot.whip_to_aoe_kill
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bot.whip_to_cancel
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if bot.whip_to_kill
    then
        if Fu.IsValidHero(bot.whip_to_kill_target)
        and Fu.CanCastOnNonMagicImmune(bot.whip_to_kill_target)
        then
            if Fu.CanKillTarget(bot.whip_to_kill_target, nDamage, DAMAGE_TYPE_MAGICAL)
            and not bot.whip_to_kill_target:HasModifier('modifier_abaddon_borrowed_time')
            and not bot.whip_to_kill_target:HasModifier('modifier_dazzle_shallow_grave')
            and not bot.whip_to_kill_target:HasModifier('modifier_necrolyte_reapers_scythe')
            and not bot.whip_to_kill_target:HasModifier('modifier_oracle_false_promise_timer')
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bot.whip_to_engage
    then
        if Fu.IsValidHero(tEnemyHeroes[1]) and botLevel < 15
        or nBotHP < 0.15
        then
            if Fu.IsInRange(bot, tEnemyHeroes[1], 350)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bot.whip_to_retreat
    then
        if not Fu.IsRealInvisible(bot)
        or Fu.IsValidHero(tEnemyHeroes[1]) and botLevel < 15
        or nBotHP < 0.15
        then
            if Fu.IsInRange(bot, tEnemyHeroes[1], nInnerRadius)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bot.whip_to_push
    or bot.whip_to_defend
    or bot.whip_to_farm
    or bot.whip_to_miniboss
    then
        if nBotHP < 0.15
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderEscapeAct()
    if not Fu.CanCastAbility(EscapeAct)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, EscapeAct:GetCastRange())
    local nRadius = EscapeAct:GetSpecialValueFloat('leash_radius')
    local nDuration = EscapeAct:GetSpecialValueFloat('invis_duration')

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, ally in pairs(tAllyHeroes)
    do
        if Fu.IsValidHero(ally)
        and not Fu.IsRealInvisible(ally)
        and Fu.IsInRange(bot, ally, nCastRange + 300)
        and Fu.IsCore(ally)
        and not ally:IsIllusion()
        and not ally:HasModifier('modifier_necrolyte_reapers_scythe')
        and Fu.CanBeAttacked(ally)
        then
            if ally:HasModifier('modifier_legion_commander_duel')
            or ally:HasModifier('modifier_enigma_black_hole_pull')
            or ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                return BOT_ACTION_DESIRE_HIGH, ally
            end

            local nAllyInRangeAlly = ally:GetNearbyHeroes(900, false, BOT_MODE_NONE)
            local nAllyInRangeEnemy = ally:GetNearbyHeroes(900, true, BOT_MODE_NONE)

            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and (nAllyInRangeEnemy[1]:GetAttackTarget() == ally or Fu.IsChasingTarget(nAllyInRangeEnemy[1], ally))
            and #nAllyInRangeEnemy >= #nAllyInRangeAlly
            and not ally:HasModifier('modifier_teleporting')
            and not Fu.IsInEtherealForm(ally)
            and Fu.GetHP(ally) < 0.5
            then
                return BOT_ACTION_DESIRE_HIGH, ally
            end
        end
    end

    if Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget)
    then
        for _, ally in pairs(tAllyHeroes)
        do
            if Fu.IsValidHero(ally)
            and not ally:IsIllusion()
            then
                if (Fu.IsDoingRoshan(ally) or Fu.IsDoingTormentor(ally))
                and Fu.IsInRange(ally, botTarget, 900)
                then
                    if Fu.GetHP(ally) < 0.15
                    and not ally:HasModifier('modifier_teleporting')
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end

                if Fu.GetHP(ally) < 0.3
                and not Fu.IsInEtherealForm(ally)
                and Fu.CanBeAttacked(ally)
                and not ally:IsIllusion()
                and not ally:HasModifier('modifier_teleporting')
                and not ally:HasModifier('modifier_abaddon_borrowed_time')
                and not ally:HasModifier('modifier_dazzle_shallow_grave')
                and not ally:HasModifier('modifier_templar_assassin_refraction_absorb')
                and not ally:HasModifier('modifier_obsidian_destroyer_astral_imprisonment_prison')
                then
                    return BOT_ACTION_DESIRE_HIGH, ally
                end
            end
        end
    end

    if nBotHP < 0.25 and X.IsBeingAttacked(bot)
    and not Fu.IsRealInvisible(bot)
    then
        return BOT_ACTION_DESIRE_HIGH, bot
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderImpalementArts()
    if not Fu.CanCastAbility(ImpalementArts)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ImpalementArts:GetCastRange())
    local nRadius = ImpalementArts:GetSpecialValueInt('dagger_width')
    local nCastPoint = ImpalementArts:GetCastPoint()
    local nImpactDamage = ImpalementArts:GetSpecialValueInt('damage_impact')
    local nBleedPct = ImpalementArts:GetSpecialValueFloat('bleed_health_pct') / 100
    local nDuration = ImpalementArts:GetSpecialValueInt('bleed_duration')
    local nSpeed = ImpalementArts:GetSpecialValueInt('dagger_speed')
    local nAbilityLevel = ImpalementArts:GetLevel()

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, enemy in pairs(tEnemyHeroes)
    do
        if Fu.IsValidHero(enemy)
        and Fu.IsInRange(bot, enemy, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemy)
        and not enemy:HasModifier('modifier_ringmaster_impalement_bleed')
        then
            local eta = (GetUnitToUnitDistance(bot, enemy) / nSpeed) + nCastPoint
            local targetLoc = Fu.GetCorrectLoc(enemy, eta)

            if not X.IsUnitBetweenMeAndLocation(bot, enemy, targetLoc, nRadius)
            and not enemy:HasModifier('modifier_abaddon_borrowed_time')
            and not enemy:HasModifier('modifier_dazzle_shallow_grave')
            and not enemy:HasModifier('modifier_oracle_false_promise_timer')
            then
                if Fu.CanKillTarget(enemy, nImpactDamage, DAMAGE_TYPE_MAGICAL)
                or Fu.CanKillTarget(enemy, nImpactDamage + enemy:GetMaxHealth() * nBleedPct * nDuration, DAMAGE_TYPE_MAGICAL)
                then
                    return BOT_ACTION_DESIRE_HIGH, targetLoc
                end
            end
        end
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not botTarget:IsInvulnerable()
        and not botTarget:HasModifier('modifier_ringmaster_impalement_bleed')
        then
            local eta = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
            local targetLoc = Fu.GetCorrectLoc(botTarget, eta)
            local nLocationAoE = bot:FindAoELocation(true, true, targetLoc, nRadius, nRadius, 0, 0)
            if nLocationAoE.count > 1
            then
                targetLoc = nLocationAoE.targetloc
            end

            if not X.IsUnitBetweenMeAndLocation(bot, botTarget, targetLoc, nRadius)
            then
                return BOT_ACTION_DESIRE_HIGH, targetLoc
            end
        end
    end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemy in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, 800)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and bot:WasRecentlyDamagedByHero(enemy, 3.0)
            and (nBotHP < 0.5 or Fu.IsChasingTarget(enemy, bot))
            and not enemy:HasModifier('modifier_ringmaster_impalement_bleed')
            then
                local nLocationAoE = bot:FindAoELocation(true, true, enemy:GetLocation(), nRadius, nRadius, 0, 0)
                local targetLoc = enemy:GetLocation()
                if nLocationAoE.count > 1
                then
                    targetLoc = nLocationAoE.targetloc
                end

                if not X.IsUnitBetweenMeAndLocation(bot, enemy, targetLoc, nRadius)
                then
                    return BOT_ACTION_DESIRE_HIGH, targetLoc
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and botTarget:GetHealth() > (nImpactDamage + botTarget:GetMaxHealth() * nBleedPct * nDuration)
        and not botTarget:HasModifier('modifier_ringmaster_impalement_bleed')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if nAbilityLevel >= 3 and DotaTime() > 12 * 60
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemy in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemy)
            and not Fu.IsInRange(bot, enemy, 900)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not enemy:HasModifier('modifier_ringmaster_impalement_bleed')
            then
                local eta = (GetUnitToUnitDistance(bot, enemy) / nSpeed) + nCastPoint
                if not X.IsUnitBetweenMeAndLocation(bot, enemy, Fu.GetCorrectLoc(enemy, eta), nRadius)
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(enemy, eta)
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSpotlight()
    if not Fu.CanCastAbility(Spotlight)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Spotlight:GetCastRange())
    local nCastPoint = Spotlight:GetCastPoint()
    local nRadius = Spotlight:GetSpecialValueInt('radius')
    local nDuration = Spotlight:GetSpecialValueInt('duration')

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nLocationAoE = bot:FindAoELocation(false, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeAlly = Fu.GetAlliesNearLoc(nLocationAoE.targetloc, nRadius)
        if #nInRangeAlly >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    for _, ally in pairs(tAllyHeroes)
    do
        if Fu.IsValidHero(ally)
        and not Fu.IsRealInvisible(ally)
        and Fu.IsInRange(bot, ally, nCastRange + 300)
        and not ally:IsIllusion()
        and Fu.CanBeAttacked(ally)
        and not ally:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            if ally:HasModifier('modifier_legion_commander_duel')
            or ally:HasModifier('modifier_enigma_black_hole_pull')
            or ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                return BOT_ACTION_DESIRE_HIGH, ally:GetLocation()
            end

            local nAllyInRangeEnemy = ally:GetNearbyHeroes(1200, true, BOT_MODE_NONE)

            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not Fu.IsChasingTarget(nAllyInRangeEnemy[1], ally)
            and nAllyInRangeEnemy[1]:GetAttackTarget() == ally
            and not Fu.IsInEtherealForm(ally)
            then
                return BOT_ACTION_DESIRE_HIGH, ally:GetLocation()
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.GetHP(botTarget) > 0.5
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderWheelOfWonder()
    if not Fu.CanCastAbility(WheelOfWonder)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WheelOfWonder:GetCastRange())
    local nCastPoint = WheelOfWonder:GetCastPoint()
    local nRadius = WheelOfWonder:GetSpecialValueInt('mesmerize_radius')
    local nSpeed = WheelOfWonder:GetSpecialValueInt('projectile_speed')

    if Fu.IsInTeamFight(bot, 1600)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
        if #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- Souvenirs

function X.ConsiderFunhouseMirror()
    if not Fu.CanCastAbility(FunhouseMirror)
    or Fu.IsRealInvisible(bot)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsStunProjectileIncoming(bot, 350)
    or Fu.IsUnitTargetProjectileIncoming(bot, 350)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

	if not bot:HasModifier('modifier_sniper_assassinate')
	and not bot:IsMagicImmune()
    and Fu.IsWillBeCastUnitTargetSpell(bot, 300)
	then
        return BOT_ACTION_DESIRE_HIGH
	end

    if bGoingOnSomeone
    then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 300)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if (Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot))
    then
        if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(bot))
        and Fu.IsInRange(bot, botTarget, 900)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderStrongmanTonic()
    if not Fu.CanCastAbility(StrongmanTonic)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, StrongmanTonic:GetCastRange())

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, ally in pairs(tAllyHeroes)
    do
        if Fu.IsValidHero(ally)
        and Fu.IsInRange(bot, ally, nCastRange + 300)
        and not ally:IsIllusion()
        and not ally:HasModifier('modifier_necrolyte_reapers_scythe')
        and Fu.CanBeAttacked(ally)
        then
            if ally:HasModifier('modifier_legion_commander_duel')
            or ally:HasModifier('modifier_enigma_black_hole_pull')
            or ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                return BOT_ACTION_DESIRE_HIGH, ally
            end

            local nAllyInRangeAlly = ally:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
            local nAllyInRangeEnemy = ally:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.IsRetreating(ally)
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], ally)
            then
                return BOT_ACTION_DESIRE_HIGH, ally
            end
        end
    end

    if Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget)
    then
        for _, ally in pairs(tAllyHeroes)
        do
            if Fu.IsValidHero(ally)
            and Fu.IsInRange(bot, ally, nCastRange)
            and not ally:IsIllusion()
            then
                if (Fu.IsDoingRoshan(ally) or Fu.IsDoingTormentor(ally))
                and Fu.IsInRange(ally, botTarget, 900)
                then
                    if Fu.GetHP(ally) < 0.15
                    then
                        return BOT_ACTION_DESIRE_HIGH, ally
                    end
                end

                if Fu.GetHP(ally) < 0.3
                and not Fu.IsInEtherealForm(ally)
                and Fu.CanBeAttacked(ally)
                and not ally:IsIllusion()
                and not ally:HasModifier('modifier_abaddon_borrowed_time')
                and not ally:HasModifier('modifier_dazzle_shallow_grave')
                and not ally:HasModifier('modifier_templar_assassin_refraction_absorb')
                and not ally:HasModifier('modifier_obsidian_destroyer_astral_imprisonment_prison')
                then
                    return BOT_ACTION_DESIRE_HIGH, ally
                end
            end
        end
    end

    if nBotHP < 0.5 and X.IsBeingAttacked(bot)
    and not Fu.IsRealInvisible(bot)
    then
        return BOT_ACTION_DESIRE_HIGH, bot
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderWhoopeeCushion()
    if not Fu.CanCastAbility(WhoopeeCushion)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nLeapDistance = WhoopeeCushion:GetSpecialValueInt('leap_distance')
    local nFartRadius = WhoopeeCushion:GetSpecialValueInt('fart_cloud_radius')

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if bGoingOnSomeone
    then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nLeapDistance + nFartRadius)
        and not Fu.IsInRange(bot, botTarget, nLeapDistance)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and #tAllyHeroes >= #tEnemyHeroes
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        if Fu.IsValidHero(tEnemyHeroes[1])
        and not Fu.IsSuspiciousIllusion(tEnemyHeroes[1])
        then
            if #tEnemyHeroes > #tAllyHeroes + 1
            and bot:IsFacingLocation(Fu.GetTeamFountain(), 30)
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            if Fu.IsInRange(bot, tEnemyHeroes[1], nFartRadius)
            and Fu.IsChasingTarget(tEnemyHeroes[1], bot)
            and bot:IsFacingLocation(Fu.GetTeamFountain(), 45)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderCrystalBall()
    if not Fu.CanCastAbility(CrystalBall)
    then
        return BOT_ACTION_DESIRE_NONE
    end
	for i, id in pairs( GetTeamPlayers( GetOpposingTeam() ) )
	do
		if IsHeroAlive( id ) then
			local info = GetHeroLastSeenInfo( id )
			if info ~= nil then
				local dInfo = info[1]
				if dInfo ~= nil
					and Fu.GetLocationToLocationDistance( bot:GetLocation(), dInfo.location ) <= 100000
					and dInfo.time_since_seen > 3
				then
					return BOT_ACTION_DESIRE_HIGH, dInfo.location
				end
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderWeightedPie()
    if not Fu.CanCastAbility(WeightedPie)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WeightedPie:GetCastRange())
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if bGoingOnSomeone
    then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange / 3)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not botTarget:IsInvulnerable()
        and not botTarget:HasModifier('modifier_ringmaster_weightedpie_blind')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemy in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and (nBotHP < 0.5 or Fu.IsChasingTarget(enemy, bot))
            and not enemy:HasModifier('modifier_ringmaster_weightedpie_blind')
            then
                return BOT_ACTION_DESIRE_HIGH, enemy
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderUnicycle()
    if not Fu.CanCastAbility(Unicycle)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bGoingOnSomeone
    then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, 2200)
        and not Fu.IsInRange(bot, botTarget, 700)
        and (nBotHP > 0.7 or Fu.IsChasingTarget(bot, botTarget))
        and Fu.CanCastOnNonMagicImmune(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemy in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, 600)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and (nBotHP < 0.5 or Fu.IsChasingTarget(enemy, bot))
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end
    return BOT_ACTION_DESIRE_NONE
end

function X.IsBeingAttacked(unit)
    for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMIES))
    do
        if Fu.IsValid(unit)
        then
            local enemyName = enemy:GetUnitName()
            if Fu.IsValidHero(enemy)
            or Fu.IsValidBuilding(enemy)
            or string.find(enemyName, 'warlock_golem')
            then
                return true
            end
        end
    end

    return false
end

function X.IsUnitBetweenMeAndLocation(hSource, hTarget, vTargetLoc, nRadius)
	local vStart = hSource:GetLocation()
	local vEnd = vTargetLoc

	for _, unit in pairs(GetUnitList(UNIT_LIST_ENEMIES))
	do
		if unit ~= nil
		and unit:CanBeSeen()
		and GetUnitToUnitDistance(GetBot(), unit) <= 1600
		and not unit:IsBuilding()
		and not string.find(unit:GetUnitName(), 'ward')
		and hSource ~= unit
		and hTarget ~= unit
		then
			local tResult = PointToLineDistance(vStart, vEnd, unit:GetLocation())
			if tResult ~= nil and tResult.within and tResult.distance <= nRadius then return true end
		end
	end

	return false
end

return X
