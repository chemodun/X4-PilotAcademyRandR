local ffi = require("ffi")
local C = ffi.C

ffi.cdef [[
  typedef uint64_t UniverseID;
  typedef uint64_t NPCSeed;

	typedef struct {
		const char* name;
		const char* colorid;
	} RelationRangeInfo;

	typedef struct {
		size_t queueidx;
		const char* state;
		const char* statename;
		const char* orderdef;
		size_t actualparams;
		bool enabled;
		bool isinfinite;
		bool issyncpointreached;
		bool istemporder;
	} Order;

	typedef struct {
		const char* id;
		const char* name;
		const char* desc;
		uint32_t amount;
		uint32_t numtiers;
		bool canhire;
	} PeopleInfo;

  UniverseID GetPlayerID(void);
  RelationRangeInfo GetUIRelationName(const char* fromfactionid, const char* tofactionid);

	uint32_t GetNumAllFactionShips(const char* factionid);
	uint32_t GetAllFactionShips(UniverseID* result, uint32_t resultlen, const char* factionid);

  bool GetDefaultOrder(Order* result, UniverseID controllableid);

	uint32_t CreateOrder(UniverseID controllableid, const char* orderid, bool default);
	bool EnablePlannedDefaultOrder(UniverseID controllableid, bool checkonly);

  void SetFleetName(UniverseID controllableid, const char* fleetname);


	int32_t GetEntityCombinedSkill(UniverseID entityid, const char* role, const char* postid);

	bool IsPerson(NPCSeed person, UniverseID controllableid);
	bool IsPersonTransferScheduled(UniverseID controllableid, NPCSeed person);
  int32_t GetPersonCombinedSkill(UniverseID controllableid, NPCSeed person, const char* role, const char* postid);
	const char* GetPersonName(NPCSeed person, UniverseID controllableid);
	const char* GetPersonRole(NPCSeed person, UniverseID controllableid);
	const char* GetPersonRoleName(NPCSeed person, UniverseID controllableid);
	UniverseID GetInstantiatedPerson(NPCSeed person, UniverseID controllableid);
	bool HasPersonArrived(UniverseID controllableid, NPCSeed person);

	uint32_t GetPeopleCapacity(UniverseID controllableid, const char* macroname, bool includepilot);
  uint32_t GetNumAllRoles(void);
	uint32_t GetPeople2(PeopleInfo* result, uint32_t resultlen, UniverseID controllableid, bool includearriving);

  const char* AssignHiredActor(GenericActor actor, UniverseID targetcontrollableid, const char* postid, const char* roleid, bool checkonly);

	bool HasResearched(const char* wareid);
]]

local traceEnabled = true

local texts = {
  pilotAcademyFull = ReadText(1972092412, 1),                 -- "Pilot Academy: Ranks and Relations"
  pilotAcademy = ReadText(1972092412, 11),                    -- "Pilot Academy R&R"
  wingFleetName = ReadText(1972092412, 111),                  -- "Wing %s of Pilot Academy R&R"
  academySettings = ReadText(1972092412, 10001),              -- "Academy Settings"
  cadetsAndPilots = ReadText(1972092412, 10011),              -- "Cadets and Pilots"
  cadetsAndPilotsTitle = ReadText(1972092412, 10019),         -- "Pilot Academy: Cadets and Pilots"
  wing = ReadText(1972092412, 10021),                         -- "Wing %s"
  addNewWing = ReadText(1972092412, 10029),                   -- "Add new Wing"
  location = ReadText(1972092412, 10101),                     -- "Location:"
  noAvailableLocations = ReadText(1972092412, 10109),         -- "No available locations"
  targetRankLevel = ReadText(1972092412, 10111),              --"Target Rank:",
  autoHire = ReadText(1972092412, 10121),                     -- "Auto hire:"
  assign = ReadText(1972092412, 10131),                       -- "Assign:"
  military_miners_traders = ReadText(1972092412, 10132),      -- "Military - Miners - Traders"
  military_traders_miners = ReadText(1972092412, 10133),      -- "Military - Traders - Miners"
  miners_traders_military = ReadText(1972092412, 10134),      -- "Miners - Traders - Military"
  miners_military_traders = ReadText(1972092412, 10135),      -- "Miners - Military - Traders"
  traders_military_miners = ReadText(1972092412, 10136),      -- "Traders - Military - Miners"
  traders_miners_military = ReadText(1972092412, 10137),      -- "Traders - Miners - Military"
  manual = ReadText(1972092412, 10139),                       -- "Manual"
  priority = ReadText(1972092412, 10141),                     -- "Priority:"
  priority_small_to_large = ReadText(1972092412, 10142),      -- "Small to Large"
  priority_large_to_small = ReadText(1972092412, 10143),      -- "Large to Small"
  cadets = ReadText(1972092412, 10201),                       -- "Cadets:"
  noCadetsAssigned = ReadText(1972092412, 10209),             -- "No cadets assigned"
  pilots = ReadText(1972092412, 10211),                       -- "Pilots:"
  noPilotsAvailable = ReadText(1972092412, 10219),            -- "No pilots available"
  primaryGoal = ReadText(1972092412, 10301),                  -- "Primary Goal:"
  increaseRank = ReadText(1972092412, 10302),                 -- "Increase Rank"
  gainReputation = ReadText(1972092412, 10303),               -- "Gain Reputation"
  noAvailablePrimaryGoals = ReadText(1972092412, 10309),      -- "No available primary goals"
  factions = ReadText(1972092412, 10311),                     -- "Factions:"
  wingLeader = ReadText(1972092412, 10321),                   -- "Wing Leader:"
  noAvailableWingLeaders = ReadText(1972092412, 10329),       -- "No available wing leaders"
  addWingman = ReadText(1972092412, 10331),                   -- "Add Wingman"
  noAvailableWingmanCandidates = ReadText(1972092412, 10339), -- "No available wingman candidates"
  wingmans = ReadText(1972092412, 10341),                     -- "Wingmans:"
  noAvailableWingmans = ReadText(1972092412, 10349),          -- "No wingmans assigned"
  dismissWing = ReadText(1972092412, 10901),                  -- "Dismiss"
  cancel = ReadText(1972092412, 10902),                       -- "Cancel"
  update = ReadText(1972092412, 10903),                       -- "Update"
  create = ReadText(1972092412, 10904),                       -- "Create"
  appointAsCadet = ReadText(1972092412, 20001),                         -- "Appoint as a cadet"
  wingNames = { a = ReadText(1972092412, 100001), b = ReadText(1972092412, 100002), c = ReadText(1972092412, 100003), d = ReadText(1972092412, 100004), e = ReadText(1972092412, 100005), f = ReadText(1972092412, 100006), g = ReadText(1972092412, 100007), h = ReadText(1972092412, 100008), i = ReadText(1972092412, 100009) },
}


local pilotAcademy = {
  playerId = nil,
  menuMap = nil,
  menuMapConfig = {},
  academySideBarInfo = {
    name = texts.pilotAcademy,
    icon = "pa_icon_academy",
    mode = "pilot_academy_r_and_r",
    helpOverlayID = "pilot_academy_r_and_r",
    helpOverlayText = "pilot_academy_r_and_r_help_overlay",
  },
  sideBarIsCreated = false,
  selectedTab = nil,
  minRelationForAcademyStation = 5, -- Neutral
  role = "trainee_group",
  commonData = {},
  wings = {},
  wingsCountMax = 9,
  wingIds = { "a", "b", "c", "d", "e", "f", "g", "h", "i" },
  variableId = "pilotAcademyRAndRData",
  wingsVariableId = "pilotAcademyRAndRWings",
  wingsInfoVariableId = "pilotAcademyRAndRWingsInfo",
  editData = {},
  orderId = "PilotAcademyWing",
  assignOptions = {
    "manual",
    "military_miners_traders",
    "military_traders_miners",
    "miners_traders_military",
    "miners_military_traders",
    "traders_military_miners",
    "traders_miners_military",
  },
  assignPriority = {
    "priority_small_to_large",
    "priority_large_to_small",
  },
  classOrderSmallToLarge = { ship_xl = 4, ship_l = 3, ship_m = 2, ship_s = 1 },
  classOrderLargeToSmall = { ship_xl = 1, ship_l = 2, ship_m = 3, ship_s = 4 },
  lastAutoAssignTime = 0,
  autoAssignCoolDown = 120, -- seconds
}

local config = {}
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

local function hasItemsExcept(table, excludedKey)
  for k, v in pairs(table) do
    if k ~= excludedKey then
      return true -- found at least one other entry
    end
  end
  return false
end

function pilotAcademy.Init(menuMap, menuPlayerInfo)
  trace("pilotAcademy.Init called")
  pilotAcademy.sideBarIsCreated = false
  if menuMap ~= nil and type(menuMap.registerCallback) == "function" and type(menuMap.uix_getConfig) == "function" then
    pilotAcademy.menuMap = menuMap
    pilotAcademy.menuMapConfig = menuMap.uix_getConfig()
    pilotAcademy.menuPlayerInfo = menuPlayerInfo
    pilotAcademy.menuInteractMenu = Helper.getMenu("InteractMenu")
    pilotAcademy.menuInteractMenuConfig = pilotAcademy.menuInteractMenu and pilotAcademy.menuInteractMenu.uix_getConfig() or nil
    menuMap.registerCallback("createSideBar_on_start", pilotAcademy.createSideBar)
    menuMap.registerCallback("createInfoFrame_on_menu_infoTableMode", pilotAcademy.createInfoFrame)
    -- menuMap.registerCallback("utRenaming_setupInfoSubmenuRows_on_end", fcm.setupInfoSubmenuRows)
    menuMap.registerCallback("ic_onSelectElement", pilotAcademy.onSelectElement)
    menuMap.registerCallback("ic_onTableRightMouseClick", pilotAcademy.onTableRightMouseClick)
    menuMap.registerCallback("createContextFrame_on_end", pilotAcademy.createInfoFrameContext)
    pilotAcademy.resetData()
    AddUITriggeredEvent("PilotAcademyRAndR", "Reloaded")
    menuMap.registerCallback("createContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menuMap)
    end)
    menuMap.registerCallback("refreshContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menuMap)
    end)
  end
  if menuPlayerInfo ~= nil and type(menuPlayerInfo.registerCallback) == "function" then
    menuPlayerInfo.registerCallback("createContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menuPlayerInfo)
    end)
    menuPlayerInfo.registerCallback("refreshContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menuPlayerInfo)
    end)
  end
  RegisterEvent("PilotAcademyRAndR.RankLevelReached", pilotAcademy.onRankLevelReached)
  RegisterEvent("PilotAcademyRAndR.PilotReturned", pilotAcademy.onPilotReturned)
  RegisterEvent("PilotAcademyRAndR.RefreshPilots", pilotAcademy.onRefreshPilots)
  pilotAcademy.loadCommonData()
end

function pilotAcademy.resetData()
  pilotAcademy.editData = {}
  pilotAcademy.loadWings()
  pilotAcademy.selectedTab = "settings"
  pilotAcademy.topRows = {
    tableWingsFactions = {},
    tableWingsWingmans = {},
    tableAcademyFactions = nil,
    tablePersonnelCadets = nil,
    tablePersonnelPilots = nil,
  }
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

