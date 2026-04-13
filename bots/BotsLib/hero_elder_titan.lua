local X             = {}
local bot           = GetBot()

local Fu             = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion        = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList   = Fu.Skill.GetTalentList( bot )
local sAbilityList  = Fu.Skill.GetAbilityList( bot )
local sRole   = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
	{--pos4,5
	['t25'] = {0, 10},
	['t20'] = {10, 0},
	['t15'] = {0, 10},
	['t10'] = {10, 0},
},
	{--pos1,3
	['t25'] = {0, 10},
	['t20'] = {0, 10},
	['t15'] = {10, 0},
	['t10'] = {10, 0},
}
}

local tAllAbilityBuildList = {
    {2,3,2,3,2,3,2,3,6,1,1,1,1,6,6},--pos1
    {2,1,2,3,2,6,2,3,3,3,6,1,1,1,6},--pos3
}


local nAbilityBuildList

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])

if sRole == "pos_1"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_bristleback_outfit",
	"item_blade_mail",--
	"item_heavens_halberd",--
	"item_lotus_orb",--
	"item_black_king_bar",--
	"item_travel_boots",
	"item_abyssal_blade",--
	-- "item_heart",--
	"item_moon_shard",
	"item_aghanims_shard",--bugged
    "item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_3'] = {
	"item_tank_outfit",
	"item_vanguard",
	"item_crimson_guard",--
	"item_heavens_halberd",--
    "item_shivas_guard",--
	"item_assault",--
	"item_travel_boots",
	"item_ultimate_scepter_2",
	"item_moon_shard",
	"item_heart",--
	"item_aghanims_shard",--bugged
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_mekansm",
	"item_glimmer_cape",
	"item_guardian_greaves",
	"item_spirit_vessel",
	"item_lotus_orb",
	"item_gungir",--
	--"item_holy_locket",
	"item_ultimate_scepter",
	"item_sheepstick",
	"item_mystic_staff",
	"item_ultimate_scepter_2",
	"item_shivas_guard",
	"item_aghanims_shard",--bugged
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
	'item_mage_outfit',
	"item_glimmer_cape",

    "item_pavise",
    "item_solar_crest",--
	"item_lotus_orb",--
	"item_pipe",--

	"item_spirit_vessel",--
	"item_ultimate_scepter",
	"item_shivas_guard",--
	"item_mystic_staff",
	"item_ultimate_scepter_2",
    "item_moon_shard",
	"item_aghanims_shard",--bugged
	"item_sheepstick",--
}

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
	"item_travel_boots",
	"item_quelling_blade",

	"item_abyssal_blade",
	"item_magic_wand",
}


if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

local EchoStomp             = SafeAbility(bot:GetAbilityByName('elder_titan_echo_stomp'), 'elder_titan_echo_stomp', 'elder_titan')
local AstralSpirit          = SafeAbility(bot:GetAbilityByName('elder_titan_ancestral_spirit'), 'elder_titan_ancestral_spirit', 'elder_titan')
local MoveAstralSpirit      = SafeAbility(bot:GetAbilityByName('elder_titan_move_spirit'), 'elder_titan_move_spirit', 'elder_titan')
local ReturnAstralSpirit    = SafeAbility(bot:GetAbilityByName('elder_titan_return_spirit'), 'elder_titan_return_spirit', 'elder_titan')
local NaturalOrder          = SafeAbility(bot:GetAbilityByName('elder_titan_natural_order'), 'elder_titan_natural_order', 'elder_titan')
local EarthSplitter         = SafeAbility(bot:GetAbilityByName('elder_titan_earth_splitter'), 'elder_titan_earth_splitter', 'elder_titan')

local botTarget
local nEnemyHeroes, nAllyHeroes

local spiritCastLoc = nil   -- where we aimed the spirit
local spiritCastTime = 0    -- when we cast it
local SPIRIT_DURATION = 10  -- max spirit lifetime (ability duration)


