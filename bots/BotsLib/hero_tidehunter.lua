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
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{3,1,2,3,3,6,3,2,2,2,6,1,1,1,6},--pos3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sLotusHalberd = RandomInt( 1, 2 ) == 1 and "item_lotus_orb" or "item_heavens_halberd"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_gauntlets",

	"item_magic_wand",
	"item_boots",
	"item_soul_ring",
	"item_phase_boots",
	"item_vladmir",--
	"item_consecrated_wraps",--
	"item_blink",
	"item_aghanims_shard",
	"item_shivas_guard",--
	sLotusHalberd,--
	"item_ultimate_scepter",
	"item_refresher",--
	"item_overwhelming_blink",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_gauntlets",

	"item_magic_wand",
	"item_boots",
	"item_soul_ring",
	"item_phase_boots",
	"item_echo_sabre",
	"item_vladmir",--
	"item_harpoon",--
	"item_aghanims_shard",
	"item_assault",--
	"item_great_scepter",--
	"item_ultimate_scepter",
	"item_overwhelming_blink",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_satanic",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_gauntlets",

	"item_magic_wand",
	"item_boots",
	"item_soul_ring",
	"item_phase_boots",
	"item_echo_sabre",
	"item_vladmir",--
	"item_harpoon",--
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_assault",--
	"item_monkey_king_bar",--
	"item_overwhelming_blink",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_satanic",--
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_wind_lace",

    "item_magic_wand",
    "item_arcane_boots",
    "item_guardian_greaves",--
    "item_blink",
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_lotus_orb",--
	"item_gungir",--
    "item_wind_waker",--
    "item_overwhelming_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_wind_lace",

    "item_magic_wand",
    "item_arcane_boots",
    "item_pipe",--
    "item_blink",
    "item_ultimate_scepter",
    "item_aghanims_shard",
    "item_black_king_bar",--
    "item_lotus_orb",--
	"item_gungir",--
    "item_wind_waker",--
    "item_overwhelming_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
	"item_travel_boots_2",--
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

	"item_satanic",
	"item_vladmir",
}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_heavens_halberd", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_tidehunter

"Ability1"		"tidehunter_gush"
"Ability2"		"tidehunter_kraken_shell"
"Ability3"		"tidehunter_anchor_smash"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"tidehunter_ravage"
"Ability10"		"special_bonus_movement_speed_15"
"Ability11"		"special_bonus_unique_tidehunter_2"
"Ability12"		"special_bonus_mp_regen_3"
"Ability13"		"special_bonus_unique_tidehunter_3"
"Ability14"		"special_bonus_unique_tidehunter_4"
"Ability15"		"special_bonus_unique_tidehunter"
"Ability16"		"special_bonus_cooldown_reduction_20"
"Ability17"		"special_bonus_attack_damage_200"

modifier_tidehunter_gush
modifier_tidehunter_kraken_shell
modifier_tidehunter_anchor_smash_caster
modifier_tidehunter_anchor_smash
modifier_tidehunter_ravage


--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'tidehunter')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'tidehunter')
abilityW = SafeAbility(bot:GetAbilityByName('tidehunter_kraken_shell'), 'tidehunter_kraken_shell', 'tidehunter')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'tidehunter')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'tidehunter')
local DeadInTheWater = SafeAbility(bot:GetAbilityByName('tidehunter_dead_in_the_water'), 'tidehunter_dead_in_the_water', 'tidehunter')
local talent3 = SafeAbility(bot:GetAbilityByName(sTalentList[3]), 'sTalentList[3]', 'tidehunter')


local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget
local DeadInTheWaterDesire, AnchorTarget

local aetherRange = 0


local nBotHP
function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	nBotHP = Fu.GetHP(bot)

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 400
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies

	castRDesire = X.ConsiderR()
	if castRDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return
	end

	castQDesire, castQTarget = X.ConsiderQ()
	if castQDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		if bot:HasScepter()
		and castQTarget ~= nil
		then
			bot:ActionQueue_UseAbilityOnLocation( abilityQ, castQTarget:GetLocation() )
		else
			bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		end
		return
	end

	castEDesire = X.ConsiderE()
	if castEDesire > 0
	then

		--Fu.SetQueuePtToINT( bot, true )

		bot:Action_UseAbility( abilityE )
		return
	end

	DeadInTheWaterDesire, AnchorTarget = X.ConsiderDeadInTheWater()
	if DeadInTheWaterDesire > 0
	then
		Fu.SetQueuePtToINT( bot, true )
		bot:ActionQueue_UseAbilityOnEntity(DeadInTheWater, AnchorTarget)
		return
	end

	castWDesire = X.ConsiderW()
	if castWDesire > 0 then
		bot:Action_UseAbility(abilityW)
		return
	end

end

