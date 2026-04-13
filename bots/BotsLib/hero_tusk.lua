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
                        ['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{3,1,2,3,3,6,3,2,2,2,6,1,1,1,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_wind_lace",

    "item_magic_wand",
    "item_arcane_boots",
    "item_blink",
    "item_guardian_greaves",--
    "item_cyclone",
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_lotus_orb",--
	"item_gungir",--
    "item_wind_waker",--
    -- "item_ultimate_scepter_2",
    "item_overwhelming_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_wind_lace",

    "item_magic_wand",
    "item_tranquil_boots",
    "item_boots_of_bearing",--
    "item_pipe",--
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_pavise",
    "item_blink",
    "item_solar_crest",--
	"item_heavens_halberd",--
    "item_lotus_orb",--
	"item_gungir",--
    -- "item_ultimate_scepter_2",
    "item_overwhelming_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = {
	"item_tank_outfit",
	"item_echo_sabre",
	"item_crimson_guard",--
	"item_ultimate_scepter",
	"item_heavens_halberd",--
	"item_assault",--
	"item_travel_boots",
	"item_aghanims_shard",
	"item_satanic",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_heart",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

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

local IceShards         = SafeAbility(bot:GetAbilityByName('tusk_ice_shards'), 'tusk_ice_shards', 'tusk')
local Snowball          = SafeAbility(bot:GetAbilityByName('tusk_snowball'), 'tusk_snowball', 'tusk')
local LaunchSnowball    = SafeAbility(bot:GetAbilityByName('tusk_launch_snowball'), 'tusk_launch_snowball', 'tusk')
local TagTeam           = SafeAbility(bot:GetAbilityByName('tusk_tag_team'), 'tusk_tag_team', 'tusk')
local WalrusKick        = SafeAbility(bot:GetAbilityByName('tusk_walrus_kick'), 'tusk_walrus_kick', 'tusk')
local WalrusPunch       = SafeAbility(bot:GetAbilityByName('tusk_walrus_punch'), 'tusk_walrus_punch', 'tusk')
local DrinkingBuddies   = SafeAbility(bot:GetAbilityByName('tusk_drinking_buddies'), 'tusk_drinking_buddies', 'tusk')

local IceShardsDesire, IceShardsLocation
local SnowballDesire, SnowballTarget
local LaunchSnowballDesire
local TagTeamDesire
local WalrusKickDesire, WalrusKickTarget
local WalrusPunchDesire, WalrusPunchTarget
local DrinkingBuddiesDesire, DrinkingBuddiesTarget

local botTarget

if bot.snowballHeroRetreat then bot.snowballHeroRetreat = false end

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

    TagTeamDesire = X.ConsiderTagTeam()
    if TagTeamDesire > 0
    then
        bot:Action_UseAbility(TagTeam)
        return
    end

    DrinkingBuddiesDesire, DrinkingBuddiesTarget = X.ConsiderDrinkingBuddies()
    if DrinkingBuddiesDesire > 0 then
        bot:Action_UseAbilityOnEntity(DrinkingBuddies, DrinkingBuddiesTarget)
        return
    end

    IceShardsDesire, IceShardsLocation = X.ConsiderIceShards()
    if IceShardsDesire > 0
    then
        bot:Action_UseAbilityOnLocation(IceShards, IceShardsLocation)
        return
    end

    LaunchSnowballDesire = X.ConsiderLaunchSnowball()
    if LaunchSnowballDesire > 0
    then
        bot:Action_UseAbility(LaunchSnowball)
        bot.snowballHeroRetreat = false
        return
    end

    SnowballDesire, SnowballTarget = X.ConsiderSnowball()
    if SnowballDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Snowball, SnowballTarget)
        return
    end

    WalrusKickDesire, WalrusKickTarget = X.ConsiderWalrusKick()
    if WalrusKickDesire > 0
    then
        bot:Action_UseAbilityOnEntity(WalrusKick, WalrusKickTarget)
        return
    end

    WalrusPunchDesire, WalrusPunchTarget = X.ConsiderWalrusPunch()
    if WalrusPunchDesire > 0
    then
        bot:Action_UseAbilityOnEntity(WalrusPunch, WalrusPunchTarget)
        return
    end
end

