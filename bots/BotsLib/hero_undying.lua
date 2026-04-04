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
                        ['t15'] = {10, 0},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,1,3,1,6,1,3,3,2,6,2,2,2,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sUtility = {"item_pipe", "item_lotus_orb"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_blood_grenade",
	"item_tank_outfit",
    "item_arcane_boots",
	"item_essence_distiller",--
	"item_crimson_guard",--
    "item_guardian_greaves",--
	"item_aghanims_shard",
	"item_heavens_halberd",--
	"item_lotus_orb",--
	"item_travel_boots",
	"item_assault",--
    "item_ultimate_scepter_2",
	-- "item_heart",--
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_pipe",
    "item_ultimate_scepter",
	"item_cyclone",
--	"item_wraith_pact",
    "item_lotus_orb",--
	"item_gungir",--
	"item_shivas_guard",
	"item_sheepstick",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {

	"item_bristleback_outfit",
	"item_aghanims_shard",
	"item_blade_mail",
	"item_heavens_halberd",
	"item_lotus_orb",
	"item_black_king_bar",
    "item_ultimate_scepter",
	"item_travel_boots",
	-- "item_abyssal_blade",
    "item_ultimate_scepter_2",
	"item_heart",
	"item_moon_shard",
	"item_travel_boots_2",

}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
    "item_hand_of_midas",
	"item_crimson_guard",--
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_lotus_orb",--
	"item_heavens_halberd",--
	"item_sheepstick",--
	"item_octarine_core",--
	"item_travel_boots",
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_power_treads",
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

local Decay         = bot:GetAbilityByName('undying_decay')
local SoulRip       = bot:GetAbilityByName('undying_soul_rip')
local Tombstone     = bot:GetAbilityByName('undying_tombstone')
local FleshGolem    = bot:GetAbilityByName('undying_flesh_golem')

local DecayDesire, DecayLocation
local SoulRipDesire, SoulRipTarget
local TombstoneDesire, TombstoneLocation
local FleshGolemDesire

local botTarget

local bAttacking
local nBotHP
local nBotMP
local bInTeamFight
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = ctx.hp
	nBotMP = ctx.mp
	bInTeamFight = ctx.isTeamFight

    botTarget = ctx.target

    FleshGolemDesire = X.ConsiderFleshGolem()
    if FleshGolemDesire > 0
    then
        bot:Action_UseAbility(FleshGolem)
        return
    end

    TombstoneDesire, TombstoneLocation = X.ConsiderTombstone()
    if TombstoneDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Tombstone, TombstoneLocation)
        return
    end

    DecayDesire, DecayLocation = X.ConsiderDecay()
    if DecayDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Decay, DecayLocation)
        return
    end

    SoulRipDesire, SoulRipTarget = X.ConsiderSoulRip()
    if SoulRipDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SoulRip, SoulRipTarget)
        return
    end
end

