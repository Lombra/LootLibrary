local addonName, addon = ...

local Search = addon:NewModule("Search", addon:CreateUI("Search"))
Search:CreateScrollFrame()

function Search:OnShow()
	addon:GetModule("Browse"):LoadAllTierLoot()
	self:SetList(addon:GetAllItems())
end

function Search:OnHide()
end

local nameFilter = Search:CreateSearchBox()
nameFilter:SetPoint("TOPLEFT", 24, -80)
nameFilter:SetSize(100, 20)
nameFilter:SetScript("OnTextChanged", function(self, isUserInput)
	if not isUserInput then
		return
	end
	local text = self:GetText():lower()
	if text:trim() ~= "" then
		Search:SetFilter("name", text)
	else
		Search:ClearFilter("name")
		-- addon:SetList(nil)
	end
	Search:ApplyFilters()
end)

local function onEnterPressed(self)
	Search:SetFilter(self.filter, self:GetNumber())
	Search:ApplyFilters()
	self:ClearFocus()
end

local minLevel = Search:CreateEditBox()
minLevel:SetPoint("TOPLEFT", nameFilter, "BOTTOMLEFT", 0, -16)
minLevel:SetSize(32, 20)
minLevel:SetNumeric(true)
minLevel:SetScript("OnEnterPressed", onEnterPressed)
minLevel.filter = "minReqLevel"

local maxLevel = Search:CreateEditBox()
maxLevel:SetPoint("LEFT", minLevel, "RIGHT", 36, 0)
maxLevel:SetSize(32, 20)
maxLevel:SetNumeric(true)
maxLevel:SetScript("OnEnterPressed", onEnterPressed)
maxLevel.filter = "maxReqLevel"

local minItemLevel = Search:CreateEditBox()
minItemLevel:SetPoint("TOPLEFT", minLevel, "BOTTOMLEFT", 0, -16)
minItemLevel:SetSize(32, 20)
minItemLevel:SetNumeric(true)
minItemLevel:SetScript("OnEnterPressed", onEnterPressed)
minItemLevel.filter = "minItemLevel"

local maxItemLevel = Search:CreateEditBox()
maxItemLevel:SetPoint("LEFT", minItemLevel, "RIGHT", 36, 0)
maxItemLevel:SetSize(32, 20)
maxItemLevel:SetNumeric(true)
maxItemLevel:SetScript("OnEnterPressed", onEnterPressed)
maxItemLevel.filter = "maxItemLevel"

local slots = {
	INVTYPE_BAG, -- "Bag"
	INVTYPE_2HWEAPON, -- "Two-Hand"
	INVTYPE_WEAPONMAINHAND, -- "Main Hand"
	INVTYPE_WEAPON, -- "One-Hand"
	-- INVTYPE_WEAPONOFFHAND, -- "Off Hand"
	INVTYPE_RANGED, -- "Ranged"
	-- INVTYPE_RANGEDRIGHT, -- "Ranged"
	INVTYPE_SHIELD, -- "Off Hand"
	INVTYPE_HOLDABLE, -- "Held In Off-hand"
	INVTYPE_HEAD, -- "Head"
	INVTYPE_NECK, -- "Neck"
	INVTYPE_SHOULDER, -- "Shoulder"
	INVTYPE_CLOAK, -- "Back"
	INVTYPE_CHEST, -- "Chest"
	-- INVTYPE_ROBE, -- "Chest"
	INVTYPE_BODY, -- "Shirt"
	INVTYPE_TABARD, -- "Tabard"
	INVTYPE_WRIST, -- "Wrist"
	INVTYPE_HAND, -- "Hands"
	INVTYPE_WAIST, -- "Waist"
	INVTYPE_LEGS, -- "Legs"
	INVTYPE_FEET, -- "Feet"
	INVTYPE_FINGER, -- "Finger"
	INVTYPE_TRINKET, -- "Trinket"
	-- INVTYPE_THROWN, -- "Thrown"
	-- INVTYPE_QUIVER, -- "Quiver"
}

local function onClick(self, slot)
	Search:SetFilter("slot", slot)
	Search:ApplyFilters()
end

local slot = CreateFrame("Frame", "LootLibrarySearchSlot", Search, "UIDropDownMenuTemplate")
slot:SetPoint("TOPLEFT", minItemLevel, "BOTTOMLEFT", -22, -8)
slot.initialize = function(self)
	local currentSlot = Search:GetFilter("slot")
	for i, v in ipairs(slots) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.func = onClick
		info.arg1 = v
		info.checked = v == currentSlot
		UIDropDownMenu_AddButton(info)
	end
end

local armorClass = {GetAuctionItemSubClasses(2)}

local function onClick(self, armorType)
	Search:SetFilter("armorType", armorType)
	Search:ApplyFilters()
end

local armorType = CreateFrame("Frame", "LootLibrarySearchArmorType", Search, "UIDropDownMenuTemplate")
armorType:SetPoint("TOP", slot, "BOTTOM")
armorType.initialize = function(self)
	local currentSlot = Search:GetFilter("armorType")
	for i, v in ipairs(armorClass) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.func = onClick
		info.arg1 = v
		info.checked = v == currentSlot
		UIDropDownMenu_AddButton(info)
	end
end

local class = CreateFrame("Frame", "LootLibrarySearchClass", Search, "UIDropDownMenuTemplate")
class:SetPoint("TOP", armorType, "BOTTOM")
class.initialize = addon.InitializeGearFilter
class.module = Search
class.onClick = function()
	addon:GetModule("Browse"):LoadSpecData()
end

local filterButton = CreateFrame("Button", "LootLibraryasddads", Search, "UIMenuButtonStretchTemplate")
filterButton:SetWidth(48)
filterButton:SetPoint("TOP", class, "BOTTOM")
filterButton:SetText("GO")
filterButton:SetScript("OnClick", function(self)
	local stats = {}
	local list = Search:GetList()
	for i = #list, 1, -1 do
		local _, link = GetItemInfo(list[i])
		local stats = GetItemStats(link, statsa)
		if not stats["ITEM_MOD_AGILITY_SHORT"] then
			tremove(list, i)
		end
		addon:GetItem(list[i]).stats = stats
		wipe(stats)
	end
	Search:UpdateList()
end)