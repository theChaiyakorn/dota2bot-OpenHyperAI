local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local R             = dofile( GetScriptDirectory()..'/FuncLib/hero/rubick' )
local SPL           = require( GetScriptDirectory()..'/FuncLib/data/spell_prob_list' )
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
						{2,1,2,3,2,6,2,3,3,3,1,6,1,1,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_bottle",
    "item_boots",
    "item_magic_wand",
    "item_dagon_2",
    "item_travel_boots",
    "item_cyclone",
    "item_ultimate_scepter",
    "item_octarine_core",--
    "item_dagon_5",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_shivas_guard",
    "item_travel_boots_2",--
    "item_wind_waker",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_magic_stick",

    "item_boots",
    "item_magic_wand",
    "item_arcane_boots",
	"item_glimmer_cape",--
	'item_pipe',--
    "item_aether_lens",
    "item_blink",
    "item_ancient_janggo",
    "item_aghanims_shard",
    "item_force_staff",--
    "item_ultimate_scepter",
    "item_octarine_core",--
    -- "item_cyclone",
    -- "item_wind_waker",--
    "item_arcane_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_magic_stick",

    "item_boots",
    "item_magic_wand",
    "item_arcane_boots",
	"item_glimmer_cape",--
    "item_aether_lens",
    "item_blink",
    "item_mekansm",
    "item_guardian_greaves",--
    "item_force_staff",--
    "item_aghanims_shard",
    "item_ultimate_scepter",
    "item_octarine_core",--
    "item_cyclone",
    -- "item_wind_waker",--
    "item_arcane_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}
sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",

    "item_boots",
    "item_magic_wand",
    "item_dagon_2",
    "item_travel_boots",
    "item_cyclone",
    "item_ultimate_scepter",
    "item_octarine_core",--
    "item_dagon_5",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_shivas_guard",
    "item_travel_boots_2",--
    "item_wind_waker",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_ring_of_protection",

    "item_helm_of_iron_will",
    "item_boots",
    "item_magic_wand",
    "item_phase_boots",
    "item_veil_of_discord",
    "item_glimmer_cape",--
    "item_ultimate_scepter",
    "item_blink",
    "item_shivas_guard",--
    "item_black_king_bar",--
    "item_travel_boots",
    "item_overwhelming_blink",--
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_moon_shard",
}


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

local Telekinesis       = SafeAbility(bot:GetAbilityByName('rubick_telekinesis'), 'rubick_telekinesis', 'rubick')
local TelekinesisLand   = SafeAbility(bot:GetAbilityByName('rubick_telekinesis_land'), 'rubick_telekinesis_land', 'rubick')
local FadeBolt          = SafeAbility(bot:GetAbilityByName('rubick_fade_bolt'), 'rubick_fade_bolt', 'rubick')
-- local ArcaneSupremacy   = bot:GetAbilityByName('rubick_null_field')
local StolenSpell1      = SafeAbility(bot:GetAbilityByName('rubick_empty1'), 'rubick_empty1', 'rubick')
local StolenSpell2      = SafeAbility(bot:GetAbilityByName('rubick_empty2'), 'rubick_empty2', 'rubick')
local SpellSteal        = SafeAbility(bot:GetAbilityByName('rubick_spell_steal'), 'rubick_spell_steal', 'rubick')

local TelekinesisDesire, TelekinesisTarget
local TelekinesisLandDesire, TelekinesisLandLocation
local FadeBoltDesire, FadeBoltTarget
local SpellStealDesire, SpellStealTarget

local botTarget
local lastTimeStealSpell = 0

if bot.shouldBlink == nil then bot.shouldBlink = false end

