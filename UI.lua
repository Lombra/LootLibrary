local addonName, addon = ...

local LBI = LibStub("LibBabble-Inventory-3.0"):GetUnstrictLookupTable()
local ItemInfo = LibStub("LibItemInfo-1.0")

local mt = {
	__newindex = function(tbl, key, value)
		rawset(tbl, LBI[key], LBI[value])
	end
}

-- GetItemInfo doesn't give the same info as the EJ API, we change GII returns into EJ format
local t = {
	["Bows"] = "Bow",
	["Crossbows"] = "Crossbow",
	["Daggers"] = "Dagger",
	["Fist Weapons"] = "Fist Weapon",
	["Guns"] = "Gun",
	["One-Handed Axes"] = "Axe",
	["One-Handed Maces"] = "Mace",
	["One-Handed Swords"] = "Sword",
	["Polearms"] = "Polearm",
	["Shields"] = "Shield",
	["Staves"] = "Staff",
	["Two-Handed Axes"] = "Axe",
	["Two-Handed Maces"] = "Mace",
	["Two-Handed Swords"] = "Sword",
	["Wands"] = "Wand",
}

local weaponTypes = {}

for k, v in pairs(t) do
	weaponTypes[LBI[k]] = LBI[v]
end

t = nil

-- do not display an armor type for items that go into these slots
local noArmor = {
	INVTYPE_CLOAK = true,
	INVTYPE_FINGER = true,
	INVTYPE_HOLDABLE = true,
	INVTYPE_NECK = true,
	INVTYPE_TRINKET = true,
}

-- do not display a slot for items of these types
local noSlot = {
	[LBI["Polearms"]] = true,
	[LBI["Staves"]] = true,
	[LBI["Wands"]] = true,
	[LBI["Guns"]] = true,
	[LBI["Crossbows"]] = true,
	[LBI["Bows"]] = true,
	[LBI["Shields"]] = true,
}

local invTypeExceptions = {
	INVTYPE_ROBE = "INVTYPE_CHEST",
	INVTYPE_RANGEDRIGHT = "INVTYPE_RANGED",
}

local noType = {
	[LBI["Junk"]] = true,
}

local frame = addon:CreateUIPanel("LootLibraryFrame")
addon.frame = frame
frame:SetPoint("CENTER")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:HidePortrait()
frame:HideButtonBar()
frame:SetTitleText("LootLibrary")
frame:SetScript("OnShow", function(self)
	PlaySound("igCharacterInfoOpen")
	if not self:GetSelectedTab() then
		self:SelectTab(1)
        -- addon:GetModule("Browse"):CacheAllItems()
	end
end)
frame:SetScript("OnHide", function(self)
	PlaySound("igCharacterInfoClose")
end)

local function onShow(self)
	if self.OnShow then
		self:OnShow()
	end
end

local function onHide(self)
	if self.OnHide then
		self:OnHide()
	end
end

addon.prototype = CreateFrame("Frame")
local Prototype = addon.prototype
local mt = {__index = Prototype}

function frame:OnTabSelected(id)
	self.tabs[id].frame:Show()
end

function frame:OnTabDeselected(id)
	self.tabs[id].frame:Hide()
end

function addon:CreateUI(name)
	local ui = setmetatable(CreateFrame("Frame", nil, frame), mt)
	ui:SetAllPoints()
	ui:Hide()
	ui:SetScript("OnShow", onShow)
	ui:SetScript("OnHide", onHide)
	ui.name = name
	ui.filterArgs = {}
	
	ui.Inset = frame.Inset
	
	local tab = frame:CreateTab()
	tab:SetText(name)
	tab.frame = ui
	return ui
end

function addon:GetSelectedTab()
	return frame.tabs[frame:GetSelectedTab()].frame
end

