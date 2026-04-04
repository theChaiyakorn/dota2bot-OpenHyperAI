local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {10, 0},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,6,1,2,2,2,3,3,6,3,1,1,1,6,6},--pos1,2 (ult at 3)
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_wraith_band",
    "item_boots",
    "item_magic_wand",
    "item_power_treads",
    "item_diffusal_blade",
    "item_aghanims_shard",
    "item_blink",
    "item_skadi",--
    "item_nullifier",--
    "item_ultimate_scepter",
    "item_sheepstick",--
    "item_disperser",--
    "item_ultimate_scepter_2",
    "item_swift_blink",--
    "item_moon_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_wraith_band",
    "item_boots",
    "item_magic_wand",
    "item_power_treads",
    "item_diffusal_blade",
    "item_aghanims_shard",
    "item_blink",
    "item_skadi",--
    "item_sheepstick",--
    "item_ultimate_scepter",
    "item_disperser",--
    "item_ultimate_scepter_2",
    "item_swift_blink",--
    "item_moon_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_wraith_band",
    "item_boots",
    "item_magic_wand",
    "item_power_treads",
    "item_diffusal_blade",
    "item_aghanims_shard",
    "item_blink",
    "item_skadi",--
    "item_ultimate_scepter",
    "item_sheepstick",--
    "item_disperser",--
    "item_ultimate_scepter_2",
    "item_swift_blink",--
    "item_moon_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_wraith_band",
	"item_quelling_blade",
	"item_magic_wand",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

-- EarthBind deduplication across clones
local function IsEarthBindCoveredByClone(location, radius)
    local now = GameTime()
    local checkRadius = radius * 1.5

    for _, member in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
    do
        if member ~= bot
        and Fu.IsValidHero(member)
        and member:GetUnitName() == 'npc_dota_hero_meepo'
        and member.earth_bind_cast ~= nil
        and (now - member.earth_bind_cast.time) < 2.0
        then
            local dist = GetUnitToLocationDistance(bot, member.earth_bind_cast.location)
            -- Use distance between the two cast locations
            local dx = location.x - member.earth_bind_cast.location.x
            local dy = location.y - member.earth_bind_cast.location.y
            local castDist = math.sqrt(dx * dx + dy * dy)
            if castDist < checkRadius then
                return true
            end
        end
    end

    return false
end

local function RecordEarthBindCast(location)
    bot.earth_bind_cast = {
        time = GameTime(),
        location = location,
    }
end

-- Ability handles (re-fetched in SkillsComplement)
local EarthBind         = bot:GetAbilityByName('meepo_earthbind')
local Poof              = bot:GetAbilityByName('meepo_poof')
local Dig               = bot:GetAbilityByName('meepo_petrify')
local MegaMeepo         = bot:GetAbilityByName('meepo_megameepo')
local MegaMeepoFling    = bot:GetAbilityByName('meepo_megameepo_fling')

local EarthBindDesire, EarthBindLocation
local PoofDesire, PoofTarget
local DigDesire
local MegaMeepoDesire
local MegaMeepoFlingDesire, MegaMeepoFlingFlingTarget

local Meepos = {}

-- Cached per-tick variables
local botTarget
local botHP
local nAllyHeroes
local nEnemyHeroes
local bAttacking

local bGoingOnSomeone
local bRetreating
local nBotMP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

    local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	nBotMP = ctx.mp

    -- Re-fetch ability handles each tick for safety
    EarthBind      = bot:GetAbilityByName('meepo_earthbind')
    Poof           = bot:GetAbilityByName('meepo_poof')
    Dig            = bot:GetAbilityByName('meepo_petrify')
    MegaMeepo      = bot:GetAbilityByName('meepo_megameepo')
    MegaMeepoFling = bot:GetAbilityByName('meepo_megameepo_fling')

    -- Cache per-tick variables
    Meepos       = Fu.GetMeepos()
    botTarget    = ctx.target
    botHP        = ctx.hp
    nAllyHeroes  = Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE)
    nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE)
    bAttacking   = Fu.IsAttacking(bot)

    PoofDesire, PoofTarget = X.ConsiderPoof()
    if PoofDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(Poof, PoofTarget)
        return
    end

    DigDesire = X.ConsiderDig()
    if DigDesire > 0
    then
        bot:ActionQueue_UseAbility(Dig)
        return
    end

    MegaMeepoDesire = X.ConsiderMegaMeepo()
    if MegaMeepoDesire > 0
    then
        bot:ActionQueue_UseAbility(MegaMeepo)
        return
    end

    EarthBindDesire, EarthBindLocation = X.ConsiderEarthBind()
    if EarthBindDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(EarthBind, EarthBindLocation)
        RecordEarthBindCast(EarthBindLocation)
        return
    end

    MegaMeepoFlingDesire, MegaMeepoFlingFlingTarget = X.ConsiderMegaMeepoFling()
    if MegaMeepoFlingDesire > 0
    then
        bot:ActionQueue_UseAbilityOnEntity(MegaMeepoFling, MegaMeepoFlingFlingTarget)
        return
    end
