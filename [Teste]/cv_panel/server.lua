local markerPosition = { x = 1535.76892, y = -1661.26477, z = 13.54688 }
local vehicleSpawnPosition = { x = 1525.54712, y = -1677.75037, z = 13.38281 }
local destroyMarkerPosition = { x = 1539.85303, y = -1664.93311, z = 13.54945 }
local allowedACLGroup = "CV"
local eventPrefix = "cvPanel"

local skins = {
    [0] = true,
    [50] = true,
    [102] = true,
    [105] = true,
    [274] = true,
    [280] = true,
    [285] = true,
    [286] = true,
    [287] = true
}

local vehicles = {
    [402] = true,
    [411] = true,
    [415] = true,
    [429] = true,
    [451] = true,
    [480] = true,
    [506] = true,
    [522] = true,
    [541] = true,
    [559] = true,
    [560] = true,
    [562] = true,
    [565] = true
}

local weapons = {
    [3] = 1,
    [24] = 2000,
    [25] = 2000,
    [29] = 2000,
    [30] = 2000,
    [31] = 2000,
    [32] = 2000
}

local playerVehicles = {}
local marker = createMarker(markerPosition.x, markerPosition.y, markerPosition.z - 1, "cylinder", 1.5, 0, 170, 255, 140)
local destroyMarker = createMarker(destroyMarkerPosition.x, destroyMarkerPosition.y, destroyMarkerPosition.z - 1, "cylinder", 2.0, 0, 0, 0, 170)

local function hasPanelAccess(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then
        return false
    end

    local accountName = getAccountName(account)
    local aclGroup = aclGetGroup(allowedACLGroup)

    if not aclGroup then
        return false
    end

    return isObjectInACLGroup("user." .. accountName, aclGroup)
end

local function isPlayerNearMarker(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    local px, py, pz = getElementPosition(player)
    local mx, my, mz = getElementPosition(marker)
    return getDistanceBetweenPoints3D(px, py, pz, mx, my, mz) <= 3
end

local function canUsePanel(player)
    return client == source and isPlayerNearMarker(player) and hasPanelAccess(player)
end

addEventHandler("onMarkerHit", marker, function(hitElement, matchingDimension)
    if getElementType(hitElement) ~= "player" or not matchingDimension then
        return
    end

    if not hasPanelAccess(hitElement) then
        outputChatBox("Voce nao tem permissao para abrir este painel.", hitElement, 255, 80, 80)
        return
    end

    triggerClientEvent(hitElement, eventPrefix .. ":toggle", resourceRoot, true)
end)

addEventHandler("onMarkerLeave", marker, function(leaveElement, matchingDimension)
    if getElementType(leaveElement) ~= "player" or not matchingDimension then
        return
    end

    triggerClientEvent(leaveElement, eventPrefix .. ":toggle", resourceRoot, false)
end)

addEventHandler("onMarkerHit", destroyMarker, function(hitElement, matchingDimension)
    if getElementType(hitElement) ~= "player" or not matchingDimension then
        return
    end

    local vehicle = getPedOccupiedVehicle(hitElement) or playerVehicles[hitElement]
    if not isElement(vehicle) then
        return
    end

    destroyElement(vehicle)
    playerVehicles[hitElement] = nil
end)

addEvent(eventPrefix .. ":onSelectSkin", true)
addEventHandler(eventPrefix .. ":onSelectSkin", root, function(skinId)
    if not canUsePanel(client) then
        return
    end

    skinId = tonumber(skinId)
    if not skins[skinId] then
        outputChatBox("Skin invalida.", client, 255, 80, 80)
        return
    end

    setElementModel(client, skinId)
end)

addEvent(eventPrefix .. ":onSelectVehicle", true)
addEventHandler(eventPrefix .. ":onSelectVehicle", root, function(vehicleId)
    if not canUsePanel(client) then
        return
    end

    vehicleId = tonumber(vehicleId)
    if not vehicles[vehicleId] then
        outputChatBox("Veiculo invalido.", client, 255, 80, 80)
        return
    end

    local oldVehicle = playerVehicles[client]
    if isElement(oldVehicle) then
        destroyElement(oldVehicle)
    end

    local _, _, rz = getElementRotation(client)
    local vehicle = createVehicle(vehicleId, vehicleSpawnPosition.x, vehicleSpawnPosition.y, vehicleSpawnPosition.z + 0.5, 0, 0, rz)
    if not isElement(vehicle) then
        return
    end

    playerVehicles[client] = vehicle
    warpPedIntoVehicle(client, vehicle)
    triggerClientEvent(client, eventPrefix .. ":toggle", resourceRoot, false)
end)

addEvent(eventPrefix .. ":onSelectWeapon", true)
addEventHandler(eventPrefix .. ":onSelectWeapon", root, function(weaponId)
    if not canUsePanel(client) then
        return
    end

    weaponId = tonumber(weaponId)
    if not weapons[weaponId] then
        outputChatBox("Arma invalida.", client, 255, 80, 80)
        return
    end

    giveWeapon(client, weaponId, weapons[weaponId], true)
end)

addEvent(eventPrefix .. ":onClearWeapons", true)
addEventHandler(eventPrefix .. ":onClearWeapons", root, function()
    if not canUsePanel(client) then
        return
    end

    takeAllWeapons(client)
end)

addEventHandler("onPlayerQuit", root, function()
    local vehicle = playerVehicles[source]
    if isElement(vehicle) then
        destroyElement(vehicle)
    end

    playerVehicles[source] = nil
end)

addEventHandler("onResourceStop", resourceRoot, function()
    for player, vehicle in pairs(playerVehicles) do
        if isElement(vehicle) then
            destroyElement(vehicle)
        end
        playerVehicles[player] = nil
    end
end)
