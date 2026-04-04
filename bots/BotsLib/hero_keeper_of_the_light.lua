-- Credit goes to Furious Puppy for Bot Experiment

local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{
                            ['t25'] = {10, 0},
                            ['t20'] = {0, 10},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        },
                        {
                            ['t25'] = {0, 10},
                            ['t20'] = {0, 10},
                            ['t15'] = {0, 10},
                            ['t10'] = {10, 0},
                        }
}

local tAllAbilityBuildList = {
						{1,3,1,3,1,6,1,3,3,2,6,2,2,2,6},--pos2
                        {1,3,1,3,1,6,1,3,3,2,6,2,2,2,6},--pos4,5
}

local nAbilityBuildList = tAllAbilityBuildList[1]
if sRole == 'pos_2' then nAbilityBuildList = tAllAbilityBuildList[1] end
if sRole == 'pos_4' then nAbilityBuildList = tAllAbilityBuildList[2] end
if sRole == 'pos_5' then nAbilityBuildList = tAllAbilityBuildList[2] end

local nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
if sRole == 'pos_2' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[1]) end
if sRole == 'pos_4' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end
if sRole == 'pos_5' then nTalentBuildList = Fu.Skill.GetTalentBuild(tTalentTreeList[2]) end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_2'] = {
    "item_faerie_fire",
    "item_mantle",
    "item_circlet",
    "item_double_branches",
    "item_tango",

    "item_null_talisman",
    "item_boots",
    "item_magic_wand",
    "item_spirit_vessel",
    "item_dagon_2",
    "item_travel_boots",
    "item_black_king_bar",--
    "item_octarine_core",--
    "item_dagon_5",--
    "item_kaya_and_sange",--
    "item_sheepstick",--
    "item_ultimate_scepter",
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_aghanims_shard",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_1'] = sRoleItemsBuyList['pos_2']

sRoleItemsBuyList['pos_4'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_clarity",
    "item_blood_grenade",

    "item_boots",
    "item_urn_of_shadows", -- Alternative: item_essence_distiller (if not going spirit_vessel)
    "item_arcane_boots",
    "item_glimmer_cape",--
    "item_spirit_vessel",--
	"item_kaya_and_sange",--
    "item_guardian_greaves",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_blood_grenade",

    "item_arcane_boots",
    "item_solar_crest",--
    "item_glimmer_cape",--
    "item_mekansm",
    "item_cyclone",
    "item_guardian_greaves",--
    "item_lotus_orb",--
    "item_sheepstick",--
    "item_wind_waker",--
    "item_ultimate_scepter_2",
    "item_aghanims_shard",
    "item_moon_shard",
}

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

	if Minion.IsValidUnit( hMinionUnit )
	then
		Minion.IllusionThink( hMinionUnit )
	end
end

-- Ability handles (re-fetched each tick in SkillsComplement for safety)
local Illuminate    = bot:GetAbilityByName('keeper_of_the_light_illuminate')
local IlluminateEnd = bot:GetAbilityByName('keeper_of_the_light_illuminate_end')
local BlindingLight = bot:GetAbilityByName('keeper_of_the_light_blinding_light')
local ChakraMagic   = bot:GetAbilityByName('keeper_of_the_light_chakra_magic')
local SolarBind     = bot:GetAbilityByName('keeper_of_the_light_radiant_bind')
local Recall        = bot:GetAbilityByName('keeper_of_the_light_recall')
local WillOWisp     = bot:GetAbilityByName('keeper_of_the_light_will_o_wisp')
local SpiritForm    = bot:GetAbilityByName('keeper_of_the_light_spirit_form')

local IlluminateDesire, IlluminateLocation
local IlluminateEndDesire
local BlindingLightDesire, BlindingLightLocation
local ChakraMagicDesire, ChakraMagicTarget
local SolarBindDesire, SolarBindTarget
local RecallDesire, RecallTarget
local WillOWispDesire, WillOWispLocation
local SpiritFormDesire

local IlluminateCastedTime = -100

local nAllyHeroes, nEnemyHeroes
local botTarget
local botHP

