local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
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
	{1,3,1,2,3,6,3,3,1,1,6,2,2,2,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_double_branches",
	"item_quelling_blade",
	"item_tango",

	"item_wraith_band",
	"item_magic_wand",
	"item_power_treads",
	"item_bfury",--
	"item_lesser_crit",
	"item_manta",--
	"item_black_king_bar",--
	"item_greater_crit",--
    "item_satanic",--
	"item_aghanims_shard",
	-- "item_butterfly",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_quelling_blade",

    "item_magic_wand",
    "item_wraith_band",
    "item_power_treads",
    "item_sange_and_yasha",--
	"item_orchid",
    "item_black_king_bar",--
    "item_bloodthorn",--
    "item_satanic",--
    "item_aghanims_shard",
    "item_monkey_king_bar",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_orb_of_frost",
	"item_magic_wand",

	"item_boots",
	"item_tranquil_boots",
	"item_ancient_janggo",
	"item_guardian_greaves",--
	"item_solar_crest",--
	"item_heavens_halberd",--
	"item_sheepstick",--
	"item_lotus_orb",--
	"item_assault",--
	"item_moon_shard",
	"item_aghanims_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_orb_of_frost",
	"item_magic_wand",

	"item_boots",
	"item_arcane_boots",
	"item_ancient_janggo",
	"item_pipe",--
	"item_solar_crest",--
	"item_boots_of_bearing",--
	-- "item_force_staff",--
	"item_heavens_halberd",--
	"item_sheepstick",--
	"item_lotus_orb",--
	"item_moon_shard",
	"item_aghanims_shard",
	"item_ultimate_scepter_2",
}


X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_black_king_bar",
	"item_quelling_blade",
}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_heavens_halberd", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_kez

[VScript] Ability At Index 0: kez_echo_slash
[VScript] Ability At Index 1: kez_grappling_claw
[VScript] Ability At Index 2: kez_kazurai_katana
[VScript] Ability At Index 3: kez_switch_weapons
[VScript] Ability At Index 4: generic_hidden
[VScript] Ability At Index 5: kez_raptor_dance
[VScript] Ability At Index 6: kez_falcon_rush
[VScript] Ability At Index 7: kez_talon_toss
[VScript] Ability At Index 8: kez_shodo_sai
[VScript] Ability At Index 9: kez_ravens_veil
[VScript] Ability At Index 10: kez_shodo_sai_parry_cancel

--]]

local SwitchWeapons = SafeAbility(bot:GetAbilityByName('kez_switch_weapons'), 'kez_switch_weapons', 'kez')

local EchoSlash = SafeAbility(bot:GetAbilityByName('kez_echo_slash'), 'kez_echo_slash', 'kez')
local GrapplingClaw = SafeAbility(bot:GetAbilityByName('kez_grappling_claw'), 'kez_grappling_claw', 'kez')
local KazuraiKatana = SafeAbility(bot:GetAbilityByName('kez_kazurai_katana'), 'kez_kazurai_katana', 'kez')
local RaptorDance = SafeAbility(bot:GetAbilityByName('kez_raptor_dance'), 'kez_raptor_dance', 'kez')

local FalconRush = SafeAbility(bot:GetAbilityByName('kez_falcon_rush'), 'kez_falcon_rush', 'kez')
local TalonToss = SafeAbility(bot:GetAbilityByName('kez_talon_toss'), 'kez_talon_toss', 'kez')
local ShodoSai = SafeAbility(bot:GetAbilityByName('kez_shodo_sai'), 'kez_shodo_sai', 'kez')
local ShodoSaiCancel = SafeAbility(bot:GetAbilityByName('kez_shodo_sai_parry_cancel'), 'kez_shodo_sai_parry_cancel', 'kez')
local RavensVeil = SafeAbility(bot:GetAbilityByName('kez_ravens_veil'), 'kez_ravens_veil', 'kez')

local nKeepMana = 220
local castEchoSlashDesire, castGrapplingClawDesire, castGrapplingClawTarget, castGrapplingClawType, castRaptorDanceDesire

local FalconRushDesire
local TalonTossDesire, TalonTossTarget
local ShodoSaiDesire, ShodoSaiLocation
local ShodoSaiCancelDesire
local RavensVeilDesire
local hNearbyTowers

