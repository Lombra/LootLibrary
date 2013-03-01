local addonName, addon = ...

local Prototype = addon.prototype

local filterTemplates = {
	stringContains = function(value, arg)
		return strfind(strlower(value), arg, nil, true) ~= nil
	end,
	tableContains = function(value, arg)
		return value[arg]
	end,
	bitflagsContain = function(value, arg)
		return bit.band(value, 2 ^ arg) > 0
	end,
	equals = function(value, arg)
		return value == arg
	end,
	lessorequal = function(value, arg)
		return value <= arg
	end,
	greaterorequal = function(value, arg)
		return value >= arg
	end,
}

-- the logic used by each filter
local filters = {
	name = filterTemplates.stringContains,
	minReqLevel = filterTemplates.greaterorequal,
	maxReqLevel = filterTemplates.lessorequal,
	minItemLevel = filterTemplates.greaterorequal,
	maxItemLevel = filterTemplates.lessorequal,
	slot = filterTemplates.equals,
	type = filterTemplates.equals,
	class = filterTemplates.bitflagsContain,
	spec = filterTemplates.bitflagsContain,
	source = filterTemplates.tableContains,
	sourceDifficulty = filterTemplates.bitflagsContain,
	stats = function(value, filterArg)
	end,
}

-- exceptions for filters whose names does not match an existing item field
local exceptions = {
	minReqLevel = "reqLevel",
	maxReqLevel = "reqLevel",
	minItemLevel = "itemLevel",
	maxItemLevel = "itemLevel",
}

local function getItemInfo(itemID, filterName)
	local name, _, quality, iLevel, reqLevel, class, subclass, _, equipSlot = GetItemInfo(itemID)
	local item = addon:GetItem(itemID)
	item.itemLevel = iLevel
	item.reqLevel = reqLevel
	return item[filterName]
end

local filterLoaders = {
	itemLevel = getItemInfo,
	reqLevel = getItemInfo,
}

local function FilterApproves(itemID)
	local item = addon:GetItem(itemID)
	for filterName, filterArg in pairs(addon:GetSelectedTab().filterArgs) do
		local value = item[exceptions[filterName] or filterName] or (filterLoaders[exceptions[filterName] or filterName] and filterLoaders[exceptions[filterName] or filterName](itemID, filterName))
		if not (value ~= nil and filters[filterName](value, filterArg)) then
			return false
		end
	end
	return true
end

local filteredList = {}

function Prototype:ApplyFilters()
	wipe(filteredList)
	for i, v in ipairs(self:GetList(true)) do
		if FilterApproves(v) then
			tinsert(filteredList, v)
		end
	end
	self:SetFilteredList(filteredList)
end

function Prototype:SetFilter(filter, arg)
	self.filterArgs[filter] = arg
end

function Prototype:GetFilter(filter)
	return self.filterArgs[filter]
end

function Prototype:ClearFilter(filter)
	self.filterArgs[filter] = nil
end

function Prototype:SetFilteredList(list)
	self.filteredList = list
	self:UpdateList()
end

function Prototype:ClearFilters()
	wipe(self.filterArgs)
	self.filteredList = nil
	-- self:UpdateList()
end

local specs = {}

local n = 1
for i = 1, GetNumClasses() do
	local classDisplayName, classTag, classID = GetClassInfo(i)
	for i = 1, GetNumSpecializationsForClassID(classID) do
		specs[GetSpecializationInfoForClassID(classID, i)] = n
		n = n + 1
	end
end

local function setGearFilter(self, classID, specID)
	addon:GetModule("Browse"):LoadAllTierLoot()
	if self.owner.onClick then
		self.owner:onClick()
	end
	CloseDropDownMenus(1)
	local module = self.owner.module
	module:SetFilter("class", classID)
	module:SetFilter("spec", specs[specID])
	module:ApplyFilters()
end

local CLASS_DROPDOWN = 1

addon.InitializeGearFilter = function(self, level)
	local filterClassID = self.module:GetFilter("class") or 0
	local filterSpecID = self.module:GetFilter("spec") or 0
	local classDisplayName, classTag, classID
	local info = UIDropDownMenu_CreateInfo()
	info.owner = self

	if (UIDROPDOWNMENU_MENU_VALUE == CLASS_DROPDOWN) then 
		info.text = ALL_CLASSES
		info.checked = (filterClassID == 0)
		info.arg1 = nil
		info.arg2 = nil
		info.func = setGearFilter
		UIDropDownMenu_AddButton(info, level)

		local numClasses = GetNumClasses()
		for i = 1, numClasses do
			classDisplayName, classTag, classID = GetClassInfo(i)
			info.text = classDisplayName
			info.checked = (filterClassID == classID)
			info.func = setGearFilter
			info.arg1 = classID
			info.arg2 = nil
			UIDropDownMenu_AddButton(info, level)
		end
	end

	if (level == 1) then 
		info.text = CLASS
		info.func =  nil
		info.notCheckable = true
		info.hasArrow = true
		info.value = CLASS_DROPDOWN
		UIDropDownMenu_AddButton(info, level)
		
		if filterClassID > 0 then
			classDisplayName, classTag, classID = GetClassInfoByID(filterClassID)
		else
			classDisplayName, classTag, classID = UnitClass("player")
		end
		info.text = classDisplayName
		info.notCheckable = true
		info.arg1 = nil
		info.arg2 = nil
		info.func =  nil
		info.hasArrow = false
		UIDropDownMenu_AddButton(info, level)
		
		info.notCheckable = nil
		local numSpecs = GetNumSpecializationsForClassID(classID)
		for i = 1, numSpecs do
			local specID, specName = GetSpecializationInfoForClassID(classID, i)
			info.leftPadding = 10
			info.text = specName
			info.checked = (filterSpecID == specID)
			info.arg1 = classID
			info.arg2 = specID
			info.func = setGearFilter
			UIDropDownMenu_AddButton(info, level)
		end

		info.text = ALL_SPECS
		info.leftPadding = 10
		info.checked = (classID == filterClassID) and (filterSpecID == 0)
		info.arg1 = classID
		info.arg2 = nil
		info.func = setGearFilter
		UIDropDownMenu_AddButton(info, level)
	end
end
