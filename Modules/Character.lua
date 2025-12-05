local addonName, ns = ...

-- Map player class to Legion mission complete background atlases
local CLASS_ATLAS_MAP = {
    DEATHKNIGHT = "legionmission-complete-background-deathknight",
    DEMONHUNTER = "legionmission-complete-background-demonhunter",
    DRUID       = "legionmission-complete-background-druid",
    HUNTER      = "legionmission-complete-background-hunter",
    MAGE        = "legionmission-complete-background-mage",
    MONK        = "legionmission-complete-background-monk",
    PALADIN     = "legionmission-complete-background-paladin",
    PRIEST      = "legionmission-complete-background-priest",
    ROGUE       = "legionmission-complete-background-rogue",
    SHAMAN      = "legionmission-complete-background-shaman",
    WARLOCK     = "legionmission-complete-background-warlock",
    WARRIOR     = "legionmission-complete-background-warrior",
}

-- Choose a background atlas based on class
function CharacterWindow_UpdateBackground()
    if not CharacterWindowFrameZoneBG then
        return
    end

    local _, classFile = UnitClass("player")

    local atlas = CLASS_ATLAS_MAP[classFile]

    -- Fallback if class not found
    if not atlas then
        atlas = "legionmission-complete-background-warrior"
    end

    if CharacterWindowFrameZoneBG.SetAtlas then
        CharacterWindowFrameZoneBG:SetAtlas(atlas, true)
    else
        CharacterWindowFrameZoneBG:SetTexture("Interface\\Glues\\CharacterCreate\\" .. atlas)
    end

    -- Slightly dull the background so it doesn't overpower character details
    if CharacterWindowFrameZoneBG.SetDesaturated then
        CharacterWindowFrameZoneBG:SetDesaturated(false)        -- Keep color but reduce intensity
    end
    CharacterWindowFrameZoneBG:SetVertexColor(0.75, 0.75, 0.75) -- Slightly darker
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

    -- Calculate percentage-based size
    local frameW = screenW * 0.7  -- 70% width
    local frameH = screenH * 0.75 -- 75% height (increased for smaller screens)

    -- Maximum size constraints (to prevent window from being too large on ultra-wide monitors)
    local maxWidth = 1200  -- Maximum width in pixels (reduced for ultra-wide)
    local maxHeight = 1200 -- Maximum height in pixels

    -- Apply maximum constraints
    frameW = math.min(frameW, maxWidth)
    frameH = math.min(frameH, maxHeight)

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
