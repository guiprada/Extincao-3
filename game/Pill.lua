-- Guilherme Cunha Prada 2020
local GridActor = require "GridActor"
local Pill = GridActor:new()
Pill.__index = Pill

local Timer = require "Timer"
local utils = require "utils"
local random = require "random"
local pill_type_name = "pill"

function Pill.init(grid, warn_sound, got_pill_update_callback, time_left_update_callback)
	GridActor.init(grid)

	Pill.pills_active = true
	Pill.warn_sound = warn_sound
	Pill.grid = grid
	Pill.got_pill_update = got_pill_update_callback
	Pill.time_left_update = time_left_update_callback

	GridActor.register_type(pill_type_name)
end

local function pill_warning()
	Pill.warn_sound:play()
end

function Pill:new(new_table, o)
	local o = GridActor:new(o or {})
	setmetatable(o, self)

	o._timer = Timer:new(new_table.pill_time)

	o._type = GridActor.get_type_by_name(pill_type_name)

	o:reset(Pill.grid.valid_pos[new_table.pos_index])

	return o
end

function Pill:reset()
	GridActor.reset(self, Pill.grid:get_valid_pos())

	self._timer:reset()

	self._in_effect = false

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
	if (Pill.pills_active) then
		love.graphics.setColor(138/255,43/255,226/255, 0.9)
		love.graphics.circle("fill", self.x, self.y, Pill.grid.grid_size*0.3)
	end
end

function Pill:collided(other)
	if (Pill.pills_active) then
		if other:is_type("player") then
			self:effect_on()
			-- if other.got_pill then
			-- 	other:got_pill()
			-- end
		end
	end
end

function Pill:update(dt)
	GridActor.update(self, dt)
	if Pill.pills_active then
		Pill.grid:update_position(self)
	else
		if self:is_in_effect() then
			if self._timer:update(dt) then
				self:effect_off()
			elseif (self._timer:time_left() < 1) then
				pill_warning()
			end
			Pill.time_left_update(self._timer:time_left())
		end
	end
end

function Pill:time_left()
	return self._timer:time_left()
end

function Pill:is_in_effect()
	return self._in_effect
end

function Pill:effect_on()
	Pill.pills_active = false
	Pill.got_pill_update(true)
	self._in_effect = true
	self._timer:start()
end

function Pill:effect_off()
	Pill.pills_active = true
	Pill.got_pill_update(false)
	self._in_effect = false
	self:reset()
	Pill.time_left_update(self._timer:time_left())
end

function Pill:is_active()
	return self._is_active
end

return Pill
