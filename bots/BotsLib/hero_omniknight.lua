local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{-- Core (pos 1/2)
                            ['t25'] = {10, 0},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {-- Offlane (pos 3)
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {10, 0},
                            ['t10'] = {10, 0},
                        },
                        {-- Support (pos 4/5)
                            ['t25'] = {0, 10},
                            ['t20'] = {0, 10},
                            ['t15'] = {10, 0},
                            ['t10'] = {0, 10},
                        }
}

local tAllAbilityBuildList = {
						{3,1,3,1,3,1,1,3,2,6,6,2,2,2,6},--pos1/2/3 core: E-max
						{3,1,1,2,1,6,1,2,2,2,6,3,3,3,6},--pos4/5 support: Q-max
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_1' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_2' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_3' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_4' then nAbilityBuildList = tAllAbilityBuildList[2] end
if sRole == 'pos_5' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList
if sRole == 'pos_3' then
    nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
elseif sRole == 'pos_4' or sRole == 'pos_5' then
    nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[3])
else
    nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
end

local utilityItems = {"item_crimson_guard", "item_pipe", "item_heavens_halberd"}
local sCrimsonPipeHalberd = utilityItems[RandomInt(1, #utilityItems)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_gauntlets",
	"item_circlet",

	"item_magic_wand",
	"item_bracer",
	"item_phase_boots",
	"item_soul_ring",
	"item_echo_sabre",
	"item_aghanims_shard",
	"item_consecrated_wraps",--
	"item_harpoon",--
	"item_blink",
	sCrimsonPipeHalberd,--
	"item_black_king_bar",--
	"item_shivas_guard",--
	"item_assault",--
	"item_overwhelming_blink",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_4'] = {
	"item_priest_outfit",
	"item_tranquil_boots",
	"item_solar_crest",
	"item_glimmer_cape",
	"item_blink",
	"item_boots_of_bearing",
	"item_aghanims_shard",
	"item_consecrated_wraps",--
	"item_sheepstick",--
	"item_ultimate_scepter",
	"item_shivas_guard",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
    "item_blood_grenade",
	"item_mage_outfit",
	"item_ancient_janggo",
	"item_glimmer_cape",
	"item_consecrated_wraps",--
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

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_tank' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

--[[

npc_dota_hero_omniknight

"Ability1"		"omniknight_purification"       -- Q: Purification (heal + pure dmg AoE)
"Ability2"		"omniknight_martyr"              -- W: Martyr (magic immunity + heal)
"Ability3"		"omniknight_hammer_of_purity"    -- E: Hammer of Purity (bonus pure dmg)
"Ability6"		"omniknight_guardian_angel"       -- R: Guardian Angel (physical immunity AoE)

--]]

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'omniknight')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'omniknight')
local abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'omniknight')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'omniknight')
local abilityAS = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'omniknight')
local talent7 = SafeAbility(bot:GetAbilityByName(sTalentList[7]), 'sTalentList[7]', 'omniknight')

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire
local castASDesire, castASTarget

local aetherRange = 0


local nLV, nKeepMana, nMP, nHP, hEnemyList, hAllyList

