local addonName, ns = ...

-- Forward declarations so slot tables and stats panel are visible inside functions
local EQUIPMENT_SLOTS
local LEFT_SLOT_SUFFIXES
local RIGHT_SLOT_SUFFIXES

-- Map player race/class to character creation starting zone atlases
local RACE_ATLAS_MAP = {
    -- Core races
    Orc                = "charactercreate-startingzone-orc",
    Troll              = "charactercreate-startingzone-troll",
    Tauren             = "charactercreate-startingzone-tauren",
    Scourge            = "charactercreate-startingzone-undead",
    Undead             = "charactercreate-startingzone-undead",
    NightElf           = "charactercreate-startingzone-nightelf",
    Draenei            = "charactercreate-startingzone-draenei",
    Dwarf              = "charactercreate-startingzone-dwarf",
    Gnome              = "charactercreate-startingzone-gnome",
    Goblin             = "charactercreate-startingzone-goblin",
    Worgen             = "charactercreate-startingzone-worgen",
    BloodElf           = "charactercreate-startingzone-bloodelf",
    Pandaren           = "charactercreate-startingzone-pandaren",

    -- Allied / newer races
    LightforgedDraenei = "charactercreate-startingzone-lightforgeddraenei",
    MagharOrc          = "charactercreate-startingzone-magharorc",
    Mechagnome         = "charactercreate-startingzone-mechagnome",
    Nightborne         = "charactercreate-startingzone-nightborne",
    HighmountainTauren = "charactercreate-startingzone-highmountaintauren",
    VoidElf            = "charactercreate-startingzone-voidelf",
    Vulpera            = "charactercreate-startingzone-vulpera",
    ZandalariTroll     = "charactercreate-startingzone-zandalaritroll",
    DarkIronDwarf      = "charactercreate-startingzone-darkirondwarf",
    KulTiran           = "charactercreate-startingzone-kultiran",
    Earthen            = "charactercreate-startingzone-earthen",
}

-- Choose a background atlas based on race/class
local function CharacterWindow_UpdateBackground()
    if not CharacterWindowFrameZoneBG then
        return
    end

    local _, raceFile = UnitRace("player")
    local _, classFile = UnitClass("player")

    local atlas

    -- Class-based overrides
    if classFile == "DEMONHUNTER" then
        atlas = "charactercreate-startingzone-demonhunter"
    elseif classFile == "DEATHKNIGHT" and raceFile and not RACE_ATLAS_MAP[raceFile] then
        -- Allied race death knights share a common background
        atlas = "charactercreate-startingzone-deathknight-alliedraces"
    end

    -- Race-based fallback
    if not atlas and raceFile and RACE_ATLAS_MAP[raceFile] then
        atlas = RACE_ATLAS_MAP[raceFile]
    end

    -- Final fallback if we don't have a specific mapping
    if not atlas then
        atlas = "charactercreate-startingzone-orc"
    end

    if CharacterWindowFrameZoneBG.SetAtlas then
        CharacterWindowFrameZoneBG:SetAtlas(atlas, true)
    else
        CharacterWindowFrameZoneBG:SetTexture("Interface\\Glues\\CharacterCreate\\" .. atlas)
    end

    -- Make the background black & white and slightly darker
    if CharacterWindowFrameZoneBG.SetDesaturated then
        CharacterWindowFrameZoneBG:SetDesaturated(true)
    end
    CharacterWindowFrameZoneBG:SetVertexColor(0.5, 0.5, 0.5)
end

-- Update the right-side stats panel (item level + basic stats)
local function CharacterWindow_UpdateStatsPanel()
    if not CharacterWindowStatsPanel then
        return
    end

    -- Item level
    local avg, equipped = GetAverageItemLevel()
    local ilvl = equipped or avg
    if CharacterWindowStatsPanelItemLevelValue and ilvl then
        CharacterWindowStatsPanelItemLevelValue:SetFormattedText("%.1f", ilvl)
    end

    -- Primary stat, stamina, armor (very simple approximation)
    local _, class = UnitClass("player")
    local primaryLabel = "Intellect"
    if class == "WARRIOR" or class == "ROGUE" or class == "HUNTER" or class == "DEMONHUNTER" then
        primaryLabel = "Agility"
    elseif class == "PALADIN" or class == "DEATHKNIGHT" then
        primaryLabel = "Strength"
    end

    local statIndex = primaryLabel == "Strength" and 1 or (primaryLabel == "Agility" and 2 or 4)
    local primaryBase, primaryEff = UnitStat("player", statIndex)
    local staminaBase, staminaEff = UnitStat("player", 3)
    local baseArmor, effectiveArmor = UnitArmor("player")

    if CharacterWindowStatsPanelAttributesLine1 then
        CharacterWindowStatsPanelAttributesLine1:SetFormattedText("%s: %d", primaryLabel, primaryEff or primaryBase or 0)
    end
    if CharacterWindowStatsPanelAttributesLine2 then
        CharacterWindowStatsPanelAttributesLine2:SetFormattedText("Stamina: %d", staminaEff or staminaBase or 0)
    end
    if CharacterWindowStatsPanelAttributesLine3 then
        CharacterWindowStatsPanelAttributesLine3:SetFormattedText("Armor: %d", effectiveArmor or baseArmor or 0)
    end

    -- Basic enhancements: Crit, Haste, Mastery
    local crit    = GetCritChance and GetCritChance() or 0
    local haste   = GetHaste and GetHaste() or 0
    local mastery = GetMasteryEffect and GetMasteryEffect() or 0

    if CharacterWindowStatsPanelEnhancementsLine1 then
        CharacterWindowStatsPanelEnhancementsLine1:SetFormattedText("Crit: %.1f%%", crit)
    end
    if CharacterWindowStatsPanelEnhancementsLine2 then
        CharacterWindowStatsPanelEnhancementsLine2:SetFormattedText("Haste: %.1f%%", haste)
    end
    if CharacterWindowStatsPanelEnhancementsLine3 then
        CharacterWindowStatsPanelEnhancementsLine3:SetFormattedText("Mastery: %.1f%%", mastery)
    end
