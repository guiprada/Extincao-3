-- Guilherme Cunha Prada 2020
--------------------------------------------------------------------------------

local game = {}

local gamestate = require "gamestate"
local utils = require "utils"
local Grid = require "Grid"
local Ghost = require "Ghost"
local Player = require "Player"
local AutoPlayer = require "AutoPlayer"
local Timer = require "Timer"
local Pill = require "Pill"
local resizer = require "resizer"
local settings = require "settings"
local shaders = require "shaders"
local Particle = require "Particle"
local random = require "random"
local Population = require "Population"

-----------------------------------------------------------------------callbacks
function game.load(args)
	game.default_width = love.graphics.getWidth()
	game.default_height = love.graphics.getHeight()

	game.paused = true
	game.just_restarted = true
	game.resets = 0
	game.pause_text = args.pause_text or settings.pause_text

	-- pill state
	game.got_pill = false

	-- respawn timer
	local ghost_respawn_time = 	args.ghost_respawn_time or
								settings.ghost_respawn_time
	game.ghost_respawn_timer = Timer:new(ghost_respawn_time)

	-- game.ghost_state timer
	local ghost_scatter_time = 	args.ghost_scatter_time or
								settings.ghost_scatter_time
	game.ghost_state_timer = Timer:new(ghost_scatter_time)


	game.grid_size = resizer.init_resizer(	game.default_width,
											game.default_height,
											Grid.get_width(args.grid_types),
											Grid.get_height(args.grid_types))

	game.grid = Grid:new()
	game.grid:reset(args.grid_types, game.grid_size, game.grid_size/2)	-- if args.grid_types == null it defaults to grid.defalt_map

	-- registering fonts
	game.font_size = args.font_size or settings.font_size
	game.text_font = love.graphics.newFont(args.font or settings.font,
											game.font_size)

	game.font_size_small = args.font_size_small or settings.font_size_small
	game.text_font_small = love.graphics.newFont(args.font or settings.font,
											game.font_size_small)

	-- grid
	game.lookahead = game.grid_size/2

	local player_speed_factor = args.player_speed_factor or
										settings.player_speed_factor
	game.speed = player_speed_factor * game.grid_size
	game.ghost_speed = game.speed * 1

	-- start subsystems
	Player.init(game.grid, args.player_click or settings.player_click)
	Ghost.init(	game.grid,
				args.ghost_fitness_on or settings.ghost_fitness_on,
				args.ghost_target_spread or settings.ghost_target_spread,
				args.ghost_migration_on or settings.ghost_migration_on,
				args.ghost_selective_migration_on or
					settings.ghost_selective_migration_on,
				game.ghost_speed,
				args.speed_boost_on or settings.speed_boost_on,
				args.ghost_speed_max_factor or settings.ghost_speed_max_factor,
				args.ghost_fear_on or settings.ghost_fear_on,
				args.ghost_go_home_on_scatter or
					settings.ghost_go_home_on_scatter,
				args.ghost_chase_feared_gene_on or
					settings.ghost_chase_feared_gene_on,
				args.ghost_scatter_feared_gene_on or
					settings.ghost_scatter_feared_gene_on,
				game.grid_size,
				game.lookahead,
				"scattering")
	Pill.init(	game.grid,
				args.pill_genetic_on or settings.pill_genetic_on,
				args.pill_precise_crossover_on or
					settings.pill_precise_crossover_on,
				args.pill_warn_sound or settings.pill_warn_sound)
	AutoPlayer.init(game.grid)

	--start player
	game.grid_pos = {}
	if(args.player_start_grid)then
		game.grid_pos.x =  args.player_start_grid.x
		game.grid_pos.y =  args.player_start_grid.y
	else
		game.grid_pos.x = settings.player_start_grid.x
		game.grid_pos.y = settings.player_start_grid.y
	end
	game.player = Player:new()
	-- game.player:reset(game.grid_pos, game.speed)

	--start AutoPlayer population
	game.AutoPlayerPopulation = Population:new(AutoPlayer, game.speed, 20, 100)

	-- create freightened on restart timer, it is not a pill
	game.freightened_on_restart_timer = Timer:new(	args.restart_pill_time or
													settings.restart_pill_time)
	game.just_restarted = false -- do not activate it first time

	-- pills
	game.pills = {}
	local n_pills = args.n_pills or settings.n_pills
	for i=1, n_pills, 1 do
		local rand = random.random(1, #game.grid.valid_pos)
		game.pills[i] = Pill:new(rand, settings.pill_time)
	end

	-- ghosts
	game.ghost_state = "scattering"
	-- stack for ghosts to be respawned
	game.to_be_respawned = {}
	-- game.ghosts array
	local n_ghosts = args.n_ghosts or settings.n_ghosts
	game.ghosts = {}
	for i=1, n_ghosts,1 do
		-- find a valid position
		local pos_index = random.random(1, #game.grid.valid_pos)

		local target_offset = random.random(	-settings.ghost_target_spread,
												settings.ghost_target_spread)

		-- build a valid try_order gene
		local try_order = {}
		for i=1, 4, 1 do
			try_order[i] = i
		end
		utils.array_shuffler(try_order)

		-- creates fear genes
		local fear_target = random.random(0, settings.ghost_fear_spread)
		local fear_group = random.random(0, settings.ghost_fear_spread)

		local chase_feared_gene = random.random(1, 9)
		local scatter_feared_gene = random.random(1, 5)

		game.ghosts[i] = Ghost:new(	pos_index,
								target_offset,
								try_order,
								fear_target,
								fear_group,
								chase_feared_gene,
								scatter_feared_gene,
								game.ghost_speed,
								game.pills)
	end

	-- render the game.maze_canvas
	game.maze_canvas = love.graphics.newCanvas(game.default_width, game.default_height)
	love.graphics.setCanvas(game.maze_canvas)
		love.graphics.clear()
		love.graphics.setBlendMode("alpha")
		for i=1, game.grid.grid_width_n do
			for j=1, game.grid.grid_height_n do
				if (game.grid.grid_types[j][i]==16) then
					love.graphics.setColor(0.7, 0.8, 0.8, 1)
					love.graphics.rectangle("fill",
											game.grid_size*(i-1),
											game.grid_size*(j-1),
											game.grid_size,game.grid_size)
				elseif (game.grid.grid_types[j][i]==0) then
						love.graphics.setColor(0.15, 0.25, 0.35, 1)
						love.graphics.rectangle("fill",
												game.grid_size*(i-1),
												game.grid_size*(j-1),
												game.grid_size, game.grid_size)
				else
					love.graphics.setColor(0, 0, 0, 0)
					love.graphics.rectangle("fill",
											game.grid_size*(i-1),
											game.grid_size*(j-1),
											game.grid_size, game.grid_size)
				end
			end
		end
	love.graphics.setCanvas()

	game.ghost_flip_sound = args.ghost_flip_sound or settings.ghost_flip_sound

	-- creates the background particles
	game.n_particles = args.n_particles or settings.n_particles
	game.particles = {}
	for i=1, game.n_particles,1 do
		game.particles[i] = Particle:new()
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function game.draw()
	local active_ghost_counter = 0 -- used on hud

	-- particles
	for i=1,game.n_particles,1 do
		game.particles[i]:draw()
	end

	-- resize screen
	resizer.draw_fix()

	local w = love.graphics.getWidth()
	local h = love.graphics.getHeight()

	-- draw the game.maze_canvas
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.draw(game.maze_canvas)
	love.graphics.setBlendMode("alpha") -- back to normal mode

	--game.pills
	for i=1, #game.pills, 1 do
		game.pills[i]:draw()
	end

	if(game.ghost_state == "chasing") then
		love.graphics.setShader(shaders.red)
	elseif(game.ghost_state == "frightened") then
		love.graphics.setShader(shaders.blue)
	end
	--game.ghosts
	for i=1, #game.ghosts, 1 do
		if (game.ghosts[i].is_active )then
			active_ghost_counter = active_ghost_counter +1
		end
		game.ghosts[i]:draw(game.ghost_state)
	end

	-- draw player
	love.graphics.setShader()
	game.player:draw()

	-- draw bot
	game.AutoPlayerPopulation:draw()

	-- hud

	--reset scale and translate
	love.graphics.origin()
	love.graphics.setFont(game.text_font_small)

	-- love.graphics.setColor(1, 1, 0)
	-- love.graphics.print("capturado: " .. reporter.player_catched, 10, 0)
	-- love.graphics.print("resets: " .. game.resets, w/5, 0)
	-- love.graphics.print("capturados: " .. reporter.ghosts_catched, 2*w/5, 0)
	-- love.graphics.print("ativos: " 	.. active_ghost_counter, 3*w/5, 0)

	if ( not game.player.is_active ) then
		love.graphics.print("'enter' para ir de novo", 3*w/4 -5, 0)
	end

	-- pause screen
	if (game.paused) then
			love.graphics.setColor(0, 0, 0, 0.8)
			--love.graphics.rectangle("fill", w/4 , h/4, w/2, h/2)
			love.graphics.rectangle("fill", 0 , 0, w, h)
			love.graphics.setColor(1, 1, 0)
			love.graphics.printf(	game.pause_text,
									game.text_font,
									w/4, h/4, w/2,
									"center")
	end

	--fps
	love.graphics.setColor(1, 0, 0)
	love.graphics.printf(	love.timer.getFPS(),
	 						0,
							game.default_height - 32,
							game.default_width,
							"right")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function game.update(dt)
	-- dt should not be to high
	if (dt > 0.06 ) then
		print("ops, dt too high, physics wont work, skipping  dt= " .. dt)
	end

	game.grid:clear_grid_collisions()

	local len_respawn =  #game.to_be_respawned
	local len_ghosts = #game.ghosts

	if ( not game.paused and (dt<0.06)) then
		for i=1,game.n_particles,1 do
			game.particles[i]:update(dt)
		end

		-- calculate average_ghost_pos
		local average_ghost_pos = {}
		average_ghost_pos.x = utils.average(game.ghosts, "x")
		average_ghost_pos.y = utils.average(game.ghosts, "y")

		local total_pill_fitness = 0
		local active_pill_count = 0

		-- game.ghost_state controller
		-- game.ghost_state is also modified by the pills update
		if (game.ghost_state_timer:update(dt) == true) then
			if ( game.ghost_state == "scattering") then
			-- if game.ghost_state == "frightened" do nothing
				game.ghost_state = "chasing"
				for i=1, #game.ghosts, 1 do
					game.ghosts[i]:flip_direction()
					game.ghost_flip_sound:play()
				end
				game.ghost_state_timer:reset(settings.ghost_chase_time)
			elseif ( game.ghost_state == "chasing") then
				game.ghost_state = "scattering"
				for i=1, #game.ghosts, 1 do
					game.ghosts[i]:flip_direction()
					game.ghost_flip_sound:play()
				end
			end
		end

		-- freightened_on_restart_timer, it is not a pill
		if	game.just_restarted then
			if game.freightened_on_restart_timer:update(dt) then
				game.ghost_state = "scattering"
				game.ghost_state_timer:reset()
				Pill.pills_active = true
				game.just_restarted = false
			elseif(game.freightened_on_restart_timer.timer < 1)then
				Pill.warn_sound:play()
			end
		end

		local total_fitness = 0
		-- update ghosts
		Ghost.set_state(game.ghost_state)
		local targets = {game.player, unpack(game.AutoPlayerPopulation:get_active_population())}
		for i=1, #game.ghosts, 1 do
			local is_active_before_update = game.ghosts[i].is_active

				game.ghosts[i]:update(
							targets,
							game.pills,
							average_ghost_pos,
							dt)

			total_fitness = total_fitness + game.ghosts[i].fitness

			if (is_active_before_update==true and
				game.ghosts[i].is_active == false)
				then -- foi pego
				-- reporter.report_catch(game.ghosts[i], game.ghosts)

				if ( len_respawn ==0 ) then
					table.insert(game.to_be_respawned, i)
					game.ghost_respawn_timer:reset()
				elseif ( len_respawn < len_ghosts ) then
					table.insert(game.to_be_respawned, i)
				end
			end
		end

		--respawns, it respaws even without player
		if ( game.ghost_respawn_timer:update(dt) )
			then
			if (#game.to_be_respawned > 0) then

				-- and spawns
				local i = table.remove(game.to_be_respawned, 1)
				if ( settings.ghost_genetic_on) then
					game.ghosts[i]:crossover(game.ghosts,
									game.pills)
				else
					-- find spawning position
					local spawn_grid_pos = {}
					if ( game.player.grid_pos.x > (game.grid.grid_width_n/2) ) then
						spawn_grid_pos = {x=7, y= 21}
					else
						spawn_grid_pos = {x=50, y= 21}
					end

					game.ghosts[i]:regen(game.pills, spawn_grid_pos)
				end

			end
		end

		--pill
		for i=1, #game.pills, 1 do
			game.pills[i]:update(game.pills, dt)
			if(game.pills[i].is_active) then
				active_pill_count = active_pill_count + 1
				total_pill_fitness = total_pill_fitness + game.pills[i].fitness
			end
			if (game.got_pill == false) and (game.pills[i].effect == true) then
				game.got_pill = i
				game.ghost_state = "frightened"
				for i=1, #game.ghosts, 1 do
					game.ghosts[i]:flip_direction()
					game.ghost_flip_sound:play()
				end
				Ghost.ghost_speed = game.ghost_speed / 1.5
				game.player.speed = game.speed * 1.1
			elseif (game.got_pill == i) and (game.pills[i].effect == false) then
				game.got_pill = false
				game.ghost_state = "scattering"

				Ghost.ghost_speed = game.ghost_speed
				game.player.speed = game.speed
				game.ghost_state_timer:reset()
			end
		end

		-- player, after game.ghosts to get player_catched
		-- keyboard controls
		if(love.keyboard.isDown("left") and love.keyboard.isDown("right")) then
			--does nothing, but also does not change
		elseif love.keyboard.isDown("left") then
			game.player.next_direction = "left"
		elseif love.keyboard.isDown("right") then
			game.player.next_direction = "right"
		end

		if(love.keyboard.isDown("up") and love.keyboard.isDown("down")) then
			--does nothing, but also does not change
		elseif love.keyboard.isDown("up") then
			game.player.next_direction = "up"
		elseif love.keyboard.isDown("down") then
			game.player.next_direction = "down"
		end
		game.player:update(dt)

		-- bot
		game.AutoPlayerPopulation:update(dt, game.ghost_state)

		-- check victory, should be the last thing done in this function
		local len = #game.to_be_respawned
		if (len == (len_ghosts -1) ) then
			gamestate.switch("victory")
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function game.keypressed(key, scancode, isrepeat)
	if (key == 'space') then
		game.paused = not game.paused
	elseif	(key == "return") then
		if (game.player.is_active == false) then
			game.ghost_state = "frightened"
			game.freightened_on_restart_timer:reset()
			game.just_restarted = true
			Pill.pills_active = false

			game.player:reset(game.grid_pos, game.speed)
		else
			game.paused = not game.paused
		end
	elseif (key == "escape") then
		-- reporter.stop()
		gamestate.switch("menu")
	elseif (key == "m") then
		love.audio.setVolume(0)
	elseif (key == "u") then
		love.audio.setVolume(1)
	end
end

function game.unload()
	game = {}
end

return game
