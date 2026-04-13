require( GetScriptDirectory()..'/FuncLib/systems/global_overrides' )
local Role = require( GetScriptDirectory()..'/FuncLib/systems/role' )

local Item = {}

local tSpecifiedItemIndex = {

	["item_tpscroll"] = true,
	["item_travel_boots"] = true,
	["item_travel_boots_2"] = true,
	["item_blink"] = true,
	["item_black_king_bar"] = true,
	["item_manta"] = true,
	["item_force_staff"] = true,

}

local sNeedDebugItemList =
{
	"item_mango_tree",
--	"item_iron_talon",
	"item_arcane_ring",
	"item_royal_jelly",
	"item_trusty_shovel",
	"item_clumsy_net",
	"item_essence_ring",
	"item_repair_kit",
	"item_greater_faerie_fire",
--	"item_spider_legs",
	"item_flicker",
	"item_ninja_gear",
	"item_illusionsts_cape",
	"item_havoc_hammer",
	"item_minotaur_horn",
	"item_force_boots",
	"item_woodland_striders",
	"item_fallen_sky",
	"item_ex_machina",

	"item_abyssal_blade",
	"item_ancient_janggo",
--	"item_arcane_boots",
	"item_armlet",
--	"item_bfury",
	"item_black_king_bar",
	"item_blade_mail",
	"item_blink",
	"item_bloodstone",
	"item_bloodthorn",
	"item_bottle",
--	"item_clarity",
	"item_crimson_guard",
	"item_cyclone",
	"item_dagon",
	"item_dagon_2",
	"item_dagon_3",
	"item_dagon_4",
	"item_dagon_5",
	"item_diffusal_blade",
	"item_enchanted_mango",
	"item_ethereal_blade",
--	"item_faerie_fire",
	"item_flask",
	"item_force_staff",
	"item_ghost",
	"item_glimmer_cape",
	"item_guardian_greaves",
--	"item_hand_of_midas",
	"item_heavens_halberd",
	"item_helm_of_the_dominator",
--	"item_hood_of_defiance",
	"item_hurricane_pike",
	"item_invis_sword",
	"item_lotus_orb",
--	"item_magic_stick",
--	"item_magic_wand",
	"item_manta",
--	"item_mask_of_madness",
--	"item_medallion_of_courage", -- removed from game
	"item_mekansm",
	"item_meteor_hammer",
	"item_mjollnir",
	"item_moon_shard",
	"item_necronomicon",
	"item_necronomicon_2",
	"item_necronomicon_3",
	"item_nullifier",
	"item_orchid",
--	"item_phase_boots",
	"item_pipe",
--	"item_power_treads",
--	"item_quelling_blade",
	"item_refresher",
	"item_refresher_shard",
--	"item_ring_of_basilius",
	"item_rod_of_atos",
	"item_satanic",
--	"item_shadow_amulet",
	"item_sheepstick",
	"item_shivas_guard",
	"item_silver_edge",
	"item_solar_crest",
	"item_sphere",
	"item_spirit_vessel",
--	"item_tango",
--	"item_tango_single",
	"item_tome_of_knowledge",
	"item_tpscroll",
--	"item_travel_boots",
--	"item_travel_boots_2",
	"item_urn_of_shadows",
	"item_veil_of_discord",
}

local function ListToSet(list)
	local set = {}
	for _, v in pairs(list) do set[v] = true end
	return set
end

local tDebugItemList = ListToSet(sNeedDebugItemList)

Item['sBasicItems'] = {
	'item_aegis',
	'item_boots_of_elves',
	'item_belt_of_strength',
	'item_blade_of_alacrity',
	'item_blades_of_attack',
	'item_blight_stone',
	'item_blink',
	'item_boots',
	'item_bottle',
	'item_branches',
	'item_broadsword',
	'item_chainmail',
	'item_cheese',
	'item_circlet',
	'item_clarity',
	'item_claymore',
	'item_cloak',
	'item_crown',
	'item_demon_edge',
	'item_dust',
	'item_eagle',
	'item_enchanted_mango',
	'item_energy_booster',
	'item_faerie_fire',
	'item_flask',
	'item_gauntlets',
	'item_gem',
	'item_ghost',
	'item_gloves',
	'item_holy_locket',
	'item_hyperstone',
	'item_infused_raindrop',
	'item_javelin',
	'item_lifesteal',
	'item_magic_stick',
	'item_mantle',
	'item_mithril_hammer',
	'item_mystic_staff',
	'item_ogre_axe',
	'item_orb_of_frost',
	'item_platemail',
	'item_point_booster',
	'item_quarterstaff',
	'item_quelling_blade',
	'item_reaver',
	'item_refresher_shard',
	'item_ring_of_health',
	'item_ring_of_protection',
	'item_ring_of_regen',
	'item_robe',
	'item_relic',
	'item_sobi_mask',
	'item_shadow_amulet',
	'item_slippers',
	'item_smoke_of_deceit',
	'item_staff_of_wizardry',
	'item_talisman_of_evasion',
	'item_tango',
	'item_tango_single',
	'item_tome_of_knowledge',
	'item_tpscroll',
	'item_ultimate_orb',
	'item_vitality_booster',
	'item_void_stone',
	'item_wind_lace',
	'item_ward_observer',
	'item_ward_sentry',
	'item_blitz_knuckles', --闪电指套
	'item_voodoo_mask', --巫毒面具
	'item_fluffy_hat', --毛毛帽
	'item_blood_grenade',
	'item_wizard_hat',
	'item_chasm_stone',
	'item_splintmail',
	'item_shawl',
}

