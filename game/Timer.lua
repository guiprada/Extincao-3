-- Guilherme Cunha Prada 2020

local Timer = {}

function Timer:new(reset_time, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.reset_time = reset_time
	o.timer = 0
	o:reset()
	return o
end

function Timer:update(dt)
	self.timer = self.timer - dt
	if (self.timer <= 0) then
		self:reset()
		return true
	end
	return false
end

function Timer:reset(new_time)
	local time = new_time or self.reset_time
	self.timer = time
end

return Timer