local SwitchDisciplineDesire

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotHP
local nLV, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotHP = Fu.GetHP(bot)
	local ctx = AbilityCtx.Build(bot)
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies
	hNearbyTowers = bot:GetNearbyTowers(800, true);

	-- Detect mode from slot 0 ability name (reliable, no desync)
	local hSlot0 = bot:GetAbilityInSlot(0)
	if hSlot0 ~= nil then
		if hSlot0:GetName() == 'kez_echo_slash' then
			bot.kez_mode = 'katana'
		elseif hSlot0:GetName() == 'kez_falcon_rush' then
			bot.kez_mode = 'sai'
		end
	end

    if Fu.IsInLaningPhase()
    and not bRetreating
    and Fu.IsValidHero(botTarget)
    and Fu.GetHP(botTarget) > 0.5
    and Fu.GetMP(bot) < 0.6 then
        return
    end

	if Fu.CanNotUseAbility(bot)
    or bot:HasModifier('modifier_kez_raptor_dance_immune')
    then return end

	X.DoCombo()

	-- Always check SwitchDiscipline first (mode-agnostic)
    SwitchDisciplineDesire = X.ConsiderSwitchDiscipline()
    if SwitchDisciplineDesire > 0 then
        bot:Action_UseAbility(SwitchWeapons)
        return
    end

	-- Only check abilities for the CURRENT active discipline.
	-- Hidden abilities (wrong mode) fail CanCastAbility, wasting cycles and
	-- blocking the bot from reaching the correct mode's abilities.
	if bot.kez_mode == 'sai' then
		-- Sai discipline: FalconRush > TalonToss > RavensVeil > ShodoSai > ShodoSaiCancel

		FalconRushDesire = X.ConsiderFalconRush()
		if FalconRushDesire > 0 then
			Fu.SetQueuePtToINT(bot, false)
			bot:ActionQueue_UseAbility(FalconRush)
			return
		end

		TalonTossDesire, TalonTossTarget = X.ConsiderTalonToss()
		if TalonTossDesire > 0 then
			Fu.SetQueuePtToINT(bot, false)
			bot:ActionQueue_UseAbilityOnEntity(TalonToss, TalonTossTarget)
			return
		end

		RavensVeilDesire = X.ConsiderRavensVeil()
		if RavensVeilDesire > 0 then
			bot:Action_UseAbility(RavensVeil)
			return
		end

		ShodoSaiCancelDesire = X.ConsiderShodoSaiCancel()
		if ShodoSaiCancelDesire > 0 then
			bot:Action_UseAbility(ShodoSaiCancel)
			return
		end

		ShodoSaiDesire, ShodoSaiLocation = X.ConsiderShodoSai()
		if ShodoSaiDesire > 0 then
			bot:Action_UseAbilityOnLocation(ShodoSai, ShodoSaiLocation)
			return
		end
	else
		-- Katana discipline: GrapplingClaw > EchoSlash > KazuraiKatana > RaptorDance

		castGrapplingClawDesire, castGrapplingClawTarget, castGrapplingClawType = X.ConsiderGrapplingClaw()
		if ( castGrapplingClawDesire > 0 ) then
			Fu.SetQueuePtToINT( bot, false )
			if castGrapplingClawTarget ~= nil and (type(castGrapplingClawTarget) == "number" or castGrapplingClawType == 'tree') then
				bot:Action_UseAbilityOnTree(GrapplingClaw, castGrapplingClawTarget)
			elseif castGrapplingClawTarget ~= nil then
				bot:Action_UseAbilityOnEntity(GrapplingClaw, castGrapplingClawTarget)
			end
			return
		end

		castEchoSlashDesire = X.ConsiderEchoSlash()
		if castEchoSlashDesire > 0 then
			Fu.SetQueuePtToINT( bot, false )
			bot:ActionQueue_UseAbility( EchoSlash )
			return
		end

		KazuraiKatanaDesire, KazuraiKatanaTarget = X.ConsiderKazuraiKatana()
		if KazuraiKatanaDesire > 0 then
			bot:Action_UseAbilityOnEntity(KazuraiKatana, KazuraiKatanaTarget)
			return
		end

		castRaptorDanceDesire = X.ConsiderRaptorDance()
		if castRaptorDanceDesire > 0 then
			Fu.SetQueuePtToINT( bot, false )
			bot:ActionQueue_UseAbility( RaptorDance )
			return
		end
	end
end

