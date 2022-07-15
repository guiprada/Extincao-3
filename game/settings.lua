-- Guilherme Cunha Prada 2020

local settings = {}

-- general game settings
settings.screen_width = 1920
settings.screen_height = 1080
settings.fullscreen = false

-- player settings
settings.player_start_grid = {}
settings.player_start_grid.x = 28
settings.player_start_grid.y = 18

-- game texts
settings.menu_n_particles = 500

--
settings.menu_title = "extinction"
settings.menu_text = "'enter' to start game\n" .. "'esc' to exit"

settings.victory_title = "Well  Done!!!"
settings.victory_text = "'enter' or 'esc' go to menu"

------ the settings bellow are overriden by level settings ---------------------

-- game texts
settings.font = "fonts/PressStart2P-Regular.ttf"
settings.pause_text = "\n\n'enter' try again \n\n"
						.. "'esc' to exit\n\n"
						.. "'spacebar' to pause\n\n"
settings.font_size = 36
settings.font_size_small = 20
settings.font_size_big = 56

-- sounds
settings.ghost_flip_sound = love.audio.newSource("audio/tic.wav", "static")
settings.player_click = love.audio.newSource("audio/plip.wav", "static")
settings.pill_warn_sound = love.audio.newSource("audio/warn.wav", "static")

-- ghost module settings
settings.ghost_target_spread = 15
settings.ghost_fear_spread = 50

-- pill module settings

-- gameplay settings
settings.n_ghosts = 200 --at least 3
settings.n_pills = 6	-- at least 2
settings.n_particles = 250

settings.pill_time = 3
settings.restart_pill_time = 3

settings.ghost_chase_time = 12
settings.ghost_scatter_time = 7

settings.player_speed_factor = 20

return settings
