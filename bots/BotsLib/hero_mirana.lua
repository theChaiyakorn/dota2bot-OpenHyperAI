local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils')
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion')
local sTalentList = Fu.Skill.GetTalentList(bot)
local sAbilityList = Fu.Skill.GetAbilityList(bot)
local sRole = Fu.Item.GetRoleItemsBuyList(bot)

local tTalentTreeList = {
	['t25'] = {10, 0},
	['t20'] = {10, 0},
	['t15'] = {10, 0},
	['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
	{1,3,1,2,1,6,1,3,3,3,6,2,2,2,6},
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList)

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {

	"item_ranged_carry_outfit",
	"item_dragon_lance",
	"item_rod_of_atos",
	"item_maelstrom",
	"item_black_king_bar",
	"item_mjollnir",
	"item_travel_boots",
	"item_orchid",
	"item_bloodthorn",
    "item_force_staff",
	"item_hurricane_pike",
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_travel_boots_2",
	"item_ultimate_scepter_2",
	"item_butterfly",
}

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
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_pipe",
    "item_ultimate_scepter",
	"item_cyclone",
--	"item_wraith_pact",
	"item_shivas_guard",
	"item_sheepstick",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'],X['sSellList'] = { 'PvN_ranged_carry' }, {} end

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'] = Fu.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList']);

X['sSkillList'] = Fu.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit(hMinionUnit) 
	then
		Minion.IllusionThink(hMinionUnit)	
	end

end

--[[

npc_dota_hero_mirana

"Ability1"		"mirana_starfall"
"Ability2"		"mirana_arrow"
"Ability3"		"mirana_leap"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"mirana_invis"
"Ability10"		"special_bonus_attack_damage_12"
"Ability11"		"special_bonus_hp_150"
"Ability12"		"special_bonus_unique_mirana_3"
"Ability13"		"special_bonus_unique_mirana_1"
"Ability14"		"special_bonus_spell_amplify_10"
"Ability15"		"special_bonus_mana_break_20"
"Ability16"		"special_bonus_unique_mirana_2"
"Ability17"		"special_bonus_unique_mirana_4"

modifier_mirana_starfall_scepter_thinker
modifier_mirana_starfall_thinker
modifier_mirana_leap_charge_counter
modifier_mirana_leap
modifier_mirana_leap_buff
modifier_mirana_moonlight_shadow
modifier_mirana_moonlight_shadow_killtracker

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'mirana')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'mirana')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'mirana')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'mirana')
local CelestialQuiver = SafeAbility(bot:GetAbilityByName('mirana_celestial_quiver'), 'mirana_celestial_quiver', 'mirana')


local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire, castRTarget
local CelestialQuiverDesire, CelestialQuiverTarget


local aetherRange = 0


