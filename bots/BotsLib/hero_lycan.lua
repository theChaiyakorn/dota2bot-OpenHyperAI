local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
                        {1,3,1,3,1,6,1,3,3,2,2,6,2,2,6},--pos1,2
						{1,3,1,2,1,6,1,3,3,3,6,2,2,2,6},--pos3
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_1' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_2' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_3' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)
if sRole == 'pos_1' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList) end
if sRole == 'pos_2' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList) end
if sRole == 'pos_3' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList) end

local sUtility = {"item_pipe", "item_lotus_orb", "item_heavens_halberd", "item_crimson_guard"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_double_circlet",

    "item_magic_wand",
    "item_double_bracer",
    "item_power_treads",
    "item_ring_of_basilius",
    "item_echo_sabre",
    "item_manta",--
    "item_aghanims_shard",
    "item_harpoon",--
	"item_orchid",
    "item_black_king_bar",--
    "item_bloodthorn",--
    "item_skadi",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_double_circlet",

    "item_bottle",
    "item_magic_wand",
    "item_double_bracer",
    "item_power_treads",
    "item_ring_of_basilius",
    "item_echo_sabre",
    "item_manta",--
    "item_aghanims_shard",
    "item_harpoon",--
    "item_black_king_bar",--
	"item_orchid",
    "item_bloodthorn",--
    "item_travel_boots",
    "item_skadi",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_quelling_blade",

    "item_magic_wand",
    "item_helm_of_the_dominator",
    "item_ring_of_basilius",
    "item_helm_of_the_overlord",--
    "item_vladmir",--
    "item_ancient_janggo",
    "item_aghanims_shard",
    "item_assault",--
    nUtility,--
    "item_travel_boots",
    "item_sheepstick",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

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
    Minion.MinionThink(hMinionUnit)
end

local SummonWolves  = SafeAbility(bot:GetAbilityByName('lycan_summon_wolves'), 'lycan_summon_wolves', 'lycan')
local Howl          = SafeAbility(bot:GetAbilityByName('lycan_howl'), 'lycan_howl', 'lycan')
local FeralImpulse  = SafeAbility(bot:GetAbilityByName('lycan_feral_impulse'), 'lycan_feral_impulse', 'lycan')
local WoflBite      = SafeAbility(bot:GetAbilityByName('lycan_wolf_bite'), 'lycan_wolf_bite', 'lycan')
local ShapeShift    = SafeAbility(bot:GetAbilityByName('lycan_shapeshift'), 'lycan_shapeshift', 'lycan')

local SummonWolvesDesire
local HowlDesire
local WoflBiteDesire, WoflBiteTarget
local ShapeShiftDesire

local botTarget
local bGoingOnSomeone
local bAttacking
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bAttacking = Fu.IsAttacking(bot)

    ShapeShiftDesire = X.ConsiderShapeShift()
    if ShapeShiftDesire > 0
    then
        bot:Action_UseAbility(ShapeShift)
        return
    end

    HowlDesire = X.ConsiderHowl()
    if HowlDesire > 0
    then
        bot:Action_UseAbility(Howl)
        return
    end

    SummonWolvesDesire = X.ConsiderSummonWolves()
    if SummonWolvesDesire > 0
    then
        bot:Action_UseAbility(SummonWolves)
        return
    end

    -- WoflBiteDesire, WoflBiteTarget = X.ConsiderWoflBite()
end

function X.ConsiderSummonWolves()
    if not SummonWolves:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    for _, unit in pairs(GetUnitList(UNIT_LIST_ALLIES))
    do
        if Fu.IsValid(unit)
        and string.find( unit:GetUnitName(), "npc_dota_lycan_wolf" )
        then
            return BOT_ACTION_DESIRE_NONE
        end
    end

    botTarget = Fu.GetProperTarget(bot)

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot) or Fu.IsLaning(bot))
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(800, true)

        if bAttacking
        then
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 1
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyTowers = bot:GetNearbyTowers(600, true)
            if nEnemyTowers ~= nil and #nEnemyTowers >= 1
            and Fu.CanBeAttacked(nEnemyTowers[1])
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
	end

    if Fu.IsFarming(bot)
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(600)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(600, true)

        if bAttacking
        then
            if (nNeutralCreeps ~= nil and #nNeutralCreeps >= 2)
            or (nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
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

function X.ConsiderHowl()
    if not Howl:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local timeOfDay = Fu.CheckTimeOfDay()
    botTarget = Fu.GetProperTarget(bot)

    if timeOfDay == 'night'
    then
        for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES))
        do
            if Fu.IsValidHero(allyHero)
            and not allyHero:IsIllusion()
            then
                if Fu.IsCore(allyHero)
                and Fu.IsGoingOnSomeone(allyHero)
                then
                    local allyTarget = allyHero:GetAttackTarget()

                    if Fu.IsValidTarget(allyTarget)
                    and Fu.IsInRange(bot, allyTarget, allyHero:GetAttackRange())
                    and allyHero:IsFacingLocation(allyTarget:GetLocation(), 30)
                    and Fu.IsAttacking(allyHero)
                    and not Fu.IsSuspiciousIllusion(allyTarget)
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end
        end

        local nTeamFightLocation = Fu.GetTeamFightLocation(bot)

        if nTeamFightLocation ~= nil
        then
            if GetUnitToLocationDistance(bot, nTeamFightLocation) > 1600
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bGoingOnSomeone
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsRetreating(bot)
	then
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,800, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
        and ((#nInRangeEnemy > #nInRangeAlly)
            or (Fu.GetHP(bot) < 0.75 and bot:WasRecentlyDamagedByAnyHero(1.7)))
        and Fu.IsValidHero(nInRangeEnemy[1])
        and Fu.IsInRange(bot, nInRangeEnemy[1], 450)
        and bot:IsFacingLocation(Fu.GetEscapeLoc(), 30)
        and nInRangeEnemy[1]:IsFacingLocation(bot:GetLocation(), 30)
        and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
        and not Fu.IsDisabled(nInRangeEnemy[1])
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	then
		local nEnemyLaneCreeps = bot:GetNearbyCreeps(600, true)

        if bAttacking
        then
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 2
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyTowers = bot:GetNearbyTowers(600, true)
            if nEnemyTowers ~= nil and #nEnemyTowers >= 1
            and Fu.CanBeAttacked(nEnemyTowers[1])
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end

        -- Buff allies during push even before engaging
        local nNearbyAllies = Fu.GetNearbyHeroes(bot, 900, false, BOT_MODE_NONE)
        if nNearbyAllies ~= nil and #nNearbyAllies >= 2
        and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 1
        then
            return BOT_ACTION_DESIRE_MODERATE
        end
	end

    if Fu.IsFarming(bot)
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(300)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(600, true)

        if bAttacking
        then
            if (nNeutralCreeps ~= nil and #nNeutralCreeps >= 2)
            or (nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
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

function X.ConsiderShapeShift()
    if not ShapeShift:IsFullyCastable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if Fu.IsInTeamFight(bot, 1000)
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    if bGoingOnSomeone then
        botTarget = Fu.GetProperTarget(bot)
        local nInRangeAlly = Fu.GetNearbyHeroes(bot,1200, false, BOT_MODE_NONE)
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1200, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, 800)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and nInRangeAlly ~= nil and nInRangeEnemy
        and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
    end

    -- Chase fleeing enemies: use Shapeshift speed to close the gap
    local nNearbyEnemies = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE)
    if nNearbyEnemies ~= nil and #nNearbyEnemies >= 1
    then
        for _, enemy in pairs(nNearbyEnemies) do
            if Fu.IsValidTarget(enemy)
            and not Fu.IsSuspiciousIllusion(enemy)
            and Fu.GetHP(enemy) < 0.5
            and not enemy:IsFacingLocation(bot:GetLocation(), 60)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    -- Escape: use Shapeshift speed boost to flee when low HP
    if Fu.IsRetreating(bot)
    then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot, 900, true, BOT_MODE_NONE)

        if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
        and Fu.GetHP(bot) < 0.3
        and bot:WasRecentlyDamagedByAnyHero(2.0)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X