--------------------------------------------------------------------
-- Unit Detection Script -------------------------------------------
--------------------------------------------------------------------
-- Depends on MIST 4.5 ---------------------------------------------

-- Configurable Parameters -----------------------------------------
local m_detectorUnitPrefixes = { "EW", "SAM", "AWACS", "DETECTOR" }   -- The prefixes of the UNIT NAMES that act as detectors.
local m_unitTypesToDetect = { "[blue][plane]", "[blue][helicopter]" } -- The types of units that can be detected.
local m_detectorCoalition = "[red]"                                   -- The coalition of the units that can act as detectors.
local m_allowDetectionOfAiUnits = false                               -- Whether or not AI units can be detected.

-- Detection types that can cause a detection of the units.
local m_detectionTypes = {
  Controller.Detection.VISUAL,
  Controller.Detection.OPTIC,
  Controller.Detection.RADAR,
  Controller.Detection.IRST,
  Controller.Detection.RWR,
  Controller.Detection.DLINK
}

local m_detectionZoneName = "SomeDetectionZone"         -- Name of the trigger zone the units can be detected in.
local m_flagName = "SomeFlagName"                       -- Name of the flag that indicates if a unit has been detected.
local m_alarmTime = 15                                  -- Time that a unit can be detected for before the flag is set to true.
local m_resetable = false                               -- Whether or not the flag can be reset (to be triggered multiple times).
local m_fasterDetectionTimeFromMultipleContacts = false -- If multiple detector units can see the unit, the unit will be detected faster.

local m_pollingTime = 5                                 -- Polling time in seconds for operations that need to be done quickly (unit detection).
local m_slowPollingTime = 12                            -- Polling time in seconds for operations that don't need to be done quickly (unit list).
-------------------------------------------------------------------

-- Debugging ------------------------------------------------------
local debugEnabled = true
local logTime = 3
-------------------------------------------------------------------

-- Internal Varables ----------------------------------------------
local ud = {}

local m_detectedTargets = {} -- Hashmap containing ["UnitName"] = timeDetected
local m_alarmTriggered = false

local m_detectableUnitNames = {} -- The names of the unit objects that can be detected.
local m_detectorUnits = {}       -- Unit objects that can detect.
-------------------------------------------------------------------

-------------------------------------------------------------------
-- Functions ------------------------------------------------------
-------------------------------------------------------------------
function ud.updateDetectedTargets()
  local detectedTargets = ud.getDetectedTargets()

  ud.updateDetectedTargetsTable(detectedTargets)
  ud.forgetUndetectedTargets(detectedTargets)
  ud.triggerOnAlarm(m_flagName)

  mist.scheduleFunction(ud.updateDetectedTargets, {}, timer.getTime() + m_pollingTime)
end

