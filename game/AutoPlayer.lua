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

function AutoPlayer.init(grid, AutoPlayer_click)
	GridActor.init(grid)

	AutoPlayer.plip_sound = AutoPlayer_click
	AutoPlayer.plip_sound:setVolume(0.3)
	AutoPlayer.plip_sound:setPitch(0.9)
end

function AutoPlayer:new(o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)
	self.__index = self

	-- new vars
	o.relay_x_counter = 0
	o.relay_y_counter = 0
	o.relay_x = 0
	o.relay_y = 0
	o.relay_times = 3 -- controls how many gameloops it takes to relay
	o.fitness = 0
	o.type = GridActor.get_type_by_name("player")

	o:getNN()

	return o
end

function AutoPlayer:getNN()
	self.NN = NN:new(4, 4, 3, 10)
end

function AutoPlayer:reset(grid_pos, speed)
	GridActor.reset(self, grid_pos, speed)

	self.relay_x_counter = 0
	self.relay_y_counter = 0
	self.relay_x = 0
	self.relay_y = 0
	self.relay_times = 3 -- controls how many gameloops it takes to relay

	self:getNN()
	self.is_active = true
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

function AutoPlayer:collided(other)

end

function AutoPlayer:update(dt)
	if (self.is_active) then
		local inputs = {
			GridActor.grid:is_grid_way({x = self.grid_pos.x + 1, y = self.grid_pos.y}) and 1 or 0,
			GridActor.grid:is_grid_way({x = self.grid_pos.x - 1, y = self.grid_pos.y}) and 1 or 0,
			GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y + 1}) and 1 or 0,
			GridActor.grid:is_grid_way({x = self.grid_pos.x, y = self.grid_pos.y - 1}) and 1 or 0,
		}
		local outputs = self.NN:get_outputs(inputs)
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

		GridActor.update(self,dt)
	end
end

return AutoPlayer
