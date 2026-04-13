local Fu = require(GetScriptDirectory() ..  "/FuncLib/func_utils")
local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')
local X = {}
local bot = nil
local DispelMagicDesire, CycloneDesire, WindWalkDesire, HurlBoulderDesire = 0, 0, 0, 0
local nAllyHeroes, nEnemyHeroes, botTarget

function X.MinionThink(aBot, hMinionUnit)
    bot = aBot
    botTarget = Fu.GetProperTarget(bot)
    nAllyHeroes = hMinionUnit:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = hMinionUnit:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

	if Fu.IsValid(hMinionUnit) then
		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_storm") then
			if (hMinionUnit:IsUsingAbility()) then return end
			DispelMagic = hMinionUnit:GetAbilityByName("brewmaster_storm_dispel_magic")
			Cyclone = hMinionUnit:GetAbilityByName("brewmaster_storm_cyclone")
			WindWalk = hMinionUnit:GetAbilityByName("brewmaster_storm_wind_walk")
			DispelMagicDesire, DispelMagicTarget = UseDispelMagic(hMinionUnit)
			if DispelMagicDesire > 0 then
				hMinionUnit:Action_UseAbilityOnLocation(DispelMagic, DispelMagicTarget)
				return
			end
			CycloneDesire, CycloneTarget = UseCyclone(hMinionUnit)
			if CycloneDesire > 0 then
				hMinionUnit:Action_UseAbilityOnEntity(Cyclone, CycloneTarget)
				return
			end
			WindWalkDesire, WindWalkTarget = UseWindWalk(hMinionUnit)
			if WindWalkDesire > 0 then
				hMinionUnit:Action_UseAbility(WindWalk)
				return
			end
		end
		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_earth") then
			if (hMinionUnit:IsUsingAbility()) then return end
			HurlBoulder = hMinionUnit:GetAbilityByName("brewmaster_earth_hurl_boulder")
			HurlBoulderDesire, HurlBoulderTarget = UseHurlBoulder(hMinionUnit)
			if HurlBoulderDesire > 0 then
				hMinionUnit:Action_UseAbilityOnEntity(HurlBoulder, HurlBoulderTarget)
				return
			end

			-- Earth is the tankiest spirit — retreat at 25% HP (not 30%)
			if hMinionUnit:GetHealth() <= hMinionUnit:GetMaxHealth() * 0.25 then
				hMinionUnit:Action_MoveToLocation(Fu.GetTeamFountain())
				return
			end

			-- Earth spirit is key unit during Primal Split — follow strongest alive ally
			local strongestAlly = nil
			local bestDamage = 0
			for i = 1, 5 do
				local member = GetTeamMember(i)
				if Fu.IsValidHero(member) and member:IsAlive() then
					local dmg = member:GetAttackDamage()
					if dmg > bestDamage then
						bestDamage = dmg
						strongestAlly = member
					end
				end
			end
			if strongestAlly ~= nil then
				local allyEnemies = strongestAlly:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
				if allyEnemies and #allyEnemies >= 1 then
					hMinionUnit:Action_AttackUnit(Fu.GetWeakestUnit(allyEnemies), false)
					return
				end
				if GetUnitToUnitDistance(hMinionUnit, strongestAlly) > 400 then
					hMinionUnit:Action_MoveToLocation(strongestAlly:GetLocation())
					return
				end
			end
		end

		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_fire") then
		end

		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_void") then
			if (hMinionUnit:IsUsingAbility()) then return end
			AstralPull = hMinionUnit:GetAbilityByName("brewmaster_void_astral_pull")
			AstralPullDesire, AstralPullTarget = UseAstralPull(hMinionUnit)
			if AstralPullDesire > 0 then
				hMinionUnit:Action_UseAbility(AstralPull)
				return
			end
		end

        local target = AttackUnits(hMinionUnit)
        if target ~= nil then
            hMinionUnit:Action_AttackUnit(target, false)
            return
        end

        local move_desire, move_location = ConsiderMove(hMinionUnit)
        if move_desire > 0
        then
            hMinionUnit:Action_MoveToLocation(move_location)
            return
        end
	end
