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
						{1,3,2,2,2,6,2,1,1,1,6,3,3,3,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sCrimsonPipe = RandomInt( 1, 2 ) == 1 and "item_crimson_guard" or "item_pipe"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_circlet",
	"item_circlet",
	"item_quelling_blade",

	"item_magic_wand",
	"item_bracer",
	"item_boots",
	"item_veil_of_discord",
	"item_blink",
	"item_cyclone",
	"item_shivas_guard",--
	"item_travel_boots",
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_black_king_bar",--
	sCrimsonPipe,--
	"item_overwhelming_blink",--
	"item_ultimate_scepter_2",
	"item_wind_waker",--
	"item_travel_boots_2",--
	"item_moon_shard",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	"item_priest_outfit",
	"item_mekansm",
	"item_glimmer_cape",
	"item_aghanims_shard",
	"item_guardian_greaves",
	"item_spirit_vessel",
--	"item_wraith_pact",
	"item_ultimate_scepter",
	"item_shivas_guard",
	"item_moon_shard",
	"item_ultimate_scepter_2",
	"item_sheepstick",
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	-- "item_glimmer_cape",
	"item_boots_of_bearing",--
	"item_pipe",--
    "item_ultimate_scepter",
	"item_cyclone",
--	"item_wraith_pact",
    -- "item_lotus_orb",
	-- "item_gungir",--
	"item_shivas_guard",--
	"item_sheepstick",--
	"item_moon_shard",
    "item_wind_waker",--
	"item_ultimate_scepter_2",
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",
}
if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = true
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_sand_king

"Ability1"		"sandking_burrowstrike"
"Ability2"		"sandking_sand_storm"
"Ability3"		"sandking_caustic_finale"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"sandking_epicenter"
"Ability10"		"special_bonus_movement_speed_20"
"Ability11"		"special_bonus_hp_200"
"Ability12"		"special_bonus_unique_sand_king_2"
"Ability13"		"special_bonus_unique_sand_king_3"
"Ability14"		"special_bonus_armor_10"
"Ability15"		"special_bonus_unique_sand_king"
"Ability16"		"special_bonus_hp_regen_50"
"Ability17"		"special_bonus_unique_sand_king_4"

modifier_sand_king_caustic_finale
modifier_sand_king_caustic_finale_orb
modifier_sand_king_caustic_finale_slow
modifier_sandking_impale
modifier_sandking_burrowstrike
modifier_sandking_sand_storm
modifier_sandking_sand_storm_slow
modifier_sand_king_epicenter
modifier_sand_king_epicenter_slow


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'sand_king')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'sand_king')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'sand_king')
local Stinger  = SafeAbility(bot:GetAbilityByName('sandking_scorpion_strike'), 'sandking_scorpion_strike', 'sand_king')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'sand_king')


local castQDesire, castQTarget
local castWDesire
local StingerDesire, StingerLocation
local castRDesire

local aetherRange = 0


local bAttacking
local nLV, nKeepMana, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) then return end

	bAttacking = Fu.IsAttacking(bot)

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQTarget )
		return
	end

	castWDesire = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityW )
		return
	end

	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end

	StingerDesire, StingerLocation = X.ConsiderStinger()
	if StingerDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(Stinger, StingerLocation)
		return
	end
