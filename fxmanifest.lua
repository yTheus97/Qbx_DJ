fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'
author 'Antigravity'
description 'Immersive DJ Job Script'
version '0.1.0'


dependencies {
    'ox_lib', 
    'qbx_core'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua', 
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'locales/*.json',
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
