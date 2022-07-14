Population = {}

local utils = require "utils"
local random = require "random"
local ANN = require "ANN"

function Population:new(class, speed, active_size, population_size, o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o._class = class
	o._speed = speed
	o._population_size = population_size
	o._random_init = population_size

	o._population = {}
	o._history = {}
	o._count = 0

	for i = 1, active_size do
		o._population[i] = class:new(nil, self._speed)
		o._population[i]:reset(nil, o._speed)
		o._count = o._count + 1
	end

	return o
end

function Population:draw()
	for i = 1, #self._population do
		self._population[i]:draw()
	end
end

function Population:add_to_history(this)
	table.insert(self._history, {ann = this:get_ann(), fitness = this:get_fitness()})
	if #self._history > (2 * self._population_size) then
		self._history = utils.get_n_best(self._history, "fitness", self._population_size)
	end
end

function Population:replace(i)
	self._count = self._count + 1
	print("count:", self._count)
	self:add_to_history(self._population[i])

	if self._random_init > 0 then
		self._random_init = self._random_init - 1
		self._population[i]:reset(nil, self._speed)
	else
		-- find parents
		local best_halth = utils.get_n_best(self._history, "fitness", self._population_size/30)
		local mom = random.choose_list(best_halth)
		local dad = random.choose_list(best_halth)

		-- cross
		local newAnn = ANN:crossover(mom.ann, dad.ann)

		-- reset
		self._population[i]:reset(newAnn, self._speed)
	end
end

function Population:update(dt, ghost_state)
	for i = 1, #self._population do
		local this = self._population[i]
		if this.is_active == false then
			self:replace(i)
		else
			this:update(dt, ghost_state)
		end
	end
end

function Population:get_population()
	return self._population
end

return Population