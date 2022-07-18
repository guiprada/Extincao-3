-- Guilherme Cunha Prada 2020
local GridActor = require "GridActor"
local Player = GridActor:new()
Player.__index = Player

local player_type_name = "player"

function Player.init(grid, player_click)
	GridActor.init(grid)

	Player.plip_sound = player_click
	Player.plip_sound:setVolume(0.3)
	Player.plip_sound:setPitch(0.9)

	GridActor.register_type(player_type_name)
end

function Player:new(o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)

	o._type = GridActor.get_type_by_name(player_type_name)

	return o
end

function Player:reset(grid_pos, speed)
	GridActor.reset(self, grid_pos, speed)
end

function Player:collided(other)

end

function Player:draw()
	--player body :)
	if (self._is_active) then
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
	if (self._is_active) then
		GridActor.update(self, dt)

		if self.changed_tile == true then
			Player.plip_sound:play()
		end
	end
end

return Player
