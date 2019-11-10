-- Guilherme Cunha Prada 2019

local grid = require "grid"
local player = {}

player.grid_size = 0
--player.lookahead = 0

function player.init(grid_size)
    player.grid_size = grid_size
    --player.lookahead = lookahead

    player.plip_sound = love.audio.newSource("plip.wav", "static")
    player.plip_sound:setVolume(0.3)
    player.plip_sound:setPitch(0.9)
end

function player.new(grid_pos, speed)
    local value = {}
    value.grid_pos = {}
    value.enabled = {}
    value.last_grid_pos = {}
    value.front = {}

    player.reset(value, grid_pos, speed)
    return value
end

function player.draw(value)
    --player body :)
    if (value.is_active) then
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", value.x, value.y, player.grid_size*0.55)

        -- front dot
        love.graphics.setColor(1, 0, 1)
        --love.graphics.setColor(138/255,43/255,226/255, 0.9)
        love.graphics.circle("fill", value.front.x, value.front.y, player.grid_size/5)
        -- front line, mesma cor
        -- love.graphics.setColor(1, 0, 1)
        love.graphics.line(value.x, value.y, value.front.x, value.front.y)
    end
end

function player.reset (value, grid_pos, speed)
    value.is_active = true
    value.speed = speed
    value.direction = "idle"
    value.next_direction = "idle"

    value.grid_pos.x = grid_pos.x
    value.grid_pos.y = grid_pos.y

    local pos = grid.get_grid_center(value)
    value.x = pos.x
    value.y = pos.y

 -- so it enters the first on tile change
    value.last_grid_pos.x = -1
    value.last_grid_pos.y = -1

    value.front = grid.get_dynamic_front(value)
    value.relay_x_counter = 0
    value.relay_y_counter = 0
    value.relay_x = 0
    value.relay_y = 0
    value.relay_times = 3 -- controls how many gameloops it takes to relay
end

function player.update(value, dt)
    -- --speed*dt, which is the distance travelled cant be bigger than the tile
    -- --grid_size*1.5 or the physics wont work
    -- if player.speed*dt > grid_size*1.5 then
    --     print("player speed > grid_size", player.speed*dt)
    --     love.event.quit(0)
    -- end
    -- print(value.speed)
    if (value.is_active) then
        if value.direction ~= "idle" then
            --print("X: ", value.x, "Y:", value.y)
            if value.direction == "up" then value.y = value.y -value.speed*dt
            elseif value.direction == "down" then value.y = value.y +value.speed*dt
            elseif value.direction == "left" then value.x = value.x -value.speed*dt
            elseif value.direction == "right" then value.x = value.x +value.speed*dt
            end
        end

        -- relays mov for cornering
        if value.relay_x_counter >= 1 then
            value.x = value.x - value.relay_x/value.relay_times
            value.relay_x_counter = value.relay_x_counter -1
            if value.relay_x_counter == 0 then grid.center_on_grid_x(value) end
        end

        if value.relay_y_counter >= 1 then
            value.y = value.y - value.relay_y/value.relay_times
            value.relay_y_counter = value.relay_y_counter -1
            if value.relay_y_counter == 0 then grid.center_on_grid_y(value) end
        end

    	-- update value info
    	value.front = grid.get_dynamic_front(value)
    	value.grid_pos = grid.get_grid_pos(value)

        --on change tile
        --print(value.grid_pos.x, value.grid_pos.y)
        --print(value.last_grid_pos.x, value.last_grid_pos.y)
        if value.grid_pos.x ~= value.last_grid_pos.x or value.grid_pos.y ~= value.last_grid_pos.y then
            value.enabled = grid.get_enabled_directions(value.grid_pos)
    		value.last_grid_pos = value.grid_pos
            player.plip_sound:play()
        end

        -- apply next_direction
        if value.next_direction ~= "idle" then
            local grid_center = grid.get_grid_center(value)
            --print(value.enabled[1], value.enabled[2], value.enabled[3], value.enabled[4])
            if value.next_direction == "up" and value.enabled[1] == true then
                value.direction = value.next_direction
                value.relay_x = value.x - grid_center.x
                value.relay_x_counter = value.relay_times
            elseif value.next_direction == "down" and value.enabled[2] == true then
                value.direction = value.next_direction
                value.relay_x = value.x - grid_center.x
                value.relay_x_counter = value.relay_times
            elseif value.next_direction == "left" and value.enabled[3] == true then
                value.direction = value.next_direction
                value.relay_y = value.y - grid_center.y
                value.relay_y_counter = value.relay_times
            elseif value.next_direction == "right" and value.enabled[4] == true then
                value.direction = value.next_direction
                value.relay_y = value.y - grid_center.y
                value.relay_y_counter = value.relay_times
            end
        end

        -- check collision with wall
    	local front_grid_pos = grid.get_grid_pos(value.front)
    	if(grid.is_grid_wall(front_grid_pos.x, front_grid_pos.y)) then
    		value.direction = "idle"
    		value.next_direction = "idle"
            grid.center_on_grid(value)
    	end

        if (love.keyboard.isDown("left") and love.keyboard.isDown("right") ) then
            --does nothing, but also does not change
    	elseif love.keyboard.isDown("left") then
            value.next_direction = "left"
        elseif love.keyboard.isDown("right") then
    		value.next_direction = "right"
        end

        if (love.keyboard.isDown("up") and love.keyboard.isDown("down") ) then
            --does nothing, but also does not change
    	elseif love.keyboard.isDown("up") then
    		value.next_direction = "up"
        elseif love.keyboard.isDown("down") then
    		value.next_direction = "down"
    	end

    end
end

return player
