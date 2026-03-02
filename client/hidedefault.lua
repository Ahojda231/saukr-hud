local skrytyKusy = {
    1, 2, 3, 4, 5, 6, 7, 8, 9, 13, 17, 20, 21, 22,
}

local mapkaScaleform = RequestScaleformMovie("minimap")
while not HasScaleformMovieLoaded(mapkaScaleform) do
    Citizen.Wait(0)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for i = 1, #skrytyKusy do
            HideHudComponentThisFrame(skrytyKusy[i])
        end
        RemoveMultiplayerHudCash()
        RemoveMultiplayerBankCash()
        BeginScaleformMovieMethod(mapkaScaleform, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(2000)
    for i = 1, #skrytyKusy do
        SetHudComponentPosition(skrytyKusy[i], 999.0, 999.0)
    end
    SetMultiplayerHudCash(0, 0)
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    local hracId = PlayerId()
    SetPlayerHealthRechargeMultiplier(hracId, 0.0)
    local hracPed = PlayerPedId()
    if DoesEntityExist(hracPed) then
        SetEntityMaxHealth(hracPed, 200)
    end
end)

AddEventHandler('playerSpawned', function()
    Citizen.Wait(500)
    local hracId = PlayerId()
    SetPlayerHealthRechargeMultiplier(hracId, 0.0)
    SetMultiplayerHudCash(0, 0)
    for i = 1, #skrytyKusy do
        SetHudComponentPosition(skrytyKusy[i], 999.0, 999.0)
    end
end)