Item['sSeniorItems'] = {

	'item_arcane_boots',
	'item_buckler',
	'item_basher',
	'item_dagon',
	'item_dagon_2',
	'item_dagon_3',
	'item_dagon_4',
	'item_dragon_lance',
	'item_force_staff',
	'item_headdress',
--	'item_hood_of_defiance', -- removed from game
	'item_invis_sword',
	'item_kaya',
	'item_lesser_crit',
	'item_maelstrom',
--	'item_medallion_of_courage', -- removed from game
	'item_mekansm',
--	'item_necronomicon', -- removed from game
--	'item_necronomicon_2', -- removed from game
	'item_essence_distiller',
	'item_specialists_array',
	'item_ring_of_basilius',
	'item_sange',
	'item_soul_booster',
	'item_travel_boots',
	'item_urn_of_shadows',
	'item_vanguard',
	'item_yasha',
	
	'item_rod_of_atos',
	'item_blink',
	'item_cyclone',
	'item_helm_of_the_dominator',
	'item_rod_of_atos',

}

Item['sTopItems'] = {

	'item_clarity',
	'item_tango',
	'item_flask',
	'item_faerie_fire',
	'item_enchanted_mango',
	'item_infused_raindrop',
	'item_blood_grenade',

	'item_abyssal_blade',
	'item_aether_lens',
	'item_armlet',
	'item_assault',
	'item_ancient_janggo',
	'item_aeon_disk',
	'item_bfury',
	'item_black_king_bar',
	'item_blade_mail',
	'item_bloodstone',
	'item_bloodthorn',
	'item_bottle',
	'item_bracer',
	'item_butterfly',
	'item_crimson_guard',
	'item_dagon_5',
	'item_desolator',
	'item_diffusal_blade',
	'item_echo_sabre',
	'item_ethereal_blade',
	'item_gem',
	'item_glimmer_cape',
	'item_guardian_greaves',
	'item_greater_crit',
	'item_hand_of_midas',
	'item_heart',
	'item_heavens_halberd',
	'item_hurricane_pike',
	'item_holy_locket',
	'item_kaya_and_sange',
	'item_lotus_orb',
	'item_manta',
	'item_mask_of_madness',
	'item_mjollnir',
	'item_monkey_king_bar',
	'item_moon_shard',
	'item_meteor_hammer',
--	'item_necronomicon_3', -- removed from game
	'item_null_talisman',
	'item_nullifier',
	'item_orb_of_frost',
	'item_phase_boots',
	'item_pipe',
	'item_power_treads',
	'item_radiance',
	'item_rapier',
	'item_refresher',
	'item_sange_and_yasha',
	'item_satanic',
	'item_sheepstick',
	'item_sphere',
	'item_shivas_guard',
	'item_silver_edge',
	'item_solar_crest',
	'item_soul_ring',
	'item_skadi',
	'item_spirit_vessel',
	'item_tpscroll',
	'item_tranquil_boots',
	'item_travel_boots_2',
	'item_veil_of_discord',
	'item_vladmir',
	'item_wraith_band',
	'item_yasha_and_kaya',
	
	'item_revenants_brooch',
	'item_boots_of_bearing',
--	'item_wraith_pact', -- removed from game

	'item_essence_distiller',
	'item_specialists_array',
	'item_hydras_breath',
	'item_consecrated_wraps',
	'item_crellas_crozier',
}

local tTopItemList = ListToSet(Item['sTopItems'])

Item['tEarlyItem'] = {
	 'item_clarity',
	 'item_faerie_fire',
	 'item_tango',
	 'item_flask',
	 'item_infused_raindrop',
	 -- 'item_magic_stick',
	 -- 'item_orb_of_frost',
	 'item_bracer',
	 'item_wraith_band',
	 'item_null_talisman',
	 'item_bottle',
	 'item_soul_ring',
	 -- 'item_magic_wand',
	 -- 'item_ancient_janggo',
	 'item_refresher_shard',
	 'item_cheese',
	 'item_blood_grenade',
	 'item_branches',
	 'item_gauntlets',
	 'item_slippers',
	 'item_circlet',
	 'item_mantle',
}

-- Extra items supports (pos 4-5) should sell when inventory is full.
-- Does NOT include wards, dust, smoke, gem — those are core support tools to keep.
Item['tSupportSellWhenFull'] = {
	'item_magic_wand',
	'item_magic_stick',
	'item_bracer',
	'item_wraith_band',
	'item_null_talisman',
	'item_infused_raindrop',
	'item_soul_ring',
	'item_bottle',
	'item_orb_of_frost',
	'item_blood_grenade',
	'item_ring_of_basilius',
	'item_urn_of_shadows',
}

Item['tEarlyConsumableItem'] = {
	 'item_clarity',
	 'item_faerie_fire',
	 'item_tango',
	 'item_enchanted_mango',
	 'item_flask',
	 'item_infused_raindrop',
	 'item_magic_stick',
	 'item_quelling_blade', -- for bf.
	 'item_branches',
	 -- 'item_magic_wand',
	 'item_blood_grenade',
	 'item_gauntlets',
	 'item_slippers',
	 'item_circlet',
	 'item_mantle',
	 'item_magic_wand',
	 'item_recipe_magic_wand',
	 'item_magic_stick',
	 'item_smoke_of_deceit'
	--  'item_dust',
	--  'item_ward_sentry',
	--  'item_ward_observer',
}

