local Config = Config or {}

if type(Config) ~= 'table' or not Config.UsePermissions then
    Config = Config or {} 
    Config.UsePermissions = false
    Config.Job = 'dj' 
end

local function IsPlayerAllowed(source)
    if not Config.UsePermissions then
        return true
    end

    if GetResourceState('qbx_core') == 'started' then
        local player = exports.qbx_core:GetPlayer(source)
        if player then
            if player.PlayerData.job.name == Config.Job then
                return true
            end
        end
    end

    if IsPlayerAceAllowed(source, Config.AcePermission) or IsPlayerAceAllowed(source, 'command') then
        return true
    end

    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in ipairs(identifiers) do
        for _, allowed in ipairs(Config.AllowedPlayers) do
            if identifier == allowed then
                return true
            end
        end
    end

    return false
end

local AllowedProps = {
    ['prop_dj_deck_01'] = true,
    ['prop_speaker_06'] = true,
    ['prop_speaker_05'] = true,
    ['prop_speaker_08'] = true,
    ['prop_spot_01'] = true,
    ['prop_worklight_03b'] = true,
    ['prop_worklight_04c'] = true,
    ['prop_air_bigradar'] = true,
    ['prop_air_towbar_01'] = true,
    ['prop_air_bigradar_l2'] = true,
    ['prop_tv_flat_01'] = true,
    ['prop_tv_flat_michael'] = true,
    ['prop_neon_01'] = true,
    ['prop_bar_stool_01'] = true,
    ['prop_bar_pump_06'] = true,
    ['prop_table_03'] = true,
    ['prop_table_04'] = true,
    ['prop_table_06'] = true,
    ['prop_barrier_work05'] = true,
    ['prop_beach_fire'] = true
}

local audioZones = {}
local persistentProps = {}

function GenerateZoneId()
    return string.format("zone_%d_%d", os.time(), math.random(1000, 9999))
end

RegisterNetEvent('dj:syncAudio', function(data)
    local src = source
    local zoneId = data.zoneId

    if not zoneId or not audioZones[zoneId] then return end
    if not data.deck then return end

    local djEntity = NetworkGetEntityFromNetworkId(audioZones[zoneId].djTable)
    if DoesEntityExist(djEntity) then
        local ped = GetPlayerPed(src)
        local dist = #(GetEntityCoords(ped) - GetEntityCoords(djEntity))
        if dist > 15.0 then return end
    end

    local deckKey = 'deck_' .. data.deck
    if not audioZones[zoneId][deckKey] then return end

    if data.action == 'play' then
        audioZones[zoneId][deckKey].url = data.url
        audioZones[zoneId][deckKey].playing = true
        audioZones[zoneId][deckKey].startTime = os.time()
        TriggerClientEvent('dj:playAudio', -1, zoneId, data.deck, data.url, 0)
    elseif data.action == 'stop' then
        audioZones[zoneId][deckKey].playing = false
        TriggerClientEvent('dj:stopAudio', -1, zoneId, data.deck)
    elseif data.action == 'pause' then
        audioZones[zoneId][deckKey].playing = false
        TriggerClientEvent('dj:pauseAudio', -1, zoneId, data.deck)
    end
end)

RegisterNetEvent('dj:syncVolume', function(data)
    TriggerClientEvent('dj:updateDeckVolume', -1, data.deck, data.volume)
end)

RegisterNetEvent('dj:spawnProp', function(data)
    local src = source

    if not IsPlayerAllowed(src) then return end
    if not AllowedProps[data.prop] then return end

    local coords = data.coords
    local heading = data.heading
    local model = data.prop

    local obj = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, true, true, false)

    local timeout = 0
    while not DoesEntityExist(obj) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    if DoesEntityExist(obj) then
        SetEntityHeading(obj, heading)
        FreezeEntityPosition(obj, true)
        SetEntityRoutingBucket(obj, 0)

        local netId = NetworkGetNetworkIdFromEntity(obj)

        if model == 'prop_dj_deck_01' then
            local zoneId = GenerateZoneId()
            Entity(obj).state:set('zoneId', zoneId, true)
            Entity(obj).state:set('propType', 'dj_table', true)

            audioZones[zoneId] = {
                djTable = netId,
                speakers = {},
                effects = {},
                deck_a = { url = nil, playing = false, startTime = 0 },
                deck_b = { url = nil, playing = false, startTime = 0 }
            }
        elseif model == 'prop_speaker_06' or model == 'prop_speaker_05' or model == 'prop_speaker_08' then
            Entity(obj).state:set('propType', 'speaker', true)
            Entity(obj).state:set('zoneId', nil, true)
        else
            Entity(obj).state:set('propType', 'effect', true)
        end

        if data.effectConfig then
            local effectConfigs = { effect1 = data.effectConfig }
            Entity(obj).state:set('effectConfigs', effectConfigs, true)
        end

        persistentProps[netId] = {
            model = model,
            coords = coords,
            heading = heading,
            propType = Entity(obj).state.propType,
            zoneId = Entity(obj).state.zoneId,
            effectConfigs = Entity(obj).state.effectConfigs
        }

        Wait(100)
        TriggerClientEvent('dj:propSpawned', -1, netId)
    end
