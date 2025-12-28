local ffi = require("ffi")
local C = ffi.C

ffi.cdef [[
  typedef uint64_t UniverseID;
  typedef uint64_t NPCSeed;

	typedef struct {
		const char* name;
		const char* colorid;
	} RelationRangeInfo;

  UniverseID GetPlayerID(void);
  RelationRangeInfo GetUIRelationName(const char* fromfactionid, const char* tofactionid);
]]

local traceEnabled = true

local pilotAcademy = {
  playerId = nil,
  menuMap = nil,
  menuMapConfig = {},
  academySideBarInfo = {
    name = "Pilot Academy R&R",
    icon = "pa_icon_academy",
    mode = "pilot_academy_r_and_r",
    helpOverlayID = "pilot_academy_r_and_r",
    helpOverlayText = "pilot_academy_r_and_r_help_overlay",
  },
  sideBarIsCreated = false,
  selectedWing = nil,
  wings = nil,
  wingIds = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i' },
  wingsVariableId = "pilotAcademyRAndRWings",
  editData = {},
}

local texts = {
  pilotAcademy = "Pilot Academy R&R",
  noAvailablePrimaryGoals = "No available primary goals",
  primaryGoal = "Primary Goal:",
  factions = "Factions:",
  targetRankLevel = "Target Rank:",
  wingLeader = "Wing Leader:",
  noAvailableWingLeaders = "No available wing leaders",
  wing = "Wing %s",
  addNewWing = "Add new Wing",
  wingmans = "Wingmans:",
  noAvailableWingmans = "No wingmans assigned",
  dismissWingman = "Dismiss",
  cancelChanges = "Cancel",
  saveWing = "Update",
  createWing = "Create",
}

local function debug(message)
  local text = "Pilot Academy: " .. message
  if type(DebugError) == "function" then
    DebugError(text)
  end
end

local function trace(message)
  ---@diagnostic disable-next-line: unnecessary-if
  if traceEnabled then
    debug(message)
  end
end

local function bind(obj, methodName)
  return function(...)
    return obj[methodName](obj, ...)
  end
end

local function preAddRowToMapMenuContext(contextMenuData, contextMenuMode, menu)
  if contextMenuData.person then
    trace("person: " ..
      ffi.string(C.GetPersonName(contextMenuData.person, contextMenuData.component)) ..
      ", combinedskill: " .. C.GetPersonCombinedSkill(contextMenuData.component, contextMenuData.person, nil, nil))
  end
  local result = nil
  return result
end

local function addRowToMapMenuContext(contextFrame, contextMenuData, contextMenuMode, menu)
  local result = nil
  trace("testAddRow called")

  if contextMenuMode ~= "info_context" then
    trace(string.format("contextMenuMode is '%s', not 'info_context', returning", tostring(contextMenuMode)))
    return result
  end

  if contextFrame == nil or type(contextFrame) ~= "table" then
    trace("contextFrame is nil or not a table, returning")
    return result
  end

  if contextMenuData == nil or type(contextMenuData) ~= "table" then
    trace("contextMenuData is not a table, returning")
    return result
  end

  if type(contextFrame.content) ~= "table" or #contextFrame.content == 0 then
    trace("contextFrame.content is not not a table or empty table, returning")
    return result
  end

  local menuTable = nil

  for i = 1, #contextFrame.content do
    local item = contextFrame.content[i]
    if type(item) == "table" and item.index == 1 then
      menuTable = item
      break
    end
  end

  if menuTable == nil then
    trace("menuTable not found in contextFrame.content, returning")
    return result
  end


  local entity = contextMenuData.entity
  local person = contextMenuData.person
  local controllable = contextMenuData.component
  local personrole = ""

  local player = C.GetPlayerID()

  if person then
    --print("person: " .. ffi.string(C.GetPersonName(person, controllable)) .. ", combinedskill: " .. C.GetPersonCombinedSkill(controllable, person, nil, nil))
    -- get real NPC if instantiated
    local instance = C.GetInstantiatedPerson(person, controllable)
    entity = (instance ~= 0 and instance or nil)
    personrole = ffi.string(C.GetPersonRole(person, controllable))
  end

  if person or (entity and (entity ~= player)) then
    if GetComponentData(controllable, "isplayerowned") then
      if (person and ((personrole == "service") or (personrole == "marine") or (personrole == "trainee_group") or (personrole == "unassigned"))) or (entity and GetComponentData(entity, "isplayerowned") and GetComponentData(entity, "caninitiatecomm")) then
        trace("Adding Pilot Academy R&R row to context menu")
        local mt = getmetatable(menuTable)
        local row = mt.__index.addRow(menuTable, "info_move_to_academy", { fixed = true })
        row[1]:createButton({ bgColor = Color["button_background_hidden"], height = Helper.standardTextHeight }):setText("Send to Pilot Academy R&R")
        result = { contextFrame = contextFrame }
      end
    end
  end
  return result