Item['tEarlyBoots'] = {
	'item_boots',
	'item_phase_boots',
	'item_power_treads',
	'item_tranquil_boots',
	'item_arcane_boots'
}

Item['sCanNotSwitchItems'] = {
		'item_aegis',
		'item_refresher_shard',
		'item_cheese',
		'item_bloodstone',
		'item_gem',
		'item_moon_shard',
		'item_black_king_bar', -- prevent keep swapping with critical items in other settings
		-- 'item_ward_sentry', -- prevent keep swapping with critical items in other settings
		'item_famango',            -- Healing Lotus: ally-castable, higher value than wand
		'item_great_famango',      -- Great Healing Lotus
		'item_greater_famango',    -- Greater Healing Lotus: very valuable for supports
}

Item['sSellList'] = {
	"item_black_king_bar",
	"item_quelling_blade",

	"item_ultimate_scepter",
	"item_magic_wand",

	"item_cyclone",
	"item_magic_wand",

	"item_shivas_guard",
	'item_magic_wand',

	"item_lotus_orb",
	"item_quelling_blade",

	"item_assault",
	"item_magic_wand",

	"item_assault",
	"item_quelling_blade",

	"item_assault",
	"item_orb_of_corrosion",

	"item_travel_boots",
	"item_magic_wand",

	"item_travel_boots",
	"item_phase_boots",

	"item_travel_boots_2",
	"item_phase_boots",

	"item_travel_boots",
	"item_arcane_boots",

	"item_assault",
	"item_ancient_janggo",

	"item_vladmir",
	"item_magic_wand",

	"item_solar_crest",
	"item_pavise",

	"item_boots_of_bearing",
	"item_drum_of_endurance",

	"item_spirit_vessel",
	"item_urn_of_shadows",

	"item_magic_wand",
	"item_recipe_magic_wand",
	
	-- ... existing entries ...
    'item_splintmail', 'item_chainmail',
    'item_shawl', 'item_cloak',
    'item_wizard_hat', 'item_circlet',
}

local tCanNotSwitchItemList = ListToSet(Item['sCanNotSwitchItems'])


local sConsumableList = {

	'item_clarity',
	'item_tango',
	'item_flask',
	'item_faerie_fire',
	'item_enchanted_mango',
	'item_infused_raindrop',
	'item_blood_grenade',

	'item_mango_tree',
	'item_royal_jelly',
	'item_greater_faerie_fire',
	"item_repair_kit",

	'item_cheese',
	'item_refresher_shard',
	'item_aegis',

}
local tConsumableItemList = ListToSet(sConsumableList)

local sNotSellItemList = {
	'item_abyssal_blade',
	'item_assault',
	'item_black_king_bar',
	'item_bloodstone',
	'item_bloodthorn',
	'item_butterfly',
	'item_bfury',
	'item_cheese',
	'item_crimson_guard',
	'item_pipe',
	'item_dust',
	'item_gem',
	'item_greater_crit',
	'item_guardian_greaves',
	'item_heart',
	'item_heavens_halberd',
	'item_hyperstone',
	'item_manta',
	'item_hurricane_pike',
	'item_mjollnir',
	'item_nullifier',
	'item_octarine_core',
	'item_radiance',
	'item_rapier',
	'item_refresher',
	'item_refresher_shard',
	'item_satanic',
	'item_sheepstick',
	'item_shivas_guard',
	'item_silver_edge',
	'item_skadi',
	'item_sphere',
	'item_ultimate_scepter',
	'item_travel_boots',
	'item_travel_boots_2',
	'item_ward_observer',
}
local tNotSellItemList = ListToSet(sNotSellItemList)



local tSmallItemList = {

	['item_tpscroll'] = 1,
	['item_flask'] = 1,
	['item_enchanted_mango'] = 1,

}