end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nCastRange = abilityQ:GetCastRange() + aetherRange

	-- Interrupt TP
	local tpTarget = Fu.GetTPTarget(bot, nCastRange)
	if tpTarget and not tpTarget:IsMagicImmune() then
		return BOT_ACTION_DESIRE_HIGH, tpTarget:GetLocation(), 'Q-InterruptTP'
	end

	local nSkillLV = abilityQ:GetLevel()
	local nRadius	 = abilityQ:GetSpecialValueInt( "burrow_width" )
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nInBonusEnemyList = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )

	local nTargetLocation = nil

	--击杀
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage + bot:GetAttackDamage(), 3.0 )
		then
			nTargetLocation = npcEnemy:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-击杀'..Fu.Chat.GetNormName( npcEnemy )
		end
	end

	--Aoe
	local nCanHurtEnemyAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius + 40, 0, 0 )
	if nCanHurtEnemyAoE.count >= 3
	then
		nTargetLocation = nCanHurtEnemyAoE.targetloc
		return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-Aoe:'..( nCanHurtEnemyAoE.count )
	end

	--团战
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, nCastRange, nRadius + 30, 2 )
		if nAoeLoc ~= nil
		then
			nTargetLocation = nAoeLoc
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-TeamFight'
		end
	end


	--攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			if nSkillLV >= 2 or nMP > 0.68 or Fu.GetHP( botTarget ) < 0.38
			then
				nTargetLocation = botTarget:GetLocation()
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-攻击:'..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
		and ( nSkillLV >= 4 or nHP < 0.4 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 ) or bot:GetActiveModeDesire() > 0.7 )
				and not bot:IsFacingLocation( npcEnemy:GetLocation(), 150 )
			then
				local nDistance = GetUnitToUnitDistance( bot, npcEnemy )
				nTargetLocation = Fu.GetUnitTowardDistanceLocation( npcEnemy, bot, nDistance + nCastRange )
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'Q-撤退:'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	--Farm
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		if Fu.IsValid( botTarget )
			and botTarget:GetTeam() == TEAM_NEUTRAL
			and Fu.IsInRange( bot, botTarget, 1000 )
			and bot:IsFacingLocation( botTarget:GetLocation(), 45 )
			and ( botTarget:GetMagicResist() < 0.4 or nMP > 0.9 )
		then
			local nShouldHurtCount = nMP > 0.5 and 3 or 4
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, 200, 0, 0 )
			if ( locationAoE.count >= nShouldHurtCount )
			then
				nTargetLocation = locationAoE.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q-打钱:"..locationAoE.count
			end
		end
	end


	--Push
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and nSkillLV >= 2 and DotaTime() > 8 * 60
		and #hAllyList <= 2 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( 1300, true )
		if #laneCreepList >= 5
			and Fu.IsValid( laneCreepList[1] )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			local locationAoEHurt = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius + 90, 0, 0 )
			if locationAoEHurt.count >= 3
			then
				nTargetLocation = locationAoEHurt.targetloc
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q-推线"..locationAoEHurt.count
			end
		end
	end


	--Roshan
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 600
	then
		if Fu.IsRoshan( botTarget ) and Fu.GetHP( botTarget ) > 0.15
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			nTargetLocation = botTarget:GetLocation()
			return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "Q-肉山"
		end
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange()
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, 800, true, BOT_MODE_NONE )

	local nRadius = abilityW:GetSpecialValueInt( "sand_storm_radius" )

	--躲弹道
	if Fu.IsNotAttackProjectileIncoming( bot, 400 )
		or ( Fu.IsWithoutTarget( bot ) and Fu.GetAttackProjectileDamageByRange( bot, 1600 ) >= bot:GetHealth() )
	then
		return BOT_ACTION_DESIRE_HIGH, vEscapeLoc, 'W-躲避'
	end


	--团战Aoe
	if Fu.IsInTeamFight( bot )
	then
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, 100, nRadius * 0.6, 2 )
		if nAoeLoc ~= nil
		then
			return BOT_ACTION_DESIRE_HIGH, 'W-团战Aoe'
		end
	end


	--进攻
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nRadius/3 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
		then
			if nSkillLV >= 3 or nMP > 0.88 or Fu.GetHP( botTarget ) < 0.4
			then
				return BOT_ACTION_DESIRE_HIGH, "W-进攻:"..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	--带线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and nSkillLV >= 4 and DotaTime() > 18 * 60
		and #hAllyList <= 1 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( 700, true )
		if #laneCreepList >= 8
			and Fu.IsValid( laneCreepList[1] )
			and Fu.IsValid( botTarget )
			and Fu.IsInRange( botTarget, bot, 300 )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			return BOT_ACTION_DESIRE_HIGH, "W-推线"..#laneCreepList
		end
	end


	--打野
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		if Fu.IsValid( botTarget )
			and botTarget:GetTeam() == TEAM_NEUTRAL
			and Fu.IsInRange( bot, botTarget, 300 )
			and bot:IsFacingLocation( botTarget:GetLocation(), 20 )
			and ( botTarget:GetMagicResist() < 0.4 or nMP > 0.8 )
		then
			local nShouldHurtCount = nMP > 0.5 and 4 or 5
			local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), 100, 600, 0, 0 )
			if ( locationAoE.count >= nShouldHurtCount )
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, "W-打钱:"..locationAoE.count
			end
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
		and ( nSkillLV >= 3 or nHP < 0.5 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 ) or bot:GetActiveModeDesire() > 0.7 )
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetLocation, 'W-撤退:'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end



	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderStinger()
	if not Stinger:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, Stinger:GetCastRange())
	local nRadius = Stinger:GetSpecialValueInt('radius')
	local nManaAfter = Fu.GetManaAfter(Stinger:GetManaCost()) * bot:GetMana()
	local nAbilityLevel = Stinger:GetLevel()

	if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nCastRange + nRadius)

                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
					if GetUnitToLocationDistance(bot, Fu.GetCenterOfUnits(nInRangeEnemy)) > nCastRange
					and GetUnitToLocationDistance(bot, Fu.GetCenterOfUnits(nInRangeEnemy)) < nCastRange + nRadius
					then
						return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
					else
						return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
					end

                end

				if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
				and not Fu.IsInRange(bot, botTarget, nCastRange)
				then
					return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
				else
					return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
				end
            end
		end
	end

	if Fu.IsRetreating(bot)
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
			and (not abilityQ:IsFullyCastable() and not abilityW:IsFullyCastable())
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                and GetUnitToUnitDistance(bot, enemyHero) < nRadius
                then
                    return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
                end
            end
        end
    end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot))
	and nManaAfter > abilityQ:GetManaCost() + abilityW:GetManaCost()
	then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1600, true)
        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 5
		and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
		and not Fu.IsRunning(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
	end

    if Fu.IsFarming(bot)
	and nManaAfter > abilityQ:GetManaCost() + abilityW:GetManaCost()
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(700)
            if nNeutralCreeps ~= nil and #nNeutralCreeps >= 3
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(700, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
			and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
			and not Fu.IsRunning(nEnemyLaneCreeps[1])
            then
                return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
            end
        end
    end

    if Fu.IsLaning(bot)
	and nManaAfter > abilityQ:GetManaCost() + abilityW:GetManaCost()
	and nAbilityLevel >= 2
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + nRadius, true)

        if nInRangeEnemy ~= nil and #nInRangeEnemy == 0
        and nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
        and bAttacking
		and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
		and not Fu.IsRunning(nEnemyLaneCreeps[1])
        then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
        end
	end

    if Fu.IsDoingRoshan(bot)
	and nManaAfter > abilityQ:GetManaCost() + abilityW:GetManaCost()
    then
        if Fu.IsRoshan(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, 600)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
	and nManaAfter > abilityQ:GetManaCost() + abilityW:GetManaCost()
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 600)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange()
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	local nRadius = abilityR:GetSpecialValueInt( "epicenter_radius" )
	local nPulses = abilityR:GetSpecialValueInt( "epicenter_pulses" )
	local nMaxRadius = nRadius + nPulses * 50

	--两机会或两个控后Aoe
	if Fu.IsInTeamFight( bot, 1600 )
	then
		--有Aoe的机会先开大
		local nAoeLoc = Fu.GetAoeEnemyHeroLocation( bot, 1200, 400, 2 )
		if nAoeLoc ~= nil
			and #hAllyList >= 2
		then
			local npcEnemy = hEnemyList[1]
			if Fu.IsValidHero( npcEnemy )
				and not Fu.IsInRange( bot, npcEnemy, 800 )
				and Fu.IsInRange( bot, npcEnemy, 1200 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and ( #hEnemyList >= 2 or npcEnemy:GetHealth() > bot:GetAttackDamage() * 5 )
			then
				return BOT_ACTION_DESIRE_HIGH, 'R-团战1'
			end
		end

		--敌人被控制住再开大
		if #hEnemyList >= 2
		then
			local nDisabledCount = 0
			local nTotalCount = 0
			for _, npcEnemy in pairs( hEnemyList )
			do
				if Fu.IsValidHero( npcEnemy )
					and Fu.IsInRange( bot, npcEnemy, 1000 )
					and Fu.CanCastOnNonMagicImmune( npcEnemy )
				then
					nTotalCount = nTotalCount + 1
					if Fu.IsDisabled( npcEnemy )
						or npcEnemy:IsSilenced()
						or npcEnemy:GetMana() < 50
					then
						nDisabledCount = nDisabledCount + 1
					end
				end
			end

			if nDisabledCount == nTotalCount
				and Fu.IsInRange( bot, hEnemyList[1], nMaxRadius * 0.5 )
			then
				return BOT_ACTION_DESIRE_HIGH, 'R-团战2'
			end
		end

	end


	--进攻
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( bot, botTarget, 1000 )
		then
			local nDamageToTarget = bot:GetEstimatedDamageToTarget( true, botTarget, 6.0, DAMAGE_TYPE_PHYSICAL )
			if not Fu.CanKillTarget( botTarget, nDamageToTarget, DAMAGE_TYPE_PHYSICAL )
			then

				if ( bot:IsInvisible() or bot:IsMagicImmune() )
					and Fu.IsInRange( bot, botTarget, nRadius + 200 )
				then
					return BOT_ACTION_DESIRE_HIGH, "R-隐身或魔免开大进攻"..Fu.Chat.GetNormName( botTarget )
				end

				if ( Fu.IsDisabled( botTarget ) or botTarget:IsSilenced() )
					and Fu.IsInRange( bot, botTarget, nRadius + 150 )
				then
					return BOT_ACTION_DESIRE_HIGH, "R-找机会开大进攻"..Fu.Chat.GetNormName( botTarget )
				end

			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


return X

