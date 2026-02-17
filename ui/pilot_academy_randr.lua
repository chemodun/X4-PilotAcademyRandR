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
		const char* icon;
		const char* description;
		const char* category;
		const char* categoryname;
		bool infinite;
		uint32_t requiredSkill;
	} OrderDefinition;

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
	bool GetOrderDefinition(OrderDefinition* result, const char* orderdef);

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

  double GetCurrentGameTime(void);
]]

local debugLevel = "trace" -- "none", "debug", "trace"

local texts = {
  pilotAcademyFull = ReadText(1972092412, 1),                 -- "Pilot Academy: Ranks and Relations"
  pilotAcademy = ReadText(1972092412, 11),                    -- "Pilot Academy R&R"
  wingFleetName = ReadText(1972092412, 111),                  -- "Wing %s of Pilot Academy R&R"
  wingBroken = ReadText(1972092412, 119),                     -- "Wing %s is broken!"
  academySettings = ReadText(1972092412, 10001),              -- "Academy Settings"
  cadetsAndPilots = ReadText(1972092412, 10011),              -- "Cadets and Pilots"
  cadetsAndPilotsTitle = ReadText(1972092412, 10019),         -- "Pilot Academy: Cadets and Pilots"
  wing = ReadText(1972092412, 10021),                         -- "Wing %s"
  addNewWing = ReadText(1972092412, 10029),                   -- "Add new Wing"
  location = ReadText(1972092412, 10101),                     -- "Location:"
  locationRentCost = ReadText(1972092412, 10102),             -- "Location rent cost: %s a day."
  insufficientFundsForRent = ReadText(1972092412, 10108),     -- "Insufficient funds for rent"
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
  perFleet = ReadText(1972092412, 10138),                     -- "Per Fleet"
  manual = ReadText(1972092412, 10139),                       -- "Manual"
  priority = ReadText(1972092412, 10141),                     -- "Priority:"
  priority_small_to_large = ReadText(1972092412, 10142),      -- "Small to Large"
  priority_large_to_small = ReadText(1972092412, 10143),      -- "Large to Small"
  noFleetsAvailable = ReadText(1972092412, 10151),           -- "No fleets available"
  autoFireLessSkilledCrewMember = ReadText(1972092412, 10191), -- "Auto fire less skilled crew member if crew is full"
  fleets = string.format("%s:", ReadText(1001, 8326)),  -- "Fleets:"
  cadets = ReadText(1972092412, 10201),                       -- "Cadets:"
  noCadetsAssigned = ReadText(1972092412, 10209),             -- "No cadets assigned"
  pilots = ReadText(1972092412, 10211),                       -- "Pilots:"
  noPilotsAvailable = ReadText(1972092412, 10219),            -- "No pilots available"
  primaryGoal = ReadText(1972092412, 10301),                  -- "Primary Goal:"
  increaseRank = ReadText(1972092412, 10302),                 -- "Increase Rank"
  gainReputation = ReadText(1972092412, 10303),               -- "Gain Reputation"
  noAvailablePrimaryGoals = ReadText(1972092412, 10309),      -- "No available primary goals"
  factions = ReadText(1972092412, 10311),                     -- "Factions:"
  noAvailableFactions = ReadText(1972092412, 10319),          -- "No available factions"
  tradeDataRefreshInterval = ReadText(1972092412, 10321),     -- "Trade data refresh interval:"
  wingLeader = ReadText(1972092412, 10331),                   -- "Wing Leader:"
  noAvailableWingLeaders = ReadText(1972092412, 10339),       -- "No available wing leaders"
  addWingman = ReadText(1972092412, 10341),                   -- "Add Wingman"
  noAvailableWingmanCandidates = ReadText(1972092412, 10349), -- "No available wingman candidates"
  wingmans = ReadText(1972092412, 10351),                     -- "Wingmans:"
  noAvailableWingmans = ReadText(1972092412, 10359),          -- "No wingmans assigned"
  dismissWing = ReadText(1972092412, 10901),                  -- "Dismiss"
  cancel = ReadText(1972092412, 10902),                       -- "Cancel"
  update = ReadText(1972092412, 10903),                       -- "Update"
  create = ReadText(1972092412, 10904),                       -- "Create"
  appointAsCadet = ReadText(1972092412, 20001),               -- "Appoint as a cadet"
  wingNames = { a = ReadText(1972092412, 100001), b = ReadText(1972092412, 100002), c = ReadText(1972092412, 100003), d = ReadText(1972092412, 100004), e = ReadText(1972092412, 100005), f = ReadText(1972092412, 100006), g = ReadText(1972092412, 100007), h = ReadText(1972092412, 100008), i = ReadText(1972092412, 100009) },
}


local pilotAcademy = {
  playerId = nil,
  menuMap = nil,
  menuMapConfig = {},
  academySideBarInfo = {
    name = texts.pilotAcademyFull,
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
    "perFleet",
    "military_miners_traders",
    "military_traders_miners",
    "miners_traders_military",
    "miners_military_traders",
    "traders_military_miners",
    "traders_miners_military",
  },
  purposePriorities = {
    military_miners_traders = { military = 1, mine = 2, trade = 3 },
    military_traders_miners = { military = 1, trade = 2, mine = 3 },
    miners_military_traders = { mine = 1, military = 2, trade = 3 },
    miners_traders_military = { mine = 1, trade = 2, military = 3 },
    traders_military_miners = { trade = 1, military = 2, mine = 3 },
    traders_miners_military = { trade = 1, mine = 2, military = 3 }
  },
  assignPriority = {
    "priority_small_to_large",
    "priority_large_to_small",
  },
  classOrderSmallToLarge = { ship_xl = 4, ship_l = 3, ship_m = 2, ship_s = 1 },
  classOrderLargeToSmall = { ship_xl = 1, ship_l = 2, ship_m = 3, ship_s = 4 },
  autoAssignCoolDown = 120,    -- seconds
  rentInterval = 24 * 60 * 60, -- seconds,
  tradeDataRefreshIntervals = {
    5,
    10,
    15,
    30,
    60,
  },
  maxOrderErrors = 3,
  academyContentColumnWidths = nil,
  buttonsColumnWidths = nil,
  infoContentColumnWidths = nil,
  relationNameMaxLen = 8, -- will be calculated on init based on actual relation names
  selectedShips = {},
  selectedRow = {}
}

local config = {}
local function debug(message)
  if debugLevel ~= "none" then
    local text = "Pilot Academy: " .. message
    if type(DebugError) == "function" then
      DebugError(text)
    end
  end
end

local function trace(message)
  ---@diagnostic disable-next-line: unnecessary-if
  if debugLevel == "trace" then
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

-- Helper: Normalize ship purpose to standard categories
function pilotAcademy.normalizePurpose(purpose)
  if purpose == "mine" or purpose == "salvage" then
    return "mine"
  elseif purpose == "fight" or purpose == "auxiliary" then
    return "military"
  else
    return "trade"
  end
end

-- Helper: Compare purpose priority based on assignment strategy
function pilotAcademy.comparePurposePriority(a, b, assign)
  local priorities = pilotAcademy.purposePriorities[assign]
  if not priorities then return false end
  local aPriority = priorities[a.purpose] or 999
  local bPriority = priorities[b.purpose] or 999
  return aPriority < bPriority
end

function pilotAcademy.Init(menuMap, menuPlayerInfo)
  trace("pilotAcademy.Init called at " .. tostring(C.GetCurrentGameTime()))
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
    AddUITriggeredEvent("PilotAcademyRAndR", "Reloaded")
    menuMap.registerCallback("createContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menuMap)
    end)
    menuMap.registerCallback("refreshContextFrame_on_end", function(contextFrame, contextMenuData, contextMenuMode)
      return pilotAcademy.addAppointAsCadetRowToContextMenu(contextFrame, contextMenuData, contextMenuMode, menuMap)
    end)
    menuMap.registerCallback("ic_onRowChanged", pilotAcademy.onRowChanged)
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
  RegisterEvent("PilotAcademyRAndR.DebugLevelChanged", pilotAcademy.onDebugLevelChanged)

  pilotAcademy.resetData()
  pilotAcademy.loadWings()
  local changed = pilotAcademy.loadCommonData()
  debugLevel = "none"
  pilotAcademy.onDebugLevelChanged()
  if pilotAcademy.setRentCost() or changed then
    pilotAcademy.saveCommonData()
  end
  local relations = GetLibrary("factions")
  local relationNameMaxLen = 0
  local relationNameMax = nil
  for i = 1, #relations do
    local relation = relations[i]
    if relation ~= nil and relation.id ~= "player" then
      local relationInfo = C.GetUIRelationName("player", relation.id)
      local relationName = ffi.string(relationInfo.name)
      local relationNameLength = string.len(relationName)
      if relationNameLength > relationNameMaxLen then
        relationNameMaxLen = relationNameLength
        relationNameMax = relationName
      end
    end
  end
  if relationNameMax then
    trace("Longest relation name is '" .. relationNameMax .. "' with length " .. relationNameMaxLen)
    pilotAcademy.relationNameMaxLen = relationNameMaxLen
  end
end

