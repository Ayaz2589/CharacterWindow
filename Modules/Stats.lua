local addonName, ns = ...

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

function CharacterWindow_UpdateStatsPanel()
    if not CharacterWindowStatsPanel then
        return
    end

    -- Initialize the three empty slots above the stats panel
    CharacterWindow_InitStatsPanelSlots()

    -- Class for stats panel background - removed per user request
    -- local _, class = UnitClass("player")
    -- local atlas    = CLASS_STATS_BG_ATLAS[class] or "UI-Character-Info-Mage-BG"
    -- if CharacterWindowStatsPanelClassBG and CharacterWindowStatsPanelClassBG.SetAtlas then
    --     CharacterWindowStatsPanelClassBG:SetAtlas(atlas, true)
    -- end

    -- Character summary has moved to the main frame; no summary text in the stats panel

    -- Item level
    local avg, equipped = GetAverageItemLevel()
    local ilvl = equipped or avg
    if CharacterWindowStatsPanelItemLevelValue and ilvl then
        CharacterWindowStatsPanelItemLevelValue:SetFormattedText("%.1f", ilvl)
        -- Ensure the item level number is visually large regardless of XML quirks
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelItemLevelValue, 25)
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
        local primaryValue = primaryEff or primaryBase or 0
        CharacterWindowStatsPanelAttributesLine1Value:SetText(BreakUpLargeNumbers(primaryValue))
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine1Label, 16)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine1Value, 16)
    end
    if CharacterWindowStatsPanelAttributesLine2Label and CharacterWindowStatsPanelAttributesLine2Value then
        CharacterWindowStatsPanelAttributesLine2Label:SetText("Stamina:")
        local staminaValue = staminaEff or staminaBase or 0
        CharacterWindowStatsPanelAttributesLine2Value:SetText(BreakUpLargeNumbers(staminaValue))
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine2Label, 16)
        CharacterWindow_SetFontSize(CharacterWindowStatsPanelAttributesLine2Value, 16)
    end
    if CharacterWindowStatsPanelAttributesLine3Label and CharacterWindowStatsPanelAttributesLine3Value then
        CharacterWindowStatsPanelAttributesLine3Label:SetText("Armor:")
        local armorValue = effectiveArmor or baseArmor or 0
        CharacterWindowStatsPanelAttributesLine3Value:SetText(BreakUpLargeNumbers(armorValue))
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

-- Tooltip helper functions
local function AddTooltipSection(title, valueLabel, value, description, baseValue, effectiveValue)
    GameTooltip:SetText(title, 1, 1, 1)
    GameTooltip:AddLine(" ")
    if valueLabel and value then
        GameTooltip:AddLine(string.format("%s: %s", valueLabel, value), 1, 1, 1)
    end
    -- Add base/bonus breakdown if provided
    if baseValue and effectiveValue and baseValue ~= effectiveValue then
        GameTooltip:AddLine(string.format("Base: %d", baseValue), 0.7, 0.7, 0.7)
        GameTooltip:AddLine(string.format("Bonus: +%d", (effectiveValue - baseValue)), 0, 1, 0)
    end
    if description then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(description, 0.7, 0.7, 0.7, true)
    end
end

local function GetPrimaryStatLabel(class)
    if class == "WARRIOR" or class == "ROGUE" or class == "HUNTER" or class == "DEMONHUNTER" then
        return "Agility", 2
    elseif class == "PALADIN" or class == "DEATHKNIGHT" then
        return "Strength", 1
    else
        return "Intellect", 4
    end
end

-- Stat tooltip configuration
local STAT_TOOLTIPS = {
    crit = {
        title = "Critical Strike",
        valueLabel = "Chance",
        getValue = function() return GetCritChance and GetCritChance() or 0 end,
        format = "%.2f%%",
        description = "Increases chance for spells and attacks to critically hit for 200% damage."
    },
    haste = {
        title = "Haste",
        valueLabel = "Rating",
        getValue = function() return GetHaste and GetHaste() or 0 end,
        format = "%.2f%%",
        description = "Increases casting speed, attack speed, and resource regeneration rate."
    },
    mastery = {
        title = "Mastery",
        valueLabel = "Rating",
        getValue = function() return GetMasteryEffect and GetMasteryEffect() or 0 end,
        format = "%.2f%%",
        description = "Increases the effectiveness of your class-specific Mastery ability."
    },
    versatility = {
        title = "Versatility",
        valueLabel = "Rating",
        getValue = function()
            if GetVersatility then
                return GetVersatility() or 0
            elseif GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
                return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0
            end
            return 0
        end,
        format = "%.2f%%",
        description = "Increases damage and healing done, and reduces damage taken."
    },
    leech = {
        title = "Leech",
        valueLabel = "Rating",
        getValue = function() return GetLifesteal and GetLifesteal() or 0 end,
        format = "%.2f%%",
        description = "Heals you for a percentage of damage dealt."
    },
    speed = {
        title = "Speed",
        valueLabel = "Rating",
        getValue = function() return GetSpeed and GetSpeed() or 0 end,
        format = "%.2f%%",
        description = "Increases movement speed."
    }
}

