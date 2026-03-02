local ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('hud:addStatus')
AddEventHandler('hud:addStatus', function(type, amount)
    local _source = source
    TriggerClientEvent('hud:modifyStatus', _source, type, amount)
end)