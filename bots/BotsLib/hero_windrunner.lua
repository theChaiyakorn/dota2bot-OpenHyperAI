local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        {--pos1
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos2
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos3
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,6,2,3,3,3,1,6,1,1,6},--pos1
                        {2,3,2,1,2,6,2,3,3,3,1,6,1,1,6},--pos2
                        {2,3,2,1,2,6,2,3,3,3,6,1,1,1,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_1"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
elseif sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
else
    nAbilityBuildList   = tAllAbilityBuildList[3]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[3])
end

local sUtility = {"item_heavens_halberd", "item_nullifier"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_magic_wand",
    "item_double_bracer",
    "item_power_treads",
    "item_maelstrom",
    "item_dragon_lance",
    "item_black_king_bar",--
    "item_mjollnir",--
    "item_greater_crit",--
    "item_ultimate_scepter",
    "item_force_staff",
    "item_hurricane_pike",--
    "item_travel_boots",
    "item_monkey_king_bar",--
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_bottle",
    "item_magic_wand",
    "item_double_bracer",
    "item_power_treads",
    "item_maelstrom",
    "item_dragon_lance",
    "item_black_king_bar",--
    "item_mjollnir",--
    "item_greater_crit",--
    "item_ultimate_scepter",
    "item_sheepstick",--
    "item_travel_boots",
    "item_monkey_king_bar",--
    "item_ultimate_scepter_2",
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_double_circlet",

    "item_magic_wand",
    "item_double_bracer",
    "item_power_treads",
    "item_maelstrom",
    "item_black_king_bar",--
    "item_ultimate_scepter",
    nUtility,--
    "item_mjollnir",--
    "item_sheepstick",--
    "item_travel_boots",
    "item_ultimate_scepter_2",
    "item_monkey_king_bar",--
    "item_travel_boots_2",--
    "item_aghanims_shard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']


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

local ShackleShot   = bot:GetAbilityByName('windrunner_shackleshot')
local Powershot     = bot:GetAbilityByName('windrunner_powershot')
local Windrun       = bot:GetAbilityByName('windrunner_windrun')
local GaleForce     = bot:GetAbilityByName('windrunner_gale_force')
local FocusFire     = bot:GetAbilityByName('windrunner_focusfire')

local ShackleShotDesire, ShackleShotTarget
local PowershotDesire, PowershotLocation
local WindrunDesire
local GaleForceDesire, GaleForceLocation
local FocusFireDesire, FocusFireTarget

local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotMP
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = Fu.GetMP(bot)

    botTarget = Fu.GetProperTarget(bot)

    ShackleShotDesire, ShackleShotTarget = X.ConsiderShackleShot()
    if ShackleShotDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(ShackleShot, ShackleShotTarget)
        return
    end

    FocusFireDesire, FocusFireTarget = X.ConsiderFocusFire()
    if FocusFireDesire > 0
    then
        bot:Action_UseAbilityOnEntity(FocusFire, FocusFireTarget)
        return
    end

    PowershotDesire, PowershotLocation = X.ConsiderPowershot()
    if PowershotDesire > 0
    then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(Powershot, PowershotLocation)
        return
    end

    WindrunDesire = X.ConsiderWindrun()
    if WindrunDesire > 0
    then
        bot:Action_UseAbility(Windrun)
        return
    end

    GaleForceDesire, GaleForceLocation = X.ConsiderGaleForce()
    if GaleForceDesire > 0
    then
        bot:Action_UseAbilityOnLocation(GaleForce, GaleForceLocation)
        return
    end
end

function X.ConsiderShackleShot()
    if not Fu.CanCastAbility(ShackleShot)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ShackleShot:GetCastRange())
    local nRadius = ShackleShot:GetSpecialValueInt('shackle_distance')
    local nAngle = ShackleShot:GetSpecialValueInt('shackle_angle')
    local nStunDuration = ShackleShot:GetSpecialValueFloat('stun_duration')

    local tAllyHeroes = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

	for _, enemyHero in pairs(tEnemyHeroes)
    do
		if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and enemyHero:IsChanneling()
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero
		end
	end

	if bGoingOnSomeone
	then
        local target = nil
        local targetAttackDamage = 0

        for _, enemy in pairs(tEnemyHeroes) do
            if Fu.IsValidTarget(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and not Fu.IsDisabled(enemy)
            and not enemy:HasModifier('modifier_enigma_black_hole_pull')
            and not enemy:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local enemyAttackDamge = enemy:GetAttackDamage() * enemy:GetAttackSpeed()
                if enemyAttackDamge > targetAttackDamage then
                    target = enemy
                    targetAttackDamage = enemyAttackDamge
                end
            end
        end

        if target then
            local tAllyHeroes_attacking = Fu.GetSpecialModeAllies(bot, 900, BOT_MODE_ATTACK)
            if Fu.IsChasingTarget(bot, target) and #tAllyHeroes_attacking >= 2
            or bAttacking and bot:GetEstimatedDamageToTarget(true, target, nStunDuration, DAMAGE_TYPE_ALL) > target:GetHealth() then
                local target__ = X.GetShackleTarget(bot, target, nRadius, nAngle)
                if target__ then
                    return BOT_ACTION_DESIRE_HIGH, target__
                end
            end
        end
	end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
	then
        for _, enemyHero in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsDisabled(enemyHero)
            and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
            then
                local target = X.GetShackleTarget(bot, enemyHero, nRadius, nAngle)
                if target ~= nil
                then
                    return BOT_ACTION_DESIRE_HIGH, target
                end
            end
        end
	end

	--打断
	for _, npcEnemy in pairs( tEnemyHeroes )
	do
		if Fu.IsValid( npcEnemy )
			and (npcEnemy:IsChanneling() or npcEnemy:HasModifier( 'modifier_teleporting' ) )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy
		end
	end

    for _, allyHero in pairs(tAllyHeroes)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsRetreating(allyHero)
        and nBotMP > 0.45
        and allyHero:WasRecentlyDamagedByAnyHero(3.0)
        and not Fu.IsRealInvisible(bot)
        and not allyHero:IsIllusion()
        then
            local tAllyInRangeEnemy = allyHero:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
            for _, enemyHero in pairs(tAllyInRangeEnemy) do
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.CanCastOnTargetAdvanced(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and Fu.IsChasingTarget(enemyHero, allyHero)
                and not Fu.IsDisabled(enemyHero)
                and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
                and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    local target = X.GetShackleTarget(bot, enemyHero, nRadius, nAngle)
                    if target ~= nil
                    then
                        return BOT_ACTION_DESIRE_HIGH, target
                    end
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderPowershot()
    if not Fu.CanCastAbility(Powershot)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Powershot:GetCastRange()
    local nCastPoint = Powershot:GetCastPoint()
	local nRadius = Powershot:GetSpecialValueInt('arrow_width')
	local nSpeed = Powershot:GetSpecialValueInt('arrow_speed')
    local nDamage = Powershot:GetSpecialValueInt('powershot_damage')
	local nAttackRange = bot:GetAttackRange()
    local botMP = nBotMP

    local tAllyHeroes = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(tEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not Fu.IsInRange(bot, enemyHero, nAttackRange - 100)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(enemyHero, eta)
        end
    end

	if bGoingOnSomeone
	then
        if Fu.IsValidHero(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsInRange(bot, botTarget, nAttackRange)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
        then
            local eta = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint

            if bot:GetLevel() < 6 then
                if Fu.CanKillTarget(botTarget, nDamage + bot:GetAttackDamage() * 3, DAMAGE_TYPE_ALL) then
                    return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(botTarget, eta)
                end
            else
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCorrectLoc(botTarget, eta)
            end
        end
	end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
        local tEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
        if Fu.IsValid(tEnemyLaneCreeps[1])
        and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
        and not Fu.IsRunning(tEnemyLaneCreeps[1])
        and botMP > 0.45 then
            local nLocationAoE = bot:FindAoELocation(true, false, tEnemyLaneCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
            if nLocationAoE.count >= 4 then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end

        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        if nLocationAoE.count >= 2
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
	end

    if Fu.IsFarming(bot)
    then
        if bAttacking
        then
            local tCreeps = bot:GetNearbyCreeps(1600, true)
            if Fu.IsValid(tCreeps[1])
            and Fu.CanBeAttacked(tCreeps[1])
            and not Fu.IsRunning(tCreeps[1])
            and botMP > 0.33 then
                local nLocationAoE = bot:FindAoELocation(true, false, tCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
                if nLocationAoE.count >= 3 or nLocationAoE.count >= 1 and tCreeps[1]:IsAncientCreep() then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
    end

    if Fu.IsLaning(bot)
    and (Fu.IsCore(bot) or (not Fu.IsCore(bot) and not Fu.IsThereNonSelfCoreNearby(1200)))
	then
        local canKill = 0
        local creepList = {}
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)

		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep) or Fu.IsKeyWordUnit('flagbearer', creep))
            and creep:GetHealth() > bot:GetAttackDamage()
			and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			then
				if nBotMP > 0.3
                and Fu.CanBeAttacked(creep)
                and not Fu.IsRunning(creep)
				then
                    if Fu.IsValidHero(tEnemyHeroes[1])
                    and not Fu.IsSuspiciousIllusion(tEnemyHeroes[1])
                    and not Fu.IsDisabled(tEnemyHeroes[1])
                    and not bot:WasRecentlyDamagedByTower(1)
                    and GetUnitToUnitDistance(creep, tEnemyHeroes[1]) < tEnemyHeroes[1]:GetAttackRange()
                    then
                        return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
                    end
				end
			end

            if Fu.IsValid(creep)
            and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
            then
                if #creepList >  0 then
                    if Fu.IsInRange(creep, creepList[1], nRadius) then
                        table.insert(creepList, creep)
                    end
                else
                    table.insert(creepList, creep)
                end
            end
		end

        if #creepList >= 3
        and nBotMP > 0.25
        and Fu.CanBeAttacked(creepList[1])
        and not Fu.IsRunning(creepList[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(creepList)
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderWindrun()
    if not Fu.CanCastAbility(Windrun)
    or bot:HasModifier('modifier_windrunner_windrun')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local botManaAfter = Fu.GetManaAfter(Windrun:GetManaCost())
    local tAllyHeroes = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            if (Fu.IsChasingTarget(bot, botTarget)
                and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
                and (botTarget:GetCurrentMovementSpeed() > bot:GetCurrentMovementSpeed() + 10))
            or (bot:WasRecentlyDamagedByAnyHero(1.5) and X.IsBeingAttackedByRealHero(bot))
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
	then
        if Fu.IsValidHero(tEnemyHeroes[1])
        and Fu.CanBeAttacked(bot)
        and Fu.IsChasingTarget(tEnemyHeroes[1], bot)
        and not Fu.IsSuspiciousIllusion(tEnemyHeroes[1])
        and not Fu.IsDisabled(tEnemyHeroes[1])
        and (bot:WasRecentlyDamagedByAnyHero(2.0) and X.IsBeingAttackedByRealHero(bot))
        then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if Fu.IsLaning(bot)
	then
		if botManaAfter > 0.8
		and not bot:HasModifier('modifier_fountain_aura_buff')
		and Fu.IsInLaningPhase()
		and #tEnemyHeroes == 0
		then
			local nLane = bot:GetAssignedLane()
			local nLaneFrontLocation = GetLaneFrontLocation(GetTeam(), nLane, 0)
			if GetUnitToLocationDistance(bot, nLaneFrontLocation) > 800 then
                return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
        then
            if Fu.GetHP(bot) < 0.5
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
        then
            if Fu.GetHP(bot) < 0.5
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderFocusFire()
    if not Fu.CanCastAbility(FocusFire)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, FocusFire:GetCastRange())
	local nDamageReduction = 1 + (FocusFire:GetSpecialValueInt('focusfire_damage_reduction') / 100)
    local nDuration = FocusFire:GetDuration()
	local nDamage = bot:GetAttackDamage()

    local tAllyHeroes = Fu.GetNearbyHeroes(bot,1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(tEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and not Fu.IsInEtherealForm(enemyHero)
        and enemyHero:GetHealth() > bot:GetAttackDamage() * 2
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanKillTarget(enemyHero, (nDamage * nDuration) * nDamageReduction, DAMAGE_TYPE_PHYSICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not enemyHero:HasModifier('modifier_item_aeon_disk_buff')
        and not enemyHero:HasModifier('modifier_item_blade_mail_reflect')
        then
            if Fu.WeAreStronger(bot, 1600) then
                bot:SetTarget(enemyHero)
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
    end

	if bGoingOnSomeone
	then
        for _, enemyHero in pairs(tEnemyHeroes)
        do
            if Fu.IsValidTarget(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and not Fu.IsInEtherealForm(enemyHero)
            and enemyHero:GetHealth() > bot:GetAttackDamage() * 3
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_item_aeon_disk_buff')
            and not enemyHero:HasModifier('modifier_item_blade_mail_reflect')
            then
                bot:SetTarget(enemyHero)
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
	end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.GetHP(botTarget) > 0.25
        and bAttacking
        and not botTarget:HasModifier('modifier_roshan_spell_block')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and Fu.GetHP(botTarget) > 0.3
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderGaleForce()
    if not Fu.CanCastAbility(GaleForce)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, GaleForce:GetCastRange())
    local nRadius = GaleForce:GetSpecialValueInt('radius')
    local nCastPoint = GaleForce:GetCastPoint()

    if bGoingOnSomeone
    then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange + nRadius, nRadius, nCastPoint, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)

        if #nInRangeEnemy >= 2
        and not Fu.IsEnemyChronosphereInLocation(nLocationAoE.targetloc)
        and not Fu.IsEnemyBlackHoleInLocation(nLocationAoE.targetloc)
        then
            return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
        end
    end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    then
        local tEnemyHeroes = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(tEnemyHeroes)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, 800)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetAlliesNearLoc(enemyHero:GetLocation(), 1200)
                local nInRangeEnemy = Fu.GetEnemiesNearLoc(enemyHero:GetLocation(), 1200)

                if #nInRangeEnemy > #nInRangeAlly and bot:WasRecentlyDamagedByAnyHero(3.0)
                then
                    return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + Fu.GetCenterOfUnits(nInRangeEnemy)) / 2
                end
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

-- Helper Funcs
function X.GetShackleCreepTarget(hSource, hTarget, nRadius, nMaxAngle)
	local nCreeps = hTarget:GetNearbyCreeps(nRadius, false)
	for _, creep in pairs(nCreeps)
    do
        if Fu.IsValid(creep)
        then
            local angle = X.GetAngleWithThreeVectors(hSource:GetLocation(), creep:GetLocation(), hTarget:GetLocation())

            if angle <= nMaxAngle then
                return creep
            end
        end
	end

	return nil
end

function X.GetShackleHeroTarget(hSource, hTarget, nRadius, nMaxAngle)
	local nEnemyHeroes = hTarget:GetNearbyHeroes(nRadius, false, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and enemyHero ~= hTarget
        then
            local angle = X.GetAngleWithThreeVectors(hSource:GetLocation(), enemyHero:GetLocation(), hTarget:GetLocation())

            if angle <= nMaxAngle then
                return enemyHero
            end
        end
	end

	return nil
end

function X.CanShackleToCreep(hSource, hTarget, nRadius, nMaxAngle)
	local nCreeps = hTarget:GetNearbyCreeps(nRadius, false)
	for _, creep in pairs(nCreeps)
    do
        if Fu.IsValid(creep)
        then
            local angle = X.GetAngleWithThreeVectors(hSource:GetLocation(), hTarget:GetLocation(), creep:GetLocation())
            if angle <= nMaxAngle then
                return true
            end
        end
	end

	return false
end

function X.CanShackleToHero(hSource, hTarget, nRadius, nMaxAngle)
	local nEnemyHeroes = Fu.GetEnemiesNearLoc(hTarget:GetLocation(), nRadius)

    -- real
	for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and enemyHero ~= hTarget
        then
            local angle = X.GetAngleWithThreeVectors(hSource:GetLocation(), hTarget:GetLocation(), enemyHero:GetLocation())
            if angle <= nMaxAngle then
                return true
            end
        end
	end

    -- include illusions
    nEnemyHeroes = hTarget:GetNearbyHeroes(nRadius, false, BOT_MODE_NONE)
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if Fu.IsValidHero(enemyHero)
        and enemyHero ~= hTarget
        then
            local angle = X.GetAngleWithThreeVectors(hSource:GetLocation(), hTarget:GetLocation(), enemyHero:GetLocation())
            if angle <= nMaxAngle then
                return true
            end
        end
	end

	return false
end

function X.CanShackleToTree(hSource, hTarget, nRadius, nMaxAngle)
	local nTrees = hTarget:GetNearbyTrees(nRadius)
	for _, tree in pairs(nTrees) do
        if tree then
            local angle = X.GetAngleWithThreeVectors(hSource:GetLocation(), hTarget:GetLocation(), GetTreeLocation(tree))
            if angle <= nMaxAngle then
                return true
            end
        end
	end

	return false
end

function X.GetShackleTarget(hSource, hTarget, nRadius, nMaxAngle)
	local sTarget = nil

    if X.CanShackleToHero(hSource, hTarget, nRadius, nMaxAngle)
    or X.CanShackleToTree(hSource, hTarget, nRadius, nMaxAngle)
    or X.CanShackleToCreep(hSource, hTarget, nRadius, nMaxAngle) then
        sTarget = hTarget
    else
        sTarget = X.GetShackleCreepTarget(hSource, hTarget, nRadius, nMaxAngle)

		if sTarget == nil then
			sTarget = X.GetShackleHeroTarget(hSource, hTarget, nRadius, nMaxAngle)
		end
    end

	return sTarget
end

function X.GetAngleWithThreeVectors(A, B, C)
    local CA = Vector(C.x - A.x, C.y - A.y, C.z - A.z)
    local CB = Vector(C.x - B.x, C.y - B.y, C.z - B.z)

    local magCA = math.sqrt(CA.x^2 + CA.y^2 + CA.z^2)
    local magCB = math.sqrt(CB.x^2 + CB.y^2 + CB.z^2)

    local dot = CA.x * CB.x + CA.y * CB.y + CA.z * CB.z

    return (math.acos(dot / (magCA * magCB))) * (180 / math.pi)
end

function X.IsBeingAttackedByRealHero(unit)
    for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMIES))
    do
        if Fu.IsValidHero(enemy)
        and not Fu.IsSuspiciousIllusion(enemy)
        and (enemy:GetAttackTarget() == unit or Fu.IsChasingTarget(enemy, unit))
        then
            return true
        end
    end

    return false
end

return X