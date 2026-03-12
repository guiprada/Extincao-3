-- Guilherme Cunha Prada / Claude 2026
-- Population save and restore system
-- Saves/loads ghost genome data to/from a file using love.filesystem

local population_save = {}

local SAVE_FILE = "population.save"

-- Serialize ghost genomes to a string
local function serialize_genomes(ghosts)
    local lines = {}
    table.insert(lines, "return {")
    for i = 1, #ghosts, 1 do
        local g = ghosts[i]
        table.insert(lines, string.format(
            "  { target_offset=%d, fear_target=%d, fear_group=%d," ..
            " chase_feared_gene=%d, scatter_feared_gene=%d," ..
            " pos_index=%d," ..
            " try_order={%d,%d,%d,%d} },",
            g.target_offset, g.fear_target, g.fear_group,
            g.chase_feared_gene, g.scatter_feared_gene,
            g.pos_index,
            g.try_order[1], g.try_order[2], g.try_order[3], g.try_order[4]
        ))
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

-- Save current ghost population genomes to file
-- Returns true on success, false on failure
function population_save.save(ghosts)
    local data = serialize_genomes(ghosts)
    local ok, err = love.filesystem.write(SAVE_FILE, data)
    if not ok then
        print("population_save: failed to write file: " .. tostring(err))
        return false
    end
    return true
end

-- Load ghost genomes from file and apply to existing ghost array
-- Returns true on success, false if file not found or parse error
function population_save.load(ghosts, pills)
    if not love.filesystem.getInfo(SAVE_FILE) then
        print("population_save: no save file found")
        return false
    end

    local chunk, err = love.filesystem.load(SAVE_FILE)
    if not chunk then
        print("population_save: failed to parse save file: " .. tostring(err))
        return false
    end

    local ok, genomes = pcall(chunk)
    if not ok or type(genomes) ~= "table" then
        print("population_save: invalid save data")
        return false
    end

    local count = math.min(#ghosts, #genomes)
    for i = 1, count, 1 do
        local gd = genomes[i]
        ghosts[i]:reset(
            gd.pos_index,
            gd.target_offset,
            gd.try_order,
            gd.fear_target,
            gd.fear_group,
            gd.chase_feared_gene,
            gd.scatter_feared_gene,
            ghosts[i].speed,
            pills
        )
    end
    return true
end

-- Returns true if a save file exists
function population_save.has_save()
    return love.filesystem.getInfo(SAVE_FILE) ~= nil
end

return population_save
