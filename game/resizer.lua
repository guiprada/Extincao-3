-- Guilherme Cunha Prada 2020

local resizer = {}

resizer.offset_x = 0
resizer.offset_y = 0

function resizer.draw_fix()
    love.graphics.translate( resizer.offset_x, resizer.offset_y)
end

function resizer.init_resizer( width, height, grid_width_n, grid_height_n )
    local aspect_ratio = grid_width_n/grid_height_n
    local screen_ratio = width/height
    local grid_size = 0

    if (screen_ratio > aspect_ratio) then -- wider, limited by height
        local max_width = height * aspect_ratio
        grid_size = math.floor(max_width/grid_width_n)
        resizer.offset_y = (height - grid_height_n*grid_size)/2
        resizer.offset_x = (width - grid_width_n*grid_size)/2
    elseif (screen_ratio < aspect_ratio) then-- taller, limited by width
        local max_height = width / aspect_ratio
        grid_size = math.floor(max_height/grid_height_n)
        resizer.offset_y = (height - grid_height_n*grid_size)/2
        resizer.offset_x = (width - grid_width_n*grid_size)/2
    else -- the same
        grid_size = math.floor(width/ grid_width_n)
        resizer.offset_x = 0
        resizer.offset_y = 0
    end
    return grid_size
end

return resizer
