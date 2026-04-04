local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos1,2
							['t25'] = {0, 10},
							['t20'] = {10, 0},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						},
						{--pos3
							['t25'] = {10, 0},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {0, 10},
						}
}

local tAllAbilityBuildList = {
						{2,1,2,1,2,6,2,3,1,1,6,3,3,3,6},--pos1,2
						{1,2,2,1,1,6,1,3,3,3,6,3,2,2,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_1" or sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_magic_stick",
	"item_quelling_blade",

	"item_magic_wand",
	"item_power_treads",
	"item_falcon_blade",
	"item_manta",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_butterfly",--
	"item_satanic",--
	"item_assault",--
	"item_skadi",--
	"item_moon_shard",
	"item_refresher",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_slippers",
	"item_circlet",

	"item_magic_wand",
	"item_wraith_band",
	"item_boots",
	"item_falcon_blade",
	"item_power_treads",
	"item_manta",--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_shivas_guard",--
	"item_assault",--
	"item_refresher",--
	"item_moon_shard",
	"item_satanic",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

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

npc_dota_hero_razor

"Ability1"		"razor_plasma_field"
"Ability2"		"razor_static_link"
"Ability3"		"razor_unstable_current"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"razor_eye_of_the_storm"
"Ability10"		"special_bonus_hp_200"
"Ability11"		"special_bonus_agility_15"
"Ability12"		"special_bonus_unique_razor"
"Ability13"		"special_bonus_unique_razor_3"
"Ability14"		"special_bonus_armor_10"
"Ability15"		"special_bonus_unique_razor_2"
"Ability16"		"special_bonus_attack_speed_100"
"Ability17"		"special_bonus_unique_razor_4"

modifier_razor_plasma_field_thinker
modifier_razor_static_link
modifier_razor_static_link_buff
modifier_razor_static_link_debuff
modifier_razor_link_vision
modifier_razor_unstable_current
modifier_razor_unstablecurrent_slow
modifier_razor_eye_of_the_storm
modifier_razor_eye_of_the_storm_armor
--]]


local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )


local castQDesire
local castWDesire, castWTarget
local castRDesire


local aetherRange = 0