end


local function preAddRowToPlayerInfoMenuContext(contextMenuData, contextMenuMode, menu)
  local result = nil
  return result
end

local function addRowToPlayerInfoMenuContext(contextFrame, contextMenuData, contextMenuMode, menu)
  local result = nil
  trace("testAddRow called")

  if contextMenuMode ~= "personnel" then
    trace(string.format("contextMenuMode is '%s', not 'info_context', returning", tostring(contextMenuMode)))
    return result
  end

  if contextFrame == nil or type(contextFrame) ~= "table" then
    trace("contextFrame is nil or not a table, returning")
    return result
  end

  if contextMenuData == nil or type(contextMenuData) ~= "table" then
    trace("contextMenuData is not a table, returning")
    -- return result
  end

  if type(contextFrame.content) ~= "table" or #contextFrame.content == 0 then
    trace("contextFrame.content is not not a table or empty table, returning")
    return result
  end

  local menuTable = nil

  for i = 1, #contextFrame.content do
    local item = contextFrame.content[i]
    if type(item) == "table" and item.index == 1 then
      menuTable = item
      break
    end
  end

  if menuTable == nil then
    trace("menuTable not found in contextFrame.content, returning")
    return result
  end


  local controllable = C.ConvertStringTo64Bit(tostring(menu.personnelData.curEntry.container))
  local entity, person
  if menu.personnelData.curEntry.type == "person" then
    person = C.ConvertStringTo64Bit(tostring(menu.personnelData.curEntry.id))
  else
    entity = menu.personnelData.curEntry.id
  end

  local transferscheduled = false
  local hasarrived = true
  local personrole = ""
  if person then
    -- get real NPC if instantiated
    local instance = C.GetInstantiatedPerson(person, controllable)
    entity = (instance ~= 0 and instance or nil)
    transferscheduled = C.IsPersonTransferScheduled(controllable, person)
    hasarrived = C.HasPersonArrived(controllable, person)
    personrole = ffi.string(C.GetPersonRole(person, controllable))
  end

  local player = C.GetPlayerID()

  if (not transferscheduled) and hasarrived then
    trace("Adding Pilot Academy R&R row to context menu")
    local mt = getmetatable(menuTable)
    local row = mt.__index.addRow(menuTable, "info_move_to_academy", { fixed = true })
    row[1]:createButton({ bgColor = Color["button_background_hidden"], height = Helper.standardTextHeight }):setText("Send to Pilot Academy R&R")
    result = { contextFrame = contextFrame }
  end
  return result
end

function pilotAcademy.Init(menuMap, menuPlayerInfo)
  trace("pilotAcademy.Init called")
  pilotAcademy.sideBarIsCreated = false
  if menuMap ~= nil and type(menuMap.registerCallback) == "function" and type(menuMap.uix_getConfig) == "function" then
    pilotAcademy.menuMap = menuMap
    pilotAcademy.menuMapConfig = menuMap.uix_getConfig()
    menuMap.registerCallback("createSideBar_on_start", pilotAcademy.createSideBar)
    menuMap.registerCallback("createInfoFrame_on_menu_infoTableMode", pilotAcademy.createInfoFrame)
    -- menuMap.registerCallback("utRenaming_setupInfoSubmenuRows_on_end", fcm.setupInfoSubmenuRows)
    pilotAcademy.resetData()
  end
end

function pilotAcademy.resetData()
  pilotAcademy.editData = {}
  if pilotAcademy.wings == nil then
    pilotAcademy.loadWings()
  end
  if #pilotAcademy.wings > 0 then
    pilotAcademy.selectedWing = 1
  else
    pilotAcademy.selectedWing = nil
  end