function pilotAcademy.resetData()
  pilotAcademy.editData = {}
  pilotAcademy.selectedTab = "settings"
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
  if C.HasResearched("research_pilot_academy_r_and_r_wings_9") then
    wingsCountMax = 9
  elseif C.HasResearched("research_pilot_academy_r_and_r_wings_5") then
    wingsCountMax = 5
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

  pilotAcademy.frame = frame

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
  for i = 1, #factionsAll do
    local faction = factionsAll[i]
    if faction ~= nil and faction.id ~= "player" then
      local shortName, isAtDockRelation, isRelationLocked = GetFactionData(faction.id, "shortname", "isatdockrelation", "isrelationlocked")
      if isAtDockRelation and not isRelationLocked then
        faction.shortName = shortName
        faction.isAtDockRelation = isAtDockRelation
        faction.uiRelation = GetUIRelation(faction.id)
        local relationInfo = C.GetUIRelationName("player", faction.id)
        faction.relationName = ffi.string(relationInfo.name)
        faction.colorId = ffi.string(relationInfo.colorid)
        factions[#factions + 1] = faction
      end
    end
  end
  if sortAscending then
    table.sort(factions, pilotAcademy.sortFactionsAscending)
  else
    table.sort(factions, pilotAcademy.sortFactionsDescending)
  end
  return factions
end

function pilotAcademy.buttonSelectTab(selector)
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot process buttonSelectTab")
    return
  end
  if selector ~= pilotAcademy.selectedTab then
    pilotAcademy.selectedTab = selector or nil
    pilotAcademy.editData = {}

    menu.refreshInfoFrame()
  end
end



function pilotAcademy.setAcademyContentColumnWidths(tableHandle, menu, config)
  if tableHandle == nil or menu == nil then
    debug("tableWingmans or menu is nil; cannot set column widths")
    return
  end
  if (pilotAcademy.academyContentColumnWidths == nil) then
    local contentWidth = menu.infoTableWidth - Helper.scrollbarWidth * 2 - config.mapRowHeight - Helper.borderSize * 5
    pilotAcademy.academyContentColumnWidths = {
      Helper.scrollbarWidth + 1,
      config.mapRowHeight,
      contentWidth,
      Helper.scrollbarWidth + 1,
    }
    trace(string.format("Calculated academy content column widths: %s", table.concat(pilotAcademy.academyContentColumnWidths, ", ")))
  end
  for i = 1, 4 do
    tableHandle:setColWidth(i, pilotAcademy.academyContentColumnWidths[i], false)
  end
end

function pilotAcademy.setInfoContentColumnWidths(tableHandle, menu, config)
  if tableHandle == nil or menu == nil then
    debug("tableWingmans or menu is nil; cannot set column widths")
    return
  end
  if (pilotAcademy.infoContentColumnWidths == nil) then
    local maxShortNameWidth = math.floor(C.GetTextWidth("[WWW]", Helper.standardFont, Helper.scaleFont(Helper.standardFont, config.mapFontSize)))
    local maxRelationNameWidth = math.floor(C.GetTextWidth(string.rep("W", pilotAcademy.relationNameMaxLen), Helper.standardFont, Helper.scaleFont(Helper.standardFont, config.mapFontSize)))
    local relationWidth = math.floor(C.GetTextWidth("99999", Helper.standardFont, Helper.scaleFont(Helper.standardFont, config.mapFontSize)))
    local minWidth = Helper.scaleX(config.mapRowHeight)
    pilotAcademy.infoContentColumnWidths = {
      Helper.scrollbarWidth + 1,
      minWidth,
      minWidth,
      maxShortNameWidth + Helper.borderSize * 2,
      minWidth,
      menu.sideBarWidth,
      0, -- will be set to min width and allowed to expand
      minWidth,
      minWidth,
      maxRelationNameWidth + Helper.borderSize * 2,
      relationWidth + Helper.borderSize * 2,
      Helper.scrollbarWidth + 1,
    }
    local preContentWidth = 0
    for i = 1, #pilotAcademy.infoContentColumnWidths do
      preContentWidth = preContentWidth + pilotAcademy.infoContentColumnWidths[i] + Helper.borderSize
    end
    pilotAcademy.infoContentColumnWidths[7] = menu.infoTableWidth - preContentWidth
    trace(string.format("Calculated info content column widths: %s", table.concat(pilotAcademy.infoContentColumnWidths, ", ")))
  end
  for i = 1, 12 do
    tableHandle:setColWidth(i, pilotAcademy.infoContentColumnWidths[i], false)
  end
end

function pilotAcademy.setButtonsColumnWidths(tableHandle, menu, config)
  if tableHandle == nil or menu == nil then
    debug("tableWingmans or menu is nil; cannot set column widths")
    return
  end

  if pilotAcademy.buttonsColumnWidths == nil then
    local buttonWidth = math.floor((menu.infoTableWidth - Helper.scrollbarWidth * 5 - 2) / 3)
    pilotAcademy.buttonsColumnWidths = {
      Helper.scrollbarWidth + 1,
      buttonWidth,
      Helper.scrollbarWidth,
      buttonWidth,
      Helper.scrollbarWidth,
      buttonWidth,
      Helper.scrollbarWidth + 1,
    }
    trace(string.format("Calculated buttons column widths: %s", table.concat(pilotAcademy.buttonsColumnWidths, ", ")))
  end

  for i = 1, 7 do
    tableHandle:setColWidth(i, pilotAcademy.buttonsColumnWidths[i], false)
  end
end

function pilotAcademy.createTable(frame, numCols, tableName, isSelectable, reserveScrollBar, menu, config)
  local tableHandle = frame:addTable(numCols, { tabOrder = 2, reserveScrollBar = reserveScrollBar })
  tableHandle.name = tableName
  tableHandle.isSelectable = isSelectable
  tableHandle:setDefaultCellProperties("text", { minRowHeight = config.mapRowHeight, fontsize = config.mapFontSize })
  tableHandle:setDefaultCellProperties("button", { height = config.mapRowHeight })
  tableHandle:setDefaultComplexCellProperties("button", "text", { fontsize = config.mapFontSize })
  if numCols == 4 then
    pilotAcademy.setAcademyContentColumnWidths(tableHandle, pilotAcademy.menuMap, config)
  elseif numCols == 7 then
    pilotAcademy.setButtonsColumnWidths(tableHandle, menu, config)
  elseif numCols == 12 then
    pilotAcademy.setInfoContentColumnWidths(tableHandle, menu, config)
  end
  return tableHandle
end

function pilotAcademy.displayFactions(tableFactions, factions, editData, storedData, config)
  local tableFactionsMaxHeight = 0
  local factionsEdit = editData.factionsTable or {}
  local factionsSaved = storedData.factionsTable or {}
  for i = 1, #factions do
    local faction = factions[i]
    if faction ~= nil then
      local row = tableFactions:addRow(faction.id, { fixed = false })
      row[2]:createCheckBox(factionsEdit[faction.id] == true or factionsEdit[faction.id] ~= false and factionsSaved[faction.id] == true, { scaling = false })
      row[2].handlers.onClick = function(_, checked) return pilotAcademy.onSelectFaction(faction.id, checked, storedData) end
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
end

-- Helper: Extract and prepare academy display data
local function getAcademyDisplayData()
  local academyData = pilotAcademy.commonData or {}
  local editData = pilotAcademy.editData or {}
  local locationId = editData.locationId or academyData.locationId or nil
  local locationSelectable = locationId == nil or
      (editData.locationId ~= nil and editData.locationId ~= academyData.locationId) or
      editData.toChangeLocation == true

  return {
    academyData = academyData,
    editData = editData,
    locationId = locationId,
    locationSelectable = locationSelectable
  }
end

-- Helper: Get max rank level based on research
local function getMaxRankLevel()
  if C.HasResearched("research_pilot_academy_r_and_r_5_star") then
    return 5
  elseif C.HasResearched("research_pilot_academy_r_and_r_4_star") then
    return 4
  elseif C.HasResearched("research_pilot_academy_r_and_r_3_star") then
    return 3
  end
  return 2
end

-- Helper: Create academy header with location selection
function pilotAcademy.createAcademyHeaderTable(frame, menu, config, tableName, titleText)
  local tableHandler = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  local row = tableHandler:addRow(nil, { fixed = true })
  row[1]:setColSpan(4):createText(texts.pilotAcademyFull, Helper.headerRowCenteredProperties)
  tableHandler:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableHandler, height = tableHandler:getFullHeight() }
end

-- Helper: Create academy location table
function pilotAcademy.createAcademyLocationTable(frame, menu, config, tableName, displayData, locationOptions, emptyText)
  local tableLocation = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  -- Location selection
  local row = tableLocation:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.location, { halign = "left", titleColor = Color["row_title"] })
  row = tableLocation:addRow("location", { fixed = true })
  row[1]:createText("", { halign = "left" })

  if displayData.locationSelectable then
    row[2]:setColSpan(2):createDropDown(locationOptions, {
      startOption = displayData.locationId or -1,
      active = true,
      textOverride = (#locationOptions == 0) and emptyText or nil,
    })
    row[2]:setTextProperties({ halign = "left" })
    row[2]:setText2Properties({ halign = "right" })
    row[2].handlers.onDropDownActivated = function() menu.noupdate = true end
    row[2].handlers.onDropDownConfirmed = function(_, id)
      menu.noupdate = false
      return pilotAcademy.onSelectLocation(id)
    end
  else
    local isAnyPersonNotArrived = pilotAcademy.isAnyPersonNotArrived()
    row[2]:setColSpan(2):createButton({
      active = not isAnyPersonNotArrived,
      mouseOverText = string.format("%s\027X %s", locationOptions[1].text, locationOptions[1].text2)
    }):setText(locationOptions[1].text, { halign = "left" }):setText2(locationOptions[1].text2, { halign = "right" })
    row[2].handlers.onClick = function() return pilotAcademy.onToChangeLocation() end
  end
  tableLocation:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  -- Rent cost display for non-player locations
  local owner = displayData.academyData.locationId and GetComponentData(displayData.academyData.locationId, "owner") or nil
  if owner ~= nil and owner ~= "player" then
    local rentCost = displayData.academyData.rentCost or 0
    row = tableLocation:addRow(nil, { fixed = true })
    row[2]:setColSpan(2):createText(
      string.format(texts.locationRentCost, ConvertMoneyString(rentCost, false, true, nil, true) .. " " .. ReadText(1001, 101)),
      { halign = "left", titleColor = Color["row_title"] }
    )
    tableLocation:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  end

  return { table = tableLocation, height = tableLocation:getFullHeight() }
end

-- Helper: Create target rank level slider table
function pilotAcademy.createTargetRankTable(frame, menu, config, tableName, displayData)
  local tableRank = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  local targetRankLevel = displayData.editData.targetRankLevel or displayData.academyData.targetRankLevel or 2
  local maxRankLevel = getMaxRankLevel()

  local row = tableRank:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.targetRankLevel, { halign = "left", titleColor = Color["row_title"] })

  row = tableRank:addRow("target_rank_level", { fixed = true })
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

  tableRank:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableRank, height = tableRank:getFullHeight() }
end

