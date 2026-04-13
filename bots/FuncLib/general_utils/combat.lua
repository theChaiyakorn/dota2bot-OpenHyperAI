-- Combat calculations: damage, kill checks, power comparison
local function Init(Fu)



function Fu.IsOtherAllyCanKillTarget( bot, target )
	if not Fu.IsValid(target) then
		return false
	end

	local CK = Fu.CK
	if CK then
		local cache = Fu.Utils.GetCachedVars(CK.IS_OTHER_ALLY_CAN_KILL + target:GetPlayerID(), 0.5)
		if cache ~= nil then return cache end
	end

	if target:GetHealth() / target:GetMaxHealth() > 0.38
	then
		if CK then Fu.Utils.SetCachedVars(CK.IS_OTHER_ALLY_CAN_KILL + target:GetPlayerID(), false) end
		return false
	end

	local nTotalDamage = 0
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nTeamMember = GetTeamPlayers( GetTeam() )

	for i = 1, #nTeamMember
	do
		local ally = GetTeamMember( i )
		if Fu.IsValidTarget(ally)
			and ally ~= bot
			and not Fu.IsDisabled( ally )
			and ally:GetHealth() / ally:GetMaxHealth() > 0.15
			and ally:IsFacingLocation( target:GetLocation(), 20 )
			and GetUnitToUnitDistance( ally, target ) <= ally:GetAttackRange() + 50
		then
			local allyTarget = Fu.GetProperTarget( ally )
			if allyTarget == nil or allyTarget == target or Fu.IsHumanPlayer( ally )
			then
				local allyDamageTime = Fu.IsHumanPlayer( ally ) and 6.0 or 2.0
				nTotalDamage = nTotalDamage + ally:GetEstimatedDamageToTarget( true, target, allyDamageTime, DAMAGE_TYPE_PHYSICAL )
			end
		end
	end

	local res = nTotalDamage > target:GetHealth()
	if CK then Fu.Utils.SetCachedVars(CK.IS_OTHER_ALLY_CAN_KILL + target:GetPlayerID(), res) end
	return res
end



function Fu.CanCastOnMagicImmune( npcTarget )
	return npcTarget:CanBeSeen()
			and not npcTarget:IsInvulnerable()
			and not Fu.IsSuspiciousIllusion( npcTarget )
			and not Fu.HasForbiddenModifier( npcTarget )
			-- and not Fu.IsAllyCanKill( npcTarget )

end


function Fu.IsNotImmune(botTarget)
	return Fu.IsValidTarget(botTarget)
	and botTarget:CanBeSeen()
	and not botTarget:IsInvulnerable()
	and not botTarget:IsMagicImmune()
end

-- Tower dive check
-- Returns true if bot is near enemy tower and team can't guarantee the kill on target.
-- Call this before committing to an attack to prevent suicidal tower dives.
function Fu.IsRecklesslyDivingTower(bot, target)
	if not Fu.IsValidHero(target) then return false end
	local nEnemyTowers = bot:GetNearbyTowers(800, true)
	if not Fu.IsValidBuilding(nEnemyTowers[1]) then return false end

	-- Count allied DPS on this target (only allies actually engaging it)
	local nInRangeAlly = target:GetNearbyHeroes(900, true, BOT_MODE_NONE)
	local ourDamage = 0
	for _, ally in pairs(nInRangeAlly) do
		if Fu.IsValidHero(ally) and Fu.IsGoingOnSomeone(ally) and not Fu.IsSuspiciousIllusion(ally) then
			local allyTarget = Fu.GetProperTarget(ally)
			if allyTarget == target then
				local timeToReach = math.max(0, (GetUnitToUnitDistance(ally, target) - ally:GetAttackRange()) / math.max(1, ally:GetCurrentMovementSpeed()))
				ourDamage = ourDamage + ally:GetAttackDamage() * ally:GetAttackSpeed() * math.max(1, 3 - timeToReach)
			end
		end
	end

	-- Can't kill target in 3 seconds under tower → reckless dive
	local targetSurvival = target:GetHealth() + target:GetHealthRegen() * 3
	if target:GetActualIncomingDamage(ourDamage, DAMAGE_TYPE_PHYSICAL) < targetSurvival then
		return true
	end

	return false
end

-- Check if unit has active spell reflection (Lotus Orb, Anti-Mage Counterspell, Mirror Shield)
function Fu.IsReflectingSpells(unit)
	if unit == nil then return false end
	return unit:HasModifier('modifier_item_lotus_orb_active')
		or unit:HasModifier('modifier_antimage_counterspell')
		or unit:HasModifier('modifier_mirror_shield')
