Config = {}

-- NPC locations for newspaper delivery using vector3
Config.NPCLocations = {
    vector3(133.92, 95.35, 82.51),  -- Adjust as necessary
}

-- Delivery points using vector3
Config.DeliveryPoints = {
    vector3(176.76, 228.89, 106.03),  -- Adjust as necessary
    vector3(-768.8, -356.01, 37.33),
    vector3(-115.62, -373.04, 38.13),
    vector3(-232.31, -915.54, 32.32),
}

-- Cash reward settings
Config.MinCashReward = 200
Config.MaxCashReward = 550

-- Item reward settings
Config.ItemReward = "water_bottle"  -- Change to the desired item
Config.ItemChance = 100  -- Chance to receive the item (percentage)

-- XP settings
Config.MaxXPLevel = 10
Config.XPPerDelivery = 2  -- XP earned per delivery

-- Vehicle model settings
Config.VehicleModel = "boxville2"  -- Change to the desired vehicle model
Config.VehicleSpawnLocation = vector3(138.01, 87.26, 82.05) -- Location where the vehicle will spawn
