-- Item and ability utilities: checks, queuing, casting
local function Init(Fu)

local bDebugMode = ( 1 == 10 )
local fKeepManaPercent = 0.39

function Fu.GetUltimateAbility( bot )

	return bot:GetAbilityInSlot( 5 )

end


-- 7.41: Refresher Orb/Shard only refreshes ABILITIES, not items.
-- This function checks if ult is on cooldown and we have enough mana for a double-cast.


-- 7.41: Refresher Orb/Shard only refreshes ABILITIES, not items.
-- This function checks if ult is on cooldown and we have enough mana for a double-cast.
function Fu.CanUseRefresherShard( bot )

	local ult = Fu.GetUltimateAbility( bot )

	if ult ~= nil
		and ult:IsPassive() == false
	then
		local ultCD = ult:GetCooldown()
		local manaCost = ult:GetManaCost()
		local ultInCooldownAtLeast = 2 -- don't directly use refresh if the ult was just use.

		if bot:GetMana() >= manaCost * 2
			and ult:GetCooldownTimeRemaining() >= ultCD / 2
			and ultCD - ult:GetCooldownTimeRemaining() >= ultInCooldownAtLeast
		then
			return true
		end
	end

	return false

end




function Fu.GetMostUltimateCDUnit()

	local unit = nil
	local maxCD = 0
	for i, id in pairs( GetTeamPlayers( GetTeam() ) )
	do
		if IsHeroAlive( id )
		then
			local member = GetTeamMember( i )
			if member ~= nil and member:IsAlive()
				and member:GetUnitName() ~= "npc_dota_hero_nevermore"
				and member:GetUnitName() ~= "npc_dota_hero_arc_warden"
			then
				if member:GetUnitName() == "npc_dota_hero_silencer" or member:GetUnitName() == "npc_dota_hero_warlock"
				then
					return member
				end
				local ult = Fu.GetUltimateAbility( member )
				if ult ~= nil
					and ult:IsPassive() == false
					and ult:GetCooldown() >= maxCD
				then
					unit = member
					maxCD = ult:GetCooldown()
				end
			end
		end
	end

	return unit

end




function Fu.CanCastAbilityOnTarget( npcTarget, bIgnoreMagicImmune )

	return npcTarget:CanBeSeen()
			and ( bIgnoreMagicImmune or not npcTarget:IsMagicImmune() )
			and not npcTarget:IsInvulnerable()
			and not Fu.IsSuspiciousIllusion( npcTarget )
			and not Fu.HasForbiddenModifier( npcTarget )
			-- and not Fu.IsAllyCanKill( npcTarget )

end


function Fu.CanCastAbility(ability)
	if ability == nil
	or ability:IsNull()
	or ability:IsPassive()
	or ability:IsHidden()
	or not ability:IsTrained()
	or not ability:IsFullyCastable()
	or not ability:IsActivated()
	then
		return false
	end

	return true
end


function Fu.CanBlinkDagger(bot)
    local blink = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil
        and (item:GetName() == "item_blink" or item:GetName() == "item_overwhelming_blink" or item:GetName() == "item_arcane_blink" or item:GetName() == "item_swift_blink")
        then
			blink = item
			break
		end
	end

    if blink ~= nil and blink:IsFullyCastable()
	then
        bot.Blink = blink
        return true
	end

    return false
end


function Fu.CanBlackKingBar(bot)
    local bkb = nil

    for i = 0, 5
    do
		local item = bot:GetItemInSlot(i)

		if item ~= nil and item:GetName() == "item_black_king_bar"
        then
			bkb = item
			break
		end
	end

    if bkb ~= nil and bkb:IsFullyCastable()
	then
        bot.BlackKingBar = bkb
        return true
	end

    return false
end


function Fu.HasItemInInventory( hItem )
	return GetBot():FindItemSlot(hItem) >= 0
end


function Fu.GetItem(itemName)
	for i = 0, 5
    do
		local item = GetBot():GetItemInSlot(i)

		if  item ~= nil
        and item:GetName() == itemName
        then
			return item
		end
	end

	return nil
end


function Fu.GetItem2(bot, sItemName)
	for i = 0, 16
	do
		local item = bot:GetItemInSlot(i)
		if item ~= nil
		then
			if string.find(item:GetName(), sItemName)
			then
				return item
			end
		end
	end

	return nil
end


function Fu.GetAbility(bot, abilityName)
	for i = 0, 23 do
		local ability = bot:GetAbilityInSlot(i)
		if  ability ~= nil
		and ability:GetName() == abilityName
		then
			return ability
		end
	end

	return nil
