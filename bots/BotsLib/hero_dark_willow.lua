-- Currently bugged internally. Just adding her here in case Valve fixes her and (others) in the future...
-- She won't be selected.

local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,2,1,3,1,4,1,2,2,2,4,3,3,3,4},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_enchanted_mango",
    "item_double_branches",
    "item_blood_grenade",

    "item_boots",
    "item_magic_wand",
    "item_arcane_boots",
    "item_guardian_greaves",--
    "item_cyclone",
    "item_aghanims_shard",
    "item_force_staff",--
    "item_aether_lens",--
    "item_ultimate_scepter",--
    "item_hurricane_pike",--
    "item_octarine_core",--
    "item_wind_waker",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_enchanted_mango",
    "item_double_branches",
    "item_blood_grenade",

    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
	"item_pipe",--
    "item_cyclone",
    "item_force_staff",--
    "item_aether_lens",--
    "item_aghanims_shard",
    "item_boots_of_bearing",--
    "item_ultimate_scepter",--
    "item_hurricane_pike",--
    "item_octarine_core",--
    "item_wind_waker",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_double_tango",
    "item_enchanted_mango",
    "item_double_branches",

    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
    "item_cyclone",
    "item_aghanims_shard",
    "item_force_staff",--
    "item_aether_lens",--
    "item_boots_of_bearing",--
    "item_ultimate_scepter",--
    "item_hurricane_pike",--
    "item_octarine_core",--
    "item_wind_waker",
    "item_moon_shard",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_ultimate_scepter",
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

local BrambleMaze   = bot:GetAbilityByName('dark_willow_bramble_maze')
local ShadowRealm   = bot:GetAbilityByName('dark_willow_shadow_realm')
local CurseCrown    = bot:GetAbilityByName('dark_willow_cursed_crown')
local Bedlam        = bot:GetAbilityByName('dark_willow_bedlam')
local Terrorize     = bot:GetAbilityByName('dark_willow_terrorize')

local BrambleMazeDesire, BrambleMazeLocation
local ShadowRealmDesire
local CurseCrownDesire, CurseCrownTarget
local BedlamDesire, BedlamTarget
local TerrorizeDesire, TerrorizeLocation

local BedlamTime    = 0
local TerrorizeTime = 0

local botTarget
local bGoingOnSomeone
local bRetreating
local nBotHP
local bInTeamFight
function X.SkillsComplement()

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	nBotHP = ctx.hp
	bInTeamFight = ctx.isTeamFight
	if Fu.CanNotUseAbility(bot)
    then
        return
    end

    BrambleMazeDesire, BrambleMazeLocation = X.ConsiderBrambleMaze()
    if BrambleMazeDesire > 0
    then
        bot:Action_UseAbilityOnLocation(BrambleMaze, BrambleMazeLocation)
        return
    end

    BedlamDesire, BedlamTarget = X.ConsiderBedlam()
    if BedlamDesire > 0
    then
        bot:Action_UseAbility(Bedlam)
        BedlamTime = DotaTime()
        return
    end

    ShadowRealmDesire = X.ConsiderShadowRealm()
    if ShadowRealmDesire > 0
    then
        bot:Action_UseAbility(ShadowRealm)
    end

    CurseCrownDesire, CurseCrownTarget = X.ConsiderCurseCrown()
    if CurseCrownDesire > 0
    then
        bot:Action_UseAbilityOnEntity(CurseCrown, CurseCrownTarget)
        return
    end

    TerrorizeDesire, TerrorizeLocation = X.ConsiderTerrorize()
    if TerrorizeDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Terrorize, TerrorizeLocation)
        TerrorizeTime = DotaTime()
        return
    end
end

