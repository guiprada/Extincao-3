-- Guilherme Cunha Prada 2019

local utils = require "utils"
local grid = require "grid"
local ghost = require "ghost"
local player = require "player"
local timer = require "timer"
local pill = require "pill"
local resizer = require "resizer"
--------------------------------------------------------------------------------
-- not quite games, not quite lab
-- to dos

	-- variaveis para o mutation rate

	-- fazer um chasing melhor, que altere o target por contexto, um controlador de grupo
	-- mais perto mira no player, medio na frente e longe atras, teriamos o gene de grupo com
	-- esses valores, oque e longe e oque e perto. talvez possamos usar a distancia do centro do grupo
	-- ai teriamos uma tabela fuzzy

	--controlador de medo usando as informacoes que o algoritmo original usa, para nao desrespeitar
	--o sistema "sensitivo inicial"
	-- posicao e direcao do player, sabe calcular distancias e sua propria direcao e distancia de casa
	-- vamos criar o medo :)
	-- e fazer o spawning na posicao da mae
	-- tempo de respawn deveria ser proporcional a populacao

	-- e se as pilulas se exitnguissem

	-- o pill ghost_selective_migration_on buga pois a home pill pode sumir
	-- criar um teto baseado no pill max fitness, ainda e bugado
	-- fazer o ghost_selective_migration_on baseado em pos_index


	-- o fitness da pilula tem que diminuir com o tempo
	-- o do ghost tambem
	-- e fazer a duracao da pilula de fitness baixo menor?
	-- fazer o ghost nao distanciar de sua home se ela tiver fitness alto?

	-- testes com handicaps diferentes

  	-- detector de emboscada
  	--ver se tem outro tile com mais de uma opcao antes de uma pilula ou do player

-- controlador fuzzy para o  target_offset do fantasma, seria dinamico
	-- entradas player is moving ou speed
	-- distancia do player para a pilula mais proxima
	-- qual fantasma e o mais perto e se sou eu
-- duas sub_especies de fantasma, uma que foge rapido e uma que persegue rapido
-- make target a gene
-- poderimos eveluir uma tabela fuzzy para o fantasma
-- fix crossover selection and turn of elitism
-- automatic grid from map

--

------------------------------------------------------------------------ Configuracao

local target_offset_distribution_file = io.open("target_offset_distribution.run", "w")
local fear_target_file = io.open("fear_target.run", "w")
local fear_group_file = io.open("fear_group.run", "w")
local stats_file = io.open("stats.run", "w")
--local config_file = io.open("config.run")

-- kitten killing globals

local ghost_genetic_on = true  	-- liga e desliga e GA
local ghost_fitness_on = true             	-- desliga a funcao fitness
local ghost_target_offset_freightned_on = true -- liga e desliga e gene target_offset_freightned
local ghost_migration_on = true
local ghost_selective_migration_on = false
local ghost_fear_on = true
local ghost_target_spread = 15
local ghost_fear_spread = 50

local pill_genetic_on = false-- liga e desliga o GA para pilulas
local pill_precise_crossover_on = false	-- controla o forma de crossover dos pilulas

local stats_on = false -- controla a exibicao de informacao do GA na tela
--local reporter_duty_cycle = 20        -- frequecia, em fantasmas nascidos, que o reporter printa uma notificacao no console

local grid_width_n = 56
local grid_height_n = 31

local player_start_grid = {}
player_start_grid.x = 28
player_start_grid.y = 18

local n_ghosts = 30 --at least 3
local n_pills = 6	-- at least 2

local pill_time = 2.7	-- tempo de duracao da pilula
local ghost_chase_time = 15 -- testado 3.99
local ghost_scatter_time = 7.5 --testado com 2
local ghost_respawn_time = 1  --  5 --15--20 testado

local speed_boost_on = false
local ghost_speed_max_factor = 1.5 		-- controla a velocidade maxima do fantasma em proporcao a velocidade inicial do fantasma

local speed = 0 -- will be set in love.load(), needs grid_size being set
local player_speed_grid_size_factor = 6 -- speed = player_speed_grid_size_factor* grid_size
local ghost_speed = 0 -- will be set in love.load(), needs speed being set

