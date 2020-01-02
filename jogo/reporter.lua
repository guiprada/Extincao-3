local reporter = {}
local settings = require "settings"

reporter.target_offset_distribution_file = io.open("target_offset_distribution.run", "w")
reporter.fear_target_file = io.open("fear_target.run", "w")
reporter.fear_group_file = io.open("fear_group.run", "w")
reporter.stats_file = io.open("stats.run", "w")
reporter.config_file = io.open("config.run", "w")
reporter.gene_scatter_file = io.open("gene_scatter.run", "w")
reporter.gene_chase_file = io.open("gene_chase.run", "w")

reporter.distrib_catched_target_offset = {}
reporter.distrib_catcher_target_offset = {}

reporter.ghosts_catched = 0
reporter.player_catched = 0
reporter.global_frame_counter = 0

for i=-settings.ghost_target_spread, settings.ghost_target_spread, 1 do
	reporter.distrib_catched_target_offset[i] = 0
	reporter.distrib_catcher_target_offset[i] = 0
end

reporter.init = function ()
    io.output(reporter.config_file)
    io.write("the Configuration used is\n")

    io.write("\n\nghost_genetic_on: " .. tostring(settings.ghost_genetic_on))
    io.write("\nghost_fitness_on: " .. tostring(settings.ghost_fitness_on) )
    io.write("\nghost_target_offset_freightned_on: " .. tostring(settings.ghost_target_offset_freightned_on))
    io.write("\nghost_migration_on: " .. tostring(settings.ghost_migration_on))
    io.write("\nghost_selective_migration_on: " .. tostring(settings.ghost_selective_migration_on))
    io.write("\nghost_fear_on: " .. tostring(settings.ghost_fear_on))
    io.write("\nghost_go_home_on_scatter: " .. tostring(settings.ghost_go_home_on_scatter))
    io.write("\nghost_chase_feared_gene_on: " .. tostring(settings.ghost_chase_feared_gene_on))
    io.write("\nghost_scatter_feared_gene_on: " .. tostring(settings.ghost_scatter_feared_gene_on))
    io.write("\nghost_target_spread: " .. settings.ghost_target_spread)
    io.write("\n\npill_genetic_on: " .. tostring(settings.pill_genetic_on))
    io.write("\npill_precise_crossover_on: " .. tostring(settings.pill_precise_crossover_on))
    io.write("\nspeed_boost_on: " .. tostring(settings.speed_boost_on))

    io.write("\n\nn_ghosts: " .. settings.n_ghosts)
    io.write("\nn_pills: " .. settings.n_pills)
    io.write("\npill_time: " .. settings.pill_time)
    io.write("\nrestart_pill_time: " .. settings.restart_pill_time)
    io.write("\nghost_chase_time: " .. settings.ghost_chase_time)
    io.write("\nghost_scatter_time: " .. settings.ghost_scatter_time)
    io.write("\nghost_respawn_time: " .. settings.ghost_respawn_time)

    io.write("\nthe grid is: " .. settings.grid_width_n .. " x " .. settings.grid_height_n)
    io.write("\nplayer's start grid is: " .. settings.player_start_grid.x .. ", " .. settings.player_start_grid.y)

    io.write("\nghost_speed_max_factor: " .. settings.ghost_speed_max_factor )
    io.write("\nplayer_speed_grid_size_factor: " .. settings.player_speed_grid_size_factor )
end

function reporter.report_catch(this_ghost, ghosts)
    reporter.ghosts_catched = reporter.ghosts_catched + 1

    if(	reporter.distrib_catched_target_offset[ this_ghost.target_offset ] ) then
        reporter.distrib_catched_target_offset[ this_ghost.target_offset ] = reporter.distrib_catched_target_offset[ this_ghost.target_offset ] + 1
    else
        reporter.distrib_catched_target_offset[ this_ghost.target_offset ] = 1
    end

	io.output(reporter.stats_file)
	io.write(	"ghosts catched: " .. reporter.ghosts_catched .. "  <>  " ..
				"player_catched: " .. reporter.player_catched .. "  <>  " ..
				"catches/catched:" .. reporter.ghosts_catched/reporter.player_catched .. " <> " ..
				"catches/frames:"  .. reporter.ghosts_catched/reporter.global_frame_counter  .. "\n"	)

