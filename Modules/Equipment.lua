local addonName, ns = ...

-- Mapping of inventory slots to transmog navigation icons for empty slots
local TRANSMOG_ICONS = {
    HeadSlot = "transmog-nav-slot-head",
    NeckSlot = nil, -- No transmog icon for neck
    ShoulderSlot = "transmog-nav-slot-shoulder",
    ChestSlot = "transmog-nav-slot-chest",
    BackSlot = "transmog-nav-slot-back",
    ShirtSlot = "transmog-nav-slot-shirt",
    TabardSlot = "transmog-nav-slot-tabard",
    WristSlot = "transmog-nav-slot-wrist",
    HandsSlot = "transmog-nav-slot-hands",
    WaistSlot = "transmog-nav-slot-waist",
    LegsSlot = "transmog-nav-slot-legs",
    FeetSlot = "transmog-nav-slot-feet",
    MainHandSlot = "transmog-nav-slot-mainhand",
    SecondaryHandSlot = "transmog-nav-slot-secondaryhand",
}

-- Mapping of item quality to rarity border atlas
local RARITY_BORDERS = {
    [0] = "wowlabs-in-world-item-common",    -- Poor
    [1] = "wowlabs-in-world-item-common",    -- Common
    [2] = "wowlabs-in-world-item-uncommon",  -- Uncommon
    [3] = "wowlabs-in-world-item-rare",      -- Rare
    [4] = "wowlabs-in-world-item-epic",      -- Epic
    [5] = "wowlabs-in-world-item-legendary", -- Legendary
    [6] = "wowlabs-in-world-item-legendary", -- Artifact
    [7] = "wowlabs-in-world-item-legendary", -- Heirloom
    [8] = "wowlabs-in-world-item-epic",      -- WoW Token
}

-- Mapping of inventory tokens to display names for tooltips
local SLOT_DISPLAY_NAMES = {
    HeadSlot = "Head",
    NeckSlot = "Neck",
    ShoulderSlot = "Shoulder",
    ChestSlot = "Chest",
    BackSlot = "Back",
    ShirtSlot = "Shirt",
    TabardSlot = "Tabard",
    WristSlot = "Wrist",
    HandsSlot = "Hands",
    WaistSlot = "Waist",
    LegsSlot = "Legs",
    FeetSlot = "Feet",
    Finger0Slot = "Ring",
    Finger1Slot = "Ring",
    Trinket0Slot = "Trinket",
    Trinket1Slot = "Trinket",
    MainHandSlot = "Main Hand",
    SecondaryHandSlot = "Off Hand",
}

-- Equipment slot configuration: which frame maps to which inventory slot
EQUIPMENT_SLOTS = {
    -- Left side: core armor + back/shirt/tabard/wrist
    { frameName = "CharacterWindowFrameLeftSlot1",          invToken = "HeadSlot" },
    { frameName = "CharacterWindowFrameLeftSlot2",          invToken = "NeckSlot" },
    { frameName = "CharacterWindowFrameLeftSlot3",          invToken = "ShoulderSlot" },
    { frameName = "CharacterWindowFrameLeftSlot4",          invToken = "ChestSlot" },
    { frameName = "CharacterWindowFrameLeftSlot5",          invToken = "BackSlot" },
    { frameName = "CharacterWindowFrameLeftSlot6",          invToken = "ShirtSlot" },
    { frameName = "CharacterWindowFrameLeftSlot7",          invToken = "TabardSlot" },
    { frameName = "CharacterWindowFrameLeftSlot8",          invToken = "WristSlot" },

    -- Right side: hands/waist/legs/feet + rings + trinkets
    { frameName = "CharacterWindowFrameRightSlot1",         invToken = "HandsSlot" },
    { frameName = "CharacterWindowFrameRightSlot2",         invToken = "WaistSlot" },
    { frameName = "CharacterWindowFrameRightSlot3",         invToken = "LegsSlot" },
    { frameName = "CharacterWindowFrameRightSlot4",         invToken = "FeetSlot" },
    { frameName = "CharacterWindowFrameRightSlot5",         invToken = "Finger0Slot" },  -- Ring 1
    { frameName = "CharacterWindowFrameRightSlot6",         invToken = "Finger1Slot" },  -- Ring 2
    { frameName = "CharacterWindowFrameRightSlot7",         invToken = "Trinket0Slot" }, -- Trinket 1
    { frameName = "CharacterWindowFrameRightSlot8",         invToken = "Trinket1Slot" }, -- Trinket 2

    -- Bottom slots: weapons
    { frameName = "CharacterWindowFrameBottomSlotMainHand", invToken = "MainHandSlot" },
    { frameName = "CharacterWindowFrameBottomSlotOffHand",  invToken = "SecondaryHandSlot" },
}