end

-- Helper: size window to 70% width / 50% height of the screen
local function CharacterWindowFrame_UpdateSize()
    if not CharacterWindowFrame or not UIParent then
        return
    end

    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if not (screenW and screenH) then
        return
    end

    local frameW = screenW * 0.7
    local frameH = screenH * 0.8

    -- Resize the window itself
    CharacterWindowFrame:SetSize(frameW, frameH)

    -- Let the model height be driven by its top/bottom anchors,
    -- but make its width scale with the window.
    if CharacterWindowFrameModel then
        local modelW = frameW * 0.30 -- 30% of window width
        CharacterWindowFrameModel:SetWidth(modelW)
    end

    -- Scale and position equipment slots so left/right columns span (almost) the same height as the model.
    if CharacterWindowFrameModel and EQUIPMENT_SLOTS then
        local modelH = CharacterWindowFrameModel:GetHeight()
        if modelH and modelH > 0 then
            -- Small gap between slots so they don't visually merge
            local gap           = math.max(4, math.floor(modelH * 0.02))

            -- Left/right column sizing (8 slots each), leave 10% padding at top/bottom
            local visibleH      = modelH * 0.80
            local padding       = (modelH - visibleH) / 2
            local count         = 8
            local leftSlotSize  = math.floor((visibleH - gap * (count - 1)) / count)
            leftSlotSize        = math.max(32, math.min(leftSlotSize, 72))
            local rightSlotSize = leftSlotSize

            -- Apply sizes to all slots
            for _, slot in ipairs(EQUIPMENT_SLOTS) do
                local button = _G[slot.frameName]
                if button then
                    local size = slot.frameName:find("LeftSlot", 1, true) and leftSlotSize or rightSlotSize
                    button:SetSize(size, size)
                end
            end

            -- Vertically center left and right columns relative to the model's visible area,
            -- and keep them beside (not overlapping) the character model.
            local function positionColumn(suffixes, side)
                local count = #suffixes
                if count == 0 then return end

                local size = leftSlotSize -- both columns use same size currently
                local totalHeight = size * count + gap * (count - 1)
                local startOffset = totalHeight / 2 - size / 2

                for i, suffix in ipairs(suffixes) do
                    local btn = _G["CharacterWindowFrame" .. suffix]
                    if btn then
                        btn:ClearAllPoints()
                        local offsetY = startOffset - (i - 1) * (size + gap)
                        if side == "LEFT" then
                            -- Right edge of slot anchored to the left edge of the model
                            btn:SetPoint("RIGHT", CharacterWindowFrameModel, "LEFT", -8, offsetY)
                        else
                            -- Left edge of slot anchored to the right edge of the model
                            btn:SetPoint("LEFT", CharacterWindowFrameModel, "RIGHT", 8, offsetY)
                        end
                    end
                end
            end

            if LEFT_SLOT_SUFFIXES then
                positionColumn(LEFT_SLOT_SUFFIXES, "LEFT")
            end
            if RIGHT_SLOT_SUFFIXES then
                positionColumn(RIGHT_SLOT_SUFFIXES, "RIGHT")
            end
        end
    end
end

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
        -- Update the race/class-specific background
        CharacterWindow_UpdateBackground()

        -- Get the player name and show it centered on the top toolbar
        local playerName = UnitName("player") or ""
        if CharacterWindowFrame.TitleText then
            local fs = CharacterWindowFrame.TitleText
            fs:ClearAllPoints()
            fs:SetPoint("TOP", CharacterWindowFrame, "TOP", 0, -4)
            fs:SetText(playerName)
            fs:Show()
        end
        -- Populate equipment slot icons and stats
        CharacterWindow_UpdateEquipmentSlots()
        CharacterWindow_UpdateStatsPanel()
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
        CharacterWindow_UpdateBackground()
        CharacterWindow_UpdateStatsPanel()
    end
end)

-- Button click handler called from XML
function UIWindowButton_OnClick(self)
    print("Button clicked from Lua handler!")
end
