local addonName, addon = ...

local Search = addon:NewModule("Search", addon:CreateUI("Search"))
Search:CreateScrollFrame()

function Search:OnShow()
	addon:GetModule("Browse"):LoadAllTierLoot()
	self:SetList(addon:GetAllItems())
end

function Search:OnHide()
end

local numResults = Search:CreateFontString(nil, nil, "GameFontHighlightSmall")
numResults:SetPoint("TOPRIGHT", -16, -40)

function Search:OnUpdateList()
	numResults:SetFormattedText("%d results.", #self:GetList())
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
	local value = self:GetNumber()
	if value == 0 then
		value = nil
	end
	Search:SetFilter(self.filter, value)
	Search:ApplyFilters()
	self:ClearFocus()
end

local function dash(left, right)
	local dash = Search:CreateFontString(nil, nil, "ChatFontSmall")
	dash:SetPoint("LEFT", left, "RIGHT")
	dash:SetPoint("RIGHT", right, "LEFT", -2, 0)
	dash:SetText("-")
end

local minLevel = Search:CreateEditBox()
minLevel:SetPoint("TOPLEFT", nameFilter, "BOTTOMLEFT", 0, -16)
minLevel:SetSize(32, 20)
minLevel:SetNumeric(true)
minLevel:SetScript("OnEnterPressed", onEnterPressed)
minLevel.filter = "minReqLevel"

local maxLevel = Search:CreateEditBox()
maxLevel:SetPoint("LEFT", minLevel, "RIGHT", 16, 0)
maxLevel:SetSize(32, 20)
maxLevel:SetNumeric(true)
maxLevel:SetScript("OnEnterPressed", onEnterPressed)
maxLevel.filter = "maxReqLevel"

local reqLevelLabel = Search:CreateFontString(nil, nil, "GameFontNormalSmall")
reqLevelLabel:SetPoint("BOTTOMLEFT", minLevel, "TOPLEFT")
reqLevelLabel:SetText("Required level")
dash(minLevel, maxLevel)

local minItemLevel = Search:CreateEditBox()
minItemLevel:SetPoint("TOPLEFT", minLevel, "BOTTOMLEFT", 0, -16)
minItemLevel:SetSize(32, 20)
minItemLevel:SetNumeric(true)
minItemLevel:SetScript("OnEnterPressed", onEnterPressed)
minItemLevel.filter = "minItemLevel"

local maxItemLevel = Search:CreateEditBox()
maxItemLevel:SetPoint("LEFT", minItemLevel, "RIGHT", 16, 0)
maxItemLevel:SetSize(32, 20)
maxItemLevel:SetNumeric(true)
maxItemLevel:SetScript("OnEnterPressed", onEnterPressed)
maxItemLevel.filter = "maxItemLevel"

local itemLevelLabel = Search:CreateFontString(nil, nil, "GameFontNormalSmall")
itemLevelLabel:SetPoint("BOTTOMLEFT", minItemLevel, "TOPLEFT")
itemLevelLabel:SetText("Item level")
dash(minItemLevel, maxItemLevel)

local slots = {
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
slot:SetPoint("TOPLEFT", minItemLevel, "BOTTOMLEFT", -22, -16)
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

local label = slot:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
label:SetPoint("BOTTOMLEFT", slot, "TOPLEFT", 16, 3)
label:SetText("Slot")

local armorClass = {GetAuctionItemSubClasses(2)}

local function onClick(self, armorType)
	Search:SetFilter("armorType", armorType)
	Search:ApplyFilters()
end

local armorType = CreateFrame("Frame", "LootLibrarySearchArmorType", Search, "UIDropDownMenuTemplate")
armorType:SetPoint("TOP", slot, "BOTTOM", 0, -16)
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

local label = armorType:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
label:SetPoint("BOTTOMLEFT", armorType, "TOPLEFT", 16, 3)
label:SetText("Armor type")

local class = CreateFrame("Frame", "LootLibrarySearchClass", Search, "UIDropDownMenuTemplate")
class:SetPoint("TOP", armorType, "BOTTOM", 0, -16)
class.initialize = addon.InitializeGearFilter
class.module = Search
class.onClick = function()
	addon:GetModule("Browse"):LoadSpecData()
end

local label = class:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
label:SetPoint("BOTTOMLEFT", class, "TOPLEFT", 16, 3)
label:SetText("Gear filter")

local filterButton = CreateFrame("Button", "LootLibraryasddads", Search, "UIMenuButtonStretchTemplate")
filterButton:SetWidth(48)
filterButton:SetPoint("TOP", class, "BOTTOM", 22, 0)
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