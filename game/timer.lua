-- Guilherme Cunha Prada 2020

local timer = {}

function timer.new(reset_time)
    local value = {}
    value.reset_time = reset_time
    value.timer = 0
    timer.reset(value)
    return value
end

function timer.update(value, dt)
    value.timer = value.timer - dt
    if (value.timer <= 0) then
        timer.reset(value)
        return true
    end
    return false
end

function timer.reset(value, new_time)
    local time = new_time or value.reset_time
    value.timer = time
end

return timer
