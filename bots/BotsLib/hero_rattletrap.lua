local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        {--pos4
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos5
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {10, 0},
                            ['t10'] = {0, 10},
                        }
}

local tAllAbilityBuildList = {
                        {1,2,1,3,1,6,1,2,2,2,6,3,3,3,6},--pos4
                        {1,2,1,3,1,6,1,3,3,3,6,2,2,2,6},--pos5
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_4"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sGlimmerSolarCrest = RandomInt(1, 2) == 2 and "item_glimmer_cape" or "item_solar_crest"
local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_wind_lace",

    "item_boots",
    "item_magic_wand",
    "item_arcane_boots",
    "item_urn_of_shadows", -- Alternative: item_essence_distiller (if not going spirit_vessel)
    "item_force_staff",--
    "item_spirit_vessel",--
    sGlimmerSolarCrest,--
    "item_aghanims_shard",
    "item_guardian_greaves",-- 
    "item_shivas_guard",--
    "item_heavens_halberd",--
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",
    "item_wind_lace",

    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
    "item_urn_of_shadows", -- Alternative: item_essence_distiller (if not going spirit_vessel)
	"item_pipe",
    "item_force_staff",--
    "item_spirit_vessel",--
    sGlimmerSolarCrest,--
    "item_aghanims_shard",
    "item_boots_of_bearing",-- 
    "item_shivas_guard",--
    -- "item_heavens_halberd",--
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_4']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_4']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_4']

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

local BatteryAssault    = bot:GetAbilityByName('rattletrap_battery_assault')
local PowerCogs         = bot:GetAbilityByName('rattletrap_power_cogs')
local RocketFlare       = bot:GetAbilityByName('rattletrap_rocket_flare')
local Jetpack           = bot:GetAbilityByName('rattletrap_jetpack')
local Overclocking      = bot:GetAbilityByName('rattletrap_overclocking')
local Hookshot          = bot:GetAbilityByName('rattletrap_hookshot')

local BatteryAssaultDesire
local PowerCogsDesire
local RocketFlareDesire, RocketFlareLocation
local JetpackDesire
local OverclockingDesire
local HookshotDesire, HookshotTarget

local cogsTime = -1
local ScoutRoshanTime = -1

local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)

    botTarget = ctx.target

    OverclockingDesire = X.ConsiderOverclocking()
    if OverclockingDesire > 0
    then
        bot:Action_UseAbility(Overclocking)
        return
    end

    HookshotDesire, HookshotTarget = X.ConsiderHookshot()
    if HookshotDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Hookshot, HookshotTarget)
        return
    end

    PowerCogsDesire = X.ConsiderPowerCogs()
    if PowerCogsDesire > 0
    then
        bot:Action_UseAbility(PowerCogs)
        cogsTime = DotaTime()
        return
    end

    BatteryAssaultDesire = X.ConsiderBatteryAssault()
    if BatteryAssaultDesire > 0
    then
        bot:Action_UseAbility(BatteryAssault)
        return
    end

    RocketFlareDesire, RocketFlareLocation = X.ConsiderRocketFlare()
    if RocketFlareDesire > 0
    then
        bot:Action_UseAbilityOnLocation(RocketFlare, RocketFlareLocation)
        return
    end

    JetpackDesire = X.ConsiderJetpack()
    if JetpackDesire > 0
    then
        bot:Action_UseAbility(Jetpack)
        return
    end
end

