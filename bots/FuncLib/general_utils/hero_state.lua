-- Hero state queries: disabled, modifiers, movement, action states
local function Init(Fu)


function Fu.HasQueuedAction( bot )
	if bot ~= GetBot() then return false end
	return bot:NumQueuedActions() > 0
end


function Fu.IsTryingtoUseAbility(bot)
	if not Fu.IsUnitValid(bot) then return false end
	return bot:IsCastingAbility()
	or bot:IsUsingAbility()
	or bot:IsChanneling()
end


function Fu.CanNotUseAction( bot )
	if not Fu.IsUnitValid(bot) then return false end
	return not bot:IsAlive()
			or Fu.HasQueuedAction( bot )
			or (bot:IsInvulnerable() and not bot:HasModifier('modifier_fountain_invulnerability') and not bot:HasModifier('modifier_dazzle_nothl_projection_soul_debuff'))
			or bot:IsCastingAbility()
			or bot:IsUsingAbility()
			or bot:IsChanneling()
			or (bot:IsStunned() and not bot:HasModifier('modifier_dazzle_nothl_projection_soul_debuff'))
			or bot:IsNightmared()
			or bot:HasModifier( 'modifier_ringmaster_the_box_buff' )
			or bot:HasModifier( 'modifier_item_forcestaff_active' )
			or bot:HasModifier( 'modifier_phantom_lancer_phantom_edge_boost' )
			or bot:HasModifier( 'modifier_tinker_rearm' )

end


function Fu.CanNotUseAbility( bot )
	if not Fu.IsUnitValid(bot) then return false end
	return not bot:IsAlive()
			or Fu.HasQueuedAction( bot )
			or (bot:IsInvulnerable() and not bot:HasModifier('modifier_fountain_invulnerability') and not bot:HasModifier('modifier_dazzle_nothl_projection_soul_debuff'))
			or bot:IsCastingAbility()
			or bot:IsUsingAbility()
			or bot:IsChanneling()
			or bot:IsSilenced()
			or (bot:IsStunned() and not bot:HasModifier('modifier_dazzle_nothl_projection_soul_debuff'))
			or bot:IsHexed()
			or bot:IsNightmared()
			or bot:HasModifier( 'modifier_ringmaster_the_box_buff' )
			or bot:HasModifier( "modifier_doom_bringer_doom" )
			or bot:HasModifier( 'modifier_item_forcestaff_active' )

end


local DotModifiers = {
    'modifier_viper_corrosive_skin_slow',
    'modifier_viper_poison_attack_slow',
    'modifier_venomancer_poison_sting_debuff',
    'modifier_venomancer_venomous_gale',
    'modifier_huskar_burning_spear_debuff',
    'modifier_doom_bringer_scorched_earth_effect_enemy',
    'modifier_jakiro_liquid_fire_burn',
    'modifier_pudge_rot',
    'modifier_queenofpain_shadow_strike',
    'modifier_ancient_apparition_ice_blast',
    'modifier_item_radiance_debuff',
    'modifier_item_urn_damage',
    'modifier_item_spirit_vessel_damage',
    'modifier_ogre_magi_ignite',
    'modifier_batrider_napalm',
}

function Fu.HasDamageOverTimeDebuff(bot)
    if not Fu.IsUnitValid(bot) then return false end
    for _, mod in pairs(DotModifiers) do
        if bot:HasModifier(mod) then return true end
    end
    return false
end

-- Cooldown tracking for deaggro/deny to avoid getting stuck
local _deaggroCooldown = {}
local _denyCooldown = {}

local function isOnCooldown(tbl, bot, cd)
    local key = bot:GetPlayerID()
    if tbl[key] and DotaTime() < tbl[key] then return true end
    return false
end

local function setCooldown(tbl, bot, cd)
    tbl[bot:GetPlayerID()] = DotaTime() + cd
end

