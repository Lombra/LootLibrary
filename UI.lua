local addonName, addon = ...

local LBI = LibStub("LibBabble-Inventory-3.0"):GetUnstrictLookupTable()
local IIC = ItemInfoCache

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
	[LBI["Polearm"]] = true,
	[LBI["Staff"]] = true,
	[LBI["Wand"]] = true,
	[LBI["Gun"]] = true,
	[LBI["Crossbow"]] = true,
	[LBI["Bow"]] = true,
	[LBI["Shield"]] = true,
}

local widgetIndex = 1
local function getWidgetName()
	local name = addonName.."Widget"..widgetIndex
	widgetIndex = widgetIndex + 1
	return name
end

local items = IIC.items

local frame = CreateFrame("Frame", "LootLibraryFrame", UIParent, "ButtonFrameTemplate")
addon.frame = frame
frame:SetPoint("CENTER")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetScript("OnShow", function(self)
	PlaySound("igCharacterInfoOpen")
	if not PanelTemplates_GetSelectedTab(self) then
		PanelTemplates_SetTab(self, 1)
        -- addon:GetModule("Browse"):CacheAllItems()
	end
end)
frame:SetScript("OnHide", function(self)
	PlaySound("igCharacterInfoClose")
end)
frame.TitleText:SetText("LootLibrary")
ButtonFrameTemplate_HidePortrait(frame)
ButtonFrameTemplate_HideButtonBar(frame)
tinsert(UISpecialFrames, frame:GetName())
UIPanelWindows[frame:GetName()] = {
	area = "left",
	-- pushable = 3,
	whileDead = true,
}

local tabs = {}

local function onClick(self)
	PanelTemplates_Tab_OnClick(self, frame)
	PlaySound("igCharacterInfoTab")
end

local function onEnable(self)
	local frame = self.frame
	frame:Hide()
end

local function onDisable(self)
	local frame = self.frame
	frame:Show()
end

local function createTab()
	local numTabs = #tabs + 1
	local tab = CreateFrame("Button", "LootLibraryFrameTab"..numTabs, frame, "CharacterFrameTabButtonTemplate")
	if numTabs == 1 then
		tab:SetPoint("BOTTOMLEFT", 19, -30)
	else
		tab:SetPoint("LEFT", tabs[numTabs - 1], "RIGHT", -15, 0)
	end
	tab:SetID(numTabs)
	tab:SetScript("OnClick", onClick)
	tab:SetScript("OnEnable", onEnable)
	tab:SetScript("OnDisable", onDisable)
	tabs[numTabs] = tab
	PanelTemplates_SetNumTabs(frame, numTabs)
	return tab
end

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

function addon:CreateUI(name)
	local ui = setmetatable(CreateFrame("Frame", nil, frame), mt)
	ui:SetAllPoints()
	ui:Hide()
	ui:SetScript("OnShow", onShow)
	ui:SetScript("OnHide", onHide)
	ui.name = name
	ui.filterArgs = {}
	
	ui.Inset = frame.Inset
	
	local tab = createTab()
	tab:SetText(name)
	tab.frame = ui
	return ui
end

function addon:GetSelectedTab()
	return tabs[PanelTemplates_GetSelectedTab(frame)].frame
end