-- Helper: Create auto hire checkbox table
function pilotAcademy.createAutoHireTable(frame, menu, config, tableName, displayData, factions)
  local tableAutoHire = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  local autoHire = displayData.editData.autoHire
  if autoHire == nil then
    autoHire = displayData.academyData.autoHire
  end
  if autoHire == nil then
    autoHire = false
  end

  local autoHireActive = C.HasResearched("research_pilot_academy_r_and_r_auto_hire")

  local row = tableAutoHire:addRow("auto_hire", { fixed = true })
  row[2]:createCheckBox(autoHire == true, {
    active = autoHireActive and #factions > 0,
    height = config.mapRowHeight,
    width = config.mapRowHeight
  })
  row[2].handlers.onClick = function(_, checked) return pilotAcademy.onToggleAutoHire(checked) end
  row[3]:createText(texts.autoHire, { halign = "left", titleColor = Color["row_title"], x = Helper.scaleX(Helper.borderSize * 2) })
  tableAutoHire:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableAutoHire, height = tableAutoHire:getFullHeight(), autoHire = autoHire }
end

-- Helper: Create factions selection table (conditional)
function pilotAcademy.createAcademyFactionsTable(frame, menu, config, tableName, displayData, factions)
  local tableFactions = pilotAcademy.createTable(frame, 12, tableName, true, false, menu, config)

  pilotAcademy.displayFactions(tableFactions, factions, displayData.editData, displayData.academyData, config)

  -- Restore scroll position if available
  pilotAcademy.setTopRow(tableFactions, tableName)


  return { table = tableFactions, height = tableFactions.properties.maxVisibleHeight }
end

