-- Guilherme Cunha Prada 2019

local utils = require "utils"
local random = require "random"
local GridActor = require "GridActor"

local ghost_type_name = "ghost"
local Ghost = {}

Ghost.state = "none"

function Ghost.set_state(new_state)
	Ghost.state = new_state
end

function Ghost.init(Grid,
					ghost_fitness_on,
					ghost_target_spread,
					ghost_migration_on,
					ghost_selective_migration_on,
					ghost_speed, speed_boost_on,
					ghost_speed_max_factor,
					ghost_fear_on,
					ghost_go_home_on_scatter,
					ghost_chase_feared_gene_on,
					ghost_scatter_feared_gene_on,
					grid_size,
					lookahead,
					initial_state)
	Ghost.grid = Grid
	Ghost.ghost_fitness_on = ghost_fitness_on
	Ghost.ghost_target_spread = ghost_target_spread
	Ghost.ghost_migration_on = ghost_migration_on
	Ghost.ghost_selective_migration_on = ghost_selective_migration_on
	Ghost.ghost_speed = ghost_speed
	Ghost.speed_boost_on = speed_boost_on
	Ghost.ghost_speed_max_factor = ghost_speed_max_factor
	Ghost.ghost_fear_on = ghost_fear_on
	Ghost.ghost_go_home_on_scatter = ghost_go_home_on_scatter
	Ghost.ghost_scatter_feared_gene_on = ghost_scatter_feared_gene_on
	Ghost.ghost_chase_feared_gene_on = ghost_chase_feared_gene_on
	Ghost.grid_size = grid_size
	Ghost.lookahead = lookahead
	Ghost.set_state(initial_state)

	GridActor.register_type(ghost_type_name)
end

