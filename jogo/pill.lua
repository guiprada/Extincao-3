-- Guilherme Cunha Prada 2019

-- make a pill duration time * speed beest

-- fitness based on distance to the average of the group of pills positions, so they are borne closer
-- and how many ghosts have gone through then, so they are harder to catch, this may be uneed because
-- coevolution may do that already

-- duas sub_especies de pilulas, uma laranja que seja mais rara e silvestre,
-- ou seja ela nasce longe do grupo, ela pode dar um speed boost ou durar mais
-- ou os dois, o fenotipo apacere quando a distancia do grupo for maior que uma certa medida
-- e ela nasce cada vez mais longe pois seu fitness e calculado diferente, invertido,
-- ela nao gosta de fantasma e quer nascer longe

local timer = require "timer"
local grid = require "grid"
local utils = require "utils"
local pill = {}
pill.pills_active = true
pill.pill_genetic_on = true
pill.pill_precise_crossover_on = false
pill.grid_size = 0
pill.lookahead = 0

--local pill_size = 5


function pill.init(pill_genetic_on, pill_precise_crossover_on, grid_size, lookahead)
    pill.pill_genetic_on = pill_genetic_on
    pill.pill_precise_crossover_on = pill_precise_crossover_on
    pill.grid_size = grid_size
    pill.lookahead = lookahead
end

function pill.new(pos_index, pill_time)
    local value = {}
    value.is_active = false
    value.x = 0
    value.y = 0
    value.fitness = 0
    value.pos_index = pos_index
    value.grid_pos = grid.grid_valid_pos[value.pos_index]
    value.timer = {}
    pill.reset(value, pill_time)
    return value
end

function pill.draw(value)
    if (value.is_active) then
        love.graphics.setColor(138/255,43/255,226/255, 0.9)
        love.graphics.circle("fill", value.x, value.y, pill.grid_size*0.39)
    end
end


function pill.update(value, pills, target, dt, pill_time)
    if (value.is_active == false) then
        if (timer.update(value.timer, dt)) then
            if(pill.pill_genetic_on)then
                pill.crossover(value, pills, pill_time)
            else
                local this_pos_index =  love.math.random(1, #grid.grid_valid_pos)
                local this_pos = grid.grid_valid_pos[this_pos_index]
                pill.reset(value, pill_time, this_pos)
            end
            pill.pills_active = true
        end
    elseif (    (pill.pills_active) and
                (target.is_active)) then
        local dist_to_player = utils.dist(value, target)
        if ( dist_to_player < pill.lookahead) then
            value.is_active = false
            pill.pills_active = false
            timer.reset(value.timer)
        end
    end
end

function pill.reset( value, pill_time, grid_pos )
    value.timer = timer.new(pill_time)
    value.fitness = 0

    local this_grid_pos = grid_pos or value.grid_pos
    value.grid_pos.x = this_grid_pos.x
    value.grid_pos.y = this_grid_pos.y

    local this_pos = grid.get_grid_center(value)
    value.x = this_pos.x
    value.y = this_pos.y
    value.is_active = true
end

function pill.selection(pills)
    -- get the living
    local living_stack = {}
    for i=1, #pills, 1 do
        if ( pills[i].is_active)then
            table.insert(living_stack, pills[i])
        end
    end

    return living_stack[love.math.random(1, math.ceil(#living_stack/2))], living_stack[love.math.random( math.floor(#living_stack/2), #living_stack)]
    --return utils.tables_get_highest(living_stack, "fitness"), living_stack[love.math.random(1, #living_stack)]
end

function pill.crossover(value, pills, pill_time)
    local son = {}
    local mom, dad = pill.selection(pills)

    if (pill.pill_precise_crossover_on) then
        son.x = math.floor((mom.x + dad.x)/2) --+ love.math.random(1, 8)j
        son.y = math.floor((mom.y + dad.y)/2) --+ love.math.random(1, 8)
        local temp_grid_pos = grid.get_grid_pos(son)

        son.grid_pos = {}

        temp_grid_pos.x = temp_grid_pos.x + love.math.random(-5,5)
        if( temp_grid_pos.x < 2) then temp_grid_pos.x = 2 end
        if( temp_grid_pos.x > (grid.grid_width_n -1)) then temp_grid_pos.x = grid.grid_width_n -1 end

        temp_grid_pos.y = temp_grid_pos.y + love.math.random(-5,5)
        if( temp_grid_pos.y < 2) then temp_grid_pos.y = 2 end
        if( temp_grid_pos.y > (grid.grid_height_n -1)) then temp_grid_pos.y = grid.grid_height_n -1 end


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

    pill.reset(value, pill_time, son.grid_pos)
end

return pill