-- Helper: check if enemy is in Chronosphere or Black Hole
local function IsInChronoOrBlackHole(enemy)
	return enemy:HasModifier('modifier_faceless_void_chronosphere_freeze')
		or enemy:HasModifier('modifier_enigma_black_hole_pull')
end

-- Helper: check if enemy is in Chrono/BH with enough remaining duration for combo
local function IsInChronoOrBlackHoleWithDuration(enemy, minDuration)
	local modifiers = {
		'modifier_faceless_void_chronosphere_freeze',
		'modifier_enigma_black_hole_pull',
	}
	for _, modName in pairs(modifiers) do
		local modIdx = enemy:GetModifierByName(modName)
		if modIdx ~= -1 then
			local remaining = enemy:GetModifierRemainingDuration(modIdx)
			if remaining >= minDuration then
				return true
			end
		end
	end
	return false
end

-- Spirit is invisible to bot API unit lists. Track state via ability cooldown.
local function IsSpiritActive()
	return AstralSpirit and not AstralSpirit:IsFullyCastable()
		and spiritCastLoc ~= nil
		and (DotaTime() - spiritCastTime) < SPIRIT_DURATION
end

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local bGoingOnSomeone
local bInTeamFight
local fLastSpiritMoveTime = 0
local SPIRIT_MOVE_INTERVAL = 1.0 -- only redirect spirit every 3s to avoid interrupting hero

function X.SkillsComplement()
	if Fu.CanNotUseAbility(bot) or bot:IsCastingAbility() or bot:IsChanneling() then return end

	local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bInTeamFight = ctx.isTeamFight

	-- Cache per-tick variables
    nEnemyHeroes = ctx.enemies
    nAllyHeroes = ctx.allies
    botTarget = ctx.target

	MoveAstralSpirit      = SafeAbility(bot:GetAbilityByName('elder_titan_move_spirit'), 'elder_titan_move_spirit', 'elder_titan')
	ReturnAstralSpirit    = SafeAbility(bot:GetAbilityByName('elder_titan_return_spirit'), 'elder_titan_return_spirit', 'elder_titan')

	-- 1) Always prioritize non-spirit skills first (echo stomp, earth splitter)
	--    These run even when spirit is out
	if ConsiderEchoStomp(bot) > 0 then
		bot:Action_UseAbility(EchoStomp)
		return
	end

    local EarthSplitterDesire, EarthSplitterLocation = ConsiderEarthSplitter()
    if EarthSplitterDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		bot:ActionQueue_UseAbilityOnLocation(EarthSplitter, EarthSplitterLocation)
		return
    end

	-- 2) Spirit active: return or occasionally redirect
	if IsSpiritActive() then
		-- Return spirit when conditions met
		if ConsiderReturnSpirit() > 0 and ReturnAstralSpirit ~= nil and Fu.CanCastAbility(ReturnAstralSpirit) then
			bot:Action_UseAbility(ReturnAstralSpirit)
			return
		end

		-- Move spirit only when safe and throttled (every 3s)
		-- Skip if bot is being hit — don't interrupt retreat/fighting
		local closestEnemy = nEnemyHeroes and nEnemyHeroes[1] or nil
		local bInEnemyRange = Fu.IsValidHero(closestEnemy) and Fu.IsInRange(bot, closestEnemy, closestEnemy:GetAttackRange() + 150)
		if DotaTime() > fLastSpiritMoveTime + SPIRIT_MOVE_INTERVAL
		and not bot:WasRecentlyDamagedByAnyHero(2.0)
		and not bot:WasRecentlyDamagedByTower(2.0)
		and not bInEnemyRange
		and MoveAstralSpirit ~= nil and Fu.CanCastAbility(MoveAstralSpirit)
		then
			local moveDesire, moveLoc = ConsiderMoveAstralSpirit()
			if moveDesire > 0 and moveLoc ~= nil then
				bot:Action_UseAbilityOnLocation(MoveAstralSpirit, moveLoc)
				fLastSpiritMoveTime = DotaTime()
			end
		end
		-- Don't block other hero actions — just return without casting anything else
		return
	end

	-- 3) No spirit out: consider casting Astral Spirit
    local AstralSpiritDesire, AstralSpiritLocation = ConsiderAstralSpirit()
    if AstralSpiritDesire > 0 then
		Fu.SetQueuePtToINT(bot, false)
		spiritCastLoc = AstralSpiritLocation
		spiritCastTime = DotaTime()
		fLastSpiritMoveTime = DotaTime() -- don't immediately move after casting
		bot:ActionQueue_UseAbilityOnLocation(AstralSpirit, AstralSpiritLocation)
    end
