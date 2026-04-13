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
							['t20'] = {0, 10},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						},
						{--pos3
							['t25'] = {0, 10},
							['t20'] = {0, 10},
							['t15'] = {0, 10},
							['t10'] = {0, 10},
						}
}

local tAllAbilityBuildList = {
						{3,2,3,1,3,6,1,1,1,3,6,2,2,2,6},--pos1,2
						{2,3,3,1,3,6,3,1,1,1,6,2,2,2,6},--pos3
}

local nAbilityBuildList = tAllAbilityBuildList[2]
if sRole == 'pos_1' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_2' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_3' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
if sRole == 'pos_1' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_2' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_3' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end

local sUtility = {"item_crimson_guard", "item_pipe"}
local nUtility = sUtility[RandomInt(1, #sUtility)]

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_slippers",
	"item_circlet",
	"item_magic_wand",

	"item_wraith_band",
	"item_phase_boots",
	"item_maelstrom",
    "item_yasha",
    "item_black_king_bar",--
    "item_sange_and_yasha",--
	"item_mjollnir",--
	"item_basher",
	"item_aghanims_shard",
	-- "item_butterfly",--
	"item_abyssal_blade",--
	"item_skadi",--
	"item_monkey_king_bar",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_slippers",
	"item_circlet",
	"item_magic_wand",

	"item_wraith_band",
	"item_bottle",
	"item_phase_boots",
	"item_maelstrom",
    "item_yasha",
    "item_black_king_bar",--
    "item_sange_and_yasha",--
	"item_mjollnir",--
	"item_basher",
	"item_aghanims_shard",
	-- "item_butterfly",--
	"item_sheepstick",--
	"item_travel_boots",
	"item_abyssal_blade",--
	"item_travel_boots_2",--
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",
	"item_magic_wand",

	"item_double_wraith_band",
	"item_boots",
	"item_phase_boots",
	"item_maelstrom",
	"item_black_king_bar",--
	"item_mjollnir",--
	"item_heavens_halberd",--
	nUtility,--
	"item_basher",
	"item_travel_boots",
	"item_abyssal_blade",--
	"item_travel_boots_2",--
	"item_aghanims_shard",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_power_treads",
	"item_quelling_blade",

	"item_abyssal_blade",
	"item_magic_wand",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_melee_carry' }, {"item_power_treads", 'item_quelling_blade'} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local abilityQ = SafeAbility(bot:GetAbilityByName(sAbilityList[1]), 'sAbilityList[1]', 'bloodseeker')
local abilityW = SafeAbility(bot:GetAbilityByName(sAbilityList[2]), 'sAbilityList[2]', 'bloodseeker')
local abilityR = SafeAbility(bot:GetAbilityByName(sAbilityList[6]), 'sAbilityList[6]', 'bloodseeker')
local BloodMist = SafeAbility(bot:GetAbilityByName('bloodseeker_blood_mist'), 'bloodseeker_blood_mist', 'bloodseeker')
local Thirst = SafeAbility(bot:GetAbilityByName("bloodseeker_thirst"), 'bloodseeker_thirst', 'bloodseeker')

local castQDesire = 0
local castWDesire, castWLocation = 0
local castRDesire, castRTarget = 0
local BloodMistDesire, ThirstDesire
local botTarget

local nKeepMana, nMP, nHP, nLV, hEnemyHeroList

local bAttacking
function X.SkillsComplement()

	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	bAttacking = Fu.IsAttacking(bot)

	local ctx = AbilityCtx.Build(bot)
	nKeepMana = 300
	nMP = ctx.mp
	nHP = ctx.hp
	nLV = ctx.level
	hEnemyHeroList = ctx.enemies

	botTarget = ctx.target
	BloodMistDesire = X.ConsiderBloodMist()
	if (BloodMistDesire > 0)
	then
		bot:Action_ClearActions( false )
		bot:ActionQueue_UseAbility(BloodMist)
		return
	end

	ThirstDesire = X.ConsiderThirst()
	if ThirstDesire > 0
	then
		Fu.SetQueuePtToINT( bot, false )
		bot:ActionQueue_UseAbility(Thirst)
		return
	end

	castRDesire, castRTarget = X.ConsiderR()
	if ( castRDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return

	end

	castQDesire = X.ConsiderQ()
	if ( castQDesire > 0 )
	then

		bot:Action_ClearActions( false )

		bot:ActionQueue_UseAbility( abilityQ )
		return

	end

	castWDesire, castWLocation = X.ConsiderW()
	if ( castWDesire > 0 )
	then

		Fu.SetQueuePtToINT( bot, false )

		bot:ActionQueue_UseAbilityOnLocation( abilityW, castWLocation )
		return
	end


end

function X.ConsiderThirst()
	if not Fu.CanCastAbility(Thirst)
	then
		return BOT_MODE_NONE
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, 600 )
		then
			if not bot:HasModifier( 'modifier_bloodseeker_thirst' )
			then
				return BOT_ACTION_DESIRE_HIGH, bot
			end
		end
	end
	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderBloodMist()
	if not bot:HasScepter()
	or not Fu.CanCastAbility(BloodMist)
	then
		return BOT_MODE_NONE
	end

	local nRadius = 450
	local nInRangeEnemyHeroList = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

	if BloodMist:GetToggleState() == true
	then
		if nHP < 0.2
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		if #nInRangeEnemyHeroList == 0
		then
			return BOT_ACTION_DESIRE_ABSOLUTE
		end
	end

	if not BloodMist:GetToggleState() == false
	and nHP > 0.5
	then
		if Fu.IsValidHero(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius * 0.8)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_MODE_NONE
end

function X.ConsiderQ()

	-- 7.41: Bloodrage is now a no-target self-buff (no longer unit-target)
	if not abilityQ:IsFullyCastable() then return 0 end

	if bot:HasModifier( 'modifier_bloodseeker_bloodrage' ) then return 0 end

	local nDamage = bot:GetAttackDamage()

	--团战
	if Fu.IsInTeamFight( bot, 1200 ) or Fu.IsPushing( bot ) or Fu.IsDefending( bot )
	then
		local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, 1200, true, BOT_MODE_NONE )
		if #tableNearbyEnemyHeroes >= 1 then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, 600 )
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	--打野时加速
	if Fu.IsValid( botTarget ) and botTarget:GetTeam() == TEAM_NEUTRAL
	then
		local tableNearbyCreeps = bot:GetNearbyCreeps( 1000, true )
		for _, ECreep in pairs( tableNearbyCreeps )
		do
			if Fu.IsValid( ECreep ) and not Fu.CanKillTarget( ECreep, nDamage, DAMAGE_TYPE_PHYSICAL )
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

function X.ConsiderW()

	if not abilityW:IsFullyCastable()  then return 0 end

	local nRadius = 600
	local nCastRange = abilityW:GetCastRange()
	local nCastPoint = abilityW:GetCastPoint()
	local nDelay = abilityW:GetSpecialValueFloat( 'delay' )
	local nManaCost = abilityW:GetManaCost()
	local nDamage = abilityW:GetSpecialValueInt( 'damage' )

	local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, nCastRange, true, BOT_MODE_NONE )
	local tableNearbyAllyHeroes = Fu.GetNearbyHeroes(bot, 800, false, BOT_MODE_NONE )

	for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if Fu.IsValid( npcEnemy ) and Fu.CanCastOnNonMagicImmune( npcEnemy ) and Fu.CanKillTarget( npcEnemy, nDamage, DAMAGE_TYPE_PURE )
		then
			if npcEnemy:GetMovementDirectionStability() >= 0.75 then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetExtrapolatedLocation( nDelay )
			else
				return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetLocation()
			end
		end
	end

	--对线期补兵
	if bot:GetActiveMode() == BOT_MODE_LANING and Fu.IsAllowedToSpam( bot, nManaCost )
	then
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), 1000, nRadius/2, nCastPoint, nDamage )
		if ( locationAoE.count >= 4 )
		then
			return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
		end
	end

	--推进带线
	if ( Fu.IsPushing( bot ) or Fu.IsDefending( bot ) ) and Fu.IsAllowedToSpam( bot, nManaCost )
		and tableNearbyEnemyHeroes == nil or #tableNearbyEnemyHeroes == 0
		and #tableNearbyAllyHeroes <= 2
	then
		local lanecreeps = bot:GetNearbyLaneCreeps( 1000, true )
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), 1000, nRadius/2, nCastPoint, nDamage )
		if ( locationAoE.count >= 4 and #lanecreeps >= 4 )
		then
			return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
		end
	end

	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( Fu.IsValid( npcEnemy ) and bot:WasRecentlyDamagedByHero( npcEnemy, 1.0 ) and Fu.CanCastOnNonMagicImmune( npcEnemy ) )
			then
				return BOT_ACTION_DESIRE_HIGH, bot:GetLocation()
			end
		end
	end

	--团战
	if Fu.IsInTeamFight( bot, 1200 )
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange - 200, nRadius/2, nCastPoint, 0 )
		if ( locationAoE.count >= 2 )
		then
			local nInvUnit = Fu.GetInvUnitInLocCount( bot, nCastRange, nRadius/2, locationAoE.targetloc, false )
			if nInvUnit >= locationAoE.count then
				return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc
			end
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + nRadius )
		then
			local nCastLoc = Fu.GetDelayCastLocation( bot, botTarget, nCastRange, nRadius, 2.0 )
			if nCastLoc ~= nil
			then
				return BOT_ACTION_DESIRE_HIGH, nCastLoc
			end
		end
	end

    if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot)
	then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0