-- Drop tower aggro by A-clicking an ally unit near the tower
-- Returns true if deaggro action was taken
function Fu.TryDropTowerAggro(bot)
    if isOnCooldown(_deaggroCooldown, bot, 0) then return false end
    local towers = bot:GetNearbyTowers(900, true)
    if towers == nil or #towers == 0 then return false end
    for _, tower in pairs(towers) do
        if Fu.IsValidBuilding(tower) and tower:GetAttackTarget() == bot then
            -- Try ally creep first
            local allyCreeps = bot:GetNearbyLaneCreeps(1600, false)
            for _, creep in pairs(allyCreeps) do
                if Fu.IsValid(creep) and GetUnitToUnitDistance(creep, tower) <= 700 then
                    bot:Action_AttackUnit(creep, false)
                    setCooldown(_deaggroCooldown, bot, 1.5)
                    return true
                end
            end
            -- Try ally hero
            local allyHeroes = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE) or {}
            for _, ally in pairs(allyHeroes) do
                if Fu.IsValidHero(ally) and ally ~= bot
                and GetUnitToUnitDistance(ally, tower) <= 700 then
                    bot:Action_AttackUnit(ally, false)
                    setCooldown(_deaggroCooldown, bot, 1.5)
                    return true
                end
            end
            -- No ally nearby — move away
            local safeLoc = Fu.AdjustLocationWithOffsetTowardsFountain(bot:GetLocation(), 500)
            bot:Action_MoveToLocation(safeLoc)
            setCooldown(_deaggroCooldown, bot, 1.5)
            return true
        end
    end
    return false
end

-- Deny ally tower (T1/T2 only) when below threshold
function Fu.TryDenyTower(bot)
    if isOnCooldown(_denyCooldown, bot, 0) then return false end
    local towers = bot:GetNearbyTowers(700, false)
    if towers == nil then return false end
    local team = GetTeam()
    for _, tower in pairs(towers) do
        if Fu.IsValidBuilding(tower) and Fu.CanBeAttacked(tower)
        and tower ~= GetTower(team, TOWER_TOP_3)
        and tower ~= GetTower(team, TOWER_MID_3)
        and tower ~= GetTower(team, TOWER_BOT_3)
        and tower ~= GetTower(team, TOWER_BASE_1)
        and tower ~= GetTower(team, TOWER_BASE_2)
        and not tower:HasModifier('modifier_backdoor_protection')
        and not tower:HasModifier('modifier_backdoor_protection_in_base')
        and tower:GetHealth() < tower:GetMaxHealth() * 0.07
        then
            bot:Action_AttackUnit(tower, false)
            return true
        end
    end
    return false
end

-- Deny ally hero under lethal debuffs
function Fu.TryDenyAllyHero(bot)
    if isOnCooldown(_denyCooldown, bot, 0) then return false end
    local allies = bot:GetNearbyHeroes(700, false, BOT_MODE_NONE)
    if allies == nil then return false end
    for _, ally in pairs(allies) do
        if Fu.IsValidHero(ally) and ally ~= bot and Fu.CanBeAttacked(ally)
        and Fu.GetHP(ally) < 0.05
        and (ally:HasModifier('modifier_doom_bringer_doom')
            or ally:HasModifier('modifier_queenofpain_shadow_strike')
            or ally:HasModifier('modifier_venomancer_venomous_gale')
            or ally:HasModifier('modifier_venomancer_poison_sting_debuff'))
        then
            bot:Action_AttackUnit(ally, false)
            setCooldown(_denyCooldown, bot, 2.0)
            return true
        end
    end
    return false
end

local TempMovableModifierNames = {
    'modifier_abaddon_borrowed_time',
    'modifier_dazzle_shallow_grave',
    'modifier_wind_waker', -- movability depends on whether who uses the item.
    'modifier_item_wind_waker',
    'modifier_oracle_false_promise_timer',
    'modifier_item_aeon_disk_buff'
}
local MovableUndyingModifierRemain = 0

-- check if the target will still have at least one movable undying modifier after nDelay seconds.
function Fu.HasMovableUndyingModifier(botTarget, nDelay)
	if not Fu.IsUnitValid(botTarget) then return false end
    for _, mName in pairs(TempMovableModifierNames)
    do
        if botTarget:HasModifier(mName) then
            MovableUndyingModifierRemain = Fu.GetModifierTime(botTarget, mName)
            -- log(DotaTime().." - Target has undying modifier "..mName..", the remaining time: " .. tostring(MovableUndyingModifierRemain) .. " seconds, check delay: "..tostring(nDelay))
            if MovableUndyingModifierRemain > 0 then
				if MovableUndyingModifierRemain > nDelay then
					return true
				end
				return false
            end
        end
    end
    return false
end

--友军生物数量