function pilotAcademy.wingsCount()
  if pilotAcademy.wings == nil or next(pilotAcademy.wings) == nil then
    return 0
  end
  local count = 0
  for _, _ in pairs(pilotAcademy.wings) do
    count = count + 1
  end
  return count
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

  pilotAcademy.loadCommonData()
  pilotAcademy.loadWings()

  local tables = {}
  if pilotAcademy.selectedTab == "settings" then
    tables = pilotAcademy.displayAcademyInfo(frame, menu, config) or {}
  elseif pilotAcademy.selectedTab == "personnel" then
    tables = pilotAcademy.displayPersonnelInfo(frame, menu, config) or {}
  else
    tables = pilotAcademy.displayWingInfo(frame, menu, config) or {}
  end

  local maxNumCategoryColumns = math.floor(menu.infoTableWidth / (menu.sideBarWidth + Helper.borderSize))
  if maxNumCategoryColumns > Helper.maxTableCols then
    maxNumCategoryColumns = Helper.maxTableCols
  end

  local tabsTable = frame:addTable(maxNumCategoryColumns, { tabOrder = 2, reserveScrollBar = false })
  tabsTable:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tabsTable:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tabsTable:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })

  local wingsCountMax = 3
  if C.HasResearched("research_pilot_academy_r_and_r_wings_5") then
    wingsCountMax = 5
  elseif C.HasResearched("research_pilot_academy_r_and_r_wings_9") then
    wingsCountMax = 9
  end

  local academyExists = pilotAcademy.commonData.locationId ~= nil
  if maxNumCategoryColumns > 0 then
    local wingsCount = pilotAcademy.wingsCount()
    local rowCount = 1
    local placesCount = 1
    if wingsCount == wingsCountMax then
      placesCount = wingsCount + 3
    elseif wingsCount == 0 then
      placesCount = academyExists and 4 or 1
    else
      placesCount = wingsCount + 5
    end
    for i = 1, maxNumCategoryColumns do
      local columnWidth = menu.sideBarWidth
      if i == 3 or wingsCount > 0 and i == wingsCount + 4 and wingsCount + 4 < maxNumCategoryColumns then
        columnWidth = math.floor(columnWidth / 2)
      end
      tabsTable:setColWidth(i, columnWidth, false)
    end
    local diff = menu.infoTableWidth - maxNumCategoryColumns * (menu.sideBarWidth + Helper.borderSize)
    tabsTable:setColWidth(maxNumCategoryColumns, menu.sideBarWidth + diff, false)
    -- object list categories row
    local row = tabsTable:addRow("pilot_academy_r_and_r_tabs", { fixed = true })
    local wingIdIndex = 1
    local selector = nil
    for i = 1, placesCount do
      if i / maxNumCategoryColumns > rowCount then
        row = tabsTable:addRow("pilot_academy_r_and_r_tabs", { fixed = true })
        rowCount = rowCount + 1
      end
      if i <= 2 or (i > 3 and i <= wingsCount + 3) or i == placesCount then
        local name = texts.addNewWing
        local icon = "pa_icon_add"
        selector = nil
        if i == 1 then
          name = texts.academySettings
          icon = "pa_icon_tools"
          selector = "settings"
        elseif i == 2 then
          name = texts.cadetsAndPilots
          icon = "pa_icon_personnel"
          selector = "personnel"
        elseif (i > 3 and i <= wingsCount + 3) then
          for j = wingIdIndex, #pilotAcademy.wingIds do
            selector = tostring(pilotAcademy.wingIds[j])
            if pilotAcademy.wings[selector] ~= nil then
              wingIdIndex = j + 1
              break
            end
          end
          name = string.format("Wing %s", texts.wingNames[selector] or "")
          icon = "pa_icon_" .. selector or ""
        end
        local bgColor = Color["row_title_background"]
        if selector == pilotAcademy.selectedTab or i == placesCount and pilotAcademy.selectedTab == nil then
          bgColor = Color["row_background_selected"]
        end
        local color = Color["icon_normal"]
        local currentSelector = selector
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
          return pilotAcademy.buttonSelectTab(currentSelector)
        end
      end
    end
  end

  local topY = tabsTable.properties.y + tabsTable:getFullHeight() + Helper.borderSize
  for i = 1, #tables do
    tables[i].table.properties.y = topY
    topY = topY + tables[i].height
  end
end

function pilotAcademy.sortFactionsAscending(a, b)
  if a.uiRelation == b.uiRelation then
    return a.shortName < b.shortName
  end
  return a.uiRelation < b.uiRelation
end

function pilotAcademy.sortFactionsDescending(a, b)
  if a.uiRelation == b.uiRelation then
    return a.shortName < b.shortName
  end
  return a.uiRelation > b.uiRelation
end

function pilotAcademy.getFactions(config, sortAscending)
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
  if sortAscending then
    table.sort(factions, pilotAcademy.sortFactionsAscending)
  else
    table.sort(factions, pilotAcademy.sortFactionsDescending)
  end
  return factions, maxShortNameWidth, maxRelationNameWidth
end

function pilotAcademy.buttonSelectTab(selector)
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot process buttonSelectTab")
    return
  end
  if selector ~= pilotAcademy.selectedTab then
    pilotAcademy.storeTopRows()
    pilotAcademy.selectedTab = selector or nil
    pilotAcademy.editData = {}

    menu.refreshInfoFrame()
  end
end

function pilotAcademy.storeTopRows()
  if pilotAcademy.selectedTab ~= "settings" then
    pilotAcademy.topRows.tableWingsFactions[tostring(pilotAcademy.selectedTab)] = nil
    pilotAcademy.topRows.tableWingsWingmans[tostring(pilotAcademy.selectedTab)] = nil
  end
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot store table factions top row")
    return
  end

  local infoFrame = menu.infoFrame
  if infoFrame == nil or type(infoFrame.content) ~= "table" or #infoFrame.content == 0 then
    trace("Info frame is nil or has no content; cannot store table factions top row")
    return
  end
  for i = 1, #infoFrame.content do
    local item = infoFrame.content[i]
    if type(item) == "table" and item.type == "table" and item.id ~= nil then
      if item.name == "table_wing_factions" then
        pilotAcademy.topRows.tableWingsFactions[tostring(pilotAcademy.selectedTab)] = GetTopRow(item.id)
      end
      if item.name == "table_wing_wingmans" then
        pilotAcademy.topRows.tableWingsWingmans[tostring(pilotAcademy.selectedTab)] = GetTopRow(item.id)
      end

      if item.name == "table_academy_factions" then
        pilotAcademy.topRows.tableAcademyFactions = GetTopRow(item.id)
      end

      if item.name == "table_personnel_cadets" then
        pilotAcademy.topRows.tablePersonnelCadets = GetTopRow(item.id)
      end

      if item.name == "table_personnel_pilots" then
        pilotAcademy.topRows.tablePersonnelPilots = GetTopRow(item.id)
      end
    end
  end
end

function pilotAcademy.setAcademyContentColumnWidths(tableHandle, menu, config)
  if tableHandle == nil or menu == nil then
    debug("tableWingmans or menu is nil; cannot set column widths")
    return
  end

  local contentWidth = menu.infoTableWidth - Helper.scrollbarWidth * 2 - config.mapRowHeight - Helper.borderSize * 5
  tableHandle:setColWidth(1, Helper.scrollbarWidth + 1, false)
  tableHandle:setColWidth(2, config.mapRowHeight, false)
  tableHandle:setColWidth(3, contentWidth, true)
  tableHandle:setColWidth(4, Helper.scrollbarWidth + 1, false)
end

