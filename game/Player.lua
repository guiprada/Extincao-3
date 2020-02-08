-- Guilherme Cunha Prada 2019

local grid = require "grid"
local Player = {}

function Player.init(grid_size, player_click)
    Player.grid_size = grid_size
    Player.plip_sound = player_click
    Player.plip_sound:setVolume(0.3)
    Player.plip_sound:setPitch(0.9)
end

function Player:new(grid_pos, speed, o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.grid_pos = {}
    o.enabled_directions = {}
    o.last_grid_pos = {}
    o.front = {}

    o:reset(grid_pos, speed)
    return o
end

function Player:reset(grid_pos, speed)
    self.is_active = true
    self.speed = speed
    self.direction = "idle"
    self.next_direction = "idle"

    self.grid_pos.x = grid_pos.x
    self.grid_pos.y = grid_pos.y

    local pos = grid.get_grid_center(self)
    self.x = pos.x
    self.y = pos.y

    -- we set it negative so it enters the first on tile change
    self.last_grid_pos.x = -1
    self.last_grid_pos.y = -1

    self.front = grid.get_dynamic_front(self)
    self.relay_x_counter = 0
    self.relay_y_counter = 0
    self.relay_x = 0
    self.relay_y = 0
    self.relay_times = 3 -- controls how many gameloops it takes to relay
end

function Player:draw()
    --player body :)
    if (self.is_active) then
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", self.x, self.y, Player.grid_size*0.55)

        -- front dot
        love.graphics.setColor(1, 0, 1)
        --love.graphics.setColor(138/255,43/255,226/255, 0.9)
        love.graphics.circle(   "fill",
                                self.front.x,
                                self.front.y,
                                Player.grid_size/5)
        -- front line, mesma cor
        -- love.graphics.setColor(1, 0, 1)
        love.graphics.line(self.x, self.y, self.front.x, self.front.y)
    end
end

function Player:update(dt)
    --speed*dt, which is the distance travelled cant be bigger than the tile
    --grid_size*1.5 or the physics wont work
    if self.speed*dt > Player.grid_size*1.5 then
        print("physics sanity check failed, Player speed > grid_size")
        love.event.quit(0)
    end

    -- print(self.speed)
    if (self.is_active) then
        if self.direction ~= "idle" then
            --print("X: ", self.x, "Y:", self.y)
            if self.direction == "up" then self.y = self.y -self.speed*dt
            elseif self.direction == "down" then self.y = self.y +self.speed*dt
            elseif self.direction == "left" then self.x = self.x -self.speed*dt
            elseif self.direction == "right" then self.x = self.x +self.speed*dt
            end
        end

        -- relays mov for cornering
        if self.relay_x_counter >= 1 then
            self.x = self.x - self.relay_x/self.relay_times
            self.relay_x_counter = self.relay_x_counter -1
            if self.relay_x_counter == 0 then grid.center_on_grid_x(self) end
        end

        if self.relay_y_counter >= 1 then
            self.y = self.y - self.relay_y/self.relay_times
            self.relay_y_counter = self.relay_y_counter -1
            if self.relay_y_counter == 0 then grid.center_on_grid_y(self) end
        end

    	-- update o info
    	self.front = grid.get_dynamic_front(self)
    	self.grid_pos = grid.get_grid_pos(self)

        --on change tile
        if  self.grid_pos.x ~= self.last_grid_pos.x or
            self.grid_pos.y ~= self.last_grid_pos.y then

            self.enabled_directions = grid.get_enabled_directions(self.grid_pos)
    		self.last_grid_pos = self.grid_pos
            Player.plip_sound:play()
        end

        -- apply next_direction
        if self.next_direction ~= "idle" then
            local grid_center = grid.get_grid_center(self)

            if  self.next_direction == "up" and
                self.enabled_directions[1] == true then

                self.direction = self.next_direction
                self.relay_x = self.x - grid_center.x
                self.relay_x_counter = self.relay_times
            elseif  self.next_direction == "down" and
                    self.enabled_directions[2] == true then

                self.direction = self.next_direction
                self.relay_x = self.x - grid_center.x
                self.relay_x_counter = self.relay_times
            elseif  self.next_direction == "left" and
                    self.enabled_directions[3] == true then

                self.direction = self.next_direction
                self.relay_y = self.y - grid_center.y
                self.relay_y_counter = self.relay_times
            elseif  self.next_direction == "right" and
                    self.enabled_directions[4] == true then

                self.direction = self.next_direction
                self.relay_y = self.y - grid_center.y
                self.relay_y_counter = self.relay_times
            end
        end

        -- check collision with wall
    	local front_grid_pos = grid.get_grid_pos(self.front)
    	if(grid.is_grid_wall(front_grid_pos.x, front_grid_pos.y)) then
    		self.direction = "idle"
    		self.next_direction = "idle"
            grid.center_on_grid(self)
    	end

        if(love.keyboard.isDown("left") and love.keyboard.isDown("right")) then
        --does nothing, but also does not change

    	elseif love.keyboard.isDown("left") then
            self.next_direction = "left"
        elseif love.keyboard.isDown("right") then
    		self.next_direction = "right"
        end

        if(love.keyboard.isDown("up") and love.keyboard.isDown("down")) then
        --does nothing, but also does not change
    	elseif love.keyboard.isDown("up") then
    		self.next_direction = "up"
        elseif love.keyboard.isDown("down") then
    		self.next_direction = "down"
    	end
    end
end

return Player
