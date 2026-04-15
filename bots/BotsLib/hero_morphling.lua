local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require( GetScriptDirectory()..'/FuncLib/systems/ability_context' )
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local SPL = require( GetScriptDirectory()..'/FuncLib/data/spell_list' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos1
                            ['t25'] = {0, 10},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        },
                        {--pos2
                            ['t25'] = {0, 10},
                            ['t20'] = {10, 0},
                            ['t15'] = {0, 10},
                            ['t10'] = {0, 10},
                        }
}

local tAllAbilityBuildList = {
						{4,2,1,1,1,6,1,4,4,2,2,6,4,2,6},--pos1
                        {4,2,1,1,1,6,1,4,4,2,2,6,4,2,6},--pos2
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_2"
then
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
else
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_circlet",

    "item_magic_wand",
    "item_power_treads",
    "item_vladmir",
    "item_manta",--
    "item_butterfly",--
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_greater_crit",--
    "item_skadi",--
    "item_moon_shard",
    "item_satanic",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = {
    "item_tango",
    "item_double_branches",
    "item_magic_stick",
    "item_circlet",

    "item_bottle",
    "item_magic_wand",
    "item_power_treads",
    "item_vladmir",
    "item_manta",--
    "item_butterfly",--
    "item_black_king_bar",--
    "item_aghanims_shard",
    "item_greater_crit",--
    "item_disperser",--
    "item_moon_shard",
    "item_satanic",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {
    "item_magic_wand",
    "item_circlet",
    "item_satanic",
    "item_vladmir"
}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
    Minion.MinionThink(hMinionUnit)
end

local Waveform              = SafeAbility(bot:GetAbilityByName('morphling_waveform'), 'morphling_waveform', 'morphling')
local AdaptiveStrikeAGI     = SafeAbility(bot:GetAbilityByName('morphling_adaptive_strike_agi'), 'morphling_adaptive_strike_agi', 'morphling')
local AdaptiveStrikeSTR     = SafeAbility(bot:GetAbilityByName('morphling_adaptive_strike_str'), 'morphling_adaptive_strike_str', 'morphling')
local AttributeShiftAGI     = SafeAbility(bot:GetAbilityByName('morphling_morph_agi'), 'morphling_morph_agi', 'morphling')
local AttributeShiftSTR     = SafeAbility(bot:GetAbilityByName('morphling_morph_str'), 'morphling_morph_str', 'morphling')
local Morph                 = SafeAbility(bot:GetAbilityByName('morphling_replicate'), 'morphling_replicate', 'morphling')
local MorphReplicate        = SafeAbility(bot:GetAbilityByName('morphling_morph_replicate'), 'morphling_morph_replicate', 'morphling')

local WaveformDesire, WaveformLocation
local AdaptiveStrikeAGIDesire, AdaptiveStrikeAGITarget
local AdaptiveStrikeSTRDesire, AdaptiveStrikeSTRTarget
local AtttributeShiftDesire
local MorphDesire, MorphTarget

local MorphedHeroName = ''

local botTarget
local botHP, botMP
local nAllyHeroes, nEnemyHeroes

local bStrengthForm = false

if bot.IsMorphling == nil then bot.IsMorphling = true end

local nAGIRatio = 1
local nSTRRatio = 1

local AGI_BASE = 24
local STR_BASE = 23
local AGI_GROWTH_RATE = 4.2
local STR_GROWTH_RATE = 2.6

local heroAbilityUsage = {}
local function HandleSpell(spell)
    if spell == nil then return end

    local heroName = SPL.GetSpellHeroName(spell:GetName())

    if heroName == nil then return end

    if not heroAbilityUsage[heroName]
    then
        heroAbilityUsage[heroName] = require(GetScriptDirectory()..'/BotsLib/'..string.gsub(heroName, 'npc_dota_', ''))
    end

    local heroSpells = heroAbilityUsage[heroName]
    if heroSpells and heroSpells.SkillsComplement
    then
        heroSpells.SkillsComplement()
    end
end

local nMorphTime = {0, math.huge}
local nAverageCooldownTime = math.pi

local bGoingOnSomeone
local bRetreating
local bAttacking
function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

    local ctx = AbilityCtx.Build(bot)
	bGoingOnSomeone = ctx.isEngaging
	bRetreating = ctx.isRetreating
	bAttacking = Fu.IsAttacking(bot)

    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = ctx.enemies
    botTarget = ctx.target
    botHP = ctx.hp
    botMP = ctx.mp

    bStrengthForm = bot:GetPrimaryAttribute() == ATTRIBUTE_STRENGTH and true or false

    if bot:GetAbilityInSlot(0) == Waveform then bot.IsMorphling = true else bot.IsMorphling = false end

    if bot:HasModifier('modifier_morphling_replicate_manager') then
        if DotaTime() > nMorphTime[2] + nAverageCooldownTime + (0.25 + 0.1) then
            if bot.IsMorphling == true then
                if bGoingOnSomeone
                and Fu.IsValidHero(botTarget)
                and Fu.IsInRange(bot, botTarget, 900)
                then
                    if (IsGoodToMorphBack(MorphedHeroName, true))
                    or (botHP > 0.8)
                    or (botHP > 0.5 and #nAllyHeroes > #nEnemyHeroes)
                    then
                        bot:Action_UseAbility(MorphReplicate)
                        nMorphTime[1] = DotaTime()
                        return
                    end
                end

                if bRetreating
                and not Fu.IsRealInvisible(bot)
                and IsGoodToMorphBack(MorphedHeroName, false)
                and not Fu.CanCastAbility(Waveform, 3)
                then
                    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
                    if #nInRangeEnemy > 0 and botHP > 0.4 then
                        bot:Action_UseAbility(MorphReplicate)
                        nMorphTime[1] = DotaTime()
                        return
                    end
                end
            end
        end

        -- give 3 seconds to cast any spells
        if DotaTime() < nMorphTime[1] + 3 + (0.25 + 0.1) then
            if bot.IsMorphling == false and Fu.CanCastAbility(MorphReplicate) then
                if nAverageCooldownTime == math.pi then
                    local bCanCastAnAbility = false
                    local count = 0
                    local weightedCooldownSum = 0
                    local totalWeight = 0

                    for i = 0, 7 do
                        local hAbility = bot:GetAbilityInSlot(i)
                        if  hAbility
                        and hAbility ~= MorphReplicate
                        and hAbility:IsTrained()
                        and not hAbility:IsPassive()
                        and string.find(hAbility:GetName(), string.gsub(MorphedHeroName, 'npc_dota_hero_',''))
                        and not string.find(hAbility:GetName(), 'morphling')
                        then
                            if Fu.CanCastAbilitySoon(hAbility, 1.5) then
                                bCanCastAnAbility = true
                            end

                            local nCooldown = hAbility:GetCooldown()
                            if nCooldown > 0 then
                                local weight = 1 / math.sqrt(nCooldown)
                                weightedCooldownSum = weightedCooldownSum + (nCooldown * weight)
                                totalWeight = totalWeight + weight
                                count = count + 1
                            end
                        end
                    end

                    if not bCanCastAnAbility then
                        bot:Action_UseAbility(MorphReplicate)
                        nMorphTime[2] = DotaTime()
                        return
                    end

                    if count > 0 then
                        nAverageCooldownTime = Max(weightedCooldownSum / totalWeight, math.pi)
                    end
                end

                for i = 0, 6 do
                    local hAbility = bot:GetAbilityInSlot(i)
                    if hAbility ~= nil and hAbility ~= MorphReplicate then
                        HandleSpell(hAbility)
                    end
                end
            end
        else
            local bShouldReplicateToMorph = true

            if bot:HasModifier('modifier_terrorblade_metamorphosis')
            or bot:HasModifier('modifier_terrorblade_metamorphosis_transform')
            then
                if botHP > 0.4 and bGoingOnSomeone then
                    bShouldReplicateToMorph = false
                end
            end

            if MorphedHeroName == 'npc_dota_hero_obsidian_destroyer' then
                local hAbility1 = bot:GetAbilityInSlot(0)
                local hAbility3 = bot:GetAbilityInSlot(2)
                if  (hAbility1 and hAbility1:IsTrained() and hAbility1:GetLevel() >= 3)
                and (hAbility3 and hAbility3:IsTrained() and hAbility1:GetLevel() >= 3)
                then
                    if bGoingOnSomeone then
                        bShouldReplicateToMorph = false
                    end
                end
            end

            if bShouldReplicateToMorph then
                if bot.IsMorphling == false and Fu.CanCastAbility(MorphReplicate) then
                    bot:Action_UseAbility(MorphReplicate)
                    nMorphTime[2] = DotaTime()
                    return
                end
            end
        end
    else
        nAverageCooldownTime = math.pi
        nMorphTime = {0, math.huge}
        MorphedHeroName = ''
    end

    if bot.IsMorphling then
        X.SetRatios()

        AtttributeShiftDesire, Type = X.ConsiderAtttributeShift()
        if AtttributeShiftDesire > 0
        then
            if Type == 'agi'
            then
                bot:Action_UseAbility(AttributeShiftAGI)
            else
                bot:Action_UseAbility(AttributeShiftSTR)
            end
            return
        end

        WaveformDesire, WaveformLocation = X.ConsiderWaveform()
        if WaveformDesire > 0
        then
            Fu.SetQueuePtToINT(bot, false)
            bot:ActionQueue_UseAbilityOnLocation(Waveform, WaveformLocation)
            return
        end

        AdaptiveStrikeSTRDesire, AdaptiveStrikeSTRTarget = X.ConsiderAdaptiveStrikeSTR()
        if AdaptiveStrikeSTRDesire > 0
        then
            bot:Action_UseAbilityOnEntity(AdaptiveStrikeSTR, AdaptiveStrikeSTRTarget)
            return
        end

        AdaptiveStrikeAGIDesire, AdaptiveStrikeAGITarget = X.ConsiderAdaptiveStrikeAGI()
        if AdaptiveStrikeAGIDesire > 0
        then
            Fu.SetQueuePtToINT(bot, false)
            bot:ActionQueue_UseAbilityOnEntity(AdaptiveStrikeAGI, AdaptiveStrikeAGITarget)
            return
        end

        MorphDesire, MorphTarget = X.ConsiderMorph()
        if MorphDesire > 0
        then
            bot:Action_UseAbilityOnEntity(Morph, MorphTarget)
            nMorphTime[1] = DotaTime()
            MorphedHeroName = MorphTarget:GetUnitName()
            return
        end
    end
end

function X.ConsiderWaveform()
    if not Fu.CanCastAbility(Waveform) or bot:IsRooted() then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Waveform:GetCastRange())
	local nCastPoint = Waveform:GetCastPoint()
	local nSpeed = Waveform:GetSpecialValueInt('speed')
    local nDamage = Waveform:GetSpecialValueInt('#AbilityDamage')
    local nRadius = Waveform:GetSpecialValueInt('width')
    local nManaCost = Waveform:GetManaCost()
    local nManaAfter = Fu.GetManaAfter(nManaCost)
    local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {AdaptiveStrikeAGI, Morph})
    local fManaThreshold2 = Fu.GetManaThreshold(bot, nManaCost, {Waveform, AdaptiveStrikeAGI, Morph})

    local vTeamFountain = Fu.GetTeamFountain()
    local vLocationTeamFountain = Fu.VectorTowards(bot:GetLocation(), vTeamFountain, nCastRange)

	if Fu.IsStuck(bot) then
		return BOT_ACTION_DESIRE_HIGH, vLocationTeamFountain
	end

    if not Fu.IsRealInvisible(bot) and not bot:IsMagicImmune() then
        if (Fu.IsStunProjectileIncoming(bot, 500))
        or (not bot:HasModifier('modifier_sniper_assassinate') and Fu.IsWillBeCastUnitTargetSpell(bot, 400))
        then
            return BOT_ACTION_DESIRE_HIGH, vLocationTeamFountain
        end
    end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and GetUnitToLocationDistance(botTarget, Fu.GetEnemyFountain()) > 1200
        and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange())
		and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local bStronger = Fu.WeAreStronger(bot, 1200)

            if #nAllyHeroes >= #nEnemyHeroes and bStronger then
                local eta = (GetUnitToUnitDistance(bot, botTarget) / nSpeed) + nCastPoint
                local vLocation = Fu.VectorAway(botTarget:GetLocation(), bot:GetLocation(), 300)
                local bTowerNearby = botTarget:HasModifier('modifier_tower_aura_bonus')

                if GetUnitToLocationDistance(bot, vLocation) <= nCastRange then
                    if IsLocationPassable(vLocation) then
                        if Fu.IsInLaningPhase() then
                            if not bTowerNearby or Fu.WillKillTarget(botTarget, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
                                return BOT_ACTION_DESIRE_HIGH, vLocation
                            end
                        else
                            return BOT_ACTION_DESIRE_HIGH, vLocation
                        end
                    end
                end

                if GetUnitToLocationDistance(bot, vLocation) > nCastRange and GetUnitToLocationDistance(bot, vLocation) < nCastRange + 350 then
                    if IsLocationPassable(vLocation) then
                        if Fu.IsInLaningPhase() then
                            if not bTowerNearby or Fu.WillKillTarget(botTarget, nDamage, DAMAGE_TYPE_MAGICAL, eta) then
                                return BOT_ACTION_DESIRE_HIGH, vLocation
                            end
                        else
                            return BOT_ACTION_DESIRE_HIGH, vLocation
                        end
                    end
                end
            end
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if Fu.IsValidHero(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            then
                if (Fu.IsChasingTarget(enemyHero, bot) and not Fu.IsInTeamFight(bot, 1200) and bot:WasRecentlyDamagedByAnyHero(3.0))
                or (#nEnemyHeroes > #nAllyHeroes)
                or (botHP < 0.65 and bot:WasRecentlyDamagedByAnyHero(3.0))
                then
                    return BOT_ACTION_DESIRE_HIGH, vLocationTeamFountain
                end
			end
        end
	end

    local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange + 300, 1600), true)

	if Fu.IsPushing(bot) and bAttacking and nManaAfter > fManaThreshold2 and nManaAfter > 0.5 and #nAllyHeroes <= 3 and #nEnemyHeroes == 0 then
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if nLocationAoE.count >= 4 and IsLocationPassable(nLocationAoE.targetloc) then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

	if Fu.IsDefending(bot) and bAttacking and nManaAfter > fManaThreshold1 and #nEnemyHeroes == 0 then
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if nLocationAoE.count >= 4 and IsLocationPassable(nLocationAoE.targetloc) then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
	end

	if Fu.IsFarming(bot) and nManaAfter > fManaThreshold2 and #nEnemyHeroes == 0 and not Fu.IsLateGame() then
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 3)
                or (nLocationAoE.count >= 2 and creep:IsAncientCreep())
                then
                    local vLocation = Fu.VectorAway(nLocationAoE.targetloc, bot:GetLocation(), 350)
                    if IsLocationPassable(vLocation) then
                        return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                    end
                end
            end
        end
	end

	if Fu.IsDoingRoshan(bot) and nManaAfter > fManaThreshold2 + 0.15 and nManaAfter > 0.5 then
		local roshLoc = Fu.GetCurrentRoshanLocation()
        if GetUnitToLocationDistance(bot, roshLoc) > 2000 and #nEnemyHeroes == 0 and IsLocationPassable(roshLoc) then
            return BOT_ACTION_DESIRE_HIGH, Fu.VectorTowards(bot:GetLocation(), roshLoc, nCastRange)
        end
    end

    if Fu.IsDoingTormentor(bot) and nManaAfter > fManaThreshold2 + 0.15 and nManaAfter > 0.5 then
		local tormentorLoc = Fu.GetTormentorLocation()
        if GetUnitToLocationDistance(bot, tormentorLoc) > 2000 and #nEnemyHeroes == 0 and IsLocationPassable(tormentorLoc) then
            return BOT_ACTION_DESIRE_HIGH, Fu.VectorTowards(bot:GetLocation(), tormentorLoc, nCastRange)
        end
    end

    local nLocationAoE = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, nRadius, 0, nDamage)
    if nLocationAoE.count >= 5 and #nEnemyHeroes <= 1 and nManaAfter > fManaThreshold2 then
        return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
    end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderAdaptiveStrikeAGI()
    if not Fu.CanCastAbility(AdaptiveStrikeAGI) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, AdaptiveStrikeAGI:GetCastRange())
    local nCastPoint = AdaptiveStrikeAGI:GetCastPoint()
	local nMinAGI = AdaptiveStrikeAGI:GetSpecialValueFloat('damage_min')
	local nMaxAGI = AdaptiveStrikeAGI:GetSpecialValueFloat('damage_max')
	local nCurrAGI = bot:GetAttributeValue(ATTRIBUTE_AGILITY)
	local nCurrSTR = bot:GetAttributeValue(ATTRIBUTE_STRENGTH)
	local nDamage = AdaptiveStrikeAGI:GetSpecialValueInt('damage_base')
    local nSpeed = AdaptiveStrikeAGI:GetSpecialValueInt('projectile_speed')
    local nManaCost = AdaptiveStrikeAGI:GetManaCost()
    local nManaAfter = Fu.GetManaAfter(nManaCost)
    local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Waveform, Morph})
    local fManaThreshold2 = Fu.GetManaThreshold(bot, nManaCost, {Waveform, AdaptiveStrikeAGI, Morph})
    local bUsingMax = nCurrAGI > nCurrSTR * 1.5

	if bUsingMax then
		nDamage = nDamage + nMaxAGI * nCurrAGI
	else
		nDamage = nDamage + nMinAGI * nCurrAGI
	end

	for _, enemyHero in pairs(nEnemyHeroes) do
        if  Fu.IsValidHero(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        then
            local nDelay = (GetUnitToUnitDistance(bot, enemyHero) / nSpeed) + nCastPoint
            if nCurrSTR > nCurrAGI * 1.5 then
                if enemyHero:HasModifier('modifier_teleporting') then
                    if Fu.GetModifierTime(enemyHero, 'modifier_teleporting') > nDelay then
                        return BOT_ACTION_DESIRE_HIGH, enemyHero
                    end
                elseif enemyHero:IsChanneling() and nManaAfter > fManaThreshold2 and not Fu.IsRealInvisible(bot) and not bRetreating then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end

            if Fu.WillKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL, nDelay)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end
        end
	end

    if Fu.IsInTeamFight(bot, 1200) and bUsingMax then
        local hTarget = nil
        local hTargetScore = 0
        for _, enemyHero in pairs(nEnemyHeroes) do
            if  Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            and not enemyHero:HasModifier('modifier_troll_warlord_battle_trance')
            then
                if Fu.IsInEtherealForm(enemyHero) then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end

                local enemyHeroDamage = enemyHero:GetActualIncomingDamage(nDamage, DAMAGE_TYPE_MAGICAL) / enemyHero:GetHealth()
                if enemyHeroDamage > hTargetScore then
                    hTarget = enemyHero
                    hTargetScore = enemyHeroDamage
                end
            end
        end

        if hTarget then
            return BOT_ACTION_DESIRE_HIGH, hTarget
        end
    end

	if bGoingOnSomeone and bUsingMax then
		if  Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.GetHP(botTarget) < 0.6
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_oracle_false_promise_timer')
        and not botTarget:HasModifier('modifier_ursa_enrage')
		then
            return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

    if bRetreating and not Fu.IsRealInvisible(bot) and not bUsingMax then
		for _, enemyHero in pairs(nEnemyHeroes) do
			if  Fu.IsValidHero(enemyHero)
            and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
			then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
        end
	end

    local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange + 300, 1600), true)

    if Fu.IsFarming(bot) and nManaAfter > fManaThreshold1 and (bStrengthForm or bUsingMax) then
        local creepTarget = nil
        local creepTargetScore = 0
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            and Fu.CanCastOnTargetAdvanced(creep)
            and Fu.GetHP(creep) > 0.4
            then
                local creepScore = creep:GetActualIncomingDamage(nDamage, DAMAGE_TYPE_MAGICAL) / creep:GetHealth()
                if creepScore > creepTargetScore then
                    creepTarget = creep
                    creepTargetScore = creepScore
                end
            end
        end

        if creepTarget then
            return BOT_ACTION_DESIRE_HIGH, creepTarget
        end
    end

    if Fu.IsLaning(bot) and Fu.IsInLaningPhase() and nManaAfter > fManaThreshold1 then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange, true)

		for _, creep in pairs(nEnemyLaneCreeps) do
			if  Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            and Fu.CanCastOnTargetAdvanced(creep)
			and (not bStrengthForm and (Fu.IsKeyWordUnit('ranged', creep)
                    or Fu.IsKeyWordUnit('siege', creep)
                    or Fu.IsKeyWordUnit('flagbearer', creep))
                or nManaAfter > 0.5)
			then
                local nDelay = (GetUnitToUnitDistance(bot, creep) / nSpeed) + nCastPoint
                if Fu.WillKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL, nDelay) then
                    local nLocationAoE = bot:FindAoELocation(true, true, creep:GetLocation(), 0, 600, 0, 0)
                    if nLocationAoE.count > 0 or Fu.IsUnitTargetedByTower(creep, false) then
                        return BOT_ACTION_DESIRE_HIGH, creep
                    end
                end
			end
		end
	end

	if Fu.IsDoingRoshan(bot) and bUsingMax then
		if  Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.CanBeAttacked(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
        and bAttacking
        and nManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

    if Fu.IsDoingTormentor(bot) and bUsingMax then
		if  Fu.IsTormentor(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and nManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAdaptiveStrikeSTR()
    if not Fu.CanCastAbility(AdaptiveStrikeSTR)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, AdaptiveStrikeSTR:GetCastRange())

    local nEnemyHeroes = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
	for _, enemyHero in pairs(nEnemyHeroes)
	do
        if  Fu.IsValidHero(enemyHero)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and enemyHero:IsChanneling()
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero
        end
	end

    if  bRetreating
    and not Fu.IsRealInvisible(bot)
    and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
	then
        local nInRangeEnemy = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nInRangeEnemy)
        do
			if  Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
			and not Fu.IsDisabled(enemyHero)
			then
				local nInRangeAlly = enemyHero:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
				local nTargetInRangeAlly = enemyHero:GetNearbyHeroes(1200, false, BOT_MODE_NONE)

				if  nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
				and ((#nTargetInRangeAlly > #nInRangeAlly)
					or bot:WasRecentlyDamagedByAnyHero(1.5))
				then
					return BOT_ACTION_DESIRE_HIGH, enemyHero
				end
			end
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderAtttributeShift()
    if not Fu.CanCastAbility(AttributeShiftAGI)
    or not Fu.CanCastAbility(AttributeShiftSTR)
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local botNetworth = bot:GetNetWorth()
    local botAttackRange = bot:GetAttackRange()
    local bToggleState__AGI = AttributeShiftAGI:GetToggleState()
    local bToggleState__STR = AttributeShiftSTR:GetToggleState()

    local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
    local nEnemyTowers = bot:GetNearbyTowers(1100, true)
    local bStronger = Fu.WeAreStronger(bot, 1600)

    local nCurrAGI = bot:GetAttributeValue(ATTRIBUTE_AGILITY)
	local nCurrSTR = bot:GetAttributeValue(ATTRIBUTE_STRENGTH)
    local nCurrAGIRatio = nCurrAGI / nCurrSTR * 1.5

    if (bRetreating and not Fu.IsRealInvisible(bot) and bot:WasRecentlyDamagedByAnyHero(5.0)) then
        if bot:WasRecentlyDamagedByAnyHero(3.0) then
            if bToggleState__STR == false then
                return BOT_ACTION_DESIRE_HIGH, 'str'
            end
            return BOT_ACTION_DESIRE_NONE, ''
        end

        if bot:HasModifier('modifier_fountain_aura_buff') and #nInRangeEnemy == 0 then
            if nAGIRatio < 0.5 then
                if bToggleState__AGI == false then
                    return BOT_ACTION_DESIRE_HIGH, 'agi'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            else
                if nAGIRatio > 0.5 + 0.02 then
                    if bToggleState__STR == false then
                        return BOT_ACTION_DESIRE_HIGH, 'str'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                end
            end
            return BOT_ACTION_DESIRE_NONE, ''
        end

        if bToggleState__STR == true then
            return BOT_ACTION_DESIRE_HIGH, 'str'
        end
        return BOT_ACTION_DESIRE_NONE, ''
    end

    if bStrengthForm then
        if botNetworth > 30000 then
            if nCurrAGIRatio < 1.0 then
                if bToggleState__AGI == false then
                    return BOT_ACTION_DESIRE_HIGH, 'agi'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            else
                if nCurrAGIRatio > 1.0 + 0.02 then
                    if bToggleState__STR == false then
                        return BOT_ACTION_DESIRE_HIGH, 'str'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                end
            end
        else
            local ratio = Fu.IsInLaningPhase() and 0.4 or 0.6
            if botNetworth > 20000 then
                ratio = 0.5
            end

            if nAGIRatio < ratio then
                if bToggleState__AGI == false then
                    return BOT_ACTION_DESIRE_HIGH, 'agi'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            end

            if nAGIRatio > ratio + 0.02 then
                if bToggleState__STR == false then
                    return BOT_ACTION_DESIRE_HIGH, 'str'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            end
        end
    else
        if bGoingOnSomeone then
            if Fu.IsValidHero(botTarget)
            and (Fu.CanBeAttacked(botTarget) or #nInRangeEnemy > 1)
            and Fu.IsInRange(bot, botTarget, botAttackRange + 300)
            and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local ratio = RemapValClamped(botNetworth, 5000, 25000, 0.5, 0.90)

                if #nInRangeEnemy > #nInRangeAlly and not bStronger then
                    ratio = ratio * 0.75
                end

                if nAGIRatio < ratio and botHP > 0.3 then
                    if bToggleState__AGI == false then
                        return BOT_ACTION_DESIRE_HIGH, 'agi'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                else
                    if nAGIRatio > ratio + 0.02 then
                        if bToggleState__STR == false then
                            return BOT_ACTION_DESIRE_HIGH, 'str'
                        end
                        return BOT_ACTION_DESIRE_NONE, ''
                    end
                end
            end
        end

        if Fu.IsPushing(bot) or Fu.IsDefending(bot) then
            local ratio = RemapValClamped(botNetworth, 5000, 20000, 0.5, 0.75)
            if #nInRangeEnemy > #nInRangeAlly and not bStronger then
                ratio = ratio * 0.75
            end

            if nAGIRatio < ratio and botHP > 0.3 then
                if bToggleState__AGI == false then
                    return BOT_ACTION_DESIRE_HIGH, 'agi'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            else
                if nAGIRatio > ratio + 0.02 then
                    if bToggleState__STR == false then
                        return BOT_ACTION_DESIRE_HIGH, 'str'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                end
            end
        end

        if Fu.IsLaning(bot) and Fu.IsInLaningPhase() then
            local ratio = RemapValClamped(bot:GetLevel(), 1, 6, 0.55, 0.6)

            if nAGIRatio < ratio then
                if bToggleState__AGI == false then
                    return BOT_ACTION_DESIRE_HIGH, 'agi'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            else
                if nAGIRatio > ratio + 0.02 then
                    if bToggleState__STR == false then
                        return BOT_ACTION_DESIRE_HIGH, 'str'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                end
            end
        end

        if Fu.IsFarming(bot) and botHP > 0.3 then
            local ratio = RemapValClamped(botNetworth, 5000, 20000, 0.55, 0.85)
            if nAGIRatio < ratio then
                if bToggleState__AGI == false then
                    return BOT_ACTION_DESIRE_HIGH, 'agi'
                end
                return BOT_ACTION_DESIRE_NONE, ''
            else
                if nAGIRatio > ratio + 0.02 then
                    if bToggleState__STR == false then
                        return BOT_ACTION_DESIRE_HIGH, 'str'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                end
            end
        end

        if Fu.IsDoingRoshan(bot) or Fu.IsDoingTormentor(bot) then
            if (Fu.IsRoshan(botTarget) or Fu.IsTormentor(botTarget))
            and Fu.CanBeAttacked(botTarget)
            and Fu.IsInRange(bot, botTarget, 1000)
            then
                local ratio = RemapValClamped(botNetworth, 5000, 20000, 0.5, 0.85)
                if nAGIRatio < ratio and botHP > 0.35 then
                    if bToggleState__AGI == false then
                        return BOT_ACTION_DESIRE_HIGH, 'agi'
                    end
                    return BOT_ACTION_DESIRE_NONE, ''
                else
                    if nAGIRatio > ratio + 0.02 then
                        if bToggleState__STR == false then
                            return BOT_ACTION_DESIRE_HIGH, 'str'
                        end
                        return BOT_ACTION_DESIRE_NONE, ''
                    end
                end
            end
        end
    end

    if bToggleState__STR == true then
        return BOT_ACTION_DESIRE_HIGH, 'str'
    end

    if bToggleState__AGI == true then
        return BOT_ACTION_DESIRE_HIGH, 'agi'
    end

    return BOT_ACTION_DESIRE_NONE, ''
end

function X.ConsiderMorph()
    if not Fu.CanCastAbility(Morph)
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Morph:GetCastRange())

    if Fu.IsInTeamFight(bot, 1200) then
        local target = nil
        local targetScore = 0
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not string.find(enemyHero:GetUnitName(), 'huskar')
            and not string.find(enemyHero:GetUnitName(), 'invoker')
            then
                local enemyHeroScore = enemyHero:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_MAGICAL)
                                     + enemyHero:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_PURE)
                if enemyHeroScore > targetScore then
                    target = enemyHero
                    targetScore = enemyHeroScore
                end
            end
        end

        if target then
            return BOT_ACTION_DESIRE_HIGH, target
        end
    end

	if bGoingOnSomeone then
        if  Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.IsInRange(bot, botTarget, 1200)
        and Fu.GetHP(botTarget) < 0.5
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_oracle_false_promise_timer')
        then
            local fDuration = 6.0
            local estimatedDamage = Fu.GetTotalEstimatedDamageToTarget(nAllyHeroes, botTarget, fDuration)

            if  (estimatedDamage > (botTarget:GetHealth() + botTarget:GetHealthRegen() * fDuration))
            and (#nAllyHeroes >= #nEnemyHeroes)
            and (botHP > 0.4)
            then
                local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
                if (not Fu.IsLateGame() and #nInRangeEnemy > 0)
                or (#nInRangeEnemy > 1)
                then
                    local target = nil
                    local targetScore = -math.huge
                    for _, enemyHero in pairs(nInRangeEnemy) do
                        if  Fu.IsValidHero(enemyHero)
                        and Fu.CanCastOnTargetAdvanced(enemyHero)
                        and not enemyHero:HasModifier('modifier_skeleton_king_reincarnation_scepter_active')
                        and not enemyHero:HasModifier('modifier_item_helm_of_the_undying_active')
                        and not string.find(enemyHero:GetUnitName(), 'huskar')
                        and not string.find(enemyHero:GetUnitName(), 'invoker')
                        then
                            local enemyHeroScore = enemyHero:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_MAGICAL)
                                                 + enemyHero:GetEstimatedDamageToTarget(false, bot, 5.0, DAMAGE_TYPE_PURE)
                            local engageScore = GetMorphEngageScore(enemyHero:GetUnitName()) * enemyHeroScore

                            if engageScore > targetScore then
                                target = enemyHero
                                targetScore = engageScore
                            end
                        end
                    end

                    if target ~= nil then
                        return BOT_ACTION_DESIRE_HIGH, target
                    end
                end
            end
        end
	end

    if  bRetreating
    and not Fu.IsRealInvisible(bot)
    and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH
    and bot:WasRecentlyDamagedByAnyHero(3.0)
    and not Fu.CanCastAbility(Waveform, 3.0)
    and botHP > 0.5
	then
        local target = nil
        local targetScore = 0

        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nCastRange)
            and Fu.CanCastOnTargetAdvanced(enemyHero)
            then
                local score = GetMorphRetreatScore(enemyHero:GetUnitName())
                if score > 0 and score > targetScore then
                    target = enemyHero
                    targetScore = score
                end
            end
        end

        if target ~= nil then
            return BOT_ACTION_DESIRE_HIGH, target
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.SetRatios()
    local count = 0
    local nAddedAGI = 0
    local nAddedSTR = 0

    local primaryAttribute = bot:GetPrimaryAttribute()

    local itemIndex = {0,1,2,3,4,5,16,17}
    for i = 1, #itemIndex do
        local hItem = bot:GetItemInSlot(itemIndex[i])
        if hItem then
            local sItemName = hItem:GetName()
            if string.find(sItemName, 'item_power_treads') then
                local bonusStats = hItem:GetSpecialValueInt('bonus_stat')
                local treadsState = hItem:GetPowerTreadsStat()
                if treadsState == ATTRIBUTE_AGILITY then
                    nAddedAGI = nAddedAGI + bonusStats
                elseif treadsState == ATTRIBUTE_STRENGTH then
                    nAddedSTR = nAddedSTR + bonusStats
                end
            end

            if string.find(sItemName, 'evolved') then
                local primaryStat = hItem:GetSpecialValueInt('primary_stat')
                if primaryAttribute == ATTRIBUTE_AGILITY then
                    nAddedAGI = nAddedAGI + primaryStat
                elseif primaryAttribute == ATTRIBUTE_STRENGTH then
                    nAddedSTR = nAddedSTR + primaryStat
                end
            end

            local allStats = hItem:GetSpecialValueInt('bonus_all_stats')

			nAddedAGI = nAddedAGI + hItem:GetSpecialValueInt('bonus_agility') + allStats
            nAddedSTR = nAddedSTR + hItem:GetSpecialValueInt('bonus_strength') + allStats
        end
    end

    count = 0
    if bot:GetLevel() >= 26 then count = 7
    elseif bot:GetLevel() >= 24 then count = 6
    elseif bot:GetLevel() >= 23 then count = 5
    elseif bot:GetLevel() >= 22 then count = 4
    elseif bot:GetLevel() >= 21 then count = 3
    elseif bot:GetLevel() >= 19 then count = 2
    elseif bot:GetLevel() >= 17 then count = 1
    end

    if primaryAttribute == ATTRIBUTE_AGILITY then
        nAddedAGI = nAddedAGI + count * 3 + count * 2
        nAddedSTR = nAddedSTR + count * 2
    elseif primaryAttribute == ATTRIBUTE_STRENGTH then
        nAddedAGI = nAddedAGI + count * 2
        nAddedSTR = nAddedSTR + count * 3 + count * 2
    end

    local talent__AGI = bot:GetAbilityInSlot(14)
	local talent__STR = bot:GetAbilityInSlot(16)

    if talent__AGI ~= nil and talent__AGI:IsTrained() then
        nAddedAGI = nAddedAGI + talent__AGI:GetSpecialValueInt('value')
    end

    if talent__STR ~= nil and talent__STR:IsTrained() then
        nAddedSTR = nAddedSTR + talent__STR:GetSpecialValueInt('value')
    end

    local nBaseAGI = AGI_BASE + AGI_GROWTH_RATE * (bot:GetLevel() - 1)
    local nBaseSTR = STR_BASE + STR_GROWTH_RATE * (bot:GetLevel() - 1)

    local nTotalAGI = bot:GetAttributeValue(ATTRIBUTE_AGILITY)
    local nTotalSTR = bot:GetAttributeValue(ATTRIBUTE_STRENGTH)

    local nShiftedAGI = nTotalAGI - nBaseAGI
    local nShiftedSTR = nTotalSTR - nBaseSTR

    local nEffAGI = nBaseAGI + nShiftedAGI - nAddedAGI
    local nEffSTR = nBaseSTR + nShiftedSTR - nAddedSTR

    nAGIRatio = nEffAGI / (nEffAGI + nEffSTR)
    nSTRRatio = nEffSTR / (nEffAGI + nEffSTR)
end

-- #### -----------------------
local function CreateHeroData(sEngage, sRetreat, bEngageBack, bRetreatBack)
    return {
        scoreEngage = sEngage,
        scoreRetreat = sRetreat,
        goodToEngageBack = bEngageBack,
        goodToRetreatBack = bRetreatBack,
    }
end

local hHeroList = {
    ['npc_dota_hero_abaddon'] = CreateHeroData(0.3, 0.1, false, false),
    ['npc_dota_hero_abyssal_underlord'] = CreateHeroData(0.8, 0.5, true, true),
    ['npc_dota_hero_alchemist'] = CreateHeroData(0.4, 0.2, false, false),
    ['npc_dota_hero_ancient_apparition'] = CreateHeroData(0.7, 0.4, true, false),
    ['npc_dota_hero_antimage'] = CreateHeroData(0.5, 0.9, true, true),
    ['npc_dota_hero_arc_warden'] = CreateHeroData(0.4, 0.1, true, false),
    ['npc_dota_hero_axe'] = CreateHeroData(0.3, 0.5, false, false),
    ['npc_dota_hero_bane'] = CreateHeroData(0.8, 0.5, true, true),
    ['npc_dota_hero_batrider'] = CreateHeroData(0.3, 0.3, false, false),
    ['npc_dota_hero_beastmaster'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_bloodseeker'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_bounty_hunter'] = CreateHeroData(0.2, 0.6, false, true),
    ['npc_dota_hero_brewmaster'] = CreateHeroData(0.3, 0.3, false, false),
    ['npc_dota_hero_bristleback'] = CreateHeroData(0.4, 0.2, false, false),
    ['npc_dota_hero_broodmother'] = CreateHeroData(0.5, 0.1, false, false),
    ['npc_dota_hero_centaur'] = CreateHeroData(0.4, 0.3, true, false),
    ['npc_dota_hero_chaos_knight'] = CreateHeroData(0.6, 0.5, true, false),
    ['npc_dota_hero_chen'] = CreateHeroData(0.4, 0.1, false, false),
    ['npc_dota_hero_clinkz'] = CreateHeroData(0.3, 0.2, false, false),
    ['npc_dota_hero_crystal_maiden'] = CreateHeroData(0.8, 0.8, true, true),
    ['npc_dota_hero_dark_seer'] = CreateHeroData(0.2, 0.5, true, true),
    ['npc_dota_hero_dark_willow'] = CreateHeroData(0.6, 0.5, true, true),
    ['npc_dota_hero_dawnbreaker'] = CreateHeroData(0.6, 0.4, true, false),
    ['npc_dota_hero_dazzle'] = CreateHeroData(0.8, 0.2, true, false),
    ['npc_dota_hero_death_prophet'] = CreateHeroData(0.5, 0.2, true, false),
    ['npc_dota_hero_disruptor'] = CreateHeroData(0.8, 0.5, true, true),
    ['npc_dota_hero_doom_bringer'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_dragon_knight'] = CreateHeroData(0.6, 0.8, true, true),
    ['npc_dota_hero_drow_ranger'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_earth_spirit'] = CreateHeroData(0.8, 1, true, true),
    ['npc_dota_hero_earthshaker'] = CreateHeroData(1, 1, true, true),
    ['npc_dota_hero_elder_titan'] = CreateHeroData(0.1, 0.1, false, false),
    ['npc_dota_hero_ember_spirit'] = CreateHeroData(0.5, 0.4, true, true),
    ['npc_dota_hero_enchantress'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_enigma'] = CreateHeroData(0.2, 0.5, false, false),
    ['npc_dota_hero_faceless_void'] = CreateHeroData(0.5, 0.5, true, true),
    ['npc_dota_hero_furion'] = CreateHeroData(0.5, 0.5, true, true),
    ['npc_dota_hero_grimstroke'] = CreateHeroData(0.8, 0.4, true, true),
    ['npc_dota_hero_gyrocopter'] = CreateHeroData(0.6, 0.4, true, false),
    ['npc_dota_hero_hoodwink'] = CreateHeroData(0.5, 0.3, true, false),
    ['npc_dota_hero_huskar'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_invoker'] = CreateHeroData(0.5, 0.3, true, false),
    ['npc_dota_hero_jakiro'] = CreateHeroData(0.6, 0.6, true, false),
    ['npc_dota_hero_juggernaut'] = CreateHeroData(0.8, 0.3, true, true),
    ['npc_dota_hero_keeper_of_the_light'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_kunkka'] = CreateHeroData(0.4, 0.4, true, true),
    ['npc_dota_hero_legion_commander'] = CreateHeroData(0.6, 0.4, true, true),
    ['npc_dota_hero_leshrac'] = CreateHeroData(0.6, 0.4, true, true),
    ['npc_dota_hero_lich'] = CreateHeroData(0.7, 0.2, true, false),
    ['npc_dota_hero_life_stealer'] = CreateHeroData(0.8, 0.4, true, true),
    ['npc_dota_hero_lina'] = CreateHeroData(0.4, 0.2, true, true),
    ['npc_dota_hero_lion'] = CreateHeroData(1, 1, true, true),
    ['npc_dota_hero_lone_druid'] = CreateHeroData(0.1, 0.1, false, false),
    ['npc_dota_hero_luna'] = CreateHeroData(0.4, 0.2, false, false),
    ['npc_dota_hero_lycan'] = CreateHeroData(0.7, 0.2, true, false),
    ['npc_dota_hero_magnataur'] = CreateHeroData(0.4, 0.7, true, true),
    ['npc_dota_hero_marci'] = CreateHeroData(0.3, 0.3, false, false),
    ['npc_dota_hero_mars'] = CreateHeroData(0.7, 0.4, true, true),
    ['npc_dota_hero_medusa'] = CreateHeroData(0.1, 0.2, true, false),
    ['npc_dota_hero_meepo'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_mirana'] = CreateHeroData(0.3, 0.7, false, true),
    ['npc_dota_hero_monkey_king'] = CreateHeroData(0.4, 0.4, true, false),
    ['npc_dota_hero_muerta'] = CreateHeroData(0.5, 0.3, true, false),
    ['npc_dota_hero_naga_siren'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_necrolyte'] = CreateHeroData(0.2, 0.1, true, true),
    ['npc_dota_hero_nevermore'] = CreateHeroData(0.2, 0.1, true, false),
    ['npc_dota_hero_night_stalker'] = CreateHeroData(0.5, 0.2, true, false),
    ['npc_dota_hero_nyx_assassin'] = CreateHeroData(0.6, 0.6, true, true),
    ['npc_dota_hero_obsidian_destroyer'] = CreateHeroData(0.8, 0.8, true, true),
    ['npc_dota_hero_ogre_magi'] = CreateHeroData(0.8, 0.7, true, true),
    ['npc_dota_hero_omniknight'] = CreateHeroData(0.3, 0.3, true, false),
    ['npc_dota_hero_oracle'] = CreateHeroData(0.3, 0.3, true, false),
    ['npc_dota_hero_pangolier'] = CreateHeroData(0.5, 0.5, true, true),
    ['npc_dota_hero_phantom_lancer'] = CreateHeroData(0.1, 0.3, false, true),
    ['npc_dota_hero_phantom_assassin'] = CreateHeroData(0.3, 0.3, false, true),
    ['npc_dota_hero_phoenix'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_primal_beast'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_puck'] = CreateHeroData(0.6, 0.5, true, true),
    ['npc_dota_hero_pudge'] = CreateHeroData(0.5, 0.1, true, false),
    ['npc_dota_hero_pugna'] = CreateHeroData(0.4, 0.1, true, true),
    ['npc_dota_hero_queenofpain'] = CreateHeroData(0.9, 0.9, true, true),
    ['npc_dota_hero_rattletrap'] = CreateHeroData(0.2, 0.2, true, false),
    ['npc_dota_hero_razor'] = CreateHeroData(0.8, 0.2, true, false),
    ['npc_dota_hero_riki'] = CreateHeroData(0.2, 0.2, true, true),
    ['npc_dota_hero_ringmaster'] = CreateHeroData(0.4, 0.1, false, false),
    ['npc_dota_hero_rubick'] = CreateHeroData(0.3, 0.5, false, true),
    ['npc_dota_hero_sand_king'] = CreateHeroData(1, 1, true, true),
    ['npc_dota_hero_shadow_demon'] = CreateHeroData(0.8, 0.5, true, false),
    ['npc_dota_hero_shadow_shaman'] = CreateHeroData(0.9, 0.8, true, true),
    ['npc_dota_hero_shredder'] = CreateHeroData(0.4, 0.8, true, true),
    ['npc_dota_hero_silencer'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_skeleton_king'] = CreateHeroData(0.2, 0.3, false, false),
    ['npc_dota_hero_skywrath_mage'] = CreateHeroData(0.5, 0.1, true, false),
    ['npc_dota_hero_slardar'] = CreateHeroData(0.5, 0.5, true, true),
    ['npc_dota_hero_slark'] = CreateHeroData(0.7, 0.7, true, true),
    ["npc_dota_hero_snapfire"] = CreateHeroData(0.5, 0.5, true, false),
    ['npc_dota_hero_sniper'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_spectre'] = CreateHeroData(0.1, 0.1, false, false),
    ['npc_dota_hero_spirit_breaker'] = CreateHeroData(0.5, 0.5, true, true),
    ['npc_dota_hero_storm_spirit'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_sven'] = CreateHeroData(0.5, 0.5, true, true),
    ['npc_dota_hero_techies'] = CreateHeroData(0.3, 0.2, false, false),
    ['npc_dota_hero_templar_assassin'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_terrorblade'] = CreateHeroData(0.5, 0.1, false, false),
    ['npc_dota_hero_tidehunter'] = CreateHeroData(0.3, 0.3, false, false),
    ['npc_dota_hero_tinker'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_tiny'] = CreateHeroData(0.9, 0.7, true, true),
    ['npc_dota_hero_treant'] = CreateHeroData(0.3, 0.2, false, false),
    ['npc_dota_hero_troll_warlord'] = CreateHeroData(0.2, 0.2, false, false),
    ['npc_dota_hero_tusk'] = CreateHeroData(0.3, 0.6, false, true),
    ['npc_dota_hero_undying'] = CreateHeroData(0.1, 0.1, false, false),
    ['npc_dota_hero_ursa'] = CreateHeroData(0.5, 0.3, true, false),
    ['npc_dota_hero_vengefulspirit'] = CreateHeroData(0.7, 0.6, true, true),
    ['npc_dota_hero_venomancer'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_viper'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_visage'] = CreateHeroData(0.2, 0.1, false, false),
    ['npc_dota_hero_void_spirit'] = CreateHeroData(0.6, 0.6, true, true),
    ['npc_dota_hero_warlock'] = CreateHeroData(0.4, 0.2, false, false),
    ['npc_dota_hero_weaver'] = CreateHeroData(0.2, 0.8, false, true),
    ['npc_dota_hero_windrunner'] = CreateHeroData(0.4, 0.5, true, true),
    ['npc_dota_hero_wisp'] = CreateHeroData(0.1, 0.1, false, false),
    ['npc_dota_hero_witch_doctor'] = CreateHeroData(0.5, 0.5, true, false),
    ['npc_dota_hero_zuus'] = CreateHeroData(0.5, 0.2, true, false),
}

function GetMorphEngageScore(sHeroName)
    if hHeroList[sHeroName] and hHeroList[sHeroName].scoreEngage then
        return hHeroList[sHeroName].scoreEngage
    end

    return 0.1
end

function GetMorphRetreatScore(sHeroName)
    if hHeroList[sHeroName] and hHeroList[sHeroName].scoreRetreat then
        if hHeroList[sHeroName].scoreRetreat >= 0.5 then
            return hHeroList[sHeroName].scoreRetreat
        end
    end

    return -1
end

function IsGoodToMorphBack(sHeroName, bEngage)
    if hHeroList[sHeroName] then
        if bEngage then
            if hHeroList[sHeroName].goodToEngageBack then
                return hHeroList[sHeroName].goodToEngageBack
            end
        else
            if hHeroList[sHeroName].goodToRetreatBack then
                return hHeroList[sHeroName].goodToRetreatBack
            end
        end
    end

    return false
end

return X
