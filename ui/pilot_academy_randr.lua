local ffi = require("ffi")
local C = ffi.C

ffi.cdef [[
  typedef uint64_t UniverseID;
  typedef uint64_t NPCSeed;

	UniverseID GetPlayerID(void);
]]

local traceEnabled = true

local playerId = nil

function debug(message)
  local text = "Pilot Academy: " .. message
  if type(DebugError) == "function" then
    DebugError(text)
  end
end

function trace(message)
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

local function testAddRowCheck(contextMenuData, contextMenuMode)
  if contextMenuData.person then
    trace("person: " .. ffi.string(C.GetPersonName(contextMenuData.person, contextMenuData.component)) .. ", combinedskill: " .. C.GetPersonCombinedSkill(contextMenuData.component, contextMenuData.person, nil, nil))
  end
  local result = nil
  return result
end

local function testAddRow(contextFrame, contextMenuData, contextMenuMode)
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


local function Init()
  playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  debug("Initializing Pilot Academy UI extension with PlayerID: " .. tostring(playerId))
  local menu = Helper.getMenu("MapMenu")
  ---@diagnostic disable-next-line: undefined-field
  if menu ~= nil and type(menu.registerCallback) == "function" then
    ---@diagnostic disable-next-line: undefined-field
    menu.registerCallback("createContextFrame_on_start", testAddRowCheck)
    menu.registerCallback("refreshContextFrame_on_start", testAddRowCheck)
    menu.registerCallback("createContextFrame_on_end", testAddRow)
    menu.registerCallback("refreshContextFrame_on_end", testAddRow)
    debug("Registered callback for Context Frame creation and refresh")
  else
    debug("Failed to get MapMenu or registerCallback is not a function")
  end
end


Register_OnLoad_Init(Init)
