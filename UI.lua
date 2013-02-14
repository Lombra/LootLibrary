local _, addon = ...

local LBI = LibStub("LibBabble-Inventory-3.0"):GetUnstrictLookupTable()

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

local items = addon.items

local currentList
local filteredList

local moduleLists = {}

local scrollFrame

local frame = CreateFrame("Frame", "LootLibraryFrame", UIParent, "ButtonFrameTemplate")
addon.frame = frame
frame:SetPoint("CENTER")
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetScript("OnShow", function(self)
	PlaySound("igCharacterInfoOpen")
	if not PanelTemplates_GetSelectedTab(self) then
		PanelTemplates_SetTab(self, 1)
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
	local hasScrollFrame = frame.hasScrollFrame
	if hasScrollFrame then
		-- restore scroll position
		frame.scrollOffset = scrollFrame.offset
	end
end

local function onDisable(self)
	local frame = self.frame
	frame:Show()
	local hasScrollFrame = frame.hasScrollFrame
	scrollFrame:SetShown(hasScrollFrame)
	if hasScrollFrame then--and frame.scrollOffset then
		frame:SetList(frame.list)
		-- restore scroll position
		-- scrollFrame.scrollBar:SetValue(frame.scrollOffset)
	end
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

local doUpdate

do
	local function onClick(self, itemID)
		local Favorites = addon:GetModule("Favorites")
		Favorites:AddItem(itemID)
	end
	
	local dropdown = CreateFrame("Frame")
	dropdown.displayMode = "MENU"
	dropdown.initialize = function(self)
		local info = UIDropDownMenu_CreateInfo()
		info.text = "Add to favorites"
		info.func = onClick
		info.arg1 = UIDROPDOWNMENU_MENU_VALUE
		info.notCheckable = true
		UIDropDownMenu_AddButton(info)
	end
	
	local function onClick(self, button)
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
				Favorites:AddItem(self.itemID)
			elseif IsModifiedClick() then
				HandleModifiedItemClick(select(2, GetItemInfo(self.itemID)))
			end
		else
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
	
	local BUTTON_HEIGHT = 30
	
	local function createButton(frame)
		local button = CreateFrame("Button", nil, frame)
		button:SetSize(295, BUTTON_HEIGHT)
		button:SetScript("OnClick", onClick)
		button:SetScript("OnEnter", onEnter)
		button:SetScript("OnLeave", onLeave)
		button:SetScript("OnEvent", onEvent)
		button:RegisterEvent("MODIFIER_STATE_CHANGED")
		
		local stripe = button:CreateTexture(nil, "BACKGROUND")
		stripe:SetPoint("TOPLEFT", 1, 0)
		stripe:SetPoint("BOTTOMRIGHT", -1, 0)
		stripe:SetTexture(1, 1, 1, 0.08)
		button.stripe = stripe
		
		local icon = button:CreateTexture()
		icon:SetPoint("LEFT", 2, 0)
		icon:SetSize(15, 15)
		button.icon = icon
		
		local label = button:CreateFontString(nil, "BORDER", "GameFontHighlightLeft")
		label:SetPoint("LEFT", icon, "RIGHT", 2, 0)
		button.label = label
		button:SetFontString(label)
		
		local info = button:CreateFontString(nil, nil, "GameFontHighlightSmallRight")
		info:SetPoint("RIGHT", -3, 0)
		button.info = info
		
		local texture = button:CreateTexture(nil, "BACKGROUND")
		texture:SetTexture([[Interface\ClassTrainerFrame\TrainerTextures]])
		texture:SetTexCoord(0.00195313, 0.57421875, 0.65820313, 0.75000000)
		texture:SetAllPoints()
		button:SetNormalTexture(texture)
		
		local categoryLeft = button:CreateTexture(nil, "BORDER")
		categoryLeft:SetPoint("LEFT")
		categoryLeft:SetSize(76, 16)
		categoryLeft:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryLeft:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
		button.categoryLeft = categoryLeft
		
		local categoryRight = button:CreateTexture(nil, "BORDER")
		categoryRight:SetPoint("RIGHT")
		categoryRight:SetSize(76, 16)
		categoryRight:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryRight:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
		button.categoryRight = categoryRight
		
		local categoryMiddle = button:CreateTexture(nil, "BORDER")
		categoryMiddle:SetPoint("LEFT", categoryLeft, "RIGHT", -20, 0)
		categoryMiddle:SetPoint("RIGHT", categoryRight, "LEFT", 20, 0)
		categoryMiddle:SetHeight(16)
		categoryMiddle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryMiddle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
		button.categoryMiddle = categoryMiddle
		
		local highlight = button:CreateTexture()
		highlight:SetPoint("TOPLEFT", 3, -2)
		highlight:SetPoint("BOTTOMRIGHT", -3, 2)
		highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
		highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
		-- highlight:SetBlendMode("ADD")
		button.highlight = highlight
		button:SetHighlightTexture(highlight)
		
		return button
	end
	
	-- frame.Inset:Hide()
	local function createButton(frame)
		local button = CreateFrame("Button", nil, frame)
		button:SetHeight(BUTTON_HEIGHT)
		button:SetPoint("RIGHT", -5, 0)
		button:SetScript("OnClick", onClick)
		button:SetScript("OnEnter", onEnter)
		button:SetScript("OnLeave", onLeave)
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		local icon = button:CreateTexture()
		icon:SetPoint("LEFT", 3, 0)
		icon:SetSize(24, 24)
		button.icon = icon
		
		local label = button:CreateFontString(nil, "BORDER", "GameFontHighlightLeft")
		label:SetJustifyV("TOP")
		label:SetPoint("TOPLEFT", icon, "TOPRIGHT", 4, 0)
		label:SetPoint("RIGHT", -21, 0)
		label:SetPoint("BOTTOM", 0, 3)
		label:SetWordWrap(false)
		button.label = label
		button:SetFontString(label)
		button:SetPushedTextOffset(0, 0)
		
		local source = button:CreateFontString(nil, nil, "GameFontHighlightSmallLeft")
		source:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 4, 0)
		button.source = source
		
		local info = button:CreateFontString(nil, nil, "GameFontHighlightSmallRight")
		info:SetPoint("BOTTOM", icon)
		info:SetPoint("RIGHT", -3, 0)
		button.info = info
		
		local l = button:CreateTexture(nil, "BACKGROUND")
		l:SetTexture([[Interface\PetBattles\PetJournal]])
		l:SetTexCoord(254 / 512, (254 + 24) / 512, 130 / 1024, 178 / 1024)
		l:SetPoint("TOPLEFT")
		l:SetPoint("BOTTOMLEFT")
		l:SetWidth(13)

		local r = button:CreateTexture(nil, "BACKGROUND")
		r:SetTexture([[Interface\PetBattles\PetJournal]])
		r:SetTexCoord((465 - 24) / 512, 465 / 512, 130 / 1024, 178 / 1024)
		r:SetPoint("TOPRIGHT")
		r:SetPoint("BOTTOMRIGHT")
		r:SetWidth(13)

		local m = button:CreateTexture(nil, "BACKGROUND")
		m:SetTexture([[Interface\PetBattles\PetJournal]])
		m:SetTexCoord((254 + 24) / 512, (465 - 24) / 512, 130 / 1024, 178 / 1024)
		m:SetPoint("TOPLEFT", l, "TOPRIGHT")
		m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
		
		-- <Size x="208" y="46"/>
		-- local texture = button:CreateTexture(nil, "BACKGROUND")
		-- texture:SetTexture([[Interface\PetBattles\PetJournal]])
		-- texture:SetTexCoord(0.49804688, 0.90625000, 0.12792969, 0.17285156)
		-- texture:SetAllPoints()
		-- button:SetNormalTexture(texture)
		
		local categoryLeft = button:CreateTexture(nil, "BORDER")
		categoryLeft:SetPoint("LEFT")
		categoryLeft:SetSize(76, 16)
		categoryLeft:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryLeft:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
		button.categoryLeft = categoryLeft
		
		local categoryRight = button:CreateTexture(nil, "BORDER")
		categoryRight:SetPoint("RIGHT")
		categoryRight:SetSize(76, 16)
		categoryRight:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryRight:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
		button.categoryRight = categoryRight
		
		local categoryMiddle = button:CreateTexture(nil, "BORDER")
		categoryMiddle:SetPoint("LEFT", categoryLeft, "RIGHT", -20, 0)
		categoryMiddle:SetPoint("RIGHT", categoryRight, "LEFT", 20, 0)
		categoryMiddle:SetHeight(16)
		categoryMiddle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryMiddle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
		button.categoryMiddle = categoryMiddle
		
		local highlight = button:CreateTexture()
		highlight:SetPoint("TOPLEFT", 3, -2)
		highlight:SetPoint("BOTTOMRIGHT", -3, 2)
		highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
		highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
		-- highlight:SetBlendMode("ADD")
		button.highlight = highlight
		button:SetHighlightTexture(highlight)
		
		return button
	end

	frame:SetWidth(338 + 256+22)
	
	frame.Inset:SetPoint("TOPLEFT", 260+22, PANEL_INSET_ATTIC_OFFSET)
	
	scrollFrame = CreateFrame("ScrollFrame", "LootLibraryScrollFrame", frame, "HybridScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", frame.Inset, 4, -4)
	scrollFrame:SetPoint("BOTTOMRIGHT", frame.Inset, -23, 4)
	-- scrollFrame:SetWidth(328)
	-- scrollFrame:SetHeight(360)
	-- scrollFrame.scrollChild:SetWidth(295)

	local scrollBar = CreateFrame("Slider", nil, scrollFrame, "HybridScrollBarTemplate")
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 0, -12)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 11)
	scrollBar.doNotHide = true

	local NUM_BUTTONS = math.ceil(scrollFrame:GetHeight() / BUTTON_HEIGHT) + 1
	scrollFrame.buttons = {}

	for i = 1, NUM_BUTTONS do
		local button = createButton(scrollFrame.scrollChild)
		if i == 1 then
			button:SetPoint("TOPLEFT", scrollFrame.scrollChild, 1, -2)
		else
			button:SetPoint("TOP", scrollFrame.buttons[i - 1], "BOTTOM")--, 0, -TOKEN_BUTTON_OFFSET)
		end
		if i % 2 == 1 then
			-- button.stripe:Hide()
		end
		scrollFrame.buttons[i] = button
	end

	HybridScrollFrame_CreateButtons(scrollFrame)--, nil, nil, nil, nil, nil, nil, -TOKEN_BUTTON_OFFSET)

	function scrollFrame:update()
		local offset = HybridScrollFrame_GetOffset(scrollFrame)
		local buttons = scrollFrame.buttons
		local numButtons = #buttons
		local list = addon:GetList()
		for i = 1, numButtons do
			local index = offset + i
			local object = list[index]
			local button = buttons[i]
			if not object then
				button:Hide()
			else
				local isHeader = type(object) == "table"
				button.categoryLeft:SetShown(isHeader)
				button.categoryRight:SetShown(isHeader)
				button.categoryMiddle:SetShown(isHeader)
				if isHeader then
					button.info:SetText("")
					button.icon:SetTexture("")
					button.highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
					button.highlight:SetPoint("TOPLEFT", 3, -2)
					button.highlight:SetPoint("BOTTOMRIGHT", -3, 2)
					button.label:SetText(object.name)
					button.label:SetFontObject("GameFontNormal")
					if object.special then
						button.label:SetFontObject("GameFontHighlight")
					end
					button.label:SetPoint("LEFT", 11, 0)
					button.itemID = nil
				else
					local itemName, icon, source, armorType, slot
					local item = items[object]
					if item then
						itemName = item.name
						icon = item.icon
						source = EJ_GetEncounterInfo(next(item.source))
						armorType = item.armorType
						slot = item.slot
					else
						local name, _, quality, iLevel, reqLevel, class, subclass, _, equipSlot = GetItemInfo(object)
						itemName = name or RETRIEVING_ITEM_INFO
						icon = GetItemIcon(object)
						if name then
							local r, g, b = GetItemQualityColor(quality)
							button.label:SetTextColor(r, g, b)
							subclass = not noArmor[equipSlot] and (weaponTypes[subclass] or subclass)
						else
							doUpdate = true
						end
						source = nil
						armorType = subclass
						slot = _G[equipSlot]
					end
					button.label:SetText(itemName)
					button.icon:SetTexture(icon)
					button.source:SetText(source)
					if armorType and slot then
						button.info:SetText(slot..", "..armorType)
					else
						button.info:SetText(slot or armorType or "")
					end
					button.label:SetPoint("LEFT", button.icon, "RIGHT", 4, 0)
					button.highlight:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
					button.highlight:SetPoint("TOPLEFT")
					button.highlight:SetPoint("BOTTOMRIGHT")
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
				button:Show()
			end
		end
		
		local totalHeight = #list * (BUTTON_HEIGHT)-- + TOKEN_BUTTON_OFFSET)
		local displayedHeight = #buttons * (BUTTON_HEIGHT)-- + TOKEN_BUTTON_OFFSET)

		HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
	end