end

function pilotAcademy.createSideBar(config)
  if not pilotAcademy.sideBarIsCreated then
    for i = 1, #config.leftBar do
      if config.leftBar[i].mode == pilotAcademy.academySideBarInfo.mode then
        trace("Pilot Academy R&R sidebar entry already exists, not adding again")
        return
      end
    end
    config.leftBar[#config.leftBar + 1] = { spacing = true }
    config.leftBar[#config.leftBar + 1] = pilotAcademy.academySideBarInfo
    trace("Added Pilot Academy R&R sidebar entry")
    pilotAcademy.sideBarIsCreated = true
  end
end

function pilotAcademy.createInfoFrame()
  if pilotAcademy.menuMap == nil then
    debug("MenuMap is nil; cannot create info frame")
    return
  end

  local menu = pilotAcademy.menuMap
  if menu.infoTableMode ~= pilotAcademy.academySideBarInfo.mode then
    trace("Info table mode is not Pilot Academy R&R, clearing edit data!")
    pilotAcademy.resetData()
    return
  end

  local config = pilotAcademy.menuMapConfig
  if config == nil then
    trace("Config is nil, cannot create info frame")
    return
  end
  local frame = menu.infoFrame
  local instance = "left"
  local infoTableMode = menu.infoTableMode[instance]

  pilotAcademy.loadWings()
  local tables = pilotAcademy.displayWingInfo(frame, menu, config)

  local maxNumCategoryColumns = math.floor(menu.infoTableWidth / (menu.sideBarWidth + Helper.borderSize))
  if maxNumCategoryColumns > Helper.maxTableCols then
    maxNumCategoryColumns = Helper.maxTableCols
  end

  local numdisplayed = 0
  -- local maxVisibleHeight = tableWing:getFullHeight()

  local tabsTable = frame:addTable(maxNumCategoryColumns, { tabOrder = 2, reserveScrollBar = false })
  tabsTable:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tabsTable:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tabsTable:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })

  if maxNumCategoryColumns > 0 then
    local wingsCount = #pilotAcademy.wings
    wingsCount = #pilotAcademy.wingIds - 1
    for i = 1, maxNumCategoryColumns do
      local columnWidth = menu.sideBarWidth
      if wingsCount > 0 and i == wingsCount + 1 and wingsCount + 1 < maxNumCategoryColumns then
        columnWidth = math.floor(columnWidth / 2)
      end
      tabsTable:setColWidth(i, columnWidth, false)
    end
    local diff = menu.infoTableWidth - maxNumCategoryColumns * (menu.sideBarWidth + Helper.borderSize)
    tabsTable:setColWidth(maxNumCategoryColumns, menu.sideBarWidth + diff, false)
    -- object list categories row
    local row = tabsTable:addRow("pilot_academy_r_and_r_tabs", { fixed = true })
    local rowCount = 1
    local placesCount = 1
    if wingsCount == #pilotAcademy.wingIds then
      placesCount = wingsCount
    elseif wingsCount == 0 then
      placesCount = 1
    else
      placesCount = wingsCount + 2
    end
    for i = 1, placesCount do
      if i / maxNumCategoryColumns > rowCount then
        row = tabsTable:addRow("pilot_academy_r_and_r_tabs", { fixed = true })
        rowCount = rowCount + 1
      end
      if i <= wingsCount or i == placesCount then
        local name = "Add Wing"
        local icon = "pa_icon_add"
        if i <= wingsCount then
          local wingId = tostring(pilotAcademy.wingIds[i] or "")
          name = string.format("Wing %s", wingId:upper())
          icon = "pa_icon_" .. wingId
        end
        local bgColor = Color["row_title_background"]
        if i == pilotAcademy.selectedWing or i == placesCount and pilotAcademy.selectedWing == nil then
          bgColor = Color["row_background_selected"]
        end
        local color = Color["icon_normal"]
        row[i - math.floor((i - 1) / maxNumCategoryColumns) * maxNumCategoryColumns]
            :createButton({
              height = menu.sideBarWidth,
              width = menu.sideBarWidth,
              bgColor = bgColor,
              mouseOverText = name,
              scaling = false,
              -- helpOverlayID = entry.helpOverlayID,
              -- helpOverlayText = entry.helpOverlayText,
            })
            :setIcon(icon, { color = color })
        row[i - math.floor((i - 1) / maxNumCategoryColumns) * maxNumCategoryColumns].handlers.onClick = function()
          return pilotAcademy.buttonSelectWing(i)
        end
      end
    end
  end

  -- if numdisplayed > 50 then
  --   table.properties.maxVisibleHeight = maxVisibleHeight + 50 * (Helper.scaleY(config.mapRowHeight) + Helper.borderSize)
  -- end
  -- menu.numFixedRows = tableWing.numfixedrows



  local topY = tabsTable.properties.y + tabsTable:getFullHeight() + Helper.borderSize
  for i = 1, #tables do
    tables[i].table.properties.y = topY
    topY = topY + tables[i].height
  end

