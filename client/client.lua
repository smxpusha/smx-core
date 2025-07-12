local Framework = {}
print("^2[smx-core] CLIENT LUA GELADEN!^0")
local ESX, QBCore
print '^2Script is started^0'
print 'Script by ^6SMX Development^0'
function InitFramework()
    if Config.Framework == "esx" then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    elseif Config.Framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end

-- Direkt beim Start initialisieren
InitFramework()

-- Exporte bereitstellen
exports('InitFramework', InitFramework)

exports('GetFramework', function()
    if Config.Framework == "esx" then
        return ESX
    elseif Config.Framework == "qb" then
        return QBCore
    end
end)


function Framework.GetPlayerData()
    if Config.Framework == "esx" then
        return ESX and ESX.GetPlayerData() or {}
    elseif Config.Framework == "qb" then
        return QBCore and QBCore.Functions.GetPlayerData() or {}
    end
    return {}
end

function Framework.GetJob()
    local data = Framework.GetPlayerData()
    return data.job and data.job.name or "unknown"
end

function Framework.RemoveMoney(amount, account)
    if Config.Framework == "esx" then
        TriggerServerEvent("esx:removeAccountMoney", account or "money", amount)
    elseif Config.Framework == "qb" then
        TriggerServerEvent("qb-core:server:RemoveMoney", account or "cash", amount)
    end
end

function Framework.AddItem(item, amount)
    if Config.Framework == "esx" then
        TriggerServerEvent("esx:addInventoryItem", item, amount)
    elseif Config.Framework == "qb" then
        TriggerServerEvent("qb-core:server:AddItem", item, amount)
    end
end
function Framework.GetIdentifier()
    local data = Framework.GetPlayerData()
    if Config.Framework == "esx" then
        return data.identifier
    elseif Config.Framework == "qb" then
        return data.citizenid
    end
    return "unknown"
end

function Framework.GetName()
    local data = Framework.GetPlayerData()
    return data.charname or data.name or "Unbekannt"
end

function Framework.HasJob(jobName)
    local job = Framework.GetJob()
    return job == jobName
end

function Framework.HasItem(itemName)
    local data = Framework.GetPlayerData()
    if not data or not data.items then return false end

    for _, item in pairs(data.items) do
        if item.name == itemName and item.amount > 0 then
            return true
        end
    end

    return false
end

function Framework.IsBoss()
    local data = Framework.GetPlayerData()
    local job = data.job or {}
    return (job.grade and job.grade_name == "boss") or (job.isboss == true)
end


-- Gemeinsame Hilfsfunktionen
local function Trim(str)
    if type(str) ~= "string" then
        str = tostring(str)
    end
    return str:match("^%s*(.-)%s*$")
end

local function Round(num)
    return math.floor(num + 0.5)
end

------------------------------------------------------------
-- DEFAULT MENU
------------------------------------------------------------
local GUI, DefaultMenuType, DefaultOpenedMenus, DefaultCurrentNS = {}, "default", 0, nil
GUI.Time = 0
local DefaultMenus = {}

function openDefaultMenu(namespace, name, data)
    if not DefaultMenus[namespace] then
        DefaultMenus[namespace] = {}
    end
    DefaultMenus[namespace][name] = data
    DefaultCurrentNS = namespace
    DefaultOpenedMenus = DefaultOpenedMenus + 1

    -- Nur erlaubte Felder in NUI schicken
    local uiData = {
        title = data.title,
        align = data.align,
        elements = data.elements,
    }

    SendNUIMessage({
        action = "openMenu",
        namespace = namespace,
        name = name,
        data = uiData,
    })

    -- Cursor optional aktivieren, standardmäßig false
    local cursor = data.cursor
    if cursor == nil then cursor = false end
    SetNuiFocus(true, cursor)
    SetNuiFocusKeepInput(true)
end




function closeDefaultMenu(namespace, name)
    if DefaultMenus[namespace] then
        DefaultMenus[namespace][name] = nil
    end

    DefaultCurrentNS = namespace
    DefaultOpenedMenus = DefaultOpenedMenus - 1
    if DefaultOpenedMenus < 0 then DefaultOpenedMenus = 0 end

    SendNUIMessage({
        action = "closeMenu",
        namespace = namespace,
        name = name,
    })

    -- Wenn keine Menüs mehr offen sind, Fokus entfernen
    if DefaultOpenedMenus == 0 then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
    