end


function Fu.FilterEnemiesForStun(enemies)
	local filteredenemies = {}
	for v, enemy in pairs(enemies) do
		if not Fu.IsSuspiciousIllusion(enemy) and not enemy:IsRooted() and not enemy:IsStunned() and not enemy:IsHexed() and not enemy:IsNightmared() and not Fu.IsTaunted(enemy) then
			table.insert(filteredenemies, enemy)
		end
	end
	return filteredenemies
end




function Fu.CanCastOnNonMagicImmune( npcTarget )

	return npcTarget:CanBeSeen()
			and not npcTarget:IsMagicImmune()
			and not npcTarget:IsInvulnerable()
			and not Fu.IsSuspiciousIllusion( npcTarget )
			and not Fu.HasForbiddenModifier( npcTarget )

end


function Fu.CanCastOnTargetAdvanced( npcTarget )
	if Fu.IsSuspiciousIllusion(npcTarget) then return false end
	if npcTarget:GetUnitName() == 'npc_dota_hero_antimage' --and npcTarget:IsBot()
	then

		if npcTarget:HasModifier( "modifier_antimage_spell_shield" )
			and Fu.GetModifierTime( npcTarget, "modifier_antimage_spell_shield" ) > 0.27
		then
			return false
		end

		if npcTarget:IsSilenced()
			or npcTarget:IsStunned()
			or npcTarget:IsHexed()
			or npcTarget:IsNightmared()
			or npcTarget:IsChanneling()
			or Fu.IsTaunted( npcTarget )
			or npcTarget:GetMana() < 45
			or ( npcTarget:HasModifier( "modifier_antimage_spell_shield" )
				and Fu.GetModifierTime( npcTarget, "modifier_antimage_spell_shield" ) < 0.27 )
		then
			if not npcTarget:HasModifier( "modifier_item_sphere_target" )
				and not npcTarget:HasModifier( "modifier_item_lotus_orb_active" )
				and not npcTarget:HasModifier( "modifier_item_aeon_disk_buff" )
				and ( not npcTarget:HasModifier( "modifier_dazzle_shallow_grave" ) or npcTarget:GetHealth() > 300 )
			then
				return true
			end
		end

		return false
	end

	return not npcTarget:HasModifier( "modifier_item_sphere_target" )
			and not npcTarget:HasModifier( "modifier_antimage_spell_shield" )
			and not npcTarget:HasModifier( "modifier_brewmaster_earth_spell_immunity" )
			and not npcTarget:HasModifier( "modifier_item_lotus_orb_active" )
			and not npcTarget:HasModifier( "modifier_item_aeon_disk_buff" )
			and not npcTarget:HasModifier( "modifier_roshan_spell_block" )
			and ( not npcTarget:HasModifier( "modifier_dazzle_shallow_grave" ) or npcTarget:GetHealth() > 300 )

end

--加入时间后的进阶函数


function Fu.CanKillTarget( npcTarget, dmg, dmgType )
	if dmgType == DAMAGE_TYPE_PURE then
		return dmg >= npcTarget:GetHealth()
	end

	return npcTarget:GetActualIncomingDamage( dmg, dmgType ) >= npcTarget:GetHealth()

end


--未计算技能增强


--未计算技能增强
function Fu.WillKillTarget( npcTarget, dmg, dmgType, nDelay )

	local targetHealth = npcTarget:GetHealth() + npcTarget:GetHealthRegen() * nDelay + 0.8

	local nRealBonus = Fu.GetTotalAttackWillRealDamage( npcTarget, nDelay )

	local nTotalDamage = npcTarget:GetActualIncomingDamage( dmg, dmgType ) + nRealBonus

	return nTotalDamage > targetHealth and nRealBonus < targetHealth - 1

end


--未计算技能增强


--未计算技能增强
function Fu.WillMixedDamageKillTarget( npcTarget, nPhysicalDamge, nMagicalDamage, nPureDamage, nDelay )

	local targetHealth = npcTarget:GetHealth() + npcTarget:GetHealthRegen() * nDelay + 0.8

	local nRealBonus = Fu.GetTotalAttackWillRealDamage( npcTarget, nDelay )

	local nRealPhysicalDamge = npcTarget:GetActualIncomingDamage( nPhysicalDamge, DAMAGE_TYPE_PHYSICAL )

	local nRealMagicalDamge = npcTarget:GetActualIncomingDamage( nMagicalDamage, DAMAGE_TYPE_MAGICAL )

	local nRealPureDamge = npcTarget:GetActualIncomingDamage( nPureDamage, DAMAGE_TYPE_PURE )

	local nTotalDamage = nRealPhysicalDamge + nRealMagicalDamge + nRealPureDamge + nRealBonus

	return nTotalDamage > targetHealth and nRealBonus < targetHealth - 1