function X.ConsiderBrambleMaze()
    if not BrambleMaze:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = BrambleMaze:GetCastRange()
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
    botTarget = Fu.GetProperTarget(bot)

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValid(enemyHero)
		and (enemyHero:IsChanneling() or Fu.IsCastingUltimateAbility(enemyHero))
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsMoving(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if bRetreating
    and	Fu.IsValid(nEnemyHeroes[1])
    and Fu.CanCastOnNonMagicImmune(nEnemyHeroes[1])
    and not Fu.IsDisabled(nEnemyHeroes[1])
    and not Fu.IsRealInvisible(bot)
    and not Fu.IsSuspiciousIllusion(nEnemyHeroes[1])
	then
		return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]:GetLocation()
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderShadowRealm()
    if not ShadowRealm:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local nRangeBonus = ShadowRealm:GetSpecialValueInt('attack_range_bonus')
    local nAttackRange = bot:GetAttackRange()
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nAttackRange + nRangeBonus, true, BOT_MODE_NONE)
    botTarget = Fu.GetProperTarget(bot)

	if bGoingOnSomeone
	then
		if nBotHP < 0.5
        and Fu.IsValidHero(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not Fu.IsRealInvisible(bot)
        and nEnemyHeroes ~= nil and #nEnemyHeroes >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if (bRetreating or (bRetreating and nBotHP < 0.6 and bot:WasRecentlyDamagedByAnyHero(2)))
    and not Fu.IsRealInvisible(bot)
    and nEnemyHeroes ~= nil and #nEnemyHeroes >= 1
	then
        if (Fu.DidEnemyCastAbility() or nBotHP < 0.5 or Fu.IsStunProjectileIncoming(bot, 800))
        then
            return BOT_ACTION_DESIRE_HIGH
        end

		return BOT_ACTION_DESIRE_MODERATE
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderCurseCrown()
	if not CurseCrown:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, CurseCrown:GetCastRange())
    local nMana = bot:GetMana() / bot:GetMaxMana()
	local nEnemysHeroesInRange = Fu.GetNearbyHeroes(bot,nCastRange + 50, true, BOT_MODE_NONE)
	local nEnemysHeroesInBonus = Fu.GetNearbyHeroes(bot,nCastRange + 150, true, BOT_MODE_NONE)
	local nWeakestEnemyHeroInRange = Fu.GetWeakestUnit(nEnemysHeroesInRange)
	local nWeakestEnemyHeroInBonus = Fu.GetWeakestUnit(nEnemysHeroesInBonus)

	local nTowers = bot:GetNearbyTowers(900, true)

	if bInTeamFight
	then
		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0
		local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange + 100, true, BOT_MODE_NONE)

		for _, enemyHero in pairs(nEnemyHeroes)
		do
			if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsDisabled(enemyHero)
			then
				local npcEnemyDamage = enemyHero:GetEstimatedDamageToTarget(false, bot, 3.5, DAMAGE_TYPE_ALL)

				if npcEnemyDamage > nMostDangerousDamage
				then
					nMostDangerousDamage = npcEnemyDamage
					npcMostDangerousEnemy = enemyHero
				end
			end
		end

		if npcMostDangerousEnemy ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end

    if bGoingOnSomeone
	then
		botTarget = Fu.GetProperTarget(bot)

		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if bRetreating
	then
		for _, enemyHero in pairs(nEnemysHeroesInRange)
		do
			if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and bot:WasRecentlyDamagedByHero(enemyHero, 3.5)
            and bot:IsFacingLocation(enemyHero:GetLocation(), 45)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end

	if bot:WasRecentlyDamagedByAnyHero(2)
    and nEnemysHeroesInRange[1] ~= nil
    and #nEnemysHeroesInRange >= 1
	then
		for _, enemyHero in pairs(nEnemysHeroesInRange)
		do
			if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and bot:IsFacingLocation(enemyHero:GetLocation(), 30)
            and not Fu.IsDisabled(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end


	if (Fu.IsLaning(bot) and #nTowers == 0) or DotaTime() > 12 * 60
	then
		if nMana > 0.7
		then
			if Fu.IsValidHero(nWeakestEnemyHeroInRange)
            and not Fu.IsDisabled(nWeakestEnemyHeroInRange)
			then
                return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyHeroInRange
			end
		end

		if nMana > 0.88
		then
			local nEnemysCreeps = bot:GetNearbyCreeps(1200, true)

			if Fu.IsValidHero(nWeakestEnemyHeroInBonus)
            and nBotHP > 0.6
            and #nTowers == 0
            and ((#nEnemysCreeps + #nEnemysHeroesInBonus ) <= 5 or DotaTime() > 12 * 60)
            and not Fu.IsDisabled(nWeakestEnemyHeroInBonus)
			then
                return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyHeroInBonus
			end
		end

		if Fu.IsValidHero(nWeakestEnemyHeroInRange)
        and Fu.GetHP(nWeakestEnemyHeroInRange) < 0.4
		then
            return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyHeroInRange
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderBedlam()
    if not Bedlam:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    if Terrorize:IsTrained()
    then
        local nFearDuration = Bedlam:GetSpecialValueInt('destination_status_duration')
        if DotaTime() - TerrorizeTime <= nFearDuration
        then
            return BOT_ACTION_DESIRE_NONE, nil
        end
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Bedlam:GetCastRange())
    botTarget = Fu.GetProperTarget(bot)
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

	if bInTeamFight
	then
        if #nEnemyHeroes >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, bot
        end
	end

    if bGoingOnSomeone
	then
        if Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsValidTarget(botTarget)
        then
            return BOT_ACTION_DESIRE_HIGH, allyTarget
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderTerrorize()
    if not Terrorize:IsFullyCastable()
    or DotaTime() - BedlamTime <= 5
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, Terrorize:GetCastRange())
	local nRadius   = Terrorize:GetSpecialValueInt('destination_radius')
	local nEnemysHeroesInBonus = Fu.GetNearbyHeroes(bot, nCastRange + 150, true, BOT_MODE_NONE)

	if bInTeamFight
	then
        local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
		local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
        local nDisabledAllies = 0
        local nInArenaEnemy = 0
        local IsCoreAllyInChronosphere = false
        local nChronodAlly = nil

        if nTeamFightLocation ~= nil
        then
            nAllyHeroes = Fu.GetAlliesNearLoc(nTeamFightLocation, nRadius)
        end

        -----
        local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and enemyHero:HasModifier('modifier_mars_arena_of_blood')
            then
                nInArenaEnemy = nInArenaEnemy + 1
            end
        end

        if nInArenaEnemy >= 2
        then
			local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)

			if nLocationAoE.count >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
        -----

		for _, allyHero in pairs(nAllyHeroes)
        do
			if Fu.IsValidHero(allyHero)
            and Fu.IsDisabled(allyHero)
            and not allyHero:IsIllusion()
            then
				nDisabledAllies = nDisabledAllies + 1
			end

            -----
            if Fu.IsValidHero(allyHero)
            and Fu.IsCore(allyHero)
            and allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            then
                local nNearbyEnemyWithAlly = Fu.GetNearbyHeroes(allyHero, 400, true, BOT_MODE_NONE)

                if nNearbyEnemyWithAlly ~= nil and #nNearbyEnemyWithAlly >= 1
                then
                    IsCoreAllyInChronosphere = true
                    nChronodAlly = allyHero
                    break
                end
            end
            -----
		end

        -----
        if nChronodAlly ~= nil
        and IsCoreAllyInChronosphere
        then
            return BOT_ACTION_DESIRE_HIGH, ChronodAlly:GetLocation()
        end
        -----

		if nDisabledAllies >= 2
        then
			local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)

			if nLocationAoE.count >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
		end
	end

	if bRetreating
	then
		local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if bot:WasRecentlyDamagedByAnyHero(2.0)
        and #nEnemyHeroes >= 2
		then
			local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)

			if nLocationAoE.count >= 2
			then
				return BOT_ACTION_DESIRE_MODERATE, nLocationAoE.targetloc
			end
		end
	end

	--打断
	for _, npcEnemy in pairs( nEnemysHeroesInBonus )
	do
		if Fu.IsValid( npcEnemy )
			and (npcEnemy:IsChanneling() or npcEnemy:HasModifier( 'modifier_teleporting' ))
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
            local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, 300, 0, 0)
            if nLocationAoE.count >= 2
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
			return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
		end
	end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero) or (Fu.IsRetreating(allyHero) and Fu.GetHP(allyHero) < 0.4)
        and Fu.IsCore(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(2)
        then
            local nLocationAoE = bot:FindAoELocation(true, true, allyHero:GetLocation(), nCastRange, nRadius, 0, 0)

			if nLocationAoE.count >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
			end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

return X