function Fu.IsWithoutTarget( bot )
	if not Fu.IsUnitValid(bot) then return false end

	return bot:CanBeSeen()
			and bot:GetAttackTarget() == nil
			and ( bot:GetTeam() == GetBot():GetTeam() and bot:GetTarget() == nil ) 
end



function Fu.IsUnderLongDurationStun(enemyHero)
	if not Fu.IsUnitValid(enemyHero) then return false end
    return enemyHero:HasModifier('modifier_bane_fiends_grip')
    or enemyHero:HasModifier('modifier_legion_commander_duel')
    or enemyHero:HasModifier('modifier_enigma_black_hole_pull')
    or enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
    or enemyHero:HasModifier('modifier_magnataur_reverse_polarity')
    or enemyHero:HasModifier('modifier_tidehunter_ravage')
	or enemyHero:HasModifier('modifier_winter_wyvern_winters_curse_aura')
end


function Fu.IsInEtherealForm( npcTarget )
	if not Fu.IsUnitValid(npcTarget) then return false end
	return npcTarget:HasModifier( "modifier_ghost_state" )
    or npcTarget:HasModifier( "modifier_item_ethereal_blade_ethereal" )
    or npcTarget:HasModifier( "modifier_necrolyte_death_seeker" )
    or npcTarget:HasModifier( "modifier_necrolyte_sadist_active" )
    or npcTarget:HasModifier( "modifier_pugna_decrepify" )
end



function Fu.HasForbiddenModifier( npcTarget )
	if not Fu.IsUnitValid(npcTarget) then return false end

	for _, mod in pairs( Fu.Buff['enemy_is_immune'] )
	do
		if npcTarget:HasModifier( mod )
		then
			return true
		end
	end

	if npcTarget:IsHero()
	then
		local enemies = Fu.GetNearbyHeroes(npcTarget, 800, false, BOT_MODE_NONE )
		if enemies ~= nil and #enemies >= 2
		then
			for _, mod in pairs( Fu.Buff['enemy_is_undead'] )
			do
				if npcTarget:HasModifier( mod )
				then
					return true
				end
			end
		end
		
		-- 有的玩家太菜了，特地加一个判断让这个玩家舒服一点
		if not npcTarget:IsBot()
		then
			local nID = npcTarget:GetPlayerID()
			local nKillCount = GetHeroKills( nID )
			local nDeathCount = GetHeroDeaths( nID )
			if nDeathCount >= 6
				and nKillCount <= 6
				and nKillCount / nDeathCount <= 0.3
			then
				return true
			end
		end
		
	else
		if npcTarget:HasModifier( "modifier_crystal_maiden_frostbite" )
			or npcTarget:HasModifier( "modifier_fountain_glyph" )
		then
			return true
		end
	end
	
	return false
end



function Fu.ShouldEscape( bot )
	if not Fu.IsUnitValid(bot) then return false end

	local tableNearbyAttackAllies = Fu.GetNearbyHeroes(bot, 800, false, BOT_MODE_ATTACK )

	if #tableNearbyAttackAllies > 0 and Fu.GetHP( bot ) > 0.16 then return false end

	local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE )
	if bot:WasRecentlyDamagedByAnyHero( 2.0 )
		or bot:WasRecentlyDamagedByTower( 2.0 )
		or #tableNearbyEnemyHeroes >= 2
	then
		return true
	end
end


function Fu.IsDisabled( npcTarget )
	if not Fu.IsUnitValid(npcTarget) then return false end

	if npcTarget:GetTeam() ~= GetTeam() and npcTarget:CanBeSeen()
	then
		return npcTarget:IsRooted()
				or npcTarget:IsStunned()
				or npcTarget:IsHexed()
				or npcTarget:IsNightmared()
				or Fu.IsTaunted( npcTarget )
	else

		if npcTarget:IsStunned() and Fu.GetRemainStunTime( npcTarget ) > 0.8
		then
			return true
		end

		if npcTarget:IsSilenced()
			and not npcTarget:HasModifier( "modifier_item_mask_of_madness_berserk" )
			and Fu.IsWithoutTarget( npcTarget )
		then
			return true
		end

		return npcTarget:IsRooted()
				or npcTarget:IsHexed()
				or npcTarget:IsNightmared()
				or Fu.IsTaunted( npcTarget )

	end

end




