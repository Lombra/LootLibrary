local addonName, addon = ...

local Favorites = addon:NewModule("Favorites", addon:CreateUI("Favorites"))
local scrollFrame = Favorites:CreateScrollFrame()
scrollFrame:AddHeader()
scrollFrame:UpdateHeight()
scrollFrame.PostUpdateButton = function(button, item)
	button.hasItem:SetShown(addon:HasItem(item))
end

local selection

do
	local menu = {
		{
			text = "Delete set",
			func = function(self, setName)
				Favorites:DeleteSet(setName)
			end,
		},
		{
			text = "Rename set",
			func = function(self, setName)
				StaticPopup_Show("LOOTLIBRARY_RENAME_SET", nil, nil, setName)
			end,
		},
	}
	
	local dropdown = CreateFrame("Frame")
	dropdown.displayMode = "MENU"
	dropdown.initialize = function(self)
		for i, v in ipairs(menu) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.text
			info.func = v.func
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.notCheckable = true
			UIDropDownMenu_AddButton(info)
		end
	end
	
	local function onClick(self, button)
		if button == "LeftButton" then
			if self.list then
				Favorites:SelectList(self.list)
				if self.list.name then
					self:LockHighlight()
					selection = self
				end
			end
		elseif self.list.name then
			ToggleDropDownMenu(nil, self.list.name, dropdown, self, 0, 0)
		end
	end
	
	local scrollFrame = Favorites:CreateNavigationFrame(onClick)
	scrollFrame.updateButton = function(button, object)
		button:SetText(object.name)
		button.list = object
	end

	local homeButton = scrollFrame:AddHeader()
	homeButton:SetText("All items")

	local instanceButton = scrollFrame:AddHeader()
	instanceButton:SetText("Sets")
	
	scrollFrame:UpdateHeight()
end

local function removeItem(self, itemID, set)
	Favorites:RemoveItem(itemID, set)
	CloseDropDownMenus()
end

local function addToSet(self, itemID, set)
	Favorites:AddItem(itemID, set)
	CloseDropDownMenus()
end

Favorites.initialize = function(self, level, menuList)
	if level == 1 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Remove item"
		info.func = removeItem
		info.arg1 = UIDROPDOWNMENU_MENU_VALUE
		info.arg2 = Favorites:GetSelectedSet()
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Add to set"
		info.value = UIDROPDOWNMENU_MENU_VALUE
		info.notCheckable = true
		info.hasArrow = true
		info.keepShownOnClick = true
		info.menuList = Favorites.db.char.sets
		UIDropDownMenu_AddButton(info)
	elseif level == 2 then
		for i, v in ipairs(menuList) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.name
			info.func = addToSet
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = v.name
			info.notCheckable = true
			-- info.disabled = 
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

local defaults = {
	char = {
		items = {},
		sets = {},
	},
}

function Favorites:OnInitialize()
	self.db = addon.db:RegisterNamespace("Favorites", defaults)
	self:SelectList(self.db.char)
	self:SetNavigationList(self.db.char.sets)
	local headers = self.navigationScrollFrame.headers
	headers[1].list = self.db.char
end

function Favorites:SelectList(object)
	if selection then
		selection:UnlockHighlight()
		selection = nil
	end
	self:SetList(object.items)
	self:SetScrollFrameHeaderText(object.name or "All items")
end

function Favorites:GetSelectedSet()
	return selection and selection.list.name
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

function Favorites:AddSet(name)
	local set = {
		name = name,
		items = {},
	}
	tinsert(self.db.char.sets, set)
	self:UpdateNavigationList()
	return set
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
		if hasItem then
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

function Favorites:DeleteSet(setName)
	for i, set in self:IterateSets() do
		if set.name == setName then
			tremove(self.db.char.sets, i)
			self:UpdateNavigationList()
			if self:GetSelectedSet() == setName then
				self:SelectList(self.db.char)
			end
			break
		end
	end
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
	return setName and self:GetSet(setName).items or self.db.char.items
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

do
	local function onAccept(self)
		local text = self.editBox:GetText()
		if not Favorites:GetSet(text) then
			Favorites:AddSet(text)
		end
	end

	StaticPopupDialogs["LOOTLIBRARY_CREATE_SET"] = {
		text = "Enter new set name",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		OnAccept = onAccept,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent()
			onAccept(parent)
			parent:Hide()
		end,
		OnShow = function(self)
			-- self.editBox:SetText()
			self.editBox:HighlightText()
		end,
		whileDead = true,
		timeout = 0,
	}
end

do
	local function onAccept(self, data)
		local text = self.editBox:GetText()
		if not Favorites:GetSet(text) then
			local set = Favorites:GetSet(data)
			set.name = text
			Favorites:UpdateNavigationList()
			if Favorites:GetSelectedSet() == set.name then
				Favorites:SetScrollFrameHeaderText(text)
			end
		end
	end

	StaticPopupDialogs["LOOTLIBRARY_RENAME_SET"] = {
		text = "Enter new set name",
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = true,
		OnAccept = onAccept,
		EditBoxOnEnterPressed = function(self, data)
			local parent = self:GetParent()
			onAccept(parent, data)
			parent:Hide()
		end,
		OnShow = function(self, data)
			self.editBox:SetText(data)
			self.editBox:HighlightText()
		end,
		whileDead = true,
		timeout = 0,
	}
end

local newSet = CreateFrame("Button", "LootLibraryFavoritesNewSetButton", Favorites, "UIMenuButtonStretchTemplate")
newSet:SetPoint("TOPLEFT", 16, -32)
newSet:SetWidth(96)
newSet:SetText("New set")
newSet:SetScript("OnClick", function(self)
	StaticPopup_Show("LOOTLIBRARY_CREATE_SET")
end)

local addItem = Favorites:CreateEditBox()
addItem:SetPoint("LEFT", newSet, "RIGHT", 16, 0)
addItem:SetWidth(148)
addItem:SetScript("OnEnterPressed", function(self)
	local text = self:GetText()
	local itemID = tonumber(text) or tonumber(text:match("item:(%d+)"))
	if itemID then
	Favorites:AddItem(itemID)
	self:SetText("")
	self:ClearFocus()
	end
end)

local old_HandleModifiedItemClick = HandleModifiedItemClick

function HandleModifiedItemClick(link)
	if not link then
		return
	end
	
	if addItem:HasFocus() and IsModifiedClick("CHATLINK") then
		addItem:SetText(link)
		return true
	end
	
	return old_HandleModifiedItemClick(link)
end