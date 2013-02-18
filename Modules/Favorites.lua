local addonName, addon = ...

local Favorites = addon:NewModule("Favorites", addon:CreateUI("Favorites"))
Favorites:CreateScrollFrame("LootLibraryFavoritesScrollFrame")

do
	local highlight
	
	local function onClick(self)
		if highlight then
			highlight:UnlockHighlight()
			highlight = nil
		end
		if self.list then
			self:LockHighlight()
			highlight = self
			Favorites:SetList(self.list)
		end
	end
	
	local scrollFrame = Favorites:CreateNavigationFrame("LootLibraryFavoritesNavigationScrollFrame", onClick)
	scrollFrame.updateButton = function(button, object)
		button:SetText(object.name)
		button.list = object.items
		button.index = index
	end

	local homeButton = scrollFrame:AddHeader()
	homeButton:SetText("All items")
	homeButton.label:SetFontObject("GameFontNormal")

	local instanceButton = scrollFrame:AddHeader()
	instanceButton:SetText("Sets")
	instanceButton.label:SetFontObject("GameFontNormal")
	
	scrollFrame:UpdateHeight()
end

local defaults = {
	char = {
		items = {},
		sets = {},
	},
}

function Favorites:OnInitialize()
	self.db = addon.db:RegisterNamespace("Favorites", defaults)
	self:SetList(self.db.char.items)
	self:SetNavigationList(self.db.char.sets)
	local headers = self.navigationScrollFrame.headers
	headers[1].list = self.db.char.items
	-- headers[2].list = self.db.char.items
end

local function onClick1(self, itemID, set)
	Favorites:RemoveItem(itemID, set)
	CloseDropDownMenus()
end

local function onClick(self, itemID, set)
	Favorites:AddItem(itemID, set)
	CloseDropDownMenus()
end

Favorites.initialize = function(self, level, menuList)
	if level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Remove from favorites"
		info.func = onClick1
		info.arg1 = UIDROPDOWNMENU_MENU_VALUE
		info.arg2 = v.name
		info.notCheckable = true
		-- info.disabled = 
		UIDropDownMenu_AddButton(info)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Add to favorite set"
		info.value = UIDROPDOWNMENU_MENU_VALUE
		info.notCheckable = true
		-- info.disabled = 
		info.hasArrow = true
		info.keepShownOnClick = true
		info.menuList = Favorites.db.char.sets
		UIDropDownMenu_AddButton(info)
	elseif level == 2 then
		for i, v in ipairs(menuList) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.name
			info.func = onClick
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = v.name
			info.notCheckable = true
			-- info.disabled = 
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Favorites:AddSet(name)
	tinsert(self.db.char.sets, {
		name = name,
		items = {},
	})
	self:UpdateNavigationList()
end

function Favorites:AddItem(itemID, setName)
	if not GetItemIcon(itemID) then
		error("Invalid item", 2)
	end
	if not self:HasItem(itemID) then
		tinsert(self.db.char.items, itemID)
	end
	if setName then
		local set = self:GetSet(setName)
		if not set then
			error(format("Set '%s' does not exist.", setName), 2)
		end
		if not self:HasItem(itemID, setName) then
			tinsert(set.items, itemID)
		end
	end
	self:UpdateList()
end

function Favorites:RemoveItem(itemID, setName)
	if setName then
		local set = self:GetSet(setName)
		if not set then
			error(format("Set '%s' does not exist.", setName), 2)
		end
		local hasItem, index = self:HasItem(itemID, setName)
		if hasItem then
			tremove(set.items, index)
		end
	else
		-- removing an item from the main list will remove from all sets
		local hasItem, index = self:HasItem(itemID)
		if not hasItem then
			tremove(self.db.char.items, index)
		end
		for i, set in self:IterateSets() do
			local hasItem, index = self:HasItem(itemID, set.name)
			if hasItem then
				tremove(set.items, index)
			end
		end
	end
	self:UpdateList()
end

function Favorites:HasItem(itemID, set)
	local items = self:GetItems(set)
	for i, v in ipairs(items) do
		if v == itemID then
			return true, i
		end
	end
	return false
end

function Favorites:GetItems(setName)
	return set and self:GetSet(setName).items or self.db.char.items
end

function Favorites:GetSet(name)
	for i, set in self:IterateSets() do
		if set.name == name then
			return set
		end
	end
end

function Favorites:IterateSets()
	return ipairs(self.db.char.sets)
end

local add = Favorites:CreateEditBox()
add:SetPoint("TOPLEFT", 24, -32)
add:SetWidth(96)
add:SetNumeric(true)
add:SetScript("OnEnterPressed", function(self)
	Favorites:AddItem(self:GetNumber())
	self:SetText("")
	self:ClearFocus()
end)

local adds = Favorites:CreateEditBox()
adds:SetPoint("LEFT", add, "RIGHT", 16, 0)
adds:SetWidth(96)
adds:SetScript("OnEnterPressed", function(self)
	Favorites:AddSet(self:GetText())
	self:SetText("")
	self:ClearFocus()
end)