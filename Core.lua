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
local CLASS_STATS_BG_ATLAS = {
    MAGE        = "UI-Character-Info-Mage-BG",
    PALADIN     = "UI-Character-Info-Paladin-BG",
    ROGUE       = "UI-Character-Info-Rogue-BG",
    WARLOCK     = "UI-Character-Info-Warlock-BG",
    WARRIOR     = "UI-Character-Info-Warrior-BG",
    MONK        = "UI-Character-Info-Monk-BG",
    PRIEST      = "UI-Character-Info-Priest-BG",
    SHAMAN      = "UI-Character-Info-Shaman-BG",
    DEATHKNIGHT = "UI-Character-Info-DeathKnight-BG",
    DEMONHUNTER = "UI-Character-Info-DemonHunter-BG",
}

local function CharacterWindow_SetFontSize(fs, size)
    if not fs or not fs.SetFont then
        return
    end
    local font, oldSize, flags = fs:GetFont()
    if font and oldSize ~= size then
        fs:SetFont(font, size, flags)
    end
end

-- Refresh the player model to reflect current appearance / equipment
local function CharacterWindow_RefreshModel()
    if not CharacterWindowFrameModel then
        return
    end

    -- Be aggressive so appearance always matches current equipment.
    if CharacterWindowFrameModel.ClearModel then
        CharacterWindowFrameModel:ClearModel()
    end

    if CharacterWindowFrameModel.SetUnit then
        CharacterWindowFrameModel:SetUnit("player")
    end

    if CharacterWindowFrameModel.SetPortraitZoom then
        CharacterWindowFrameModel:SetPortraitZoom(0.025)
    end

    if CharacterWindowFrameModel.ResetCamera then
        CharacterWindowFrameModel:ResetCamera()
    end

    if CharacterWindowFrameModel.SetAnimation then
        CharacterWindowFrameModel:SetAnimation(0)
    end
end

