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
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{2,3,2,1,2,6,2,3,3,3,6,1,1,1,6},--pos1,3
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRandomItem_1 = RandomInt( 1, 9 ) > 6 and "item_black_king_bar" or "item_heavens_halberd"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",

	"item_magic_wand",
	"item_bracer",
	"item_power_treads",
	"item_ultimate_scepter",
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_sange_and_yasha",--
	"item_basher",
	"item_satanic",--
	"item_abyssal_blade",--
	"item_assault",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_travel_boots_2",--
}
sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",

	"item_magic_wand",
	"item_bracer",
	"item_arcane_boots",
	"item_blade_mail",
	"item_crimson_guard",--
	"item_black_king_bar",--
	sRandomItem_1,--
	"item_aghanims_shard",
	"item_assault",--
	"item_ultimate_scepter_2",
	"item_wind_waker",--
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
	"item_tango",
	"item_double_branches",
	"item_quelling_blade",

	"item_bottle",
	"item_magic_wand",
	"item_bracer",
	"item_power_treads",
	"item_ultimate_scepter",
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_sange_and_yasha",--
	"item_assault",--
	"item_satanic",--
	"item_basher",
	"item_ultimate_scepter_2",
	"item_abyssal_blade",--
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",
	"item_aghanims_shard",
	"item_guardian_greaves",
	"item_spirit_vessel",
	"item_lotus_orb",
	"item_mjollnir",--
	"item_ultimate_scepter",
	"item_sheepstick",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_shivas_guard",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_mage_outfit',
	"item_hand_of_midas",
	"item_glimmer_cape",

    "item_pavise",
	"item_pipe",--
    "item_solar_crest",--
	"item_lotus_orb",--
	"item_aghanims_shard",
	"item_spirit_vessel",--
	"item_ultimate_scepter",
	"item_shivas_guard",--
	"item_mystic_staff",
	"item_ultimate_scepter_2",
    "item_moon_shard",
	"item_sheepstick",--
}


X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_power_treads", "item_quelling_blade",

	"item_basher", "item_quelling_blade",
	"item_satanic", "item_magic_wand",
	"item_assault", "item_bracer",
	"item_assault", "item_bottle",
	"item_satanic", "item_bracer",
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

npc_dota_hero_bristleback

"Ability1"		"bristleback_viscous_nasal_goo"
"Ability2"		"bristleback_quill_spray"
"Ability3"		"bristleback_bristleback"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"bristleback_warpath"
"Ability10"		"special_bonus_movement_speed_20"
"Ability11"		"special_bonus_mp_regen_3"
"Ability12"		"special_bonus_hp_250"
"Ability13"		"special_bonus_unique_bristleback"
"Ability14"		"special_bonus_hp_regen_25"
"Ability15"		"special_bonus_unique_bristleback_2"
"Ability16"		"special_bonus_spell_lifesteal_15"
"Ability17"		"special_bonus_unique_bristleback_3"

modifier_bristleback_viscous_nasal_goo
modifier_bristleback_quillspray_thinker
modifier_bristleback_quill_spray
modifier_bristleback_quill_spray_stack
modifier_bristleback_bristleback
modifier_bristleback_warpath
modifier_bristleback_warpath_stack

--]]
local ViscousNasalGoo = bot:GetAbilityByName('bristleback_viscous_nasal_goo')
local QuillSpray = bot:GetAbilityByName('bristleback_quill_spray')
local Bristleback = bot:GetAbilityByName('bristleback_bristleback')
local Hairball = bot:GetAbilityByName('bristleback_hairball')
local Warpath = bot:GetAbilityByName('bristleback_warpath')

local ViscousNasalGooDesire, ViscousNasalGooTarget
local QuillSprayDesire
local HairballDesire, HairballTarget
local BristlebackDesire, BristlebackLocation
local WarpathDesire

local bAttacking = false
local botTarget, botHP
local nAllyHeroes, nEnemyHeroes