function Item.GetComponentList( itemName )

	local componentList = {}
	local rawItemComponentTable = GetItemComponents( itemName )

	if #rawItemComponentTable == 0
	then
		componentList = { itemName }
	else
		local itemComponentList = rawItemComponentTable[1]
		for _, v in pairs( itemComponentList )
		do
			componentList[#componentList + 1] = v
		end	
	end
	
	return componentList
	
end


-- Auto-populate item component lists from Valve API
local autoComponentItems = {
	'item_abyssal_blade', 'item_aether_lens', 'item_arcane_boots', 'item_armlet',
	'item_assault', 'item_ancient_janggo', 'item_aeon_disk', 'item_bfury',
	'item_black_king_bar', 'item_blade_mail', 'item_bloodstone', 'item_bloodthorn',
	'item_bracer', 'item_buckler', 'item_butterfly', 'item_basher',
	'item_crimson_guard', 'item_cyclone',
	'item_dagon', 'item_dagon_2', 'item_dagon_3', 'item_dagon_4', 'item_dagon_5',
	'item_desolator', 'item_diffusal_blade', 'item_dragon_lance', 'item_echo_sabre',
	'item_ethereal_blade', 'item_force_staff', 'item_glimmer_cape',
	'item_guardian_greaves', 'item_greater_crit', 'item_hand_of_midas',
	'item_headdress', 'item_heart', 'item_heavens_halberd',
	'item_helm_of_the_dominator', 'item_hurricane_pike', 'item_holy_locket',
	'item_invis_sword', 'item_kaya', 'item_kaya_and_sange', 'item_lotus_orb',
	'item_lesser_crit', 'item_maelstrom', 'item_magic_wand', 'item_manta',
	'item_mask_of_madness', 'item_mekansm', 'item_mjollnir',
	'item_monkey_king_bar', 'item_moon_shard', 'item_meteor_hammer',
	'item_necronomicon', 'item_necronomicon_2', 'item_necronomicon_3',
	'item_null_talisman', 'item_nullifier', 'item_oblivion_staff',
	'item_octarine_core', 'item_orchid', 'item_pers', 'item_pipe',
	'item_radiance', 'item_rapier', 'item_refresher', 'item_ring_of_basilius',
	'item_rod_of_atos', 'item_sange', 'item_sange_and_yasha', 'item_satanic',
	'item_sheepstick', 'item_sphere', 'item_shivas_guard', 'item_silver_edge',
	'item_solar_crest', 'item_soul_booster', 'item_soul_ring', 'item_skadi',
	'item_spirit_vessel', 'item_tranquil_boots', 'item_travel_boots',
	'item_travel_boots_2', 'item_urn_of_shadows', 'item_ultimate_scepter_2',
	'item_vanguard', 'item_veil_of_discord', 'item_vladmir', 'item_wraith_band',
	'item_yasha_and_kaya',
	'item_falcon_blade', 'item_orb_of_corrosion', 'item_witch_blade',
	'item_gungir', 'item_mage_slayer', 'item_helm_of_the_overlord',
	'item_overwhelming_blink', 'item_swift_blink', 'item_arcane_blink',
	'item_wind_waker', 'item_revenants_brooch', 'item_boots_of_bearing',
	'item_pavise', 'item_phylactery', 'item_harpoon', 'item_disperser',
	'item_blood_grenade', 'item_angels_demise', 'item_devastator',
	'item_essence_distiller', 'item_specialists_array', 'item_hydras_breath',
	'item_consecrated_wraps', 'item_crellas_crozier',
	'item_new_1', 'item_new_2', 'item_new_3', 'item_new_4', 'item_new_5', 'item_new_6',
}
for _, name in pairs(autoComponentItems) do
	Item[name] = GetItemComponents(name)[1]
end

-- Hardcoded component overrides (Valve API returns wrong/missing data for these)
Item['item_phase_boots']       = { 'item_blades_of_attack', 'item_boots', 'item_chainmail' }
Item['item_power_treads_agi']  = { 'item_boots', 'item_boots_of_elves', 'item_gloves' }
Item['item_power_treads_int']  = { 'item_boots', 'item_robe', 'item_gloves' }
Item['item_power_treads_str']  = { 'item_boots', 'item_belt_of_strength', 'item_gloves' }
Item['item_power_treads']      = { 'item_boots', 'item_belt_of_strength', 'item_gloves' }
Item['item_ultimate_scepter']  = { 'item_point_booster', 'item_ogre_axe', 'item_blade_of_alacrity', 'item_staff_of_wizardry' }
Item['item_yasha']             = { 'item_boots_of_elves', 'item_blade_of_alacrity', 'item_recipe_yasha' }


--Self_Define Item
local tDefineItemRealName = {

['item_double_tango'] = "item_tango",
['item_double_clarity'] = "item_clarity",
['item_double_flask'] = "item_flask",
['item_double_enchanted_mango'] = "item_enchanted_mango",


['item_broken_satanic'] = "item_satanic",


['item_power_treads_agi'] = "item_power_treads",
['item_power_treads_int'] = "item_power_treads",
['item_power_treads_str'] = "item_power_treads",



['item_mid_outfit'] = "item_power_treads",
['item_medusa_outfit'] = "item_power_treads",
['item_templar_assassin_outfit'] = "item_power_treads",


['item_ranged_carry_outfit'] = "item_power_treads",
['item_melee_carry_outfit'] = "item_power_treads",
['item_phantom_assassin_outfit'] = "item_power_treads",
['item_juggernaut_outfit'] = "item_phase_boots",
['item_huskar_outfit'] = "item_phase_boots",
['item_sven_outfit'] = "item_phase_boots",
['item_bristleback_outfit'] = "item_power_treads",


['item_tank_outfit'] = "item_power_treads",
['item_dragon_knight_outfit'] = "item_soul_ring",



['item_mage_outfit'] = "item_tranquil_boots",
['item_crystal_maiden_outfit'] = "item_magic_wand",
['item_priest_outfit'] = "item_arcane_boots",


}

-- Custom composite item definitions

Item['item_double_branches']		= { 'item_branches', 'item_branches', }

Item['item_double_tango']			= { 'item_tango', 'item_tango', }

Item['item_double_clarity']			= { 'item_clarity', 'item_clarity', }

Item['item_double_flask']			= { 'item_flask', 'item_flask', }

Item['item_double_enchanted_mango']	= { 'item_enchanted_mango', 'item_enchanted_mango', }

Item['item_double_circlet']			= { 'item_circlet', 'item_circlet', }

Item['item_double_slippers']		= { 'item_slippers', 'item_slippers', }

Item['item_double_mantle']			= { 'item_mantle', 'item_mantle', }

Item['item_double_gauntlets']		= { 'item_gauntlets', 'item_gauntlets', }

Item['item_double_wraith_band']		= { 'item_wraith_band', 'item_wraith_band', }

Item['item_double_null_talisman']	= { 'item_null_talisman', 'item_null_talisman', }

Item['item_double_bracer']			= { 'item_bracer', 'item_bracer', }

Item['item_double_crown']			= { 'item_crown', 'item_crown', }

Item['item_broken_hurricane_pike']	= { 'item_force_staff', 'item_recipe_hurricane_pike' }

Item['item_broken_silver_edge']		= { 'item_blitz_knuckles', 'item_broadsword', 'item_recipe_silver_edge'}

Item['item_broken_bfury']			= { 'item_ring_of_health', 'item_void_stone', 'item_broadsword', 'item_claymore' }

Item['item_broken_satanic']			= { 'item_reaver', 'item_claymore' }

Item['item_broken_soul_ring']		= { 'item_ring_of_protection', 'item_recipe_soul_ring' }

Item['item_four_branches']		= { 'item_branches', 'item_branches', 'item_branches', 'item_branches' }

Item['item_six_branches']		= { 'item_branches', 'item_branches', 'item_branches', 'item_branches', 'item_branches', 'item_branches'}


Item['item_mid_outfit']					= { 'item_tango', 'item_faerie_fire', 'item_double_branches', 'item_wraith_band', 'item_flask', 'item_magic_stick', 'item_recipe_magic_wand', 'item_power_treads_agi' }

Item['item_medusa_outfit']				= { 'item_null_talisman', 'item_double_branches', 'item_null_talisman', 'item_null_talisman', 'item_power_treads_int', 'item_magic_stick', 'item_recipe_magic_wand' }

Item['item_templar_assassin_outfit']	= { 'item_tango', 'item_faerie_fire', 'item_double_branches', 'item_wraith_band', 'item_flask', 'item_magic_stick', 'item_recipe_magic_wand', 'item_power_treads_agi', 'item_blight_stone' }





Item['item_ranged_carry_outfit']		= { 'item_tango', 'item_flask', 'item_double_branches', 'item_slippers', 'item_circlet', 'item_magic_stick', 'item_recipe_wraith_band', 'item_power_treads_agi', 'item_recipe_magic_wand', 'item_infused_raindrop' }

Item['item_melee_carry_outfit']			= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_circlet', 'item_magic_stick', 'item_slippers', 'item_recipe_wraith_band', 'item_recipe_magic_wand', 'item_power_treads_agi' }

Item['item_phantom_assassin_outfit']	= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_circlet', 'item_magic_stick', 'item_slippers', 'item_recipe_wraith_band', 'item_recipe_magic_wand', 'item_power_treads_agi', 'item_blight_stone' }

Item['item_juggernaut_outfit']			= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_circlet', 'item_magic_stick', 'item_slippers', 'item_recipe_wraith_band', 'item_recipe_magic_wand', 'item_phase_boots', 'item_wraith_band' }

Item['item_huskar_outfit']				= { 'item_tango', 'item_flask', 'item_double_branches', 'item_gauntlets', 'item_circlet', 'item_magic_stick', 'item_recipe_bracer', 'item_boots', 'item_bracer', 'item_recipe_magic_wand', 'item_blades_of_attack', 'item_chainmail' }

Item['item_sven_outfit']				= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_circlet', 'item_magic_stick', 'item_gauntlets', 'item_recipe_bracer', 'item_recipe_magic_wand', 'item_phase_boots' }

Item['item_bristleback_outfit']			= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_circlet', 'item_magic_stick', 'item_gauntlets', 'item_recipe_bracer', 'item_recipe_magic_wand', 'item_power_treads_str' }



Item['item_tank_outfit']				= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_circlet', 'item_magic_stick', 'item_gauntlets', 'item_recipe_bracer', 'item_recipe_magic_wand', 'item_power_treads_str' }

Item['item_dragon_knight_outfit']		= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_double_branches', 'item_gauntlets', 'item_magic_stick', 'item_recipe_magic_wand', 'item_gauntlets', 'item_power_treads_str', 'item_broken_soul_ring' }



Item['item_priest_outfit']				= { 'item_tango', 'item_tango', 'item_branches', 'item_magic_stick', 'item_branches', 'item_arcane_boots', 'item_recipe_magic_wand', 'item_flask', 'item_urn_of_shadows' }



Item['item_mage_outfit']				= { 'item_tango', 'item_tango', 'item_double_branches', 'item_circlet', 'item_mantle', 'item_magic_stick', 'item_recipe_null_talisman', 'item_tranquil_boots', 'item_recipe_magic_wand', 'item_flask' }

Item['item_crystal_maiden_outfit']		= { 'item_tango', 'item_double_branches', 'item_circlet', 'item_mantle', 'item_magic_stick', 'item_recipe_null_talisman',  'item_arcane_boots', 'item_recipe_magic_wand', 'item_flask' }




Item['PvN_priest']		= { 'item_tango', 'item_flask', 'item_bracer', 'item_power_treads_int', 'item_bracer', 'item_ghost', 'item_glimmer_cape', 'item_aeon_disk', 'item_cyclone', 'item_sphere', 'item_sheepstick', 'item_moon_shard'}

Item['PvN_mage']		= { 'item_tango', 'item_flask', 'item_bracer', 'item_power_treads_int', 'item_bracer', 'item_ghost', 'item_glimmer_cape', 'item_aeon_disk', 'item_lotus_orb', 'item_force_staff', 'item_sheepstick', 'item_moon_shard'}

Item['PvN_melee_carry']	= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_blade_mail', 'item_heavens_halberd', 'item_diffusal_blade', "item_travel_boots", 'item_abyssal_blade', 'item_moon_shard'}

Item['PvN_str_carry']	= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_bracer', 'item_bracer', 'item_power_treads_str', 'item_blade_mail', 'item_heavens_halberd', "item_travel_boots", 'item_abyssal_blade', 'item_moon_shard'}

Item['PvN_ranged_carry']= { 'item_tango', 'item_flask', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_wraith_band', 'item_dragon_lance', 'item_ghost', 'item_heavens_halberd', "item_travel_boots", 'item_broken_hurricane_pike', 'item_bloodthorn', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_tank']		= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_bracer', 'item_bracer', 'item_power_treads_str', 'item_blade_mail', 'item_crimson_guard', 'item_heavens_halberd', "item_travel_boots", 'item_assault', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_mid']			= { 'item_tango', 'item_flask', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_dragon_lance', 'item_ghost', 'item_heavens_halberd', "item_travel_boots", 'item_broken_hurricane_pike', 'item_bloodthorn', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_antimage']	= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_blade_mail', 'item_broken_bfury', 'item_manta', 'item_heavens_halberd', "item_travel_boots", 'item_abyssal_blade', 'item_skadi', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_huskar']		= { 'item_tango', 'item_flask', 'item_bracer', 'item_bracer', 'item_bracer', 'item_power_treads_agi', 'item_dragon_lance', 'item_blade_mail', 'item_heavens_halberd', "item_travel_boots", 'item_broken_hurricane_pike', 'item_heart', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_clinkz']		= { 'item_tango', 'item_flask', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_dragon_lance', 'item_blade_mail', 'item_heavens_halberd', "item_travel_boots", 'item_solar_crest', 'item_broken_hurricane_pike', 'item_bloodthorn', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_BH']			= { 'item_tango', 'item_flask', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_ghost', 'item_heavens_halberd', "item_travel_boots", 'item_solar_crest', "item_abyssal_blade", 'item_bloodthorn', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_TA']			= { 'item_tango', 'item_flask', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_dragon_lance', 'item_ghost',  'item_heavens_halberd', "item_travel_boots", 'item_desolator', 'item_broken_hurricane_pike', 'item_bloodthorn', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_PA']			= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_blade_mail',  'item_heavens_halberd', "item_travel_boots", 'item_desolator', 'item_abyssal_blade', 'item_nullifier', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_PL']			= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_wraith_band', 'item_wraith_band', 'item_power_treads_agi', 'item_diffusal_blade', 'item_blade_mail', 'item_manta', 'item_heavens_halberd', "item_travel_boots", 'item_abyssal_blade', 'item_moon_shard', "item_travel_boots_2" }

