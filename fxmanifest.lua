fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'smxpusha#1972'
description 'Core Script by SMX Development'
version '1.0.0'

escrow_ignore {
	'config.lua'
  }

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/css/*.css',
    'html/js/*.js',
}

client_script {
    'config.lua',
    'client/*.lua'
}

exports {
    'openDefaultMenu',
    'closeDefaultMenu',
    'getDefaultMenu',
    'closeAllDefaultMenus',
    'openDialogMenu',
    'closeDialogMenu',
    'getOpenedDialogMenu',
    'ShowTextUI',
    'HideTextUI',
    'GetJob',
    'GetPlayerData',
    'GetIdentifier',
    'HasItem',
    'IsBoss',
    'ShowNotification'
}