fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'len_justice'
description 'Lennart'
version '2.0.0'

dependencies {
    'es_extended',
    'oxmysql',
}

shared_scripts {
    'config.lua',
    'locales/*.lua',
}

client_scripts {
    'client/utils.lua',
    'client/jail.lua',
    'client/comserv.lua',
    'client/adminjail.lua',
    'client/nui.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils.lua',
    'server/jail.lua',
    'server/comserv.lua',
    'server/adminjail.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}
