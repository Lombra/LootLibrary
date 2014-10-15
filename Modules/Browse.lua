local addonName, addon = ...

local Browse = addon:NewModule("Browse", addon:CreateUI("Browse"))

local scrollFrame = Browse:CreateScrollFrame()
scrollFrame:AddHeader():Hide()
scrollFrame:UpdateHeight()
scrollFrame.PostUpdateButton = function(button, item)
	button.favorite:SetShown(addon:GetModule("Favorites"):HasItem(item))
end

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

local filterMenu = addon:CreateDropdown("Menu")
filterMenu.initialize = addon.InitializeGearFilter
filterMenu.module = Browse
filterMenu.onClick = function(self, classID, specID)
	-- Browse:LoadSpecData(Browse:GetNavigationList() ~= home and Browse:GetSelectedTier())
	Browse:UpdateLoot()
	Browse:ApplyFilters()
end

local filterButton = addon:CreateButton(Browse)
filterButton:SetWidth(96)
filterButton:SetPoint("TOPLEFT", 16, -32)
filterButton:SetText(GEAR_FILTER)
filterButton.arrow:Show()
filterButton:SetScript("OnClick", function(self)
	filterMenu:Toggle()
	PlaySound("igMainMenuOptionCheckBoxOn")
end)
filterMenu.relativeTo = filterButton

-- DIFFICULTY_DUNGEON_NORMAL = 1;
-- DIFFICULTY_DUNGEON_HEROIC = 2;
-- DIFFICULTY_RAID10_NORMAL = 3;
-- DIFFICULTY_RAID25_NORMAL = 4;
-- DIFFICULTY_RAID10_HEROIC = 5;
-- DIFFICULTY_RAID25_HEROIC = 6;
-- DIFFICULTY_RAID_LFR = 7;
-- DIFFICULTY_RAID40 = 9;

local DIFFICULTIES = {
	{
		size = 5,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 1,
	},
	{
		size = 5,
		prefix = PLAYER_DIFFICULTY2,
		difficultyID = 2,
	},
	{
		size = 25,
		prefix = PLAYER_DIFFICULTY3,
		difficultyID = 7,
	},
	{
		size = 10,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 3,
	},
	{
		size = 10,
		prefix = PLAYER_DIFFICULTY2,
		difficultyID = 5,
	},
	{
		size = 25,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 4,
	},
	{
		size = 25,
		prefix = PLAYER_DIFFICULTY2,
		difficultyID = 6,
	},
	{
		size = 40,
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 9,
	},
	{
		prefix = PLAYER_DIFFICULTY3,
		difficultyID = 17,
	},
	{
		prefix = PLAYER_DIFFICULTY1,
		difficultyID = 14,
	},
	{
		prefix = PLAYER_DIFFICULTY2,
		difficultyID = 15,
	},
	{
		prefix = PLAYER_DIFFICULTY6,
		difficultyID = 16,
	},
}

local difficultyInfo = {}

for i, v in ipairs(DIFFICULTIES) do
	difficultyInfo[v.difficultyID] = v
end

local function selectDifficulty(self, value)
	Browse:SetDifficulty(value)
	Browse:UpdateLoot()
	Browse:ApplyFilters()
end

local difficultyMenu = addon:CreateDropdown("Menu")
difficultyMenu.initialize = function(self, level)
	local currDifficulty = Browse:GetFilter("sourceDifficulty")
	local currentList = Browse:GetNavigationList()
	
	local filter = currentList.difficulty
	local selectedEncounter = Browse:GetFilter("source")
	if selectedEncounter then
		filter = data.encounters[selectedEncounter].difficulty
	end
	
	for i, entry in ipairs(Browse:GetDifficulties()) do
		if not filter or bit.band(filter, 2 ^ entry.difficultyID) ~= 0 then
			local info = UIDropDownMenu_CreateInfo()
			info.text = entry.size and format(ENCOUNTER_JOURNAL_DIFF_TEXT, entry.size, entry.prefix) or entry.prefix
			info.func = selectDifficulty
			info.arg1 = entry.difficultyID
			info.checked = currDifficulty == entry.difficultyID
			info.disabled = filter and bit.band(filter, 2 ^ entry.difficultyID) == 0
			self:AddButton(info)
		end
	end