function Ghost:new( pos_index,
					target_offset,
					try_order,
					fear_target,
					fear_group,
					chase_feared_gene,
					scatter_feared_gene,
					speed,
					pills,
					o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self

	o.grid_pos = {}
	o.pill_debounce = {}
	o.home = {} -- determined by pos_index, it is a phenotype
	o.try_order = {} -- gene

	o.enabled_dir = {}
	o.last_grid_pos = {}
	o.front = {}
	o._type = GridActor.get_type_by_name(ghost_type_name)
	o:reset(pos_index,
			target_offset,
			try_order,
			fear_target,
			fear_group,
			chase_feared_gene,
			scatter_feared_gene,
			speed,
			pills)

	return  o
end

function Ghost:reset(   pos_index,
						target_offset,
						try_order,
						fear_target,
						fear_group,
						chase_feared_gene,
						scatter_feared_gene,
						speed,
						pills,
						spawn_grid_pos,
						direction)
	self.is_active = true
	self.n_updates = 0
	self.n_chase_updates = 0
	self.n_freightened_updates = 0
	self.acc_chase_dist = 0
	self.acc_freightened_dist = 0
	self.n_catches = 0
	self.n_pills = 0
	self.fitness = 0

	self.home_pill_index = 0
	self.speed_boost = 0
	self.dist_to_group = 0
	self.dist_to_target = 0
	self.is_feared = false

	self.target_offset = target_offset
	self.fear_target = fear_target
	self.fear_group = fear_group
	self.chase_feared_gene = chase_feared_gene
	self.scatter_feared_gene = scatter_feared_gene


	for i=1, #pills, 1 do
		self.pill_debounce[i] = false
	end

	self.speed = speed

	local valid_grid_pos = Ghost.grid.valid_pos[pos_index]
	self.pos_index = pos_index
	self.home.x = valid_grid_pos.x
	self.home.y = valid_grid_pos.y

	local this_spawn_grid_pos = spawn_grid_pos or self.home
	self.grid_pos.x = this_spawn_grid_pos.x
	self.grid_pos.y = this_spawn_grid_pos.y

	local this_pos = Ghost.grid:get_grid_center(self.grid_pos)
	self.x = this_pos.x
	self.y = this_pos.y

	self.home.x = self.grid_pos.x
	self.home.y = self.grid_pos.y

	-- choose initial direction
	self.enabled_dir = Ghost.grid:get_enabled_directions(self.grid_pos)

	--self.try_order = {}
	-- dont destroy the old one, it is used by Ghost.highest_fitness_genome
	self.try_order[1] = try_order[1]
	self.try_order[2] = try_order[2]
	self.try_order[3] = try_order[3]
	self.try_order[4] = try_order[4]

	-- finds a valid direction
	if(not direction) then
		for i=1, #self.try_order, 1 do
			if ( self.enabled_dir[self.try_order[i]] == true) then
				if(self.try_order[i]==1) then
					self.direction = "up"
				elseif(self.try_order[i]==2) then
					self.direction = "down"
				elseif(self.try_order[i]==3) then
					self.direction = "left"
				elseif(self.try_order[i]==4) then
					self.direction = "right"
				end
			end
		end
	else
		self.direction = direction
	end

	self.last_grid_pos.x = -1
	self.last_grid_pos.y = -1


	self.front = Ghost.grid:get_dynamic_front(self)
end

function Ghost:is_type(type_name)
	if type_name == ghost_type_name then
		return true
	else
		return false
	end
end

function Ghost.selection(in_table)
		--find the living
	local living_stack = {}
	for i=1, #in_table, 1 do
		if in_table[i].is_active == true then
			table.insert(living_stack, in_table[i])
		end
	end

	local mom = {}
	local dad = {}
	if (Ghost.ghost_fitness_on) then
		local best_stack = utils.get_n_best(living_stack,
											"fitness",
											math.ceil(#living_stack/2))
		mom = best_stack[random.random(1, #best_stack)]
		dad = living_stack[random.random(1, #living_stack)]
	else
		mom = living_stack[random.random(1, #living_stack)]
		dad = living_stack[random.random(1, #living_stack)]
	end

	return mom, dad
end

function Ghost:crossover(ghosts, pills, spawn_grid_pos)
	local mom = {}
	local dad = {}
	mom, dad = Ghost.selection(ghosts)

	local son = {}
	son.fear_target =  math.floor(
		(mom.fear_target + dad.fear_target)/2 + random.random(-5, 5)
	)
	son.fear_group = math.floor(
		(mom.fear_group + dad.fear_group)/2 + random.random(-5, 5)
	)

	if (son.fear_target > 50) then
		son.fear_target = 50
	elseif (son.fear_target < 0) then
		son.fear_target = 0
	end

	if (son.fear_group > 50) then
		son.fear_group = 50
	elseif (son.fear_group < 0) then
		son.fear_group = 0
	end

	local this_spawn_grid_pos = {}
	local this_direction
	if spawn_grid_pos then
		this_spawn_grid_pos = spawn_grid_pos
		this_direction = random.choose("up", "down", "left", "right")
	else -- nasce com a mae
		this_spawn_grid_pos.x = mom.grid_pos.x
		this_spawn_grid_pos.y = mom.grid_pos.y
		this_direction = mom.direction
	end

	son.pos_index = math.floor((mom.pos_index + dad.pos_index)/2)
	if (random.random(0, 10) <= 9) then -- mutate
		son.pos_index = son.pos_index + math.floor(random.random(-50, 50))
		if (son.pos_index < 1) then
			son.pos_index = 1
		elseif (son.pos_index > #Ghost.grid.valid_pos) then
			son.pos_index = #Ghost.grid.valid_pos
		end
	end
	--print(son.pos_index)

	son.target_offset = math.floor((mom.target_offset + dad.target_offset)/2)

	if (random.random(0, 10)<=3) then -- mutate
		son.target_offset = son.target_offset +
							math.floor(random.random(-2, 2))
	end

	son.target_offset = random.random(	-Ghost.ghost_target_spread,
										Ghost.ghost_target_spread)

	son.try_order = {} -- we should add mutation

	local this_rand = random.random(0, 10)
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

	this_rand =  random.random(0, 10)
	if ( this_rand<=4) then
		son.chase_feared_gene = mom.chase_feared_gene
	elseif ( this_rand<=8) then
		son.chase_feared_gene = dad.chase_feared_gene
	else
		son.chase_feared_gene = random.random(1, 9)
	end

	this_rand =  random.random(0, 10)
	if ( this_rand<=4) then
		son.scatter_feared_gene = mom.scatter_feared_gene
	elseif ( this_rand<=8) then
		son.scatter_feared_gene = dad.scatter_feared_gene
	else
		son.scatter_feared_gene = random.random(1, 5)
	end

	self:reset( son.pos_index,
				son.target_offset,
				son.try_order,
				son.fear_target,
				son.fear_group,
				son.chase_feared_gene,
				son.scatter_feared_gene,
				Ghost.ghost_speed,
				pills,
				this_spawn_grid_pos,
				this_direction)
end

function Ghost:reactivate(pills, spawn_grid_pos)
	local this_spawn_grid_pos = spawn_grid_pos or self.grid_pos
	Ghost:reset(self.pos_index,
				self.target_offset,
				self.try_order,
				self.fear_target,
				self.fear_group,
				self.chase_feared_gene,
				self.scatter_feared_gene,
				Ghost.ghost_speed,
				pills,
				this_spawn_grid_pos)
end

function Ghost:regen(pills, spawn_grid_pos)
	local this_spawn_grid_pos = spawn_grid_pos or self.grid_pos

	local pos_index = random.random(1, #Ghost.grid.valid_pos)

	local target_offset = random.random( -Ghost.ghost_target_spread,
											Ghost.ghost_target_spread)
	-- build a valid try_order gene
	local try_order = {}
	for i=1, 4, 1 do
		try_order[i] = i
	end
	utils.array_shuffler(try_order)

	local fear_target = random.random(0, ghost_fear_spread)
	local fear_group = random.random(0, ghost_fear_spread)

	local chase_feared_gene = random.random(1, 9)
	local scatter_feared_gene = random.random(1, 5)


	self:reset( pos_index,
				target_offset,
				try_order,
				fear_target,
				fear_group,
				chase_feared_gene,
				scatter_feared_gene,
				Ghost.ghost_speed,
				pills,
				this_spawn_grid_pos)
end

function Ghost:draw(state)
	if self.is_active then
		if(self.target_offset <= 0)then
			if (self.target_offset == -1) then
				love.graphics.setColor( 0.2, 0.5, 0.8)
			elseif (self.target_offset == -2) then
				love.graphics.setColor( 0.4, 0.5, 0.6)
			elseif (self.target_offset == -3) then
				love.graphics.setColor( 0.6, 0.5, 0.4)
			elseif (self.target_offset == -4) then
				love.graphics.setColor( 0.8, 0.5, 0.2)
			else--if (self.target_offset < -4) then
				love.graphics.setColor( 1, 0.5, 0)
			end
		else
			if (self.target_offset == 1) then
				love.graphics.setColor( 0.5, 0.2, 0.8)
			elseif (self.target_offset == 2) then
				love.graphics.setColor( 0.5, 0.4, 0.6)
			elseif (self.target_offset == 3) then
				love.graphics.setColor( 0.5, 0.6, 0.4)
			elseif (self.target_offset == 4) then
				love.graphics.setColor( 0.5, 0.8, 0.2)
			else--if (self.target_offset > 4) then
				love.graphics.setColor( 0.5, 1, 0)
			end
		end

		--love.graphics.setColor( (1/self.target_offset) + 0.3, 0.5, 0.3)
		love.graphics.circle("fill", self.x, self.y, Ghost.grid_size*0.5)

		-- assign  colors based on pos_index
		if (self.pos_index < #Ghost.grid.valid_pos/4 )then
			love.graphics.setColor(1, 1, 1)
		elseif (self.pos_index < (#Ghost.grid.valid_pos/4)*2 )then
			love.graphics.setColor(0.75, 0, 0.75)
		elseif (self.pos_index < (#Ghost.grid.valid_pos/4)*3 )then
			love.graphics.setColor(0, 0.5, 0.5)
		else
			love.graphics.setColor(0.05, 0.05, 0.05)
		end

		--love.graphics.circle("fill", self.x , self.y, grid_size*0.3)
		local midle = utils.midle_point(self, self.front)
		local midle_midle = utils.midle_point(self, midle)
		local midle_midle_midle = utils.midle_point(self, midle_midle)
		love.graphics.circle(	"fill",
								midle_midle_midle.x,
								midle_midle_midle.y,
								Ghost.grid_size/4)
		--love.graphics.circle("fill", self.x, self.y, grid_size/6)

		if self.is_feared then
			love.graphics.setColor(1, 0, 0)
			love.graphics.circle("fill", midle.x, midle.y, Ghost.grid_size/5)
			--love.graphics.line(self.x, self.y, self.front.x, self.front.y)
		end
	end
end

function Ghost:collided(other)
	if other:is_type("player") then
		if (Ghost.state ~= "freightened") then
			--print("you loose, my target is: " .. self.target_offset)
			-- Ghost.reporter.report_catched(self.target_offset)

			if(Ghost.speed_boost_on) then
				self.speed_boost = self.speed_boost  + 0.1*Ghost.grid_size
			end
			self.n_catches = self.n_catches + 1
			other.is_active = false
		else
			if self.got_ghost then
				self:got_ghost()
			end
			self.is_active = false
		end
	end
end

function Ghost:update(targets, pills, average_ghost_pos, dt)
	--print(value.fear_group)
	if (self.is_active) then
		Ghost.grid:update_position(self)

		self.n_updates = self.n_updates + 1
		self.fitness = self.n_catches + (self.n_pills*0.001)/self.n_updates

		-- updates average distance to player and group,
		-- it is used for collision
		local target = targets[1]
		local target_distance = utils.distance(target, self)
		for i = 2, #targets do
			if target.is_active then
				local this_target = targets[i]
				local this_target_distance = utils.distance(target, self)
				if (this_target_distance < target_distance) then
					target = this_target
					target_distance = this_target_distance
				end
			end
		end
		self.dist_to_target = utils.distance(target, self)
		self.dist_to_group = utils.distance(average_ghost_pos, self)

		self.front = Ghost.grid:get_dynamic_front(self)

		self.is_feared = false
		if  (Ghost.ghost_fear_on) then
			if (self.dist_to_target < self.fear_target*Ghost.grid_size  and
				self.dist_to_group > self.fear_group*Ghost.grid_size
				--dist_to_home > 10*ghost.grid_size
				--self.direction == "idle"
				) then
				self.is_feared = true
			end
		end

		local this_grid_pos = Ghost.grid:get_grid_pos_absolute(self)

		--check collision with pills
		self.dist_to_closest_pill =  10000*Ghost.grid_size
		self.grid_pos_closest_pill = {}
		self.grid_pos_closest_pill_index = 1

		--- pills
		for i=1, #pills, 1 do
			if (self.dist_to_closest_pill > utils.distance(pills[i], self) and
				pills[i].is_active) then

				self.dist_to_closest_pill = utils.distance(pills[i], self)
				self.grid_pos_closest_pill.x = pills[i].grid_pos.x
				self.grid_pos_closest_pill.y = pills[i].grid_pos.y
				self.grid_pos_closest_pill_index = i
			end
			local coliding =    (self.grid_pos.x == pills[i].grid_pos.x) and
								(self.grid_pos.y == pills[i].grid_pos.y)
			if (  coliding and not self.pill_debounce[i]) then
				self.n_pills = self.n_pills + 1

				if(Ghost.speed_boost_on)then
					self.speed_boost = self.speed_boost  + 0.02*Ghost.grid_size
				end



				pills[i].n_ghost_pass = pills[i].n_ghost_pass + 1

				self.pill_debounce[i] = true

			elseif ( not coliding and self.pill_debounce )then
				self.pill_debounce[i] = false
			end
		end

		local reset_home_pill = false
		if Ghost.ghost_migration_on then
			if Ghost.ghost_selective_migration_on then
				if(pills[ self.home_pill_index ].is_active == false) then
					reset_home_pill = true
				end-- else maintain home
			else
				reset_home_pill = true
			end
		end
		if reset_home_pill then
			self.home.x = self.grid_pos_closest_pill.x
			self.home.y = self.grid_pos_closest_pill.y
			self.home_pill_index = self.grid_pos_closest_pill_index
		end

		-- check collision with wall
		local front_grid_pos = Ghost.grid:get_grid_pos_absolute(self.front)
		if(Ghost.grid:is_grid_wall(front_grid_pos)) then
			self.direction = "idle"
			self.next_direction = "idle"
			Ghost.grid:center_on_grid(self)
		end

		--on change tile
		if ((this_grid_pos.x ~= self.grid_pos.x) or
			(this_grid_pos.y ~= self.grid_pos.y)) then

			self.last_grid_pos = self.grid_pos
			self.grid_pos = this_grid_pos
		end

		--on tile center, or close
		local dist_grid_center = utils.distance( Ghost.grid:get_grid_center(self.grid_pos), self)
		if (dist_grid_center < Ghost.lookahead/8) then
			if ( self.direction == "up" or self.direction== "down") then
				Ghost.grid:center_on_grid_x(self)
			elseif ( self.direction == "left" or self.direction== "right") then
				Ghost.grid:center_on_grid_y(self)
			end
			self:find_next_dir(target, average_ghost_pos)
		end

		-- checks if the ghost has exceeded max speed
		-- if yes, limit it but keep self.speed to calculate fitness
		local this_speed = self.speed + self.speed_boost
		if this_speed > (Ghost.ghost_speed_max_factor * Ghost.ghost_speed) then
			this_speed = Ghost.ghost_speed_max_factor * Ghost.ghost_speed
		end
		--print(this_speed)
		if self.direction ~= "idle" then
			--print("X: ", self.x, "Y:", self.y)
			if self.direction == "up" then self.y = self.y - dt*this_speed
			elseif self.direction == "down" then self.y = self.y +dt*this_speed
			elseif self.direction == "left" then self.x = self.x -dt*this_speed
			elseif self.direction == "right" then self.x = self.x +dt*this_speed
			end
		end

	end
end

function Ghost:find_next_dir(target, average_ghost_pos)
	self.enabled_dir = Ghost.grid:get_enabled_directions(self.grid_pos)

	--count = grid.count_enabled_directions(self.grid_pos)
	if ( 	Ghost.grid.grid_types[self.grid_pos.y][self.grid_pos.x]~=3 and-- invertido
			Ghost.grid.grid_types[self.grid_pos.y][self.grid_pos.x]~=12 ) then
		--check which one is closer to the target
		-- make a table to contain the posible destinations
		local maybe_dirs = {}

		for i=1, #self.try_order, 1 do
			if (self.enabled_dir[self.try_order[i]]==true ) then --up
				local pos = {}
				if(self.try_order[i]==1) then
					pos.x = self.grid_pos.x
					pos.y = self.grid_pos.y -1
					pos.direction = "up"
				elseif(self.try_order[i]==2) then
					pos.x = self.grid_pos.x
					pos.y = self.grid_pos.y +1
					pos.direction = "down"
				elseif(self.try_order[i]==3) then
					pos.x = self.grid_pos.x -1
					pos.y = self.grid_pos.y
					pos.direction = "left"
				elseif(self.try_order[i]==4) then
					pos.x = self.grid_pos.x +1
					pos.y = self.grid_pos.y
					pos.direction = "right"
				end

				if (pos.x~=self.last_grid_pos.x or
					pos.y~=self.last_grid_pos.y) then

					table.insert(maybe_dirs, pos)
				else
					--print("skipped")
				end
			end
		end

		if( #maybe_dirs == 0) then
			print("maybe_dirs cant be empty")
			for e=1, #self.try_order, 1 do
				print(self.try_order[e])
			end
		end

		if (target.is_active) then
			--io.output()
			if ( Ghost.state == "chasing" ) then
				if(self.fear)then
					if(Ghost.ghost_chase_feared_gene_on)then
						if(self.chase_feared_gene == 1)then
							self:go_home(maybe_dirs)
						elseif(self.chase_feared_gene == 2)then
							self:go_to_closest_pill(maybe_dirs)
						elseif(self.chase_feared_gene == 3)then
							self:go_to_group(maybe_dirs, average_ghost_pos)
						elseif(self.chase_feared_gene == 4)then
							self:run_from_target(self, target, maybe_dirs)
						elseif(self.chase_feared_gene == 5)then
							self:wander(maybe_dirs)
						elseif(self.chase_feared_gene == 6)then
							self:go_to_target(target, maybe_dirs)
						elseif(self.chase_feared_gene == 7)then
							self:catch_target(target,maybe_dirs)
						elseif(self.chase_feared_gene == 8)then
							self:surround_target_back(target,maybe_dirs)
						elseif(self.chase_feared_gene == 9)then
							self:surround_target_front(target, maybe_dirs)
						end
					else
						self:go_home(maybe_dirs)
					end
				else
					self:go_to_target(target, maybe_dirs)
				end
			elseif ( Ghost.state == "scattering") then
				if(self.fear)then
					--print("feared")
					if( Ghost.ghost_scatter_feared_gene_on ) then
						if(self.scatter_feared_gene == 1)then
							self:go_home(maybe_dirs)
						elseif(self.scatter_feared_gene == 2)then
							self:go_to_closest_pill(maybe_dirs)
						elseif(self.scatter_feared_gene == 3)then
							self:go_to_group(maybe_dirs, average_ghost_pos)
						elseif(self.scatter_feared_gene == 4)then
							self:run_from_target(target, maybe_dirs)
						elseif(self.scatter_feared_gene == 5)then
							self:wander(maybe_dirs)
						end
					else
						self:run_from_target(target, maybe_dirs)
					end

				else
					--print("not feared")
					if(Ghost.ghost_go_home_on_scatter) then
						self:go_home(maybe_dirs)
					else
						self:wander(maybe_dirs)
					end
				end

			elseif ( Ghost.state == "freightened") then
				self:wander(maybe_dirs)
				--ghost.run_from_target(self, target, maybe_dirs)
				--ghost.go_home(self, maybe_dirs)
				-- ghost.go_to_closest_pill(self, maybe_dirs)
			else
				print("error, invalid ghost_state")
			end
		else
			self:wander(maybe_dirs)
		end
	end
end

---------------------------------------------------------------

function Ghost:catch_target(target, maybe_dirs)
	local destination = {}

	destination.x = target.grid_pos.x
	destination.y = target.grid_pos.y

	self:get_closest(maybe_dirs, destination)
end

function Ghost:go_to_target(target, maybe_dirs)
	local destination = {}

	if (target.direction == "up") then
		destination.x =  target.grid_pos.x
		destination.y = -self.target_offset + target.grid_pos.y
	elseif (target.direction == "down") then
		destination.x = target.grid_pos.x
		destination.y = self.target_offset + target.grid_pos.y
	elseif (target.direction == "left") then
		destination.x = -self.target_offset + target.grid_pos.x
		destination.y = target.grid_pos.y
	elseif (target.direction == "right") then
		destination.x = self.target_offset + target.grid_pos.x
		destination.y = target.grid_pos.y
	elseif (target.direction == "idle") then
		destination.x = target.grid_pos.x
		destination.y = target.grid_pos.y
	end

	self:get_closest(maybe_dirs, destination)
end

function Ghost:surround_target_front(target, maybe_dirs)
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

	self:get_closest(maybe_dirs, destination)
end

function Ghost:surround_target_back(target, maybe_dirs)
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

	self:get_closest(maybe_dirs, destination)
end

function Ghost:wander(maybe_dirs)
	local destination = {}
	local rand_grid = random.random(1, #Ghost.grid.valid_pos )
	local this_grid_pos = Ghost.grid.valid_pos[rand_grid]

	destination.x = this_grid_pos.x
	destination.y = this_grid_pos.y

	self:get_closest(maybe_dirs, destination)
end

function Ghost:go_home(maybe_dirs)
	local destination = {}
	destination.x = self.home.x
	destination.y = self.home.y

	self:get_closest(maybe_dirs, destination)
end

function Ghost:go_to_group(maybe_dirs, average_ghost_pos)
	local this_grid_pos = Ghost.grid:get_grid_pos_absolute(average_ghost_pos)

	local destination = {}
	destination.x =  this_grid_pos.x
	destination.y =  this_grid_pos.y

	self:get_closest(maybe_dirs, destination)
end


function Ghost:run_from_target(target, maybe_dirs)
	local destination = {}

	if (target.direction == "up") then
		destination.x =  target.grid_pos.x
		destination.y = -self.target_offset + target.grid_pos.y
	elseif (target.direction == "down") then
		destination.x = target.grid_pos.x
		destination.y = self.target_offset + target.grid_pos.y
	elseif (target.direction == "left") then
		destination.x = -self.target_offset + target.grid_pos.x
		destination.y = target.grid_pos.y
	elseif (target.direction == "right") then
		destination.x = self.target_offset + target.grid_pos.x
		destination.y = target.grid_pos.y
	elseif (target.direction == "idle") then
		destination.x = target.grid_pos.x
		destination.y = target.grid_pos.y
	end

	self:get_furthest(maybe_dirs, destination)
end

function Ghost:go_to_closest_pill(maybe_dirs)
	local destination = {}

	destination.x = self.grid_pos_closest_pill.x
	destination.y = self.grid_pos_closest_pill.y

	self:get_closest(maybe_dirs, destination)
end


function Ghost:get_closest(maybe_dirs, destination)
	local shortest = 1
	--print(destination.x)
	for i=1, #maybe_dirs, 1 do
		maybe_dirs[i].dist = utils.distance(maybe_dirs[i], destination)
		if ( maybe_dirs[i].dist < maybe_dirs[shortest].dist ) then
			shortest = i
			--print(#maybe_dirs)
		end
	end
	self.direction = maybe_dirs[shortest].direction
end

function Ghost:get_furthest(maybe_dirs, destination)
	local furthest = 1
	for i=1, #maybe_dirs, 1 do
		maybe_dirs[i].dist = utils.distance(maybe_dirs[i], destination)
		if ( maybe_dirs[i].dist > maybe_dirs[furthest].dist ) then
			furthest = i
		end
	end
	--print("furthest" .. furthest)
	self.direction = maybe_dirs[furthest].direction
end

function Ghost:flip_direction()
	if (self.is_active == false) then return end
	if(self.direction == "up") then self.direction = "down"
	elseif(self.direction == "down") then self.direction = "up"
	elseif(self.direction == "left") then self.direction = "right"
	elseif(self.direction == "right") then self.direction = "left" end
end

return Ghost