function X.ConsiderEchoSlash()
	if not Fu.CanCastAbility(EchoSlash) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nDistance = EchoSlash:GetSpecialValueInt('katana_distance')
    local nFrontTravelDistance = EchoSlash:GetSpecialValueInt('travel_distance')
    local nRadius = EchoSlash:GetSpecialValueInt('katana_radius')
    local nAttackDamagePercentage = EchoSlash:GetSpecialValueInt('katana_echo_damage') / 100
    local nBonusHeroDamage = EchoSlash:GetSpecialValueInt('echo_hero_damage')
    local nDamage = bot:GetAttackDamage() * nAttackDamagePercentage
    local nStrikeCount = EchoSlash:GetSpecialValueInt('katana_strikes')
    local nManaAfter = Fu.GetManaAfter(EchoSlash:GetManaCost())

    for _, enemy in pairs(hEnemyList) do
        if Fu.IsValidHero(enemy)
        and Fu.IsInRange(bot, enemy, nDistance * 0.8)
        and bot:IsFacingLocation(enemy:GetLocation(), 15)
        and Fu.CanBeAttacked(enemy)
        and not Fu.IsSuspiciousIllusion(enemy)
        and Fu.CanKillTarget(enemy, (nDamage + nBonusHeroDamage) * nStrikeCount, DAMAGE_TYPE_PHYSICAL)
        and not enemy:HasModifier('modifier_abaddon_borrowed_time')
        and not enemy:HasModifier('modifier_dazzle_shallow_grave')
        and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemy:HasModifier('modifier_troll_warlord_battle_trance')
        and not enemy:HasModifier('modifier_oracle_false_promise_timer')
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nDistance)
        and bot:IsFacingLocation(botTarget:GetLocation(), 15)
        and Fu.CanBeAttacked(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_troll_warlord_battle_trance')
        and not botTarget:HasModifier('modifier_oracle_false_promise_timer')
        then
            -- Use when not chasing (standing and fighting), or when target is disabled/slowed
            if not Fu.IsChasingTarget(bot, botTarget)
            or Fu.IsDisabled(botTarget)
            or botTarget:GetCurrentMovementSpeed() <= 200
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bRetreating
    and not Fu.IsRealInvisible(bot)
    and bot:WasRecentlyDamagedByAnyHero(3.0)
    and Fu.CanBeAttacked(bot)
    then
        for _, enemyHero in pairs(hEnemyList) do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, 1200)
            then
                if Fu.IsChasingTarget(enemyHero, bot) or (hAllyList ~= nil and #hEnemyList > #hAllyList) then
                    local vAwayLocation = Fu.VectorAway and Fu.VectorAway(bot:GetLocation(), enemyHero:GetLocation(), 800) or Fu.GetTeamFountain()
                    if bot:IsFacingLocation(Fu.GetTeamFountain(), 45) or bot:IsFacingLocation(vAwayLocation, 45) then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end
        end
    end

    if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
    and not Fu.IsThereNonSelfCoreNearby(1200)
    and nManaAfter > 0.4
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nDistance, true)
        if Fu.IsValid(nEnemyLaneCreeps[1])
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        and not Fu.IsRunning(nEnemyLaneCreeps[1])
        then
            local nLocationAoE = bot:FindAoELocation(true, false, nEnemyLaneCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
            if nLocationAoE.count >= 4 and bot:IsFacingLocation(nLocationAoE.targetloc, 20) then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsFarming(bot)
    and not Fu.IsThereNonSelfCoreNearby(1200)
    and nManaAfter > 0.3
    then
        local nCreeps = bot:GetNearbyCreeps(nDistance, true)
        if Fu.IsValid(nCreeps[1])
        and Fu.CanBeAttacked(nCreeps[1])
        and not Fu.IsRunning(nCreeps[1])
        then
            local nLocationAoE = bot:FindAoELocation(true, false, nCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
            if (nLocationAoE.count >= 2 or (nLocationAoE.count >= 2 and nCreeps[1]:IsAncientCreep()))
            and bot:IsFacingLocation(nLocationAoE.targetloc, 20)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsLaning(bot)
    and not Fu.IsThereNonSelfCoreNearby(1200)
    then
        if hEnemyList[1] ~= nil and Fu.IsInRange(bot, hEnemyList[1], nDistance - 100)
        and bot:IsFacingLocation(hEnemyList[1]:GetLocation(), 8)
        and nManaAfter > 0.5
        then
            return BOT_ACTION_DESIRE_HIGH
        end
        local nCreeps = bot:GetNearbyCreeps(nDistance, true)
        if Fu.IsValid(nCreeps[1])
        and Fu.CanBeAttacked(nCreeps[1])
        and not Fu.IsRunning(nCreeps[1])
        then
            local nLocationAoE = bot:FindAoELocation(true, false, nCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
            if nLocationAoE.count >= 5
            and bot:IsFacingLocation(nLocationAoE.targetloc, 15)
            then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsDoingRoshan(bot) then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and bot:IsFacingLocation(botTarget:GetLocation(), 20)
        and Fu.IsInRange(bot, botTarget, nDistance)
        and bAttacking
        and nManaAfter > 0.25
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and bot:IsFacingLocation(botTarget:GetLocation(), 20)
        and Fu.IsInRange(bot, botTarget, nDistance)
        and bAttacking
        and nManaAfter > 0.25
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderGrapplingClaw()
	if not Fu.CanCastAbility(GrapplingClaw) or bot:IsRooted() then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = GrapplingClaw:GetCastRange()
	local nManaAfter = Fu.GetManaAfter(GrapplingClaw:GetManaCost())

	-- Retreat: grapple away from enemies
	if bRetreating
	and not Fu.IsRealInvisible(bot)
	and bot:DistanceFromFountain() > 600
	and not bot:HasModifier('modifier_fountain_aura_buff')
	then
		local hTarget, sType = X.GetBestRetreatGrapplingTarget(nCastRange)
		if hTarget ~= nil then
			if hAllyList ~= nil and hEnemyList ~= nil then
				for _, enemy in pairs(hEnemyList) do
					if Fu.IsValidHero(enemy)
					and Fu.IsInRange(bot, enemy, 1600)
					then
						if Fu.IsChasingTarget(enemy, bot)
						or (#hEnemyList > #hAllyList)
						then
							return BOT_ACTION_DESIRE_HIGH, hTarget, sType
						end
					end
				end
			end

			-- Outnumbered retreat
			if not Fu.IsInLaningPhase() and (nManaAfter > 0.4 or nBotHP < 0.2) then
				local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
				if hEnemyList ~= nil and #hEnemyList >= #nInRangeAlly + 2 then
					return BOT_ACTION_DESIRE_HIGH, hTarget, sType
				end
			end
		end
	end

	if Fu.IsInLaningPhase() and nMP < 0.3 then return BOT_ACTION_DESIRE_NONE end

	-- Going on someone: gap close
	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 200)
		and Fu.IsChasingTarget(bot, botTarget)
		and Fu.CanCastOnTargetAdvanced(botTarget)
		and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'unit'
		end
	end

	-- Stuck escape
	if bot.stuckTime ~= nil and (DotaTime() - bot.stuckTime) > 2 then
		local hTarget, sType = X.GetBestRetreatGrapplingTarget(nCastRange)
		if hTarget ~= nil then
			return BOT_ACTION_DESIRE_HIGH, hTarget, sType
		end
	end

	-- Laning: grapple to lane front when far away
	if Fu.IsLaning(bot) and Fu.IsInLaningPhase() and nManaAfter > 0.8 and DotaTime() > 0 then
		local vLaneFrontLocation = GetLaneFrontLocation(GetTeam(), bot:GetAssignedLane(), 0)
		if GetUnitToLocationDistance(bot, vLaneFrontLocation) > 2000 and hEnemyList ~= nil and #hEnemyList <= 1 then
			local hTarget, sType = X.GetBestGrapplingTargetTowardsLocation(nCastRange, vLaneFrontLocation)
			if hTarget ~= nil then
				return BOT_ACTION_DESIRE_HIGH, hTarget, sType
			end
		end
	end

	-- Push: grapple towards lane front for faster travel
	if Fu.IsPushing(bot) and nManaAfter > 0.5 then
		local nLane = LANE_MID
		if bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_TOP then nLane = LANE_TOP end
		if bot:GetActiveMode() == BOT_MODE_PUSH_TOWER_BOT then nLane = LANE_BOT end
		local vLaneFrontLocation = GetLaneFrontLocation(GetTeam(), nLane, 0)
		if (GetUnitToLocationDistance(bot, vLaneFrontLocation) / bot:GetCurrentMovementSpeed()) > 3.5 then
			local hTarget, sType = X.GetBestGrapplingTargetTowardsLocation(nCastRange, vLaneFrontLocation)
			if hTarget ~= nil then
				return BOT_ACTION_DESIRE_HIGH, hTarget, sType
			end
		end
	end

	-- Defend: grapple towards defense target
	if Fu.IsDefending(bot) and nManaAfter > 0.5 and hEnemyList ~= nil and #hEnemyList <= 1 then
		local nLane = LANE_MID
		if bot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_TOP then nLane = LANE_TOP end
		if bot:GetActiveMode() == BOT_MODE_DEFEND_TOWER_BOT then nLane = LANE_BOT end
		local vLaneFrontLocation = GetLaneFrontLocation(GetTeam(), nLane, 0)
		if (GetUnitToLocationDistance(bot, vLaneFrontLocation) / bot:GetCurrentMovementSpeed()) > 3.5 then
			local hTarget, sType = X.GetBestGrapplingTargetTowardsLocation(nCastRange, vLaneFrontLocation)
			if hTarget ~= nil then
				return BOT_ACTION_DESIRE_HIGH, hTarget, sType
			end
		end
	end

	-- Farm: grapple to farm location
	if Fu.IsFarming(bot) and nManaAfter > 0.5 and hEnemyList ~= nil and #hEnemyList == 0 then
		if bot.farm and bot.farm.location then
			local hTarget, sType = X.GetBestGrapplingTargetTowardsLocation(nCastRange, bot.farm.location)
			if hTarget ~= nil and Fu.IsRunning(bot) then
				return BOT_ACTION_DESIRE_HIGH, hTarget, sType
			end
		end
	end

	-- Roshan: grapple to rosh pit
	if Fu.IsDoingRoshan(bot) then
		local vRoshLoc = Fu.GetCurrentRoshanLocation and Fu.GetCurrentRoshanLocation() or nil
		if vRoshLoc ~= nil
		and GetUnitToLocationDistance(bot, vRoshLoc) > 2000
		and hEnemyList ~= nil and #hEnemyList <= 1
		and nManaAfter > 0.4
		then
			local hTarget, sType = X.GetBestGrapplingTargetTowardsLocation(nCastRange, vRoshLoc)
			if hTarget ~= nil then
				return BOT_ACTION_DESIRE_HIGH, hTarget, sType
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderRaptorDance()
	if not Fu.CanCastAbility(RaptorDance) then return BOT_ACTION_DESIRE_NONE end

	local nRadius = RaptorDance:GetSpecialValueInt( "radius" ) - 150
	local nBaseDamage = RaptorDance:GetSpecialValueInt( "base_damage" )
	local nStrikes = RaptorDance:GetSpecialValueInt( "strikes" )
	local nStrikeInterval = RaptorDance:GetSpecialValueFloat( "strike_interval" ) or 0.2
	local nMaxHealthDamagePct = RaptorDance:GetSpecialValueInt( "max_health_damage_pct" )
	local nCastPoint = RaptorDance:GetCastPoint()

	-- Avoid using during stun projectile if not magic immune
	if not bot:IsMagicImmune() then
		if Fu.IsStunProjectileIncoming and Fu.IsStunProjectileIncoming(bot, 800) then
			return BOT_ACTION_DESIRE_NONE
		end
	end

	-- Kill confirmation
	for _, npcEnemy in pairs( hEnemyList ) do
		if Fu.IsValidHero( npcEnemy )
		and Fu.IsInRange(bot, npcEnemy, nRadius)
		and Fu.CanBeAttacked(npcEnemy)
		then
			local nDamage = (nBaseDamage + bot:GetAttackDamage() + nMaxHealthDamagePct / 100 * npcEnemy:GetMaxHealth()) * nStrikes
			if Fu.CanKillTarget( npcEnemy, nDamage, DAMAGE_TYPE_PURE )
			and not npcEnemy:HasModifier('modifier_abaddon_borrowed_time')
			and not npcEnemy:HasModifier('modifier_dazzle_shallow_grave')
			and not npcEnemy:HasModifier('modifier_oracle_false_promise_timer')
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	-- Invulnerability exploitation: when BKB/shallow grave/false promise, go all in
	if Fu.IsInTeamFight(bot, 1200) and nBotHP < 0.75 then
		if bot:IsMagicImmune()
		or bot:IsInvulnerable()
		or bot:HasModifier('modifier_dazzle_shallow_grave')
		or bot:HasModifier('modifier_oracle_false_promise_timer')
		then
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius * 0.8)
			if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1 then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	-- Going on someone: use when estimated damage is high or outnumbered
	if bGoingOnSomeone and nBotHP < 0.75 then
		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius * 0.75)
		and Fu.CanBeAttacked(botTarget)
		and not Fu.IsChasingTarget(bot, botTarget)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_oracle_false_promise_timer')
		and not botTarget:HasModifier('modifier_ursa_enrage')
		then
			local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius * 0.8)
			local nEstDamage = bot:GetEstimatedDamageToTarget(true, botTarget, nCastPoint + (nStrikes * nStrikeInterval), DAMAGE_TYPE_ALL)
			if nInRangeEnemy ~= nil then
				if (nEstDamage / botTarget:GetHealth() > 0.5)
				or (nBotHP < 0.65 and #nInRangeEnemy >= 2)
				or (#nInRangeEnemy >= 3)
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	-- Retreat: dodge damage when outnumbered
	if bRetreating then
		if hAllyList ~= nil and hEnemyList ~= nil
		and #hEnemyList >= #hAllyList
		and nBotHP < 0.5 and nBotHP > 0.15 and bot:WasRecentlyDamagedByAnyHero(3)
		and Fu.IsValidHero(hEnemyList[1])
		and Fu.IsInRange(bot, hEnemyList[1], nRadius)
		and not Fu.IsSuspiciousIllusion(hEnemyList[1])
		and not hEnemyList[1]:HasModifier('modifier_abaddon_borrowed_time')
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsInLaningPhase() and nMP < 0.3 then return BOT_ACTION_DESIRE_NONE end

	-- Teamfight AoE
	if Fu.IsInTeamFight( bot, 1200 ) and nBotHP < 0.6 then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, 0, nRadius, 2)
		if nAoeLoc ~= nil then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- Roshan survival
	if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and nBotHP < 0.55
		and bAttacking
		and hEnemyList ~= nil and #hEnemyList == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderKazuraiKatana()
    if not Fu.CanCastAbility(KazuraiKatana) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = KazuraiKatana:GetSpecialValueInt('katana_attack_range')
    local fBonusDamagePercentage = KazuraiKatana:GetSpecialValueInt('katana_bonus_damage') / 100

    for _, enemy in pairs(hEnemyList) do
        if Fu.IsValidHero(enemy)
        and Fu.IsInRange(bot, enemy, nCastRange)
        and Fu.CanCastOnTargetAdvanced(enemy)
        then
            if enemy:IsChanneling() then
                return BOT_ACTION_DESIRE_HIGH, enemy
            end

            local nDamage = Fu.GetModifierCount(bot, 'modifier_kez_katana_bleed')
            if Fu.CanKillTarget(enemy, nDamage, DAMAGE_TYPE_PHYSICAL)
            and not enemy:HasModifier('modifier_abaddon_borrowed_time')
            and not enemy:HasModifier('modifier_dazzle_shallow_grave')
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemy:HasModifier('modifier_oracle_false_promise_timer')
            and not enemy:HasModifier('modifier_troll_warlord_battle_trance')
            and not enemy:HasModifier('modifier_ursa_enrage')
            then
                return BOT_ACTION_DESIRE_HIGH, enemy
            end
        end
    end

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_troll_warlord_battle_trance')
        and not botTarget:HasModifier('modifier_ursa_enrage')
        then
            local nDamage = Fu.GetModifierCount(bot, 'modifier_kez_katana_bleed')
            if (nDamage / bot:GetHealth()) > RemapValClamped(KazuraiKatana:GetLevel(), 2, 4, 0.1, 0.25)
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end

            if nDamage > RemapValClamped(KazuraiKatana:GetLevel(), 2, 4, 75, 300)
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderFalconRush()
    if not Fu.CanCastAbility(FalconRush) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRushRange = FalconRush:GetSpecialValueInt('rush_range') - 50
    local nManaAfter = Fu.GetManaAfter(FalconRush:GetManaCost())
    local nDistance = bot:GetAttackRange()

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nRushRange)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not Fu.IsEnemyBlackHoleInLocation(botTarget:GetLocation())
        and not Fu.IsEnemyChronosphereInLocation(botTarget:GetLocation())
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_troll_warlord_battle_trance')
        then
            if Fu.IsInLaningPhase() then
                if Fu.GetHP(botTarget) < 0.4 and #hNearbyTowers <= 0 then
                    return BOT_ACTION_DESIRE_HIGH
                end
                return BOT_ACTION_DESIRE_NONE
            end
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsFarming(bot)
    and not Fu.IsThereNonSelfCoreNearby(1200)
    and nManaAfter > 0.4
    then
        local nCreeps = bot:GetNearbyCreeps(nDistance, true)
        if #nCreeps >= 2
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsPushing(bot) and nManaAfter > 0.3 then
        if Fu.IsValidBuilding(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 300)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingRoshan(bot) then
        if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nManaAfter > 0.25
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        and nManaAfter > 0.25
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderTalonToss()
    if not Fu.CanCastAbility(TalonToss) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, TalonToss:GetCastRange())
    local nRadius = TalonToss:GetSpecialValueInt('radius')
    local nDamage = TalonToss:GetSpecialValueInt('damage')

    for _, enemy in pairs(hEnemyList) do
        if Fu.IsValidHero(enemy)
        and Fu.CanCastOnNonMagicImmune(enemy)
        and Fu.CanCastOnTargetAdvanced(enemy)
        and Fu.IsInRange(bot, enemy, nCastRange)
        and Fu.CanKillTarget(enemy, nDamage, DAMAGE_TYPE_MAGICAL)
        and not enemy:HasModifier('modifier_abaddon_borrowed_time')
        and not enemy:HasModifier('modifier_dazzle_shallow_grave')
        and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
        and not enemy:HasModifier('modifier_oracle_false_promise_timer')
        and not enemy:HasModifier('modifier_troll_warlord_battle_trance')
        then
            return BOT_ACTION_DESIRE_HIGH, enemy
        end
    end

    if Fu.IsInTeamFight(bot, 1200) then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)
        for _, enemy in pairs(nInRangeEnemy) do
            if Fu.IsValidHero(enemy)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and not Fu.IsDisabled(enemy)
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemy:HasModifier('modifier_troll_warlord_battle_trance')
            then
                hEnemyList = Fu.GetEnemiesNearLoc(enemy:GetLocation(), nRadius)
                if #hEnemyList >= 2 then
                    return BOT_ACTION_DESIRE_HIGH, enemy
                end
            end
        end
    end

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_troll_warlord_battle_trance')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsLaning(bot)
	and Fu.GetManaAfter(TalonToss:GetManaCost()) > 0.3
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
		for _, creep in pairs(nEnemyLaneCreeps) do
			if  Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and not Fu.IsInRange(bot, creep, bot:GetAttackRange() * 2.5)
			and Fu.IsKeyWordUnit('ranged', creep)
			and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			then
				if Fu.IsValidHero(hEnemyList[1])
				and not Fu.IsSuspiciousIllusion(hEnemyList[1])
				and Fu.IsInRange(creep, hEnemyList[1], 550)
				then
                    return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderShodoSai()
    if not Fu.CanCastAbility(ShodoSai) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	if bRetreating and not Fu.IsRealInvisible(bot)
	then
		local nAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 900)
		if #nAllyHeroes >= 1 then
			local numFacing = 0
			local nEnemyHeroes = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
			for _, enemy in pairs(nEnemyHeroes) do
				if Fu.IsValidHero(enemy)
				and Fu.CanCastOnMagicImmune(enemy)
				and bot:IsFacingLocation(enemy:GetLocation(), 30)
                and (enemy:GetAttackTarget() == bot or Fu.IsChasingTarget(enemy, bot))
				and not Fu.IsDisabled(enemy)
				then
					numFacing = numFacing + 1
				end
			end

			if numFacing >= 1 and #nEnemyHeroes > #nAllyHeroes then
                return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]:GetLocation()
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderShodoSaiCancel()
    if not Fu.CanCastAbility(ShodoSaiCancel) then
        return BOT_ACTION_DESIRE_NONE
    end

    if bRetreating and not Fu.IsRealInvisible(bot)
	then
		local nAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 900)
		if #nAllyHeroes >= 1 then
			local nFacing = 0
			local nEnemyHeroes = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
			for _, enemy in pairs(nEnemyHeroes) do
				if  Fu.IsValidHero(enemy)
				and Fu.CanCastOnMagicImmune(enemy)
				and bot:IsFacingLocation(enemy:GetLocation(), 15)
				and not Fu.IsDisabled(enemy)
				then
					nFacing = nFacing + 1
				end
			end

			if nFacing < 1 and #nEnemyHeroes < #nAllyHeroes then
                return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderRavensVeil()
    if not Fu.CanCastAbility(RavensVeil) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = RavensVeil:GetSpecialValueInt('blast_radius')

    if Fu.IsInTeamFight(bot, 1200) then
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), nRadius * 0.6)
        if (Fu.IsLateGame() and #nInRangeEnemy >= 3)
        or (not Fu.IsLateGame() and #nInRangeEnemy >= 2)
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderSwitchDiscipline()
    if not Fu.CanCastAbility(SwitchWeapons) then
        return BOT_ACTION_DESIRE_NONE
    end
    -- Don't switch while we have ability points to spend (leveling depends on current mode)
    if bot:GetAbilityPoints() > 0 then
        return BOT_ACTION_DESIRE_NONE
    end

    -- Going on someone: switch to sai for FalconRush engage + TalonToss disable
    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, 1200)
        and Fu.GetMP(bot) > 0.25
        and bot.kez_mode == 'katana'
        then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    -- Retreating: switch to katana (EchoSlash dash away, GrapplingClaw escape)
    if bRetreating and not Fu.IsRealInvisible(bot) then
        if bot.kez_mode == 'sai' then
            -- Only if we have TalonToss available (disable chaser before switching)
            if Fu.CanCastAbility(TalonToss) or not bot:WasRecentlyDamagedByAnyHero(2) then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    -- Laning/Pushing: stay in katana (better for last hitting and wave clear with EchoSlash)
    if Fu.IsLaning(bot) or Fu.IsPushing(bot) then
        if bot.kez_mode == 'sai' then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    -- Farming/Roshan/Tormentor: switch to sai (FalconRush attack speed buff)
    if Fu.IsFarming(bot)
    or Fu.IsDoingRoshan(bot)
    or Fu.IsDoingTormentor(bot)
    then
        if bot.kez_mode == 'katana' then
            return BOT_ACTION_DESIRE_HIGH
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.DoCombo()
    if bot.kez_mode == 'sai' then
        if bot:HasScepter() and not Fu.CanCastAbility(FalconRush) then
            if Fu.CanCastAbility(RavensVeil) and not bot:IsRooted() then
                local nManaCost_falconRush = 0 -- FalconRush:GetManaCost()
                local nManaCost_ravensVeil = RavensVeil:GetManaCost()
                local nManaCost_grapplingClaw = 50
                local nManaCost_echoSlash = 85  -- + (15 * (FalconRush:GetLevel() - 1))

                if Fu.GetManaAfter(nManaCost_falconRush + nManaCost_ravensVeil + nManaCost_grapplingClaw + nManaCost_echoSlash) > 0.1 then
                    local nCastRange = 700 + (100 * (TalonToss:GetLevel() - 1))

                    local target = nil
                    local targetDamage = 0

                    local nEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), nCastRange)

                    for _, enemy in pairs(nEnemyHeroes) do
                        if bGoingOnSomeone then
                            if Fu.IsValidHero(enemy)
                            and Fu.IsInRange(bot, enemy, nCastRange)
                            and Fu.CanBeAttacked(enemy)
                            and Fu.CanCastOnTargetAdvanced(enemy)
                            and not enemy:HasModifier('modifier_abaddon_borrowed_time')
                            and not enemy:HasModifier('modifier_dazzle_shallow_grave')
                            and not enemy:HasModifier('modifier_enigma_black_hole_pull')
                            and not enemy:HasModifier('modifier_faceless_void_chronosphere_freeze')
                            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
                            and not enemy:HasModifier('modifier_oracle_false_promise_timer')
                            and not enemy:HasModifier('modifier_troll_warlord_battle_trance')
                            and not enemy:HasModifier('modifier_ursa_enrage')
                            then
                                local nInRangeAlly = enemy:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
                                local nInRangeEnemy = enemy:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
                                local enemyDamage = enemy:GetAttackDamage() * enemy:GetAttackSpeed() + enemy:GetEstimatedDamageToTarget(false, bot, 4.0, DAMAGE_TYPE_ALL)
                                if enemyDamage > targetDamage and #nInRangeAlly >= #nInRangeEnemy and not (#nInRangeAlly >= #nInRangeEnemy + 2) then
                                    target = enemy
                                    targetDamage = enemyDamage
                                end
                            end
                        end
                    end

                    if Fu.IsValidHero(target) then
                        local nDistFromTarget = GetUnitToUnitDistance(bot, target)
                        local eta = nDistFromTarget / 1800 + nDistFromTarget / 3000

                        bot:Action_ClearActions(false)
                        -- bot:ActionQueue_UseAbility(FalconRush)
                        bot:ActionQueue_UseAbility(RavensVeil)
                        bot:ActionQueue_Delay(0.3)
                        bot:ActionQueue_UseAbility(SwitchWeapons)
                        bot:ActionQueue_UseAbilityOnEntity(GrapplingClaw, target)
                        bot:ActionQueue_Delay(eta)
                        bot:ActionQueue_UseAbility(EchoSlash)
                        return
                    end
                end
            end
        end
    end
