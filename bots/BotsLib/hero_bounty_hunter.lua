local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos2
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {0, 10},
							['t10'] = {10, 0},
						},
						{--po3
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {10, 0},
						}
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,6,2,1,1,1,6,3,3,3,6},--pos2
						{2,3,2,1,2,6,2,3,3,3,6,1,1,1,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sUtilityItem = RandomInt( 1, 2 ) == 1 and "item_crimson_guard" or "item_heavens_halberd"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_double_branches",
	"item_quelling_blade",
	"item_tango",
	"item_faerie_fire",
	"item_magic_wand",

	"item_phase_boots",
	"item_phylactery",
	"item_ultimate_scepter",
	"item_octarine_core",--
	"item_black_king_bar",--
	"item_angels_demise",--
	"item_assault",--
	"item_travel_boots",
	"item_monkey_king_bar",--
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
	"item_moon_shard",
	"item_aghanims_shard",
}

sRoleItemsBuyList['pos_2'] = {
	"item_double_branches",
	"item_quelling_blade",
	"item_tango",
	"item_faerie_fire",

	"item_bottle",
	"item_phase_boots",
	"item_magic_wand",
	"item_phylactery",
	"item_ultimate_scepter",
	"item_octarine_core",--
	"item_black_king_bar",--
	"item_angels_demise",--
	"item_assault",--
	"item_travel_boots",
	"item_moon_shard",
	"item_monkey_king_bar",--
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
	"item_aghanims_shard",
}

sRoleItemsBuyList['pos_3'] = {
	"item_double_branches",
	"item_quelling_blade",
	"item_tango",
	"item_faerie_fire",
	"item_magic_wand",

	"item_boots",
	"item_phase_boots",
	"item_phylactery",
	"item_pipe",
	"item_black_king_bar",--
	sUtilityItem,--
	"item_angels_demise",--
	"item_assault",--
	"item_travel_boots",
	"item_monkey_king_bar",--
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
	"item_moon_shard",
	"item_aghanims_shard",
}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_orb_of_frost",
	"item_magic_wand",

	"item_boots",
	"item_tranquil_boots",
	"item_ancient_janggo",
	"item_guardian_greaves",--
	"item_solar_crest",--
	"item_heavens_halberd",--
	"item_sheepstick",--
	"item_lotus_orb",--
	"item_moon_shard",
	"item_assault",--
	"item_aghanims_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_double_branches",
	"item_blood_grenade",
	"item_orb_of_frost",
	"item_magic_wand",

	"item_boots",
	"item_arcane_boots",
	"item_ancient_janggo",
	"item_pipe",--
	"item_solar_crest",--
	"item_boots_of_bearing",--
	-- "item_force_staff",--
	"item_heavens_halberd",--
	"item_sheepstick",--
	"item_moon_shard",
	"item_lotus_orb",--
	"item_aghanims_shard",
	"item_ultimate_scepter_2",
}


X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_power_treads",
	"item_quelling_blade",

	"item_heavens_halberd",
	"item_quelling_blade",

	"item_abyssal_blade",
	"item_magic_wand",

	"item_assault",
	"item_ancient_janggo",
}

if Fu.Role.IsPvNMode() then X['sBuyList'], X['sSellList'] = { 'PvN_BH' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_bounty_hunter

"Ability1"		"bounty_hunter_shuriken_toss"
"Ability2"		"bounty_hunter_jinada"
"Ability3"		"bounty_hunter_wind_walk"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"bounty_hunter_track"
"Ability10"		"special_bonus_movement_speed_15"
"Ability11"		"special_bonus_attack_damage_20"
"Ability12"		"special_bonus_unique_bounty_hunter_2"
"Ability13"		"special_bonus_hp_275"
"Ability14"		"special_bonus_attack_speed_50"
"Ability15"		"special_bonus_unique_bounty_hunter"
"Ability16"		"special_bonus_evasion_40"
"Ability17"		"special_bonus_unique_bounty_hunter_3"

modifier_bounty_hunter_jinada
modifier_bounty_hunter_wind_walk
modifier_bounty_hunter_wind_walk_slow
modifier_bounty_hunter_track

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'bounty_hunter')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'bounty_hunter')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'bounty_hunter')
local FriendlyShadow = SafeAbility(bot:GetAbilityByName('bounty_hunter_wind_walk_ally'), 'bounty_hunter_wind_walk_ally', 'bounty_hunter')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'bounty_hunter')
local talent3 = SafeAbility(bot:GetAbilityByName(sTalentList[3]), 'sTalentList[3]', 'bounty_hunter')

