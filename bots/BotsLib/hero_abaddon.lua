local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {10, 0},
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,6,2,1,1,1,6,3,3,3,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

local sUtility = {"item_lotus_orb", "item_crimson_guard", "item_heavens_halberd"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_orb_of_frost",
    "item_circlet",

    "item_wraith_band",
    "item_magic_wand",
    "item_orb_of_corrosion",
    "item_phase_boots",
    "item_echo_sabre",
    "item_manta",--
    "item_harpoon",--
    "item_black_king_bar",--
    "item_skadi",--
    "item_aghanims_shard",
    "item_bloodthorn",--
    "item_travel_boots_2",--
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_orb_of_frost",
    "item_circlet",

    "item_bottle",
    "item_magic_wand",
    "item_wraith_band",
    "item_orb_of_corrosion",
    "item_phase_boots",
    "item_echo_sabre",
    "item_manta",--
    "item_assault",--
    "item_harpoon",--
    "item_aghanims_shard",
    "item_basher",
    "item_heart",--
    "item_ultimate_scepter",
    "item_travel_boots",
    "item_abyssal_blade",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}
sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_gloves",
    "item_magic_wand",
    "item_orb_of_corrosion",
    "item_phase_boots",
    "item_radiance",--
    "item_consecrated_wraps",--
    "item_crimson_guard",--
    "item_assault",--
    nUtility,--
    "item_ultimate_scepter",
    "item_travel_boots",
    "item_heart",--
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_4'] = {
	"item_tank_outfit",
	"item_echo_sabre",
	"item_aghanims_shard",
	"item_consecrated_wraps",--
	"item_crimson_guard",
	"item_ultimate_scepter",
	"item_heavens_halberd",
	"item_assault",
	"item_travel_boots",
	"item_moon_shard",
	"item_sheepstick",
	"item_ultimate_scepter_2",
	"item_octarine_core",
	"item_travel_boots_2",
}

sRoleItemsBuyList['pos_5'] = {
	'item_mage_outfit',
	"item_ancient_janggo",
	"item_glimmer_cape",--
	"item_boots_of_bearing",--
	"item_pipe",--
	"item_aghanims_shard",
	"item_cyclone",
    "item_shivas_guard",--
	"item_sheepstick",--
    "item_heart",--
	"item_octarine_core",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}


X['sBuyList'] = sRoleItemsBuyList[sRole]


X['sSellList'] = {
	"item_ultimate_scepter",
	"item_magic_wand",

	"item_assault",
	"item_magic_wand",

    "item_heart",
    "item_orb_of_corrosion",

	"item_assault",
    "item_bottle",

	"item_assault",
	"item_ancient_janggo",
}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local MistCoil          = SafeAbility(bot:GetAbilityByName('abaddon_death_coil'), 'abaddon_death_coil', 'abaddon')
local AphoticShield     = SafeAbility(bot:GetAbilityByName('abaddon_aphotic_shield'), 'abaddon_aphotic_shield', 'abaddon')
-- local CurseOfAvernus    = bot:GetAbilityByName( 'abaddon_frostmourne' )
-- local BorrowedTimelocal = bot:GetAbilityByName( 'abaddon_borrowed_time' )

local MistCoilDesire, MistCoilTarget
local AphoticShieldDesire, AphoticShieldTarget

local botTarget
local bAttacking
local nBotHP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = ctx.hp

    AphoticShieldDesire, AphoticShieldTarget = X.ConsiderAphoticShield()
    if AphoticShieldDesire > 0
    then
        bot:Action_UseAbilityOnEntity(AphoticShield, AphoticShieldTarget)
        return
    end

    MistCoilDesire, MistCoilTarget = X.ConsiderMistCoil()
    if MistCoilDesire > 0 and MistCoilTarget
    then
        bot:Action_UseAbilityOnEntity(MistCoil, MistCoilTarget)
        return
    end
end

