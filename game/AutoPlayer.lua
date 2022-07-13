-- Guilherme Cunha Prada 2022
local GridActor = require "GridActor"
local AutoPlayer = GridActor:new()

local NN = require "NN"
local utils = require "utils"
local random = require "random"

local outputs_to_next_direction = {
	"up",
	"down",
	"left",
	"right",
}

local autoplayer_type_name = "player"

function AutoPlayer.init(grid, AutoPlayer_click)
	GridActor.init(grid)

	AutoPlayer.plip_sound = AutoPlayer_click
	AutoPlayer.plip_sound:setVolume(0.3)
	AutoPlayer.plip_sound:setPitch(0.9)

	GridActor.register_type(autoplayer_type_name)
end

function AutoPlayer:new(o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)
	self.__index = self

	o._type = GridActor.get_type_by_name(autoplayer_type_name)

	o:getAnn()

	return o
end

function AutoPlayer:getAnn()
	self._ann = NN:new(4, 4, 3, 10)
end

function AutoPlayer:reset(grid_pos, speed)
	GridActor.reset(self, grid_pos, speed)

	self.fitness = 0
	self:getAnn()
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

function AutoPlayer:got_ghost()
	self.fitness = self.fitness + 1
end

function AutoPlayer:got_pill()
	self.fitness = self.fitness + 1
end

function AutoPlayer:update(dt)
	if (self.is_active) then
		GridActor.update(self,dt)

		local inputs = {
			GridActor.grid:is_grid_way({x = self.grid_pos.x + 1, y = self.grid_pos.y}) and 1 or 0,
			GridActor.grid:is_grid_way({x = self.grid_pos.x - 1, y = self.grid_pos.y}) and 1 or 0,
			GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y + 1}) and 1 or 0,
			GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y - 1}) and 1 or 0,
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

		self.next_direction = outputs_to_next_direction[greatest_index]

		if self.changed_tile == true then
			self.fitness = self.fitness + 0.001
		end
	end
end

return AutoPlayer
