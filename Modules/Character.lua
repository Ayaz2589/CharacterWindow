local addonName, ns = ...

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
function CharacterWindow_UpdateBackground()
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

-- Refresh the player model to reflect current appearance / equipment
function CharacterWindow_RefreshModel()
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

-- Helper: size window to 70% width / 80% height of the screen, and position model/equipment slots
function CharacterWindowFrame_UpdateSize()
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
        local modelW = frameW * 0.40 -- 40% of window width
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