-- Helper: Create assignment settings table
function pilotAcademy.createAssignmentTable(frame, menu, config, tableName, displayData, locationOptions)
  local tableAssign = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  tableAssign:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  local assignOptions = pilotAcademy.getAssignOptions()
  local assign = displayData.editData.assign or displayData.academyData.assign or "manual"
  local autoAssignActive = C.HasResearched("research_pilot_academy_r_and_r_auto_assign")

  local row = tableAssign:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.assign, { halign = "left", titleColor = Color["row_title"] })

  row = tableAssign:addRow("location", { fixed = true })
  row[1]:createText("", { halign = "left" })
  row[2]:setColSpan(2):createDropDown(assignOptions, {
    startOption = assign or "manual",
    active = autoAssignActive,
    textOverride = (#locationOptions == 0) and "" or nil,
  })
  row[2]:setTextProperties({ halign = "left" })
  row[2].handlers.onDropDownActivated = function() menu.noupdate = true end
  row[2].handlers.onDropDownConfirmed = function(_, id)
    menu.noupdate = false
    return pilotAcademy.onSelectAssign(id)
  end

  return { table = tableAssign, height = tableAssign:getFullHeight(), assign = assign }
end

function pilotAcademy.createAssignOptionsTable(frame, menu, config, tableName, displayData)
  local tableAssignOptions = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  -- Priority dropdown (conditional on non-manual assignment)
  local assignPriority = displayData.editData.assignPriority or displayData.academyData.assignPriority or "priority_small_to_large"
  local priorityOptions = pilotAcademy.getAssignPriorityOptions()

  tableAssignOptions:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableAssignOptions:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(texts.priority, { halign = "left", titleColor = Color["row_title"] })

  row = tableAssignOptions:addRow("assign_priority", { fixed = true })
  row[1]:createText("", { halign = "left" })
  row[2]:setColSpan(2):createDropDown(priorityOptions, {
    startOption = assignPriority or "priority_small_to_large",
    active = true,
    textOverride = (#priorityOptions == 0) and "" or nil,
  })
  row[2]:setTextProperties({ halign = "left" })
  row[2].handlers.onDropDownActivated = function() menu.noupdate = true end
  row[2].handlers.onDropDownConfirmed = function(_, id)
    menu.noupdate = false
    return pilotAcademy.onSelectAssignPriority(id)
  end

  tableAssignOptions:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local autoFireLessSkilledCrewMember = displayData.editData.autoFireLessSkilledCrewMember
  if autoFireLessSkilledCrewMember == nil then
    autoFireLessSkilledCrewMember = displayData.academyData.autoFireLessSkilledCrewMember
  end
  if autoFireLessSkilledCrewMember == nil then
    autoFireLessSkilledCrewMember = false
  end
  local row = tableAssignOptions:addRow("auto_fire_less_skilled", { fixed = true })
  row[2]:createCheckBox(autoFireLessSkilledCrewMember == true, {
    height = config.mapRowHeight,
    width = config.mapRowHeight
  })
  row[2].handlers.onClick = function(_, checked) return pilotAcademy.onToggleAutoFireLessSkilledCrewMember(checked) end
  row[3]:createText(texts.autoFireLessSkilledCrewMember, { halign = "left", titleColor = Color["row_title"], x = Helper.scaleX(Helper.borderSize * 2) })

  return { table = tableAssignOptions, height = tableAssignOptions:getFullHeight() }
end

-- Helper: Create fleet assignment table (conditional on assignment type)
function pilotAcademy.createFleetAssignmentTable(frame, menu, config, tableName, displayData)
  local tableFleets = pilotAcademy.createTable(frame, 12, tableName, true, false, menu, config)

  tableFleets:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  local row = tableFleets:addRow(nil, { fixed = true })
  row[2]:setColSpan(10):createText(texts.fleets, { halign = "left", titleColor = Color["row_title"] })

  local tableFleetsMaxHeight = 0

  local fleetsSaved = displayData.academyData.fleets or {}
  local fleets, fleetsExists = pilotAcademy.fetchFleets()
  for fleetId, _ in pairs(fleetsSaved) do
    if fleetsExists and fleetsExists[fleetId] == nil then
      fleetsSaved[fleetId] = nil
    end
  end
  local fleetsEdit = displayData.editData.fleets or {}
  local selectedShip = pilotAcademy.selectedShips[tableName] or nil
  for i = 1, #fleets do
    local fleet = fleets[i]
    if fleet ~= nil then
      local bgColor = nil
      if selectedShip and fleet.commanderId == selectedShip then
        bgColor = Color["row_background_selected"]
      end
      local row = tableFleets:addRow({ tableName = tableFleets.name, rowData = fleet }, { fixed = false, bgColor = bgColor })
      row[2]:createCheckBox(fleetsEdit[fleet.commanderId] == true or fleetsEdit[fleet.commanderId] ~= false and fleetsSaved[fleet.commanderId] == true, { scaling = false })
      row[2].handlers.onClick = function(_, checked) return pilotAcademy.onSelectFleet(fleet.commanderId, checked) end
      row[3]:setColSpan(7):createText(string.format("\027G%s\027X: %s", fleet.fleetName, fleet.commander), { halign = "left", color = Color["text_normal"] })
      row[10]:setColSpan(2):createText(fleet.sector, { halign = "right", color = Color["text_normal"]})
      if i == 10 then
        tableFleetsMaxHeight = tableFleets:getFullHeight()
      end
    end
  end
  if tableFleetsMaxHeight == 0 then
    tableFleetsMaxHeight = tableFleets:getFullHeight()
  end
  tableFleets.properties.maxVisibleHeight = math.min(tableFleets:getFullHeight(), tableFleetsMaxHeight)

  if #fleets == 0 then
    row = tableFleets:addRow(nil, { fixed = false })
    local emptyText = texts.noFleetsAvailable
    row[2]:setColSpan(2):createText(emptyText, { halign = "center", color = Color["text_warning"] })
  else
    -- Restore scroll position if available
    pilotAcademy.setTopRow(tableFleets, tableName)
  end

  return
  {
    table = tableFleets,
    height = tableFleets.properties.maxVisibleHeight,
    fleetsCount = pilotAcademy.fleetsSave(displayData.academyData, displayData.editData, true)
  }
end

function pilotAcademy.fetchFleets()
  local fleets = {}
  local fleetsExists = {}
  local allShipsCount = C.GetNumAllFactionShips("player")
  local allShips = ffi.new("UniverseID[?]", allShipsCount)
  allShipsCount = C.GetAllFactionShips(allShips, allShipsCount, "player")
  local academyShips = pilotAcademy.fetchAllAcademyShipsForExclusion()
  for i = 0, allShipsCount - 1 do
    local shipId = ConvertStringTo64Bit(tostring(allShips[i]))
    local shipMacro, isDeployable, shipName, pilot, classId, idcode, icon, fleetName, sector = GetComponentData(shipId, "macro", "isdeployable", "name", "assignedaipilot",
      "classid", "idcode", "icon", "fleetname", "sector")
    local isLasertower, shipWare = GetMacroData(shipMacro, "islasertower", "ware")
    local isUnit = C.IsUnit(shipId)
    if shipWare and (not isUnit) and (not isLasertower) and (not isDeployable) and pilot and IsValidComponent(pilot) then
      local subordinates = GetSubordinates(shipId)
      local commander = GetCommander(shipId)
      if #subordinates > 0 and commander == nil then
        if academyShips[tostring(shipId)] ~= true then
          local candidate = {}
          candidate.commanderId = shipId
          candidate.commanderName = shipName
          candidate.commander = string.format("\027[%s] %s (%s)", icon, shipName, idcode)
          candidate.fleetName = fleetName or shipName
          candidate.sector = sector
          fleets[#fleets + 1] = candidate
          fleetsExists[shipId] = true
        end
      end
    end
  end
  table.sort(fleets, function(a, b) return a.fleetName < b.fleetName end)
  return fleets, fleetsExists
end

-- Helper: Create bottom buttons table
function pilotAcademy.createAcademyButtonsTable(frame, menu, config, tableName, canSave,  displayData)
  local tableBottom = pilotAcademy.createTable(frame, 7, tableName, false, false, menu, config)

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableBottom:addRow("buttons", { fixed = true })

  row[4]:createButton({ active = next(displayData.editData) ~= nil }):setText(texts.cancel, { halign = "center" })
  row[4].handlers.onClick = function() return pilotAcademy.buttonCancelAcademyChanges() end

  row[6]:createButton({
    active = hasItemsExcept(displayData.editData, "toChangeLocation") and displayData.locationId ~= nil and canSave == true
  }):setText(
    displayData.academyData.locationId ~= nil and texts.update or texts.create,
    { halign = "center" }
  )
  row[6].handlers.onClick = function() return pilotAcademy.buttonSaveAcademy() end

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableBottom, height = tableBottom:getFullHeight() }
end

-- Main function: Orchestrate academy info display
function pilotAcademy.displayAcademyInfo(frame, menu, config)
  trace("displayAcademyInfo called at " .. tostring(C.GetCurrentGameTime()))
  if frame == nil then
    trace("Frame is nil; cannot display wing info")
    return nil
  end
  if menu == nil or config == nil then
    trace("Menu or config is nil; cannot display wing info")
    return nil
  end

  local tables = {}

  -- Prepare display data
  local displayData = getAcademyDisplayData()

  -- Get factions and location data
  local factions = pilotAcademy.getFactions(config, false)
  local emptyText, locationOptions = pilotAcademy.fetchPotentialLocations(
    displayData.locationSelectable,
    displayData.academyData.locationId,
    factions
  )

  -- Create all UI sections
  tables[#tables + 1] = pilotAcademy.createAcademyHeaderTable(frame, menu, config, "table_academy_header")
  tables[#tables + 1] = pilotAcademy.createAcademyLocationTable(frame, menu, config, "table_academy_location", displayData, locationOptions, emptyText)
  tables[#tables + 1] = pilotAcademy.createTargetRankTable(frame, menu, config, "table_academy_rank", displayData)

  local autoHireResult = pilotAcademy.createAutoHireTable(frame, menu, config, "table_academy_autohire", displayData, factions)
  tables[#tables + 1] = autoHireResult

  -- Conditionally add factions table if auto-hire is enabled
  if #factions > 0 and autoHireResult.autoHire == true then
    tables[#tables + 1] = pilotAcademy.createAcademyFactionsTable(frame, menu, config, "table_academy_factions", displayData, factions)
  end


  local assignmentResult = pilotAcademy.createAssignmentTable(frame, menu, config, "table_academy_assignment", displayData, locationOptions)
  tables[#tables + 1] = assignmentResult

  local fleetsCount = 0
  if assignmentResult.assign == "perFleet" then
    local fleetResult = pilotAcademy.createFleetAssignmentTable(frame, menu, config, "table_academy_fleets", displayData)
    tables[#tables + 1] = fleetResult
    fleetsCount = fleetResult.fleetsCount
  end

  if assignmentResult.assign ~= "manual" then
    tables[#tables + 1] = pilotAcademy.createAssignOptionsTable(frame, menu, config, "table_academy_assignment_options", displayData)
  end

  tables[#tables + 1] = pilotAcademy.createAcademyButtonsTable(frame, menu, config, "table_academy_buttons", assignmentResult.assign ~= "perFleet" or fleetsCount > 0, displayData)
  return tables
end

function pilotAcademy.setTopRow(tableHandle, tableName)
  if pilotAcademy.frame ~= nil then
    for i = 1, #pilotAcademy.frame.content do
      local item = pilotAcademy.frame.content[i]
      if type(item) == "table" and item.type == "table" and item.name == tableName then
        local topRow = GetTopRow(item.id)
        if topRow ~= nil then
          trace(string.format("Set top row %d for table name %s", topRow, tableName))
          tableHandle:setTopRow(topRow)
        end
        break
      end
    end
  end
end

function pilotAcademy.fetchPotentialLocations(selectable, currentLocationId, factions)
  local locations = {}
  local stations = {}
  local emptyText = texts.noAvailableLocations
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
    local playerMoney = GetPlayerMoney()
    if playerMoney < pilotAcademy.commonData.rentCost then
      factions = {}
      emptyText = texts.insufficientFundsForRent
    end
    if #stations == 0 and #factions > 0 then
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
  return emptyText, locations
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
  if pilotAcademy.editData.factionsTable == nil or type(pilotAcademy.editData.factionsTable) ~= "table" then
    pilotAcademy.editData.factionsTable = {}
  end

  pilotAcademy.editData.factionsTable[factionId] = isSelected

  local menu = pilotAcademy.menuMap
  if menu ~= nil then
    menu.refreshInfoFrame()
  end
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

function pilotAcademy.onSelectFleet(fleetId, isSelected, savedData)
  trace("onSelectFleet called with fleetId: " .. tostring(fleetId) .. ", isSelected: " .. tostring(isSelected))
  if fleetId == nil then
    trace("fleetId is nil; cannot process")
    return
  else
    fleetId = ConvertStringTo64Bit(tostring(fleetId))
  end
  if pilotAcademy.editData.fleets == nil or type(pilotAcademy.editData.fleets) ~= "table" then
    pilotAcademy.editData.fleets = {}
  end

  pilotAcademy.editData.fleets[fleetId] = isSelected

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

function pilotAcademy.onToggleAutoFireLessSkilledCrewMember(checked)
  trace("Toggled auto fire less skilled crew member: " .. tostring(checked))
  pilotAcademy.editData.autoFireLessSkilledCrewMember = checked
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

function pilotAcademy.factionsSave(savedDate, editData)
  local factions = {}
  local factionsSaved = savedDate.factionsTable or {}
  local factionsEdit = editData.factionsTable or {}
  for factionId, _ in pairs(factionsSaved) do
    if factionsSaved[factionId] == true and factionsEdit[factionId] ~= false then
      factions[#factions + 1] = factionId
    end
  end

  for factionId, _ in pairs(factionsEdit) do
    if factionsEdit[factionId] == true and factionsSaved[factionId] ~= true then
      factions[#factions + 1] = factionId
    end
  end
  savedDate.factions = factions
  trace("Saving factions to saved data: " .. tostring(#factions) .. " factions saved")
  savedDate.factionsTable = nil
end

function pilotAcademy.factionsLoad(savedData)
  local factionsTable = {}
  if savedData.factions == nil then
    savedData.factions = {}
  end
  trace("Loading factions from saved data: " .. tostring(#savedData.factions) .. " factions found")
  for i = 1, #savedData.factions do
    local factionId = savedData.factions[i]
    if factionId ~= nil then
      factionsTable[factionId] = true
    end
  end
  savedData.factionsTable = factionsTable
end

function pilotAcademy.fleetsSave(savedDate, editData, countOnly)
  local fleetsSaved = savedDate.fleets or {}
  local fleetsEdit = editData.fleets or {}
  local fleetObjects = {}
  for fleetId, _ in pairs(fleetsSaved) do
    if fleetsSaved[fleetId] == true and fleetsEdit[fleetId] ~= false then
      fleetObjects[#fleetObjects + 1] = ConvertStringToLuaID(tostring(fleetId))
    end
  end

  for fleetId, _ in pairs(fleetsEdit) do
    if fleetsEdit[fleetId] == true and fleetsSaved[fleetId] ~= true then
      fleetObjects[#fleetObjects + 1] = ConvertStringToLuaID(tostring(fleetId))
    end
  end

  if countOnly ~= true then
    savedDate.fleetObjects = fleetObjects
    trace("Saving fleets to common data: " .. tostring(#fleetObjects) .. " fleet objects saved")
    savedDate.fleets = nil
  else
    trace("Counting fleets: " .. tostring(#fleetObjects) .. " fleet objects counted")
  end

  return #fleetObjects
end

function pilotAcademy.fleetsLoad()
  pilotAcademy.commonData.fleets = {}
  if pilotAcademy.commonData.fleetObjects == nil then
    pilotAcademy.commonData.fleetObjects = {}
  end
  trace("Loading fleets from common data: " .. tostring(#pilotAcademy.commonData.fleetObjects) .. " fleet objects found")
  for i = 1, #pilotAcademy.commonData.fleetObjects do
    local fleetObject = pilotAcademy.commonData.fleetObjects[i]
    if fleetObject ~= nil then
      local fleetId = ConvertStringTo64Bit(tostring(fleetObject))
      pilotAcademy.commonData.fleets[fleetId] = true
    end
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

  trace("Existing location ID: " .. tostring(academyData.locationId) .. "Updated location ID: " .. tostring(editData.locationId))
  local toPayRent = false
  if editData.locationId ~= nil then
    local newLocationId = ConvertStringTo64Bit(tostring(editData.locationId))
    pilotAcademy.transferPersonnel(academyData.locationId, newLocationId)
    if academyData.locationId ~= nil then
      academyData.rentCost = 0
      academyData.rentLastPaid = 0
    end
    toPayRent = academyData.locationId ~= newLocationId
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

  pilotAcademy.factionsSave(academyData, editData)

  if editData.assign ~= nil then
    academyData.assign = editData.assign
  end
  if academyData.assign == nil then
    academyData.assign = "manual"
  end

  pilotAcademy.fleetsSave(academyData, editData, false)

  if editData.assignPriority ~= nil then
    academyData.assignPriority = editData.assignPriority
  end
  if academyData.assignPriority == nil then
    academyData.assignPriority = "priority_small_to_large"
  end

  if editData.autoFireLessSkilledCrewMember ~= nil then
    academyData.autoFireLessSkilledCrewMember = editData.autoFireLessSkilledCrewMember
  end
  if academyData.autoFireLessSkilledCrewMember == nil then
    academyData.autoFireLessSkilledCrewMember = false
  end

  pilotAcademy.editData = {}

  pilotAcademy.saveCommonData()
  if toPayRent then
    pilotAcademy.payRent()
  end
  if rankLevelChanged then
    SignalObject(pilotAcademy.playerId, "PilotAcademyRAndR.TargetRankLevelChangedSignal")
  end
  pilotAcademy.editData = {}
  menu.refreshInfoFrame()
end

function pilotAcademy.payRent(skipSave)
  trace("payRent called")

  pilotAcademy.loadCommonData()

  skipSave = skipSave or false

  local academyData = pilotAcademy.commonData or {}
  if academyData.locationId == nil then
    trace("No location ID for pilot academy; cannot pay rent")
    return
  end


  local owner = GetComponentData(academyData.locationId, "owner")
  if owner == "player" then
    trace("Pilot academy located at player-owned station; no rent to pay")
    return
  end

  pilotAcademy.setRentCost()

  local currentTime = C.GetCurrentGameTime()
  local rentLastPaid = academyData.rentLastPaid or 0

  local timeElapsed = currentTime - rentLastPaid
  if timeElapsed >= pilotAcademy.rentInterval then
    local numIntervals = math.floor(timeElapsed / pilotAcademy.rentInterval)
    local totalRent = academyData.rentCost * numIntervals
    C.AddPlayerMoney(-totalRent * 100)
  end
  academyData.rentLastPaid = currentTime
  if skipSave then
    return
  end
  pilotAcademy.saveCommonData()
end

function pilotAcademy.setRentCost()
  if pilotAcademy.commonData == nil then
    return false
  end
  if pilotAcademy.commonData.rentCost == nil or pilotAcademy.commonData.rentCost <= 0 then
    pilotAcademy.commonData.rentCost = pilotAcademy.calculateHiringFee(40)
    return true
  end

  return false
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

function pilotAcademy.combineSelections(field, editData, savedData)
  local selectedItems = {}
  if editData[field] ~= nil and type(editData[field]) == "table" then
    for i = 1, #editData[field] do
      local content = editData[field][i]
      selectedItems[content] = true
    end
  elseif savedData[field] ~= nil and type(savedData[field]) == "table" then
    for i = 1, #savedData[field] do
      local content = savedData[field][i]
      selectedItems[content] = true
    end
  end
  return selectedItems
end

function pilotAcademy.skillBase(skill)
  return skill * 15.0 / 300
end

-- Helper: Create personnel list table (cadets or pilots)
function pilotAcademy.createPersonnelListTable(frame, menu, config, tableName, personnel, title)
  local tablePersonnel = pilotAcademy.createTable(frame, 4, tableName, true, false, menu, config)

  tablePersonnel:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tablePersonnel:addRow(nil, { fixed = true })
  row[2]:setColSpan(2):createText(title, Helper.headerRowCenteredProperties)

  -- Add personnel rows
  local tablePersonnelMaxHeight = 0
  for i = 1, #personnel do
    local person = personnel[i]
    if person ~= nil then
      row = tablePersonnel:addRow({ tableName = tablePersonnel.name, rowData = person }, { fixed = false })
      local icon = row[2]:setColSpan(2):createIcon(person.icon, {
        height = config.mapRowHeight,
        width = config.mapRowHeight,
        color = person.hasArrived and Color["text_normal"] or Color["text_inactive"]
      })
      icon:setText(person.name, {
        x = config.mapRowHeight,
        halign = "left",
        color = person.hasArrived and Color["text_normal"] or Color["text_inactive"]
      })
      icon:setText2(person.skillInStars, {
        halign = "right",
        color = person.hasArrived and Color["text_skills"] or Color["text_inactive"]
      })

      if i == 15 then
        tablePersonnelMaxHeight = tablePersonnel:getFullHeight()
      end
    end
  end

  -- Handle empty state
  if #personnel == 0 then
    row = tablePersonnel:addRow(nil, { fixed = false })
    local emptyText = title == texts.pilots and texts.noPilotsAvailable or texts.noCadetsAssigned
    row[2]:setColSpan(2):createText(emptyText, { halign = "center", color = Color["text_warning"] })
  else
    -- Restore scroll position if available
    pilotAcademy.setTopRow(tablePersonnel, tableName)
  end

  -- Set max visible height
  if tablePersonnelMaxHeight == 0 then
    tablePersonnelMaxHeight = tablePersonnel:getFullHeight()
  end
  tablePersonnel.properties.maxVisibleHeight = math.min(tablePersonnel:getFullHeight(), tablePersonnelMaxHeight)

  return { table = tablePersonnel, height = tablePersonnel.properties.maxVisibleHeight }
end

-- Helper: Create personnel bottom spacing table
function pilotAcademy.createPersonnelBottomTable(frame, menu, config, tableName)
  local tableBottom = pilotAcademy.createTable(frame, 4, tableName, false, false, menu, config)

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableBottom, height = tableBottom:getFullHeight() }
end

-- Main function: Orchestrate personnel info display
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

  -- Fetch personnel data
  local cadets, pilots = pilotAcademy.fetchAcademyPersonnel()

  -- Create all UI sections
  tables[#tables + 1] = pilotAcademy.createAcademyHeaderTable(frame, menu, config, "table_personnel_header", texts.cadetsAndPilotsTitle)
  tables[#tables + 1] = pilotAcademy.createPersonnelListTable(frame, menu, config, "table_personnel_cadets", cadets, texts.cadets)
  tables[#tables + 1] = pilotAcademy.createPersonnelListTable(frame, menu, config, "table_personnel_pilots", pilots, texts.pilots)
  tables[#tables + 1] = pilotAcademy.createPersonnelBottomTable(frame, menu, config, "table_personnel_bottom")

  return tables
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
          if hasArrived == true then
            trace("Person has arrived at non-player-owned location; checking entity ownership")
            entity = pilotAcademy.getOrCreateEntity(personId, locationId)
            if isPlayerOwned ~= true and entity ~= nil then
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
  local changed = false
  if pilotAcademy.playerId == nil or pilotAcademy.playerId == 0 then
    debug("loadCommonData: unable to resolve player id")
    return false
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

  debug("loadCommonData: locationId is " .. tostring(pilotAcademy.commonData.locationId))
  if pilotAcademy.commonData.autoHire == 1 then
    pilotAcademy.commonData.autoHire = true
  else
    pilotAcademy.commonData.autoHire = false
  end

  pilotAcademy.factionsLoad(pilotAcademy.commonData)

  pilotAcademy.fleetsLoad()

  if pilotAcademy.commonData.autoFireLessSkilledCrewMember == 1 then
    pilotAcademy.commonData.autoFireLessSkilledCrewMember = true
  else
    pilotAcademy.commonData.autoFireLessSkilledCrewMember = false
  end

  if pilotAcademy.commonData.lastAutoAssignTime == nil then
    pilotAcademy.commonData.lastAutoAssignTime = C.GetCurrentGameTime()
  end

  if pilotAcademy.commonData.notificationsEnabled == nil then
    pilotAcademy.commonData.notificationsEnabled = 1
    changed = true
  end

  if pilotAcademy.commonData.logbookEnabled == nil then
    pilotAcademy.commonData.logbookEnabled = 1
    changed = true
  end

  return changed
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

function pilotAcademy.onDebugLevelChanged(event)
  if event == "PilotAcademyRAndR.DebugLevelChanged" then
    pilotAcademy.loadCommonData()
  end
  if pilotAcademy.commonData ~= nil then
    debugLevel = pilotAcademy.commonData.debugLevel or "none"
  end
end

-- Helper: Extract and prepare wing display data
local function getWingDisplayData()
  local wings = pilotAcademy.wings or {}
  local wingId = pilotAcademy.selectedTab
  local existingWing = wingId ~= nil and wings[wingId] ~= nil
  return {
    wingId = wingId,
    existingWing = existingWing,
    wingData = existingWing and wings[wingId] or {},
    editData = pilotAcademy.editData or {},
    primaryGoal = nil,  -- Will be set by caller
    refreshInterval = nil,  -- Will be set by caller
    wingLeaderId = nil  -- Will be set by caller
  }
end

-- Helper: Create wing header table with primary goal dropdown
function pilotAcademy.createWingPrimaryGoalTable(frame, menu, config, tableName, wingDisplayData)
  local tableGoal = pilotAcademy.createTable(frame, 12, tableName, false, false, menu, config)

  local row = tableGoal:addRow("wing_primary_goal", { fixed = true })
  local primaryGoalOptions = {
    { id = "rank",     icon = "", text = texts.increaseRank,   text2 = "", displayremoveoption = false },
    { id = "relation", icon = "", text = texts.gainReputation, text2 = "", displayremoveoption = false },
  }
  row[2]:setColSpan(5):createText(texts.primaryGoal, { halign = "left", titleColor = Color["row_title"] })
  row[7]:setColSpan(5):createDropDown(primaryGoalOptions, {
    startOption = wingDisplayData.primaryGoal or -1,
    active = true,
    textOverride = (#primaryGoalOptions == 0) and texts.noAvailablePrimaryGoals or nil,
  })
  row[7]:setTextProperties({ halign = "left" })
  row[7].handlers.onDropDownActivated = function() menu.noupdate = true end
  row[7].handlers.onDropDownConfirmed = function(_, id)
    menu.noupdate = false
    return pilotAcademy.onSelectPrimaryGoal(id)
  end
  tableGoal:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableGoal, height = tableGoal:getFullHeight() }
end

-- Helper: Create factions table with restore capability
function pilotAcademy.createWingFactionsSection(frame, menu, config, tableName, wingDisplayData, factions)
  local tableFactions = pilotAcademy.createTable(frame, 12, tableName, true, false, menu, config)

  local row = tableFactions:addRow(nil, { fixed = true })
  row[2]:setColSpan(10):createText(texts.factions, { halign = "left", titleColor = Color["row_title"] })

  pilotAcademy.displayFactions(tableFactions, factions, wingDisplayData.editData, wingDisplayData.wingData, config)

  -- Restore scroll position if available
  pilotAcademy.setTopRow(tableFactions, tableName)

  return { table = tableFactions, height = tableFactions.properties.maxVisibleHeight }
end

-- Helper: Create refresh interval table
function pilotAcademy.createWingRefreshIntervalTable(frame, menu, config, tableName, wingDisplayData)
  local tableRefreshInterval = pilotAcademy.createTable(frame, 12, tableName, false, false, menu, config)

  tableRefreshInterval:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableRefreshInterval:addRow(nil, { fixed = true })
  row[2]:setColSpan(10):createText(texts.tradeDataRefreshInterval, { halign = "left", titleColor = Color["row_title"] })

  local refreshIntervalOptions = pilotAcademy.getRefreshIntervalOptions()
  row = tableRefreshInterval:addRow("wing_refresh_interval", { fixed = true })
  row[1]:createText("", { halign = "left" })
  row[2]:setColSpan(10):createDropDown(refreshIntervalOptions, {
    startOption = wingDisplayData.refreshInterval or -1,
    active = true,
    textOverride = (#refreshIntervalOptions == 0) and "0" or nil,
  })
  row[2]:setTextProperties({ halign = "right" })
  row[2].handlers.onDropDownActivated = function() menu.noupdate = true end
  row[2].handlers.onDropDownConfirmed = function(_, id)
    menu.noupdate = false
    return pilotAcademy.onSelectRefreshInterval(id)
  end
  tableRefreshInterval:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableRefreshInterval, height = tableRefreshInterval:getFullHeight() }
end

-- Helper: Create wing leader table
function pilotAcademy.createWingLeaderTable(frame, menu, config, tableName, wingDisplayData)
  local tableWingLeader = pilotAcademy.createTable(frame, 12, tableName, wingDisplayData.existingWing, false, menu, config)

  local row = tableWingLeader:addRow(nil, { fixed = true })
  local wingLeaderOptions = pilotAcademy.fetchPotentialWingmans(wingDisplayData.existingWing, wingDisplayData.wingLeaderId)
  row[2]:setColSpan(10):createText(texts.wingLeader, { halign = "left", titleColor = Color["row_title"] })

  if wingDisplayData.existingWing then
    -- Display existing wing leader
    local leaderInfo = wingLeaderOptions[1] or {}
    local bgColor = nil
    local selectedShip = pilotAcademy.selectedShips[tableWingLeader.name] or nil
    if selectedShip and leaderInfo.id == selectedShip then
      bgColor = Color["row_background_selected"]
    end
    row = tableWingLeader:addRow({ tableName = tableWingLeader.name, rowData = leaderInfo }, { fixed = false, bgColor = bgColor })
    row[1]:createText("", { halign = "left" })
    local icon = row[2]:setColSpan(10):createIcon("order_pilotacademywing", { height = config.mapRowHeight, width = config.mapRowHeight })
    icon:setText(leaderInfo.text, { x = config.mapRowHeight, halign = "left", color = Color["text_normal"] })
    icon:setText2(leaderInfo.text2, { halign = "right", color = Color["text_skills"] })
  else
    -- Dropdown for selecting new wing leader
    row = tableWingLeader:addRow("wing_leader", { fixed = true })
    row[1]:createText("", { halign = "left" })
    row[2]:setColSpan(10):createDropDown(wingLeaderOptions, {
      startOption = wingDisplayData.wingLeaderId or -1,
      active = not wingDisplayData.existingWing,
      textOverride = (#wingLeaderOptions == 0) and texts.noAvailableWingLeaders or nil,
    })
    row[2]:setTextProperties({ halign = "left" })
    row[2]:setText2Properties({ halign = "right", color = Color["text_skills"] })
    row[2].handlers.onDropDownActivated = function() menu.noupdate = true end
    row[2].handlers.onDropDownConfirmed = function(_, id)
      menu.noupdate = false
      return pilotAcademy.onSelectWingLeader(id)
    end
  end

  return { table = tableWingLeader, height = tableWingLeader:getFullHeight() }
end

-- Helper: Create wingmans management table
function pilotAcademy.createWingmansTable(frame, menu, config, tableName, wingDisplayData)

  local tableWingmans = pilotAcademy.createTable(frame, 12, tableName, true, false, menu, config)

  tableWingmans:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local tableWingmansMaxHeight = 0
  local wingmans = {}
  local mimicGroupId = nil

  if wingDisplayData.existingWing then
    -- Add wingman dropdown
    local row = tableWingmans:addRow(nil, { fixed = true })
    row[2]:setColSpan(10):createText(texts.addWingman, { halign = "left", titleColor = Color["row_title"] })

    local addWingmanOptions = pilotAcademy.fetchPotentialWingmans(wingDisplayData.existingWing, nil)
    mimicGroupId, wingmans = pilotAcademy.fetchWingmans(wingDisplayData.wingLeaderId)

    row = tableWingmans:addRow("add_wingman", { fixed = true })
    row[1]:createText("", { halign = "left" })
    row[2]:setColSpan(10):createDropDown(addWingmanOptions, {
      startOption = wingDisplayData.wingLeaderId or -1,
      active = wingDisplayData.existingWing,
      textOverride = (#addWingmanOptions == 0) and texts.noAvailableWingmanCandidates or nil,
    })
    row[2]:setTextProperties({ halign = "left" })
    row[2]:setText2Properties({ halign = "right", color = Color["text_skills"] })
    row[2].handlers.onDropDownActivated = function() menu.noupdate = true end
    row[2].handlers.onDropDownConfirmed = function(_, id)
      menu.noupdate = false
      return pilotAcademy.onSelectWingman(id, wingDisplayData.wingLeaderId, mimicGroupId)
    end

    tableWingmans:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

    -- Display existing wingmans
    row = tableWingmans:addRow(nil, { fixed = true })
    row[2]:setColSpan(10):createText(texts.wingmans, { halign = "left", titleColor = Color["row_title"] })
    local selectedShip = pilotAcademy.selectedShips[tableName] or nil
    for i = 1, #wingmans do
      local wingman = wingmans[i]
      if wingman ~= nil then
        local bgColor = nil
        if selectedShip and wingman.id == selectedShip then
          bgColor = Color["row_background_selected"]
        end
        row = tableWingmans:addRow({ tableName = tableWingmans.name, rowData = wingman }, { fixed = false, bgColor = bgColor })
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

  -- Restore scroll position if available
  local wingKey = tostring(pilotAcademy.selectedTab)
  if #wingmans > 0 then
    pilotAcademy.setTopRow(tableWingmans, tableName)
  end

  return { table = tableWingmans, height = tableWingmans.properties.maxVisibleHeight }
end

-- Helper: Create bottom buttons table
function pilotAcademy.createWingButtonsTable(frame, menu, config, tableName, wingDisplayData)
  local tableBottom = pilotAcademy.createTable(frame, 7, tableName, false, false, menu, config)

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
  local row = tableBottom:addRow("buttons", { fixed = true })

  if wingDisplayData.existingWing then
    row[2]:createButton({ active = next(wingDisplayData.editData) == nil }):setText(texts.dismissWing, { halign = "center" })
    row[2].handlers.onClick = function() return pilotAcademy.buttonDismissWing() end
  end

  row[4]:createButton({ active = next(wingDisplayData.editData) ~= nil }):setText(texts.cancel, { halign = "center" })
  row[4].handlers.onClick = function() return pilotAcademy.buttonCancelChanges() end

  row[6]:createButton({ active = next(wingDisplayData.editData) ~= nil and wingDisplayData.wingLeaderId ~= nil }):setText(
    wingDisplayData.existingWing and texts.update or texts.create, { halign = "center" })
  row[6].handlers.onClick = function() return pilotAcademy.buttonSaveWing() end

  tableBottom:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })

  return { table = tableBottom, height = tableBottom:getFullHeight() }
end

-- Main function: Orchestrate wing info display
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

  -- Prepare display data
  local wingDisplayData = getWingDisplayData()
  wingDisplayData.primaryGoal = wingDisplayData.editData.primaryGoal or wingDisplayData.wingData.primaryGoal or "rank"
  wingDisplayData.refreshInterval = wingDisplayData.editData.refreshInterval or wingDisplayData.wingData.refreshInterval or 30
  wingDisplayData.wingLeaderId = wingDisplayData.editData.wingLeaderId or wingDisplayData.wingData.wingLeaderId or nil


  -- Get factions data
  local factions = pilotAcademy.getFactions(config, true)

  local suffix = string.format(wingDisplayData.wingId ~= nil and texts.wing or texts.addNewWing,
    wingDisplayData.existingWing and texts.wingNames[wingDisplayData.wingId] or "")
  local titleText = string.format("%s: %s", texts.pilotAcademy, suffix)
  -- Create all UI sections
  tables[#tables + 1] = pilotAcademy.createAcademyHeaderTable(frame, menu, config, "table_wing_header", titleText)
  tables[#tables + 1] = pilotAcademy.createWingPrimaryGoalTable(frame, menu, config, "table_wing_primary_goal", wingDisplayData)
  
  local factionsTableName = string.format("table_wing_%s_factions", tostring(wingDisplayData.wingId or "new"))
  tables[#tables + 1] = pilotAcademy.createWingFactionsSection(frame, menu, config, factionsTableName, wingDisplayData, factions)

  tables[#tables + 1] = pilotAcademy.createWingRefreshIntervalTable(frame, menu, config, "table_refresh_interval", wingDisplayData)
  local wingLeaderTableName = string.format("table_wing_%s_leader", tostring(wingDisplayData.wingId or "new"))

  tables[#tables + 1] = pilotAcademy.createWingLeaderTable(frame, menu, config, wingLeaderTableName, wingDisplayData)
  
  local wingmansTableName = string.format("table_wing_%s_wingmans", tostring(wingDisplayData.wingId or "new"))
  tables[#tables + 1] = pilotAcademy.createWingmansTable(frame, menu, config, wingmansTableName, wingDisplayData)

  tables[#tables + 1] = pilotAcademy.createWingButtonsTable(frame, menu, config, "table_wing_bottom", wingDisplayData)

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

function pilotAcademy.getRefreshIntervalOptions()
  local options = {}
  for i = 1, #pilotAcademy.tradeDataRefreshIntervals do
    local interval = pilotAcademy.tradeDataRefreshIntervals[i]
    options[#options + 1] = {
      id = tostring(interval),
      icon = "",
      text = string.format("%d %s", interval, ReadText(1001, 103)), -- "minutes"
      text2 = "",
      displayremoveoption = false,
    }
  end
  return options
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

function pilotAcademy.getTableFromUI(uiTable)
  local tableHandle = nil
  if pilotAcademy.frame == nil or type(pilotAcademy.frame.content) ~= "table" or #pilotAcademy.frame.content == 0 then
    return tableHandle
  end
  for i = 1, #pilotAcademy.frame.content do
    if pilotAcademy.frame.content[i].id == uiTable then
      tableHandle = pilotAcademy.frame.content[i]
      -- trace("Found matching table in frame content at index " .. tostring(i))
      break
    end
  end
  return tableHandle
end

function pilotAcademy.getTableFromByName(tableName)
  local tableHandle = nil
  if pilotAcademy.frame == nil or type(pilotAcademy.frame.content) ~= "table" or #pilotAcademy.frame.content == 0 then
    return tableHandle
  end
  for i = 1, #pilotAcademy.frame.content do
    if pilotAcademy.frame.content[i].name == tableName then
      tableHandle = pilotAcademy.frame.content[i]
      -- trace("Found matching table in frame content at index " .. tostring(i))
      break
    end
  end
  return tableHandle
end

function pilotAcademy.resetTableSelection(currentTableName)
  local tableName = pilotAcademy.selectedRow and next(pilotAcademy.selectedRow) and next(pilotAcademy.selectedRow) or nil
  if tableName ~= nil and (currentTableName == nil or tableName ~= currentTableName) then
    local tableToClear = pilotAcademy.getTableFromByName(tableName)
    if tableToClear ~= nil then
      SelectRow(tableToClear.id, pilotAcademy.selectedRow[tableName])
      tableToClear.selectedrow = 0
    end
    pilotAcademy.selectedRow = {}
  end
end

function pilotAcademy.onRowChanged(row, rowData, uiTable, modified, input, source)
  -- trace("pilotAcademy.onRowChanged called for row " .. tostring(row) .. " with modified: " .. tostring(modified) .. " and source: " .. tostring(source))

  local menu = pilotAcademy.menuMap
  if menu == nil then
    return
  end
  if menu.infoTableMode ~= pilotAcademy.academySideBarInfo.mode then
    return
  end
  if pilotAcademy.frame == nil or type(pilotAcademy.frame.content) ~= "table" or #pilotAcademy.frame.content == 0 then
    return
  end

  trace("Looking for matching table in frame content for uiTable " .. tostring(uiTable))
  local table = pilotAcademy.getTableFromUI(uiTable)

  if table == nil or table.name == nil then
    trace("No matching table found in frame content for uiTable " .. tostring(uiTable))
    return
  end


  if source == "auto" then
    trace("Row change source is auto; attempting to restore previous selection for table " .. tostring(uiTable) .. " stored :" .. tostring(next(pilotAcademy.selectedRow)))
    if pilotAcademy.selectedRow[table.name] ~= nil then
      SelectRow(uiTable, pilotAcademy.selectedRow[table.name], nil, nil, nil, true)
      trace("Auto-selecting previously selected row " .. tostring(pilotAcademy.selectedRow[table.name]) .. " for table " .. tostring(uiTable)  .. " name: " .. tostring(table.name))
    end
    return
  end

  pilotAcademy.resetTableSelection(table and table.name or nil)
  pilotAcademy.selectedRow = {}
  if table.isSelectable == false then
    trace("Table " .. tostring(uiTable) .. " name: " .. tostring(table.name) .. " is not selectable; skipping selection update")
    return
  end
  trace("Updating selected row for table " .. tostring(uiTable) .. " name: " .. tostring(table.name) .. " to row " .. tostring(row))
  pilotAcademy.selectedRow[table.name] = row
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
  local table = pilotAcademy.getTableFromUI(uiTable)
  if table == nil then
    trace("No matching table found in frame content for uiTable " .. tostring(uiTable))
    return
  end

  local tableName = table.name
  local rowData = selectedData.rowData
  if tableName == nil then
    trace("Table name is nil; cannot process onSelectElement")
    return
  end

  pilotAcademy.resetTableSelection(tableName)

  if rowData == nil then
    trace("Row data is nil; cannot process onSelectElement")
    return
  end
  if tableName:match("table_wing_.*_leader") or tableName:match("table_wing_.*_wingmans") or tableName == "table_academy_fleets" then
    local shipId = rowData.id or rowData.commanderId
    if shipId == nil then
      trace("Row data id is nil; cannot process onSelectElement")
      return
    end
    local unselect = pilotAcademy.selectedShips[tableName] == shipId
    if isDoubleClick or (input ~= "mouse") then
      trace("Double click or non-mouse input detected; setting focus to component " .. tostring(shipId))
      C.SetFocusMapComponent(menu.holomap, ConvertStringTo64Bit(tostring(shipId)), true)
      unselect = false
    end
    trace("Single click detected; selecting component " .. tostring(shipId))
    menu.selectedcomponents = {}
    if unselect then
      pilotAcademy.selectedShips[tableName] = nil
    else
      pilotAcademy.selectedShips = {}
      pilotAcademy.selectedShips[tableName] = shipId
      menu.addSelectedComponent(shipId, true, true)
    end
    menu.setSelectedMapComponents()
    menu.refreshInfoFrame()
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
  if tableName:match("table_wing_.*_leader") or tableName:match("table_wing_.*_wingmans") or tableName == "table_academy_fleets" then
    config = pilotAcademy.menuMapConfig
    menu.contextMenuMode = "academyShip"
    if posX == nil or posY == nil then
      posX, posY = GetLocalMousePosition()
    end
    menu.contextMenuData = {
      width = Helper.scaleX(interactMenuConfig.width),
      xoffset = posX + Helper.viewWidth / 2,
      yoffset = Helper.viewHeight / 2 - posY,
      instance = menu.instance,
      tableName = tableName,
      rowData = rowData
    }
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
    menu.contextMenuData = {
      width = Helper.scaleX(interactMenuConfig.width),
      xoffset = posX + Helper.viewWidth / 2,
      yoffset = Helper.viewHeight / 2 - posY,
      instance = menu.instance,
      person = rowData.id,
      component = pilotAcademy.commonData.locationId,
      tableName = tableName,
      rowData = rowData,
      isAcademyPersonnel = true
    }

    menu.createContextFrame()
  end
end

function pilotAcademy.createInfoFrameContext(contextFrame, contextMenuData, contextMenuMode)
  trace("createInfoFrameContext called with mode: " .. tostring(contextMenuMode))
  if contextFrame == nil then
    trace("Context frame is nil; cannot create ship context menu")
    return
  end
  if contextMenuMode == "academyShip" then
    pilotAcademy.createShipContextMenu(contextFrame, contextMenuData)
  end
end

function pilotAcademy.createShipContextMenu(contextFrame, contextMenuData)
  trace("createShipContextMenu called")

  if contextMenuData == nil or type(contextMenuData) ~= "table" then
    trace("Context menu data is nil or invalid; cannot create ship context menu")
    return
  end
  local rowData = contextMenuData.rowData
  if rowData == nil then
    trace("Row data is nil; cannot create ship context menu")
    return
  end

  local shipId = rowData.id or rowData.commanderId
  if shipId == nil then
    trace("Ship id is nil; cannot create ship context menu")
    return
  end
  shipId = ConvertStringTo64Bit(tostring(shipId))
  local commander = GetCommander(shipId)

  local menu = pilotAcademy.menuInteractMenu
  local config = pilotAcademy.menuInteractMenuConfig
  if menu == nil or config == nil then
    trace("Menu or config is nil; cannot create ship context menu")
    return
  end

  local menuMap = pilotAcademy.menuMap

  local holomapColor = menu.holomapcolor
  if holomapColor == nil or holomapColor.playercolor == nil then
    holomapColor = Helper.getHoloMapColors()
  end
  local commanderId = ConvertStringTo64Bit(tostring(commander))
  local commanderShortName = commander and ffi.string(C.GetComponentName(commanderId)) or ""
  commanderShortName = Helper.convertColorToText(holomapColor.playercolor) .. commanderShortName
  local commanderName = commanderShortName .. " (" .. (commander and ffi.string(C.GetObjectIDCode(commanderId)) or "") .. ")"
  local x = 0
  local menuWidth = menu.width or Helper.scaleX(config.width)
  local text = ffi.string(C.GetComponentName(shipId))
  local color = holomapColor.playercolor
  local ftable = contextFrame:addTable(5,
    {
      tabOrder = 2,
      x = x,
      width = menuWidth,
      backgroundID = "solid",
      backgroundColor = Color["frame_background_semitransparent"],
      highlightMode = "offnormalscroll"
    })
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

  if menuMap ~= nil then
    row = ftable:addRow(true, {})
    local button = row[1]:setColSpan(5):createButton({
      bgColor = Color["button_background_hidden"],
      highlightColor = Color["button_highlight_default"],
      mouseOverText = "",
      -- helpOverlayID = entry.helpOverlayID,
      -- helpOverlayText = entry.helpOverlayText,
      -- helpOverlayHighlightOnly = entry.helpOverlayHighlightOnly,
    }):setText(ReadText(1001, 2427), { color = Color["text_normal"] })
    row[1].handlers.onClick = function()
      if pilotAcademy.contextFrame ~= nil then
        pilotAcademy.contextFrame:close()
        pilotAcademy.contextFrame = nil
      end
      menuMap.openDetails(shipId)
      menuMap.closeContextMenu()
    end
    height = height + row:getHeight() + Helper.borderSize
  end

  if commander ~= nil then
    if menuMap ~= nil then
      ftable:addEmptyRow(Helper.standardTextHeight / 2, { fixed = true })
      height = height + Helper.standardTextHeight / 2 + Helper.borderSize
    end
    row = ftable:addRow(false, {})
    row[1]:createText(string.format(ReadText(1001, 7803), commanderShortName),
      { font = Helper.standardFontBold, mouseOverText = commanderName, titleColor = Color["row_title"] })

    row[4]:createText("[" .. GetComponentData(shipId, "assignmentname") .. "]",
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
    row[1].handlers.onClick = function() return pilotAcademy.wingmanRemoveAssignment(shipId) end
    height = height + row:getHeight() + Helper.borderSize
  end
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
  SignalObject(wingmanId, "PilotAcademyRAndR.RemoveFromWingRequest")
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

function pilotAcademy.onSelectRefreshInterval(id)
  trace("onSelectRefreshInterval called with id: " .. tostring(id))
  if id == nil then
    trace("id is nil; cannot process")
    return
  end
  local interval = tonumber(id)
  if interval == nil then
    trace("id could not be converted to number; cannot process")
    return
  end
  pilotAcademy.editData.refreshInterval = interval
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
  local wingId = pilotAcademy.selectedTab
  pilotAcademy.dismissWing(wingId)
  local menu = pilotAcademy.menuMap
  if menu == nil then
    trace("Menu is nil; cannot refresh info frame")
    return
  end
  menu.refreshInfoFrame()
end

function pilotAcademy.dismissWing(wingId)
  trace("dismissWing called for wingId: " .. tostring(wingId))
  local wings = pilotAcademy.wings
  if wings == nil then
    trace("Wings is nil; cannot dismiss wing")
    return
  end
  if wingId == nil or wingId == "settings" or wingId == "personnel" then
    trace("No wing selected or invalid index; cannot dismiss wing")
    return
  end
  if wings[wingId] and wings[wingId].wingLeaderId ~= nil then
    SignalObject(wings[wingId].wingLeaderId, "PilotAcademyRAndR.DismissWingRequest")
    local name, idcode = GetComponentData(wings[wingId].wingLeaderId, "name", "idcode")
    C.SetFleetName(wings[wingId].wingLeaderId, string.format("%s (%s)", name, idcode))
  end
  wings[wingId] = nil
  local currentWingIsSelected = pilotAcademy.selectedTab == wingId
  if next(wings) == nil then
    if pilotAcademy.selectedTab ~= "settings" and pilotAcademy.selectedTab ~= "personnel" then
      pilotAcademy.selectedTab = nil
    end
  elseif currentWingIsSelected then
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
  if editData.refreshInterval ~= nil then
    wingData.refreshInterval = editData.refreshInterval
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
    pilotAcademy.selectedTab = wingId
  end

  pilotAcademy.factionsSave(wingData, editData)
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
      SignalObject(wingLeaderId, "PilotAcademyRAndR.WingDataIsUpdatedSignal")
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
    SetOrderParam(wingLeaderId, "planneddefault", 1, nil, wingId)
    SetOrderParam(wingLeaderId, "planneddefault", 2, nil, true)
    SetOrderParam(wingLeaderId, "planneddefault", 3, nil, debugLevel == 'debug' or debugLevel == 'trace')
    C.EnablePlannedDefaultOrder(wingLeaderId, false)
  end
  C.SetFleetName(wingLeaderId, string.format(texts.wingFleetName, texts.wingNames[wingId]))
end

function pilotAcademy.CheckOrdersOnWings()
  pilotAcademy.loadWings()
  local wings = pilotAcademy.wings or {}
  for wingId, wingData in pairs(wings) do
    local wingIsOk = false
    local wingLeaderId = wingData.wingLeaderId
    if wingLeaderId ~= nil then
      trace("Checking orders for wing leader " .. tostring(GetComponentData(wingLeaderId, "name")) .. " of wing " .. tostring(wingId))
      for i = 1, 2 do
        local buf = ffi.new("Order")
        local isDefaultOrder = nil
        if i == 1 then
          isDefaultOrder = C.GetDefaultOrder(buf, wingLeaderId)
        else
          isDefaultOrder = C.GetPlannedDefaultOrder(buf, wingLeaderId)
        end
        if isDefaultOrder then
          local currentOrderDef = ffi.string(buf.orderdef)
          local orderDefinition = ffi.new("OrderDefinition")
          if currentOrderDef ~= nil and C.GetOrderDefinition(orderDefinition, currentOrderDef) then
            local orderId = ffi.string(orderDefinition.id)
            if orderId == pilotAcademy.orderId then
              wingIsOk = true
              break
            end
          end
        end
      end
    end
    if not wingIsOk and wingLeaderId ~= nil then
      wingData.errorsCount = (wingData.errorsCount or 0) + 1
      debug("Wing leader " ..
        tostring(GetComponentData(wingData.wingLeaderId, "name")) ..
        " of wing " ..
        tostring(wingId) .. " is missing proper orders for its wing leader; reapplying orders. Current errors count: " .. tostring(wingData.errorsCount or 0))
      if wingData.errorsCount ~= nil and wingData.errorsCount >= pilotAcademy.maxOrderErrors then
        debug("Maximum order errors reached for wing leader " ..
          tostring(GetComponentData(wingData.wingLeaderId, "name")) .. " of wing " .. tostring(wingId) .. "; skipping reapplication of orders")
        pilotAcademy.dismissWing(wingId)
        local subordinates = GetSubordinates(wingLeaderId)
        if #subordinates > 0 then
          C.SetFleetName(wingLeaderId, string.format(texts.wingBroken, texts.wingNames[wingId]))
        end
        SignalObject(pilotAcademy.playerId, "PilotAcademyRAndR.WingIsBrokenInfo", texts.wingNames[wingId], ConvertStringToLuaID(tostring(wingLeaderId)))
      else
        pilotAcademy.setOrderForWingLeader(wingData.wingLeaderId, wingId, true)
      end
    else
      wingData.errorsCount = 0
    end
  end
  pilotAcademy.saveWings()
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
    pilotAcademy.factionsLoad(wing)
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
    transferScheduled = false -- Not relevant for map context
    hasArrived = true         -- Not relevant for map context
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

  if pilotAcademy.commonData == nil or pilotAcademy.commonData.targetRankLevel == nil or skillBase - pilotAcademy.commonData.targetRankLevel > 0 then
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
          row[1].handlers.onClick = function()
            Helper.closeMenuAndOpenNewMenu(menu, "MapMenu", { 0, 0, true, controllable, nil, "hire", { "signal", entity, 0 } }); menu.cleanup()
          end
        else
          row[1].handlers.onClick = function()
            Helper.closeMenuAndOpenNewMenu(menu, "MapMenu", { 0, 0, true, controllable, nil, "hire", { "signal", controllable, 0, person } }); menu.cleanup()
          end
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
      SignalObject(pilotAcademy.playerId, "PilotAcademyRAndR.CadetAutoHireRequest", ConvertStringToLuaID(tostring(controllable)),
        pilotAcademy.commonData.factions)
      return
    else
      trace("No cadets found, signalling and returning")
      SignalObject(pilotAcademy.playerId, "PilotAcademyRAndR.NoCadetsAvailableInfo")
      return
    end
  end
  local cadet = cadets[1]
  if cadet == nil then
    trace("Cadet is nil, returning")
    return
  end
  trace("Promoting cadet with name: " .. tostring(cadet.name) .. " (entity: " .. tostring(cadet.entity) .. ") and skill: " .. tostring(cadet.skill))
  SignalObject(controllable, "PilotAcademyRAndR.PrepareForPilotReplacementRequest", ConvertStringToLuaID(tostring(cadet.entity)))
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
    trace("Auto-assigning returned pilot " ..
      tostring(ffi.string(C.GetPersonName(pilotTemplateId, pilotAcademy.commonData.locationId))) .. " to academy location")
    pilotAcademy.autoAssignPilots()
  else
    trace("Auto-assign is disabled, not assigning returned pilot")
  end
end

function pilotAcademy.onRefreshPilots()
  trace("onRefreshPilots called")
  pilotAcademy.CheckOrdersOnWings()
  pilotAcademy.autoAssignPilots()
  pilotAcademy.payRent()
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
  local currentTime = C.GetCurrentGameTime()
  if pilotAcademy.commonData.lastAutoAssignTime ~= nil and currentTime - pilotAcademy.commonData.lastAutoAssignTime < pilotAcademy.autoAssignCoolDown then
    trace("Auto-assign cool down not yet elapsed, returning")
    return
  end
  local cadets, pilots = pilotAcademy.fetchAcademyPersonnel(false, true)
  if pilots == nil or #pilots == 0 then
    trace("No available pilots found, returning")
    return
  end
  pilotAcademy.commonData.lastAutoAssignTime = currentTime
  pilotAcademy.saveCommonData()
  local candidateShips = {}
  if pilotAcademy.commonData.assign == "perFleet" and next(pilotAcademy.commonData.fleets) ~= nil then
    candidateShips = pilotAcademy.fetchCandidatesForReplacementPerFleet()
  else
    candidateShips = pilotAcademy.fetchCandidatesForReplacement()
  end
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
        SignalObject(pilotAcademy.playerId, "PilotAcademyRAndR.MoveNewPilotRequest", data)
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

function pilotAcademy.processCandidateForReplacement(shipId, candidateShips, academyShips, targetRankLevel)
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
        local class = Helper.isComponentClass(classId, "ship_s") and "ship_s" or Helper.isComponentClass(classId, "ship_m") and "ship_m" or
            Helper.isComponentClass(classId, "ship_l") and "ship_l" or Helper.isComponentClass(classId, "ship_xl") and "ship_xl" or "unknown"
        trace(string.format("Evaluating ship '%s' (idcode: %s, class: %s, purpose: %s) with pilot '%s' (skill: %d, base rank: %d)",
          shipName, idcode, class, purpose, pilotName, pilotSkill, skillBase))
        if class ~= "unknown" then
          purpose = pilotAcademy.normalizePurpose(purpose)
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
    pilotAcademy.processCandidateForReplacement(shipId, candidateShips, academyShips, targetRankLevel)
  end
  pilotAcademy.sortCandidatesForReplacement(candidateShips, pilotAcademy.commonData.assign, pilotAcademy.commonData.assignPriority)
  return candidateShips
end

function pilotAcademy.collectCandidatesFromFleets(shipId, candidateShips, academyShips, targetRankLevel)
  shipId = ConvertStringTo64Bit(tostring(shipId))
  pilotAcademy.processCandidateForReplacement(shipId, candidateShips, academyShips, targetRankLevel)
  local subordinates = GetSubordinates(shipId)
  for i = 1, #subordinates do
    local subordinate = ConvertIDTo64Bit(subordinates[i])
    pilotAcademy.collectCandidatesFromFleets(subordinate, candidateShips, academyShips, targetRankLevel)
  end
end

function pilotAcademy.fetchCandidatesForReplacementPerFleet()
  trace("fetchCandidatesForReplacementPerFleet called")
  local targetRankLevel = pilotAcademy.commonData and pilotAcademy.commonData.targetRankLevel or 2
  local candidateShips = {}
  local fleetCommanders = pilotAcademy.commonData.fleets or {}

  local academyShips = pilotAcademy.fetchAllAcademyShipsForExclusion()
  for commanderId, _ in pairs(fleetCommanders) do
    pilotAcademy.collectCandidatesFromFleets(commanderId, candidateShips, academyShips, targetRankLevel)
  end
  pilotAcademy.sortCandidatesForReplacement(candidateShips, pilotAcademy.commonData.assign, pilotAcademy.commonData.assignPriority)
  return candidateShips
end

function pilotAcademy.sortCandidatesForReplacement(candidates, assign, assignPriority)
  table.sort(candidates, function(a, b)
    -- Compare by purpose priority
    if assign ~= "perFleet" and a.purpose ~= b.purpose then
      return pilotAcademy.comparePurposePriority(a, b, assign)
    end

    -- Compare by ship class
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

    -- Tie-breaker: alphabetical by ship name
    return a.shipName < b.shipName
  end)
end

local function Init()
  pilotAcademy.playerId = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
  debug("Initializing Pilot Academy UI extension with PlayerID: " .. tostring(pilotAcademy.playerId))
  local menuMap = Helper.getMenu("MapMenu")
  local menuMapIsOk = menuMap ~= nil and type(menuMap.registerCallback) == "function"
  if not menuMapIsOk then
    debug("Failed to get MapMenu or registerCallback is not a function")
  end
  local menuPlayerInfo = Helper.getMenu("PlayerInfoMenu")
  local menuPlayerInfoIsOk = menuPlayerInfo ~= nil and type(menuPlayerInfo.registerCallback) == "function"
  if not menuPlayerInfoIsOk then
    debug("Failed to get PlayerInfoMenu or registerCallback is not a function")
  end
  trace(string.format("menuMap is %s and menuPlayerInfo is %s", tostring(menuMap), tostring(menuPlayerInfo)))
  if (menuMapIsOk and menuPlayerInfoIsOk) then
    pilotAcademy.Init(menuMap, menuPlayerInfo)
  end
end


Register_OnLoad_Init(Init)