end)

RegisterNetEvent('dj:removeSpecificProp', function(netId)
    local src = source

    if not IsPlayerAllowed(src) then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        local propType = Entity(entity).state.propType
        local zoneId = Entity(entity).state.zoneId

        if propType == nil then return end

        if propType == 'dj_table' and zoneId and audioZones[zoneId] then
            for _, speakerNetId in ipairs(audioZones[zoneId].speakers) do
                local speakerEntity = NetworkGetEntityFromNetworkId(speakerNetId)
                if DoesEntityExist(speakerEntity) then
                    Entity(speakerEntity).state:set('zoneId', nil, true)
                    TriggerClientEvent('dj:speakerUnlinked', -1, speakerNetId)
                end
            end

            for _, effectNetId in ipairs(audioZones[zoneId].effects) do
                local effectEntity = NetworkGetEntityFromNetworkId(effectNetId)
                if DoesEntityExist(effectEntity) then
                    Entity(effectEntity).state:set('zoneId', nil, true)
                    TriggerClientEvent('dj:effectUnlinked', -1, effectNetId)
                end
            end

            TriggerClientEvent('dj:stopAudio', -1, zoneId, 'a')
            TriggerClientEvent('dj:stopAudio', -1, zoneId, 'b')

            audioZones[zoneId] = nil
        elseif propType == 'speaker' and zoneId then
            if audioZones[zoneId] then
                for i, speakerNetId in ipairs(audioZones[zoneId].speakers) do
                    if speakerNetId == netId then
                        table.remove(audioZones[zoneId].speakers, i)
                        break
                    end
                end
            end
            TriggerClientEvent('dj:speakerUnlinked', -1, netId)
        elseif propType == 'effect' and zoneId then
            if audioZones[zoneId] then
                for i, effectNetId in ipairs(audioZones[zoneId].effects) do
                    if effectNetId == netId then
                        table.remove(audioZones[zoneId].effects, i)
                        break
                    end
                end
            end
            TriggerClientEvent('dj:effectUnlinked', -1, netId)
        end

        if persistentProps[netId] then
            persistentProps[netId] = nil
        end

        DeleteEntity(entity)
    end
end)

RegisterNetEvent('dj:linkSpeaker', function(speakerNetId, zoneId)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local speaker = NetworkGetEntityFromNetworkId(speakerNetId)

    if not DoesEntityExist(speaker) or not audioZones[zoneId] then return end

    Entity(speaker).state.zoneId = zoneId
    table.insert(audioZones[zoneId].speakers, speakerNetId)

    TriggerClientEvent('dj:speakerLinked', -1, speakerNetId, zoneId)
end)

RegisterNetEvent('dj:unlinkSpeaker', function(speakerNetId)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local speaker = NetworkGetEntityFromNetworkId(speakerNetId)
    if not DoesEntityExist(speaker) then return end

    local zoneId = Entity(speaker).state.zoneId
    if zoneId and audioZones[zoneId] then
        for i, netId in ipairs(audioZones[zoneId].speakers) do
            if netId == speakerNetId then
                table.remove(audioZones[zoneId].speakers, i)
                break
            end
        end
    end

    Entity(speaker).state.zoneId = nil
    TriggerClientEvent('dj:speakerUnlinked', -1, speakerNetId)
end)

RegisterNetEvent('dj:linkEffect', function(effectNetId, zoneId)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local effect = NetworkGetEntityFromNetworkId(effectNetId)

    if not DoesEntityExist(effect) or not audioZones[zoneId] then return end

    if not audioZones[zoneId].effects then
        audioZones[zoneId].effects = {}
    end

    Entity(effect).state.zoneId = zoneId
    Entity(effect).state.propType = 'effect'
    table.insert(audioZones[zoneId].effects, effectNetId)

    local currentConfigs = Entity(effect).state.effectConfigs
    if not currentConfigs or type(currentConfigs) ~= 'table' then
        local oldConfig = Entity(effect).state.effectConfig
        if oldConfig and oldConfig.type and oldConfig.type ~= 'none' then
            Entity(effect).state:set('effectConfigs', { effect1 = oldConfig }, true)
        end
    end

    TriggerClientEvent('dj:effectLinked', -1, effectNetId, zoneId)
end)

