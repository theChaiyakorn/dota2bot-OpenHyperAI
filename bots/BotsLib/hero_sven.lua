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
						['t20'] = {10, 0},
						['t15'] = {0, 10},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,2,2,2,6,2,3,3,3,6,1,1,1,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_quelling_blade",

	"item_magic_wand",
	"item_power_treads",
	"item_mask_of_madness",
	"item_echo_sabre",
	"item_blink",
	"item_black_king_bar",--
	"item_greater_crit",--
	"item_harpoon",--
	"item_satanic",--
	"item_moon_shard",
	"item_swift_blink",--
	"item_orchid",
	"item_bloodthorn",--
	"item_ultimate_scepter_2",
	"item_aghanims_shard",

}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_echo_sabre",
	"item_quelling_blade",

	"item_travel_boots",
	"item_magic_wand",

	"item_greater_crit",
	"item_hand_of_midas",

	"item_overwhelming_blink",
	"item_echo_sabre",
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_str_carry' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_sven

"Ability1"		"sven_storm_bolt"
"Ability2"		"sven_great_cleave"
"Ability3"		"sven_warcry"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"sven_gods_strength"
"Ability10"		"special_bonus_strength_8"
"Ability11"		"special_bonus_mp_regen_3"
"Ability12"		"special_bonus_movement_speed_30"
"Ability13"		"special_bonus_unique_sven_3"
"Ability14"		"special_bonus_lifesteal_25"
"Ability15"		"special_bonus_unique_sven"
"Ability16"		"special_bonus_unique_sven_2"
"Ability17"		"special_bonus_unique_sven_4"

modifier_sven_great_cleave
modifier_sven_warcry
modifier_sven_gods_strength
modifier_sven_gods_strength_child

--]]


local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'sven')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'sven')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'sven')


local castQDesire, castQTarget
local castEDesire
local castRDesire

local nKeepMana, nMP, nHP, nLV, hEnemyHeroList
local botTarget

local hAllyList

function X.SkillsComplement()


	Fu.ConsiderForMkbDisassembleMask( bot )
	X.SvenConsiderTarget()


	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyHeroList = ctx.enemies
	hAllyList = ctx.allies


	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end

	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return

	end

	castEDesire = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityE )
		return

	end

