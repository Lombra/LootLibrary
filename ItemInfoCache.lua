if ItemInfoCache then return end

local LBI = LibStub("LibBabble-Inventory-3.0"):GetUnstrictLookupTable()

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

local invTypeExceptions = {
	INVTYPE_ROBE = "INVTYPE_CHEST",
	INVTYPE_RANGEDRIGHT = "INVTYPE_RANGED",
}

local noType = {
	[LBI["Junk"]] = true,
}

local IIC = {}
ItemInfoCache = IIC

local callbacks = LibStub("CallbackHandler-1.0"):New(IIC)

local items = {}
local queued = {}

IIC.items = items

local function onEvent(self, event)
end

local function onUpdate(self)
	for itemID in pairs(queued) do
		if items[itemID] then
			-- callbacks:Fire("GetItemInfoReceived", itemID)
			queued[itemID] = nil
		end
	end
	callbacks:Fire("GetItemInfoReceivedAll")
	if not next(queued) then
		self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		self:Hide()
	end
end

local frame = CreateFrame("Frame")
-- frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:SetScript("OnEvent", frame.Show)
frame:SetScript("OnUpdate", onUpdate)
frame:Hide()

setmetatable(items, {
	__index = function(self, itemID)
		-- local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice
		local name, _, quality, itemLevel, requiredLevel, class, subclass, _, equipSlot = GetItemInfo(itemID)
		if not name then
			queued[itemID] = true
			frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
			return
		end
		local item = {
			name = name,
			quality = quality,
			slot = _G[equipSlot] and (invTypeExceptions[equipSlot] or equipSlot),
			type = not (noArmor[equipSlot] or noType[subclass]) and (weaponTypes[subclass] or subclass),
			itemLevel = itemLevel,
			reqLevel = requiredLevel,
		}
		self[itemID] = item
		return item
	end,
})

-- function addon:GetAllItems()
	-- return itemArray
-- end