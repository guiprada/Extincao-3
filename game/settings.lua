-- Guilherme Cunha Prada 2020

local settings = {}

-- general game settings
-- settings.screen_width = 1920
-- settings.screen_height = 1080
settings.fullscreen = true

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
settings.ghost_genetic_on = true
settings.ghost_fitness_on = true
settings.ghost_migration_on = true
settings.ghost_selective_migration_on = false
settings.ghost_fear_on = true
settings.ghost_go_home_on_scatter = true
settings.ghost_chase_feared_gene_on = true
settings.ghost_scatter_feared_gene_on = true
settings.ghost_target_spread = 15
settings.ghost_fear_spread = 50

-- pill module settings
settings.pill_genetic_on = false
settings.pill_precise_crossover_on = false

-- gameplay settings
settings.n_ghosts = 20 --at least 3
settings.n_pills = 6	-- at least 2
settings.n_particles = 250

settings.pill_time = 3
settings.restart_pill_time = 3

settings.ghost_chase_time = 12
settings.ghost_scatter_time = 7
settings.ghost_respawn_time = 30

settings.speed_boost_on = true
settings.ghost_speed_max_factor = 1.1
settings.player_speed_factor = 5

return settings
