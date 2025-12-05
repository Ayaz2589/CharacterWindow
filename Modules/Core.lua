local addonName, ns = ...

-- Update the frame portrait with spec icon or character portrait
local function CharacterWindow_UpdatePortrait()
    if not CharacterWindowFramePortrait then
        return
    end

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

-- Update the character summary on the main frame (Level + Spec + Class)
local function CharacterWindow_UpdateCharacterSummary()
    if not CharacterWindowFrameCharacterSummary then
        return
    end

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

-- Update the PortraitFrameTemplate title bar text with character's full title + name
local function CharacterWindow_UpdateTitle()
    local baseName  = UnitName("player") or ""
    local titleName = UnitPVPName and UnitPVPName("player") or baseName -- includes chosen title if any
    titleName       = titleName or baseName

    if CharacterWindowFrame and CharacterWindowFrame.SetTitle then
        CharacterWindowFrame:SetTitle(titleName)
    end
end

-- Slash command to toggle the window
SLASH_CHARACTERWINDOW1 = "/init"
SlashCmdList["CHARACTERWINDOW"] = function()
    if not CharacterWindowFrame then
        print("CharacterWindow: frame not loaded. Check for XML errors in the chat window.")
        return
    end
    if CharacterWindowFrame:IsShown() then
        CharacterWindowFrame:Hide()
        -- Hide tabs when window is hidden
        if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Hide() end
        if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Hide() end
        if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Hide() end
    else
        CharacterWindow_UpdatePortrait()

        if CharacterWindow_UpdateBackground then
            CharacterWindow_UpdateBackground()
        end
        if CharacterWindow_RefreshModel then
            CharacterWindow_RefreshModel()
        end

        CharacterWindow_UpdateCharacterSummary()

        CharacterWindow_UpdateTitle()

        if CharacterWindow_UpdateEquipmentSlots then
            CharacterWindow_UpdateEquipmentSlots()
        end
        if CharacterWindow_UpdateStatsPanel then
            CharacterWindow_UpdateStatsPanel()
        end
        if CharacterWindowFrame_UpdateSize then
            CharacterWindowFrame_UpdateSize()
        end
        
        -- Ensure rarity borders are resized after window is sized
        if CharacterWindow_ResizeRarityBorders then
            CharacterWindow_ResizeRarityBorders()
        end
        
        -- Ensure weapon slots have a higher frame level than the character model so they can receive mouse clicks
        if CharacterWindowFrameModel then
            local modelLevel = CharacterWindowFrameModel:GetFrameLevel() or 1
            local weaponSlotLevel = modelLevel + 10 -- Ensure weapon slots are above the model
            
            if CharacterWindowFrameBottomSlotMainHand then
                CharacterWindowFrameBottomSlotMainHand:SetFrameLevel(weaponSlotLevel)
            end
            if CharacterWindowFrameBottomSlotOffHand then
                CharacterWindowFrameBottomSlotOffHand:SetFrameLevel(weaponSlotLevel)
            end
        end
        
        CharacterWindowFrame:Show()
        -- Show tabs when window is shown
        if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Show() end
        if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Show() end
        if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Show() end

        -- Set Character tab as active by default
        if CharacterWindow_SwitchTab then
            CharacterWindow_SwitchTab(1)
        end
    end
end


-- Button click handler called from XML
function UIWindowButton_OnClick(self)
    print("Button clicked from Lua handler!")
end
