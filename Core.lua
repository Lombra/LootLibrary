local addonName, addon = ...

LootLibrary = addon

BINDING_HEADER_LOOT_LIBRARY = "LootLibrary"
BINDING_NAME_LOOT_LIBRARY_TOGGLE = "Toggle LootLibrary"

local itemArray = {}
local items = {}
addon.items = items

local modules = {}

SlashCmdList["LOOT_LIBRARY"] = function(msg)
	ToggleFrame(addon.frame)
end
SLASH_LOOT_LIBRARY1 = "/lootlibrary"
SLASH_LOOT_LIBRARY2 = "/ll"

local events = {}
local onUpdates = {}

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	for module, eventHandler in pairs(events[event]) do
		eventHandler(module, ...)
	end
end)

local function onUpdate(self, elapsed)
	for module, update in pairs(onUpdates) do
		update(module, elapsed)
	end
end

setmetatable(events, {
	__index = function(table, key)
		local newTable = {}
		table[key] = newTable
		return newTable
	end
})

local mixins = {
	RegisterEvent = function(self, event, handler)
		if not next(events[event]) then
			eventFrame:RegisterEvent(event)
		end
		if type(handler) ~= "function" then
			handler = self[handler] or self[event]
		end
		events[event][self] = handler
	end,
	UnregisterEvent = function(self, event)
		events[event][self] = nil
		if not next(events[event]) then
			eventFrame:UnregisterEvent(event)
		end
	end,
	SetOnUpdate = function(self, handler)
		if not next(onUpdates) then
			eventFrame:SetScript("OnUpdate", onUpdate)
		end
		if type(handler) ~= "function" then
			handler = self[handler]
		end
		onUpdates[self] = handler
	end,
	RemoveOnUpdate = function(self)
		onUpdates[self] = nil
		if not next(onUpdates) then
			eventFrame:SetScript("OnUpdate", nil)
		end
	end,
}

for k, v in pairs(mixins) do addon[k] = v end

addon:RegisterEvent("ADDON_LOADED", function(self, addon)
	if addon == addonName then
		self:OnInitialize()
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

local defaults = {
	profile = {
	},
}

function addon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LootLibraryDB", defaults, true)
	for k, module in pairs(modules) do
		if module.OnInitialize then
			module:OnInitialize()
		end
	end
end

function addon:NewModule(name, table)
	if modules[name] then
		error("Module '"..name.."' already exists.", 2)
	end
	
	local module = table or {}
	for k, v in pairs(mixins) do module[k] = v end
	modules[name] = module
	return module
end

function addon:GetModule(name)
	return modules[name]
end

function addon:IterateModules()
	return pairs(modules)
end

function addon:AddItem(itemID, data)
	items[itemID] = data
	tinsert(itemArray, itemID)
end

function addon:GetItem(itemID)
	return items[itemID]
end

function addon:GetAllItems()
	return itemArray
end

function addon:HasItem(itemID)
	return GetItemCount(itemID, true) > 0
end