do
	frame:SetWidth(PANEL_DEFAULT_WIDTH + 256)
	
	frame.Inset:SetPoint("TOPLEFT", 260, PANEL_INSET_ATTIC_OFFSET)
	
	function Prototype:SetScrollFrameHeaderText(indexOrText, text)
		local index = indexOrText
		if not text then
			index = 1
			text = indexOrText
		end
		self.scrollFrame.headers[index]:SetText(text)
	end
	
	local function getNumVisibleHeaders(self)
		local numHeaders = #self.headers
		if self.dynamicHeaders then
			for i, header in ipairs(self.headers) do
				if not header:IsShown() then
					numHeaders = i - 1
					break
				end
			end
		end
		return numHeaders
	end
	
	local function updateScrollSize(self)
		self:SetPoint("TOP", self.inset, 0, -(self:GetNumVisibleHeaders() * self.buttonHeight + 4))
	end
	
	local function addHeader(self, onClick)
		local n = #self.headers + 1
		local header = self:CreateHeader(onClick)
		if n == 1 then
			header:SetPoint("TOPLEFT", self.inset, 5, -6)
		else
			header:SetPoint("TOP", self.headers[n - 1], "BOTTOM", 0, -self.buttonOffset)
		end
		self.headers[n] = header
		return header
	end
	
	local function update(self)
		local offset = self:GetOffset()
		local list = self.list
		if type(list) == "function" then
			list = list(self)
		end
		local buttons = self.buttons
		local numButtons = #buttons
		for i = 1, numButtons do
			local index = offset + i
			local object = list[index]
			local button = buttons[i]
			if object then
				self.updateButton(button, object, list)
				if self.PostUpdateButton then
					self.PostUpdateButton(button, object, list)
				end
			end
			button:SetShown(object ~= nil)
		end
		
		local numHeaders = self:GetNumVisibleHeaders()
		local totalHeight = #list * self.buttonHeight
		local displayedHeight = (numButtons - numHeaders) * self.buttonHeight
		if self.dynamicHeaders then
			self:UpdateHeight()
		end

		HybridScrollFrame_Update(self, totalHeight, displayedHeight)
	end
	
	local function createScrollFrame(self, inset, createButton, buttonHeight, buttonOffset)
		local scrollFrame = addon:CreateScrollFrame("Hybrid", self)
		scrollFrame:SetPoint("TOP", inset, 0, -4)
		scrollFrame:SetPoint("LEFT", inset, 4, 0)
		scrollFrame:SetPoint("BOTTOMRIGHT", inset, -20, 4)
		scrollFrame:SetButtonHeight(buttonHeight)
		scrollFrame.initialOffsetX = 1
		scrollFrame.initialOffsetY = -2
		scrollFrame.offsetY = -buttonOffset
		scrollFrame.parent = self
		scrollFrame.inset = inset
		scrollFrame.AddHeader = addHeader
		scrollFrame.GetNumVisibleHeaders = getNumVisibleHeaders
		scrollFrame.UpdateHeight = updateScrollSize
		scrollFrame.headers = {}
		scrollFrame.buttonOffset = buttonOffset
		scrollFrame.update = function()
			update(scrollFrame)
		end
		scrollFrame.createButton = createButton
		scrollFrame:CreateButtons()
		
		local scrollBar = scrollFrame.scrollBar
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPRIGHT", inset, 0, -18)
		scrollBar:SetPoint("BOTTOMRIGHT", inset, 0, 16)
		scrollBar.doNotHide = true
		
		return scrollFrame
	end
	
	do	-- scroll frame for items
		local dropdown = addon:CreateDropdown("Menu")
		
		local function onClick(self, button)
			local module = self:GetParent():GetParent().parent
			if HandleModifiedItemClick(select(2, GetItemInfo(self.itemID))) then
				return
			end
			if button == "LeftButton" then
				local Favorites = addon:GetModule("Favorites")
				if self.isHeader then
					local index = self.index
					local data = currentList[index].data
					if not data then
						data = addon:GetModule("Browse"):LoadTierData(index)
					end
					addon:SetList(data)
				elseif Favorites and IsAltKeyDown() then
					if module == Favorites then
						Favorites:RemoveItem(self.itemID, Favorites:GetSelectedSet())
					else
						Favorites:AddItem(self.itemID)
						self.favorite:Show()
					end
				end
			else
				dropdown.initialize = module.initialize
				dropdown:Toggle(self.itemID, self)
			end
		end

		local function onUpdate(self)
			if GameTooltip:IsOwned(self) then
				if IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not IsEquippedItem(self.itemID)) then
					GameTooltip_ShowCompareItem()
				else
					ShoppingTooltip1:Hide()
					ShoppingTooltip2:Hide()
				end

				if IsModifiedClick("DRESSUP") then
					ShowInspectCursor()
				else
					ResetCursor()
				end
			end
		end
		
		local function onEnter(self)
			if self.itemID then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 28, 0)
				if type(self.itemID) == "number" then
					GameTooltip:SetItemByID(self.itemID)
				else
					GameTooltip:SetHyperlink(self.itemID)
				end
				local info = addon:GetItem(self.itemID)
				if info then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Sources:")
					for k, v in pairs(info.source) do
						GameTooltip:AddLine(tonumber(k) and EJ_GetEncounterInfo(k) or k, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
					end
					GameTooltip:Show()
				end
				if IsModifiedClick("DRESSUP") then
					ShowInspectCursor()
				end
				self:SetScript("OnUpdate", onUpdate)
			end
		end

		local function onLeave(self)
			GameTooltip:Hide()
			ResetCursor()
			self:SetScript("OnUpdate", nil)
		end
		
		local BUTTON_HEIGHT = 26
		local BUTTON_OFFSET = 3
		
		local function createFrame(frame)
			local button = CreateFrame("Button", nil, frame)
			button:SetHeight(BUTTON_HEIGHT)
			button:SetPoint("RIGHT", -5, 0)
			button:SetPushedTextOffset(0, 0)
			
			button.label = button:CreateFontString(nil, nil, "GameFontNormal")
			button.label:SetWordWrap(false)
			button:SetFontString(button.label)
			
			return button
		end
		
		-- frame.Inset:Hide()
		local function createButton(frame)
			local button = createFrame(frame)
			button:SetScript("OnClick", onClick)
			button:SetScript("OnEnter", onEnter)
			button:SetScript("OnLeave", onLeave)
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])

			button.icon = button:CreateTexture()
			button.icon:SetPoint("LEFT", 3, 0)
			button.icon:SetSize(24, 24)
			
			local label = button.label
			label:SetJustifyH("LEFT")
			label:SetJustifyV("TOP")
			label:SetPoint("TOP", 0, -1)
			label:SetPoint("LEFT", button.icon, "TOPRIGHT", 4, 0)
			-- label:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 4, 0)
			label:SetPoint("RIGHT", -21, 0)
			label:SetPoint("BOTTOM", 0, 3)
			
			button.source = button:CreateFontString(nil, nil, "GameFontHighlightSmallLeft")
			button.source:SetPoint("BOTTOMLEFT", button.icon, "BOTTOMRIGHT", 4, 0)
			
			button.info = button:CreateFontString(nil, nil, "GameFontHighlightSmallRight")
			button.info:SetPoint("BOTTOM", button.icon)
			button.info:SetPoint("RIGHT", -3, 0)
			
			button.hasItem = button:CreateTexture(nil, "OVERLAY")
			button.hasItem:SetTexture([[Interface\RaidFrame\ReadyCheck-Ready]])
			button.hasItem:SetSize(18, 18)
			button.hasItem:SetPoint("TOPLEFT", button.icon, -5, 5)
			button.hasItem:Hide()
			
			button.favorite = button:CreateTexture(nil, "OVERLAY")
			button.favorite:SetSize(24, 24)
			button.favorite:SetPoint("TOPLEFT", button.icon, -8, 8)
			button.favorite:SetTexture([[Interface\PetBattles\PetJournal]])
			button.favorite:SetTexCoord(0.11328125, 0.16210938, 0.02246094, 0.046875)
			button.favorite:Hide()
			
			return button
		end

		local function createHeader(frame)
			local button = createFrame(frame)
			
			button.label:SetFontObject(GameFontNormalMed3)
			button.label:SetAllPoints()
			
			button.background = button:CreateTexture(nil, "BACKGROUND")
			button.background:SetAllPoints()
			button.background:SetTexture([[Interface\PVPFrame\PvPMegaQueue]])
			button.background:SetTexCoord(0.00195313, 0.63867188, 0.83203125, 0.87109375)
			
				-- <Texture parentKey="Bg" file="Interface\PVPFrame\PvPMegaQueue" alpha="0.6">
					-- <Anchors>
						-- <Anchor point="TOPLEFT" x="3" y="-1"/>
						-- <Anchor point="BOTTOMRIGHT" x="-3" y="2"/>
					-- </Anchors>
					-- <TexCoords left="0.00195313" right="0.63867188" top="0.83203125" bottom="0.87109375"/>
				-- </Texture>
			-- local categoryLeft = button:CreateTexture(nil, "BORDER")
			-- categoryLeft:SetPoint("LEFT")
			-- categoryLeft:SetSize(76, 16)
			-- categoryLeft:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			-- categoryLeft:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
			-- button.categoryLeft = categoryLeft
			
			-- local categoryRight = button:CreateTexture(nil, "BORDER")
			-- categoryRight:SetPoint("RIGHT")
			-- categoryRight:SetSize(76, 16)
			-- categoryRight:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			-- categoryRight:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
			-- button.categoryRight = categoryRight
			
			-- local categoryMiddle = button:CreateTexture(nil, "BORDER")
			-- categoryMiddle:SetPoint("LEFT", categoryLeft, "RIGHT", -20, 0)
			-- categoryMiddle:SetPoint("RIGHT", categoryRight, "LEFT", 20, 0)
			-- categoryMiddle:SetHeight(16)
			-- categoryMiddle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			-- categoryMiddle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
			-- button.categoryMiddle = categoryMiddle
			
			return button
		end

		local function updateButton(button, object)
			local isHeader = type(object) == "table"
			if isHeader then
				button.info:SetText("")
				button.icon:SetTexture("")
				button.label:SetText(object.name)
				button.label:SetFontObject("GameFontNormal")
				button.itemID = nil
			else
				local item = ItemInfo[object]
				if item then
					local info = addon:GetItem(object)
					local r, g, b = GetItemQualityColor(item.quality)
					local source = info and info.source and next(info.source)
					local slot = not noSlot[item.subType] and _G[item.invType]
					local itemType = not (noArmor[item.invType] or noType[item.subType]) and (weaponTypes[item.subType] or item.subType)
					-- in some cases itemType is the same as slot, no need to show both
					if itemType and slot and itemType ~= slot then
						button.info:SetText(slot..", "..itemType)
					else
						button.info:SetText(slot or itemType or "")
					end
					button.label:SetText(item.name)
					button.label:SetTextColor(r, g, b)
					button.source:SetText(source and (tonumber(source) and EJ_GetEncounterInfo(source) or source))
				else
					button.label:SetText(RETRIEVING_ITEM_INFO)
					button.label:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
					button.source:SetText(nil)
					button.info:SetText(nil)
					button:GetParent():GetParent().parent.doUpdateList = true
				end
				button.icon:SetTexture(GetItemIcon(object))
				button.itemID = object
			end
			
			if GetMouseFocus() == button then
				if not isHeader then
					onEnter(button)
				else
					GameTooltip:Hide()
				end
			end

			button.index = index
			button.isHeader = isHeader
		end

		local function getList(self)
			return self.parent:GetList()
		end
		
		function Prototype:CreateScrollFrame()
			local scrollFrame = createScrollFrame(self, frame.Inset, createButton, BUTTON_HEIGHT, BUTTON_OFFSET)
			scrollFrame.list = getList
			scrollFrame.updateButton = updateButton
			scrollFrame.CreateHeader = createHeader
			self.scrollFrame = scrollFrame
			return scrollFrame
		end
	end
	
	do	-- scroll frame for navigation frame
		local BUTTON_HEIGHT = 16
		local BUTTON_OFFSET = 3
		
		local function onClick(self, button)
			local scrollFrame = self:GetParent():GetParent()
			if scrollFrame.onClick then
				scrollFrame.onClick(self, button)
			end
		end
		
		local function createButtonBase(frame)
			local button = CreateFrame("Button", nil, frame)
			button:SetHeight(BUTTON_HEIGHT)
			button:SetPoint("RIGHT", -5, 0)
			button:SetScript("OnClick", onClick)
			button:SetPushedTextOffset(0, 0)
			
			button.label = button:CreateFontString(nil, nil, "GameFontHighlightLeft")
			button.label:SetPoint("LEFT", 11, 0)
			button:SetFontString(button.label)
			
			return button
		end
		
		local function createButton(frame)
			local button = createButtonBase(frame)
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
			
			return button
		end
		
		local function createHeader2(frame)
			local button = createButtonBase(frame)
			
			button:SetNormalFontObject(GameFontNormal)
			
			local left = button:CreateTexture(nil, "BORDER")
			left:SetPoint("LEFT")
			left:SetSize(76, 16)
			left:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			left:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
			
			local right = button:CreateTexture(nil, "BORDER")
			right:SetPoint("RIGHT")
			right:SetSize(76, 16)
			right:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			right:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
			
			local middle = button:CreateTexture(nil, "BORDER")
			middle:SetPoint("LEFT", left, "RIGHT", -20, 0)
			middle:SetPoint("RIGHT", right, "LEFT", 20, 0)
			middle:SetHeight(16)
			middle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			middle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
			
			local left = button:CreateTexture(nil, "HIGHLIGHT")
			left:SetBlendMode("ADD")
			left:SetPoint("LEFT", -5, 0)
			left:SetSize(26, 18)
			left:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			left:SetTexCoord(18 / 256, 44 / 256, 18 / 64, 36 / 64)
			
			local right = button:CreateTexture(nil, "HIGHLIGHT")
			right:SetBlendMode("ADD")
			right:SetPoint("RIGHT", 5, 0)
			right:SetSize(26, 18)
			right:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			right:SetTexCoord(18 / 256, 44 / 256, 0, 18 / 64)
			
			local middle = button:CreateTexture(nil, "HIGHLIGHT")
			middle:SetBlendMode("ADD")
			middle:SetPoint("LEFT", left, "RIGHT")
			middle:SetPoint("RIGHT", right, "LEFT")
			middle:SetHeight(18)
			middle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			middle:SetTexCoord(0, 18 / 256, 0, 18 / 64)
			
			-- local highlight = button:CreateTexture()
			-- highlight:SetPoint("TOPLEFT", 3, -2)
			-- highlight:SetPoint("BOTTOMRIGHT", -3, 2)
			-- highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
			-- highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
			-- button:SetHighlightTexture(highlight)
			
			return button
		end
		
		local function createHeader(frame)
			local button = createButtonBase(frame, frame.onClick)
			
			button:SetNormalFontObject(GameFontNormal)
			
			local left = button:CreateTexture(nil, "BORDER")
			left:SetPoint("LEFT")
			left:SetSize(76, 16)
			left:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			left:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
			
			local right = button:CreateTexture(nil, "BORDER")
			right:SetPoint("RIGHT")
			right:SetSize(76, 16)
			right:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			right:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
			
			local middle = button:CreateTexture(nil, "BORDER")
			middle:SetPoint("LEFT", left, "RIGHT", -20, 0)
			middle:SetPoint("RIGHT", right, "LEFT", 20, 0)
			middle:SetHeight(16)
			middle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
			middle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
			
			local highlight = button:CreateTexture()
			highlight:SetPoint("TOPLEFT", 3, -2)
			highlight:SetPoint("BOTTOMRIGHT", -3, 2)
			highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
			highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
			button:SetHighlightTexture(highlight)
			
			return button
		end
		
		function Prototype:CreateNavigationFrame()
			local inset = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
			inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_ATTIC_OFFSET)
			inset:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET + 2)
			inset:SetPoint("RIGHT", self.Inset, "LEFT", PANEL_INSET_RIGHT_OFFSET, 0)
			
			local scrollFrame = createScrollFrame(self, inset, createButton, BUTTON_HEIGHT, BUTTON_OFFSET)
			scrollFrame.CreateHeader = createHeader
			self.navigationScrollFrame = scrollFrame
			return scrollFrame
		end
	end
