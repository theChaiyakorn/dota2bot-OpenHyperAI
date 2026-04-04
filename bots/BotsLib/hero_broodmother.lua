local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos2
                            ['t25'] = {0, 10},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        },
                        {--pos3
                            ['t25'] = {0, 10},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        }
}

local tAllAbilityBuildList = {
						{2,3,2,3,2,6,2,3,3,1,6,1,1,1,6},--pos2
                        {2,3,2,1,2,6,2,3,3,3,6,1,1,1,6},--pos3
}

local nAbilityBuildList = tAllAbilityBuildList[2]
local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2])

if sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
elseif sRole == "pos_3"
then
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",

    "item_double_wraith_band",
    "item_power_treads",
    "item_soul_ring",
    "item_magic_wand",
	"item_orchid",
    "item_bloodthorn",--
    "item_black_king_bar",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_nullifier",--
    "item_skadi",--
    "item_travel_boots_2",--
    "item_moon_shard",
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",

    "item_double_wraith_band",
    "item_power_treads",
    "item_soul_ring",
    "item_magic_wand",
	"item_orchid",
    "item_bloodthorn",--
    "item_black_king_bar",--
    "item_assault",--
    "item_aghanims_shard",
    "item_sheepstick",--
    "item_skadi",--
    "item_travel_boots_2",--
    "item_moon_shard",
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

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

local InsatiableHunger  = bot:GetAbilityByName('broodmother_insatiable_hunger')
local SpinWeb           = bot:GetAbilityByName('broodmother_spin_web')
-- local SilkenBola        = bot:GetAbilityByName('broodmother_silken_bola')
-- local SpinnersSnare     = bot:GetAbilityByName('broodmother_sticky_snare')
local SpawnSpiderlings  = bot:GetAbilityByName('broodmother_spawn_spiderlings')

local InsatiableHungerDesire
local SpinWebDesire, SpinWebLocation
-- local SilkenBolaDesire, SilkenBolaTarget
-- local SpinnersSnareDesire, SpinnersSnareLocation -- No Unit.
local SpawnSpiderlingsDesire, SpirderlingsTarget
local WebGapTime = 1
local LastWebTime = 0

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

    SpawnSpiderlingsDesire, SpirderlingsTarget = X.ConsiderSpawnSpiderlings()
    if SpawnSpiderlingsDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SpawnSpiderlings, SpirderlingsTarget)
        return
    end

    SpinWebDesire, SpinWebLocation = X.ConsiderSpinWeb()
    if SpinWebDesire > 0
    then
        if DotaTime() - LastWebTime > WebGapTime then
            bot:Action_UseAbilityOnLocation(SpinWeb, SpinWebLocation)
            LastWebTime = DotaTime()
        end
        return
    end

    -- SilkenBolaDesire, SilkenBolaTarget = X.ConsiderSilkenBola()
    -- if SilkenBolaDesire > 0
    -- then
    --     bot:Action_UseAbilityOnEntity(SilkenBola, SilkenBolaTarget)
    --     return
    -- end

    InsatiableHungerDesire = X.ConsiderInsatiableHunger()
    if InsatiableHungerDesire > 0
    then
        bot:Action_UseAbility(InsatiableHunger)
        return
    end
end