end

--计算了技能增强

--计算了技能增强
function Fu.WillMagicKillTarget( bot, npcTarget, dmg, nDelay )

	local nDamageType = DAMAGE_TYPE_MAGICAL

	local MagicResistReduce = 1 - npcTarget:GetMagicResist()

	if MagicResistReduce < 0.05 then MagicResistReduce = 0.05 end

	local HealthBack = npcTarget:GetHealthRegen() * nDelay

	local EstDamage = dmg * ( 1 + bot:GetSpellAmp() ) - HealthBack / MagicResistReduce

	if npcTarget:HasModifier( "modifier_medusa_mana_shield" )
	then
		local EstDamageMaxReduce = EstDamage * 0.98
		if npcTarget:GetMana() * 2.8 >= EstDamageMaxReduce
		then
			EstDamage = EstDamage * 0.04
		else
			EstDamage = EstDamage * 0.02 + EstDamageMaxReduce - npcTarget:GetMana() * 2.8
		end
	end

	if npcTarget:GetUnitName() == "npc_dota_hero_bristleback"
		and not npcTarget:IsFacingLocation( bot:GetLocation(), 120 )
	then
		EstDamage = EstDamage * 0.7
	end

	if npcTarget:HasModifier( "modifier_kunkka_ghost_ship_damage_delay" )
	then
		local buffTime = Fu.GetModifierTime( npcTarget, "modifier_kunkka_ghost_ship_damage_delay" )
		if buffTime >= nDelay then EstDamage = EstDamage * 0.55 end
	end

	if npcTarget:HasModifier( "modifier_templar_assassin_refraction_absorb" )
	then
		local buffTime = Fu.GetModifierTime( npcTarget, "modifier_templar_assassin_refraction_absorb" )
		if buffTime >= nDelay then EstDamage = 0 end
	end

	local nRealDamage = npcTarget:GetActualIncomingDamage( EstDamage, nDamageType )

	return nRealDamage >= npcTarget:GetHealth() --, nRealDamage

end


function Fu.GetUnitListTotalAttackDamage(bot, tUnits, fTimeInterval)
    local dmg = 0
	for _, unit in pairs(tUnits) do
		if Fu.IsValid(unit) then
            local nAttackDamage = unit:GetAttackDamage()
			local sUnitName = unit:GetUnitName()

            if Fu.IsSuspiciousIllusion(unit) then
                if string.find(sUnitName, 'phantom_lancer') then
                    nAttackDamage = nAttackDamage * 0.19
                elseif string.find(sUnitName, 'naga_siren') then
                    nAttackDamage = nAttackDamage * 0.4
                elseif string.find(sUnitName, 'chaos_knight') then
                    -- full
                elseif string.find(sUnitName, 'terrorblade') then
                    if Fu.IsUnitNearby(bot, tUnits, 1200, sUnitName, true) then
                        nAttackDamage = nAttackDamage * (0.6 + 0.25)
                    else
                        nAttackDamage = nAttackDamage * (0.6 - 0.50)
                    end
                elseif unit:HasModifier('modifier_darkseer_wallofreplica_illusion') then
                    nAttackDamage = nAttackDamage * 0.9
                elseif unit:HasModifier('modifier_grimstroke_scepter_buff') then
                    nAttackDamage = nAttackDamage * 1.5
                else
					if unit:GetAttackRange() > 300 then
						nAttackDamage = nAttackDamage * 0.28
					else
						nAttackDamage = nAttackDamage * 0.33
					end
                end
            end

            dmg = dmg + nAttackDamage * unit:GetAttackSpeed() * fTimeInterval
		end
	end

	return dmg
end

local function IsEnemyTerrorbladeNear(unit, nRadius)
	for _, enemy in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
		if Fu.IsValidHero(enemy)
		and Fu.IsInRange(unit, enemy, nRadius)
		and enemy:GetUnitName() == 'npc_dota_hero_terrorblade'
		and not Fu.IsSuspiciousIllusion(enemy)
		then
			return true
		end
	end

	return false
end


