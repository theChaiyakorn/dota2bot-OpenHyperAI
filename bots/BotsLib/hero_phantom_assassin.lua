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
						['t20'] = {10, 0},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
	{1,2,1,5,1,6,2,2,2,1,6,5,5,5,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_blight_stone",

	"item_orb_of_corrosion",
	"item_magic_wand",
	"item_power_treads",
	"item_bfury",--
	"item_black_king_bar",--
	"item_desolator",--
	"item_aghanims_shard",
	"item_basher",
	"item_satanic",--
	"item_monkey_king_bar",--
	"item_abyssal_blade",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_PA' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_phantom_assassin

"Ability1"		"phantom_assassin_stifling_dagger"
"Ability2"		"phantom_assassin_phantom_strike"
"Ability3"		"phantom_assassin_blur"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"phantom_assassin_coup_de_grace"
"Ability10"		"special_bonus_hp_150"
"Ability11"		"special_bonus_attack_damage_15"
"Ability12"		"special_bonus_lifesteal_15"
"Ability13"		"special_bonus_cleave_25"
"Ability14"		"special_bonus_corruption_4"
"Ability15"		"special_bonus_unique_phantom_assassin_3"
"Ability16"		"special_bonus_unique_phantom_assassin_2"
"Ability17"		"special_bonus_unique_phantom_assassin"

modifier_phantom_assassin_stiflingdagger_caster
modifier_phantom_assassin_stiflingdagger
modifier_phantom_assassin_phantom_strike
modifier_phantom_assassin_blur
modifier_phantom_assassin_blur_active
modifier_phantom_assassin_coupdegrace

--]]


local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'phantom_assassin')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'phantom_assassin')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'phantom_assassin')
local abilityAS = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'phantom_assassin')
local Immaterial = SafeAbility(bot:GetAbilityByName('phantom_assassin_immaterial'), 'phantom_assassin_immaterial', 'phantom_assassin')


local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire
local castASDesire, castASTarget




local lastSkillCreep

function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) then return end

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 300
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies


	castEDesire = X.ConsiderE()
	if castEDesire > 0
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityE )
		return

	end
	
	castASDesire = X.ConsiderAS()
	if castASDesire > 0
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility( abilityAS )
		return

	end

	castQDesire, castQTarget = X.ConsiderQ()
	if castQDesire > 0
	then
		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityQ , castQTarget )
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityW , castWTarget )
		return
	end


end


