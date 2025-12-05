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
      local tabName = tab:GetName()
      local left = _G[tabName .. "Left"]
      local right = _G[tabName .. "Right"]
      local center = _G[tabName .. "Center"]
      local inactiveLeft = _G[tabName .. "InactiveLeft"]
      local inactiveRight = _G[tabName .. "InactiveRight"]
      local inactiveCenter = _G[tabName .. "InactiveCenter"]

      if i == tabIndex then
        -- Active tab - show active textures, hide inactive textures
        if left then left:Show() end
        if right then right:Show() end
        if center then center:Show() end
        if inactiveLeft then inactiveLeft:Hide() end
        if inactiveRight then inactiveRight:Hide() end
        if inactiveCenter then inactiveCenter:Hide() end
      else
        -- Inactive tab - hide active textures, show inactive textures
        if left then left:Hide() end
        if right then right:Hide() end
        if center then center:Hide() end
        if inactiveLeft then inactiveLeft:Show() end
        if inactiveRight then inactiveRight:Show() end
        if inactiveCenter then inactiveCenter:Show() end
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
    if CharacterWindowFrame then
      CharacterWindowFrame:Hide()
    end

    -- Hide tabs
    if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Hide() end
    if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Hide() end
    if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Hide() end

    if ToggleCharacter then
      ToggleCharacter("ReputationFrame")
    end
  elseif tabIndex == 3 then
    -- Currency tab - close our window and open WoW's Currency frame
    if CharacterWindowFrame then
      CharacterWindowFrame:Hide()
    end

    -- Hide tabs
    if CharacterWindowFrameTab1 then CharacterWindowFrameTab1:Hide() end
    if CharacterWindowFrameTab2 then CharacterWindowFrameTab2:Hide() end
    if CharacterWindowFrameTab3 then CharacterWindowFrameTab3:Hide() end

    if ToggleCharacter then
      ToggleCharacter("TokenFrame")
    end
  end
end