local function GetUnitAttackDamage(unit, fInterval, bIllusion)
	if Fu.IsValid(unit) then
		local nAttackDamage = unit:GetAttackDamage()
		local sUnitName = unit:GetUnitName()

		if bIllusion and Fu.IsSuspiciousIllusion(unit) then
			if string.find(sUnitName, 'phantom_lancer') then
				nAttackDamage = nAttackDamage * 0.19
			elseif string.find(sUnitName, 'naga_siren') then
				nAttackDamage = nAttackDamage * 0.4
			elseif string.find(sUnitName, 'chaos_knight') then
				-- full
			elseif string.find(sUnitName, 'terrorblade') then
				if IsEnemyTerrorbladeNear(unit, 1200) then
					nAttackDamage = nAttackDamage * 0.6 * (1.25)
				else
					nAttackDamage = nAttackDamage * 0.6 * (0.60)
				end
			elseif unit:HasModifier('modifier_darkseer_wallofreplica_illusion') then
				nAttackDamage = nAttackDamage * 0.9
			elseif unit:HasModifier('modifier_grimstroke_scepter_buff') then
				nAttackDamage = nAttackDamage * 1.5
			else
				nAttackDamage = nAttackDamage * 0.33
			end

			return nAttackDamage * unit:GetAttackSpeed() * fInterval
		else
			if not bIllusion then
				return nAttackDamage * unit:GetAttackSpeed() * fInterval
			end
		end
	end


	return nil
end



--以下可少算但不可多算
function Fu.GetAttackProDelayTime( bot, nCreep )
	if nCreep == nil then
		log('[ERROR] nil creep target')
		log("Stack Trace:", debug.traceback())
		return 0
	end

	local botName = bot:GetUnitName()
	local botAttackRange = bot:GetAttackRange()
	local botAttackPoint = bot:GetAttackPoint()
	local botAttackSpeed = bot:GetAttackSpeed()
	local botProSpeed = bot:GetAttackProjectileSpeed()
	local botMoveSpeed = bot:GetCurrentMovementSpeed()
	local botAttackPointTime = botAttackPoint / botAttackSpeed
	local botAttackIdleTime = bot:GetSecondsPerAttack() - botAttackPointTime
	local nLastAttackRemainIdleTime = 0

	if GameTime() - bot:GetLastAttackTime() < botAttackIdleTime
	then
		nLastAttackRemainIdleTime = botAttackIdleTime - ( GameTime() - bot:GetLastAttackTime() )
	end

	local nAttackDamageDelayTime = botAttackPointTime + nLastAttackRemainIdleTime * 0.98
	local nDist = GetUnitToUnitDistance( bot, nCreep )

	if bot:CanBeSeen()
		and bot:GetAttackTarget() == nCreep
		and bot:GetAnimActivity() == 1503
		and bot:GetAnimCycle() < botAttackPoint
	then
		nAttackDamageDelayTime = 0.9 * ( botAttackPoint - bot:GetAnimCycle() ) / botAttackSpeed
	end

	if botAttackRange > 320 or botName == "npc_dota_hero_templar_assassin"
	then

		local ignoreDist = 39
		if bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT then ignoreDist = 59 end

		local projectMoveDist = nDist - ignoreDist

		if projectMoveDist < 0 then projectMoveDist = 0 end

		if projectMoveDist > botAttackRange then projectMoveDist = botAttackRange - 32 end

		nAttackDamageDelayTime = nAttackDamageDelayTime + projectMoveDist / botProSpeed

		if nDist > botAttackRange + ignoreDist / 1.2 and botName ~= "npc_dota_hero_sniper"
		then
			nAttackDamageDelayTime = nAttackDamageDelayTime + ( nDist - botAttackRange - ignoreDist / 1.2 ) / botMoveSpeed
		end

	end

	if botAttackRange < 326
		and nDist > botAttackRange + 50
		and botName ~= "npc_dota_hero_templar_assassin"
	then
		nAttackDamageDelayTime = nAttackDamageDelayTime + ( nDist - botAttackRange - 50 ) / botMoveSpeed
	end

	return nAttackDamageDelayTime

end


--当前点 * 攻击间隔 / 1.0 = 当前时


