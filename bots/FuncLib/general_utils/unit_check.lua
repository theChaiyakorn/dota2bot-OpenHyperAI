-- Unit validation and type checking utilities
local function Init(Fu)



function Fu.IsNoItemIllution(bot)
	-- local cacheKey = 'IsNoItemIllution'
	-- local cache = Fu.Utils.GetCachedVars(cacheKey, 0.5)
	-- if cache ~= nil then return cache end

	if (bot:IsIllusion() or Fu.IsMeepoClone(bot))
	and not bot:HasModifier("modifier_arc_warden_tempest_double")
	and bot:GetUnitName() ~= 'npc_dota_hero_vengefulspirit'
	then
		-- Fu.Utils.SetCachedVars(cacheKey, true)
		return true
	end
	-- Fu.Utils.SetCachedVars(cacheKey, false)
	return false
end


function Fu.IsNoAbilityIllution(bot)
	-- local cacheKey = 'IsNoAbilityIllution'
	-- local cache = Fu.Utils.GetCachedVars(cacheKey, 0.5)
	-- if cache ~= nil then return cache end

	if bot:IsIllusion()
	and not bot:HasModifier("modifier_arc_warden_tempest_double")
	and bot:GetUnitName() ~= 'npc_dota_hero_vengefulspirit'
	and not Fu.IsMeepoClone(bot)
	then
		-- Fu.Utils.SetCachedVars(cacheKey, true)
		return true
	end
	-- Fu.Utils.SetCachedVars(cacheKey, false)
	return false
end




function Fu.IsSuspiciousIllusion( npcTarget )
	if npcTarget == nil or npcTarget:IsNull() then return false end
	if npcTarget.is_suspicious_illusion ~= nil then
		return npcTarget.is_suspicious_illusion
	end
	if not npcTarget:CanBeSeen() then
		npcTarget.is_suspicious_illusion = false
		return false
	end

	if npcTarget:CanBeSeen() and (
		not npcTarget:IsHero()
		or npcTarget:IsCastingAbility()
		or npcTarget:IsUsingAbility()
		or npcTarget:IsChanneling()
	)
		-- or npcTarget:HasModifier( "modifier_item_satanic_unholy" )
		-- or npcTarget:HasModifier( "modifier_item_mask_of_madness_berserk" )
		-- or npcTarget:HasModifier( "modifier_black_king_bar_immune" )
		-- or npcTarget:HasModifier( "modifier_rune_doubledamage" )
		-- or npcTarget:HasModifier( "modifier_rune_regen" )
		-- or npcTarget:HasModifier( "modifier_rune_haste" )
		-- or npcTarget:HasModifier( "modifier_rune_arcane" )
		-- or npcTarget:HasModifier( "modifier_item_phase_boots_active" )
	then
		npcTarget.is_suspicious_illusion = false
		return false
	end

	local bot = GetBot()

	if npcTarget:GetTeam() == bot:GetTeam()
	then
		npcTarget.is_suspicious_illusion = npcTarget:IsIllusion() or npcTarget:HasModifier( "modifier_arc_warden_tempest_double" )
		return npcTarget.is_suspicious_illusion
	elseif npcTarget:GetTeam() == GetOpposingTeam()
	then

		if npcTarget:HasModifier( 'modifier_illusion' )
		or npcTarget:HasModifier( 'modifier_darkseer_wallofreplica_illusion' )
		or npcTarget:HasModifier( 'modifier_phantom_lancer_doppelwalk_illusion' )
		or npcTarget:HasModifier( 'modifier_phantom_lancer_juxtapose_illusion' )
		or npcTarget:HasModifier( 'modifier_skeleton_king_reincarnation_scepter_active' )
		or npcTarget:HasModifier( 'modifier_item_helm_of_the_undying_active' )
		or npcTarget:HasModifier( 'modifier_terrorblade_conjureimage' )
		then
			npcTarget.is_suspicious_illusion = true
			return true
		end

		local tID = npcTarget:GetPlayerID()

		if not IsHeroAlive( tID )
		then
			npcTarget.is_suspicious_illusion = true
			return true
		end

		if GetHeroLevel( tID ) > npcTarget:GetLevel()
		then
			npcTarget.is_suspicious_illusion = true
			return true
		end
		--[[
		if GetSelectedHeroName( tID ) ~= "npc_dota_hero_morphling"
			and GetSelectedHeroName( tID ) ~= npcTarget:GetUnitName()
		then
			npcTarget.is_suspicious_illusion = true
			return true
		end
		--]]
	end

	npcTarget.is_suspicious_illusion = false
	return false

