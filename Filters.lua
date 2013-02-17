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
	armorType = filterTemplates.equals,
	class = filterTemplates.bitflagsContain,
	spec = filterTemplates.bitflagsContain,
	source = filterTemplates.tableContains,
	sourceDifficulty = filterTemplates.bitflagsContain,
}

-- exceptions for filters whose names does not match an existing item field
local exceptions = {
	minReqLevel = "reqLevel",
	maxReqLevel = "reqLevel",
	minItemLevel = "itemLevel",
	maxItemLevel = "itemLevel",
}

local function FilterApproves(item)
	item = addon:GetItem(item)
	for filterName, filterArg in pairs(addon:GetSelectedTab().filterArgs) do
		local value = item[exceptions[filterName] or filterName]
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