end

local difficultyButton = addon:CreateButton(Browse)
difficultyButton:SetWidth(120)
difficultyButton:SetPoint("LEFT", filterButton, "RIGHT", 16, 0)
difficultyButton:SetText("(10) Normal")
difficultyButton.arrow:Show()
difficultyButton:SetScript("OnClick", function(self)
	difficultyMenu:Toggle()
	PlaySound("igMainMenuOptionCheckBoxOn")
end)
difficultyMenu.relativeTo = difficultyButton

local searchBox = Browse:CreateSearchBox()
searchBox:SetPoint("TOPRIGHT", -16, -33)
searchBox:SetSize(128, 20)
searchBox.clearFunc = function()
	Browse:ClearFilter("name")
	Browse:ApplyFilters()
end
searchBox:SetScript("OnTextChanged", function(self, isUserInput)
	if not isUserInput then
		return
	end
	local text = self:GetText():lower()
	-- local search = {}
	-- for _, tier in ipairs(Browse:GetList(true)) do
		-- for _, instance in ipairs(tier.data) do
			-- if (self:GetText():trim() == "" or strfind(instance.name:lower(), text)) and not instance.special then
				-- tinsert(search, instance)
			-- end
			-- for _, boss in ipairs(instance.data) do
				-- if (self:GetText():trim() == "" or strfind(boss.name:lower(), text)) and not boss.special then
					-- tinsert(search, boss)
				-- end
			-- end
		-- end
	-- end
	-- for itemID, data in pairs(items) do
		-- if self:GetText():trim() == "" or strfind(data.name:lower(), text) then
			-- tinsert(search, itemID)
		-- end
	-- end
	-- Browse:SetNavigationList(search)
	if text:trim() ~= "" then
		Browse:SetFilter("name", text)
	else
		Browse:ClearFilter("name")
	end
	Browse:ApplyFilters()
end)

local tierButton
local instanceButton

do
	local highlight
	
	local function onClick(self, button)
		Browse:OnClick(self, button)
	end
	
	local scrollFrame = Browse:CreateNavigationFrame()
	scrollFrame.dynamicHeaders = true
	scrollFrame.updateButton = function(button, object, list)
		local item = data[list.type][object]
		button:SetText(item.name)
		if item.isRaid then
			button.label:SetTextColor(1, 1, 0.6)
		else
			button.label:SetTextColor(1, 1, 1)
		end
		button.type = item.type
		button.list = item
		button.index = index
		button.id = object
	end
	scrollFrame.onClick = onClick
	
	scrollFrame:SetScript("OnMouseUp", function(self, button)
		if button == "RightButton" then
			Browse:OnClick(scrollFrame.headers[max(scrollFrame:GetNumVisibleHeaders() - 1, 1)])
		end
	end)
	
	function Browse:OnClick(object, button)
		if button == "RightButton" then
			self:OnClick(scrollFrame.headers[max(scrollFrame:GetNumVisibleHeaders() - 1, 1)])
			return
		end
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
			self.selectedTier = nil
			self.selectedInstance = nil
		elseif object.type == "instances" then
			instanceButton:Hide()
			self:SetSelectedTier(object.id)
			self:SetList(nil)
			self:SetNavigationList(object.list)
			self.selectedInstance = nil
		elseif object.type == "encounters" then
			if not self:IsValidDifficulty("instances", object.id) then
				self:SelectValidDifficulty("instances", object.id)
			end
			self:SetSelectedInstance(object.id)
			self:UpdateLoot()
		else
			highlight = object
			object:LockHighlight()
			if not self:IsValidDifficulty("encounters", object.id) then
				self:SelectValidDifficulty("encounters", object.id)
			end
			self.scrollFrame.headers[1]:SetText(object.list.name)
			self.scrollFrame.headers[1]:Show()
			self:SetFilter("source", object.id)
			self:UpdateLoot()
			self:ApplyFilters()
		end
	end
	
	local homeButton = scrollFrame:AddHeader()
	homeButton.type = "tiers"
	homeButton.list = home
	homeButton:SetText(HOME)
	homeButton:SetScript("OnClick", onClick)
	
	tierButton = scrollFrame:AddHeader()
	tierButton.type = "instances"
	tierButton.label:SetPoint("LEFT", 15, 0)
	tierButton:SetScript("OnClick", onClick)
	tierButton:Hide()
	
	instanceButton = scrollFrame:AddHeader()
	instanceButton.type = "encounters"
	instanceButton.label:SetPoint("LEFT", 19, 0)
	instanceButton:SetScript("OnClick", onClick)
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
		local instanceID, name, _, _, buttonImage, _, mapID, link = EJ_GetInstanceByIndex(n, isRaid)
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
			journal = true,
		}
	end
