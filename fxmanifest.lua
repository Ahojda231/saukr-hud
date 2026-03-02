fx_version 'cerulean'
game 'gta5'

description 'saukr_hud'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/*.png',
    'html/img/*.svg'
}

client_scripts {
    'client/hidedefault.lua',
    'client/main.lua'
}

server_scripts {
    'server/main.lua',
    'items.lua'
}

lua54 'yes'