end

function Prototype:CreateEditBox()
	local editbox = addon:CreateEditbox(self)
	editbox:SetAutoFocus(false)
	editbox:SetScript("OnEnterPressed", EditBox_ClearFocus)
	return editbox
end

ItemInfo.RegisterCallback(addon, "OnItemInfoReceivedBatch", function(self)
	for i, module in addon:IterateModules() do
		if module.doUpdateList then
			module.doUpdateList = nil
			-- module:UpdateList()
			module:ApplyFilters()
		end
	end
end)


local empty = {}

function Prototype:SetList(list)
	self.list = list or empty
	self.filteredList = nil
	self:UpdateList()
end

function Prototype:GetList(raw)
	return not raw and self.filteredList or self.list
end

local sortPriority = {
	"quality",
	"invType",
	"subType",
	"name",
	"itemLevel",
}

local sortDescending = {
	quality = true,
	itemLevel = true,
}

local customSort = {
	invType = {
		"INVTYPE_2HWEAPON",
		"INVTYPE_WEAPONMAINHAND",
		"INVTYPE_WEAPONOFFHAND",
		"INVTYPE_WEAPON",
		"INVTYPE_RANGED",
		"INVTYPE_SHIELD",
		"INVTYPE_HOLDABLE",
		"INVTYPE_HEAD",
		"INVTYPE_NECK",
		"INVTYPE_SHOULDER",
		"INVTYPE_CLOAK",
		"INVTYPE_CHEST",
		"INVTYPE_BODY",
		"INVTYPE_TABARD",
		"INVTYPE_WRIST",
		"INVTYPE_HAND",
		"INVTYPE_WAIST",
		"INVTYPE_LEGS",
		"INVTYPE_FEET",
		"INVTYPE_FINGER",
		"INVTYPE_TRINKET",
	},
	subType = {
		LBI["Plate"],
		LBI["Mail"],
		LBI["Leather"],
		LBI["Cloth"],
		LBI["Miscellaneous"],
		LBI["Axe"],
		LBI["Mace"],
		LBI["Sword"],
		LBI["Polearm"],
		LBI["Staff"],
		LBI["Dagger"],
		LBI["Bow"],
	},
}