end

-- Find best grappling target (tree or creep) towards a destination for mobility.
-- Searches trees first, then creeps, prioritizing furthest target in the right direction.
function X.GetBestGrapplingTargetTowardsLocation(nCastRange, vTargetLocation)
	local nTrees = bot:GetNearbyTrees(math.min(nCastRange, 1600))
	local botLocation = bot:GetLocation()
	local targetDir = (vTargetLocation - botLocation):Normalized()
	local nMinDistance = nCastRange * 0.5
	local nConeAngle = 45

	local bestTarget = nil
	local bestTargetDistance = 0

	-- Trees
	for i = #nTrees, 1, -1 do
		if nTrees[i] then
			local vTreeLocation = GetTreeLocation(nTrees[i])
			local treeDir = (vTreeLocation - botLocation):Normalized()
			local fDot = Fu.DotProduct(targetDir, treeDir)

			if fDot >= math.cos(math.rad(nConeAngle)) then
				local nBotTreeDist = GetUnitToLocationDistance(bot, vTreeLocation)
				if nBotTreeDist > nMinDistance then
					local nBotTargetDist = GetUnitToLocationDistance(bot, vTargetLocation)
					local nTreeTargetDist = Fu.GetDistance(vTreeLocation, vTargetLocation)
					if nTreeTargetDist < nBotTargetDist and nBotTreeDist > bestTargetDistance then
						bestTarget = nTrees[i]
						bestTargetDistance = nBotTreeDist
					end
				end
			end
		end
	end

	if bestTarget ~= nil then
		return bestTarget, 'tree'
	end

	-- Enemy creeps
	local nEnemyCreeps = bot:GetNearbyCreeps(math.min(nCastRange, 1600), true)
	bestTarget = nil
	bestTargetDistance = 0

	for i = #nEnemyCreeps, 1, -1 do
		if Fu.IsValid(nEnemyCreeps[i]) and Fu.CanCastOnTargetAdvanced(nEnemyCreeps[i]) then
			local vCreepLocation = nEnemyCreeps[i]:GetLocation()
			local creepDir = (vCreepLocation - botLocation):Normalized()
			local fDot = Fu.DotProduct(targetDir, creepDir)

			if fDot >= math.cos(math.rad(nConeAngle)) then
				local nBotCreepDist = GetUnitToUnitDistance(bot, nEnemyCreeps[i])
				if nBotCreepDist > nMinDistance then
					local nBotTargetDist = GetUnitToLocationDistance(bot, vTargetLocation)
					local nCreepTargetDist = GetUnitToLocationDistance(nEnemyCreeps[i], vTargetLocation)
					if nCreepTargetDist < nBotTargetDist and nBotCreepDist > bestTargetDistance then
						bestTarget = nEnemyCreeps[i]
						bestTargetDistance = nBotCreepDist
					end
				end
			end
		end
	end

	if bestTarget ~= nil then
		return bestTarget, 'unit'
	end

	return nil, ''
