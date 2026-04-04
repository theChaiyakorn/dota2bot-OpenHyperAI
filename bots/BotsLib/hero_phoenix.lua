local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx    = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {--pos4,5
                        ['t25'] = {0, 10},
                        ['t20'] = {0, 10},
                        ['t15'] = {10, 0},
                        ['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{2,1,2,3,2,6,2,3,3,3,6,1,1,1,6},--pos4,5
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_double_branches",
    "item_blood_grenade",

    "item_boots",
    "item_magic_wand",
    "item_tranquil_boots",
    "item_veil_of_discord",
    "item_aghanims_shard",
    "item_shivas_guard",--
    "item_force_staff",--
    "item_boots_of_bearing",--
    "item_cyclone",
    "item_refresher",--
    "item_sheepstick",--
    "item_wind_waker",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
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
	"item_shivas_guard",--
--	"item_wraith_pact",
    "item_refresher",--
	"item_sheepstick",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}


sRoleItemsBuyList['pos_2'] = {
	"item_bristleback_outfit",
    "item_hand_of_midas",
    "item_radiance",--
	"item_kaya_and_sange",--
    "item_aghanims_shard",
	"item_shivas_guard",--
	"item_heart",--
    "item_ultimate_scepter_2",
    "item_refresher",--
    "item_travel_boots_2",--
    "item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_2']
sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_2']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_heart",--
    "item_hand_of_midas",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local IcarusDive        = bot:GetAbilityByName('phoenix_icarus_dive')
local IcarusDiveStop    = bot:GetAbilityByName('phoenix_icarus_dive_stop')
local FireSpirits       = bot:GetAbilityByName('phoenix_fire_spirits')
local FireSpiritsLaunch = bot:GetAbilityByName('phoenix_launch_fire_spirit')
local SunRay            = bot:GetAbilityByName('phoenix_sun_ray')
local SunRayStop        = bot:GetAbilityByName('phoenix_sun_ray_stop')
local ToggleMovement    = bot:GetAbilityByName('phoenix_sun_ray_toggle_move')
local Supernova         = bot:GetAbilityByName('phoenix_supernova')

local IcarusDiveDesire, IcarusDiveLocation
local IcarusDiveStopDesire
local FireSpiritsDesire
local FireSpiritsLaunchDesire, FireSpiritsLaunchLocation
local SunRayDesire, SunRayLocation
local SunRayStopDesire
local ToggleMovementDesire, State
local SupernovaDesire, SupernovaTarget

local IcarusDiveTime = -1
local IcarusDiveDuration = 2

local FireSpiritsLaunchTime = 0

if bot.sun_ray_target == nil then bot.sun_ray_target = bot end

local botTarget
local bGoingOnSomeone
local bAttacking
local nBotHP
function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = ctx.hp

    FireSpiritsDesire = X.ConsiderFireSpirits()
    if FireSpiritsDesire > 0
    then
        bot:Action_UseAbility(FireSpirits)
        return
    end

    FireSpiritsLaunchDesire, FireSpiritsLaunchLocation, ETA = X.ConsiderFireSpiritsLaunch()
    if FireSpiritsLaunchDesire > 0
    then
        bot:Action_UseAbilityOnLocation(FireSpiritsLaunch, FireSpiritsLaunchLocation)
        FireSpiritsLaunchTime = DotaTime()
        return
    end

    SupernovaDesire, SupernovaTarget, AllyCast = X.ConsiderSupernova()
    if SupernovaDesire > 0
    then
        if string.find(GetBot():GetUnitName(), 'phoenix')
        and bot:HasScepter()
        and AllyCast
        then
            bot:Action_UseAbilityOnEntity(Supernova, SupernovaTarget)
            return
        else
            -- use Fire Spirits before exploding
            if Fu.CanCastAbility(FireSpirits) then
                bot:ActionQueue_UseAbility(FireSpirits)

                local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
                for _, enemy in pairs(tEnemyHeroes) do
                    if Fu.IsValidHero(enemy)
                    and Fu.IsInRange(bot, enemy, FireSpirits:GetCastRange())
                    and Fu.CanCastOnNonMagicImmune(enemy)
                    and not Fu.IsEnemyChronosphereInLocation(enemy:GetLocation())
                    and not Fu.IsEnemyBlackHoleInLocation(enemy:GetLocation())
                    and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
                    and not enemy:HasModifier('modifier_phoenix_fire_spirit_burn') then
                        bot:ActionQueue_UseAbilityOnLocation(FireSpiritsLaunch, enemy:GetLocation())
                    end
                end

                bot:ActionQueue_UseAbility(Supernova)
                return
            else
                bot:Action_UseAbility(Supernova)
                return
            end
        end
    end

    IcarusDiveDesire, IcarusDiveLocation = X.ConsiderIcarusDive()
    if IcarusDiveDesire > 0
    then
        bot:Action_UseAbilityOnLocation(IcarusDive, IcarusDiveLocation)
        IcarusDiveTime = DotaTime()
        return
    end

    IcarusDiveStopDesire = X.ConsiderIcarusDiveStop()
    if IcarusDiveStopDesire > 0
    then
        bot:Action_UseAbility(IcarusDiveStop)
        bot.icarus_dive_stuck = false
        return
    end

    SunRayDesire, SunRayLocation = X.ConsiderSunRay()
    if SunRayDesire > 0
    then
        bot:Action_UseAbilityOnLocation(SunRay, SunRayLocation)
        return
    end

    SunRayStopDesire = X.ConsiderSunRayStop()
    if SunRayStopDesire > 0
    then
        bot:Action_UseAbility(SunRayStop)
        bot.sun_ray_engage = false
        bot.sun_ray_heal_ally = false
        return
    end

    ToggleMovementDesire, State = X.ConsiderToggleMovement()
    if ToggleMovementDesire > 0
    then
		if State == 'on'
        then
			if not ToggleMovement:GetToggleState()
            then
				bot:Action_UseAbility(ToggleMovement)
			end
		else
			if ToggleMovement:GetToggleState()
            then
				bot:Action_UseAbility(ToggleMovement)
			end
		end

        return
    end
end

function X.ConsiderIcarusDive()
    if not Fu.CanCastAbility(IcarusDive)
    or bot:IsRooted()
    or bot:HasModifier('modifier_phoenix_icarus_dive')
    or bot:HasModifier('modifier_phoenix_supernova_hiding')
    or bot:HasModifier('modifier_bloodseeker_rupture')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nDiveLength = IcarusDive:GetSpecialValueInt('dash_length')
	local nDiveWidth = IcarusDive:GetSpecialValueInt('dash_width')
    local nHealthCost = (IcarusDive:GetSpecialValueInt('hp_cost_perc') / 100) * bot:GetHealth()
	local nDamage = IcarusDive:GetSpecialValueInt('damage_per_second') * IcarusDive:GetSpecialValueFloat('burn_duration')
    local nHealth = (bot:GetHealth() - nHealthCost) / bot:GetMaxHealth()
    botTarget = Fu.GetProperTarget(bot)

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(tEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nDiveLength)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not Fu.IsEnemyChronosphereInLocation(enemyHero:GetLocation())
        and not Fu.IsEnemyBlackHoleInLocation(enemyHero:GetLocation())
        and nHealth > 0.4
        then
            bot.icarus_dive_kill = true
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
        end
    end

	if Fu.IsStuck(bot)
	then
        bot.icarus_dive_stuck = true
		return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nDiveLength)
	end

	if Fu.IsInTeamFight(bot, 1200)
	then
		local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nDiveLength, nDiveWidth / 1.5, 0, 0)

		if  nLocationAoE.count >= 2
        and not Fu.IsEnemyChronosphereInLocation(nLocationAoE.targetloc)
        and not Fu.IsEnemyBlackHoleInLocation(nLocationAoE.targetloc)
        and nHealth > 0.3
        then
            bot.icarus_dive_engage = true
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

    if bGoingOnSomeone
    then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nDiveLength)
        and not Fu.IsEnemyChronosphereInLocation(botTarget:GetLocation())
        and not Fu.IsEnemyBlackHoleInLocation(botTarget:GetLocation())
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and nHealth > 0.3
        then
            if #tAllyHeroes >= #tEnemyHeroes + 1
            then
                bot.icarus_dive_engage = true
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            end
        end
    end

    if Fu.IsRetreating(bot)
    and bot:GetActiveModeDesire() > 0.75
    and not Fu.IsSuspiciousIllusion(bot)
    then
        for _, enemy in pairs(tEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and not Fu.IsSuspiciousIllusion(enemy)
            and bot:WasRecentlyDamagedByHero(enemy, 3.0)
            and nHealth > 0.15
            then
                bot.icarus_dive_retreat = true
                return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nDiveLength)
            end
        end

        if nBotHP < 0.5 and bot:WasRecentlyDamagedByTower(2.5)
        and nHealth > 0.2
        then
            bot.icarus_dive_retreat = true
            return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nDiveLength)
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderIcarusDiveStop()
    if not Fu.CanCastAbility(IcarusDiveStop)
    or bot:HasModifier('modifier_phoenix_icarus_dive')
    or bot:HasModifier('modifier_phoenix_supernova_hiding')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    if bot.icarus_dive_kill
    or bot.icarus_dive_engage then
        if DotaTime() > (IcarusDiveTime + IcarusDiveDuration) then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bot.icarus_dive_stuck
    or bot.icarus_dive_retreat then
        if DotaTime() > (IcarusDiveTime + (IcarusDiveDuration / 2))
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderFireSpirits()
    if not Fu.CanCastAbility(FireSpirits)
    or bot:HasModifier('modifier_phoenix_icarus_dive')
    or bot:HasModifier('modifier_phoenix_supernova_hiding')
    or bot:HasModifier('modifier_phoenix_fire_spirit_count')
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, FireSpirits:GetCastRange())
	local nRadius = FireSpirits:GetSpecialValueInt('radius')
    local nHealthCost = (FireSpirits:GetSpecialValueInt('hp_cost_perc') / 100) * bot:GetHealth()
	local nDamage = FireSpirits:GetSpecialValueInt('damage_per_second') * FireSpirits:GetSpecialValueFloat('duration')
    local nSpeed = FireSpirits:GetSpecialValueInt('spirit_speed')
    local nHealth = (bot:GetHealth() - nHealthCost) / bot:GetMaxHealth()
    botTarget = Fu.GetProperTarget(bot)

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(tEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not enemyHero:HasModifier('modifier_phoenix_fire_spirit_burn')
        and nHealth > 0.25
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone
    then
        local target = nil
        local targetAttackDamage = 0
        for _, enemy in pairs(tEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not Fu.IsEnemyChronosphereInLocation(enemy:GetLocation())
            and not Fu.IsEnemyBlackHoleInLocation(enemy:GetLocation())
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemy:HasModifier('modifier_phoenix_fire_spirit_burn') then
                local enemyAttackDamage = enemy:GetAttackDamage() * enemy:GetAttackSpeed()
                if enemyAttackDamage > targetAttackDamage then
                    target = enemy
                    targetAttackDamage = enemyAttackDamage
                end
            end
        end

        if target ~= nil then
            if Fu.IsInLaningPhase() then
                for _, ally in pairs(tAllyHeroes) do
                    if Fu.IsValidHero(ally)
                    and not ally:IsIllusion()
                    and (Fu.IsAttacking(target) == ally or (Fu.IsChasingTarget(target, ally)) or target:GetAttackTarget() == ally)
                    then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            else
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    local tEnemyLaneCreeps = bot:GetNearbyLaneCreeps(math.min(nCastRange, 1600), true)

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and not Fu.IsThereNonSelfCoreNearby(1200)
    then
        if #tEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
        and not Fu.IsRunning(tEnemyLaneCreeps[1])
        and #tEnemyHeroes == 0
        and Fu.GetMP(bot) > 0.35
        and nHealth > 0.5
        and not Fu.DoesSomeoneHaveModifier(tEnemyLaneCreeps, 'modifier_phoenix_fire_spirit_burn')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot) and Fu.GetMP(bot) > 0.35 and nHealth > 0.4
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(math.min(nCastRange, 1600))
        if ((#nNeutralCreeps >= 2)
            or (#nNeutralCreeps >= 1 and nNeutralCreeps[1]:IsAncientCreep()))
        and not Fu.DoesSomeoneHaveModifier(nNeutralCreeps, 'modifier_phoenix_fire_spirit_burn')
        then
            return BOT_ACTION_DESIRE_HIGH
        end

        if #tEnemyLaneCreeps >= 3
        and not Fu.DoesSomeoneHaveModifier(tEnemyLaneCreeps, 'modifier_phoenix_fire_spirit_burn')
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if  Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.GetHP(botTarget) > 0.25
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and nHealth > 0.6
        and not botTarget:HasModifier('modifier_phoenix_fire_spirit_burn')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and nHealth > 0.7
        and not botTarget:HasModifier('modifier_phoenix_fire_spirit_burn')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderFireSpiritsLaunch()
    if not Fu.CanCastAbility(FireSpiritsLaunch)
    or bot:HasModifier('modifier_phoenix_icarus_dive')
    or bot:HasModifier('modifier_phoenix_supernova_hiding')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = FireSpirits:GetCastRange()
	local nRadius = FireSpirits:GetSpecialValueInt('radius')
    local nSpeed = FireSpirits:GetSpecialValueInt('spirit_speed')
    local nDuration = FireSpirits:GetSpecialValueFloat('burn_duration')
	local nDamage = FireSpirits:GetSpecialValueInt('damage_per_second') * nDuration
    botTarget = Fu.GetProperTarget(bot)

    local tAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    for _, enemyHero in pairs(tEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
        and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
        and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
        and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
        and not enemyHero:HasModifier('modifier_phoenix_fire_spirit_burn')
        then
            local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed)
            local targetLoc = Fu.GetCorrectLoc(enemyHero, eta)
            local nLocationAoE = bot:FindAoELocation(true, true, targetLoc, nCastRange, nRadius, 0, 0)

            if eta > X.GetModifierTime(enemyHero, 'modifier_phoenix_fire_spirit_burn')
            then
                if nLocationAoE.count >= 2 then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                else
                    return BOT_ACTION_DESIRE_HIGH, targetLoc
                end
            end
        end
    end

    if bGoingOnSomeone
    then
        local target = nil
        local targetAttackDamage = 0
        for _, enemy in pairs(tEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not Fu.IsEnemyChronosphereInLocation(enemy:GetLocation())
            and not Fu.IsEnemyBlackHoleInLocation(enemy:GetLocation())
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemy:HasModifier('modifier_phoenix_fire_spirit_burn') then
                local enemyAttackDamage = enemy:GetAttackDamage() * enemy:GetAttackSpeed()
                if enemyAttackDamage > targetAttackDamage then
                    target = enemy
                    targetAttackDamage = enemyAttackDamage
                end
            end
        end

        if target ~= nil then
            local eta = GetUnitToUnitDistance(bot, target) / nSpeed
            local targetLoc = Fu.GetCorrectLoc(target, eta)
            local nLocationAoE = bot:FindAoELocation(true, true, targetLoc, nCastRange, nRadius, 0, 0)

            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(target, 'modifier_phoenix_fire_spirit_burn')
            then
                if Fu.IsInLaningPhase() then
                    for _, ally in pairs(tAllyHeroes) do
                        if Fu.IsValidHero(ally)
                        and not ally:IsIllusion()
                        and (Fu.IsAttacking(target) == ally or (Fu.IsChasingTarget(target, ally)) or target:GetAttackTarget() == ally)
                        then
                            if nLocationAoE.count >= 2 then
                                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                            else
                                return BOT_ACTION_DESIRE_HIGH, targetLoc
                            end
                        end
                    end
                else
                    if nLocationAoE.count >= 2 then
                        return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                    else
                        return BOT_ACTION_DESIRE_HIGH, targetLoc
                    end
                end
            end
        end
    end

    local tEnemyLaneCreeps = bot:GetNearbyLaneCreeps(math.min(nCastRange, 1600), true)
    local vCenterLaneCreeps = Fu.GetCenterOfUnits(tEnemyLaneCreeps)

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and not Fu.IsThereNonSelfCoreNearby(1200)
    then
        if #tEnemyLaneCreeps >= 4
        and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
        and not Fu.IsRunning(tEnemyLaneCreeps[1])
        and #tEnemyHeroes == 0
        then
            local eta = GetUnitToLocationDistance(bot, vCenterLaneCreeps) / nSpeed
            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(tEnemyLaneCreeps[1], 'modifier_phoenix_fire_spirit_burn') then
                return BOT_ACTION_DESIRE_HIGH, vCenterLaneCreeps
            end
        end
    end

    if Fu.IsFarming(bot)
    then
        local nNeutralCreeps = bot:GetNearbyNeutralCreeps(math.min(nCastRange, 1600))
        local vCenterNeutralCreeps = Fu.GetCenterOfUnits(nNeutralCreeps)

        if ((#nNeutralCreeps >= 2)
            or (#nNeutralCreeps >= 1 and nNeutralCreeps[1]:IsAncientCreep()))
        and not Fu.IsRunning(bot)
        then
            local eta = GetUnitToLocationDistance(bot, vCenterNeutralCreeps) / nSpeed
            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(nNeutralCreeps[1], 'modifier_phoenix_fire_spirit_burn') then
                return BOT_ACTION_DESIRE_HIGH, vCenterNeutralCreeps
            end
        end

        if #tEnemyLaneCreeps >= 3
        and Fu.CanBeAttacked(tEnemyLaneCreeps[1])
        and not Fu.IsRunning(tEnemyLaneCreeps[1])
        and not Fu.IsThereNonSelfCoreNearby(1200)
        then
            local eta = GetUnitToLocationDistance(bot, vCenterLaneCreeps) / nSpeed
            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(tEnemyLaneCreeps[1], 'modifier_phoenix_fire_spirit_burn') then
                return BOT_ACTION_DESIRE_HIGH, vCenterLaneCreeps
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.GetHP(botTarget) > 0.25
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            local eta = GetUnitToUnitDistance(bot, botTarget) / nSpeed
            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(botTarget, 'modifier_phoenix_fire_spirit_burn') then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not botTarget:HasModifier('modifier_phoenix_fire_spirit_burn')
        then
            local eta = GetUnitToUnitDistance(bot, botTarget) / nSpeed
            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(botTarget, 'modifier_phoenix_fire_spirit_burn') then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            end
        end
    end

    local tCreeps = bot:GetNearbyCreeps(nCastRange, true)
    if Fu.IsValid(tCreeps[2])
    and Fu.CanBeAttacked(tCreeps[2])
    and not Fu.IsRunning(tCreeps[2]) then
        local nLocationAoE = bot:FindAoELocation(true, false, Fu.GetCenterOfUnits(tCreeps), nRadius, nRadius, 0, 0)
        if nLocationAoE.count >= 3 then
            local eta = GetUnitToLocationDistance(bot, nLocationAoE.targetloc) / nSpeed
            if DotaTime() > FireSpiritsLaunchTime + eta + 0.25
            and eta > X.GetModifierTime(tCreeps[2], 'modifier_phoenix_fire_spirit_burn') then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSunRay()
    if not Fu.CanCastAbility(SunRay)
    or bot:HasModifier('modifier_phoenix_icarus_dive')
    or bot:HasModifier('modifier_phoenix_sun_ray')
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SunRay:GetCastRange())
    local botHP = nBotHP

    local tEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    if bGoingOnSomeone
    then
        local target = nil
        local targetHP = 99999
        local tInRangeAlly_attacking = Fu.GetSpecialModeAllies(bot, 900, BOT_MODE_ATTACK)

        for _, enemy in pairs(tEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange * 0.8)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not enemy:HasModifier('modifier_abaddon_borrowed_time')
            and not enemy:HasModifier('modifier_dazzle_shallow_grave')
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            and botHP > 0.4 then
                local enemyHP = enemy:GetHealth()
                if enemyHP < targetHP then
                    target = enemy
                    targetHP = enemyHP
                end
            end
        end

        if target ~= nil and #tInRangeAlly_attacking >= 2 then
            bot.sun_ray_engage = true
            bot.sun_ray_target = target
            return BOT_ACTION_DESIRE_HIGH, target:GetLocation()
        end
    end

    local tInRangeAlly = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(tInRangeAlly)
    do
        if Fu.IsValidHero(allyHero)
        and Fu.IsCore(allyHero)
        and Fu.GetHP(allyHero) < 0.5
        and allyHero:WasRecentlyDamagedByAnyHero(3.5)
        and not allyHero:IsIllusion()
        and botHP > 0.38
        and not (Fu.IsRetreating(bot) and Fu.IsRealInvisible(bot))
        then
            if not Fu.IsRunning(allyHero)
            or allyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
            or allyHero:HasModifier('modifier_enigma_black_hole_pull') then
                bot.sun_ray_heal_ally = true
                bot.sun_ray_target = allyHero
                return BOT_ACTION_DESIRE_HIGH, allyHero:GetLocation()
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSunRayStop()
    if not Fu.CanCastAbility(SunRayStop)
    or bot:HasModifier('modifier_phoenix_icarus_dive')
    then
        return BOT_ACTION_DESIRE_NONE
    end

	local tAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 1600)
	local tEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1600)
    local botHP = nBotHP

    if bot.sun_ray_engage then
        if (X.IsBeingAttackedByRealHero(tEnemyHeroes, bot) and botHP < 0.25 and bot:WasRecentlyDamagedByAnyHero(2.0))
        or #tAllyHeroes + 1 < #tEnemyHeroes
        or #tEnemyHeroes == 0
        or #tAllyHeroes == 0 and #tEnemyHeroes == 0
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bot.sun_ray_heal_ally then
        if (X.IsBeingAttackedByRealHero(tEnemyHeroes, bot) and botHP < 0.25 and bot:WasRecentlyDamagedByAnyHero(2.0))
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if botHP < 0.17 then
        return BOT_ACTION_DESIRE_HIGH
    end

    if math.floor(DotaTime()) % 2 == 0 then
        if Fu.IsValidHero(bot.sun_ray_target)
        and not bot:IsFacingLocation(bot.sun_ray_target:GetLocation(), 45)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderToggleMovement()
    if not Fu.CanCastAbility(ToggleMovement)
    or not bot:HasModifier('modifier_phoenix_sun_ray')
    or bot:HasModifier('modifier_phoenix_supernova_hiding')
    or bot:IsRooted()
    then
        return BOT_ACTION_DESIRE_NONE, ''
    end

    local nBeamDistance = 1150

    if Fu.IsValidHero(bot.sun_ray_target) then
        if not Fu.IsInRange(bot, bot.sun_ray_target, nBeamDistance) then
            if ToggleMovement:GetToggleState() == false then
                return BOT_ACTION_DESIRE_HIGH, 'on'
            end

            return BOT_ACTION_DESIRE_NONE, ''
        end
    end

    if ToggleMovement:GetToggleState() == true then
        return BOT_ACTION_DESIRE_HIGH, 'off'
    end

    return BOT_ACTION_DESIRE_NONE, ''
end

function X.ConsiderSupernova()
    if not Fu.CanCastAbility(Supernova)
    or bot:HasModifier('modifier_phoenix_supernova_hiding')
    then
        return BOT_ACTION_DESIRE_NONE, nil, false
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, Supernova:GetCastRange())
	local nRadius = Supernova:GetSpecialValueInt('aura_radius')

    if Fu.IsInTeamFight(bot, 1200)
	then
        local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), (nRadius / 2) + 250)

        if #nInRangeEnemy >= 2
        then
            if string.find(GetBot():GetUnitName(), 'phoenix') and bot:HasScepter()
            then
                nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)
                for _, allyHero in pairs(nInRangeAlly)
                do
                    if Fu.IsValidHero(allyHero)
                    and not Fu.IsAttacking(allyHero)
                    and Fu.GetHP(allyHero) < 0.25
                    and allyHero:WasRecentlyDamagedByAnyHero(3.0)
                    then
                        return BOT_ACTION_DESIRE_HIGH, allyHero, true
                    end
                end
            else
                if not (#nInRangeAlly >= #nInRangeEnemy + 2) then
                    return BOT_ACTION_DESIRE_HIGH, nil, false
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil, false
end

function X.IsBeingAttackedByRealHero(hUnitList, hUnit)
    for _, enemy in pairs(hUnitList)
    do
        if Fu.IsValidHero(enemy)
        and not Fu.IsSuspiciousIllusion(enemy)
        and (enemy:GetAttackTarget() == hUnit or Fu.IsChasingTarget(enemy, hUnit))
        then
            return true
        end
    end

    return false
end

function X.GetModifierTime(unit, sModifierName)
    if unit:HasModifier(sModifierName) then
        return unit:GetModifierRemainingDuration(unit:GetModifierByName(sModifierName))
    else
        return 0
    end
end

return X