do
	frame:SetWidth(338 + 256+22)
	
	frame.Inset:SetPoint("TOPLEFT", 260+22, PANEL_INSET_ATTIC_OFFSET)
	
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
		local offset = HybridScrollFrame_GetOffset(self)
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
	
	local function createScrollFrame(self, inset, createButton, onClick, buttonHeight, buttonOffset)
		local name = getWidgetName()
		local scrollFrame = CreateFrame("ScrollFrame", name, self, "HybridScrollFrameTemplate")
		scrollFrame:SetPoint("TOP", inset, 0, -4)
		scrollFrame:SetPoint("LEFT", inset, 4, 0)
		scrollFrame:SetPoint("BOTTOMRIGHT", inset, -23, 4)
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
		_G[name] = nil
		
		local scrollBar = CreateFrame("Slider", nil, scrollFrame, "HybridScrollBarTemplate")
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOP", inset, 0, -16)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 11)
		scrollBar.doNotHide = true
		
		local buttons = {}
		scrollFrame.buttons = buttons
		
		for i = 1, (ceil(scrollFrame:GetHeight() / buttonHeight) + 1) do
			local button = createButton(scrollFrame.scrollChild, onClick)
			if i == 1 then
				button:SetPoint("TOPLEFT", 1, -2)
			else
				button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -buttonOffset)
			end
			buttons[i] = button
		end
		
		HybridScrollFrame_CreateButtons(scrollFrame, nil, nil, nil, nil, nil, nil, -buttonOffset)
		
		return scrollFrame
	end
	
	do	-- scroll frame for items
		local dropdown = CreateFrame("Frame")
		dropdown.displayMode = "MENU"
		
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
				ToggleDropDownMenu(nil, self.itemID, dropdown, self, 0, 0)
			end
		end

		local function onUpdate(self)
			if GameTooltip:IsOwned(self) then
				if IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not IsEquippedItem(self.itemID)) then
					GameTooltip_ShowCompareItem()
				else
					ShoppingTooltip1:Hide()
					ShoppingTooltip2:Hide()
					ShoppingTooltip3:Hide()
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
				GameTooltip:SetItemByID(self.itemID)
				local info = addon:GetItem(self.itemID)
				if info then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Sources:")
					for k, v in pairs(info.source) do
						GameTooltip:AddLine(tonumber(k) and EJ_GetEncounterInfo(k) or k, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
					end
					GameTooltip:Show()
				end
				self.showingTooltip = true
				if IsModifiedClick("DRESSUP") then
					ShowInspectCursor()
				end
				self:SetScript("OnUpdate", onUpdate)
			end
		end

		local function onLeave(self)
			GameTooltip:Hide()
			self.showingTooltip = false
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
				local item = items[object]
				if item then
					local info = addon:GetItem(object)
					local r, g, b = GetItemQualityColor(item.quality)
					local source = info and info.source and next(info.source)
					local slot = not noSlot[item.type] and _G[item.slot]
					local armorType = not noArmor[slot] and item.type
					-- in some cases armorType is the same as slot, no need to show both
					if armorType and slot and armorType ~= slot then
						button.info:SetText(slot..", "..armorType)
					else
						button.info:SetText(slot or armorType or "")
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
			
			if button.showingTooltip then
				if not isHeader then
					GameTooltip:SetItemByID(button.itemID)
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
			local scrollFrame = createScrollFrame(self, frame.Inset, createButton, onClick, BUTTON_HEIGHT, BUTTON_OFFSET)
			scrollFrame.list = getList
			scrollFrame.updateButton = updateButton
			scrollFrame.CreateHeader = createHeader
			self.scrollFrame = scrollFrame
			return scrollFrame
		end
	end
	
	do	-- scroll frame for navigation frame
		local BUTTON_HEIGHT = 17
		local BUTTON_OFFSET = 3
		
		local function onClick(self)
			Browse:SetNavigationList(self)
		end
		
		local function createButtonBase(frame, onClick)
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
		
		local function createButton(frame, onClick)
			local button = createButtonBase(frame, onClick)
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
		
		function Prototype:CreateNavigationFrame(onClick)
			local inset = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
			inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_ATTIC_OFFSET)
			inset:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET)
			inset:SetPoint("RIGHT", self.Inset, "LEFT", PANEL_INSET_RIGHT_OFFSET, 0)
			
			local scrollFrame = createScrollFrame(self, inset, createButton, onClick, BUTTON_HEIGHT, BUTTON_OFFSET)
			scrollFrame.CreateHeader = createHeader
			scrollFrame.onClick = onClick
			self.navigationScrollFrame = scrollFrame
			return scrollFrame
		end
	end
end

local function onEditFocusLost(self)
	self:SetFontObject("ChatFontSmall")
	self:SetTextColor(0.5, 0.5, 0.5)
end

local function onEditFocusGained(self)
	self:SetTextColor(1, 1, 1)
end

function Prototype:CreateSearchBox()
	local name = getWidgetName()
	local searchBox = CreateFrame("EditBox", name, self, "SearchBoxTemplate")
	-- apparently the textures bug if you don't specify a name, but we don't need it once it's created, so remove it from global namespace
	_G[name] = nil
	searchBox:SetHeight(20)
	searchBox:SetFontObject("ChatFontSmall")
	searchBox:SetTextColor(0.5, 0.5, 0.5)
	searchBox:HookScript("OnEditFocusLost", onEditFocusLost)
	searchBox:HookScript("OnEditFocusGained", onEditFocusGained)
	searchBox:SetScript("OnEnterPressed", EditBox_ClearFocus)
	return searchBox
end

function Prototype:CreateEditBox()
	local name = getWidgetName()
	local editbox = CreateFrame("EditBox", name, self, "InputBoxTemplate")
	-- apparently the textures bug if you don't specify a name, but we don't need it once it's created, so remove it from global namespace
	_G[name] = nil
	-- editbox:SetSize(100, 20)
	editbox:SetHeight(20)
	editbox:SetFontObject("ChatFontSmall")
	-- editbox:SetTextColor(0.5, 0.5, 0.5)
	editbox:SetAutoFocus(false)
	-- editbox:HookScript("OnEditFocusLost", onEditFocusLost)
	-- editbox:HookScript("OnEditFocusGained", onEditFocusGained)
	editbox:SetScript("OnEnterPressed", EditBox_ClearFocus)
	return editbox
end

IIC.RegisterCallback(addon, "GetItemInfoReceivedAll", function(self)
	for k, module in addon:IterateModules() do
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
	"slot",
	"type",
	"name",
	"itemLevel",
}

local sortAscending = {
	name = true,
	slot = true,
	type = true,
}

local customSort = {
	slot = {
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
	type = {
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

local function listSort(a, b)
	a, b = items[a], items[b]
	if not (a and b) then return end
	for i, v in ipairs(sortPriority) do
		if a[v] ~= b[v] then
			if sortAscending[v] then
				a, b = b, a
			end
			local valueA, valueB = a[v], b[v]
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
					return customSortA > customSortB
				end
			end
			return valueA > valueB
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