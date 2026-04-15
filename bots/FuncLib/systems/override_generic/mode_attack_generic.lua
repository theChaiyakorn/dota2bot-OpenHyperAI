-- mode_attack_generic.lua (override for weak/buggy heroes)
local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local X = {}

local bot = GetBot()

local botTarget = {
    unit = nil,
    id = -1,
    location = nil,
    locationFuture = nil,
    hidden1 = false,
    hidden2 = false,
}

local botAttackRange, botHP, botMP, botHealth, botAttackDamage, botAttackSpeed, botActiveModeDesire, botLocation, botName

local bClearMode = false
local fModeCooldown = { time = 0, interval = 0 }

local function IsValid(hUnit)
	return hUnit ~= nil and not hUnit:IsNull() and hUnit:IsAlive()
end

BotsInit = require("game/botsinit")
local Generic = BotsInit.CreateGeneric()

function Generic.OnStart() end
function Generic.OnEnd()
	botTarget.location = nil
	botTarget.locationFuture = nil
	botTarget.hidden1 = false
	botTarget.hidden2 = false
end

--------------------------------------------------------------------
-- GetDesire
--------------------------------------------------------------------
function Generic.GetDesire()
	if not bot:IsAlive()
	or bot:IsIllusion()
	or bot:HasModifier('modifier_fountain_fury_swipes_damage_increase')
	then
		return BOT_MODE_DESIRE_NONE
	end

	if bClearMode then bClearMode = false return 0 end

	-- Laning phase: don't fight when taking heavy creep damage
	if Fu.IsInLaningPhase() then
		local nEnemyCreeps = bot:GetNearbyCreeps(600, true)
		if Fu.IsGoingOnSomeone(bot) and #nEnemyCreeps >= 4 and bot:WasRecentlyDamagedByCreep(3.0) then
			return BOT_MODE_DESIRE_NONE
		end
	end

	botTarget.hidden1 = false
	botTarget.hidden2 = false

	botAttackRange = bot:GetAttackRange()
	botHP = Fu.GetHP(bot)
	botMP = Fu.GetMP(bot)
	botHealth = bot:GetHealth()
	botAttackDamage = bot:GetAttackDamage()
	botAttackSpeed = bot:GetAttackSpeed()
	botName = bot:GetUnitName()
	botLocation = bot:GetLocation()
	local bCore = Fu.IsCore(bot)

	local nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
	local nAllyHeroes_real = Fu.GetAlliesNearLoc(botLocation, 1600)
	local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	local nEnemyHeroes_real = Fu.GetEnemiesNearLoc(botLocation, 1600)
	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
	local nEnemyTowers = bot:GetNearbyTowers(1600, true)

	------------------------------------------------------------
	-- 1) Target selection (unified — used by both desire & Think)
	------------------------------------------------------------
	local target = nil
	local targetScore = 0
	for _, enemy in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemy)
		and Fu.IsInRange(bot, enemy, Max(1200, botAttackRange + 650))
		and not Fu.IsSuspiciousIllusion(enemy)
		and not enemy:HasModifier('modifier_abaddon_borrowed_time')
		and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemy:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
		and not enemy:HasModifier('modifier_troll_warlord_battle_trance')
		and not enemy:HasModifier('modifier_winter_wyvern_cold_embrace')
		then
			local sEnemyName = enemy:GetUnitName()
			local fMultiplier = 1

			-- Hero-specific priority multipliers
			if sEnemyName == 'npc_dota_hero_sniper' then
				fMultiplier = 4
			elseif sEnemyName == 'npc_dota_hero_drow_ranger' then
				fMultiplier = 2
			elseif sEnemyName == 'npc_dota_hero_crystal_maiden' then
				fMultiplier = 2
			elseif sEnemyName == 'npc_dota_hero_jakiro' then
				fMultiplier = 2.5
			elseif sEnemyName == 'npc_dota_hero_lina' then
				fMultiplier = 3
			elseif sEnemyName == 'npc_dota_hero_nevermore' then
				fMultiplier = 3
			elseif sEnemyName == 'npc_dota_hero_bristleback' and not enemy:IsFacingLocation(botLocation, 90) then
				fMultiplier = 0.5
			elseif sEnemyName == 'npc_dota_hero_enchantress' and enemy:GetLevel() >= 6 then
				fMultiplier = 0.5
			end

			-- Modifier-based multipliers
			if enemy:HasModifier('modifier_troll_warlord_battle_trance') then
				fMultiplier = fMultiplier * 0.5
			end
			if enemy:HasModifier('modifier_item_blade_mail_reflect') then
				fMultiplier = fMultiplier * 0.3
			end
			if enemy:HasModifier('modifier_item_aeon_disk_buff') then
				fMultiplier = fMultiplier * 0.5
			end

			-- Core vs support
			if sEnemyName ~= 'npc_dota_hero_bristleback' then
				if Fu.IsCore(enemy) then
					fMultiplier = fMultiplier * 1.5
				else
					fMultiplier = fMultiplier * 0.5
				end
			end

			-- Disabled enemy: free kill opportunity
			if Fu.IsDisabled(enemy) then
				fMultiplier = fMultiplier * 3
			end

			-- Under tower: less attractive
			if Fu.IsEarlyGame() then
				if Fu.IsValidBuilding(nEnemyTowers[1]) and Fu.IsInRange(enemy, nEnemyTowers[1], 800) then
					fMultiplier = fMultiplier * 0.5
				end
			end

			local nInRangeAlly = Fu.GetAlliesNearLoc(enemy:GetLocation(), 1200)
			local fTotalEstimatedAllyDamage = Fu.GetTotalEstimatedDamageToTarget(nInRangeAlly, enemy)
			local fKillPct = Max(fTotalEstimatedAllyDamage / Max(enemy:GetHealth(), 1), 1)
			local fHpFrac = 1 - Fu.GetHP(enemy)
			local baseScore = (0.35 + fHpFrac * 0.65) * Max(fKillPct, 0.15)
			local fRangeFrac = Min(1, botAttackRange / GetUnitToUnitDistance(bot, enemy))
			local enemyScore = baseScore * fRangeFrac * fMultiplier

			if not Fu.CanBeAttacked(enemy) then
				enemyScore = enemyScore * 0.2
			end

			if enemyScore > targetScore then
				target = enemy
				targetScore = enemyScore
			end
		end
	end

	botTarget.unit = target or X.GetWeakestNearbyHero(true, botAttackRange + 700)

	if Fu.IsValidHero(botTarget.unit) then
		botTarget.id = botTarget.unit:GetPlayerID()
		botTarget.location = botTarget.unit:GetLocation()
		botTarget.locationFuture = botTarget.unit:GetExtrapolatedLocation(5.0)
	end

	------------------------------------------------------------
	-- 2) Marci/Muerta special modifier: must fight while active
	------------------------------------------------------------
	if (bot:HasModifier('modifier_marci_unleash') and Fu.GetModifierTime(bot, 'modifier_marci_unleash') > 3)
	or (bot:HasModifier('modifier_muerta_pierce_the_veil_buff') and Fu.GetModifierTime(bot, 'modifier_muerta_pierce_the_veil_buff') > 3)
	then
		if #nEnemyHeroes_real > 0
		and not (#nEnemyHeroes_real >= #nAllyHeroes_real + 2)
		and ((botName == 'npc_dota_hero_muerta' and (botHP > 0.3 or bot:HasModifier('modifier_item_satanic_unholy') or bot:IsAttackImmune()))
			or (botName == 'npc_dota_hero_marci' and (botHP > 0.45 or bot:HasModifier('modifier_item_satanic_unholy') or bot:IsAttackImmune())))
		and Fu.IsValidHero(botTarget.unit)
		then
			bot:SetTarget(botTarget.unit)
			return BOT_MODE_DESIRE_HIGH
		end
	end

	------------------------------------------------------------
	-- 3) Main engagement evaluation
	------------------------------------------------------------
	if Fu.IsValidHero(botTarget.unit)
	and not Fu.IsSuspiciousIllusion(botTarget.unit)
	and not botTarget.unit:HasModifier('modifier_necrolyte_reapers_scythe')
	then
		-- Tower dive cooldown: don't re-engage after a bad dive
		if DotaTime() < fModeCooldown.time + fModeCooldown.interval then
			return BOT_MODE_DESIRE_NONE
		end

		local fCoolOffTime = X.IsRecklesslyDivingTower()
		if fCoolOffTime ~= 0 then
			fModeCooldown.time = DotaTime()
			fModeCooldown.interval = fCoolOffTime
			return BOT_MODE_DESIRE_NONE
		end

		-- Ally damage estimate
		local fAllyDamage = 0
		local fAllyHealth = 0
		local fDamageInterval = (bot:GetLevel() < 6 and 2.5) or 5
		local nUnitList_AlliedHeroes = GetUnitList(UNIT_LIST_ALLIED_HEROES)
		for _, allyHero in ipairs(nUnitList_AlliedHeroes) do
			if Fu.IsValidHero(allyHero)
			and not Fu.IsSuspiciousIllusion(allyHero)
			and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not allyHero:HasModifier('modifier_teleporting')
			and (Fu.IsInLaningPhase() and Fu.IsInRange(allyHero, botTarget.unit, 1600)
				or (not Fu.IsInLaningPhase() and (((GetUnitToUnitDistance(allyHero, botTarget.unit) - allyHero:GetAttackRange()) / allyHero:GetCurrentMovementSpeed()) <= 6.0)))
			then
				local fTimeToReach = Max(0, math.floor((GetUnitToUnitDistance(allyHero, botTarget.unit) - allyHero:GetAttackRange()) / allyHero:GetCurrentMovementSpeed()))
				fAllyDamage = fAllyDamage + allyHero:GetEstimatedDamageToTarget(true, botTarget.unit, fDamageInterval - fTimeToReach, DAMAGE_TYPE_ALL)
				fAllyHealth = fAllyHealth + allyHero:GetHealth()
			end
		end

		-- Ally tower damage on target
		local nAllyTowersNearTarget = botTarget.unit:GetNearbyTowers(350, true)
		if Fu.IsValidBuilding(nAllyTowersNearTarget[1]) and (Fu.IsEarlyGame() or not Fu.CanBeAttacked(nAllyTowersNearTarget[1])) then
			fAllyDamage = fAllyDamage + #nAllyTowersNearTarget * botTarget.unit:GetActualIncomingDamage(nAllyTowersNearTarget[1]:GetAttackDamage() * 3, DAMAGE_TYPE_PHYSICAL)
		end

		-- Enemy damage estimate (only count enemies ACTIVELY targeting/chasing/damaging this bot)
		local fEnemyDamage = 0
		local fEnemyHealth = 0
		local nUnitList_EnemyHeroes = GetUnitList(UNIT_LIST_ENEMY_HEROES)
		for _, enemyHero in ipairs(nUnitList_EnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and ((GetUnitToUnitDistance(enemyHero, botTarget.unit)) / enemyHero:GetCurrentMovementSpeed()) <= 6.0
			and not Fu.IsSuspiciousIllusion(enemyHero)
			then
				if not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				and not enemyHero:HasModifier('modifier_teleporting')
				then
					-- Only count damage from enemies actively engaged with us
					if enemyHero:GetAttackTarget() == bot
					or Fu.IsChasingTarget(enemyHero, bot)
					or bot:WasRecentlyDamagedByHero(enemyHero, 2.0)
					then
						fEnemyDamage = fEnemyDamage + enemyHero:GetEstimatedDamageToTarget(false, bot, fDamageInterval, DAMAGE_TYPE_ALL)
					end
				end
				fEnemyHealth = fEnemyHealth + enemyHero:GetHealth()
			end
		end

		-- Enemy tower damage on us
		nEnemyTowers = bot:GetNearbyTowers(1200, true)
		if Fu.IsValidBuilding(nEnemyTowers[1]) and (Fu.IsEarlyGame() or not Fu.CanBeAttacked(nEnemyTowers[1])) then
			fEnemyDamage = fEnemyDamage + #nEnemyTowers * bot:GetActualIncomingDamage(nEnemyTowers[1]:GetAttackDamage() * 3, DAMAGE_TYPE_PHYSICAL)
		end

		-- Evaluate fight
		if fEnemyHealth > 0 and Fu.IsValidHero(botTarget.unit) then
			local allyDamageRatio = fAllyDamage / Max(botTarget.unit:GetHealth(), 1)
			local enemyDamageRatio = fEnemyDamage / botHealth
			local fFightingDesire = RemapValClamped(allyDamageRatio, 1/3, 2/3, 0, 1.5)
			local fSelfPreservationDesire = RemapValClamped(enemyDamageRatio, 0.5, 1.5, 1.5, 0.5)

			-- Laning: tower aura bonus
			if Fu.IsInLaningPhase() then
				if #nAllyHeroes_real >= #nEnemyHeroes_real then
					if bot:HasModifier('modifier_tower_aura_bonus') then
						fFightingDesire = fFightingDesire + BOT_MODE_DESIRE_LOW
					end
				end
			end

			-- In-range enemy during numbers advantage: boost desire
			if #nAllyHeroes_real >= #nEnemyHeroes_real then
				if Fu.IsValidHero(nEnemyHeroes_real[1])
				and Fu.CanBeAttacked(nEnemyHeroes_real[1])
				and Fu.IsInRange(bot, nEnemyHeroes_real[1], botAttackRange + 150)
				and (not bot:WasRecentlyDamagedByAnyHero(3.0) and not bot:WasRecentlyDamagedByTower(2.0) or Fu.IsInTeamFight(bot, 1200))
				then
					-- Don't fight if a creep is about to die (last hit priority)
					if not (Fu.IsInLaningPhase() and X.IsThereDyingCreepNearby()) then
						botTarget.unit = nEnemyHeroes_real[1]
						fFightingDesire = fFightingDesire + BOT_MODE_DESIRE_HIGH
					end
				end
			end

			-- Oracle False Promise: fight while invulnerable
			if bot:HasModifier('modifier_oracle_false_promise_timer') then
				if (#nAllyHeroes_real >= #nEnemyHeroes_real and allyDamageRatio >= 1/3) or allyDamageRatio >= 0.8 then
					fFightingDesire = fFightingDesire + BOT_MODE_DESIRE_HIGH
				end
			end

			-- Satanic: lifesteal window, must fight
			if bot:HasModifier('modifier_item_satanic_unholy') and Fu.IsInRange(bot, botTarget.unit, botAttackRange - 75) and botHP < 0.6 then
				if (#nAllyHeroes_real >= #nEnemyHeroes_real and allyDamageRatio >= 1/3) or allyDamageRatio >= 0.8 then
					fFightingDesire = fFightingDesire + BOT_MODE_DESIRE_HIGH
				end
			end

			-- Slark Shadow Dance: fight while invisible
			if bot:HasModifier('modifier_slark_shadow_dance') then
				if (#nAllyHeroes_real >= #nEnemyHeroes_real and allyDamageRatio >= 1/3) or allyDamageRatio >= 2/3 then
					fFightingDesire = fFightingDesire + BOT_MODE_DESIRE_HIGH
				end
			end

			local nDesire = RemapValClamped(fFightingDesire * fSelfPreservationDesire, 0, 1, BOT_MODE_DESIRE_NONE, BOT_MODE_DESIRE_VERYHIGH + 0.05)
			if nDesire > BOT_MODE_DESIRE_VERYHIGH then
				bot:SetTarget(botTarget.unit)
				return nDesire
			end
		end
	end

	------------------------------------------------------------
	-- 4) Ally is engaging nearby — join the fight
	------------------------------------------------------------
	for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
		if Fu.IsValidHero(allyHero)
		and bot ~= allyHero
		and not allyHero:IsIllusion()
		and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not allyHero:HasModifier('modifier_teleporting')
		and (Fu.IsInLaningPhase() and Fu.IsInRange(bot, allyHero, 900)
			or (not Fu.IsInLaningPhase() and (((GetUnitToUnitDistance(bot, allyHero)) / bot:GetCurrentMovementSpeed()) <= 11.0)))
		then
			local allyHeroTarget = Fu.GetProperTarget(allyHero)
			if Fu.IsGoingOnSomeone(allyHero) then
				if Fu.IsValidHero(allyHeroTarget) and not Fu.IsSuspiciousIllusion(allyHeroTarget) then
					botTarget.unit = allyHeroTarget
					bot:SetTarget(botTarget.unit)
					return BOT_MODE_DESIRE_VERYHIGH + 0.05
				end

				-- Ally fighting but target not visible
				if Fu.IsInRange(bot, allyHero, 1000) and #nEnemyHeroes_real == 0 then
					botTarget.location = allyHero:GetLocation()
					botTarget.hidden1 = true
					return BOT_MODE_DESIRE_VERYHIGH + 0.05
				end

				-- Human ally pinged nearby enemy
				for i = 1, 5 do
					local member = GetTeamMember(i)
					if member and member == allyHero then
						local ping = member:GetMostRecentPing()
						if ping ~= nil
						and ping.normal_ping
						and GameTime() < ping.time + 5.5
						then
							local nInRangeEnemy = Fu.GetEnemiesNearLoc(ping.location, 300)
							if Fu.IsValidHero(nInRangeEnemy[1]) then
								botTarget.location = ping.location
								return BOT_MODE_DESIRE_VERYHIGH + 0.05
							end
						end
					end
				end
			end
		end
	end

	------------------------------------------------------------
	-- 5) Fog-of-war chase (extrapolated position)
	------------------------------------------------------------
	if #nEnemyHeroes_real == 0 then
		if botTarget.locationFuture then
			for _, id in ipairs(GetTeamPlayers(GetOpposingTeam())) do
				if IsHeroAlive(id) and id == botTarget.id then
					local info = GetHeroLastSeenInfo(id)
					if info then
						local dInfo = info[1]
						if dInfo
						and dInfo.time_since_seen > 0.5
						and dInfo.time_since_seen < 5.0
						and Fu.GetDistance(dInfo.location, botTarget.locationFuture) <= 1200
						and Fu.GetDistance(botLocation, botTarget.locationFuture) <= 1200
						then
							botTarget.hidden2 = true
							return BOT_MODE_DESIRE_VERYHIGH + 0.05
						end
					end
				end
			end
		end
	end

	return BOT_MODE_DESIRE_NONE
end

--------------------------------------------------------------------
-- Think
--------------------------------------------------------------------
function Generic.Think()
	if Fu.CanNotUseAction(bot) then return end

	local nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	local nEnemyTowers = bot:GetNearbyTowers(1600, true)

	-- Escape dangerous modifiers
	if bot:HasModifier('modifier_pugna_life_drain') then
		for _, enemy in ipairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemy)
			and Fu.IsInRange(bot, enemy, 750)
			and not Fu.IsSuspiciousIllusion(enemy)
			and (enemy:GetUnitName() == 'npc_dota_hero_pugna' or enemy:GetUnitName() == 'npc_dota_hero_rubick') then
				bot:Action_MoveToLocation(Fu.VectorAway(botLocation, enemy:GetLocation(), 800))
				return
			end
		end
	elseif bot:HasModifier('modifier_razor_static_link_debuff') then
		for _, enemy in ipairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemy)
			and Fu.IsInRange(bot, enemy, 750)
			and not Fu.IsSuspiciousIllusion(enemy)
			and enemy:GetUnitName() == 'npc_dota_hero_razor' then
				bot:Action_MoveToLocation(Fu.VectorAway(botLocation, enemy:GetLocation(), 800))
				return
			end
		end
	else
		-- Kite Helm of Undying / WK scepter targets
		for _, enemy in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemy) and enemy:GetAttackTarget() == bot
			and (enemy:HasModifier('modifier_item_helm_of_the_undying_active')
				or enemy:HasModifier('modifier_skeleton_king_reincarnation_scepter_active'))
			then
				if Fu.IsInRange(bot, enemy, enemy:GetAttackRange() + 150) then
					bot:Action_MoveToLocation(Fu.VectorAway(botLocation, enemy:GetLocation(), enemy:GetAttackRange() * 2))
					return
				end
			end
		end
	end

	-- Use target from GetDesire; fallback to weakest nearby
	if botTarget.unit == nil then botTarget.unit = X.GetWeakestNearbyHero(true, botAttackRange + 800) end

	if Fu.IsValidHero(botTarget.unit) and Fu.IsInRange(bot, botTarget.unit, 1200) then
		local dist = GetUnitToUnitDistance(bot, botTarget.unit)
		local bIsMuerta = botName == 'npc_dota_hero_muerta'
		local bEtherealForm = Fu.IsInEtherealForm(botTarget.unit)
		local bAttackImmune = botTarget.unit:IsAttackImmune() and (not bEtherealForm or not bIsMuerta)

		if bAttackImmune then
			-- Maintain distance while target is immune
			bot:Action_MoveToLocation(Fu.VectorTowards(botTarget.unit:GetLocation(), botLocation, botAttackRange / 2))
			return
		end

		bot:Action_AttackUnit(botTarget.unit, false)
		return
	end

	-- Hidden target chasing (ally fighting, target not visible)
	if botTarget.hidden1 and botTarget.location then
		bot:Action_MoveToLocation(botTarget.location)
		return
	end

	-- Fog chase (extrapolated position)
	if botTarget.hidden2 and botTarget.locationFuture then
		if GetUnitToLocationDistance(bot, botTarget.locationFuture) > botAttackRange then
			bot:Action_MoveToLocation(botTarget.locationFuture)
			return
		end
	end

	bClearMode = true