end

function ConsiderAstralSpirit()
	if not AstralSpirit:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE end
    if bot:IsUsingAbility() or bot:IsCastingAbility() then return BOT_ACTION_DESIRE_NONE end
	if bot:HasModifier('modifier_elder_titan_ancestral_spirit_buff') then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = AstralSpirit:GetSpecialValueInt('AbilityCastRange')

	if Fu.IsValidTarget(botTarget) and (Fu.IsInTeamFight(bot, 1600) or bGoingOnSomeone or Fu.IsPushing(bot))
	then
        if Fu.IsInRange(bot, botTarget, nCastRange) then
			local locationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, 500, 0, 0)
			if locationAoE.count >= #nEnemyHeroes - 1 then
                return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
			end
        end
	end
	return BOT_ACTION_DESIRE_NONE
end

function ConsiderMoveAstralSpirit()
    if MoveAstralSpirit == nil then return BOT_ACTION_DESIRE_NONE end
    if not IsSpiritActive() then return BOT_ACTION_DESIRE_NONE end

    -- Move spirit toward the closest visible enemy hero near the cast area
    local enemies = nEnemyHeroes or bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE) or {}
    local bestTarget = nil
    local bestDist = 99999
    for _, enemy in pairs(enemies) do
        if Fu.IsValidHero(enemy) then
            local dist = Fu.Utils.GetLocationToLocationDistance(spiritCastLoc, enemy:GetLocation())
            if dist < bestDist then
                bestDist = dist
                bestTarget = enemy
            end
        end
    end

    if bestTarget ~= nil then
        return BOT_ACTION_DESIRE_VERYHIGH, bestTarget:GetLocation()
    end

    return BOT_ACTION_DESIRE_NONE
end

function ConsiderReturnSpirit()
    -- Return spirit after it's been out long enough to have hit things
    if not IsSpiritActive() then return BOT_ACTION_DESIRE_NONE end
    local elapsed = DotaTime() - spiritCastTime
    -- Return after 4+ seconds, or if no enemies nearby to move toward
    if elapsed >= 4 then
        return BOT_ACTION_DESIRE_HIGH
    end
    return BOT_ACTION_DESIRE_NONE
end

