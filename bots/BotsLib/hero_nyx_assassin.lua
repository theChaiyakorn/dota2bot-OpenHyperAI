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
                        ['t20'] = {10, 0},
                        ['t15'] = {10, 0},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,2,2,2,6,3,3,3,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",

    "item_magic_wand",
    "item_tranquil_boots",
    "item_dagon_2",
    "item_aghanims_shard",
    "item_guardian_greaves",--
    "item_blink",
    "item_force_staff",--
    "item_boots_of_bearing",--
    "item_octarine_core",--
    "item_ultimate_scepter",
    "item_dagon_5",--
    "item_swift_blink",--
    "item_ultimate_scepter_2",
    "item_wind_waker",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",

    "item_magic_wand",
    "item_arcane_boots",
    "item_dagon_2",
    "item_pipe",
    "item_aghanims_shard",
    "item_blink",
    "item_force_staff",--
    "item_octarine_core",--
    "item_ultimate_scepter",
    "item_dagon_5",--
    "item_swift_blink",--
    "item_ultimate_scepter_2",
    "item_wind_waker",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_3'] = {
    "item_double_tango",
    "item_double_branches",

    "item_magic_wand",
    "item_tranquil_boots",
    "item_dagon_2",
    "item_aghanims_shard",
    "item_blink",
    "item_force_staff",--
    "item_boots_of_bearing",--
    "item_octarine_core",--
    "item_ultimate_scepter",
    "item_dagon_5",--
    "item_swift_blink",--
    "item_ultimate_scepter_2",
    "item_wind_waker",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

Pos4SellList = {
	"item_magic_wand",
}

Pos5SellList = {
    "item_magic_wand",
}

X['sSellList'] = {}

if sRole == "pos_4"
then
    X['sSellList'] = Pos4SellList
else
    X['sSellList'] = Pos5SellList
end

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local Impale            = SafeAbility(bot:GetAbilityByName('nyx_assassin_impale'), 'nyx_assassin_impale', 'nyx_assassin')
local Mindflare         = SafeAbility(bot:GetAbilityByName('nyx_assassin_jolt'), 'nyx_assassin_jolt', 'nyx_assassin')
local SpikedCarapace    = SafeAbility(bot:GetAbilityByName('nyx_assassin_spiked_carapace'), 'nyx_assassin_spiked_carapace', 'nyx_assassin')
local Burrow            = SafeAbility(bot:GetAbilityByName('nyx_assassin_burrow'), 'nyx_assassin_burrow', 'nyx_assassin')
local UnBurrow          = SafeAbility(bot:GetAbilityByName('nyx_assassin_unburrow'), 'nyx_assassin_unburrow', 'nyx_assassin')
local Vendetta          = SafeAbility(bot:GetAbilityByName('nyx_assassin_vendetta'), 'nyx_assassin_vendetta', 'nyx_assassin')

local ImpaleDesire, ImpaleLocation
local MindflareDesire, MindflareTarget
local SpikedCarapaceDesire
local BurrowDesire
local UnBurrowDesire
local VendettaDesire

if bot.canVendettaKill == nil then bot.canVendettaKill = false end
if bot.vendettaTarget == nil then bot.vendettaTarget = nil end

local botTarget
local bGoingOnSomeone
local nBotMP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	nBotMP = ctx.mp

    VendettaDesire = X.ConsiderVendetta()
    if VendettaDesire > 0
    then
        bot:Action_UseAbility(Vendetta)
        return
    end

    SpikedCarapaceDesire = X.ConsiderSpikedCarapace()
    if SpikedCarapaceDesire > 0
    then
        bot:Action_UseAbility(SpikedCarapace)
        return
    end

    ImpaleDesire, ImpaleLocation = X.ConsiderImpale()
    if ImpaleDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Impale, ImpaleLocation)
        return
    end

    MindflareDesire, MindflareTarget = X.ConsiderMindflare()
    if MindflareDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Mindflare, MindflareTarget)
        return
    end

    BurrowDesire = X.ConsiderBurrow()
    if BurrowDesire > 0
    then
        bot:Action_UseAbility(Burrow)
        return
    end

    UnBurrowDesire = X.ConsiderUnBurrow()
    if UnBurrowDesire > 0
    then
        bot:Action_UseAbility(UnBurrow)
        return
    end