Item['PvN_OM']			= { 'item_tango', 'item_flask', 'item_quelling_blade', 'item_bracer', 'item_bracer', 'item_power_treads_int', 'item_ghost', 'item_hand_of_midas', 'item_heavens_halberd', "item_travel_boots", 'item_sheepstick', 'item_moon_shard', "item_travel_boots_2" }




function Item.IsConsumableItem( sItemName )
	return tConsumableItemList[sItemName] == true
end

function Item.IsSmallItem( sItemName )
	return tSmallItemList[sItemName] ~= nil
end

function Item.IsNeutralItem( sItemName )
	return tNeutralItemLevelList[sItemName] ~= nil
end

function Item.GetNeutralItemLevel( sItemName )
	return tNeutralItemLevelList[sItemName] or 0
end

function Item.GetMinTeamNeutralItemLevel()

	local nMinItemLevel = 999
	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local member = GetTeamMember( i )
		if	member ~= nil
		then
			local hNeutralItem = member:GetItemInSlot( 16 )
			if hNeutralItem ~= nil
			then
				local sNeutralItemName = hNeutralItem:GetName()
				if Item.GetNeutralItemLevel( sNeutralItemName ) < nMinItemLevel
				then
					nMinItemLevel = Item.GetNeutralItemLevel( sNeutralItemName )
				end
			else
				nMinItemLevel = 0
				break
			end
		end
	end

	return nMinItemLevel

