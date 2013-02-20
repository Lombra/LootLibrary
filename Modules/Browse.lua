local addonName, addon = ...

local Browse = addon:NewModule("Browse", addon:CreateUI("Browse"))
local scrollFrame = Browse:CreateScrollFrame()
scrollFrame:AddHeader()
scrollFrame:UpdateHeight()

local data = {
	tiers = {},
	instances = {},
	encounters = {},
}

local home = {type = "tiers"}

local specs = {}

local n = 1
for i = 1, GetNumClasses() do
	local classDisplayName, classTag, classID = GetClassInfo(i)
	for i = 1, GetNumSpecializationsForClassID(classID) do
		specs[GetSpecializationInfoForClassID(classID, i)] = n
		n = n + 1
	end
end

local filterMenu = CreateFrame("Frame")
filterMenu.displayMode = "MENU"
filterMenu.initialize = addon.InitializeGearFilter
filterMenu.module = Browse
filterMenu.onClick = function(self, classID, specID)
	Browse:LoadSpecData(Browse:GetNavigationList() ~= home and Browse:GetSelectedTier())
end

local filterButton = CreateFrame("Button", "LootLibraryFilter", Browse, "UIMenuButtonStretchTemplate")
filterButton:SetWidth(96)
filterButton:SetPoint("TOPLEFT", 16, -32)
filterButton:SetText(GEAR_FILTER)
filterButton.rightArrow:Show()
filterButton:SetScript("OnClick", function(self)
	ToggleDropDownMenu(nil, nil, filterMenu, self, 0, 0)
	PlaySound("igMainMenuOptionCheckBoxOn")
end)

local EJ_DIFF_5MAN 			= 1
local EJ_DIFF_5MAN_HEROIC 	= 2

local EJ_DIFF_10MAN		 	= 1
local EJ_DIFF_25MAN		 	= 2
local EJ_DIFF_10MAN_HEROIC 	= 3
local EJ_DIFF_25MAN_HEROIC 	= 4
local EJ_DIFF_LFRAID	 	= 5

local EJ_DIFF_DUNGEON_TBL = {
	{
		enumValue = EJ_DIFF_5MAN,
		size = 5,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 1
	},
	{
		enumValue = EJ_DIFF_5MAN_HEROIC,
		size = 5,
		prefix = PLAYER_DIFFICULTY2,
		difficultyID =  2
	},
}

local EJ_DIFF_RAID_TBL = {
	{
		enumValue = EJ_DIFF_LFRAID,
		size = 25,
		prefix = PLAYER_DIFFICULTY3,
		difficultyID = 7
	},
	{
		enumValue = EJ_DIFF_10MAN,
		size = 10,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 3
	},
	{
		enumValue = EJ_DIFF_10MAN_HEROIC,
		size = 10,
		prefix = PLAYER_DIFFICULTY2,
		difficultyID = 5
	},
	{
		enumValue = EJ_DIFF_25MAN,
		size = 25,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 4
	},
	{
		enumValue = EJ_DIFF_25MAN_HEROIC,
		size = 25,
		prefix = PLAYER_DIFFICULTY2,
		difficultyID = 6
	},
}

local difficultyInfo = {}

for i, v in ipairs(EJ_DIFF_DUNGEON_TBL) do
	difficultyInfo[v.difficultyID] = v
end

for i, v in ipairs(EJ_DIFF_RAID_TBL) do
	difficultyInfo[v.difficultyID] = v
end

local function selectDifficulty(self, value)
	Browse:SetDifficulty(value)
end

local difficultyMenu = CreateFrame("Frame")
difficultyMenu.displayMode = "MENU"
difficultyMenu.initialize = function(self, level)
	local currDifficulty = Browse:GetFilter("sourceDifficulty")
	local currentList = Browse:GetNavigationList()
	local diffList = Browse:GetDifficulties(currentList.isRaid)
	
	local filter = currentList.difficulty
	local selectedEncounter = Browse:GetFilter("source")
	if selectedEncounter then
		filter = data.encounters[selectedEncounter].difficulty
	end
	
	for i = 1, #diffList do
		local entry = diffList[i]
		local info = UIDropDownMenu_CreateInfo()
		info.text = format(ENCOUNTER_JOURNAL_DIFF_TEXT, entry.size, entry.prefix)
		info.func = selectDifficulty
		info.arg1 = entry.difficultyID
		info.checked = currDifficulty == entry.difficultyID
		info.disabled = filter and bit.band(filter, 2 ^ entry.difficultyID) == 0
		UIDropDownMenu_AddButton(info)
	end
