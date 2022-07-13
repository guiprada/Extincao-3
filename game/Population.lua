Population = {}

local utils = require "utils"
local random = require "random"
local ANN = require "ANN"

function Population:new(class, speed, active_quantity, population_size, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o._class = class
	o._speed = speed
	o._population_size = population_size

	o._active_population = {}
	o._population = {}
	o._grimory = {}
	for i = 1, population_size do
		local new = class.new(class)
		table.insert(o._population, new)
	end

	for i = 1, active_quantity do
		o._population[population_size + 1 - i]:reset(nil, o._speed)
		o._active_population[i] = o._population[population_size + 1 - i]
		o._population[population_size + 1 - i] = nil
	end

	return o
end

function Population:draw()
	for i = 1, #self._active_population do
		self._active_population[i]:draw()
	end
end

function Population:add_to_grimory(this)
	table.insert(self._grimory, this)
	if #self._grimory > (2 * self._population_size) then
		self._grimory = utils.get_n_best(self._grimory, "fitness", self._population_size)
	end
end

function Population:replace(i)
	if #self._population > 0 then
		self:add_to_grimory(self._active_population[i])

		local this = self._population[#self._population]
		this:reset(nil, self._speed)
		self._active_population[i] = this
		self._population[#self._population] = nil
	else
		-- find parents
		local best_halth = utils.get_n_best(self._grimory, "fitness", self._population_size/2)
		local mom = random.choose_list(best_halth)
		local dad = random.choose_list(best_halth)

		-- cross
		local newAnn = ANN:crossover(mom:get_ann(), dad:get_ann())

		-- reset
		local this = self._active_population[i]
		this:reset(newAnn, self._speed)
	end
end

function Population:update(dt, ghost_state)
	for i = 1, #self._active_population do
		local this = self._active_population[i]
		if this.is_active == false then
			self:replace(i)
		else
			this:update(dt, ghost_state)
		end
	end
end

function Population:get_active_population()
	return self._active_population
end

return Population