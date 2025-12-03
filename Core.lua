local addonName, ns = ...

-- Helper: size window to 70% width / 50% height of the screen
local function CharacterWindowFrame_UpdateSize()
    if not CharacterWindowFrame or not UIParent then
        return
    end
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if screenW and screenH then
        CharacterWindowFrame:SetSize(screenW * 0.7, screenH * 0.7)
    end
end

-- Equipment slot configuration: which frame maps to which inventory slot
local EQUIPMENT_SLOTS = {
    { frameName = "CharacterWindowFrameLeftSlot1",  invToken = "HeadSlot" },
    { frameName = "CharacterWindowFrameLeftSlot2",  invToken = "NeckSlot" },
    { frameName = "CharacterWindowFrameLeftSlot3",  invToken = "ShoulderSlot" },
    { frameName = "CharacterWindowFrameLeftSlot4",  invToken = "ChestSlot" },
    { frameName = "CharacterWindowFrameRightSlot1", invToken = "HandsSlot" },
    { frameName = "CharacterWindowFrameRightSlot2", invToken = "WaistSlot" },
    { frameName = "CharacterWindowFrameRightSlot3", invToken = "LegsSlot" },
    { frameName = "CharacterWindowFrameRightSlot4", invToken = "FeetSlot" },
}

local function CharacterWindow_UpdateEquipmentSlots()
    for _, slot in ipairs(EQUIPMENT_SLOTS) do
        local button = _G[slot.frameName]
        if button then
            local icon = button.Icon or _G[slot.frameName .. "Icon"]
            if icon then
                local invSlotId = GetInventorySlotInfo(slot.invToken)
                local texture = GetInventoryItemTexture("player", invSlotId)
                -- Store info on the button so tooltip handlers can use it
                button.invSlotId = invSlotId
                button.invUnit = "player"
                if texture then
                    icon:SetTexture(texture)
                    icon:Show()
                else
                    icon:SetTexture(nil)
                    icon:Hide()
                end
            end
        end
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

-- Slash command to toggle the window
SLASH_CHARACTERWINDOW1 = "/uiwin"
SlashCmdList["CHARACTERWINDOW"] = function()
    if not CharacterWindowFrame then
        print("CharacterWindow: frame not loaded. Check for XML errors in the chat window.")
        return
    end
    if CharacterWindowFrame:IsShown() then
        CharacterWindowFrame:Hide()
    else
        -- Ensure title text is set on the PortraitFrame template
        if CharacterWindowFrame.TitleText then
            CharacterWindowFrame.TitleText:SetText("Troll Character View")
        end
        -- Set the spec icon (or fallback to character portrait) in the frame's portrait circle
        if CharacterWindowFramePortrait then
            local specIndex = GetSpecialization and GetSpecialization()
            if specIndex then
                local _, _, _, icon = GetSpecializationInfo(specIndex)
                if icon then
                    CharacterWindowFramePortrait:SetTexture(icon)
                else
                    SetPortraitTexture(CharacterWindowFramePortrait, "player")
                end
            else
                SetPortraitTexture(CharacterWindowFramePortrait, "player")
            end
        end
        -- Desaturate the Zandalari starting zone background to make it black & white
        if CharacterWindowFrameZoneBG and CharacterWindowFrameZoneBG.SetDesaturated then
            CharacterWindowFrameZoneBG:SetDesaturated(true)
        end
        -- Populate equipment slot icons
        CharacterWindow_UpdateEquipmentSlots()
        CharacterWindowFrame_UpdateSize()
        CharacterWindowFrame:Show()
    end
end

-- Keep equipment slots updated when gear changes while the window is open
local eqFrame = CreateFrame("Frame")
eqFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eqFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eqFrame:SetScript("OnEvent", function()
    if CharacterWindowFrame and CharacterWindowFrame:IsShown() then
        CharacterWindow_UpdateEquipmentSlots()
    end
end)

-- Button click handler called from XML
function UIWindowButton_OnClick(self)
    print("Button clicked from Lua handler!")
end