end

local difficultyButton = CreateFrame("Button", "LootLibraryDifficulty", Browse, "UIMenuButtonStretchTemplate")
difficultyButton:SetWidth(120)
difficultyButton:SetPoint("LEFT", filterButton, "RIGHT", 16, 0)
difficultyButton:SetText("(10) Normal")
difficultyButton.rightArrow:Show()
difficultyButton:SetScript("OnClick", function(self)
	ToggleDropDownMenu(nil, nil, difficultyMenu, self, 0, 0)
	PlaySound("igMainMenuOptionCheckBoxOn")
end)

local searchBox = Browse:CreateSearchBox("LootLibrarySearchBox")
searchBox:SetPoint("TOPRIGHT", -16, -33)
searchBox:SetSize(128, 20)
searchBox:SetScript("OnTextChanged", function(self, isUserInput)
	if not isUserInput then
		return
	end
	local text = self:GetText():lower()
	local search = {}
	for _, tier in ipairs(addon:GetList(true)) do
		for _, instance in ipairs(tier.data) do
			if (self:GetText():trim() == "" or strfind(instance.name:lower(), text)) and not instance.special then
				tinsert(search, instance)
			end
			for _, boss in ipairs(instance.data) do
				if (self:GetText():trim() == "" or strfind(boss.name:lower(), text)) and not boss.special then
					tinsert(search, boss)
				end
			end
		end
	end
	for itemID, data in pairs(items) do
		if self:GetText():trim() == "" or strfind(data.name:lower(), text) then
			tinsert(search, itemID)
		end
	end
	Browse:SetNavigationList(search)
end)

local tierButton
local instanceButton

do
	local highlight
	
	local function onClick(self)
		Browse:OnClick(self)
	end
	
	function Browse:OnClick(object)
		if highlight then
			highlight:UnlockHighlight()
			highlight = nil
		end
		self.scrollFrame.headers[1]:Hide()
		if object.type == "tiers" then
			tierButton:Hide()
			instanceButton:Hide()
			self:SetList(nil)
			self:SetNavigationList(object.list)
			tierButton.id = nil
		elseif object.type == "instances" then
			instanceButton:Hide()
			self:SetSelectedTier(object.id)
			self:SetList(nil)
			self:SetNavigationList(object.list)
		elseif object.type == "encounters" then
			if not self:IsValidDifficulty("instances", object.id) then
				self:SelectValidDifficulty("instances", object.id)
			end
			self:SetSelectedInstance(object.id)
		else
			highlight = object
			object:LockHighlight()
			if not self:IsValidDifficulty("encounters", object.id) then
				self:SelectValidDifficulty("encounters", object.id)
			end
			self.scrollFrame.headers[1]:SetText(object.list.name)
			self.scrollFrame.headers[1]:Show()
			self:SetFilter("source", object.id)
			self:ApplyFilters()
		end
	end
	
	local scrollFrame = Browse:CreateNavigationFrame(onClick)
	scrollFrame.dynamicHeaders = true
	scrollFrame.updateButton = function(button, object, list)
		local item = data[list.type][object]
		button:SetText(item.name)
		button.type = item.type
		button.list = item
		button.index = index
		button.id = object
	end

	local homeButton = scrollFrame:AddHeader(onClick)
	homeButton.type = "tiers"
	homeButton.list = home
	homeButton:SetText(HOME)

	tierButton = scrollFrame:AddHeader(onClick)
	tierButton.type = "instances"
	tierButton.label:SetPoint("LEFT", 15, 0)
	tierButton:Hide()

	instanceButton = scrollFrame:AddHeader(onClick)
	instanceButton.type = "encounters"
	instanceButton.label:SetPoint("LEFT", 19, 0)
	instanceButton:Hide()
end

local defaults = {
	profile = {
		autoSelectInstance = true,
	},
}

local function addInstances(tier, isRaid)
	local n = 1
	while true do
		local instanceID, name, _, _, buttonImage, _, _, link = EJ_GetInstanceByIndex(n, isRaid)
		if not instanceID then
			break
		end
		n = n + 1
		tinsert(tier, instanceID)
		data.instances[instanceID] = {
			type = "encounters",
			name = name,
			difficulty = 0,
			isRaid = isRaid,
			loot = {},
		}
	end
end