function X.ConsiderW()
	if not Fu.CanCastAbility(abilityW) then
		return BOT_ACTION_DESIRE_NONE
	end

	local nAllyHeroes = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
	local nEnemyHeroes = bot:GetNearbyHeroes(800, true, BOT_MODE_NONE)

	if Fu.IsRetreating( bot ) and not Fu.IsRealInvisible(bot) and (nBotHP < 0.4 or #nEnemyHeroes > #nAllyHeroes + 2)
	then
		for _, npcEnemy in pairs( nEnemyHeroes )
		do
			if Fu.IsValidHero( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
				and Fu.IsChasingTarget(npcEnemy, bot)
			then

				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan( botTarget )
		and Fu.IsInRange( botTarget, bot, 600)
		and Fu.IsAttacking(bot)
		and nBotHP < 0.25
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, 600 )
        and Fu.IsAttacking(bot)
		and nBotHP < 0.25
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	
	if bot:HasScepter() then nCastRange = 1400 end
	
	local nRadius = 600
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	
	local nDamage = abilityQ:GetSpecialValueInt( 'gush_damage' )
	if talent3:IsTrained() then nDamage = nDamage + talent3:GetSpecialValueInt( 'value' ) end
	
	local nDamageType = DAMAGE_TYPE_MAGICAL 
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	--击杀敌人
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage , nCastPoint )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'Q-击杀'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	
	end
	
	
	--打架先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and Fu.CanCastOnTargetAdvanced( botTarget )
		then			
			hCastTarget = botTarget
			sCastMotive = 'Q-先手'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot )
		and bot:WasRecentlyDamagedByAnyHero( 5.0 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				hCastTarget = npcEnemy
				sCastMotive = 'Q-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	
	--对线期间补刀
	if bot:GetActiveMode() == BOT_MODE_LANING or ( nLV <= 7 and #hAllyList <= 2 )
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 200, true )
		local keyWord = "ranged"
		for _, creep in pairs( laneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and not Fu.IsOtherAllysTarget( creep )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				and GetUnitToUnitDistance( creep, bot ) > 280
			then
				hCastTarget = creep
				sCastMotive = 'Q-补远'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end

		if nSkillLV >= 2
			and ( bot:GetMana() > nKeepMana or nMP > 0.9 )
		then
			local keyWord = "melee"
			for _, creep in pairs( laneCreepList )
			do
				if Fu.IsValid( creep )
					and not creep:HasModifier( "modifier_fountain_glyph" )
					and not Fu.IsOtherAllysTarget( creep )
					and Fu.IsKeyWordUnit( keyWord, creep )
					and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
					and GetUnitToUnitDistance( creep, bot ) > 350
				then
					hCastTarget = creep
					sCastMotive = 'Q-补近'
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end
	end
	
	
	--带线补远程
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and #hAllyList <= 2 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange, true )
		local keyWord = "ranged"
		for _, creep in pairs( laneCreepList )
		do
			if Fu.IsValid( creep )
			    and ( Fu.IsKeyWordUnit( keyWord, creep ) or nMP > 0.8 )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.WillKillTarget( creep, nDamage, nDamageType, nCastPoint )
				and not Fu.CanKillTarget( creep, bot:GetAttackDamage() * 1.38, DAMAGE_TYPE_PHYSICAL )
			then
				hCastTarget = creep
				sCastMotive = 'Q-带线'
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end
	
	
	--打野削护甲
	if Fu.IsFarming( bot )
		and DotaTime() > 6 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		local targetCreep = bot:GetAttackTarget()

		if Fu.IsValid( targetCreep )
			and targetCreep:GetTeam() == TEAM_NEUTRAL
			and Fu.IsInRange( bot, targetCreep, nCastRange )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 2.2, DAMAGE_TYPE_PHYSICAL )
		then
			hCastTarget = targetCreep
			sCastMotive = 'Q-打野'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	    end
	end
	
	
	--辅助打肉山
	if Fu.IsDoingRoshan( bot )
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange )
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-肉山'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end	
	end


	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nRadius = abilityE:GetSpecialValueInt( 'radius' )
	local nCastRange = nRadius	
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = abilityE:GetSpecialValueInt( 'attack_damage' ) + bot:GetAttackDamage()
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange - 40 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--击杀敌人
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnMagicImmune( npcEnemy )
			and Fu.CanKillTarget( npcEnemy, nDamage, nDamageType )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'E-击杀'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	
	end
		
	
	--打架攻击
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, nRadius - 50 )
			and Fu.CanCastOnMagicImmune( botTarget )			
		then			
			hCastTarget = botTarget
			sCastMotive = 'E-攻击'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	--团战AOE
	if Fu.IsInTeamFight( bot, 1000 )
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do 
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnMagicImmune( npcEnemy )
			then
				nAoeCount = nAoeCount + 1	
			end
		end

		if nAoeCount >= 2
		then
			hCastTarget = botTarget
			sCastMotive = 'E-团战AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not npcEnemy:IsDisarmed()
			then
				hCastTarget = npcEnemy
				sCastMotive = 'E-撤退'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, sCastMotive
			end
		end
	end
	
	
	--对线期间消耗收兵
	if Fu.IsLaning( bot )
	then
		local nCanKillMeleeCount = 0
		local nCanKillRangedCount = 0
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				--and not Fu.IsOtherAllysTarget( creep )
			then
				local lastHitDamage = nDamage
				if Fu.IsItemAvailable( "item_quelling_blade" ) then lastHitDamage = lastHitDamage + 12 end
				
				if Fu.WillKillTarget( creep, lastHitDamage, nDamageType, nCastPoint )
				then
					if Fu.IsKeyWordUnit( 'ranged', creep )
					then
						nCanKillRangedCount = nCanKillRangedCount + 1
					end

					if Fu.IsKeyWordUnit( 'melee', creep )
					then
						nCanKillMeleeCount = nCanKillMeleeCount + 1
					end

				end
			end
		end

		if nCanKillMeleeCount + nCanKillRangedCount >= 3
		then
			return BOT_ACTION_DESIRE_HIGH, 'E对线1'
		end

		if nCanKillRangedCount >= 1 and nCanKillMeleeCount >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, 'E对线2'
		end

		if #hLaneCreepList == 0
			and #nInRangeEnemyList >= 1
			and nMP > 0.6
		then
			return BOT_ACTION_DESIRE_HIGH, 'E消耗'	
		end
	end
	
	
	--带线AOE
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and #hAllyList <= 3
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange , true )
		if ( #laneCreepList >= 3 or ( #laneCreepList >= 2 and nMP > 0.82 ) )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			
			hCastTarget = creep
			sCastMotive = 'E-带线AOE'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	
	--打野AOE
	if Fu.IsFarming( bot )
		and DotaTime() > 6 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.25 )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius )

		if #creepList >= 2
			and Fu.IsValid( botTarget )
		then
			hCastTarget = botTarget
			sCastMotive = 'E-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
	    end
	end


	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetSpecialValueInt( 'radius' )
	local nRadius = abilityR:GetSpecialValueInt( 'radius' )
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange - 80 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange - 260 )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--打断敌人施法
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do 
		if npcEnemy:IsChanneling()
			and not npcEnemy:IsMagicImmune()
		then
			hCastTarget = npcEnemy
			sCastMotive = 'R-打断'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive		
		end
	end
	
	
	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( botTarget, bot, 600 )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and not Fu.IsDisabled( botTarget )
		then			
			hCastTarget = botTarget
			sCastMotive = 'R-先手'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end
	
	
	
	--团战AOE
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do 
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
			then
				nAoeCount = nAoeCount + 1	
			end
		end

		if nAoeCount >= 2
		then
			hCastTarget = botTarget
			sCastMotive = 'R-团战AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end
	end

	
	
	--撤退时保护队友
	if Fu.IsRetreating( bot )
		and #nInBonusEnemyList >= 1
		and #hAllyList >= 2
	then
		local nAoeCount = 0
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do 
			if Fu.IsValidHero( npcEnemy )
				and Fu.IsInRange( bot, npcEnemy, 450 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 )
			then
				nAoeCount = nAoeCount + 1
			end
		end

		if nAoeCount >= 1
		then
			hCastTarget = botTarget
			sCastMotive = 'R-撤退AOE'..nAoeCount
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
		end		
	end

	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderDeadInTheWater()
	if not DeadInTheWater:IsTrained()
	or not DeadInTheWater:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = DeadInTheWater:GetCastRange()
	local nInRangeEnmyList = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

	if Fu.IsRetreating(bot)
	then
		for _, npcEnemy in pairs(nInRangeEnmyList)
		do
			if Fu.IsValid(npcEnemy)
			and Fu.IsMoving(npcEnemy)
			and Fu.IsInRange(npcEnemy, bot, nCastRange)
			and bot:WasRecentlyDamagedByHero(npcEnemy, 4.0)
			and Fu.CanCastOnNonMagicImmune(npcEnemy)
			and IsWithoutSpellShield(npcEnemy)
			and not Fu.IsDisabled(npcEnemy)
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidHero(botTarget)
		and Fu.IsMoving(botTarget)
		and Fu.IsInRange(botTarget, bot, nCastRange)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and IsWithoutSpellShield(botTarget)
		and not Fu.IsDisabled(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	local npcEnemy = nInRangeEnmyList[1]
	if Fu.IsValidHero(npcEnemy)
	and Fu.IsMoving(npcEnemy)
	and Fu.IsInRange(bot, npcEnemy, nCastRange - 100)
	and Fu.CanCastOnNonMagicImmune(npcEnemy)
	and IsWithoutSpellShield(npcEnemy)
	and not Fu.IsDisabled(npcEnemy)
	and Fu.IsRunning(npcEnemy)
	then
		return BOT_ACTION_DESIRE_HIGH, npcEnemy
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function IsWithoutSpellShield(npcEnemy)
	return not npcEnemy:HasModifier("modifier_item_sphere_target")
			and not npcEnemy:HasModifier("modifier_antimage_spell_shield")
			and not npcEnemy:HasModifier("modifier_item_lotus_orb_active")
end

return X