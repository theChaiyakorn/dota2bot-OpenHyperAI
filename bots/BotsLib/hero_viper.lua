local X = {}
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local AbilityCtx = require(GetScriptDirectory()..'/FuncLib/systems/ability_context')
local Minion = require( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						{--pos2
							['t25'] = {0, 10},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {0, 10},
						},
						{--pos3
							['t25'] = {0, 10},
							['t20'] = {10, 0},
							['t15'] = {10, 0},
							['t10'] = {10, 0},
						}
}

local tAllAbilityBuildList = {
						{1,3,1,2,1,6,1,2,2,3,6,3,2,3,6},--pos2
						{1,3,1,3,1,6,1,2,3,3,6,2,2,2,6},--pos3
}

local nAbilityBuildList
local nTalentBuildList

if sRole == "pos_2"
then 
	nAbilityBuildList = tAllAbilityBuildList[1]
	nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList[1] )
else
	nAbilityBuildList = tAllAbilityBuildList[2]
	nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList[2] )
end

local sRandomItem_1 = RandomInt( 1, 9 ) > 5 and "item_sphere" or "item_lotus_orb"

local sRandomItem_2 = RandomInt( 1, 9 ) > 6 and "item_monkey_king_bar" or "item_butterfly"

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_ranged_carry_outfit",
	"item_dragon_lance",
	"item_yasha",
	"item_bloodthorn",
	"item_aghanims_shard",
	"item_manta",
	"item_travel_boots",
	sRandomItem_1,
	"item_hurricane_pike",
	sRandomItem_2,
	"item_hydras_breath",--
	"item_moon_shard",
	"item_travel_boots_2",

}

sRoleItemsBuyList['pos_2'] = {
	"item_mid_outfit",
	"item_dragon_lance",
	"item_yasha",
	"item_bloodthorn",
	"item_aghanims_shard",
	"item_manta",
	"item_travel_boots",
	sRandomItem_1,
	"item_hurricane_pike",
	sRandomItem_2,
	"item_hydras_breath",--
	"item_moon_shard",
	"item_travel_boots_2",
}

sRoleItemsBuyList['pos_3'] = {
	"item_tango",
	"item_double_branches",
	"item_enchanted_mango",
	"item_double_circlet",

	"item_magic_wand",
	"item_double_wraith_band",
	"item_boots",
	"item_power_treads",
	"item_mage_slayer",--
	"item_dragon_lance",
	sRandomItem_1,--
	"item_black_king_bar",--
	"item_aghanims_shard",
	"item_hurricane_pike",--
	"item_butterfly",
	"item_sheepstick",--
	"item_travel_boots_2",--
	"item_ultimate_scepter_2",
	"item_moon_shard",
}

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_3']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_3']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

	"item_mage_slayer",--
	"item_butterfly",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_mid' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )


X['bDeafaultAbility'] = true
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)
	Minion.MinionThink(hMinionUnit)
end

local PoisonAttack = SafeAbility(bot:GetAbilityByName('viper_poison_attack'), 'viper_poison_attack', 'viper')
local NetherToxin = SafeAbility(bot:GetAbilityByName('viper_nethertoxin'), 'viper_nethertoxin', 'viper')
-- local CorrosiveSkin = bot:GetAbilityByName('viper_corrosive_skin')
local Nosedive = SafeAbility(bot:GetAbilityByName('viper_nose_dive'), 'viper_nose_dive', 'viper')
local ViperStrike = SafeAbility(bot:GetAbilityByName('viper_viper_strike'), 'viper_viper_strike', 'viper')

local PoisonAttackDesire, PoisonAttackTarget
local NetherToxinDesire, NetherToxinLocation
local NosediveDesire, NosediveLocation
local ViperStrikeDesire, ViperStrikeTarget

local botTarget

