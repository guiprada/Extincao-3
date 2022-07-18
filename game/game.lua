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
local GeneticPopulation = require "GeneticPopulation"

-----------------------------------------------------------------------functions
local function got_pill_update_callback(value)
	game.got_pill = value
end

local function pill_time_left_update_callback(value)
	game.pill_time_left = value
end

-----------------------------------------------------------------------love callbacks
function game.load(args)
	love.audio.setVolume(0)
	game.default_width = love.graphics.getWidth()
	game.default_height = love.graphics.getHeight()

	game.paused = true
	game.resets = 0
	game.pause_text = args.pause_text or settings.pause_text

	-- pill state
	game.got_pill = false

	-- respawn timer
	-- game.ghost_state timer
	game.ghost_scatter_time = 	args.ghost_scatter_time or
								settings.ghost_scatter_time
	game.ghost_state_timer = Timer:new(game.ghost_scatter_time)


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
	game.ghost_speed_boost = 1.5
	local ghost_target_spread = 15

	-- start subsystems
	Player.init(game.grid, args.player_click or settings.player_click)
	Ghost.init(game.grid, game.grid_size, game.lookahead, game.ghost_speed, "scattering", ghost_target_spread)
	Pill.init(game.grid, args.pill_warn_sound or settings.pill_warn_sound, got_pill_update_callback, pill_time_left_update_callback)
	AutoPlayer.init(game.grid, 5)

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
	game.AutoPlayerPopulation = GeneticPopulation:new(AutoPlayer, 10, 100, nil, {speed = game.speed})

	game.restart_pill_time = args.restart_pill_time or settings.restart_pill_time

	-- pills
	game.pill_time_left = game.restart_pill_time
	game.got_pill = false
	game.pill_is_in_effect = false
	game.pillsPopulation = Population:new(Pill, 6, {pill_time = game.restart_pill_time})

	-- ghosts
	game.ghost_state = "scattering"
	-- game.ghosts array
	local n_ghosts = args.n_ghosts or settings.n_ghosts
	game.ghosts = {}
	for i=1, n_ghosts,1 do
		-- find a valid position
		local pos_index = random.random(1, #game.grid.valid_pos)

		local target_offset = random.random(-settings.ghost_target_spread, settings.ghost_target_spread)

		-- build a valid try_order gene
		local try_order = {}
		for i=1, 4, 1 do
			try_order[i] = i
		end
		utils.array_shuffler(try_order)

		game.ghosts[i] = Ghost:new(	pos_index, target_offset, try_order, game.ghost_speed)
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

	-- max dt, for physics sanity
	game.max_dt = (game.grid_size / 4) / utils.max(game.speed, game.ghost_speed * game.ghost_speed_boost)
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
	game.pillsPopulation:draw()

	if(game.ghost_state == "chasing") then
		love.graphics.setShader(shaders.red)
	elseif(game.ghost_state == "frightened") then
		love.graphics.setShader(shaders.blue)
	end
	--game.ghosts
	for i=1, #game.ghosts, 1 do
		if (game.ghosts[i]._is_active )then
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

	if ( not game.player._is_active ) then
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
	local dt = dt < game.max_dt and dt or game.max_dt
	if (dt > game.max_dt ) then
		print("ops, dt too high, physics wont work, skipping dt= " .. dt)
	end

	game.grid:clear_grid_collisions()


	if ( not game.paused and (dt<0.06)) then
		for i=1,game.n_particles,1 do
			game.particles[i]:update(dt)
		end

		-- calculate average_ghost_pos
		local average_ghost_pos = {}
		average_ghost_pos.x = utils.average(game.ghosts, "x")
		average_ghost_pos.y = utils.average(game.ghosts, "y")

		-- game.ghost_state controller
		-- game.ghost_state is also modified by the pills update
		if (game.ghost_state_timer:update(dt) == true) then
			if (game.ghost_state == "scattering") then
			-- if game.ghost_state == "frightened" do nothing
				game.ghost_state = "chasing"
				for i=1, #game.ghosts, 1 do
					game.ghosts[i]:flip_direction()
					game.ghost_flip_sound:play()
				end
			elseif (game.ghost_state == "chasing") then
				game.ghost_state = "scattering"
				for i=1, #game.ghosts, 1 do
					game.ghosts[i]:flip_direction()
					game.ghost_flip_sound:play()
				end
			end

			game.ghost_state_timer:reset(settings.ghost_chase_time)
			game.ghost_state_timer:start()
		end

		-- update ghosts
		Ghost.set_state(game.ghost_state)
		local targets = {game.player, unpack(game.AutoPlayerPopulation:get_population())}
		for i=1, #game.ghosts, 1 do
			game.ghosts[i]:update(targets, game.pills, average_ghost_pos, dt)
			if not game.ghosts[i]._is_active then
				game.ghosts[i]:crossover(game.ghosts)
			end
		end

		--pill
		game.pillsPopulation:update(dt)

		if (game.got_pill == true) and (game.pill_is_in_effect == false) then
			game.pill_is_in_effect = true
			game.ghost_state = "frightened"
			game.ghost_state_timer:stop()
			Ghost.set_speed(game.ghost_speed * game.ghost_speed_boost )

			for i=1, #game.ghosts, 1 do
				game.ghosts[i]:flip_direction()
				game.ghost_flip_sound:play()
			end
		elseif (game.pill_is_in_effect == true) and (game.got_pill == false) then
			game.pill_is_in_effect = false
			game.ghost_state = "scattering"

			Ghost.set_speed(game.ghost_speed)
			game.ghost_state_timer:reset()
			game.ghost_state_timer:start()
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
		game.AutoPlayerPopulation:update(
			dt,
			game.ghost_state,
			game.ghosts,
			game.pillsPopulation:get_population(),
			game.AutoPlayerPopulation:get_population(),
			game.ghost_state_timer:time_left()/game.ghost_scatter_time,
			game.pill_time_left/game.restart_pill_time)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function game.keypressed(key, scancode, isrepeat)
	if (key == 'space') then
		game.paused = not game.paused
	elseif (key == "return") then
		if (game.player._is_active == false) then
			game.player:reset(game.grid_pos, game.speed)
			if game.paused then
				game.paused = false
			end
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