end



function Fu.GetComboItem( bot, sItemName )

	local Slot = bot:FindItemSlot( sItemName )

	if Slot >= 0 and Slot <= 5
	then
		return bot:GetItemInSlot( Slot )
	end

end




function Fu.HasItem( bot, sItemName )

	local Slot = bot:FindItemSlot( sItemName )

	if Slot >= 0 and Slot <= 5 then	return true end

	return false

end


function Fu.FindItemSlotNotInNonbackpack( bot, sItemName )
	local Slot = bot:FindItemSlot( sItemName )
	if Slot >= 0 and Slot <= 5 then	return Slot end
	return -1
end


function Fu.IsItemAvailable( sItemName )

	local bot = GetBot()

	local slot = bot:FindItemSlot( sItemName )

	if slot >= 0 and slot <= 5
	then
		return bot:GetItemInSlot( slot )
	end

end




function Fu.IsAllowedToSpam( bot, nManaCost )

	if bot:HasModifier( "modifier_silencer_curse_of_the_silent" ) then return false end

	if bot:HasModifier( "modifier_rune_regen" ) then return true end

	return ( bot:GetMana() - nManaCost ) / bot:GetMaxMana() >= fKeepManaPercent

end




function Fu.SetQueueToInvisible( bot )

	if bot:IsAlive()
		and not bot:IsInvisible()
		and not bot:HasModifier( "modifier_item_dustofappearance" )
	then
		local enemyTowerList = bot:GetNearbyTowers( 888, true )

		if enemyTowerList[1] ~= nil then return end

		local itemAmulet = Fu.IsItemAvailable( 'item_shadow_amulet' )
		if itemAmulet ~= nil
			and itemAmulet:IsFullyCastable()
		then
			bot:ActionQueue_UseAbilityOnEntity( itemAmulet, bot )
			return
		end
	
		local itemGlimer = Fu.IsItemAvailable( 'item_glimmer_cape' )
		if itemGlimer ~= nil and itemGlimer:IsFullyCastable()
		then
			bot:ActionQueue_UseAbilityOnEntity( itemGlimer, bot )
			return
		end

		local itemInvisSword = Fu.IsItemAvailable( 'item_invis_sword' )
		if itemInvisSword ~= nil and itemInvisSword:IsFullyCastable()
		then
			bot:ActionQueue_UseAbility( itemInvisSword )
			return
		end

		local itemSilverEdge = Fu.IsItemAvailable( 'item_silver_edge' )
		if itemSilverEdge ~= nil and itemSilverEdge:IsFullyCastable()
		then
			bot:ActionQueue_UseAbility( itemSilverEdge )
			return
		end

	end


end




function Fu.SetQueueSwitchPtToINT( bot )

	local pt = Fu.IsItemAvailable( "item_power_treads" )
	if pt ~= nil and pt:IsFullyCastable()
	then
		if pt:GetPowerTreadsStat() == ATTRIBUTE_INTELLECT
		then
			bot:ActionQueue_UseAbility( pt )
			bot:ActionQueue_UseAbility( pt )
			return
		elseif pt:GetPowerTreadsStat() == ATTRIBUTE_STRENGTH
			then
				bot:ActionQueue_UseAbility( pt )
				return
		end
	end

end




function Fu.SetQueueUseSoulRing( bot )

	local sr = Fu.IsItemAvailable( "item_soul_ring" )

	if sr ~= nil and sr:IsFullyCastable()
	then
		local nEnemyCount = Fu.GetEnemyCount( bot, 1600 )
		local botHP = Fu.GetHP( bot )
		local botMP = Fu.GetMP( bot )
		if botHP > 0.35 + 0.1 * nEnemyCount
			and botMP < 0.99 - 0.1 * nEnemyCount
			and ( nEnemyCount <= 2 or botHP > botMP * 2.5 )
		then
			bot:ActionQueue_UseAbility( sr )
			return
		end
	end

end




function Fu.SetQueuePtToINT( bot, bSoulRingUsed )

	bot:Action_ClearActions(false)

	if bSoulRingUsed then Fu.SetQueueUseSoulRing( bot ) end

	if not Fu.IsPTReady( bot, ATTRIBUTE_INTELLECT )
	then
		Fu.SetQueueSwitchPtToINT( bot )
	end

end


