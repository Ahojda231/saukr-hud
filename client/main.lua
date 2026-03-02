local ESX = exports["es_extended"]:getSharedObject()

local pauza = false
local nacteno = false
local hudVypnut = false

local potreby = {
	hlad = 100,
	zizen = 100
}

local hlas = 2
local veVozidle = false
local bylVeVozidle = false
local pas = false

local function orezni(x)
	x = tonumber(x) or 0
	if x < 0 then return 0 end
	if x > 100 then return 100 end
	return x
end

local function procentaZeStatusu(st)
	if not st then return 100 end
	if type(st.getPercent) == "function" then
		local p = tonumber(st.getPercent()) or 0
		if p <= 1.0 then p = p * 100.0 end
		return orezni(p)
	end
	local val = tonumber(st.val)
	local max = tonumber(st.max)
	if val then
		if max and max > 0 then
			return orezni((val / max) * 100.0)
		end
		if val > 100.0 then
			return orezni(val / 10000.0)
		end
		return orezni(val)
	end
	return 100
end

local function jeNacteno()
	if nacteno then return true end
	if ESX and ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
		nacteno = true
		return true
	end
	return false
end

AddEventHandler("esx:playerLoaded", function()
	nacteno = true
end)

AddEventHandler("esx:onPlayerLogout", function()
	nacteno = false
end)

RegisterNetEvent("pma-voice:setTalkingMode", function(mod)
	hlas = tonumber(mod) or hlas
end)

RegisterCommand("pas", function()
	if veVozidle then
		pas = not pas
		SendNUIMessage({ action = "updateVehicleStatus", seatbelt = pas })
	end
end, false)

RegisterKeyMapping("pas", "Bezpečnostní pás", "keyboard", "B")

RegisterCommand("hud", function()
	hudVypnut = not hudVypnut
	if not pauza then
		SendNUIMessage({ action = "toggleHud", show = not hudVypnut })
	end
end, false)

local function obnovPotreby()
	if GetResourceState("esx_status") ~= "started" then return end
	TriggerEvent("esx_status:getAllStatus", function(stats)
		if type(stats) ~= "table" then return end
		for i = 1, #stats do
			local st = stats[i]
			if st and st.name == "hunger" then
				potreby.hlad = procentaZeStatusu(st)
			elseif st and st.name == "thirst" then
				potreby.zizen = procentaZeStatusu(st)
			end
		end
	end)
end

CreateThread(function()
	while true do
		if jeNacteno() and GetResourceState("esx_status") == "started" then
			break
		end
		Wait(200)
	end
	obnovPotreby()
	local posledniHlad = -1
	local posledniZizen = -1
	while true do
		obnovPotreby()
		local h = math.floor(orezni(potreby.hlad) + 0.0001)
		local t = math.floor(orezni(potreby.zizen) + 0.0001)
		if h ~= posledniHlad then
			potreby.hlad = h
			posledniHlad = h
		end
		if t ~= posledniZizen then
			potreby.zizen = t
			posledniZizen = t
		end
		Wait(200)
	end
end)

CreateThread(function()
	local scaleform = 0
	AddTextEntry("FE_THDR_GTAO", "~y~~h~Legacy RP")
	AddTextEntry("PM_SCR_MAP",  "~s~Mapa")
	AddTextEntry("PM_SCR_GAM",  "~s~Hra")
	AddTextEntry("PM_SCR_INF",  "~s~Info")
	AddTextEntry("PM_SCR_STA",  "~s~Statistiky")
	AddTextEntry("PM_SCR_SET",  "~s~Nastavení")
	AddTextEntry("PM_SCR_GAL",  "~s~Galerie")
	AddTextEntry("PM_PANE_LEAVE", "~s~Zpět na výběr serveru")
	AddTextEntry("PM_PANE_QUIT",  "~s~Ukončit hru")
	while true do
		Wait(0)
		local paused = IsPauseMenuActive()
		if paused and not pauza then
			pauza = true
			SendNUIMessage({ action = "toggleHud", show = false })
			SendNUIMessage({ action = "pauseOverlay", show = true })
			scaleform = RequestScaleformMovie("pause_menu_ped_previews")
			AddTextEntry("FE_THDR_GTAO", "~y~~h~Legacy RP")
		elseif not paused and pauza then
			pauza = false
			SendNUIMessage({ action = "toggleHud", show = not hudVypnut })
			SendNUIMessage({ action = "pauseOverlay", show = false })
			scaleform = 0
		end
		if paused then
			BeginScaleformMovieMethod(scaleform, "SET_HIGHLIGHT_COLOUR")
			ScaleformMovieMethodAddParamInt(212)
			ScaleformMovieMethodAddParamInt(175)
			ScaleformMovieMethodAddParamInt(55)
			ScaleformMovieMethodAddParamInt(255)
			EndScaleformMovieMethod()
			local sfHeader = RequestScaleformMovie("LOBBY_MENU_HD")
			if HasScaleformMovieLoaded(sfHeader) then
				BeginScaleformMovieMethod(sfHeader, "SET_HEADER_COLOUR")
				ScaleformMovieMethodAddParamInt(212)
				ScaleformMovieMethodAddParamInt(175)
				ScaleformMovieMethodAddParamInt(55)
				ScaleformMovieMethodAddParamInt(255)
				EndScaleformMovieMethod()
			end
		end
	end
end)

