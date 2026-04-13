local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils')
local Customize = require( GetScriptDirectory()..'/Customize/general' )

local bot = GetBot()
local botName = bot:GetUnitName()

if bot == nil or bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return end

local cAbility = nil
local TinkerShouldWaitInBaseToHeal = false

local ShouldWaitInBaseToHeal = false
local TPScroll = nil

local ShouldMoveCloseTowerForEdict = false
local EdictTowerTarget = nil

local ShouldMoveOutsideFountain = false
local ShouldMoveOutsideFountainCheckTime = 0
local ShouldTPToLane = false
local TPToLaneLocation = nil
local MoveOutsideFountainDistance = 1500
local BearAttackLimitDistance = 1100
local TetherBreakDistance = 1000
local ConsiderHeroSpecificRoaming = {}

local laneToGank = nil
local lastGankDecisionTime = 0
local gankDecisionHoldTime = 30 -- 30s commitment to a gank decision (was 90s — too long, bots wasted laning time)
local TwinGates = Fu.Utils.GameStates.twinGates
local targetGate
local gateWarp = bot:GetAbilityByName("twin_gate_portal_warp")
local enableGateUsage = false -- twin_gate_portal_warp to be fixed
local arriveGankLocTime = 0
local gankTimeAfterArrival = 15 -- 15s stay at gank location (was 33s — too long doing nothing)
local gankGapTime = 3 * 60 -- 3 min between ganks (was 6 min — too restrictive)
local lastStaticLinkDebuffStack = 0
local AnyUnitAffectedByChainFrost = false
local HasPossibleWallOfReplicaAround = false
local ShouldBotsSpreadOut = false
local nChainFrostBounceDistance = 600 + 150
local cachedTombstoneZombieSlowState = 0
local nInRangeEnemy, nInRangeAlly, allyTowers, enemyTowers, trySeduce, shouldTempRetreat, botTarget, shouldGoBackToFountain, nInCloseRangeEnemy, nInCloseRangeAlly

local tangoDesire, tangoTarget, tangoSlot

local laneAndT1s = {
	{LANE_TOP, TOWER_TOP_1},
	{LANE_MID, TOWER_MID_1},
	{LANE_BOT, TOWER_BOT_1}
}

local _roamReason = 'none'
local _lastRoamLog = 0
function GetDesire()
	if ShouldSkipBotThink(GetBot()) then return 0 end
	local res = GetDesireHelper()
	if res > 0 then
		_lastRoamLog = DotaTime()
		log('[ROAM] %s t=%.0f desire=%.2f reason=%s hp=%.2f enemies=%d allies=%d',
			bot:GetUnitName(), DotaTime(), res, _roamReason,
			Fu.GetHP(bot),
			nInRangeEnemy and #nInRangeEnemy or -1,
			nInRangeAlly and #nInRangeAlly or -1)
	end
	return res
end

function GetDesireHelper()
	botName = bot:GetUnitName()
	if bot:IsInvulnerable() or not bot:IsHero() or not bot:IsAlive() or not string.find(botName, "hero") or bot:IsIllusion() then return BOT_MODE_DESIRE_NONE end

	trySeduce = false
	shouldTempRetreat = false
	TPScroll = Fu.Utils.GetItemFromFullInventory(bot, 'item_tpscroll')
	botTarget = Fu.GetProperTarget(bot)
	nInRangeEnemy = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
	nInRangeAlly = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
	nInCloseRangeEnemy = bot:GetNearbyHeroes(1000, true, BOT_MODE_NONE)
	nInCloseRangeAlly = bot:GetNearbyHeroes(1000, false, BOT_MODE_NONE)
	allyTowers = bot:GetNearbyTowers(1600, false)
	enemyTowers = bot:GetNearbyTowers(1600, true)

	-- if ConsiderWaitInBaseToHeal()
	-- and GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) > 5500
	-- then
	-- 	return BOT_ACTION_DESIRE_ABSOLUTE
	-- end

	-- Wraith King scepter / Undying helm: fight aggressively since already "dead"
	if bot:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
	or bot:HasModifier('modifier_item_helm_of_the_undying_active')
	then
		local weakestEnemy = Fu.GetVulnerableWeakestUnit(bot, true, true, bot:GetAttackRange() + 250)
		if Fu.IsValidHero(weakestEnemy) then
			bot:SetTarget(weakestEnemy)
			_roamReason = 'wk_scepter_undying'
			return BOT_MODE_DESIRE_ABSOLUTE * 1.5
		end
	end

	-- tangoDesire, tangoTarget = ConsiderUseTango()
	-- if tangoDesire > 0 and not Fu.IsInLaningPhase() then
	-- 	return BOT_MODE_DESIRE_ABSOLUTE
	-- end

	TinkerShouldWaitInBaseToHeal = TinkerWaitInBaseAndHeal()
	if TinkerShouldWaitInBaseToHeal
	then
		_roamReason = 'tinker_base_heal'
		return BOT_ACTION_DESIRE_ABSOLUTE
	end

	if bot:HasModifier('modifier_fountain_aura_buff') and DotaTime() > 0 and DotaTime() - ShouldMoveOutsideFountainCheckTime < 2 then
		_roamReason = 'fountain_move_outside'
		return Clamp(bot:GetActiveModeDesire() + 0.2, 0, 1.1)
	else
		ShouldMoveOutsideFountain = false
	end

	if ConsiderHeroMoveOutsideFountain() then
		ShouldMoveOutsideFountain = true
		ShouldMoveOutsideFountainCheckTime = DotaTime()
		_roamReason = 'hero_move_outside_fountain'
		return Clamp(bot:GetActiveModeDesire() + 0.2, 0, 1.1)
	end

	-- Ranged core frontline safety: when facing 2+ healthy enemies with no melee
	-- ally in front, take over from attack mode to hold position behind frontline.
	-- Skip during laning phase — dual lanes naturally have 2+ enemies nearby.
	-- shouldTempRetreat = false
	-- if not Fu.IsInLaningPhase()
	-- and bot:GetAttackRange() >= 400 and Fu.IsCore(bot)
	-- and nInRangeEnemy ~= nil and #nInRangeEnemy >= 2
	-- and nInRangeAlly ~= nil and #nInRangeAlly >= 2 then
	-- 	local healthyEnemyCount = 0
	-- 	for _, e in pairs(nInRangeEnemy) do
	-- 		if Fu.IsValidHero(e) and Fu.GetHP(e) >= 0.5 then
	-- 			healthyEnemyCount = healthyEnemyCount + 1
	-- 		end
	-- 	end
	-- 	if healthyEnemyCount >= 2 then
	-- 		local enemyCenter = Fu.GetCenterOfUnits(nInRangeEnemy)
	-- 		local distToEnemies = GetUnitToLocationDistance(bot, enemyCenter)
	-- 		local hasMeleeFrontliner = false
	-- 		for _, ally in pairs(nInRangeAlly or {}) do
	-- 			if Fu.IsValidHero(ally) and ally ~= bot and ally:IsAlive() then
	-- 				local allyDist = GetUnitToLocationDistance(ally, enemyCenter)
	-- 				if allyDist < distToEnemies - 150 then
	-- 					hasMeleeFrontliner = true
	-- 					break
	-- 				end
	-- 			end
	-- 		end
	-- 		if not hasMeleeFrontliner and distToEnemies < bot:GetAttackRange() + 200 then
	-- 			shouldTempRetreat = true
	-- 			_roamReason = 'ranged_frontline_safety'
	-- 			return Clamp(bot:GetActiveModeDesire() + 0.1, 0, 0.99)
	-- 		end
	-- 	end
	-- end

	-- Tower dive prevention is handled in team_roam Think (runs every frame for all bots)

	-- unit special abilities
	local specialRoaming = ConsiderHeroSpecificRoaming[botName]
	if specialRoaming then
		local specialDesire = specialRoaming()
		if specialDesire and specialDesire > 0 then
			_roamReason = 'hero_specific_'..botName
			if specialDesire <= 1 then
				return Clamp(specialDesire, 0, 0.99)
			else
				return specialDesire
			end
		end
	end

	-- general items or conditions.
	local generalRoaming = ConsiderGeneralRoamingInConditions()
	if generalRoaming then
		if generalRoaming > 0 and generalRoaming <= 1 then
			_roamReason = 'general_condition'
			return Clamp(generalRoaming, 0, 0.99)
		else
			_roamReason = 'general_condition_override'
			return generalRoaming
		end
	end

	-- if Fu.IsValidHero(botTarget)
	-- and (Fu.GetModifierTime(botTarget, 'modifier_dazzle_shallow_grave') > 0.5
	-- 	or Fu.GetModifierTime(botTarget, 'modifier_oracle_false_promise_timer') > 0.5
	-- 	or botTarget:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
	-- 	or botTarget:HasModifier('modifier_item_helm_of_the_undying_active'))
	-- and Fu.GetHP(botTarget) < 0.2 and botName ~= "npc_dota_hero_axe"
	-- then
	-- 	local nAttackTarget = Fu.GetAttackableWeakestUnit( bot, bot:GetAttackRange() + 400, true, true )
	-- 	bot:SetTarget( nAttackTarget )
	-- end

	return BOT_MODE_DESIRE_NONE
end

