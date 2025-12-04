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

-- Tooltip functions for stats
function CharacterWindow_ShowStatTooltip(self, statType)
    if not GameTooltip then
        return
    end

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    local _, class = UnitClass("player")

    if statType == "itemlevel" then
        local avg, equipped = GetAverageItemLevel()
        local ilvl = equipped or avg
        GameTooltip:SetText("Item Level", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Equipped: %.1f", equipped or avg or 0), 1, 1, 1)
        if avg and equipped and avg ~= equipped then
            GameTooltip:AddLine(string.format("Average: %.1f", avg), 0.7, 0.7, 0.7)
        end
    elseif statType == "primary" then
        local primaryLabel = "Intellect"
        if class == "WARRIOR" or class == "ROGUE" or class == "HUNTER" or class == "DEMONHUNTER" then
            primaryLabel = "Agility"
        elseif class == "PALADIN" or class == "DEATHKNIGHT" then
            primaryLabel = "Strength"
        end

        local statIndex = primaryLabel == "Strength" and 1 or (primaryLabel == "Agility" and 2 or 4)
        local primaryBase, primaryEff = UnitStat("player", statIndex)

        GameTooltip:SetText(primaryLabel, 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Total: %d", primaryEff or primaryBase or 0), 1, 1, 1)
        if primaryBase and primaryEff and primaryBase ~= primaryEff then
            GameTooltip:AddLine(string.format("Base: %d", primaryBase), 0.7, 0.7, 0.7)
            GameTooltip:AddLine(string.format("Bonus: +%d", (primaryEff - primaryBase)), 0, 1, 0)
        end
    elseif statType == "stamina" then
        local staminaBase, staminaEff = UnitStat("player", 3)
        GameTooltip:SetText("Stamina", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Total: %d", staminaEff or staminaBase or 0), 1, 1, 1)
        if staminaBase and staminaEff and staminaBase ~= staminaEff then
            GameTooltip:AddLine(string.format("Base: %d", staminaBase), 0.7, 0.7, 0.7)
            GameTooltip:AddLine(string.format("Bonus: +%d", (staminaEff - staminaBase)), 0, 1, 0)
        end
        local health = UnitHealthMax("player")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Health: %s", health and BreakUpLargeNumbers(health) or "0"), 0, 1, 0)
    elseif statType == "armor" then
        local baseArmor, effectiveArmor = UnitArmor("player")
        GameTooltip:SetText("Armor", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Total: %d", effectiveArmor or baseArmor or 0), 1, 1, 1)
        if baseArmor and effectiveArmor and baseArmor ~= effectiveArmor then
            GameTooltip:AddLine(string.format("Base: %d", baseArmor), 0.7, 0.7, 0.7)
            GameTooltip:AddLine(string.format("Bonus: +%d", (effectiveArmor - baseArmor)), 0, 1, 0)
        end
        local reduction = effectiveArmor and (effectiveArmor / (effectiveArmor + 400 + 85 * UnitLevel("player"))) * 100 or
            0
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Physical Damage Reduction: %.1f%%", reduction), 0, 1, 0)
    elseif statType == "crit" then
        local crit = GetCritChance and GetCritChance() or 0
        GameTooltip:SetText("Critical Strike", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Chance: %.2f%%", crit), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Increases chance for spells and attacks to critically hit for 200% damage.", 0.7, 0.7, 0.7,
            true)
    elseif statType == "haste" then
        local haste = GetHaste and GetHaste() or 0
        GameTooltip:SetText("Haste", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Rating: %.2f%%", haste), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Increases casting speed, attack speed, and resource regeneration rate.", 0.7, 0.7, 0.7, true)
    elseif statType == "mastery" then
        local mastery = GetMasteryEffect and GetMasteryEffect() or 0
        GameTooltip:SetText("Mastery", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Rating: %.2f%%", mastery), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Increases the effectiveness of your class-specific Mastery ability.", 0.7, 0.7, 0.7, true)
    elseif statType == "versatility" then
        local vers = 0
        if GetVersatility then
            vers = GetVersatility() or 0
        elseif GetCombatRatingBonus and CR_VERSATILITY_DAMAGE_DONE then
            vers = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0
        end
        GameTooltip:SetText("Versatility", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Rating: %.2f%%", vers), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Increases damage and healing done, and reduces damage taken.", 0.7, 0.7, 0.7, true)
    elseif statType == "leech" then
        local leech = GetLifesteal and GetLifesteal() or 0
        GameTooltip:SetText("Leech", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Rating: %.2f%%", leech), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Heals you for a percentage of damage dealt.", 0.7, 0.7, 0.7, true)
    elseif statType == "speed" then
        local speed = GetSpeed and GetSpeed() or 0
        GameTooltip:SetText("Speed", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format("Rating: %.2f%%", speed), 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Increases movement speed.", 0.7, 0.7, 0.7, true)
    end

    GameTooltip:Show()
end

function CharacterWindow_HideStatTooltip()
    if GameTooltip then
        GameTooltip:Hide()
    end
end