end

function updateDefaultMenuElements(namespace, name, newElements)
    local menu = getDefaultMenu(namespace, name)
    if not menu then return end

    menu.elements = newElements

    SendNUIMessage({
        action = "updateElements",
        namespace = namespace,
        name = name,
        elements = newElements,
    })
end

function getDefaultMenu(namespace, name)
    if DefaultMenus[namespace] then
        return DefaultMenus[namespace][name]
    end
    return nil
end

function closeAllDefaultMenus()
    for ns, menus in pairs(DefaultMenus) do
        for name, _ in pairs(menus) do
            closeDefaultMenu(ns, name)
        end
    end
    DefaultMenus = {}
    DefaultOpenedMenus = 0
end

RegisterNUICallback("menu_submit", function(data, cb)
    local menu = getDefaultMenu(data._namespace, data._name)
    if menu and menu.submit then
        menu.submit(data, menu)
    end
    cb("OK")
end)

RegisterNUICallback("menu_cancel", function(data, cb)
    local menu = getDefaultMenu(data._namespace, data._name)
    if menu and menu.cancel then
        menu.cancel(data, menu)
    end
    cb("OK")
end)

RegisterNUICallback("menu_change", function(data, cb)
    local menu = getDefaultMenu(data._namespace, data._name)
    if not menu then return cb("OK") end

    for i = 1, #data.elements do
        if menu.setElement then
            menu.setElement(i, "value", data.elements[i].value)
            menu.setElement(i, "selected", data.elements[i].selected or false)
        end
    end

    if menu.change then
        menu.change(data, menu)
    end
    cb("OK")
end)

-- Default keybinds
RegisterCommand("menu_enter", function()
    if DefaultOpenedMenus > 0 and (GetGameTimer() - GUI.Time) > 200 then
        SendNUIMessage({ action = "controlPressed", control = "ENTER" })
        GUI.Time = GetGameTimer()
    end
end, false)

RegisterCommand("menu_backspace", function()
    if DefaultOpenedMenus > 0 then
        SendNUIMessage({ action = "controlPressed", control = "BACKSPACE" })
        GUI.Time = GetGameTimer()
    end
end, false)

RegisterCommand("menu_up", function()
    if DefaultOpenedMenus > 0 then
        SendNUIMessage({ action = "controlPressed", control = "TOP" })
        GUI.Time = GetGameTimer()
    end
end, false)

RegisterCommand("menu_down", function()
    if DefaultOpenedMenus > 0 then
        SendNUIMessage({ action = "controlPressed", control = "DOWN" })
        GUI.Time = GetGameTimer()
    end
end, false)

RegisterCommand("menu_left", function()
    if DefaultOpenedMenus > 0 then
        SendNUIMessage({ action = "controlPressed", control = "LEFT" })
        GUI.Time = GetGameTimer()
    end
end, false)

RegisterCommand("menu_right", function()
    if DefaultOpenedMenus > 0 then
        SendNUIMessage({ action = "controlPressed", control = "RIGHT" })
        GUI.Time = GetGameTimer()
    end
end, false)

-- Keymapping
RegisterKeyMapping("menu_enter", "Submit menu item", "keyboard", "RETURN")
RegisterKeyMapping("menu_backspace", "Close menu", "keyboard", "BACK")
RegisterKeyMapping("menu_up", "Menu up", "keyboard", "UP")
RegisterKeyMapping("menu_down", "Menu down", "keyboard", "DOWN")
RegisterKeyMapping("menu_left", "Menu left", "keyboard", "LEFT")
RegisterKeyMapping("menu_right", "Menu right", "keyboard", "RIGHT")

------------------------------------------------------------
-- DIALOG MENU
------------------------------------------------------------
local DialogTimeouts, DialogOpened, DialogMenus = {}, {}, {}

