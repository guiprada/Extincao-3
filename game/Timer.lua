-- Guilherme Cunha Prada 2020

local Timer = {}

function Timer:new(reset_time, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o._reset_time = reset_time
	o._timer = 0
	o._active = false
	o:reset()
	return o
end

function Timer:update(dt)
	if self._active then
		self._timer = self._timer - dt
		if (self._timer <= 0) then
			return true
		end
		return false
	end
	return nil
end

function Timer:time_left()
	return self._timer
end

function Timer:reset(new_time)
	local time = new_time or self._reset_time
	self._timer = time
	self._active = false
end

function Timer:is_active()
	return self._active
end

function Timer:start()
	self._active = true
end

function Timer:stop()
	self._active = false
end

return Timer
