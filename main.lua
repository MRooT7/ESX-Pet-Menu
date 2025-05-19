local ESX = exports['es_extended']:getSharedObject()

-- Database table setup
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `user_pets` (
            `id` INT AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `pet_type` VARCHAR(30) NOT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_pet` (`identifier`, `pet_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

-- Item usage handler
for petType, itemName in pairs(Config.PetItems) do
    ESX.RegisterUsableItem(itemName, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        
        MySQL.Async.fetchScalar('SELECT 1 FROM user_pets WHERE identifier = @id AND pet_type = @type', {
            ['@id'] = xPlayer.identifier,
            ['@type'] = petType
        }, function(exists)
            if exists then
                xPlayer.showNotification('You already own this pet!')
            else
                MySQL.Async.insert('INSERT INTO user_pets (identifier, pet_type) VALUES (@id, @type)', {
                    ['@id'] = xPlayer.identifier,
                    ['@type'] = petType
                }, function()
                    xPlayer.removeInventoryItem(itemName, 1)
                    xPlayer.showNotification('Pet unlocked: '..petType)
                end)
            end
        end)
    end)
end

-- Get player's pets callback
ESX.RegisterServerCallback('pet:getPets', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    MySQL.Async.fetchAll('SELECT pet_type FROM user_pets WHERE identifier = @id', {
        ['@id'] = xPlayer.identifier
    }, function(result)
        local pets = {}
        for _, row in ipairs(result) do
            table.insert(pets, row.pet_type)
        end
        cb(pets)
    end)
end)

-- Despawn event with ownership check
RegisterNetEvent('pet:despawnPet')
AddEventHandler('pet:despawnPet', function(petType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    MySQL.Async.fetchScalar('SELECT 1 FROM user_pets WHERE identifier = @id AND pet_type = @type', {
        ['@id'] = xPlayer.identifier,
        ['@type'] = petType
    }, function(exists)
        if exists then
            TriggerClientEvent('pet:despawnSingle', src, petType)
        else
            print(('[PET] %s attempted to despawn a pet they don\'t own: %s'):format(xPlayer.identifier, petType))
        end
    end)
end)

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    TriggerClientEvent('pet:despawnAll', source)
end)