end

function X.GetBestRetreatGrapplingTarget(nCastRange)
	local nTrees = bot:GetNearbyTrees(math.min(nCastRange, 1600))

	local bestRetreatTree = nil
	local bestRetreatTreeDist = 0
	local bestRetreatTreeFountainDist = 100000

	local vTeamFountain = Fu.GetTeamFountain()
	local botLoc = bot:GetLocation()

	local vToFountain = (vTeamFountain - botLoc):Normalized()

    -- Tree
	for i = #nTrees, 1, -1 do
		if nTrees[i] then
			local vTreeLoc = GetTreeLocation(nTrees[i])

            local currDist1 = GetUnitToLocationDistance(bot, vTreeLoc)
            local currDist2 = Fu.GetDistance(vTeamFountain, vTreeLoc)
            local vToTree = (vTreeLoc - botLoc):Normalized()
            local fDot = Fu.DotProduct(vToTree, vToFountain)

            if fDot >= math.cos(45)
            and currDist1 > bestRetreatTreeDist
            and currDist2 < bestRetreatTreeFountainDist then
                bestRetreatTreeDist = currDist1
                bestRetreatTreeFountainDist = currDist2
                bestRetreatTree = nTrees[i]
            end
		end
	end

	if bestRetreatTree ~= nil and bestRetreatTreeDist > nCastRange * 0.4 then
		return bestRetreatTree, 'tree'
	end

    -- Unit
    local bestRetreatCreep = nil
	local bestRetreatCreepDist = 0
	local bestRetreatCreepFountainDist = 100000
    local nEnemyCreeps = bot:GetNearbyCreeps(nCastRange, true)
    for i = #nEnemyCreeps, 1, -1 do
		if Fu.IsValid(nEnemyCreeps[i]) and not Fu.IsInRange(bot, nEnemyCreeps[1], nCastRange * 0.4) then
			local vCreepLoc = nEnemyCreeps[i]:GetLocation()

            local currDist1 = GetUnitToLocationDistance(bot, vCreepLoc)
            local currDist2 = Fu.GetDistance(vTeamFountain, vCreepLoc)
            local vToTree = (vCreepLoc - botLoc):Normalized()
            local fDot = Fu.DotProduct(vToTree, vToFountain)

            if fDot >= math.cos(45)
            and currDist1 > bestRetreatCreepDist
            and currDist2 < bestRetreatCreepFountainDist then
                bestRetreatCreepDist = currDist1
                bestRetreatCreepFountainDist = currDist2
                bestRetreatCreep = nEnemyCreeps[i]
            end
		end
	end

    if bestRetreatCreep ~= nil then
		return bestRetreatCreep, 'unit'
	end

	return nil, ''
end

return X