local QBCore = exports['qb-core']:GetCoreObject()
local currentDelivery = nil
local deliveryInProgress = false
local vehicle = nil
local deliveryCompleted = false
local deliveryIndex = 1  -- Track the current delivery index
local npcBlips = {}  -- Store NPC blips
local deliveryStartTime

-- Function to spawn NPCs
local function spawnNPCs()
    for _, loc in ipairs(Config.NPCLocations) do
        RequestModel('a_m_m_business_01')  -- Change to desired NPC model
        while not HasModelLoaded('a_m_m_business_01') do
            Wait(500)
        end

        local npc = CreatePed(4, 'a_m_m_business_01', loc.x, loc.y, loc.z, 0.0, false, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        FreezeEntityPosition(npc, true)  -- Freeze NPC position

        -- Add blip for the NPC
        local blip = AddBlipForEntity(npc)
        SetBlipSprite(blip, 280)  -- Choose a blip icon (customize as needed)
        SetBlipColour(blip, 5)  -- Set blip color (customize as needed)
        SetBlipScale(blip, 0.8)  -- Scale of the blip
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Newspaper Job")  -- Blip name
        EndTextCommandSetBlipName(blip)
        table.insert(npcBlips, blip)  -- Store blip

        exports['qb-target']:AddTargetEntity(npc, {
            options = {
                {
                    type = "client",
                    event = "pugz-newspaper:delivery:start",
                    icon = "fas fa-newspaper",
                    label = "Speak to NPC",
                },
                {
                    type = "client",
                    event = "pugz-newspaper:delivery:end",
                    icon = "fas fa-times",
                    label = "End Delivery Job",
                    canInteract = function()
                        return deliveryInProgress -- Show option only if job is in progress
                    end
                },
                {
                    type = "client",
                    event = "pugz-newspaper:delivery:claimReward",
                    icon = "fas fa-money-bill",
                    label = "Claim Reward",
                    canInteract = function()
                        return deliveryCompleted -- Show option only if delivery is completed
                    end
                },
            },
            distance = 2.0
        })
    end
end


local deliveryStartTime -- Variable to track delivery start time

-- Start the job
RegisterNetEvent('pugz-newspaper:startJob', function()
    deliveryStartTime = os.time() -- Store the start time
    local response = getRandomResponse()
    local deliveryEndTime = os.time()
    QBCore.Functions.Notify(response, "inform")
    -- Additional logic to start the job
end)

-- Complete delivery
RegisterNetEvent('pugz-newspaper:delivery:complete', function()
    local deliveryEndTime = os.time()
    local timeTaken = deliveryEndTime - deliveryStartTime

    local cashReward = math.random(Config.MinCashReward, Config.MaxCashReward)
    if timeTaken < 300 then  -- Less than 5 minutes
        cashReward = cashReward + 50 -- Bonus for quick delivery
        QBCore.Functions.Notify("You completed the delivery quickly! Bonus $50!", "success")
    end

    TriggerServerEvent('pugz-newspaper:delivery:giveReward', cashReward)
end)






-- Function to spawn the vehicle
local function spawnVehicle()
    local playerPed = PlayerPedId()
    local spawnCoords = Config.VehicleSpawnLocation

    RequestModel(Config.VehicleModel)
    while not HasModelLoaded(Config.VehicleModel) do
        Wait(500)
    end

    vehicle = CreateVehicle(Config.VehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(playerPed), true, false)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
end

-- Function to notify and set waypoint
local function notifyAndSetWaypoint(deliveryLocation)
    QBCore.Functions.Notify("Deliver the newspaper to the location!", "success")
    SetNewWaypoint(deliveryLocation.x, deliveryLocation.y)
end

-- Function to draw text on screen
local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local dist = Vdist(camCoords.x, camCoords.y, camCoords.z, x, y, z)
    local scale = (1 / dist) * 2
    if onScreen then
        SetTextScale(0.0, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.005 + factor, 0.03, 0, 0, 0, 75)
    end
end

-- Start delivery
RegisterNetEvent('pugz-newspaper:delivery:start', function()
    if deliveryInProgress then
        QBCore.Functions.Notify("You are already on a delivery!", "error")
        return
    end

    deliveryInProgress = true
    deliveryIndex = 1  -- Reset delivery index for new job
    spawnVehicle()  -- Spawn the vehicle
    currentDelivery = Config.DeliveryPoints[deliveryIndex]
    notifyAndSetWaypoint(currentDelivery)

    -- Notify server about the delivery start
    TriggerServerEvent('pugz-newspaper:delivery:started')
end)

-- End delivery job
RegisterNetEvent('pugz-newspaper:delivery:end', function()
    if not deliveryInProgress then
        QBCore.Functions.Notify("You are not currently on a delivery!", "error")
        return
    end

    deliveryInProgress = false
    QBCore.Functions.Notify("Delivery job has been ended.", "info")
end)

-- Check delivery completion and handle door interaction
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Continuous check

        if deliveryInProgress and currentDelivery then
            local playerCoords = GetEntityCoords(PlayerPedId())
            if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, currentDelivery.x, currentDelivery.y, currentDelivery.z) < 5.0 then
                DrawText3D(currentDelivery.x, currentDelivery.y, currentDelivery.z, "Press [E] to deliver the newspaper!")

                -- Check for interaction to deliver
                if IsControlJustReleased(0, 38) then -- E key
                    QBCore.Functions.Notify("Delivery complete! Proceed to the next location.", "success")
                    deliveryIndex = deliveryIndex + 1

                    -- Check if there are more deliveries
                    if deliveryIndex > #Config.DeliveryPoints then
                        -- All deliveries done
                        deliveryInProgress = false
                        deliveryCompleted = true
                        QBCore.Functions.Notify("All deliveries completed! Return to the NPC to get your money.", "info")
                        SetNewWaypoint(Config.NPCLocations[math.random(#Config.NPCLocations)].x, Config.NPCLocations[math.random(#Config.NPCLocations)].y) -- Set waypoint to NPC
                    else
                        -- Set waypoint to the next delivery point
                        currentDelivery = Config.DeliveryPoints[deliveryIndex]
                        notifyAndSetWaypoint(currentDelivery)
                    end
                end
            end
        end
    end
end)

-- Claim reward
RegisterNetEvent('pugz-newspaper:delivery:claimReward', function()
    if not deliveryCompleted then
        QBCore.Functions.Notify("You haven't completed a delivery yet!", "error")
        return
    end

    -- Calculate cash reward
    local cashReward = math.random(Config.MinCashReward, Config.MaxCashReward)

    -- Add cash to player and reset deliveryCompleted
    TriggerServerEvent('pugz-newspaper:delivery:giveReward', cashReward)


    -- Check for item reward
    if Config.ItemReward and math.random(1, 100) <= 100 then  -- 50% chance to receive the item
        TriggerServerEvent('qb-inventory:addItem', Config.ItemReward, 1)
        QBCore.Functions.Notify("You've received a " .. Config.ItemReward .. "!", "success")
    else
        QBCore.Functions.Notify("You didn't receive any item this time.", "info")
    end


    -- Delete the vehicle if it exists
    if vehicle then
        DeleteVehicle(vehicle)
        vehicle = nil
    end

    deliveryCompleted = false
  
     -- Notify about vehicle return
    QBCore.Functions.Notify("Vehicle taken back to the warehouse. Thank you!", "success")
end)

-- Check XP Level
RegisterNetEvent('pugz-newspaper:checkXP', function()
    TriggerServerEvent('pugz-newspaper:getXP')
end)


-- Event to display player XP and level after delivery
RegisterNetEvent('pugz-newspaper:showXP', function(xp, level)
    QBCore.Functions.Notify("You have " .. xp .. " XP and are at level " .. level .. ".", "info")
end)

-- Initialize the script
Citizen.CreateThread(function()
    spawnNPCs()
end)