CreateThread(function()
	while true do
		local sleep = 200
		local ped = PlayerPedId()
		if not pauza and jeNacteno() then
			local zivot = GetEntityHealth(ped) - 100
			if zivot < 0 then zivot = 0 end
			if zivot > 100 then zivot = 100 end
			local brneni = orezni(GetPedArmour(ped))
			local sprintuje = IsPedSprinting(ped) or IsPedRunning(ped)
			local stamina = orezni(GetPlayerSprintStaminaRemaining(PlayerId()))
			local mluvi = NetworkIsPlayerTalking(PlayerId())
			SendNUIMessage({
				action = "updateStatus",
				health = zivot,
				armor = brneni,
				hunger = math.floor(potreby.hlad),
				thirst = math.floor(potreby.zizen),
				stamina = stamina,
				showStamina = sprintuje or stamina < 100,
				isTalking = mluvi,
				voice = hlas
			})
		end
		Wait(sleep)
	end
end)

CreateThread(function()
	while true do
		Wait(0)
		if veVozidle then
			DisableControlAction(0, 80, true)
			DisableControlAction(0, 81, true)
			DisableControlAction(0, 82, true)
			HideHudComponentThisFrame(19)
			if pas then
				DisableControlAction(0, 75, true)
				DisableControlAction(27, 75, true)
			end
		end
	end
end)

CreateThread(function()
	while true do
		local sleep = 200
		local ped = PlayerPedId()
		local vozidlo = GetVehiclePedIsIn(ped, false)
		veVozidle = vozidlo ~= 0
		if veVozidle ~= bylVeVozidle then
			if veVozidle then
				SendNUIMessage({ action = "vehicleEnter" })
				pas = false
			else
				SendNUIMessage({ action = "vehicleExit" })
				pas = false
			end
			bylVeVozidle = veVozidle
		end
		if veVozidle then
			sleep = 50
			local rychlost = GetEntitySpeed(vozidlo) * 2.237
			if rychlost < 0 then rychlost = 0 end
			local palivo = orezni(GetVehicleFuelLevel(vozidlo))
			local motor = GetVehicleEngineHealth(vozidlo)
			if motor < 0 then motor = 0 end
			if motor > 1000 then motor = 1000 end
			local _, svetla, dalkova = GetVehicleLightsState(vozidlo)
			local stavSvetel = 0
			if svetla == 1 then stavSvetel = 1 end
			if dalkova == 1 then stavSvetel = 2 end
			local gear = GetVehicleCurrentGear(vozidlo)
			local heading = GetEntityHeading(vozidlo)
			if heading < 0 then heading = heading + 360 end
			local coords = GetEntityCoords(vozidlo)
			local streetHash, crossStreetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
			local streetName = GetStreetNameFromHashKey(streetHash)
			local zoneName = GetNameOfZone(coords.x, coords.y, coords.z)
			local zoneLabel = GetLabelText(zoneName)
			SendNUIMessage({
				action = "updateVehicleStatus",
				speed = rychlost,
				fuel = palivo,
				engineHealth = motor,
				lights = stavSvetel,
				seatbelt = pas,
				heading = heading,
				gear = gear,
				street = streetName ~= "" and streetName or nil,
				zone = zoneLabel ~= "" and zoneLabel or nil
			})
			DisplayRadar(true)
		else
			DisplayRadar(false)
		end
		Wait(sleep)
	end
end)

AddEventHandler('playerSpawned', function()
	Citizen.Wait(100)
	SetRadarBigmapEnabled(false, false)
	DisplayRadar(false)
	SetRadarZoom(1000)
	Citizen.Wait(400)
	nasadCtverecek()
end)