function pilotAcademy.displayAcademyInfo(frame, menu, config)
  if frame == nil then
    trace("Frame is nil; cannot display wing info")
    return nil
  end
  if menu == nil or config == nil then
    trace("Menu or config is nil; cannot display wing info")
    return nil
  end

  local academyData = pilotAcademy.commonData or {}
  local editData = pilotAcademy.editData or {}
  local tables = {}
  local tableTop = frame:addTable(4, { tabOrder = 2, reserveScrollBar = false })
  tableTop.name = "table_academy_top"
  tableTop:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableTop:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableTop:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setAcademyContentColumnWidths(tableTop, menu, config)
  local row = tableTop:addRow(nil, { fixed = true })
  row[1]:setColSpan(4):createText(texts.pilotAcademyFull, Helper.headerRowCenteredProperties)
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local locationId = editData.locationId or academyData.locationId or nil
  local locationSelectable = locationId == nil or editData.locationId ~= nil and editData.locationId ~= academyData.locationId or
  editData.toChangeLocation == true

  local factions, maxShortNameWidth, maxRelationNameWidth = pilotAcademy.getFactions(config, false)
  local locationOptions = pilotAcademy.fetchPotentialLocations(locationSelectable, academyData.locationId, factions)

  row = tableTop:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.location, { halign = "left", titleColor = Color["row_title"] })
  row = tableTop:addRow("location", { fixed = true })
  row[1]:createText("", { halign = "left" })
  if locationSelectable then
    row[2]:setColSpan(2):createDropDown(
      locationOptions,
      {
        startOption = locationId or -1,
        active = true,
        textOverride = (#locationOptions == 0) and texts.noAvailableLocations or nil,
      }
    )
    row[2]:setTextProperties({ halign = "left" })
    row[2]:setText2Properties({ halign = "right" })
    row[2].handlers.onDropDownConfirmed = function(_, id)
      return pilotAcademy.onSelectLocation(id)
    end
  else
    local isAnyPersonNotArrived = pilotAcademy.isAnyPersonNotArrived()
    row[2]:setColSpan(2):createButton({ active = not isAnyPersonNotArrived }):setText(locationOptions[1].text, { halign = "left" }):setText2(locationOptions[1].text2,
      { halign = "right" })
    row[2].handlers.onClick = function() return pilotAcademy.onToChangeLocation() end
  end
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local targetRankLevel = editData.targetRankLevel or academyData.targetRankLevel or 2
  local maxRankLevel = 2
  if C.HasResearched("research_pilot_academy_r_and_r_3_star") then
    maxRankLevel = 3
  elseif C.HasResearched("research_pilot_academy_r_and_r_4_star") then
    maxRankLevel = 4
  elseif C.HasResearched("research_pilot_academy_r_and_r_5_star") then
    maxRankLevel = 5
  end
  row = tableTop:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.targetRankLevel, { halign = "left", titleColor = Color["row_title"] })
  row = tableTop:addRow("target_rank_level", { fixed = true })
  row[2]:setColSpan(2):createSliderCell({
    height = config.mapRowHeight,
    bgColor = Color["slider_background_transparent"],
    min = 2,
    minSelect = 2,
    max = maxRankLevel,
    maxSelect = maxRankLevel,
    start = targetRankLevel,
    step = 1,
  })
  row[2].handlers.onSliderCellChanged = function(_, val) return pilotAcademy.onSelectTargetRankLevel(val) end
  row[2].handlers.onSliderCellConfirm = function() return menu.refreshInfoFrame() end
  row[2].handlers.onSliderCellActivated = function() menu.noupdate = true end
  row[2].handlers.onSliderCellDeactivated = function() menu.noupdate = false end

  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  local autoHire = editData.autoHire
  if autoHire == nil then
    autoHire = academyData.autoHire
  end

  if autoHire == nil then
    autoHire = false
  end

  local autoHireActive = C.HasResearched("research_pilot_academy_r_and_r_auto_hire")

  row = tableTop:addRow("auto_hire", { fixed = true })
  row[2]:createCheckBox(autoHire == true, { active = autoHireActive and #factions > 0 })
  row[2].handlers.onClick = function(_, checked) return pilotAcademy.onToggleAutoHire(checked) end
  row[3]:createText(texts.autoHire, { halign = "left", titleColor = Color["row_title"] })
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  tables[#tables + 1] = { table = tableTop, height = tableTop:getFullHeight() }

  if #factions > 0 and autoHire == true then
    local tableFactionsMaxHeight = 0

    local tableFactions = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
    tableFactions.name = "table_academy_factions"
    tableFactions:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
    tableFactions:setDefaultCellProperties("button", { height = config.mapRowHeight })
    tableFactions:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
    pilotAcademy.setInfoContentColumnWidths(tableFactions, menu, config, maxShortNameWidth, maxRelationNameWidth)
    local selectedFactions = pilotAcademy.combineFactionsSelections(editData, academyData)
    for i = 1, #factions do
      local faction = factions[i]
      if faction ~= nil then
        local row = tableFactions:addRow(faction.id, { fixed = false })
        row[2]:createCheckBox(selectedFactions[faction.id] == true, { scaling = false })
        row[2].handlers.onClick = function(_, checked) return pilotAcademy.onSelectFaction(faction.id, checked, academyData) end
        row[3]:createIcon(faction.icon, { height = config.mapRowHeight, width = config.mapRowHeight, color = Color[faction.colorId] or Color["text_normal"] })
        row[4]:createText(string.format("[%s]", faction.shortName), { halign = "center", color = Color[faction.colorId] or Color["text_normal"] })
        row[5]:createText("-", { halign = "center", color = Color[faction.colorId] or Color["text_normal"] })
        row[6]:setColSpan(4):createText(faction.name, { halign = "left", color = Color[faction.colorId] or Color["text_normal"] })
        row[10]:createText(faction.relationName, { halign = "left", color = Color[faction.colorId] or Color["text_normal"] })
        row[11]:createText(string.format("(%+2d)", faction.uiRelation), { halign = "right", color = Color[faction.colorId] or Color["text_normal"] })
        if i == 10 then
          tableFactionsMaxHeight = tableFactions:getFullHeight()
        end
      end
    end
    if tableFactionsMaxHeight == 0 then
      tableFactionsMaxHeight = tableFactions:getFullHeight()
    end
    tableFactions.properties.maxVisibleHeight = math.min(tableFactions:getFullHeight(), tableFactionsMaxHeight)
    tables[#tables + 1] = { table = tableFactions, height = tableFactions.properties.maxVisibleHeight }

    if pilotAcademy.topRows.tableAcademyFactions ~= nil then
      tableFactions:setTopRow(pilotAcademy.topRows.tableAcademyFactions)
    end
  end
  pilotAcademy.topRows.tableAcademyFactions = nil

  local tableAssign = frame:addTable(4, { tabOrder = 2, reserveScrollBar = false })
  tableAssign.name = "table_academy_top"
  tableAssign:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableAssign:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableAssign:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setAcademyContentColumnWidths(tableAssign, menu, config)
  tableAssign:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  local assign = editData.assign or academyData.assign or "manual"
  local assignOptions = pilotAcademy.getAssignOptions()
  local autoAssignActive = C.HasResearched("research_pilot_academy_r_and_r_auto_assign")

  row = tableAssign:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.assign, { halign = "left", titleColor = Color["row_title"] })
  row = tableAssign:addRow("location", { fixed = true })
  row[1]:createText("", { halign = "left" })
  row[2]:setColSpan(2):createDropDown(
    assignOptions,
    {
      startOption = assign or "manual",
      active = autoAssignActive,
      textOverride = (#locationOptions == 0) and "" or nil,
    }
  )
  row[2]:setTextProperties({ halign = "left" })
  row[2].handlers.onDropDownConfirmed = function(_, id)
    return pilotAcademy.onSelectAssign(id)
  end

  if assign ~= "manual" then
    local assignPriority = editData.assignPriority or academyData.assignPriority or "priority_small_to_large"
    local priorityOptions = pilotAcademy.getAssignPriorityOptions()
    tableAssign:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
    row = tableAssign:addRow(nil, { fixed = true })
    row[2]:setColSpan(2):createText(texts.priority, { halign = "left", titleColor = Color["row_title"] })
    row = tableAssign:addRow("assign_priority", { fixed = true })
    row[1]:createText("", { halign = "left" })
    row[2]:setColSpan(2):createDropDown(
      priorityOptions,
      {
        startOption = assignPriority or "priority_small_to_large",
        active = true,
        textOverride = (#priorityOptions == 0) and "" or nil,
      }
    )
    row[2]:setTextProperties({ halign = "left" })
    row[2].handlers.onDropDownConfirmed = function(_, id)
      return pilotAcademy.onSelectAssignPriority(id)
    end
  end

  tables[#tables + 1] = { table = tableAssign, height = tableAssign:getFullHeight() }

  local tableBottom = frame:addTable(7, { tabOrder = 2, reserveScrollBar = false })
  tableBottom.name = "table_wing_bottom"
  tableBottom:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableBottom:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableBottom:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setButtonsColumnWidths(tableBottom, menu, config)
  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  row = tableBottom:addRow("buttons", { fixed = true })

  row[4]:createButton({ active = next(editData) ~= nil }):setText(texts.cancel, { halign = "center" })
  row[4].handlers.onClick = function() return pilotAcademy.buttonCancelAcademyChanges() end

  row[6]:createButton({ active = hasItemsExcept(editData, "toChangeLocation") and locationId ~= nil }):setText(
    academyData.locationId ~= nil and texts.update or texts.create,
    { halign = "center" })
  row[6].handlers.onClick = function() return pilotAcademy.buttonSaveAcademy() end

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  tables[#tables + 1] = { table = tableBottom, height = tableBottom:getFullHeight() }
  return tables
end

function pilotAcademy.fetchPotentialLocations(selectable, currentLocationId, factions)
  local locations = {}
  local stations = {}
  if selectable then
    local numOwnedStations = C.GetNumAllFactionStations("player")
    local allOwnedStations = ffi.new("UniverseID[?]", numOwnedStations)
    numOwnedStations = C.GetAllFactionStations(allOwnedStations, numOwnedStations, "player")
    if numOwnedStations > 0 then
      for i = 0, numOwnedStations - 1 do
        local stationId = ConvertStringTo64Bit(tostring(allOwnedStations[i]))
        local isUnderConstruction = IsComponentConstruction(stationId)
        if not isUnderConstruction then
          stations[#stations + 1] = pilotAcademy.getStationInfo(stationId)
        end
      end
    end
    if --[[ #stations == 0 and ]] #factions > 0 then
      for i = 1, #factions do
        local faction = factions[i]
        local relation = GetUIRelation(faction.id)
        if relation < pilotAcademy.minRelationForAcademyStation then
          break
        end
        local numOwnedStations = C.GetNumAllFactionStations(faction.id)
        local allOwnedStations = ffi.new("UniverseID[?]", numOwnedStations)
        numOwnedStations = C.GetAllFactionStations(allOwnedStations, numOwnedStations, faction.id)
        if numOwnedStations > 0 then
          for i = 0, numOwnedStations - 1 do
            local stationId = ConvertStringTo64Bit(tostring(allOwnedStations[i]))
            local isUnderConstruction = IsComponentConstruction(stationId)
            if not isUnderConstruction then
              local name, isShipyard, isWharf, isEquipmentDock, isTradeStation = GetComponentData(stationId, "name", "isshipyard", "iswharf", "isequipmentdock",
                "istradestation")
              if name ~= nil and (isShipyard == true or isWharf == true or isEquipmentDock == true or isTradeStation == true) then
                stations[#stations + 1] = pilotAcademy.getStationInfo(stationId)
              end
            end
          end
        end
      end
    end
  else
    local station = pilotAcademy.getStationInfo(currentLocationId)
    stations = { station }
  end
  table.sort(stations, pilotAcademy.sortStationsDescending)
  for i = 1, #stations do
    local station = stations[i]
    if station ~= nil then
      locations[#locations + 1] = {
        id = station.id,
        icon = "",
        text = string.format("%s\027[%s] %s (%s)", station.color, station.icon, pilotAcademy.formatName(station.name, 40), station.idCode),
        text2 = station.sector,
        displayremoveoption = false,
      }
    end
  end
  return locations
end

function pilotAcademy.getStationInfo(stationId)
  local name, faction, icon, idCode, sector = GetComponentData(stationId, "name", "owner", "icon", "idcode", "sector")
  local color = Helper.convertColorToText(GetFactionData(faction, "color"))
  return {
    id = stationId,
    color = color,
    uiRelation = GetUIRelation(faction),
    name = name,
    idCode = idCode,
    sector = sector,
    icon = icon,
  }
end

function pilotAcademy.sortStationsDescending(a, b)
  if a.uiRelation == b.uiRelation then
    return a.name < b.name
  end
  return a.uiRelation > b.uiRelation
end

function pilotAcademy.onSelectLocation(locationId)
  trace("Selected location ID: " .. tostring(locationId))
  pilotAcademy.editData.locationId = locationId
  pilotAcademy.editData.toChangeLocation = false
  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
end

function pilotAcademy.onToChangeLocation()
  trace("Changing academy location")
  pilotAcademy.editData.toChangeLocation = true
  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
end

function pilotAcademy.onSelectTargetRankLevel(level)
  trace("onSelectTargetRankLevel called with level: " .. tostring(level))
  if level == nil then
    trace("level is nil; cannot process")
    return
  end
  pilotAcademy.editData.targetRankLevel = level
end

function pilotAcademy.onSelectFaction(factionId, isSelected, savedData)
  trace("onSelectFaction called with factionId: " .. tostring(factionId) .. ", isSelected: " .. tostring(isSelected))
  if factionId == nil then
    trace("factionId is nil; cannot process")
    return
  end
  if pilotAcademy.editData.factions == nil or type(pilotAcademy.editData.factions) ~= "table" then
    pilotAcademy.editData.factions = savedData.factions ~= nil and type(savedData.factions) == "table" and savedData.factions or {}
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
  pilotAcademy.storeTopRows()
  menu.refreshInfoFrame()
end

function pilotAcademy.onToggleAutoHire(checked)
  trace("Toggled auto hire: " .. tostring(checked))
  pilotAcademy.editData.autoHire = checked
  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
end

function pilotAcademy.getAssignOptions()
  local options = {}
  for i = 1, #pilotAcademy.assignOptions do
    local priority = pilotAcademy.assignOptions[i]
    options[#options + 1] = { id = priority, icon = "", text = texts[priority], text2 = "", displayremoveoption = false }
  end
  return options
end

function pilotAcademy.onSelectAssign(priority)
  trace("Selected assign priority: " .. tostring(priority))
  pilotAcademy.editData.assign = priority
  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
end

function pilotAcademy.getAssignPriorityOptions()
  local options = {}
  for i = 1, #pilotAcademy.assignPriority do
    local shipClass = pilotAcademy.assignPriority[i]
    options[#options + 1] = { id = shipClass, icon = "", text = texts[shipClass], text2 = "", displayremoveoption = false }
  end
  return options
end

function pilotAcademy.onSelectAssignPriority(priority)
  trace("Selected assign priority: " .. tostring(priority))
  pilotAcademy.editData.assignPriority = priority
  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
end

function pilotAcademy.buttonCancelAcademyChanges()
  trace("Cancelling academy changes")
  pilotAcademy.editData = {}
  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
end

function pilotAcademy.buttonSaveAcademy()
  trace("Saving academy changes")
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot save academy changes")
    return
  end

  local academyData = pilotAcademy.commonData or {}
  local editData = pilotAcademy.editData or {}

  if editData.locationId ~= nil then
    local newLocationId = ConvertStringTo64Bit(tostring(editData.locationId))
    pilotAcademy.transferPersonnel(academyData.locationId, newLocationId)
    academyData.locationId = newLocationId
  end
  if academyData.locationId ~= nil then
    academyData.locationObject = ConvertStringToLuaID(tostring(academyData.locationId))
  end
  local rankLevelChanged = false
  if editData.targetRankLevel ~= nil then
    if editData.targetRankLevel ~= academyData.targetRankLevel then
      trace("Setting target rank level to " .. tostring(editData.targetRankLevel))
      rankLevelChanged = true
    end
    academyData.targetRankLevel = editData.targetRankLevel
  end
  if academyData.targetRankLevel == nil then
    academyData.targetRankLevel = 2
  end

  if editData.autoHire ~= nil then
    academyData.autoHire = editData.autoHire
  end
  if academyData.autoHire == nil then
    academyData.autoHire = false
  end

  if editData.factions ~= nil then
    academyData.factions = editData.factions
  end
  if academyData.factions == nil then
    academyData.factions = {}
  end

  if editData.assign ~= nil then
    academyData.assign = editData.assign
  end
  if academyData.assign == nil then
    academyData.assign = "manual"
  end

  if editData.assignPriority ~= nil then
    academyData.assignPriority = editData.assignPriority
  end
  if academyData.assignPriority == nil then
    academyData.assignPriority = "priority_small_to_large"
  end

  pilotAcademy.editData = {}

  pilotAcademy.saveCommonData()
  if rankLevelChanged then
    SignalObject(pilotAcademy.playerId, "AcademyTargetRankLevelChanged")
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.transferPersonnel(oldLocationId, newLocationId)
  if oldLocationId == nil or newLocationId == nil then
    trace("Old or new location ID is nil; cannot transfer personnel")
    return
  end
  if oldLocationId == newLocationId then
    trace("Old and new location IDs are the same; no transfer needed")
    return
  end
  local personnel = pilotAcademy.fetchAcademyPersonnel(true)
  for i = 1, #personnel do
    local person = personnel[i]
    if person ~= nil and person.hasArrived == true and not person.transferScheduled then
      local actor = { entity = nil, personcontrollable = oldLocationId, personseed = person.id }
      if not GetComponentData(oldLocationId, "isplayerowned") then
        local entity = pilotAcademy.getOrCreateEntity(person.id, oldLocationId)
        actor = { entity = entity, personcontrollable = nil, personseed = nil }
      end
      pilotAcademy.appointAsCadet(actor, newLocationId)
    end
  end
end

function pilotAcademy.setNPCOwnedByPlayer(entity)
  local entityId = ConvertStringTo64Bit(tostring(entity))
  if not GetComponentData(entityId, "isplayerowned") then
    C.SetComponentOwner(entityId, "player")
  end
end

function pilotAcademy.getOrCreateEntity(person, controllable)
  local entity = C.GetInstantiatedPerson(person, controllable)
  trace("Retrieved entity for person: " .. tostring(entity))
  if entity == 0 or entity == nil then
    entity = C.CreateNPCFromPerson(person, controllable)
    trace("Created entity for person: " .. tostring(entity))
  end
  return entity
end

function pilotAcademy.combineFactionsSelections(editData, savedData)
  local selectedFactions = {}
  if editData.factions ~= nil and type(editData.factions) == "table" then
    for _, factionId in ipairs(editData.factions) do
      selectedFactions[factionId] = true
    end
  elseif savedData.factions ~= nil and type(savedData.factions) == "table" then
    for _, factionId in ipairs(savedData.factions) do
      selectedFactions[factionId] = true
    end
  end
  return selectedFactions
end

function pilotAcademy.skillBase(skill)
  return skill * 15.0 / 300
end

function pilotAcademy.displayPersonnelInfo(frame, menu, config)
  if frame == nil then
    trace("Frame is nil; cannot display wing info")
    return nil
  end
  if menu == nil or config == nil then
    trace("Menu or config is nil; cannot display wing info")
    return nil
  end

  local tables = {}
  local tableTop = frame:addTable(4, { tabOrder = 2, reserveScrollBar = false })
  tableTop.name = "table_personnel_top"
  tableTop:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableTop:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableTop:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setAcademyContentColumnWidths(tableTop, menu, config)
  local row = tableTop:addRow(nil, { fixed = true })
  row[1]:setColSpan(4):createText(texts.cadetsAndPilotsTitle, Helper.headerRowCenteredProperties)

  tables[#tables + 1] = { table = tableTop, height = tableTop:getFullHeight() }

  local cadets, pilots = pilotAcademy.fetchAcademyPersonnel()

  local tableCadets = frame:addTable(4, { tabOrder = 2, reserveScrollBar = false })
  tableCadets.name = "table_personnel_cadets"
  pilotAcademy.fillPersonnelTable(tableCadets, cadets, texts.cadets, menu, config, tables)

  local tablePilots = frame:addTable(4, { tabOrder = 2, reserveScrollBar = false })
  tablePilots.name = "table_personnel_pilots"
  pilotAcademy.fillPersonnelTable(tablePilots, pilots, texts.pilots, menu, config, tables)

  local tableBottom = frame:addTable(4, { tabOrder = 2, reserveScrollBar = false })
  tableBottom.name = "table_personnel_bottom"
  tableBottom:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableBottom:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableBottom:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setAcademyContentColumnWidths(tableBottom, menu, config)
  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  tables[#tables + 1] = { table = tableBottom, height = tableBottom:getFullHeight() }

  return tables
end

function pilotAcademy.fillPersonnelTable(tablePersonnel, personnel, title, menu, config, tables)
  tablePersonnel:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tablePersonnel:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tablePersonnel:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setAcademyContentColumnWidths(tablePersonnel, menu, config)
  tablePersonnel:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tablePersonnel:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(title, Helper.headerRowCenteredProperties)
  local tablePersonnelMaxHeight = 0
  for i = 1, #personnel do
    local person = personnel[i]
    if person ~= nil then
      local row = tablePersonnel:addRow({ tableName = tablePersonnel.name, rowData = person }, { fixed = false })
      local icon = row[2]:setColSpan(2):createIcon(person.icon, { height = config.mapRowHeight, width = config.mapRowHeight, color = person.hasArrived and Color["text_normal"] or Color["text_inactive"] })
      icon:setText(person.name, { x = config.mapRowHeight, halign = "left", color = person.hasArrived and Color["text_normal"] or Color["text_inactive"] })
      icon:setText2(person.skillInStars, { halign = "right", color = person.hasArrived and Color["text_skills"] or Color["text_inactive"] })

      if i == 15 then
        tablePersonnelMaxHeight = tablePersonnel:getFullHeight()
      end
    end
  end

  if #personnel == 0 then
    local row = tablePersonnel:addRow(nil, { fixed = false })
    row[2]:setColSpan(2):createText(title == texts.pilots and texts.noPilotsAvailable or texts.noCadetsAssigned, { halign = "center", color = Color["text_warning"] })
  else
    if pilotAcademy.topRows.tablePersonnelPilots ~= nil then
      tablePersonnel:setTopRow(pilotAcademy.topRows.tablePersonnelPilots)
    end
  end
  pilotAcademy.topRows.tablePersonnelPilots = nil
  if tablePersonnelMaxHeight == 0 then
    tablePersonnelMaxHeight = tablePersonnel:getFullHeight()
  end
  tablePersonnel.properties.maxVisibleHeight = math.min(tablePersonnel:getFullHeight(), tablePersonnelMaxHeight)
  tables[#tables + 1] = { table = tablePersonnel, height = tablePersonnel.properties.maxVisibleHeight }
end

function pilotAcademy.fetchAcademyPersonnel(toOneTable, onlyArrived)
  local cadets = {}
  local pilots = {}
  toOneTable = toOneTable or false
  if pilotAcademy.commonData == nil then
    trace("commonData is nil; cannot get cadets list")
    return cadets, pilots
  end
  if pilotAcademy.commonData.locationId == nil then
    trace("locationId is nil; cannot get cadets list")
    return cadets, pilots
  end

  local locationId = pilotAcademy.commonData.locationId
  local isPlayerOwned = GetComponentData(locationId, "isplayerowned")
  local capacity = C.GetPeopleCapacity(locationId, "", false)
  trace("Cadet capacity at location " .. tostring(locationId) .. " is " .. tostring(capacity))
  if capacity == nil or capacity <= 0 then
    trace("No capacity; returning empty cadets list")
    return cadets, pilots
  end

  local numRoles = C.GetNumAllRoles()
  local rolesTable = ffi.new("PeopleInfo[?]", numRoles)
  numRoles = C.GetPeople2(rolesTable, numRoles, locationId, true)
  for i = 0, numRoles - 1 do
    local role = rolesTable[i]
    local roleId = ffi.string(role.id)
    trace("Processing role ID: " .. tostring(roleId) .. " with amount: " .. tostring(role.amount))
    if roleId == pilotAcademy.role and role.amount > 0 then
      local personsTable = GetRoleTierNPCs(locationId, roleId, 0)
      for j = 1, #personsTable do
        local person = personsTable[j]
        if person ~= nil then
          local personId = C.ConvertStringTo64Bit(tostring(person.seed))
          local skill = C.GetPersonCombinedSkill(locationId, personId, nil, "aipilot")
          trace("Found person: " .. tostring(person.name) .. " with skill: " .. tostring(skill))
          local skillBase = pilotAcademy.skillBase(skill)
          local skillInStars = string.format("%s", Helper.displaySkill(skill * 15 / 100))
          local transferScheduled = C.IsPersonTransferScheduled(locationId, personId)
          local hasArrived = C.HasPersonArrived(locationId, personId)
          local entity = nil
          if isPlayerOwned ~= true and hasArrived == true then
            trace("Person has arrived at non-player-owned location; checking entity ownership")
            entity = pilotAcademy.getOrCreateEntity(personId, locationId)
            if entity ~= nil then
              pilotAcademy.setNPCOwnedByPlayer(entity)
            end
          end
          if transferScheduled ~= true and (not onlyArrived or hasArrived) then
            if toOneTable or skillBase - pilotAcademy.commonData.targetRankLevel < 0 then
              cadets[#cadets + 1] = {
                id = personId,
                name = person.name,
                icon = "pa_icon_cadet",
                skill = skill,
                skillInStars = skillInStars,
                transferScheduled = transferScheduled,
                hasArrived = hasArrived,
                entity = entity
              }
            else
              pilots[#pilots + 1] = {
                id = personId,
                name = person.name,
                icon = "pa_icon_pilot",
                skill = skill,
                skillInStars = skillInStars,
                transferScheduled = transferScheduled,
                hasArrived = hasArrived,
                entity = entity
              }
            end
          end
        end
      end
    end
  end
  if not toOneTable then
    table.sort(cadets, pilotAcademy.sortCadets)
    table.sort(pilots, pilotAcademy.sortPilots)
  end
  return cadets, pilots
end

function pilotAcademy.sortCadets(a, b)
  if a.skill == b.skill then
    return a.name < b.name
  end
  return a.skill < b.skill
end

function pilotAcademy.sortPilots(a, b)
  if a.skill == b.skill then
    return a.name < b.name
  end
  return a.skill > b.skill
end


function pilotAcademy.isAnyPersonNotArrived()
  if pilotAcademy.commonData == nil then
    trace("commonData is nil; returning false")
    return false
  end
  if pilotAcademy.commonData.locationId == nil then
    trace("locationId is nil; returning false")
    return false
  end

  local locationId = pilotAcademy.commonData.locationId
  local capacity = C.GetPeopleCapacity(locationId, "", false)
  trace("Cadet capacity at location " .. tostring(locationId) .. " is " .. tostring(capacity))
  if capacity == nil or capacity <= 0 then
    trace("No capacity; returning false")
    return false
  end

  local numRoles = C.GetNumAllRoles()
  local rolesTable = ffi.new("PeopleInfo[?]", numRoles)
  numRoles = C.GetPeople2(rolesTable, numRoles, locationId, true)
  for i = 0, numRoles - 1 do
    local role = rolesTable[i]
    local roleId = ffi.string(role.id)
    trace("Processing role ID: " .. tostring(roleId) .. " with amount: " .. tostring(role.amount))
    if roleId == pilotAcademy.role and role.amount > 0 then
      local amount = role.amount
      local personsTable = GetRoleTierNPCs(locationId, roleId, 0)
      for j = 1, #personsTable do
        local person = personsTable[j]
        if person ~= nil then
          local personId = C.ConvertStringTo64Bit(tostring(person.seed))
          local hasArrived = C.HasPersonArrived(locationId, personId)
          if hasArrived ~= true then
            return true
          end
        end
      end
    end
  end
  return false
end

function pilotAcademy.loadCommonData()
  pilotAcademy.commonData = {}
  if pilotAcademy.playerId == nil or pilotAcademy.playerId == 0 then
    debug("loadCommonData: unable to resolve player id")
    return
  end
  local variableId = string.format("$%s", pilotAcademy.variableId)
  local savedData = GetNPCBlackboard(pilotAcademy.playerId, variableId)
  if savedData == nil or type(savedData) ~= "table" then
    debug("loadCommonData: no saved common data found, initializing empty common data")
    return
  end
  pilotAcademy.commonData = savedData or {}
  debug("loadCommonData: loaded common data from saved data")
  if pilotAcademy.commonData.locationObject ~= nil then
    pilotAcademy.commonData.locationId = ConvertStringTo64Bit(tostring(pilotAcademy.commonData.locationObject))
  end

  if pilotAcademy.commonData.autoHire == 0 then
    pilotAcademy.commonData.autoHire = false
  elseif pilotAcademy.commonData.autoHire == 1 then
    pilotAcademy.commonData.autoHire = true
  end

  debug("loadCommonData: locationId is " .. tostring(pilotAcademy.commonData.locationId))
end

function pilotAcademy.saveCommonData()
  if pilotAcademy.playerId == nil or pilotAcademy.playerId == 0 then
    debug("saveCommonData: unable to resolve player id")
    return
  end
  local variableId = string.format("$%s", pilotAcademy.variableId)
  if pilotAcademy.commonData == nil or type(pilotAcademy.commonData) ~= "table" or next(pilotAcademy.commonData) == nil then
    debug("saveCommonData: no common data to save, going to clear saved data")
    SetNPCBlackboard(pilotAcademy.playerId, variableId, {})
    return
  end
  SetNPCBlackboard(pilotAcademy.playerId, variableId, pilotAcademy.commonData)
  debug("saveCommonData: saved common data to saved data")
  -- Save common data to persistent storage
end

function pilotAcademy.setInfoContentColumnWidths(tableHandle, menu, config, maxShortNameWidth, maxRelationNameWidth)
  if tableHandle == nil or menu == nil then
    debug("tableWingmans or menu is nil; cannot set column widths")
    return
  end
  tableHandle:setColWidth(1, Helper.scrollbarWidth + 1, false)
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
  tableHandle:setColWidth(12, Helper.scrollbarWidth + 1, false)
end

function pilotAcademy.setButtonsColumnWidths(tableHandle, menu, config)
  if tableHandle == nil or menu == nil then
    debug("tableWingmans or menu is nil; cannot set column widths")
    return
  end

  local buttonWidth = math.floor((menu.infoTableWidth - Helper.scrollbarWidth * 5 - 2) / 3)
  tableHandle:setColWidth(1, Helper.scrollbarWidth + 1, true)
  for i = 2, 6 do
    if i % 2 == 0 then
      tableHandle:setColWidth(i, buttonWidth, false)
    else
      tableHandle:setColWidth(i, Helper.scrollbarWidth, false)
    end
  end
  tableHandle:setColWidth(7, Helper.scrollbarWidth + 1, true)
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
  tableTop.name = "table_wing_top"
  tableTop:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableTop:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableTop:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  local wings = pilotAcademy.wings or {}
  local wingId = pilotAcademy.selectedTab
  local existingWing = wingId ~= nil and wings[wingId] ~= nil
  local factions, maxShortNameWidth, maxRelationNameWidth = pilotAcademy.getFactions(config, true)
  -- local factionsSorted =
  pilotAcademy.setInfoContentColumnWidths(tableTop, menu, config, maxShortNameWidth, maxRelationNameWidth)
  local wingData = existingWing and wings[wingId] or {}
  local editData = pilotAcademy.editData or {}
  local primaryGoal = editData.primaryGoal or wingData.primaryGoal or "rank"
  local selectedFactions = pilotAcademy.combineFactionsSelections(editData, wingData)

  local wingLeaderId = editData.wingLeaderId or wingData.wingLeaderId or nil

  local row = tableTop:addRow(nil, { fixed = true })
  local suffix = string.format(pilotAcademy.selectedTab ~= nil and texts.wing or texts.addNewWing,
    existingWing and texts.wingNames[pilotAcademy.selectedTab] or "")
  row[1]:setColSpan(12):createText(string.format("%s: %s", texts.pilotAcademy, suffix), Helper.headerRowCenteredProperties)
  tableTop:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableTop:addRow("wing_primary_goal", { fixed = true })
  local primaryGoalOptions = {
    { id = "rank",     icon = "", text = texts.increaseRank,   text2 = "", displayremoveoption = false },
    { id = "relation", icon = "", text = texts.gainReputation, text2 = "", displayremoveoption = false },
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
  tables[#tables + 1] = { table = tableTop, height = tableTop:getFullHeight() }

  local tableFactions = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
  tableFactions.name = "table_wing_factions"
  tableFactions:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableFactions:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableFactions:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setInfoContentColumnWidths(tableFactions, menu, config, maxShortNameWidth, maxRelationNameWidth)
  local row = tableFactions:addRow(nil, { fixed = true })
  row[2]:setColSpan(10):createText(texts.factions, { halign = "left", titleColor = Color["row_title"] })
  local tableFactionMaxHeight = 0
  for i = 1, #factions do
    local faction = factions[i]
    if faction ~= nil then
      local row = tableFactions:addRow(faction.id, { fixed = false })
      row[2]:createCheckBox(selectedFactions[faction.id] == true, { scaling = false })
      row[2].handlers.onClick = function(_, checked) return pilotAcademy.onSelectFaction(faction.id, checked, wingData) end
      row[3]:createIcon(faction.icon, { height = config.mapRowHeight, width = config.mapRowHeight, color = Color[faction.colorId] or Color["text_normal"] })
      row[4]:createText(string.format("[%s]", faction.shortName), { halign = "center", color = Color[faction.colorId] or Color["text_normal"] })
      row[5]:createText("-", { halign = "center", color = Color[faction.colorId] or Color["text_normal"] })
      row[6]:setColSpan(4):createText(faction.name, { halign = "left", color = Color[faction.colorId] or Color["text_normal"] })
      row[10]:createText(faction.relationName, { halign = "left", color = Color[faction.colorId] or Color["text_normal"] })
      row[11]:createText(string.format("(%+2d)", faction.uiRelation), { halign = "right", color = Color[faction.colorId] or Color["text_normal"] })
      if i == 15 then
        tableFactionMaxHeight = tableFactions:getFullHeight()
      end
    end
  end
  if tableFactionMaxHeight == 0 then
    tableFactionMaxHeight = tableFactions:getFullHeight()
  end
  tableFactions.properties.maxVisibleHeight = math.min(tableFactions:getFullHeight(), tableFactionMaxHeight)
  tables[#tables + 1] = { table = tableFactions, height = tableFactions.properties.maxVisibleHeight }

  local wingKey = tostring(pilotAcademy.selectedTab)
  if #factions > 0 then
    if pilotAcademy.topRows.tableWingsFactions[wingKey] ~= nil then
      tableFactions:setTopRow(pilotAcademy.topRows.tableWingsFactions[wingKey])
    end
  end
  pilotAcademy.topRows.tableWingsFactions[wingKey] = nil

  local tableWingLeader = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
  tableWingLeader.name = "table_wing_wing_leader"
  tableWingLeader:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableWingLeader:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableWingLeader:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setInfoContentColumnWidths(tableWingLeader, menu, config, maxShortNameWidth, maxRelationNameWidth)
  tableWingLeader:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableWingLeader:addRow(nil, { fixed = true })
  local wingLeaderOptions = pilotAcademy.fetchPotentialWingmans(existingWing, wingLeaderId)
  row[2]:setColSpan(10):createText(texts.wingLeader, { halign = "left", titleColor = Color["row_title"] })
  if existingWing then
    local leaderInfo = wingLeaderOptions[1] or {}
    row = tableWingLeader:addRow({ tableName = tableWingLeader.name, rowData = leaderInfo }, { fixed = false })
    row[1]:createText("", { halign = "left" })
    local icon = row[2]:setColSpan(10):createIcon("order_pilotacademywing", { height = config.mapRowHeight, width = config.mapRowHeight })
    icon:setText(leaderInfo.text, { x = config.mapRowHeight, halign = "left", color = Color["text_normal"] })
    icon:setText2(leaderInfo.text2, { halign = "right", color = Color["text_skills"] })
  else
    row = tableWingLeader:addRow("wing_leader", { fixed = true })
    row[1]:createText("", { halign = "left" })
    row[2]:setColSpan(10):createDropDown(
      wingLeaderOptions,
      {
        startOption = wingLeaderId or -1,
        active = not existingWing,
        textOverride = (#wingLeaderOptions == 0) and texts.noAvailableWingLeaders or nil,
      }
    )
    row[2]:setTextProperties({ halign = "left" })
    row[2]:setText2Properties({ halign = "right", color = Color["text_skills"] })
    row[2].handlers.onDropDownConfirmed = function(_, id)
      return pilotAcademy.onSelectWingLeader(id)
    end
  end
  tables[#tables + 1] = { table = tableWingLeader, height = tableWingLeader:getFullHeight() }

  local tableWingmans = frame:addTable(12, { tabOrder = 2, reserveScrollBar = false })
  tableWingmans.name = "table_wing_wingmans"
  tableWingmans:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableWingmans:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableWingmans:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setInfoContentColumnWidths(tableWingmans, menu, config, maxShortNameWidth, maxRelationNameWidth)
  tableWingmans:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local tableWingmansMaxHeight = 0
  local wingmans = {}
  local mimicGroupId = nil
  if existingWing then
    row = tableWingmans:addRow(nil, { fixed = true })
    row[2]:setColSpan(10):createText(texts.addWingman, { halign = "left", titleColor = Color["row_title"] })
    local addWingmanOptions = pilotAcademy.fetchPotentialWingmans(existingWing, nil)
    mimicGroupId, wingmans = pilotAcademy.fetchWingmans(wingLeaderId)
    row = tableWingmans:addRow("add_wingman", { fixed = true })
    row[1]:createText("", { halign = "left" })
    row[2]:setColSpan(10):createDropDown(
      addWingmanOptions,
      {
        startOption = wingLeaderId or -1,
        active = existingWing,
        textOverride = (#addWingmanOptions == 0) and texts.noAvailableWingmanCandidates or nil,
      }
    )
    row[2]:setTextProperties({ halign = "left" })
    row[2]:setText2Properties({ halign = "right", color = Color["text_skills"] })
    row[2].handlers.onDropDownConfirmed = function(_, id)
      return pilotAcademy.onSelectWingman(id, wingLeaderId, mimicGroupId)
    end
    tableWingmans:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
    row = tableWingmans:addRow(nil, { fixed = true })
    row[2]:setColSpan(10):createText(texts.wingmans, { halign = "left", titleColor = Color["row_title"] })
    for i = 1, #wingmans do
      local wingman = wingmans[i]
      if wingman ~= nil then
        local row = tableWingmans:addRow({ tableName = tableWingmans.name, rowData = wingman }, { fixed = false })
        local icon = row[2]:setColSpan(10):createIcon("order_assist", { height = config.mapRowHeight, width = config.mapRowHeight })
        icon:setText(wingman.text, { x = config.mapRowHeight, halign = "left", color = Color["text_normal"] })
        icon:setText2(wingman.text2, { halign = "right", color = Color["text_skills"] })
        if i == 10 then
          tableWingmansMaxHeight = tableWingmans:getFullHeight()
        end
      end
    end
    if #wingmans == 0 then
      row = tableWingmans:addRow("noWingmans", { fixed = true })
      row[2]:setColSpan(10):createText(texts.noAvailableWingmans, { halign = "left", color = Color["text_warning"] })
    end
  end
  if tableWingmansMaxHeight == 0 then
    tableWingmansMaxHeight = tableWingmans:getFullHeight()
  end

  tableWingmans.properties.maxVisibleHeight = math.min(tableWingmans:getFullHeight(), tableWingmansMaxHeight)
  tables[#tables + 1] = { table = tableWingmans, height = tableWingmans.properties.maxVisibleHeight }

  if #wingmans > 0 then
    if pilotAcademy.topRows.tableWingsWingmans[wingKey] ~= nil then
      tableFactions:setTopRow(pilotAcademy.topRows.tableWingsWingmans[wingKey])
    end
  end
  pilotAcademy.topRows.tableWingsWingmans[wingKey] = nil

  local tableBottom = frame:addTable(7, { tabOrder = 2, reserveScrollBar = false })
  tableBottom.name = "table_wing_bottom"
  tableBottom:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableBottom:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableBottom:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  pilotAcademy.setButtonsColumnWidths(tableBottom, menu, config)
  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  row = tableBottom:addRow("buttons", { fixed = true })
  if existingWing then
    row[2]:createButton({ active = next(editData) == nil }):setText(texts.dismissWing, { halign = "center" })
    row[2].handlers.onClick = function() return pilotAcademy.buttonDismissWing() end
  end

  row[4]:createButton({ active = next(editData) ~= nil }):setText(texts.cancel, { halign = "center" })
  row[4].handlers.onClick = function() return pilotAcademy.buttonCancelChanges() end

  row[6]:createButton({ active = next(editData) ~= nil and wingLeaderId ~= nil }):setText(existingWing and texts.update or texts.create,
    { halign = "center" })
  row[6].handlers.onClick = function() return pilotAcademy.buttonSaveWing() end

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  tables[#tables + 1] = { table = tableBottom, height = tableBottom:getFullHeight() }
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
  pilotAcademy.storeTopRows()
  menu.refreshInfoFrame()
end

function pilotAcademy.fetchPotentialWingmans(existingWing, existingWingLeader)
  if existingWing and existingWingLeader ~= nil then
    return { pilotAcademy.wingLeaderToOption(existingWingLeader) }
  end
  local candidateShips = {}
  local allShipsCount = C.GetNumAllFactionShips("player")
  local allShips = ffi.new("UniverseID[?]", allShipsCount)
  allShipsCount = C.GetAllFactionShips(allShips, allShipsCount, "player")
  local academyShips = pilotAcademy.fetchAllAcademyShipsForExclusion()
  for i = 0, allShipsCount - 1 do
    local shipId = ConvertStringTo64Bit(tostring(allShips[i]))
    local shipMacro, isDeployable, shipName, pilot, classId, idcode, icon = GetComponentData(shipId, "macro", "isdeployable", "name", "assignedaipilot",
      "classid", "idcode", "icon")
    local isLasertower, shipWare = GetMacroData(shipMacro, "islasertower", "ware")
    local isUnit = C.IsUnit(shipId)
    if shipWare and (not isUnit) and (not isLasertower) and (not isDeployable) and Helper.isComponentClass(classId, "ship_s") and pilot and IsValidComponent(pilot) then
      local subordinates = GetSubordinates(shipId)
      local commander = GetCommander(shipId)
      if #subordinates == 0 and commander == nil then
        if academyShips[tostring(shipId)] ~= true then
          local candidate = {}
          candidate.shipId = shipId
          candidate.shipName = shipName
          candidate.shipIdCode = idcode
          candidate.shipIcon = icon
          candidate.pilotId = pilot
          candidate.pilotName, candidate.pilotSkill = GetComponentData(pilot, "name", "combinedskill")
          candidateShips[#candidateShips + 1] = candidate
        end
      end
    end
  end
  table.sort(candidateShips, pilotAcademy.sortPotentialWingLeaders)
  local potentialWingLeaders = {}
  for i = 1, #candidateShips do
    potentialWingLeaders[#potentialWingLeaders + 1] = pilotAcademy.formatShipInfoOption(candidateShips[i])
  end
  return potentialWingLeaders
end

function pilotAcademy.sortPotentialWingLeaders(a, b)
  if a.pilotSkill == b.pilotSkill then
    return a.pilotName < b.pilotName
  end
  return a.pilotSkill < b.pilotSkill
end

function pilotAcademy.formatShipInfoOption(shipInfo)
  return {
    id = tostring(shipInfo.shipId),
    icon = "",
    text = string.format("\027[%s] %s (%s): %s", shipInfo.shipIcon, pilotAcademy.formatName(shipInfo.shipName, 25), shipInfo.shipIdCode,
      pilotAcademy.formatName(shipInfo.pilotName, 20)),
    text2 = string.format("%s", shipInfo.pilotSkill and Helper.displaySkill(shipInfo.pilotSkill * 15 / 100)) or 0,
    displayremoveoption = false,
  }
end

function pilotAcademy.wingLeaderToOption(wingLeaderId)
  if type(wingLeaderId) == "string" then
    wingLeaderId = ConvertStringTo64Bit(wingLeaderId)
  end
  local shipName, pilot, shipIdCode, shipIcon = GetComponentData(wingLeaderId, "name", "assignedaipilot", "idcode", "icon")
  local pilotName, pilotSkill = GetComponentData(pilot, "name", "combinedskill")
  return pilotAcademy.formatShipInfoOption({
    shipId = wingLeaderId,
    shipName = shipName,
    shipIdCode = shipIdCode,
    pilotName = pilotName,
    pilotSkill = pilotSkill,
    shipIcon = shipIcon,
  })
end

function pilotAcademy.onSelectElement(uiTable, modified, row, isDoubleClick, input)
  trace("onSelectElement called with double click: " .. tostring(isDoubleClick) .. " at row " .. tostring(row))
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot process onSelectElement")
    return
  end
  local selectedData = Helper.getCurrentRowData(menu, uiTable)
  if selectedData == nil then
    trace("Selected data is nil; cannot process onSelectElement")
    return
  end
  local tableName = selectedData.tableName
  local rowData = selectedData.rowData
  if tableName == nil then
    trace("Table name is nil; cannot process onSelectElement")
    return
  end
  if rowData == nil then
    trace("Row data is nil; cannot process onSelectElement")
    return
  end
  if tableName == "table_wing_wing_leader" or tableName == "table_wing_wingmans" then
    if rowData.id == nil then
      trace("Row data id is nil; cannot process onSelectElement")
      return
    end
    if isDoubleClick or (input ~= "mouse") then
      C.SetFocusMapComponent(menu.holomap, ConvertStringTo64Bit(tostring(rowData.id)), true)
    else
      menu.selectedcomponents = {}
      menu.addSelectedComponent(rowData.id, true, true)
      menu.setSelectedMapComponents()
    end
  end
end

function pilotAcademy.onTableRightMouseClick(uiTable, row, posX, posY)
  trace("onTableRightMouseClick called at row " .. tostring(row))
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot process onTableRightMouseClick")
    return
  end
  local interactMenuConfig = pilotAcademy.menuInteractMenuConfig
  if interactMenuConfig == nil then
    trace("Interact menu is nil; cannot process onTableRightMouseClick")
    return
  end

  local selectedData = Helper.getCurrentRowData(menu, uiTable)

  if selectedData == nil then
    trace("Selected data is nil; cannot process onSelectElement")
    return
  end
  local tableName = selectedData.tableName
  local rowData = selectedData.rowData
  if tableName == nil then
    trace("Table name is nil; cannot process onSelectElement")
    return
  end
  if rowData == nil then
    trace("Row data is nil; cannot process onSelectElement")
    return
  end
  if tableName == "table_wing_wingmans" then
    config = pilotAcademy.menuMapConfig
    menu.contextMenuMode = "academyWingman"
    if posX == nil or posY == nil then
      posX, posY = GetLocalMousePosition()
    end
    menu.contextMenuData = { width = Helper.scaleX(interactMenuConfig.width), xoffset = posX + Helper.viewWidth / 2, yoffset = Helper.viewHeight / 2 - posY, instance =
        menu.instance, tableName = tableName, rowData = rowData }
    menu.createContextFrame()
  elseif tableName == "table_personnel_cadets" or tableName == "table_personnel_pilots" then
    local isPlayerOwned = GetComponentData(pilotAcademy.commonData.locationId, "isplayerowned")
    if isPlayerOwned ~= true and rowData.hasArrived ~= true then
      trace("Location is not player owned and person has not arrived; no context menu")
      return
    end
    config = pilotAcademy.menuMapConfig
    menu.contextMenuMode = "info_context"
    if posX == nil or posY == nil then
      posX, posY = GetLocalMousePosition()
    end
    menu.contextMenuData = { width = Helper.scaleX(interactMenuConfig.width), xoffset = posX + Helper.viewWidth / 2, yoffset = Helper.viewHeight / 2 - posY, instance =
        menu.instance,  person = rowData.id, component = pilotAcademy.commonData.locationId, tableName = tableName, rowData = rowData, isAcademyPersonnel = true }

    menu.createContextFrame()
  end
end

function pilotAcademy.createInfoFrameContext(contextFrame, contextMenuData, contextMenuMode)
  trace("createInfoFrameContext called with mode: " .. tostring(contextMenuMode))
  if contextFrame == nil then
    trace("Context frame is nil; cannot create wingman context menu")
    return
  end
  if contextMenuMode == "academyWingman" then
    pilotAcademy.createWingmanContextMenu(contextFrame, contextMenuData)
  end
end

function pilotAcademy.createWingmanContextMenu(contextFrame, contextMenuData)
  trace("createWingmanContextMenu called")

  if contextMenuData == nil or type(contextMenuData) ~= "table" then
    trace("Context menu data is nil or invalid; cannot create wingman context menu")
    return
  end
  local rowData = contextMenuData.rowData
  if rowData == nil then
    trace("Row data is nil; cannot create wingman context menu")
    return
  end

  if rowData.id == nil then
    trace("Wingman id is nil; cannot create wingman context menu")
    return
  end
  local wingmanId = ConvertStringTo64Bit(tostring(rowData.id))
  local commander = GetCommander(wingmanId)
  if commander == nil then
    trace("Wingman has no commander; cannot create wingman context menu")
    return
  end
  local menu = pilotAcademy.menuInteractMenu
  local config = pilotAcademy.menuInteractMenuConfig
  if menu == nil or config == nil then
    trace("Menu or config is nil; cannot create wingman context menu")
    return
  end
  local holomapColor = menu.holomapcolor or Helper.getHoloMapColors()
  local commanderId = ConvertStringTo64Bit(tostring(commander))
  local commanderShortName = ffi.string(C.GetComponentName(commanderId))
  commanderShortName = Helper.convertColorToText(holomapColor.playercolor) .. commanderShortName
  local commanderName = commanderShortName .. " (" .. ffi.string(C.GetObjectIDCode(commanderId)) .. ")"
  local x = 0
  local menuWidth = menu.width or Helper.scaleX(config.width)
  local text = ffi.string(C.GetComponentName(wingmanId))
  local color = holomapColor.playercolor
  local ftable = contextFrame:addTable(5,
    { tabOrder = 2, x = x, width = menuWidth, backgroundID = "solid", backgroundColor = Color["frame_background_semitransparent"], highlightMode =
    "offnormalscroll" })
  ftable:setDefaultCellProperties("text", { minRowHeight = config.rowHeight, fontsize = config.entryFontSize, x = config.entryX })
  ftable:setDefaultCellProperties("button", { height = config.rowHeight })
  ftable:setDefaultCellProperties("checkbox", { height = config.rowHeight, width = config.rowHeight })
  ftable:setDefaultComplexCellProperties("button", "text", { fontsize = config.entryFontSize, x = config.entryX })
  ftable:setDefaultComplexCellProperties("button", "text2", { fontsize = config.entryFontSize, x = config.entryX })

  -- need a min width here, otherwise column 3 gets a negative width if the mode text would fit into column 2
  local borderIconSize = Helper.scaleX(Helper.headerRow1Height)
  local borderWidth = math.max(borderIconSize, Helper.scaleX(config.rowHeight) + Helper.borderSize + 1)

  ftable:setColWidth(1, config.rowHeight)
  ftable:setColWidth(2, borderWidth - Helper.scaleX(config.rowHeight) - Helper.borderSize, false)
  ftable:setColWidth(4, math.ceil(0.4 * menuWidth - borderWidth - Helper.borderSize), false)
  ftable:setColWidth(5, borderWidth, false)
  ftable:setDefaultBackgroundColSpan(1, 4)
  ftable:setDefaultColSpan(1, 3)
  ftable:setDefaultColSpan(4, 2)

  local height = 0
  -- title
  local row = ftable:addRow(false, {})
  text = TruncateText(text, Helper.standardFontBold, Helper.scaleFont(Helper.standardFontBold, Helper.headerRow1FontSize),
    menuWidth - Helper.scaleX(Helper.standardButtonWidth) - 2 * config.entryX)
  row[1]:setColSpan(5):createText(text, Helper.headerRowCenteredProperties)
  row[1].properties.color = color
  height = height + row:getHeight() + Helper.borderSize

  row = ftable:addRow(false, {})
  row[1]:createText(string.format(ReadText(1001, 7803), commanderShortName),
    { font = Helper.standardFontBold, mouseOverText = commanderName, titleColor = Color["row_title"] })
  row[4]:createText("[" .. GetComponentData(wingmanId, "assignmentname") .. "]",
    { font = Helper.standardFontBold, halign = "right", height = Helper.subHeaderHeight, titleColor = Color["row_title"] })
  height = height + row:getHeight() + Helper.borderSize
  row = ftable:addRow(true, {})
  local button = row[1]:setColSpan(5):createButton({
    bgColor = Color["button_background_hidden"],
    highlightColor = Color["button_highlight_default"],
    mouseOverText = "",
    -- helpOverlayID = entry.helpOverlayID,
    -- helpOverlayText = entry.helpOverlayText,
    -- helpOverlayHighlightOnly = entry.helpOverlayHighlightOnly,
  }):setText(ReadText(1001, 7810), { color = Color["text_normal"] })
  row[1].handlers.onClick = function() return pilotAcademy.wingmanRemoveAssignment(wingmanId) end
  height = height + row:getHeight() + Helper.borderSize
end

function pilotAcademy.wingmanRemoveAssignment(wingmanId)
  trace("wingmanRemoveAssignment called")
  if wingmanId == nil then
    trace("wingmanId is nil; cannot remove assignment")
    return
  end
  if pilotAcademy.contextFrame ~= nil then
    pilotAcademy.contextFrame:close()
    pilotAcademy.contextFrame = nil
  end
  SignalObject(wingmanId, "AcademyOrderRemoveFromWing")
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.closeContextMenu()
  menu.refreshInfoFrame()
end

function pilotAcademy.formatName(name, maxLength)
  if name == nil then
    return ""
  end
  if maxLength == nil or maxLength <= 0 then
    return name
  end
  if #name <= maxLength then
    return name
  end
  return string.sub(name, 1, maxLength - 1) .. "..."
end

function pilotAcademy.fetchWingmans(wingLeaderId)
  local wingmans = {}
  if type(wingLeaderId) == "string" then
    wingLeaderId = ConvertStringTo64Bit(wingLeaderId)
  end
  local subordinates = GetSubordinates(wingLeaderId)
  local mimicGroupId = nil
  for i = 1, #subordinates do
    local wingmanId = ConvertStringTo64Bit(tostring(subordinates[i]))
    local groupId = GetComponentData(wingmanId, "subordinategroup")
    if mimicGroupId == nil then
      local group = ffi.string(C.GetSubordinateGroupAssignment(wingLeaderId, groupId))
      if group == "assist" then
        mimicGroupId = groupId
      end
    end
    if mimicGroupId ~= nil and groupId == mimicGroupId then
      local shipName, pilot, shipIcon = GetComponentData(wingmanId, "name", "assignedaipilot", "icon")
      local pilotName, pilotSkill = GetComponentData(pilot, "name", "combinedskill")
      local shipIdCode = ffi.string(C.GetObjectIDCode(wingmanId))
      wingmans[#wingmans + 1] = pilotAcademy.formatShipInfoOption({
        shipId = wingmanId,
        shipName = shipName,
        shipIdCode = shipIdCode,
        pilotName = pilotName,
        pilotSkill = pilotSkill,
        shipIcon = shipIcon,
      })
    end
  end
  return mimicGroupId, wingmans
end

function pilotAcademy.fetchAllAcademyShipsForExclusion()
  local academyShips = {}
  local wings = pilotAcademy.wings
  if wings == nil then
    return academyShips
  end
  for _, wingData in pairs(wings) do

    local wingLeaderId = wingData.wingLeaderId
    if wingLeaderId ~= nil then
      academyShips[tostring(wingLeaderId)] = true
      local mimicGroupId, wingmans = pilotAcademy.fetchWingmans(wingLeaderId)
      for i = 1, #wingmans do
        local wingman = wingmans[i]
        if wingman ~= nil and wingman.id ~= nil then
          academyShips[tostring(wingman.id)] = true
        end
      end
    end
  end
  return academyShips
end

function pilotAcademy.onSelectWingLeader(id)
  trace("onSelectWingLeader called with id: " .. tostring(id))
  if id == nil then
    trace("id is nil; cannot process")
    return
  end
  if type(id) == "string" then
    id = ConvertStringTo64Bit(id)
  end

  pilotAcademy.editData.wingLeaderId = id

  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  pilotAcademy.storeTopRows()
  menu.refreshInfoFrame()
end

function pilotAcademy.onSelectWingman(id, wingLeaderId, mimicGroupId)
  trace("onSelectWingman called with id: " .. tostring(id))
  if id == nil then
    trace("id is nil; cannot process")
    return
  end
  if type(id) == "string" then
    id = ConvertStringTo64Bit(id)
  end

  local menu = pilotAcademy.menuInteractMenu
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  C.ResetOrderLoop(id)
  menu.orderAssignCommander(id, wingLeaderId, "assist", mimicGroupId or 1)

  menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.buttonDismissWing()
  trace("buttonDismissWing called")
  local wings = pilotAcademy.wings
  if wings == nil then
    trace("Wings is nil; cannot dismiss wing")
    return
  end
  local wingId = pilotAcademy.selectedTab
  if wingId == nil then
    trace("No wing selected or invalid index; cannot dismiss wing")
    return
  end
  pilotAcademy.topRows.tableWingsFactions[wingId] = nil
  pilotAcademy.topRows.tableWingsWingmans[wingId] = nil
  if wings[wingId] and wings[wingId].wingLeaderId ~= nil then
    SignalObject(wings[wingId].wingLeaderId, "AcademyOrderDismissWing")
  end
  wings[wingId] = nil
  if next(wings) == nil then
    pilotAcademy.selectedTab = nil
  else
    local fromCurrent = false
    for i = 1, #pilotAcademy.wingIds do
      local currentWingId = pilotAcademy.wingIds[i]
      if not fromCurrent and currentWingId == wingId then
        fromCurrent = true
      end
      if fromCurrent and wings[currentWingId] ~= nil then
        pilotAcademy.selectedTab = currentWingId
        break
      end
    end
    if pilotAcademy.selectedTab ~= wingId then
      wingId = pilotAcademy.selectedTab
    else
      fromCurrent = false
      for i = #pilotAcademy.wingIds, 1, -1 do
        local currentWingId = pilotAcademy.wingIds[i]
        if not fromCurrent and currentWingId == wingId then
          fromCurrent = true
        end
        if fromCurrent and wings[currentWingId] ~= nil then
          pilotAcademy.selectedTab = currentWingId
          wingId = pilotAcademy.selectedTab
          break
        end
      end
    end
  end
  pilotAcademy.saveWings()
  local variableId = string.format("$%s", pilotAcademy.wingsInfoVariableId)
  local wingsInfo = GetNPCBlackboard(pilotAcademy.playerId, variableId)
  if wingsInfo ~= nil then
    wingsInfo[wingId] = nil
    SetNPCBlackboard(pilotAcademy.playerId, variableId, wingsInfo)
  end
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.buttonCancelChanges()
  trace("buttonCancelChanges called")
  pilotAcademy.editData = {}
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  pilotAcademy.storeTopRows()
  menu.refreshInfoFrame()
end

function pilotAcademy.buttonSaveWing()
  trace("buttonSaveWing called")
  local wings = pilotAcademy.wings
  if wings == nil then
    wings = {}
    pilotAcademy.wings = wings
  end
  local wingId = pilotAcademy.selectedTab
  local existingWing = wingId ~= nil and wings[wingId] ~= nil
  local wingData = existingWing and wings[wingId] or {}
  local editData = pilotAcademy.editData or {}
  if editData.primaryGoal ~= nil then
    wingData.primaryGoal = editData.primaryGoal
  end
  if wingData.primaryGoal == nil then
    wingData.primaryGoal = "rank"
  end
  if editData.factions ~= nil then
    wingData.factions = editData.factions
  end
  if editData.wingLeaderId ~= nil then
    wingData.wingLeaderId = editData.wingLeaderId
    wingData.wingLeaderObject = ConvertStringToLuaID(tostring(editData.wingLeaderId))
  end
  if not existingWing then
    for i = 1, #pilotAcademy.wingIds do
      wingId = pilotAcademy.wingIds[i]
      if wings[wingId] == nil then
        break
      end
    end
    wings[wingId] = wingData
    pilotAcademy.storeTopRows()
    local currentTopRowFactions = pilotAcademy.topRows.tableWingsFactions[tostring(pilotAcademy.selectedTab)]
    local currentTopRowWingmans = pilotAcademy.topRows.tableWingsWingmans[tostring(pilotAcademy.selectedTab)]
    pilotAcademy.topRows.tableWingsFactions[tostring(pilotAcademy.selectedTab)] = nil
    pilotAcademy.topRows.tableWingsWingmans[tostring(pilotAcademy.selectedTab)] = nil
    pilotAcademy.selectedTab = wingId
    pilotAcademy.topRows.tableWingsFactions[tostring(pilotAcademy.selectedTab)] = currentTopRowFactions
    pilotAcademy.topRows.tableWingsWingmans[tostring(pilotAcademy.selectedTab)] = currentTopRowWingmans
  end
  pilotAcademy.saveWings()
  pilotAcademy.setOrderForWingLeader(wingData.wingLeaderId, pilotAcademy.selectedTab, existingWing)
  pilotAcademy.editData = {}
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.setOrderForWingLeader(wingLeaderId, wingId, existingWing)
  if type(wingLeaderId) == "string" then
    wingLeaderId = ConvertStringTo64Bit(wingLeaderId)
  end
  local buf = ffi.new("Order")
  if existingWing and C.GetDefaultOrder(buf, wingLeaderId) then
    local currentOrderDef = ffi.string(buf.orderdef)
    if currentOrderDef == pilotAcademy.orderId then
      debug("Wing leader already has " .. pilotAcademy.orderId .. " order; sending appropriate signal")
      SignalObject(wingLeaderId, "AcademyOrderDataIsUpdated")
      return
    end
  end
  local wings = pilotAcademy.wings or {}
  local existingWing = wingId ~= nil and wings[wingId] ~= nil
  local wingData = existingWing and wings[wingId] or {}
  if wingData.wingLeaderId == nil or wingData.wingLeaderId ~= wingLeaderId then
    trace("wingLeaderId does not match wing data; cannot set orders")
    return
  end
  C.RemoveAllOrders(wingLeaderId)
  C.CreateOrder(wingLeaderId, pilotAcademy.orderId, true)
  local buf = ffi.new("Order")
  if C.GetPlannedDefaultOrder(buf, wingLeaderId) then
    local newOrderIdx = tonumber(buf.queueidx)
    local orderDef = ffi.string(buf.orderdef)
    SetOrderParam(wingLeaderId, "planneddefault", 1, nil, true)
    SetOrderParam(wingLeaderId, "planneddefault", 2, nil, wingId)
    SetOrderParam(wingLeaderId, "planneddefault", 3, nil, true)
    C.EnablePlannedDefaultOrder(wingLeaderId, false)
  end
  C.SetFleetName(wingLeaderId, string.format(texts.wingFleetName, texts.wingNames[wingId]))
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
  local wingsIds = ""
  for wingId, wing in pairs(pilotAcademy.wings) do
    wingsIds = wingsIds .. (wingsIds ~= "" and ", " or "") .. "'" .. tostring(wingId) .. "'"
    wing.wingLeaderId = ConvertStringTo64Bit(tostring(wing.wingLeaderObject))
  end
  debug("loadWings: loaded " .. (wingsIds ~= "" and ("wings: " .. wingsIds) or "no wings") .. " from saved data")
end

function pilotAcademy.saveWings()
  if pilotAcademy.playerId == nil or pilotAcademy.playerId == 0 then
    debug("saveWings: unable to resolve player id")
    return
  end
  local variableId = string.format("$%s", pilotAcademy.wingsVariableId)
  if pilotAcademy.wings == nil or type(pilotAcademy.wings) ~= "table" or next(pilotAcademy.wings) == nil then
    debug("saveWings: no wings data to save, going to clear saved data")
    SetNPCBlackboard(pilotAcademy.playerId, variableId, {})
    return
  end
  SetNPCBlackboard(pilotAcademy.playerId, variableId, pilotAcademy.wings)
  debug("saveWings: saved " .. tostring(#pilotAcademy.wings) .. " wings to saved data")
  -- Save wings data to persistent storage
end

function pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menu)
  local result = nil
  trace("pilotAcademy.addAppointAsCadetRowToContextMenu called with mode: " .. tostring(contextMenuMode))

  if menu == nil then
    trace("menu is nil, returning")
    return result
  end

  pilotAcademy.loadCommonData()

  if pilotAcademy.commonData == nil then
    trace("pilotAcademy.commonData is nil, returning")
    return result
  end

  if pilotAcademy.commonData.locationId == nil then
    trace("pilotAcademy.commonData.locationId is nil, returning")
    return result
  end

  -- Validate context mode
  local isMapContext = contextMenuMode == "info_context"
  local isPersonnelContext = contextMenuMode == "personnel"

  if not isMapContext and not isPersonnelContext then
    trace(string.format("contextMenuMode is '%s', not supported, returning", tostring(contextMenuMode)))
    return result
  end

  if contextFrame == nil or type(contextFrame) ~= "table" then
    trace("contextFrame is nil or not a table, returning")
    return result
  end

  if isMapContext and (contextMenuData == nil or type(contextMenuData) ~= "table") then
    trace("contextMenuData is not a table, returning")
    return result
  end

  if type(contextFrame.content) ~= "table" or #contextFrame.content == 0 then
    trace("contextFrame.content is not a table or empty, returning")
    return result
  end

  -- Find the menu table
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

  -- Extract entity, person, and controllable based on context mode
  local entity, person, controllable, transferScheduled, hasArrived, personrole

  local isPlayerOwned = true
  if isMapContext then

    -- Map context: data comes from contextMenuData
    entity = contextMenuData.entity
    person = contextMenuData.person
    controllable = contextMenuData.component
    transferScheduled = false  -- Not relevant for map context
    hasArrived = true          -- Not relevant for map context
    personrole = ""
    isPlayerOwned = GetComponentData(controllable, "isplayerowned")
    if contextMenuData.isAcademyPersonnel then
      if isPlayerOwned then
        trace("Context menu is for academy personnel; skipping 'Assign as Cadet' option")
        return result
      end
    end
  else
    -- Personnel context: data comes from menu.personnelData
    controllable = C.ConvertStringTo64Bit(tostring(menu.personnelData.curEntry.container))
    if menu.personnelData.curEntry.type == "person" then
      person = C.ConvertStringTo64Bit(tostring(menu.personnelData.curEntry.id))
    else
      entity = menu.personnelData.curEntry.id
    end
    transferScheduled = false
    hasArrived = true
    personrole = ""
    isPlayerOwned = true
  end

  -- Get real NPC if instantiated
  if person then
    local instance = C.GetInstantiatedPerson(person, controllable)
    entity = (instance ~= 0 and instance or nil)
    transferScheduled = C.IsPersonTransferScheduled(controllable, person)
    hasArrived = C.HasPersonArrived(controllable, person)
    personrole = ffi.string(C.GetPersonRole(person, controllable))
  end



  -- Get skill level
  local skill = -1
  if person then
    skill = C.GetPersonCombinedSkill(controllable, person, nil, "aipilot")
  elseif entity then
    skill = C.GetEntityCombinedSkill(entity, nil, "aipilot")
  end

  if skill < 0 then
    trace("Person or entity has zero pilot skill, returning")
    return result
  end

  local skillBase = pilotAcademy.skillBase(skill)

  if pilotAcademy.commonData == nil or pilotAcademy.commonData.targetRankLevel == nil --[[ or skillBase - pilotAcademy.commonData.targetRankLevel > 0 ]] then
    trace("Person or entity has pilot skill at or above cadet max rank, returning")
    return result
  end

  -- Check additional conditions based on context mode
  local canAdd = false

  if isMapContext then
    local player = C.GetPlayerID()
    if person or (entity and (entity ~= player)) then
      if isPlayerOwned then
        if (person and ((personrole == "service") or (personrole == "marine") or (personrole == "trainee_group") or (personrole == "unassigned"))) or
           (entity and GetComponentData(entity, "isplayerowned") and GetComponentData(entity, "caninitiatecomm")) then
          canAdd = transferScheduled == false and hasArrived
        end
      else
        trace("Controllable is not player owned, adding standard menu items only")
        canAdd = contextMenuData.isAcademyPersonnel or false
      end
    end
  else
    -- Personnel context
    if (not transferScheduled) and hasArrived then
      canAdd = true
    end
  end

  if canAdd then
    local actor = entity and { entity = entity, personcontrollable = nil, personseed = nil } or
        person and { entity = nil, personcontrollable = controllable, personseed = person } or nil
    if actor == nil then
      trace("Actor is nil, cannot add row, returning")
      return result
    end
    trace("Adding Pilot Academy R&R row to context menu with actor: " .. tostring(actor))
    local mt = getmetatable(menuTable)
    if isPlayerOwned then
      local row = mt.__index.addRow(menuTable, "info_move_to_academy", { fixed = true })
      row[1]:createButton({ bgColor = Color["button_background_hidden"], height = Helper.standardTextHeight }):setText(texts.appointAsCadet) -- "Appoint as a cadet"
      row[1].handlers.onClick = function()
        pilotAcademy.appointAsCadet(actor)
        menu.closeContextMenu()
      end
    elseif contextMenuData and contextMenuData.isAcademyPersonnel then
      if hasArrived then
        -- if entity == nil then
        --   entity = C.CreateNPCFromPerson(person, controllable)
        -- end
        -- pilotAcademy.setNPCOwnedByPlayer(entity)
        -- person = nil
        -- controllable = nil
        -- work somewhere else
        local row = mt.__index.addRow(menuTable, "info_person_worksomewhere", { fixed = true })
        row[1]:createButton({ bgColor = Color["button_background_hidden"], height = Helper.standardTextHeight }):setText(ReadText(1002, 3008))
        if entity then
          row[1].handlers.onClick = function () Helper.closeMenuAndOpenNewMenu(menu, "MapMenu", { 0, 0, true, controllable, nil, "hire", { "signal", entity, 0 } }); menu.cleanup() end
        else
          row[1].handlers.onClick = function () Helper.closeMenuAndOpenNewMenu(menu, "MapMenu", { 0, 0, true, controllable, nil, "hire", { "signal", controllable, 0, person } }); menu.cleanup() end
        end

        local row = mt.__index.addRow(menuTable, "info_person_fire", { fixed = true })
        row[1]:createButton({ bgColor = Color["button_background_hidden"], height = Helper.standardTextHeight }):setText(ReadText(1002, 15800))
        row[1].handlers.onClick = function() return menu.infoSubmenuFireNPCConfirm(controllable, entity, person, menu.contextMenuData.instance) end
      end
    end
    result = { contextFrame = contextFrame }
  end

  return result
end

function pilotAcademy.appointAsCadet(actor, controllable)
  trace("assignAsCadet called: actor.entity=" .. tostring(actor.entity) .. ", actor.personcontrollable=" .. tostring(actor.personcontrollable) ..
    ", actor.personseed=" .. tostring(actor.personseed) .. ", controllable=" .. tostring(controllable))
  local target = controllable or pilotAcademy.commonData.locationId
  local result = ffi.string(C.AssignHiredActor(actor, target, nil, pilotAcademy.role, false))
  debug("assignAsCadet result: " .. tostring(result))
end

function pilotAcademy.calculateHiringFee(combinedskill)
  -- Base fee
  local hiringFee = combinedskill * 225

  -- If combinedskill > 20, apply the special max() formula
  if combinedskill > 20 then
    local alt = (combinedskill * 15) * (15 ^ (combinedskill / 20))
    hiringFee = math.max(hiringFee, alt)
  end

  -- Add a random amount between 300 and 700
  hiringFee = hiringFee + math.random(300, 700)

  -- Round down to nearest 10
  hiringFee = math.floor(hiringFee / 10) * 10

  return hiringFee
end

function pilotAcademy.onRankLevelReached(_, param)
  trace("OnRankLevelReached called with param: " .. tostring(param))
  local controllable = ConvertStringTo64Bit(tostring(param))
  if controllable == nil or controllable == 0 then
    trace("controllable is nil or invalid, returning")
    return
  end
  local locationId = pilotAcademy.commonData and pilotAcademy.commonData.locationId or nil
  if locationId == nil then
    trace("locationId is nil, returning")
    return
  end
  local name, idcode, pilot = GetComponentData(controllable, "name", "idcode", "assignedaipilot")
  if pilot == nil or pilot == 0 then
    trace("pilot is nil or invalid, returning")
    return
  end
  local pilotName, pilotSkill = GetComponentData(pilot, "name", "combinedskill")
  if pilotSkill == nil or pilotSkill < 0 then
    trace("pilotSkill is nil or invalid, returning")
    return
  end
  local skillBase = pilotAcademy.skillBase(pilotSkill)
  if skillBase - pilotAcademy.commonData.targetRankLevel < 0 then
    trace("Pilot has not reached target rank level, returning")
    return
  end
  trace(string.format("Pilot '%s' has reached rank level %d (skill: %d) at controllable '%s (%s)'",
    pilotName, skillBase, pilotSkill, name, idcode))
  local cadets = pilotAcademy.fetchAcademyPersonnel(false, true)
  if cadets == nil or #cadets == 0 then
    if pilotAcademy.commonData.autoHire then
      trace("No cadets found, auto-hire is enabled, attempting to hire new cadet")
      SignalObject(pilotAcademy.playerId, "AcademyCadetAutoHire", ConvertStringToLuaID(tostring(controllable)), pilotAcademy.commonData.factions)
      return
    else
      trace("No cadets found, signalling and returning")
      SignalObject(pilotAcademy.playerId, "AcademyNoCadetsAvailable")
      return
    end
  end
  local cadet = cadets[1]
  if cadet == nil then
    trace("Cadet is nil, returning")
    return
  end
  trace("Promoting cadet with name: " .. tostring(cadet.name) .. " (entity: " .. tostring(cadet.entity) .. ") and skill: " .. tostring(cadet.skill))
  SignalObject(controllable, "AcademyOrderPrepareForPilotReplacement", ConvertStringToLuaID(tostring(cadet.entity)))
end

function pilotAcademy.onPilotReturned(_, param)
  trace("OnPilotReturned called with param: " .. tostring(param))
  local pilotTemplateId = ConvertStringTo64Bit(tostring(param))
  if pilotTemplateId == nil or pilotTemplateId == 0 then
    trace("pilotTemplateId is nil or invalid, returning")
    return
  end

  pilotAcademy.loadCommonData()
  if pilotAcademy.commonData == nil then
    trace("pilotAcademy.commonData is nil, returning")
    return
  end
  if pilotAcademy.commonData.locationId == nil then
    trace("pilotAcademy.commonData.locationId is nil, returning")
    return
  end

  if pilotAcademy.commonData.assign ~= "manual" then
    trace("Auto-assigning returned pilot " .. tostring(ffi.string(C.GetPersonName(pilotTemplateId, pilotAcademy.commonData.locationId))) .. " to academy location")
    pilotAcademy.autoAssignPilots()
  else
    trace("Auto-assign is disabled, not assigning returned pilot")
  end
end

function pilotAcademy.onRefreshPilots()
  trace("onRefreshPilots called")
  pilotAcademy.autoAssignPilots()
end

function pilotAcademy.autoAssignPilots()
  trace("autoAssignPilots called")
  pilotAcademy.loadCommonData()
  if pilotAcademy.commonData == nil then
    trace("pilotAcademy.commonData is nil, returning")
    return
  end
  if pilotAcademy.commonData.locationId == nil then
    trace("pilotAcademy.commonData.locationId is nil, returning")
    return
  end
  if pilotAcademy.commonData.assign == "manual" then
    trace("Auto-assign is disabled, returning")
    return
  end
  local currentTime = getElapsedTime()
  if pilotAcademy.lastAutoAssignTime ~= nil and currentTime - pilotAcademy.lastAutoAssignTime < pilotAcademy.autoAssignCoolDown then
    trace("Auto-assign cool down not yet elapsed, returning")
    return
  end
  pilotAcademy.lastAutoAssignTime = currentTime
  local cadets, pilots = pilotAcademy.fetchAcademyPersonnel(false, true)
  if pilots == nil or #pilots == 0 then
    trace("No available pilots found, returning")
    return
  end
  local candidateShips = pilotAcademy.fetchCandidatesForReplacement()
  if candidateShips == nil or #candidateShips == 0 then
    trace("No candidate ships found for replacement, returning")
    return
  end
  trace(string.format("Auto-assigning pilots: found %d pilots and %d candidate ships", #pilots, #candidateShips))
  for i = #pilots, 1, -1 do
    local pilot = pilots[i]
    if pilot == nil then
      trace("Pilot is nil, skipping")
    else
      local candidateShip = candidateShips[1]
      if candidateShip ~= nil then
        local data = {
          ship = ConvertStringToLuaID(tostring(candidateShip.shipId)),
          academyObject = ConvertStringToLuaID(tostring(pilotAcademy.commonData.locationId)),
          newPilot = ConvertStringToLuaID(tostring(pilot.entity)),
          iteration = 0
        }
        SignalObject(pilotAcademy.playerId, "AcademyMoveNewPilotRequest", data)
        trace(string.format("Assigned pilot '%s' (skill: %d) to ship '%s' (idcode: %s)",
          pilot.name, pilot.skill, candidateShip.shipName, candidateShip.shipIdCode))
        table.remove(candidateShips, 1)
        if #candidateShips == 0 then
          trace("No more candidate ships available, ending auto-assign")
          break
        end
      end
    end
  end
end

function pilotAcademy.fetchCandidatesForReplacement()
  trace("fetchCandidatesForReplacement called")
  local targetRankLevel = pilotAcademy.commonData and pilotAcademy.commonData.targetRankLevel or 2
  local candidateShips = {}
  local allShipsCount = C.GetNumAllFactionShips("player")
  local allShips = ffi.new("UniverseID[?]", allShipsCount)
  allShipsCount = C.GetAllFactionShips(allShips, allShipsCount, "player")
  local academyShips = pilotAcademy.fetchAllAcademyShipsForExclusion()
  for i = 0, allShipsCount - 1 do
    local shipId = ConvertStringTo64Bit(tostring(allShips[i]))
    local shipMacro, isDeployable, shipName, pilot, classId, idcode, purpose = GetComponentData(shipId, "macro", "isdeployable", "name", "assignedaipilot",
      "classid", "idcode", "primarypurpose")
    local isLasertower, shipWare = GetMacroData(shipMacro, "islasertower", "ware")
    local isUnit = C.IsUnit(shipId)
    if shipWare and (not isUnit) and (not isLasertower) and (not isDeployable) and not Helper.isComponentClass(classId, "ship_xs") and pilot and IsValidComponent(pilot) then
      if academyShips[tostring(shipId)] ~= true then
        local pilotName, pilotSkill, pilotMacro = GetComponentData(pilot, "name", "combinedskill", "macro")
        local pilotRace = GetMacroData(pilotMacro)
        local skillBase = pilotAcademy.skillBase(pilotSkill)
        if skillBase < targetRankLevel and pilotRace ~= "drone" then
          local class = Helper.isComponentClass(classId, "ship_s") and "ship_s" or Helper.isComponentClass(classId, "ship_m") and "ship_m" or Helper.isComponentClass(classId, "ship_l") and "ship_l" or  Helper.isComponentClass(classId, "ship_xl") and "ship_xl" or "unknown"
          trace(string.format("Evaluating ship '%s' (idcode: %s, class: %s, purpose: %s) with pilot '%s' (skill: %d, base rank: %d)",
            shipName, idcode, class, purpose, pilotName, pilotSkill, skillBase))
          if class ~= "unknown" then
            if purpose == "mine" or purpose == "salvage" then
              purpose = "mine"
            elseif purpose == "fight" or purpose == "auxiliary" then
              purpose = "military"
            else
              purpose = "trade"
            end
            candidateShips[#candidateShips + 1] = {
              shipId = shipId,
              shipName = shipName,
              shipIdCode = idcode,
              class = class,
              purpose = purpose,
              pilotName = pilotName,
              pilotSkill = pilotSkill,
            }
          end
        end
      end
    end
  end
  pilotAcademy.sortCandidatesForReplacement(candidateShips, pilotAcademy.commonData.assign, pilotAcademy.commonData.assignPriority)
  return candidateShips
end


function pilotAcademy.sortCandidatesForReplacement(candidates, assign, assignPriority)
  table.sort(candidates, function(a, b)
    if a.purpose ~= b.purpose then
      if assign == "military_miners_traders" then
        if a.purpose == "military" then
          return true
        elseif b.purpose == "military" then
          return false
        elseif a.purpose == "mine" then
          return true
        elseif b.purpose == "mine" then
          return false
        end
      elseif assign == "military_traders_miners" then
        if a.purpose == "military" then
          return true
        elseif b.purpose == "military" then
          return false
        elseif a.purpose == "trade" then
          return true
        elseif b.purpose == "trade" then
          return false
        end
      elseif assign == "miners_military_traders" then
        if a.purpose == "mine" then
          return true
        elseif b.purpose == "mine" then
          return false
        elseif a.purpose == "military" then
          return true
        elseif b.purpose == "military" then
          return false
        end
      elseif assign == "traders_military_miners" then
        if a.purpose == "trade" then
          return true
        elseif b.purpose == "trade" then
          return false
        elseif a.purpose == "military" then
          return true
        elseif b.purpose == "military" then
          return false
        end
      elseif assign == "miners_traders_military" then
        if a.purpose == "mine" then
          return true
        elseif b.purpose == "mine" then
          return false
        elseif a.purpose == "trade" then
          return true
        elseif b.purpose == "trade" then
          return false
        end
      elseif assign == "traders_miners_military" then
        if a.purpose == "trade" then
          return true
        elseif b.purpose == "trade" then
          return false
        elseif a.purpose == "mine" then
          return true
        elseif b.purpose == "mine" then
          return false
        end
      end
    end
    if a.class ~= b.class then
      if assignPriority == "priority_small_to_large" then
        return pilotAcademy.classOrderSmallToLarge[a.class] < pilotAcademy.classOrderSmallToLarge[b.class]
      else
        return pilotAcademy.classOrderLargeToSmall[a.class] < pilotAcademy.classOrderLargeToSmall[b.class]
      end
    end
    if a.pilotSkill ~= b.pilotSkill then
      return a.pilotSkill < b.pilotSkill
    end
    return a.shipName < b.shipName
  end)
end

local function preAddRowToMapMenuContext(contextMenuData, contextMenuMode, menu)
  if contextMenuData.person then
    trace("mode: " .. tostring(contextMenuMode) .. ", component: " .. (contextMenuData.component or "nil") .. "person: " ..
      (contextMenuData.component and ffi.string(C.GetPersonName(contextMenuData.person, contextMenuData.component)) or "unknown") ..
      ", combinedskill: " .. (contextMenuData.component and C.GetPersonCombinedSkill(contextMenuData.component, contextMenuData.person, nil, nil) or "unknown"))
  end
  local result = nil
  return result
end

local function preAddRowToPlayerInfoMenuContext(contextMenuData, contextMenuMode, menu)
  local result = nil
  return result
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