-- 动力鞋/假腿状态
function Fu.IsPTReady( bot, status )

	if not bot:IsAlive()
		or bot:IsMuted()
		or bot:IsChanneling()
		or bot:IsInvisible()
		or bot:GetHealth() / bot:GetMaxHealth() < 0.2
	then
		return true
	end

	if status == ATTRIBUTE_INTELLECT
	then
		status = ATTRIBUTE_AGILITY
	elseif status == ATTRIBUTE_AGILITY
		then
			status = ATTRIBUTE_INTELLECT
	end

	local pt = Fu.IsItemAvailable( "item_power_treads" )
	if pt ~= nil and pt:IsFullyCastable()
	then
		if pt:GetPowerTreadsStat() ~= status
		then
			return false
		end
	end

	return true

end




function Fu.ShouldSwitchPTStat( bot, pt )

	local ptStatus = pt:GetPowerTreadsStat()
	local botAttribute = bot:GetPrimaryAttribute()
	
	
	if ptStatus == ATTRIBUTE_INTELLECT
	then
		ptStatus = ATTRIBUTE_AGILITY
	elseif ptStatus == ATTRIBUTE_AGILITY
		then
			ptStatus = ATTRIBUTE_INTELLECT
	end
	
	if botAttribute ~= ATTRIBUTE_INTELLECT
		and botAttribute ~= ATTRIBUTE_STRENGTH
		and botAttribute ~= ATTRIBUTE_AGILITY
	then
		return ptStatus ~= ATTRIBUTE_STRENGTH
	end

	return botAttribute ~= ptStatus

end




function Fu.IsCastingUltimateAbility( bot )

	if bot:CanBeSeen() and (bot:IsCastingAbility() or bot:IsUsingAbility())
	then
		local nAbility = bot:GetCurrentActiveAbility()
		if nAbility ~= nil
			and nAbility:IsUltimate()
		then
			return true
		end
	end

	return false

end



function Fu.ConsiderForMkbDisassembleMask( bot )

	if bot.maskDismantleDone == nil then bot.maskDismantleDone = false end
	if bot.staffUnlockDone == nil then bot.staffUnlockDone = false end
	if bot.lifestealUnlockDone == nil then bot.lifestealUnlockDone = false end
	if bot.dismantleCheckTime == nil then bot.dismantleCheckTime = 600 end

	if bot.staffUnlockDone then return end

	if bot.dismantleCheckTime < DotaTime() + 1.0
	then
		bot.dismantleCheckTime = DotaTime()

		local mask	 = bot:FindItemSlot( "item_mask_of_madness" )
		local claymore = bot:FindItemSlot( "item_claymore" )
		local reaver	= bot:FindItemSlot( "item_reaver" )

		if not bot.maskDismantleDone
			and ( bot:GetItemInSlot( 6 ) == nil or bot:GetItemInSlot( 7 ) == nil or bot:GetItemInSlot( 8 ) == nil )
		then

			if mask >= 0 and mask <= 8
				and ( ( reaver >= 0 and reaver <= 8 ) or ( claymore >= 0 and claymore <= 8 ) )
				and ( bot:GetGold() >= 1400 or bot:GetStashValue() >= 1400 or bot:GetCourierValue() >= 1400 )
			then
				if bDebugMode then log( "%s mask Dismantle1", bot:GetUnitName() ) end
				bot.maskDismantleDone = true
				bot:ActionImmediate_DisassembleItem( bot:GetItemInSlot( mask ) )
				return
			end

			if mask >= 0 and mask <= 8
				and claymore >= 0 and reaver >= 0
			then
				if bDebugMode then log( "%s mask Dismantle2", bot:GetUnitName() ) end
				bot.maskDismantleDone = true
				bot:ActionImmediate_DisassembleItem( bot:GetItemInSlot( mask ) )
				return
			end
		end

		if not bot.maskDismantleDone then return end

		local lifesteal = bot:FindItemSlot( "item_lifesteal" )
		local staff = bot:FindItemSlot( "item_quarterstaff" )

		if lifesteal >= 0
			and not bot.lifestealUnlockDone
		then
			if bDebugMode then log( "%s lifestealUnlockDone", bot:GetUnitName() ) end
			bot.lifestealUnlockDone = true
			bot:ActionImmediate_SetItemCombineLock( bot:GetItemInSlot( lifesteal ), false )
			return
		end

		local satanic = bot:FindItemSlot( "item_satanic" )

		if satanic >= 0 and staff >= 0 and not bot.staffUnlockDone
		then
			if bDebugMode then log( "%s staffUnlockDone", bot:GetUnitName() ) end
			bot.staffUnlockDone = true
			bot:ActionImmediate_SetItemCombineLock( bot:GetItemInSlot( staff ), false )
			return
		end

	end
