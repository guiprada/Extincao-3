-- Guilherme Cunha Prada 2019

local grid = require "grid"
local utils = require "utils"
local ghost = {}

ghost.ghost_fitness_on = false
ghost.ghost_target_offset_freightned_on = false
ghost.ghost_migration_on = true
ghost.ghost_selective_migration_on = true
ghost.speed_boost_on = false
ghost.ghost_speed_max_factor = 1
ghost.ghost_speed = 0
ghost.grid_size = 0
ghost.ghost_fear_on = false
ghost.ghost_go_home_on_scatter = false
ghost.ghost_scatter_feared_gene_on = false
ghost.ghost_chase_feared_gene_on = false

function ghost.init( ghost_fitness_on, ghost_target_spread, ghost_target_offset_freightned_on, ghost_migration_on, ghost_selective_migration_on, ghost_speed, speed_boost_on, ghost_speed_max_factor, ghost_fear_on, ghost_go_home_on_scatter, ghost_chase_feared_gene_on, ghost_scatter_feared_gene_on, grid_size, lookahead)
    ghost.ghost_fitness_on = ghost_fitness_on
    ghost.ghost_target_spread = ghost_target_spread
    ghost.ghost_target_offset_freightned_on = ghost_target_offset_freightned_on
    ghost.ghost_migration_on = ghost_migration_on
    ghost.ghost_selective_migration_on = ghost_selective_migration_on
    ghost.ghost_speed = ghost_speed
    ghost.speed_boost_on = speed_boost_on
    ghost.ghost_speed_max_factor = ghost_speed_max_factor
    ghost.ghost_fear_on = ghost_fear_on
    ghost.ghost_go_home_on_scatter = ghost_go_home_on_scatter
    ghost.ghost_scatter_feared_gene_on = ghost_scatter_feared_gene_on
    ghost.ghost_chase_feared_gene_on = ghost_chase_feared_gene_on
    ghost.grid_size = grid_size
    ghost.lookahead = lookahead
end

function ghost.new(pos_index, pilgrin_gene, target_offset, target_offset_freightned, try_order, fear_target, fear_group, chase_feared_gene, scatter_feared_gene, speed, pills)
    local value = {}
    value.grid_pos = {} -- fenotipo de pos_index
    value.pill_debounce = {}
    value.home = {} -- determinado por pos_index, e um fenotipo
    value.try_order = {} -- gene

    value.enabled_dir = {}
    value.last_grid_pos = {}
    value.front = {}
    ghost.reset(value, pos_index, pilgrin_gene, target_offset, target_offset_freightned, try_order, fear_target, fear_group, chase_feared_gene, scatter_feared_gene, speed, pills)

    return  value
end

function ghost.reset(value, pos_index, pilgrin_gene, target_offset, target_offset_freightned, try_order, fear_target, fear_group, chase_feared_gene, scatter_feared_gene, speed, pills, spawn_grid_pos, direction)
    value.is_active = true
    value.n_updates = 0
    value.n_chase_updates = 0
    value.n_freightened_updates = 0
    value.acc_chase_dist = 0
    value.acc_freightened_dist = 0
    value.n_catches = 0
    value.n_pills = 0
    value.fitness = 0
    --value.home_pill_fitness = 0
    value.home_pill_index = 0
    value.speed_boost = 0
    value.dist_to_group = 0
    value.dist_to_target = 0
    value.is_feared = false

    value.pilgrin_gene = pilgrin_gene
    value.target_offset = target_offset
    value.target_offset_freightned = target_offset_freightned
    value.fear_target = fear_target
    value.fear_group = fear_group
    value.chase_feared_gene = chase_feared_gene
    value.scatter_feared_gene = scatter_feared_gene


    for i=1, #pills, 1 do
        value.pill_debounce[i] = false
    end

    value.speed = speed

    local valid_grid_pos = grid.grid_valid_pos[pos_index]
    value.pos_index = pos_index
    value.home.x = valid_grid_pos.x
    value.home.y = valid_grid_pos.y

    local this_spawn_grid_pos = spawn_grid_pos or value.home
    value.grid_pos.x = this_spawn_grid_pos.x
    value.grid_pos.y = this_spawn_grid_pos.y

    local this_pos = grid.get_grid_center(value)
    value.x = this_pos.x
    value.y = this_pos.y

    value.home.x = value.grid_pos.x
    value.home.y = value.grid_pos.y

    -- escolhe direcao inicial
    value.enabled_dir = grid.get_enabled_directions(value.grid_pos)

    --value.try_order = {} -- nao destroi a velha, pois e usada por ghost.highest_fitness_genome
    value.try_order[1] = try_order[1]
    value.try_order[2] = try_order[2]
    value.try_order[3] = try_order[3]
    value.try_order[4] = try_order[4]

    -- e habilita uma direcao valida
    if(not direction) then
        for i=1, #value.try_order, 1 do
            if ( value.enabled_dir[value.try_order[i]] == true) then
                if(value.try_order[i]==1) then
                    value.direction = "up"
                elseif(value.try_order[i]==2) then
                    value.direction = "down"
                elseif(value.try_order[i]==3) then
                    value.direction = "left"
                elseif(value.try_order[i]==4) then
                    value.direction = "right"
                end
            end
        end
    else
        value.direction = direction
    end

    value.last_grid_pos.x = -1
    value.last_grid_pos.y = -1


    value.front = grid.get_dynamic_front(value)