function Fu.IsTaunted( npcTarget )
	if not Fu.IsUnitValid(npcTarget) then return false end
	if not npcTarget:CanBeSeen() then
		return false
	end

	return npcTarget:HasModifier( "modifier_axe_berserkers_call" )
		or npcTarget:HasModifier( "modifier_legion_commander_duel" )
		or npcTarget:HasModifier( "modifier_winter_wyvern_winters_curse" )
		or npcTarget:HasModifier( "modifier_winter_wyvern_winters_curse_aura" )

end




function Fu.IsMoving( bot )
	if not Fu.IsUnitValid(bot) then return false end

	if not bot:IsAlive() then return false end

	local vLocation = bot:GetExtrapolatedLocation( 0.6 )
	if GetUnitToLocationDistance( bot, vLocation ) > bot:GetCurrentMovementSpeed() * 0.45
	then
		return true
	end

	return false

end




function Fu.IsRunning( bot )
	if not Fu.IsUnitValid(bot) then return false end

	if not bot:IsAlive() then return false end

	return bot:GetAnimActivity() == ACTIVITY_RUN

end




function Fu.IsAttacking( bot )
	if not Fu.IsUnitValid(bot) then return false end

	local nAnimActivity = bot:GetAnimActivity()

	if nAnimActivity ~= ACTIVITY_ATTACK
		and nAnimActivity ~= ACTIVITY_ATTACK2
	then
		return false
	end

	if bot:GetAttackPoint() > bot:GetAnimCycle() * 0.99
	then
		return true
	end

	return false
end




function Fu.IsChasingTarget( bot, nTarget )
	if not Fu.IsUnitValid(bot) then return false end

	if Fu.IsRunning( bot )
		and Fu.IsRunning( nTarget )
		and bot:IsFacingLocation( nTarget:GetLocation(), 20 )
		and not nTarget:IsFacingLocation( bot:GetLocation(), 150 )
	then
		return true
	end

	return false

end




function Fu.IsRealInvisible( bot )
	if not Fu.IsUnitValid(bot) then return false end

	local enemyTowerList = bot:GetNearbyTowers( 880, true )

	if bot:IsInvisible()
		and not bot:HasModifier( 'modifier_item_dustofappearance' )
		and not bot:HasModifier( 'modifier_bloodseeker_thirst_vision' )
		and not bot:HasModifier( 'modifier_slardar_amplify_damage' )
		and not bot:HasModifier( 'modifier_sniper_assassinate' )
		and not bot:HasModifier( 'modifier_bounty_hunter_track' )
		and not bot:HasModifier( 'modifier_faceless_void_chronosphere_freeze' )
		and #enemyTowerList == 0
	then
		return true
	end


	return false

end




function Fu.GetModifierTime( bot, sModifierName )
	if not Fu.IsUnitValid(bot) then return 0 end

	if not bot:HasModifier( sModifierName ) then return 0 end

	local npcModifier = bot:NumModifiers()
	for i = 0, npcModifier
	do
		if bot:GetModifierName( i ) == sModifierName
		then
			return bot:GetModifierRemainingDuration( i )
		end
	end

	return 0

end




function Fu.GetModifierCount( bot, sModifierName )
	if not Fu.IsUnitValid(bot) then return 0 end

	if not bot:HasModifier( sModifierName ) then return 0 end

	local npcModifier = bot:NumModifiers()
	for i = 0, npcModifier
	do
		if bot:GetModifierName( i ) == sModifierName
		then
			return bot:GetModifierStackCount( i )
		end
	end

	return 0

end




function Fu.GetUniqueModifierCount( bot, sModifierName )
	if not Fu.IsUnitValid(bot) then return 0 end

	if not bot:HasModifier( sModifierName ) then return 0 end

	local count = 0
	local npcModifier = bot:NumModifiers()
	for i = 0, npcModifier
	do
		if bot:GetModifierName( i ) == sModifierName
		then
			count = count + 1
		end
	end

	return count

end






function Fu.GetRemainStunTime( bot )
	if not Fu.IsUnitValid(bot) then return 0 end

	if not bot:HasModifier( "modifier_stunned" ) then return 0 end

	local npcModifier = bot:NumModifiers()
	for i = 0, npcModifier
	do
		if bot:GetModifierName( i ) == "modifier_stunned"
		then
			return bot:GetModifierRemainingDuration( i )
		end
	end

	return 0

end