LEFT_SLOT_SUFFIXES = {
    "LeftSlot1",
    "LeftSlot2",
    "LeftSlot3",
    "LeftSlot4",
    "LeftSlot5",
    "LeftSlot6",
    "LeftSlot7",
    "LeftSlot8",
}

RIGHT_SLOT_SUFFIXES = {
    "RightSlot1",
    "RightSlot2",
    "RightSlot3",
    "RightSlot4",
    "RightSlot5",
    "RightSlot6",
    "RightSlot7",
    "RightSlot8",
}

local function CharacterWindow_SetSlotDesaturated(self, desaturated)
    if not self then
        return
    end
    local icon = self.Icon
    if not icon and self.GetName then
        local name = self:GetName()
        if name then
            icon = _G[name .. "Icon"]
        end
    end
    if icon and icon.SetDesaturated then
        icon:SetDesaturated(desaturated and true or false)
    end
end

-- Resize all rarity borders to match their slot sizes
function CharacterWindow_ResizeRarityBorders()
    if not EQUIPMENT_SLOTS then
        return
    end

    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local button = _G[slot.frameName]
        if button then
            local rarityBorder = button.RarityBorder or _G[slot.frameName .. "RarityBorder"]
            if rarityBorder then
                local slotWidth, slotHeight = button:GetSize()
                if slotWidth and slotHeight and slotWidth > 0 and slotHeight > 0 then
                    -- Make border about 20% larger than the slot for better visibility
                    local borderSize = math.max(slotWidth, slotHeight) * 1.28
                    rarityBorder:SetSize(borderSize, borderSize)
                end
            end
        end
    end
end