function Think()
    if Fu.CanNotUseAction(bot) then return end

	-- Healing at fountain (walked back, not respawn TP): stay put until healthy
	if bot:HasModifier('modifier_fountain_aura_buff') and ShouldTPToLane == false
	and (Fu.GetHP(bot) < 0.8 or Fu.GetMP(bot) < 0.8) then
		return
	end

	nInRangeEnemy = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)

	-- Ranged core frontline safety: hold position behind melee allies
	if shouldTempRetreat and nInRangeEnemy and #nInRangeEnemy >= 2 then
		local attackRange = bot:GetAttackRange()
		-- Find nearest melee ally to hide behind
		local bestAlly = nil
		local bestDist = math.huge
		local nAlly = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
		for _, ally in pairs(nAlly or {}) do
			if Fu.IsValidHero(ally) and ally ~= bot and ally:GetAttackRange() < 350 and ally:IsAlive() then
				local d = GetUnitToUnitDistance(bot, ally)
				if d < bestDist then
					bestDist = d
					bestAlly = ally
				end
			end
		end

		-- Position: stay behind melee ally relative to enemy center
		if bestAlly ~= nil then
			local enemyCenter = Fu.GetCenterOfUnits(nInRangeEnemy)
			local safePos = Fu.VectorAway(bestAlly:GetLocation(), enemyCenter, 250)
			-- Attack anything in range from safe position, otherwise move there
			local target = Fu.GetAttackableWeakestUnit(bot, attackRange, true, true)
			if target then
				bot:Action_AttackUnit(target, false)
			else
				bot:Action_MoveToLocation(safePos)
			end
			return
		else
			-- No melee ally: back off toward fountain side
			local enemyCenter = Fu.GetCenterOfUnits(nInRangeEnemy)
			local safePos = Fu.VectorAway(bot:GetLocation(), enemyCenter, 200)
			local target = Fu.GetAttackableWeakestUnit(bot, attackRange, true, true)
			if target then
				bot:Action_AttackUnit(target, false)
			else
				bot:Action_MoveToLocation(safePos)
			end
			return
		end
	end

	ThinkIndividualRoaming() -- unit special abilities
	ThinkGeneralRoaming() -- general items or conditions.
	ThinkActualGankingInLanes()

	-- Fallback: if roam is active but no Think function issued an action,
	-- the bot idles at 0.9+ desire blocking retreat. Attack nearest enemy or move to safety.
	if bot:GetCurrentActionType() == BOT_ACTION_TYPE_NONE then
		local enemies = bot:GetNearbyHeroes(bot:GetAttackRange() + 100, true, BOT_MODE_NONE)
		if enemies and #enemies >= 1 and Fu.IsValidHero(enemies[1]) and Fu.CanBeAttacked(enemies[1]) then
			bot:Action_AttackUnit(enemies[1], false)
		else
			-- No target in range: move toward fountain (disengage)
			bot:Action_MoveToLocation(Fu.AdjustLocationWithOffsetTowardsFountain(bot:GetLocation(), 300))
		end
	end
end

