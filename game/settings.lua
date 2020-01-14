local settings = {}

-- general game settings
settings.screen_width = 1920
settings.screen_height = 1080
settings.fullscreen = true

-- ghost module settings
settings.ghost_genetic_on = true  	-- liga e desliga e GA
settings.ghost_fitness_on = true 	-- desliga a funcao fitness
settings.ghost_target_offset_freightned_on = true -- liga e desliga e gene target_offset_freightned
settings.ghost_migration_on = true
settings.ghost_selective_migration_on = false
settings.ghost_fear_on = true
settings.ghost_go_home_on_scatter = true
settings.ghost_chase_feared_gene_on = true
settings.ghost_scatter_feared_gene_on = true
settings.ghost_target_spread = 15
settings.ghost_fear_spread = 50

-- pill module settings
settings.pill_genetic_on = false-- liga e desliga o GA para pilulas
settings.pill_precise_crossover_on = false

-- player settings
settings.player_start_grid = {}
settings.player_start_grid.x = 28
settings.player_start_grid.y = 18

-- gameplay settings
settings.n_ghosts = 20 --at least 3
settings.n_pills = 6	-- at least 2

settings.pill_time = 3	-- tempo de duracao da pilula
settings.restart_pill_time = 3

settings.ghost_chase_time = 12 -- testado 3.99
settings.ghost_scatter_time = 7 --testado com 2
settings.ghost_respawn_time = 0 -- should be non zero  --  5 --15--20 testado

settings.speed_boost_on = true
settings.ghost_speed_max_factor = 1.1 		-- controla a velocidade maxima do fantasma em proporcao a velocidade inicial do fantasma

settings.player_speed_grid_size_factor = 5 -- speed = player_speed_grid_size_factor* grid_size

return settings