function X.SkillsComplement()


	Fu.ConsiderForMkbDisassembleMask( bot )


	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end


	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 280
	aetherRange = ctx.aetherRange
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	botTarget = ctx.target
	hEnemyList = ctx.enemies
	hAllyList = ctx.allies
	if #hEnemyList <= 1 then aetherRange = aetherRange + 200 end


	castRDesire = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityR )
		return

	end


	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return
	end


	castQDesire = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityQ )
		return
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end

	local nSkillLV = abilityQ:GetLevel()
	local nCastRange = 777
	local nCastPoint = abilityQ:GetCastPoint()
	local nManaCost = abilityQ:GetManaCost()
	local nDamage = abilityQ:GetAbilityDamage()
	local nDamageMin = abilityQ:GetSpecialValueInt( 'damage_min' )
	local nDamageMax = abilityQ:GetSpecialValueInt( 'damage_max' )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )

	--团战和击杀
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnMagicImmune( npcEnemy )
		then

			--击杀
			local nDist = GetUnitToUnitDistance( bot, npcEnemy )
			local nDamage = RemapValClamped( nDist, 0, nCastRange, nDamageMin, nDamageMax ) * 2
			if Fu.WillMagicKillTarget( bot, npcEnemy, nDamage, nCastPoint + nDist /636 )
			then
				return BOT_ACTION_DESIRE_HIGH, 'Q击杀'..Fu.Chat.GetNormName( npcEnemy )
			end

			--打断大药
			if npcEnemy:HasModifier( "modifier_flask_healing" )
				and Fu.GetModifierTime( npcEnemy, 'modifier_flask_healing' ) > 3.0
			then
				return BOT_ACTION_DESIRE_HIGH, 'Q断药'..Fu.Chat.GetNormName( npcEnemy )
			end

			--撤退
			if Fu.IsRetreating( bot )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH )
			then
				return BOT_ACTION_DESIRE_HIGH, 'Q撤退'..Fu.Chat.GetNormName( npcEnemy )
			end

			--打架
			if Fu.IsGoingOnSomeone( bot )
				and Fu.IsValidHero( botTarget )
				and Fu.IsInRange( bot, botTarget, nCastRange )
			then
				return BOT_ACTION_DESIRE_HIGH, 'Q打架'..Fu.Chat.GetNormName( botTarget )
			end

		end
	end

	--推线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) or Fu.IsFarming( bot ) )
		and #hAllyList < 3 and nLV > 7
		and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local nCanKillCount = 0
		local nCanHurtCount = 0
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 100, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
			then
				nCanHurtCount = nCanHurtCount + 1
				local nDist = GetUnitToUnitDistance( bot, creep )
				local nDamage = RemapValClamped( nDist, 0, nCastRange, nDamageMin, nDamageMax ) * 2
				if Fu.WillKillTarget( creep, nDamage, nDamageType, nDist/636 )
				then
					nCanKillCount = nCanKillCount + 1
				end
			end
		end

		if nCanKillCount >= 3 or nCanHurtCount >= 5
		then
			return BOT_ACTION_DESIRE_HIGH, 'Q推进'..nCanHurtCount
		end
	end

	--打钱
	if Fu.IsFarming( bot ) and nLV > 7 and bot:GetMana() > nKeepMana
	then
		local nCreepList = bot:GetNearbyNeutralCreeps( nCastRange + 200 )
		local nNearCreepList = bot:GetNearbyNeutralCreeps( 400 )
		if ( #nCreepList >= 3 and #nNearCreepList <= 2 )
			or #nCreepList >= 5
		then
			return BOT_ACTION_DESIRE_HIGH, 'Q打野'..( #nCreepList )
		end

	end

	--对线
	if Fu.IsLaning( bot )
	then
		local nCanKillMeleeCount = 0
		local nCanKillRangedCount = 0
		local hLaneCreepList = bot:GetNearbyLaneCreeps( nCastRange + 100, true )
		for _, creep in pairs( hLaneCreepList )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
			then
				local nDist = GetUnitToUnitDistance( bot, creep )
				local nDamage = RemapValClamped( nDist, 0, nCastRange, nDamageMin, nDamageMax ) * 2
				if Fu.WillKillTarget( creep, nDamage, nDamageType, nDist * 0.9/636 )
				then
					if Fu.IsKeyWordUnit( 'ranged', creep )
					then
						nCanKillRangedCount = nCanKillRangedCount + 1
						if not Fu.IsInRange( bot, creep, bot:GetAttackRange() + 50 )
						then
							return BOT_ACTION_DESIRE_HIGH, 'Q对线1'
						end
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
			return BOT_ACTION_DESIRE_HIGH, 'Q对线2'
		end

		if nCanKillRangedCount >= 1 and nCanKillMeleeCount >= 1
		then
			return BOT_ACTION_DESIRE_HIGH, 'Q对线3'
		end


	end

	--通用
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 15
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and Fu.CanCastOnNonMagicImmune( npcEnemy ) 
			then
				return BOT_ACTION_DESIRE_HIGH, 'Q通用'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end

	local nSkillLV = abilityW:GetLevel()
	local nCastRange = abilityW:GetCastRange()	 + aetherRange
	local nCastPoint = abilityW:GetCastPoint()
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )


	local nInRangeEnemyCount = 0
	local nCastTarget = nil
	local nAttackDamageMax = 0
	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnNonMagicImmune( npcEnemy )
			and Fu.CanCastOnTargetAdvanced( npcEnemy )
			and not npcEnemy:HasModifier('modifier_razor_static_link_debuff')
		then
			nInRangeEnemyCount = nInRangeEnemyCount + 1
			if npcEnemy:GetAttackDamage() > nAttackDamageMax
			then
				nCastTarget = npcEnemy
				nAttackDamageMax = npcEnemy:GetAttackDamage()
			end
		end
	end
	if nInRangeEnemyCount >= 2
		and nCastTarget ~= nil
	then
		return BOT_ACTION_DESIRE_HIGH, nCastTarget, 'W择优'..Fu.Chat.GetNormName( nCastTarget )
	end


	if Fu.IsLaning( bot )
	then
		nCastTarget = nInRangeEnemyList[1]
		if Fu.IsValidHero( nCastTarget )
			and Fu.CanCastOnNonMagicImmune( nCastTarget )
			and Fu.CanCastOnTargetAdvanced( nCastTarget )
			and Fu.IsInRange( bot, nCastTarget, nCastRange - 180 )
			and not nCastTarget:HasModifier('modifier_razor_static_link_debuff')
		then
			bot:SetTarget( nCastTarget )
			return BOT_ACTION_DESIRE_HIGH, nCastTarget, 'W对线'..Fu.Chat.GetNormName( nCastTarget )
		end
	end


	if Fu.IsGoingOnSomeone( bot )
		and Fu.IsValidHero( botTarget )
		and not botTarget:HasModifier('modifier_razor_static_link_debuff')
		and Fu.CanCastOnNonMagicImmune( botTarget )
		and Fu.CanCastOnTargetAdvanced( botTarget )
		and Fu.IsInRange( bot, botTarget, nCastRange - 100 )
		and Fu.GetAllyCount( bot, 1200 ) - Fu.GetEnemyCount( bot, 1600 ) < 3
	then
		return BOT_ACTION_DESIRE_HIGH, botTarget, 'W进攻'..Fu.Chat.GetNormName( botTarget )
	end


	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and not npcEnemy:HasModifier('modifier_razor_static_link_debuff')
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 3.0 ) or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, "W撤退"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end

	--通用
	if ( #hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero( 3.0 ) )
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nLV >= 15
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValid( npcEnemy )
				and not npcEnemy:HasModifier('modifier_razor_static_link_debuff')
				and Fu.IsInRange( bot, npcEnemy, nCastRange - 100 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy, 'W通用'..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


function X.ConsiderR()


	if not abilityR:IsFullyCastable()
		or bot:HasModifier( 'modifier_razor_eye_of_the_storm' )
	then return 0 end

	local nSkillLV = abilityR:GetLevel()
	local nCastRange = 500
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()
	local nDamage = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nInRangeEnemyList = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local nDamageCount = 0

	for _, npcEnemy in pairs( nInRangeEnemyList )
	do
		if Fu.IsValidHero( npcEnemy )
			and Fu.CanCastOnMagicImmune( npcEnemy )
		then
			nDamageCount = nDamageCount + 1
		end
	end


	if nDamageCount >= 2
	then
		return BOT_ACTION_DESIRE_HIGH, "R两人"
	end


	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.IsInRange( bot, botTarget, nCastRange + 200 )
			and Fu.CanCastOnMagicImmune( botTarget )
			and ( Fu.GetProperTarget( botTarget ) ~= nil or Fu.IsInRange( bot, botTarget, nCastRange ) )
			and Fu.GetAllyCount( bot, 1200 ) - Fu.GetEnemyCount( bot, 1600 ) <= 2
		then
			return BOT_ACTION_DESIRE_HIGH, "R进攻"..Fu.Chat.GetNormName( botTarget )
		end
	end

	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( nInRangeEnemyList )
		do
			if Fu.IsValidHero( npcEnemy )
				and Fu.CanCastOnMagicImmune( npcEnemy )
				and ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH )
			then
				return BOT_ACTION_DESIRE_HIGH, "R撤退"..Fu.Chat.GetNormName( npcEnemy )
			end
		end
	end


	return BOT_ACTION_DESIRE_NONE


end


return X