end

-- Mode-aware minion attack/move
function AttackUnits(hMinionUnit)
	local mode = bot:GetActiveMode()

	-- Engaging: attack owner's target
	if Fu.IsGoingOnSomeone(bot) and Fu.IsValidHero(botTarget) then
		if GetUnitToUnitDistance(hMinionUnit, botTarget) <= 1600 then
			return botTarget
		end
	end

	-- Retreat / non-combat modes: attack nearby enemies opportunistically, then creeps
	if mode == BOT_MODE_RETREAT
	or mode == BOT_MODE_SECRET_SHOP
	or mode == BOT_MODE_WARD
	or mode == BOT_MODE_RUNE
	then
		local enemies = hMinionUnit:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
		if enemies and #enemies >= 1 then
			return Fu.GetWeakestUnit(enemies)
		end
		local creeps = hMinionUnit:GetNearbyLaneCreeps(1600, true)
		if creeps and #creeps >= 1 then
			return Fu.GetWeakestUnit(creeps)
		end
		return nil
	end

	-- Laning: attack owner's attack target, dodge tower aggro
	if mode == BOT_MODE_LANING then
		-- Flee from enemy tower if being targeted or too close
		local enemyTowers = hMinionUnit:GetNearbyTowers(800, true)
		for _, tower in pairs(enemyTowers) do
			if Fu.IsValidBuilding(tower) then
				local towerTarget = tower:GetAttackTarget()
				if towerTarget == hMinionUnit or GetUnitToUnitDistance(hMinionUnit, tower) <= 700 then
					return nil -- ConsiderMove will handle retreat
				end
			end
		end
		-- Attack what owner is attacking
		local ownerAttackTarget = bot:GetAttackTarget()
		if ownerAttackTarget ~= nil then return ownerAttackTarget end
		-- Harass nearby enemy heroes
		local enemies = hMinionUnit:GetNearbyHeroes(800, true, BOT_MODE_NONE)
		if enemies and #enemies >= 1 then
			-- Flee if enemy is targeting us
			for _, enemy in pairs(enemies) do
				if Fu.IsValidHero(enemy) and enemy:GetAttackTarget() == hMinionUnit then
					return nil
				end
			end
			return Fu.GetWeakestUnit(enemies)
		end
		return nil
	end

	-- Farm: attack creeps
	if mode == BOT_MODE_FARM then
		local creeps = hMinionUnit:GetNearbyLaneCreeps(1600, true)
		if creeps and #creeps >= 1 then return Fu.GetWeakestUnit(creeps) end
		creeps = hMinionUnit:GetNearbyCreeps(1600, true)
		if creeps and #creeps >= 1 then return Fu.GetWeakestUnit(creeps) end
		return nil
	end

	-- Push: creeps > melee rax > ranged rax > towers > ancient
	if Fu.IsPushing(bot) then
		local creeps = hMinionUnit:GetNearbyLaneCreeps(1600, true)
		if creeps and #creeps >= 1 then return Fu.GetWeakestUnit(creeps) end
		local barracks = hMinionUnit:GetNearbyBarracks(1600, true)
		if barracks then
			for _, rax in pairs(barracks) do
				if Fu.IsValidBuilding(rax) and not rax:IsInvulnerable() and string.find(rax:GetUnitName(), 'melee') then
					return rax
				end
			end
			for _, rax in pairs(barracks) do
				if Fu.IsValidBuilding(rax) and not rax:IsInvulnerable() then
					return rax
				end
			end
		end
		local towers = hMinionUnit:GetNearbyTowers(1600, true)
		if towers and #towers >= 1 and Fu.IsValidBuilding(towers[1]) and not towers[1]:IsInvulnerable() then
			return towers[1]
		end
		local ancient = GetAncient(GetOpposingTeam())
		if ancient and Fu.IsValidBuilding(ancient) and not ancient:IsInvulnerable() and GetUnitToUnitDistance(hMinionUnit, ancient) <= 1600 then
			return ancient
		end
		return nil
	end

	-- Defend: kill enemy creeps
	if Fu.IsDefending(bot) then
		local creeps = hMinionUnit:GetNearbyLaneCreeps(1600, true)
		if creeps and #creeps >= 1 then return Fu.GetWeakestUnit(creeps) end
		return nil
	end

	-- Roshan: attack Roshan
	if mode == BOT_MODE_ROSHAN then
		local creeps = hMinionUnit:GetNearbyCreeps(1600, true)
		if creeps then
			for _, c in pairs(creeps) do
				if Fu.IsRoshan(c) then return c end
			end
		end
		return nil
	end

	-- Default: attack heroes > creeps > buildings
	local enemies = hMinionUnit:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
	if enemies and #enemies >= 1 then return Fu.GetWeakestUnit(enemies) end
	local creeps = hMinionUnit:GetNearbyLaneCreeps(1600, true)
	if creeps and #creeps >= 1 then return creeps[1] end
	local towers = hMinionUnit:GetNearbyTowers(1600, true)
	if towers and #towers >= 1 and Fu.IsValidBuilding(towers[1]) then return towers[1] end
	return nil
