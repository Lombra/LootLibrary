local addonName, addon = ...

local Favorites = addon:NewModule("Favorites", addon:CreateUI("Favorites"))
Favorites.hasScrollFrame = true

local scrollFrame

local highlight

do
	local function onClick(self)
		if highlight then
			highlight:UnlockHighlight()
			highlight = nil
		end
		if self.list then
			self:LockHighlight()
			highlight = self
		end
		currentList = self.list
		Favorites:SetList(self.list)
	end
	
	scrollFrame = Favorites:CreateNavigationFrame("LootLibraryFavoritesNavigationScrollFrame", onClick)
	scrollFrame.updateButton = function(button, object)
		button:SetText(object.name)
		button.list = object.items
		button.index = index
	end

	local homeButton = scrollFrame:AddHeader()
	homeButton.type = "tiers"
	homeButton.list = home
	homeButton:SetText("All items")
	homeButton.label:SetFontObject("GameFontNormal")

	local tierButton = scrollFrame:AddHeader()
	tierButton.type = "instances"
	-- tierButton.list = FavoritesDB.items
	tierButton:SetText("Non set items")
	tierButton.label:SetFontObject("GameFontNormal")

	local instanceButton = scrollFrame:AddHeader()
	instanceButton.type = "encounters"
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
	self.db = LibStub("AceDB-3.0"):New("LootLibrary_FavoritesDB", defaults)
	self:SetList(self.db.char.items)
	scrollFrame.list = self.db.char.sets
	scrollFrame.update()
end

function Favorites:AddSet(name)
	tinsert(self.db.char.sets, {
		name = name,
		items = {},
	})
	scrollFrame.update()
end

function Favorites:AddItem(itemID)
	if not GetItemIcon(itemID) then
		error("Invalid item", 2)
	end
	-- tinsert(addon:GetList(true), itemID)
	tinsert(self.db.char.items, itemID)
	self:UpdateList()
end

function Favorites:HasItem(itemID)
	for i, v in ipairs(items) do
		if v == itemID then
			return true
		end
	end
	return false
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