end

function Item.GetInUseNeutralItemLevel( bot )

	local hNeutralItem = bot:GetItemInSlot( 16 )
	if hNeutralItem ~= nil
	then
		local sNeutralItemName = hNeutralItem:GetName()
		return Item.GetNeutralItemLevel( sNeutralItemName )
	end

	return 0

end




function Item.IsNotSellItem( sItemName )
	return tNotSellItemList[sItemName] == true
end

function Item.IsCanNotSwitchItem( sItemName )
	return tCanNotSwitchItemList[sItemName] == true
end

function Item.IsDebugItem( sItemName )
	return tDebugItemList[sItemName] == true
end

function Item.IsSpecifiedItem( sItemName )
	return tSpecifiedItemIndex[sItemName] == true
end

function Item.IsTopItem( sItemName )
	return tTopItemList[sItemName] == true
end

function Item.HasItem( bot, itemName )
	return bot:FindItemSlot( itemName ) >= 0
end

function Item.HasItemWithName( bot, iname )
	for i = 0, 8 do
		local item = bot:GetItemInSlot( i )
		if item ~= nil then
			if string.find(item:GetName(), iname) then return true end
		end
	end
	return false
end


function Item.IsItemInHero( sItemName )
	return Item.IsItemInTargetHero( sItemName, GetBot() )