function ConsiderEarthSplitter()
	if not EarthSplitter:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE end
    if bot:IsCastingAbility() then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = EarthSplitter:GetSpecialValueInt('AbilityCastRange')
    local crack_width = 300
    local crack_time = 3.14

	if Fu.IsInTeamFight(bot, 1600) or bGoingOnSomeone or Fu.IsPushing(bot)
	then
		-- Check for enemies caught in Chronosphere/Black Hole with enough remaining duration
		for _, npcEnemy in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(npcEnemy)
			and Fu.CanCastOnNonMagicImmune(npcEnemy)
			and Fu.IsInRange(bot, npcEnemy, nCastRange)
			and IsInChronoOrBlackHoleWithDuration(npcEnemy, 1.8)
			then
				return BOT_ACTION_DESIRE_VERYHIGH, npcEnemy:GetLocation()
			end
		end

		local locationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, crack_width, crack_time, 1500)
		local nHeroesInAoE = Fu.GetHeroesNearLocation(true, locationAoE.targetloc, 800)
        if #nHeroesInAoE >= 3 then
            return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
        end

		-- Require at least 1 core hero when hitting 2+ enemies
		if #nHeroesInAoE >= 2 then
			local bHasCore = false
			for _, enemy in pairs(nHeroesInAoE) do
				if Fu.IsValidHero(enemy) and Fu.IsCore(enemy) then
					bHasCore = true
					break
				end
			end
			if bHasCore then
				return BOT_ACTION_DESIRE_HIGH, locationAoE.targetloc
			end
		end

        if Fu.IsValidHero( botTarget )
			and #nEnemyHeroes >= #nAllyHeroes
			and Fu.CanCastOnNonMagicImmune( botTarget )
			and Fu.CanKillTarget( botTarget, botTarget:GetMaxHealth() * 0.4, DAMAGE_TYPE_MAGICAL )
		then
            local loc = Fu.GetCorrectLoc(botTarget, crack_time)
			return BOT_ACTION_DESIRE_HIGH, loc
		end

	end
	return BOT_ACTION_DESIRE_NONE
end

function ConsiderEchoStomp(eveluator)
	if not EchoStomp:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE end

	local nRadius = EchoStomp:GetSpecialValueInt("radius");
	local nDamage = EchoStomp:GetSpecialValueInt("stomp_damage");

	if eveluator == nil then eveluator = bot end
	local nInEchoRangeEnemyHeroes = eveluator:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE)

	for _, npcEnemy in pairs(nInEchoRangeEnemyHeroes) do
		if npcEnemy:IsChanneling() -- 打断技能
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	-- Only stomp enemies that are disabled, slow, or caught in Chrono/Black Hole
	local nStompableEnemies = 0
	for _, npcEnemy in pairs(nInEchoRangeEnemyHeroes) do
		if Fu.IsValidHero(npcEnemy)
		and ( Fu.IsDisabled(npcEnemy)
			or npcEnemy:GetCurrentMovementSpeed() <= 250
			or IsInChronoOrBlackHole(npcEnemy) )
		then
			nStompableEnemies = nStompableEnemies + 1
		end
	end

	if nStompableEnemies >= 3 then
        return BOT_ACTION_DESIRE_HIGH
	end

	if Fu.IsRetreating(bot)
	then
		for _, npcEnemy in pairs(nInEchoRangeEnemyHeroes) do
			if Fu.IsValidHero(npcEnemy) and bot:WasRecentlyDamagedByHero(npcEnemy, 2)
			then
				if Fu.CanCastOnNonMagicImmune(npcEnemy)
				and ( Fu.IsDisabled(npcEnemy)
					or npcEnemy:GetCurrentMovementSpeed() <= 250
					or IsInChronoOrBlackHole(npcEnemy) )
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	if bInTeamFight or bGoingOnSomeone or Fu.IsPushing(bot) or Fu.IsDefending(bot)
	then
		if Fu.IsValidHero(botTarget)
		and Fu.IsChasingTarget(bot, botTarget)
		and Fu.IsInRange(eveluator, botTarget, nRadius)
		and ( Fu.IsDisabled(botTarget)
			or botTarget:GetCurrentMovementSpeed() <= 250
			or IsInChronoOrBlackHole(botTarget) )
		then
			return BOT_ACTION_DESIRE_HIGH
		end

		-- AoE check: only count stompable enemies
		local nAoEStompable = 0
		for _, npcEnemy in pairs(nInEchoRangeEnemyHeroes) do
			if Fu.IsValidHero(npcEnemy)
			and ( Fu.IsDisabled(npcEnemy)
				or npcEnemy:GetCurrentMovementSpeed() <= 250
				or IsInChronoOrBlackHole(npcEnemy) )
			then
				nAoEStompable = nAoEStompable + 1
			end
		end
		if nAoEStompable >= 3 then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

return X