function ThinkIndividualRoaming()
	local nBotHP = Fu.GetHP(bot)
	if tangoDesire and tangoDesire > 0 and tangoTarget then
		local hItem = bot:GetItemInSlot( tangoSlot )
		bot:Action_UseAbilityOnTree( hItem, tangoTarget )
		return
	end

	-- Heal in Base
	-- Just for TP. Too much back and forth when "forcing" them try to walk to fountain; <- not reliable and misses farm.
	if ShouldWaitInBaseToHeal
	then
		if GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) > 150
		then
			nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1400)
			if Fu.Item.GetItemCharges(bot, 'item_tpscroll') >= 1
			and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
			then
				if botName == 'npc_dota_hero_furion'
				then
					local Teleportation = bot:GetAbilityByName('furion_teleportation')
					if Teleportation:IsTrained()
					and Teleportation:IsFullyCastable()
					then
						bot:Action_UseAbilityOnLocation(Teleportation, Fu.GetTeamFountain())
						return
					end
				end

				if TPScroll ~= nil
				and not TPScroll:IsNull()
				and TPScroll:IsFullyCastable()
				then
					log('[TP] %s t=%.0f ROAM tp to fountain', bot:GetUnitName(), DotaTime())
					bot:Action_UseAbilityOnLocation(TPScroll, Fu.GetTeamFountain())
					return
				end
			end
		else
			if nBotHP < 0.85 or Fu.GetMP(bot) < 0.85
			then
				bot:Action_MoveToLocation(bot:GetLocation() + 150)
				return
			else
				ShouldWaitInBaseToHeal = false
			end
		end
	end

	-- Tinker: wait in base to heal — walk to fountain instead of clearing actions
	if TinkerShouldWaitInBaseToHeal
	then
		if nBotHP < 0.8 or Fu.GetMP(bot) < 0.8
		then
			bot:Action_MoveToLocation(Fu.GetTeamFountain())
			return
		end
	end

	-- Spirit Breaker
	if bot:HasModifier('modifier_spirit_breaker_charge_of_darkness')
	then
		if bot.chargeRetreat and #nInRangeEnemy == 0 then
			if IsLocationPassable(bot:GetLocation()) then
				bot.chargeRetreat = false
				bot:Action_MoveToLocation(bot:GetLocation() + RandomVector(150))
				return
			end
		end
	end

	-- Batrider
	if bot:HasModifier('modifier_batrider_flaming_lasso_self')
	then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	-- Nyx Assassin
	if bot.canVendettaKill
	then
		if Fu.IsValid(bot.vendettaTarget)
		then
			if GetUnitToUnitDistance(bot, bot.vendettaTarget) > bot:GetAttackRange() + 200
			then
				bot:Action_MoveToLocation(bot.vendettaTarget:GetLocation())
				return
			else
				bot:Action_AttackUnit(bot.vendettaTarget, true)
				return
			end
		end
	end

	-- Rolling Thunder
	if bot:HasModifier('modifier_pangolier_gyroshell')
	then
		if Fu.IsInTeamFight(bot, 1600)
		then
			local target = nil
			local hp = 0
			for _, enemyHero in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES))
			do
				if Fu.IsValidHero(enemyHero)
				and Fu.IsInRange(bot, enemyHero, 2200)
				and Fu.CanBeAttacked(enemyHero)
				and Fu.CanCastOnNonMagicImmune(enemyHero)
				and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
				and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				and hp < enemyHero:GetHealth()
				then
					hp = enemyHero:GetHealth()
					target = enemyHero
				end
			end

			if target ~= nil
			then
				local moveLoc = Fu.GetCorrectLoc(target, 0.2)
				bot:Action_MoveToLocation(moveLoc)
				return
			end
		end

		if Fu.IsRetreating(bot)
		then
			bot:Action_MoveToLocation(Fu.GetTeamFountain())
			return
		end

		local tEnemyHeroes = bot:GetNearbyHeroes(880, true, BOT_MODE_NONE)
		if Fu.IsValidHero(tEnemyHeroes[1])
		and not tEnemyHeroes[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
			bot:Action_MoveToLocation(Fu.GetCorrectLoc(tEnemyHeroes[1], 0.2))
			return
		end

		local tCreeps = bot:GetNearbyCreeps(880, true)
		if Fu.IsValid(tCreeps[1])
		then
			bot:Action_MoveToLocation(Fu.GetCorrectLoc(tCreeps[1], 0.2))
			return
		end
	end

	-- Primal Beast (Trample)
	if bot:HasModifier('modifier_primal_beast_trample') then
		local tAllyHeroes = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
		local tEnemyHeroes = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

		if #tEnemyHeroes > #tAllyHeroes + 1
		or (not Fu.WeAreStronger(bot, 800) and nBotHP < 0.55)
		or (#tEnemyHeroes > 0 and nBotHP < 0.3) then
			TrampleToBase()
			return
		end

		-- bot.trample_status {1 - type, 2 - location, 3 - target, if any}
		if bot.trample_status ~= nil and type(bot.trample_status) == "table" then
			if bot.trample_status[1] == 'engaging' then
				if Fu.IsValidHero(bot.trample_status[3]) then
					DoTrample(Fu.GetCorrectLoc( bot.trample_status[3], 0.2 ))
					return
				elseif #tEnemyHeroes > 0 then
					local target = nil
					local hp = 0
					for _, enemyHero in pairs(tEnemyHeroes) do
						if Fu.IsValidHero(enemyHero)
						and Fu.IsInRange(bot, enemyHero, 2200)
						and Fu.CanBeAttacked(enemyHero)
						and Fu.CanCastOnNonMagicImmune(enemyHero)
						and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
						and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
						and hp < enemyHero:GetHealth()
						then
							hp = enemyHero:GetHealth()
							target = enemyHero
						end
					end

					if target ~= nil then
						DoTrample(Fu.GetCorrectLoc( target, 0.2 ))
						return
					end
				else
					if #tAllyHeroes >= #tEnemyHeroes and Fu.WeAreStronger(bot, 800) then
						for _, ally in pairs(tAllyHeroes) do
							if Fu.IsValidHero(ally) and not Fu.IsSuspiciousIllusion(ally) then
								local allyTarget = ally:GetAttackTarget()
								if Fu.IsValidHero(allyTarget) then
									DoTrample(Fu.GetCorrectLoc( allyTarget, 0.2 ))
									return
								end
							end
						end
					end
				end
				-- TrampleToBase()
				return
			elseif bot.trample_status[1] == 'retreating' then
				TrampleToBase()
				return
			elseif bot.trample_status[1] == 'farming' or bot.trample_status[1] == 'laning' then
				local tCreeps = bot:GetNearbyCreeps(1200, true)
				if Fu.IsValid(tCreeps[1]) and Fu.CanBeAttacked(tCreeps[1])
				then
					local nLocationAoE = bot:FindAoELocation(true, false, tCreeps[1]:GetLocation(), 0, 300, 0, 0)
					if nLocationAoE.count > 0 then
						DoTrample(nLocationAoE.targetloc)
						return
					end
				else
					TrampleToBase()
					return
				end
			elseif bot.trample_status[1] == 'miniboss' then
				if Fu.IsValid(bot.trample_status[3]) then
					DoTrample(bot.trample_status[2])
					return
				else
					TrampleToBase()
					return
				end
			end
		end
		TrampleToBase()
		return
	end

	-- Primal Beast (Onslaught)
	if bot:HasModifier('modifier_primal_beast_onslaught_windup')
	or bot:HasModifier('modifier_prevent_taunts')
	or bot:HasModifier('modifier_primal_beast_onslaught_movement_adjustable')
	then
		if bot.onslaught_status ~= nil then
			if bot.onslaught_status[1] == 'engage' then
				if Fu.IsValidHero(bot.onslaught_status[2]) then
					bot:Action_MoveToLocation(Fu.GetCorrectLoc(bot.onslaught_status[2], 0.3))
					return
				else
					local target = nil
					local targetHealth = math.huge
					for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
						if Fu.IsValidHero(enemy)
						and Fu.IsInRange(bot, enemy, 1600)
						and Fu.CanBeAttacked(enemy)
						and not Fu.IsEnemyBlackHoleInLocation(enemy:GetLocation())
						and not Fu.IsEnemyChronosphereInLocation(enemy:GetLocation())
						and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
						then
							local enemyHealth = enemy:GetHealth()
							if enemyHealth < targetHealth then
								targetHealth = enemyHealth
								target = enemy
							end
						end
					end

					if target ~= nil then
						bot:Action_MoveToLocation(Fu.GetCorrectLoc(target, 0.3))
						return
					end

					for i = 1, #GetTeamPlayers( GetTeam() ) do
						local member = GetTeamMember(i)
						if Fu.IsValidHero(member)
						and Fu.IsInRange(bot, member, 1600)
						then
							local memberTarget = member:GetAttackTarget()
							if Fu.IsValidHero(memberTarget)
							and Fu.IsInRange(bot, memberTarget, 1600)
							and not Fu.IsEnemyBlackHoleInLocation(memberTarget:GetLocation())
							and not Fu.IsEnemyChronosphereInLocation(memberTarget:GetLocation())
							and not memberTarget:HasModifier('modifier_necrolyte_reapers_scythe')
							then
								bot:Action_MoveToLocation(Fu.GetCorrectLoc(memberTarget, 0.3))
								return
							end
						end
					end
				end
			end
		elseif bot.onslaught_status[1] == 'retreat' then
			bot:Action_MoveToLocation(bot.onslaught_status[2])
			return
		elseif bot.onslaught_status[1] == 'farm' then
			local nCreeps = bot:GetNearbyCreeps(800, true)
			if Fu.IsValid(nCreeps[1])
			and not Fu.IsRunning(nCreeps[1])
			and Fu.CanBeAttacked(nCreeps[1])
			then
				local nLocationAoE = bot:FindAoELocation(true, false, nCreeps[1]:GetLocation(), 0, 200, 0, 0)
				if ((#nCreeps >= 4 and nLocationAoE.count >= 4))
				or (#nCreeps >= 2 and nLocationAoE.count >= 2 and nCreeps[1]:IsAncientCreep())
				then
					bot:Action_MoveToLocation(nLocationAoE.targetloc)
					return
				end
			end
		end
	end

	-- Phoenix
	if bot:HasModifier('modifier_phoenix_sun_ray')
	then
		local nRadius = 130
		local nBeamDistance = 1150
		local vBeamEndLoc = Fu.GetFaceTowardDistanceLocation(bot, nBeamDistance)

		if Fu.IsValidHero(bot.sun_ray_target) then
			bot:Action_MoveToLocation(bot.sun_ray_target:GetLocation())
			return
		end

		-- beam other enemy
		local tEnemyHeroes = bot:GetNearbyHeroes(nBeamDistance, true, BOT_MODE_NONE)
		for _, enemy in pairs(tEnemyHeroes) do
			if Fu.IsValidHero(enemy)
			and Fu.CanCastOnNonMagicImmune(enemy)
			and not enemy:HasModifier('modifier_abaddon_borrowed_time')
			and not enemy:HasModifier('modifier_dazzle_shallow_grave')
			and not enemy:HasModifier('modifier_necrolyte_reapers_scythe') then
				bot.sun_ray_target = enemy
				bot:Action_MoveToLocation(enemy:GetLocation())
				return
			end
		end

		-- heal ally
		local tInRangeAlly = bot:GetNearbyHeroes(nBeamDistance, false, BOT_MODE_NONE)
		for _, ally in pairs(tInRangeAlly)
		do
			if Fu.IsValidHero(ally)
			and bot ~= ally
			and Fu.GetHP(ally) < 0.5
			and ally:WasRecentlyDamagedByAnyHero(3.5)
			and not ally:IsIllusion()
			and bot:IsFacingLocation(ally:GetLocation(), 60)
			then
				if not Fu.IsRunning(ally)
				or ally:IsStunned()
				or ally:IsRooted()
				or ally:IsHexed()
				or ally:HasModifier('modifier_bane_fiends_grip')
				or ally:HasModifier('modifier_faceless_void_chronosphere_freeze')
				or ally:HasModifier('modifier_enigma_black_hole_pull') then
					bot.sun_ray_target = ally
					bot:Action_MoveToLocation(ally:GetLocation())
					return
				end
			end
		end
	end

	-- Snapfire
	if bot:HasModifier('modifier_snapfire_mortimer_kisses')
	then
		local nKissesTarget = GetMortimerKissesTarget()

		if nKissesTarget ~= nil
		then
			local eta = (GetUnitToUnitDistance(bot, nKissesTarget) / 1300) + 0.3
			bot:Action_MoveToLocation(Fu.GetCorrectLoc(nKissesTarget, eta))
			return
		end
	end

	-- Leshrac
	if ShouldMoveCloseTowerForEdict
	then
		if EdictTowerTarget ~= nil
		then
			if GetUnitToUnitDistance(bot, EdictTowerTarget) > 350
			then
				bot:Action_MoveToLocation(EdictTowerTarget:GetLocation())
				return
			end
		end
	end

	-- Void Spirit
	if bot:HasModifier('modifier_void_spirit_dissimilate_phase')
	then
		local botTarget = Fu.GetProperTarget(bot)

		if Fu.IsGoingOnSomeone(bot)
		then
			if Fu.IsValidTarget(botTarget)
			then
				bot:Action_MoveToLocation(botTarget:GetLocation())
			end
		end

		if Fu.IsRetreating(bot)
		then
			bot:Action_MoveToLocation(Fu.GetEscapeLoc())
		end

		return
	end

	-- Marci
	if bot:HasModifier("modifier_marci_unleash") then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) > bot:GetAttackRange() + 200
		then
			bot:Action_MoveToLocation(botTarget:GetLocation())
			return
		else
			bot:Action_AttackUnit(botTarget, false)
			return
		end
	end

	if bot:HasModifier("modifier_muerta_pierce_the_veil_buff")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) > bot:GetAttackRange() + 200
		then
			bot:Action_MoveToLocation(botTarget:GetLocation())
			return
		else
			bot:Action_AttackUnit(botTarget, false)
			return
		end
	end

	if bot:HasModifier('modifier_razor_static_link_buff') then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) then
			local distanceFromHero = GetUnitToUnitDistance(bot, botTarget)
			if distanceFromHero > bot:GetAttackRange()
			then
				bot:Action_MoveToLocation(botTarget:GetLocation() + RandomVector(200))
				return
			elseif distanceFromHero <= bot:GetAttackRange() / 2 then
				bot:Action_AttackUnit(botTarget, false)
				return
			end
		end
	end

	if bot:HasModifier("modifier_faceless_void_chronosphere")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) > bot:GetAttackRange() + 200
		then
			bot:Action_MoveToLocation(botTarget:GetLocation())
			return
		else
			bot:Action_AttackUnit(botTarget, false)
			return
		end
	end

	-- Leshrac
	if bot:HasModifier("modifier_leshrac_pulse_nova")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) > 400
		then
			bot:Action_MoveToLocation(botTarget:GetLocation())
			return
		else
			bot:ActionQueue_AttackUnit(botTarget, false)
			return
		end
	end

	if bot:HasModifier("modifier_wisp_tether")
	and Fu.IsValid(bot.stateTetheredHero) then
		if GetUnitToUnitDistance(bot, bot.stateTetheredHero) > TetherBreakDistance - 400 then
			bot:Action_MoveToLocation(bot.stateTetheredHero:GetLocation())
			return
		else
			local botTarget = Fu.GetProperTarget(bot)
			if Fu.IsValidTarget(botTarget) then
				bot:ActionQueue_AttackUnit(botTarget, false)
			end
			return
		end
	end

	if botName == 'npc_dota_hero_lone_druid_bear' then
		if Fu.IsTryingtoUseAbility(bot) then return BOT_MODE_DESIRE_NONE end

		local hero = Fu.Utils.GetLoneDruid(bot).hero
		-- local hasUltimateScepter = Fu.Item.HasItem(bot, 'item_ultimate_scepter') or bot:HasModifier('modifier_item_ultimate_scepter_consumed')
		local distanceFromHero = GetUnitToUnitDistance(Fu.Utils.GetLoneDruid(bot).hero, bot)
		local target = hero:GetAttackTarget() or Fu.GetProperTarget(hero) or Fu.GetProperTarget(bot)

		if distanceFromHero > BearAttackLimitDistance
		then
			bot:Action_MoveToLocation(hero:GetLocation())
			return
		end

		local avoidDangerous = (#bot:GetNearbyLaneCreeps(400, true) < 3 and #bot:GetNearbyTowers(800, true) == 0) or bot:GetLevel() >= 3
		if Fu.Utils.IsValidUnit(target)
		and distanceFromHero <= BearAttackLimitDistance
		and GetUnitToUnitDistance(hero, target) < BearAttackLimitDistance + 250
		and avoidDangerous then
			if GetUnitToUnitDistance(hero, target) > hero:GetAttackRange() + 200 then
				bot:Action_MoveToLocation(target:GetLocation())
				return
			else
				bot:Action_AttackUnit(target, false)
				return
			end
		end

		target = Fu.GetAttackableWeakestUnitFromList(hero, hero:GetNearbyHeroes(BearAttackLimitDistance + 250, true, BOT_MODE_NONE))
		if target ~= nil
		and avoidDangerous
		then
			bot:Action_AttackUnit(target, false)
			return
		end
		return
	end

	if botName == 'npc_dota_hero_pudge' then
		local Rot = bot:GetAbilityByName('pudge_rot')
		if Rot:GetToggleState()
		then
			local botTarget = Fu.GetProperTarget(bot)
			if Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) > 400
			then
				bot:Action_MoveToLocation(botTarget:GetLocation())
				return
			end
		end
		bot:ActionQueue_AttackUnit(botTarget, false)
	end

	if botName == 'npc_dota_hero_nevermore' then
		if Fu.Utils.IsTruelyInvisible(bot) then
			local botTarget = Fu.GetProperTarget(bot)
			if Fu.IsValidTarget(botTarget) and GetUnitToUnitDistance(bot, botTarget) > 400
			then
				bot:Action_MoveToLocation(botTarget:GetLocation())
				return
			end
		end
	end
