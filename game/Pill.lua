-- Guilherme Cunha Prada 2020

local Pill = {}

local timer = require "timer"
local grid = require "grid"
local utils = require "utils"

-- Pill.pill_genetic_on = true
-- Pill.pill_precise_crossover_on = false
-- Pill.grid_size = 0
-- Pill.lookahead = 0

function Pill.init(pill_genetic_on, pill_precise_crossover_on, grid_size, lookahead, warn_sound)
    Pill.pills_active = false
    Pill.pill_genetic_on = pill_genetic_on
    Pill.pill_precise_crossover_on = pill_precise_crossover_on
    Pill.grid_size = grid_size
    Pill.lookahead = lookahead
    Pill.warn_sound = warn_sound
end

function Pill:new(pos_index, pill_time, o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.pos_index = pos_index
    o.grid_pos = grid.grid_valid_pos[pos_index]
    o.timer = {}

    o:reset(pill_time, grid_pos)

    return o
end

function Pill:draw()
    if (self.is_active) then
        love.graphics.setColor(138/255,43/255,226/255, 0.9)
        love.graphics.circle("fill", self.x, self.y, Pill.grid_size*0.3)
    end
end


function Pill:update(pills, target, dt)
    self.n_updates = self.n_updates + 1
    self.fitness = self.n_ghost_pass/self.n_updates
    if (self.is_active == false) then
        if (timer.update(self.timer, dt)) then
            if(Pill.pill_genetic_on)then
                self:crossover( pills)
            else
                local this_pos_index =  love.math.random(1, #grid.grid_valid_pos)
                local this_pos = grid.grid_valid_pos[this_pos_index]
                self:reset(self.timer.reset_time, this_pos)
            end
            Pill.pills_active = true
        elseif(self.timer.timer < 1)then
            Pill.warn_sound:play()
        end
    elseif (    (Pill.pills_active) and
                (target.is_active)) then
        local dist_to_player = utils.dist(self, target)
        if ( dist_to_player < Pill.lookahead) then
            self.is_active = false
            Pill.pills_active = false
            timer.reset(self.timer)
        end
    end
end

function Pill:reset(pill_time, grid_pos )
    self.timer = timer.new(pill_time)
    self.fitness = 0
    self.n_ghost_pass = 0
    self.n_updates = 0

    local this_grid_pos = grid_pos or self.grid_pos
    self.grid_pos.x = this_grid_pos.x
    self.grid_pos.y = this_grid_pos.y

    local this_pos = grid.get_grid_center(self)
    self.x = this_pos.x + love.math.random(-Pill.grid_size*0.17, Pill.grid_size*0.17)
    self.y = this_pos.y + love.math.random(-Pill.grid_size*0.17, Pill.grid_size*0.17)
    self.is_active = true
end

function Pill.selection(pills)
    -- get the living
    local living_stack = {}
    for i=1, #pills, 1 do
        if ( pills[i].is_active)then
            table.insert(living_stack, pills[i])
        end
    end

    local best = utils.get_n_best(living_stack, "fitness", 2)

    return best[1], best[2]
    --return utils.tables_get_highest(living_stack, "fitness"), living_stack[love.math.random(1, #living_stack)]
end

function Pill:crossover(pills)
    local son = {}
    local mom, dad = Pill.selection(pills)

    if (Pill.pill_precise_crossover_on) then
        son.x = math.floor((mom.x + dad.x)/2) --+ love.math.random(1, 8)j
        son.y = math.floor((mom.y + dad.y)/2) --+ love.math.random(1, 8)
        local temp_grid_pos = grid.get_grid_pos(son)

        son.grid_pos = {}
        son.pos_index = {}

        temp_grid_pos.x = temp_grid_pos.x + love.math.random(-5,5)
        if( temp_grid_pos.x < 2) then temp_grid_pos.x = 2 end
        if( temp_grid_pos.x > (grid.grid_width_n -1)) then
            temp_grid_pos.x = grid.grid_width_n -1
        end

        temp_grid_pos.y = temp_grid_pos.y + love.math.random(-5,5)
        if( temp_grid_pos.y < 2) then temp_grid_pos.y = 2 end
        if( temp_grid_pos.y > (grid.grid_height_n -1)) then
            temp_grid_pos.y = grid.grid_height_n -1
        end

        -- find a valid position to spawn
        if(grid.is_grid_way(temp_grid_pos.x, temp_grid_pos.y)) then
            son.grid_pos.x = temp_grid_pos.x
            son.grid_pos.y = temp_grid_pos.y
        elseif(grid.is_grid_way(temp_grid_pos.x -1, temp_grid_pos.y)) then
            son.grid_pos.x = temp_grid_pos.x - 1
            son.grid_pos.y = temp_grid_pos.y
        elseif(grid.is_grid_way(temp_grid_pos.x +1, temp_grid_pos.y)) then
            son.grid_pos.x = temp_grid_pos.x + 1
            son.grid_pos.y = temp_grid_pos.y
        elseif(grid.is_grid_way(temp_grid_pos.x, temp_grid_pos.y -1)) then
            son.grid_pos.x = temp_grid_pos.x
            son.grid_pos.y = temp_grid_pos.y - 1
        elseif(grid.is_grid_way(temp_grid_pos.x, temp_grid_pos.y +1)) then
            son.grid_pos.x = temp_grid_pos.x
            son.grid_pos.y = temp_grid_pos.y + 1
        elseif(grid.is_grid_way(temp_grid_pos.x -1, temp_grid_pos.y -1)) then
            son.grid_pos.x = temp_grid_pos.x - 1
            son.grid_pos.y = temp_grid_pos.y - 1
        elseif(grid.is_grid_way(temp_grid_pos.x +1, temp_grid_pos.y + 1)) then
            son.grid_pos.x = temp_grid_pos.x + 1
            son.grid_pos.y = temp_grid_pos.y + 1
        elseif(grid.is_grid_way(temp_grid_pos.x +1, temp_grid_pos.y -1)) then
            son.grid_pos.x = temp_grid_pos.x + 1
            son.grid_pos.y = temp_grid_pos.y - 1
        elseif(grid.is_grid_way(temp_grid_pos.x -1, temp_grid_pos.y +1)) then
            son.grid_pos.x = temp_grid_pos.x - 1
            son.grid_pos.y = temp_grid_pos.y + 1
        else
            local this_pos_index = math.floor((mom.pos_index + dad.pos_index)/2)
            local this_grid_pos = grid.grid_valid_pos[this_pos_index]
            son.grid_pos.x = this_grid_pos.x
            son.grid_pos.y = this_grid_pos.y
            --print("error")
        end
    else
        son.pos_index = math.floor((mom.pos_index + dad.pos_index)/2)
        if (love.math.random(0, 10)<=9) then -- mutate
            son.pos_index = son.pos_index + math.floor(love.math.random(-3, 3))
            if (son.pos_index < 1) then
                son.pos_index = 1
            elseif (son.pos_index > #grid.grid_valid_pos) then
                son.pos_index = #grid.grid_valid_pos
            end
        end
        son.grid_pos = grid.grid_valid_pos[son.pos_index ]
    end

    son.pill_time = (mom.timer.reset_time + dad.timer.reset_time)/2

    Pill.reset(self, son.pill_time, son.grid_pos)
end

return Pill
