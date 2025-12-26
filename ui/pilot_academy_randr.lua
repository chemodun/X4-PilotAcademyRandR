local ffi = require("ffi")
local C = ffi.C

ffi.cdef [[
  typedef uint64_t UniverseID;
  typedef uint64_t NPCSeed;

  UniverseID GetPlayerID(void);
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
  wings = {},
  wingIds = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'},
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
  if pilotAcademy.menuMap.infoTableMode == pilotAcademy.academySideBarInfo.mode then

    local menu = pilotAcademy.menuMap
    local config = pilotAcademy.menuMapConfig
    if menu == nil or config == nil then
      trace("Menu or config is nil, cannot create info frame")
      return
    end
    local frame = menu.infoFrame
    local instance = "left"
    local infoTableMode = menu.infoTableMode[instance]
    local tableWing = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
    tableWing:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
    tableWing:setDefaultCellProperties("button", { height = config.mapRowHeight })
    tableWing:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })

    if menu.objectMode == "objectall" then
      menu.objectMode = "pilot_academy_r_and_r"
    end

    local maxNumCategoryColumns = math.floor(menu.infoTableWidth / (menu.sideBarWidth + Helper.borderSize))
    if maxNumCategoryColumns > Helper.maxTableCols then
      maxNumCategoryColumns = Helper.maxTableCols
    end

    local row = tableWing:addRow("pilot_academy_r_and_r_wings_header", { fixed = true })
    row[1]:setColSpan(12):createText("Pilot Academy R&R Wings", { halign = "center", fontsize = config.mapFontSize + 2, bold = true })
    local numdisplayed = 0
    local maxVisibleHeight = tableWing:getFullHeight()

    -- if menu.objectMode == "cheats_player" then
    --   numdisplayed = fcm.createPlayerCheatsSection(table, numdisplayed)
    -- elseif menu.objectMode == "cheats_factions" then
    --   numdisplayed = fcm.createFactionCheatsSection(table, numdisplayed)
    -- elseif menu.objectMode == "cheats_objectspawn" then
    --   numdisplayed = fcm.createObjectSpawnCheatsSection(table, numdisplayed)
    -- end

    local tabsTable = frame:addTable(maxNumCategoryColumns, { tabOrder = 2, reserveScrollBar = false })
    tabsTable:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
    tabsTable:setDefaultCellProperties("button", { height = config.mapRowHeight })
    tabsTable:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })

    if maxNumCategoryColumns > 0 then
      for i = 1, maxNumCategoryColumns do
        tabsTable:setColWidth(i, menu.sideBarWidth, false)
      end
      local diff = menu.infoTableWidth - maxNumCategoryColumns * (menu.sideBarWidth + Helper.borderSize)
      tabsTable:setColWidth(maxNumCategoryColumns, menu.sideBarWidth + diff, false)
      -- object list categories row
      local row = tabsTable:addRow("pilot_academy_r_and_r_tabs", { fixed = true })
      local rowCount = 1
      if pilotAcademy.wings and #pilotAcademy.wings > 0 then
      end
      for i = 1, #pilotAcademy.wings + 1 do
        if i / maxNumCategoryColumns > rowCount then
          row = tabsTable:addRow("pilot_academy_r_and_r_tabs", { fixed = true })
          rowCount = rowCount + 1
        end
        local name = "Add Wing"
        local icon = "pa_icon_add"
        if i <= #pilotAcademy.wings then
          name = string.format("Wing %s", pilotAcademy.wingIds[i]:upper())
          icon = "pa_icon_" .. pilotAcademy.wingIds[i]
        end
        local bgcolor = Color["row_title_background"]
        local color = Color["icon_normal"]
        row[i - math.floor((i - 1) / maxNumCategoryColumns) * maxNumCategoryColumns]
            :createButton({
              height = menu.sideBarWidth,
              width = menu.sideBarWidth,
              bgColor = bgcolor,
              mouseOverText = name,
              scaling = false,
              -- helpOverlayID = entry.helpOverlayID,
              -- helpOverlayText = entry.helpOverlayText,
            })
            :setIcon(icon, { color = color })
        row[i - math.floor((i - 1) / maxNumCategoryColumns) * maxNumCategoryColumns].handlers.onClick = function()
          return true
        end
      end
    end

    -- if numdisplayed > 50 then
    --   table.properties.maxVisibleHeight = maxVisibleHeight + 50 * (Helper.scaleY(config.mapRowHeight) + Helper.borderSize)
    -- end
    menu.numFixedRows = tableWing.numfixedrows

    tableWing:setTopRow(menu.settoprow)
    if menu.infoTable then
      local result = GetShiftStartEndRow(menu.infoTable)
      if result then
        tableWing:setShiftStartEnd(tableWing.unpack(result))
      end
    end
    tableWing:setSelectedRow(menu.sethighlightborderrow or menu.setrow)
    menu.setrow = nil
    menu.settoprow = nil
    menu.setcol = nil
    menu.sethighlightborderrow = nil

    tableWing.properties.y = tabsTable.properties.y + tabsTable:getFullHeight() + Helper.borderSize
  end
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
  end
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