end

function Item.IsItemInTargetHero( sItemName, bot )
	if sItemName == 'item_double_flask'
	then return Item.IsItemInHero( 'item_flask' ) end
	
	if sItemName == 'item_flask' and GetItemStockCount( 'item_flask' ) == 0
	then return true end
	

	if tDefineItemRealName[sItemName] ~= nil
	then return Item.IsItemInHero( tDefineItemRealName[sItemName] ) end

	if string.find( sItemName, 'item_double' ) ~= nil
	then return Item.GetItemCountInSolt( bot, string.gsub( sItemName, "_double", "" ), 0, 8 ) >= 2 end

	if string.find( sItemName, 'PvN_' ) ~= nil then return Item.IsItemInHero( 'item_moon_shard' ) end

	if sItemName == 'item_ultimate_scepter' and bot:HasScepter() then return true end
	
	if sItemName == 'item_moon_shard' and bot:HasModifier( "modifier_item_moon_shard_consumed" ) then return true end

	if sItemName == 'item_ultimate_scepter_2' then return ( bot:HasScepter() and bot:FindItemSlot('item_ultimate_scepter') < 0 ) end

	local nItemSolt = bot:FindItemSlot( sItemName )

	return nItemSolt >= 0 and ( nItemSolt <= 8 or Item.IsTopItem( sItemName ) )
end