print("the Configuration used is:")
print()
print("ghost_genetic_on: " .. tostring(ghost_genetic_on))
print("ghost_fitness_on: " .. tostring(ghost_fitness_on) )
print("ghost_target_offset_freightned_on: " .. tostring(ghost_target_offset_freightned_on))
print("ghost_migration_on: " .. tostring(ghost_migration_on))
print("ghost_selective_migration_on: " .. tostring(ghost_selective_migration_on))
print("ghost_fear_on: " .. tostring(ghost_fear_on))
print("ghost_target_spread: " .. ghost_target_spread)
print()
print("pill_genetic_on: " .. tostring(pill_genetic_on))
print("pill_precise_crossover_on: " .. tostring(pill_precise_crossover_on))
print("speed_boost_on: " .. tostring(speed_boost_on))
print()

print("n_ghosts: " .. n_ghosts)
print("n_pills: " .. n_pills)
print("pill_time: " .. pill_time)
print("ghost_chase_time: " .. ghost_chase_time)
print("ghost_scatter_time: " .. ghost_scatter_time)
print("ghost_respawn_time: " .. ghost_respawn_time)

print()
print("the grid is: " .. grid_width_n .. " x " .. grid_height_n)
print("player's start grid is: " .. player_start_grid.x .. ", " .. player_start_grid.y)
print("stats_on: " .. tostring(stats_on) )
--print("reporter_duty_cycle: " .. reporter_duty_cycle )
print("ghost_speed_max_factor: " .. ghost_speed_max_factor )
print("player_speed_grid_size_factor: " .. player_speed_grid_size_factor )

--------------------------------------------------------------------------------

local grid_size = 0 -- will be set by resizer
local lookahead = 0 -- will be set after grid_size
local font_size = 0 -- will be set after grid_size


-- tables para os objetos de jogo
local come_come = {}
local ghosts = {} -- e um array
local pills = {} -- e um array
local freightened_on_restart_timer = {}
local just_restarted = false

-- gamestate
local has_shown_menu = false
local ghost_state = "scattering" -- controla o estado dos fantasmas
local game_on = true -- e falsa caso o jogador tenha vencido :)
local paused = true  -- para pausar e despausar
local restarts = 0 -- contador de reinicios
local resets = 0 -- contador de resets
local ghosts_catched = 0 -- contador de comidos
local to_be_respawned = {} -- fila para armazenar os indices dos objetos a serem reiniciados


local ghost_state_timer = timer.new(ghost_scatter_time) -- timer para alternar o ghost_state
local ghost_respawn_timer = timer.new(ghost_respawn_time) --39-- timer para reativar um fantasma

-- canvas para o maze
local maze = {}

local pause_text = 	"Jogo da extinção\n\n"
					.."Não deixe o monstro te pegar :) \n"
					.. "Voce precisa comer uma  pilula verde para poder vencelos.\n"
					.. "O objetivo do jogo é levar os montros a extinção, "
					.. "deixando    ao    maximo    um    exemplar   solto.\n"
					.. "Alguns monstros escapam com o tempo.\n"
					.. "\nComandos\n"
					.. "'r' para tentar de novo \n"
					.. "'q' para sair\n"
					.. "'p' para pausar/despausar\n"

local active_ghost_counter = 0
-- local reporter_counter = 0

local player_catched_counter = 0

local last_catched_target_offset = 0
last_catcher_target_offset = 0 -- tem que ser global pois é setada por ghost.update()

local distrib_catched_target_offset = {}
local distrib_catcher_target_offset = {}
for i=-ghost_target_spread, ghost_target_spread, 1 do
	distrib_catched_target_offset[i] = 0
	distrib_catcher_target_offset[i] = 0
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function reporter()
	--reporter_counter = reporter_counter + 1

	io.output(stats_file)
	io.write(	"ghosts catched: " .. ghosts_catched .. "  <>  " ..
			"last_catched_target_offset: " .. last_catched_target_offset .. "  <>  " ..
			"player_catched_counter: " .. player_catched_counter .. "  <>  " ..
			"av ghost fitness: " .. utils.round_2_dec(utils.average( ghosts, "fitness") ) .. "  <>  " ..
			"std_dev ghost fitness: " .. utils.round_2_dec( utils.std_deviation(ghosts, "fitness") ).. "  <> " ..
			"max ghost fitness: " .. utils.round_2_dec( utils.get_highest(ghosts, "fitness").fitness ).. "  <>  " ..
			"max ghost fitness's target: " .. utils.get_highest(ghosts, "fitness").target_offset  .. "  <>  " ..
			"av target_offset: " .. utils.round_2_dec( utils.average(ghosts, "target_offset") ) .. "  <>  " ..
			"std_dev target_offset: " .. utils.round_2_dec( utils.std_deviation(ghosts, "target_offset") ).. " <>  " ..
			"av target_offset_freightned: " .. utils.round_2_dec( utils.average(ghosts, "target_offset_freightned") ) .. "  <>  " ..
			"std_dev target_offset_freightned: " .. utils.round_2_dec( utils.std_deviation(ghosts, "target_offset_freightned") ).. "  <>  " ..
			"average age: " .. utils.round_2_dec( utils.average(ghosts, "n_updates") ).. " <> " ..
			"std_dev age: " .. utils.round_2_dec( utils.std_deviation( ghosts, "n_updates" ) ) .. " <> " ..
			"av-pill-fitness: " .. utils.round_2_dec( utils.average(pills, "fitness") ) .. "\n"	)