function X.ConsiderBatteryAssault()
    if not Fu.CanCastAbility(BatteryAssault)
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRadius    = BatteryAssault:GetSpecialValueInt('radius')

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,nRadius, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)

        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and Fu.IsCore(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1.5)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nRadius)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = botTarget:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = botTarget:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if bRetreating
    and bot:GetActiveModeDesire() > 0.5
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nRadius)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1.5))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        if nEnemyCreeps ~= nil and #nEnemyCreeps >= 3
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderPowerCogs()
    if not Fu.CanCastAbility(PowerCogs)
    then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = PowerCogs:GetSpecialValueInt('cogs_radius')
	local nDuration = PowerCogs:GetSpecialValueFloat('duration')

	if DotaTime() < cogsTime + nDuration
    then
		return BOT_ACTION_DESIRE_NONE
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius - 25)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = botTarget:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = botTarget:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if bRetreating
    and bot:GetActiveModeDesire() > 0.5
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and Fu.IsInRange(bot, enemyHero, nRadius + 200)
            and not Fu.IsInRange(bot, enemyHero, nRadius)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderRocketFlare()
    if not Fu.CanCastAbility(RocketFlare)
    then
        return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastPoint = RocketFlare:GetCastPoint()
	local nRadius = RocketFlare:GetSpecialValueInt('radius')
    local nDamage = RocketFlare:GetSpecialValueInt('damage')
	local nCastRange = 1600
    local RoshanLocation = Fu.GetCurrentRoshanLocation()
    local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidTarget(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
        end
    end

    if nTeamFightLocation ~= nil
    then
        if GetUnitToLocationDistance(bot, nTeamFightLocation) > bot:GetCurrentVisionRange()
        then
            return BOT_ACTION_DESIRE_HIGH, nTeamFightLocation
        end
    end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetCurrentVisionRange())
        and Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = botTarget:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = botTarget:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)
                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                else
                    return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
                end
            end
		end
	end

    if bRetreating
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nRadius)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                end
            end
        end
	end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nEnemyLanecreeps = bot:GetNearbyLaneCreeps(nCastRange, true);

		if nLocationAoE.count >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end

		nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)
		if nLocationAoE.count >= 4 and #nEnemyLanecreeps >= 4
		then
			return BOT_ACTION_DESIRE_MODERATE, Fu.GetCenterOfUnits(nEnemyLanecreeps)
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end

        if GetUnitToLocationDistance(bot, RoshanLocation) > 1600
        and DotaTime() > ScoutRoshanTime + 15
        and Fu.GetManaAfter(RocketFlare:GetManaCost()) * bot:GetMana() > Hookshot:GetManaCost()
        then
            ScoutRoshanTime = DotaTime()
            return BOT_ACTION_DESIRE_HIGH, RoshanLocation
        end
    end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
		then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderHookshot()
    if not Fu.CanCastAbility(Hookshot)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastPoint = Hookshot:GetCastPoint()
	local nCastRange = Fu.GetProperCastRange(false, bot, Hookshot:GetCastRange())
	local nRadius = Hookshot:GetSpecialValueInt('stun_radius')
	local nSpeed = Hookshot:GetSpecialValueInt('speed')

	if bGoingOnSomeone
	then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidTarget(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and GetUnitToLocationDistance(enemyHero, Fu.GetEnemyFountain()) > 1000
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
                local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
                local targetLoc = Fu.GetCorrectLoc(enemyHero, eta)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                and not Fu.IsUnitBetweenMeAndLocation(bot, enemyHero, targetLoc, nRadius)
                and not Fu.IsLocationInChrono(targetLoc)
                and not Fu.IsLocationInArena(targetLoc, 800)
                then
                    if #nInRangeAlly == 0 and #nTargetInRangeAlly == 0
                    then
                        if bot:GetEstimatedDamageToTarget(true, enemyHero, 5, DAMAGE_TYPE_ALL) > enemyHero:GetHealth()
                        and Fu.CanCastAbility(PowerCogs)
                        and Fu.CanCastAbility(BatteryAssault)
                        then
                            bot:SetTarget(enemyHero)
                            return BOT_ACTION_DESIRE_HIGH, targetLoc
                        end
                    else
                        if #nInRangeAlly >= 1
                        then
                            bot:SetTarget(enemyHero)
                            return BOT_ACTION_DESIRE_HIGH, targetLoc
                        end
                    end
                end
            end
        end
	end

    if bRetreating
    and bot:GetActiveModeDesire() > 0.75
	then
        local nAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    for _, allyHero in pairs(nAllyHeroes)
                    do
                        if Fu.IsValidHero(allyHero)
                        and bot:DistanceFromFountain() > 1600
                        and allyHero:DistanceFromFountain() > 1600
                        and bot:DistanceFromFountain() > allyHero:DistanceFromFountain()
                        and GetUnitToUnitDistance(bot, allyHero) > 1200
                        and not Fu.IsNotSelf(bot, allyHero)
                        then
                            local eta = (GetUnitToUnitDistance(bot, allyHero) / nSpeed) + nCastPoint
                            local targetLoc = Fu.GetCorrectLoc(allyHero, eta)

                            if not Fu.IsUnitBetweenMeAndLocation(bot, allyHero, targetLoc, nRadius)
                            and not Fu.IsLocationInChrono(targetLoc)
                            and not Fu.IsLocationInArena(targetLoc, 800)
                            then
                                return BOT_ACTION_DESIRE_HIGH, targetLoc
                            end
                        end
                    end
                end
            end
        end

        local nNeutralCamps = GetNeutralSpawners()
		local escapeLoc = Fu.GetEscapeLoc()
		local targetLoc = GetUnitToLocationDistance(bot, escapeLoc)

		for _, camp in pairs(nNeutralCamps)
        do
			local campDist = Fu.GetDistance(camp.location, escapeLoc)

			if campDist < targetLoc
			and GetUnitToLocationDistance(bot, camp.location) > 700
			then
				if not Fu.IsUnitBetweenMeAndLocation(bot, bot, camp.location, nRadius)
                and not Fu.IsLocationInChrono(camp.location)
                and not Fu.IsLocationInArena(camp.location, 800)
				then
					return BOT_ACTION_DESIRE_HIGH, camp.location
				end
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderJetpack()
    if not Fu.CanCastAbility(Jetpack)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bRetreating
    and bot:GetActiveModeDesire() > 0.5
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, 800)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2.5))
                then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderOverclocking()
    if not Fu.CanCastAbility(Overclocking)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X