local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos4
					['t25'] = {0, 10},
					['t20'] = {10, 0},
					['t15'] = {10, 0},
					['t10'] = {10, 0},
						},
						{--pos5
					['t25'] = {0, 10},
					['t20'] = {10, 0},
					['t15'] = {10, 0},
					['t10'] = {10, 0},
						},
}

local tAllAbilityBuildList = {
						{2,1,3,1,1,6,1,3,3,3,6,2,2,2,6},--pos4
						{2,1,3,1,1,6,1,3,3,3,6,2,2,2,6},--pos5
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_5"
then
    nAbilityBuildList   = tAllAbilityBuildList[1]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[1])
else
    nAbilityBuildList   = tAllAbilityBuildList[2]
    nTalentBuildList    = Fu.Skill.GetTalentBuild(tTalentTreeList[2])
end

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_4'] = {
	"item_enchanted_mango",
	"item_blood_grenade",
	"item_priest_outfit",
	"item_force_staff",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_aghanims_shard",
	"item_guardian_greaves",--
	"item_hurricane_pike",--
--	"item_wraith_pact",
	"item_shivas_guard",--
	"item_ultimate_scepter",
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_refresher",--
	"item_moon_shard",
}

sRoleItemsBuyList['pos_5'] = {
    "item_double_tango",
    "item_faerie_fire",
    "item_enchanted_mango",
    "item_blood_grenade",

    "item_boots",
    "item_urn_of_shadows", -- Alternative: item_essence_distiller (if not going spirit_vessel)
    "item_tranquil_boots",
	"item_pipe",
    "item_spirit_vessel",--
    "item_glimmer_cape",--
    "item_pavise",
    "item_solar_crest",--
    "item_boots_of_bearing",--
    "item_octarine_core",--
    "item_sheepstick",--
    "item_aghanims_shard",
    "item_ultimate_scepter_2",
    "item_moon_shard",
}

