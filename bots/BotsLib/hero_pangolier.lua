local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos2
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },--pos3
                        {
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        }
}

local tAllAbilityBuildList = {
						{2,1,2,1,1,6,1,2,2,3,6,3,3,3,6},--pos2
                        {2,1,3,2,2,6,2,1,1,1,6,3,3,3,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sUtility = {"item_pipe", "item_lotus_orb", "item_heavens_halberd", "item_crimson_guard"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",
    "item_faerie_fire",

    "item_bottle",
    "item_magic_wand",
    "item_arcane_boots",
    "item_diffusal_blade",
    "item_mage_slayer",--
    "item_blink",
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_basher",
    "item_disperser",--
    "item_octarine_core",--
    "item_abyssal_blade",--
    "item_ultimate_scepter_2",
    "item_travel_boots",
    "item_moon_shard",
    "item_overwhelming_blink",--
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
    "item_quelling_blade",
    "item_tango",
    "item_double_branches",

    "item_bracer",
    "item_arcane_boots",
    "item_magic_wand",
    "item_diffusal_blade",
    "item_blink",
    nUtility,--
    "item_mage_slayer",--
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_octarine_core",--
    "item_disperser",--
    "item_ultimate_scepter_2",
    "item_travel_boots",
    "item_moon_shard",
    "item_overwhelming_blink",--
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		Minion.IllusionThink( hMinionUnit )
	end
end

local Swashbuckle       = bot:GetAbilityByName('pangolier_swashbuckle')
local ShieldCrash       = bot:GetAbilityByName('pangolier_shield_crash')
-- local LuckyShot         = bot:GetAbilityByName('pangolier_luckyshot')
local RollUp            = bot:GetAbilityByName('pangolier_rollup')
local EndRollUp         = bot:GetAbilityByName('pangolier_rollup_stop')
local RollingThunder    = bot:GetAbilityByName('pangolier_gyroshell')
local EndRollingThunder    = bot:GetAbilityByName('pangolier_gyroshell_stop')

local SwashbuckleDesire, SwashbuckleLocation
local ShieldCrashDesire
local RollUpDesire
local EndRollUpDesire
local RollingThunderDesire
local EndRollingThunderDesire

local botTarget
local bRetreating
local bAttacking
local nBotHP
local nBotMP
local bInTeamFight
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = Fu.GetHP(bot)
	nBotMP = Fu.GetMP(bot)
	bInTeamFight = Fu.IsInTeamFight(bot, 1200)

    Swashbuckle       = bot:GetAbilityByName('pangolier_swashbuckle')
    ShieldCrash       = bot:GetAbilityByName('pangolier_shield_crash')
    RollUp            = bot:GetAbilityByName('pangolier_rollup')
    EndRollUp         = bot:GetAbilityByName('pangolier_rollup_stop')
    RollingThunder    = bot:GetAbilityByName('pangolier_gyroshell')
    EndRollingThunder = bot:GetAbilityByName('pangolier_gyroshell_stop')

    botTarget = Fu.GetProperTarget(bot)
    local botHP = nBotHP
    local nAllyHeroes = Fu.GetNearbyHeroes(bot, 1600, false, BOT_MODE_NONE)
    local nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE)

    EndRollUpDesire = X.ConsiderEndRollUp()
    if EndRollUpDesire > 0
    then
        bot:Action_UseAbility(EndRollUp)
        return
    end

    RollUpDesire = X.ConsiderRollUp()
    if RollUpDesire > 0
    then
        bot:Action_UseAbility(RollUp)
        return
    end

    EndRollingThunderDesire = X.ConsiderEndRollingThunder()
    if EndRollingThunderDesire > 0
    then
        bot:Action_UseAbility(EndRollingThunder)
        return
    end

    RollingThunderDesire = X.ConsiderRollingThunder()
    if RollingThunderDesire > 0
    then
        bot:Action_UseAbility(RollingThunder)
        return
    end

    ShieldCrashDesire = X.ConsiderShieldCrash()
    if ShieldCrashDesire > 0
    then
        bot:Action_UseAbility(ShieldCrash)
        return
    end

    SwashbuckleDesire, SwashbuckleLocation = X.ConsiderSwashbuckle()
    if SwashbuckleDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Swashbuckle, SwashbuckleLocation)
        return
    end
end

function X.ConsiderSwashbuckle()
    if not Swashbuckle:IsFullyCastable()
    or bot:HasModifier('modifier_pangolier_gyroshell')
    or bot:HasModifier('modifier_pangolier_swashbuckle_stunned')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nDashRange = Swashbuckle:GetSpecialValueInt('dash_range')
    local nSwashRange = Swashbuckle:GetSpecialValueInt('range')
	local nRadius = 140
    local nDamage = Swashbuckle:GetSpecialValueInt('damage')
    local nStrikeCount = Swashbuckle:GetSpecialValueInt('strikes')
    botTarget = Fu.GetProperTarget(bot)

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage * nStrikeCount, DAMAGE_TYPE_PHYSICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
        and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            if bot:IsFacingLocation(enemyHero:GetLocation(), 25)
            then
                if Fu.IsInRange(bot, enemyHero, nDashRange)
                then
                    return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
                end

                if Fu.IsInRange(bot, enemyHero, nDashRange + nSwashRange)
                and not Fu.IsInRange(bot, enemyHero, nDashRange)
                and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, enemyHero:GetLocation(), nDashRange)
                end
            end
        end
    end

	if Fu.IsStuck(bot)
	then
		local loc = Fu.GetEscapeLoc()
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nDashRange)
	end

    if Fu.IsGoingOnSomeone(bot)
    then
        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, 1200)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1000, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        and not weakestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not weakestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not weakestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 800, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            and bot:IsFacingLocation(weakestTarget:GetLocation(), 30)
            then
                if Fu.IsInRange(bot, weakestTarget, nDashRange)
                then
                    if #nInRangeAlly >= #nTargetInRangeAlly + 2
                    then
                        return BOT_ACTION_DESIRE_HIGH, weakestTarget:GetLocation()
                    else
                        return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
                    end
                end

                if Fu.IsInRange(bot, weakestTarget, nDashRange + nSwashRange)
                and not Fu.IsInRange(bot, weakestTarget, nDashRange)
                and not weakestTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, weakestTarget:GetLocation(), nDashRange)
                end
            end
        end
    end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
        and not nInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not nInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1000, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.68 and bot:WasRecentlyDamagedByAnyHero(1.6)))
            then
                local loc = Fu.GetEscapeLoc()
		        return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, loc, nDashRange)
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nSwashRange, nRadius, 0, 0)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nSwashRange, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and nLocationAoE.count >= 4
        and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        and bot:IsFacingLocation(nLocationAoE.targetloc, 10)
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end

        nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nSwashRange, nRadius, 0, 0)
        if nLocationAoE.count >= 1
        and bot:IsFacingLocation(nLocationAoE.targetloc, 10)
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.33
    then
        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nSwashRange, nRadius, 0, 0)

        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nSwashRange)
        if nNeutralCreeps ~= nil
        and ((#nNeutralCreeps >= 3 and nLocationAoE.count >= 3)
            or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep() and nLocationAoE.count >= 2))
        and bot:IsFacingLocation(nLocationAoE.targetloc, 10)
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nSwashRange, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
        and nLocationAoE.count >= 3
        and bot:IsFacingLocation(nLocationAoE.targetloc, 10)
        then
            return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
        end
    end

    if Fu.IsLaning(bot)
    and nBotMP > 0.33
	then
        local canKill = 0
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)
        local nCreepRange = nDashRange + nSwashRange

        if nCreepRange > 1600 then nCreepRange = 1600 end

        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCreepRange, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage * nStrikeCount
            -- and bot:IsFacingLocation(creep:GetLocation(), 10)
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
			-- 	then
            --         if Fu.IsInRange(bot, creep, nDashRange)
            --         then
            --             return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            --         end

            --         if Fu.IsInRange(bot, creep, nDashRange + nSwashRange)
            --         and not Fu.IsInRange(bot, creep, nDashRange)
            --         then
            --             return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, creep:GetLocation(), nDashRange)
            --         end
			-- 	end

            --     nCreepInRangeHero = creep:GetNearbyHeroes(nRadius, false, BOT_MODE_NONE)
            --     if nCreepInRangeHero ~= nil and #nCreepInRangeHero == 1
            --     then
            --         if Fu.IsInRange(bot, creep, nDashRange)
            --         then
            --             return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            --         end
            --     end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage * nStrikeCount
            then
                canKill = canKill + 1
            end
		end

        local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), 1000, nRadius, 0, 0)

        if canKill >= 2
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and nLocationAoE.count >= 2
        and bot:IsFacingLocation(nLocationAoE.targetloc, 15)
        then
            if GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nDashRange
            then
                return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
            end

            if GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nDashRange + nSwashRange
            and not (GetUnitToLocationDistance(bot, nLocationAoE.targetloc) <= nDashRange)
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, nLocationAoE.targetloc, nDashRange)
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and bot:IsFacingLocation(botTarget:GetLocation(), 10)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        and bot:IsFacingLocation(botTarget:GetLocation(), 10)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderShieldCrash()
    if not ShieldCrash:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = ShieldCrash:GetSpecialValueInt('radius')
    local nDamage = ShieldCrash:GetSpecialValueInt('damage')
    local nAbilityLevel = ShieldCrash:GetLevel()
    botTarget = Fu.GetProperTarget(bot)

    if Fu.IsStuck(bot)
	then
		return BOT_ACTION_DESIRE_HIGH
	end

    if bot:HasModifier('modifier_pangolier_rollup')
    then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bInTeamFight
    then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        and not bot:HasModifier('modifier_pangolier_gyroshell')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsGoingOnSomeone(bot)
    then
        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, nRadius)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)

        if Fu.IsValidTarget(weakestTarget)
        and bot:HasModifier('modifier_pangolier_gyroshell')
        and bot:IsFacingLocation(weakestTarget:GetLocation(), 5)
        then
            local vJumpLocation = weakestTarget:GetLocation()
            if IsLocationPassable(vJumpLocation)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end

        if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        and not weakestTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not weakestTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not weakestTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not weakestTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(weakestTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
            and #nInRangeAlly >= #nTargetInRangeAlly
            and bot:IsFacingLocation(weakestTarget:GetLocation(), 30)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not nInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
        and not nInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not nInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
        and not nInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1000, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
                or (nBotHP < 0.68 and bot:WasRecentlyDamagedByAnyHero(1.6)))
            and bot:IsFacingLocation(Fu.GetEscapeLoc(), 30)
            then
		        return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)

        if bAttacking
        then
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
            and bot:IsFacingLocation(nEnemyLaneCreeps[1]:GetLocation(), 30)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsFarming(bot)
    and nBotMP > 0.33
    and nAbilityLevel >= 2
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(nRadius)
            if nNeutralCreeps ~= nil
            and ((#nNeutralCreeps >= 3)
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            and bot:IsFacingLocation(nNeutralCreeps[1]:GetLocation(), 15)
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
            and bot:IsFacingLocation(nEnemyLaneCreeps[1]:GetLocation(), 15)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsLaning(bot)
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			-- if Fu.IsValid(creep)
			-- and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
			-- and creep:GetHealth() <= nDamage
			-- then
			-- 	local nCreepInRangeHero = creep:GetNearbyHeroes(500, false, BOT_MODE_NONE)

			-- 	if nCreepInRangeHero ~= nil and #nCreepInRangeHero >= 1
            --     and nBotMP > 0.33
            --     and bot:IsFacingLocation(creep:GetLocation(), 15)
			-- 	then
			-- 		return BOT_ACTION_DESIRE_HIGH
			-- 	end
			-- end

            if Fu.IsValid(creep)
            and creep:GetHealth() <= nDamage
            then
                if nBotMP > 0.33
                and bot:IsFacingLocation(creep:GetLocation(), 15)
                and not Fu.IsInRange(bot, creep, bot:GetAttackRange())
                and not bAttacking
                then
                    return BOT_ACTION_DESIRE_HIGH
                end

                canKill = canKill + 1
                table.insert(creepList, creep)
            end
		end

        if canKill >= 2
        and nBotMP > 0.25
        and nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and bot:IsFacingLocation(Fu.GetCenterOfUnits(creepList), 15)
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and bot:IsFacingLocation(nInRangeEnemy[1]:GetLocation(), 15)
        and Fu.IsInRange(bot, nInRangeEnemy[1], nRadius)
        then
            local nTargetInRangeTowers = nInRangeEnemy[1]:GetNearbyTowers(700, false)

            if nTargetInRangeTowers ~= nil and #nTargetInRangeTowers == 0
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
        and bot:IsFacingLocation(botTarget:GetLocation(), 15)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and bAttacking
        and bot:IsFacingLocation(botTarget:GetLocation(), 15)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderRollingThunder()
    if not RollingThunder:IsFullyCastable()
    or bot:HasModifier('modifier_bloodseeker_rupture')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bInTeamFight
	then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

        if realEnemyCount ~= nil and #realEnemyCount >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if bRetreating
    then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1000, true, BOT_MODE_NONE)

        if nInRangeAlly ~= nil and nInRangeEnemy
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsRunning(nInRangeEnemy[1])
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        then
            local nTargetInRangeAlly = Fu.GetNearbyHeroes(nInRangeEnemy[1], 1000, false, BOT_MODE_NONE)

            if nTargetInRangeAlly ~= nil
            and ((#nTargetInRangeAlly > #nInRangeAlly)
            and (nBotHP < 0.55 and bot:WasRecentlyDamagedByAnyHero(2)))
            then
		        return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderEndRollingThunder()
    if EndRollingThunder:IsHidden()
    or not EndRollingThunder:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

    if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderRollUp()
    if not RollUp:IsTrained()
    or RollUp:IsHidden()
    or not RollUp:IsFullyCastable()
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

    if bInTeamFight
    then
        local realEnemyCount = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)

        if realEnemyCount ~= nil and #realEnemyCount >= 3
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, 1200)

        if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        then
            if bot:HasModifier('modifier_pangolier_gyroshell')
            and not bot:IsFacingLocation(weakestTarget:GetLocation(), 90)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderEndRollUp()
    if EndRollUp:IsHidden()
    or not EndRollUp:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bInTeamFight
    then
        local weakestTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, 1200)

        if Fu.IsValidTarget(weakestTarget)
        and not Fu.IsSuspiciousIllusion(weakestTarget)
        then
            if bot:HasModifier('modifier_pangolier_roll')
            and bot:IsFacingLocation(weakestTarget:GetLocation(), 15)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X