local p
local function refreshLoot(self)
	self:SetOnUpdate(self.RefreshLoot)
	if not p then
		print(" --- ")
		print("OnEvent", #addon:GetAllItems())
		p = true
	end
end

function Browse:OnInitialize()
	self.db = addon.db:RegisterNamespace("Browse", defaults)
	self:RegisterEvent("EJ_LOOT_DATA_RECIEVED", refreshLoot)
	
	for i = 1, EJ_GetNumTiers() do
		home[i] = i
		local name = EJ_GetTierInfo(i)
		local tier = {
			type = "instances",
			name = name,
			standby = true,
		}
		data.tiers[i] = tier
		EJ_SelectTier(i)
		addInstances(tier, false)
		addInstances(tier, true)
	end
	
	self:SetNavigationList(home)
	self:SetList(nil)
end

local lastInstance
local lastDifficulty

function Browse:OnShow()
	if not self.db.profile.autoSelectInstance then return end
	
	-- navigate to current instance
	local instanceID = EJ_GetCurrentInstance()
	local _, _, difficultyIndex = GetInstanceInfo()
	if instanceID ~= 0 then--and (instanceID ~= lastInstance or difficultyIndex ~= lastDifficultyIndex) then
		lastInstance = instanceID
		lastDifficulty = difficultyIndex
		if IsPartyLFG() and IsInRaid() then
			difficultyIndex = EJ_DIFF_LFRAID
		end
		self:SelectInstance(instanceID)
		if self:IsValidDifficulty("instances", instanceID, difficultyIndex) then
			self:SetDifficulty(difficultyIndex)
		else
			self:SelectValidDifficulty("instances", instanceID)
		end
	end
end

function Browse:IsValidDifficulty(objectType, objectID, filter)
	filter = filter or self:GetFilter("sourceDifficulty")
	return filter and bit.band(data[objectType][objectID].difficulty, 2 ^ filter) > 0
end

-- select the first valid difficulty by going through the flags
function Browse:SelectValidDifficulty(objectType, objectID)
	local difficulty = data[objectType][objectID].difficulty
	for i = 0, difficulty do
		if bit.band(difficulty, bit.lshift(1, i)) > 0 then
			self:SetDifficulty(i)
			break
		end
	end
end

function Browse:GetDifficulties(isRaid)
	return isRaid and EJ_DIFF_RAID_TBL or EJ_DIFF_DUNGEON_TBL
end

function Browse:SetDifficulty(difficultyID)
	self:SetFilter("sourceDifficulty", difficultyID)
	self:ApplyFilters()
	local entry = difficultyInfo[difficultyID]
	LootLibraryDifficulty:SetFormattedText(ENCOUNTER_JOURNAL_DIFF_TEXT, entry.size, entry.prefix)
end

function Browse:SetSelectedTier(tierID)
	if not self:IsTierDataLoaded(tierID) then
		self:LoadTierLoot(tierID)
	end
	if self:GetFilter("class") or self:GetFilter("spec") then
		self:LoadSpecData(tierID)
	end
	
	local tier = data.tiers[tierID]
	tierButton:SetText(tier.name)
	tierButton.id = tierID
	tierButton.list = tier
	tierButton:Show()
end

function Browse:SetSelectedInstance(instanceID)
	local instance = data.instances[instanceID]
	instanceButton:SetText(instance.name)
	instanceButton.id = instanceID
	instanceButton.list = instance
	instanceButton:Show()
	
	self:SetNavigationList(instance)
	
	self:SetList(instance.loot)
	self:ClearFilter("source")
	self:ApplyFilters()
	
	self:SetScrollFrameHeaderText(instance.name)
	self.scrollFrame.headers[1]:Show()
end

function Browse:GetSelectedTier()
	return tierButton.id
end

function Browse:SelectInstance(instanceID)
	for tierID, tier in ipairs(data.tiers) do
		for i, instance in ipairs(tier) do
			if instance == instanceID then
				self:SetSelectedTier(tierID)
				self:SetSelectedInstance(instance)
				return
			end
		end
	end
end

function Browse:GetNumTiers()
	return #home
end

function Browse:GetNumInstances(tier)
	return #data.tiers[tier]
end

function Browse:GetNumEncounters(instanceID)
	local instance = data.instances[instanceID]
	return instance and #instance
end

function Browse:GetNumItems(instanceID)
	local instance = data.instances[instanceID]
	return instance and #instance.loot
end

local addedItems = {}

local function getQuality(item)
	for k, v in pairs(ITEM_QUALITY_COLORS) do
		if item:match("^"..v.hex) then
			return k
		end
	end
end

function Browse:LoadTierLoot(index)
	local t = debugprofilestop()

	local classFilter, specFilter = EJ_GetLootFilter()
	for i, instanceID in ipairs(data.tiers[index]) do
		local instance = data.instances[instanceID]
		wipe(instance.loot)
		wipe(addedItems)
		EJ_SelectInstance(instanceID)
		
		for i, v in ipairs(Browse:GetDifficulties(instance.isRaid)) do
			if EJ_IsValidInstanceDifficulty(v.difficultyID) then
				EJ_SetDifficulty(v.enumValue)
				local encounterIndex = 1
				while true do
					local name, _, encounterID = EJ_GetEncounterInfoByIndex(encounterIndex)
					if not encounterID then
						break
					end
					local encounter = data.encounters[encounterID]
					if not encounter then
						tinsert(instance, encounterIndex, encounterID)
						encounter = {
							name = name,
							difficulty = 0,
						}
					end
					encounterIndex = encounterIndex + 1
					encounter.difficulty = bit.bor(encounter.difficulty, 2 ^ v.difficultyID)
					data.encounters[encounterID] = encounter
				end
				
				EJ_SetLootFilter(0, 0)
				local numLoot = EJ_GetNumLoot()
				if numLoot > 0 then
					instance.difficulty = bit.bor(instance.difficulty, 2 ^ v.difficultyID)
				end
				for i = 1, numLoot do
					local name, icon, slot, armorType, itemID, link, encounterID = EJ_GetLootInfoByIndex(i)
					local item = addon:GetItem(itemID)
					if not item then
						local quality = getQuality(name)
						item = {
							name = strmatch(name, "|cff%x%x%x%x%x%x(.+)|r"),
							icon = icon,
							quality = quality,
							slot = slot ~= "" and slot or nil,
							armorType = armorType ~= "" and armorType or nil,
							source = {},
							class = 0,
							spec = 0,
							sourceDifficulty = 0,
						}
						addon:AddItem(itemID, item)
					end
					item.source[encounterID] = true
					-- if this item has already been added for the current difficulty, don't add it again, otherwise we'd get duplicates from 10 and 25 man
					if not addedItems[itemID] then
						tinsert(instance.loot, itemID)
						addedItems[itemID] = true
					end
					item.sourceDifficulty = bit.bor(item.sourceDifficulty, 2 ^ v.difficultyID)
				end
			end
		end
	end
	EJ_SetLootFilter(classFilter, specFilter)
	data.tiers[index].standby = nil
	print("LoadTierLoot", index, debugprofilestop() - t)
end

function Browse:LoadAllTierLoot()
	for i = 1, self:GetNumTiers() do
		if not self:IsTierDataLoaded(i) then
			self:LoadTierLoot(i)
		end
	end
end

function Browse:IsTierDataLoaded(index)
	return not data.tiers[index].standby
end

function Browse:LoadSpecData(index)
	local t = debugprofilestop()
	if not index then
		for i, v in ipairs(data.tiers) do
			self:LoadSpecData(i)
		end
		return
	end
	if data.tiers[index].spec then
		return
	end
	
	local classFilter, specFilter = EJ_GetLootFilter()
	
	for i, instanceID in ipairs(data.tiers[index]) do
		local instance = data.instances[instanceID]
		EJ_SelectInstance(instanceID)
		
		for i, v in ipairs(self:GetDifficulties(instance.isRaid)) do
			if bit.band(instance.difficulty, 2 ^ v.difficultyID) then
				EJ_SetDifficulty(v.enumValue)
		
				for classID = 1, GetNumClasses() do
					for i = 1, GetNumSpecializationsForClassID(classID) do
						local specID = GetSpecializationInfoForClassID(classID, i)
						EJ_SetLootFilter(classID, specID)
						for i = 1, EJ_GetNumLoot() do
							local name, icon, slot, armorType, itemID = EJ_GetLootInfoByIndex(i)
							local item = addon:GetItem(itemID)
							if not item then print(itemID, name) end
							item.class = bit.bor(item.class, 2 ^ classID)
							item.spec = bit.bor(item.spec, 2 ^ specs[specID])
						end
					end
				end
			end
		end
	end
	EJ_SetLootFilter(classFilter, specFilter)
	
	data.tiers[index].spec = true
	
	print("LoadSpecData", index, debugprofilestop() - t)
end

function Browse:RefreshLoot()
	p = nil
	local s, d = debugprofilestop()
	for i = 1, self:GetNumTiers() do
		if self:IsTierDataLoaded(i) then
			self:LoadTierLoot(i)
			d = true
			-- v.spec = nil
		end
	end
	self:UpdateList()
	self:RemoveOnUpdate()
	print("OnUpdate", #addon:GetAllItems())
	if d then print("RefreshLoot", debugprofilestop() - s) end
end