local bRetreating
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bRetreating = ctx.isRetreating

    -- if Rubick is in good health condition and is casting an ability with some enmey still nearby, don't consider any other spells.
    if Fu.GetHP(bot) > 0.3
    and not bRetreating
    and (bot:IsChanneling()
    or bot:IsUsingAbility()
    or bot:IsCastingAbility())
    then
        local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius + 300, true, BOT_MODE_NONE)
        if nEnemyHeroes ~= nil and #nEnemyHeroes > 0 then
            return
        end
    end

    botTarget = ctx.target
    StolenSpell1 = bot:GetAbilityInSlot(3)
    StolenSpell2 = bot:GetAbilityInSlot(4)

    -- consider using whatever it has first
    X.ConsiderStolenSpell1()
    X.ConsiderStolenSpell2()

    -- consdier stealing
    SpellStealDesire, SpellStealTarget = X.ConsiderSpellSteal()
    if SpellStealDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SpellSteal, SpellStealTarget)
        lastTimeStealSpell = DotaTime()
        return
    end

    TelekinesisDesire, TelekinesisTarget = X.ConsiderTelekinesis()
    if TelekinesisDesire > 0
    then
        bot.teleTarget = TelekinesisTarget
        bot:Action_UseAbilityOnEntity(Telekinesis, TelekinesisTarget)
        return
    end

    TelekinesisLandDesire, TelekinesisLandLocation = X.ConsiderTelekinesisLand()
    if TelekinesisLandDesire > 0
    then
        bot:Action_UseAbilityOnLocation(TelekinesisLand, TelekinesisLandLocation)
        bot.isChannelLand = false
        bot.isSaveUltLand= false
        bot.isEngagingLand = false
        bot.isRetreatLand = false
        bot.isSaveAllyLand = false
        return
    end

    FadeBoltDesire, FadeBoltTarget = X.ConsiderFadeBolt()
    if FadeBoltDesire > 0
    then
        bot:Action_UseAbilityOnEntity(FadeBolt, FadeBoltTarget)
        return
    end
end

function X.ConsiderTelekinesis()
    if Telekinesis:IsHidden()
    or not Telekinesis:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Telekinesis:GetCastRange())

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 300, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
		then
            if enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero)
            then
                bot.isChannelLand = true
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
		end
	end

    if Fu.IsGoingOnSomeone(bot)
	then
        local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
        for _, allyHero in pairs(nInRangeAlly)
        do
            if Fu.IsValidHero(allyHero)
            and Fu.IsCore(allyHero)
            and not Fu.IsSuspiciousIllusion(allyHero)
            and not allyHero:IsInvulnerable()
            and not allyHero:IsAttackImmune()
            and not allyHero:HasModifier('modifier_furion_sprout_damage')
            and not allyHero:HasModifier('modifier_legion_commander_duel')
            and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                if allyHero:HasModifier('modifier_enigma_black_hole_pull')
                or allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                then
                    bot.isSaveUltLand = true
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange + 150)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_furion_sprout_damage')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            nInRangeAlly =  Fu.GetAlliesNearLoc(botTarget:GetLocation(), 1200)
            nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), 1200)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            and not (#nInRangeEnemy == 0 and #nInRangeAlly >= #nInRangeEnemy + 2)
            then
                bot.isEngagingLand = true
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
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_furion_sprout_damage')
			then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and (#nTargetInRangeAlly > #nInRangeAlly
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    bot.isRetreatLand = true
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
			end
		end
	end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
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
            and nAllyInRangeEnemy[1]:IsFacingLocation(allyHero:GetLocation(), 30)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_furion_sprout_damage')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                bot.isSaveAllyLand = true
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

	if Fu.IsDoingRoshan(bot)
	then
        -- Remove Spell Block
		if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
        and botTarget:HasModifier('modifier_roshan_spell_block')
		then
			return BOT_ACTION_DESIRE_LOW, botTarget
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTelekinesisLand()
    if TelekinesisLand:IsHidden()
    or not TelekinesisLand:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nDistance = TelekinesisLand:GetSpecialValueInt('radius')
    local nTalent8 = SafeAbility(bot:GetAbilityByName('special_bonus_unique_rubick_8'), 'special_bonus_unique_rubick_8', 'rubick')
    if nTalent8:IsTrained()
    then
        nDistance = nDistance + nTalent8:GetSpecialValueInt('value')
    end

    local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

    if Fu.IsValidHero(botTarget)
    and not Fu.IsSuspiciousIllusion(botTarget)
    then
        nInRangeAlly = Fu.GetAlliesNearLoc(botTarget:GetLocation(), 1200)
        nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), 1200)
    end

    if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
    and Fu.IsValid(bot.teleTarget)
    then
        if bot.isChannelLand ~= nil
        and bot.isChannelLand == true
        then
            if #nInRangeAlly >= #nInRangeEnemy
            then
                if Fu.IsInRange(bot, bot.teleTarget, nDistance)
                then
                    return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
                end

                if not Fu.IsInRange(bot, bot.teleTarget, nDistance)
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, bot:GetLocation(), nDistance)
                end
            end

            if #nInRangeEnemy > #nInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEnemyFountain(), nDistance)
            end
        end

        if bot.isSaveUltLand ~= nil
        and bot.isSaveUltLand == true
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nDistance)
        end

        if bot.isEngagingLand ~= nil
        and bot.isEngagingLand == true
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end

        if bot.isRetreatLand ~= nil
        and bot.isRetreatLand == true
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEnemyFountain(), nDistance)
        end

        if bot.isSaveAllyLand ~= nil
        and bot.isSaveAllyLand == true
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nDistance)
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderFadeBolt()
    if not FadeBolt:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, FadeBolt:GetCastRange())
    local nDamage = FadeBolt:GetSpecialValueInt('damage')
    local nRadius = FadeBolt:GetSpecialValueInt('radius')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_rubick_telekinesis')
        then
            if Fu.IsInEtherealForm(enemyHero)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1.5)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and Fu.IsAttacking(nAllyInRangeEnemy[1])
            and nAllyInRangeEnemy[1]:IsFacingLocation(allyHero:GetLocation(), 30)
            and not Fu.IsChasingTarget(nAllyInRangeEnemy[1], bot)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_rubick_telekinesis')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
            end
        end
    end

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)
        local target = nil
        local hp = 100000

        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_rubick_telekinesis')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                local nTargetInRangeAlly = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nRadius)
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

    if Fu.IsGoingOnSomeone(bot)
    then
        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_rubick_telekinesis')
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
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and Fu.IsAttacking(enemyHero)
            and not Fu.IsInRange(bot, enemyHero, 300)
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

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1200, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH, nEnemyLaneCreeps[1]
        end
    end

    if Fu.IsLaning(bot)
    and not Fu.IsThereNonSelfCoreNearby(800)
	then
        local creepList = {}
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and creep:GetHealth() <= nDamage
            and Fu.GetMP(bot) > 0.3
			then
				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) < 500
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                table.insert(creepList, creep)
            end
		end

        if Fu.GetMP(bot) > 0.3
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
        and not botTarget:HasModifier('modifier_roshan_spell_block')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderStolenSpell1()
    if StolenSpell1:GetName() == 'rubick_empty1'
    or not StolenSpell1:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_HIGH, 0, ''
    end

    R.ConsiderStolenSpell(StolenSpell1)

    return BOT_ACTION_DESIRE_HIGH, 0, ''