function X.ConsiderInsatiableHunger()
    if not InsatiableHunger:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nAttackRange = bot:GetAttackRange()
    botTarget = Fu.GetProperTarget(bot)

    if Fu.IsInTeamFight(bot, 1200)
	then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and Fu.GetHP(bot) < 0.75
        and bAttacking
        then
			return BOT_ACTION_DESIRE_HIGH
        end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nAttackRange + 150)
        and bAttacking
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
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

    if Fu.IsFarming(bot)
    then
        local nCreeps = bot:GetNearbyCreeps(700, true)

        if nCreeps ~= nil and #nCreeps > 0
        and Fu.GetHP(bot) < 0.4
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
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
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSpinWeb()
    if not SpinWeb:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, SpinWeb:GetCastRange())
    local nRadius = SpinWeb:GetSpecialValueInt('radius')
    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
    local nEnemyTowers = bot:GetNearbyTowers(nCastRange, true)
    botTarget = Fu.GetProperTarget(bot)

    if Fu.IsStuck(bot)
    and not DoesLocationHaveWeb(bot:GetLocation(), nRadius)
	then
		return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
	end

    if Fu.IsInTeamFight(bot, 1200)
	then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius / 1.7)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
        and not DoesLocationHaveWeb(nLocationAoE.targetloc, nRadius)
        and not Fu.IsLocationInChrono(nLocationAoE.targetloc)
        and not Fu.IsLocationInBlackHole(nLocationAoE.targetloc)
        then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
	end

    if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not DoesLocationHaveWeb(botTarget:GetLocation(), nRadius)
        and not Fu.IsLocationInChrono(botTarget:GetLocation())
        and not Fu.IsLocationInBlackHole(botTarget:GetLocation())
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            end
		end
	end

    if bRetreating
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 600)
        and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not DoesLocationHaveWeb(bot:GetLocation(), nRadius)
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (bot:WasRecentlyDamagedByAnyHero(1.5)))
            then
		        return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            end
        end
    end

    if Fu.IsPushing(bot)
	then
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and not DoesLocationHaveWeb(Fu.GetCenterOfUnits(nEnemyLaneCreeps), nRadius)
        then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end

		if nEnemyTowers ~= nil and #nEnemyTowers >= 1
        and Fu.CanBeAttacked(nEnemyTowers[1])
        and not DoesLocationHaveWeb(nEnemyTowers[1]:GetLocation(), nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH, nEnemyTowers[1]:GetLocation()
		end
	end

    if Fu.IsLaning(bot)
    then
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and not DoesLocationHaveWeb(Fu.GetCenterOfUnits(nEnemyLaneCreeps), nRadius)
        then
			return BOT_MODE_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end
	end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and not DoesLocationHaveWeb(botTarget:GetLocation(), nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and not DoesLocationHaveWeb(botTarget:GetLocation(), nRadius)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- function X.ConsiderSilkenBola()
-- 	if not SilkenBola:IsFullyCastable()
--     then
-- 		return BOT_ACTION_DESIRE_NONE, nil
-- 	end

-- 	local nCastRange = SilkenBola:GetCastRange()
--     local nDamage = SilkenBola:GetSpecialValueInt('impact_damage')
--     botTarget = Fu.GetProperTarget(bot)

--     local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
--     for _, enemyHero in pairs(nEnemyHeroes)
--     do
--         if Fu.IsValidHero(enemyHero)
--         and Fu.CanCastOnNonMagicImmune(enemyHero)
--         and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
--         and not Fu.IsSuspiciousIllusion(enemyHero)
--         and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
--         and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
--         and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
--         and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
--         and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
--         then
--             return BOT_ACTION_DESIRE_HIGH, enemyHero
--         end
--     end

--     if bGoingOnSomeone
-- 	then
-- 		if Fu.IsValidTarget(botTarget)
--         and Fu.IsInRange(bot, botTarget, nCastRange)
--         and not Fu.IsSuspiciousIllusion(botTarget)
--         and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
--         and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
--         and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
--         and not botTarget:HasModifier('modifier_oracle_false_promise_timer')
-- 		then
--             local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
--             local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

--             if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
--             and #nInRangeAlly >= #nInRangeEnemy
--             then
--                 return BOT_ACTION_DESIRE_HIGH, botTarget
--             end
-- 		end
-- 	end

--     if bRetreating
-- 	then
--         local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
--         local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

--         if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
--         and Fu.IsValidHero(nInRangeEnemy[1])
--         and Fu.IsInRange(bot, nInRangeEnemy[1], nCastRange)
--         and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
--         and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
--         and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
--         then
--             local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1200, false, BOT_MODE_NONE)

--             if nTargetInRangeAlly ~= nil
--             and ((#nTargetInRangeAlly > #nInRangeAlly)
--                 or (bot:WasRecentlyDamagedByAnyHero(1.5)))
--             then
-- 		        return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
--             end
--         end
--     end

--     if Fu.IsLaning(bot)
-- 	then
-- 		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

-- 		for _, creep in pairs(nEnemyLaneCreeps)
-- 		do
-- 			if Fu.IsValid(creep)
-- 			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
-- 			and creep:GetHealth() <= nDamage
-- 			then
-- 				local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

-- 				if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
--                 and Fu.GetMP(bot) > 0.49
-- 				then
-- 					return BOT_ACTION_DESIRE_HIGH, creep
-- 				end
-- 			end
-- 		end
-- 	end

--     if Fu.IsDoingRoshan(bot)
-- 	then
-- 		if Fu.IsRoshan(botTarget)
--         and Fu.IsInRange(bot, botTarget, 500)
--         and bAttacking
-- 		then
-- 			return BOT_ACTION_DESIRE_HIGH, botTarget
-- 		end
-- 	end

--     if Fu.IsDoingTormentor(bot)
--     then
--         if Fu.IsTormentor(botTarget)
--         and Fu.IsInRange(bot, botTarget, 500)
--         and bAttacking
--         then
--             return BOT_ACTION_DESIRE_HIGH, botTarget
--         end
--     end

--     local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
--     for _, allyHero in pairs(nAllyHeroes)
--     do
--         local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

--         if Fu.IsValidHero(allyHero)
--         and Fu.IsRetreating(allyHero)
--         and Fu.GetMP(bot) > 0.45
--         and allyHero:WasRecentlyDamagedByAnyHero(1.5)
--         and not allyHero:IsIllusion()
--         then
--             if nAllyInRangeEnemy ~= nil and #nAllyInRangeEnemy >= 1
--             and Fu.IsValidHero(nAllyInRangeEnemy[1])
--             and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
--             and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
--             and Fu.IsInRange(bot, nAllyInRangeEnemy[1], nCastRange)
--             and Fu.IsChasingTarget(nAllyInRangeEnemy[1], allyHero)
--             and not Fu.IsDisabled(nAllyInRangeEnemy[1])
--             and not Fu.IsTaunted(nAllyInRangeEnemy[1])
--             and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
--             and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
--             and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
--             and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
--             and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
--             then
--                 return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
--             end
--         end
--     end

-- 	return BOT_ACTION_DESIRE_NONE, nil
-- end

function X.ConsiderSpawnSpiderlings()
	if not SpawnSpiderlings:IsFullyCastable()
    then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, SpawnSpiderlings:GetCastRange())
	local nDamage = SpawnSpiderlings:GetSpecialValueInt('damage')

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
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
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
    end

    local nCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
    for _, creep in pairs(nCreeps)
    do
        if Fu.IsValid(creep)
        and Fu.CanBeAttacked(creep)
        and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
        and not bRetreating
        then
            return BOT_ACTION_DESIRE_HIGH, creep
        end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

-- Helper Funcs
function DoesLocationHaveWeb(loc, nRadius)
	for _, u in pairs (GetUnitList(UNIT_LIST_ALLIES))
	do
		if Fu.IsValid(u)
        and u:GetUnitName() == 'npc_dota_broodmother_web'
        and GetUnitToLocationDistance(u, loc) < nRadius
		then
			return true
		end
	end

	return false
end

return X