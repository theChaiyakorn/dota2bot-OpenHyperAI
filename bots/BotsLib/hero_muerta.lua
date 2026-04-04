local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )

local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,2,1,3,1,6,1,3,3,3,2,6,2,2,6},--pos1,2
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_slippers",
	"item_circlet",

	"item_magic_wand",
	"item_wraith_band",
	"item_wraith_band",
	"item_power_treads",
	
	"item_mask_of_madness",
	"item_dragon_lance",
	"item_lesser_crit",
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_greater_crit",--
	"item_invis_sword",
	"item_silver_edge",--
	"item_butterfly",--
	"item_travel_boots",
	"item_moon_shard",
	"item_satanic",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_faerie_fire",

	"item_magic_wand",
	"item_arcane_boots",
	"item_urn_of_shadows",
	"item_glimmer_cape",--
	"item_spirit_vessel",--
	"item_aghanims_shard",
	"item_guardian_greaves",--
	"item_sheepstick",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_4']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_muerta

Modifier or ability names not supported as of 5.5.2024

--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local abilityAS = bot:GetAbilityByName( sAbilityList[4] )
local SpectralSlug = bot:GetAbilityByName('muerta_spectral_slug')

local castQDesire, castQTarget
local castWDesire, castWLocation
local castEDesire, castRDesire
local castASDesire, castASTarget
local SpectralSlugDesire, SpectralSlugTarget

local nKeepMana = 280
local botTarget = nil

-- was for fully takeover, but not used atm.
function X.Think()
	-- X.AbilityItemUsage = require( GetScriptDirectory()..'/ability_item_usage_generic')

	-- bot:Action_AttackMove(Fu.GetEnemyFountain())
    if X.TeamRoam == nil then
		X.TeamRoam = require(GetScriptDirectory() .. "/FuncLib/mode_team_roam_generic_shared")
        -- X.FarmGeneric = require(GetScriptDirectory() .. "/FuncLib/mode_farm_generic_shared")
    --     -- X.ItemPurchase = require(GetScriptDirectory() .. "/item_purchase_generic")
    --     -- X.TeamRoam = require(GetScriptDirectory() .. "/mode_team_roam_generic")
    --     -- X.AbilityItemUsage = require(GetScriptDirectory() .. "/ability_item_usage_generic")
    end

    -- -- X.ItemPurchase.ItemPurchaseThink()

    if X.TeamRoam.GetDesire() > 0 then
        X.TeamRoam.Think()
    end
    -- if X.FarmGeneric.GetDesire() > 0 then
    --     X.FarmGeneric.Think()
    -- end

    -- X.AbilityItemUsage.ItemUsageThink()
    -- X.AbilityItemUsage.AbilityUsageThink()
    -- X.AbilityItemUsage.BuybackUsageThink()
    -- X.AbilityItemUsage.AbilityLevelUpThink()

end

function X.SkillsComplement()

	X.ConsiderTarget()
	Fu.ConsiderForMkbDisassembleMask( bot )

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	-- Re-fetch ability handles each tick for safety against Aghs upgrades
	abilityQ = bot:GetAbilityByName( sAbilityList[1] )
	abilityW = bot:GetAbilityByName( sAbilityList[2] )
	abilityE = bot:GetAbilityByName( sAbilityList[3] )
	abilityR = bot:GetAbilityByName( sAbilityList[6] )
	abilityAS = bot:GetAbilityByName( sAbilityList[4] )

	-- Cache per-tick variables
	botTarget = Fu.GetProperTarget(bot)

    castQDesire, castQTarget = X.ConsiderQ()
    if castQDesire > 0
    then
        bot:Action_UseAbilityOnEntity(abilityQ, castQTarget)
        -- bot:Action_UseAbilityOnTree(abilityQ, castQTarget) -- dont know how to choose release angle.
        return
    end

	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then
		Fu.SetQueuePtToINT( bot, true )
		bot:ActionQueue_UseAbility( abilityR )
		return
	end

	castWDesire, castWLocation = X.ConsiderW()
	if ( castWDesire > 0 )
	then
		Fu.SetQueuePtToINT( bot, false )
		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWLocation )
		return
	end

	SpectralSlugDesire, SpectralSlugTarget = X.ConsiderSpectralSlug()
	if SpectralSlugDesire > 0
	then
		Fu.SetQueuePtToINT( bot, false )
		bot:ActionQueue_UseAbilityOnEntity( SpectralSlug, SpectralSlugTarget )
		return
	end

	castEDesire = X.ConsiderE()
	if ( castEDesire > 0 )
	then
		bot:Action_ClearActions( false )
		bot:ActionQueue_UseAbility( abilityE )
		return
	end

	castASDesire, castASTarget = X.ConsiderAS()
	if ( castASDesire > 0 )
	then
		Fu.SetQueuePtToINT( bot, true )
		bot:ActionQueue_UseAbilityOnEntity( abilityAS, castASTarget )
		return
	end