end

local function refreshLoot(self)
	self:SetOnUpdate(self.RefreshLoot)
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
		addInstances(tier, true)
		addInstances(tier, false)
	end
	
	self:SetNavigationList(home)
	self:SetList(nil)
end

local lastInstance
local lastDifficulty

function Browse:OnShow()
	if not self.db.profile.autoSelectInstance then return end
	
	-- navigate to current instance
	local mapID
	local instanceID = EJ_GetCurrentInstance()
	-- if instanceID > 0 then
		-- mapID = select(6, EJ_GetInstanceInfo(instanceID))
	-- else
		-- local currentMap = GetCurrentMapAreaID()
		-- SetMapToCurrentZone()
		-- mapID = GetCurrentMapAreaID()
		-- SetMapByID(currentMap)
	-- end
	local name, _, difficultyID = GetInstanceInfo()
	if instanceID == 0 and data.instances[name] then
		instanceID = name
	end
	if instanceID ~= 0 and (instanceID ~= lastInstance) then--or difficultyID ~= lastDifficulty) then
		lastInstance = instanceID
		lastDifficulty = difficultyID
		self:SetDifficulty(max(difficultyID, 1))
		self:SelectInstance(instanceID)
		self:UpdateLoot()
	end
end

local addedItems = {}

function Browse:UpdateLoot()
	if not self:GetSelectedInstance() then
		return
	end
	
	if self:IsJournal() then
		EJ_SelectInstance(self:GetSelectedInstance())
		local difficultyID = self:GetFilter("sourceDifficulty")
		EJ_SetDifficulty(difficultyID)
		local source = self:GetFilter("source")
		if source then
			EJ_SelectEncounter(source)
		end
		local loot = {}
		wipe(addedItems)
		local classFilter, specFilter = EJ_GetLootFilter()
		EJ_SetLootFilter(self:GetFilter("class") or 0, self:GetFilter("spec") or 0)
		for i = 1, EJ_GetNumLoot() do
			local name, icon, slot, armorType, itemID, link, encounterID = EJ_GetLootInfoByIndex(i)
			local item = addon:GetItem(link)
			if not item then
				item = {
					source = {},
					sourceDifficulty = 0,
					class = 0,
					spec = 0,
				}
				addon:AddItem(link, item, true)
			end
			item.source[encounterID] = true
			item.sourceDifficulty = bit.bor(item.sourceDifficulty, 2 ^ difficultyID)
			item.class = bit.bor(item.class, 2 ^ (self:GetFilter("class") or 0))
			item.spec = bit.bor(item.spec, 2 ^ (specs[self:GetFilter("spec")] or 0))
			-- if this item has already been added for the current instance, don't add it again, otherwise we'd get duplicates from 10 and 25 man
			if not addedItems[link] then
				tinsert(loot, link)
				addedItems[link] = true
			end
		end
		EJ_SetLootFilter(classFilter, specFilter)
		self:SetList(loot)
	else
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
	return DIFFICULTIES--isRaid and RAID_DIFFICULTIES or DUNGEON_DIFFICULTIES
end

function Browse:SetDifficulty(difficultyID)
	self:SetFilter("sourceDifficulty", difficultyID)
	-- self:ApplyFilters()
	local entry = difficultyInfo[difficultyID]
	difficultyButton:SetFormattedText(entry.size and ENCOUNTER_JOURNAL_DIFF_TEXT or entry.prefix, entry.size, entry.prefix)
