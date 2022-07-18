-- Guilherme Cunha Prada 2022
local GridActor = require "GridActor"
local AutoPlayer = GridActor:new()
AutoPlayer.__index = AutoPlayer

local ANN = require "ANN"
local utils = require "utils"

local autoplayer_type_name = "player"

function AutoPlayer.init(grid, search_path_length)
	GridActor.init(grid)

	AutoPlayer._search_path_length = search_path_length
	AutoPlayer._max_grid_distance = math.ceil(math.sqrt((grid.grid_width_n ^ 2) + (grid.grid_height_n ^ 2)))
	AutoPlayer._hunger_limit = 144 * 60 * 1

	GridActor.register_type(autoplayer_type_name)
end

function AutoPlayer:new(o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)

	o._type = GridActor.get_type_by_name(autoplayer_type_name)
	self._target_grid = {}
	self._home_grid = {}

	return o
end

function AutoPlayer:reset(reset_table)
	local grid_pos = reset_table.grid_pos
	local speed = reset_table.speed
	local ann = reset_table.ann


	grid_pos = grid_pos or AutoPlayer.grid:get_valid_pos()
	GridActor.reset(self, grid_pos, speed)

	self._fitness = 0
	self._hunger = 0

	local target_grid = AutoPlayer.grid:get_valid_pos()
	self._home_grid.x = target_grid.x
	self._home_grid.y = target_grid.y

	self._target_grid.x = target_grid.x
	self._target_grid.y = target_grid.y


	self._ann = ann or ANN:new(7, 4, 3, 4)
end

function AutoPlayer:crossover(mom, dad, reset_table)
	local newAnn = ANN:crossover(mom._ann, dad._ann)
	-- reset
	self:reset({speed = reset_table.speed, ann = newAnn})
end

function AutoPlayer:draw()
	--AutoPlayer body :)
	if (self._is_active) then
		love.graphics.setColor(0.9, 0.9, 0.9)
		love.graphics.circle(	"fill",
								self.x,
								self.y,
								GridActor.get_grid_size()*0.55)

		-- front dot
		love.graphics.setColor(1, 0, 1)
		--love.graphics.setColor(138/255,43/255,226/255, 0.9)
		love.graphics.circle(	"fill",
								self.front.x,
								self.front.y,
								GridActor.get_grid_size()/5)
		-- front line, mesma cor
		-- love.graphics.setColor(1, 0, 1)
		love.graphics.line(self.x, self.y, self.front.x, self.front.y)
	end
end

local function list_has_class(class_name, grid_actor_list)
	for i = 1, #grid_actor_list do
		if grid_actor_list[i]:is_type(class_name) then
			return true
		end
	end

	return false
end

