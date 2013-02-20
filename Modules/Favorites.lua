local addonName, addon = ...

local Favorites = addon:NewModule("Favorites", addon:CreateUI("Favorites"))
local scrollFrame = Favorites:CreateScrollFrame()
scrollFrame:AddHeader()
scrollFrame:UpdateHeight()

local selection

do
	local function removeSet(self, setName)
		Favorites:RemoveSet(setName)
	end
	
	local function renameSet(self, setName)
		StaticPopup_Show("LOOTLIBRARY_REMOVE_SET", nil, nil, setName)
	end
	
	local dropdown = CreateFrame("Frame")
	dropdown.displayMode = "MENU"
	dropdown.initialize = function(self)
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Remove set"
		info.func = removeSet
		info.arg1 = UIDROPDOWNMENU_MENU_VALUE
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Rename set"
		info.func = renameSet
		info.arg1 = UIDROPDOWNMENU_MENU_VALUE
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
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
		info.text = "Remove from favorites"
		info.func = removeItem
		info.arg1 = UIDROPDOWNMENU_MENU_VALUE
		info.arg2 = Favorites:GetSelectedSet()
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
		
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Add to favorite set"
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
	tinsert(self.db.char.sets, {
		name = name,
		items = {},
	})
	self:UpdateNavigationList()
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

function Favorites:RemoveSet(setName)
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

StaticPopupDialogs["LOOTLIBRARY_REMOVE_SET"] = {
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