--------------------------------------------------------------------------------
	local distrib_target_offset = {}
	for i=-ghost_target_spread, ghost_target_spread, 1 do
		distrib_target_offset[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then -- para criar novos valores
			if ( distrib_target_offset[ ghosts[i].target_offset ] ~= nil ) then
				distrib_target_offset[ ghosts[i].target_offset ] = distrib_target_offset[ ghosts[i].target_offset ] + 1
			else
				distrib_target_offset[ ghosts[i].target_offset ] = 1
			end
		end
	end

	io.output(target_offset_distribution_file)
	--print("population's target distribution")
	for i=-ghost_target_spread, ghost_target_spread, 1 do
		if ( distrib_target_offset[i] == 0 ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_target_offset[i] .. " ")
		end
	end
	io.write("\n")
	--print()

--------------------------------------------------------------------------------

	local distrib_fear_group = {}
	for i=1, ghost_fear_spread, 1 do
		distrib_fear_group[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then -- para criar novos valores
			if ( distrib_fear_group[ ghosts[i].fear_group ] ~= nil ) then
				distrib_fear_group[ ghosts[i].fear_group ] = distrib_fear_group[ ghosts[i].fear_group ] + 1
			else
				distrib_fear_group[ ghosts[i].fear_group ] = 1
			end
		end
	end

	io.output(fear_group_file)
	--print("population's target distribution")
	for i=1, #distrib_fear_group, 1 do
		if ( distrib_fear_group[i] == 0 or distrib_fear_group[i] == nil ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_fear_group[i] .. " ")
		end
	end
	io.write("\n")
	--print()

--------------------------------------------------------------------------------

	local distrib_fear_target = {}
	for i=1, ghost_fear_spread, 1 do
		distrib_fear_target[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then -- para criar novos valores
			if ( distrib_fear_target[ ghosts[i].fear_target ] ~= nil ) then
				distrib_fear_target[ ghosts[i].fear_target ] = distrib_fear_target[ ghosts[i].fear_target ] + 1
			else
				distrib_fear_target[ ghosts[i].fear_target ] = 1
			end
		end
	end

	io.output(fear_target_file)
	--print("population's target distribution")
	for i=1, #distrib_fear_target, 1 do
		if ( distrib_fear_target[i] == 0 or distrib_fear_target[i] == nil ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_fear_target[i] .. " ")
		end
	end
	io.write("\n")
	--print()

end

function generate_rand_actions( start, stop)
	local m = {}
	for a=1,2,1 do
		m[a]={}
		for b=1,2,1 do
			m[a][b]={}
			for c=1,2,1 do
				m[a][b][c]={}
				for d=1,2,1 do
					m[a][b][c][d] = love.math.random(start, stop)
				end
			end
		end
	end
	return m
end

--------------------------------------------------------------------------------

local red_shader = love.graphics.newShader[[
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
		vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
		vec4 redish = vec4(1, 0.1, 0.1, 0.7);
		return pixel * redish;
	}
]]

local blue_shader = love.graphics.newShader[[
	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
		vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
		vec4 blueish = vec4(0, 0, 1, 0.5);
		return pixel * blueish;
	}
]]

function love.load()
	love.window.setMode(0, 0, {resizable=true, vsync=true})

	local default_width = love.graphics.getWidth()-- atualiza
	local default_height = love.graphics.getHeight() -- atualiza

	grid_size = resizer.init_resizer(default_width, default_height, grid_width_n, grid_height_n)
	print("grid_size is: " .. grid_size)
	lookahead = grid_size/2

	speed = (player_speed_grid_size_factor*grid_size)
	ghost_speed = speed*1

	print("player's speed: " .. speed)
	print("ghost_speed: " .. ghost_speed)
	print("grid_size is: " .. grid_size)
	print()

	grid.init(grid_width_n, grid_height_n, grid_size, lookahead)
	player.init(grid_size, lookahead)
	ghost.init(ghost_fitness_on, ghost_target_offset_freightned_on, ghost_migration_on, ghost_selective_migration_on, ghost_speed, speed_boost_on, ghost_speed_max_factor, ghost_fear_on, grid_size, lookahead)
	pill.init(pill_genetic_on, pill_precise_crossover_on, grid_size, lookahead)

	-- registrando uma fonte
	font_size = grid_size
	local font = love.graphics.newFont(font_size)
	love.graphics.setFont(font)

	--print("graphics is on, starting the game")

	--inicia player
	local grid_pos = {}
	grid_pos.x =  player_start_grid.x
	grid_pos.y =  player_start_grid.y

    come_come = player.new(grid_pos, speed)
	--assert(come_come, "no player created")
	--print("you are up...")
	-- timer  de estado freightened no restart
	freightened_on_restart_timer = timer.new(pill_time)

	-- pilulas
	for i=1, n_pills, 1 do
		local rand = love.math.random(1, #grid.grid_valid_pos)
		pills[i] = pill.new(rand, pill_time)
	end
	--print("adding some pills and")

	for i=1,n_ghosts,1 do
		-- encontra posicao valida, gene pos_index
		local pos_index = love.math.random(1, #grid.grid_valid_pos)

		local pilgrin_gene
		if ( love.math.random(0, 1) == 1) then
			pilgrin_gene = true
		else
			pilgrin_gene = false
		end

		local target_offset = love.math.random(-ghost_target_spread, ghost_target_spread)
		local target_offset_freightned = love.math.random(-ghost_target_spread, ghost_target_spread)
		-- faz um gene try_order valido
		local try_order = {}
		for i=1, 4, 1 do
			try_order[i] = i
		end
		utils.array_shuffler(try_order)

		local fear_target = love.math.random(0, ghost_fear_spread)
		local fear_group = love.math.random(0, ghost_fear_spread)

	    ghosts[i] = ghost.new(pos_index, pilgrin_gene, target_offset, target_offset_freightned, try_order, fear_target, fear_group, ghost_speed, pills)
	end
	--print("some ghosts for you to catch :)")
    -- cria o canvas para o maze
	maze = love.graphics.newCanvas(default_width, default_height)
	love.graphics.setCanvas(maze)
		love.graphics.clear()
		love.graphics.setBlendMode("alpha")
		for i=1,grid_width_n do
			for j=1,grid_height_n do
				if (grid.grid_types[j][i]==16) then
					love.graphics.setColor(0.7, 0.8, 0.8, 1)
					love.graphics.rectangle("fill", grid_size*(i-1), grid_size*(j-1), grid_size, grid_size)
				elseif (grid.grid_types[j][i]==0) then
						love.graphics.setColor(0.15, 0.25, 0.35, 1)
						love.graphics.rectangle("fill", grid_size*(i-1), grid_size*(j-1), grid_size, grid_size)
				else
					love.graphics.setColor(0, 0, 0, 1)
					love.graphics.rectangle("fill", grid_size*(i-1), grid_size*(j-1), grid_size, grid_size)
				end
			end
		end
	love.graphics.setCanvas()
	--print("and finally a stage, game_on, good luck ;)")

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function love.draw()
	total_target = 0
	active_ghost_counter = 0 -- usado no hud

	resizer.draw_fix()

	local w = love.graphics.getWidth()-- atualiza
	local h = love.graphics.getHeight() -- atualiza

	-- maze canvas
	love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
	love.graphics.draw(maze)
	love.graphics.setBlendMode("alpha") -- volta ao modo normal



	if( game_on ) then
		--pills
		for i=1, #pills, 1 do
			pill.draw(pills[i])
		end

		if(ghost_state == "chasing") then
			love.graphics.setShader(red_shader)
		elseif(ghost_state == "freightened") then
			love.graphics.setShader(blue_shader)
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
	else -- tela de vitoria
		-- reseta scale and translate
		love.graphics.origin()
		--love.graphics.setShader()
		love.graphics.setColor(1, 1, 1)
		love.graphics.print( "extintos! 'r' para reiniciar", 4*w/5 -50, -3)
		-- e volta
		resizer.draw_fix()
	end

	-- jogador
	love.graphics.setShader()
	player.draw(come_come, grid_size)

	-- hud
	-- reseta scale and translate
	love.graphics.origin()

	love.graphics.setColor(1, 0, 0)
	love.graphics.print( "reinicios: " .. restarts, 10,  font_size - 22)
	love.graphics.print( "resets: " .. resets, w/5,  font_size -22)
	love.graphics.print( "capturados: " .. ghosts_catched, 2*w/5,  font_size - 22)
	love.graphics.print( "ativos: " .. active_ghost_counter, 3*w/5,  font_size -22)

	if (stats_on) then
		--love.graphics.setColor(1, 0, 0)
		love.graphics.print(tostring(love.timer.getFPS( )), 5, h -3*font_size -10)
		love.graphics.print("av-ghost-fit: " .. utils.round_2_dec(utils.average( ghosts, "fitness")), 10, h -font_size -10)
		local best_specime = utils.get_highest(ghosts, "fitness")
		love.graphics.print("max-fit: " .. utils.round_2_dec(best_specime.fitness), w/4, h -font_size -10)
		love.graphics.print("av-target_offset: " .. utils.round_2_dec(total_target/active_ghost_counter), 2*w/4, h -font_size -10)
		love.graphics.print("av-pill-fit: " .. utils.round_2_dec( utils.average(pills, "fitness")), 3*w/4, h -font_size -10)
	end
	if ( not come_come.is_active ) then
		love.graphics.print( "'r' para ir de novo", 3*w/4 -5, font_size - 22)
	end

	-- tela de pause
	if (paused) then
		if (has_shown_menu==false) then
			love.graphics.setColor(0, 0, 0, 0.8)
			love.graphics.rectangle("fill", w/4 , h/4, w/2, h/2)
			love.graphics.setColor(1, 1, 0)
			love.graphics.printf(pause_text, w/4, h/4, w/2,"center")
		else
			love.graphics.setColor(0, 0, 0, 0.1)
			love.graphics.rectangle("fill", 0, 0, w, h)
		end
	end

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function love.update(dt)
	--if (dt > 0.06 ) then print("ops, dt too high, physics wont work  dt= " .. dt) end

	if ( not paused and (dt<0.06)) then --  dt tem que ser baixo para nao bugar a fisica
		-- calcula posicao media dos fantasmas
		local average_ghost_pos = {}
		average_ghost_pos.x = utils.average(ghosts, "x")
		average_ghost_pos.y = utils.average(ghosts, "y")

		-- local total_dist_to_group = 0
		local total_pill_fitness = 0
		local active_pill_count = 0
		local player_active_before_update = come_come.is_active -- tem que ser antes do update dos ghosts
		--print("in" .. tostring(come_come.is_active) )

		-- controlador do ghost_state
		-- o pill update  tbem faz modificoes no ghost_state
		if ( timer.update(ghost_state_timer, dt)== true) then
			--state_change_timer = state_change_reset_time
			if ( ghost_state == "scattering") then -- nao faz nada caso ghost_state == "freightened"
				ghost_state = "chasing"
				timer.reset(ghost_state_timer, ghost_chase_time)
			elseif ( ghost_state == "chasing") then
				ghost_state = "scattering"
			end
		end


		for i=1, #pills, 1 do
			local is_active_before_update = pills[i].is_active
			pill.update(pills[i], pills, come_come, dt, pill_time)
			if(pills[i].is_active) then
				active_pill_count = active_pill_count + 1
				total_pill_fitness = total_pill_fitness + pills[i].fitness
			end
			if (is_active_before_update == true and
					pills[i].is_active == false ) then
				ghost_state =  "freightened"
				come_come.speed = ghost_speed
			elseif (is_active_before_update== false and
					pills[i].is_active == true ) then
				ghost_state = "scattering"
				come_come.speed = speed
				timer.reset(ghost_state_timer)
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

		if (game_on) then
			local total_fitness = 0
			local active_ghost_counter = 0

			for i=1, #ghosts, 1 do
				local is_active_before_update = ghosts[i].is_active

				ghost.update(ghosts[i], ghosts, come_come, pills, average_ghost_pos, dt, ghost_state, grid_size, lookahead)
				total_fitness = total_fitness + ghosts[i].fitness
				-- total_dist_to_group = total_dist_to_group + ghosts[i].dist_to_group

				if(ghosts[i].is_active) then
					active_ghost_counter = active_ghost_counter +1
				end
				--

				if ( is_active_before_update==true and
						ghosts[i].is_active == false) then -- foi pego
					ghosts_catched = ghosts_catched + 1
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

					last_catched_target_offset = ghosts[i].target_offset
					if(	distrib_catched_target_offset[ ghosts[i].target_offset ] ) then
						distrib_catched_target_offset[ ghosts[i].target_offset ] = distrib_catched_target_offset[ ghosts[i].target_offset ] + 1
					else
						distrib_catched_target_offset[ ghosts[i].target_offset ] = 1
					end
					reporter()
				end
			end

			-- if (active_ghost_counter ~=0) then
			-- 	average_ghost_fitness = total_fitness/ active_ghost_counter
			-- 	average_dist_group = total_dist_to_group/ active_ghost_counter
			-- end

			--respawns
			if ( game_on and timer.update(ghost_respawn_timer,dt) and ghost_state == "freightened") then -- continua respawnando mesma sem player
				if (#to_be_respawned > 0) then
					--print("respawned")

					-- encontra posicao de spawn
					-- local spawn_grid_pos = {}
					-- if ( come_come.grid_pos.x > (grid_width_n/2) ) then
					-- 	spawn_grid_pos = {x=7, y= 21}
					-- else
					-- 	spawn_grid_pos = {x=50, y= 21}
					-- end

					-- e spawna
					local i = table.remove(to_be_respawned, 1)
					if ( ghost_genetic_on) then
						ghost.crossover(ghosts[i], ghosts, pills)--, spawn_grid_pos)
					else
						ghost.reactivate(ghosts[i], pills)
					end

				end
			end
		end

		-- player, depois de ghosts, para pegar a mudanca de estado( player catched)

		player.update(come_come, dt)
		if ( player_active_before_update == true and come_come.is_active == false ) then -- player killed
			player_catched_counter = player_catched_counter + 1
			if (distrib_catcher_target_offset[ last_catcher_target_offset ])then
				distrib_catcher_target_offset[ last_catcher_target_offset ] = distrib_catcher_target_offset[ last_catcher_target_offset] + 1
			else
				distrib_catcher_target_offset[ last_catcher_target_offset ] = 1
			end
		end

	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function love.keypressed(key, scancode, isrepeat)
   	if (key == 'p') then
		has_shown_menu = true
	   	if (paused) then paused = false
	   	else paused = true end

	elseif (key == "r" and come_come.is_active==false and (not paused)) then
		--print("restarting")
		restarts = restarts + 1
		ghost_state = "freightened"

		timer.reset(freightened_on_restart_timer)
		just_restarted = true
		pill.pills_active = false
		local grid_pos = {x=player_start_grid.x, y=player_start_grid.y}
		player.reset( come_come, grid_pos, speed, grid_size, lookahead)

	elseif (key == "r" and game_on==false and (not paused)) then
		--print("reset")
		resets = resets + 1
		--if ( not game_on ) then
			for i=1, #ghosts, 1 do
				ghosts[i].is_active = true
				if ( ghost_genetic_on) then
					ghost.crossover(ghosts[i], ghosts, pills)
				else
					ghost.reactivate(ghosts[i], pills)
				end
			end
			to_be_respawned = {}
		--end
		game_on = true

		ghost_state = "scattering"
		timer.reset(ghost_state_timer)

   	elseif (key == "q") then

		print("\ncatched")
		for i=-ghost_target_spread, ghost_target_spread, 1 do
			print("distrib_catched_target_offset[" .. i .. "]: " .. distrib_catched_target_offset[i])
		end

		print("\ncatcher")
		for i=-ghost_target_spread, ghost_target_spread, 1 do
			print("distrib_catcher_target_offset[" .. i .. "]: " .. distrib_catcher_target_offset[i])
		end

		-------------

		io.close(target_offset_distribution_file)
		io.close(fear_target_file)
		io.close(fear_group_file)
		io.close(stats_file)
	   	love.event.quit(0)
   	end
end