end

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------

-- Tower dive check: returns cooldown duration if dive is reckless, 0 otherwise
function X.IsRecklesslyDivingTower()
	if Fu.IsValidHero(botTarget.unit) then
		local nEnemyTowers = bot:GetNearbyTowers(800, true)
		if Fu.IsValidBuilding(nEnemyTowers[1]) then
			local nInRangeAlly = botTarget.unit:GetNearbyHeroes(900, true, BOT_MODE_NONE)

			local ourDamage = 0
			for _, allyHero in pairs(nInRangeAlly) do
				if Fu.IsValidHero(allyHero) and Fu.IsGoingOnSomeone(allyHero) and not Fu.IsSuspiciousIllusion(allyHero) then
					local allyHeroTarget = Fu.GetProperTarget(allyHero)
					if allyHeroTarget == botTarget.unit then
						ourDamage = ourDamage + allyHero:GetAttackDamage() * allyHero:GetAttackSpeed() * (Max(1, 3 - (GetUnitToUnitDistance(allyHero, botTarget.unit) / allyHero:GetCurrentMovementSpeed())))
					end
				end
			end

			if botTarget.unit:GetActualIncomingDamage(ourDamage, DAMAGE_TYPE_PHYSICAL) < (botTarget.unit:GetHealth() + botTarget.unit:GetHealthRegen() * 3) then
				return 2.5
			end
		end
	end

	return 0