-- reverse the tables for easier use
for k, v in pairs(customSort) do
	local t = {}
	for i, v in ipairs(v) do
		t[v] = i
	end
	customSort[k] = t
end

local mappings = {
	subType = weaponTypes,
	invType = invTypeExceptions,
}

local function listSort(a, b)
	a = ItemInfo[a]
	b = ItemInfo[b]
	if not (a and b) then return end
	for i, v in ipairs(sortPriority) do
		local valueA, valueB = a[v], b[v]
		valueA = mappings[v] and mappings[v][valueA] or valueA
		valueB = mappings[v] and mappings[v][valueB] or valueB
		if valueA ~= valueB then
			if sortDescending[v] then
				valueA, valueB = valueB, valueA
			end
			if not (valueA and valueB) then
				return valueA
			end
			local customSort = customSort[v]
			if customSort then
				local customSortA, customSortB = customSort[valueA], customSort[valueB]
				if (customSortA or customSortB) then
					if not (customSortA and customSortB) then
						return not customSortA and customSortB
					end
					return customSortA < customSortB
				end
			end
			return valueA < valueB
		end
	end
end

function Prototype:UpdateList()
	sort(self:GetList(), listSort)
	self.scrollFrame:update()
	if self.OnUpdateList then
		self:OnUpdateList()
	end
end

function Prototype:SetNavigationList(list)
	self.navigationScrollFrame.list = list
	self:UpdateNavigationList()
end

function Prototype:GetNavigationList()
	return self.navigationScrollFrame.list
end

function Prototype:UpdateNavigationList()
	self.navigationScrollFrame:update()
end