function X.ConsiderIceShards()
    if not IceShards:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, IceShards:GetCastRange())
	local nCastPoint = IceShards:GetCastPoint()
    local nRadius = IceShards:GetSpecialValueInt('shard_width')
	local nDamage = IceShards:GetSpecialValueInt('shard_damage')
	local nSpeed = IceShards:GetSpecialValueInt('shard_speed')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local eta =  (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint + 2
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(eta)
        end
    end

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
        and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                local eta =  (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint + 2
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(eta)
            end
		end
	end

    -- if bRetreating
    -- then
    --     local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
    --     local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

    --     if nInRangeAlly ~= nil and nInRangeEnemy
    --     and Fu.IsValidHero(nInRangeEnemy[1])
    --     and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
    --     and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
    --     and not Fu.IsDisabled(nInRangeEnemy[1])
    --     and not nInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
    --     and not nInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
    --     and not nInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
    --     and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
    --     then
    --         local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

    --         if nTargetInRangeAlly ~= nil
    --         and ((#nTargetInRangeAlly > #nInRangeAlly)
    --             or bot:WasRecentlyDamagedByAnyHero(2))
    --         then
    --             local eta = ((GetUnitToUnitDistance(bot, nInRangeEnemy[1])) / nSpeed) + nCastPoint + 2
	-- 	        return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetExtrapolatedLocation(eta)
    --         end
    --     end
    -- end

    if Fu.IsLaning(bot) or Fu.IsPushing(bot)
    and not Fu.IsThereNonSelfCoreNearby(1200)
	then
        if not Fu.IsInLaningPhase()
        then
            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- no alt-cast support from the api
function X.ConsiderDrinkingBuddies()
    if not Fu.CanCastAbility(DrinkingBuddies) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, DrinkingBuddies:GetCastRange())
    local nAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)

    local hTarget = nil
	local nMaxDamage = 0
    for _, allyHero in pairs(nAllyHeroes) do
        if allyHero ~= bot and Fu.IsValidHero(allyHero) and not allyHero:IsIllusion() then
            if Fu.IsStuck(bot) or Fu.IsStuck(allyHero) then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end

            if Fu.IsDoingRoshan(bot)
            then
                if  Fu.IsRoshan(botTarget)
                and Fu.CanBeAttacked(botTarget)
                and Fu.IsInRange(bot, botTarget, 500)
                and bAttacking
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end

            if Fu.IsDoingTormentor(bot)
            then
                if  Fu.IsTormentor(botTarget)
                and Fu.IsInRange(bot, botTarget, 500)
                and bAttacking
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end

            if not Fu.IsDisabled(allyHero)
            and (not Fu.IsWithoutTarget(allyHero))
            and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not allyHero:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
            then
                local nDamage = allyHero:GetAttackDamage() * allyHero:GetAttackSpeed()
                if nDamage > nMaxDamage then
                    hTarget = allyHero
                    nMaxDamage = nDamage
                end
            end
        end
    end

    if bGoingOnSomeone and hTarget ~= nil then
		if  Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 1000)
        and Fu.CanBeAttacked(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            local bBotChasing = Fu.IsChasingTarget(bot, botTarget)
            local bAllyChasing = Fu.IsChasingTarget(hTarget, botTarget)
            local distbotToTarget = GetUnitToUnitDistance(bot, botTarget)
            local distAllyToTarget = GetUnitToUnitDistance(hTarget, botTarget)
            if (not bBotChasing or (bBotChasing and bAllyChasing and distAllyToTarget < distbotToTarget and distAllyToTarget < 500))
            then
                return BOT_ACTION_DESIRE_HIGH, hTarget
            end
		end
	end

    local nEnemyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

    if bRetreating
	and not Fu.IsRealInvisible(bot)
	and not bot:HasModifier('modifier_fountain_aura_buff')
    and #nAllyHeroes > 1
	then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, 800)
            and Fu.IsChasingTarget(enemyHero, bot)
            then
                if (bot:WasRecentlyDamagedByAnyHero(3.0) and not Fu.IsSuspiciousIllusion(enemyHero))
                or (#nAllyHeroes + 2 <= #nEnemyHeroes)
                then
                    for _, allyHero in pairs(nAllyHeroes) do
                        if allyHero ~= bot
                        and Fu.IsValidHero(allyHero)
                        and not allyHero:IsIllusion()
                        and Fu.IsRetreating(allyHero)
                        and GetUnitToUnitDistance(allyHero, enemyHero) > GetUnitToUnitDistance(bot, enemyHero)
                        and GetUnitToLocationDistance(enemyHero, ((bot:GetLocation() + allyHero:GetLocation()) / 2)) > 500
                        then
                            return BOT_ACTION_DESIRE_HIGH, allyHero
                        end
                    end
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSnowball()
    if not Snowball:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Snowball:GetCastRange())
    local nDuration = Snowball:GetSpecialValueFloat('snowball_duration')

	if bGoingOnSomeone
	then
		local strongestTarget = nil
		local dmg = 0

		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				local currDmg = enemyHero:GetEstimatedDamageToTarget(false, bot, nDuration, DAMAGE_TYPE_ALL)
				if currDmg > dmg
				then
					dmg = currDmg
					strongestTarget = enemyHero
				end
			end
		end

		if strongestTarget ~= nil
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(strongestTarget, 1200, true, BOT_MODE_NONE)
            nInRangeEnemy = Fu.GetNearbyHeroes(strongestTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, strongestTarget
            end
		end
	end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        local targetCreep = nil
        local dist = 0

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and #nInRangeEnemy > #nInRangeAlly
        then
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, 600)
                and Fu.IsChasingTarget(enemyHero, bot)
                and bot:WasRecentlyDamagedByHero(enemyHero, 1.5)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                then
                    local nCreeps = bot:GetNearbyCreeps(nCastRange, true)
                    for _, creep in pairs(nCreeps)
                    do
                        if Fu.IsValid(creep)
                        and GetUnitToLocationDistance(creep, GetAncient(GetTeam()):GetLocation()) < GetUnitToLocationDistance(bot, GetAncient(GetTeam()):GetLocation())
                        and GetUnitToUnitDistance(bot, creep) > nCastRange / 2
                        and dist > GetUnitToUnitDistance(bot, creep)
                        then
                            dist = GetUnitToUnitDistance(bot, creep)
                            targetCreep = creep
                        end
                    end
                end
            end

            if targetCreep ~= nil
            then
                return BOT_ACTION_DESIRE_HIGH, targetCreep
            end

            nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
            for _, enemyHero in pairs(nInRangeEnemy)
            do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, 600)
                and Fu.IsChasingTarget(enemyHero, bot)
                and bot:WasRecentlyDamagedByHero(enemyHero, 1.5)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not Fu.IsDisabled(enemyHero)
                and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
                and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not enemyHero:HasModifier('modifier_legion_commander_duel')
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    bot.snowballHeroRetreat = true
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
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
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderLaunchSnowball()
    if LaunchSnowball:IsHidden()
    or not LaunchSnowball:IsFullyCastable()
    or bot.snowballHeroRetreat
    then
        return BOT_ACTION_DESIRE_NONE
    end

    return BOT_ACTION_DESIRE_HIGH
