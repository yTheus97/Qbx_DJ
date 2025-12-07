Config = {}

-- ============================================
-- GENERAL SETTINGS
-- ============================================
Config.Debug = false
Config.DefaultBPM = 128
Config.MaxAudioDistance = 100.0
Config.VolumeFalloff = 1.5

-- ============================================
-- PERMISSIONS
-- ============================================

Config.UsePermissions = true -- Ativado para forçar a checagem

-- Define o Job necessário (QBox)
Config.Job = 'police'

-- add_ace group.admin command allow
Config.AcePermission = 'command'

-- Jogadores permitidos por ID (Steam, License, Discord)
Config.AllowedPlayers = {
    -- 'steam:110000xxxxxxxx',
    -- 'license:xxxxxxxxxxxxxxxx',
}

-- ============================================
-- COMMANDS
-- ============================================

Config.CommandDJ = 'dj'
Config.CommandBuilder = 'djbuilder'
Config.CommandBeatCheck = 'djbeatcheck'
Config.CommandBeatInfo = 'djbeatinfo'
Config.CommandBeatTest = 'djbeattest'
Config.CommandFix = 'djfix'

-- ============================================
-- KEYBINDS
-- ============================================

Config.BuilderKey = 167 -- F6
Config.EnableHotkeys = false
Config.Hotkeys = {
    [166] = 'deck_a_play',
    [167] = 'deck_b_play',
    [168] = 'stop_all',
    [169] = 'next_track',
    [170] = 'shuffle_toggle',
    [171] = 'repeat_toggle',
}

-- ============================================
-- ZONES
-- ============================================

Config.Zones = {
    {
        name = "Vanilla Unicorn",
        coords = vector3(120.0, -1280.0, 29.0),
        radius = 50.0,
        blip = {
            enabled = true,
            sprite = 136,
            color = 27,
            scale = 0.8
        }
    },
    {
        name = "Bahama Mamas",
        coords = vector3(-1387.0, -618.0, 30.0),
        radius = 50.0,
        blip = {
            enabled = true,
            sprite = 136,
            color = 27,
            scale = 0.8
        }
    },
}

-- ============================================
-- PROPS
-- ============================================

Config.MaxPropsPerPlayer = 50
Config.PropPlacementDistance = 5.0
Config.PropRotationSpeed = 2.0
Config.PropCollision = true
Config.FreezeProps = true

-- ============================================
-- EFFECTS
-- ============================================

Config.MaxEffectsPerProp = 5
Config.EffectIntensityMultiplier = 3.0
Config.EffectSyncEnabled = true
Config.EffectUpdateRate = 100

-- ============================================
-- AUDIO
-- ============================================

Config.DefaultVolume = 0.8
Config.MaxVolume = 1.0
Config.Enable3DAudio = true
Config.AudioUpdateRate = 100

-- ============================================
-- PLAYLIST
-- ============================================

Config.EnablePlaylist = true
Config.MaxTracksPerPlaylist = 100
Config.AutoPlayNext = true
Config.DefaultShuffle = false
Config.DefaultRepeat = false

-- ============================================
-- UI
-- ============================================

Config.UIScale = 1.0
Config.UITheme = 'dark'
Config.ShowNotifications = true
Config.NotificationDuration = 3000

-- ============================================
-- TARGET SYSTEM
-- ============================================

Config.TargetSystem = 'auto'
Config.TargetDistance = 2.5
Config.TargetIcon = 'fas fa-music'

-- ============================================
-- PERFORMANCE
-- ============================================

Config.PerformanceMode = false
Config.EffectRenderDistance = 50.0
Config.ReduceParticles = true

-- ============================================
-- LOGGING
-- ============================================

Config.EnableLogging = true
Config.LogLevel = 'info'
Config.LogToFile = false
Config.LogFilePath = 'logs/dj-system.log'

-- ============================================
-- ADVANCED
-- ============================================

Config.ExperimentalFeatures = false
Config.BeatSensitivity = 1.0
Config.SyncTolerance = 50
Config.NetworkUpdateRate = 100