end

function X.ConsiderImpale()
    if not Impale:IsFullyCastable()
    or bot:HasModifier('modifier_nyx_assassin_vendetta')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Impale:GetCastRange())
    local nCastPoint = Impale:GetCastPoint()
    local nStunDuration = Impale:GetSpecialValueInt('duration')
    local nDamage = Impale:GetSpecialValueInt('impale_damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
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
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2.1)
        and not allyHero:IsIllusion()
        and nBotMP > 0.31
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(allyHero, nAllyInRangeEnemy[1], 400)
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
            and Fu.IsRunning(allyHero)
            and nAllyInRangeEnemy[1]:IsFacingLocation(allyHero:GetLocation(), 30)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    if bGoingOnSomeone
	then
        local strongestTarget = Fu.GetStrongestUnit(nCastRange, bot, true, false, nStunDuration)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)

        if strongestTarget == nil
        then
            strongestTarget = Fu.GetStrongestUnit(nCastRange, bot, true, true, nStunDuration)
        end

		if Fu.IsValidTarget(strongestTarget)
        and Fu.IsInRange(bot, strongestTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(strongestTarget)
        and not Fu.IsDisabled(strongestTarget)
        and not Fu.IsTaunted(strongestTarget)
        and not strongestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not strongestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not strongestTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not strongestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not strongestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not strongestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(strongestTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, strongestTarget:GetExtrapolatedLocation(nCastPoint)
            end
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
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 800, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (Fu.GetHP(bot) < 0.82 and bot:WasRecentlyDamagedByAnyHero(1.5)))
            then
                return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetExtrapolatedLocation(nCastPoint)
            end
        end
    end

    if Fu.IsLaning(bot)
    and not Fu.IsThereNonSelfCoreNearby(1200)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
            --     and nBotMP > 0.41
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
			-- 	end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                canKill = canKill + 1
                table.insert(creepList, creep)
            end
		end

        if canKill >= 2
        and nBotMP > 0.25
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.IsAttacking(bot)
        and not Fu.IsDisabled(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderMindflare()
    if not Mindflare:IsFullyCastable()
    or bot:HasModifier('modifier_nyx_assassin_vendetta')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Mindflare:GetCastRange())
	local nDmgPct = Mindflare:GetSpecialValueInt('max_mana_as_damage_pct')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, enemyHero:GetMaxMana() * (nDmgPct / 100), DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    if bGoingOnSomeone
	then
        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, nCastRange)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        and not weakestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not weakestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not weakestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not weakestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, weakestTarget
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSpikedCarapace()
    if not SpikedCarapace:IsFullyCastable()
    or bot:HasModifier('modifier_nyx_assassin_vendetta')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsUnitTargetProjectileIncoming(bot, 400)
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if not bot:HasModifier('modifier_sniper_assassinate')
	and not bot:IsMagicImmune()
	then
		if Fu.IsWillBeCastUnitTargetSpell(bot, 1400)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderBurrow()
    if bot:HasModifier('modifier_nyx_assassin_burrow') or not Fu.CanBeCast(Burrow)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCarapaceRadius = Burrow:GetSpecialValueInt('carapace_radius')

    if Fu.IsInTeamFight(bot, 1200)
    then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCarapaceRadius)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderUnBurrow()
    if not bot:HasModifier('modifier_nyx_assassin_burrow') or not Fu.CanBeCast(UnBurrow)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE)
    if #nEnemyHeroes < 1
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderVendetta()
    if not Vendetta:IsFullyCastable()
    or bot:HasModifier('modifier_nyx_assassin_burrow')
    or Fu.IsRealInvisible(bot)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nDamage = Vendetta:GetSpecialValueInt('bonus_damage')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PURE)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                bot.canVendettaKill = true
                bot.vendettaTarget = enemyHero
                return BOT_ACTION_DESIRE_HIGH
            else
                bot.canVendettaKill = false
                bot.vendettaTarget = nil
            end
        end
    end

    if Fu.IsRetreating(bot)
    and not Fu.IsRealInvisible(bot)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 2200)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1600, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

return X