end

-- Laning: check if a creep is about to die (last hit priority over harass)
function X.IsThereDyingCreepNearby()
	local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(Min(botAttackRange + 300, 1600), true)
	for _, creep in pairs(nEnemyLaneCreeps) do
		if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
			if creep:GetHealth() < (botAttackDamage + botAttackDamage / 2) then
				return true
			end
		end
	end

	return false
end

function X.GetWeakestNearbyHero(bEnemy, nRadius)
	local weakestHero = nil
	local weakestHeroScore = 0
	local nNearbyHeroes = bot:GetNearbyHeroes(Min(nRadius, 1600), bEnemy, BOT_MODE_NONE)

	for _, hero in ipairs(nNearbyHeroes) do
		if Fu.IsValidHero(hero)
		and not Fu.IsSuspiciousIllusion(hero)
		and not hero:HasModifier('modifier_abaddon_borrowed_time')
		and not hero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not hero:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
		and not hero:HasModifier('modifier_item_helm_of_the_undying_active')
		then
			local heroScore = hero:GetActualIncomingDamage(bot:GetAttackDamage() * bot:GetAttackSpeed() * 3.0, DAMAGE_TYPE_PHYSICAL) / (hero:GetHealth() + hero:GetHealthRegen() * 3.0)
			if heroScore > weakestHeroScore then
				weakestHero = hero
				weakestHeroScore = heroScore
			end
		end
	end

	return weakestHero
end

return Generic
