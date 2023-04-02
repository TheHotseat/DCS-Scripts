--------------------------------------------------------------------
-- Marine Traffic Generator ----------------------------------------
--------------------------------------------------------------------
-- Depends on MIST 4.5 ---------------------------------------------


local _shipDataPath = [[C:\<Path to CSV>\PG_Static.csv]] -- Modify this to point to the CSV file on you disk. Ex: C:\Users\JasonBourne\Saved Games\DCS.openbeta\Missions\scripts\MarineTrafficGenerator\PG_Static.csv

local _countryOfShips = country.id.OMAN                  -- Modify to a red, blue or neutral country as desired. By default Oman is neutral. Ships will spawn as neutral

--------------------------------------------------------------------
-- Do not modify past this line ------------------------------------
--------------------------------------------------------------------
local marineTraffic = {}

local MARINE_TRAFFIC_ATTRIBUTES = {
    MARINE_TRAFFIC = 'MARINE_TRAFFIC',
    SPAWN_AS_STATIC = 'MT_SPAWN_AS_STATIC',
}

local SHIP_TYPE = {
    SUPPORT = 'SUPPORT',
    TANKER = 'TANKER',
    CARGO = 'CARGO',
    FISHING = 'FISHING',
    YACHT = 'YACHT',
    PASSENGER = 'PASSENGER'
}

local _shipTypesToSpawn = { SHIP_TYPE.TANKER, SHIP_TYPE.CARGO, SHIP_TYPE.YACHT, SHIP_TYPE.PASSENGER }

local _nbOfShipsSpawnedAsUnits = 0;
local _nbOfShipsSpawnedAsStatics = 0;

function marineTraffic.SpawnShip(name, latitude, longitude, heading, shiptype, spawningZoneName)
    local spawnPoint = coord.LLtoLO(latitude, longitude)

    if heading == "null" then
        heading = mist.random(0, 359)
    end

    if marineTraffic.IsSpawningZoneAStaticZone(spawningZoneName) then
        marineTraffic.SpawnShipAsStatic(name, spawnPoint, heading, shiptype)
    else
        marineTraffic.SpawnShipAsUnit(name, spawnPoint, heading, shiptype)
    end
end

function marineTraffic.SpawnShipAsUnit(name, spawnPoint, heading, shiptype)
    local group = {
        ["visible"] = false,
        ["hidden"] = false,
        ["units"] = {
            [1] = {
                ["name"] = "MT Generated Boat " .. name,
                ["type"] = shiptype,
                ["z"] = spawnPoint.y,
                ["y"] = spawnPoint.z,
                ["x"] = spawnPoint.x,
                ["playerCanDrive"] = false,
                ["heading"] = math.rad(heading),
            },
        },
        ["name"] = "MT Generated Boat " .. name,
        ["task"] = "Ground Nothing",
    }

    coalition.addGroup(_countryOfShips, Group.Category.SHIP, group)

    _nbOfShipsSpawnedAsUnits = _nbOfShipsSpawnedAsUnits + 1
end

function marineTraffic.SpawnShipAsStatic(name, spawnPoint, heading, shiptype)
    local staticShip = {
        ["heading"] = math.rad(heading),
        ["type"] = shiptype,
        ["name"] = "MT Generated Boat " .. name,
        ["category"] = "Ships",
        ["z"] = spawnPoint.y,
        ["y"] = spawnPoint.z,
        ["x"] = spawnPoint.x,
        ["dead"] = false,
    }

    coalition.addStaticObject(_countryOfShips, staticShip)

    _nbOfShipsSpawnedAsStatics = _nbOfShipsSpawnedAsStatics + 1
end

function marineTraffic.ShouldSpawnShip(spawningZones, latitude, longitude, shipType)
    if not marineTraffic.IsShipTypeSpawnable(shipType) then
        return false
    end

    local isShipInSpawnableZone, spawnableZoneName = marineTraffic.IsShipInSpawnableZone(spawningZones, latitude, longitude)
    if not isShipInSpawnableZone then
        return false
    end

    return true, spawnableZoneName
end

function marineTraffic.IsShipTypeSpawnable(shipType)
    for _, shipTypeToSpawn in ipairs(_shipTypesToSpawn) do
        if shipTypeToSpawn == shipType then
            return true
        end
    end

    return false
end