end

function X.ConsiderTarget()
	if not Fu.IsRunning( bot )
		or bot:HasModifier( "modifier_item_hurricane_pike_range" )
	then return end

	local nAttackRange = math.max(1600, bot:GetAttackRange() + 60)
	local nInAttackRangeWeakestEnemyHero = Fu.GetAttackableWeakestUnit( bot, nAttackRange, true, true )

	local npcTarget = Fu.GetProperTarget( bot )
	local nTargetUint = nil

	if Fu.IsValidHero( npcTarget )
		and GetUnitToUnitDistance( npcTarget, bot ) > nAttackRange
		and Fu.IsValidHero( nInAttackRangeWeakestEnemyHero )
	then
		nTargetUint = nInAttackRangeWeakestEnemyHero
		bot:SetTarget( nTargetUint )
		return
	end

end

function X.ConsiderQ()
	if not abilityQ:IsFullyCastable() then return 0 end

	local nCastRange = Fu.GetProperCastRange(false, bot, abilityQ:GetCastRange())
    local nDamage = abilityQ:GetSpecialValueInt('damage')
	
	-- local nCastPoint = abilityQ:GetCastPoint()
	-- local nRadius = abilityQ:GetSpecialValueInt('bounce_range')
    -- local nSpeed = abilityQ:GetSpecialValueInt('projectile_speed')
    -- local nAbilityLevel = abilityQ:GetLevel()

    local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

	-- Interrupt channeling enemies (high priority)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero( enemyHero )
		and Fu.IsInRange( bot, enemyHero, nCastRange )
		and Fu.CanCastOnNonMagicImmune( enemyHero )
		and Fu.CanCastOnTargetAdvanced( enemyHero )
		and enemyHero:IsChanneling()
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero, 'Q-InterruptChannel'
		end
	end

	-- get the kill
    for _, enemyHero in pairs(nEnemyHeroes)
    do
		if Fu.IsValidHero( enemyHero )
		and Fu.IsInRange( bot, enemyHero, nCastRange )
		and Fu.CanCastOnNonMagicImmune( enemyHero )
		and Fu.CanCastOnTargetAdvanced( enemyHero )
        and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_PHYSICAL)
        and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero, 'Q-Kill'
		end
    end

	--进攻
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q-Attack'
		end
	end

	--撤退
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nEnemyHeroes )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 )
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget, 'Q-Retreat'
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderW()

	if not abilityW:IsFullyCastable() then return 0 end

	local nCastRange = abilityW:GetCastRange() + 200
	local nSkillLV = abilityW:GetLevel()
	local nRadius = abilityW:GetAOERadius()
	local nCastPoint = abilityW:GetCastPoint()
	local botLocation = bot:GetLocation()

	local nEnemysHeroesInSkillRange = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	-- Interrupt channeling enemies: center The Calling silence on them
	for _, enemyHero in pairs(nEnemysHeroesInSkillRange)
	do
		if Fu.IsValidHero( enemyHero )
		and Fu.IsInRange( bot, enemyHero, nCastRange )
		and Fu.CanCastOnNonMagicImmune( enemyHero )
		and enemyHero:IsChanneling()
		and not Fu.IsSuspiciousIllusion(enemyHero)
		then
			return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
		end
	end

	local nCanHurtHeroLocationAoE = bot:FindAoELocation( true, true, botLocation, nCastRange, nRadius-30, 0.8, 0 )

	--对多个敌方英雄使用
	if #nEnemysHeroesInSkillRange >= 2
		and ( nCanHurtHeroLocationAoE.cout ~= nil and nCanHurtHeroLocationAoE.cout >= 2 )
		and bot:GetActiveMode() ~= BOT_MODE_LANING
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or ( bot:GetActiveMode() == BOT_MODE_RETREAT and bot:GetActiveModeDesire() < 0.6 ) )
	then
		return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoE.targetloc
	end

	--对当前目标英雄使用
	if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 300 )
			and ( nSkillLV >= 3 or bot:GetMana() >= nKeepMana )
		then

			if botTarget:IsFacingLocation( Fu.GetEnemyFountain(), 30 )
				and Fu.GetHP( botTarget ) < 0.4
				and Fu.IsRunning( botTarget )
			then
				--追击减速当前目标
				for i=0, 800, 200
				do
					local nCastLocation = Fu.GetLocationTowardDistanceLocation( botTarget, Fu.GetEnemyFountain(), nRadius + 800 - i )
					if GetUnitToLocationDistance( bot, nCastLocation ) <= nCastRange + 200
					then
						return BOT_ACTION_DESIRE_HIGH, nCastLocation
					end
				end
			end

			--对当前目标使用技能
			local npcTargetLocInFuture = Fu.GetCorrectLoc( botTarget, nCastPoint + 1.8 )
			if Fu.GetLocationToLocationDistance( botTarget:GetLocation(), npcTargetLocInFuture ) > 300
				and botTarget:GetMovementDirectionStability() > 0.4
			then
				return BOT_ACTION_DESIRE_HIGH, npcTargetLocInFuture
			end

			--近处预测将到近处来的目标
			local castDistance = GetUnitToUnitDistance( bot, botTarget )
			if botTarget:IsFacingLocation( botLocation, 30 ) and Fu.IsMoving( botTarget )
			then
				if castDistance > 400
				then
					castDistance = castDistance - 200
				end
				return BOT_ACTION_DESIRE_HIGH, Fu.GetUnitTowardDistanceLocation( bot, botTarget, castDistance )
			end

			--远处预测将到远处去的目标
			if bot:IsFacingLocation( botTarget:GetLocation(), 30 )
			then
				if castDistance <= nCastRange - 200
				then
					castDistance = castDistance + 400
				else
					castDistance = nCastRange + 300
				end
				return BOT_ACTION_DESIRE_HIGH, Fu.GetUnitTowardDistanceLocation( bot, botTarget, castDistance )
			end

			--目标位置无规律
			return BOT_ACTION_DESIRE_HIGH, Fu.GetLocationTowardDistanceLocation( botTarget, Fu.GetEnemyFountain(), nRadius/2 )

		end
	end

	--撤退时
	if Fu.IsRetreating( bot )
		and not bot:IsInvisible()
	then
		local nCanHurtHeroLocationAoENearby = bot:FindAoELocation( true, true, botLocation, nCastRange - 400, nRadius, 1.5, 0 )
		if nCanHurtHeroLocationAoENearby.count >= 2
		then
			return BOT_ACTION_DESIRE_HIGH, nCanHurtHeroLocationAoENearby.targetloc
		end

		if bot:GetActiveModeDesire() > 0.8
		then
			local nEnemyNearby = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE )
			for _, npcEnemy in pairs( nEnemyNearby )
			do
				if Fu.IsValid( npcEnemy )
					and bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
				then
					local nCastLocation = ( botLocation + npcEnemy:GetLocation() )/2
                    --对特定位置使用技能
                    return BOT_ACTION_DESIRE_HIGH, nCastLocation
				end
			end
		end
	end

	if Fu.IsFarming( bot ) and bot:GetMana() >= nKeepMana
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( 800 )
		if #nNeutralCreeps >= 4
			and Fu.IsValid( botTarget )
			and not Fu.CanKillTarget( botTarget, bot:GetAttackDamage() * 3.88 , DAMAGE_TYPE_PHYSICAL )
		then
			local nAoE = bot:FindAoELocation( true, false, botLocation, nCastRange, nRadius, 0.8, 0 )
			if nAoE.count >= 5
			then
				return BOT_ACTION_DESIRE_HIGH, nAoE.targetloc
			end
		end
	end

	if bot:GetActiveMode() == BOT_MODE_ROSHAN
	then
		local nAttackTarget = bot:GetAttackTarget()
		if Fu.IsValid( nAttackTarget )
			and Fu.GetHP( nAttackTarget ) > 0.5
			and Fu.IsInRange( nAttackTarget, bot, 600 )
		then
			local nAllies = Fu.GetNearbyHeroes(bot, 800, false, BOT_MODE_ROSHAN )
			if #nAllies >= 4
			then
				return BOT_ACTION_DESIRE_HIGH, nAttackTarget:GetLocation()
			end
		end
	end

	return 0
