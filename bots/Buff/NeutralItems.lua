if NeutralItems == nil
then
    NeutralItems = {}
end

local isTierOneDone   = false
local isTierTwoDone   = false
local isTierThreeDone = false
local isTierFourDone  = false
local isTierFiveDone  = false
local DOTA_ITEM_NEUTRAL_SLOT = 16

-- Derive tier lists from FretBots/SettingsNeutralItemTable (single source of truth).
-- No more maintaining two separate item lists.
local ok, settingsTable = pcall(require, 'bots.FretBots.SettingsNeutralItemTable')
if not ok then settingsTable = {} end
-- SettingsNeutralItemTable returns { items = {...}, enhancements = {...} }.
-- Fall back to treating the value itself as the item list for older layouts.
local neutralItemList = (settingsTable and settingsTable.items) or settingsTable or {}

local function ExtractTierNames(tier)
    local names = {}
    for _, item in ipairs(neutralItemList) do
        if item.tier == tier then
            table.insert(names, item.name)
        end
    end
    return names
end

local Tier1NeutralItems = ExtractTierNames(1)
local Tier2NeutralItems = ExtractTierNames(2)
local Tier3NeutralItems = ExtractTierNames(3)
local Tier4NeutralItems = ExtractTierNames(4)
local Tier5NeutralItems = ExtractTierNames(5)