function X.SkillsComplement()
	
	if Fu.CanNotUseAbility(bot) then return end
	
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

		Fu.SetQueuePtToINT(bot, true)

		bot:ActionQueue_UseAbility( abilityQ )
		return;
	end

	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, true)

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWTarget )
		return;
	end

	castEDesire, castETarget = X.ConsiderE()
	if ( castEDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, false)

		bot:ActionQueue_UseAbility( abilityE )
		return;
	end

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT(bot, true)

		bot:ActionQueue_UseAbility( abilityR )
		return;

	end

	CelestialQuiverDesire, CelestialQuiverTarget = X.ConsiderCelestialQuiver()
	if CelestialQuiverDesire > 0
	then
		bot:Action_UseAbilityOnEntity(CelestialQuiver, CelestialQuiverTarget)
		return
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetSpecialValueInt( "starfall_radius" )
	local nRadius = abilityQ:GetSpecialValueInt( "starfall_secondary_radius" )
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nRadius )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	--击杀敌人
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do 
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.WillMagicKillTarget( bot, npcEnemy, nDamage , nCastPoint )
		then
			hCastTarget = npcEnemy
			sCastMotive = 'Q-击杀:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end	
	end
	
	
	--打架先手
	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and Fu.CanCastOnNonMagicImmune( botTarget )			
			and ( #nInRangeEnemyList >= 1 
					or #nInBonusEnemyList >= 2
					or nHP < 0.4 )
		then			
			hCastTarget = botTarget
			sCastMotive = 'Q-攻击:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot )
		and bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and ( #nInRangeEnemyList >= 1 or nHP < 0.6 )
	then
		for _, npcEnemy in pairs( nInBonusEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )				
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
		local nCanKillMeleeCount = 0
		local nCanKillRangedCount = 0
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and not Fu.IsOtherAllysTarget( creep )
			then
				local lastHitDamage = nDamage
								
				if Fu.WillKillTarget( creep, lastHitDamage, nDamageType, nCastPoint + 0.57 )
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
			hCastTarget = bot
			sCastMotive = 'Q对线1'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end

		if nCanKillRangedCount >= 1 and nCanKillMeleeCount >= 1
		then
			hCastTarget = bot
			sCastMotive = 'Q对线2'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end

		if #hLaneCreepList == 0
			and #nInRangeEnemyList >= 1
			and nMP > 0.5
		then
			hCastTarget = nInRangeEnemyList[1]
			sCastMotive = 'Q对线消耗:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end
	
	
	--带线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost * 0.32 )
		and #hAllyList <= 3 and #hEnemyList == 0
	then
		local laneCreepList = bot:GetNearbyLaneCreeps( nCastRange - 50, true )
		
		if Fu.IsValid( laneCreepList[1] )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
			and ( #laneCreepList >= 5 or ( nMP > 0.88 and #laneCreepList >= 4 ) )
		then
			hCastTarget = creep
			sCastMotive = 'Q-带线'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
		
	end
	
	
	--打野
	if Fu.IsFarming( bot )
		and DotaTime() > 8 * 60
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius )

		if #creepList >= 3
			and Fu.IsValid( botTarget )
			and botTarget:GetMagicResist() < 0.51
		then
			hCastTarget = botTarget
			sCastMotive = 'Q-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, sCastMotive
	    end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetSpecialValueInt( 'arrow_range' )
	local nRadius = abilityW:GetSpecialValueInt( 'arrow_width' )
	local nSpeed = abilityW:GetSpecialValueInt( 'arrow_speed' )
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	
	local nCanSeenEnemyHeroList = GetUnitList( UNIT_LIST_ENEMY_HEROES )
	
	local hCastTarget = nil
	local sCastMotive = nil
	
	
	
	for _, npcEnemy in pairs( nCanSeenEnemyHeroList )
	do
		if Fu.IsInRange( bot, npcEnemy, nCastRange )
			and not Fu.IsInRange( bot, npcEnemy, 80 )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and not Fu.IsOtherAllyCanKillTarget( bot, npcEnemy )
		then
			--打断TP
			if npcEnemy:HasModifier( 'modifier_teleporting' )
				and not X.IsEnemyCreepBetweenEnemyHero( bot, npcEnemy, nRadius )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-射箭打断:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget:GetLocation(), sCastMotive			
			end
			
			
			--辅助眩晕
			-- if npcEnemy:IsStunned()
			-- then
				-- local nDistance = GetUnitToUnitDistance( bot, npcEnemy )
				-- local nDelay = nCastPoint + ( nDistance - 50 ) / nSpeed
				-- if Fu.GetRemainStunTime( npcEnemy ) > nDelay * 0.666
				   -- or Fu.GetRemainStunTime( npcEnemy ) > 1.4
				-- then
					-- hCastTarget = npcEnemy
					-- sCastMotive = 'W-辅助眩晕:'..Fu.Chat.GetNormName( hCastTarget )
					-- return BOT_ACTION_DESIRE_HIGH, hCastTarget:GetLocation(), sCastMotive		
				-- end
			-- end
			--辅助控制
			if Fu.IsDisabled( npcEnemy )
				and not X.IsEnemyCreepBetweenEnemyHero( bot, npcEnemy, nRadius )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'W-辅助控制:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget:GetLocation(), sCastMotive				
			end
					
		end
	end
	
	
	--打野
	if Fu.IsFarming( bot )
		and DotaTime() > 4 * 60
		and nLV <= 22
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local creepList = bot:GetNearbyNeutralCreeps( 1600 )

		local targetCreep = Fu.GetMostHpUnit( creepList )

		if Fu.IsValid( targetCreep )
			and targetCreep:GetHealth() > 920
			and not targetCreep:IsAncientCreep()
			and not Fu.IsOtherAllysTarget( targetCreep )
		then
			hCastTarget = targetCreep
			sCastMotive = 'W-打野'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget:GetLocation(), sCastMotive
		end
	end
	

	--肉山
	if Fu.IsDoingRoshan( bot )
	then
		if Fu.IsRoshan( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange )
			and not Fu.IsInRange( bot, botTarget, 300 )
		then
			hCastTarget = botTarget
			sCastMotive = 'W-肉山'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget:GetLocation(), sCastMotive
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange( botTarget, bot, nCastRange )
        and Fu.IsAttacking(bot)
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderE()


	if not abilityE:IsFullyCastable() 
		or bot:IsRooted()
	then return 0 end

	local nSkillLV = abilityE:GetLevel()
	local nCastRange = abilityE:GetSpecialValueInt( "leap_distance" )
	local nRadius = bot:GetAttackRange()
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( 800 )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( 1200 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	--攻击敌人
	if Fu.IsGoingOnSomeone( bot ) 
		and not bot:HasModifier( 'modifier_mirana_leap_buff' )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + nRadius + 100 )
			and not Fu.IsInRange( bot, botTarget, nCastRange - 30 )
			and not botTarget:IsAttackImmune()
			and Fu.CanCastOnMagicImmune( botTarget )
			and bot:IsFacingLocation( botTarget:GetLocation(), 6 )
		then
			local enemyList = Fu.GetNearbyHeroes(botTarget,  900, false, BOT_MODE_NONE )
			local allyList = Fu.GetNearbyHeroes(botTarget,  1300, true, BOT_MODE_NONE )
			local aliveEnemyCount = Fu.GetNumOfAliveHeroes( true )
			
			if aliveEnemyCount <= 2
				or #enemyList <= 1
				or #enemyList <= #allyList
				or Fu.WillKillTarget( botTarget, bot:GetAttackDamage() * 3, DAMAGE_TYPE_PHYSICAL, 2.0 )
			then
			
				hCastTarget = botTarget
				sCastMotive = 'E-进攻:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				
			end		
	
		end
	end
	
	
	
	--被卡住了
	if Fu.IsStuck( bot )
	then
		hCastTarget = bot
		sCastMotive = 'E-被卡住'
		return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	end	
	
	
	
	--撤退时保护自己
	if Fu.IsRetreating( bot ) 
		and bot:WasRecentlyDamagedByAnyHero( 3.0 )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and not Fu.IsDisabled( npcEnemy )
				and not bot:IsFacingLocation( npcEnemy:GetLocation(), 155 )
			then
				hCastTarget = npcEnemy
				sCastMotive = 'E-逃跑:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive			
			end
		end
	end
	
	
	--打钱赶路
	if Fu.IsFarming( bot ) 
		and nLV >= 12
		and not bot:HasModifier( 'modifier_mirana_leap_buff' )
	then
	
		if botTarget ~= nil 
			and botTarget:IsAlive()
			and Fu.IsInRange( bot, botTarget, nCastRange + nRadius + 400 )
			and not Fu.IsInRange( bot, botTarget, 1080 )
			and bot:IsFacingLocation( botTarget:GetLocation(), 6 )			
		then
			hCastTarget = botTarget:GetLocation()
			sCastMotive = 'E-打钱赶路'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
		
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = abilityR:GetCastRange()
	local nRadius = 600
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetSpecialValueInt( 'dam' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	
	
	for i = 1, #GetTeamPlayers( GetTeam() )
	do 
		local npcAlly = GetTeamMember( i )
		if npcAlly ~= nil
			and npcAlly:IsAlive()
			and not npcAlly:IsInvisible()
		then
			
			--为潜行准备进攻的队友们提供隐身
			if Fu.IsGoingOnSomeone( npcAlly ) 
			then
				local allyTarget = Fu.GetProperTarget( npcAlly )
				if Fu.IsValidHero( allyTarget )
					and not Fu.IsInRange( npcAlly, allyTarget, 1600 )
					and Fu.IsInRange( npcAlly, allyTarget, 2800 )
				then
					local nearAllyList = Fu.GetAlliesNearLoc( npcAlly:GetLocation(), 1000 )
					if #nearAllyList >= 2
					then
						hCastTarget = npcAlly
						sCastMotive = 'R-潜行准备进攻的队友:'..Fu.Chat.GetNormName( hCastTarget )
						return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
					end					
				end			
			end
			
			
			--为撤退的队友隐身
			if Fu.IsRetreating( npcAlly )
			then
				local enemyList = Fu.GetNearbyHeroes(npcAlly,  900, true, BOT_MODE_NONE )
				for _, npcEnemy in pairs( enemyList )
				do 
					if npcAlly:WasRecentlyDamagedByHero( npcEnemy, 3.0 )
					then
						hCastTarget = npcAlly
						sCastMotive = 'R-隐身撤退的队友:'..Fu.Chat.GetNormName( hCastTarget )
						return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
					end
				end
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.IsEnemyCreepBetweenEnemyHero( hSource, hTarget, nRadius )
	local vStart = hSource:GetLocation()
	local vEnd = hTarget:GetLocation()
	local creeps = hSource:GetNearbyLaneCreeps(1600, true)
	for i,creep in pairs(creeps) 
	do
		if Fu.IsValid(creep) then
			local tResult = PointToLineDistance(vStart, vEnd, creep:GetLocation())
			if tResult ~= nil 
				and tResult.within 
				and tResult.distance <= nRadius + 20
			then
				return true
			end
		end
	end

	creeps = hTarget:GetNearbyLaneCreeps(1600, false)
	if creeps then
		for i,creep in pairs(creeps)
		do
			if Fu.IsValid(creep) then
				local tResult = PointToLineDistance(vStart, vEnd, creep:GetLocation());
				if tResult ~= nil
					and tResult.within
					and tResult.distance <= nRadius + 20
				then
					return true
				end
			end
		end
	end
	return false
end

function X.ConsiderCelestialQuiver()
	if not Fu.CanCastAbility(CelestialQuiver)
	or bot:IsDisarmed()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nDamage = CelestialQuiver:GetSpecialValueInt('bonus_damage')
	local bIsAutoCasted = CelestialQuiver:GetAutoCastState()
	local nEnemyHeroes = bot:GetNearbyHeroes(bot:GetAttackRange() + 300, true, BOT_MODE_NONE)

	for _, enemyHero in pairs(nEnemyHeroes) do
		if  Fu.IsValidHero(enemyHero)
		and Fu.CanBeAttacked(enemyHero)
		and Fu.IsInRange(bot, enemyHero, bot:GetAttackRange() + 150)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
		and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
		and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
		and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			if  Fu.WillKillTarget(enemyHero, bot:GetAttackDamage() + nDamage, DAMAGE_TYPE_MAGICAL, bot:GetAttackSpeed())
			and not Fu.WillKillTarget(enemyHero, bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL, bot:GetAttackSpeed())
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end

	if Fu.IsGoingOnSomeone(bot) then
		if  Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, bot:GetAttackRange() + 300)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and not botTarget:HasModifier('modifier_oracle_false_promise_timer')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			if not bIsAutoCasted then
				CelestialQuiver:ToggleAutoCast()
			end

			return BOT_ACTION_DESIRE_NONE
		end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(Min(bot:GetAttackRange() + 300, 1600), true)

	if Fu.IsLaning(bot) and Fu.IsEarlyGame() then
		for _, creep in pairs(nEnemyCreeps) do
			if  Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and Fu.IsKeyWordUnit('ranged', creep)
			and not Fu.CanKillTarget(creep, bot:GetAttackDamage(), DAMAGE_TYPE_PHYSICAL)
			then
				local nLocationAoE = bot:FindAoELocation(true, true, creep:GetLocation(), 0, 650, 0, 0)
				if Fu.WillKillTarget(creep, bot:GetAttackDamage() + nDamage, DAMAGE_TYPE_MAGICAL, bot:GetAttackSpeed()) then
					if nLocationAoE.count > 0 or Fu.IsUnitTargetedByTower(creep, false) or Fu.IsEnemyTargetUnit(creep, 1200) then
						return BOT_ACTION_DESIRE_HIGH, creep
					end
				end
			end
		end
	end

	if bIsAutoCasted then CelestialQuiver:ToggleAutoCast() end

	return BOT_ACTION_DESIRE_NONE
end

return X