end


-- NEWLY ADDED FUNCTIONS FOR NEW HEROES AND BEHAVIOUR

function Fu.CanBeCast(ability)
	return ability:IsTrained() and ability:IsFullyCastable() and ability:IsHidden() == false;
end


function Fu.CanSpamSpell(bot, manaCost)
	local initialRatio = 1.0;
	if manaCost < 100 then
		initialRatio = 0.6;
	end
	return ( bot:GetMana() - manaCost ) / bot:GetMaxMana() >= ( initialRatio - bot:GetLevel()/(3*30) );
end

local maxAddedRange = 200
local maxGetRange = 1600
function Fu.GetProperCastRange(bIgnore, hUnit, abilityCR)
	local attackRng = hUnit:GetAttackRange();
	if bIgnore then
		return abilityCR;
	elseif abilityCR <= attackRng then
		return attackRng + maxAddedRange;
	elseif abilityCR + maxAddedRange <= maxGetRange then
		return abilityCR + maxAddedRange;
	elseif abilityCR > maxGetRange then
		return maxGetRange;
	else
		return abilityCR;
	end
end


local maxLevel = 30
function Fu.AllowedToSpam(bot, manaCost)
	return ( bot:GetMana() - manaCost ) / bot:GetMaxMana() >= ( 1.0 - bot:GetLevel()/(2*maxLevel) );
end


function Fu.HasAghanimsShard(bot)
	return bot:HasModifier("modifier_item_aghanims_shard")
end


function Fu.CanCastAbilitySoon(ability, fTime)
	if ability == nil
	or ability:IsNull()
	or ability:GetName() == ''
	or ability:IsPassive()
	or ability:IsHidden()
	or not ability:IsTrained()
	or not ability:IsActivated()
	then
		return false
	end

	if ability:GetCooldownTimeRemaining() > fTime then
		return false
	end

	return true
end

-- hAbilityList: handle / integer (mana)

-- hAbilityList: handle / integer (mana)
function Fu.GetManaThreshold(bot, nManaCost, hAbilityList)
	local fManaThreshold = 0
	local botManaRegen = bot:GetManaRegen()
	local botMaxMana = bot:GetMaxMana()

	-- tp, bkb
	local itemSlots = {0, 1, 2, 3, 4, 5, 15}
	for i = 1, #itemSlots do
		local hItem = bot:GetItemInSlot(itemSlots[i])
		if hItem then
			local sItemName = hItem:GetName()
			if sItemName == 'item_tpscroll'
			or sItemName == 'item_black_king_bar'
			then
				local nManaCostItem = hItem:GetManaCost()
				if Fu.CanCastAbilitySoon(hItem, nManaCost / botManaRegen) then
					fManaThreshold = fManaThreshold + (nManaCostItem / botMaxMana)
				end
			end
		end
	end

	for _, hAbility in pairs(hAbilityList) do
		if type(hAbility) == 'number' then
			fManaThreshold = fManaThreshold + hAbility / botMaxMana
		else
			if Fu.CanCastAbilitySoon(hAbility, nManaCost / botManaRegen) then
				fManaThreshold = fManaThreshold + (hAbility:GetManaCost()) / botMaxMana
			end
		end
	end

	return fManaThreshold
end


function Fu.HasInvisibilityOrItem( npcEnemy )

	if npcEnemy:HasInvisibility( false )
		or Fu.HasItem( npcEnemy, "item_shadow_amulet" )
		or Fu.HasItem( npcEnemy, "item_glimmer_cape" )
		or Fu.HasItem( npcEnemy, "item_invis_sword" )
		or Fu.HasItem( npcEnemy, "item_silver_edge" )
	then
		return true
	end

	return false

end


function Fu.HasAbility(bot, abilityName)
	for i = 0, 23
	do
		local ability = bot:GetAbilityInSlot(i)
		if  ability ~= nil
		and ability:GetName() == abilityName
		then
			return true, ability
		end
	end

	return false, nil
end


function Fu.HasPowerTreads(bot)
	if Fu.HasItem(bot, 'item_power_treads')
	or Fu.HasItem(bot, 'item_power_treads_agi')
	or Fu.HasItem(bot, 'item_power_treads_int')
	or Fu.HasItem(bot, 'item_power_treads_str')
	then
		return true
	end

	return false
end


end

return Init