local bGoingOnSomeone
local bRetreating
local bAttacking
local nBotMP
function X.SkillsComplement()
	if Fu.CanNotUseAbility( bot ) or bot:IsInvisible() then return end

	bGoingOnSomeone = Fu.IsGoingOnSomeone(bot)
	bRetreating = Fu.IsRetreating(bot)
	bAttacking = Fu.IsAttacking(bot)
	nBotMP = Fu.GetMP(bot)

	botTarget = Fu.GetProperTarget(bot)

	if Fu.IsValidHero(botTarget) then
		if not PoisonAttack:GetAutoCastState()
		then
			PoisonAttack:ToggleAutoCast()
		end
	else
		if PoisonAttack:GetAutoCastState()
		then
			PoisonAttack:ToggleAutoCast()
		end
	end

	ViperStrikeDesire, ViperStrikeTarget = X.ConsiderViperStrike()
	if ViperStrikeDesire > 0
	then
		if Fu.HasPowerTreads(bot)
		then
			Fu.SetQueuePtToINT(bot, true)
			bot:ActionQueue_UseAbilityOnEntity(ViperStrike, ViperStrikeTarget)
		else
			bot:Action_UseAbilityOnEntity(ViperStrike, ViperStrikeTarget)
		end

		return
	end

	NosediveDesire, NosediveLocation = X.ConsiderNosedive()
	if NosediveDesire > 0
	then
		if Fu.HasPowerTreads(bot)
		then
			Fu.SetQueuePtToINT(bot, true)
			bot:ActionQueue_UseAbilityOnLocation(Nosedive, NosediveLocation)
		else
			bot:Action_UseAbilityOnLocation(Nosedive, NosediveLocation)
		end

		return
	end

	NetherToxinDesire, NetherToxinLocation = X.ConsiderNetherToxin()
	if NetherToxinDesire > 0
	then
		if Fu.HasPowerTreads(bot)
		then
			Fu.SetQueuePtToINT(bot, true)
			bot:ActionQueue_UseAbilityOnLocation(NetherToxin, NetherToxinLocation)
		else
			bot:Action_UseAbilityOnLocation(NetherToxin, NetherToxinLocation)
		end

		return
	end

	PoisonAttackDesire, PoisonAttackTarget = X.ConsiderPoisonAttack()
	if PoisonAttackDesire > 0
	then
		bot:Action_UseAbilityOnEntity(PoisonAttack, PoisonAttackTarget)
		return
	end
end

