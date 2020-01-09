-- Guilherme Cunha Prada 2019

local resizer = {}

resizer.offset_x = 0
resizer.offset_y = 0
--resizer.grid_size = 0
resizer.default_size = 0

function resizer.draw_fix()
    love.graphics.translate( resizer.offset_x, resizer.offset_y)
	--love.graphics.scale(resizer.scale_x, resizer.scale_y )
end

function resizer.init_resizer( width, height, grid_width_n, grid_height_n )
    local aspect_ratio = grid_width_n/grid_height_n
    local screen_ratio = width/height
    local grid_size = 0
    --print(screen_ratio)
    --print(aspect_ratio)

    if (screen_ratio > aspect_ratio) then -- wider, limited by height
        --print("wider")
        local max_width = height * aspect_ratio
        --grid_size = height/grid_height_n --limited by height
        grid_size = math.floor(max_width/grid_width_n)
        resizer.offset_y = (height - grid_height_n*grid_size)/2
        resizer.offset_x = (width - grid_width_n*grid_size)/2
        --print(resizer.offset_x .. " " .. resizer.offset_y)
        --print(height .. " " .. grid_height_n*grid_size )
    elseif (screen_ratio < aspect_ratio) then-- taller, limited by width
        --print("thes")
        local max_height = width / aspect_ratio
        grid_size = math.floor(max_height/grid_height_n)
        resizer.offset_y = (height - grid_height_n*grid_size)/2
        resizer.offset_x = (width - grid_width_n*grid_size)/2
        --print(resizer.offset_x .. " " .. resizer.offset_y)
        --print(width .. " " .. grid_width_n*grid_size )
    else -- the same
        grid_size = math.floor(width/ grid_width_n)
        resizer.offset_x = 0
        resizer.offset_y = 0
        --print(height .. " " .. max_height)
    end
    return grid_size
end

return resizer
