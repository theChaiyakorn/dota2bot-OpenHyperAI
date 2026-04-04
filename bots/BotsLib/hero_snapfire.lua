local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        ['t25'] = {0, 10},
                        ['t20'] = {0, 10},
                        ['t15'] = {0, 10},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,2,1,3,3,6,3,3,1,1,6,2,2,2,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_double_branches",
    "item_circlet",
    "item_faerie_fire",
    "item_tango",

    "item_bottle",
    "item_bracer",
    "item_boots",
    "item_magic_wand",
    "item_maelstrom",
    "item_dragon_lance",
    "item_mjollnir",--
    "item_travel_boots",
    "item_greater_crit",--
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_force_staff",
    "item_hurricane_pike",--
    "item_moon_shard",
    "item_sheepstick",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = {
    "item_double_branches",
    "item_circlet",
    "item_faerie_fire",
    "item_tango",

    "item_bracer",
    "item_boots",
    "item_magic_wand",
    "item_maelstrom",
    "item_dragon_lance",
    "item_mjollnir",--
    "item_travel_boots",
    "item_greater_crit",--
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_force_staff",
    "item_hurricane_pike",--
    "item_moon_shard",
    "item_sheepstick",--
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

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

local ScatterBlast      = bot:GetAbilityByName('snapfire_scatterblast')
local FiresnapCookie    = bot:GetAbilityByName('snapfire_firesnap_cookie')
local LilShredder       = bot:GetAbilityByName('snapfire_lil_shredder')
local GobbleUp          = bot:GetAbilityByName('snapfire_gobble_up')
local SpitOut           = bot:GetAbilityByName('snapfire_spit_creep')
local MortimerKisses    = bot:GetAbilityByName('snapfire_mortimer_kisses')

local ScatterBlastDesire, ScatterBlastLocation
local FiresnapCookieDesire, FiresnapCookieTarget
local LilShredderDesire
local GobbleUpDesire, GobbleUpTarget
local SpitOutDesire, SpitOutLocation
local MortimerKissesDesire, MortimerKissesLocation

local botTarget
local bGoingOnSomeone
local bAttacking
local nBotMP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = ctx.mp

    MortimerKissesDesire, MortimerKissesLocation = X.ConsiderMortimerKisses()
    if MortimerKissesDesire > 0
    then
        bot:Action_UseAbilityOnLocation(MortimerKisses, MortimerKissesLocation)
        return
    end

    LilShredderDesire = X.ConsiderLilShredder()
    if LilShredderDesire > 0
    then
        bot:Action_UseAbility(LilShredder)
        return
    end

    ScatterBlastDesire, ScatterBlastLocation = X.ConsiderScatterBlast()
    if ScatterBlastDesire > 0
    then
        bot:Action_UseAbilityOnLocation(ScatterBlast, ScatterBlastLocation)
        return
    end

    FiresnapCookieDesire, FiresnapCookieTarget = X.ConsiderFiresnapCookie()
    if FiresnapCookieDesire > 0
    then
        bot:Action_UseAbilityOnEntity(FiresnapCookie, FiresnapCookieTarget)
        return
    end

    SpitOutDesire, SpitOutLocation = X.ConsiderSpitOut()
    if SpitOutDesire > 0
    then
        bot:Action_UseAbilityOnLocation(SpitOut, SpitOutLocation)
        return
    end

    GobbleUpDesire, GobbleUpTarget = X.ConsiderGobbleUp()
    if GobbleUpDesire > 0
    then
        bot:Action_UseAbilityOnEntity(GobbleUp, GobbleUpTarget)
        return
    end
end

function X.ConsiderScatterBlast()
    if not ScatterBlast:IsFullyCastable()
    or bot:HasModifier('modifier_snapfire_mortimer_kisses')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ScatterBlast:GetCastRange())
	local nCastPoint = ScatterBlast:GetCastPoint()
	local nRadius = ScatterBlast:GetSpecialValueInt('blast_width_end')
	local nDamage = ScatterBlast:GetSpecialValueInt('damage');
	botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
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
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(nCastPoint)
        end
    end

    if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetExtrapolatedLocation(nCastPoint)
            end
		end
	end

	if Fu.IsRetreating(bot)
	then
        for _, enemyHero in pairs(nEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.IsChasingTarget(enemyHero, bot)
            and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH, bot:GetExtrapolatedLocation(nCastPoint)
            end
        end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and not bot:HasModifier('modifier_snapfire_lil_shredder_buff')
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)
        if nLocationAoE.count >= 1
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if Fu.IsFarming(bot)
    and not bot:HasModifier('modifier_snapfire_lil_shredder_buff')
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, nCastPoint, 0)

        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nCastRange)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
            and nBotMP > 0.33
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and nLocationAoE.count >= 3
            and nBotMP > 0.37
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if Fu.IsLaning(bot)
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
            --     and nBotMP > 0.35
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

        if nInRangeEnemy ~= nil and #nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsAttacking(nInRangeEnemy[1])
        and nBotMP > 0.55
        and Fu.GetHP(bot) < Fu.GetHP(nInRangeEnemy[1])
        and nInRangeEnemy[1]:GetAttackTarget() == bot
        then
            return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]:GetLocation()
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderFiresnapCookie()
    if not FiresnapCookie:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, FiresnapCookie:GetCastRange())
	local nCastPoint = FiresnapCookie:GetCastPoint()
	local nRadius = FiresnapCookie:GetSpecialValueInt('impact_radius')
	local nJumpDistance = FiresnapCookie:GetSpecialValueInt('jump_horizontal_distance')
    local nJumpDuration = FiresnapCookie:GetSpecialValueInt('jump_duration')
	botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and enemyHero:IsChanneling()
        and bot:IsFacingLocation(enemyHero:GetLocation(), 15)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        then
            local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

            if Fu.IsInRange(bot, enemyHero, nJumpDistance + nRadius)
            and not Fu.IsInRange(bot, enemyHero, nJumpDistance * 0.51)
            and nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    if Fu.IsStuck(bot)
	then
		return BOT_ACTION_DESIRE_HIGH, bot
	end

    if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nJumpDistance, nRadius, nJumpDuration + nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nJumpDistance)
		local nNonStunnedEnemy = Fu.CountNotStunnedUnits(nInRangeEnemy, nLocationAoE, nRadius, 2)

		if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and nNonStunnedEnemy >= 2
        and bot:IsFacingLocation(nLocationAoE.targetloc, 15)
		then
			return BOT_ACTION_DESIRE_LOW, bot
		end
	end

	if bGoingOnSomeone
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(bot, enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not Fu.IsLocationInChrono(enemyHero:GetLocation())
            and not Fu.IsLocationInBlackHole(enemyHero:GetLocation())
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                then
                    return BOT_ACTION_DESIRE_HIGH, bot
                end
            end
        end

        local nInRangeAlly = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_ATTACK)
        for _, allyHero in pairs(nInRangeAlly)
        do
            local allyTarget = allyHero:GetAttackTarget()

            if Fu.IsValidHero(allyHero)
            and Fu.IsValidTarget(allyTarget)
            and Fu.CanCastOnNonMagicImmune(allyTarget)
            and Fu.IsChasingTarget(allyHero, allyTarget)
            and Fu.IsInRange(allyHero, allyTarget, nJumpDistance)
            and not Fu.IsInRange(allyHero, allyTarget, nJumpDistance / 2)
            and not allyHero:IsIllusion()
            and not Fu.IsSuspiciousIllusion(allyTarget)
            and not Fu.IsDisabled(allyTarget)
            and not allyTarget:HasModifier('modifier_abaddon_borrowed_time')
            and not allyTarget:HasModifier('modifier_dazzle_shallow_grave')
            and not allyTarget:HasModifier('modifier_necrolyte_reapers_scythe')
            and not Fu.IsLocationInChrono(allyTarget:GetLocation())
            and not Fu.IsLocationInBlackHole(allyTarget:GetLocation())
            then
                local nAllyInRangeAlly = Fu.GetNearbyHeroes(allyTarget, 1200, true, BOT_MODE_NONE)
                local nAllyTargetInRangeAlly = Fu.GetNearbyHeroes(allyTarget, 1200, false, BOT_MODE_NONE)

                if nAllyInRangeAlly ~= nil and nAllyTargetInRangeAlly ~= nil
                and #nAllyInRangeAlly >= #nAllyTargetInRangeAlly
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end
            end
        end
	end

    if Fu.IsRetreating(bot)
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (Fu.GetHP(bot) < 0.65 and bot:WasRecentlyDamagedByAnyHero(1.5)))
            and bot:IsFacingLocation(Fu.GetEscapeLoc(), 30)
            then
		        return BOT_ACTION_DESIRE_HIGH, bot
            end
        end
    end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsStuck(allyHero)
        and not allyHero:IsIllusion()
        then
            return BOT_ACTION_DESIRE_HIGH, allyHero
        end

        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 800, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, allyHero, nCastRange)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and allyHero:IsFacingLocation(Fu.GetEscapeLoc(), 30)
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderLilShredder()
    if not LilShredder:IsFullyCastable()
    or bot:HasModifier('modifier_snapfire_mortimer_kisses')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nAttackRange = bot:GetAttackRange() + LilShredder:GetSpecialValueInt('attack_range_bonus')
    botTarget = Fu.GetProperTarget(bot)

	if botTarget ~= nil
    and botTarget:IsBuilding()
    and bAttacking
    then
		return BOT_ACTION_DESIRE_HIGH
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nAttackRange - 100)
        and bAttacking
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nAttackRange, true)
        local nEnemyTowers = bot:GetNearbyTowers(bot:GetAttackRange(), true)

        if bAttacking
        and nInRangeEnemy ~= nil and #nInRangeEnemy <= 1
        and ((nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4)
            or (nEnemyTowers ~= nil and #nEnemyTowers >= 1))
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        and nBotMP > 0.33
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nAttackRange)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nAttackRange, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderMortimerKisses()
    if not MortimerKisses:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nMinDistance = MortimerKisses:GetSpecialValueInt('min_range')

	if bGoingOnSomeone
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsInRange(bot, enemyHero, nMinDistance)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                if Fu.IsLocationInChrono(enemyHero:GetLocation())
                or Fu.IsLocationInBlackHole(enemyHero:GetLocation())
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                end
            end

            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsInRange(bot, enemyHero, nMinDistance)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1600, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1600, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                then
                    if (#nTargetInRangeAlly >= 1 and #nTargetInRangeAlly >= 1)
                    or #nTargetInRangeAlly == 0
                    then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
                    end
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderGobbleUp()
    if not bot:HasScepter()
    or not GobbleUp:IsFullyCastable()
    or bot:HasModifier('modifier_snapfire_mortimer_kisses')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, GobbleUp:GetCastRange())
    local nSpitRange = Fu.GetProperCastRange(false, bot, MortimerKisses:GetCastRange())
    botTarget = Fu.GetProperTarget(bot)

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nSpitRange)
        and not Fu.IsInRange(bot, botTarget, 600)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not Fu.IsLocationInChrono(botTarget:GetLocation())
        and not Fu.IsLocationInBlackHole(botTarget:GetLocation())
		then
			local nCreeps = bot:GetNearbyCreeps(nCastRange + 100, true)

			if nCreeps ~= nil and #nCreeps >= 1
            then
				GobledUnit = 'creep'
				return BOT_ACTION_DESIRE_HIGH, nCreeps[1]
			end
		end
	end

    local nAllyHeroes = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 800, true, BOT_MODE_NONE)

        if Fu.IsRetreating(allyHero)
        and allyHero:WasRecentlyDamagedByAnyHero(1.5)
        and not allyHero:IsIllusion()
        then
            if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
            and Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.IsInRange(bot, allyHero, nCastRange)
            and Fu.IsInRange(allyHero, nAllyInRangeEnemy[1], 600)
            and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not Fu.IsDisabled(nAllyInRangeEnemy[1])
            and not Fu.IsTaunted(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                GobbleUp = 'hero'
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSpitOut()
    if not SpitOut:IsFullyCastable()
    or not bot:HasModifier('modifier_snapfire_gobble_up_belly_has_unit')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nSpitRange = Fu.GetProperCastRange(false, bot, MortimerKisses:GetCastRange())
    botTarget = Fu.GetProperTarget(bot)

	if bGoingOnSomeone
    and GobbleUp == 'creep'
	then
		if Fu.IsValidTarget(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if GobbleUp == 'hero'
    then
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetEscapeLoc(), nSpitRange)
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

return X