end

local trample_step = 12
local trample = {}
function DoTrample(vLoc)
	trample = Fu.Utils.GetCirclarPointsAroundCenterPoint(vLoc, 300, 12)
	if trample_step < 12 then
		bot:Action_MoveToLocation(trample[trample_step])
		trample_step = trample_step + 1
	else
		trample_step = 1
	end
end
function TrampleToBase()
	trample_step = 12
	trample = {}
	bot:Action_MoveToLocation(Fu.GetTeamFountain())
end

function ThinkGeneralRoaming()
	local nBotHP = Fu.GetHP(bot)

	-- TP back to lane (flag set by GetDesire)
	if ShouldTPToLane and TPToLaneLocation ~= nil then
		local tpScroll = Fu.Utils.GetItemFromFullInventory(bot, 'item_tpscroll')
		if Fu.CanCastAbility(tpScroll) then
			log('[TP] %s t=%.0f ROAM tp to lane at (%.0f,%.0f)', bot:GetUnitName(), DotaTime(), TPToLaneLocation.x, TPToLaneLocation.y)
			bot:Action_UseAbilityOnLocation(tpScroll, TPToLaneLocation)
			ShouldTPToLane = false
			return
		end
	end

	-- Get out of fountain if in item mode
	if ShouldMoveOutsideFountain
	then
		bot:Action_AttackMove(Fu.Utils.GetOffsetLocationTowardsTargetLocation(Fu.GetTeamFountain(), Fu.GetEnemyFountain(), MoveOutsideFountainDistance))
		return
	end

	if shouldGoBackToFountain then
		if bot:HasModifier('modifier_fountain_aura_buff')
		   or (nBotHP > 0.8 and Fu.GetMP(bot) > 0.7) then
			shouldGoBackToFountain = false
		end
	end

	if AnyUnitAffectedByChainFrost then
		Fu.Utils.SmartSpreadOut(bot, nChainFrostBounceDistance, nChainFrostBounceDistance, nInRangeEnemy, false)
		return
	end

	if HasPossibleWallOfReplicaAround then
		Fu.Utils.MoveBotSafely(bot)
		return
	end

	if ShouldBotsSpreadOut then
		Fu.Utils.SmartSpreadOut(bot, 450, 450, nInRangeEnemy, false)
		return
	end

	if bot:GetActiveMode() == BOT_MODE_ITEM
	and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH
	and (botName == 'npc_dota_hero_lone_druid_bear' or bot:HasModifier('modifier_arc_warden_tempest_double') or Fu.IsMeepoClone(bot))
	then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_item_mask_of_madness_berserk") then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValid(botTarget) then
			if GetUnitToUnitDistance(bot, botTarget) > bot:GetAttackRange() + 200
			then
				bot:Action_MoveToLocation(botTarget:GetLocation())
				return
			else
				bot:Action_AttackUnit(botTarget, false)
				return
			end
		end
	end

	if Fu.GetModifierTime(bot, "modifier_flask_healing") >= 1 then
		if #(bot:GetNearbyHeroes(1000, true, BOT_MODE_NONE) or {}) >= 1 and nBotHP < 0.8 then
			bot:Action_MoveToLocation(Fu.GetTeamFountain())
			return
		end
	end

	if bot:HasModifier("modifier_skeleton_king_reincarnation_scepter_active") or bot:HasModifier("modifier_item_helm_of_the_undying_active") then
		local botTarget = Fu.GetProperTarget(bot)
		if not Fu.IsValid() then
			botTarget = Fu.GetVulnerableWeakestUnit(bot, true, true, bot:GetAttackRange() + 350)
		else
			if GetUnitToUnitDistance(bot, botTarget) > bot:GetAttackRange() + 200
			then
				bot:Action_MoveToLocation(botTarget:GetLocation())
				return
			else
				bot:Action_AttackUnit(botTarget, false)
				return
			end
		end
	end

	if bot:HasModifier("modifier_nevermore_shadowraze_debuff") then
		MoveAwayFromTarget(GetTargetEnemy("npc_dota_hero_nevermore"), 1350)
		return
	end

	if bot:HasModifier("modifier_razor_static_link_debuff") then
		MoveAwayFromTarget(GetTargetEnemy("npc_dota_hero_razor"), 1200)
		return
	end

	if bot:HasModifier("modifier_primal_beast_trample") then
		MoveAwayFromTarget(GetTargetEnemy("npc_dota_hero_primal_beast"), 1200)
		return
	end

	if botName == 'npc_dota_hero_lone_druid' then
		if nBotHP < 0.65 or Fu.GetMP(bot) < 0.35 then
			bot:Action_MoveToLocation(Fu.GetTeamFountain()); return
		end
	end

	if bot:HasModifier("modifier_ursa_fury_swipes_damage_increase") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_monkey_king_quadruple_tap_counter") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_slark_essence_shift_debuff_counter") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_silencer_glaives_of_wisdom_debuff_counter") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_dazzle_poison_touch") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_maledict") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_viper_poison_attack_slow") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if Fu.GetModifierCount(bot, "modifier_huskar_burning_spear_debuff") >= 3 then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if Fu.GetModifierCount(bot, "modifier_batrider_sticky_napalm") >= 3 then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if bot:HasModifier("modifier_undying_tombstone_zombie_deathstrike_slow") then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if Fu.GetModifierCount(bot, "modifier_bristleback_quill_spray") >= 3 then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if trySeduce then
		allyTowers = bot:GetNearbyTowers(1600, false)
		if allyTowers[1] then
			local distanceFromFountain = GetUnitToLocationDistance(bot, Fu.GetTeamFountain())
			local towerFromFountain = GetUnitToLocationDistance(allyTowers[1], Fu.GetTeamFountain())
			local distanceToTower = GetUnitToUnitDistance(bot, allyTowers[1])
			if distanceFromFountain > towerFromFountain and distanceToTower > 300 then
				bot:Action_MoveToLocation(allyTowers[1]:GetLocation() + RandomVector(150))
			else
				bot:Action_MoveToLocation(Fu.GetTeamFountain())
			end
			return
		end
	end

	if shouldTempRetreat then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end

	if shouldGoBackToFountain then
		bot:Action_MoveToLocation(Fu.GetTeamFountain())
		return
	end
end

function GeneralReactToStackedDebuff(enemyHeroName)
	local enemy = GetTargetEnemy(enemyHeroName)
	if enemy ~= nil then -- nil check is enough here
		if Fu.GetHP(bot) > 0.6 and not Fu.Utils.NumActionTypeInQueue(BOT_ACTION_TYPE_ATTACK) <= 2 then
			bot:ActionImmediate_Ping(enemy:GetLocation().x, enemy:GetLocation().y, true)
			bot:ActionQueue_AttackUnit(enemy, false)
		else
			local fountainLoc = Fu.GetTeamFountain()
			bot:Action_MoveToLocation(fountainLoc)
		end
	end
end

function MoveAwayFromTarget(target, keepDistance)
	if Fu.IsValidHero(target) and GetUnitToUnitDistance(bot, target) < keepDistance then
		if GetUnitToLocationDistance(target, Fu.GetTeamFountain()) > GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) then
			bot:Action_MoveToLocation(Fu.GetTeamFountain())
		else
			bot:Action_MoveToLocation(Fu.Utils.GetOffsetLocationTowardsTargetLocation(target:GetLocation(), bot:GetLocation(), keepDistance * 2))
		end
	end
end

