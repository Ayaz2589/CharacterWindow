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

function CharacterWindow_UpdateEquipmentSlots()
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local button = _G[slot.frameName]
        if button then
            local icon = button.Icon or _G[slot.frameName .. "Icon"]
            local border = button.Border or _G[slot.frameName .. "Border"]
            local rarityBorder = button.RarityBorder or _G[slot.frameName .. "RarityBorder"]

            if icon then
                local invSlotId = GetInventorySlotInfo(slot.invToken)
                local texture = GetInventoryItemTexture("player", invSlotId)
                -- Store info on the button so tooltip handlers can use it
                button.invSlotId = invSlotId
                button.invUnit = "player"

                -- Always show a full-size icon so empty and filled slots look the same size.
                -- Use the real item icon when present, otherwise use transmog icon or fall back to generic empty-slot texture.
                if not texture then
                    -- Empty slot - show transmog icon or generic empty slot, hide rarity border
                    local transmogAtlas = TRANSMOG_ICONS[slot.invToken]
                    if transmogAtlas and icon.SetAtlas then
                        icon:SetAtlas(transmogAtlas, true)
                    else
                        icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
                    end
                    -- Hide rarity border, show default border
                    if rarityBorder then
                        rarityBorder:Hide()
                    end
                    if border then
                        border:Show()
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
                end
                icon:Show()
            end
        end
    end
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
    local unit = self.invUnit or "player"
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetInventoryItem(unit, self.invSlotId)
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