end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable() then return 0 end

	local nCastRange = abilityQ:GetCastRange()
	
	if nCastRange > 1000 then nCastRange = 1000 end
	
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nSkillLV = abilityQ:GetLevel()
	local nDamage = 80 * nSkillLV
	local nRadius = 255
	local nDamageType = DAMAGE_TYPE_MAGICAL

	local nAllies =  Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE )

	if #hEnemyHeroList == 1
		and Fu.IsValidHero( hEnemyHeroList[1] )
		and Fu.IsInRange( hEnemyHeroList[1], bot, nCastRange + 350 )
		and hEnemyHeroList[1]:IsFacingLocation( bot:GetLocation(), 30 )
		and hEnemyHeroList[1]:GetAttackRange() > nCastRange
		and hEnemyHeroList[1]:GetAttackRange() < 1250
	then
		nCastRange = nCastRange + 260
	end

	local nEnemysHerosInRange = Fu.GetNearbyHeroes(bot, nCastRange + 43, true, BOT_MODE_NONE )
	local nEnemysHerosInBonus = Fu.GetNearbyHeroes(bot, nCastRange + 350, true, BOT_MODE_NONE )

	local nEmemysCreepsInRange = bot:GetNearbyCreeps( nCastRange + 43, true )

	--打断和击杀
	for _, npcEnemy in pairs( nEnemysHerosInBonus )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and not Fu.IsDisabled( npcEnemy )
		then
			if npcEnemy:IsChanneling()
				or Fu.CanKillTarget( npcEnemy, nDamage, nDamageType )
			then

				--隔空打断击杀目标
				local nBetterTarget = nil
				local nAllEnemyUnits = Fu.CombineTwoTable( nEnemysHerosInRange, nEmemysCreepsInRange )
				for _, enemy in pairs( nAllEnemyUnits )
				do
					if Fu.IsValid( enemy )
						and Fu.IsInRange( npcEnemy, enemy, nRadius )
						and Fu.CanCastOnNonMagicImmune( enemy )
						and Fu.CanCastOnTargetAdvanced( enemy )
					then
						nBetterTarget = enemy
						break
					end
				end

				if nBetterTarget ~= nil
					and not Fu.IsInRange( npcEnemy, bot, nCastRange )
				then
					--打断或击杀更优目标
					return BOT_ACTION_DESIRE_HIGH, nBetterTarget
				else
					--打断或击杀目标
					return BOT_ACTION_DESIRE_HIGH, npcEnemy
				end
			end
		end
	end

	--团战中对作用数量最多或物理输出最强的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcMostAoeEnemy = nil
		local nMostAoeECount = 1
		local nAllEnemyUnits = Fu.CombineTwoTable( nEnemysHerosInRange, nEmemysCreepsInRange )

		local npcMostDangerousEnemy = nil
		local nMostDangerousDamage = 0

		for _, npcEnemy in pairs( nAllEnemyUnits )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then

				local nEnemyHeroCount = Fu.GetAroundTargetEnemyHeroCount( npcEnemy, nRadius )
				if ( nEnemyHeroCount > nMostAoeECount )
				then
					nMostAoeECount = nEnemyHeroCount
					npcMostAoeEnemy = npcEnemy
				end

				if npcEnemy:IsHero()
				then
					local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_PHYSICAL )
					if ( npcEnemyDamage > nMostDangerousDamage )
					then
						nMostDangerousDamage = npcEnemyDamage
						npcMostDangerousEnemy = npcEnemy
					end
				end
			end
		end

		if ( npcMostAoeEnemy ~= nil )
		then
			--团战控制数量多
			return BOT_ACTION_DESIRE_HIGH, npcMostAoeEnemy
		end

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy
		end
	end

	--对线期间对敌方英雄使用
	if bot:GetActiveMode() == BOT_MODE_LANING or nLV <= 5
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and Fu.GetAttackEnemysAllyCreepCount( npcEnemy, 1400 ) >= 5
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 60 )
			and not Fu.IsDisabled( botTarget )
			and not botTarget:IsDisarmed()
		then
			if nSkillLV >= 3 or nMP > 0.88 or Fu.GetHP( botTarget ) < 0.38 or nHP < 0.25
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget
			end
		end
	end

	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
						or nMP > 0.8
						or GetUnitToUnitDistance( bot, npcEnemy ) <= 400 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	--发育时对野怪输出
	if Fu.IsFarming( bot ) and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( 700 )
		if #nNeutralCreeps >= 3
		then
			for _, creep in pairs( nNeutralCreeps )
			do
				if Fu.IsValid( creep )
					and Fu.IsInRange( creep, bot, nCastRange )
					and Fu.GetAroundTargetEnemyUnitCount( creep, nRadius ) >= 3
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange, true )
		if #nLaneCreeps >= 3
		then
			for _, creep in pairs( nLaneCreeps )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and Fu.IsInRange( creep, bot, nCastRange )
					and Fu.GetAroundTargetEnemyUnitCount( creep, nRadius ) >= 3
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end


	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and ( bot:GetAttackDamage() < 200 or nMP > 0.9 )
		and nSkillLV >= 4 and #hEnemyHeroList == 0 and nMP > 0.68
		and not Fu.IsInEnemyArea( bot )
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( 1000, true )
		if #nLaneCreeps >= 5
		then
			for _, creep in pairs( nLaneCreeps )
			do
				if Fu.IsValid( creep )
					and creep:GetHealth() >= 500
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and Fu.IsInRange( creep, bot, nCastRange + 100 )
					and Fu.GetAroundTargetEnemyUnitCount( creep, nRadius ) >= 5
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end

	--打肉的时候输出
	if Fu.IsDoingRoshan( bot )
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and Fu.GetManaAfter( nManaCost ) > 0.3
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget, ''
		end
	end

	--通用受到伤害时保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nEnemysHerosInRange >= 1
		and nLV >= 7
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 45 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	--通用消耗敌人或保护自己
	if ( #hEnemyHeroList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #nAllies >= 2 )
		and #nEnemysHerosInRange >= 1
		and nLV >= 7
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	--farming: use on neutral creep camps with 3+ creeps
	if Fu.IsFarming( bot )
		and #hEnemyHeroList == 0
		and Fu.GetManaAfter( nManaCost ) > 0.3
	then
		local nNeutralCreeps = bot:GetNearbyNeutralCreeps( nCastRange )
		if #nNeutralCreeps >= 3
		then
			local nTargetCreep = Fu.GetMostHpUnit( nNeutralCreeps )
			if Fu.IsValid( nTargetCreep )
				and not Fu.IsRoshan( nTargetCreep )
				and Fu.CanCastOnNonMagicImmune( nTargetCreep )
				and Fu.CanCastOnTargetAdvanced( nTargetCreep )
			then
				return BOT_ACTION_DESIRE_HIGH, nTargetCreep
			end
		end
	end

	return 0, nil
end

function X.ConsiderE()

	if not abilityE:IsFullyCastable()
		or ( #hEnemyHeroList == 0 and nHP > 0.2 )
	then
		return 0
	end

	local nSkillRange = 700

	local nAllies = Fu.GetAllyList( bot, nSkillRange )
	local nAlliesCount = #nAllies
	local nWeakestAlly = Fu.GetLeastHpUnit( nAllies )
	if nWeakestAlly == nil then nWeakestAlly = bot end
	local nWeakestAllyHP = Fu.GetHP( nWeakestAlly )

	local nEnemysHerosNearby = nWeakestAlly:GetNearbyHeroes( 800, true, BOT_MODE_NONE )

	local nBonusPer = ( #nEnemysHerosNearby )/20

	local nShouldBonusCount = 1
	if nWeakestAllyHP > 0.35 + nBonusPer then nShouldBonusCount = nShouldBonusCount + 1 end
	if nWeakestAllyHP > 0.50 + nBonusPer then nShouldBonusCount = nShouldBonusCount + 1 end
	if nWeakestAllyHP > 0.65 + nBonusPer then nShouldBonusCount = nShouldBonusCount + 1 end
	if nWeakestAllyHP > 0.9 + nBonusPer then nShouldBonusCount = nShouldBonusCount + 1 end

	--根据血量决定作用人数
	if nAlliesCount >= nShouldBonusCount
		and #nEnemysHerosNearby >= 1
		and nWeakestAlly:WasRecentlyDamagedByAnyHero( 4.0 )
	then
		return BOT_ACTION_DESIRE_HIGH
	end


	if Fu.IsRetreating( nWeakestAlly )
		and nWeakestAlly:GetHealth() < 800
		and Fu.IsRunning( nWeakestAlly )
		and nWeakestAlly:WasRecentlyDamagedByAnyHero( 3.0 )
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, 600 )
			and bot:IsFacingLocation( botTarget:GetLocation(), 15 )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end
	
	
	if Fu.IsRetreating( bot )
		and bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and #nEnemysHerosNearby >= 1
		and bot:GetHealth() / bot:GetMaxHealth() < 0.85
	then
		return BOT_ACTION_DESIRE_HIGH	
	end
	

	return 0
end


function X.ConsiderR()

	if not abilityR:IsFullyCastable()
	then
		return 0
	end

	local nEnemysHerosInBonus = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE )

	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and ( Fu.GetHP( botTarget ) > 0.25 or #nEnemysHerosInBonus >= 2 )
			and ( Fu.IsInRange( botTarget, bot, 700 )
				or Fu.IsInRange( botTarget, bot, botTarget:GetAttackRange() + 80 ) )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	--撤退时保护自己
	if bot:GetActiveMode() == BOT_MODE_RETREAT
		and bot:DistanceFromFountain() > 800
		and nHP > 0.5
		and bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and #nEnemysHerosInBonus >= 1
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	if bot:GetActiveMode() == BOT_MODE_ROSHAN
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, 400 )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 400)
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end
	

	return 0
end

function X.SvenConsiderTarget()

	local bot = GetBot()

	if not Fu.IsRunning( bot )
	then return end

	if not Fu.IsValidHero( botTarget ) then return end

	local nAttackRange = bot:GetAttackRange() + 50
	local nEnemyHeroInRange = Fu.GetNearbyHeroes(bot, nAttackRange, true, BOT_MODE_NONE )

	local nInAttackRangeNearestEnemyHero = nEnemyHeroInRange[1]

	if Fu.IsValidHero( nInAttackRangeWeakestEnemyHero )
		and Fu.CanBeAttacked( nInAttackRangeWeakestEnemyHero )
		and ( GetUnitToUnitDistance( botTarget, bot ) >  350 or Fu.HasForbiddenModifier( botTarget ) )
	then
		--更改目标为
		bot:SetTarget( nInAttackRangeWeakestEnemyHero )
		return
	end

end

return X