--当前点 * 攻击间隔 / 1.0 = 当前时
function Fu.GetCreepAttackActivityWillRealDamage( nUnit, nTime )

	local bot = GetBot()
	local botLV = bot:GetLevel()
	local gameTime = GameTime()
	local nDamage = 0
	local othersBeEnemy = true

	if nUnit:GetTeam() ~= bot:GetTeam() then othersBeEnemy = false end

	local nCreeps = bot:GetNearbyLaneCreeps( 1600, othersBeEnemy )
	for _, creep in pairs( nCreeps )
	do
		if creep:CanBeSeen()
			and creep:GetAttackTarget() == nUnit
			and creep:GetAnimActivity() == 1503
			and creep:GetLastAttackTime() < gameTime - 0.2
		then
			local attackPoint	= creep:GetAttackPoint()
			local animCycle	 = creep:GetAnimCycle()
			local attackPerTime = creep:GetSecondsPerAttack()

			if Fu.IsKeyWordUnit( 'melee', creep )
				and animCycle < attackPoint
				and ( attackPoint - animCycle ) * attackPerTime < nTime * ( 0.99 - botLV / 300 )
			then
				nDamage = nDamage + creep:GetAttackDamage() * 1
			end

			if Fu.IsKeyWordUnit( 'ranged', creep )
				and animCycle < attackPoint
			then
				local nDist = GetUnitToUnitDistance( creep, nUnit ) - 22
				local nProjectSpeed = creep:GetAttackProjectileSpeed()
				local nProjectTime = nDist / ( nProjectSpeed + 1 )
				if ( attackPoint - animCycle ) * attackPerTime + nProjectTime < nTime * ( 0.98 - botLV / 200 )
				then
					nDamage = nDamage + creep:GetAttackDamage() * 1
				end
			end

			if Fu.IsKeyWordUnit( 'siege', creep )
				and animCycle < 0.292 --0.285
			then
				local nDist = GetUnitToUnitDistance( creep, nUnit ) - 28
				local nProjectSpeed = creep:GetAttackProjectileSpeed()
				local nProjectTime = nDist / ( nProjectSpeed + 1 )
				if ( 0.292 - animCycle ) * 0.699 / 0.292 + nProjectTime < nTime * ( 0.9 - botLV / 150 )
				then
					nDamage = nDamage + creep:GetAttackDamage() * 1
				end
			end

		end
	end

	return nUnit:GetActualIncomingDamage( nDamage, DAMAGE_TYPE_PHYSICAL )

end




function Fu.GetCreepAttackProjectileWillRealDamage( nUnit, nTime )

	local nDamage = 0
	local incProj = nUnit:GetIncomingTrackingProjectiles()
	for _, p in pairs( incProj )
	do
		if p.is_attack
			and p.caster ~= nil
		then
			local nProjectSpeed = p.caster:GetAttackProjectileSpeed()
			if p.caster:IsTower() then nProjectSpeed = nProjectSpeed * 0.93 end
			local nProjectDist = nProjectSpeed * nTime * 0.95
			local nDistance	 = GetUnitToLocationDistance( nUnit, p.location )
			if nProjectDist > nDistance * 1.02
			then
				nDamage = nDamage + p.caster:GetAttackDamage() * 1
			end
		end
	end

	return nUnit:GetActualIncomingDamage( nDamage, DAMAGE_TYPE_PHYSICAL )

end




function Fu.GetTotalAttackWillRealDamage( nUnit, nTime )

	 return Fu.GetCreepAttackProjectileWillRealDamage( nUnit, nTime ) + Fu.GetCreepAttackActivityWillRealDamage( nUnit, nTime )

end




function Fu.GetAttackProjectileDamageByRange( nUnit, nRadius )

	local nDamage = 0
	local incProj = nUnit:GetIncomingTrackingProjectiles()
	for _, p in pairs( incProj )
	do
		if p.is_attack and p.caster ~= nil
			and GetUnitToLocationDistance( nUnit, p.location ) < nRadius
		then
			nDamage = nDamage + p.caster:GetAttackDamage() * 1
		end
	end

	return nDamage

end



function Fu.DotProduct(A, B)
	return A.x * B.x + A.y * B.y + A.z * B.z
end


local function GetEffectiveHealthFromArmor(nHealth, fArmor)
    local damageMultiplier = 1 - ((0.06 * fArmor) / (1 + 0.06 * math.abs(fArmor)))
    return nHealth / damageMultiplier
end


