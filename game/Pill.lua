-- Guilherme Cunha Prada 2020

local Pill = {}

local Timer = require "Timer"
local utils = require "utils"

function Pill.init(grid, pill_genetic_on, pill_precise_crossover_on, warn_sound)
    Pill.pills_active = true
    Pill.pill_genetic_on = pill_genetic_on
    Pill.pill_precise_crossover_on = pill_precise_crossover_on
    Pill.warn_sound = warn_sound
    Pill.grid = grid
end

function Pill:new(pos_index, pill_time, o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.pos_index = pos_index
    o.grid_pos = Pill.grid.grid_valid_pos[pos_index]
    o.timer = Timer:new(pill_time)

    o:reset(grid_pos)

    return o
end

function Pill:draw()
    if (self.is_active) then
        love.graphics.setColor(138/255,43/255,226/255, 0.9)
        love.graphics.circle("fill", self.x, self.y, Pill.grid.grid_size*0.3)
    end
end


function Pill:update(pills, target, dt)
    self.n_updates = self.n_updates + 1
    self.fitness = self.n_ghost_pass/self.n_updates
    if (self.is_active == false) then -- if pill is inactive(it is under effect)
        if (self.timer:update(dt)) then -- update timers
            if(Pill.pill_genetic_on)then
                self:crossover( pills)
            else
                local this_pos_index =
                                love.math.random(1, #Pill.grid.grid_valid_pos)
                local this_pos = Pill.grid.grid_valid_pos[this_pos_index]
                self:reset(this_pos)
            end

            Pill.pills_active = true
        elseif(self.timer.timer < 1)then
            Pill.warn_sound:play()
        end
    elseif (    (Pill.pills_active) and -- if pills are active
                (target.is_active)) then -- and the player is active
        local dist_to_player = utils.dist(self, target)
        if ( dist_to_player < Pill.grid.lookahead) then -- check collision
            self.is_active = false  -- if yes, activate pill effect
            Pill.pills_active = false -- deactivate other pills
            self.timer:reset() -- and start pill timer
        end
    end
end

function Pill:reset(grid_pos)
    self.timer:reset()
    self.fitness = 0
    self.n_ghost_pass = 0
    self.n_updates = 0

    local this_grid_pos = grid_pos or self.grid_pos
    self.grid_pos.x = this_grid_pos.x
    self.grid_pos.y = this_grid_pos.y

    local this_pos = Pill.grid:get_grid_center(self.grid_pos)
    self.x = this_pos.x +
        love.math.random(-Pill.grid.grid_size*0.17, Pill.grid.grid_size*0.17)
    self.y = this_pos.y +
        love.math.random(-Pill.grid.grid_size*0.17, Pill.grid.grid_size*0.17)
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
        if(Pill.grid.is_grid_way(temp_grid_pos.x, temp_grid_pos.y)) then
            son.grid_pos.x = temp_grid_pos.x
            son.grid_pos.y = temp_grid_pos.y
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x -1, temp_grid_pos.y)) then
            son.grid_pos.x = temp_grid_pos.x - 1
            son.grid_pos.y = temp_grid_pos.y
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x +1, temp_grid_pos.y)) then
            son.grid_pos.x = temp_grid_pos.x + 1
            son.grid_pos.y = temp_grid_pos.y
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x, temp_grid_pos.y -1)) then
            son.grid_pos.x = temp_grid_pos.x
            son.grid_pos.y = temp_grid_pos.y - 1
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x, temp_grid_pos.y +1)) then
            son.grid_pos.x = temp_grid_pos.x
            son.grid_pos.y = temp_grid_pos.y + 1
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x -1, temp_grid_pos.y -1)) then
            son.grid_pos.x = temp_grid_pos.x - 1
            son.grid_pos.y = temp_grid_pos.y - 1
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x +1, temp_grid_pos.y + 1)) then
            son.grid_pos.x = temp_grid_pos.x + 1
            son.grid_pos.y = temp_grid_pos.y + 1
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x +1, temp_grid_pos.y -1)) then
            son.grid_pos.x = temp_grid_pos.x + 1
            son.grid_pos.y = temp_grid_pos.y - 1
        elseif(Pill.grid.is_grid_way(temp_grid_pos.x -1, temp_grid_pos.y +1)) then
            son.grid_pos.x = temp_grid_pos.x - 1
            son.grid_pos.y = temp_grid_pos.y + 1
        else
            local this_pos_index = math.floor((mom.pos_index + dad.pos_index)/2)
            local this_grid_pos = Pill.grid.grid_valid_pos[this_pos_index]
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
            elseif (son.pos_index > #Pill.grid.grid_valid_pos) then
                son.pos_index = #Pill.grid.grid_valid_pos
            end
        end
        son.grid_pos = Pill.grid.grid_valid_pos[son.pos_index ]
    end

    self:reset(son.grid_pos)
end

return Pill
