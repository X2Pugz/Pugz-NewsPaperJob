fx_version 'cerulean'
game 'gta5'

author 'Pugz'
description 'Newspaper Delivery Script for QB-Core'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'qb-core',
    'qb-target',
    'qb-notify'
}