end

function X.ConsiderStolenSpell2()
    if StolenSpell2:GetName() == 'rubick_empty2'
    or not StolenSpell2:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_HIGH, 0, ''
    end

    R.ConsiderStolenSpell(StolenSpell2)

    return BOT_ACTION_DESIRE_HIGH, 0, ''
end

function X.ConsiderSpellSteal()
    if not SpellSteal:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end
    if DotaTime() - lastTimeStealSpell < 60 then
        -- or low cd high dmg spells
        if StolenSpell1:IsFullyCastable() and StolenSpell1:IsUltimate() and not bot:HasScepter() then
            return BOT_ACTION_DESIRE_NONE, nil
        end
        if StolenSpell2:IsFullyCastable() and StolenSpell2:IsUltimate() then
            return BOT_ACTION_DESIRE_NONE, nil
        end
    end
    if StolenSpell1:GetCooldownTimeRemaining() < 5 and StolenSpell1:GetAbilityDamage() >= 280 then
        return BOT_ACTION_DESIRE_NONE, nil
    end
    if StolenSpell2:GetCooldownTimeRemaining() < 5 and StolenSpell2:GetAbilityDamage() >= 280 then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SpellSteal:GetCastRange())

    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange + 300)
    for _, enemyHero in pairs(nInRangeEnemy)
    do
        -- log("Rubick considering spell steal on an enemy...")
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not Fu.IsMeepoClone(enemyHero)
        then
            -- log("Rubick considering spell steal on a valid target enemy...")
            if enemyHero:IsUsingAbility()
            or enemyHero:IsCastingAbility()
            or Fu.IsCastingUltimateAbility(enemyHero)
            or enemyHero:GetLevel() > 10
            then
                -- log("Rubick considering spell steal on a valid target enemy that casted an ability...")
                local ss1Weight = SPL.GetSpellReplaceWeight(StolenSpell1) * 100
                local ranInt = RandomInt(1, 70)
                -- log("Rubick considering spell steal on a valid target enemy that casted an ability: weight="..ss1Weight..", random int="..ranInt)

                if bot:HasScepter()
                then
                    local ss2Weight = SPL.GetSpellReplaceWeight(StolenSpell2) * 100

                    if ss1Weight * 100 >= ranInt
                    and ss2Weight * 100 >= RandomInt(1, 70)
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end

                    if ss2Weight * 100 >= ranInt
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end
                else
                    if ss1Weight * 100 >= ranInt
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X