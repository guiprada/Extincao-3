-- Guilherme Cunha Prada 2020
local GridActor = {}

function GridActor.init(grid)
    GridActor.grid = grid
end

function GridActor:new(o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.grid_pos = {}
    o.enabled_directions = {}
    o.front = {}
    o.last_grid_pos = {}

    o.is_active = true
    o.changed_tile = false
    o.speed = 0
    o.direction = "idle"
    o.next_direction = "idle"

    o.grid_pos.x = 0
    o.grid_pos.y = 0

    o.x = 0
    o.y = 0

    -- we set it negative so it enters the first on tile change
    o.last_grid_pos.x = -1
    o.last_grid_pos.y = -1

    o.front.x = 0
    o.front.y = 0

    return o
end

function GridActor:reset(grid_pos, speed)
    self.is_active = true
    self.changed_tile = false
    self.speed = speed
    self.direction = "idle"
    self.next_direction = "idle"

    self.grid_pos.x = grid_pos.x
    self.grid_pos.y = grid_pos.y

    local pos = self:get_grid_center()
    self.x = pos.x
    self.y = pos.y

    -- we set it negative so it enters the first on tile change
    self.last_grid_pos.x = -1
    self.last_grid_pos.y = -1

    self.front = self:get_dynamic_front()
end

function GridActor:draw()
    if (self.is_active) then
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle(   "fill",
                                self.x,
                                self.y,
                                GridActor.grid.grid_size*0.55)
    end
end

function GridActor:update(dt)
    --speed*dt, which is the distance travelled cant be bigger than the tile
    --grid_size*1.5 or the physics wont work
    if self.speed*dt > GridActor.grid.grid_size*1.5 then
        print("physics sanity check failed, Player speed > grid_size")
        love.event.quit(0)
    end

    -- print(self.speed)
    if (self.is_active) then
        self.changed_tile = false
        if self.direction ~= "idle" then
            --print("X: ", self.x, "Y:", self.y)
            if self.direction == "up" then self.y = self.y -self.speed*dt
            elseif self.direction == "down" then self.y = self.y +self.speed*dt
            elseif self.direction == "left" then self.x = self.x -self.speed*dt
            elseif self.direction == "right" then self.x = self.x +self.speed*dt
            end
        end

    	-- update o info
    	self.front = self:get_dynamic_front()
    	self.grid_pos = self:get_grid_pos()

        --on change tile
        if  self.grid_pos.x ~= self.last_grid_pos.x or
            self.grid_pos.y ~= self.last_grid_pos.y then

            self.changed_tile = true
            self.enabled_directions = self:get_enabled_directions()
    		self.last_grid_pos = self.grid_pos
        end

        -- apply next_direction
        if self.next_direction ~= "idle" then
            local grid_center = self:get_grid_center()

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
    	if(self:is_front_wall()) then
    		self.direction = "idle"
    		self.next_direction = "idle"
            GridActor.grid:center_on_grid(self)
    	end
    end
end

function GridActor:center_on_grid_x()
    GridActor.grid:center_on_grid_x(self)
end

function GridActor:center_on_grid_y()
    GridActor.grid:center_on_grid_y(self)
end

function GridActor:get_grid_center()
    return GridActor.grid:get_grid_center(self)
end

function GridActor:get_dynamic_front()
    return GridActor.grid:get_dynamic_front(self)
end

function GridActor:get_grid_pos()
    return GridActor.grid:get_grid_pos(self)
end

function GridActor:get_front_grid()
    return GridActor.grid:get_grid_pos(self.front)
end

function GridActor:get_enabled_directions()
    return GridActor.grid:get_enabled_directions(self.grid_pos)
end

function GridActor:is_front_wall()
    local front_grid_pos = self:get_front_grid()
    return GridActor.grid:is_grid_wall(front_grid_pos.x, front_grid_pos.y)
end

function  GridActor.get_grid_size()
    return GridActor.grid.grid_size
end

function  GridActor.get_lookahead()
    return GridActor.grid.lookahead
end

return GridActor