sRoleItemsBuyList['pos_3'] = {
	'item_mage_outfit',
	"item_glimmer_cape",
	"item_boots_of_bearing",
	"item_aghanims_shard",
	"item_ultimate_scepter",
	"item_veil_of_discord",--
	"item_cyclone",
	"item_shivas_guard",--
	"item_refresher",--
	"item_ultimate_scepter_2",
	"item_sheepstick",--
	"item_wind_waker",--
	"item_moon_shard",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = {
	"item_crystal_maiden_outfit",
    "item_kaya",
	"item_force_staff",
	"item_kaya_and_sange",--
	"item_rod_of_atos",
	"item_aghanims_shard",
	"item_hurricane_pike",--
	"item_shivas_guard",--
	"item_octarine_core",--
	"item_gungir",--
	"item_moon_shard",
	"item_ultimate_scepter",
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
}

sRoleItemsBuyList['pos_1'] = {
	"item_crystal_maiden_outfit",
    "item_kaya",
	"item_force_staff",
	"item_kaya_and_sange",--
    "item_dagon_2",
	"item_rod_of_atos",
	"item_aghanims_shard",
	"item_dagon_5",--
	"item_hurricane_pike",--
	"item_shivas_guard",--
	-- "item_sheepstick",--
	"item_gungir",--
	"item_moon_shard",
	"item_ultimate_scepter",
	"item_ultimate_scepter_2",
	"item_travel_boots_2",--
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



local CatchyLick        = SafeAbility(bot:GetAbilityByName('largo_catchy_lick'), 'largo_catchy_lick', 'largo')
local Frogstomp         = SafeAbility(bot:GetAbilityByName('largo_frogstomp'), 'largo_frogstomp', 'largo')
local CroakOfGenius     = SafeAbility(bot:GetAbilityByName('largo_croak_of_genius'), 'largo_croak_of_genius', 'largo')
local AmphibianRhapsody = SafeAbility(bot:GetAbilityByName('largo_amphibian_rhapsody'), 'largo_amphibian_rhapsody', 'largo')
local BullbellyBlitz    = SafeAbility(bot:GetAbilityByName('largo_song_fight_song'), 'largo_song_fight_song', 'largo')
local HotfeetHustle     = SafeAbility(bot:GetAbilityByName('largo_song_double_time'), 'largo_song_double_time', 'largo')
local IslandElixir      = SafeAbility(bot:GetAbilityByName('largo_song_good_vibrations'), 'largo_song_good_vibrations', 'largo')

local CatchyLickDesire, CatchyLickTarget
local FrogstompDesire, FrogstompLocation
local CroakOfGeniusDesire, CroakOfGeniusTarget
local AmphibianRhapsodyDesire

local songs = {
    strumTime = 0,
    song1 = BullbellyBlitz,
    song2 = BullbellyBlitz,
    wasInWindow = false,
}

local bAttacking = false
local botTarget, botHP
local nAllyHeroes, nEnemyHeroes

local bGoingOnSomeone
function X.SkillsComplement()
    if not bot:HasModifier('modifier_largo_amphibian_rhapsody_self') then
        songs.strumTime = 0
        songs.wasInWindow = false
    else
        if AmphibianRhapsody and AmphibianRhapsody:IsTrained() and songs.strumTime > 0 then
            local nStrumInterval = AmphibianRhapsody:GetSpecialValueInt('rhythm_interval')
            if DotaTime() >= songs.strumTime + nStrumInterval then
                songs.strumTime = songs.strumTime + nStrumInterval
            end
        end
    end

    if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)

	bAttacking = Fu.IsAttacking(bot)
    botHP = Fu.GetHP(bot)
    botTarget = Fu.GetProperTarget(bot)
    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    CroakOfGeniusDesire, CroakOfGeniusTarget = X.ConsiderCroakOfGenius()
    if CroakOfGeniusDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(CroakOfGenius, CroakOfGeniusTarget)
        return
    end

    CatchyLickDesire, CatchyLickTarget = X.ConsiderCatchLick()
    if CatchyLickDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(CatchyLick, CatchyLickTarget)
        return
    end

    FrogstompDesire, FrogstompLocation = X.ConsiderFrogstomp()
    if FrogstompDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnLocation(Frogstomp, FrogstompLocation)
        return
    end

    AmphibianRhapsodyDesire = X.ConsiderAmphibianRhapsody()
    if AmphibianRhapsodyDesire > 0 then
        bot:Action_UseAbility(AmphibianRhapsody)
        return
    end
end

function X.ConsiderCatchLick()
    if not Fu.CanCastAbility(CatchyLick) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = CatchyLick:GetCastRange()
    local nPullDistance = CatchyLick:GetSpecialValueInt('pull_distance')
    local nPullDistanceAlly = CatchyLick:GetSpecialValueInt('pull_distance_ally')
    local nDamage = CatchyLick:GetSpecialValueInt('damage')
    local nManaCost = CatchyLick:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Frogstomp, CroakOfGenius})

	for _, allyHero in pairs(nAllyHeroes) do
		if Fu.IsValidHero(allyHero)
		and bot ~= allyHero
		and Fu.IsInRange(bot, allyHero, nPullDistanceAlly + 300)
		and not Fu.IsInRange(bot, allyHero, nPullDistanceAlly * 0.8)
		and not Fu.IsDisabled(allyHero)
		and not Fu.IsSuspiciousIllusion(allyHero)
		and not Fu.IsRealInvisible(allyHero)
		and not allyHero:IsChanneling()
		then
			if Fu.IsGoingOnSomeone(allyHero) then
				local allyHeroTarget = Fu.GetProperTarget(allyHero)
				if  Fu.IsValidHero(allyHeroTarget)
				and allyHeroTarget:IsFacingLocation(allyHeroTarget:GetLocation(), 15)
				and GetUnitToUnitDistance(allyHero, allyHeroTarget) > allyHero:GetAttackRange() + 50
				and GetUnitToUnitDistance(allyHero, allyHeroTarget) < allyHero:GetAttackRange() + 700
				and not Fu.IsSuspiciousIllusion(allyHeroTarget)
				and not allyHeroTarget:IsFacingLocation(allyHero:GetLocation(), 40)
				and #nAllyHeroes >= 3
				then
					local tResult = PointToLineDistance(allyHeroTarget:GetLocation(), allyHero:GetLocation(), bot:GetLocation())
					if tResult and tResult.within and tResult.distance <= 600 then
						return BOT_ACTION_DESIRE_HIGH, allyHero
					end

					tResult = PointToLineDistance(bot:GetLocation(), allyHero:GetLocation(), allyHeroTarget:GetLocation())
					if tResult and tResult.within and tResult.distance <= 600 then
						return BOT_ACTION_DESIRE_HIGH, allyHero
					end
				end
			end

			local nInRangeEnemy = Fu.GetEnemiesNearLoc(allyHero:GetLocation(), 900)
			if  Fu.IsRetreating(allyHero)
			and #nInRangeEnemy > 0
			and allyHero:IsFacingLocation(Fu.GetTeamFountain(), 30)
			and allyHero:DistanceFromFountain() > 1200
			and allyHero:WasRecentlyDamagedByAnyHero(5.0)
			then
				local tResult = PointToLineDistance(Fu.GetTeamFountain(), allyHero:GetLocation(), bot:GetLocation())
				if tResult and tResult.within and tResult.distance <= 600 then
					return BOT_ACTION_DESIRE_HIGH, allyHero
				end
			end

			if Fu.IsStuck(allyHero) then
				return BOT_ACTION_DESIRE_HIGH, allyHero
			end
		end

        if  Fu.IsValidHero(allyHero)
        and Fu.IsInRange(bot, allyHero, nCastRange)
        and not allyHero:IsMagicImmune()
        and not allyHero:IsIllusion()
        and not allyHero:IsChanneling()
        and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and allyHero:WasRecentlyDamagedByAnyHero(2.0)
        then
            -- dispel some stuff
            local bIsGoingOnSomeone = Fu.IsGoingOnSomeone(allyHero)
            local bIsRetreating = Fu.IsRetreating(allyHero)
            if (Fu.GetModifierTime(allyHero, 'modifier_bane_nightmare') > 2)
            or (Fu.GetModifierTime(allyHero, 'modifier_axe_battle_hunger') > 2 and bIsRetreating)
            or (Fu.GetModifierTime(allyHero, 'modifier_bristleback_viscous_nasal_goo') > 2 and Fu.IsRunning(allyHero))
            or (Fu.GetModifierTime(allyHero, 'modifier_earth_spirit_magnetize') > 2 and not bIsGoingOnSomeone)
            or (Fu.GetModifierTime(allyHero, 'modifier_phoenix_fire_spirit_burn') > 2 and bIsGoingOnSomeone)
            or (Fu.GetModifierTime(allyHero, 'modifier_life_stealer_open_wounds') > 2 and bIsRetreating)
            or (Fu.GetModifierTime(allyHero, 'modifier_faceless_void_time_dilation_slow') > 2 and bIsGoingOnSomeone)
            or (Fu.GetModifierTime(allyHero, 'modifier_warlock_fatal_bonds') > 2)
            or (Fu.GetModifierTime(allyHero, 'modifier_arc_warden_flux') > 2 and bIsRetreating)
            or (Fu.GetModifierTime(allyHero, 'modifier_venomancer_venomous_gale') > 2 and bIsRetreating)
            or (Fu.GetModifierTime(allyHero, 'modifier_stunned') > 2)
            then
                return BOT_ACTION_DESIRE_HIGH, allyHero
            end
        end
	end

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
        and Fu.CanCastOnTargetAdvanced(enemyHero)
        and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        then
            if  Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
            then
                return BOT_ACTION_DESIRE_HIGH, enemyHero
            end

            -- dispel some stuff
            if botHP < 0.9 then
                if (Fu.GetModifierTime(enemyHero, 'modifier_earthshaker_enchant_totem') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_legion_commander_overwhelming_odds') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_legion_commander_press_the_attack') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_ogre_magi_bloodlust') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_shredder_reactive_armor_bomb') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_ursa_overpower') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_necrolyte_sadist_active') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_pugna_decrepify') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_warlock_shadow_word') > 2)
                or (Fu.GetModifierTime(enemyHero, 'modifier_abaddon_aphotic_shield') > 2)
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

	if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsInRange(bot, botTarget, nPullDistance)
        and Fu.IsChasingTarget(bot, botTarget)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange + 300, 1600), true)

    if Fu.IsPushing(bot) or Fu.IsDefending(bot) or Fu.IsFarming(bot) then
        if #nAllyHeroes <= 2 and #nEnemyHeroes == 0 and bAttacking and fManaAfter > fManaThreshold1 + 0.1 then
            local hTarget = nil
            local hTargetScore = 0
            for _, creep in pairs(nEnemyCreeps) do
                if  Fu.IsValid(creep)
                and Fu.CanBeAttacked(creep)
                and not Fu.IsRoshan(creep)
                and not Fu.IsTormentor(creep)
                and not Fu.IsOtherAllysTarget(creep)
                and creep:GetHealth() > 0
                then
                    local creepScore = creep:GetActualIncomingDamage(nDamage, DAMAGE_TYPE_MAGICAL) / creep:GetHealth()
                    if creepScore > hTargetScore then
                        hTarget = creep
                        hTargetScore = creepScore
                    end
                end
            end

            if hTarget then
                return BOT_ACTION_DESIRE_HIGH, hTarget
            end
        end
    end

	if Fu.IsLaning(bot) and Fu.IsInLaningPhase() and fManaAfter > fManaThreshold1 then
		for _, creep in pairs(nEnemyCreeps) do
			if  Fu.IsValid(creep)
            and Fu.CanBeAttacked(creep)
            and Fu.CanKillTarget(creep, nDamage, DAMAGE_TYPE_MAGICAL)
			and (Fu.IsCore(bot) or not Fu.IsThereCoreInLocation(creep:GetLocation(), 650))
			and not Fu.IsOtherAllysTarget(creep)
			then
                local sCreepName = creep:GetUnitName()
                if string.find(sCreepName, 'ranged') then
                    local nLocationAoE = bot:FindAoELocation(true, true, creep:GetLocation(), 0, 600, 0, 0)
                    if nLocationAoE.count > 0 or Fu.IsUnitTargetedByTower(creep, false) then
                        return BOT_ACTION_DESIRE_HIGH, creep
                    end
                end
			end
		end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderFrogstomp()
    if not Fu.CanCastAbility(Frogstomp) then
        return BOT_ACTION_DESIRE_NONE, 0
    end

    local nCastRange = Frogstomp:GetCastRange()
    local nRadius = Frogstomp:GetSpecialValueInt('radius')
    local nManaCost = Frogstomp:GetManaCost()
	local fManaAfter = Fu.GetManaAfter(nManaCost)
	local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {CatchyLick, CroakOfGenius})

    for _, enemyHero in pairs(nEnemyHeroes) do
        if Fu.IsValidHero(enemyHero)
        and Fu.CanBeAttacked(enemyHero)
        and Fu.IsInRange(bot, enemyHero, nCastRange)
        and Fu.CanCastOnNonMagicImmune(enemyHero)
		and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and enemyHero:IsChanneling()
        then
            return BOT_ACTION_DESIRE_HIGH, enemyHero:GetLocation()
        end
    end

    if bGoingOnSomeone then
		if Fu.IsValidHero(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and Fu.CanCastOnNonMagicImmune(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            if Fu.IsDisabled(botTarget)
            or botTarget:GetCurrentMovementSpeed() <= 250
            then
                return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
            end
		end
	end

    if Fu.IsRetreating(bot) and not Fu.IsRealInvisible(bot) and Fu.IsRunning(bot) then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if  Fu.IsValidHero(enemyHero)
			and Fu.CanBeAttacked(enemyHero)
            and Fu.IsInRange(bot, enemyHero, nRadius * 2)
            and not Fu.IsInRange(bot, enemyHero, nRadius * 0.8)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            and bot:WasRecentlyDamagedByHero(enemyHero, 3.0)
            then
                return BOT_ACTION_DESIRE_HIGH, (bot:GetLocation() + enemyHero:GetLocation()) / 2
            end
        end
	end

    local nEnemyCreeps = bot:GetNearbyCreeps(Min(nCastRange + 300, 1600), true)

    if Fu.IsPushing(bot) and #nAllyHeroes <= 2 and bAttacking and fManaAfter > fManaThreshold1 and #nEnemyHeroes == 0 then
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 4) then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
    end

    if Fu.IsDefending(bot) and bAttacking and fManaAfter > fManaThreshold1 then
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 4)
                or (nLocationAoE.count >= 3 and string.find(creep:GetUnitName(), 'upgraded'))
                then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
    end

    if Fu.IsFarming(bot) and bAttacking and fManaAfter > fManaThreshold1 then
        for _, creep in pairs(nEnemyCreeps) do
            if Fu.IsValid(creep) and Fu.CanBeAttacked(creep) and not Fu.IsRunning(creep) then
                local nLocationAoE = bot:FindAoELocation(true, false, creep:GetLocation(), 0, nRadius, 0, 0)
                if (nLocationAoE.count >= 3)
                or (nLocationAoE.count >= 2 and creep:IsAncientCreep())
                or (nLocationAoE.count >= 1 and creep:GetHealth() >= 550)
                then
                    return BOT_ACTION_DESIRE_HIGH, nLocationAoE.targetloc
                end
            end
        end
    end

    if Fu.IsDoingRoshan(bot) then
		if Fu.IsRoshan(botTarget)
		and Fu.CanBeAttacked(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and bAttacking
        and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and fManaAfter > fManaThreshold1
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
		end
	end

    return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderCroakOfGenius()
    if not Fu.CanCastAbility(CroakOfGenius) then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = CroakOfGenius:GetCastRange()

    local hTarget = nil
    local hTargetDamage = 0
    for _, allyHero in pairs(nAllyHeroes) do
        if Fu.IsValidHero(allyHero)
        and Fu.IsInRange(bot, allyHero, nCastRange + 300)
        and Fu.IsGoingOnSomeone(allyHero)
        and not allyHero:IsIllusion()
        and not allyHero:IsSilenced()
        and not allyHero:HasModifier('modifier_doom_bringer_doom_aura_enemy')
        and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not allyHero:HasModifier('modifier_largo_croak_of_genius_buff')
        and not allyHero:HasModifier('modifier_silencer_curse_of_the_silent')
        and not allyHero:HasModifier('modifier_teleporting')
        then
            local allyHeroTarget = Fu.GetProperTarget(allyHero)
            if  Fu.IsValidHero(allyHeroTarget)
            and Fu.CanBeAttacked(allyHeroTarget)
            and not Fu.IsSuspiciousIllusion(allyHeroTarget)
            then
                local allyHeroDamage = allyHero:GetEstimatedDamageToTarget(true, allyHeroTarget, 5.0, DAMAGE_TYPE_MAGICAL)
                if allyHeroDamage > hTargetDamage then
                    hTarget = allyHero
                    hTargetDamage = allyHeroDamage
                end
            end
        end
    end

    if hTarget then
        return BOT_ACTION_DESIRE_HIGH, hTarget
    end

    return BOT_ACTION_DESIRE_NONE, nil
end

local songs__ = {BullbellyBlitz, HotfeetHustle, IslandElixir}
function X.ConsiderAmphibianRhapsody()
    if not Fu.CanCastAbility(AmphibianRhapsody) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nRadius = AmphibianRhapsody:GetSpecialValueInt('radius')
    local bCanPlayDouble = AmphibianRhapsody:GetSpecialValueInt('double_song') > 0
    local fManaThreshold1 = Fu.GetManaThreshold(bot, 150, {CatchyLick, Frogstomp, CroakOfGenius})
    local botMP = Fu.GetMP(bot)

    local bIsToggled = AmphibianRhapsody:GetToggleState()

    repeat
          songs.song1 = songs__[RandomInt(1, 3)]
          songs.song2 = songs__[RandomInt(1, 3)]
    until songs.song1 ~= songs.song2

    if bCanPlayDouble and botMP > fManaThreshold1 then
        if bGoingOnSomeone or Fu.IsInTeamFight(bot, 1200) then
            for _, enemyHero in pairs(nEnemyHeroes) do
                if  Fu.IsValidHero(enemyHero)
                and Fu.CanBeAttacked(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nRadius)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
                and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
                then
                    if not bIsToggled then
                        return BOT_ACTION_DESIRE_HIGH
                    else
                        X.Strum(songs.song1, songs.song2)
                        return BOT_ACTION_DESIRE_NONE
                    end
                end
            end
        end
    end

    for _, allyHero in pairs(nAllyHeroes) do
        if  Fu.IsValidHero(allyHero)
        and Fu.IsInRange(bot, allyHero, nRadius)
        and not allyHero:IsIllusion()
        and not allyHero:HasModifier('modifier_necrolyte_reapers_scythe')
        and not allyHero:HasModifier('modifier_teleporting')
        then
            local allyHeroHp = Fu.GetHP(allyHero)
            local allyTarget = Fu.GetProperTarget(allyHero)

            if Fu.IsGoingOnSomeone(allyHero) and bot ~= allyHero then
                if  Fu.IsValidHero(allyTarget)
                and Fu.CanBeAttacked(allyTarget)
                and Fu.IsInRange(allyHero, allyTarget, Max(allyHero:GetAttackRange(), 800))
                and not Fu.IsSuspiciousIllusion(allyTarget)
                then
                    if not Fu.CanCastAbility(Frogstomp) then
                        if botMP > fManaThreshold1 + 0.1 then
                            if not bIsToggled then
                                return BOT_ACTION_DESIRE_HIGH
                            else
                                if (Fu.IsChasingTarget(allyHero, allyTarget))
                                or (Fu.IsInTeamFight(bot, 1200) and allyHero:WasRecentlyDamagedByAnyHero(2.0))
                                or (allyHero:GetCurrentMovementSpeed() <= 250)
                                then
                                    X.Strum(HotfeetHustle, nil)
                                elseif allyHeroHp < 0.55 and X.IsGoodToHeal(allyHero) then
                                    X.Strum(IslandElixir, nil)
                                else
                                    X.Strum(BullbellyBlitz, nil)
                                end

                                return BOT_ACTION_DESIRE_NONE
                            end
                        end
                    end
                end
            end

            if not Fu.IsRealInvisible(bot) then
                if (Fu.IsRetreating(allyHero) and allyHeroHp < 0.65 and not Fu.CanCastAbility(Frogstomp)) then
                    if botMP > fManaThreshold1 + 0.1 then
                        if not bIsToggled then
                            return BOT_ACTION_DESIRE_HIGH
                        else
                            if allyHero:GetCurrentMovementSpeed() <= 250 and not allyHero:IsRooted() then
                                X.Strum(HotfeetHustle, nil)
                            else
                                if X.IsGoodToHeal(allyHero) then
                                    X.Strum(IslandElixir, nil)
                                end
                            end

                            return BOT_ACTION_DESIRE_NONE
                        end
                    end
                end

                if allyHeroHp < 0.5 and X.IsGoodToHeal(allyHero) then
                    if botMP > fManaThreshold1 + 0.1 then
                        if not bIsToggled then
                            return BOT_ACTION_DESIRE_HIGH
                        else
                            X.Strum(IslandElixir, nil)
                        end

                        return BOT_ACTION_DESIRE_NONE
                    end
                end
            end

            if bot ~= allyHero and Fu.IsCore(allyHero) and botMP > fManaThreshold1 + 0.1 then
                if Fu.IsDoingRoshan(allyHero) and Fu.IsDoingRoshan(bot) then
                    if  Fu.IsRoshan(allyTarget)
                    and Fu.CanBeAttacked(allyTarget)
                    and Fu.IsInRange(allyHero, allyTarget, 1200)
                    then
                        if not bIsToggled and Fu.IsAttacking(allyHero) then
                            return BOT_ACTION_DESIRE_HIGH
                        else
                            X.Strum(BullbellyBlitz, nil)
                        end

                        return BOT_ACTION_DESIRE_NONE
                    end
                end

                if Fu.IsDoingTormentor(allyHero) and Fu.IsDoingTormentor(bot) then
                    if  Fu.IsTormentor(allyTarget)
                    and Fu.IsInRange(allyHero, allyTarget, 1200)
                    then
                        if not bIsToggled and Fu.IsAttacking(allyHero) then
                            return BOT_ACTION_DESIRE_HIGH
                        else
                            if bCanPlayDouble then
                                X.Strum(BullbellyBlitz, IslandElixir)
                            else
                                X.Strum(BullbellyBlitz, nil)
                            end
                        end

                        return BOT_ACTION_DESIRE_NONE
                    end
                end
            end
        end
    end

	if bIsToggled and math.floor(DotaTime()) % 2 == 0 then
		return BOT_ACTION_DESIRE_HIGH
	end

    return BOT_ACTION_DESIRE_NONE
end

function X.IsGoodToHeal(hUnit)
    return  not hUnit:HasModifier('modifier_abaddon_borrowed_time')
        and not hUnit:HasModifier('modifier_doom_bringer_doom_aura_enemy')
        and not hUnit:HasModifier('modifier_ice_blast')
        and not hUnit:HasModifier('modifier_necrolyte_reapers_scythe')
        and hUnit:GetUnitName() ~= 'npc_dota_hero_medusa'
        and hUnit:GetUnitName() ~= 'npc_dota_hero_huskar'
end

function X.Strum(song1, song2)
    local fGracePeriod = AmphibianRhapsody:GetSpecialValueFloat('rhythm_grace_period')
    local now = DotaTime()

    local inWindow = (songs.strumTime == 0)
                  or ((now >= songs.strumTime - fGracePeriod)) and (now <= songs.strumTime + fGracePeriod)

    if inWindow and not songs.wasInWindow then
        if song1 and song2 == nil then
            bot:Action_UseAbility(song1)
            if songs.strumTime == 0 then songs.strumTime = DotaTime() end
        elseif song1 and song2 and song1 ~= song2 then
            bot:ActionPush_UseAbility(song1)
            bot:ActionPush_UseAbility(song2)
            if songs.strumTime == 0 then songs.strumTime = DotaTime() end
        end
    end

    songs.wasInWindow = inWindow
end

return X
