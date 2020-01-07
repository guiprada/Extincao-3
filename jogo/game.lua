-- Guilherme Cunha Prada 2020
--------------------------------------------------------------------------------
-- not quite game, not quite lab
-- kitten killing globals
local game = {}

--print("ow yeah")
local gamestate = require "gamestate"
local utils = require "utils"
local grid = require "grid"
local ghost = require "ghost"
local player = require "player"
local timer = require "timer"
local pill = require "pill"
local resizer = require "resizer"
local settings = require "settings"
local reporter = require "reporter"
local shaders = require "shaders"

--------------------------------------------------------------------------------

local text_font = love.graphics.newFont("fonts/PressStart2P-Regular.ttf", 35)

local grid_size = 0 -- will be set by resizer
local lookahead = 0 -- will be set after grid_size
local font_size = 0 -- will be set after grid_size

-- tables para os objetos de jogo
local come_come = {}
local ghosts = {} -- e um array
local pills = {} -- e um array
local freightened_on_restart_timer = {}
local just_restarted = false

local ghost_speed = 0 -- will be set in love.load(), needs speed being set
local speed = 0 -- will be set in love.load(), needs grid_size being set

-- gamestate
local ghost_state = "scattering" -- controla o estado dos fantasmas
local paused = true  -- para pausar e despausar

local resets = 0 -- contador de resets

local to_be_respawned = {} -- fila para armazenar os indices dos objetos a serem reiniciados

local ghost_state_timer = timer.new(settings.ghost_scatter_time) -- timer para alternar o ghost_state
local ghost_respawn_timer = timer.new(settings.ghost_respawn_time) --39-- timer para reativar um fantasma

-- para o maze_canvas
local maze_canvas = {}

-- para o som do troca de estados do fantasma
local flip_sound = true

local pause_text = 	"\n\n'enter' para tentar de novo \n\n"
					.. "'esc' para sair\n\n"
					.. "'spaco' para pausar\n\n"

local active_ghost_counter = 0

--------------------------------------------------------------------------------

