local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
                        {--pos1
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {--pos2
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {10, 0},
                            ['t10'] = {0, 10},
                        },
}

local tAllAbilityBuildList = {
						{1,5,1,5,1,5,1,5,6,4,6,4,4,4,6}, -- starting with armor reduction is better, souls aslo give him more damage for better last hit
}

local nAbilityBuildList = tAllAbilityBuildList[1]
local nTalentBuildList

if sRole == "pos_1" or sRole == "pos_3" then
    nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	
	"item_magic_wand",
	"item_power_treads",
	"item_lifesteal",
	"item_dragon_lance",
	"item_lesser_crit",
	"item_black_king_bar",--
	"item_butterfly",--
	"item_greater_crit",--
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_satanic",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_faerie_fire",
	"item_enchanted_mango",
	"item_enchanted_mango",

	"item_bottle",
	"item_magic_wand",
	"item_power_treads",
	"item_lifesteal",
	"item_dragon_lance",
	"item_lesser_crit",
	"item_black_king_bar",--
	"item_orchid",
	"item_bloodthorn",--
	"item_greater_crit",--
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_satanic",--
	"item_moon_shard",
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_clarity",

	"item_magic_wand",
	"item_tranquil_boots",
	"item_null_talisman",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
	"item_force_staff",
	"item_cyclone",
	"item_boots_of_bearing",--
	"item_octarine_core",--
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_wind_waker",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	"item_tango",
	"item_tango",
	"item_double_branches",
	"item_clarity",

	"item_magic_wand",
	"item_tranquil_boots",
	"item_null_talisman",
	"item_glimmer_cape",--
	"item_pipe",--
	"item_force_staff",
	"item_cyclone",
	"item_boots_of_bearing",--
	"item_octarine_core",--
	"item_hurricane_pike",--
	"item_aghanims_shard",
	"item_wind_waker",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_kaya",
	"item_quelling_blade",

	"item_octarine_core",
	"item_bottle",
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

npc_dota_hero_nevermore

"Ability1"		"nevermore_shadowraze1"
"Ability2"		"nevermore_shadowraze2"
"Ability3"		"nevermore_shadowraze3"
"Ability4"		"nevermore_necromastery"
"Ability5"		"nevermore_dark_lord"
"Ability6"		"nevermore_requiem"
"Ability10"		"special_bonus_spell_amplify_8"
"Ability11"		"special_bonus_attack_speed_20"
"Ability12"		"special_bonus_unique_nevermore_3"
"Ability13"		"special_bonus_movement_speed_30"
"Ability14"		"special_bonus_unique_nevermore_1"
"Ability15"		"special_bonus_unique_nevermore_2"
"Ability16"		"special_bonus_unique_nevermore_5"
"Ability17"		"special_bonus_cooldown_reduction_40"

modifier_nevermore_shadowraze_debuff
modifier_nevermore_shadowraze_counter
modifier_nevermore_presence_aura
modifier_nevermore_presence
modifier_nevermore_requiem_invis_break
modifier_nevermore_requiem_thinker
modifier_nevermore_requiem_aura
modifier_nevermore_requiem
modifier_nevermore_necromastery

--]]

local abilityZ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'nevermore')
local abilityX = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'nevermore')
local abilityC = SafeAbility(bot:GetAbilityByName(sAbilityList[3]), 'sAbilityList[3]', 'nevermore')
local abilityN = SafeAbility(bot:GetAbilityByName(sAbilityList[4]), 'sAbilityList[4]', 'nevermore')
local FeastOfSouls = SafeAbility(bot:GetAbilityByName('nevermore_frenzy'), 'nevermore_frenzy', 'nevermore')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'nevermore')
local talent4 = SafeAbility(bot:GetAbilityByName(sTalentList[4]), 'sTalentList[4]', 'nevermore')

local castZDesire
local castXDesire
local castCDesire
local castNDesire, castNTarget
local FeastOfSoulsDesire
local castRDesire

local nKeepMana, nMP, nHP, nLV, nInRangeEnemy, botTarget

local bAttacking
function X.SkillsComplement()
	if bot.invisUltCombo then return end

	Fu.ConsiderTarget()
	if Fu.CanNotUseAbility( bot ) then return end

	bAttacking = Fu.IsAttacking(bot)

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 340
	nLV = ctx.level
	nMP = ctx.mp
	nHP = ctx.hp
	nInRangeEnemy = ctx.enemies
	botTarget = ctx.target

	castRDesire = X.ConsiderR()
	if castRDesire > 0
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbility ( abilityR )
		return

	end

	-- invis ult can be a good combo, dont use other spells yet.
	if abilityR:IsFullyCastable()
	and Fu.Utils.IsTruelyInvisible(bot)
	then return end

	-- this one is more important
	castXDesire = X.Consider( abilityX, 450 )
	if castXDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityX )
		return
	end

	castCDesire = X.Consider( abilityC, 700 )
	if castCDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityC )
		return
	end

	castZDesire = X.Consider( abilityZ, 200 )
	if castZDesire > 0
	then

		Fu.SetQueuePtToINT( bot, true )

		bot:ActionQueue_UseAbility( abilityZ )
		return

	end
	
	castNDesire, castNTarget = X.ConsiderN()
	if castNDesire > 0
	then

		bot:ActionQueue_UseAbilityOnEntity ( abilityN, castNTarget )
		return

	end
	
	FeastOfSoulsDesire = X.ConsiderFeastOfSouls()
	if FeastOfSoulsDesire > 0
	then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbility(FeastOfSouls)
		return
	end