end

function UseDispelMagic(hMinionUnit)
	if not DispelMagic:IsFullyCastable() then return 0, nil end
	if Fu.CanNotUseAbility(hMinionUnit) then return 0, nil end
	
	local CastRange = DispelMagic:GetCastRange()
	local Radius = DispelMagic:GetSpecialValueInt("radius")
	
	local AoE = bot:FindAoELocation(true, true, hMinionUnit:GetLocation(), CastRange, Radius/2, 0, 0)
	if (AoE.count >= 2) then
		return BOT_ACTION_DESIRE_HIGH, AoE.targetloc
	end
	
	return 0, nil
end

function UseCyclone(hMinionUnit)
	if not Cyclone:IsFullyCastable() then return 0, nil end
	if Fu.CanNotUseAbility(hMinionUnit) then return 0, nil end

	local CastRange = Cyclone:GetCastRange()

	local enemies = hMinionUnit:GetNearbyHeroes(CastRange + 500, true, BOT_MODE_NONE)
	local filteredenemies = Fu.FilterEnemiesForStun(enemies)
	local target = nil

	-- Interrupt channeling enemies (highest priority)
	for _, enemy in pairs(enemies) do
		if Fu.IsValidTarget(enemy) and enemy:IsChanneling()
		and Fu.IsNotImmune(enemy)
		and not Fu.IsReflectingSpells(enemy)
		then
			target = enemy
			break
		end
	end

	-- When engaging: cyclone strongest enemy that ISN'T the main target (peel)
	if target == nil and Fu.IsGoingOnSomeone(bot) then
		local mainTarget = botTarget
		for _, enemy in pairs(filteredenemies) do
			if Fu.IsValidHero(enemy) and enemy ~= mainTarget
			and not enemy:IsMagicImmune()
			and not Fu.IsReflectingSpells(enemy)
			then
				target = enemy
				break
			end
		end
	end

	-- Fallback: cyclone strongest when 2+ enemies nearby
	if target == nil and #filteredenemies >= 2 then
		local strongest = Fu.GetStrongestEnemyHero(filteredenemies)
		if strongest ~= nil and not strongest:IsMagicImmune() and not Fu.IsReflectingSpells(strongest) then
			target = strongest
		end
	end

	if target ~= nil then
		return BOT_ACTION_DESIRE_HIGH, target
	end

	return 0, nil
end

function UseWindWalk(hMinionUnit)
	if not WindWalk:IsFullyCastable() then return 0, nil end
	if DispelMagic:IsFullyCastable() then return 0, nil end
	if Cyclone:IsFullyCastable() then return 0 , nil end
	if Fu.CanNotUseAbility(hMinionUnit) then return 0, nil end
	
	return BOT_ACTION_DESIRE_HIGH
end