function ActualGankDesire()
	SetupTwinGates()

	if Fu.IsInLaningPhase()
	and not bot:WasRecentlyDamagedByAnyHero(2)
	and (botTarget == nil or #nInRangeEnemy <= 0 or nInRangeEnemy[1] ~= botTarget) then
		local botLvl = bot:GetLevel()
		-- Only gank with strong conditions: high HP/mana, reasonable level
		if (Fu.GetPosition(bot) == 2 and botLvl >= 6 and Fu.GetHP(bot) > 0.8 and Fu.GetMP(bot) > 0.6)
		or (Fu.GetPosition(bot) == 4 and botLvl >= 5 and Fu.GetHP(bot) > 0.7 and Fu.GetMP(bot) > 0.6)
		or (Fu.GetPosition(bot) == 5 and botLvl >= 4 and Fu.GetHP(bot) > 0.7 and Fu.GetMP(bot) > 0.6)
		then
			return CheckLaneToGank(Fu.GetPosition(bot))
		end
	end
	return BOT_MODE_DESIRE_NONE
end

function SetupTwinGates()
	if #TwinGates == 0 then
		for _, unit in pairs(GetUnitList(UNIT_LIST_ALL))
		do
			local name = unit:GetUnitName()
			if name == 'npc_dota_unit_twin_gate'
			then
				table.insert(TwinGates, unit)
				log("Twin gate: " .. name .. ". " .. tostring(unit:GetLocation()))
			end
			if #TwinGates >= 2 then
				break
			end
		end
	end
end

function ThinkActualGankingInLanes()
	if laneToGank ~= nil then
		-- Abort gank if the target lane no longer has enemies (they left)
		local nEnemiesInGankLane = Fu.GetEnemyCountInLane(laneToGank)
		if nEnemiesInGankLane == 0 then
			laneToGank = nil
			-- Gank cancelled — move to assigned lane front instead of standing idle
			bot:Action_MoveToLocation(GetLaneFrontLocation(GetTeam(), bot:GetAssignedLane(), 0))
			return
		end

		local targetLoc = GetLaneFrontLocation(GetTeam(), laneToGank, -300)
		local distanceToGankLoc = GetUnitToLocationDistance(bot, targetLoc)
		if distanceToGankLoc > 5000 then
			if Fu.GetPosition(bot) > 3
			and targetGate ~= nil
			and enableGateUsage
			then
				log('Trying to use gate '..botName)
				local distanceToGate = GetUnitToUnitDistance(bot, targetGate)
				if distanceToGate > 350 then
					bot:Action_MoveToLocation(targetGate:GetLocation())
					return
				elseif gateWarp:IsFullyCastable()
				then
					bot:Action_UseAbilityOnEntity(gateWarp, targetGate)
					return
				end
			end
		end

		if distanceToGankLoc > bot:GetAttackRange() + 300 and bot:WasRecentlyDamagedByAnyHero(1.5) then
			bot:Action_MoveToLocation(targetLoc)
		end
		if distanceToGankLoc < 600 and DotaTime() - arriveGankLocTime > gankTimeAfterArrival * 1.1 then
			arriveGankLocTime = DotaTime()
		end
		if DotaTime() - arriveGankLocTime > gankTimeAfterArrival then
			laneToGank = nil
		end
	end
end

function OnStart()
end

function OnEnd()
	laneToGank = nil
	targetGate = nil
	if shouldGoBackToFountain and IsInHealthyState() then
		shouldGoBackToFountain = false
	end
end

function IsInHealthyState()
	return botName ~= 'npc_dota_hero_huskar' and Fu.GetHP(bot) > 0.7 and Fu.GetMP(bot) > 0.6
end

function CheckLaneToGank(botPosition)

	-- Don't gank if enemies are already near us (we're in a fight)
	if #Fu.GetEnemiesNearLoc(bot:GetLocation(), 800) > 0 then
		return BOT_MODE_DESIRE_NONE
	end

	-- If we committed to a gank, REVALIDATE before continuing
	-- (enemy may have left the lane since we decided)
	if DotaTime() - lastGankDecisionTime <= gankDecisionHoldTime and laneToGank ~= nil then
		local nEnemiesStillThere = Fu.GetEnemyCountInLane(laneToGank)
		if nEnemiesStillThere == 0 then
			-- Enemy left — cancel the gank, go back to what we were doing
			laneToGank = nil
			lastGankDecisionTime = 0
			return BOT_MODE_DESIRE_NONE
		end
		return BOT_ACTION_DESIRE_VERYHIGH
	end

	-- Cores should NOT gank during laning — they lose too much farm/XP
	local nPos = Fu.GetPosition(bot)
	if Fu.IsInLaningPhase() then
		if nPos == 1 or nPos == 2 then
			return BOT_MODE_DESIRE_NONE
		end
	end

	local botLvlTooLow = (nPos == 1 and botLevel < 10) or
		(nPos == 2 and botLevel < 8) or
		(nPos == 3 and botLevel < 8) or
		(nPos == 4 and botLevel < 5) or
		(nPos == 5 and botLevel < 4)

	if (DotaTime() - lastGankDecisionTime < gankGapTime and lastGankDecisionTime ~= 0)
		or botLvlTooLow then
		return BOT_MODE_DESIRE_NONE
	end

	if not HasSufficientMana(300) then
		return BOT_MODE_DESIRE_NONE
	end

	-- Evaluate each lane for gank viability
	local bestLane = nil
	local bestDesire = 0

	for _, lane in pairs(laneAndT1s) do
		local enemyCountInLane = Fu.GetEnemyCountInLane(lane[1])
		if enemyCountInLane > 0 then
			local tTower = GetTower(GetTeam(), lane[2])
			if tTower ~= nil then
				local laneFront = GetLaneFrontLocation(GetTeam(), lane[1], 0)
				local laneFrontToT1Dist = GetUnitToLocationDistance(tTower, laneFront)
				local nInRangeAlly = Fu.GetAlliesNearLoc(laneFront, 1200)
				local botDistToLane = GetUnitToLocationDistance(bot, laneFront)

				-- Skip this lane if it's too far (> 4000 units — would take too long)
				if botDistToLane > 4000 and not Fu.HasItem(bot, 'item_tpscroll') then
					goto continue_lane
				end

				-- Skip if this is our own assigned lane (don't "gank" our own lane)
				if lane[1] == bot:GetAssignedLane() then
					goto continue_lane
				end

				-- Gank conditions: enemy pushed past river (close to our tower)
				-- AND ally present to help — don't gank 1v1
				local bEnemyOverextended = laneFrontToT1Dist < 2000
				local bAllyPresent = #nInRangeAlly >= 1

				if bEnemyOverextended and bAllyPresent then
					local desire = RemapValClamped(botDistToLane, 4000, 600, BOT_ACTION_DESIRE_MODERATE, BOT_ACTION_DESIRE_HIGH)
					-- Bonus desire if enemy is outnumbered
					if enemyCountInLane <= #nInRangeAlly then
						desire = desire + 0.1
					end
					if desire > bestDesire then
						bestDesire = desire
						bestLane = lane[1]
					end
				end
			end
		end
		::continue_lane::
	end

	if bestLane then
		laneToGank = bestLane
		lastGankDecisionTime = DotaTime()
		return Clamp(bestDesire, 0, BOT_ACTION_DESIRE_VERYHIGH)
	end

	return BOT_MODE_DESIRE_NONE
end

function HasSufficientMana(nMana)
	return bot:GetMana() > nMana and botName ~= 'npc_dota_hero_huskar'
end

function GetGateNearLane(laneLoc)
	local minDis = 99999
	local tGate
	for _, gate in pairs(TwinGates)
	do
		local distanceToGate = GetUnitToLocationDistance(gate, laneLoc)
		if distanceToGate < minDis then
			tGate = gate
			minDis = distanceToGate
		end
	end
	return tGate
end


function TinkerWaitInBaseAndHeal()
	if botName == 'npc_dota_hero_tinker'
	and bot.healInBase
	and GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) < 500
	then
		return true
	end

	return false
end

function GetMortimerKissesTarget()
	for _, enemyHero in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES))
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.IsInRange(bot, enemyHero, 3000 + (275 / 2))
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not Fu.IsInRange(bot, enemyHero, 600)
		then
			if Fu.IsLocationInChrono(enemyHero:GetLocation())
			or Fu.IsLocationInBlackHole(enemyHero:GetLocation())
			then
				return enemyHero
			end
		end

		if Fu.IsValidHero(enemyHero)
		and Fu.IsInRange(bot, enemyHero, 3000 + (275 / 2))
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not Fu.IsInRange(bot, enemyHero, 600)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return enemyHero
		end
	end

	local nCreeps = bot:GetNearbyCreeps(1600, true)
	if Fu.IsValid(nCreeps[1])
	then
		return nCreeps[1]
	end

	return nil
end

