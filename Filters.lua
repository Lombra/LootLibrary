local addonName, addon = ...

local items = addon.items

local filters = {
	name = function(value, filterArg)
		return strfind(strlower(strmatch(value, "|cff%x%x%x%x%x%x(.+)|r")), filterArg, nil, true)
	end,
	minReqLevel = function(value, filterArg)
		return value >= filterArg
	end,
	maxReqLevel = function(value, filterArg)
		return value <= filterArg
	end,
	minItemLevel = function(value, filterArg)
		return value >= filterArg
	end,
	maxItemLevel = function(value, filterArg)
		return value <= filterArg
	end,
	slot = function(value, filterArg)
		return strfind(value, filterArg)
	end,
	armorType = function(value, filterArg)
		return strfind(value, filterArg)
	end,
	class = function(value, filterArg)
		return bit.band(value, 2 ^ filterArg) > 0
	end,
	spec = function(value, filterArg)
		return bit.band(value, 2 ^ filterArg) > 0
	end,
	source = function(value, filterArg)
		return value[filterArg]
	end,
	sourceDifficulty = function(value, filterArg)
		return bit.band(value, 2 ^ filterArg) > 0
	end,
}

local exceptions = {
	minReqLevel = "reqLevel",
	maxReqLevel = "reqLevel",
	minItemLevel = "itemLevel",
	maxItemLevel = "itemLevel",
}

local filterArgs = {
}

local function FilterApproves(item)
	item = items[item]
	for filterName, filterArg in pairs(addon:GetSelectedTab().filterArgs) do
		local value = item[exceptions[filterName] or filterName]
		if not (value ~= nil and filters[filterName](value, filterArg)) then
			return false
		end
	end
	return true
end

local Prototype = addon.prototype

local filteredList = {}

function Prototype:ApplyFilters()
	wipe(filteredList)
	for i, v in ipairs(addon:GetList(true)) do
		if FilterApproves(v) then
			tinsert(filteredList, v)
		end
	end
	addon:SetFilteredList(filteredList)
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