-- Tooltip functions for stats
function CharacterWindow_ShowStatTooltip(self, statType)
    if not GameTooltip then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local _, class = UnitClass("player")

    -- Handle special cases
    if statType == "itemlevel" then
        local avg, equipped = GetAverageItemLevel()
        AddTooltipSection("Item Level", "Equipped", string.format("%.1f", equipped or avg or 0))
        if avg and equipped and avg ~= equipped then
            GameTooltip:AddLine(string.format("Average: %.1f", avg), 0.7, 0.7, 0.7)
        end
    elseif statType == "primary" then
        local primaryLabel, statIndex = GetPrimaryStatLabel(class)
        local primaryBase, primaryEff = UnitStat("player", statIndex)
        AddTooltipSection(primaryLabel, "Total", string.format("%d", primaryEff or primaryBase or 0), nil, primaryBase,
            primaryEff)
    elseif statType == "stamina" then
        local staminaBase, staminaEff = UnitStat("player", 3)
        AddTooltipSection("Stamina", "Total", string.format("%d", staminaEff or staminaBase or 0), nil, staminaBase,
            staminaEff)
        local health = UnitHealthMax("player")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Health: %s", health and BreakUpLargeNumbers(health) or "0"), 0, 1, 0)
    elseif statType == "armor" then
        local baseArmor, effectiveArmor = UnitArmor("player")
        AddTooltipSection("Armor", "Total", string.format("%d", effectiveArmor or baseArmor or 0), nil, baseArmor,
            effectiveArmor)
        local reduction = effectiveArmor and (effectiveArmor / (effectiveArmor + 400 + 85 * UnitLevel("player"))) * 100 or
            0
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Physical Damage Reduction: %.1f%%", reduction), 0, 1, 0)
        -- Handle simple stats from configuration table
    elseif STAT_TOOLTIPS[statType] then
        local config = STAT_TOOLTIPS[statType]
        local value = config.getValue()
        AddTooltipSection(config.title, config.valueLabel, string.format(config.format, value), config.description)
    end

    GameTooltip:Show()
end

function CharacterWindow_HideStatTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

-- Mapping of class file names to class icon atlases
local CLASS_ICON_MAP = {
    DEATHKNIGHT = "classicon-deathknight",
    DEMONHUNTER = "classicon-demonhunter",
    DRUID = "classicon-druid",
    EVOKER = "classicon-evoker",
    HUNTER = "classicon-hunter",
    MAGE = "classicon-mage",
    MONK = "classicon-monk",
    PALADIN = "classicon-paladin",
    PRIEST = "classicon-priest",
    ROGUE = "classicon-rogue",
    SHAMAN = "classicon-shaman",
    WARLOCK = "classicon-warlock",
    WARRIOR = "classicon-warrior",
}

-- Initialize the three empty slots above the stats panel
function CharacterWindow_InitStatsPanelSlots()
    -- Leftmost slot: class icon (square, fitted inside slot frame)
    local slot1Frame = _G["CharacterWindowStatsPanelSlotsSlot1Frame"]
    local slot1 = _G["CharacterWindowStatsPanelSlotsSlot1"]

    -- Set the frame background
    if slot1Frame then
        if slot1Frame.SetAtlas then
            slot1Frame:SetAtlas("UI-HUD-ActionBar-IconFrame", false) -- Don't use atlas size
            -- Explicitly set size to match XML
            slot1Frame:SetSize(45, 45)
        end
        slot1Frame:Show()
    end

    -- Set the class icon inside the frame
    if slot1 then
        -- Get player's class
        local _, classFile = UnitClass("player")
        local classIconAtlas = CLASS_ICON_MAP[classFile] or "classicon-warrior" -- Fallback to warrior

        -- Clear any existing texture
        if slot1.SetTexture then
            slot1:SetTexture(nil)
        end
        -- Clear any existing texcoord
        slot1:SetTexCoord(0, 1, 0, 1)

        -- Set class icon atlas
        if slot1.SetAtlas then
            slot1:SetAtlas(classIconAtlas, false) -- Don't use atlas size
            -- Explicitly set size to match XML (smaller than frame)
            slot1:SetSize(40, 40)
        end
        slot1:Show()
    end

    -- Middle and right slots: empty frame
    for i = 2, 3 do
        local slot = _G["CharacterWindowStatsPanelSlotsSlot" .. i]
        if slot then
            if slot.SetAtlas then
                slot:SetAtlas("UI-HUD-ActionBar-IconFrame", true)
            end
            slot:Show()
        end
    end
end
