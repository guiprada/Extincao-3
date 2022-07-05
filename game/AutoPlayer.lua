-- Guilherme Cunha Prada 2022
local GridActor = require "GridActor"
local AutoPlayer = GridActor:new()

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
	o.nn = {}

	return o
end

function AutoPlayer:reset(grid_pos, speed)
	GridActor.reset(self, grid_pos, speed)

	self.relay_x_counter = 0
	self.relay_y_counter = 0
	self.relay_x = 0
	self.relay_y = 0
	self.relay_times = 3 -- controls how many gameloops it takes to relay
end

function AutoPlayer:draw()
	--AutoPlayer body :)
	if (self.is_active) then
		love.graphics.setColor(0.8, 0.8, 0)
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

function AutoPlayer:update(dt)

end

return AutoPlayer