end

function ghost.selection(in_table)
        --find the living
    local living_stack = {}
    for i=1, #in_table, 1 do
        if in_table[i].is_active == true then
            table.insert(living_stack, in_table[i])
        end
    end

    local mom = {}
    local dad = {}
    if (ghost.ghost_fitness_on) then
        --print("fitness on")
        --mom = utils.tables_get_highest(living_stack, "fitness")
        --dad = living_stack[love.math.random(1, #living_stack)]

        local best_stack = utils.get_n_best(living_stack, "fitness", math.ceil(#living_stack/2))
        mom = best_stack[love.math.random(1, #best_stack)]
        --dad = best_stack[love.math.random(1, #best_stack)]
        dad = living_stack[love.math.random(1, #living_stack)]
    else
        mom = living_stack[love.math.random(1, #living_stack)]
        dad = living_stack[love.math.random(1, #living_stack)]
    end

    return mom, dad
end

function ghost.crossover (value, ghosts, pills, spawn_grid_pos)
    local mom = {}
    local dad = {}
    mom, dad = ghost.selection(ghosts)

    local son = {}

    son.fear_target =  math.floor( (mom.fear_target + dad.fear_target)/2 + love.math.random(-5, 5) )
    son.fear_group = math.floor( (mom.fear_group + dad.fear_group)/2 + love.math.random(-5, 5) )

    if(son.fear_target > 50)then
        son.fear_target = 50
    elseif(son.fear_target < 0)then
        son.fear_target = 0
    end

    if(son.fear_group > 50)then
        son.fear_group = 50
    elseif(son.fear_group < 0)then
        son.fear_group = 0
    end

    local this_spawn_grid_pos = {}
    local this_direction = ""
    if (spawn_grid_pos) then
        this_spawn_grid_pos = spawn_grid_pos
        this_direction = nil
    else -- nasce com a mae
        this_spawn_grid_pos.x = mom.grid_pos.x
        this_spawn_grid_pos.y = mom.grid_pos.y
        this_direction = mom.direction
    end

    -- recessivo para o gene peregrino
    if( mom.pilgrin_gene == dad.pilgrin_gene ) then
        son.pilgrin_gene = mom.pilgrin_gene
    else
        if ( love.math.random(0, 3) == 1 ) then
            son.pilgrin_gene = true
        else
            son.pilgrin_gene = false
        end
    end

    son.pos_index = math.floor((mom.pos_index + dad.pos_index)/2)
    if (love.math.random(0, 10)<=9) then -- mutate
        son.pos_index = son.pos_index + math.floor(love.math.random(-50, 50))
        if (son.pos_index < 1) then
            son.pos_index = 1
        elseif (son.pos_index > #grid.grid_valid_pos) then
            son.pos_index = #grid.grid_valid_pos
        end
    end
    --print(son.pos_index)

    son.target_offset = math.floor((mom.target_offset + dad.target_offset)/2)
    -- ate run10
    if (love.math.random(0, 10)<=3) then -- mutate
        son.target_offset = son.target_offset + math.floor(love.math.random(-2, 2))
    end

    -- run 11
    -- if (love.math.random(0, 10)<=5) then -- mutate
    --     son.target_offset = son.target_offset + math.floor(love.math.random(-3, 3))
    -- end

    --run 12
    -- son.target_offset = son.target_offset + math.floor(love.math.random(-4, 4))

    -- run 13
    son.target_offset = love.math.random(-ghost.ghost_target_spread, ghost.ghost_target_spread)

    son.target_offset_freightned = math.floor((mom.target_offset_freightned + dad.target_offset_freightned)/2)
    if (love.math.random(0, 10)<=3) then -- mutate
        son.target_offset_freightned = son.target_offset_freightned + math.floor(love.math.random(-2, 2))
    end

    son.try_order = {} -- we should add mutation

    local this_rand = love.math.random(0, 10)
    if ( this_rand<=3) then
        --print("mom")
        for i= 1, #mom.try_order, 1 do
            --print(mom.try_order[i])
            son.try_order[i] = mom.try_order[i]
            --print(son.try_order[i])
        end
    elseif(this_rand<=5) then
        --print("dad")
        for i= 1, #dad.try_order, 1 do
            --print(dad.try_order[i])
            son.try_order[i] = dad.try_order[i]
            --print(son.try_order[i])
        end
    else
        for i=1, 4, 1 do
            son.try_order[i] = i
        end
        utils.array_shuffler(son.try_order)
    end

    this_rand =  love.math.random(0, 10)
    if ( this_rand<=4) then
        son.chase_feared_gene = mom.chase_feared_gene
    elseif ( this_rand<=8) then
        son.chase_feared_gene = dad.chase_feared_gene
    else
        son.chase_feared_gene = love.math.random(1, 9)
    end

    this_rand =  love.math.random(0, 10)
    if ( this_rand<=4) then
        son.scatter_feared_gene = mom.scatter_feared_gene
    elseif ( this_rand<=8) then
        son.scatter_feared_gene = dad.scatter_feared_gene
    else
        son.scatter_feared_gene = love.math.random(1, 5)
    end

    ghost.reset(value, son.pos_index, son.pilgrin_gene, son.target_offset, son.target_offset_freightned, son.try_order, son.fear_target, son.fear_group, son.chase_feared_gene, son.scatter_feared_gene, ghost.ghost_speed, pills, this_spawn_grid_pos, this_direction)
end

function ghost.reactivate(value, pills, spawn_grid_pos)
    local this_spawn_grid_pos = spawn_grid_pos or value.grid_pos
    ghost.reset(value, value.pos_index, value.pilgrin_gene, value.target_offset, value.target_offset_freightned, value.try_order, value.fear_target, value.fear_group, value.chase_feared_gene, value.scatter_feared_gene, ghost.ghost_speed, pills, this_spawn_grid_pos)
end

function ghost.regen(value, pills, spawn_grid_pos)
    local this_spawn_grid_pos = spawn_grid_pos or value.grid_pos

    local pos_index = love.math.random(1, #grid.grid_valid_pos)

    local pilgrin_gene
    if ( love.math.random(0, 1) == 1) then
        pilgrin_gene = true
    else
        pilgrin_gene = false
    end

    local target_offset = love.math.random(-ghost.ghost_target_spread, ghost.ghost_target_spread)
    local target_offset_freightned = love.math.random(-ghost.ghost_target_spread, ghost.ghost_target_spread)
    -- faz um gene try_order valido
    local try_order = {}
    for i=1, 4, 1 do
        try_order[i] = i
    end
    utils.array_shuffler(try_order)

    local fear_target = love.math.random(0, ghost_fear_spread)
    local fear_group = love.math.random(0, ghost_fear_spread)

    local chase_feared_gene = love.math.random(1, 9)
    local scatter_feared_gene = love.math.random(1, 5)


    ghost.reset(value, pos_index, pilgrin_gene, target_offset, target_offset_freightned, try_order, fear_target, fear_group, chase_feared_gene, scatter_feared_gene, ghost.ghost_speed, pills, this_spawn_grid_pos)
end

function ghost.draw(value, state)
    if ( value.is_active ) then
        if(value.target_offset <= 0)then
            if (value.target_offset == -1) then
                love.graphics.setColor( 0.2, 0.5, 0.8)
            elseif (value.target_offset == -2) then
                love.graphics.setColor( 0.4, 0.5, 0.6)
            elseif (value.target_offset == -3) then
                love.graphics.setColor( 0.6, 0.5, 0.4)
            elseif (value.target_offset == -4) then
                love.graphics.setColor( 0.8, 0.5, 0.2)
            else--if (value.target_offset < -4) then
                love.graphics.setColor( 1, 0.5, 0)
            end
        else
            if (value.target_offset == 1) then
                love.graphics.setColor( 0.5, 0.2, 0.8)
            elseif (value.target_offset == 2) then
                love.graphics.setColor( 0.5, 0.4, 0.6)
            elseif (value.target_offset == 3) then
                love.graphics.setColor( 0.5, 0.6, 0.4)
            elseif (value.target_offset == 4) then
                love.graphics.setColor( 0.5, 0.8, 0.2)
            else--if (value.target_offset > 4) then
                love.graphics.setColor( 0.5, 1, 0)
            end
        end


        --love.graphics.setColor( (1/value.target_offset) + 0.3, 0.5, 0.3)
        love.graphics.circle("fill", value.x, value.y, ghost.grid_size*0.5)

        -- "bando"
        if (value.pos_index < #grid.grid_valid_pos/4 )then
            love.graphics.setColor(1, 1, 1)
        elseif (value.pos_index < (#grid.grid_valid_pos/4)*2 )then
            love.graphics.setColor(0.75, 0, 0.75)
        elseif (value.pos_index < (#grid.grid_valid_pos/4)*3 )then
            love.graphics.setColor(0, 0.5, 0.5)
        else
            love.graphics.setColor(0.05, 0.05, 0.05)
        end

        --love.graphics.circle("fill", value.x , value.y, grid_size*0.3)
        local midle = utils.midle_point(value, value.front)
        local midle_midle = utils.midle_point(value, midle)
        local midle_midle_midle = utils.midle_point(value, midle_midle)
        love.graphics.circle("fill", midle_midle_midle.x, midle_midle_midle.y, ghost.grid_size/4)
        --love.graphics.circle("fill", value.x, value.y, grid_size/6)

        --if ( value.pilgrin_gene ) then
        if ( value.is_feared ) then
            love.graphics.setColor(1, 0, 0)
            love.graphics.circle("fill", midle.x, midle.y, ghost.grid_size/5)
            --love.graphics.line(value.x, value.y, value.front.x, value.front.y)
        end
    end
end

function ghost.update(value, target, pills, average_ghost_pos, dt, state)
    --print(value.fear_group)
    if (value.is_active) then
        value.n_updates = value.n_updates + 1
        value.fitness = value.n_catches + (value.n_pills*0.001)/value.n_updates

        -- atualiza distacia_media do player, poderiamos usar para colisao
        value.dist_to_target = utils.dist(target, value)
        value.dist_to_group = utils.dist(average_ghost_pos, value)

        value.front = grid.get_dynamic_front(value)

        value.is_feared = false
        if( ghost.ghost_fear_on) then
            if (value.dist_to_target < value.fear_target*ghost.grid_size  and
                value.dist_to_group > value.fear_group*ghost.grid_size
                --dist_to_home > 10*ghost.grid_size
                --value.direction == "idle"
                )then
                value.is_feared = true
            end
        end

        local this_grid_pos = grid.get_grid_pos(value)

        --check collision with target
        --print(target.is_active)
        if (target.is_active == true) then
            --if ( value.grid_pos.x == target.grid_pos.x and value.grid_pos.y == target.grid_pos.y) then
            if (value.dist_to_target < ghost.lookahead) then
                if (state~="freightened") then
                    print("you loose, my target is: " .. value.target_offset)
                    last_catcher_target_offset = value.target_offset
                    if(ghost.speed_boost_on) then
                        value.speed_boost = value.speed_boost  + 0.1*ghost.grid_size
                    end
                    value.n_catches = value.n_catches + 1
                    target.is_active = false
                else
                    value.is_active = false
                end
            end
        end

        --check collision with pills
        value.dist_to_closest_pill =  10000*ghost.grid_size -- utils.dist(pills[1], value)
        value.grid_pos_closest_pill = {}
        -- value.grid_pos_closest_pill.x = pills[1].grid_pos.x
        -- value.grid_pos_closest_pill.y = pills[1].grid_pos.y

        --- pills
        for i=1, #pills, 1 do
            if (value.dist_to_closest_pill > utils.dist(pills[i], value) and pills[i].is_active) then
                value.dist_to_closest_pill = utils.dist(pills[i], value)
                value.grid_pos_closest_pill.x = pills[i].grid_pos.x
                value.grid_pos_closest_pill.y = pills[i].grid_pos.y
            end
            local coliding = value.grid_pos.x == pills[i].grid_pos.x and value.grid_pos.y == pills[i].grid_pos.y
            if (  coliding and not value.pill_debounce[i]) then
                value.n_pills = value.n_pills + 1

                if(ghost.speed_boost_on)then
                    value.speed_boost = value.speed_boost  + 0.02*ghost.grid_size
                end



                pills[i].n_ghost_pass = pills[i].n_ghost_pass + 1

                value.pill_debounce[i] = true

            elseif ( not coliding and value.pill_debounce )then
                value.pill_debounce[i] = false
            end
        end
        if ( ghost.ghost_migration_on ) then
            if (ghost_selective_migration_on ) then
                if(pills[ value.home_pill_index ].is_active == false) then
                    value.home.x = value.grid_pos_closest_pill.x
                    value.home.y = value.grid_pos_closest_pill.y
                    value.home_pill_index = i
                end-- else maintain home
            else
                value.home.x = value.grid_pos_closest_pill.x
                value.home.y = value.grid_pos_closest_pill.y
                value.home_pill_index = i
            end
        end

        -- check collision with wall
        local front_grid_pos = grid.get_grid_pos(value.front)
        if(grid.is_grid_wall(front_grid_pos.x, front_grid_pos.y)) then
            value.direction = "idle"
            value.next_direction = "idle"
            grid.center_on_grid(value)
        end

        --on change tile
        if (this_grid_pos.x ~= value.grid_pos.x or this_grid_pos.y ~= value.grid_pos.y ) then
            value.last_grid_pos = value.grid_pos
            value.grid_pos = this_grid_pos
        end

        --on tile center, or close
        local dist_grid_center = utils.dist( grid.get_grid_center(value), value)
        if (dist_grid_center < ghost.lookahead/8) then
            if ( value.direction == "up" or value.direction== "down") then
                grid.center_on_grid_x(value)
            elseif ( value.direction == "left" or value.direction== "right") then
                grid.center_on_grid_y(value)
            end
            ghost.find_next_dir(value, target, state, average_ghost_pos)
        end

        -- checa se o fantasma excedeu a velocidade maxima
        -- caso tenha excedido ele a limita usand this_speed, mas mantem o valor de value.speed para calcular o fitness
        local this_speed = value.speed + value.speed_boost
        if ( (this_speed) > (ghost.ghost_speed_max_factor * ghost.ghost_speed) ) then
            this_speed = ghost.ghost_speed_max_factor * ghost.ghost_speed
        end
        --print(this_speed)
        if value.direction ~= "idle" then
            --print("X: ", value.x, "Y:", value.y)
            if value.direction == "up" then value.y = value.y - dt*this_speed
            elseif value.direction == "down" then value.y = value.y +dt*this_speed
            elseif value.direction == "left" then value.x = value.x -dt*this_speed
            elseif value.direction == "right" then value.x = value.x +dt*this_speed
            end
        end

    end
end

function ghost.find_next_dir(value, target, state, average_ghost_pos)
    value.enabled_dir = grid.get_enabled_directions(value.grid_pos)

    --count = grid.count_enabled_directions(value.grid_pos)
    if ( 	grid.grid_types[value.grid_pos.y][value.grid_pos.x]~=3 and -- invertido
            grid.grid_types[value.grid_pos.y][value.grid_pos.x]~=12 ) then
        --check which one is closer to the target
        -- make a table to contain the posible destinations
        local maybe_dirs = {}

        for i=1, #value.try_order, 1 do
            if (value.enabled_dir[value.try_order[i]]==true ) then --up
                local pos = {}
                if(value.try_order[i]==1) then
                    pos.x = value.grid_pos.x
                    pos.y = value.grid_pos.y -1
                    pos.direction = "up"
                elseif(value.try_order[i]==2) then
                    pos.x = value.grid_pos.x
                    pos.y = value.grid_pos.y +1
                    pos.direction = "down"
                elseif(value.try_order[i]==3) then
                    pos.x = value.grid_pos.x -1
                    pos.y = value.grid_pos.y
                    pos.direction = "left"
                elseif(value.try_order[i]==4) then
                    pos.x = value.grid_pos.x +1
                    pos.y = value.grid_pos.y
                    pos.direction = "right"
                end

                if (pos.x~=value.last_grid_pos.x or pos.y~=value.last_grid_pos.y) then
                    table.insert(maybe_dirs, pos)
                else
                    --print("skipped")
                end
            end
        end

        if( #maybe_dirs == 0) then
            print("maybe_dirs cant be empty")
            for e=1, #value.try_order, 1 do
                print(value.try_order[e])
            end
        end

        -- calculate the destination, get the targets grid position and "sum" it with the value.target_offset
        local destination = {}
        --print( state)

        if (target.is_active) then

            --io.output()
            if ( state == "chasing" ) then
                if(value.fear)then
                    if(ghost.ghost_chase_feared_gene_on)then
                        if(value.chase_feared_gene == 1)then
                            ghost.go_home(value, maybe_dirs)
                        elseif(value.chase_feared_gene == 2)then
                            ghost.go_to_closest_pill(value, maybe_dirs)
                        elseif(value.chase_feared_gene == 3)then
                            ghost.go_to_group(value, maybe_dirs, average_ghost_pos)
                        elseif(value.chase_feared_gene == 4)then
                            ghost.run_from_target(value, target, maybe_dirs)
                        elseif(value.chase_feared_gene == 5)then
                            ghost.wander(value, maybe_dirs)
                        elseif(value.chase_feared_gene == 6)then
                            ghost.go_to_target(value, target, maybe_dirs)
                        elseif(value.chase_feared_gene == 7)then
                            ghost.catch_target(value,target,maybe_dirs)
                        elseif(value.chase_feared_gene == 8)then
                            ghost.surround_target_back(value,target,maybe_dirs)
                        elseif(value.chase_feared_gene == 9)then
                            ghost.surround_target_front(value, target, maybe_dirs)
                        end
                    else
                        ghost.go_home(value, maybe_dirs)
                    end
                else
                    ghost.go_to_target(value, target, maybe_dirs)
                end
            elseif ( state == "scattering") then
                if(value.fear)then
                    --print("feared")
                    if ( not ghost.target_offset_freightned_on ) then
                        value.target_offset_freightned = value.target_offset
                    end
                    if( ghost.ghost_scatter_feared_gene_on ) then
                        if(value.scatter_feared_gene == 1)then
                            ghost.go_home(value, maybe_dirs)
                        elseif(value.scatter_feared_gene == 2)then
                            ghost.go_to_closest_pill(value, maybe_dirs)
                        elseif(value.scatter_feared_gene == 3)then
                            ghost.go_to_group(value, maybe_dirs, average_ghost_pos)
                        elseif(value.scatter_feared_gene == 4)then
                            ghost.run_from_target(value, target, maybe_dirs)
                        elseif(value.scatter_feared_gene == 5)then
                            ghost.wander(value, maybe_dirs)
                        end
                    else
                        ghost.run_from_target(value, target, maybe_dirs)
                    end

                else
                    --print("not feared")
                    if(ghost.ghost_go_home_on_scatter) then
                        ghost.go_home(value, maybe_dirs)
                    else
                        ghost.wander(value, maybe_dirs)
                    end
                end

            elseif ( state == "freightened") then
                if ( not ghost.target_offset_freightned_on ) then
                    value.target_offset_freightned = value.target_offset
                end
                ghost.wander(value, maybe_dirs)
                --ghost.run_from_target(value, target, maybe_dirs)
                --ghost.go_home(value, maybe_dirs)
                -- ghost.go_to_closest_pill(value, maybe_dirs)
            else
                print("error, invalid ghost_state")
            end
        else
            ghost.wander(value, maybe_dirs)
        end


    end
end

---------------------------------------------------------------

function ghost.catch_target(value, target, maybe_dirs)
    local destination = {}

    destination.x = target.grid_pos.x
    destination.y = target.grid_pos.y

    ghost.get_closest( value, maybe_dirs, destination)
end

function ghost.go_to_target(value, target, maybe_dirs)
    local destination = {}

    if (target.direction == "up") then
        destination.x =  target.grid_pos.x
        destination.y = -value.target_offset + target.grid_pos.y
    elseif (target.direction == "down") then
        destination.x = target.grid_pos.x
        destination.y = value.target_offset + target.grid_pos.y
    elseif (target.direction == "left") then
        destination.x = -value.target_offset + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "right") then
        destination.x = value.target_offset + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "idle") then
        destination.x = target.grid_pos.x
        destination.y = target.grid_pos.y
    end

    ghost.get_closest( value, maybe_dirs, destination)
end

function ghost.surround_target_front(value, target, maybe_dirs)
    local destination = {}

    if (target.direction == "up") then
        destination.x =  target.grid_pos.x
        destination.y = -4 + target.grid_pos.y
    elseif (target.direction == "down") then
        destination.x = target.grid_pos.x
        destination.y = 4 + target.grid_pos.y
    elseif (target.direction == "left") then
        destination.x = -4 + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "right") then
        destination.x = 4 + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "idle") then
        destination.x = target.grid_pos.x
        destination.y = target.grid_pos.y
    end

    ghost.get_closest( value, maybe_dirs, destination)
end

function ghost.surround_target_back(value, target, maybe_dirs)
    local destination = {}

    if (target.direction == "up") then
        destination.x =  target.grid_pos.x
        destination.y = 4 + target.grid_pos.y
    elseif (target.direction == "down") then
        destination.x = target.grid_pos.x
        destination.y = -4 + target.grid_pos.y
    elseif (target.direction == "left") then
        destination.x = 4 + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "right") then
        destination.x = -4 + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "idle") then
        destination.x = target.grid_pos.x
        destination.y = target.grid_pos.y
    end

    ghost.get_closest( value, maybe_dirs, destination)
end

function ghost.wander(value, maybe_dirs)
    local destination = {}
    local rand_grid = love.math.random(1, #grid.grid_valid_pos )
    local this_grid_pos = grid.grid_valid_pos[rand_grid]

    destination.x = this_grid_pos.x
    destination.y = this_grid_pos.y

    ghost.get_closest( value, maybe_dirs, destination)
end

function ghost.go_home( value, maybe_dirs)
    local destination = {}
    destination.x = value.home.x
    destination.y = value.home.y

    ghost.get_closest( value, maybe_dirs, destination)
end

function ghost.go_to_group(value, maybe_dirs, average_ghost_pos)
    local this_grid_pos = grid.get_grid_pos(average_ghost_pos)

    local destination = {}
    destination.x =  this_grid_pos.x
    destination.y =  this_grid_pos.y

    ghost.get_closest( value, maybe_dirs, destination)
end


function ghost.run_from_target(value, target, maybe_dirs)

    local destination = {}

    if (target.direction == "up") then
        destination.x =  target.grid_pos.x
        destination.y = -value.target_offset + target.grid_pos.y
    elseif (target.direction == "down") then
        destination.x = target.grid_pos.x
        destination.y = value.target_offset + target.grid_pos.y
    elseif (target.direction == "left") then
        destination.x = -value.target_offset + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "right") then
        destination.x = value.target_offset + target.grid_pos.x
        destination.y = target.grid_pos.y
    elseif (target.direction == "idle") then
        destination.x = target.grid_pos.x
        destination.y = target.grid_pos.y
    end

    ghost.get_furthest(value, maybe_dirs, destination)
end

function ghost.go_to_closest_pill(value, maybe_dirs)
    local destination = {}

    destination.x = value.grid_pos_closest_pill.x
    destination.y = value.grid_pos_closest_pill.y

    ghost.get_closest( value, maybe_dirs, destination)
end


function ghost.get_closest( value, maybe_dirs, destination)

    local shortest = 1
    --print(destination.x)
    for i=1, #maybe_dirs, 1 do
        maybe_dirs[i].dist = utils.dist(maybe_dirs[i], destination)
        if ( maybe_dirs[i].dist < maybe_dirs[shortest].dist ) then
            shortest = i
            --print(#maybe_dirs)
        end
    end
    value.direction = maybe_dirs[shortest].direction
end

function ghost.get_furthest(value, maybe_dirs, destination)
    local furthest = 1
    for i=1, #maybe_dirs, 1 do
        maybe_dirs[i].dist = utils.dist(maybe_dirs[i], destination)
        if ( maybe_dirs[i].dist > maybe_dirs[furthest].dist ) then
            furthest = i
        end
    end
    --print("furthest" .. furthest)
    value.direction = maybe_dirs[furthest].direction
end

function ghost.flip_direction(value)
    if (value == nil) then return end
    if(value.direction == "up") then value.direction = "down"
    elseif(value.direction == "down") then value.direction = "up"
    elseif(value.direction == "left") then value.direction = "right"
    elseif(value.direction == "right") then value.direction = "left" end
end

return ghost