function CharacterWindow_UpdateEquipmentSlots()
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local button = _G[slot.frameName]
        if button then
            local icon = button.Icon or _G[slot.frameName .. "Icon"]
            local border = button.Border or _G[slot.frameName .. "Border"]
            local rarityBorder = button.RarityBorder or _G[slot.frameName .. "RarityBorder"]
            local gemIndicator = button.GemIndicator or _G[slot.frameName .. "GemIndicator"]
            local enchantIndicator = button.EnchantIndicator or _G[slot.frameName .. "EnchantIndicator"]

            if icon then
                local invSlotId, invSlotName = GetInventorySlotInfo(slot.invToken)
                local texture = GetInventoryItemTexture("player", invSlotId)
                -- Store info on the button so tooltip handlers can use it
                button.invSlotId = invSlotId
                button.invUnit = "player"
                button.invToken = slot.invToken
                -- Use display name mapping if available, otherwise fall back to slot name
                button.invSlotName = SLOT_DISPLAY_NAMES[slot.invToken] or invSlotName
                button.isEmpty = not texture

                -- Always show a full-size icon so empty and filled slots look the same size.
                -- Use the real item icon when present, otherwise use empty slot atlas.
                if not texture then
                    -- Empty slot - show empty slot atlas with common border, hide indicators
                    if icon.SetAtlas then
                        icon:SetAtlas("bags-item-bankslot64", true)
                    else
                        icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
                    end
                    -- Show common rarity border for empty slots
                    if rarityBorder then
                        if rarityBorder.SetAtlas then
                            rarityBorder:SetAtlas("wowlabs-in-world-item-common", true)
                            rarityBorder:Show()
                        end
                    end
                    -- Hide default border when rarity border is shown
                    if border then
                        border:Hide()
                    end
                    -- Hide indicators
                    if gemIndicator then
                        gemIndicator:Hide()
                    end
                    if enchantIndicator then
                        enchantIndicator:Hide()
                    end
                else
                    -- Item is equipped, use normal texture (clear any atlas that might be set)
                    if icon.SetAtlas then
                        icon:SetAtlas(nil)
                    end
                    icon:SetTexture(texture)

                    -- Get item quality and show appropriate rarity border
                    local itemLink = GetInventoryItemLink("player", invSlotId)
                    local quality = 0
                    if itemLink then
                        quality = select(3, GetItemInfo(itemLink)) or 0
                    end

                    local rarityAtlas = RARITY_BORDERS[quality] or RARITY_BORDERS[0]
                    if rarityBorder then
                        if rarityAtlas then
                            if rarityBorder.SetAtlas then
                                rarityBorder:SetAtlas(rarityAtlas, true)
                                rarityBorder:Show()
                            end
                        else
                            rarityBorder:Hide()
                        end
                    end
                    -- Hide default border when rarity border is shown
                    if border then
                        border:Hide()
                    end

                    -- Check for gems first (needed for positioning order)
                    local hasGem = false
                    if itemLink then
                        -- Use C_Item.GetItemGems API (most reliable method)
                        if C_Item and C_Item.GetItemGems then
                            local gems = C_Item.GetItemGems(itemLink)
                            if gems and type(gems) == "table" and #gems > 0 then
                                for _, gem in ipairs(gems) do
                                    -- Gems can be item IDs (numbers) or item links (strings)
                                    -- Only count as gem if it's a valid, non-zero value
                                    if gem ~= nil and gem ~= 0 then
                                        if type(gem) == "number" then
                                            -- Valid gem item IDs must be > 0
                                            if gem > 0 then
                                                hasGem = true
                                                break
                                            end
                                        elseif type(gem) == "string" then
                                            -- Check if it's a valid item link or item ID string
                                            if gem ~= "" and gem ~= "0" then
                                                -- Try to parse as number first
                                                local gemId = tonumber(gem)
                                                if gemId and gemId > 0 then
                                                    hasGem = true
                                                    break
                                                elseif gem:match("item:%d+") then
                                                    -- It's an item link, count as gem
                                                    hasGem = true
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Check for enchant
                    local hasEnchant = false
                    if itemLink and C_Item and C_Item.GetItemEnchantInfo then
                        local enchantId = C_Item.GetItemEnchantInfo(itemLink)
                        if enchantId and enchantId > 0 then
                            hasEnchant = true
                        end
                    end
                    -- Fallback: check item link string for enchant ID
                    if not hasEnchant and itemLink then
                        -- Item links contain enchant ID in format: |cff...|Hitem:itemID:enchantID:...|h
                        local enchantId = itemLink:match("item:%d+:(%d+):")
                        if enchantId and tonumber(enchantId) and tonumber(enchantId) > 0 then
                            hasEnchant = true
                        end
                    end

                    -- Determine indicator positioning:
                    -- Right side slots and weapon slots (main hand and off hand): indicators go left
                    -- Left side slots: indicators go right
                    local isRightSideSlot = slot.frameName:find("RightSlot", 1, true) ~= nil
                    local isMainHand = slot.frameName:find("BottomSlotMainHand", 1, true) ~= nil
                    local isOffHand = slot.frameName:find("BottomSlotOffHand", 1, true) ~= nil
                    local indicatorsGoLeft = isRightSideSlot or isMainHand or isOffHand

                    -- Position gem indicator first (for right-side slots, gem goes leftmost)
                    if gemIndicator then
                        if hasGem then
                            gemIndicator:ClearAllPoints()
                            if indicatorsGoLeft then
                                -- Right side slots and weapon slots: gem goes leftmost (further from slot)
                                gemIndicator:SetPoint("RIGHT", button, "LEFT", -35, 0)
                            else
                                -- Left side slots: gem goes to the right of enchant (away from slot)
                                if hasEnchant and enchantIndicator then
                                    gemIndicator:SetPoint("LEFT", enchantIndicator, "RIGHT", 2, 0)
                                else
                                    -- Position to the right of slot if no enchant
                                    gemIndicator:SetPoint("LEFT", button, "RIGHT", 4, 0)
                                end
                            end
                            if gemIndicator.SetAtlas then
                                gemIndicator:SetAtlas("bags-icon-profession-goods", false)
                                gemIndicator:SetSize(30, 30)
                            end
                            gemIndicator:Show()
                        else
                            gemIndicator:Hide()
                        end
                    end

                    -- Show/hide and position enchant indicator
                    if enchantIndicator then
                        if hasEnchant then
                            enchantIndicator:ClearAllPoints()
                            if indicatorsGoLeft then
                                -- Right side slots and weapon slots: enchant goes to the right of gem (closer to slot)
                                if hasGem and gemIndicator then
                                    enchantIndicator:SetPoint("LEFT", gemIndicator, "RIGHT", 2, 0)
                                else
                                    -- Position to the left of slot if no gem
                                    enchantIndicator:SetPoint("RIGHT", button, "LEFT", -15, 0)
                                end
                            else
                                -- Left side slots: position to the RIGHT of slot (enchant rightmost)
                                enchantIndicator:SetPoint("LEFT", button, "RIGHT", 4, 0)
                            end
                            if enchantIndicator.SetAtlas then
                                enchantIndicator:SetAtlas("bags-icon-questitem", false)
                                enchantIndicator:SetSize(30, 30)
                            end
                            enchantIndicator:Show()
                        else
                            enchantIndicator:Hide()
                        end
                    end
                end
                icon:Show()
            end
        end
    end

    -- Resize all rarity borders to match slot sizes
    CharacterWindow_ResizeRarityBorders()

    -- Ensure the player model reflects any newly equipped/unequipped items
    if CharacterWindow_RefreshModel then
        CharacterWindow_RefreshModel()
    end
