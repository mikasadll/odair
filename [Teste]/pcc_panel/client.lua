local screenW, screenH = guiGetScreenSize()

local eventPrefix = "pccPanel"
local panelLogoPath = "pcc_logo.png"
local fonts = {
    title = "bankgothic",
    subtitle = "clear",
    text = "clear"
}

local panel = {
    visible = false,
    x = 0,
    y = 0,
    width = 920,
    height = 560,
    rowHeight = 48,
    maxVisibleRows = 5,
    closeButton = nil,
    clearWeaponsButton = nil,
    screenArea = nil,
    columns = {},
    hoverKey = nil
}

local skins = {
    { name = "CJ", id = 0 },
    { name = "Policial", id = 280 },
    { name = "Soldado", id = 287 },
    { name = "Mecanico", id = 50 },
    { name = "SWAT", id = 285 },
    { name = "FBI", id = 286 },
    { name = "Medico", id = 274 },
    { name = "Ballas", id = 102 },
    { name = "Groove", id = 105 }
}

local vehicles = {
    { name = "Infernus", id = 411 },
    { name = "Bullet", id = 541 },
    { name = "Sultan", id = 560 },
    { name = "NRG-500", id = 522 },
    { name = "Buffalo", id = 402 },
    { name = "Turismo", id = 451 },
    { name = "Cheetah", id = 415 },
    { name = "Banshee", id = 429 },
    { name = "Comet", id = 480 },
    { name = "Super GT", id = 506 },
    { name = "Flash", id = 565 },
    { name = "Elegy", id = 562 },
    { name = "Jester", id = 559 }
}

local weapons = {
    { name = "Cacetete", id = 3 },
    { name = "M4", id = 31 },
    { name = "Shotgun", id = 25 },
    { name = "Deagle", id = 24 },
    { name = "AK-47", id = 30 },
    { name = "MP5", id = 29 },
    { name = "Tec-9", id = 32 }
}

local colors = {
    backdrop = tocolor(0, 0, 0, 165),
    shell = tocolor(14, 14, 14, 255),
    shellSoft = tocolor(28, 28, 28, 255),
    screen = tocolor(52, 52, 52, 255),
    card = tocolor(18, 18, 18, 255),
    cardHover = tocolor(42, 42, 42, 255),
    accent = tocolor(210, 210, 210, 255),
    accentSoft = tocolor(255, 255, 255, 255),
    accentDark = tocolor(10, 10, 10, 255),
    text = tocolor(245, 245, 245, 255),
    textSoft = tocolor(175, 175, 175, 255),
    border = tocolor(0, 0, 0, 255),
    track = tocolor(90, 90, 90, 255),
    home = tocolor(225, 225, 225, 255)
}

local function drawRoundedRect(x, y, width, height, color, radius)
    dxDrawRectangle(x + radius, y, width - (radius * 2), height, color)
    dxDrawRectangle(x, y + radius, width, height - (radius * 2), color)
    dxDrawCircle(x + radius, y + radius, radius, 180, 270, color, color, 16)
    dxDrawCircle(x + width - radius, y + radius, radius, 270, 360, color, color, 16)
    dxDrawCircle(x + radius, y + height - radius, radius, 90, 180, color, color, 16)
    dxDrawCircle(x + width - radius, y + height - radius, radius, 0, 90, color, color, 16)
end

local function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then
        return false
    end

    local cursorX, cursorY = getCursorPosition()
    if not cursorX or not cursorY then
        return false
    end

    cursorX = cursorX * screenW
    cursorY = cursorY * screenH
    return cursorX >= x and cursorX <= x + width and cursorY >= y and cursorY <= y + height
end