local mapkaDebug = false

local function chytMapku()
	local safezone = GetSafeZoneSize()
	local safezone_x = 1.0 / 20.0
	local safezone_y = 1.0 / 20.0
	local aspect_ratio = GetAspectRatio(0)
	local res_x, res_y = GetActiveScreenResolution()
	local xscale = 1.0 / res_x
	local yscale = 1.0 / res_y
	local Minimap = {}
	Minimap.width = xscale * (res_x / (4 * aspect_ratio))
	Minimap.height = yscale * (res_y / 5.674)
	Minimap.left_x = xscale * (res_x * (safezone_x * ((math.abs(safezone - 1.0)) * 10)))
	Minimap.bottom_y = 1.0 - yscale * (res_y * (safezone_y * ((math.abs(safezone - 1.0)) * 10)))
	Minimap.right_x = Minimap.left_x + Minimap.width
	Minimap.top_y = Minimap.bottom_y - Minimap.height
	Minimap.x = Minimap.left_x
	Minimap.y = Minimap.top_y
	Minimap.xunit = xscale
	Minimap.yunit = yscale
	return Minimap, res_x, res_y
end

local posledniMapka = {
	res_x = 0,
	res_y = 0,
	safezone = 0,
	aspect = 0,
}

local function nasadCtverecek()
	local ui, res_x, res_y = chytMapku()
	RequestStreamedTextureDict("squaremap", false)
	while not HasStreamedTextureDictLoaded("squaremap") do
		Wait(100)
	end
	AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
	AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmask1g")
	AddReplaceTexture("platform:/textures/graphics", "radarmasklg", "squaremap", "radarmasklg")
	SetMinimapClipType(0)
	SetRadarBigmapEnabled(false, false)
	local defaultAspectRatio = 1920/1080
	local res_x_new, res_y_new = GetActiveScreenResolution()
	local aspectRatio = res_x_new/res_y_new
	local minimapOffset = 0
	if aspectRatio > defaultAspectRatio then
		minimapOffset = ((defaultAspectRatio-aspectRatio)/3.6)-0.008
	end
	SetMinimapComponentPosition("minimap", "L", "B", 0.0 + minimapOffset, -0.047, 0.1638, 0.183)
	SetMinimapComponentPosition("minimap_mask", "L", "B", 0.0 + minimapOffset, 0.0, 0.128, 0.20)
	SetMinimapComponentPosition("minimap_blur", "L", "B", -0.01 + minimapOffset, 0.025, 0.262, 0.300)
	SetBlipAlpha(GetNorthRadarBlip(), 0)
	SetRadarBigmapEnabled(true, false)
	SetMinimapClipType(0)
	Wait(50)
	SetRadarBigmapEnabled(false, false)
	SetRadarZoom(1000)
end

CreateThread(function()
	SetRadarBigmapEnabled(false, false)
	DisplayRadar(false)
	Wait(500)
	nasadCtverecek()
	while true do
		Wait(750)
		local res_x, res_y = GetActiveScreenResolution()
		local safezone = GetSafeZoneSize()
		local aspect = GetAspectRatio(0)
		if res_x ~= posledniMapka.res_x or res_y ~= posledniMapka.res_y or safezone ~= posledniMapka.safezone or aspect ~= posledniMapka.aspect then
			posledniMapka.res_x = res_x
			posledniMapka.res_y = res_y
			posledniMapka.safezone = safezone
			posledniMapka.aspect = aspect
			nasadCtverecek()
		end
	end
end)

CreateThread(function()
	while true do
		Wait(0)
		if mapkaDebug then
			local ui = chytMapku()
			local thickness = 3
			DrawRect(ui.left_x + ui.width / 2, ui.top_y + (thickness * ui.yunit) / 2, ui.width, thickness * ui.yunit, 255, 0, 0, 120)
			DrawRect(ui.left_x + ui.width / 2, ui.bottom_y - (thickness * ui.yunit) / 2, ui.width, thickness * ui.yunit, 255, 0, 0, 120)
			DrawRect(ui.left_x + (thickness * ui.xunit) / 2, ui.top_y + ui.height / 2, thickness * ui.xunit, ui.height, 255, 0, 0, 120)
			DrawRect(ui.right_x - (thickness * ui.xunit) / 2, ui.top_y + ui.height / 2, thickness * ui.xunit, ui.height, 255, 0, 0, 120)
		end
	end
end)