end

function Browse:SetSelectedTier(tierID)
	if not self:IsTierDataLoaded(tierID) then
		self:LoadTierLoot(tierID)
	end
	if self:GetFilter("class") or self:GetFilter("spec") then
		-- self:LoadSpecData(tierID)
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
	
	self.selectedInstance = instanceID
	
	self:SetNavigationList(instance)
	
	if instance.journal then
		EJ_SelectInstance(instanceID)
	else
		self:SetList(instance.loot)
	end
	
	self:ClearFilter("source")
	self:ApplyFilters()
	
	self:SetScrollFrameHeaderText(instance.name)
	self.scrollFrame.headers[1]:Show()
end

function Browse:GetSelectedTier()
	return tierButton.id
end

function Browse:GetSelectedInstance()
	return self.selectedInstance
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

function Browse:IsJournal()
	return instanceButton.list.journal
end

function Browse:LoadTierLoot(index)
	local classFilter, specFilter = EJ_GetLootFilter()
	EJ_SetLootFilter(0, 0)
	for i, instanceID in ipairs(data.tiers[index]) do
		local instance = data.instances[instanceID]
		if instance.journal then
			wipe(instance.loot)
			wipe(addedItems)
			EJ_SelectInstance(instanceID)
			
			for i, v in ipairs(self:GetDifficulties(instance.isRaid)) do
				if EJ_IsValidInstanceDifficulty(v.difficultyID) then
					EJ_SetDifficulty(v.difficultyID)
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
					
					local numLoot = EJ_GetNumLoot()
					if numLoot > 0 then
						instance.difficulty = bit.bor(instance.difficulty, 2 ^ v.difficultyID)
					end
				end
			end
		end
	end
	EJ_SetLootFilter(classFilter, specFilter)
	data.tiers[index].standby = nil
end

function Browse:LoadAllTierLoot()
	for i = 1, self:GetNumTiers() do
		if not self:IsTierDataLoaded(i) then
			self:LoadTierLoot(i)
		end
	end
end

local function instanceSort(a, b)
	local instanceA, instanceB = data.instances[a], data.instances[b]
	if instanceA.isRaid == instanceB.isRaid then
		return a < b
	else
		return instanceA.isRaid
	end
end

function Browse:AddInstance(instanceData)
	tinsert(data.tiers[instanceData.expansion], instanceData.name)
	local instance = {
		type = "encounters",
		name = instanceData.name,
		difficulty = 0,
		isRaid = true,
		loot = {},
	}
	data.instances[instanceData.name] = instance
	sort(data.tiers[instanceData.expansion], instanceSort)
	for i, v in ipairs(instanceData.encounters) do
		tinsert(instance, v)
		data.encounters[v] = {
			name = v,
			difficulty = 0,
		}
	end
	wipe(addedItems)
	for boss, bossData in pairs(instanceData.items) do
		for itemID, sourceDifficulty in pairs(bossData) do
			-- tinsert(instance.loot, itemID)
			local item = addon:GetItem(itemID)
			if not item then
				item = {
					source = {},
					sourceDifficulty = 0,
					-- class = 0,
					-- spec = 0,
				}
				addon:AddItem(itemID, item, true)
			end
			-- if this item has already been added for the current instance, don't add it again, otherwise we'd get duplicates from 10 and 25 man
			if not addedItems[itemID] then
				tinsert(instance.loot, itemID)
				addedItems[itemID] = true
			end
			item.sourceDifficulty = bit.bor(item.sourceDifficulty, sourceDifficulty)
			instance.difficulty = bit.bor(instance.difficulty, sourceDifficulty)
			item.source[boss] = true
			local boss = data.encounters[boss]
			boss.difficulty = bit.bor(boss.difficulty, sourceDifficulty)
		end
	end
end

function Browse:IsTierDataLoaded(index)
	return not data.tiers[index].standby
end

function Browse:RefreshLoot()
	for i = 1, self:GetNumTiers() do
		if self:IsTierDataLoaded(i) then
			self:LoadTierLoot(i)
		end
	end
	self:UpdateLoot()
	self:RemoveOnUpdate()
end