function X.ConsiderMistCoil()
    if not MistCoil:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = MistCoil:GetCastRange()
	local nDamage = MistCoil:GetSpecialValueInt('target_damage')
	local nSelfDamage = MistCoil:GetSpecialValueInt('self_damage')
    local nDamageType = DAMAGE_TYPE_MAGICAL
    botTarget = Fu.GetProperTarget(bot)
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

    if Fu.HasAghanimsShard(bot)
    then
        nDamage = bot:GetAttackDamage()
        nDamageType = DAMAGE_TYPE_PURE
    end

    if Fu.IsGoingOnSomeone(bot) then
        if Fu.IsValidHero(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget) then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
	for _, allyHero in pairs(nAllyHeroes)
	do
        if Fu.IsValidHero(allyHero)
        and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        and (allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            or allyHero:HasModifier('modifier_enigma_black_hole_pull'))
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

		if Fu.IsValidHero(allyHero)
		and Fu.IsInRange(bot, allyHero, nCastRange)
		and not allyHero:HasModifier('modifier_legion_commander_press_the_attack')
		and not allyHero:IsMagicImmune()
		and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
		and allyHero:CanBeSeen()
		then
			if Fu.IsRetreating(allyHero)
            and Fu.GetHP(allyHero) < 0.6
			then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end

			if Fu.IsGoingOnSomeone(allyHero)
			then
                local allyTarget = allyHero:GetAttackTarget()

				if Fu.IsValidHero(allyTarget)
				and allyHero:IsFacingLocation(allyTarget:GetLocation(), 30)
				and Fu.IsInRange(allyHero, allyTarget, 300)
                and Fu.GetHP(allyHero) < 0.8
                and nBotHP > 0.2
				then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end
		end
	end

    if not Fu.IsRetreating(bot)
    and nEnemyHeroes ~= nil
    and Fu.IsValidHero(nEnemyHeroes[1])
    and Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange)
    and Fu.GetMP(bot) > 0.25
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange + 200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and ((#nInRangeAlly == 0 and #nInRangeEnemy >= 1)
            or (#nInRangeAlly >= 1
                and nBotHP < 0.25
                and bot:WasRecentlyDamagedByAnyHero(1)
                and not bot:HasModifier('modifier_abaddon_borrowed_time')))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, nDamageType)
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAphoticShield()
    if not AphoticShield:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange  = AphoticShield:GetCastRange()
    botTarget = Fu.GetProperTarget(bot)

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
	do
        if Fu.IsValidHero(allyHero)
        and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        and (allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            or allyHero:HasModifier('modifier_enigma_black_hole_pull')
            or allyHero:HasModifier('modifier_legion_commander_duel'))
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

        if Fu.IsValidHero(allyHero)
        and Fu.IsDisabled(allyHero)
        and not allyHero:IsMagicImmune()
		and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

		if Fu.IsValidHero(allyHero)
        and not allyHero:HasModifier('modifier_abaddon_aphotic_shield')
        and not allyHero:HasModifier('modifier_item_solar_crest_armor_addition')
		and not allyHero:IsMagicImmune()
		and not allyHero:IsInvulnerable()
        and not allyHero:IsIllusion()
        and Fu.IsNotSelf(bot, allyHero)
		then
            local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 800, true, BOT_MODE_NONE)

            if Fu.IsRetreating(allyHero)
            and allyHero:WasRecentlyDamagedByAnyHero(1.6)
            and not allyHero:IsIllusion()
            then
                if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
                and Fu.IsValidHero(nAllyInRangeEnemy[1])
                and Fu.IsInRange(allyHero, nAllyInRangeEnemy[1], 400)
                and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
                and Fu.IsRunning(allyHero)
                and nAllyInRangeEnemy[1]:IsFacingLocation(allyHero:GetLocation(), 30)
                and not Fu.IsDisabled(nAllyInRangeEnemy[1])
                and not Fu.IsTaunted(nAllyInRangeEnemy[1])
                and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
                and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
                and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
                and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end

			if Fu.IsGoingOnSomeone(allyHero)
			then
				local allyTarget = allyHero:GetAttackTarget()

				if Fu.IsValidHero(allyTarget)
				and Fu.IsInRange(allyHero, allyTarget, allyHero:GetAttackRange())
                and not Fu.IsSuspiciousIllusion(allyTarget)
                and not allyTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not allyTarget:HasModifier('modifier_enigma_black_hole_pull')
                and not allyTarget:HasModifier('modifier_necrolyte_reapers_scythe')
				then
                    local nAllInRangeAlly = Fu.GetNearbyHeroes(allyHero, 800, false, BOT_MODE_NONE)
                    local nTargetInRangeAlly = Fu.GetNearbyHeroes(allyTarget, 800, false, BOT_MODE_NONE)

                    if nAllInRangeAlly ~= nil and  nTargetInRangeAlly ~= nil
                    and #nAllInRangeAlly >= #nTargetInRangeAlly
                    then
                        return BOT_ACTION_DESIRE_HIGH, allyHero
                    end
				end
			end
		end
	end

	if Fu.IsGoingOnSomeone(bot)
    then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                if Fu.IsValidHero(nInRangeAlly[1])
                and Fu.IsInRange(bot, nInRangeAlly[1], nCastRange)
                and Fu.IsCore(nInRangeAlly[1])
                and not nInRangeAlly[1]:HasModifier('modifier_abaddon_aphotic_shield')
                and not nInRangeAlly[1]:IsMagicImmune()
                and not nInRangeAlly[1]:IsInvulnerable()
                and not nInRangeAlly[1]:IsIllusion()
                then
                    return BOT_ACTION_DESIRE_HIGH, nInRangeAlly[1]
                end

                if not bot:HasModifier('modifier_abaddon_aphotic_shield')
                and not bot:HasModifier("modifier_abaddon_borrowed_time")
                then
                    return BOT_ACTION_DESIRE_MODERATE, bot
                end
            end
	    end

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeAlly == 0 and #nInRangeEnemy >= 1
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 500)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not bot:HasModifier('modifier_abaddon_aphotic_shield')
        and not bot:HasModifier("modifier_abaddon_borrowed_time")
        then
            return BOT_ACTION_DESIRE_MODERATE, bot
        end
    end

    if Fu.IsRetreating(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
        and not nInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.55 and bot:WasRecentlyDamagedByAnyHero(2)))
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            local weakestAlly = Fu.GetAttackableWeakestUnit(bot, nCastRange, true, false)

            if weakestAlly ~= nil
            and not weakestAlly:HasModifier('modifier_abaddon_aphotic_shield')
            then
                return BOT_ACTION_DESIRE_HIGH, weakestAlly
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            local weakestAlly = Fu.GetAttackableWeakestUnit(bot, nCastRange, true, false)

            if weakestAlly ~= nil
            and not weakestAlly:HasModifier('modifier_abaddon_aphotic_shield')
            then
                return BOT_ACTION_DESIRE_HIGH, weakestAlly
            end
        end
    end

	return BOT_ACTION_DESIRE_NONE, nil
end

return X