-------------------------------------------------------------------
-- Complexity O(n^2) ----------------------------------------------
-------------------------------------------------------------------
function ud.getDetectedTargets()
  local allDetectedUnits = ud.detectAllUnits()
  local detectedTargets = ud.filterDetectedTargets(allDetectedUnits)

  if debugEnabled then
    env.info("Number of detector units: " .. #m_detectorUnits)
    env.info("Number of detectable units (prefilter): " .. #m_detectableUnitNames)
    env.info("Detected targets: " .. mist.utils.tableShow(detectedTargets))
  end

  return detectedTargets;
end

-------------------------------------------------------------------
function ud.updateDetectedTargetsTable(detectedTargets)
  -- Loop through each detected target
  for _, target in pairs(detectedTargets) do
    -- Get the name of the detected target
    local targetName = target.object:getName()

    -- Check if this plane has already been detected
    if m_detectedTargets[targetName] ~= nil then
      -- Update the detection time for the existing entry
      m_detectedTargets[targetName] = m_detectedTargets[targetName] + m_pollingTime
    else
      -- Add a new entry for this plane
      m_detectedTargets[targetName] = m_pollingTime
    end

    if debugEnabled then
      local msg = "Detected target: " .. targetName .. " for " .. m_detectedTargets[targetName] .. " seconds"
      trigger.action.outText(msg, logTime)
      env.info(msg)
    end
  end
end

-------------------------------------------------------------------
-- Complexity O(n^2) ----------------------------------------------
-------------------------------------------------------------------
function ud.forgetUndetectedTargets(detectedTargets)
  -- Check for planes that are no longer detected
  for planeName, _ in pairs(m_detectedTargets) do
    local planeDetected = false

    -- Check if the plane is still detected
    for _, target in pairs(detectedTargets) do
      if target.object:getName() == planeName then
        planeDetected = true
        break
      end
    end

    -- If the plane is no longer detected, remove it from the detectedPlanes table
    if not planeDetected then
      m_detectedTargets[planeName] = nil
    end
  end
end

-------------------------------------------------------------------
function ud.triggerOnAlarm(flagName)
  -- Once the flag has been triggered, reset it.
  if m_resetable and m_alarmTriggered then
    trigger.action.setUserFlag(flagName, false)
  end

  -- Check if any planes have been detected for more than alarmTime
  for planeName, detectionTime in pairs(m_detectedTargets) do
    if detectionTime >= m_alarmTime and not m_alarmTriggered then
      m_alarmTriggered = true
      trigger.action.setUserFlag(flagName, true)

      if debugEnabled then
        trigger.action.outText(planeName .. " triggered the alarm", logTime)
      end
      break
    end
  end
end

-------------------------------------------------------------------
function ud.detectAllUnits()
  local detectedTargets = {}

  for _, detectorUnit in pairs(m_detectorUnits) do
    local unitController = detectorUnit:getController()

    if unitController ~= nil then
      local detectedTargetsForCurrentDetector = unitController:getDetectedTargets(unpack(m_detectionTypes))
      if detectedTargetsForCurrentDetector ~= nil then
        ud.tableConcat(detectedTargets, detectedTargetsForCurrentDetector)
      end
    elseif debugEnabled then
      env.error("No controller found for " .. detectorUnit:getName(), logTime)
    end
  end

  return detectedTargets;
end

-------------------------------------------------------------------
-- Complexity O(n^2) ----------------------------------------------
-------------------------------------------------------------------
function ud.filterDetectedTargets(detectedTargets)
  local filteredDetectedTargets = {}

  -- Filter out units that aren't in the detection zone. O(n)
  filteredDetectedTargets = ud.getTargetsInZone(detectedTargets, m_detectionZoneName)

  -- Filter out units that should never be detectable. O(n^2)
  filteredDetectedTargets = ud.removeUndetectableTargets(filteredDetectedTargets)

  -- Filter out duplicate detections. O(n^2)
  if not m_fasterDetectionTimeFromMultipleContacts then
    filteredDetectedTargets = ud.removeDetectedTargetDuplicates(filteredDetectedTargets)
  end

  -- Filter out Ai targets. O(n)
  if not m_allowDetectionOfAiUnits then
    filteredDetectedTargets = ud.removeAiTargets(filteredDetectedTargets)
  end

  env.info("DetectedTargetList:" .. #filteredDetectedTargets)
  return filteredDetectedTargets
end

-------------------------------------------------------------------
function ud.updateUnitLists()
  m_detectableUnitNames = ud.getUnitsToDetect()
  m_detectorUnits = ud.getDetectorUnits()

  mist.scheduleFunction(ud.updateUnitLists, {}, timer.getTime() + m_slowPollingTime)
end

-------------------------------------------------------------------
function ud.getUnitsToDetect()
  local nameOfUnitsToDetect = mist.makeUnitTable(m_unitTypesToDetect)
  table.sort(nameOfUnitsToDetect)

  return nameOfUnitsToDetect
end

-------------------------------------------------------------------
function ud.getDetectorUnits()
  local detectorUnits = {}
  local allDetectorCoalitionUnits = mist.makeUnitTable({ m_detectorCoalition })
  local detectorUnitNames = ud.getUnitNamesPrefixedBy(allDetectorCoalitionUnits, m_detectorUnitPrefixes)

  for _, unitName in pairs(detectorUnitNames) do
    table.insert(detectorUnits, Unit.getByName(unitName));
  end

  if debugEnabled then
    env.info("Detector units: " .. mist.utils.tableShow(detectorUnitNames))
  end

  return detectorUnits
end

-------------------------------------------------------------------
-- Complexity O(n^2) ----------------------------------------------
-------------------------------------------------------------------
function ud.removeUndetectableTargets(detectedUnits)
  local detectedTargets = {}

  for _, detectedUnit in pairs(detectedUnits) do
    local detectedUnitName = detectedUnit.object:getName()

    for _, nameOfUnitToDetect in pairs(m_detectableUnitNames) do
      if detectedUnitName == nameOfUnitToDetect then
        table.insert(detectedTargets, detectedUnit)
      end
    end
  end

  return detectedTargets
end

-------------------------------------------------------------------
-- Complexity O(n^2) ----------------------------------------------
-------------------------------------------------------------------
function ud.removeDetectedTargetDuplicates(detectedTargets)
  local seenNames = {}
  local uniqueTargets = {}

  for _, detectedTarget in pairs(detectedTargets) do
    local detectedTargetName = detectedTarget.object:getName()

    local isNamePresent = false
    for _, seenName in pairs(seenNames) do
      if seenName == tostring(detectedTargetName) then
        isNamePresent = true
        break
      end
    end

    if not isNamePresent then
      table.insert(seenNames, detectedTargetName)
      table.insert(uniqueTargets, detectedTarget)
    end
  end

  return uniqueTargets
end

-------------------------------------------------------------------
function ud.removeAiTargets(detectedTargets)
  local playerTargets = {}

  for _, target in pairs(detectedTargets) do
    local unitName = target.object:getName()
    local unit = Unit.getByName(unitName)

    if unit ~= nil then
      local isAi = true
      local playerName = unit:getPlayerName()

      if playerName ~= nil then
        isAi = false
        table.insert(playerTargets, target)
      end

      if debugEnabled then
        env.info("ud.removeAiTargets(): " .. unitName .. " is Ai:" .. tostring(isAi))
      end
    end
  end

  if debugEnabled then
    env.info("ud.removeAiTargets(): Player targets: " .. mist.utils.tableShow(playerTargets))
  end

  return playerTargets
end

-------------------------------------------------------------------
function ud.getTargetsInZone(targets, zoneName)
  local targetsInZone = {}

  local zone = trigger.misc.getZone(zoneName)

  if debugEnabled then
    env.info("Zone '" .. zoneName .. "': " .. mist.utils.tableShow(zone))
  end

  if zone == nil then
    env.error("Zone " .. zoneName .. "does not exist.")
    return {}
  end

  local zonePosition = ud.removeAltitudeFromPoint(zone.point)
  local zoneRadius = zone.radius

  for _, target in pairs(targets) do
    local unitPosition = ud.removeAltitudeFromPoint(target.object:getPoint())
    local unitDistance = ud.getDistance(zonePosition, unitPosition)

    if unitDistance <= zoneRadius then
      table.insert(targetsInZone, target)
    end
  end

  if debugEnabled then
    env.info("Targets in zone '" .. zoneName .. "': " .. mist.utils.tableShow(targetsInZone))
  end

  return targetsInZone
end

-------------------------------------------------------------------
function ud.getDistance(point1, point2)
  local deltaX = math.abs(point1.x - point2.x)
  local deltaY = math.abs(point1.y - point2.y)
  local deltaZ = math.abs(point1.z - point2.z)

  return math.sqrt((deltaX ^ 2) + (deltaY ^ 2) + (deltaZ ^ 2))
end

-------------------------------------------------------------------
function ud.removeAltitudeFromPoint(point)
  return { x = point.x, y = 0, z = point.z }
end

-------------------------------------------------------------------
function ud.getUnitNamesPrefixedBy(mistUnitTable, prefixes)
  local unitNamesWithPrefix = {}
  for _, unitName in pairs(mistUnitTable) do
    if ud.startsWithSomePrefix(unitName, prefixes) then
      table.insert(unitNamesWithPrefix, unitName)
    end
  end

  return unitNamesWithPrefix;
end

-------------------------------------------------------------------
function ud.startsWithSomePrefix(name, prefixes)
  for _, prefix in pairs(prefixes) do
    if string.sub(name, 1, #prefix) == prefix then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------
function ud.tableConcat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

-------------------------------------------------------------------
-- Entry Point ----------------------------------------------------
-------------------------------------------------------------------
ud.updateUnitLists()
ud.updateDetectedTargets()