function marineTraffic.IsShipInSpawnableZone(spawningZones, latitude, longitude)
    local currentShipSpawnPoint = coord.LLtoLO(latitude, longitude)
    local currentShipSpawnZone = { point = currentShipSpawnPoint, radius = 1 } -- We need to create a zone around the ship to check if it's inside a valid spawning zone

    for spawningZoneName, spawningZone in pairs(spawningZones) do
        local shipSpawningZone = mist.DBs.zonesByName[spawningZoneName]

        if shipSpawningZone.verticies ~= nil then
            -- If shape zone
            if mist.shape.insideShape(currentShipSpawnZone, shipSpawningZone.verticies) then
                return true, spawningZoneName
            end
        else
            -- If circle zone
            if mist.shape.insideShape(currentShipSpawnZone, shipSpawningZone) then
                return true, spawningZoneName
            end
        end
    end

    return false, nil
end

function marineTraffic.IsSpawningZoneAStaticZone(spawningZoneName)
    local spawningZoneConfig = marineTraffic.GetZoneConfigurationFromName(spawningZoneName)
    if spawningZoneConfig[MARINE_TRAFFIC_ATTRIBUTES.SPAWN_AS_STATIC] == true then
        return true
    end

    return false
end

function marineTraffic.GetRandomDcsShipTypeFromDataSourceShipType(shipType)
    local cargos = { "Dry-cargo ship-1", "Dry-cargo ship-2" }
    local tankers = { "ELNYA", "HandyWind" }
    local passengers = { "ZWEZDNY" }
    local yachts = { "ZWEZDNY" }

    if shipType == SHIP_TYPE.CARGO then
        local randomValue = mist.random(1, #cargos)
        return cargos[randomValue]
    elseif shipType == SHIP_TYPE.TANKER then
        local randomValue = mist.random(1, #tankers)
        return tankers[randomValue]
    elseif shipType == SHIP_TYPE.PASSENGER then
        local randomValue = mist.random(1, #passengers)
        return passengers[randomValue]
    elseif shipType == SHIP_TYPE.YACHT then
        local randomValue = mist.random(1, #yachts)
        return yachts[randomValue]
    end
end

function marineTraffic.GetZoneConfigurationFromName(nameOfZone)
    local myObject = {}

    for key, value in nameOfZone:gmatch("%[(.-):([%w%s:_\"']+)%]") do
        if value == "true" or value == "false" then
            myObject[key] = value == "true"
        elseif tonumber(value) ~= nil then
            myObject[key] = tonumber(value)
        else
            myObject[key] = value:gsub('"', '')
        end
    end

    return myObject
end

function marineTraffic.getSpawningZones()
    local spawningZones = {}

    for zoneName, _ in pairs(mist.DBs.zonesByName) do
        local zoneConfig = marineTraffic.GetZoneConfigurationFromName(zoneName)
        if zoneConfig[MARINE_TRAFFIC_ATTRIBUTES.MARINE_TRAFFIC] == true then
            spawningZones[zoneName] = zoneConfig
        end
    end

    return spawningZones
end

function marineTraffic.ReadCsvFile(path)
    local file = io.open(path, "r") -- open the file in read mode
    if not file then return nil end

    local headers = {}
    local objects = {}

    -- read the header row and split it into fields
    local header_line = file:read()
    for field in header_line:gmatch("[^,]+") do
        table.insert(headers, field)
    end

    -- read each subsequent row and create an object for it
    for line in file:lines() do
        local fields = {}
        for field in line:gmatch("[^,]+") do
            table.insert(fields, field)
        end

        local object = {}
        for i, field in ipairs(fields) do
            object[headers[i]] = field
        end

        table.insert(objects, object)
    end

    file:close()
    return objects
end

local ships = marineTraffic.ReadCsvFile(_shipDataPath)
local spawningZones = marineTraffic.getSpawningZones()

for _, ship in ipairs(ships) do
    local shouldSpawn, spawningZoneName = marineTraffic.ShouldSpawnShip(spawningZones, ship.latitude, ship.longitude, ship.shiptype)
    if shouldSpawn == true then
        local shipType = marineTraffic.GetRandomDcsShipTypeFromDataSourceShipType(ship.shiptype)
        marineTraffic.SpawnShip(ship.name, ship.latitude, ship.longitude, ship.heading, shipType, spawningZoneName)
    end
end

env.info("Marine Traffic Generator: " .. _nbOfShipsSpawnedAsStatics .. " ships spawned as statics.")
env.info("Marine Traffic Generator: " .. _nbOfShipsSpawnedAsUnits .. " ships spawned as units.")