function game.load()
	love.window.setMode(settings.screen_width or 0,
						settings.screen_height or 0,
						{fullscreen=true, resizable=false, vsync=true})

	local default_width = love.graphics.getWidth()-- atualiza
	local default_height = love.graphics.getHeight() -- atualiza

	grid_size = resizer.init_resizer(default_width, default_height, settings.grid_width_n, settings.grid_height_n)
	lookahead = grid_size/2

	speed = (settings.player_speed_grid_size_factor*grid_size)
	ghost_speed = speed*1

	-- print("player's speed: " .. speed)
	-- print("ghost_speed: " .. ghost_speed)
	-- print("grid_size is: " .. grid_size)

	reporter.init()
	grid.init(	settings.grid_width_n,
				settings.grid_height_n,
				grid_size, lookahead)
	player.init(grid_size, lookahead)
	ghost.init(	settings.ghost_fitness_on,
				settings.ghost_target_spread,
				settings.ghost_target_offset_freightned_on,
				settings.ghost_migration_on,
				settings.ghost_selective_migration_on,
				ghost_speed,
				settings.speed_boost_on,
				settings.ghost_speed_max_factor,
				settings.ghost_fear_on,
				settings.ghost_go_home_on_scatter,
				settings.ghost_chase_feared_gene_on,
				settings.ghost_scatter_feared_gene_on,
				grid_size,
				lookahead,
				reporter)
	pill.init(	settings.pill_genetic_on,
				settings.pill_precise_crossover_on,
				grid_size,
				lookahead)

	-- registrando uma fonte
	font_size = grid_size
	local font = love.graphics.newFont(font_size)
	love.graphics.setFont(font)

	--inicia player
	local grid_pos = {}
	grid_pos.x =  settings.player_start_grid.x
	grid_pos.y =  settings.player_start_grid.y

    come_come = player.new(grid_pos, speed)
	--print("you are up...")
	-- timer  de estado freightened no restart
	freightened_on_restart_timer = timer.new(settings.restart_pill_time)

	-- pilulas
	for i=1, settings.n_pills, 1 do
		local rand = love.math.random(1, #grid.grid_valid_pos)
		pills[i] = pill.new(rand, settings.pill_time)
	end
	--print("adding some pills and")

	for i=1, settings.n_ghosts,1 do
		-- encontra posicao valida, gene pos_index
		local pos_index = love.math.random(1, #grid.grid_valid_pos)

		local pilgrin_gene
		if ( love.math.random(0, 1) == 1) then
			pilgrin_gene = true
		else
			pilgrin_gene = false
		end

		local target_offset = love.math.random(	-settings.ghost_target_spread,
												settings.ghost_target_spread)
		local target_offset_freightned = love.math.random(
												-settings.ghost_target_spread,
												settings.ghost_target_spread)
		-- faz um gene try_order valido
		local try_order = {}
		for i=1, 4, 1 do
			try_order[i] = i
		end
		utils.array_shuffler(try_order)

		local fear_target = love.math.random(0, settings.ghost_fear_spread)
		local fear_group = love.math.random(0, settings.ghost_fear_spread)

		local chase_feared_gene = love.math.random(1, 9)
		local scatter_feared_gene = love.math.random(1, 5)

	    ghosts[i] = ghost.new(	pos_index,
								pilgrin_gene,
								target_offset,
								target_offset_freightned,
								try_order,
								fear_target,
								fear_group,
								chase_feared_gene,
								scatter_feared_gene,
								ghost_speed,
								pills)
	end
	--print("some ghosts for you to catch :)")
    -- cria o canvas para o maze_canvas
	maze_canvas = love.graphics.newCanvas(default_width, default_height)
	love.graphics.setCanvas(maze_canvas)
		love.graphics.clear()
		love.graphics.setBlendMode("alpha")
		for i=1, settings.grid_width_n do
			for j=1,settings.grid_height_n do
				if (grid.grid_types[j][i]==16) then
					love.graphics.setColor(0.7, 0.8, 0.8, 1)
					love.graphics.rectangle("fill",
											grid_size*(i-1),
											grid_size*(j-1),
											grid_size,grid_size)
				elseif (grid.grid_types[j][i]==0) then
						love.graphics.setColor(0.15, 0.25, 0.35, 1)
						love.graphics.rectangle("fill",
												grid_size*(i-1),
												grid_size*(j-1),
												grid_size, grid_size)
				else
					love.graphics.setColor(0, 0, 0, 1)
					love.graphics.rectangle("fill",
											grid_size*(i-1),
											grid_size*(j-1),
											grid_size, grid_size)
				end
			end
		end
	love.graphics.setCanvas()

	flip_sound = love.audio.newSource("tic.wav", "static")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function game.draw()
	total_target = 0
	active_ghost_counter = 0 -- usado no hud

	resizer.draw_fix()

	local w = love.graphics.getWidth()-- atualiza
	local h = love.graphics.getHeight() -- atualiza

	-- maze_canvas
	love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.draw(maze_canvas)
	love.graphics.setBlendMode("alpha") -- volta ao modo normal



	--pills
	for i=1, #pills, 1 do
		pill.draw(pills[i])
	end

	if(ghost_state == "chasing") then
		love.graphics.setShader(shaders.red)
	elseif(ghost_state == "freightened") then
		love.graphics.setShader(shaders.blue)
	end
	--ghosts
	for i=1, #ghosts, 1 do
		--print(ghosts[i].n_updates)

		if (ghosts[i].is_active )then
			active_ghost_counter = active_ghost_counter +1
			total_target = total_target + ghosts[i].target_offset
		end
		ghost.draw(ghosts[i], ghost_state)
		--print(ghosts[i].fitness)
	end

	-- jogador
	love.graphics.setShader()
	player.draw(come_come, grid_size)

	-- hud
	-- reseta scale and translate
	love.graphics.origin()

	love.graphics.setColor(1, 0, 0)
	love.graphics.print("capturado: " .. reporter.player_catched, 10,
						font_size - 22)
	love.graphics.print("resets: " .. resets, w/5,  font_size -22)
	love.graphics.print("capturados: " .. reporter.ghosts_catched, 2*w/5,
						font_size - 22)
	love.graphics.print("ativos: " .. active_ghost_counter, 3*w/5,  font_size -22)

	love.graphics.print(tostring(love.timer.getFPS( )), 5, h -3*font_size -10)

	if ( not come_come.is_active ) then
		love.graphics.print( "'r' para ir de novo", 3*w/4 -5, font_size - 22)
	end

	-- tela de pause
	if (paused) then
			love.graphics.setColor(0, 0, 0, 0.8)
			love.graphics.rectangle("fill", w/4 , h/4, w/2, h/2)
			love.graphics.setColor(1, 1, 0)
			love.graphics.printf(pause_text, text_font, w/4, h/4, w/2,"center")

			-- love.graphics.setColor(0, 0, 0, 0.1)
			-- love.graphics.rectangle("fill", 0, 0, w, h)
			--
	end

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function game.update(dt)
	--if (dt > 0.06 ) then print("ops, dt too high, physics wont work  dt= " .. dt) end

	if ( not paused and (dt<0.06)) then --  dt tem que ser baixo para nao bugar a fisica
		-- calcula posicao media dos fantasmas
		local average_ghost_pos = {}
		average_ghost_pos.x = utils.average(ghosts, "x")
		average_ghost_pos.y = utils.average(ghosts, "y")

		-- local total_dist_to_group = 0
		local total_pill_fitness = 0
		local active_pill_count = 0

		-- controlador do ghost_state
		-- o pill update  tbem faz modificoes no ghost_state
		if ( timer.update(ghost_state_timer, dt)== true) then
			--state_change_timer = state_change_reset_time
			if ( ghost_state == "scattering") then -- nao faz nada caso ghost_state == "freightened"
				ghost_state = "chasing"
				for i=1, #ghosts, 1 do
					ghost.flip_direction(ghosts[i])
					flip_sound:play()
				end
				timer.reset(ghost_state_timer, settings.ghost_chase_time)
			elseif ( ghost_state == "chasing") then
				ghost_state = "scattering"
				for i=1, #ghosts, 1 do
					ghost.flip_direction(ghosts[i])
					flip_sound:play()
				end
			end
		end

		-- if(active_pill_count > 0) then
		-- 	average_pill_fitness = total_pill_fitness/active_pill_count
		-- end

		-- pilula de reset
		if(timer.update(freightened_on_restart_timer, dt) and just_restarted) then
			ghost_state = "scattering"
			--come_come.speed = speed
			timer.reset(ghost_state_timer)
			pill.pills_active = true
			just_restarted = false
		end

		reporter.global_frame_counter = reporter.global_frame_counter + 1
		local total_fitness = 0
		local active_ghost_counter = 0

		for i=1, #ghosts, 1 do
			local is_active_before_update = ghosts[i].is_active

			ghost.update(ghosts[i], come_come, pills, average_ghost_pos, dt, ghost_state, grid_size, lookahead)
			total_fitness = total_fitness + ghosts[i].fitness
			-- total_dist_to_group = total_dist_to_group + ghosts[i].dist_to_group

			if(ghosts[i].is_active) then
				active_ghost_counter = active_ghost_counter +1
			end
			--

			if ( is_active_before_update==true and
					ghosts[i].is_active == false) then -- foi pego

				reporter.report_catch(ghosts[i], ghosts)

				local len_respawn =  #to_be_respawned
				local len_ghosts = #ghosts
				if ( len_respawn ==0 ) then
					table.insert(to_be_respawned, i)
					timer.reset(ghost_respawn_timer)
				elseif ( len_respawn < len_ghosts ) then
					table.insert(to_be_respawned, i)
				end

				len = #to_be_respawned
				if ( len == (len_ghosts -1) ) then
					print("You win!")
					for i=1, #ghosts, 1 do
						ghosts[i].is_active = false
					end
					game_on = false
				end
			end
		end

		--respawns
		if ( timer.update(ghost_respawn_timer,dt) )then --and ghost_state == "freightened") then -- continua respawnando mesma sem player
			if (#to_be_respawned > 0) then
				--print("respawned")

				-- e spawna
				local i = table.remove(to_be_respawned, 1)
				if ( ghost_genetic_on) then
					ghost.crossover(ghosts[i], ghosts, pills)--, spawn_grid_pos)
				else
					-- encontra posicao de spawn
					local spawn_grid_pos = {}
					if ( come_come.grid_pos.x > (settings.grid_width_n/2) ) then
						spawn_grid_pos = {x=7, y= 21}
					else
						spawn_grid_pos = {x=50, y= 21}
					end

					ghost.regen(ghosts[i], pills, spawn_grid_pos)
				end

			end
		end

		--pilulas

		for i=1, #pills, 1 do
			local is_active_before_update = pills[i].is_active
			pill.update(pills[i], pills, come_come, dt, settings.pill_time)
			if(pills[i].is_active) then
				active_pill_count = active_pill_count + 1
				total_pill_fitness = total_pill_fitness + pills[i].fitness
			end
			if (is_active_before_update == true and
					pills[i].is_active == false ) then
				ghost_state =  "freightened"
				for i=1, #ghosts, 1 do
					ghost.flip_direction(ghosts[i])
					flip_sound:play()
				end
				ghost.ghost_speed = ghost_speed / 1.5
				come_come.speed = speed * 1.1
			elseif (is_active_before_update== false and
					pills[i].is_active == true ) then
				ghost_state = "scattering"

				ghost.ghost_speed = ghost_speed
				come_come.speed = speed
				timer.reset(ghost_state_timer)
			end
		end

		-- player, depois de ghosts, para pegar a mudanca de estado( player catched)
		player.update(come_come, dt)

	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function game.keypressed(key, scancode, isrepeat)
   	if (key == 'space') then
		has_shown_menu = true
	   	if (paused) then paused = false
	   	else paused = true end
	elseif (key == "return" and come_come.is_active==false and (not paused)) then
		ghost_state = "freightened"

		timer.reset(freightened_on_restart_timer)
		just_restarted = true
		pill.pills_active = false
		local grid_pos = {x=settings.player_start_grid.x, y=settings.player_start_grid.y}
		player.reset( come_come, grid_pos, speed, grid_size, lookahead)
   	elseif (key == "escape") then
		reporter.stop()
		-------------
		gamestate.switch("menu")
	   	--love.event.quit(0)
   	end
end

return  game