function ConsiderUseTango()
	if bot:HasModifier('modifier_tango_heal') then return BOT_ACTION_DESIRE_NONE, nil end

	tangoDesire = 0
	tangoSlot = Fu.FindItemSlotNotInNonbackpack(bot, "item_tango")
	if tangoSlot < 0 then
		tangoSlot = Fu.FindItemSlotNotInNonbackpack(bot, "item_tango_single")
	end
	if tangoSlot >= 0
	and bot:OriginalGetMaxHealth() - bot:OriginalGetHealth() > 150
	and Fu.GetHP(bot) < 0.75
	then
		local trees = bot:GetNearbyTrees( 800 )
		local targetTree = trees[1]
		local nearEnemyList = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE )
		local nearestEnemy = nearEnemyList[1]
		local nearTowerList = bot:GetNearbyTowers( 1400, true )
		local nearestTower = nearTowerList[1]
		if targetTree ~= nil
		then
			local targetTreeLoc = GetTreeLocation( targetTree )
			if IsLocationVisible( targetTreeLoc )
				and IsLocationPassable( targetTreeLoc )
				-- and ( #nearEnemyList == 0 or not Fu.IsInRange( bot, nearestEnemy, 800 ) )
				and ( #nearEnemyList == 0 or GetUnitToLocationDistance( bot, targetTreeLoc ) * 1.6 < GetUnitToUnitDistance( bot, nearestEnemy ) )
				and ( #nearTowerList == 0 or GetUnitToLocationDistance( nearestTower, targetTreeLoc ) > 920 )
			then
				return BOT_ACTION_DESIRE_HIGH, targetTree
			end
		end
	end
	return BOT_ACTION_DESIRE_NONE
end

-- Just for TP. Too much back and forth when "forcing" them try to walk to fountain; <- not reliable and misses farm.
function ConsiderWaitInBaseToHeal()
	local ProphetTP = nil
	if botName == 'npc_dota_hero_furion'
	then
		ProphetTP = bot:GetAbilityByName('furion_teleportation')
	end

	if not Fu.IsInLaningPhase()
	and not (Fu.IsFarming(bot) and Fu.IsAttacking(bot))
	and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
	and GetUnitToUnitDistance(bot, GetAncient(GetOpposingTeam())) > 2400
	and (  (TPScroll ~= nil and TPScroll:IsFullyCastable())
		or (ProphetTP ~= nil and ProphetTP:IsTrained() and ProphetTP:IsFullyCastable()))
	then
		if (Fu.GetHP(bot) < 0.25
			and bot:GetHealthRegen() < 15
			and botName ~= 'npc_dota_hero_huskar'
			and botName ~= 'npc_dota_hero_slark'
			and botName ~= 'npc_dota_hero_necrolyte'
			and not bot:HasModifier('modifier_tango_heal')
			and not bot:HasModifier('modifier_flask_healing')
			and not bot:HasModifier('modifier_alchemist_chemical_rage')
			and not bot:HasModifier('modifier_arc_warden_tempest_double')
			and not bot:HasModifier('modifier_juggernaut_healing_ward_heal')
			and not bot:HasModifier('modifier_oracle_purifying_flames')
			and not bot:HasModifier('modifier_warlock_fatal_bonds')
			and not bot:HasModifier('modifier_item_satanic_unholy')
			and not bot:HasModifier('modifier_item_spirit_vessel_heal')
			and not bot:HasModifier('modifier_item_urn_heal'))
		or (((Fu.IsCore(bot) and Fu.GetMP(bot) < 0.25 and (Fu.GetHP(bot) < 0.75 and bot:GetHealthRegen() < 10))
				or ((not Fu.IsCore(bot) and Fu.GetMP(bot) < 0.25 and bot:GetHealthRegen() < 10)))
			and botName ~= 'npc_dota_hero_necrolyte'
			and not (Fu.IsPushing(bot) and #Fu.GetAlliesNearLoc(bot:GetLocation(), 900) >= 3))
		then
			ShouldWaitInBaseToHeal = true
			return true
		end
	end

	return false
end

function ConsiderHeroMoveOutsideFountain()
	if DotaTime() < 0 then return false end
	if bot:DistanceFromFountain() > MoveOutsideFountainDistance then return false end
	-- Don't use roam to move out of fountain when ancient is under threat — let defend handle it
	if Fu.GetEnemiesAroundAncient(bot, 3200) > 0 then return false end

	if ((bot:HasModifier('modifier_fountain_aura_buff') -- in fountain with high hp
		and Fu.GetHP(bot) > 0.95)
	and (botName == 'npc_dota_hero_huskar' -- is huskar (ignore mana)
		or (bot:GetActiveMode() == BOT_MODE_ITEM -- is stuck in item mode
			and Fu.GetMP(bot) > 0.95)))
	then
		return true
	end
	if bot:GetActiveMode() == BOT_MODE_ITEM then
		for _, droppedItem in pairs(GetDroppedItemList()) do
            if droppedItem ~= nil
            and GetUnitToLocationDistance(bot, droppedItem.location) < 1200
            then
				local iName = droppedItem.item:GetName()
				if not (iName == 'item_aegis'
				or iName == 'item_rapier'
				or iName == 'item_cheese'
				or iName == 'item_gem')
				then
					return true
				end
            end
        end
	end

	return false
end

function CanBeAffectedByChainFrost()
	if bot:HasModifier("modifier_black_king_bar_immune") or bot:IsMagicImmune() then
		return false
	end
	local searchRange = nChainFrostBounceDistance
	if Fu.HasEnemyIceSpireNearby(bot, searchRange) then return true end
	if bot:HasModifier('modifier_lich_chainfrost_slow') then
		local allyCreeps = bot:GetNearbyCreeps(searchRange, false)
		if #allyCreeps > 0 then return true end
		local allyHeores = bot:GetNearbyHeroes(searchRange, false, BOT_MODE_NONE)
		if #allyHeores > 1 then return true end
	end
	return Fu.AnyAllyAffectedByChainFrost(bot, searchRange)
end

function ConsiderGeneralRoamingInConditions()
	local nBotHP = Fu.GetHP(bot)
	if nBotHP < 0.35 then
		return BOT_ACTION_DESIRE_NONE
	end

	-- Don't lock roam high when outnumbered in enemy territory (let retreat win)
	if nInRangeEnemy and nInRangeAlly and #nInRangeEnemy > #nInRangeAlly + 1
	and not Fu.WeAreStronger(bot, 1200) then
		return BOT_ACTION_DESIRE_NONE
	end

	-- if not botTarget then
	-- 	botTarget = Fu.GetAttackableWeakestUnit( bot, 1500, true, true )
	-- 	bot:SetTarget( botTarget )
	-- end

	if bot:HasModifier("modifier_item_mask_of_madness_berserk") then
		if Fu.IsValid(botTarget) and nBotHP > 0.3 then
			return BOT_ACTION_DESIRE_ABSOLUTE
		end
	end

	if Fu.GetModifierTime(bot, "modifier_flask_healing") >= 1.5 then
		if #nInCloseRangeEnemy >= 1 and nBotHP < 0.8 then
			return BOT_ACTION_DESIRE_ABSOLUTE
		end
	end

	if bot:HasModifier("modifier_skeleton_king_reincarnation_scepter_active") or bot:HasModifier("modifier_item_helm_of_the_undying_active") then
		if not Fu.IsValidHero(botTarget) then
			botTarget = Fu.GetAttackableWeakestUnit( bot, 1600, true, true )
		end
		if Fu.IsValidHero(botTarget) then
			bot:SetTarget( botTarget )
			return BOT_ACTION_DESIRE_ABSOLUTE * 2
		end
	end

	if bot:HasModifier("modifier_razor_static_link_debuff") then
		local staticLinkDebuffStack = Fu.GetModifierCount( bot, "modifier_razor_static_link_debuff" )
		if staticLinkDebuffStack > lastStaticLinkDebuffStack then
			local enemy = GetTargetEnemy("npc_dota_hero_razor")
			if enemy ~= nil and nBotHP - 0.2 < Fu.GetHP(enemy) and GetUnitToUnitDistance(bot, enemy) <= 850 then
				return BOT_ACTION_DESIRE_ABSOLUTE * 1.1
			end
		end
	end

	if bot:HasModifier("modifier_bloodseeker_rupture") then
		if Fu.IsRunning(bot) and not Fu.IsAttacking(bot) then
			return 0.6
		end
		if not nInCloseRangeEnemy or #nInCloseRangeEnemy == 0 then
			return 0.7
		end
	end

	if botName == 'npc_dota_hero_lone_druid'
	and not bot:HasModifier("modifier_lone_druid_true_form") then
		if nInRangeEnemy and Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.IsInRange(bot, nInRangeEnemy[1], math.max(bot:GetAttackRange(), nInRangeEnemy[1]:GetAttackRange()) - 250) then
			return 0.6
		end
	end

	local quillSparyStack = Fu.GetModifierCount(bot, "modifier_bristleback_quill_spray")
	if quillSparyStack >= 3 then -- 14s
		local enemy = GetTargetEnemy("npc_dota_hero_bristleback")
		if enemy ~= nil
		and (#nInRangeEnemy >= #nInRangeAlly or enemy:GetLevel() >= bot:GetLevel())
		and nBotHP < Fu.GetHP(enemy) + 0.2
		and GetUnitToUnitDistance(bot, enemy) <= 900
		and GetUnitToLocationDistance(bot, Fu.GetTeamFountain()) > 1000 then
			return RemapValClamped(quillSparyStack / nBotHP, 10, 50, BOT_ACTION_DESIRE_LOW, BOT_ACTION_DESIRE_ABSOLUTE)
		end
	end

	if bot:HasModifier("modifier_primal_beast_trample") then
		local enemy = GetTargetEnemy("npc_dota_hero_primal_beast")
		local distanceToEnemy =  GetUnitToUnitDistance(bot, enemy)
		if enemy ~= nil and nBotHP - 0.2 < Fu.GetHP(enemy) and distanceToEnemy <= 500 and distanceToEnemy > 250 then
			return BOT_ACTION_DESIRE_ABSOLUTE
		end
	end

	AnyUnitAffectedByChainFrost = CanBeAffectedByChainFrost()
	if AnyUnitAffectedByChainFrost then
		local hasLowHpEnemy = false
		for _, enemy in pairs(nInCloseRangeEnemy) do
			if Fu.Utils.IsValidHero(enemy)
			and not Fu.IsSuspiciousIllusion(enemy)
			and Fu.GetHP(enemy) < 0.2 then
				hasLowHpEnemy = true
			end
		end
		if not hasLowHpEnemy then
			local crowd = #nInCloseRangeAlly
			local hp = nBotHP
			return Clamp(0.35 + 0.35 * (crowd >= 2 and 1 or 0) + 0.3 * (hp < 0.6 and 1 or 0), 0.35, 0.85)
			-- return RemapValClamped(hp, 0, 0.6, BOT_ACTION_DESIRE_NONE, 0.98)
		end
		AnyUnitAffectedByChainFrost = false
	end

	-- HasPossibleWallOfReplicaAround = Fu.Utils.HasPossibleWallOfReplicaAround(bot)
	-- if HasPossibleWallOfReplicaAround then
	-- 	local hasLowHpEnemy = false
	-- 	for _, enemy in pairs(nInCloseRangeEnemy) do
	-- 		if Fu.Utils.IsValidHero(enemy)
	-- 		and not Fu.IsSuspiciousIllusion(enemy)
	-- 		and Fu.GetHP(enemy) < 0.2 then
	-- 			hasLowHpEnemy = true
	-- 		end
	-- 	end
	-- 	if not hasLowHpEnemy then
	-- 		return BOT_ACTION_DESIRE_ABSOLUTE
	-- 	end
	-- end

	if bot:GetActiveMode() == BOT_MODE_ITEM
	and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH
	and (botName == 'npc_dota_hero_lone_druid_bear' or bot:HasModifier('modifier_arc_warden_tempest_double') or Fu.IsMeepoClone(bot))
	then
		for _, droppedItem in pairs(GetDroppedItemList()) do
            if droppedItem ~= nil
            and droppedItem.item:GetName() == 'item_aegis'
            and GetUnitToLocationDistance(bot, droppedItem.location) < 300
            then
                return BOT_ACTION_DESIRE_ABSOLUTE
            end
        end
	end

	-- 留一个bot抵御超级兵 看家
	-- if Fu.GetHP(GetAncient(bot:GetTeam())) < 0.99 then
		
	-- end

	local isBotInCombat = Fu.IsAttacking(bot)
		or (bot:GetActiveMode() == BOT_MODE_ATTACK and bot:GetActiveModeDesire() > 0.5)
		or bot:WasRecentlyDamagedByAnyHero(2.0)
		or Fu.IsGoingOnSomeone(bot)
		or Fu.IsInTeamFight(bot, 1200)
	ShouldBotsSpreadOut = not isBotInCombat and not Fu.IsInLaningPhase() and Fu.Utils.ShouldBotsSpreadOut(bot, 450)
	if ShouldBotsSpreadOut then
		_roamReason = 'spread_out_aoe'
		return 0.91
	end

	if Fu.IsInLaningPhase() then

		-- 状态不好 回泉水补给
		if not bot:WasRecentlyDamagedByAnyHero(1.5)
		and not Fu.HasHealingItem(bot)
		and botName ~= 'npc_dota_hero_huskar'
		and (
			(shouldGoBackToFountain and not IsInHealthyState())
			or (nBotHP < 0.22 or (nBotHP < 0.3 and Fu.GetMP(bot) < 0.22))
		) then
			shouldGoBackToFountain = true
			return BOT_ACTION_DESIRE_ABSOLUTE * 1.5
		end

		if Fu.GetModifierCount(bot, "modifier_nevermore_shadowraze_debuff") >= 2 then -- 7s
			local enemy = GetTargetEnemy("npc_dota_hero_nevermore")
			if enemy ~= nil and nBotHP < Fu.GetHP(enemy) and GetUnitToUnitDistance(bot, enemy) <= 1200 then
				return BOT_ACTION_DESIRE_VERYHIGH * 1.2
			end
		end

		if Fu.GetModifierCount(bot, "modifier_monkey_king_quadruple_tap_counter") >= 2 then -- 7 - 10s
			local enemy = GetTargetEnemy("npc_dota_hero_monkey_king")
			if enemy ~= nil and nBotHP < Fu.GetHP(enemy) and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 3 then
				return BOT_ACTION_DESIRE_VERYHIGH * 1.2
			end
		end

		if Fu.GetModifierCount(bot, "modifier_viper_poison_attack_slow") >= 2 then -- 4s
			local enemy = GetTargetEnemy("npc_dota_hero_viper")
			if enemy ~= nil and nBotHP < Fu.GetHP(enemy) and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 2 then
				return BOT_ACTION_DESIRE_VERYHIGH * 1.2
			end
		end

		if Fu.GetModifierCount(bot, "modifier_huskar_burning_spear_debuff") >= 3 then -- 9s
			local enemy = GetTargetEnemy("npc_dota_hero_huskar")
			if enemy ~= nil and nBotHP < Fu.GetHP(enemy) + 0.2 and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 2 then
				return BOT_ACTION_DESIRE_VERYHIGH * 1.2
			end
		end

		if Fu.GetModifierCount(bot, "modifier_batrider_sticky_napalm") >= 3 then -- 6s
			local enemy = GetTargetEnemy("npc_dota_hero_batrider")
			if enemy ~= nil and nBotHP < Fu.GetHP(enemy) + 0.2 and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 3 then
				return BOT_ACTION_DESIRE_VERYHIGH * 1.2
			end
		end

		if bot:HasModifier("modifier_undying_tombstone_zombie_deathstrike_slow") then
			cachedTombstoneZombieSlowState = DotaTime()
			if Fu.IsValidTarget(botTarget) and not Fu.Utils.IsUnitWithName(botTarget, "tombstone") then
				local enemy = Fu.FindEnemyUnit("tombstone")
				if not enemy then
					enemy = GetTargetEnemy("npc_dota_hero_undying")
				end
				if nBotHP < 0.8
				and ((Fu.IsValid(enemy) and GetUnitToUnitDistance(enemy, bot) < 1200) or (DotaTime() - cachedTombstoneZombieSlowState < 3))
				and Fu.IsValidHero(nInRangeEnemy[1]) and Fu.GetHP(nInRangeEnemy) > 0.35 then
					return BOT_ACTION_DESIRE_VERYHIGH * 1.2
				end
			end
		end

		-- long duration debuff
		if not Fu.WeAreStronger(bot, 1200) then
			if Fu.GetModifierCount(bot, "modifier_slark_essence_shift_debuff_counter") >= 2 then -- 20 - 80s
				local enemy = GetTargetEnemy("npc_dota_hero_slark")
				if enemy ~= nil and nBotHP < Fu.GetHP(enemy) + 0.1 and GetUnitToUnitDistance(bot, enemy) <= 750 then
					return BOT_ACTION_DESIRE_ABSOLUTE * 1.1
				end
			end

			if Fu.GetModifierCount(bot, "modifier_silencer_glaives_of_wisdom_debuff_counter") >= 2 then -- 20 - 35s
				local enemy = GetTargetEnemy("npc_dota_hero_silencer")
				if enemy ~= nil and nBotHP < 0.5 and nBotHP < Fu.GetHP(enemy) + 0.1 and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 2.5 then
					return BOT_ACTION_DESIRE_HIGH
				end
			end

			if Fu.GetModifierCount(bot, "modifier_ursa_fury_swipes_damage_increase") >= 2 then -- 8 - 20s
				local enemy = GetTargetEnemy("npc_dota_hero_ursa")
				if enemy ~= nil and nBotHP < Fu.GetHP(enemy) + 0.1 and GetUnitToUnitDistance(bot, enemy) <= 450 then
					return BOT_ACTION_DESIRE_VERYHIGH
				end
			end

			if bot:HasModifier("modifier_dazzle_poison_touch") then -- 5s - forever
				local enemy = GetTargetEnemy("npc_dota_hero_dazzle")
				if enemy ~= nil and nBotHP < 0.6 and nBotHP < Fu.GetHP(enemy) + 0.1 and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 2 then
					return BOT_ACTION_DESIRE_VERYHIGH
				end
			end

			if bot:HasModifier("modifier_maledict") then -- 5s - forever
				local enemy = GetTargetEnemy("npc_dota_hero_witch_doctor")
				if enemy ~= nil and nBotHP < 0.6 and nBotHP < Fu.GetHP(enemy) + 0.1 and GetUnitToUnitDistance(bot, enemy) <= enemy:GetAttackRange() * 2 then
					return BOT_ACTION_DESIRE_VERYHIGH * 1.2
				end
			end
		end

		-- 尝试勾引
		if #nInRangeEnemy >= 1
		and #allyTowers >= 1
		and GetUnitToUnitDistance(allyTowers[1], bot) < 1600
		and bot:GetActiveModeDesire() < 0.9
		and #nInRangeAlly <= #nInRangeEnemy then
			for _, enemy in pairs(nInRangeEnemy) do
				if Fu.Utils.IsValidHero(enemy) then
					if enemy:IsFacingLocation(bot:GetLocation(), 45)
					and Fu.IsInRange(bot, enemy, enemy:GetAttackRange() * 1.5 + 550)
					and Fu.GetHP(enemy) > nBotHP - 0.15
					and bot:WasRecentlyDamagedByAnyHero(5)
					and nBotHP < 0.75 and nBotHP > 0.3 -- don't block real retreat action
					then
						trySeduce = true
						return BOT_ACTION_DESIRE_VERYHIGH
					end
				end
			end
		end
	end

	if bot:WasRecentlyDamagedByTower(0.2) then
		if #nInCloseRangeAlly >= 2 and Fu.GetHP(nInCloseRangeAlly[2]) > nBotHP then
			bot:Action_AttackUnit(nInCloseRangeAlly[2], true)
		else
			local allyCreeps = bot:GetNearbyCreeps(1000, false)
			if #allyCreeps >= 1 and Fu.IsValid(allyCreeps[1]) then
				bot:Action_AttackUnit(allyCreeps[1], true)
			end
		end
	end

	-- local actualGankingDesire = ActualGankDesire()
	-- if actualGankingDesire > 0 then
	-- 	lastGankDecisionTime = DotaTime()
	-- 	return actualGankingDesire
	-- end
	return BOT_ACTION_DESIRE_NONE
end

function GetTargetEnemy(unitName)
	for _, enemyHero in pairs(nInRangeEnemy)
	do
		if Fu.IsValidHero(enemyHero) and enemyHero:GetUnitName() == unitName then
			return enemyHero
		end
	end
	return nil
end

-- Hero Channel/Kill/CC abilities
-- ConsiderHeroSpecificRoaming['npc_dota_hero_rubick'] = function ()
-- 	if bot:IsChanneling() or bot:IsUsingAbility() or bot:IsCastingAbility()
-- 	then
-- 		return BOT_MODE_DESIRE_ABSOLUTE
-- 	end
-- 	return BOT_MODE_DESIRE_NONE
-- end

function CheckHighPriorityChannelAbility(abilityName)
	local nBotHP = Fu.GetHP(bot)
	if cAbility == nil then cAbility = bot:GetAbilityByName(abilityName) end;
	if cAbility:IsTrained() and (cAbility:IsInAbilityPhase() or bot:IsChanneling()) then
		return BOT_DESIRE_OVERRIDE * 1.5; -- must beat everything, never cancel channel
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_pugna'] = function ()
	return CheckHighPriorityChannelAbility("pugna_life_drain")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_drow_ranger'] = function ()
	return CheckHighPriorityChannelAbility("drow_ranger_multishot")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_shadow_shaman'] = function ()
	return CheckHighPriorityChannelAbility("shadow_shaman_shackles")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_clinkz'] = function ()
	return CheckHighPriorityChannelAbility("clinkz_burning_barrage")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_tiny'] = function ()
	return CheckHighPriorityChannelAbility("tiny_tree_channel")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_hoodwink'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("hoodwink_sharpshooter") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_hoodwink_sharpshooter_windup') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
end

ConsiderHeroSpecificRoaming['npc_dota_hero_void_spirit'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("void_spirit_dissimilate") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier("modifier_void_spirit_dissimilate_phase")
		then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_elder_titan'] = function ()
	return CheckHighPriorityChannelAbility("elder_titan_echo_stomp")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_primal_beast'] = function ()
	cAbility = bot:GetAbilityByName("primal_beast_onslaught")
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_primal_beast_onslaught_windup') or bot:HasModifier('modifier_prevent_taunts') or bot:HasModifier('modifier_primal_beast_onslaught_movement_adjustable') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end

	cAbility = bot:GetAbilityByName("primal_beast_trample")
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or (bot:HasModifier('modifier_primal_beast_trample') and nBotHP > 0.3) then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end

	cAbility = bot:GetAbilityByName("primal_beast_pulverize")
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_primal_beast_pulverize_self') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_batrider'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("batrider_flaming_lasso") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier("modifier_batrider_flaming_lasso_self")
		then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_enigma'] = function ()
	return CheckHighPriorityChannelAbility("enigma_black_hole")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_keeper_of_the_light'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("keeper_of_the_light_illuminate") end
	if cAbility:IsInAbilityPhase() or bot:IsChanneling() or bot:HasModifier('modifier_keeper_of_the_light_illuminate') then
		return BOT_DESIRE_OVERRIDE * 1.5
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_meepo'] = function ()
	return CheckHighPriorityChannelAbility("meepo_poof")
end

ConsiderHeroSpecificRoaming['npc_dota_hero_monkey_king'] = function ()
	-- Protect Primal Spring channel
	cAbility = bot:GetAbilityByName("monkey_king_primal_spring")
	if cAbility ~= nil and cAbility:IsTrained() then
		if cAbility:IsInAbilityPhase() or bot:IsChanneling() then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end

	-- After landing from Tree Dance, hold position briefly to avoid
	-- erratic movement (tree_dance_status tracks the jump timing)
	if not bot:IsChanneling() and bot.tree_dance_status then
		local eta = bot.tree_dance_status.eta or 0
		local elapsed = DotaTime() - (bot.tree_dance_status.cast_time or 0)
		if elapsed > (3.0 + eta) and elapsed < (4.0 + eta) then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end

	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_nyx_assassin'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("nyx_assassin_vendetta") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_nyx_assassin_vendetta')
		then
			if bot.canVendettaKill
			then
				return BOT_DESIRE_OVERRIDE * 1.5
			end
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_pangolier'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("pangolier_gyroshell") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_pangolier_gyroshell')
		then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_phoenix'] = function ()
	cAbility = bot:GetAbilityByName("phoenix_supernova")
	if cAbility:IsTrained()
	then
		if bot:HasModifier('modifier_phoenix_supernova_hiding') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end

	cAbility = bot:GetAbilityByName("phoenix_sun_ray")
	if cAbility:IsTrained()
	then
		if bot:HasModifier('modifier_phoenix_sun_ray')
		then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
end

ConsiderHeroSpecificRoaming['npc_dota_hero_puck'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("puck_phase_shift") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_puck_phase_shift') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_ringmaster'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("ringmaster_tame_the_beasts") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier("modifier_ringmaster_tame_the_beasts") then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_snapfire'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("snapfire_mortimer_kisses") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_snapfire_mortimer_kisses') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_spirit_breaker'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("spirit_breaker_charge_of_darkness") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:HasModifier('modifier_spirit_breaker_charge_of_darkness') then
			return BOT_DESIRE_OVERRIDE * 1.2
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_windrunner'] = function ()
	return CheckHighPriorityChannelAbility("windrunner_powershot")
end
ConsiderHeroSpecificRoaming['npc_dota_hero_invoker'] = function ()
	if Fu.IsValid(botTarget)
	and GetUnitToUnitDistance(bot, botTarget) < bot:GetAttackRange() - 100
	and (botTarget:HasModifier("modifier_invoker_tornado") or botTarget:HasModifier("modifier_item_wind_waker")
		or botTarget:HasModifier("modifier_eul_cyclone") or botTarget:HasModifier("modifier_item_cyclone") or botTarget:IsInvulnerable())
	and (Fu.GetHP(botTarget) > 0.3 or Fu.GetHP(botTarget) > nBotHP) then
		return BOT_DESIRE_OVERRIDE * 0.96
	end
end

ConsiderHeroSpecificRoaming['npc_dota_hero_tinker'] = function ()
	if cAbility == nil then cAbility = bot:GetAbilityByName("tinker_rearm") end
	if cAbility:IsTrained()
	then
		if cAbility:IsInAbilityPhase() or bot:IsChanneling() or bot:HasModifier('modifier_tinker_rearm') then
			return BOT_DESIRE_OVERRIDE * 1.5
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_leshrac'] = function ()
	if bot:HasModifier("modifier_leshrac_diabolic_edict")
	then
		local DiabolicEdict = bot:GetAbilityByName('leshrac_diabolic_edict')
		if DiabolicEdict:IsTrained()
		then
			local nRadius = DiabolicEdict:GetSpecialValueInt('radius')
			if Fu.IsPushing(bot)
			then
				local nEnemyTowers = bot:GetNearbyTowers(1600, true)
				local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
				if nEnemyTowers ~= nil and #nEnemyTowers >= 1
				and Fu.IsValidBuilding(nEnemyTowers[1])
				and Fu.CanBeAttacked(nEnemyTowers[1])
				and not Fu.IsInRange(bot, nEnemyTowers[1], nRadius - 75)
				and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps <= 2
				then
					EdictTowerTarget = nEnemyTowers[1]
					return BOT_MODE_DESIRE_VERYHIGH
				end
			end
		end
	end

	if bot:HasModifier("modifier_leshrac_pulse_nova")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and nBotHP > Fu.GetHP(botTarget) then
			if GetUnitToUnitDistance(bot, botTarget) > 400
			then
				return BOT_MODE_DESIRE_VERYHIGH
			end
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_lone_druid_bear'] = function ()
	if Fu.IsTryingtoUseAbility(bot) then return BOT_MODE_DESIRE_NONE end

	local hero = Fu.Utils.GetLoneDruid(bot).hero
	local heroTarget = hero:GetAttackTarget()
	local hasUltimateScepter = Fu.Item.HasItem(bot, 'item_ultimate_scepter') or bot:HasModifier('modifier_item_ultimate_scepter_consumed')
    local distanceFromHero = GetUnitToUnitDistance(Fu.Utils.GetLoneDruid(bot).hero, bot)

    if Fu.IsValidHero(hero)
	and nBotHP >= Fu.GetHP(hero) - 0.2 -- hp is higher or within 20% lower than hero.
	and nBotHP > 0.25
	and not hasUltimateScepter
	then
        if distanceFromHero > BearAttackLimitDistance then
			return BOT_DESIRE_OVERRIDE * 1.2
        end
		local avoidDangerous = (#bot:GetNearbyLaneCreeps(400, true) < 3 and #bot:GetNearbyTowers(800, true) == 0) or bot:GetLevel() >= 3
		if Fu.Utils.IsValidUnit(heroTarget)
		and distanceFromHero <= BearAttackLimitDistance
		and GetUnitToUnitDistance(hero, heroTarget) < BearAttackLimitDistance + 250
		and avoidDangerous
		then
			return BOT_DESIRE_OVERRIDE * 1.2
		end

		local target = Fu.GetAttackableWeakestUnitFromList(hero, hero:GetNearbyHeroes(BearAttackLimitDistance + 250, true, BOT_MODE_NONE))
		if target ~= nil
		and avoidDangerous
		then
			return BOT_DESIRE_OVERRIDE * 1.2
		end
    end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_marci'] = function ()
	if bot:HasModifier("modifier_marci_unleash")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and nBotHP > Fu.GetHP(botTarget) then
			if Fu.IsInTeamFight(bot, 1500) then
				return BOT_MODE_DESIRE_VERYHIGH
			end
			if Fu.IsGoingOnSomeone(bot) and #nInRangeEnemy >= 1 then
				return BOT_DESIRE_OVERRIDE * 1.5
			end
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_wisp'] = function ()
	if bot:HasModifier("modifier_wisp_tether") and DotaTime() > 60
	then
		if Fu.IsValid(bot.stateTetheredHero)
		and nBotHP > 0.5
		and GetUnitToUnitDistance(bot, bot.stateTetheredHero) > TetherBreakDistance - 200 then
			return BOT_DESIRE_OVERRIDE * 0.85
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_pudge'] = function ()
	local Rot = bot:GetAbilityByName('pudge_rot')
	if Rot ~= nil and Rot:GetToggleState() and Fu.WeAreStronger(bot, 1200)
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and nBotHP > Fu.GetHP(botTarget) then
			return BOT_DESIRE_OVERRIDE * 0.85
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_muerta'] = function ()
	if bot:HasModifier("modifier_muerta_pierce_the_veil_buff")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and nBotHP > 0.2 then
			if Fu.IsInTeamFight(bot, 1500) then
				return BOT_MODE_DESIRE_VERYHIGH
			end
			if Fu.IsGoingOnSomeone(bot) and #nInRangeEnemy >= 1 then
				return BOT_DESIRE_OVERRIDE * 1.5
			end
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_razor'] = function ()
	if bot:HasModifier("modifier_razor_static_link_buff")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidHero(botTarget) and nBotHP > 0.3 and nBotHP >= Fu.GetHP(botTarget) then
			if enemyTowers == nil or #enemyTowers == 0 or GetUnitToUnitDistance(bot, enemyTowers[1]) > 850 then
				return BOT_MODE_DESIRE_VERYHIGH
			end
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_faceless_void'] = function ()
	if bot:HasModifier("modifier_faceless_void_chronosphere")
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidTarget(botTarget) and nBotHP > 0.25
		and Fu.IsLocationInChrono(botTarget:GetLocation()) then
			return BOT_MODE_DESIRE_VERYHIGH
		end
	end
	return BOT_MODE_DESIRE_NONE
end

ConsiderHeroSpecificRoaming['npc_dota_hero_nevermore'] = function ()
	bot.invisUltCombo = false
	if Fu.Utils.IsTruelyInvisible(bot)
	and bot:GetAbilityByName("nevermore_requiem"):IsFullyCastable()
	then
		local botTarget = Fu.GetProperTarget(bot)
		if Fu.IsValidHero(botTarget) and nBotHP > 0.5 and Fu.GetHP(botTarget) > 0.5 and botTarget:GetHealth() > 800 then
			if enemyTowers == nil or #enemyTowers == 0 or GetUnitToUnitDistance(bot, enemyTowers[1]) > 850 then
				bot.invisUltCombo = true
				return BOT_MODE_DESIRE_VERYHIGH
			end
		end
	end
	return BOT_MODE_DESIRE_NONE
end

-- SafeCall wrapping for error protection
if SafeCall then
  local _origGetDesire = GetDesire
  local _origThink = Think
  if _origGetDesire then GetDesire = SafeCall(_origGetDesire, 0, 'ROAM_GetDesire') end
  if _origThink then Think = SafeCall(_origThink, nil, 'ROAM_Think') end
end