local function CharacterWindow_UpdateStatsPanel()
    if not CharacterWindowStatsPanel then
        return
    end

    -- Class for stats panel background
    local _, class = UnitClass("player")
    local atlas    = CLASS_STATS_BG_ATLAS[class] or "UI-Character-Info-Mage-BG"
    if CharacterWindowStatsPanelClassBG and CharacterWindowStatsPanelClassBG.SetAtlas then
        CharacterWindowStatsPanelClassBG:SetAtlas(atlas, true)
    end

    -- Character summary has moved to the main frame; no summary text in the stats panel

    -- Item level
    local avg, equipped = GetAverageItemLevel()
    local ilvl = equipped or avg
    if CharacterWindowStatsPanelItemLevelValue and ilvl then
        CharacterWindowStatsPanelItemLevelValue:SetFormattedText("%.1f", ilvl)
        -- Ensure the item level number is visually large regardless of XML quirks
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelItemLevelValue, 30)
    end

    -- Primary stat, stamina, armor (very simple approximation)
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

    -- Attribute lines: labels on the left, values right-aligned on the same row
    if CharacterWindowStatsPanelAttributesLine1Label and CharacterWindowStatsPanelAttributesLine1Value then
        CharacterWindowStatsPanelAttributesLine1Label:SetText(primaryLabel .. ":")
        CharacterWindowStatsPanelAttributesLine1Value:SetFormattedText("%d", primaryEff or primaryBase or 0)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine1Label, 16)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine1Value, 16)
    end
    if CharacterWindowStatsPanelAttributesLine2Label and CharacterWindowStatsPanelAttributesLine2Value then
        CharacterWindowStatsPanelAttributesLine2Label:SetText("Stamina:")
        CharacterWindowStatsPanelAttributesLine2Value:SetFormattedText("%d", staminaEff or staminaBase or 0)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine2Label, 16)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine2Value, 16)
    end
    if CharacterWindowStatsPanelAttributesLine3Label and CharacterWindowStatsPanelAttributesLine3Value then
        CharacterWindowStatsPanelAttributesLine3Label:SetText("Armor:")
        CharacterWindowStatsPanelAttributesLine3Value:SetFormattedText("%d", effectiveArmor or baseArmor or 0)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine3Label, 16)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine3Value, 16)
    end

    -- Basic enhancements: Crit, Haste, Mastery (+ optional Vers, Leech, Speed)
    local crit    = GetCritChance and GetCritChance() or 0
    local haste   = GetHaste and GetHaste() or 0
    local mastery = GetMasteryEffect and GetMasteryEffect() or 0
    local vers    = 0
    local leech   = 0
    local speed   = 0

    if GetVersatility then
        vers = GetVersatility() or 0
    elseif GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
        vers = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0
    end

    if GetLifesteal then
        leech = GetLifesteal() or 0
    end

    if GetSpeed then
        speed = GetSpeed() or 0
    end

    -- Helper to show/hide an enhancement row based on value
    local function SetEnhancementRow(labelFS, valueFS, labelText, value)
        if not (labelFS and valueFS) then
            return
        end
        -- Treat very small values as "missing"
        if value and math.abs(value) > 0.01 then
            labelFS:SetText(labelText)
            valueFS:SetFormattedText("%.1f%%", value)
            labelFS:Show()
            valueFS:Show()
            CharacterWindow_SetFontSize(labelFS, 16)
            CharacterWindow_SetFontSize(valueFS, 16)
        else
            labelFS:Hide()
            valueFS:Hide()
        end
    end

    -- Always show core three
    SetEnhancementRow(
        CharacterWindowStatsPanelEnhancementsLine1Label,
        CharacterWindowStatsPanelEnhancementsLine1Value,
        "Critical Strike:",
        crit
    )
    SetEnhancementRow(
        CharacterWindowStatsPanelEnhancementsLine2Label,
        CharacterWindowStatsPanelEnhancementsLine2Value,
        "Haste:",
        haste
    )
    SetEnhancementRow(
        CharacterWindowStatsPanelEnhancementsLine3Label,
        CharacterWindowStatsPanelEnhancementsLine3Value,
        "Mastery:",
        mastery
    )

    -- Optional: Versatility, Leech, Speed only if present
    SetEnhancementRow(
        CharacterWindowStatsPanelEnhancementsLine4Label,
        CharacterWindowStatsPanelEnhancementsLine4Value,
        "Versatility:",
        vers
    )
    SetEnhancementRow(
        CharacterWindowStatsPanelEnhancementsLine5Label,
        CharacterWindowStatsPanelEnhancementsLine5Value,
        "Leech:",
        leech
    )
    SetEnhancementRow(
        CharacterWindowStatsPanelEnhancementsLine6Label,
        CharacterWindowStatsPanelEnhancementsLine6Value,
        "Speed:",
        speed
    )
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
        local modelW = frameW * 0.40 -- 30% of window width
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
                -- Always show a full-size icon so empty and filled slots look the same size.
                -- Use the real item icon when present, otherwise fall back to a generic empty-slot texture.
                if not texture then
                    texture = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
                end
                icon:SetTexture(texture)
                icon:Show()
            end
        end
    end
    -- Ensure the player model reflects any newly equipped/unequipped items
    CharacterWindow_RefreshModel()
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
        -- Update the race/class-specific background and player model
        CharacterWindow_UpdateBackground()
        CharacterWindow_RefreshModel()

        -- Update the character summary on the main frame (Level + Spec + Class)
        if CharacterWindowFrameCharacterSummary then
            local level = UnitLevel and UnitLevel("player") or nil

            -- Build the "Elemental Shaman" portion with class color and only the first letter of the class name capitalized
            local specName
            if GetSpecialization and GetSpecializationInfo then
                local specIndex = GetSpecialization()
                if specIndex then
                    local _, name = GetSpecializationInfo(specIndex)
                    specName = name
                end
            end
            local classLocalized, classFile = UnitClass("player")

            -- Normalize class display: only first letter uppercase
            local className = classLocalized or ""
            className = className:lower():gsub("^%l", string.upper)

            -- Build spec + class as plain text first (e.g., "Elemental Shaman" or just "Shaman")
            local specAndClassPlain
            if specName and specName ~= "" then
                specAndClassPlain = string.format("%s %s", specName, className)
            else
                specAndClassPlain = className
            end

            -- Apply class color to the entire "spec + class" string
            local specAndClassColored = specAndClassPlain
            if RAID_CLASS_COLORS and classFile and RAID_CLASS_COLORS[classFile] then
                local c = RAID_CLASS_COLORS[classFile]
                if c and c.r and c.g and c.b then
                    specAndClassColored = string.format("|cff%02x%02x%02x%s|r",
                        math.floor(c.r * 255 + 0.5),
                        math.floor(c.g * 255 + 0.5),
                        math.floor(c.b * 255 + 0.5),
                        specAndClassPlain
                    )
                end
            end

            -- "Level 80" in yellow, followed by spec + class in class color
            local levelPart = ""
            if level and level > 0 then
                levelPart = string.format("|cffffff00Level %d|r ", level)
            end

            local summaryText = levelPart .. (specAndClassColored or "")
            CharacterWindowFrameCharacterSummary:SetText(summaryText)
        end

        -- Set the PortraitFrameTemplate title bar text to the character's full title + name in white
        local baseName  = UnitName("player") or ""
        local titleName = UnitPVPName and UnitPVPName("player") or baseName -- includes chosen title if any
        titleName       = titleName or baseName

        if CharacterWindowFrame.SetTitle then
            CharacterWindowFrame:SetTitle(titleName)
        end

        -- Different PortraitFrameTemplate variants store TitleText in different places; try them all.
        local titleFS = CharacterWindowFrame.TitleText
        if not titleFS and CharacterWindowFrame.TitleContainer and CharacterWindowFrame.TitleContainer.TitleText then
            titleFS = CharacterWindowFrame.TitleContainer.TitleText
        end
        if not titleFS and CharacterWindowFrame.GetName then
            local frameName = CharacterWindowFrame:GetName()
            if frameName then
                titleFS = _G[frameName .. "TitleText"]
            end
        end

        if titleFS then
            titleFS:SetText(titleName)
            if titleFS.SetTextColor then
                -- Force pure white text for both title and name
                titleFS:SetTextColor(1, 1, 1)
            end
            titleFS:Show()
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
        CharacterWindow_UpdateBackground()
        CharacterWindow_UpdateStatsPanel()
        CharacterWindow_RefreshModel()
    end
end)

-- Button click handler called from XML
function UIWindowButton_OnClick(self)
    print("Button clicked from Lua handler!")
end
