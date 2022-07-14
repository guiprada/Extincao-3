-- Guilherme Cunha Prada 2022
local GridActor = require "GridActor"
local AutoPlayer = GridActor:new()

local ANN = require "ANN"
local utils = require "utils"
local random = require "random"

local outputs_to_next_direction = {
	"do_nothing",
	"up",
	"down",
	"left",
	"right",
}

local autoplayer_type_name = "player"

function AutoPlayer.init(grid)
	GridActor.init(grid)

	GridActor.register_type(autoplayer_type_name)
end

function AutoPlayer:new(o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)
	self.__index = self

	o._type = GridActor.get_type_by_name(autoplayer_type_name)

	return o
end

function AutoPlayer:reset(ann, speed, grid_pos)
	local grid_pos = grid_pos or AutoPlayer.grid:get_valid_pos()
	GridActor.reset(self, grid_pos, speed)

	self._fitness = 0

	self._ann = ann or ANN:new(6, 5, 1, 5)
end

function AutoPlayer:draw()
	--AutoPlayer body :)
	if (self.is_active) then
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

function AutoPlayer:update(dt, ghost_state)
	if (self.is_active) then
		local inputs = {
			(ghost_state == "frightened") and 0 or 1, -- ghosts freightned
			(ghost_state == "scattering") and 0 or 1, -- ghosts scattering
			GridActor.grid:is_grid_way({x = self.grid_pos.x + 1, y = self.grid_pos.y}) and 0 or 1,
			GridActor.grid:is_grid_way({x = self.grid_pos.x - 1, y = self.grid_pos.y}) and 0 or 1,
			GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y + 1}) and 0 or 1,
			GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y - 1}) and 0 or 1,
		}
		local outputs = self._ann:get_outputs(inputs)
		-- for i = 1, #outputs do
		-- 	io.write(tostring(outputs[i].value), " : ")
		-- end
		-- print("--")

		local greatest_index = 1
		local greatest_value = outputs[greatest_index].value
		for i = 2, #outputs do
			local this_value = outputs[i].value

			if this_value >= greatest_value then
				greatest_value = this_value
				greatest_index = i
			end
		end

		if not (greatest_index == 1) then
			self.next_direction = outputs_to_next_direction[greatest_index]
		end

		-- kill if choose invalid next_direction
		-- if self:is_front_wall() then
		-- 	self.is_active = false
		-- if  self.next_direction == "up" and
		-- 	self.enabled_directions[1] ~= true then
		-- 	self.is_active = false
		-- elseif  self.next_direction == "down" and
		-- 	self.enabled_directions[2] ~= true then
		-- 	self.is_active = false
		-- elseif  self.next_direction == "left" and
		-- 	self.enabled_directions[3] ~= true then
		-- 	self.is_active = false
		-- elseif  self.next_direction == "right" and
		-- 	self.enabled_directions[4] ~= true then
		-- 	self.is_active = false
		-- end

		GridActor.update(self,dt)
		if self.changed_tile == true then
			self._fitness = self._fitness + 0.001
		end

		-- if self.direction == "idle" and greatest_index == 1 then
		-- 	self._is_active = false
		-- end
		--
	end
end


function AutoPlayer:got_ghost()
	-- self._fitness = self._fitness + 1
end

function AutoPlayer:got_pill()
	-- self._fitness = self._fitness + 1
end

function AutoPlayer:get_ann()
	return self._ann
end

function AutoPlayer:get_fitness()
	return self._fitness
end

return AutoPlayer