end

function X.ConsiderEarthBind()
    if not EarthBind:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, EarthBind:GetCastRange())
    local nCastPoint = EarthBind:GetCastPoint()
	local nRadius = EarthBind:GetSpecialValueInt('radius')
	local nSpeed = EarthBind:GetSpecialValueInt('speed')
    local nModeDesire = bot:GetActiveModeDesire()

    local nEnemyHeroesInRange = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroesInRange)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and (enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero))
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            local loc = enemyHero:GetLocation()
            if not IsEarthBindCoveredByClone(loc, nRadius) then
                return BOT_ACTION_DESIRE_HIGH, loc
            end
        end
    end

    if Fu.IsInTeamFight(bot, 1200)
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        if nLocationAoE.count >= 2
        then
            if not IsEarthBindCoveredByClone(nLocationAoE.targetloc, nRadius) then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsTaunted(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_meepo_earthbind')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        then
            local nDelay = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
            local loc = botTarget:GetExtrapolatedLocation(nDelay)
            if not IsEarthBindCoveredByClone(loc, nRadius) then
                return BOT_ACTION_DESIRE_HIGH, loc
            end
        end
	end

    if bRetreating
    and nModeDesire > BOT_ACTION_DESIRE_HIGH
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (botHP < 0.62 and bot:WasRecentlyDamagedByAnyHero(2)))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_meepo_earthbind')
        then
            local nDelay = (GetUnitToUnitDistance(bot, nInRangeEnemy[1]) / nSpeed) + nCastPoint
            local loc = nInRangeEnemy[1]:GetExtrapolatedLocation(nDelay)
            if not IsEarthBindCoveredByClone(loc, nRadius) then
                return BOT_ACTION_DESIRE_HIGH, loc
            end
        end
    end

    local nAllyHeroesInRange = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroesInRange)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, nCastRange, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2.1)
        and not allyHero:IsIllusion()
        and nBotMP > 0.48
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
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_meepo_earthbind')
            then
                local nDelay = (GetUnitToUnitDistance(bot, nAllyInRangeEnemy[1]) / nSpeed) + nCastPoint
                local loc = nAllyInRangeEnemy[1]:GetExtrapolatedLocation(nDelay + nCastPoint)
                if not IsEarthBindCoveredByClone(loc, nRadius) then
                    return BOT_ACTION_DESIRE_HIGH, loc
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderPoof()
    if not Poof:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nRadius = Poof:GetSpecialValueInt('radius')
	local nDamage = Poof:GetAbilityDamage()

    ----------------------------------------------------------------
    -- Poof-to-clone: Fountain escape
    -- If HP < 0.5, not stunned, and a clone is near fountain, poof to it
    ----------------------------------------------------------------
    if botHP < 0.5
    and bRetreating
    then
        for _, meepo in pairs(Meepos)
        do
            if meepo ~= bot
            and meepo:DistanceFromFountain() < 800
            and not Fu.IsStunProjectileIncoming(bot, 400)
            then
                return BOT_ACTION_DESIRE_ABSOLUTE, meepo
            end
        end
    end

    ----------------------------------------------------------------
    -- Poof-to-clone: Push/Defend lane front
    -- If a clone is near lane front and bot is far (>3200), poof there
    ----------------------------------------------------------------
    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and not bRetreating
    then
        local laneFrontLoc = GetLaneFrontLocation(GetTeam(), bot:GetAssignedLane(), 0)

        for _, meepo in pairs(Meepos)
        do
            if meepo ~= bot
            and GetUnitToLocationDistance(meepo, laneFrontLoc) < 1200
            and GetUnitToLocationDistance(bot, laneFrontLoc) > 3200
            and botHP > 0.6
            then
                return BOT_ACTION_DESIRE_HIGH, meepo
            end
        end
    end

    ----------------------------------------------------------------
    -- Poof-to-clone: Rescue retreating clone
    -- If a clone is being chased, bot has good HP and allies >= enemies, poof to help
    ----------------------------------------------------------------
    if botHP > 0.5
    and not bRetreating
    then
        for _, meepo in pairs(Meepos)
        do
            if meepo ~= bot
            and Fu.IsRetreating(meepo)
            and meepo:WasRecentlyDamagedByAnyHero(2.0)
            and Fu.GetHP(meepo) < 0.5
            and GetUnitToUnitDistance(bot, meepo) > 1200
            then
                local cloneAlly = Fu.GetNearbyHeroes(meepo, 1200, false, BOT_MODE_NONE)
                local cloneEnemy = Fu.GetNearbyHeroes(meepo, 1200, true, BOT_MODE_NONE)

                if cloneAlly ~= nil and cloneEnemy ~= nil
                and #cloneAlly >= #cloneEnemy
                and #cloneEnemy >= 1
                then
                    return BOT_ACTION_DESIRE_HIGH, meepo
                end
            end
        end
    end

    ----------------------------------------------------------------
    -- Existing logic: Poof to clone that is going on someone
    ----------------------------------------------------------------
    for _, meepo in pairs(Meepos)
    do
        local mTarget = meepo:GetAttackTarget()

        if Fu.IsGoingOnSomeone(meepo)
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(meepo, 1000, false, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(meepo, 800, true, BOT_MODE_NONE)

            if Fu.IsValidTarget(mTarget)
            and Fu.IsInRange(meepo, mTarget, 800)
            and not bRetreating
            and not Fu.IsSuspiciousIllusion(mTarget)
            and nInRangeAlly ~= nil and nInRangeEnemy
            and #nInRangeAlly >= #nInRangeEnemy
            and GetUnitToUnitDistance(bot, meepo) > 1600
            then
                return BOT_ACTION_DESIRE_HIGH, meepo
            end
        end

        if Fu.IsLaning(bot)
        and Fu.IsLaning(meepo)
        and meepo ~= bot
        then
            local laneFrontLoc = GetLaneFrontLocation(GetTeam(), bot:GetAssignedLane(), 0)

            if GetUnitToLocationDistance(bot, laneFrontLoc) > 1600
            and GetUnitToLocationDistance(meepo, laneFrontLoc) < 600
            then
                return BOT_ACTION_DESIRE_HIGH, meepo
            end
        end

        if Fu.IsDoingRoshan(meepo)
        then
            local nInRangeEnemy = Fu.GetNearbyHeroes(meepo, 800, true, BOT_MODE_NONE)

            if Fu.IsRoshan(mTarget)
            and Fu.IsInRange(meepo, mTarget, 400)
            and Fu.GetHP(mTarget) > 0.33
            and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
            then
                return BOT_ACTION_DESIRE_HIGH, meepo
            end
        end

        if Fu.IsDoingTormentor(meepo)
        then
            local nInRangeEnemy = Fu.GetNearbyHeroes(meepo, 800, true, BOT_MODE_NONE)

            if Fu.IsTormentor(mTarget)
            and Fu.IsInRange(meepo, mTarget, 400)
            and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
            then
                return BOT_ACTION_DESIRE_HIGH, meepo
            end
        end

        if botHP < 0.3
        and bRetreating
        and meepo ~= bot
        and meepo:DistanceFromFountain() < 500
        then
            return BOT_ACTION_DESIRE_HIGH, meepo
        end
    end

	if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (botHP < 0.8 and bot:WasRecentlyDamagedByAnyHero(1.3)))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.CanCastOnNonMagicImmune(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 1000)
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local targetMeepo = nil
            local dist = 0

            for _, meepo in pairs(Meepos)
            do
                if GetUnitToUnitDistance(bot, meepo) > dist
                then
                    targetMeepo = meepo
                    dist = GetUnitToUnitDistance(bot, meepo)
                end
            end

            if targetMeepo ~= nil and targetMeepo ~= bot
            then
                return BOT_ACTION_DESIRE_HIGH, targetMeepo
            end
        end
	end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local nEnemyLanecreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLanecreeps ~= nil and #nEnemyLanecreeps >= 3
            and nBotMP > 0.33
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end

            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil and #nNeutralCreeps >= 2
            and nBotMP > 0.26
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    if Fu.IsLaning(bot)
    and nBotMP > 0.29
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        local canKillCreepsCount = 0

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			then
                canKillCreepsCount = canKillCreepsCount + 1
			end
		end

        if canKillCreepsCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end

        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius / 2.1, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and nBotMP > 0.76
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			then
				nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

				if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
				and GetUnitToUnitDistance(creep, nInRangeEnemy[1]) <= 500
                and botHP > 0.5 and not bot:WasRecentlyDamagedByAnyHero(2.7)
				then
					return BOT_ACTION_DESIRE_HIGH, bot
				end
			end
		end
	end

	if (Fu.IsDefending(bot) or Fu.IsPushing(bot))
	then
		local nEnemyLanecreeps = bot:GetNearbyLaneCreeps(nRadius, true)
		if nEnemyLanecreeps ~= nil and #nEnemyLanecreeps >= 4
		then
			return BOT_ACTION_DESIRE_HIGH, bot
		end
	end

	if botHP
    and not bRetreating
    then
		for _, meepo in pairs(Meepos)
        do
            local nInRangeAlly = Fu.GetNearbyHeroes(meepo, 800, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(meepo, 1200, true, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and ((#Meepos >= #nInRangeEnemy)
                or (#nInRangeAlly >= #nInRangeEnemy))
            and GetUnitToUnitDistance(bot, meepo) > 1600
            and meepo:WasRecentlyDamagedByAnyHero(1.1)
            then
				return BOT_ACTION_DESIRE_HIGH, meepo
			end
		end
	end

	if botHP
    and not bRetreating
    then
		for _, meepo in pairs(Meepos)
        do
            local nInRangeAlly = Fu.GetNearbyHeroes(meepo, 800, false, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(meepo, 324, true, BOT_MODE_NONE)

			if nInRangeEnemy ~= nil
            and botHP - Fu.GetHP(meepo) > 0.2
            then
				if Fu.IsValidHero(nInRangeEnemy[1])
                and ((#Meepos >= #nInRangeEnemy)
                    or (#nInRangeAlly >= #nInRangeEnemy))
                and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
                and not Fu.IsLaning(meepo)
                then
					return BOT_ACTION_DESIRE_HIGH, meepo
				end
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderDig()
    if not Dig:IsTrained()
    or not Dig:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Modifier awareness: skip Dig when it won't help or interferes
    if bot:HasModifier('modifier_doom_bringer_doom') then
        -- Doom prevents all abilities/items; Dig heal is negligible, waste of time
        return BOT_ACTION_DESIRE_NONE
    end

    if bot:HasModifier('modifier_oracle_false_promise_timer') then
        -- False Promise delays damage; digging during it interferes with Oracle's save
        return BOT_ACTION_DESIRE_NONE
    end

    if bot:HasModifier('modifier_ice_blast') then
        -- Ice Blast prevents healing; only dig if we were recently hit (to dodge further damage)
        if not bot:WasRecentlyDamagedByAnyHero(1.5) then
            return BOT_ACTION_DESIRE_NONE
        end
        -- If recently damaged, still consider digging for invulnerability
    end

    if botHP < 0.49
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderMegaMeepo()
    if not MegaMeepo:IsTrained()
    or not MegaMeepo:IsFullyCastable()
    or bot:HasModifier('modifier_meepo_petrify')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = 600

    if bGoingOnSomeone
    then
        local count = 0

        for _, meepo in pairs(Meepos)
        do

            if meepo:WasRecentlyDamagedByAnyHero(1.2)
            and Fu.IsMeepoClone(meepo)
            and Fu.IsInRange(bot, meepo, nRadius)
            and not meepo:HasModifier('modifier_meepo_petrify')
            then
                count = count + 1
            end
        end

        if count >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderMegaMeepoFling()
    if MegaMeepoFling:IsHidden()
    or not MegaMeepoFling:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCastRange = MegaMeepoFling:GetCastRange()
    local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
    local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

    if bGoingOnSomeone
    then
        local weakestTarget = Fu.GetAttackableWeakestUnit(bot, nCastRange, true, true)

        if weakestTarget ~= nil
        and bot:WasRecentlyDamagedByAnyHero(3.1)
        and not Fu.IsMeepoClone(bot)
        and not weakestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
        then
            return BOT_ACTION_DESIRE_HIGH, weakestTarget
        end
    end

    local nCreeps = bot:GetNearbyCreeps(nCastRange, true)
    if nCreeps ~= nil and #nCreeps >= 1
    and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
    then
        if Fu.IsValid(nCreeps[1])
        and not Fu.IsMeepoClone(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, nCreeps[1]
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X
