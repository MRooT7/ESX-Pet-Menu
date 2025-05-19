ESX = exports["es_extended"]:getSharedObject()

local pets = {}           -- petType → Ped
local sittingStates = {}  -- petType → bool
local followingStates = {}-- petType → bool
local inVehicle = {}      -- petType → bool

-- Spawn pet
RegisterNetEvent('pet:spawnPet')
AddEventHandler('pet:spawnPet', function(petType)
    if pets[petType] and DoesEntityExist(pets[petType]) then return end

    local model = Config.PetModels[petType]
    if not model then return end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local playerPed = PlayerPedId()
    local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 2.0, 0.0)
    local petPed = CreatePed(28, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)

    SetEntityInvincible(petPed, true)
    SetBlockingOfNonTemporaryEvents(petPed, true)
    SetPedCanBeTargetted(petPed, false)
    SetPedAsGroupMember(petPed, GetPedGroupIndex(playerPed))
    SetPedNeverLeavesGroup(petPed, true)

    SetPedFleeAttributes(petPed, 0, false)
    SetPedCombatAttributes(petPed, 46, true) -- disable attacks
    SetPedCombatAttributes(petPed, 0, false)
    SetPedCanRagdoll(petPed, false)
    SetPedRelationshipGroupHash(petPed, GetHashKey("PLAYER"))
    SetPedAsEnemy(petPed, false)

    pets[petType] = petPed
    sittingStates[petType] = false
    followingStates[petType] = true
    inVehicle[petType] = false

    followPet(petType)
    ESX.ShowNotification("Your pet '" .. petType .. "' has arrived!")
end)

-- Despawn single pet
RegisterNetEvent('pet:despawnSingle')
AddEventHandler('pet:despawnSingle', function(petType)
    local petPed = pets[petType]
    if petPed and DoesEntityExist(petPed) then
        DeleteEntity(petPed)
        pets[petType] = nil
        sittingStates[petType] = nil
        followingStates[petType] = nil
        inVehicle[petType] = nil
        ESX.ShowNotification("Your pet '" .. petType .. "' has been dismissed.")
    end
end)

-- Despawn all pets
RegisterNetEvent('pet:despawnAll')
AddEventHandler('pet:despawnAll', function()
    for petType, petPed in pairs(pets) do
        if petPed and DoesEntityExist(petPed) then
            DeleteEntity(petPed)
        end
    end
    pets = {}
    sittingStates = {}
    followingStates = {}
    inVehicle = {}
    ESX.ShowNotification("All pets have been dismissed.")
end)

-- Make pet sit
function sitPet(petType)
    local petPed = pets[petType]
    if petPed then
        if not sittingStates[petType] then
            ClearPedTasks(petPed)
            TaskStartScenarioInPlace(petPed, 'WORLD_DOG_SITTING', 0, true)
            sittingStates[petType] = true
            followingStates[petType] = false
            ESX.ShowNotification("Your pet '" .. petType .. "' is now sitting.")
        else
            -- Make pet stand up
            ClearPedTasks(petPed)
            sittingStates[petType] = false
            followingStates[petType] = true
            followPet(petType)
            ESX.ShowNotification("Your pet '" .. petType .. "' is standing again.")
        end
    end
end

-- Make pet follow
function followPet(petType)
    local petPed = pets[petType]
    if petPed then
        ClearPedTasks(petPed)
        local playerPed = PlayerPedId()
        TaskFollowToOffsetOfEntity(petPed, playerPed, 0.0, 1.0, 0.0, 2.0, -1, 3.0, true)
        sittingStates[petType] = false
        followingStates[petType] = true
    end
end

-- Toggle follow behavior
function toggleFollow(petType)
    if followingStates[petType] then
        ClearPedTasks(pets[petType])
        followingStates[petType] = false
        ESX.ShowNotification("Your pet '" .. petType .. "' is no longer following you.")
    else
        followPet(petType)
        ESX.ShowNotification("Your pet '" .. petType .. "' is now following you.")
    end
end