end

-- Tooltip handlers for equipment slots (called from XML)
function CharacterWindow_EquipSlot_OnEnter(self)
    if not self or not self.invSlotId then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    -- If slot is empty, show slot name; otherwise show item tooltip
    if self.isEmpty and self.invSlotName then
        GameTooltip:ClearLines()
        GameTooltip:SetText(self.invSlotName)
    else
        local unit = self.invUnit or "player"
        GameTooltip:SetInventoryItem(unit, self.invSlotId)
    end

    GameTooltip:Show()
end

function CharacterWindow_EquipSlot_OnLeave(self)
    GameTooltip:Hide()
end

-- Allow dragging items out of the equipment slots / equipping from the cursor or bags
function CharacterWindow_EquipSlot_OnDragStart(self)
    if not self or not self.invSlotId then
        return
    end
    -- Visually gray out the icon while the user is dragging it
    CharacterWindow_SetSlotDesaturated(self, true)
    -- Pick up the equipped item from this inventory slot
    PickupInventoryItem(self.invSlotId)
end

function CharacterWindow_EquipSlot_OnReceiveDrag(self)
    if not self or not self.invSlotId then
        return
    end
    -- If the cursor has an item (from bags, another slot, etc.), equip it into this slot
    if CursorHasItem() and EquipCursorItem then
        EquipCursorItem(self.invSlotId)
    end
    -- Drag ended on this slot; restore normal icon coloring (UpdateEquipmentSlots will also refresh)
    CharacterWindow_SetSlotDesaturated(self, false)
end

function CharacterWindow_EquipSlot_OnClick(self, button)
    if not self or not self.invSlotId then
        return
    end

    if button == "RightButton" then
        -- Right-click behaves like the default paper doll: pick up the equipped item
        CharacterWindow_SetSlotDesaturated(self, true)
        PickupInventoryItem(self.invSlotId)
        return
    end

    -- Left-click: if we have an item on the cursor, try to equip it, otherwise pick up this slot's item
    if CursorHasItem() and EquipCursorItem then
        EquipCursorItem(self.invSlotId)
    else
        CharacterWindow_SetSlotDesaturated(self, true)
        PickupInventoryItem(self.invSlotId)
    end
end

function CharacterWindow_EquipSlot_OnDragStop(self)
    -- When the drag ends (item placed or cancelled), restore normal icon coloring.
    CharacterWindow_SetSlotDesaturated(self, false)
end

-- Keep equipment slots updated when gear changes while the window is open
local eqFrame = CreateFrame("Frame")
eqFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eqFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eqFrame:RegisterEvent("UNIT_MODEL_CHANGED")
eqFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eqFrame:SetScript("OnEvent", function(_, event, arg1)
    -- Only care about the player unit for UNIT_* events
    if (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED") and arg1 ~= "player" then
        return
    end

    if CharacterWindowFrame and CharacterWindowFrame:IsShown() then
        CharacterWindow_UpdateEquipmentSlots()
        if CharacterWindow_UpdateBackground then
            CharacterWindow_UpdateBackground()
        end
        if CharacterWindow_UpdateStatsPanel then
            CharacterWindow_UpdateStatsPanel()
        end
        if CharacterWindow_RefreshModel then
            CharacterWindow_RefreshModel()
        end
    end
end)
