local addonName, ns = ...

-- Tab switching function
function CharacterWindow_SwitchTab(tabIndex)
  local tabs = {
    CharacterWindowFrameTab1,
    CharacterWindowFrameTab2,
    CharacterWindowFrameTab3
  }

  -- Update all tabs: show/hide left/right/center textures based on active state
  for i, tab in ipairs(tabs) do
    if tab then
      local left = tab.Left or _G[tab:GetName() .. "Left"]
      local right = tab.Right or _G[tab:GetName() .. "Right"]
      local center = tab.Center or _G[tab:GetName() .. "Center"]

      if i == tabIndex then
        -- Active tab - show left, right, and center textures
        if left then left:Show() end
        if right then right:Show() end
        if center then center:Show() end
      else
        -- Inactive tab - hide left, right, and center textures
        if left then left:Hide() end
        if right then right:Hide() end
        if center then center:Hide() end
      end
    end
  end

  -- Handle tab-specific actions
  if tabIndex == 1 then
    -- Character tab - show our custom character window
    if CharacterWindowFrame then
      CharacterWindowFrame:Show()
    end
    -- Show tabs
    if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Show() end
    if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Show() end
    if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Show() end
  elseif tabIndex == 2 then
    -- Reputation tab - close our window and open WoW's Reputation frame
    local savedLeft, savedTop
    if CharacterWindowFrame then
      savedLeft = CharacterWindowFrame:GetLeft()
      savedTop = CharacterWindowFrame:GetTop()
      CharacterWindowFrame:Hide()
    end

    -- Hide tabs
    if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Hide() end
    if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Hide() end
    if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Hide() end

    if ToggleCharacter then
      ToggleCharacter("ReputationFrame")
      -- Set position after frame is shown
      if savedLeft and savedTop and CharacterFrame then
        C_Timer.After(0.1, function()
          if CharacterFrame then
            CharacterFrame:ClearAllPoints()
            CharacterFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedLeft, savedTop)
          end
        end)
      end
    end
  elseif tabIndex == 3 then
    -- Currency tab - close our window and open WoW's Currency frame
    local savedLeft, savedTop
    if CharacterWindowFrame then
      savedLeft = CharacterWindowFrame:GetLeft()
      savedTop = CharacterWindowFrame:GetTop()
      CharacterWindowFrame:Hide()
    end

    -- Hide tabs
    if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Hide() end
    if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Hide() end
    if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Hide() end

    if ToggleCharacter then
      ToggleCharacter("TokenFrame")
      -- Set position after frame is shown
      if savedLeft and savedTop and CharacterFrame then
        C_Timer.After(0.1, function()
          if CharacterFrame then
            CharacterFrame:ClearAllPoints()
            CharacterFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", savedLeft, savedTop)
          end
        end)
      end
    end
  end
end