end

function X.ConsiderE()
	if not abilityE:IsTrained() or not abilityE:IsFullyCastable() then 
        return BOT_ACTION_DESIRE_NONE 
    end

    if not abilityE:GetToggleState() then
        return BOT_ACTION_DESIRE_HIGH
    end
	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderR()

	if not abilityR:IsFullyCastable() then return 0 end

    local nAttackRange = bot:GetAttackRange()
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE )

    if Fu.IsRetreating( bot )
	then
		if bot:WasRecentlyDamagedByAnyHero( 2.0 ) and #nEnemyHeroes > 0 and Fu.GetHP(bot) < 0.5
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	if Fu.IsWithoutTarget( bot ) and Fu.GetAttackProjectileDamageByRange( bot, 800 ) >= bot:GetHealth()
	then
		return BOT_ACTION_DESIRE_MODERATE
	end

	if Fu.IsGoingOnSomeone( bot ) and false
	then
		local npcTarget = bot:GetTarget()
		if Fu.IsValidHero( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nAttackRange )
		then
            if Fu.GetHP(npcTarget) <= 0.7 then return BOT_ACTION_DESIRE_MODERATE end

            if npcTarget:HasModifier('modifier_item_ethereal_blade_ethereal')
            or npcTarget:HasModifier('modifier_necrophos_death_seeker_ethereal')
            or npcTarget:HasModifier('modifier_necrolyte_sadist_active')
            or npcTarget:HasModifier('modifier_pugna_decrepify')
            or npcTarget:HasModifier('modifier_ghost_state')
            then
		        return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

	if not bot:IsMagicImmune()
    and not bot:IsInvulnerable()
    and Fu.IsInTeamFight(bot)
	then
        if Fu.GetEnemyCount(bot, 1000) >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
    end
	return 0
