-- Guilherme Cunha Prada 2020
local GridActor = require "GridActor"
local Pill = GridActor:new()
Pill.__index = Pill

local Timer = require "Timer"
local utils = require "utils"
local random = require "random"
local pill_type_name = "pill"

function Pill.init(grid, warn_sound)
	GridActor.init(grid)

	Pill.pills_active = true
	Pill.warn_sound = warn_sound
	Pill.grid = grid

	GridActor.register_type(pill_type_name)
end

function Pill:new(pos_index, pill_time, o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)

	o.timer = Timer:new(pill_time)

	o._type = GridActor.get_type_by_name(pill_type_name)

	o:reset(Pill.grid.valid_pos[pos_index])

	return o
end

function Pill:reset(grid_pos)
	GridActor.reset(self, grid_pos)

	self.timer:reset()
	self.is_active = true
	self.effect = false

	local this_pos = Pill.grid:get_grid_center(self.grid_pos)
	self.x = this_pos.x +
		random.random(math.ceil(-Pill.grid.grid_size * 0.17), math.ceil(Pill.grid.grid_size * 0.17))
	self.y = this_pos.y +
		random.random(math.ceil(-Pill.grid.grid_size * 0.17), math.ceil(Pill.grid.grid_size * 0.17))

end

function Pill:is_type(type_name)
	if type_name == pill_type_name then
		return true
	else
		return false
	end
end

function Pill:draw()
	if (self.is_active) then
		love.graphics.setColor(138/255,43/255,226/255, 0.9)
		love.graphics.circle("fill", self.x, self.y, Pill.grid.grid_size*0.3)
	end
end

function Pill:collided(other)
	if other:is_type("player") then
		if self.got_pill then
			self:got_pill()
		end
		self.is_active = false  -- if yes, activate pill effect
		self.effect = true
		Pill.pills_active = false -- deactivate other pills
		self.timer:reset() -- and start pill timer
	end
end

function Pill:update(dt)
	GridActor.update(self, dt)
	if (self.is_active == false) then -- if pill is inactive(it is under effect)
		if (self.timer:update(dt)) then -- update timers
			local this_pos_index = random.random(1, #Pill.grid.valid_pos)
			local this_pos = Pill.grid.valid_pos[this_pos_index]
			self:reset(this_pos)

			Pill.pills_active = true
		elseif(self.timer.timer < 1)then
			Pill.warn_sound:play()
		end
	elseif (Pill.pills_active) then -- and the player is active
		Pill.grid:update_position(self)
	end
end

return Pill