--------------------------------------------------------------------------------
	local distrib_target_offset = {}
	for i=-settings.ghost_target_spread, settings.ghost_target_spread, 1 do
		distrib_target_offset[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then -- para criar novos valores
			if ( distrib_target_offset[ ghosts[i].target_offset ] ~= nil ) then
				distrib_target_offset[ ghosts[i].target_offset ] = distrib_target_offset[ ghosts[i].target_offset ] + 1
			else
				distrib_target_offset[ ghosts[i].target_offset ] = 1
			end
		end
	end

	io.output(reporter.target_offset_distribution_file)
	--print("population's target distribution")
	for i=-settings.ghost_target_spread, settings.ghost_target_spread, 1 do
		if ( distrib_target_offset[i] == 0 ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_target_offset[i] .. " ")
		end
	end
	io.write("\n")
	--print()

--------------------------------------------------------------------------------

	local distrib_fear_group = {}
	for i=1, settings.ghost_fear_spread, 1 do
		distrib_fear_group[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then -- para criar novos valores
			if ( distrib_fear_group[ ghosts[i].fear_group ] ~= nil ) then
				distrib_fear_group[ ghosts[i].fear_group ] = distrib_fear_group[ ghosts[i].fear_group ] + 1
			else
				distrib_fear_group[ ghosts[i].fear_group ] = 1
			end
		end
	end

	io.output(reporter.fear_group_file)
	--print("population's target distribution")
	for i=1, #distrib_fear_group, 1 do
		if ( distrib_fear_group[i] == 0 or distrib_fear_group[i] == nil ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_fear_group[i] .. " ")
		end
	end
	io.write("\n")
	--print()

--------------------------------------------------------------------------------

	local distrib_fear_target = {}
	for i=1, settings.ghost_fear_spread, 1 do
		distrib_fear_target[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then -- para criar novos valores
			if ( distrib_fear_target[ ghosts[i].fear_target ] ~= nil ) then
				distrib_fear_target[ ghosts[i].fear_target ] = distrib_fear_target[ ghosts[i].fear_target ] + 1
			else
				distrib_fear_target[ ghosts[i].fear_target ] = 1
			end
		end
	end

	io.output(reporter.fear_target_file)
	--print("population's target distribution")
	for i=1, #distrib_fear_target, 1 do
		if ( distrib_fear_target[i] == 0 or distrib_fear_target[i] == nil ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_fear_target[i] .. " ")
		end
	end
	io.write("\n")
	--print()
-------------------------------------------------------------------------------
	local distrib_chase_feared = {}
	for i=1, 9, 1 do
		distrib_chase_feared[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then
			distrib_chase_feared[ghosts[i].chase_feared_gene] = distrib_chase_feared[ghosts[i].chase_feared_gene] +1
		end
	end

	io.output(reporter.gene_chase_file)
	--print("population's target distribution")
	for i=1, #distrib_chase_feared, 1 do
		if ( distrib_chase_feared[i] == 0 ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_chase_feared[i] .. " ")
		end
	end
	io.write("\n")
	--print()
------------------------------------------------------------------------------
	local distrib_scatter_feared = {}
	for i=1, 5, 1 do
		distrib_scatter_feared[i] = 0
	end
	for i=1, #ghosts, 1 do
		if( ghosts[i].is_active == true) then
			distrib_scatter_feared[ghosts[i].scatter_feared_gene] = distrib_scatter_feared[ghosts[i].scatter_feared_gene] +1
		end
	end

	io.output(reporter.gene_scatter_file)
	--print("population's target distribution")
	for i=1, #distrib_scatter_feared, 1 do
		if ( distrib_scatter_feared[i] == 0 ) then
			io.write(" _ ")
		else
			io.write(" " .. distrib_scatter_feared[i] .. " ")
		end
	end
	io.write("\n")
	--print()

end

function reporter.stop()
    io.output(reporter.config_file)
    io.write("\n\ncatched")
    for i=-settings.ghost_target_spread, settings.ghost_target_spread, 1 do
        io.write("\ndistrib_catched_target_offset[" .. i .. "]: " .. reporter.distrib_catched_target_offset[i])
    end

    io.write("\n\ncatcher")
    for i=-settings.ghost_target_spread, settings.ghost_target_spread, 1 do
        io.write("\ndistrib_catcher_target_offset[" .. i .. "]: " .. reporter.distrib_catcher_target_offset[i])
    end
end

function reporter.report_catched(last_catcher_target_offset)
    if (reporter.distrib_catcher_target_offset[ last_catcher_target_offset ])then
        reporter.distrib_catcher_target_offset[ last_catcher_target_offset ] = reporter.distrib_catcher_target_offset[ last_catcher_target_offset] + 1
    else
        reporter.distrib_catcher_target_offset[ last_catcher_target_offset ] = 1
    end
end

return reporter