local bGoingOnSomeone
local bRetreating
local nBotHP
local bInTeamFight
function X.SkillsComplement()
	bot = GetBot()

	if Fu.CanNotUseAbility(bot) then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	nBotHP = ctx.hp
	bInTeamFight = ctx.isTeamFight

	bAttacking = Fu.IsAttacking(bot)
	botHP = nBotHP
	botTarget = ctx.target
	nAllyHeroes = ctx.allies
	nEnemyHeroes = ctx.enemies

	HairballDesire, HairballTarget = X.ConsiderHairball()
	if HairballDesire > 0 then
		Fu.SetQueuePtToINT(bot, true)
		bot:ActionQueue_UseAbilityOnLocation(Hairball, HairballTarget)
		return
	end

	BristlebackDesire, BristlebackLocation = X.ConsiderBristleback()
	if BristlebackDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(Bristleback, BristlebackLocation)
		return
	end

	ViscousNasalGooDesire, ViscousNasalGooTarget = X.ConsiderViscousNasalGoo()
    if ViscousNasalGooDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(ViscousNasalGoo, ViscousNasalGooTarget)
        return
    end

	WarpathDesire = X.ConsiderWarpath()
	if WarpathDesire > 0 then
		bot:Action_UseAbility(Warpath)
		return
	end

	QuillSprayDesire = X.ConsiderQuillSpray()
	if QuillSprayDesire > 0 then
		Fu.SetQueuePtToINT(bot, true)
		bot:ActionQueue_UseAbility(QuillSpray)
		return
	end
end

