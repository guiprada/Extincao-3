Population = {}

function Population:new(class, reset_parameters, initial_quantity, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o._class = class
	o._reset_parameters = reset_parameters
	o._count = 0
	o._population = {}
	for i = 1, initial_quantity do
		local new = class.new(class)
		new:reset(unpack(reset_parameters))
		table.insert(o._population, new)
		o._count = o._count + 1
	end

	return o
end

function Population:draw()
	for i = 1, self._count do
		self._population[i]:draw()
	end
end

function Population:update(dt)
	for i = 1, self._count do
		local this = self._population[i]
		if this.is_active == false then
			this:reset(unpack(self._reset_parameters))
		else
			this:update(dt)
		end
	end
end

return Population