function X.ConsiderQ()

	if not abilityQ:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE
	end

	local nAttackDamage = bot:GetAttackDamage()
	local nCastRange = abilityQ:GetCastRange()
	if nCastRange < 700 then nCastRange = 700 end
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nSkillLV = abilityQ:GetLevel()
	local nBonusPer = 0.1 + 0.15 * nSkillLV
	local nDamage = 65 + nAttackDamage * nBonusPer
	local nBonusDamage= 8 * nBonusPer

	local nDamageType = DAMAGE_TYPE_PHYSICAL

	local nAllies = Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE )

	local nEnemysHerosInView = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
	local nEnemysHerosInRange = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )
	local nEnemysHerosInBonus = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )


	--击杀敌人
	for _, npcEnemy in pairs( nEnemysHerosInBonus )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and GetUnitToUnitDistance( bot, npcEnemy ) <= nCastRange + 80
			and ( Fu.CanKillTarget( npcEnemy, nDamage * 1.6, nDamageType )
				or ( npcEnemy:IsChanneling() and Fu.CanKillTarget( npcEnemy, nDamage * 4.5, nDamageType ) ) )
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy
		end
	end


	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.CanCastOnTargetAdvanced( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange + 50 )
		then
			if nSkillLV >= 3
				or nMP > 0.6 or nHP < 0.4
				or Fu.GetHP( npcTarget ) < 0.38
				or DotaTime() > 6 * 60
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget
			end
		end
	end


	--团战中对血量最低的敌人使用
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local npcWeakestEnemy = nil
		local npcWeakestEnemyHealth = 10000

		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				local npcEnemyHealth = npcEnemy:GetHealth()
				if ( npcEnemyHealth < npcWeakestEnemyHealth )
				then
					npcWeakestEnemyHealth = npcEnemyHealth
					npcWeakestEnemy = npcEnemy
				end
			end
		end

		if ( npcWeakestEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcWeakestEnemy
		end
	end



	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and ( bot:IsFacingLocation( npcEnemy:GetLocation(), 60 )
						or not Fu.IsInRange( npcEnemy, bot, nCastRange - 300 ) )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end


	--对线期间对线上小兵和敌人使用
	if ( bot:GetActiveMode() == BOT_MODE_LANING or ( nLV <= 14 and not Fu.IsGoingOnSomeone( bot ) ) )
		and not Fu.IsValid( botTarget )
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 168, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and ( GetUnitToUnitDistance( creep, bot ) > 300 or nDamage + nBonusDamage - 10 > nAttackDamage + 24 )
			then
				local nTime = nCastPoint + GetUnitToUnitDistance( bot, creep )/1250
				if Fu.WillKillTarget( creep, nDamage + nBonusDamage, nDamageType, nTime * 0.94 )
				then
					lastSkillCreep = creep
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end

		if bot:GetMana() > 80 + nLV * 10
			and ( nLV <= 9 or #nEnemysHerosInBonus == 0 )
		then
			local keyWord = "melee"
			for _, creep in pairs( nLaneCreeps )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and Fu.IsKeyWordUnit( keyWord, creep )
					and GetUnitToUnitDistance( creep, bot ) > 240 + nLV * 20
				then
					local nTime = nCastPoint + GetUnitToUnitDistance( bot, creep )/1250
					if Fu.WillKillTarget( creep, nDamage + nBonusDamage, nDamageType, nTime * 0.9 )
					then
						lastSkillCreep = creep
						return BOT_ACTION_DESIRE_HIGH, creep
					end
				end
			end
		end

		--对线期间对敌人使用
		local nWeakestEnemyLaneCreep = Fu.GetVulnerableWeakestUnit( bot, false, true, nCastRange + 100 )
		local nWeakestEnemyLaneHero = Fu.GetVulnerableWeakestUnit( bot, true , true, nCastRange + 40 )
		if nWeakestEnemyLaneCreep == nil
			or not Fu.CanKillTarget( nWeakestEnemyLaneCreep, ( nDamage + nBonusDamage ) * 2, nDamageType )
		then
			if nWeakestEnemyLaneHero ~= nil
				and ( Fu.GetHP( nWeakestEnemyLaneHero ) <= 0.48
					  or Fu.IsInRange( bot, nWeakestEnemyLaneHero, 400 ) )
			then
				return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyLaneHero
			end
		end

		--打断回复
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and GetUnitToUnitDistance( bot, npcEnemy ) <= nCastRange + 80
				and ( npcEnemy:HasModifier( "modifier_flask_healing" )
					or npcEnemy:HasModifier( "modifier_clarity_potion" )
					or npcEnemy:HasModifier( "modifier_bottle_regeneration" )
					or npcEnemy:HasModifier( "modifier_rune_regen" ) )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end


	--发育时对野怪输出
	if Fu.IsFarming( bot )
		and ( nSkillLV >= 2 or nMP > 0.5 )
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange )

		local targetCreep = Fu.GetMostHpUnit( nCreeps )

		if Fu.IsValid( targetCreep )
			and GetUnitToUnitDistance( targetCreep, bot ) >= 300
			and not Fu.IsRoshan( targetCreep )
			and not Fu.IsTormentor( targetCreep )
			and ( not Fu.CanKillTarget( targetCreep, nDamage + nBonusDamage, nDamageType ) or #nCreeps == 1 )
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep
		end
	end


	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and ( bot:GetAttackDamage() >= 90 or nLV >= 15 )
		and #nEnemysHerosInView == 0
		and #nAllies <= 2
	then

		--补刀远程程兵
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 188, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
			then
				if Fu.IsKeyWordUnit( keyWord, creep )
				then
					local nTime = nCastPoint + GetUnitToUnitDistance( bot, creep )/1250
					if Fu.WillKillTarget( creep, nDamage + nBonusDamage, nDamageType, nTime * 0.9 )
					then
						return BOT_ACTION_DESIRE_HIGH, creep
					end
				end

				if not Fu.CanKillTarget( creep, bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL )
					and not Fu.IsInRange( creep, bot, nCastRange - 300 )
					and ( Fu.CanKillTarget( creep, nDamage-2, nDamageType )
						or Fu.GetUnitAllyCountAroundEnemyTarget( creep, 450 ) <= 1 )
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end

			end
		end

		--补刀非狂战范围内的兵
		local keyWord = "melee"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and GetUnitToUnitDistance( creep, bot ) > 350
				and not bot:IsFacingLocation( creep:GetLocation(), 50 )
			then
				local nTime = nCastPoint + GetUnitToUnitDistance( bot, creep )/1250
				if Fu.WillKillTarget( creep, nDamage + nBonusDamage, nDamageType, nTime * 0.9 )
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end


	--打肉的时候输出
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= nManaCost + 50
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	if Fu.IsDoingTormentor(bot)
		and bot:GetMana() >= nManaCost + 50
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsValid( npcTarget )
			and Fu.IsTormentor( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	--通用消耗敌人或受到伤害时保护自己
	if ( #nEnemysHerosInView > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #nAllies >= 2 )
		and #nEnemysHerosInRange >= 1
		and nLV >= 7
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and bot:IsFacingLocation( npcEnemy:GetLocation(), 80 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end


	return 0

end


function X.ConsiderW()

	if not abilityW:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nAttackDamage = bot:GetAttackDamage()
	local nCastRange = abilityW:GetCastRange()
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nSkillLV = abilityW:GetLevel()
	local nBonus	 = 18
	local nDamage = nAttackDamage
	local nDamageType = DAMAGE_TYPE_PHYSICAL

	local nAllies =  Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE )

	local nEnemysHerosInView = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
	local nEnemysHerosInRange = Fu.GetNearbyHeroes(bot, nCastRange + 50, true, BOT_MODE_NONE )
	local nEnemysHerosInBonus = Fu.GetNearbyHeroes(bot, nCastRange + 300, true, BOT_MODE_NONE )

	local nEnemysTowers = bot:GetNearbyTowers( 1400, true )
	local aliveEnemyCount = Fu.GetNumOfAliveHeroes( true )

	local npcTarget = Fu.GetProperTarget( bot )

	--击杀敌人
	if Fu.IsValid( npcTarget )
		and not npcTarget:IsAttackImmune()
		and Fu.CanCastOnNonMagicImmune( npcTarget )
		and GetUnitToUnitDistance( bot, npcTarget ) <= nCastRange + 80
		and ( Fu.CanKillTarget( npcTarget, nDamage * 1.28, nDamageType )
			or ( npcTarget:IsChanneling() and Fu.CanKillTarget( npcTarget, nDamage * 2.28, nDamageType ) ) )
	then
		return BOT_ACTION_DESIRE_HIGH, npcTarget
	end
	



	--打架时先手
	if Fu.IsGoingOnSomeone( bot ) 
		and ( nLV >= 2 or #nEnemysHerosInView <= 1 )
		and ( #nAllies >= 2 or #nEnemysHerosInView <= 1 or nLV >= 6 )
	then

		if Fu.IsValidHero( npcTarget )
			and not npcTarget:IsAttackImmune()
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange + 50 )
		then
			local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(npcTarget, 800, false, BOT_MODE_NONE )
			local tableNearbyAllyHeroes = Fu.GetNearbyHeroes(npcTarget, 800, true, BOT_MODE_NONE )
			local tableAllEnemyHeroes = Fu.GetNearbyHeroes(npcTarget, 1600, false, BOT_MODE_NONE )
			if ( Fu.WillKillTarget( npcTarget, nAttackDamage * 3, DAMAGE_TYPE_PHYSICAL, 1.0 ) )
				or ( #tableNearbyEnemyHeroes <= #tableNearbyAllyHeroes )
				or ( #tableAllEnemyHeroes <= 1 )
				or GetUnitToUnitDistance( bot, npcTarget ) <= 400
				or aliveEnemyCount <= 2
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget
			end
		end
	end


	--撤退时逃跑
	if Fu.IsRetreating( bot )
		and bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		local nAttackAllys = Fu.GetNearbyHeroes(bot, 600, false, BOT_MODE_ATTACK )
		if #nAttackAllys == 0 or nHP < 0.16
		then
			local nAllyInCastRange = Fu.GetNearbyHeroes(bot, nCastRange + 80, false, BOT_MODE_NONE )
			local nAllyCreeps	 = bot:GetNearbyCreeps( nCastRange + 80, false )
			local nEnemyCreeps = bot:GetNearbyCreeps( nCastRange + 80, true )
			local nAllyUnits = Fu.CombineTwoTable( nAllyInCastRange, nAllyCreeps )
			local nAllUnits = Fu.CombineTwoTable( nAllyUnits, nEnemyCreeps )

			local targetUnit = nil
			local targetUnitDistance = Fu.GetDistanceFromAllyFountain( bot )
			for _, unit in pairs( nAllUnits )
			do
				if Fu.IsValid( unit )
					and GetUnitToUnitDistance( unit, bot ) > 260
					and Fu.GetDistanceFromAllyFountain( unit ) < targetUnitDistance
				then
					targetUnit = unit
					targetUnitDistance = Fu.GetDistanceFromAllyFountain( unit )
				end
			end

			if targetUnit ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, targetUnit
			end
		end
	end


	--对线期间对线上小兵使用
	if bot:GetActiveMode() == BOT_MODE_LANING and #nEnemysHerosInView == 0 and #nEnemysTowers == 0
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 80, true )
		local keyWord = "ranged"
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and creep ~= lastSkillCreep
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and GetUnitToUnitDistance( creep, bot ) > 400
			then
				local nTime = nCastPoint * 3
				if Fu.WillKillTarget( creep, nDamage + nBonus, nDamageType, nTime )
				then
					return BOT_ACTION_DESIRE_HIGH, creep
				end
			end
		end
	end


	--发育时对野怪输出
	if Fu.IsFarming( bot )
		and ( bot:GetAttackTarget() == nil or not bot:GetAttackTarget():IsBuilding() )
		and nLV >= 4
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange )

		local targetCreep = Fu.GetProperTarget( bot )

		if Fu.IsValid( targetCreep )
			and not Fu.IsRoshan( targetCreep )
			and ( not Fu.CanKillTarget( targetCreep, nDamage * 2, nDamageType )
				  or GetUnitToUnitDistance( targetCreep, bot ) >= 650 )
		then

			if Fu.IsAllowedToSpam( bot, nManaCost )
			then
				if ( #nCreeps >= 3 and GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
					or ( #nCreeps >= 2 and not Fu.CanKillTarget( targetCreep, nDamage * 3, nDamageType ) )
					or ( #nCreeps >= 1 and not Fu.CanKillTarget( targetCreep, nDamage * 6, nDamageType ) )
				then
					return BOT_ACTION_DESIRE_HIGH, targetCreep
				end
			end

			if bot:GetMana() >= 100
				and GetUnitToUnitDistance( targetCreep, bot ) >= 550
			then
				return BOT_ACTION_DESIRE_HIGH, targetCreep
			end

		end

	end

	--推进时对小兵用
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and nLV >= 8
		and #nEnemysHerosInView == 0
		and #nAllies <= 2
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( nCastRange + 300, true )
		--local targetCreep = nLaneCreeps[1]
		if Fu.IsValid( npcTarget )
			and not npcTarget:IsHero()
			and not npcTarget :HasModifier( "modifier_fountain_glyph" )
			and ( ( not Fu.IsInRange( bot, npcTarget, 630 ) and bot:GetMana() >= 100 )
				or ( #nLaneCreeps >= 3 and Fu.IsAllowedToSpam( bot, nManaCost ) ) )
		then
			if not Fu.IsEnemyHeroAroundLocation( npcTarget:GetLocation(), 660 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget
			end
		end
	end

	--打肉的时候输出
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
			and Fu.GetHP( npcTarget ) > 0.15
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	if Fu.IsDoingTormentor(bot)
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsValid( npcTarget )
			and Fu.IsTormentor( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	return 0

end


function X.ConsiderE()

	local nEnemyTowers = bot:GetNearbyTowers( 878, true )

	if not abilityE:IsFullyCastable()
		or bot:IsInvisible()
		or #nEnemyTowers >= 1
		or bot:DistanceFromFountain() < 600
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	--撤退逃跑
	if Fu.IsRetreating( bot )
		and bot:WasRecentlyDamagedByAnyHero( 3.1 )
		and ( nLV >= 6 or nHP <= 0.3 )
	then
		local nEnemysHerosInRange = Fu.GetNearbyHeroes(bot, 740, true, BOT_MODE_NONE )
		if #nEnemysHerosInRange == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	--过河道接近敌方基地
	if Fu.IsInEnemyArea( bot ) and nLV >= 7
	then
		local nEnemies = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
		local nAllies = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )
		local nEnemyTowers = bot:GetNearbyTowers( 1600, true )
		if #nEnemies == 0 and #nAllies <= 2 and nEnemyTowers == 0
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	--低血量打远古
	if Fu.IsFarming( bot )
	then
		local nTarget = Fu.GetProperTarget( bot )
		if Fu.IsValid( nTarget )
			and ( nTarget:IsAncientCreep() or nHP < 0.28 )
			and nHP <= 0.58
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
		return BOT_ACTION_DESIRE_NONE
	end
	
	local nRadius = 550 - 30

	local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, nRadius, true, BOT_MODE_NONE )

	if #tableNearbyEnemyHeroes <= 0 then return BOT_ACTION_DESIRE_NONE end
	
	if Fu.IsRetreating( bot ) or Fu.IsInTeamFight( bot, 800 )
	then
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if Fu.CanCastOnMagicImmune(npcEnemy)
			then
				return BOT_ACTION_DESIRE_MODERATE
			end
		end
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnMagicImmune( npcTarget )
			and Fu.IsInRange( bot, npcTarget, nRadius - 160 )
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end


	return 0

end


return X