end



function Fu.IsKeyWordUnit( keyWord, uUnit )

	if string.find( uUnit:GetUnitName(), keyWord ) ~= nil
	then
		return true
	end

	return false
end




function Fu.IsHumanPlayer( nUnit )

	return not nUnit:IsBot() -- or IsPlayerBot( nUnit:GetPlayerID() )

end




function Fu.IsValid( nTarget )
	return nTarget ~= nil
			and not nTarget:IsNull()
			and nTarget:CanBeSeen()
			and nTarget:IsAlive()
			and not nTarget:IsBuilding()
end


function Fu.IsValidTarget(nTarget)
	-- NOTE: return Fu.Utils.IsValidUnit(nTarget) -- ideally it should be IsValidUnit, but a lot of legacy usage causing some problems.
	return Fu.Utils.IsValidHero(nTarget)
end


function Fu.IsValidHero( nTarget )
	return Fu.Utils.IsValidHero(nTarget)
end


function Fu.IsValidBuilding( nTarget )
	return Fu.Utils.IsValidBuilding(nTarget)
end


function Fu.IsRoshan( nTarget )

	return nTarget ~= nil
			and not nTarget:IsNull()
			and nTarget:CanBeSeen()
			and nTarget:IsAlive()
			and string.find( nTarget:GetUnitName(), "roshan" ) ~= nil

end



function Fu.CanBeAttacked( unit )
	return  unit ~= nil
			and not Fu.HasForbiddenModifier( unit )
			and unit:IsAlive()
			and unit:CanBeSeen()
			and not unit:IsNull()
			and not unit:IsAttackImmune()
			and not unit:IsInvulnerable()
			and not unit:HasModifier("modifier_fountain_glyph")
			and not unit:HasModifier("modifier_omninight_guardian_angel")
			and not unit:HasModifier("modifier_winter_wyvern_cold_embrace")
			and not unit:HasModifier("modifier_dark_willow_shadow_realm_buff")
			and not unit:HasModifier("modifier_ringmaster_the_box_buff")
			and not unit:HasModifier("modifier_dazzle_nothl_projection_soul_debuff")
			and (unit:GetTeam() == GetTeam() 
					or not unit:HasModifier("modifier_crystal_maiden_frostbite") )
			and (unit:GetTeam() ~= GetTeam() 
			     or ( unit:GetUnitName() ~= "npc_dota_wraith_king_skeleton_warrior" 
					  and unit:GetHealth()/unit:GetMaxHealth() < 0.5 ) )
end



function Fu.IsTormentor(nTarget)
	return nTarget ~= nil
			and not nTarget:IsNull()
			and nTarget:CanBeSeen()
			and nTarget:IsAlive()
			and string.find(nTarget:GetUnitName(), 'miniboss') ~= nil
end


function Fu.IsRealBot(bot)
	for i = 1, 5 do
		local member = GetTeamMember(i)
		if member and bot == member then
			return true
		end
	end
	return false
end

function Fu.IsMeepoClone(hero)
	if Fu.IsValidHero(hero)
	and hero:GetUnitName() == 'npc_dota_hero_meepo'
	and not Fu.IsRealBot(hero)
	then
		return true
	end
	return false
end


function Fu.IsEnemyHero(hero)
	if hero ~= nil
	and hero:GetTeam() ~= GetBot():GetTeam()
	then
		return true
	else
		return false
	end
end

-- Adds an avoidance zone for use with GeneratePath(). Takes a Vector with x and y as a 2D location, and z as as radius. Returns a handle to the avoidance zone.
-- location as Vector(-7174.0, -6671.0, 10.0)

end

return Init