end

function X.ConsiderN()

	if not abilityN:IsTrained()
		or abilityN:IsPassive()
		or not abilityN:IsFullyCastable()
		or bot:IsDisarmed()
		or abilityN:GetAutoCastState()
	then
		return 0
	end
	
	
	if not abilityN:GetAutoCastState()
	then
		abilityN:ToggleAutoCast()
	end
		
		
	return BOT_ACTION_DESIRE_NONE

end

function X.ConsiderR()
	-- the ult can be used for dealing with dmg or retreating like when hp is low.
	if not abilityR:IsFullyCastable()
	then
		return 0
	end

	-- less souls = no fear
	local nSoulCount = bot:GetModifierStackCount(bot:GetModifierByName('modifier_nevermore_necromastery'))
	-- if less sours and have sufficient hp, dont use ult yet. may collect more souls or use ult for retreating.
	if nSoulCount < 10 and nHP > 0.5 then return 0 end

	local nEnemysHerosInLong	 = Fu.GetEnemyList( bot, 1200 )
	local nEnemysHerosInSkillRange = Fu.GetEnemyList( bot, 750 )
	local nEnemysHerosNearby	 = Fu.GetEnemyList( bot, 350 )

	for _, enemy in pairs( nEnemysHerosNearby )
	do
		local cycloneTime = Fu.GetModifierTime( enemy, "modifier_brewmaster_storm_cyclone" )
		if Fu.IsValidHero( enemy )
		and ((cycloneTime > 0 and cycloneTime <= 1.66)
			or Fu.Utils.IsTruelyInvisible(bot))
		and enemy:GetHealth() > 700
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsInTeamFight( bot, 1000 ) or Fu.IsGoingOnSomeone( bot )
	then
		if #nEnemysHerosInSkillRange >= 3
			or ( #nEnemysHerosNearby >= 1 and #nEnemysHerosInSkillRange >= 2 )
			or ( #nEnemysHerosInLong >= 3 and #nEnemysHerosInSkillRange >= 2 )
			or ( #nEnemysHerosInLong >= 4 and #nEnemysHerosNearby >= 1 )
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		local nAoe = bot:FindAoELocation( true, true, bot:GetLocation(), 100, 800, 1.67, 0 )
		if nAoe.count >= 3
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		local npcTarget = Fu.GetProperTarget( bot )
		if Fu.IsValidHero( npcTarget )
			and Fu.CanCastOnNonMagicImmune( npcTarget )
			and not Fu.IsDisabled( npcTarget )
			and GetUnitToUnitDistance( npcTarget, bot ) <= 400
			and npcTarget:GetHealth() > 700
		then
			return BOT_ACTION_DESIRE_HIGH
		end

	end

	return 0
end


function X.Consider( nAbility, nDistance )

	if not nAbility:IsFullyCastable() then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius	 = 248
	local nCastLocation = Fu.GetFaceTowardDistanceLocation( bot, nDistance )
	local nCastPoint = nAbility:GetCastPoint()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nSkillLV	 = nAbility:GetLevel()
	local nDamage	 = 20 + 70 * nSkillLV
	
	if talent4:IsTrained() then nDamage = nDamage + talent4:GetSpecialValueInt( "value" ) end
	
	local nBonus	 = nAbility:GetSpecialValueInt( 'stack_bonus_damage' )
	local keyWord	 = "ranged"
	local nEnemyHeroes = Fu.GetNearbyHeroes(bot, 1000, true, BOT_MODE_NONE )
	local npcTarget = Fu.GetProperTarget( bot )

	if Fu.IsValidHero( npcTarget )
		and Fu.CanCastOnNonMagicImmune( npcTarget )
		and X.IsUnitNearLoc( npcTarget, nCastLocation, nRadius - 20, nCastPoint )
		and ( not ( bot:GetMana() <= nKeepMana * ( 1 - nSkillLV/4 ) )
				or X.IsUnitCanBeKill( npcTarget, nDamage, nBonus, nCastPoint )
				or npcTarget:HasModifier("modifier_nevermore_requiem_fear") )
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	for _, enemy in pairs( nEnemyHeroes )
	do
		if Fu.IsValidHero( enemy )
			and Fu.CanCastOnNonMagicImmune( enemy )
			and X.IsUnitNearLoc( enemy, nCastLocation, nRadius - 30, nCastPoint )
			and ( not ( bot:GetMana() <= nKeepMana * ( 1 - nSkillLV/4 ) )
			or X.IsUnitCanBeKill( enemy, nDamage, nBonus, nCastPoint )
			or enemy:HasModifier("modifier_nevermore_requiem_fear") )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if nLV <= 12
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps( 1000, true )
		local keyCount = 0
		for _, creep in pairs( nLaneCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and Fu.IsKeyWordUnit( keyWord, creep )
				and X.IsUnitNearLoc( creep, nCastLocation, nRadius, nCastPoint )
				and X.IsUnitCanBeKill( creep, nDamage, nBonus, nCastPoint )
			then
				keyCount = keyCount + 1
			end
		end
		if keyCount >= 2
		then
			--十二级下可击杀二远程
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if not Fu.IsRetreating( bot )
	then
		local nEnemysCreeps = bot:GetNearbyCreeps( 1200, true )
		local tableLaneCreeps = bot:GetNearbyLaneCreeps( nDistance + nRadius * 1.5, true )
		local nCanHurtCount = 0
		local nCanKillCount = 0
		for _, creep in pairs( nEnemysCreeps )
		do
			if Fu.IsValid( creep )
				and not creep:HasModifier( "modifier_fountain_glyph" )
				and ( creep:GetMagicResist() < 0.4 or nMP > 0.9 )
				and X.IsUnitNearLoc( creep, nCastLocation, nRadius, nCastPoint )
			then
				nCanHurtCount = nCanHurtCount + 1
				if X.IsUnitCanBeKill( creep, nDamage, nBonus, nCastPoint )
				then
					nCanKillCount = nCanKillCount + 1
				end
			end
		end

		if nLV >= 8 and nEnemyHeroes[1] == nil
		then
			if ( nCanHurtCount >= 4 and nMP > 0.6 )
				or ( nCanHurtCount >= 3 and bot:GetActiveMode() ~= BOT_MODE_LANING and nMP > 0.78 )
				or ( nCanKillCount >= 2 and nCanHurtCount == #tableLaneCreeps )
				or ( nCanHurtCount >= 2 and nMP > 0.8 and nLV > 10 and #nEnemysCreeps == 2 )
				or ( nCanHurtCount >= 2 and nLV > 24 and #nEnemysCreeps == 2 and Fu.IsAllowedToSpam( bot, 180 ) )
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		if nLV <= 10
		then
			if nCanKillCount >= 2 and ( nCanHurtCount == #tableLaneCreeps or nMP > 0.8 )
			then
				--十级下可击杀二小兵
				return BOT_ACTION_DESIRE_HIGH
			end
		end

		if nCanKillCount >= 3
		then
			--可击杀3小兵
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return 0
end

function X.ConsiderFeastOfSouls()
	if not FeastOfSouls:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nAttackRange = bot:GetAttackRange()
	local nSoulCount = bot:GetModifierStackCount(bot:GetModifierByName('modifier_nevermore_necromastery'))
	local nManaAfter = Fu.GetManaAfter(FeastOfSouls:GetManaCost()) * bot:GetMana()

	if nSoulCount < 25 then return BOT_ACTION_DESIRE_NONE end

	if Fu.IsGoingOnSomeone(bot)
	then
		if Fu.IsValidTarget(botTarget)
        and Fu.IsInRange(bot, botTarget, nAttackRange)
        and not Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    if Fu.IsFarming(bot)
	and nManaAfter > 0.3
    then
        if bAttacking
        then
            local nNeutralCreeps = bot:GetNearbyNeutralCreeps(1000)
            if nNeutralCreeps ~= nil
            and (#nNeutralCreeps >= 3
                or (#nNeutralCreeps >= 2 and nNeutralCreeps[1]:IsAncientCreep()))
            then
				return BOT_ACTION_DESIRE_HIGH
            end

            local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
            if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
            then
				return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)

        if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
		and nInRangeEnemy ~= nil and #nInRangeEnemy == 0
		and nManaAfter > 0.3
        then
			return BOT_ACTION_DESIRE_HIGH
        end

		if Fu.IsValidBuilding(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
    end

	if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot)
	then
		if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
        and Fu.IsInRange(bot, botTarget, nAttackRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.IsUnitNearLoc( nUnit, vLoc, nRange, nDely )

	if GetUnitToLocationDistance( nUnit, vLoc ) > 250
	then
		return false
	end

	local nMoveSta = nUnit:GetMovementDirectionStability()
	if nMoveSta < 0.98 then nRange = nRange - 14 end
	if nMoveSta < 0.91 then nRange = nRange - 26 end
	if nMoveSta < 0.81 then nRange = nRange - 30 end

	local fLoc = Fu.GetCorrectLoc( nUnit, nDely )
	if Fu.GetLocationToLocationDistance( fLoc, vLoc ) < nRange
	then
		return true
	end

	return false

end


function X.IsUnitCanBeKill( nUnit, nDamage, nBonus, nCastPoint )
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nStack = Fu.GetModifierCount( nUnit, "modifier_nevermore_shadowraze_debuff" )

	local nRealDamage = nDamage + nStack * nBonus

	return Fu.WillKillTarget( nUnit, nRealDamage, nDamageType, nCastPoint )

end


return X