end

function pilotAcademy.sortFactions(a, b)
  if a.uiRelation == b.uiRelation then
    return a.shortName < b.shortName
  end
  return a.uiRelation < b.uiRelation
end

function pilotAcademy.getFactions(config)
  local factionsAll = GetLibrary("factions")
  local factions = {}
  local maxShortNameWidth = 0
  local maxRelationNameWidth = 0
  for i, faction in ipairs(factionsAll) do
    if faction.id ~= "player" then
      local shortName, isAtDockRelation = GetFactionData(faction.id, "shortname", "isatdockrelation")
      if isAtDockRelation then
        faction.shortName = shortName
        faction.isAtDockRelation = isAtDockRelation
        faction.uiRelation = GetUIRelation(faction.id)
        local relationInfo = C.GetUIRelationName("player", faction.id)
        faction.relationName = ffi.string(relationInfo.name)
        faction.colorId = ffi.string(relationInfo.colorid)
        factions[#factions + 1] = faction
        local shortNameWidth = C.GetTextWidth(string.format("[%s]", shortName), Helper.standardFont, Helper.scaleFont(Helper.standardFont, config.mapFontSize))
        if shortNameWidth > maxShortNameWidth then
          maxShortNameWidth = shortNameWidth
        end
        local relationNameWidth = C.GetTextWidth(faction.relationName, Helper.standardFont, Helper.scaleFont(Helper.standardFont, config.mapFontSize))
        if relationNameWidth > maxRelationNameWidth then
          maxRelationNameWidth = relationNameWidth
        end
      end
    end
  end
  table.sort(factions, pilotAcademy.sortFactions)
  return factions, maxShortNameWidth, maxRelationNameWidth
end

function pilotAcademy.buttonSelectWing(i)
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot process buttonSelectWing")
    return
  end
  if i ~= pilotAcademy.selectedWing then
    pilotAcademy.selectedWing = i <= #pilotAcademy.wingIds and i or nil

    -- AddUITriggeredEvent(menu.name, pilotAcademy.tableMode)

    menu.refreshInfoFrame()
  end
end

function pilotAcademy.setTableWingColumnWidths(tableHandle, menu, config, maxShortNameWidth, maxRelationNameWidth)
  if tableHandle == nil or menu == nil then
    debug("TableWing or menu is nil; cannot set column widths")
    return
  end
  tableHandle:setColWidth(1, Helper.scrollbarWidth, false)
  for i = 2, 3 do
    tableHandle:setColWidth(i, config.mapRowHeight, false)
  end
  tableHandle:setColWidth(4, maxShortNameWidth + Helper.borderSize * 2, false)
  tableHandle:setColWidth(5, config.mapRowHeight, false)
  tableHandle:setColWidth(6, menu.sideBarWidth, false)
  tableHandle:setColWidthMin(7, menu.sideBarWidth, 2, true)
  for i = 8, 9 do
    tableHandle:setColWidth(i, config.mapRowHeight, false)
  end
  tableHandle:setColWidth(10, maxRelationNameWidth + Helper.borderSize * 2)
  local relationWidth = C.GetTextWidth(string.format("(%+2d)", 30), Helper.standardFont, Helper.scaleFont(Helper.standardFont, config.mapFontSize))
  tableHandle:setColWidth(11, relationWidth + Helper.borderSize * 2, false)
  tableHandle:setColWidth(12, Helper.scrollbarWidth, false)
end

function pilotAcademy.displayWingInfo(frame, menu, config)
  if frame == nil then
    trace("Frame is nil; cannot display wing info")
    return nil
  end
  if menu == nil or config == nil then
    trace("Menu or config is nil; cannot display wing info")
    return nil
  end
  local tables = {}
  local tableTop = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
  tableTop:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableTop:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableTop:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  local wings = pilotAcademy.wings or {}
  local wingIndex = pilotAcademy.selectedWing
  local existingWing = wingIndex ~= nil and wingIndex <= #wings and wings[wingIndex] ~= nil
  local factions, maxShortNameWidth, maxRelationNameWidth = pilotAcademy.getFactions(config)
  -- local factionsSorted =
  pilotAcademy.setTableWingColumnWidths(tableTop, menu, config, maxShortNameWidth, maxRelationNameWidth)
  local wingData = existingWing and wings[wingIndex] or {}
  local editData = pilotAcademy.editData or {}
  local primaryGoal = editData.primaryGoal or wingData.primaryGoal or "rank"
  local targetRankLevel = editData.targetRankLevel or wingData.targetRankLevel or 2
  local selectedFactions = {}
  if editData.factions ~= nil and type(editData.factions) == "table" then
    for _, factionId in ipairs(editData.factions) do
      selectedFactions[factionId] = true
    end
  elseif wingData.factions ~= nil and type(wingData.factions) == "table" then
    for _, factionId in ipairs(wingData.factions) do
      selectedFactions[factionId] = true
    end
  end

  local wingLeader = editData.wingLeader or wingData.wingLeader or nil

  local potentialWingLeaders = existingWing and {} or pilotAcademy.fetchPotentialWingLeaders()

  local row = tableTop:addRow("wing_header", { fixed = true })
  local suffix = string.format(pilotAcademy.selectedWing ~= nil and texts.wing or texts.addNewWing,
    existingWing and pilotAcademy.wingIds[pilotAcademy.selectedWing]:upper() or "")
  row[1]:setColSpan(12):createText(string.format("%s: %s", texts.pilotAcademy, suffix), Helper.headerRowCenteredProperties)
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableTop:addRow("wing_primary_goal", { fixed = true })
  local primaryGoalOptions = {
    { id = "rank",     icon = "", text = "Increase Rank",     text2 = "", displayremoveoption = false },
    { id = "relation", icon = "", text = "Improve Relations", text2 = "", displayremoveoption = false },
  }
  row[2]:setColSpan(5):createText(texts.primaryGoal, { halign = "left", titleColor = Color["row_title"] })
  row[7]:setColSpan(5):createDropDown(
    primaryGoalOptions,
    {
      startOption = primaryGoal or -1,
      active = true,
      textOverride = (#primaryGoalOptions == 0) and texts.noAvailablePrimaryGoals or nil,
    }
  )
  row[7]:setTextProperties({ halign = "left" })
  row[7].handlers.onDropDownConfirmed = function(_, id)
    return pilotAcademy.onSelectPrimaryGoal(id)
  end
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableTop:addRow("target_rank_level", { fixed = true })
  row[2]:setColSpan(5):createText(texts.targetRankLevel, { halign = "left", titleColor = Color["row_title"] })
  row[7]:setColSpan(5):createSliderCell({
    height = config.mapRowHeight,
    bgColor = Color["slider_background_transparent"],
    min = 2,
    minSelect = 2,
    max = 5,
    maxSelect = 5,
    start = targetRankLevel,
    step = 1,
    -- mouseOverText = ffi.string(C.GetDisplayedModifierKey("shift")) .. " - " .. ReadText(1026, 3279),
  })
  row[7].handlers.onSliderCellChanged = function(_, val) return pilotAcademy.onSelectTargetRankLevel(val) end
  row[7].handlers.onSliderCellConfirm = function() return menu.refreshInfoFrame() end
  row[7].handlers.onSliderCellActivated = function() menu.noupdate = true end
  row[7].handlers.onSliderCellDeactivated = function() menu.noupdate = false end
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  tables[#tables + 1] = { table = tableTop, height = tableTop:getFullHeight() }

  local tableFaction = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
  tableFaction:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableFaction:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableFaction:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setTableWingColumnWidths(tableFaction, menu, config, maxShortNameWidth, maxRelationNameWidth)
  local row = tableFaction:addRow(nil, { fixed = true })
  row[2]:setColSpan(10):createText(texts.factions, { halign = "left", titleColor = Color["row_title"] })
  local tableFactionMaxHeight = 0
  for i = 1, #factions do
    local faction = factions[i]
    if faction ~= nil then
      local row = tableFaction:addRow(faction.id, { fixed = false })
      row[2]:createCheckBox(selectedFactions[faction.id] == true, { scaling = false })
      row[2].handlers.onClick = function(_, checked) return pilotAcademy.onSelectFaction(faction.id, checked) end
      row[3]:createIcon(faction.icon, { height = config.mapRowHeight, width = config.mapRowHeight, color = Color[faction.colorId] or Color["text_normal"] })
      row[4]:createText(string.format("[%s]", faction.shortName), { halign = "center", color = Color[faction.colorId] or Color["text_normal"] })
      row[5]:createText("-", { halign = "center", color = Color[faction.colorId] or Color["text_normal"] })
      row[6]:setColSpan(4):createText(faction.name, { halign = "left", color = Color[faction.colorId] or Color["text_normal"] })
      row[10]:createText(faction.relationName, { halign = "left", color = Color[faction.colorId] or Color["text_normal"] })
      row[11]:createText(string.format("(%+2d)", faction.uiRelation), { halign = "right", color = Color[faction.colorId] or Color["text_normal"] })
      if i == 10 then
        tableFactionMaxHeight = tableFaction:getFullHeight()
      end
    end
  end
  if tableFactionMaxHeight == 0 then
    tableFactionMaxHeight = tableFaction:getFullHeight()
  end
  tableFaction.properties.maxVisibleHeight = math.min(tableFaction:getFullHeight(), tableFactionMaxHeight)
  tables[#tables + 1] = { table = tableFaction, height = tableFaction.properties.maxVisibleHeight }

  local tableWing = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
  tableWing:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableWing:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableWing:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setTableWingColumnWidths(tableWing, menu, config, maxShortNameWidth, maxRelationNameWidth)
  tableWing:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableWing:addRow("wing_leader", { fixed = true })
  local wingLeaderOptions = pilotAcademy.fetchPotentialWingLeaders(existingWing, wingLeader)
  row[2]:setColSpan(5):createText(texts.wingLeader, { halign = "left", titleColor = Color["row_title"] })
  row[7]:setColSpan(5):createDropDown(
    wingLeaderOptions,
    {
      startOption = wingLeader or -1,
      active = not existingWing,
      textOverride = (#wingLeaderOptions == 0) and texts.noAvailableWingLeaders or nil,
    }
  )
  row[7]:setTextProperties({ halign = "left" })
  row[7]:setText2Properties({ halign = "right", color = Color["text_positive"] })
  row[7].handlers.onDropDownConfirmed = function(_, id)
    return pilotAcademy.onSelectWingLeader(id)
  end
  tableWing:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  row = tableWing:addRow("wingmans", { fixed = true })
  row[2]:setColSpan(10):createText(texts.wingmans, { halign = "left", titleColor = Color["row_title"] })
  local wingmans = pilotAcademy.fetchWingmans(wingLeader)
  local tableWingMaxHeight = 0
  for i = 1, #wingmans do
    local wingman = wingmans[i]
    if wingman ~= nil then
      local row = tableWing:addRow(true, { fixed = false })
      if i == 10 then
        tableWingMaxHeight = tableWing:getFullHeight()
      end
    end
  end
  if #wingmans == 0 then
    row = tableWing:addRow("noWingmans", { fixed = true })
    row[2]:setColSpan(10):createText(texts.noAvailableWingmans, { halign = "left", color = Color["text_warning"] })
  end
  if tableWingMaxHeight == 0 then
    tableWingMaxHeight = tableWing:getFullHeight()
  end

  tableWing.properties.maxVisibleHeight = math.min(tableWing:getFullHeight(), tableWingMaxHeight)
  tables[#tables + 1] = { table = tableWing, height = tableWing.properties.maxVisibleHeight }

  local tableBottom = frame:addTable(7, { tabOrder = 2, reserveScrollBar = false })
  tableBottom:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableBottom:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableBottom:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  local buttonWidth = math.floor((menu.infoTableWidth - Helper.scrollbarWidth * 5) / 3)
  tableBottom:setColWidth(1, Helper.scrollbarWidth, true)
  for i = 2, 6 do
    if i % 2 == 0 then
      tableBottom:setColWidth(i, buttonWidth, false)
    else
      tableBottom:setColWidth(i, Helper.scrollbarWidth, false)
    end
  end
  tableBottom:setColWidth(7, Helper.scrollbarWidth, true)
  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  row = tableBottom:addRow("buttons", { fixed = true })
  if existingWing then
    row[2]:createButton({ active = next(editData) == nil }):setText(texts.dismissWing, { halign = "center" })
    row[2].handlers.onClick = function() return pilotAcademy.buttonDismissWing() end
  end

  row[4]:createButton({ active = next(editData) ~= nil }):setText(texts.cancelChanges, { halign = "center" })
  row[4].handlers.onClick = function() return pilotAcademy.buttonCancelChanges() end

  row[6]:createButton({ active = next(editData) == nil }):setText(existingWing and texts.saveWing or texts.createWing, { halign = "center" })
  row[6].handlers.onClick = function() return pilotAcademy.buttonSaveWing() end
  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  tables[#tables + 1] = { table = tableBottom, height = tableBottom:getFullHeight() }


  tableFaction:setTopRow(menu.settoprow)
  if menu.infoTable then
    local result = GetShiftStartEndRow(menu.infoTable)
    if result then
      tableFaction:setShiftStartEnd(tableFaction.unpack(result))
    end
  end
  tableFaction:setSelectedRow(menu.sethighlightborderrow or menu.setrow)
  menu.setrow = nil
  menu.settoprow = nil
  menu.setcol = nil
  menu.sethighlightborderrow = nil

  return tables
end

function pilotAcademy.onSelectPrimaryGoal(id)
  trace("onSelectPrimaryGoal called with id: " .. tostring(id))
  if id == nil then
    trace("id is nil; cannot process")
    return
  end
  pilotAcademy.editData.primaryGoal = id
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.onSelectTargetRankLevel(level)
  trace("onSelectTargetRankLevel called with level: " .. tostring(level))
  if level == nil then
    trace("level is nil; cannot process")
    return
  end
  pilotAcademy.editData.targetRankLevel = level
end

function pilotAcademy.onSelectFaction(factionId, isSelected)
  trace("onSelectFaction called with factionId: " .. tostring(factionId) .. ", isSelected: " .. tostring(isSelected))
  if factionId == nil then
    trace("factionId is nil; cannot process")
    return
  end
  if pilotAcademy.editData.factions == nil or type(pilotAcademy.editData.factions) ~= "table" then
    pilotAcademy.editData.factions = {}
  end
  local factions = pilotAcademy.editData.factions
  if isSelected then
    -- Add faction if not already present
    local found = false
    for i = 1, #factions do
      if factions[i] == factionId then
        found = true
        break
      end
    end
    if not found then
      factions[#factions + 1] = factionId
    end
  else
    -- Remove faction if present
    for i = 1, #factions do
      if factions[i] == factionId then
        table.remove(factions, i)
        break
      end
    end
  end

  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.fetchPotentialWingLeaders(existingWing, existingWingLeader)
  local potentialWingLeaders = {}
  return potentialWingLeaders
end

function pilotAcademy.fetchWingmans(wingLeader)
  local wingmans = {}
  return wingmans
end

function pilotAcademy.onSelectWingLeader(id)
  trace("onSelectWingLeader called with id: " .. tostring(id))
  if id == nil then
    trace("id is nil; cannot process")
    return
  end
  pilotAcademy.editData.wingLeader = id

  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.buttonDismissWing()
  trace("buttonDismissWing called")
end

function pilotAcademy.buttonCancelChanges()
  trace("buttonCancelChanges called")
  pilotAcademy.editData = {}
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.buttonSaveWing()
  trace("buttonSaveWing called")
end


function pilotAcademy.loadWings()
  pilotAcademy.wings = {}
  if pilotAcademy.playerId == nil or pilotAcademy.playerId == 0 then
    debug("loadWings: unable to resolve player id")
    return
  end

  local variableId = string.format("$%s", pilotAcademy.wingsVariableId)
  local savedData = GetNPCBlackboard(pilotAcademy.playerId, variableId)

  if savedData == nil or type(savedData) ~= "table" then
    debug("loadWings: no saved wings data found, initializing empty wings list")
    return
  end

  pilotAcademy.wings = savedData or {}
  debug("loadWings: loaded " .. tostring(#pilotAcademy.wings) .. " wings from saved data")
  -- Load wings data from saved data or initialize as needed
end

function pilotAcademy.saveWings()
  if pilotAcademy.playerId == nil or pilotAcademy.playerId == 0 then
    debug("saveWings: unable to resolve player id")
    return
  end
  local variableId = string.format("$%s", pilotAcademy.wingsVariableId)
  if pilotAcademy.wings == nil or type(pilotAcademy.wings) ~= "table" or #pilotAcademy.wings == 0 then
    debug("saveWings: no wings data to save, going to clear saved data")
    SetNPCBlackboard(pilotAcademy.playerId, variableId, nil)
    return
  end
  SetNPCBlackboard(pilotAcademy.playerId, variableId, pilotAcademy.wings)
  debug("saveWings: saved " .. tostring(#pilotAcademy.wings) .. " wings to saved data")
  -- Save wings data to persistent storage
end

local function Init()
  pilotAcademy.playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  debug("Initializing Pilot Academy UI extension with PlayerID: " .. tostring(pilotAcademy.playerId))
  local menuMap = Helper.getMenu("MapMenu")
  ---@diagnostic disable-next-line: undefined-field
  if menuMap ~= nil and type(menuMap.registerCallback) == "function" then
    ---@diagnostic disable-next-line: undefined-field
    menuMap.registerCallback("createContextFrame_on_start", function(contextMenuData, contextMenuMode)
      return preAddRowToMapMenuContext(contextMenuData, contextMenuMode, menuMap)
    end)
    menuMap.registerCallback("refreshContextFrame_on_start", function(contextMenuData, contextMenuMode)
      return preAddRowToMapMenuContext(contextMenuData, contextMenuMode, menuMap)
    end)
    menuMap.registerCallback("createContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return addRowToMapMenuContext(contextFrame, contextMenuData, contextMenuMode, menuMap)
    end)
    menuMap.registerCallback("refreshContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return addRowToMapMenuContext(contextFrame, contextMenuData, contextMenuMode, menuMap)
    end)
    debug("Registered callback for Context Frame creation and refresh in MapMenu")
    -- menuMap.registerCallback("createInfoFrame_on_menu_infoTableMode", fcm.createInfoFrame)
  else
    debug("Failed to get MapMenu or registerCallback is not a function")
  end
  local menuPlayerInfo = Helper.getMenu("PlayerInfoMenu")
  ---@diagnostic disable-next-line: undefined-field
  if menuPlayerInfo ~= nil and type(menuPlayerInfo.registerCallback) == "function" then
    ---@diagnostic disable-next-line: undefined-field
    menuPlayerInfo.registerCallback("createContextFrame_on_start", function(contextMenuData, contextMenuMode)
      return preAddRowToPlayerInfoMenuContext(contextMenuData, contextMenuMode, menuPlayerInfo)
    end)
    menuPlayerInfo.registerCallback("refreshContextFrame_on_start", function(contextMenuData, contextMenuMode)
      return preAddRowToPlayerInfoMenuContext(contextMenuData, contextMenuMode, menuPlayerInfo)
    end)
    menuPlayerInfo.registerCallback("createContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return addRowToPlayerInfoMenuContext(contextFrame, contextMenuData, contextMenuMode, menuPlayerInfo)
    end)
    menuPlayerInfo.registerCallback("refreshContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return addRowToPlayerInfoMenuContext(contextFrame, contextMenuData, contextMenuMode, menuPlayerInfo)
    end)
    debug("Registered callback for Context Frame creation and refresh in PlayerInfoMenu")
  else
    debug("Failed to get PlayerInfoMenu or registerCallback is not a function")
  end
  trace(string.format("menuMap is %s and menuPlayerInfo is %s", tostring(menuMap), tostring(menuPlayerInfo)))
  if (menuMap ~= nil and menuPlayerInfo ~= nil) then
    pilotAcademy.Init(menuMap, menuPlayerInfo)
  end
end


Register_OnLoad_Init(Init)
