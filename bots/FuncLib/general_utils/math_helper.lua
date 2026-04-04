-- Math helpers, HP/MP queries, table utilities, timing
local function Init(Fu)

function Fu.GetHP( unit )
	local nCurHealth = unit:GetHealth()
    local nMaxHealth = unit:GetMaxHealth()
	if GetTeam() == unit:GetTeam() then
		nCurHealth = unit:OriginalGetHealth()
		nMaxHealth = unit:OriginalGetMaxHealth()
	end
	if nCurHealth <= 0 then return 0 end
	return nCurHealth / nMaxHealth
end

function Fu.GetMP( bot )
	if bot:GetUnitName() == 'npc_dota_hero_huskar' then
		return bot:GetHealth() / bot:GetMaxHealth()
	end
	return bot:GetMana() / bot:GetMaxMana()
end

function Fu.GetManaAfter(manaCost)
	local bot = GetBot()
	return (bot:GetMana() - manaCost) / bot:GetMaxMana()
end

function Fu.GetHealthAfter(hpCost)
	local bot = GetBot()
	return (bot:GetHealth() - hpCost) / bot:GetMaxHealth()
end

function Fu.GetOne( number )
	return math.floor( number * 10 ) / 10
end

function Fu.ToNearest500(num)
    return math.floor(num / 500 + 0.5) * 500
end

function Fu.CombineTwoTable( tableA, tableB )
	local targetTable = tableA
	local Num = #tableA
	for i, u in pairs( tableB )
	do
		targetTable[Num + i] = u
	end
	return targetTable
end

function Fu.CheckBitfieldFlag(bitfield, flag)
    return ((bitfield / flag) % 2) >= 1
end

function Fu.GetETAWithAcceleration(dist, speed, accel)
	return (math.sqrt(2 * accel * dist + speed * speed) - speed) / accel
end

local LastActionTime = {}
function Fu.HasNotActionLast( nCD, nNumber )
	if LastActionTime[nNumber] == nil then LastActionTime[nNumber] = -90 end
	if DotaTime() > LastActionTime[nNumber] + nCD
	then
		LastActionTime[nNumber] = DotaTime()
		return true
	end
	return false
end

function Fu.CountNotStunnedUnits(tUnits, locAOE, nRadius, nUnits)
	local count = 0;
	if locAOE.count >= nUnits then
		for _,unit in pairs(tUnits)
		do
			if GetUnitToLocationDistance(unit, locAOE.targetloc) <= nRadius and not unit:IsInvulnerable() and not Fu.IsDisabled(unit) then
				count = count + 1;
			end
		end
	end
	return count;
end

function Fu.HasHealingItem(bot)
	return Fu.HasItem(bot, "item_tango")
		or Fu.HasItem(bot, "item_tango_single")
		or Fu.HasItem(bot, "item_flask")
		or Fu.HasItem(bot, "item_bottle")
		or Fu.HasItem(bot, "item_faerie_fire")
		or Fu.HasItem(bot, "item_enchanted_mango")
		or Fu.HasItem(bot, "item_famango")
		or Fu.HasItem(bot, "item_great_famango")
		or Fu.HasItem(bot, "item_greater_famango")
		or bot:HasModifier("modifier_tango_heal")
		or bot:HasModifier("modifier_flask_healing")
		or bot:HasModifier("modifier_bottle_regeneration")
end

end

return Init