function X.ConsiderViscousNasalGoo()
	if not Fu.CanCastAbility(ViscousNasalGoo) then
		return BOT_ACTION_DESIRE_NONE, nil
	end
	for _, enemyHero in pairs(nEnemyHeroes) do
		if Fu.IsValidHero(enemyHero)
		and nBotHP < 0.6
		and nBotHP < Fu.GetHP(enemyHero)
		and Fu.IsInRange(bot, enemyHero, 900)
		and enemyHero:IsFacingLocation(bot:GetLocation(), 40)
		then
			return BOT_ACTION_DESIRE_NONE, nil
		end
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, ViscousNasalGoo:GetCastRange())
	local nManaCost = ViscousNasalGoo:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Bristleback, Hairball})

	if bInTeamFight then
		if Fu.IsValidHero(nEnemyHeroes[1])
		and Fu.CanBeAttacked(nEnemyHeroes[1])
        and Fu.CanCastOnNonMagicImmune(nEnemyHeroes[1])
		and not nEnemyHeroes[1]:HasModifier('modifier_necrolyte_reapers_scythe')
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]
		end
	end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) then
		if Fu.IsValidHero(nEnemyHeroes[1]) and Fu.IsInRange(bot, nEnemyHeroes[1], nCastRange) then
			if bInTeamFight or not Fu.IsInLaningPhase() then
				return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]
			end

			if  Fu.CanCastOnNonMagicImmune(nEnemyHeroes[1])
            and Fu.CanCastOnTargetAdvanced(nEnemyHeroes[1])
            and bot:WasRecentlyDamagedByHero(nEnemyHeroes[1], 3.0)
			then
				if Fu.IsChasingTarget(nEnemyHeroes[1], bot)
				or (#nEnemyHeroes > #nAllyHeroes and nEnemyHeroes[1]:GetAttackTarget() == bot)
				then
					return BOT_ACTION_DESIRE_HIGH, nEnemyHeroes[1]
				end
			end
		end

		for _, allyHero in pairs(nAllyHeroes) do
			if bot ~= allyHero
			and Fu.IsValidHero(allyHero)
			and Fu.IsRetreating(allyHero)
			and allyHero:WasRecentlyDamagedByAnyHero(3.0)
			and not Fu.IsSuspiciousIllusion(allyHero)
			and not Fu.IsRealInvisible(allyHero)
			and not Fu.IsRealInvisible(bot)
			then
				for _, enemyHero in ipairs(nEnemyHeroes) do
					if Fu.IsValidHero(enemyHero)
					and Fu.IsInRange(bot, enemyHero, nCastRange)
					and Fu.CanCastOnNonMagicImmune(enemyHero)
					and Fu.CanCastOnTargetAdvanced(enemyHero)
					and Fu.IsChasingTarget(enemyHero, allyHero)
					and not Fu.IsDisabled(enemyHero)
					then
						return BOT_ACTION_DESIRE_HIGH, enemyHero
					end
				end
			end
		end
	end

    if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
		and fManaAfter > 0.4
		and fManaAfter > fManaThreshold1
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

    if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
		and fManaAfter > 0.4
		and fManaAfter > fManaThreshold1
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderQuillSpray()
	if not Fu.CanCastAbility(QuillSpray) then
		return BOT_ACTION_DESIRE_NONE
	end

	if QuillSpray:GetAutoCastState() == true then
		QuillSpray:ToggleAutoCast()
	end

	local nRadius = QuillSpray:GetSpecialValueInt('radius')
	local fManaAfter = Fu.GetManaAfter(QuillSpray:GetManaCost())

	if bInTeamFight then
		if Fu.IsValidHero(nEnemyHeroes[1]) then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius - 100)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nRadius)
            and (bot:WasRecentlyDamagedByHero(enemyHero, 4.0) or enemyHero:HasModifier('modifier_bristleback_quill_spray'))
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(nRadius, true)

	if Fu.IsPushing(bot )
    or Fu.IsDefending(bot)
    or bGoingOnSomeone
    or Fu.IsFarming(bot)
	then
		if Fu.CanBeAttacked(nEnemyCreeps[1]) and fManaAfter > 0.25 then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsFarming(bot) and fManaAfter > 0.25 then
		if Fu.IsValid(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and botTarget:IsCreep()
		then
			if botTarget:GetHealth() > bot:GetAttackDamage() * 3 then
				return BOT_ACTION_DESIRE_HIGH
			end

			if Fu.IsValid(nEnemyCreeps[1]) and Fu.CanBeAttacked(nEnemyCreeps[1]) and #nEnemyCreeps >= 2 then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsDoingRoshan(bot) and bAttacking then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot) and bAttacking then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if fManaAfter > 0.9
	and not Fu.IsInLaningPhase()
	and bot:DistanceFromFountain() > 2400
	then
		return BOT_ACTION_DESIRE_HIGH
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderBristleback()
	if not Fu.CanCastAbility(Bristleback)
	or not bot:HasScepter()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nRadius = 350
	local nManaCost = Bristleback:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Bristleback, Hairball})

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and not Fu.IsChasingTarget(bot, botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
		for _, enemyHero in ipairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nRadius)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and enemyHero:GetAttackTarget() == bot
			then
				local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
				local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
				if not (#nInRangeEnemy >= #nInRangeAlly + 2) then
					return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
				end
			end
		end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(800, true)

	if Fu.IsPushing(bot) and fManaAfter > fManaThreshold1 + 0.1 and bAttacking and #nAllyHeroes <= 1 and #nEnemyHeroes == 0 then
		for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 5) then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

	if Fu.IsFarming(bot) and fManaAfter > fManaThreshold1 and bAttacking then
		for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 5)
				or (nLocationAoE.count >= 2 and creep:IsAncientCreep())
				then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

    if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius * 2)
		and fManaAfter > fManaThreshold1
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius * 2)
		and fManaAfter > fManaThreshold1
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderHairball()
	if not Fu.CanCastAbility(Hairball) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Hairball:GetCastRange())
    local nRadius = Hairball:GetSpecialValueInt('radius')
	local nManaCost = Hairball:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Bristleback})

    if Fu.IsInTeamFight(bot, 1400) then
        local vAoELocation = Fu.GetAoeEnemyHeroLocation(bot, nCastRange, nRadius, 2)
        if vAoELocation ~= nil and fManaAfter > fManaThreshold1 then
            return BOT_ACTION_DESIRE_HIGH, vAoELocation
        end
    end

    if bGoingOnSomeone then
        if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanCastOnNonMagicImmune(botTarget)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and fManaAfter > fManaThreshold1
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

	if bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(3.0) then
		for _, enemyHero in ipairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.IsInRange(bot, enemyHero, nCastRange)
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			then
				if Fu.IsChasingTarget(enemyHero, bot)
				or (#nEnemyHeroes > #nAllyHeroes and enemyHero:GetAttackTarget() == bot)
				then
					return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
				end
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderWarpath()
	if not Fu.CanCastAbility(Warpath) then
		return BOT_ACTION_DESIRE_NONE
	end

	local nInRangeAlly = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
	local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 800)

	if bInTeamFight then
		if #nInRangeEnemy > #nInRangeAlly or (botHP < 0.5 and bot:WasRecentlyDamagedByAnyHero(4.0)) then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero) and Fu.IsInRange(bot, enemyHero, 500) and Fu.IsChasingTarget(enemyHero, bot) then
				if (Fu.GetTotalEstimatedDamageToTarget(nEnemyHeroes, bot, 8.0) > bot:GetHealth() * 1.15)
				or (#nEnemyHeroes > #nAllyHeroes and botHP < 0.4)
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X