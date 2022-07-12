-- Guilherme Cunha Prada 2020
local GridActor = require "GridActor"
local Player = GridActor:new()

function Player.init(grid, player_click)
	GridActor.init(grid)

	Player.plip_sound = player_click
	Player.plip_sound:setVolume(0.3)
	Player.plip_sound:setPitch(0.9)

	GridActor.register_type("player")
end

function Player:new(o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)
	self.__index = self

	-- new vars
	o.relay_x_counter = 0
	o.relay_y_counter = 0
	o.relay_x = 0
	o.relay_y = 0
	o.relay_times = 3 -- controls how many gameloops it takes to relay
	o.type = GridActor.get_type_by_name("player")

	return o
end

function Player:reset(grid_pos, speed)
	GridActor.reset(self, grid_pos, speed)

	self.relay_x_counter = 0
	self.relay_y_counter = 0
	self.relay_x = 0
	self.relay_y = 0
	self.relay_times = 3 -- controls how many gameloops it takes to relay
end

function Player:collided(other)

end

function Player:draw()
	--player body :)
	if (self.is_active) then
		love.graphics.setColor(1, 1, 0)
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

function Player:update(dt)
	if (self.is_active) then
		GridActor.update(self, dt)

		if self.changed_tile == true then
			Player.plip_sound:play()
		end
	end
end

return Player