function X.ConsiderPoisonAttack()
	if not PoisonAttack:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, PoisonAttack:GetCastRange())
	local nAttackRange = bot:GetAttackRange()
	local nDamage = PoisonAttack:GetSpecialValueInt('damage')
	local nDuration = PoisonAttack:GetSpecialValueInt('duration')

	if not bRetreating then
		local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
		for _, enemyHero in pairs(nEnemyHeroes)
		do
			if Fu.IsValidHero(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
			and Fu.CanKillTarget(enemyHero, nDamage * nDuration, DAMAGE_TYPE_MAGICAL)
			and not Fu.IsSuspiciousIllusion(enemyHero)
			and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
			and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
			and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
			and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
			and not enemyHero:HasModifier('modifier_templar_assassin_refraction_absorb')
			then
				return BOT_ACTION_DESIRE_HIGH, enemyHero
			end
		end
	end

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
		and botTarget:CanBeSeen()
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:IsMagicImmune()
		and not botTarget:IsInvulnerable()
        and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
			and Fu.GetManaAfter(PoisonAttack:GetManaCost()) * bot:GetMana() > ViperStrike:GetManaCost()
            then
                if Fu.IsInRange(bot, botTarget, nAttackRange)
				and not botTarget:IsAttackImmune()
				then
					if not PoisonAttack:GetAutoCastState()
					then
						PoisonAttack:ToggleAutoCast()
						return BOT_ACTION_DESIRE_HIGH, nil
					else
						return BOT_ACTION_DESIRE_NONE, nil
					end
				end

				if Fu.IsInRange(bot, botTarget, nCastRange)
				and not Fu.IsInRange(bot, botTarget, nAttackRange)
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget
				end
            end
		end
	end

	if bRetreating
	then
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)

		if Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.IsChasingTarget(nInRangeEnemy[1], bot)
		and not nInRangeEnemy[1]:HasModifier('modifier_viper_poison_attack_slow')
		and not nInRangeEnemy[1]:IsMagicImmune()
		and not nInRangeEnemy[1]:IsInvulnerable()
		then
			return BOT_ACTION_DESIRE_HIGH, nInRangeEnemy[1]
		end
	end

	if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
			if not PoisonAttack:GetAutoCastState()
			and nBotMP > 0.25
			then
				PoisonAttack:ToggleAutoCast()
				return BOT_ACTION_DESIRE_HIGH, nil
			else
				if PoisonAttack:GetAutoCastState()
				and nBotMP < 0.25
				then
					PoisonAttack:ToggleAutoCast()
					return BOT_ACTION_DESIRE_HIGH, nil
				end

				return BOT_ACTION_DESIRE_NONE, nil
			end
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
        then
			if not PoisonAttack:GetAutoCastState()
			and nBotMP > 0.25
			then
				PoisonAttack:ToggleAutoCast()
				return BOT_ACTION_DESIRE_HIGH, nil
			else
				if PoisonAttack:GetAutoCastState()
				and nBotMP < 0.25
				then
					PoisonAttack:ToggleAutoCast()
					return BOT_ACTION_DESIRE_HIGH, nil
				end

				return BOT_ACTION_DESIRE_NONE, nil
			end
        end
    end

	local nAllyHeroes = Fu.GetNearbyHeroes(bot,nCastRange, false, BOT_MODE_NONE)
    for _, allyHero in pairs(nAllyHeroes)
    do
        local nAllyInRangeEnemy = Fu.GetNearbyHeroes(allyHero, 1200, true, BOT_MODE_NONE)

        for _, enemyHero in pairs(nAllyInRangeEnemy)
        do
            if Fu.IsValidHero(allyHero)
            and Fu.IsRetreating(allyHero)
            and allyHero:WasRecentlyDamagedByAnyHero(2)
            and not allyHero:IsIllusion()
            then
                if Fu.IsValidHero(enemyHero)
                and Fu.CanCastOnNonMagicImmune(enemyHero)
                and Fu.IsInRange(bot, enemyHero, nCastRange)
                and Fu.IsChasingTarget(enemyHero, allyHero)
                and not Fu.IsDisabled(enemyHero)
                and not Fu.IsTaunted(enemyHero)
                and not Fu.IsSuspiciousIllusion(enemyHero)
                and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
				and not enemyHero:HasModifier('modifier_viper_poison_attack_slow')
				then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero
                end
            end
        end
    end

	if PoisonAttack:GetAutoCastState()
	then
		PoisonAttack:ToggleAutoCast()
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderNetherToxin()
	if not NetherToxin:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, NetherToxin:GetCastRange())
	local nRadius = NetherToxin:GetSpecialValueInt('radius')
	local nAbilityLevel = NetherToxin:GetLevel()

	if bGoingOnSomeone
	then
		if Fu.IsValidHero(botTarget)
		and Fu.CanCastOnNonMagicImmune(botTarget)
		and Fu.IsInRange(bot, botTarget, nCastRange)
		and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
		and not botTarget:HasModifier('modifier_viper_nethertoxin')
		then
			local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
			local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

			if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
			and #nInRangeAlly >= #nInRangeEnemy
			then
				if Fu.IsInRange(bot, botTarget, nCastRange)
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
				end

				if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
				and not Fu.IsInRange(bot, botTarget, nCastRange)
				then
					return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
				end
			end
		end
	end

	if bRetreating
    and bot:GetActiveModeDesire() > 0.5
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
			and Fu.CanCastOnNonMagicImmune(enemyHero)
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, enemyHero:GetExtrapolatedLocation(0.5)
                end
            end
        end
	end

	if Fu.IsPushing(bot) or Fu.IsDefending(bot)
    then
        local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(1000, true)
		if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 4
		and not Fu.IsRunning(nEnemyLaneCreeps[1])
		then
			return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
		end
    end

	if Fu.IsFarming(bot)
	and Fu.GetManaAfter(NetherToxin:GetManaCost()) * bot:GetMana() > ViperStrike:GetManaCost()
	and nAbilityLevel >= 2
    then
		if bAttacking
		then
			local nNeutralCreeps = bot:GetNearbyNeutralCreeps(bot:GetAttackRange() + 200)
			local nCreepCount = Fu.GetNearbyAroundLocationUnitCount(true, false, nRadius, Fu.GetCenterOfUnits(nNeutralCreeps))

			if nNeutralCreeps ~= nil and #nNeutralCreeps >= 1
			and Fu.GetManaAfter(NetherToxin:GetManaCost()) * bot:GetMana() > ViperStrike:GetManaCost()
			then
				if Fu.IsBigCamp(nNeutralCreeps)
				or nNeutralCreeps[1]:IsAncientCreep()
				then
					if #nNeutralCreeps >= 2
					and nCreepCount >= 2
					then
						return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
					end
				else
					if #nNeutralCreeps >= 3
					and nCreepCount >= 2
					then
						return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nNeutralCreeps)
					end
				end
			end

			local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(bot:GetAttackRange() + 200, true)
			nCreepCount = Fu.GetNearbyAroundLocationUnitCount(true, false, nRadius, Fu.GetCenterOfUnits(nEnemyLaneCreeps))
			if nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3
			and nCreepCount >= 2
			then
				return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nEnemyLaneCreeps)
			end
		end
    end

	if Fu.IsDoingRoshan(bot)
    then
        if Fu.IsRoshan(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
		and not botTarget:IsMagicImmune()
		and not botTarget:HasModifier('modifier_viper_nethertoxin')
        then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

    if Fu.IsDoingTormentor(bot)
    then
        if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(bot, botTarget, 500)
        and bAttacking
		and not botTarget:HasModifier('modifier_viper_nethertoxin')
        then
			return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
        end
    end

	return BOT_ACTION_DESIRE_NONE, 0
end

function X.ConsiderViperStrike()
	if not ViperStrike:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, nil
	end

	local nCastRange = ViperStrike:GetCastRange()
	local nDamage = ViperStrike:GetSpecialValueInt('damage')
	local nDuration = ViperStrike:GetSpecialValueInt('duration')

	local nEnemysHerosInCastRange = Fu.GetNearbyHeroes(bot, nCastRange + 80 , true, BOT_MODE_NONE )
	local nWeakestEnemyHeroInCastRange = Fu.GetVulnerableWeakestUnit(bot, true, true, nCastRange + 80)

	if bGoingOnSomeone
	then
		local nInRangeEnemy = Fu.GetEnemiesNearLoc(bot:GetLocation(), 1200)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidTarget(enemyHero)
			and Fu.CanCastOnTargetAdvanced(enemyHero)
            and (nDamage + nDuration) < enemyHero:GetHealth()
            and not enemyHero:HasModifier('modifier_abaddon_borrowed_time')
            and not enemyHero:HasModifier('modifier_dazzle_shallow_grave')
            and not enemyHero:HasModifier('modifier_necrolyte_reapers_scythe')
            and not enemyHero:HasModifier('modifier_oracle_false_promise_timer')
            and not enemyHero:HasModifier('modifier_item_aeon_disk_buff')
            and not enemyHero:HasModifier('modifier_item_blade_mail_reflect')
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and #nInRangeAlly >= #nTargetInRangeAlly
                then
                    if enemyHero:GetUnitName() == 'npc_dota_hero_bristleback'
					or enemyHero:GetUnitName() == 'npc_dota_hero_spectre'
					or enemyHero:GetUnitName() == 'npc_dota_hero_huskar'
					or enemyHero:GetUnitName() == 'npc_dota_hero_dragon_knight'
					or enemyHero:GetUnitName() == 'npc_dota_hero_tidehunter'
					or enemyHero:GetUnitName() == 'npc_dota_hero_phantom_assassin'
					or enemyHero:GetUnitName() == 'npc_dota_hero_antimage'
					or enemyHero:GetUnitName() == 'npc_dota_hero_mars'
					or enemyHero:GetUnitName() == 'npc_dota_hero_centaur'
					or enemyHero:GetUnitName() == 'npc_dota_hero_necrolyte'
					then
						return BOT_ACTION_DESIRE_HIGH, enemyHero
					end
                end
            end
        end
	end

	if Fu.IsValidHero(nEnemysHerosInCastRange[1])
	and not Fu.IsSuspiciousIllusion(nEnemysHerosInCastRange[1])
	then
		if nWeakestEnemyHeroInCastRange ~= nil
		then
			if nWeakestEnemyHeroInCastRange:GetHealth() < nWeakestEnemyHeroInCastRange:GetActualIncomingDamage(nDamage * nDuration, DAMAGE_TYPE_MAGICAL)
			and Fu.CanCastOnNonMagicImmune(nWeakestEnemyHeroInCastRange)
			and not Fu.IsSuspiciousIllusion(nWeakestEnemyHeroInCastRange)
			and not nWeakestEnemyHeroInCastRange:HasModifier('modifier_abaddon_borrowed_time')
			and not nWeakestEnemyHeroInCastRange:HasModifier('modifier_dazzle_shallow_grave')
			and not nWeakestEnemyHeroInCastRange:HasModifier('modifier_necrolyte_reapers_scythe')
			and not nWeakestEnemyHeroInCastRange:HasModifier('modifier_oracle_false_promise_timer')
			and not nWeakestEnemyHeroInCastRange:HasModifier('modifier_item_sphere_target')
			then
				return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyHeroInCastRange
			end

			if Fu.IsValidHero(botTarget)
			then
				if Fu.IsInRange(bot, botTarget, nCastRange + 75)
				and Fu.CanCastOnNonMagicImmune(botTarget)
				and Fu.CanCastOnTargetAdvanced(botTarget)
				and not Fu.IsSuspiciousIllusion(botTarget)
				and not botTarget:HasModifier('modifier_necrolyte_reapers_scythe')
				and not botTarget:HasModifier('modifier_item_sphere_target')
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget
				else
					if Fu.CanCastOnTargetAdvanced(nWeakestEnemyHeroInCastRange)
					then
						return BOT_ACTION_DESIRE_HIGH, nWeakestEnemyHeroInCastRange
					end
				end
			end
		end

		if Fu.CanCastOnNonMagicImmune(nEnemysHerosInCastRange[1])
		and Fu.CanCastOnTargetAdvanced(nEnemysHerosInCastRange[1])
		and not nEnemysHerosInCastRange[1]:HasModifier('modifier_abaddon_borrowed_time')
		and not nEnemysHerosInCastRange[1]:HasModifier('modifier_dazzle_shallow_grave')
		and not nEnemysHerosInCastRange[1]:HasModifier('modifier_necrolyte_reapers_scythe')
		and not nEnemysHerosInCastRange[1]:HasModifier('modifier_oracle_false_promise_timer')
		and not nEnemysHerosInCastRange[1]:HasModifier('modifier_item_sphere_target')
		then
			return BOT_ACTION_DESIRE_HIGH, nEnemysHerosInCastRange[1]
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		and Fu.IsInRange(bot, botTarget, 500)
		and bAttacking
		and not botTarget:HasModifier('modifier_roshan_spell_block')
		then
			return BOT_ACTION_DESIRE_HIGH, botTarget
		end
	end

	return BOT_ACTION_DESIRE_NONE, nil
end

function X.ConsiderNosedive()
	if not Nosedive:IsTrained()
	or not Nosedive:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE, 0
	end

	local nCastRange = Fu.GetProperCastRange(false, bot, Nosedive:GetCastRange())
	local nRadius = 500

	if bGoingOnSomeone
	then
		if Fu.IsValidTarget(botTarget)
        and not Fu.IsSuspiciousIllusion(botTarget)
        and not botTarget:IsMagicImmune()
		then
            local nInRangeAlly = Fu.GetNearbyHeroes(botTarget, 1200, true, BOT_MODE_NONE)
            local nInRangeEnemy = Fu.GetNearbyHeroes(botTarget, 1200, false, BOT_MODE_NONE)

            if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
            and #nInRangeAlly >= #nInRangeEnemy
            then
                nInRangeEnemy = Fu.GetEnemiesNearLoc(botTarget:GetLocation(), nRadius)

                if nInRangeEnemy ~= nil and #nInRangeEnemy >= 1
                then
					if Fu.IsInRange(bot, botTarget, nCastRange)
					then
						return BOT_ACTION_DESIRE_HIGH, Fu.GetCenterOfUnits(nInRangeEnemy)
					end

					if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
					and not Fu.IsInRange(bot, botTarget, nCastRange)
					then
						return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetCenterOfUnits(nInRangeEnemy), nCastRange)
					end
                end

				if Fu.IsInRange(bot, botTarget, nCastRange)
				then
					return BOT_ACTION_DESIRE_HIGH, botTarget:GetLocation()
				end

				if Fu.IsInRange(bot, botTarget, nCastRange + nRadius)
				and not Fu.IsInRange(bot, botTarget, nCastRange)
				then
					return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, botTarget:GetLocation(), nCastRange)
				end
            end
		end
	end

	if bRetreating
	and bot:GetActiveModeDesire() > 0.75
	then
        local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nCastRange, true, BOT_MODE_NONE)
        for _, enemyHero in pairs(nInRangeEnemy)
        do
            if Fu.IsValidHero(enemyHero)
            and Fu.CanCastOnNonMagicImmune(enemyHero)
            and Fu.IsChasingTarget(enemyHero, bot)
			and bot:IsFacingLocation(Fu.GetTeamFountain(), 30)
			and bot:DistanceFromFountain() > 600
            and not Fu.IsSuspiciousIllusion(enemyHero)
            and not Fu.IsDisabled(enemyHero)
			and not Fu.IsRealInvisible(bot)
            then
                local nInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, true, BOT_MODE_NONE)
                local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, 1200, false, BOT_MODE_NONE)

                if nInRangeAlly ~= nil and nTargetInRangeAlly ~= nil
                and ((#nTargetInRangeAlly > #nInRangeAlly)
                    or bot:WasRecentlyDamagedByAnyHero(2))
                then
                    return BOT_ACTION_DESIRE_HIGH, Fu.Site.GetXUnitsTowardsLocation(bot, Fu.GetTeamFountain(), nCastRange)
                end
            end
        end
	end

	return BOT_ACTION_DESIRE_NONE, 0
end

return X