end

function X.ConsiderTagTeam()
    if not Fu.CanCastAbility(TagTeam) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = TagTeam:GetSpecialValueInt('radius')

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
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

    if Fu.IsDoingRoshan(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,600, false, BOT_MODE_NONE)

        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nInRangeAlly ~= nil and #nInRangeAlly >= 2
        and Fu.IsAttacking(nInRangeAlly[1])
        and Fu.IsAttacking(nInRangeAlly[2])
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderWalrusKick()
    if not WalrusKick:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WalrusKick:GetCastRange())

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        for _, enemyHero in pairs(Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE))
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

    if bGoingOnSomeone
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE)

        for _, enemyHero in pairs(Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE))
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                if nInRangeAlly ~= nil and #nInRangeAlly >= 2
                and enemyHero ~= botTarget
                and Fu.IsInRange(enemyHero, nInRangeAlly[1], 600)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderWalrusPunch()
    if not WalrusPunch:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, WalrusPunch:GetCastRange())

    if bGoingOnSomeone
	then
		local strongestTarget = nil
		local dmg = 0

		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
		do
			if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
            and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemyHero:HasModifier('modifier_legion_commander_duel')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			then
				local currDmg = enemyHero:GetEstimatedDamageToTarget(false, bot, 4, DAMAGE_TYPE_ALL)
				if currDmg > dmg
				then
					dmg = currDmg
					strongestTarget = enemyHero
				end
			end
		end

		if strongestTarget ~= nil
		then
            return BOT_ACTION_DESIRE_HIGH, strongestTarget
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,600, false, BOT_MODE_NONE)

        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nInRangeAlly ~= nil and #nInRangeAlly >= 2
        and Fu.IsAttacking(nInRangeAlly[1])
        and Fu.IsAttacking(nInRangeAlly[2])
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X