local function GetHealthMultiplier(hUnit)
	local mul = 1
	local sUnitName = hUnit:GetUnitName()
	local botHP = Fu.GetHP(hUnit) + (hUnit:GetHealthRegen() * 5.0 / hUnit:GetMaxHealth())
	local botMP = Fu.GetMP(hUnit) + (hUnit:GetManaRegen() * 5.0 / hUnit:GetMaxMana())
	if sUnitName == 'npc_dota_hero_huskar' then
		botHP = ((GetEffectiveHealthFromArmor(hUnit:GetHealth(), hUnit:GetArmor())) / hUnit:GetMaxHealth()) + (hUnit:GetHealthRegen() * 5.0 / hUnit:GetMaxHealth())
		mul = RemapValClamped(botHP, 0, 0.5, 0.5, 1)
	elseif sUnitName == 'npc_dota_hero_medusa' then
		local unitHealth = GetEffectiveHealthFromArmor(hUnit:GetHealth() - hUnit:GetMana(), hUnit:GetArmor())
		local unitMaxHealth = hUnit:GetMaxHealth() - hUnit:GetMaxMana()
		local nHealth = RemapValClamped(unitHealth / unitMaxHealth, 0, 1, 0, 1) * 0.2 + RemapValClamped(botMP, 0, 0.75, 0, 1) * 0.8
		mul = RemapValClamped(nHealth, 0.5, 1, 0.5, 1)
	else
		botHP = ((GetEffectiveHealthFromArmor(hUnit:GetHealth(), hUnit:GetArmor())) / hUnit:GetMaxHealth()) + (hUnit:GetHealthRegen() * 5.0 / hUnit:GetMaxHealth())
		local nHealth = RemapValClamped(botHP, 0, 0.75, 0, 1) * 0.8 + RemapValClamped(botMP, 0, 1, 0, 1) * 0.2
		mul = RemapValClamped(nHealth, 0.5, 1, 0.5, 1)
	end

	return mul
end