--获取物品当前不重复基础构造
function Item.GetBasicItems( sItemList )

	local bot = GetBot()
	local tBasicItem = {}

	for i, v in pairs( sItemList )
	do
		local bRepeatedItem = Item.IsItemInHero( v )
		if bRepeatedItem == false
			or v == bot.sLastRepeatItem
		then
			if Item[v] ~= nil	
			then		
				for _, w in pairs( Item.GetBasicItems( Item[v] ) )
				do
					tBasicItem[#tBasicItem + 1] = w
				end
			elseif Item[v] == nil
				then
					tBasicItem[#tBasicItem + 1] = v
			end
		else
			if Item.GetItemCount( GetBot(), v ) <= 1 --能修复"两个"系列重复的问题
			then
				bot.sLastRepeatItem = v	--能修复单重重复的问题
			end
		end
	end

	return tBasicItem

end

-- function Item.ItemBasicItemsNotInHeroSlots(finalItem, bot)
	
-- end

function Item.GetMainInvLessValItemSlot( bot )

	local minPrice = 10000
	local minSlot = - 1
	for i = 0, 5
	do
		local item = bot:GetItemInSlot( i )
		
		if item == nil
		then
			return i
		end
		
		if item ~= nil
			and not Item.IsCanNotSwitchItem( item:GetName() )
		then
			local cost = GetItemCost( item:GetName() )
			if cost < minPrice then
				minPrice = cost
				minSlot = i
			end
		end
	end

	return minSlot

end

function Item.GetBodyInvLessValItemSlot( bot )
	local minPrice = 10000
	local minSlot = - 1
	for i = 0, 8
	do
		local item = bot:GetItemInSlot( i )
		
		if item == nil
		then
			return i, -1
		end
		
		if item ~= nil
			and not Item.IsCanNotSwitchItem( item:GetName() )
		then
			local cost = GetItemCost( item:GetName() )
			if cost < minPrice then
				minPrice = cost
				minSlot = i
			end
		end
	end

	return minSlot, minPrice

end


function Item.GetItemCharges( bot, itemName )

	local charges = 0
	for i = 0, 16
	do
		local item = bot:GetItemInSlot( i )
		if item ~= nil and item:GetName() == itemName
		then
			charges = charges + item:GetCurrentCharges()
		end
	end

	return charges

end


function Item.GetNeutralItemCount( bot )

	local amount = 0
	local nSlotList = { 6, 7, 8, 16 }
	for _, i in pairs( nSlotList )
	do
		local item = bot:GetItemInSlot( i )
		if item ~= nil
		then
			local itemName = item:GetName()
			if Item.IsNeutralItem( itemName )
				and not Item.IsConsumableItem( itemName )
			then
				amount = amount + 1
			end
		end
	end

	return amount

end


local function CountEmptySlots(bot, slotMin, slotMax)
	local amount = 0
	for i = slotMin, slotMax do
		if bot:GetItemInSlot(i) == nil then amount = amount + 1 end
	end
	return amount
end

function Item.GetEmptyInventoryAmount( bot )
	return CountEmptySlots(bot, 0, 8)
end

function Item.GetEmptyNonBackpackInventoryAmount( bot )
	return CountEmptySlots(bot, 0, 5)
end

function Item.GetEmptyNeutralBackpackAmount( bot )
	return CountEmptySlots(bot, 6, 8) + (bot:GetItemInSlot(16) == nil and 1 or 0)
end

function Item.GetEmptyBackpackSlot( bot )
	for i = 6, 8
	do
		if bot:GetItemInSlot( i ) == nil
		then
			return i
		end
	end
	return -1
end

function Item.GetItemCount( unit, itemName )
	return Item.GetItemCountInSolt( unit, itemName, 0, 16 )
end


function Item.GetItemCountInSolt( unit, itemName, nSlotMin, nSlotMax )

	local count = 0
	for i = nSlotMin, nSlotMax
	do
		local item = unit:GetItemInSlot( i )
		if item ~= nil and item:GetName() == itemName
		then
			count = count + 1
		end
	end

	return count

end


function Item.HasBasicItem( bot )

	local basicItemSlot = - 1

	for i = 1, #Item['sBasicItems']
	do
		basicItemSlot = bot:FindItemSlot( Item['sBasicItems'][i] )
		if basicItemSlot >= 0 and basicItemSlot <= 5
		then
			return true
		end
	end

	return false
end


local function FindBootsSlot(bot, maxSlot)
	for _, bootName in pairs(Item['tEarlyBoots']) do
		local slot = bot:FindItemSlot(bootName)
		if slot >= 0 and slot <= maxSlot then return true end
	end
	return false
end

function Item.HasBuyBoots( bot )
	return FindBootsSlot(bot, 16)
end

function Item.HasBootsInMainSolt( bot )
	return FindBootsSlot(bot, 8)
end

function Item.GetItemTotalWorthInSlots(unit)
	local totalValue = 0
	for i = 0, 16
	do
		local item = unit:GetItemInSlot( i )
		if item ~= nil
		then
			totalValue = totalValue + GetItemCost(item:GetName())
		end
	end
	return totalValue
end

function Item.GetTheItemSolt( bot, nSlotMin, nSlotMax, bMaxCost )
	local bestCost = bMaxCost and -9999 or 99999
	local idx = -1
	for i = nSlotMin, nSlotMax do
		local item = bot:GetItemInSlot(i)
		if item ~= nil then
			local cost = GetItemCost(item:GetName())
			if (bMaxCost and cost > bestCost) or (not bMaxCost and cost < bestCost) then
				bestCost = cost
				idx = i
			end
		end
	end
	return idx
end

function Item.GetOutfitType( bot )
	local sOutfitTypeList = {
		[1] = 'outfit_mid',
		[2] = 'outfit_tank',
		[3] = 'outfit_carry',
		[4] = 'outfit_mage',
		[5] = 'outfit_priest',
	}
	local nTeamPlayerIDs = GetTeamPlayers( GetTeam() )
	for i = 1, #GetTeamPlayers( GetTeam() )
	do
		local memberID = nTeamPlayerIDs[i]
		if bot:GetPlayerID() == memberID
		then
			return sOutfitTypeList[i]
		end
	end
	return 'outfit_carry'
end

-- returns pos_1, pos_2, pos_3, depends on the roles...
function Item.GetRoleItemsBuyList( bot )
	-- local nTeamPlayerIDs = GetTeamPlayers( GetTeam() )
	-- for i = 1, #GetTeamPlayers( GetTeam() )
	-- do
	-- 	local memberID = nTeamPlayerIDs[i]
	-- 	if bot:GetPlayerID() == memberID
	-- 	then
	-- 		local team = GetTeam() == TEAM_RADIANT and 'TEAM_RADIANT' or 'TEAM_DIRE'
	-- 		return 'pos_'..tostring(Role.RoleAssignment[team][i])
	-- 	end
	-- end
	return 'pos_'..tostring(Role.GetPosition(bot))
end

function Item.HasTargetItemCompositByItems(bot, items)
	local purchased = {}
	for i = 0, 8
	do
		local item = bot:GetItemInSlot( i )
		if item ~= nil
		then
			local basicItems = Item.GetBasicItems( {item:GetName()} )
			local intersection, built = Item.GetIntersection(items, basicItems)
			if built then
				purchased = Item.MergeLists(purchased, intersection)
			end
		end
	end
	return purchased
end

function Item.GetReducedPurchaseList(bot, items)
	local purchasedList = Item.HasTargetItemCompositByItems(bot, items)
	return Item.RemoveIntersectedItems(items, purchasedList)
end

-- returns: interection of t1 and t2, and whether t2 is in t1
function Item.GetIntersection(list1, list2)
    -- Create a lookup table for quick membership testing in list1
    local set1 = {}
    for _, value in ipairs(list1) do
        set1[value] = true
    end

    local intersection = {}
    local containsAll = true

    -- Check each element in list2: add to intersection if in list1,
    -- and determine if list1 contains every element from list2.
    for _, value in ipairs(list2) do
        if set1[value] then
            table.insert(intersection, value)
        else
            containsAll = false
        end
    end

    return intersection, containsAll
end

function Item.MergeLists(list1, list2)
    local merged = {}
    -- Append elements from the first list
    for _, value in ipairs(list1) do
        table.insert(merged, value)
    end
    -- Append elements from the second list
    for _, value in ipairs(list2) do
        table.insert(merged, value)
    end
    return merged
end

-- remove l2 from l1
function Item.RemoveIntersectedItems(list1, list2)
    -- Build a lookup table for elements in list2
    local set2 = {}
    for _, value in ipairs(list2) do
        set2[value] = true
    end

    local result = {}
    -- Add elements from list1 only if they are not in list2
    for _, value in ipairs(list1) do
        if not set2[value] then
            table.insert(result, value)
        end
    end

    return result
end


function Item.GetItemWardSolt()

	local bot = GetBot()

	local sWardTypeList = {
		'item_ward_observer',
		'item_ward_sentry',
		'item_ward_dispenser',
	}


	for _, sType in pairs( sWardTypeList )
	do
		local nWardSolt = bot:FindItemSlot( sType )
		if nWardSolt ~= - 1
		then
			return nWardSolt
		end
	end

	return - 1

end

--item_aghanims_shard
--item_ultimate_scepter_roshan

return Item
