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

function Favorites:AddSet(name)
	tinsert(self.db.char.sets, {
		name = name,
		items = {},
	})
	self:UpdateNavigationList()
end

function Favorites:AddItem(itemID, set)
	if not GetItemIcon(itemID) then
		error("Invalid item", 2)
	end
	if not self:HasItem(itemID) then
		tinsert(self.db.char.items, itemID)
	end
	if set then
		local set1 = self:GetSet(set)
		if not set1 then
			error(format("Set '%s' does not exist.", set), 2)
		elseif not self:HasItem(itemID, set) then
			tinsert(set.items, itemID)
		end
	end
	self:UpdateList()
end

function Favorites:HasItem(itemID, set)
	local items = self:GetItems(set)
	for i, v in ipairs(items) do
		if v == itemID then
			return true
		end
	end
	return false
end

function Favorites:GetItems(set)
	return set and self:GetSet(set).items or self.db.char.items
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

local add = Favorites:CreateEditBox("loool")
add:SetPoint("TOPLEFT", 24, -32)
add:SetWidth(96)
add:SetNumeric(true)
add:SetScript("OnEnterPressed", function(self)
	Favorites:AddItem(self:GetNumber())
	self:SetText("")
	self:ClearFocus()
end)

local adds = Favorites:CreateEditBox("loool2")
adds:SetPoint("LEFT", add, "RIGHT", 16, 0)
adds:SetWidth(96)
adds:SetScript("OnEnterPressed", function(self)
	Favorites:AddSet(self:GetText())
	self:SetText("")
	self:ClearFocus()
end)