end

do
	local BUTTON_HEIGHT = 17
	local BUTTON_OFFSET = 3
	
	local function onClick(self)
		Browse:SetNavigationList(self)
	end
	
	local function createButton(frame, onClick)
		local button = CreateFrame("Button", nil, frame)
		button:SetHeight(BUTTON_HEIGHT)
		button:SetPoint("RIGHT", -5, 0)
		button:SetScript("OnClick", onClick)
		
		local label = button:CreateFontString(nil, nil, "GameFontHighlightLeft")
		label:SetPoint("LEFT", 11, 0)
		button.label = label
		button:SetFontString(label)
		button:SetPushedTextOffset(0, 0)
		
		local highlight = button:CreateTexture()
		-- highlight:SetAllPoints()
		highlight:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
		button.highlight = highlight
		button:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
		
		return button
	end
	
	local function createHeader(frame, onClick)
		local button = createButton(frame, onClick)
		
		local categoryLeft = button:CreateTexture(nil, "BORDER")
		categoryLeft:SetPoint("LEFT")
		categoryLeft:SetSize(76, 16)
		categoryLeft:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryLeft:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
		button.categoryLeft = categoryLeft
		
		local categoryRight = button:CreateTexture(nil, "BORDER")
		categoryRight:SetPoint("RIGHT")
		categoryRight:SetSize(76, 16)
		categoryRight:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryRight:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
		button.categoryRight = categoryRight
		
		local categoryMiddle = button:CreateTexture(nil, "BORDER")
		categoryMiddle:SetPoint("LEFT", categoryLeft, "RIGHT", -20, 0)
		categoryMiddle:SetPoint("RIGHT", categoryRight, "LEFT", 20, 0)
		categoryMiddle:SetHeight(16)
		categoryMiddle:SetTexture([[Interface\Buttons\CollapsibleHeader]])
		categoryMiddle:SetTexCoord(0.48046875, 0.98046875, 0.01562500, 0.26562500)
		button.categoryMiddle = categoryMiddle
		
		local highlight = button:CreateTexture()
		highlight:SetPoint("TOPLEFT", 3, -2)
		highlight:SetPoint("BOTTOMRIGHT", -3, 2)
		highlight:SetTexture([[Interface\TokenFrame\UI-TokenFrame-CategoryButton]])
		highlight:SetTexCoord(0, 1, 0.609375, 0.796875)
		button.highlight = highlight
		button:SetHighlightTexture(highlight)
		
		return button
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
		self:SetPoint("TOP", self.inset, 0, -self:GetNumVisibleHeaders() * (BUTTON_HEIGHT + BUTTON_OFFSET) - 4)
	end
	
	local function addHeader(self, onClick)
		local n = #self.headers + 1
		local header = createHeader(self, onClick)
		if n == 1 then
			header:SetPoint("TOPLEFT", self.inset, 5, -6)
		else
			header:SetPoint("TOP", self.headers[n - 1], "BOTTOM", 0, -BUTTON_OFFSET)
		end
		self.headers[n] = header
		return header
	end
	
	function Prototype:CreateNavigationFrame(name, onClick)
		local inset = CreateFrame("Frame", nil, self, "InsetFrameTemplate")
		inset:SetPoint("TOPLEFT", PANEL_INSET_LEFT_OFFSET, PANEL_INSET_ATTIC_OFFSET)
		inset:SetPoint("BOTTOM", 0, PANEL_INSET_BOTTOM_OFFSET)
		inset:SetPoint("RIGHT", self.Inset, "LEFT", PANEL_INSET_RIGHT_OFFSET, 0)
		
		local scrollFrame = CreateFrame("ScrollFrame", name, self, "HybridScrollFrameTemplate")
		scrollFrame:SetPoint("LEFT", inset, 4, 0)
		scrollFrame:SetPoint("BOTTOMRIGHT", inset, -23, 4)
		scrollFrame.inset = inset
		scrollFrame.AddHeader = addHeader
		scrollFrame.GetNumVisibleHeaders = getNumVisibleHeaders
		scrollFrame.UpdateHeight = updateScrollSize
		scrollFrame.headers = {}
		scrollFrame.update = function()
			local offset = HybridScrollFrame_GetOffset(scrollFrame)
			local list = scrollFrame.list
			local buttons = scrollFrame.buttons
			local numButtons = #buttons
			for i = 1, numButtons do
				local index = offset + i
				local object = list[index]
				local button = buttons[i]
				if object then
					scrollFrame.updateButton(button, list[index], list)
				end
				button:SetShown(object)
			end
			
			local numHeaders = scrollFrame:GetNumVisibleHeaders()
			local totalHeight = #list * (BUTTON_HEIGHT + BUTTON_OFFSET)
			local displayedHeight = (#buttons - numHeaders) * (BUTTON_HEIGHT + BUTTON_OFFSET)
			if scrollFrame.dynamicHeaders then
				scrollFrame:UpdateHeight()
			end

			HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
		end
		
		local scrollHeight = inset:GetTop() - inset:GetBottom()
		local buttons = {}
		scrollFrame.buttons = buttons
		
		local scrollBar = CreateFrame("Slider", nil, scrollFrame, "HybridScrollBarTemplate")
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOP", inset, 0, -16)
		scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 11)
		scrollBar.doNotHide = true
		
		for i = 1, (ceil(scrollHeight / BUTTON_HEIGHT) + 1) do
			local button = createButton(scrollFrame.scrollChild, onClick)
			if i == 1 then
				button:SetPoint("TOPLEFT", 1, -2)
			else
				button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT", 0, -BUTTON_OFFSET)
			end
			buttons[i] = button
		end
		
		HybridScrollFrame_CreateButtons(scrollFrame, nil, nil, nil, nil, nil, nil, -BUTTON_OFFSET)
		
		return scrollFrame
	end
end

local function onEditFocusLost(self)
	self:SetFontObject("ChatFontSmall")
	self:SetTextColor(0.5, 0.5, 0.5)
end

local function onEditFocusGained(self)
	self:SetTextColor(1, 1, 1)
end

function Prototype:CreateSearchBox(name)
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

function Prototype:CreateEditBox(name)
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

local function onUpdate(self)
	scrollFrame:update()
	self:RemoveOnUpdate()
	doUpdate = nil
end

addon:RegisterEvent("GET_ITEM_INFO_RECEIVED", function(self)
	if not doUpdate then return end
	self:SetOnUpdate(onUpdate)
end)


local empty = {}

function Prototype:SetList(list)
	currentList = list or empty
	filteredList = nil
	scrollFrame:update()
	self.list = list
end

function addon:GetList(raw)
	return not raw and filteredList or currentList
end

function Prototype:UpdateList()
	scrollFrame:update()
end

function addon:SetFilteredList(list)
	filteredList = list
	scrollFrame:update()
end

function addon:ClearFilters()
	filteredList = nil
	scrollFrame:update()
end