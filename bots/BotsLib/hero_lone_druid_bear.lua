local X = {}
local bear = GetBot()

local Utils = require( GetScriptDirectory()..'/FuncLib/systems/utils' )
local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )

if Utils.GetLoneDruid(bear).bear == nil or not Utils.GetLoneDruid(bear).bear:IsAlive() then Utils.GetLoneDruid(bear).bear = bear end
bear.assignedRole = Utils.GetLoneDruid(bear).hero.assignedRole -- math.min(1, Utils['LoneDruid'].hero.assignedRole - 1)
bear.isBear = true

local sTalentList = Fu.Skill.GetTalentList( bear )
local sAbilityList = Fu.Skill.GetAbilityList( bear )
local sRole = Fu.Item.GetRoleItemsBuyList( bear )

local tTalentTreeList = {--pos2
                        ['t25'] = {0, 10},
                        ['t20'] = {0, 10},
                        ['t15'] = {0, 10},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
                        {1,2,1,2,1,6,1,2,2,3,6,3,3,3,6},--pos2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = { }

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

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

-- Ability usage logic
local abilityQ = bear:GetAbilityByName(sAbilityList[1])
local SavageRoar = bear:GetAbilityByName('lone_druid_savage_roar_bear')

local castQDesire
local castSavageRoarDesire

local hEnemyList, hAllyList, botTarget, distanceFromHero

function X.SkillsComplement()

    if Fu.CanNotUseAbility(bear) or bear:IsInvisible() then return end

    botTarget = Fu.GetProperTarget(Utils.GetLoneDruid(bear).hero)
    if botTarget ~= nil then bear:SetTarget(botTarget) end
    botTarget = Fu.GetProperTarget(bear)

    distanceFromHero = GetUnitToUnitDistance(Utils.GetLoneDruid(bear).hero, bear)

    -- hEnemyList = Fu.GetNearbyHeroes(bear, 1600, true, BOT_MODE_NONE)
    -- hAllyList = Fu.GetNearbyHeroes(bear, 1600, false, BOT_MODE_NONE)

    castQDesire = X.ConsiderQ()
    if castQDesire > 0 then
        bear:Action_UseAbility(abilityQ)
        return
    end

    castSavageRoarDesire = X.ConsiderSavageRoar()
    if castSavageRoarDesire > 0 then
        bear:Action_UseAbility(SavageRoar)
        return
    end

end

function X.ConsiderQ()
    if not abilityQ:IsFullyCastable() then return 0 end
    if not Utils.GetLoneDruid(bear).hero:IsAlive() then return 0 end

    if Fu.GetHP(bear) < 0.9 and bear:DistanceFromFountain() < 450 then return 0 end

    -- too far from hero
    if distanceFromHero > 3000
    and Fu.GetHP(bear) > 0.25
    and not Fu.IsRetreating(bear)
    and not Fu.Item.HasItem( bear, 'item_ultimate_scepter' ) then
        return BOT_ACTION_DESIRE_HIGH
    end

    -- hero is being attacked
    if Utils.GetLoneDruid(bear).hero:WasRecentlyDamagedByAnyHero(2)
    and Fu.GetHP(Utils.GetLoneDruid(bear).hero) < 0.9
    and Fu.GetHP(bear) > 0.25
    and not Fu.IsRetreating(bear)
    and distanceFromHero > 3000 then
        local nInRangeEnemy = Fu.GetNearbyHeroes(Utils.GetLoneDruid(bear).hero, 1000, true, BOT_MODE_NONE)
        if #nInRangeEnemy >= 1 then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSavageRoar()
    if not SavageRoar:IsFullyCastable() then return 0 end

    local nRadius = SavageRoar:GetSpecialValueInt('radius')
    local nInRangeEnemy = Fu.GetNearbyHeroes(bear, nRadius, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(nInRangeEnemy) do
		if Fu.IsValidTarget(enemyHero)
        -- and Fu.IsInRange(bear, enemyHero, nRadius)
        and (Fu.IsChasingTarget(enemyHero, bear)
            or Fu.IsAttacking(enemyHero)
            or Fu.IsMoving(enemyHero)
            or enemyHero:IsChanneling()
            or enemyHero:IsUsingAbility())
        and not Fu.IsSuspiciousIllusion(enemyHero)
        and not Fu.IsDisabled(enemyHero)
        and Fu.CanCastOnNonMagicImmune( enemyHero )
        and Fu.CanCastOnTargetAdvanced( enemyHero )
		then
            return BOT_ACTION_DESIRE_HIGH
		end
    end

    if Fu.IsGoingOnSomeone(bear)
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bear, botTarget, nRadius)
        and not Fu.IsSuspiciousIllusion(botTarget)
		then
            return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingRoshan(bear)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bear, botTarget, 500)
        and Fu.IsAttacking(bear)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bear)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bear, botTarget, 500)
        and Fu.IsAttacking(bear)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

return X