end

function X.ConsiderAS()

	if not abilityAS:IsTrained()
		or not abilityAS:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = abilityAS:GetCastRange() + 200
	-- local nRadius = 100
	-- local nCastPoint = abilityAS:GetCastPoint()
	-- local nManaCost = abilityAS:GetManaCost()

	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )

	--撤退时保护自己
	if Fu.IsRetreating( bot )
		and ( bot:WasRecentlyDamagedByAnyHero( 3.0 ) or bot:GetActiveModeDesire() > 0.7 )
	then
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				local hCastTarget = npcEnemy
				local sCastMotive = '撤退'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end

	--团战中对最能输出的人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcStrongestEnemy = nil
		local nStrongestPower = 0
		local nEnemyCount = 0
		
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
			then
				nEnemyCount = nEnemyCount + 1
				if Fu.CanCastOnTargetAdvanced( npcEnemy )
					and not Fu.IsDisabled( npcEnemy )
					and not npcEnemy:IsDisarmed()
				then
					local npcEnemyPower = npcEnemy:GetEstimatedDamageToTarget( true, bot, 6.0, DAMAGE_TYPE_ALL )
					if ( npcEnemyPower > nStrongestPower )
					then
						nStrongestPower = npcEnemyPower
						npcStrongestEnemy = npcEnemy
					end
				end
			end
		end

		if npcStrongestEnemy ~= nil and nEnemyCount >= 2
			and Fu.IsInRange( bot, npcStrongestEnemy, nCastRange + 150 )
		then
			local hCastTarget = npcStrongestEnemy
			local sCastMotive = '团战控制输出'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		local targetHero = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( targetHero )
			and Fu.IsInRange( bot, targetHero, nCastRange )
			and Fu.CanCastOnNonMagicImmune( targetHero )
		then
			return BOT_ACTION_DESIRE_HIGH, targetHero
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0

end


function X.ConsiderSpectralSlug()
	if not Fu.CanCastAbility(SpectralSlug) then
		return BOT_ACTION_DESIRE_NONE
	end

	local nCastRange = SpectralSlug:GetCastRange()
	local nCastPoint = SpectralSlug:GetCastPoint()
	local nDamage = SpectralSlug:GetSpecialValueInt('damage')
	local nSpeed = SpectralSlug:GetSpecialValueInt('projectile_speed')

	local nEnemyHeroes = bot:GetNearbyHeroes(nCastRange + 300, true, BOT_MODE_NONE)
	local nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)

	for _, enemyHero in pairs(nEnemyHeroes) do
		if  Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nCastRange + 300)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.CanCastOnTargetAdvanced(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		then
			local eta = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
			if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end

			if enemyHero:HasModifier('modifier_abaddon_borrowed_time') then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end

			local nAllyHeroesAttackingTarget = Fu.GetHeroesTargetingUnit(nAllyHeroes, enemyHero)
			if Fu.IsGoingOnSomeone(bot) then
				if  not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
				and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
				and Fu.GetHP(enemyHero) < 0.5
				and #nAllyHeroesAttackingTarget <= 1
				then
					return BOT_ACTION_DESIRE_HIGH, enemyHero
				end
			end
		end
	end

	if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
			and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
			and not Fu.IsDisabled(enemyHero)
			and not enemyHero:IsDisarmed()
			and not enemyHero:HasModifier('modifier_muerta_spectral_slug_ethereal')
			then
				local nAllyHeroesAttackingTarget = Fu.GetHeroesTargetingUnit(nAllyHeroes, enemyHero)
				if #nAllyHeroesAttackingTarget == 0 then
					return BOT_ACTION_DESIRE_HIGH, enemyHero
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X
