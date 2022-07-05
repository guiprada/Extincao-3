-- Guilherme Cunha Prada 2020

local Grid = {}

function Grid:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.grid_width_n = 0
	o.grid_height_n = 0

	o.grid_size = 0
	o.lookahead = 0
	o.grid_types = {}
	o.enabled_directions = {}
	o.grid_directions = {}

	return o
end

function Grid.get_width(grid_types)
	return #grid_types[1]
end

function Grid.get_height(grid_types)
	return #grid_types
end

function Grid:reset(grid_types, grid_size, lookahead)
	self.grid_types = grid_types or grid.defalt_map

	self.grid_width_n = #self.grid_types[1]
	self.grid_height_n = #self.grid_types

	self.grid_size = grid_size
	self.lookahead = lookahead
	self:generate_directions()
	self:generate_valid_pos()
end

function Grid:generate_directions()
	-- this matrix defines the map, it stores the tile type
	-- there are 16 variations! so we are goig to encode then with a number between
	-- 1 and 16 , we can get then with bits
	-- each bit representing an enabled direction in the order
	-- up, down, left, right

	-- grid.grid_directions matrix is defined dinamicaly based on grid_types
	-- it stores the enabled movements for each cell

	self.grid_directions = {}

	for i=1,self.grid_width_n do
		self.grid_directions[i] = {}
		for j=1,self.grid_height_n do
			--print("logging")
			local tile_type = self.grid_types[j][i] -- inverted
			-- matrix is  [pos_x][pos_y]

			if tile_type == 0 or tile_type == 16 then
				self.grid_directions[i][j] =  {false, false, false, false}
			elseif tile_type == 3 then
				self.grid_directions[i][j] =  {false, false, true, true}
			elseif tile_type == 5 then
				self.grid_directions[i][j] =  {false, true, false, true}
			elseif tile_type == 6 then
				self.grid_directions[i][j] =  {false, true, true, false}
			elseif tile_type == 7 then
				self.grid_directions[i][j] =  {false, true, true, true}
			elseif tile_type == 9 then
				self.grid_directions[i][j] =  {true, false, false, true}
			elseif tile_type == 10 then
				self.grid_directions[i][j] =  {true, false, true, false}
			elseif tile_type == 11 then
				self.grid_directions[i][j] =  {true, false, true, true}
			elseif tile_type == 12 then
				self.grid_directions[i][j] =  {true, true, false, false}
			elseif tile_type == 13 then
				self.grid_directions[i][j] =  {true, true, false, true}
			elseif tile_type == 14 then
				self.grid_directions[i][j] =  {true, true, true, false}
			elseif tile_type == 15 then
				self.grid_directions[i][j] =  {true, true, true, true}
			else
				self.grid_directions[i][j] =  {false, false, false, false}
			end
		end
	end
end

function Grid:generate_valid_pos()
	self.valid_pos = {}
	for i=1, self.grid_width_n do
		for j=1,self.grid_height_n do
			if (self.grid_types[j][i]~= 16 and self.grid_types[j][i]~= 0 and (j<=15 or j>=30)) then
				local value = {}
				value.x = i
				value.y = j
				table.insert(self.valid_pos, value)
			end
		end
	end
end

function Grid:get_grid_center(grid_pos)
	-- returns the center of the grid that obj lays
	local center = {}
	center.x = (grid_pos.x-1)*self.grid_size + math.ceil(self.grid_size/2)
	center.y = (grid_pos.y-1)*self.grid_size + math.ceil(self.grid_size/2)
	return center
end

function Grid:center_on_grid(pos)
	-- centers obj on its own grid cell
	local grid_pos = self:get_grid_pos(pos)
	pos.x = (grid_pos.x-1)*self.grid_size + math.ceil(self.grid_size/2)
	pos.y = (grid_pos.y-1)*self.grid_size + math.ceil(self.grid_size/2)
end

function Grid:center_on_grid_x(pos)
	-- centers obj on its own grid cell x axis
	local grid_pos = self:get_grid_pos(pos)
	pos.x = (grid_pos.x-1)*self.grid_size + math.ceil(self.grid_size/2)