function Fu.WeAreStronger(bot, nRadius)
	local CK = Fu.CK
	if CK then
		local cachedVar = Fu.Utils.GetCachedVars(CK.WE_ARE_STRONGER + bot:GetPlayerID(), 0.5)
		if cachedVar ~= nil then return cachedVar end
	end

	local tAllyHeroes = {}
	local tEnemyHeroes = {}
	local ourPower = 0
	local ourPowerRaw = 0
	local enemyPower = 0
	local botHealthRegen =  bot:GetHealthRegen() * 2.0

	for _, unit in pairs(GetUnitList(UNIT_LIST_ALL)) do
		if Fu.IsValidHero(unit)
		and GetUnitToUnitDistance(bot, unit) <= nRadius
		and Fu.GetHP(unit) > 0.1
		and not unit:HasModifier('modifier_necrolyte_reapers_scythe')
		and not unit:HasModifier('modifier_dazzle_nothl_projection_physical_body_debuff')
		and not unit:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
		and not unit:HasModifier('modifier_item_helm_of_the_undying_active')
		and not unit:HasModifier('modifier_teleporting')
		and unit:GetTeam() ~= TEAM_NEUTRAL
		and unit:GetTeam() ~= TEAM_NONE
		then
			local sUnitName = unit:GetUnitName()
			local fMul = GetHealthMultiplier(unit)
			local fMul_Illusion = RemapValClamped(Fu.GetHP(unit), 0.25, 1, 0, 1)

			if GetTeam() == unit:GetTeam() then
				if not unit:HasModifier('modifier_arc_warden_tempest_double')
				and Fu.IsSuspiciousIllusion(unit)
				then
					local nDamage = GetUnitAttackDamage(unit, 5.0, true)
					if nDamage then
						ourPower = ourPower + (math.log(1 + unit:GetOffensivePower())) * ((math.sqrt(Max(0, nDamage)))) * fMul_Illusion
						ourPowerRaw = ourPowerRaw + (math.log(1 + unit:GetRawOffensivePower())) * (math.sqrt(Max(0, nDamage))) * fMul_Illusion
					end
				else
					if not Fu.IsMeepoClone(unit)
					and not string.find(sUnitName, 'lone_druid_bear')
					and not unit:HasModifier('modifier_item_helm_of_the_undying_active')
					then
						table.insert(tAllyHeroes, unit)
					end
					ourPower = ourPower + (math.log(1 + unit:GetOffensivePower())) * (math.sqrt(unit:GetAttackDamage() * unit:GetAttackSpeed() * 5)) * fMul
					ourPowerRaw = ourPowerRaw + (math.log(1 + unit:GetRawOffensivePower())) * (math.sqrt(Max(0, unit:GetAttackDamage() * unit:GetAttackSpeed() * 5))) * fMul
				end
			else
				if not unit:HasModifier('modifier_arc_warden_tempest_double')
				and Fu.IsSuspiciousIllusion(unit)
				then
					local nDamage = GetUnitAttackDamage(unit, 5.0, true)
					if nDamage then
						enemyPower = enemyPower + (math.log(1 + unit:GetRawOffensivePower())) * (math.sqrt(Max(0, nDamage))) * fMul_Illusion
					end
				else
					if not Fu.IsMeepoClone(unit)
					and not string.find(sUnitName, 'lone_druid_bear')
					and not unit:HasModifier('modifier_item_helm_of_the_undying_active')
					then
						table.insert(tEnemyHeroes, unit)
					end
					enemyPower = enemyPower + (math.log(1 + unit:GetRawOffensivePower())) * (math.sqrt(Max(0, unit:GetAttackDamage() * unit:GetAttackSpeed() * 5))) * fMul
				end
			end
		end
	end

	local nAllyTowers = bot:GetNearbyTowers(600, false)
	if Fu.IsValidBuilding(nAllyTowers[1]) then
		if nAllyTowers[1]:HasModifier('modifier_fountain_glyph') then
			local power = #nAllyTowers * (math.sqrt(Max(0, nAllyTowers[1]:GetAttackDamage() * nAllyTowers[1]:GetAttackSpeed() * 5.0 * 2)))
			ourPower = ourPower + power
			ourPowerRaw = ourPowerRaw + power
		else
			local power = #nAllyTowers * (math.sqrt(Max(0, nAllyTowers[1]:GetAttackDamage() * nAllyTowers[1]:GetAttackSpeed() * 5.0)))
			ourPower = ourPower + power
			ourPowerRaw = ourPowerRaw + power
		end
	end

	if not Fu.IsEarlyGame() and Fu.IsInTeamFight(bot, 1600) and #tAllyHeroes >= #tEnemyHeroes then
		local vTeamFightLocation = Fu.GetTeamFightLocation(bot)
		if vTeamFightLocation ~= nil and (Fu.IsHumanInLoc(vTeamFightLocation, 1200) or #tAllyHeroes > #tEnemyHeroes) then
			ourPower = ourPower * 1.20
			ourPowerRaw = ourPowerRaw * 1.20
		end
	end

	local res = ourPowerRaw > enemyPower
	if CK then Fu.Utils.SetCachedVars(CK.WE_ARE_STRONGER + bot:GetPlayerID(), res) end
	return res
end


function Fu.GetArmorReducers(hero)
	local reducedArmor = 0

	-- Items (Passives for now)
	if Fu.HasItem(hero, "item_desolator")
	and (hero:GetItemInSlot (6) ~= "item_desolator" or hero:GetItemInSlot(7) ~= "item_desolator" or hero:GetItemInSlot(8) ~= "item_desolator")
	then
		reducedArmor = reducedArmor + 6
	end

	if Fu.HasItem(hero, "item_assault")
	and (hero:GetItemInSlot (6) ~= "item_assault" or hero:GetItemInSlot(7) ~= "item_assault" or hero:GetItemInSlot(8) ~= "item_assault")
	then
		reducedArmor = reducedArmor + 5
	end

	if Fu.HasItem(hero, "item_blight_stone")
	and (hero:GetItemInSlot (6) ~= "item_blight_stone" or hero:GetItemInSlot(7) ~= "item_blight_stone" or hero:GetItemInSlot(8) ~= "item_blight_stone")
	then
		reducedArmor = reducedArmor + 2
	end

	-- Abilities (Passives for now)
	local NevermoreDarkLord = hero:GetAbilityByName("nevermore_dark_lord")
	if hero:GetUnitName() == "npc_dota_hero_nevermore"
	and NevermoreDarkLord ~= nil
	and NevermoreDarkLord:GetLevel() > 0
	then
		reducedArmor = reducedArmor + NevermoreDarkLord:GetSpecialValueInt("presence_armor_reduction")
	end

	local NagaSirenRiptide = hero:GetAbilityByName("naga_siren_rip_tide")
	if hero:GetUnitName() == "npc_dota_hero_naga_siren"
	and NagaSirenRiptide ~= nil
	and NagaSirenRiptide:GetLevel() > 0 then
		reducedArmor = reducedArmor + NagaSirenRiptide:GetSpecialValueInt("armor_reduction")
	end

	return reducedArmor
end

function Fu.HasEnoughDPSForRoshan(heroes)
    local DPS = 0
    local DPSThreshold = 0
    local plannedTimeToKill = 60

    -- Roshan Stats
    local baseHealth = 6000
    local baseArmor = 30
    local armorPerInterval = 0.375
    local maxHealthBonusPerInterval = 130 * 2

    local roshanHealth = baseHealth + maxHealthBonusPerInterval * math.floor(DotaTime() / 60)

    for _, h in pairs(heroes) do
        local roshanArmor = baseArmor + armorPerInterval * math.floor(DotaTime() / 60) - Fu.GetArmorReducers(h)

        -- Only right click damage for now
        local attackDamage = h:GetAttackDamage()
        local attackSpeed = h:GetAttackSpeed()

        local dps = attackDamage * attackSpeed * (1 - roshanArmor / (roshanArmor + 20))
        DPS = DPS + dps
    end

    -- Use TOTAL team DPS (not average per hero).
    -- Old code divided by hero count, which penalized large teams.
    DPSThreshold = roshanHealth / plannedTimeToKill
    return DPS >= DPSThreshold
end


function Fu.GetTotalEstimatedDamageToTarget(nUnits, target)
	local dmg = 0

	for _, unit in pairs(nUnits)
	do
		if Fu.IsValid(unit)
		and Fu.IsValid(target)
		and not Fu.IsSuspiciousIllusion(unit)
		then
			dmg = dmg + unit:GetEstimatedDamageToTarget(true, target, 5, DAMAGE_TYPE_ALL)
		end
	end

	return dmg
end


function Fu.IsAllyCanKill( target )
	if target:GetHealth() / target:GetMaxHealth() > 0.38
	then
		return false
	end

	local nTotalDamage = 0
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nTeamMember = GetTeamPlayers( GetTeam() )
	for i = 1, #nTeamMember
	do
		local ally = GetTeamMember( i )
		if ally ~= nil and ally:IsAlive() and ally:CanBeSeen()
			and ( ally:GetAttackTarget() == target )
			and GetUnitToUnitDistance( ally, target ) <= ally:GetAttackRange() + 50
		then
			nTotalDamage = nTotalDamage + ally:GetAttackDamage()
		end
	end

	nTotalDamage = nTotalDamage * 2.44 + Fu.GetAttackProjectileDamageByRange( target, 1200 )

	if Fu.CanKillTarget( target, nTotalDamage, nDamageType )
	then
		return true
	end

	return false
end

--------------------------------------------------------------------
-- Shared combat utilities for hero ability decisions
--------------------------------------------------------------------

-- Check if an enemy is currently teleporting (TP scroll or Boots of Travel)
function Fu.IsEnemyTeleporting(enemy)
	if not Fu.IsValidHero(enemy) then return false end
	return enemy:HasModifier('modifier_teleporting')
end

-- Find an enemy that is currently teleporting within range (for interrupt abilities)
function Fu.GetTPTarget(bot, nRange)
	local enemies = bot:GetNearbyHeroes(nRange, true, BOT_MODE_NONE) or {}
	for _, enemy in pairs(enemies) do
		if Fu.IsValidHero(enemy) and Fu.IsEnemyTeleporting(enemy) and Fu.CanBeAttacked(enemy) then
			return enemy
		end
	end
	return nil
end

-- Check if an enemy is using a healing item (flask, clarity, bottle, etc.)
function Fu.IsEnemyHealing(enemy)
	if not Fu.IsValidHero(enemy) then return false end
	return enemy:HasModifier('modifier_flask_healing')
		or enemy:HasModifier('modifier_clarity_potion')
		or enemy:HasModifier('modifier_bottle_regeneration')
		or enemy:HasModifier('modifier_tango_heal')
end

-- Find an enemy healing within range (for harassment/interrupt)
function Fu.GetHealingTarget(bot, nRange)
	local enemies = bot:GetNearbyHeroes(nRange, true, BOT_MODE_NONE) or {}
	for _, enemy in pairs(enemies) do
		if Fu.IsValidHero(enemy) and Fu.IsEnemyHealing(enemy) and Fu.CanBeAttacked(enemy) then
			return enemy
		end
	end
	return nil
end

-- Validate team composition before committing a big ultimate.
-- Returns true if safe to use ult (allies >= enemies near target location).
function Fu.IsSafeToUseUltimate(bot, targetLoc, nRadius)
	nRadius = nRadius or 1200
	local allies = Fu.GetAlliesNearLoc(targetLoc, nRadius)
	local enemies = Fu.GetEnemiesNearLoc(targetLoc, nRadius)
	return #allies >= #enemies
end

-- Check if a target is in a dangerous zone (Chrono, Black Hole, etc.)
-- Returns true if the location is inside a known danger zone.
function Fu.IsLocationDangerous(vLoc)
	local dangerModifiers = {
		'modifier_faceless_void_chronosphere_freeze',
		'modifier_enigma_black_hole_pull',
		'modifier_dark_willow_bramble_maze',
	}
	for _, unit in pairs(GetUnitList(UNIT_LIST_ENEMIES)) do
		if unit and not unit:IsNull() and unit:IsAlive() then
			for _, mod in pairs(dangerModifiers) do
				if unit:HasModifier(mod) and GetUnitToLocationDistance(unit, vLoc) < 600 then
					return true
				end
			end
		end
	end
	return false
end

end

return Init
