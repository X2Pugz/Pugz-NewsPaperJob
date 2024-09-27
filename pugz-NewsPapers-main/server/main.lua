local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize player XP and level
AddEventHandler('playerConnecting', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        Player.PlayerData.xp = Player.PlayerData.xp or 0
        Player.PlayerData.level = Player.PlayerData.level or 1
    end
end)

RegisterNetEvent('pugz-newspaper:delivery:started', function()
    local src = source
    print("Delivery started by player: " .. GetPlayerName(src))
end)

RegisterNetEvent('pugz-newspaper:delivery:completed', function()
    local src = source
    print("Delivery completed by player: " .. GetPlayerName(src))

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Reward cash
    local cashReward = math.random(Config.MinCashReward, Config.MaxCashReward)

    -- Scale cash reward based on XP level
    local levelMultiplier = 1 + (Player.PlayerData.level - 1) * 0.1 -- 10% increase per level
    cashReward = math.floor(cashReward * levelMultiplier)

    Player.Functions.AddMoney("cash", cashReward)
    TriggerClientEvent('QBCore:Notify', src, "You received $" .. cashReward .. " for the delivery!", "success")

    -- Add XP for delivery
    Player.PlayerData.xp = Player.PlayerData.xp + Config.XPPerDelivery

    -- Check for level up
    if Player.PlayerData.xp >= 100 and Player.PlayerData.level < Config.MaxXPLevel then
        Player.PlayerData.xp = 0
        Player.PlayerData.level = Player.PlayerData.level + 1
        TriggerClientEvent('QBCore:Notify', src, "Congratulations! You've reached level " .. Player.PlayerData.level .. "!", "success")
    end

    -- Send updated XP and level to client
    TriggerClientEvent('pugz-newspaper:showXP', src, Player.PlayerData.xp, Player.PlayerData.level)

    -- Chance to give item
    if math.random(1, 100) <= Config.ItemChance then
        if Player.Functions.AddItem(Config.ItemReward, 1) then
            TriggerClientEvent('QBCore:Notify', src, "You received a " .. Config.ItemReward .. "!", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "You do not have enough space in your inventory for a " .. Config.ItemReward .. "!", "error")
        end
    end
end)

-- Function to add reward and update XP
RegisterNetEvent('pugz-newspaper:delivery:giveReward', function(cashReward)
    local player = QBCore.Functions.GetPlayer(source)
    player.Functions.AddMoney("cash", cashReward)

    -- Update XP system
    if not playerXP[source] then playerXP[source] = 0 end
    playerXP[source] = playerXP[source] + math.random(5, 15) -- Random XP gain for delivery

    -- Check for level up
    if playerXP[source] >= 100 then  -- Level up logic (example)
        playerXP[source] = playerXP[source] - 100 -- Reset XP or decrease as needed
        -- Implement your level-up logic here
        QBCore.Functions.Notify(player.PlayerData.source, "You leveled up!", "success")
    end
end)

-- Retrieve XP level
RegisterNetEvent('pugz-newspaper:getXP', function()
    local src = source
    local xp = playerXP[src] or 0
    local level = math.floor(xp / 100)  -- Example level calculation

    -- Notify the player with their XP and level
    TriggerClientEvent('qb-notify', src, {
        title = "Your XP Level",
        text = "XP: " .. xp .. " | Level: " .. level,
        type = "inform"
    })
end)