-- Teleport pet to player (if too far away)
local function teleportPetToPlayer(petPed, playerPed)
    local playerCoords = GetEntityCoords(playerPed)
    local x, y = playerCoords.x + 1.0, playerCoords.y + 1.0
    local z = playerCoords.z + 50.0  -- Start high

    local foundGround, groundZ = false, 0.0
    local attempts = 0

    -- Find ground height from top down (20 attempts, every 2 meters)
    while not foundGround and attempts < 20 do
        foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z - attempts * 2.0, false)
        attempts = attempts + 1
        Citizen.Wait(5)
    end

    if not foundGround then
        groundZ = playerCoords.z -- Fallback to player Z
    end

    SetEntityCoordsNoOffset(petPed, x, y, groundZ, false, false, false)

    ClearPedTasksImmediately(petPed)
    TaskFollowToOffsetOfEntity(petPed, playerPed, 0.0, 1.0, 0.0, 2.0, -1, 3.0, true)
end

-- Open menu (F7)
RegisterCommand('openPetMenu', function()
    ESX.TriggerServerCallback('pet:getPets', function(userPets)
        if #userPets == 0 then
            ESX.ShowNotification("You don't own any pets.")
            return
        end

        local elements = {}
        for _, petType in pairs(userPets) do
            table.insert(elements, {label = "🐾 " .. petType, value = petType})
        end

        ESX.UI.Menu.CloseAll()
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pet_select_menu', {
            title = 'Your Pets',
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            local petType = data.current.value
            menu.close()

            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pet_action_menu', {
                title = 'Pet: ' .. petType,
                align = 'top-left',
                elements = {
                    {label = '🐾 Call', value = 'spawn'},
                    {label = '🚫 Dismiss', value = 'despawn'},
                    {label = '🪑 Sit/Stand', value = 'sit'},
                    {label = (followingStates[petType] and '❌ Stop following' or '✅ Start following'), value = 'toggle_follow'}
                }
            }, function(data2, menu2)
                if data2.current.value == 'spawn' then
                    TriggerEvent('pet:spawnPet', petType)
                elseif data2.current.value == 'despawn' then
                    TriggerServerEvent('pet:despawnPet', petType)
                elseif data2.current.value == 'sit' then
                    sitPet(petType)
                elseif data2.current.value == 'toggle_follow' then
                    toggleFollow(petType)
                end
                menu2.close()
            end, function(data2, menu2)
                menu2.close()
            end)
        end)
    end)
end)

-- Key mapping for menu (F7)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, GetHashKey(Config.MenuKey)) then
            ExecuteCommand('openPetMenu')
        end
    end
end)

-- Update loop for pet following, vehicle entry, and teleport if too far
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local playerVeh = GetVehiclePedIsIn(playerPed, false)

        for petType, petPed in pairs(pets) do
            if DoesEntityExist(petPed) then
                -- Put pet in vehicle
                if playerVeh ~= 0 and not inVehicle[petType] then
                    local seat = -1
                    for i = 0, GetVehicleMaxNumberOfPassengers(playerVeh) do
                        if IsVehicleSeatFree(playerVeh, i) then
                            seat = i
                            break
                        end
                    end
                    if seat ~= -1 then
                        TaskWarpPedIntoVehicle(petPed, playerVeh, seat)
                        inVehicle[petType] = true
                    end
                elseif playerVeh == 0 and inVehicle[petType] then
                    ClearPedTasks(petPed)
                    SetEntityCoords(petPed, GetEntityCoords(playerPed))
                    inVehicle[petType] = false
                    followPet(petType)
                end

                -- Ensure pet follows if it should and isn't sitting
                if followingStates[petType] and not sittingStates[petType] and not inVehicle[petType] then
                    local dist = #(GetEntityCoords(petPed) - GetEntityCoords(playerPed))
                    if dist > 20.0 then
                        teleportPetToPlayer(petPed, playerPed)
                    else
                        local isFollowingTask = IsTaskActive(petPed, 169) -- TASK_FOLLOW_TO_OFFSET_OF_ENTITY = 169
                        if not isFollowingTask then
                            TaskFollowToOffsetOfEntity(petPed, playerPed, 0.0, 1.0, 0.0, 2.0, -1, 3.0, true)
                        end
                    end
                end
            end
        end
    end
end)
