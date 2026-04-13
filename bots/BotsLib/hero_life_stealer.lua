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
						{2,3,1,3,3,6,3,2,2,2,1,6,1,1,6},--pos1
						-- {2,3,3,3,6,3,2,2,2,6,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRandom = RandomInt(1, 2) == 1 and "item_radiance" or "item_desolator"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
    "item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_quelling_blade",

    "item_orb_of_corrosion",
	"item_magic_wand",
    "item_double_gauntlets",
    "item_phase_boots",
    "item_armlet",
    sRandom,--
    "item_aghanims_shard",
    "item_assault",--
    "item_basher",
    "item_nullifier",--
    "item_monkey_king_bar",--
    "item_travel_boots",
    "item_abyssal_blade",--
    "item_moon_shard",
    "item_travel_boots_2",--
    "item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_guardian_greaves",--
    "item_basher",
    "item_monkey_king_bar",--
	"item_assault",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
    "item_abyssal_blade",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
}

sRoleItemsBuyList['pos_5'] = {
	'item_priest_outfit',
	"item_hand_of_midas",
	"item_mekansm",
	"item_glimmer_cape",--
	"item_pipe",--
    "item_basher",
    "item_monkey_king_bar",--
	"item_assault",--
	"item_heavens_halberd",--
	"item_aghanims_shard",
    "item_abyssal_blade",--
	"item_ultimate_scepter",
	"item_moon_shard",
	"item_ultimate_scepter_2",
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

local botTarget, infestTarget, infestTargetType
local nAllyHeroes, nEnemyHeroes

function X.MinionThink(hMinionUnit)
    local botHp = Fu.GetHP(bot)

    -- Control ability: lets LS take over the infested creep
    local hControl = hMinionUnit:GetAbilityByName('life_stealer_control')
    if hControl and not hControl:IsHidden() and hControl:IsFullyCastable() then
        hMinionUnit:Action_UseAbility(hControl)
        return
    end

    -- Consume (burst out of host)
    local hConsume = hMinionUnit:GetAbilityByName('life_stealer_consume')
    if hConsume and hConsume:IsFullyCastable() then
        local nNearbyEnemy = hMinionUnit:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
        local bIsHeroHost = hMinionUnit:IsHero()

        -- Track infest time for anti-stuck timeout
        if not bot._infestTime then bot._infestTime = DotaTime() end
        local nInfestDuration = DotaTime() - bot._infestTime

        -- === CONSUME CONDITIONS (ordered by priority) ===

        -- 1. Pop out at fountain (we're healed, go fight)
        if botHp > 0.9 and hMinionUnit:HasModifier('modifier_fountain_aura_buff') then
            hMinionUnit:Action_UseAbility(hConsume)
            bot._infestTime = nil
            return
        end

        -- 2. Teamfight burst: pop out for AoE damage when healthy and enemies present
        if nNearbyEnemy and #nNearbyEnemy >= 2 and botHp > 0.7 then
            hMinionUnit:Action_UseAbility(hConsume)
            bot._infestTime = nil
            return
        end

        -- 3. Fully healed: no reason to stay inside
        if botHp > 0.95 and nInfestDuration > 2 then
            hMinionUnit:Action_UseAbility(hConsume)
            bot._infestTime = nil
            return
        end

        -- 4. Creep host: move toward fight, pop when enemies are close
        if not bIsHeroHost then
            if nNearbyEnemy and #nNearbyEnemy > 0 and botHp > 0.5 then
                -- Enemies in range and healthy enough — burst out for damage
                hMinionUnit:Action_UseAbility(hConsume)
                bot._infestTime = nil
                return
            end
            -- Move creep toward teamfight or fountain
            local nTeamFightLocation = Fu.GetTeamFightLocation(bot)
            if nTeamFightLocation and botHp > 0.5 then
                hMinionUnit:Action_MoveToLocation(nTeamFightLocation)
            else
                hMinionUnit:Action_MoveToLocation(Fu.GetTeamFountain())
            end
            return
        end

        -- 5. Hero host: pop out when healed enough and action is happening
        if bIsHeroHost then
            -- Pop out to fight alongside ally when healthy
            if botHp > 0.75 and nNearbyEnemy and #nNearbyEnemy > 0 then
                hMinionUnit:Action_UseAbility(hConsume)
                bot._infestTime = nil
                return
            end
            -- Pop out when fully healed (even if no enemies — don't ride ally forever)
            if botHp > 0.85 and nInfestDuration > 4 then
                hMinionUnit:Action_UseAbility(hConsume)
                bot._infestTime = nil
                return
            end
        end

        -- 6. Anti-stuck timeout: if inside for 15+ seconds, pop out regardless
        -- (Infest heals 3-5% HP/sec, 15 sec = 45-75% HP restored — should be enough)
        if nInfestDuration > 15 then
            hMinionUnit:Action_UseAbility(hConsume)
            bot._infestTime = nil
            return
        end
    end

    Minion.MinionThink(hMinionUnit)
end

local Rage          = SafeAbility(bot:GetAbilityByName('life_stealer_rage'), 'life_stealer_rage', 'life_stealer')
-- local Feast         = bot:GetAbilityByName('life_stealer_feast')
-- local GhoulFrenzy   = bot:GetAbilityByName('life_stealer_ghoul_frenzy')
local OpenWounds    = SafeAbility(bot:GetAbilityByName('life_stealer_open_wounds'), 'life_stealer_open_wounds', 'life_stealer')
local Infest        = SafeAbility(bot:GetAbilityByName('life_stealer_infest'), 'life_stealer_infest', 'life_stealer')
local Consume       = SafeAbility(bot:GetAbilityByName('life_stealer_consume'), 'life_stealer_consume', 'life_stealer')
local Control       = SafeAbility(bot:GetAbilityByName('life_stealer_control'), 'life_stealer_control', 'life_stealer')


local RageDesire
local OpenWoundsDesire, OpenWoundsTarget
local InfestDesire, InfestTarget
local ConsumeDesire

local bAttacking = false
local botHP, botMaxMana, botManaRegen

local bGoingOnSomeone
local bRetreating
function X.SkillsComplement()
    -- Re-fetch ability handles each tick for safety
    Rage       = SafeAbility(bot:GetAbilityByName('life_stealer_rage'), 'life_stealer_rage', 'life_stealer')
    OpenWounds = SafeAbility(bot:GetAbilityByName('life_stealer_open_wounds'), 'life_stealer_open_wounds', 'life_stealer')
    Infest     = SafeAbility(bot:GetAbilityByName('life_stealer_infest'), 'life_stealer_infest', 'life_stealer')
    Consume    = SafeAbility(bot:GetAbilityByName('life_stealer_consume'), 'life_stealer_consume', 'life_stealer')

    bAttacking = Fu.IsAttacking(bot)
    botHP = Fu.GetHP(bot)
	botMaxMana = bot:GetMaxMana()
    botManaRegen = bot:GetManaRegen()
    botTarget = Fu.GetProperTarget(bot)
    nAllyHeroes = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    nEnemyHeroes = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE)

    ConsumeDesire = X.ConsiderConsume()
    if ConsumeDesire > 0 then
        bot:Action_UseAbility(Consume)
        return
    end

    if not bot:HasModifier('modifier_life_stealer_infest') then
        if Fu.CanNotUseAbility(bot) then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
    end

    -- InfestDesire, InfestTarget = X.ConsiderInfest()
    -- if InfestDesire > 0 then
    --     bot:Action_UseAbilityOnEntity(Infest, InfestTarget)
    --     return
    -- end

    RageDesire = X.ConsiderRage()
    if RageDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbility(Rage)
        return
    end

    OpenWoundsDesire, OpenWoundsTarget = X.ConsiderOpenWounds()
    if OpenWoundsDesire > 0 then
        Fu.SetQueuePtToINT(bot, false)
        bot:ActionQueue_UseAbilityOnEntity(OpenWounds, OpenWoundsTarget)
        return
    end
end

function X.ConsiderRage()
    if not Fu.CanCastAbility(Rage)
    or bot:HasModifier('modifier_life_stealer_infest')
    or bot:IsMagicImmune()
    or bot:IsInvulnerable()
    then
        return BOT_ACTION_DESIRE_NONE
    end

    local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)

    if #nInRangeEnemy > 0 then
        -- Spell/projectile dodge: only use Rage if recently damaged (don't burn it at full HP)
        if bot:WasRecentlyDamagedByAnyHero(3.0) and not Fu.IsRealInvisible(bot) then
            if Fu.IsNotAttackProjectileIncoming(bot, 350)
            or Fu.IsWillBeCastUnitTargetSpell(bot, 500)
            or Fu.IsWillBeCastPointSpell(bot, 500)
            then
                if (bGoingOnSomeone and Fu.IsValidTarget(botTarget) and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange()))
                or (bRetreating and botHP < 0.55) then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end

            -- Stun-specific projectile dodge (higher priority)
            if Fu.IsStunProjectileIncoming and Fu.IsStunProjectileIncoming(bot, 550) then
                return BOT_ACTION_DESIRE_HIGH
            end
        end

        if (bGoingOnSomeone or (bRetreating and not Fu.IsRealInvisible(bot))) then
            -- Rooted: use Rage only if target is out of attack range (going) or retreating
            if bot:IsRooted() then
                if bRetreating then
                    return BOT_ACTION_DESIRE_HIGH
                elseif bGoingOnSomeone and Fu.IsValidTarget(botTarget)
                and not Fu.IsInRange(bot, botTarget, bot:GetAttackRange()) then
                    return BOT_ACTION_DESIRE_HIGH
                end
            end

            nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 600)
            if bot:IsSilenced()
            and #nInRangeEnemy >= 2
            and bGoingOnSomeone
            and not bot:HasModifier('modifier_item_mask_of_madness_berserk')
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            local nInRangeAlly = Fu.GetAlliesNearLoc(bot:GetLocation(), 1200)
            if #nInRangeEnemy >= #nInRangeAlly
            and botHP < 0.6
            and Fu.IsValidHero(nInRangeEnemy[1])
            and (Fu.IsChasingTarget(nInRangeEnemy[1], bot) or nInRangeEnemy[1]:GetAttackTarget() == bot)
            then
                return BOT_ACTION_DESIRE_HIGH
            end

            -- FIX: #table is always truthy in Lua (returns a number). Use > 0 explicitly.
            if #nInRangeEnemy >= 3 and Fu.IsInTeamFight(bot, 1200)
            and #Fu.GetHeroesTargetingUnit(nInRangeEnemy, bot) > 0
            and not Fu.IsRealInvisible(bot) then
                return BOT_ACTION_DESIRE_HIGH
            end
        end
    end

    if bot:HasModifier('modifier_jakiro_macropyre_burn')
    or bot:HasModifier('modifier_lich_chainfrost_slow')
    or bot:HasModifier('modifier_crystal_maiden_freezing_field_slow')
    or bot:HasModifier('modifier_puck_coiled')
    or bot:HasModifier('modifier_skywrath_mystic_flare_aura_effect')
    or bot:HasModifier('modifier_snapfire_magma_burn_slow')
    or bot:HasModifier('modifier_sand_king_epicenter_slow')
    then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderOpenWounds()
    if not Fu.CanCastAbility(OpenWounds)
    or bot:HasModifier('modifier_life_stealer_infest')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

	local nCastRange = Fu.GetProperCastRange(false, bot, OpenWounds:GetCastRange())
    local nManaCost = OpenWounds:GetManaCost()
    local fManaAfter = Fu.GetManaAfter(nManaCost)
    local fManaThreshold1 = Fu.GetManaThreshold(bot, nManaCost, {Rage, Infest})

	if bGoingOnSomeone then
        if  Fu.IsValidTarget(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and not Fu.IsDisabled(botTarget)
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
        and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		then
            if Fu.IsChasingTarget(bot, botTarget)
            or (#Fu.GetHeroesTargetingUnit(nAllyHeroes, botTarget) >= 2 and Fu.GetHP(botTarget) > 0.2)
            then
                if fManaAfter > fManaThreshold1 then
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end
        end
	end

    if bRetreating and not Fu.IsRealInvisible(bot) then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.IsInRange(bot, enemy, nCastRange)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and Fu.CanCastOnTargetAdvanced(enemy)
            and bot:WasRecentlyDamagedByHero(enemy, 3.0)
            and Fu.IsChasingTarget(enemy, bot)
            and not Fu.IsDisabled(enemy)
            and not enemy:IsDisarmed()
            then
                if Fu.IsChasingTarget(enemy, bot) or #nEnemyHeroes > #nAllyHeroes and botHP < 0.5 then
                    return BOT_ACTION_DESIRE_HIGH, enemy
                end
            end
        end
    end

	if (Fu.IsPushing(bot) or Fu.IsDefending(bot) or Fu.IsFarming(bot)) and botHP < 0.5 and (fManaAfter > fManaThreshold1 or botHP < 0.2) and bAttacking then
		if Fu.IsValid(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and botTarget:IsCreep()
        and Fu.GetHP(botTarget) >= 0.75
        and not Fu.CanKillTarget(botTarget, bot:GetAttackDamage() * 4, DAMAGE_TYPE_PHYSICAL)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
	end

	if Fu.IsDoingRoshan(bot) then
        if  Fu.IsRoshan(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnTargetAdvanced(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and Fu.GetHP(botTarget) > 0.2
        and bAttacking
        and botHP < 0.5
        and (fManaAfter > fManaThreshold1 or botHP < 0.2)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
	end

	if Fu.IsDoingTormentor(bot) then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, nCastRange)
        and bAttacking
        and botHP < 0.5
        and (fManaAfter > fManaThreshold1 or botHP < 0.2)
        then
            return BOT_ACTION_DESIRE_HIGH, botTarget
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderInfest()
    if not Fu.CanCastAbility(Infest)
    or bot:HasModifier('modifier_life_stealer_infest')
    then
        return BOT_ACTION_DESIRE_NONE, nil
    end

    local nCastRange = Fu.GetProperCastRange(false, bot, Infest:GetCastRange())

	if bGoingOnSomeone then
        if  Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and not Fu.IsDisabled(botTarget)

        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
            if bot:HasScepter() then
                if botHP < 0.5
                and Fu.CanCastOnTargetAdvanced(botTarget)
                and Fu.IsInRange(bot, botTarget, nCastRange + 300)
                and (Fu.IsCore(botTarget) or Fu.GetHP(botTarget) > 0.5)
                then
                    bot.infest_target = 'hero'
                    return BOT_ACTION_DESIRE_HIGH, botTarget
                end
            end

            local nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), 900)
            if #nInRangeEnemy >= 2 then
                local hTarget = nil
                for _, allyHero in pairs(nAllyHeroes) do
                    if bot ~= allyHero
                    and Fu.IsValidHero(allyHero)
                    and Fu.IsInRange(bot, allyHero, 900)
                    and Fu.IsGoingOnSomeone(allyHero)
                    and (allyHero:GetAttackTarget() == botTarget or Fu.IsChasingTarget(allyHero, botTarget))
                    and not allyHero:IsIllusion()
                    and not Fu.IsMeepoClone(allyHero)
                    and allyHero:GetAttackRange() <= 324
                    then
                        hTarget = allyHero
                    end
                end

                if hTarget ~= nil then
                    bot.infest_target = 'hero'
                    return BOT_ACTION_DESIRE_HIGH, hTarget
                end
            end
		end
	end

	if bRetreating and not Fu.IsRealInvisible(bot) then
        for _, enemyHero in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemyHero)
            and Fu.IsInRange(bot, enemyHero, 800)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not enemyHero:IsDisarmed()
            then
                if Fu.IsChasingTarget(enemyHero, bot) or #nEnemyHeroes > #nAllyHeroes and botHP < 0.5 then
                    local enemyDamage = Fu.GetTotalEstimatedDamageToTarget(nEnemyHeroes, bot, 5.0)
                    if enemyDamage > (bot:GetHealth() + bot:GetHealthRegen() * 5.0) then
                        for _, allyHero in ipairs(nAllyHeroes) do
                            if bot ~= allyHero
                            and Fu.IsValidHero(allyHero)
                            and Fu.IsInRange(bot, allyHero, nCastRange + 500)
                            and Fu.IsRetreating(allyHero)
                            and not Fu.IsSuspiciousIllusion(allyHero)
                            and not Fu.IsMeepoClone(allyHero)
                            then
                                bot.infest_target = 'hero'
                                return BOT_ACTION_DESIRE_HIGH, allyHero
                            end
                        end

                        local nAllyLaneCreeps = bot:GetNearbyLaneCreeps(777, false)
                        for _, creep in ipairs(nAllyLaneCreeps) do
                            if Fu.IsValid(creep) then
                                bot.infest_target = 'creep'
                                return BOT_ACTION_DESIRE_HIGH, creep
                            end
                        end

                        local nEnemyCreeps = bot:GetNearbyCreeps(777, true)
                        for _, creep in ipairs(nEnemyCreeps) do
                            if Fu.IsValid(creep)
                            and not creep:IsAncientCreep()
                            and not creep:IsDominated()
                            and not creep:HasModifier('modifier_chen_holy_persuasion')
                            and not creep:HasModifier('modifier_dominated')
                            then
                                bot.infest_target = 'creep'
                                return BOT_ACTION_DESIRE_HIGH, creep
                            end
                        end
                    end
                end
            end
        end
	end

    return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderConsume()
    if not Fu.CanCastAbility(Consume) then
        return BOT_ACTION_DESIRE_NONE
    end

    local nDamage = Infest:GetSpecialValueInt('damage')
	local nRadius = Infest:GetSpecialValueInt('radius')

    if not bRetreating then
        for _, enemy in pairs(nEnemyHeroes) do
            if Fu.IsValidHero(enemy)
            and Fu.CanBeAttacked(enemy)
            and Fu.IsInRange(bot, enemy, nRadius - 100)
            and Fu.CanCastOnNonMagicImmune(enemy)
            and not enemy:HasModifier('modifier_abaddon_borrowed_time')
            and not enemy:HasModifier('modifier_dazzle_shallow_grave')
            and not enemy:HasModifier('modifier_necrolyte_reapers_scythe')
            then
                local nInRangeAlly = Fu.GetAlliesNearLoc(enemy:GetLocation(), 1200)
                local nInRangeEnemy = Fu.GetEnemiesNearLoc(enemy:GetLocation(), 1200)
                if #nInRangeAlly >= #nInRangeEnemy then
                    if Fu.CanKillTarget(enemy, nDamage, DAMAGE_TYPE_MAGICAL) then
                        return BOT_ACTION_DESIRE_HIGH
                    end
                end
            end
        end
    end

	if bGoingOnSomeone then
		if  Fu.IsValidHero(botTarget)
        and Fu.CanBeAttacked(botTarget)
        and Fu.CanCastOnNonMagicImmune(botTarget)
        and Fu.IsInRange(bot, botTarget, nRadius)
        and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
        and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
        and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
            if botHP > 0.8 then
                return BOT_ACTION_DESIRE_HIGH
            end
		end
	end

	if bRetreating then
        if #nEnemyHeroes == 0 and botHP > 0.9 then
            return BOT_ACTION_DESIRE_HIGH
        end
	end

    if botHP > 0.9 and #nAllyHeroes >= #nEnemyHeroes then
        return BOT_ACTION_DESIRE_HIGH
    end

    return BOT_ACTION_DESIRE_NONE
end

return X