function UseHurlBoulder(hMinionUnit)
	if not HurlBoulder:IsFullyCastable() then return 0, nil end
	if Fu.CanNotUseAbility(hMinionUnit) then return 0, nil end

	local CastRange = HurlBoulder:GetCastRange()
	local nDamage = HurlBoulder:GetSpecialValueInt('damage')

	local enemies = hMinionUnit:GetNearbyHeroes(CastRange, true, BOT_MODE_NONE)

	-- Priority 1: kill or interrupt channeling
	for _, enemy in pairs(enemies) do
		if Fu.IsValidHero(enemy)
		and not enemy:IsMagicImmune()
		and not Fu.IsReflectingSpells(enemy)
		and (enemy:IsChanneling() or nDamage > enemy:GetHealth())
		then
			return BOT_ACTION_DESIRE_HIGH, enemy
		end
	end

	-- Priority 2: stun the engage target (if not already disabled)
	if Fu.IsGoingOnSomeone(bot) and Fu.IsValidHero(botTarget)
	and Fu.IsInRange(hMinionUnit, botTarget, CastRange)
	and not botTarget:IsMagicImmune()
	and not Fu.IsReflectingSpells(botTarget)
	and not Fu.IsDisabled(botTarget)
	then
		return BOT_ACTION_DESIRE_HIGH, botTarget
	end

	-- Priority 3: stun strongest enemy when retreating
	if Fu.IsRetreating(bot) then
		local strongest = Fu.GetStrongestEnemyHero(enemies)
		if strongest ~= nil
		and not strongest:IsMagicImmune()
		and not Fu.IsReflectingSpells(strongest)
		then
			return BOT_ACTION_DESIRE_HIGH, strongest
		end
	end

	-- Priority 4: stun tower aggro target (ally tower being dived)
	local allyTowers = hMinionUnit:GetNearbyTowers(1600, false)
	for _, tower in pairs(allyTowers) do
		local towerTarget = tower:GetAttackTarget()
		if Fu.IsValidHero(towerTarget)
		and not towerTarget:IsMagicImmune()
		and not Fu.IsDisabled(towerTarget)
		and not Fu.IsReflectingSpells(towerTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, towerTarget
		end
	end

	return 0, nil
end

function UseAstralPull(hMinionUnit)
	if not AstralPull:IsFullyCastable() then return 0, nil end
	if Fu.CanNotUseAbility(hMinionUnit) then return 0, nil end

	local SearchRange = 800
	local nDamage = AstralPull:GetAbilityDamage()

	local enemies = hMinionUnit:GetNearbyHeroes(SearchRange, true, BOT_MODE_NONE)
	if enemies ~= nil and #enemies >= 1 then
		for _, enemy in pairs(enemies) do
			if Fu.IsValidHero(enemy)
			and not Fu.IsReflectingSpells(enemy)
			and (enemy:IsChanneling() or nDamage > enemy:GetHealth())
			then
				return BOT_ACTION_DESIRE_HIGH, enemy
			end
		end
	end
	return 0, nil
end

function ConsiderMove(hMinionUnit)
	if U.CantMove(hMinionUnit) then
		return BOT_MODE_DESIRE_NONE, 0
	end

	local mode = bot:GetActiveMode()

	-- Laning: dodge tower aggro by retreating toward fountain
	if mode == BOT_MODE_LANING then
		local enemyTowers = hMinionUnit:GetNearbyTowers(800, true)
		for _, tower in pairs(enemyTowers) do
			if Fu.IsValidBuilding(tower) then
				local towerTarget = tower:GetAttackTarget()
				if towerTarget == hMinionUnit or GetUnitToUnitDistance(hMinionUnit, tower) <= 700 then
					return BOT_ACTION_DESIRE_HIGH, Fu.GetTeamFountain()
				end
			end
		end
		-- Also flee if enemy hero is targeting us
		local enemies = hMinionUnit:GetNearbyHeroes(800, true, BOT_MODE_NONE)
		for _, enemy in pairs(enemies or {}) do
			if Fu.IsValidHero(enemy) and enemy:GetAttackTarget() == hMinionUnit then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	-- Follow owner
	local distToOwner = GetUnitToUnitDistance(hMinionUnit, bot)
	if distToOwner > 200 then
		return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
	end

	return BOT_ACTION_DESIRE_HIGH, bot:GetLocation() + RandomVector(200)
end

return X