local bGoingOnSomeone
local bAttacking
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bAttacking = Fu.IsAttacking(bot)

    -- Re-fetch ability handles each tick for safety
    Illuminate    = bot:GetAbilityByName('keeper_of_the_light_illuminate')
    IlluminateEnd = bot:GetAbilityByName('keeper_of_the_light_illuminate_end')
    BlindingLight = bot:GetAbilityByName('keeper_of_the_light_blinding_light')
    ChakraMagic   = bot:GetAbilityByName('keeper_of_the_light_chakra_magic')
    SolarBind     = bot:GetAbilityByName('keeper_of_the_light_radiant_bind')
    Recall        = bot:GetAbilityByName('keeper_of_the_light_recall')
    WillOWisp     = bot:GetAbilityByName('keeper_of_the_light_will_o_wisp')
    SpiritForm    = bot:GetAbilityByName('keeper_of_the_light_spirit_form')

    -- Cache per-tick variables
    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)
    botTarget = Fu.GetProperTarget(bot)
    botHP = Fu.GetHP(bot)

    SpiritFormDesire = X.ConsiderSpiritForm()
    if SpiritFormDesire > 0
    then
        bot:Action_UseAbility(SpiritForm)
        return
    end

    SolarBindDesire, SolarBindTarget = X.ConsiderSolarBind()
    if SolarBindDesire > 0
    then
        bot:Action_UseAbilityOnEntity(SolarBind, SolarBindTarget)
        return
    end

    WillOWispDesire, WillOWispLocation = X.ConsiderWillOWisp()
    if WillOWispDesire > 0
    then
        bot:Action_UseAbilityOnLocation(WillOWisp, WillOWispLocation)
        return
    end

    BlindingLightDesire, BlindingLightLocation = X.ConsiderBlindingLight()
    if BlindingLightDesire > 0
    then
        bot:Action_UseAbilityOnLocation(BlindingLight, BlindingLightLocation)
        return
    end

    -- Check IlluminateEnd BEFORE Illuminate so we release a channel for a kill/optimal damage
    -- before considering whether to start a new one
    IlluminateEndDesire = X.ConsiderIlluminateEnd()
    if IlluminateEndDesire > 0
    then
        bot:Action_UseAbility(IlluminateEnd)
        return
    end

    IlluminateDesire, IlluminateLocation = X.ConsiderIlluminate()
    if IlluminateDesire > 0
    then
        bot:Action_UseAbilityOnLocation(Illuminate, IlluminateLocation)
        IlluminateCastedTime = DotaTime()
        return
    end

    ChakraMagicDesire, ChakraMagicTarget = X.ConsiderChakraMagic()
    if ChakraMagicDesire > 0
    then
        bot:Action_UseAbilityOnEntity(ChakraMagic, ChakraMagicTarget)
        return
    end

    RecallDesire, RecallTarget = X.ConsiderRecall()
    if RecallDesire > 0
    then
        bot:Action_UseAbilityOnEntity(Recall, RecallTarget)
        return
    end
end