end

function Grid:center_on_grid_y(pos)
	-- centers obj on its own grid cell y axis
	local grid_pos = self:get_grid_pos(pos)
	pos.y = (grid_pos.y-1)*self.grid_size + math.ceil(self.grid_size/2)
end

-- DELETE
function Grid:get_dynamic_front(obj)
	-- returns the point that is lookahead in front of the player
	-- it does consider the direction obj is set

	local point = {}
	-- the player has a dynamic center
	if obj.direction == "up" then
		point.y = obj.y - self.lookahead
 		point.x = obj.x
	elseif obj.direction == "down" then
		point.y = obj.y + self.lookahead
		point.x = obj.x
	elseif obj.direction == "left" then
		point.x = obj.x - self.lookahead
		point.y = obj.y
	elseif obj.direction == "right" then
		point.x = obj.x + self.lookahead
		point.y = obj.y
	else
		point.y = obj.y
		point.x = obj.x
	end
	return point
end

function Grid:get_grid_pos(pos)
	local grid_pos = {}

	grid_pos.x = math.floor(pos.x / self.grid_size) + 1--lua arrays start at 1
	grid_pos.y = math.floor(pos.y / self.grid_size) + 1 --lua arrays start at 1
	return grid_pos
end

function Grid:is_grid_wall(pos)
	if 	self.grid_types[pos.y][pos.x] == 16 or
	 	self.grid_types[pos.y][pos.x] == 0 then	return true end
	return false
end

function Grid:is_grid_way(x, y)
	if 	self.grid_types[y][x] ~= 16 and
		self.grid_types[y][x] ~= 0 then return true end
	return false
end

function Grid:is_corridorX(pos)
	if self.grid_types[pos.y][pos.x] == 3 then return true end
	return false
end

function Grid:is_corridorY(pos)
	if self.grid_types[pos.y][pos.x] == 12 then return true end
	return false
end

function Grid:is_corridor(pos)
	if ( self.grid_types[pos.y][pos.x] == 12 or self.grid_types[pos.y][pos.x] == 3 )then
		return true
	end
	return false
end

function Grid:count_enabled_directions(pos)
	local count = 0
	local value = {}
	value = self.grid_directions[pos.x][pos.y]
	for i=1, #value, 1 do
		if (value[i] == true) then
			count = count + 1
		end
	end
	return count
end

function Grid:get_enabled_directions(grid_pos)
	local value = {}
	value = self.grid_directions[grid_pos.x][grid_pos.y]
	return value
end

