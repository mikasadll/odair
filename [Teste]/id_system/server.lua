local playerIdElementData = "account:id"
local adminAclGroupName = "Console"
local eventPrefix = "idSystem"
local database

local function setPlayerAccountId(player, id)
    if not isElement(player) then
        return false
    end

    setElementData(player, playerIdElementData, tostring(id), true)
    return true
end

local function clearPlayerAccountId(player)
    if isElement(player) then
        removeElementData(player, playerIdElementData)
    end
end

local function getAccountNameSafe(account)
    if not account or isGuestAccount(account) then
        return nil
    end

    return getAccountName(account)
end

local function hasIdAdminAccess(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    local account = getPlayerAccount(player)
    local accountName = getAccountNameSafe(account)
    if not accountName then
        return false
    end

    local aclGroup = aclGetGroup(adminAclGroupName)
    if not aclGroup then
        return false
    end

    return isObjectInACLGroup("user." .. accountName, aclGroup)
end

local function ensureDatabase()
    if database then
        return true
    end

    database = dbConnect("sqlite", "ids.db")
    if not database then
        outputDebugString("[id_system] Falha ao conectar no banco SQLite.", 1)
        return false
    end

    dbExec(database, [[
        CREATE TABLE IF NOT EXISTS account_ids (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_name TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL
        )
    ]])

    return true
end

local function getRowByAccountName(accountName)
    if not ensureDatabase() then
        return nil
    end

    local result = dbPoll(dbQuery(database, "SELECT id, account_name FROM account_ids WHERE account_name = ? LIMIT 1", accountName), -1)
    if result and result[1] then
        return result[1]
    end

    return nil
end

local function getRowById(id)
    if not ensureDatabase() then
        return nil
    end

    local result = dbPoll(dbQuery(database, "SELECT id, account_name FROM account_ids WHERE id = ? LIMIT 1", id), -1)
    if result and result[1] then
        return result[1]
    end

    return nil
end

local function getAllRows()
    if not ensureDatabase() then
        return {}
    end

    local result = dbPoll(dbQuery(database, "SELECT id, account_name FROM account_ids ORDER BY id ASC"), -1)
    return result or {}
end

local function createAccountRow(accountName)
    if not ensureDatabase() then
        return nil
    end

    dbExec(database, "INSERT OR IGNORE INTO account_ids (account_name, created_at) VALUES (?, ?)", accountName, getRealTime().timestamp)
    return getRowByAccountName(accountName)
end

local function refreshAutoIncrement()
    if not ensureDatabase() then
        return
    end

    local result = dbPoll(dbQuery(database, "SELECT MAX(id) AS max_id FROM account_ids"), -1)
    local maxId = 0
    if result and result[1] and result[1].max_id then
        maxId = tonumber(result[1].max_id) or 0
    end

    dbExec(database, "UPDATE sqlite_sequence SET seq = ? WHERE name = 'account_ids'", maxId)
    dbExec(database, "INSERT OR IGNORE INTO sqlite_sequence (name, seq) VALUES ('account_ids', ?)", maxId)
end

local function ensureAccountRow(account)
    local accountName = getAccountNameSafe(account)
    if not accountName then
        return nil
    end

    local row = getRowByAccountName(accountName)
    if row then
        return row
    end

    return createAccountRow(accountName)
end

local function syncPlayerAccountId(player)
    if not isElement(player) or getElementType(player) ~= "player" then
        return
    end

    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then
        clearPlayerAccountId(player)
        return
    end

    local row = ensureAccountRow(account)
    if row and row.id then
        setPlayerAccountId(player, row.id)
    end
end

local function syncAllOnlinePlayers()
    for _, player in ipairs(getElementsByType("player")) do
        syncPlayerAccountId(player)
    end
end

local function syncAllKnownAccounts()
    for _, account in ipairs(getAccounts()) do
        if not isGuestAccount(account) then
            ensureAccountRow(account)
        end
    end

    refreshAutoIncrement()
end

local function setAccountIdByName(accountName, numericId)
    dbExec(database, "UPDATE account_ids SET id = ? WHERE account_name = ?", numericId, accountName)
    refreshAutoIncrement()
    syncAllOnlinePlayers()
    return getRowByAccountName(accountName)
end

local function sendAdminList(player)
    syncAllKnownAccounts()
    triggerClientEvent(player, eventPrefix .. ":receiveAccountList", resourceRoot, getAllRows())
end

addEventHandler("onResourceStart", resourceRoot, function()
    if not ensureDatabase() then
        return
    end

    syncAllKnownAccounts()
    syncAllOnlinePlayers()
end)

addEventHandler("onPlayerLogin", root, function(_, currentAccount)
    local row = ensureAccountRow(currentAccount)
    if row and row.id then
        setPlayerAccountId(source, row.id)
        outputChatBox("Seu ID permanente e: " .. tostring(row.id), source, 80, 255, 120)
    end
end)

addEventHandler("onPlayerLogout", root, function()
    clearPlayerAccountId(source)
end)

addCommandHandler("meuid", function(player)
    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then
        outputChatBox("Voce precisa estar logado em uma conta para ter um ID permanente.", player, 255, 80, 80)
        return
    end

    local row = ensureAccountRow(account)
    if not row or not row.id then
        outputChatBox("Nao foi possivel carregar seu ID no banco de dados.", player, 255, 80, 80)
        return
    end

    setPlayerAccountId(player, row.id)
    outputChatBox("Seu ID atual e: " .. tostring(row.id), player, 80, 255, 120)
end)

addCommandHandler("setid", function(player, _, newId)
    if not hasIdAdminAccess(player) then
        outputChatBox("Apenas quem tem ACL Console pode alterar IDs.", player, 255, 80, 80)
        return
    end

    local account = getPlayerAccount(player)
    local accountName = getAccountNameSafe(account)
    if not accountName then
        outputChatBox("Voce precisa estar logado em uma conta para alterar o ID.", player, 255, 80, 80)
        return
    end

    local numericId = tonumber(newId)
    if not numericId or numericId < 1 or numericId ~= math.floor(numericId) then
        outputChatBox("Use /setid [numero]. O ID precisa ser um numero inteiro maior que 0.", player, 255, 220, 120)
        return
    end

    local rowWithTargetId = getRowById(numericId)
    if rowWithTargetId and rowWithTargetId.account_name ~= accountName then
        outputChatBox("Esse ID ja esta sendo usado por outra conta.", player, 255, 80, 80)
        return
    end

    local updatedRow = setAccountIdByName(accountName, numericId)
    if not updatedRow or tonumber(updatedRow.id) ~= numericId then
        outputChatBox("Nao foi possivel atualizar o ID no banco de dados.", player, 255, 80, 80)
        return
    end

    outputChatBox("Seu novo ID foi salvo com sucesso: " .. tostring(updatedRow.id), player, 80, 255, 120)
end)

addCommandHandler("idchange", function(player)
    if not hasIdAdminAccess(player) then
        outputChatBox("Apenas quem tem ACL Console pode usar /idchange.", player, 255, 80, 80)
        return
    end

    sendAdminList(player)
    triggerClientEvent(player, eventPrefix .. ":toggleAdminPanel", resourceRoot, true)
end)

addEvent(eventPrefix .. ":requestAccountList", true)
addEventHandler(eventPrefix .. ":requestAccountList", root, function()
    if client ~= source or not hasIdAdminAccess(client) then
        return
    end

    sendAdminList(client)
end)

addEvent(eventPrefix .. ":updateAccountId", true)
addEventHandler(eventPrefix .. ":updateAccountId", root, function(targetAccountName, newId)
    if client ~= source or not hasIdAdminAccess(client) then
        return
    end

    if type(targetAccountName) ~= "string" or targetAccountName == "" then
        outputChatBox("Conta invalida para alteracao de ID.", client, 255, 80, 80)
        return
    end

    local numericId = tonumber(newId)
    if not numericId or numericId < 1 or numericId ~= math.floor(numericId) then
        outputChatBox("O novo ID precisa ser um numero inteiro maior que 0.", client, 255, 220, 120)
        return
    end

    local targetRow = getRowByAccountName(targetAccountName)
    if not targetRow then
        outputChatBox("A conta selecionada nao foi encontrada no banco.", client, 255, 80, 80)
        return
    end

    local rowWithTargetId = getRowById(numericId)
    if rowWithTargetId and rowWithTargetId.account_name ~= targetAccountName then
        outputChatBox("Esse ID ja esta sendo usado por outra conta.", client, 255, 80, 80)
        return
    end

    local updatedRow = setAccountIdByName(targetAccountName, numericId)
    if not updatedRow or tonumber(updatedRow.id) ~= numericId then
        outputChatBox("Nao foi possivel atualizar o ID da conta selecionada.", client, 255, 80, 80)
        return
    end

    outputChatBox("ID da conta " .. targetAccountName .. " alterado para " .. tostring(updatedRow.id) .. ".", client, 80, 255, 120)
    sendAdminList(client)
end)
