local addonName, addon = ...

local Libra = LibStub("Libra")

LootLibrary = Libra:NewAddon(addonName, addon)
Libra:EmbedWidgets(addon)

local itemArray = {}
local items = {}
addon.items = items

BINDING_HEADER_LOOT_LIBRARY = "LootLibrary"
BINDING_NAME_LOOT_LIBRARY_TOGGLE = "Toggle LootLibrary"

SlashCmdList["LOOT_LIBRARY"] = function(msg)
	ToggleFrame(addon.frame)
end
SLASH_LOOT_LIBRARY1 = "/lootlibrary"
SLASH_LOOT_LIBRARY2 = "/ll"

local defaults = {
	profile = {
	},
}

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LootLibraryDB", defaults, true)
end

function addon:AddItem(itemID, data)
	items[itemID] = data
	tinsert(itemArray, itemID)
end

function addon:GetItem(itemID)
	return items[itemID]
end

function addon:GetAllItems()
	return itemArray
end

function addon:HasItem(itemID)
	return GetItemCount(itemID, true) > 0
end