function AutoPlayer:find_in_path_x(dx)
	local search_path_length = -AutoPlayer._search_path_length
	for i = 1, search_path_length do
		if not GridActor.grid:is_grid_way({x = self.grid_pos.x + dx, y = self.grid_pos.y}) then
			return i - search_path_length
		end

		local obj_list = AutoPlayer.grid:get_grid_actors_in_position({x = self.grid_pos + dx * i, y = self.grid_pos.y})
		if (#obj_list > 0) then
			if list_has_class("ghost") then
				return i - search_path_length
			elseif list_has_class("pill") or list_has_class("player") then
				return search_path_length - i
			end
		end
	end
	return search_path_length
end

function AutoPlayer:find_in_path_y(dy)
	local search_path_length = -AutoPlayer._search_path_length
	for i = 1, search_path_length do
		if not GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y + dy}) then
			return i - search_path_length
		end

		local obj_list = AutoPlayer.grid:get_grid_actors_in_position({x = self.grid_pos, y = self.grid_pos.y  + dy * i})
		if (#obj_list > 0) then
			if list_has_class("ghost") then
				return i - search_path_length
			elseif list_has_class("pill") or list_has_class("player") then
				return search_path_length - i
			end
		end
	end
	return search_path_length
end

function AutoPlayer:update(dt, ghost_state, ghosts, pills, autoplayers, ghost_time_left_normalized, pill_time_left_normalized)
	if (self._is_active) then
		-- find nearest pill
		local nearest_pill_index = 1
		local nearest_pill_distance = utils.distance(pills[nearest_pill_index].grid_pos, self.grid_pos)
		for i = 2, #pills do
			local this_distance = utils.distance(pills[i].grid_pos, self.grid_pos)
			if this_distance < nearest_pill_distance then
				nearest_pill_distance = this_distance
				nearest_pill_index = i
			end
		end

		-- find nearest ghost
		local nearest_ghost_index = 1
		local nearest_ghost_distance = utils.distance(ghosts[nearest_ghost_index].grid_pos, self.grid_pos)
		for i = 2, #ghosts do
			local this_distance = utils.distance(ghosts[i].grid_pos, self.grid_pos)
			if this_distance < nearest_ghost_distance then
				nearest_ghost_distance = this_distance
				nearest_ghost_index = i
			end
		end

		-- find nearest Autoplayer
		local nearest_autoplayer_distance = AutoPlayer._max_grid_distance
		local target_autoplayer_grid = self._home_grid
		for i = 1, #autoplayers do
			if autoplayers[i] ~= self then
				local this_distance = math.floor(utils.distance(autoplayers[i].grid_pos, self.grid_pos))
				if this_distance < nearest_autoplayer_distance then
					nearest_autoplayer_distance = this_distance
					target_autoplayer_grid = autoplayers[i].grid_pos
				end
			end
		end

		local inputs = {
			nearest_pill_distance/AutoPlayer._max_grid_distance,
			nearest_pill_distance/AutoPlayer._max_grid_distance,
			nearest_autoplayer_distance/AutoPlayer._max_grid_distance,
			(ghost_state == "frightened") and 0 or 1, -- ghosts freightned
			pill_time_left_normalized,
			(ghost_state == "scattering") and 0 or 1, -- ghosts scattering
			ghost_time_left_normalized,
		}
		local outputs = self._ann:get_outputs(inputs)

		local greatest_index = 1
		local greatest_value = outputs[greatest_index].value
		for i = 2, #outputs do
			local this_value = outputs[i].value

			if this_value >= greatest_value then
				greatest_value = this_value
				greatest_index = i
			end
		end

		local target_grid
		if greatest_index == 1 then
			self._target_grid = pills[nearest_pill_index].grid_pos
		elseif greatest_index == 2 then
			self._target_grid = ghosts[nearest_pill_index].grid_pos
		elseif greatest_index == 3 then
			self._target_grid = target_autoplayer_grid
		else
			-- do nothing
			-- self._target_grid = self._target_grid
		end

		self:move_get_closer_to_target_grid()

		GridActor.update(self,dt)
		-- if self.changed_tile == true then
		-- 	self._fitness = self._fitness + 0.001
		-- end
	end
end

function AutoPlayer:move_get_closer_to_target_grid()
	self._hunger = self._hunger + 1
	if self._hunger > AutoPlayer._hunger_limit then
		self._is_active = false
	end

	local enabled_directions = AutoPlayer.grid:get_enabled_directions(self.grid_pos)
	local possible_next_moves = {}
	for i = 1, #enabled_directions, 1 do
			if enabled_directions[i] then
			local grid_pos = {}
			if (i == 1) then
				grid_pos.x = self.grid_pos.x
				grid_pos.y = self.grid_pos.y - 1
				grid_pos.direction = "up"
			elseif (i == 2) then
				grid_pos.x = self.grid_pos.x
				grid_pos.y = self.grid_pos.y + 1
				grid_pos.direction = "down"
			elseif (i == 3) then
				grid_pos.x = self.grid_pos.x - 1
				grid_pos.y = self.grid_pos.y
				grid_pos.direction = "left"
			elseif (i == 4) then
				grid_pos.x = self.grid_pos.x + 1
				grid_pos.y = self.grid_pos.y
				grid_pos.direction = "right"
			end

			table.insert(possible_next_moves, grid_pos)
		end
	end

	local shortest_index = 1
	local shortest_distance = utils.distance(possible_next_moves[shortest_index], self._target_grid)
	for i = 2, #possible_next_moves, 1 do
		local dist = utils.distance(possible_next_moves[i], self._target_grid)
		if (dist < shortest_distance) then
			shortest_index = i
			shortest_distance = dist
		end
	end
	self.next_direction = possible_next_moves[shortest_index].direction
end

function AutoPlayer:got_ghost()
	self:add_fitness(1)
	self._hunger = 0
end

function AutoPlayer:got_pill()
	self:add_fitness(1)
	self._hunger = 0
end

function AutoPlayer:get_ann()
	return self._ann
end

function AutoPlayer:get_fitness()
	return self._fitness
end

function AutoPlayer:add_fitness(amount)
	self._fitness = self._fitness + amount
end

function  AutoPlayer:get_history()
	return {_fitness = self:get_fitness(), _ann = self:get_ann()}
end

return AutoPlayer
