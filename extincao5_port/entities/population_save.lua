-- Guilherme Cunha Prada / Claude 2026
-- Population save and restore system for Extincao-5
-- Saves/loads ghost live genes and history (gene pool) using love.filesystem

local population_save = {}

local SAVE_FILE = "population.save"

local function serialize(ghost_population)
	local lines = {}
	table.insert(lines, "return {")

	-- live population genes
	table.insert(lines, "  live = {")
	local population = ghost_population:get_population()
	for i = 1, #population do
		local g = population[i]
		table.insert(lines, string.format(
			"    { home=%d, target_offset=%d, try_order={%d,%d,%d,%d} },",
			g._home, g._target_offset,
			g._try_order[1], g._try_order[2], g._try_order[3], g._try_order[4]
		))
	end
	table.insert(lines, "  },")

	-- history / gene pool
	table.insert(lines, "  history = {")
	local history = ghost_population._history
	for i = 1, #history do
		local h = history[i]
		table.insert(lines, string.format(
			"    { _fitness=%d, _target_offset=%d, _try_order={%d,%d,%d,%d} },",
			h._fitness or 0, h._target_offset,
			h._try_order[1], h._try_order[2], h._try_order[3], h._try_order[4]
		))
	end
	table.insert(lines, "  },")

	table.insert(lines, "}")
	return table.concat(lines, "\n")
end

-- Save current ghost population (live genes + history) to file.
-- Returns true on success, false on failure.
function population_save.save(ghost_population)
	local data = serialize(ghost_population)
	local ok, err = love.filesystem.write(SAVE_FILE, data)
	if not ok then
		print("population_save: failed to write file: " .. tostring(err))
		return false
	end
	return true
end

-- Load ghost population from file.
-- Restores history pool and applies genes to live ghosts.
-- Returns true on success, false if file not found or parse error.
function population_save.load(ghost_population)
	if not love.filesystem.getInfo(SAVE_FILE) then
		print("population_save: no save file found")
		return false
	end

	local chunk, err = love.filesystem.load(SAVE_FILE)
	if not chunk then
		print("population_save: failed to parse save file: " .. tostring(err))
		return false
	end

	local ok, data = pcall(chunk)
	if not ok or type(data) ~= "table" then
		print("population_save: invalid save data")
		return false
	end

	-- Restore history (gene pool used for selection/crossover)
	if data.history and #data.history > 0 then
		ghost_population._history = data.history
		ghost_population._history_fitness_sum = 0
		for _, h in ipairs(data.history) do
			ghost_population._history_fitness_sum =
				ghost_population._history_fitness_sum + (h._fitness or 0)
		end
		-- Skip remaining random inits so selection uses the loaded pool immediately
		ghost_population._random_init = 0
	end

	-- Restore live ghost genes
	if data.live then
		local population = ghost_population:get_population()
		local count = math.min(#population, #data.live)
		for i = 1, count do
			local gd = data.live[i]
			population[i]:reset({
				home         = gd.home,
				target_offset = gd.target_offset,
				try_order    = gd.try_order,
			})
		end
	end

	return true
end

-- Returns true if a save file exists.
function population_save.has_save()
	return love.filesystem.getInfo(SAVE_FILE) ~= nil
end

return population_save