function Fu.CannotBeKilled(bot, botTarget)
	if not Fu.IsUnitValid(bot) then return false end
	return Fu.IsValidHero( botTarget )
	and (
		(Fu.GetModifierTime(botTarget, 'modifier_dazzle_shallow_grave') > 0.6 and Fu.GetHP(botTarget) < 0.15 and (bot == nil or bot:GetUnitName() ~= "npc_dota_hero_axe"))
		or Fu.GetModifierTime(botTarget, 'modifier_oracle_false_promise_timer') > 0.6
		or botTarget:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
		or botTarget:HasModifier('modifier_item_helm_of_the_undying_active')
		or botTarget:HasModifier('modifier_item_aeon_disk_buff')
		or botTarget:HasModifier('modifier_abaddon_borrowed_time')
	)
end


function Fu.CanIgnoreLowHp(bot)
	if not Fu.IsUnitValid(bot) then return false end
	return Fu.GetModifierTime(bot, 'modifier_dazzle_shallow_grave') > 0.6
	or Fu.GetModifierTime(bot, 'modifier_oracle_false_promise_timer') > 0.6
end

-- Per-bot chase fatigue tracking.
-- NOTE: Each bot runs in its own Lua sandbox, so module-level state is per-bot only.
-- Cross-bot coordination uses Valve API (GetAttackTarget, GetActiveMode) not shared Lua state.

-- Score an enemy for target prioritization. Higher score = better target.
-- Uses Valve API for cross-bot coordination (ally:GetAttackTarget()).
-- Per-bot state (chase fatigue) stored on bot handle to survive across ticks.

function Fu.DoesSomeoneHaveModifier(nUnitList, modifierName)
	if not Fu.IsUnitValid(nUnitList) then return false end
	for _, unit in pairs(nUnitList)
	do
		if Fu.IsValid(unit)
		and unit:HasModifier(modifierName)
		then
			return true
		end
	end

	return false
end

-- count the number of human vs bot players in the team. returns: #humen, #bots
function Fu.DoesUnitHaveTemporaryBuff(hUnit)
	if not Fu.IsUnitValid(hUnit) then return false end
	local sUnitName = hUnit:GetUnitName()
	if sUnitName == 'npc_dota_hero_huskar' and Fu.GetHP(hUnit) < 0.6 then
		return true
	end

	for i = 0, hUnit:NumModifiers() do
		local sDuration = hUnit:GetModifierRemainingDuration(i)
		if (sDuration > 0.5)
		or (sDuration > -1 and sDuration < 0.5)
		then
			return true
		end
	end

	return false
end


function Fu.IsUnitWillGoInvisible(unit)
	if not Fu.IsUnitValid(unit) then return false end
	return unit:HasModifier('modifier_sandking_sand_storm')
		or unit:HasModifier('modifier_bounty_hunter_wind_walk')
		or unit:HasModifier('modifier_clinkz_wind_walk')
		or unit:HasModifier('modifier_weaver_shukuchi')
		or (unit:HasModifier('modifier_oracle_false_promise') and unit:HasModifier('modifier_oracle_false_promise_invis'))
		or (unit:HasModifier('modifier_windrunner_windrun') and unit:HasModifier('modifier_windrunner_windrun_invis'))
		or unit:HasModifier('modifier_item_invisibility_edge')
		or unit:HasModifier('modifier_item_invisibility_edge_windwalk')
		or unit:HasModifier('modifier_item_silver_edge')
		or unit:HasModifier('modifier_item_silver_edge_windwalk')
		or unit:HasModifier('modifier_item_glimmer_cape_fade')
		or unit:HasModifier('modifier_item_glimmer_cape')
		or unit:HasModifier('modifier_item_shadow_amulet')
		or unit:HasModifier('modifier_item_shadow_amulet_fade')
		or unit:HasModifier('modifier_item_trickster_cloak_invis')
end


function Fu.HasInvisCounterBuff(unit)
	if not Fu.IsUnitValid(unit) then return false end
	if unit:HasModifier('modifier_item_dustofappearance')
	or unit:HasModifier('modifier_bounty_hunter_track')
	or unit:HasModifier('modifier_bloodseeker_thirst_vision')
	or unit:HasModifier('modifier_slardar_amplify_damage')
	or unit:HasModifier('modifier_sniper_assassinate')
	or unit:HasModifier( 'modifier_faceless_void_chronosphere_freeze' )
	then
		return true
	end

	return false
end


end

return Init