function X.SkillsComplement()

	-- Re-fetch ability handles each tick for safety
	abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'omniknight')
	abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'omniknight')
	abilityE = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'omniknight')
	abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'omniknight')

	-- Hammer of Purity autocast toggle — runs BEFORE the CanNotUseAbility gate
	-- so it stays toggled on even during stuns/silences.
	if abilityE ~= nil and abilityE:IsTrained() then
		local bShouldAutocast = false
		local nEnemyHeroesNearby = bot:GetNearbyHeroes(900, true, BOT_MODE_NONE)
		if nEnemyHeroesNearby ~= nil and #nEnemyHeroesNearby >= 1 then
			-- Enemy heroes nearby: autocast on for bonus damage
			bShouldAutocast = true
		elseif Fu.IsFarming(bot) or Fu.IsPushing(bot) or Fu.IsDefending(bot) then
			-- Farming/pushing: autocast on if enough mana
			if Fu.GetMP(bot) > 0.4 then
				bShouldAutocast = true
			end
		elseif Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot) then
			bShouldAutocast = true
		end

		if bShouldAutocast and not abilityE:GetAutoCastState() then
			abilityE:ToggleAutoCast()
		elseif not bShouldAutocast and abilityE:GetAutoCastState() then
			abilityE:ToggleAutoCast()
		end
	end

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	-- Cache per-tick variables
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

		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return
	end

	castWDesire, castWTarget = X.ConsiderW()
	if castWDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end

	-- Hammer of Purity: manual cast for kill confirmation or specific targets
	castEDesire, castETarget = X.ConsiderE()
	if castEDesire > 0
	then
		bot:Action_UseAbilityOnEntity( abilityE, castETarget )
		return
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = abilityQ:GetCastRange() + aetherRange
	local nRadius = abilityQ:GetSpecialValueInt( 'radius' )
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetSpecialValueInt( 'heal' )

	if talent7:IsTrained() then nDamage = nDamage + talent7:GetSpecialValueInt( 'value' ) end

	local nDamageType = DAMAGE_TYPE_PURE
	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + nRadius )
	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 + nRadius )

	local nInRangeAllyHeroList = Fu.GetNearbyHeroes(bot, nCastRange + 350, false, BOT_MODE_NONE )
	local nInRangeAllyCreepList = bot:GetNearbyCreeps( nCastRange + 200, false )

	local hCastTarget = nil
	local sCastMotive = nil


	-- Self-heal when incoming projectile or heavy damage would kill
	if Fu.GetHP(bot) < 0.3 and bot:WasRecentlyDamagedByAnyHero(2.0) then
		local nIncomingDmg = Fu.GetAttackProjectileDamageByRange(bot, 1200) * 2
		if bot:GetHealth() < bot:GetActualIncomingDamage(nIncomingDmg, DAMAGE_TYPE_PHYSICAL) + 100
		or Fu.IsStunProjectileIncoming(bot, 1200)
		then
			hCastTarget = bot
			sCastMotive = 'Q-self-save'
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end

	--击杀低血量敌人
	for _, npcEnemy in pairs( nInBonusEnemyList )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnMagicImmune( npcEnemy )
			and Fu.CanKillTarget( npcEnemy, nDamage , nDamageType )
			and not Fu.IsSuspiciousIllusion( npcEnemy )
			and not npcEnemy:HasModifier( 'modifier_abaddon_borrowed_time' )
			and not npcEnemy:HasModifier( 'modifier_dazzle_shallow_grave' )
			and not npcEnemy:HasModifier( 'modifier_necrolyte_reapers_scythe' )
			and not npcEnemy:HasModifier( 'modifier_oracle_false_promise_timer' )
		then
			local bestTarget = nil
			local bestTargetHP = 9

			--优先通过治疗队友来击杀
			for _, npcAlly in pairs( nInRangeAllyHeroList )
			do
				if Fu.IsInRange( npcAlly, npcEnemy, nRadius )
					and Fu.GetHP( npcAlly ) < bestTargetHP
				then
					bestTarget = npcAlly
					bestTargetHP = Fu.GetHP( npcAlly )
				end
			end
			if bestTarget ~= nil
			then
				hCastTarget = bestTarget
				sCastMotive = 'Q-击杀1'..Fu.Chat.GetNormName( npcEnemy )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end

			--通过治疗小兵击杀敌人
			for _, creep in pairs( nInRangeAllyCreepList )
			do
				if Fu.IsInRange( creep, npcEnemy, nRadius )
					and Fu.GetHP( creep ) < bestTargetHP
				then
					bestTarget = creep
					bestTargetHP = Fu.GetHP( creep )
				end
			end
			if bestTarget ~= nil
			then
				hCastTarget = bestTarget
				sCastMotive = 'Q-击杀2'..Fu.Chat.GetNormName( npcEnemy )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	--攻击和撤退
	if Fu.IsGoingOnSomeone( bot )
		or Fu.IsRetreating( bot )
	then

		local bestTarget = nil
		local bestAoeCount = 0

		for _, npcAlly in pairs( hAllyList )
		do
			if Fu.IsInRange( bot, npcAlly, nCastRange )
				and npcAlly:GetMaxHealth() - npcAlly:GetHealth() > nDamage + 50
			then
				local nearbyEnemyList = Fu.GetNearbyHeroes(npcAlly,  nRadius, true, BOT_MODE_NONE )
				if #nearbyEnemyList > bestAoeCount
				then
					bestAoeCount = #nearbyEnemyList
					bestTarget = npcAlly
				end
			end
		end

		if bestTarget ~= nil
		then
			local nearbyEnemyList = Fu.GetNearbyHeroes(bot,  nRadius, true, BOT_MODE_NONE)
			for _, npcEnemy in pairs( nearbyEnemyList )
			do
				if Fu.CanCastOnMagicImmune( npcEnemy )
				then
					hCastTarget = bestTarget
					sCastMotive = 'Q-AOE:'..Fu.Chat.GetNormName( bestTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end


		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nRadius )
			and Fu.CanCastOnMagicImmune( botTarget )
			and	bot:GetMaxHealth() - bot:GetHealth() > nDamage
		then
			hCastTarget = bot
			sCastMotive = 'Q-攻击时奶自己'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	--奶队友
	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local npcAlly = GetTeamMember( i )
		if npcAlly ~= nil
			and npcAlly:IsAlive()
			and not npcAlly:HasModifier( 'modifier_fountain_aura' )
			and Fu.IsInRange( bot, npcAlly, nCastRange )
			and ( Fu.GetHP( npcAlly ) < 0.15
					or ( Fu.GetHP( npcAlly ) < 0.3 and npcAlly:WasRecentlyDamagedByAnyHero( 3.0 ) ) )
		then
			hCastTarget = npcAlly
			sCastMotive = 'Q-奶队友:'..Fu.Chat.GetNormName( hCastTarget )
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end
	end


	--对线
	if Fu.IsLaning( bot )
	then
		for _, npcAlly in pairs( nInRangeAllyHeroList )
		do
			if npcAlly:GetMaxHealth() - npcAlly:GetHealth() > nDamage * 1.2
			then
				local nearbyEnemyList = Fu.GetNearbyHeroes(npcAlly,  nRadius - 20, true, BOT_MODE_NONE )
				if Fu.IsValidHero( nearbyEnemyList[1] )
					and Fu.CanCastOnMagicImmune(  nearbyEnemyList[1]  )
				then
					hCastTarget = npcAlly
					sCastMotive = 'Q-对线治疗'..Fu.Chat.GetNormName( npcAlly )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end
	end


	--推线
	local enemyLaneCreepList = bot:GetNearbyLaneCreeps( 1600, true )
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and #hAllyList <= 3 and #enemyLaneCreepList >= 3
	then
		--以自己为Aoe中心
		local laneCreepList = bot:GetNearbyLaneCreeps( nRadius , true )
		if ( #laneCreepList >= 4 or ( #laneCreepList >= 3 and nMP > 0.82 ) )
			and not laneCreepList[1]:HasModifier( "modifier_fountain_glyph" )
		then
			hCastTarget = bot
			sCastMotive = 'Q-带线AOE'..(#laneCreepList)
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
		end

		--以小兵为中心
		if enemyLaneCreepList[1] ~= nil
			and not enemyLaneCreepList[1]:HasModifier('modifier_fountain_glyph')
		then

			local bestTarget = nil
			local bestAoeCount = 0

			for _, creep in pairs( nInRangeAllyCreepList )
			do
				local creepCount = 0
				for i = 1, #enemyLaneCreepList
				do
					if enemyLaneCreepList[i]:GetHealth() < nDamage
					then
						creepCount = creepCount + 1
					end
				end

				if creepCount > bestAoeCount
				then
					bestTarget = creep
					bestAoeCount = creepCount
				end

			end

			if bestTarget ~= nil and bestAoeCount >= 3
			then
				hCastTarget = bestTarget
				sCastMotive = 'Q-清兵AOE'..(bestAoeCount)
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	--打钱
	if Fu.IsFarming( bot )
		and Fu.IsAllowedToSpam( bot, nManaCost )
		and ( bot:GetMaxHealth() - bot:GetHealth() > nDamage or nMP > 0.85 )
	then
		local creepList = bot:GetNearbyNeutralCreeps( nRadius - 20 )

		if ( #creepList >= 3 or ( #creepList >= 2 and nMP > 0.88 ) )
		then
			hCastTarget = bot
			sCastMotive = 'Q-打野AOE'..(#creepList)
			return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
	    end
	end


	--肉山
	if Fu.IsDoingRoshan( bot ) and bot:GetMana() > 660
	then
		for _, npcAlly in pairs( hAllyList )
		do
			if npcAlly:GetMaxHealth() - npcAlly:GetHealth() > nDamage
			then
				local allyTarget = npcAlly:GetAttackTarget()
				if Fu.IsRoshan( allyTarget )
					and Fu.IsInRange( npcAlly, allyTarget, nRadius )
				then
					hCastTarget = npcAlly
					sCastMotive = 'Q-肉山'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end
	end


	--折磨者
	if Fu.IsDoingTormentor( bot ) and bot:GetMana() > 660
	then
		for _, npcAlly in pairs( hAllyList )
		do
			if npcAlly:GetMaxHealth() - npcAlly:GetHealth() > nDamage
			then
				local allyTarget = npcAlly:GetAttackTarget()
				if Fu.IsTormentor( allyTarget )
					and Fu.IsInRange( npcAlly, allyTarget, nRadius )
				then
					hCastTarget = npcAlly
					sCastMotive = 'Q-折磨者'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange() + aetherRange
	local nRadius = 600
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = 0
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nDuration = abilityW:GetSpecialValueInt( "duration" )
	local nHealHealth = abilityW:GetSpecialValueInt( "hp_regen" ) * nDuration
--	local nInRangeEnemyList = Fu.GetAroundEnemyHeroList( nCastRange )
--	local nInBonusEnemyList = Fu.GetAroundEnemyHeroList( nCastRange + 200 )
	local hCastTarget = nil
	local sCastMotive = nil

	for _, npcAlly in pairs( hAllyList )
	do
		if Fu.IsValidHero( npcAlly )
			and Fu.IsInRange( bot, npcAlly, nCastRange + 300 )
			and not npcAlly:HasModifier( 'modifier_omniknight_repel' )
			and not npcAlly:IsMagicImmune()
			and not npcAlly:IsInvulnerable()
			and not npcAlly:IsIllusion()
		then


			--为加状态抗性
			if not npcAlly:IsBot()
				and npcAlly:GetLevel() >= 6
				and npcAlly:GetAttackTarget() ~= nil
				and npcAlly:GetAttackTarget():IsHero()
				and npcAlly:GetMaxHealth() - npcAlly:GetHealth() >= nHealHealth * 0.8
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-加状态抗性:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end

			--为被控制队友解状态
			if Fu.IsDisabled( npcAlly )
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-解状态:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end

			--为撤退中的队友加血
			if Fu.IsRetreating( npcAlly )
				and not npcAlly:HasModifier( 'modifier_fountain_aura' )
				and npcAlly:GetMaxHealth() - npcAlly:GetHealth() >= nHealHealth * 0.7
				and npcAlly:WasRecentlyDamagedByAnyHero( 3.0 )
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-加撤退中的队友:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end


			--为准备打架的力量队友辅助
			if Fu.IsGoingOnSomeone( npcAlly )
				and npcAlly:GetPrimaryAttribute() == ATTRIBUTE_STRENGTH
			then
				local allyTarget = Fu.GetProperTarget( npcAlly )
				if Fu.IsValidHero( allyTarget )
					and npcAlly:IsFacingLocation( allyTarget:GetLocation(), 20 )
					and Fu.IsInRange( npcAlly, allyTarget, npcAlly:GetAttackRange() + 60 )
				then
					hCastTarget = npcAlly
					sCastMotive = 'W-进攻辅助力量队友:'..Fu.Chat.GetNormName( hCastTarget )
					return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
				end
			end

			--为残血队友buff
			if Fu.GetHP( npcAlly ) < 0.5
				and ( npcAlly:WasRecentlyDamagedByAnyHero( 5.0 ) or Fu.GetHP( npcAlly ) < 0.25 )
				and not npcAlly:HasModifier( 'modifier_fountain_aura' )
			then
				hCastTarget = npcAlly
				sCastMotive = 'W-为队友回血:'..Fu.Chat.GetNormName( hCastTarget )
				return BOT_ACTION_DESIRE_HIGH, hCastTarget, sCastMotive
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end



function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end

	local nCastRange = abilityE:GetCastRange()
	local nCastPoint = abilityE:GetCastPoint()
	local nManaCost = abilityE:GetManaCost()
	local nSkillLV = abilityE:GetLevel()
	local nDamage = 25 * nSkillLV + 25 + bot:GetAttackDamage() * ( 0.5 + nSkillLV * 0.1 )
	local nDamageType = DAMAGE_TYPE_PURE

	local allyList =  Fu.GetNearbyHeroes(bot, 1200, false, BOT_MODE_NONE )

	local nEnemysHerosInView = Fu.GetNearbyHeroes(bot, 1600, true, BOT_MODE_NONE )


	local nEnemysHerosInRange = Fu.GetNearbyHeroes(bot, nCastRange + 43, true, BOT_MODE_NONE )
	local nEnemysHerosInBonus = Fu.GetNearbyHeroes(bot, nCastRange + 330, true, BOT_MODE_NONE )

	--击杀
	for _, npcEnemy in pairs( nEnemysHerosInBonus )
	do
		if Fu.IsValid( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and not Fu.IsSuspiciousIllusion( npcEnemy )
			and not npcEnemy:HasModifier( 'modifier_abaddon_borrowed_time' )
			and not npcEnemy:HasModifier( 'modifier_dazzle_shallow_grave' )
			and not npcEnemy:HasModifier( 'modifier_item_blade_mail_reflect' )
		then

			if GetUnitToUnitDistance( bot, npcEnemy ) <= nCastRange + 80
				and Fu.CanKillTarget( npcEnemy, nDamage * 1.18, nDamageType )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end

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
				and not Fu.IsSuspiciousIllusion( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_item_blade_mail_reflect' )
				and Fu.GetHP( npcEnemy ) < 0.6
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end


	--打架时先手
	if Fu.IsGoingOnSomeone( bot )
	then
		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and Fu.CanCastOnTargetAdvanced( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange + 80 )
			and not Fu.IsSuspiciousIllusion( npcTarget )
			and not npcTarget:HasModifier( 'modifier_abaddon_borrowed_time' )
			and not npcTarget:HasModifier( 'modifier_dazzle_shallow_grave' )
			and not npcTarget:HasModifier( 'modifier_item_blade_mail_reflect' )
		then
			if nSkillLV >= 3 or nMP > 0.68 or Fu.GetHP( npcTarget ) < 0.4 or nHP < 0.25
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget
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
				and not npcEnemy:HasModifier( 'modifier_item_blade_mail_reflect' )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	if Fu.IsFarming( bot )
		and nSkillLV >= 3
		and ( bot:GetAttackDamage() < 200 or nMP > 0.88 )
		and nMP > 0.71 and #hEnemyList == 0
	then
		local nCreeps = bot:GetNearbyNeutralCreeps( nCastRange + 100 )

		local targetCreep = bot:GetAttackTarget()

		if Fu.IsValid( targetCreep )
			and bot:IsFacingLocation( targetCreep:GetLocation(), 46 )
			and ( #nCreeps >= 2 or GetUnitToUnitDistance( targetCreep, bot ) <= 400 )
			and not Fu.IsRoshan( targetCreep )
			and not Fu.IsOtherAllysTarget( targetCreep )
			and not Fu.CanKillTarget( targetCreep, bot:GetAttackDamage() * 1.68, DAMAGE_TYPE_PHYSICAL )
			and not Fu.CanKillTarget( targetCreep, nDamage, nDamageType )
		then
			return BOT_ACTION_DESIRE_HIGH, targetCreep
		end
	end


	--打肉的时候输出
	if bot:GetActiveMode() == BOT_MODE_ROSHAN
		and bot:GetMana() >= 600
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsRoshan( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	--折磨者
	if Fu.IsDoingTormentor( bot )
		and bot:GetMana() >= 600
	then
		local npcTarget = bot:GetAttackTarget()
		if Fu.IsTormentor( npcTarget )
			and Fu.IsInRange( npcTarget, bot, nCastRange )
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget
		end
	end

	--受到伤害时保护自己
	if bot:WasRecentlyDamagedByAnyHero( 3.0 )
		and bot:GetActiveMode() ~= BOT_MODE_RETREAT
		and #nEnemysHerosInRange >= 1
		and nLV >= 8
	then
		for _, npcEnemy in pairs( nEnemysHerosInRange )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and npcEnemy:IsFacingLocation( bot:GetLocation(), 45 )
				and not npcEnemy:HasModifier( 'modifier_item_blade_mail_reflect' )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end

	local nRadius = abilityR:GetSpecialValueInt( 'radius' )


	-- Teamfight check FIRST (highest priority -- save multiple allies)
	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local npcAlly = GetTeamMember( i )
		if Fu.IsValidHero( npcAlly )
			and Fu.CanBeAttacked( npcAlly )
			and ( bot:HasScepter() or Fu.IsInRange( bot, npcAlly, nRadius ) )
			and not npcAlly:HasModifier( 'modifier_necrolyte_reapers_scythe' )
		then
			if Fu.IsInTeamFight( npcAlly, 1600 )
			then
				local allyList = Fu.GetAlliesNearLoc( npcAlly:GetLocation(), nRadius )
				local enemyList = Fu.GetEnemiesNearLoc( npcAlly:GetLocation(), 1200 )
				if #enemyList >= 2
					and ( #enemyList >= #allyList or #enemyList >= 3 )
				then
					local guardianCount = 0
					for _, allyHero in pairs(allyList)
					do
						if Fu.IsValidHero( allyHero )
							and Fu.CanBeAttacked( allyHero )
							and allyHero:WasRecentlyDamagedByAnyHero(4.0)
							and not allyHero:HasModifier( 'modifier_necrolyte_reapers_scythe' )
						then
							guardianCount = guardianCount + 1
							if Fu.GetHP( allyHero ) < 0.4 then guardianCount = guardianCount + 1 end
						end
					end

					if guardianCount >= 2
					then
						return BOT_ACTION_DESIRE_HIGH
					end
				end
			end
		end
	end

	-- Ally retreat check SECOND
	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local npcAlly = GetTeamMember( i )
		if Fu.IsValidHero( npcAlly )
			and Fu.CanBeAttacked( npcAlly )
			and ( bot:HasScepter() or Fu.IsInRange( bot, npcAlly, nRadius ) )
			and not npcAlly:HasModifier( 'modifier_necrolyte_reapers_scythe' )
		then
			if Fu.IsRetreating( npcAlly )
				and not Fu.IsRealInvisible( npcAlly )
				and npcAlly:WasRecentlyDamagedByAnyHero( 2.0 )
			then
				local attackModeAlly = Fu.GetNearbyHeroes(npcAlly,  nRadius, false, BOT_MODE_ATTACK )
				local retreatModeAlly = Fu.GetNearbyHeroes(npcAlly,  nRadius, false, BOT_MODE_RETREAT )
				if ( #attackModeAlly >= 2 or ( #attackModeAlly >= 1 and #retreatModeAlly >= 2 ) )
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	-- Self-defense while attacking LAST (lowest priority)
	if Fu.IsGoingOnSomeone( bot )
		and nHP < ( #hEnemyList >= 3 and 0.65 or 0.45 )
		and bot:WasRecentlyDamagedByAnyHero( 2.0 )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, 800 )
			and not Fu.IsSuspiciousIllusion( botTarget )
			and not botTarget:IsDisarmed()
			and botTarget:IsFacingLocation( bot:GetLocation(), 60 )
			and not Fu.IsChasingTarget( bot, botTarget )
		then
			if nHP < 0.55 then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X
