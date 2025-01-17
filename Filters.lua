local addonName, addon = ...

local ItemInfo = LibStub("LibItemInfo-1.0")

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
	invType = filterTemplates.equals,
	subType = filterTemplates.equals,
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

local function filterApproves(itemID, filterArgs, module)
	local item = ItemInfo[itemID]
	local info = addon:GetItem(itemID)
	if not item then
		module.doUpdateList = true
		return
	end
	for filterName, filterArg in pairs(filterArgs) do
		local propertyName = exceptions[filterName] or filterName
		local value = item[propertyName] or info[propertyName]
		if not (value ~= nil and filters[filterName](value, filterArg)) then
			return false
		end
	end
	return true
end

local filteredList = {}

function Prototype:ApplyFilters()
	wipe(filteredList)
	local filterArgs = self.filterArgs
	for i, v in ipairs(self:GetList(true)) do
		if filterApproves(v, filterArgs, self) then
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

local sex = UnitSex("player")

local specs = {}

local n = 1
for i = 1, GetNumClasses() do
	local classDisplayName, classTag, classID = GetClassInfo(i)
	for i = 1, GetNumSpecializationsForClassID(classID) do
		specs[GetSpecializationInfoForClassID(classID, i, sex)] = n
		n = n + 1
	end
end

local function setGearFilter(self, classID, specID)
	-- addon:GetModule("Browse"):LoadAllTierLoot()
	CloseDropDownMenus(1)
	local module = self.owner.module
	module:SetFilter("class", classID)
	module:SetFilter("spec", specID or specs[specID])
	-- module:ApplyFilters()
	if self.owner.onClick then
		self.owner:onClick()
	end
end

local CLASS_DROPDOWN = 1

addon.InitializeGearFilter = function(self, level)
	local filterClassID = self.module:GetFilter("class") or 0
	local filterSpecID = self.module:GetFilter("spec") or 0
	local classDisplayName, classTag, classID
	local info = UIDropDownMenu_CreateInfo()

	if (UIDROPDOWNMENU_MENU_VALUE == CLASS_DROPDOWN) then 
		info.text = ALL_CLASSES
		info.checked = (filterClassID == 0)
		info.arg1 = nil
		info.arg2 = nil
		info.func = setGearFilter
		self:AddButton(info, level)

		local numClasses = GetNumClasses()
		for i = 1, numClasses do
			classDisplayName, classTag, classID = GetClassInfo(i)
			info.text = classDisplayName
			info.checked = (filterClassID == classID)
			info.func = setGearFilter
			info.arg1 = classID
			info.arg2 = nil
			self:AddButton(info, level)
		end
	end

	if (level == 1) then 
		info.text = CLASS
		info.func =  nil
		info.notCheckable = true
		info.hasArrow = true
		info.value = CLASS_DROPDOWN
		self:AddButton(info, level)
		
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
		self:AddButton(info, level)
		
		info.notCheckable = nil
		local numSpecs = GetNumSpecializationsForClassID(classID)
		for i = 1, numSpecs do
			local specID, specName = GetSpecializationInfoForClassID(classID, i, sex)
			info.leftPadding = 10
			info.text = specName
			info.checked = (filterSpecID == specID)
			info.arg1 = classID
			info.arg2 = specID
			info.func = setGearFilter
			self:AddButton(info, level)
		end

		info.text = ALL_SPECS
		info.leftPadding = 10
		info.checked = (classID == filterClassID) and (filterSpecID == 0)
		info.arg1 = classID
		info.arg2 = nil
		info.func = setGearFilter
		self:AddButton(info, level)
	end
end
