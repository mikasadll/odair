local playerIdElementData = "account:id"
local eventPrefix = "idSystem"

local idTagSettings = {
    maxDistance = 30,
    scale = 1.2
}

local adminPanel = {
    window = nil,
    grid = nil,
    edit = nil,
    selectedAccount = nil,
    searchEdit = nil,
    rows = {}
}

local function renderPlayerIds()
    local cameraX, cameraY, cameraZ = getCameraMatrix()

    for _, player in ipairs(getElementsByType("player")) do
        if isElementStreamedIn(player) and getElementDimension(player) == getElementDimension(localPlayer) and getElementInterior(player) == getElementInterior(localPlayer) then
            local accountId = getElementData(player, playerIdElementData)
            if accountId and accountId ~= "" then
                local px, py, pz = getElementPosition(player)
                local distance = getDistanceBetweenPoints3D(cameraX, cameraY, cameraZ, px, py, pz)

                if distance <= idTagSettings.maxDistance then
                    local screenX, screenY = getScreenFromWorldPosition(px, py, pz + 1.15, 0.06)
                    if screenX and screenY then
                        local alpha = math.max(70, 255 - (distance * 6))
                        local textColor = tocolor(255, 255, 255, alpha)
                        local shadowColor = tocolor(0, 0, 0, math.min(220, alpha))
                        local text = tostring(accountId)

                        dxDrawText(text, screenX + 1, screenY + 1, screenX + 1, screenY + 1, shadowColor, idTagSettings.scale, "default-bold", "center", "center")
                        dxDrawText(text, screenX, screenY, screenX, screenY, textColor, idTagSettings.scale, "default-bold", "center", "center")
                    end
                end
            end
        end
    end
end

local function ensureAdminPanel()
    if isElement(adminPanel.window) then
        return
    end

    local screenW, screenH = guiGetScreenSize()
    local width, height = 680, 430
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2

    adminPanel.window = guiCreateWindow(x, y, width, height, "Gerenciador de IDs", false)
    guiWindowSetSizable(adminPanel.window, false)

    adminPanel.grid = guiCreateGridList(20, 32, 410, 345, false, adminPanel.window)
    guiGridListAddColumn(adminPanel.grid, "Conta", 0.62)
    guiGridListAddColumn(adminPanel.grid, "ID", 0.25)

    guiCreateLabel(450, 55, 180, 20, "Conta selecionada:", false, adminPanel.window)
    adminPanel.accountLabel = guiCreateLabel(450, 78, 200, 40, "Nenhuma", false, adminPanel.window)
    guiLabelSetHorizontalAlign(adminPanel.accountLabel, "left", true)

    guiCreateLabel(450, 125, 180, 20, "Pesquisar usuario:", false, adminPanel.window)
    adminPanel.searchEdit = guiCreateEdit(450, 149, 190, 30, "", false, adminPanel.window)

    guiCreateLabel(450, 195, 180, 20, "Novo ID:", false, adminPanel.window)
    adminPanel.edit = guiCreateEdit(450, 219, 190, 30, "", false, adminPanel.window)

    adminPanel.saveButton = guiCreateButton(450, 265, 190, 36, "Salvar ID", false, adminPanel.window)
    adminPanel.refreshButton = guiCreateButton(450, 310, 190, 36, "Atualizar Lista", false, adminPanel.window)
    adminPanel.closeButton = guiCreateButton(450, 355, 190, 36, "Fechar", false, adminPanel.window)

    guiSetVisible(adminPanel.window, false)

    addEventHandler("onClientGUIClick", adminPanel.grid, function()
        local row = guiGridListGetSelectedItem(adminPanel.grid)
        if row and row ~= -1 then
            adminPanel.selectedAccount = guiGridListGetItemText(adminPanel.grid, row, 1)
            local selectedId = guiGridListGetItemText(adminPanel.grid, row, 2)
            guiSetText(adminPanel.accountLabel, adminPanel.selectedAccount)
            guiSetText(adminPanel.edit, selectedId)
        end
    end, false)

    addEventHandler("onClientGUIClick", adminPanel.saveButton, function()
        if not adminPanel.selectedAccount or adminPanel.selectedAccount == "" then
            outputChatBox("Selecione uma conta na lista para alterar o ID.", 255, 220, 120)
            return
        end

        local newId = guiGetText(adminPanel.edit)
        triggerServerEvent(eventPrefix .. ":updateAccountId", localPlayer, adminPanel.selectedAccount, newId)
    end, false)

    addEventHandler("onClientGUIClick", adminPanel.refreshButton, function()
        triggerServerEvent(eventPrefix .. ":requestAccountList", localPlayer)
    end, false)

    addEventHandler("onClientGUIClick", adminPanel.closeButton, function()
        guiSetVisible(adminPanel.window, false)
        showCursor(false)
    end, false)

    addEventHandler("onClientGUIChanged", adminPanel.searchEdit, function()
        local searchText = guiGetText(adminPanel.searchEdit)
        fillAccountGrid(adminPanel.rows, searchText)
    end, false)
end

function fillAccountGrid(rows, searchText)
    ensureAdminPanel()
    adminPanel.rows = rows or adminPanel.rows or {}
    guiGridListClear(adminPanel.grid)
    adminPanel.selectedAccount = nil
    guiSetText(adminPanel.accountLabel, "Nenhuma")
    guiSetText(adminPanel.edit, "")

    local filter = string.lower(tostring(searchText or guiGetText(adminPanel.searchEdit) or ""))

    for _, rowData in ipairs(adminPanel.rows) do
        local accountName = tostring(rowData.account_name or "")
        if filter == "" or string.find(string.lower(accountName), filter, 1, true) then
            local row = guiGridListAddRow(adminPanel.grid)
            guiGridListSetItemText(adminPanel.grid, row, 1, accountName, false, false)
            guiGridListSetItemText(adminPanel.grid, row, 2, tostring(rowData.id or ""), false, false)
        end
    end
end

addEvent(eventPrefix .. ":toggleAdminPanel", true)
addEventHandler(eventPrefix .. ":toggleAdminPanel", root, function(visible)
    ensureAdminPanel()
    guiSetVisible(adminPanel.window, visible and true or false)
    showCursor(visible and true or false)
end)

addEvent(eventPrefix .. ":receiveAccountList", true)
addEventHandler(eventPrefix .. ":receiveAccountList", root, function(rows)
    fillAccountGrid(rows or {})
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    addEventHandler("onClientRender", root, renderPlayerIds)
end)