function openDialogMenu(namespace, name, data)
    for i = 1, #DialogTimeouts do
        if DialogTimeouts[i] then
            ClearTimeout(DialogTimeouts[i])
        end
    end

    DialogOpened[namespace .. "_" .. name] = true

    if not DialogMenus[namespace] then DialogMenus[namespace] = {} end
    DialogMenus[namespace][name] = data

    local uiData = {
        title = data.title,
        type = data.type or "default", -- 🔥 WICHTIG!
        align = data.align,
        elements = data.elements
    }

    SendNUIMessage({
        action = "openMenu",
        namespace = namespace,
        name = name,
        data = uiData,
    })

    local timeoutId = SetTimeout(200, function()
        SetNuiFocus(true, true)
    end)

    table.insert(DialogTimeouts, timeoutId)
end



function closeDialogMenu(namespace, name)
    DialogOpened[namespace .. "_" .. name] = nil
    if DialogMenus[namespace] then DialogMenus[namespace][name] = nil end

    SendNUIMessage({
        action = "closeMenu",
        namespace = namespace,
        name = name,
    })

    if not next(DialogOpened) then
        SetNuiFocus(false)
    end
end

function getOpenedDialogMenu(namespace, name)
    if DialogMenus[namespace] then
        return DialogMenus[namespace][name]
    end
    return nil
end

RegisterNUICallback("menu_submit", function(data, cb)
    local menu = getOpenedDialogMenu(data._namespace, data._name)
    local cancel = false

    if menu and menu.submit then
        if tonumber(data.value) then
            data.value = Round(tonumber(data.value))
            if tonumber(data.value) <= 0 then cancel = true end
        end

        data.value = Trim(data.value)

        if cancel then
            print("[Dialog Menu] Ungültige Eingabe.")
        else
            menu.submit(data, menu)
        end
    end
    cb("ok")
end)

RegisterNUICallback("menu_cancel", function(data, cb)
    local menu = getOpenedDialogMenu(data._namespace, data._name)
    if menu and menu.cancel then
        menu.cancel(data, menu)
    end
    cb("ok")
end)

RegisterNUICallback("menu_change", function(data, cb)
    local menu = getOpenedDialogMenu(data._namespace, data._name)
    if menu and menu.change then
        menu.change(data, menu)
    end
    cb("ok")
end)

------------------------------------------------------------
-- RESOURCE STOP HANDLER
------------------------------------------------------------
AddEventHandler("onResourceStop", function(resource)
    if GetCurrentResourceName() == resource then
        closeAllDefaultMenus()
        for ns, menus in pairs(DialogMenus) do
            for name, _ in pairs(menus) do
                closeDialogMenu(ns, name)
            end
        end
    end
end)



--Notify
function ShowNotification(data)
    SendNUIMessage({
        action = "showNotify",
        type = data.type or "info", -- "success", "error", "info"
        title = data.title or "",
        text = data.text or "",
        time = data.time or Config.DefaultNotifyTime,
            position = Config.NotifyPosition
    })
end


local activeHelpKey = nil

function ShowHelpNotification(data)
    local key = data.key or Config.DefaultHelpKey
    local text = data.text or Config.DefaultHelpText
    local time = data.time or Config.DefaultNotifyTime

    -- Wenn gleiche Hilfe bereits aktiv ist, nichts tun
    if activeHelpKey == key then return end

    -- Neue Hilfe setzen
    activeHelpKey = key

    SendNUIMessage({
        action = "showHelp",
        key = key,
        text = text,
        time = time
    })

    -- Zeitlich gesteuert zurücksetzen
    SetTimeout(time, function()
        if activeHelpKey == key then
            activeHelpKey = nil
        end
    end)
end



RegisterNetEvent("smx-core:showProgressbar")
AddEventHandler("smx-core:showProgressbar", function(duration, label)
    SendNUIMessage({
        action = "showAdvancedProgressbar",
        duration = duration or 5000,
        label = label or "Wird verarbeitet..."
    })
end)


exports("ShowHelpNotification", ShowHelpNotification)
exports("GetPlayerData", Framework.GetPlayerData)
exports("GetJob", Framework.GetJob)
exports("RemoveMoney", Framework.RemoveMoney)
exports("AddItem", Framework.AddItem)
exports("GetIdentifier", Framework.GetIdentifier)
exports("GetName", Framework.GetName)
exports("HasJob", Framework.HasJob)
exports("HasItem", Framework.HasItem)
exports("IsBoss", Framework.IsBoss)
exports('ShowNotification', function(data)
    ShowNotification(data)
end)
exports('updateDefaultMenuElements', updateDefaultMenuElements)