Grid.defalt_map = 	{	-- 1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31  32  33  34  35  36  37  38  39  40  41  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56
						{ 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 }, --1
						{ 16,  5,  3,  3,  3,  3,  7,  3,  3,  3,  3,  3,  6, 16, 16,  5,  3,  3,  3,  3,  3,  7,  3,  3,  3,  3,  7,  3,  3,  7,  3,  3,  3,  3,  7,  3,  3,  3,  3,  3,  6, 16, 16,  5,  3,  3,  3,  3,  3,  7,  3,  3,  3,  3,  6, 16 }, --2
						{ 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16 }, --3
						{ 16, 12, 16,  0,  0, 16, 12, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0,  0, 16, 12, 16,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0, 16, 12, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0,  0, 16, 12, 16,  0,  0, 16, 12, 16 }, --4
						{ 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16 }, --5
						{ 16, 13,  3,  3,  3,  3, 15,  3,  3,  7,  3,  3, 11,  3,  3, 11,  3,  3,  7,  3,  3, 15,  3,  3,  3,  3, 14, 16, 16, 13,  3,  3,  3,  3, 15,  3,  3,  7,  3,  3, 11,  3,  3, 11,  3,  3,  7,  3,  3, 15,  3,  3,  3,  3, 14, 16 }, --6
						{ 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16 }, --7
						{ 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16 }, --8
						{ 16,  9,  3,  3,  3,  3, 14, 16, 16,  9,  3,  3,  6, 16, 16,  5,  3,  3, 10, 16, 16, 13,  3,  3,  3,  3, 11,  3,  3, 11,  3,  3,  3,  3, 14, 16, 16,  9,  3,  3,  6, 16, 16,  5,  3,  3, 10, 16, 16, 13,  3,  3,  3,  3, 10, 16 }, --9
						{ 16, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 16 }, --10
						{ 16, 16, 16, 16,  0, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16,  0, 16 }, --11
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16,  5,  3,  3, 11,  3,  3, 11,  3,  3,  6, 16, 16, 13,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 14, 16, 16,  5,  3,  3, 11,  3,  3, 11,  3,  3,  6, 16, 16, 12, 16, 16,  0,  0,  0, 16 }, --12
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16,  0,  0,  0, 16 }, --13
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0,  0,  0,  0,  0, 16, 12, 16, 16, 12, 16,  0, 16, 16, 16, 16, 16, 16, 16, 16,  0, 16, 12, 16, 16, 12, 16,  0,  0,  0,  0,  0,  0, 16, 12, 16, 16, 12, 16, 16,  0,  0,  0, 16 }, --14
						{ 16, 16, 16,  0,  0, 16, 13,  3,  3, 14, 16,  0,  0,  0,  0,  0,  0, 16, 13,  3,  3, 14, 16,  0,  0,  0,  0, 16, 16,  0,  0,  0,  0, 16, 13,  3,  3, 14, 16, 16, 16, 16, 16,  0,  0, 16, 13,  3,  3, 14, 16, 16,  0,  0,  0, 16 }, --15
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0, 16, 16,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0,  0,  0, 16, 16,  0,  0,  0,  0, 16, 12, 16, 16, 12, 16,  0,  0,  0,  0,  0,  0, 16, 12, 16, 16, 12, 16, 16,  0,  0,  0, 16 }, --16
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16,  0,  0,  0, 16 }, --17
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16, 13,  3,  3,  3,  3,  3,  3,  3,  3, 14, 16, 16, 13,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 14, 16, 16, 13,  3,  3,  3,  3,  3,  3,  3,  3, 14, 16, 16, 12, 16, 16,  0,  0,  0, 16 }, --18
						{ 16, 16,  0,  0,  0, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16,  0, 16 }, --19
						{ 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16 }, --20
						{ 16,  5,  3,  3,  3,  3, 15,  3,  3, 11,  3,  3,  6, 16, 16,  5,  3,  3, 11,  3,  3, 15,  3,  3,  3,  3,  7,  3,  3,  7,  3,  3,  3,  3, 15,  3,  3, 11,  3,  3,  6, 16, 16,  5,  3,  3, 11,  3,  3, 15,  3,  3,  3,  3,  6, 16 }, --21
						{ 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16 }, --22
						{ 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 12, 16, 16, 16, 16, 12, 16 }, --23
						{ 16,  9,  3,  6, 16, 16, 13,  3,  3,  7,  3,  3, 11,  3,  3, 11,  3,  3,  7,  3,  3, 14, 16, 16,  5,  3, 10, 16, 16,  9,  3,  6, 16, 16, 13,  3,  3,  7,  3,  3, 11,  3,  3, 11,  3,  3,  7,  3,  3, 14, 16, 16,  5,  3, 10, 16 }, --24
						{ 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16 }, --25
						{ 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 12, 16, 16, 16 }, --26
						{ 16,  5,  3, 11,  3,  3, 10, 16, 16,  9,  3,  3,  6, 16, 16,  5,  3,  3, 10, 16, 16,  9,  3,  3, 11,  3,  6, 16, 16,  5,  3, 11,  3,  3, 10, 16, 16,  9,  3,  3,  6, 16, 16,  5,  3,  3, 10, 16, 16,  9,  3,  3, 11,  3,  6, 16 }, --27
						{ 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16 }, --28
						{ 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16, 16, 12, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 12, 16 }, --29
						{ 16,  9,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 11,  3,  3, 11,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 11,  3,  3, 11,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 11,  3,  3, 11,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3, 10, 16 }, --61
						{ 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 }, --62
				  	}


return Grid