RegisterNetEvent('dj:unlinkEffect', function(effectNetId)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local effect = NetworkGetEntityFromNetworkId(effectNetId)
    if not DoesEntityExist(effect) then return end

    local zoneId = Entity(effect).state.zoneId
    if zoneId and audioZones[zoneId] and audioZones[zoneId].effects then
        for i, netId in ipairs(audioZones[zoneId].effects) do
            if netId == effectNetId then
                table.remove(audioZones[zoneId].effects, i)
                break
            end
        end
    end

    Entity(effect).state.zoneId = nil
    Entity(effect).state.propType = nil
    TriggerClientEvent('dj:effectUnlinked', -1, effectNetId)
end)

RegisterNetEvent('dj:spawnVisual', function(data)
    local src = source
    if not IsPlayerAllowed(src) then return end
    TriggerClientEvent('dj:spawnVisualClient', -1, data.visual, source)
end)

RegisterNetEvent('dj:requestSync', function()
    local src = source

    for netId, propData in pairs(persistentProps) do
        local entity = NetworkGetEntityFromNetworkId(netId)

        if not DoesEntityExist(entity) then
            local obj = CreateObject(GetHashKey(propData.model), propData.coords.x, propData.coords.y, propData.coords.z,
                true, true, false)

            if DoesEntityExist(obj) then
                SetEntityHeading(obj, propData.heading)
                FreezeEntityPosition(obj, true)
                SetEntityRoutingBucket(obj, 0)

                local newNetId = NetworkGetNetworkIdFromEntity(obj)

                if propData.propType then Entity(obj).state:set('propType', propData.propType, true) end
                if propData.zoneId then Entity(obj).state:set('zoneId', propData.zoneId, true) end
                if propData.effectConfigs then Entity(obj).state:set('effectConfigs', propData.effectConfigs, true) end

                persistentProps[newNetId] = propData
                persistentProps[netId] = nil

                TriggerClientEvent('dj:propSpawned', src, newNetId)
            end
        else
            TriggerClientEvent('dj:propSpawned', src, netId)
        end
    end

    for zoneId, zone in pairs(audioZones) do
        for deck, info in pairs({ a = zone.deck_a, b = zone.deck_b }) do
            if info.playing and info.url then
                local timeDiff = os.time() - info.startTime
                TriggerClientEvent('dj:playAudio', src, zoneId, deck, info.url, timeDiff)
            end
        end
        if zone.musicState then
            TriggerClientEvent('dj:syncMusicState', src, zoneId, zone.musicState)
        end
    end
end)

RegisterNetEvent('dj:broadcastBeat', function(zoneId, bpm)
    if not audioZones[zoneId] then return end
    TriggerClientEvent('dj:receiveBeat', -1, zoneId, bpm)
end)

RegisterNetEvent('dj:updateMusicState', function(zoneId, playing, bpm)
    if not audioZones[zoneId] then return end

    audioZones[zoneId].musicState = {
        playing = playing,
        bpm = bpm,
        lastUpdate = os.time()
    }

    TriggerClientEvent('dj:syncMusicState', -1, zoneId, audioZones[zoneId].musicState)
end)

RegisterNetEvent('dj:addEffect', function(netId, effectConfig)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local prop = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(prop) then return end

    local currentEffects = Entity(prop).state.effectConfigs or {}
    local effectId = string.format("effect%d", os.time() + math.random(1, 9999))

    currentEffects[effectId] = effectConfig
    Entity(prop).state:set('effectConfigs', currentEffects, true)
end)

RegisterNetEvent('dj:removeEffect', function(netId, effectId)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local prop = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(prop) then return end

    local currentEffects = Entity(prop).state.effectConfigs or {}
    currentEffects[effectId] = nil
    Entity(prop).state:set('effectConfigs', currentEffects, true)
end)

RegisterNetEvent('dj:updateEffect', function(netId, effectId, newConfig)
    local src = source
    if not IsPlayerAllowed(src) then return end

    local prop = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(prop) then return end

    local currentEffects = Entity(prop).state.effectConfigs or {}
    currentEffects[effectId] = newConfig
    Entity(prop).state:set('effectConfigs', currentEffects, true)
end)
