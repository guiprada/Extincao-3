-- Guilherme Cunha Prada 2020
local GridActor = require "GridActor"
local Player = GridActor:new()

function Player.init(grid_size, player_click)
    GridActor.init(grid_size)

    Player.plip_sound = player_click
    Player.plip_sound:setVolume(0.3)
    Player.plip_sound:setPitch(0.9)
end

function Player:new(o)
    local o = GridActor:new(o or {})
    setmetatable(o, self)
    self.__index = self

    -- new vars
    o.relay_x_counter = 0
    o.relay_y_counter = 0
    o.relay_x = 0
    o.relay_y = 0
    o.relay_times = 3 -- controls how many gameloops it takes to relay

    return o
end

function Player:reset(grid_pos, speed)
    GridActor.reset(self, grid_pos, speed)

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
        love.graphics.circle("fill", self.x, self.y, GridActor.grid_size*0.55)

        -- front dot
        love.graphics.setColor(1, 0, 1)
        --love.graphics.setColor(138/255,43/255,226/255, 0.9)
        love.graphics.circle(   "fill",
                                self.front.x,
                                self.front.y,
                                GridActor.grid_size/5)
        -- front line, mesma cor
        -- love.graphics.setColor(1, 0, 1)
        love.graphics.line(self.x, self.y, self.front.x, self.front.y)
    end
end

function Player:update(dt)
    if (self.is_active) then
        GridActor.update(self,dt)
        -- relays mov for cornering
        if self.relay_x_counter >= 1 then
            self.x = self.x - self.relay_x/self.relay_times
            self.relay_x_counter = self.relay_x_counter -1
            if self.relay_x_counter == 0 then self:center_on_grid_x() end
        end

        if self.relay_y_counter >= 1 then
            self.y = self.y - self.relay_y/self.relay_times
            self.relay_y_counter = self.relay_y_counter -1
            if self.relay_y_counter == 0 then self:center_on_grid_y() end
        end

        if self.changed_tile == true then
            Player.plip_sound:play()
        end
    end
end

return Player