function X.ConsiderDecay()
    if not Decay:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, Decay:GetCastRange())
    local nRadius = Decay:GetSpecialValueInt('radius')
	local nDamage = Decay:GetSpecialValueInt('decay_damage')
    local nAbilityLevel = Decay:GetLevel()

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        then
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nRadius)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
            then
                if not Fu.IsInRange(bot, enemyHero, nCastRange)
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                else
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                end
            end

            if not Fu.IsInRange(bot, enemyHero, nCastRange)
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetLocation(), nCastRange)
            else
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    if bInTeamFight
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange + nRadius, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nLocationAoE.targetloc, nCastRange)
        end
    end

	if Fu.IsGoingOnSomeone(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange + nRadius, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                then
                    nInRangeEnemy = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), nRadius)

                    if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                    then
                        if not Fu.IsInRange(bot, enemyHero, nCastRange)
                        then
                            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
                        else
                            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
                        end
                    end

                    if not Fu.IsInRange(bot, enemyHero, nCastRange)
                    then
                        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetLocation(), nCastRange)
                    else
                        return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                    end
                end
            end
        end
	end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nAbilityLevel >= 3
        and nBotMP > 0.6
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
	end

    if Fu.IsLaning(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + nRadius, true)

        if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and bAttacking
        and nBotMP > 0.5
        and nAbilityLevel >= 3
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end

        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange + nRadius, nRadius, 0, 0)
        nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and Fu.IsInLaningPhase()
        and nAbilityLevel >= 2
        then
            if GetUnitToLocationDistance(bot, Fu.GetCenterOfUnits(nInRangeEnemy)) > nCastRange
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
            else
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nAbilityLevel >= 3
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nAbilityLevel >= 3
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSoulRip()
    if not SoulRip:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SoulRip:GetCastRange())
	local nRadius = SoulRip:GetSpecialValueInt('radius')
    local nDamage = SoulRip:GetSpecialValueInt('damage_per_unit')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        then
            local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)
            local nCreeps = bot:GetNearbyCreeps(nRadius, true)

            if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
            then
                nDamage = nDamage * #nInRangeEnemy
            end

            if nCreeps ~= nil and #nCreeps >= 1
            then
                nDamage = nDamage * #nCreeps
            end

            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

	if Fu.IsGoingOnSomeone(bot, 1200)
	then
		local targetAlly = nil
		local hp = 1000

		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
		for _, allyHero in pairs(nInRangeAlly)
		do
			if Fu.IsValidHero(allyHero)
            and not Fu.IsSuspiciousIllusion(allyHero)
			then
                local nAllyInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
                local nAllyInRangeCreeps = bot:GetNearbyCreeps(nRadius, true)
				local currHP = allyHero:GetHealth()

				if currHP < hp
                and Fu.GetHP(allyHero) < 0.75
                and (nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
                    or nAllyInRangeCreeps ~= nil and #nAllyInRangeCreeps >= 2)
				then
					hp = currHP
					targetAlly = allyHero
				end
			end
		end

		if targetAlly ~= nil
		then
			return BOT_ACTION_DESIRE_MODERATE, targetAlly
		end
	end

	if Fu.IsRetreating(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(1.5)
                    or nBotHP < 0.5)
                then
                    return BOT_ACTION_DESIRE_HIGH, bot
                end
            end
        end

        local nCreeps = bot:GetNearbyCreeps(nRadius, true)
        if nCreeps ~= nil and #nCreeps >= 4
        and nBotHP < 0.6
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

    if Fu.IsPushing(bot)
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nBotMP > 0.7
        and nBotHP < 0.6
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

    if Fu.IsLaning(bot)
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and bAttacking
        and nBotMP > 0.5
        and nBotHP < 0.6
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

    if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	then
        if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, nRadius)
        and bAttacking
        then
            local targetAlly = nil
            local hp = 1000

            local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
            for _, allyHero in pairs(nInRangeAlly)
            do
                if Fu.IsValidHero(allyHero)
                and not Fu.IsSuspiciousIllusion(allyHero)
                then
                    local currHP = allyHero:GetHealth()

                    if currHP < hp
                    and Fu.GetHP(allyHero) < 0.75
                    then
                        hp = currHP
                        targetAlly = allyHero
                    end
                end
            end

            if targetAlly ~= nil
            then
                return BOT_ACTION_DESIRE_MODERATE, targetAlly
            end
        end
	end

    local targetAlly = nil
    local hp = 1000

    local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nInRangeAlly)
    do
        if Fu.IsValidHero(allyHero)
        and not Fu.IsSuspiciousIllusion(allyHero)
        then
            local nAllyInRangeCreeps = bot:GetNearbyCreeps(nRadius, true)
            local currHP = allyHero:GetHealth()

            if currHP < hp
            and Fu.GetHP(allyHero) < 0.75
            and nBotMP > 0.35
            and nAllyInRangeCreeps ~= nil and #nAllyInRangeCreeps >= 4
            then
                hp = currHP
                targetAlly = allyHero
            end
        end
    end

    if targetAlly ~= nil
    then
        return BOT_ACTION_DESIRE_MODERATE, targetAlly
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTombstone()
    if not Tombstone:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Tombstone:GetCastRange())
    local nRadius = Tombstone:GetSpecialValueInt('radius')

    if bInTeamFight
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius / 2)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            local loc = Fu.GetCenterOfUnits(nInRangeEnemy)

            if Fu.IsLocationInChrono(loc)
            or Fu.IsLocationInBlackHole(loc)
            or Fu.IsLocationInArena(loc, nRadius / 2)
            then
                return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            end

            return BOT_ACTION_DESIRE_HIGH, loc
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderFleshGolem()
    if not FleshGolem:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bInTeamFight
    then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X