local enhancements = {
    -- Tier 1 enhancements
    { name = "item_enhancement_mystical", tier = 1, roles = {1, 1, 1, 1, 1}, realName = "Mystical Enhancement" },
    { name = "item_enhancement_brawny",    tier = 1, roles = {1, 1, 3, 2, 2}, realName = "Brawny Enhancement" },
    { name = "item_enhancement_alert",     tier = 1, roles = {1, 2, 1, 1, 1}, realName = "Alert Enhancement" },
    { name = "item_enhancement_tough",     tier = 1, roles = {1, 1, 2, 2, 1}, realName = "Tough Enhancement" },
    { name = "item_enhancement_quickened", tier = 1, roles = {1, 1, 1, 2, 1}, realName = "Quickened Enhancement" },
    { name = "item_enhancement_vital",     tier = 1, roles = {1, 1, 1, 1, 1}, realName = "Vital Enhancement" },

    -- Tier 2 enhancements
    { name = "item_enhancement_mystical", tier = 2, roles = {1, 1, 1, 1, 1}, realName = "Mystical Enhancement" },
    { name = "item_enhancement_brawny",    tier = 2, roles = {1, 1, 3, 2, 2}, realName = "Brawny Enhancement" },
    { name = "item_enhancement_alert",     tier = 2, roles = {1, 2, 1, 1, 1}, realName = "Alert Enhancement" },
    { name = "item_enhancement_tough",     tier = 2, roles = {1, 1, 2, 2, 1}, realName = "Tough Enhancement" },
    { name = "item_enhancement_quickened", tier = 2, roles = {1, 1, 1, 2, 1}, realName = "Quickened Enhancement" },
    { name = "item_enhancement_keen_eyed", tier = 2, roles = {1, 1, 1, 1, 2}, realName = "Keen Eyed Enhancement" },
    { name = "item_enhancement_vast",      tier = 2, roles = {1, 1, 1, 1, 1}, realName = "Vast Enhancement" },
    { name = "item_enhancement_greedy",    tier = 2, roles = {1, 1, 1, 2, 2}, realName = "Greedy Enhancement" },
    { name = "item_enhancement_vampiric",  tier = 2, roles = {1, 1, 1, 1, 1}, realName = "Vampiric Enhancement" },
    { name = "item_enhancement_nimble",    tier = 2, roles = {1, 1, 1, 1, 1}, realName = "Nimble Enhancement" },
    { name = "item_enhancement_crude",     tier = 2, roles = {1, 1, 1, 1, 1}, realName = "Crude Enhancement" },
    { name = "item_enhancement_titanic",   tier = 2, roles = {1, 1, 1, 1, 1}, realName = "Titanic Enhancement" },

    -- Tier 3 enhancements
    { name = "item_enhancement_mystical", tier = 3, roles = {1, 1, 1, 1, 1}, realName = "Mystical Enhancement" },
    { name = "item_enhancement_brawny",    tier = 3, roles = {1, 1, 3, 2, 2}, realName = "Brawny Enhancement" },
    { name = "item_enhancement_alert",     tier = 3, roles = {1, 2, 1, 1, 1}, realName = "Alert Enhancement" },
    { name = "item_enhancement_tough",     tier = 3, roles = {1, 1, 2, 2, 1}, realName = "Tough Enhancement" },
    { name = "item_enhancement_quickened", tier = 3, roles = {1, 1, 1, 2, 1}, realName = "Quickened Enhancement" },
    { name = "item_enhancement_keen_eyed", tier = 3, roles = {1, 1, 1, 1, 2}, realName = "Keen Eyed Enhancement" },
    { name = "item_enhancement_vast",      tier = 3, roles = {1, 1, 1, 1, 1}, realName = "Vast Enhancement" },
    { name = "item_enhancement_greedy",    tier = 3, roles = {1, 1, 1, 2, 2}, realName = "Greedy Enhancement" },
    { name = "item_enhancement_vampiric",  tier = 3, roles = {1, 1, 1, 1, 1}, realName = "Vampiric Enhancement" },
    { name = "item_enhancement_nimble",    tier = 3, roles = {1, 1, 1, 1, 1}, realName = "Nimble Enhancement" },
    { name = "item_enhancement_crude",     tier = 3, roles = {1, 1, 1, 1, 1}, realName = "Crude Enhancement" },
    { name = "item_enhancement_titanic",   tier = 3, roles = {1, 1, 1, 1, 1}, realName = "Titanic Enhancement" },

    -- Tier 4 enhancements
    { name = "item_enhancement_mystical", tier = 4, roles = {1, 1, 1, 1, 1}, realName = "Mystical Enhancement" },
    { name = "item_enhancement_brawny",    tier = 4, roles = {1, 1, 3, 2, 2}, realName = "Brawny Enhancement" },
    { name = "item_enhancement_alert",     tier = 4, roles = {1, 2, 1, 1, 1}, realName = "Alert Enhancement" },
    { name = "item_enhancement_tough",     tier = 4, roles = {1, 1, 2, 2, 1}, realName = "Tough Enhancement" },
    { name = "item_enhancement_quickened", tier = 4, roles = {1, 1, 1, 2, 1}, realName = "Quickened Enhancement" },
    { name = "item_enhancement_vampiric",  tier = 4, roles = {1, 1, 1, 1, 1}, realName = "Vampiric Enhancement" },
    { name = "item_enhancement_timeless", tier = 4, roles = {1, 1, 1, 1, 1}, realName = "Timeless Enhancement" },
    { name = "item_enhancement_nimble",   tier = 4, roles = {1, 1, 1, 1, 1}, realName = "Nimble Enhancement" },
    { name = "item_enhancement_crude",    tier = 4, roles = {1, 1, 1, 1, 1}, realName = "Crude Enhancement" },
    { name = "item_enhancement_titanic",  tier = 4, roles = {1, 1, 1, 1, 1}, realName = "Titanic Enhancement" },

    -- Tier 5 enhancements
    { name = "item_enhancement_timeless", tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Timeless Enhancement" },
    { name = "item_enhancement_feverish", tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Feverish Enhancement" },
    { name = "item_enhancement_fleetfooted", tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Fleetfooted Enhancement" },
    { name = "item_enhancement_audacious", tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Audacious Enhancement" },
    { name = "item_enhancement_evolved",  tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Evolved Enhancement" },
    { name = "item_enhancement_boundless", tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Boundless Enhancement" },
    { name = "item_enhancement_wise",     tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Wise Enhancement" },
    { name = "item_enhancement_hulking",  tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Hulking Enhancement" },
    { name = "item_enhancement_manic",    tier = 5, roles = {1, 1, 1, 1, 1}, realName = "Manic Enhancement" },
}

function NeutralItems:GetRandomEnhanByTier(tier)
    local filtered = {}
    for _, enh in ipairs(enhancements) do
        if enh.tier == tier then
            table.insert(filtered, enh)
        end
    end

    if #filtered == 0 then
        return nil  -- No enhancement found for this tier
    end

    -- Return a random enhancement from the filtered list.
    return filtered[math.random(#filtered)]
end


-- Just give out random for now.
-- Will work out a decent algorithm later to better assign suitable items.
function NeutralItems.GiveNeutralItems(TeamRadiant, TeamDire)
    local isTurboMode = Helper.IsTurboMode()

    -- Tier 1 Neutral Items
    if (isTurboMode and Helper.DotaTime() >= 0 or Helper.DotaTime() >= 0)
    and not isTierOneDone
    then
        GameRules:SendCustomMessage('Bots receiving Tier 1 Neutral Items...', 0, 0)

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier1NeutralItems[RandomInt(1, #Tier1NeutralItems)], h, isTierOneDone, 1)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier1NeutralItems[RandomInt(1, #Tier1NeutralItems)], h, isTierOneDone, 1)
        end

        isTierOneDone = true
    end

    -- Tier 2 Neutral Items
    if (isTurboMode and Helper.DotaTime() >= 8.5 * 60 or Helper.DotaTime() >= 17 * 60)
    and not isTierTwoDone
    then
        GameRules:SendCustomMessage('Bots receiving Tier 2 Neutral Items...', 0, 0)

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier2NeutralItems[RandomInt(1, #Tier2NeutralItems)], h, isTierOneDone, 2)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier2NeutralItems[RandomInt(1, #Tier2NeutralItems)], h, isTierOneDone, 2)
        end

        isTierTwoDone = true
    end

    -- Tier 3 Neutral Items
    if (isTurboMode and Helper.DotaTime() >= 13.5 * 60 or Helper.DotaTime() >= 27 * 60)
    and not isTierThreeDone
    then
        GameRules:SendCustomMessage('Bots receiving Tier 3 Neutral Items...', 0, 0)

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier3NeutralItems[RandomInt(1, #Tier3NeutralItems)], h, isTierTwoDone, 3)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier3NeutralItems[RandomInt(1, #Tier3NeutralItems)], h, isTierTwoDone, 3)
        end

        isTierThreeDone = true
    end

    -- Tier 4 Neutral Items
    if (isTurboMode and Helper.DotaTime() >= 18.5 * 60 or Helper.DotaTime() >= 37 * 60)
    and not isTierFourDone
    then
        GameRules:SendCustomMessage('Bots receiving Tier 4 Neutral Items...', 0, 0)

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier4NeutralItems[RandomInt(1, #Tier4NeutralItems)], h, isTierThreeDone, 4)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier4NeutralItems[RandomInt(1, #Tier4NeutralItems)], h, isTierThreeDone, 4)
        end

        isTierFourDone = true
    end

    -- Tier 5 Neutral Items
    if (isTurboMode and Helper.DotaTime() >= 30 * 60 or Helper.DotaTime() >= 60 * 60)
    and not isTierFiveDone
    then
        GameRules:SendCustomMessage('Bots receiving Tier 5 Neutral Items...', 0, 0)

        for _, h in pairs(TeamRadiant) do
            NeutralItems.GiveItem(Tier5NeutralItems[RandomInt(1, #Tier5NeutralItems)], h, isTierFourDone, 5)
        end

        for _, h in pairs(TeamDire) do
            NeutralItems.GiveItem(Tier5NeutralItems[RandomInt(1, #Tier5NeutralItems)], h, isTierFourDone, 5)
        end

        isTierFiveDone = true
    end
end

function NeutralItems.GiveItem(itemName, hero, isTierDone, nTier)
    if itemName == nil then
        log('[Buff][NeutralItems] tier %s: nil itemName (empty tier list?)', tostring(nTier))
        return
    end
    NeutralItems:RemoveEnhan(hero)
    if hero:HasRoomForItem(itemName, true, true)
    then
        local item = CreateItem(itemName, hero, hero)
        if item == nil then
            log('[Buff][NeutralItems] tier %s: CreateItem("%s") returned nil -- invalid/renamed in this patch', tostring(nTier), tostring(itemName))
            return
        end
        item:SetPurchaseTime(0)

        if NeutralItems.HasNeutralItem(hero)
        and isTierDone
        then
            hero:RemoveItem(hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT))
            NeutralItems:RemoveEnhan(hero)
            hero:AddItem(item)
        else
            hero:AddItem(item)
        end
        local enhancement = NeutralItems:GetRandomEnhanByTier(nTier)
        if enhancement then
            local enha = CreateItem(enhancement.name, hero, hero)
            if enha == nil then
                log('[Buff][NeutralItems] tier %s: CreateItem enhancement "%s" returned nil', tostring(nTier), tostring(enhancement.name))
            else
                enha:SetPurchaseTime(0)
                hero:AddItem(enha)
            end
        end
    end
end

function NeutralItems:RemoveEnhan(unit)
	for idx = 1, 20 do
		local currentItem = unit:GetItemInSlot(idx)
		if currentItem ~= nil then
			if string.find(currentItem:GetName(), "item_enhancement") then
				unit:RemoveItem(currentItem)
				-- return
			end
		end
	end
end

function NeutralItems.HasNeutralItem(hero)
    if not hero then
        return false
    end

    local item = hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
    if item then
        return true
    end

    return false
end

return NeutralItems