local function recalculateLayout()
    panel.x = (screenW - panel.width) / 2
    panel.y = (screenH - panel.height) / 2
    panel.screenArea = {
        x = panel.x + 18,
        y = panel.y + 18,
        width = panel.width - 36,
        height = panel.height - 36
    }

    panel.columns = {
        skins = {
            x = panel.screenArea.x + 34,
            y = panel.screenArea.y + 118,
            width = 228,
            title = "Roupas",
            items = skins,
            scroll = 0
        },
        vehicles = {
            x = panel.screenArea.x + 326,
            y = panel.screenArea.y + 118,
            width = 228,
            title = "Carros",
            items = vehicles,
            scroll = 0
        },
        weapons = {
            x = panel.screenArea.x + 618,
            y = panel.screenArea.y + 118,
            width = 228,
            title = "Armas",
            items = weapons,
            scroll = 0
        }
    }

    panel.clearWeaponsButton = {
        x = panel.screenArea.x + 618,
        y = panel.screenArea.y + 404,
        width = 228,
        height = 42,
        text = "Remover Todas Armas"
    }

    panel.closeButton = {
        x = panel.screenArea.x + 386,
        y = panel.screenArea.y + 466,
        width = 120,
        height = 40,
        text = "Fechar"
    }
end

local function getVisibleRange(column)
    local startIndex = column.scroll + 1
    local endIndex = math.min(#column.items, column.scroll + panel.maxVisibleRows)
    return startIndex, endIndex
end

local function drawColumn(columnKey, column)
    dxDrawText(column.title, column.x, column.y - 34, column.x + column.width, column.y - 6, colors.accentSoft, 1.08, fonts.title, "center", "center")

    local startIndex, endIndex = getVisibleRange(column)
    local listHeight = (panel.rowHeight + 8) * panel.maxVisibleRows - 8
    drawRoundedRect(column.x - 1, column.y - 1, column.width + 2, listHeight + 2, colors.accentDark, 12)

    local visibleRow = 0
    for index = startIndex, endIndex do
        local item = column.items[index]
        local itemY = column.y + (visibleRow * (panel.rowHeight + 8))
        local hovered = isMouseInPosition(column.x, itemY, column.width, panel.rowHeight)

        if hovered then
            panel.hoverKey = columnKey .. ":" .. index
        end

        drawRoundedRect(column.x, itemY, column.width, panel.rowHeight, hovered and colors.cardHover or colors.card, 10)
        dxDrawText(item.name, column.x + 16, itemY, column.x + column.width - 18, itemY + panel.rowHeight, colors.text, 1, fonts.text, "left", "center")
        visibleRow = visibleRow + 1
    end

    if #column.items > panel.maxVisibleRows then
        local barX = column.x + column.width - 7
        local barHeight = listHeight
        local thumbHeight = math.max(34, (panel.maxVisibleRows / #column.items) * barHeight)
        local maxScroll = #column.items - panel.maxVisibleRows
        local thumbTravel = barHeight - thumbHeight
        local thumbY = column.y

        if maxScroll > 0 then
            thumbY = column.y + (column.scroll / maxScroll) * thumbTravel
        end

        drawRoundedRect(barX, column.y, 5, barHeight, colors.track, 2)
        drawRoundedRect(barX, thumbY, 5, thumbHeight, colors.accentSoft, 2)
    end
end

local function drawButton(button, normalColor, hoverColor, textColor)
    local hovered = isMouseInPosition(button.x, button.y, button.width, button.height)
    if hovered then
        panel.hoverKey = button.text
    end

    drawRoundedRect(button.x - 1, button.y - 1, button.width + 2, button.height + 2, colors.border, 14)
    drawRoundedRect(button.x, button.y, button.width, button.height, hovered and hoverColor or normalColor, 13)
    dxDrawText(button.text, button.x, button.y, button.x + button.width, button.y + button.height, textColor, 1, fonts.subtitle, "center", "center")
end

local function renderPanel()
    if not panel.visible then
        return
    end

    panel.hoverKey = nil

    dxDrawRectangle(0, 0, screenW, screenH, colors.backdrop)
    drawRoundedRect(panel.x - 4, panel.y - 4, panel.width + 8, panel.height + 8, colors.border, 28)
    drawRoundedRect(panel.x, panel.y, panel.width, panel.height, colors.shell, 26)
    drawRoundedRect(panel.screenArea.x, panel.screenArea.y, panel.screenArea.width, panel.screenArea.height, colors.screen, 20)
    drawRoundedRect(panel.screenArea.x + 22, panel.screenArea.y + 18, panel.screenArea.width - 44, 66, colors.card, 18)
    drawRoundedRect(panel.screenArea.x + 22, panel.screenArea.y + 18, 290, 66, colors.accentDark, 18)
    drawRoundedRect(panel.screenArea.x + 30, panel.screenArea.y + 26, 56, 50, tocolor(255, 255, 255, 255), 10)
    dxDrawImage(panel.screenArea.x + 34, panel.screenArea.y + 29, 48, 44, panelLogoPath)
    dxDrawText("PAINEL PCC", panel.screenArea.x + 98, panel.screenArea.y + 24, panel.screenArea.x + 360, panel.screenArea.y + 72, colors.text, 1.22, fonts.title, "left", "center")

    drawColumn("skins", panel.columns.skins)
    drawColumn("vehicles", panel.columns.vehicles)
    drawColumn("weapons", panel.columns.weapons)

    drawButton(panel.clearWeaponsButton, colors.accentDark, colors.accent, colors.text)
    drawButton(panel.closeButton, colors.card, colors.cardHover, colors.text)
    drawRoundedRect(panel.x + (panel.width / 2) - 18, panel.y + panel.height - 16, 36, 6, colors.home, 3)
end

local function openPanel()
    if panel.visible then
        return
    end

    recalculateLayout()
    panel.visible = true
    showCursor(true)
    addEventHandler("onClientRender", root, renderPanel)
end

local function closePanel()
    if not panel.visible then
        return
    end

    panel.visible = false
    showCursor(false)
    removeEventHandler("onClientRender", root, renderPanel)
end

local function handleColumnClick(columnKey, column)
    local startIndex, endIndex = getVisibleRange(column)
    local visibleRow = 0

    for index = startIndex, endIndex do
        local item = column.items[index]
        local itemY = column.y + (visibleRow * (panel.rowHeight + 8))
        if isMouseInPosition(column.x, itemY, column.width, panel.rowHeight) then
            if columnKey == "skins" then
                triggerServerEvent(eventPrefix .. ":onSelectSkin", localPlayer, item.id)
            elseif columnKey == "vehicles" then
                triggerServerEvent(eventPrefix .. ":onSelectVehicle", localPlayer, item.id)
            elseif columnKey == "weapons" then
                triggerServerEvent(eventPrefix .. ":onSelectWeapon", localPlayer, item.id)
            end
            return true
        end

        visibleRow = visibleRow + 1
    end

    return false
end

local function handleColumnScroll(direction)
    for _, column in pairs(panel.columns) do
        local listHeight = (panel.rowHeight + 8) * panel.maxVisibleRows - 8
        if isMouseInPosition(column.x, column.y, column.width, listHeight) and #column.items > panel.maxVisibleRows then
            local maxScroll = #column.items - panel.maxVisibleRows

            if direction == "up" then
                column.scroll = math.max(0, column.scroll - 1)
            elseif direction == "down" then
                column.scroll = math.min(maxScroll, column.scroll + 1)
            end

            return true
        end
    end

    return false
end

addEventHandler("onClientClick", root, function(button, state)
    if not panel.visible or button ~= "left" or state ~= "down" then
        return
    end

    if handleColumnClick("skins", panel.columns.skins) then
        return
    end

    if handleColumnClick("vehicles", panel.columns.vehicles) then
        return
    end

    if handleColumnClick("weapons", panel.columns.weapons) then
        return
    end

    if isMouseInPosition(panel.clearWeaponsButton.x, panel.clearWeaponsButton.y, panel.clearWeaponsButton.width, panel.clearWeaponsButton.height) then
        triggerServerEvent(eventPrefix .. ":onClearWeapons", localPlayer)
        return
    end

    if isMouseInPosition(panel.closeButton.x, panel.closeButton.y, panel.closeButton.width, panel.closeButton.height) then
        closePanel()
    end
end)

bindKey("mouse_wheel_up", "down", function()
    if panel.visible then
        handleColumnScroll("up")
    end
end)

bindKey("mouse_wheel_down", "down", function()
    if panel.visible then
        handleColumnScroll("down")
    end
end)

addEvent(eventPrefix .. ":toggle", true)
addEventHandler(eventPrefix .. ":toggle", root, function(visible)
    if visible then
        openPanel()
    else
        closePanel()
    end
end)

addEventHandler("onClientResourceStart", resourceRoot, function()
    recalculateLayout()
end)