end

function X.ConsiderR()

	if not abilityR:IsFullyCastable() then 	return 0 end

	local nCastRange = abilityR:GetCastRange()
	local nCastPoint = abilityR:GetCastPoint()
	local nManaCost = abilityR:GetManaCost()

	local tableNearbyEnemyHeroes = Fu.GetNearbyHeroes(bot, nCastRange + 200, true, BOT_MODE_NONE )

	if Fu.IsRetreating( bot )
	then
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if bot:WasRecentlyDamagedByHero( npcEnemy, 1.0 )
				and Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and not npcEnemy:HasModifier( 'modifier_bloodseeker_bloodrage' )
				and not npcEnemy:HasModifier('modifier_bloodseeker_rupture')
			then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy
			end
		end
	end

	if Fu.IsInTeamFight( bot, 1200 )
	then
		for _, npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if Fu.CanCastOnNonMagicImmune( npcEnemy )
				and Fu.CanCastOnTargetAdvanced( npcEnemy )
				and Fu.Role.IsCarry( npcEnemy:GetUnitName() )
				and not npcEnemy:HasModifier( 'modifier_bloodseeker_bloodrage' )
				and not npcEnemy:HasModifier('modifier_bloodseeker_rupture')
				and not Fu.IsDisabled( npcEnemy )
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy
			end
		end
	end

	if Fu.IsGoingOnSomeone( bot )
	then
		if Fu.IsValidHero( botTarget )
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanCastOnTargetAdvanced( botTarget )
			and Fu.IsInRange( botTarget, bot, nCastRange + 100 )
			and not botTarget:HasModifier( 'modifier_bloodseeker_bloodrage' )
			and not botTarget:HasModifier('modifier_bloodseeker_rupture')
			and not Fu.IsDisabled( botTarget )
		then
			local allies = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE )
			if ( allies ~= nil and #allies >= 2 )
			then
				return BOT_ACTION_DESIRE_HIGH, botTarget
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0

end


return X
