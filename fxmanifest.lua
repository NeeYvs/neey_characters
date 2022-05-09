
fx_version 'bodacious'
game 'gta5'

ui_page 'html/ui.html'

files {
	'html/**',
}

client_scripts {
    'client.lua'
} 
server_scripts {
	'server.lua',
    '@mysql-async/lib/MySQL.lua'
} 