local castQDesire, castQTarget
local castEDesire
local FriendlyShadowDesire, FriendlyShadowTarget
local castRDesire, castRTarget

local aetherRange = 0
local talent3Damage = 0

function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies
	if talent3:IsTrained() then talent3Damage = talent3:GetSpecialValueInt( "value" ) end

	castEDesire = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityE )
		return
	end

	FriendlyShadowDesire, FriendlyShadowTarget = X.ConsiderFriendlyShadow()
	if (FriendlyShadowDesire > 0)
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnEntity(FriendlyShadow, FriendlyShadowTarget)
		return
	end

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( 'bonus_damage' ) + talent3Damage
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nCastTarget = nil


	local nRadius = abilityQ:GetSpecialValueInt( "bounce_aoe" )
	local nEnemyUnitList = Fu.GetAroundBotUnitList( bot, nCastRange + 100, true )
	local nTrackEnemyList = {}

	
	--击杀和打断
	for _, npcEnemy in pairs( hEnemyList )
	do
		--计算出视野内被标记的
		if npcEnemy:HasModifier( "modifier_bounty_hunter_track" )
		then
			nTrackEnemyList[#nTrackEnemyList + 1] = npcEnemy
		end

		--打断施法
		if npcEnemy:IsChanneling()
			and not npcEnemy:IsMagicImmune()
		then
			if npcEnemy:HasModifier( "modifier_bounty_hunter_track" )
			then
				for _, nUnit in pairs( nEnemyUnitList )
				do
					if Fu.IsValid( nUnit )
						and Fu.CanCastOnTargetAdvanced( nUnit )
						and not nUnit:IsMagicImmune()
					then
						nCastTarget = nUnit
						return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-通过弹射打断施法:"..Fu.Chat.GetNormName( npcEnemy )
					end
				end
			end

			if Fu.IsInRange( bot, npcEnemy, nCastRange + 200 )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				nCastTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-直接打断施法:"..Fu.Chat.GetNormName( nCastTarget )
			end
		end

		--击杀
		if Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint + GetUnitToUnitDistance( bot, npcEnemy )/1000 )
		then
			if npcEnemy:HasModifier( "modifier_bounty_hunter_track" )
			then
				for _, nUnit in pairs( nEnemyUnitList )
				do
					if Fu.IsValid( nUnit )
						and Fu.CanCastOnTargetAdvanced( nUnit )
						and not nUnit:IsMagicImmune()
					then
						nCastTarget = nUnit
						return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-通过弹射击杀:"..Fu.Chat.GetNormName( npcEnemy )
					end
				end
			end

			if Fu.IsInRange( bot, npcEnemy, nCastRange + 200 )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				nCastTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-直接击杀:"..Fu.Chat.GetNormName( nCastTarget )
			end
		end
	end


	--可弹射两人以上时
	if #nTrackEnemyList >= 2
	then
		local nBestUnit = nil
		local nMaxBounceCount = 1.2
		for _, nUnit in pairs( nEnemyUnitList )
		do
			if Fu.IsValid( nUnit )
				and not nUnit:IsMagicImmune()
				and Fu.CanCastOnTargetAdvanced( nUnit )
			then
				local nBounceCount = 0

				if not nUnit:HasModifier( "modifier_bounty_hunter_track" )
				then
					if nUnit:IsHero()
					then
						nBounceCount = nBounceCount + 1
					else
						nBounceCount = nBounceCount + 0.1
					end
				end

				for _, npcEnemy in pairs( nTrackEnemyList )
				do 
					if Fu.IsInRange( nUnit, npcEnemy, nRadius - 80 )
					then
						nBounceCount = nBounceCount + 1
					end
				end

				if nBounceCount > nMaxBounceCount
				then
					nBestUnit = nUnit
					nMaxBounceCount = nBounceCount
				end
			end
		end

		if nBestUnit ~= nil
		then
			nCastTarget = nBestUnit
			return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-弹射多个:"..nMaxBounceCount
		end
	end


	--进攻时尽量弹小兵
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + nRadius + 100 )
			and Fu.CanCastOnNonMagicImmune( botTarget )
		then
			if botTarget:HasModifier( "modifier_bounty_hunter_track" )
			then
				for _, nUnit in pairs( nEnemyUnitList )
				do
					if Fu.IsInRange( nUnit, botTarget, nRadius - 100 )
						and not nUnit:IsMagicImmune()
						and Fu.CanCastOnTargetAdvanced( nUnit )
						and not nUnit:HasModifier( "modifier_bounty_hunter_track" )
					then
						nCastTarget = nUnit
						return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-弹射进攻:"..Fu.Chat.GetNormName( botTarget )
					end
				end
			end

			if Fu.IsInRange( bot, botTarget, nCastRange )
				and Fu.CanCastOnTargetAdvanced( botTarget )
			then
				nCastTarget = botTarget
				return BOT_ACTION_DESIRE_HIGH, nCastTarget, "Q-直接进攻:"..Fu.Chat.GetNormName( botTarget )
			end
		end
	end


	--对线期间补刀远程兵
	if ( bot:GetActiveMode() == BOT_MODE_LANING or ( nLV <= 7 and #hAllyList <= 2 ) )
		and bot:GetMana() >= 150
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 300, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint + GetUnitToUnitDistance( bot, creep )/1100 )
				and GetUnitToUnitDistance( creep, bot ) > 300
			then
				nCastTarget = creep
				return BOT_ACTION_DESIRE_HIGH, nCastTarget, 'Q-补远程兵'
			end
		end
	end


	--带线期间补刀远程兵
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.52 )
		and ( bot:GetAttackDamage() < 300 or nMP > 0.7 )
		and nSkillLV >= 2 and DotaTime() > 7 * 60
		and #hAllyList <= 2 and #hEnemyList == 0
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 350, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint + GetUnitToUnitDistance( bot, creep )/1100 )
				and not Fu.CanKillTarget( creep, bot:GetAttackDamage() * 1.2, DAMAGE_TYPE_PHYSICAL )
			then
				nCastTarget = creep
				return BOT_ACTION_DESIRE_HIGH, nCastTarget, 'Q-推线补远程'
			end
		end
	end


	--打钱时增加输出
	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 200 )

		local targetCreep = Fu.GetMostHpUnit( nCreeps )

		if Fu.IsValid( targetCreep )
			and not Fu.IsRoshan( targetCreep )
			and ( #nCreeps >= 2 or GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
			and bot:IsFacingLocation( targetCreep:GetLocation(), 40 )
			and ( targetCreep:GetMagicResist() < 0.3 or nMP > 0.9 )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 1.68, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( targetCreep, nDamage - 50, nDamageType )
		then
			nCastTarget = targetCreep
			return BOT_ACTION_DESIRE_HIGH, nCastTarget, 'Q-打钱'
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan( botTarget )
        and Fu.GetHP( botTarget ) > 0.2
        and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor( botTarget )
        and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end


	local nSkillLV = abilityE:GetLevel()


	--进攻
	if Fu.IsGoingOnSomeone( bot )
		and ( nLV >= 7 or DotaTime() > 6 * 60 or nSkillLV >= 2 )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnMagicImmune( botTarget )
			and Fu.IsInRange( bot, botTarget, 2500 )
			and ( not Fu.IsInRange( bot, botTarget, 1000 )
					or Fu.IsChasingTarget( bot, botTarget ) )
		then
			return BOT_ACTION_DESIRE_HIGH, "E-隐身进攻:"..Fu.Chat.GetNormName( botTarget )
		end
	end


	--撤退
	if Fu.IsRetreating( bot )
		and bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and ( #hEnemyList >= 1 or nHP < 0.2 )
		and bot:DistanceFromFountain() > 800
	then
		return BOT_ACTION_DESIRE_HIGH, "E-隐身逃跑"
	end


	--潜行
	if Fu.IsInEnemyArea( bot ) and nLV >= 7 and nMP >= 280
	then
		local nEnemies = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
		local nEnemyTowers = bot:GetNearbyTowers( 1600, true )
		if #nEnemies == 0 and nEnemyTowers == 0
		then
			return BOT_ACTION_DESIRE_HIGH, "E-潜行"
		end
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderR()
	if not abilityR:IsFullyCastable() then return 0 end

	-- local nSkillLV = abilityR:GetLevel()
	-- local nCastPoint = abilityR:GetCastPoint()
	-- local nManaCost = abilityR:GetManaCost()
	-- local nDamage = abilityR:GetAbilityDamage()
	-- local nDamageType = DAMAGE_TYPE_MAGICAL
	local nCastRange = abilityR:GetCastRange()
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nCastTarget = nil

	--见人就标血最少那个
	local nMinHealth = 999999
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and not npcEnemy:HasModifier( "modifier_bounty_hunter_track" )
			and not npcEnemy:HasModifier( "modifier_arc_warden_tempest_double" )
			and Fu.CanCastAbilityOnTarget( npcEnemy, false )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and npcEnemy:GetHealth() < nMinHealth
		then
			nCastTarget = npcEnemy
			nMinHealth = npcEnemy:GetHealth()
		elseif npcEnemy:HasModifier( "modifier_bounty_hunter_track" ) then
			nMinHealth = 999999
		end
	end
	if nCastTarget ~= nil
	then
		return BOT_ACTION_DESIRE_HIGH, nCastTarget, "R-标记:"..Fu.Chat.GetNormName( nCastTarget )
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderFriendlyShadow()
	if not FriendlyShadow:IsTrained()
	or not FriendlyShadow:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = FriendlyShadow:GetCastRange()
	local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)

	for _, ally in pairs(nAllyHeroes) do
		if Fu.IsGoingOnSomeone(ally)
		and Fu.IsInRange(bot, ally, nCastRange)
		and Fu.IsNotSelf(bot, ally)
		and not Fu.IsRealInvisible(ally)
		then
			return BOT_ACTION_DESIRE_HIGH, ally
		end

		if Fu.IsRetreating(ally)
		and ally:WasRecentlyDamagedByAnyHero(3.0)
		and ally:DistanceFromFountain() > 800
		and Fu.IsInRange(bot, ally, nCastRange)
		and Fu.IsNotSelf(bot, ally)
		and not Fu.IsRealInvisible(ally)
		and #hEnemyList >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, ally
		end

		if Fu.IsInEnemyArea(bot)
		then
			local nEnemies = Fu.GetNearbyHeroes(bot,1600, true, BOT_MODE_NONE)
			local nEnemyTowers = bot:GetNearbyTowers(1600, true)

			if nEnemies ~= nil and nEnemyTowers ~= nil
			and #nEnemies == 0 and #nEnemyTowers == 0
			and Fu.IsInRange(bot, ally, nCastRange)
			and Fu.IsNotSelf(bot, ally)
			and not Fu.IsRealInvisible(ally)
			then
				return BOT_ACTION_DESIRE_HIGH, ally
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

return X