function X.ConsiderIlluminate()
    if not Fu.CanCastAbility(Illuminate) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Illuminate:GetCastRange())
    local nTravelDist = Illuminate:GetSpecialValueInt('range')
    local nRadius = Illuminate:GetSpecialValueInt('radius')
    local nMaxDamage = Illuminate:GetSpecialValueInt('total_damage')
    local nManaAfter = Fu.GetManaAfter(Illuminate:GetManaCost())

    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nTravelDist)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        then
            if Fu.CanKillTarget(enemyHero, nMaxDamage, DAMAGE_TYPE_MAGICAL)
            and not Fu.IsRunning(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
            then
                bot.illuminate_status = {'kill', enemyHero}
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end

            if Fu.IsInEtherealForm(enemyHero)
            or enemyHero:HasModifier('modifier_keeper_of_the_light_radiant_bind')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    if bGoingOnSomeone
	then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nTravelDist)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsFarming(bot) and nManaAfter > 0.25 then
        local nEnemyCreeps = bot:GetNearbyCreeps(800, true)
        if #nEnemyCreeps >= 3
        and Fu.IsValid(nEnemyCreeps[1])
        and Fu.CanBeAttacked(nEnemyCreeps[1])
        and not Fu.IsRunning(nEnemyCreeps[1])
        then
            local nLocationAoE = bot:FindAoELocation(true, false, nEnemyCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
            if nLocationAoE.count >= 3 or (nLocationAoE.count >= 2 and nEnemyCreeps[1]:IsAncientCreep())
            then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(800, true)
    if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        if #nEnemyLaneCreeps >= 3
        and Fu.IsValid(nEnemyLaneCreeps[1])
        and Fu.CanBeAttacked(nEnemyLaneCreeps[1])
        and not Fu.IsRunning(nEnemyLaneCreeps[1])
        then
            local nLocationAoE = bot:FindAoELocation(true, false, nEnemyLaneCreeps[1]:GetLocation(), 0, nRadius, 0, 0)
            if nLocationAoE.count >= 3 then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    if  Fu.IsLaning(bot)
    and (Fu.IsCore(bot) or not Fu.IsCore(bot) and not Fu.IsThereCoreNearby(1200))
    and nManaAfter > 0.28
	then
        local hCreepList = {}
        local nNearbyTower = bot:GetNearbyTowers(1600, true)
		for _, creep in pairs(nEnemyLaneCreeps) do
			if  Fu.IsValid(creep)
			and Fu.IsKeyWordUnit('ranged', creep)
            and Fu.CanBeAttacked(creep)
            and not Fu.IsRunning(creep)
			and Fu.CanKillTarget(creep, nMaxDamage, DAMAGE_TYPE_MAGICAL)
			then
				if Fu.IsValidHero(nEnemyHeroes[1])
                and not Fu.IsSuspiciousIllusion(nEnemyHeroes[1])
				and GetUnitToUnitDistance(creep, nEnemyHeroes[1]) <= 600
                and (#nNearbyTower == 0 or Fu.IsValidBuilding(nNearbyTower[1]) and GetUnitToUnitDistance(nNearbyTower[1], creep) > 700)
				then
                    bot.illuminate_status = {'laning', creep}
					return BOT_ACTION_DESIRE_HIGH, creep:GetLocation()
				end
			end

            if  Fu.IsValid(creep)
            and Fu.CanKillTarget(creep, nMaxDamage, DAMAGE_TYPE_MAGICAL)
            then
                table.insert(hCreepList, creep)
            end
		end

        if #hCreepList >= 2 then
            return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(hCreepList)
        end
	end

    if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(botTarget, bot, nCastRange)
		and Fu.CanBeAttacked(botTarget)
		and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(botTarget, bot, nCastRange)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderIlluminateEnd()
    if not Fu.CanCastAbility(IlluminateEnd)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nChannelTime = Illuminate:GetSpecialValueInt('max_channel_time')
    local nMaxDamage = Illuminate:GetSpecialValueInt('total_damage')
    local nDamage = RemapValClamped(DotaTime(), IlluminateCastedTime, IlluminateCastedTime + nChannelTime, 0, nMaxDamage)

    if bot.illuminate_status ~= nil then
        if bot.illuminate_status[1] == 'kill' then
            if Fu.IsValidHero(bot.illuminate_status[2]) and Fu.CanKillTarget(bot.illuminate_status[2], nDamage, DAMAGE_TYPE_MAGICAL) then
                return BOT_ACTION_DESIRE_HIGH
            end
        elseif bot.illuminate_status[1] == 'laning' then
            if Fu.IsValid(bot.illuminate_status[2]) and Fu.CanKillTarget(bot.illuminate_status[2], nDamage, DAMAGE_TYPE_MAGICAL) then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderBlindingLight()
    if not Fu.CanCastAbility(BlindingLight)
    then
        return BOT_ACTION_DESIRE_NONE, 0
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, BlindingLight:GetCastRange())
	local nCastPoint = BlindingLight:GetCastPoint()
    local nDamage = BlindingLight:GetSpecialValueInt('damage')
    local nRadius = BlindingLight:GetSpecialValueInt('radius')
    local nBlindingLightLevel = BlindingLight:GetLevel()

    -- Kill secure: finish off low-HP enemies
    for _, enemyHero in pairs(nEnemyHeroes)
    do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        then
            if Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end

            if (enemyHero:HasModifier('modifier_troll_warlord_battle_trance') and Fu.IsAttacking(enemyHero))
            or (enemyHero:HasModifier('modifier_legion_commander_duel') and Fu.GetHP(enemyHero) > 0.25)
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    -- Offensive: push enemy TOWARD your team when going on someone
	if bGoingOnSomeone
	then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_legion_commander_duel')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            if Fu.IsChasingTarget(bot, botTarget) then
                -- Place the light behind the target so the push goes toward us
                local vPushOrigin = Fu.VectorAway(botTarget:GetLocation(), bot:GetLocation(), nCastRange * 0.5)
                return BOT_ACTION_DESIRE_HIGH, vPushOrigin
            end
		end
	end

    -- Self-defense: push enemies away when retreating
	if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and not Fu.CanCastAbility(SolarBind)
    and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nRadius)
            and Fu.IsChasingTarget(enemy, bot)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not Fu.IsDisabled(enemy)
            then
                return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemy:GetLocation()) / 2
            end
        end
	end

    -- Ally protection: push enemy away from retreating ally
    for _, allyHero in pairs(nAllyHeroes)
    do
        if  Fu.IsValidHero(allyHero)
        and Fu.IsInRange(bot, allyHero, nCastRange)
        and Fu.IsRetreating(allyHero)
        and not allyHero:IsIllusion()
        then
            local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(nRadius, true, BOT_MODE_NONE)
            if Fu.IsValidHero(nAllyInRangeEnemy[1])
            and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
            and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_enigma_black_hole_pull')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_faceless_void_chronosphere_freeze')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_legion_commander_duel')
            and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                -- Place behind the enemy relative to the ally, so push goes away from ally
                local vPushOrigin = Fu.VectorAway(nAllyInRangeEnemy[1]:GetLocation(), allyHero:GetLocation(), nRadius * 0.4)
                return BOT_ACTION_DESIRE_HIGH, vPushOrigin
            end
        end
    end

    -- Creep clearing: use Blinding Light on 4+ lane creeps when pushing/defending (level 3+)
    if nBlindingLightLevel >= 3 and (Fu.IsPushing(bot) or Fu.IsDefending(bot)) then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)
        if #nEnemyLaneCreeps >= 4 then
            local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0)
            if nLocationAoE.count >= 4 then
                return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
            end
        end
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderChakraMagic()
    if not Fu.CanCastAbility(ChakraMagic)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, ChakraMagic:GetCastRange())
    local nManaRestore = ChakraMagic:GetSpecialValueInt('mana_restore')

	if (bot:GetMaxMana() - bot:GetMana()) > nManaRestore * 1.2
    then
		return BOT_ACTION_DESIRE_HIGH, bot
	else
		local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), nCastRange)
		for _, allyHero in pairs(nInRangeAlly) do
			if Fu.IsValidHero(allyHero)
            and ((allyHero:GetMaxMana() - allyHero:GetMana()) > nManaRestore * 1.3)
            then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderSolarBind()
    if not Fu.CanCastAbility(SolarBind)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, SolarBind:GetCastRange())

	if bGoingOnSomeone
	then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_keeper_of_the_light_radiant_bind')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	if  Fu.IsRetreating(bot)
    and not Fu.IsRealInvisible(bot)
    and not Fu.CanCastAbility(BlindingLight)
    and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, 400)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and Fu.IsChasingTarget(enemy, bot)
            and not Fu.IsDisabled(enemy)
            and not enemy:HasModifier('modifier_keeper_of_the_light_radiant_bind')
            then
                return BOT_ACTION_DESIRE_HIGH, enemy
            end
        end
	end

    if not Fu.CanCastAbility(BlindingLight) then
        for _, allyHero in pairs(nAllyHeroes) do
            if  Fu.IsValidHero(allyHero)
            and Fu.IsInRange(bot, allyHero, nCastRange)
            and Fu.IsRetreating(allyHero)
            and not allyHero:IsIllusion()
            then
                local nAllyInRangeEnemy = allyHero:GetNearbyHeroes(400, true, BOT_MODE_NONE)
                if Fu.IsValidHero(nAllyInRangeEnemy[1])
                and Fu.CanCastOnNonMagicImmune(nAllyInRangeEnemy[1])
                and Fu.CanCastOnTargetAdvanced(nAllyInRangeEnemy[1])
                and not Fu.IsSuspiciousIllusion(nAllyInRangeEnemy[1])
                and not Fu.IsDisabled(nAllyInRangeEnemy[1])
                and not nAllyInRangeEnemy[1]:HasModifier('modifier_necrolyte_reapers_scythe')
                and not nAllyInRangeEnemy[1]:HasModifier('modifier_keeper_of_the_light_radiant_bind')
                then
                    return BOT_ACTION_DESIRE_HIGH, nAllyInRangeEnemy[1]
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot)
    then
        if  Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and not botTarget:HasModifier('modifier_roshan_spell_block')
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    if Fu.IsDoingTormentor(bot) then
        if  Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderWillOWisp()
    if not Fu.CanCastAbility(WillOWisp)
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, WillOWisp:GetCastRange())
    local nRadius = WillOWisp:GetSpecialValueInt('radius')
    local nCastPoint = WillOWisp:GetCastPoint()
    local nDuration = WillOWisp:GetSpecialValueInt('duration')

    -- TP-cancel: catch enemies channeling a TP if Wisp can lock them down in time
    for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and enemyHero:HasModifier('modifier_teleporting')
        then
            local fTPRemaining = Fu.GetModifierTime(enemyHero, 'modifier_teleporting')
            -- We need the cast point to be less than the remaining TP time,
            -- and Wisp duration must be enough to actually interrupt
            if fTPRemaining > nCastPoint and nDuration > 0.5 then
                return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
            end
        end
    end

    -- Teamfight: place Wisp on 2+ enemies (at least one core)
	if Fu.IsInTeamFight(bot, 1200)
	then
        local nLocationAoE = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, nRadius, 0, 0)
        local nInRangeEnemy = Fu.GetEnemiesNearLoc(nLocationAoE.targetloc, nRadius)
		if #nInRangeEnemy >= 2 and (Fu.IsCore(nInRangeEnemy[1]) or Fu.IsCore(nInRangeEnemy[2])) then
			return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderSpiritForm()
    if not Fu.CanCastAbility(SpiritForm)
    then
        return BOT_ACTION_DESIRE_NONE
    end

	if bGoingOnSomeone
	then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, 1200)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_troll_warlord_battle_trance')
        and not botTarget:HasModifier('modifier_ursa_enrage')
		then
            -- Transform when we are stronger OR when we can secure the kill
            if Fu.WeAreStronger(bot, 1600)
            or bot:GetEstimatedDamageToTarget(true, botTarget, 10.0, DAMAGE_TYPE_ALL) > botTarget:GetHealth()
            then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderRecall()
    if not Fu.CanCastAbility(Recall) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    -- Use actual teleport delay from ability data instead of hardcoded value
    local nTeleportDelay = Recall:GetSpecialValueInt('teleport_delay')
    if nTeleportDelay == nil or nTeleportDelay == 0 then nTeleportDelay = 3 end

    for _, allyHero in pairs(GetUnitList(UNIT_LIST_ALLIED_HEROES)) do
        if Fu.IsValidHero(allyHero) and not allyHero:IsIllusion() and not Fu.IsMeepoClone(allyHero) then
            local bEnemyNearby = Fu.IsEnemyHeroAroundLocation(allyHero:GetLocation(), 1600)
            local nAllyInRangeEnemy = Fu.GetEnemiesNearLoc(allyHero:GetLocation(), 1600)

            if not bEnemyNearby then
                -- Recall low-HP retreating allies to safety (check damage window = teleport delay)
                if  Fu.IsRetreating(allyHero)
                and Fu.GetHP(allyHero) < 0.25
                and #nAllyInRangeEnemy == 0
                and allyHero:DistanceFromFountain() > 4500
                and bot:DistanceFromFountain() < 1600
                and not allyHero:WasRecentlyDamagedByAnyHero(nTeleportDelay)
                then
                    return BOT_ACTION_DESIRE_HIGH, allyHero
                end

                if Fu.IsPushing(bot)
                and GetUnitToUnitDistance(bot, allyHero) > 4000
                and not Fu.IsFarming(allyHero)
                and not Fu.IsLaning(allyHero)
                and not Fu.IsDoingRoshan(allyHero)
                and not Fu.IsDoingTormentor(allyHero)
                and not Fu.IsDefending(allyHero)
                then
                    local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1600)
                    if #nInRangeAlly >= 2 then
                        return BOT_ACTION_DESIRE_HIGH, allyHero
                    end
                end
            end
        end

    end

    return BOT_ACTION_DESIRE_NONE, nil
end

return X
