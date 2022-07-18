-- Guilherme Cunha Prada 2020

local reporter = {}
local settings = require "settings"

reporter.target_offset_distribution_file = io.open("run/target_offset_distribution.run", "w")
reporter.fear_target_file = io.open("run/fear_target.run", "w")
reporter.fear_group_file = io.open("run/fear_group.run", "w")
reporter.stats_file = io.open("run/stats.run", "w")
reporter.config_file = io.open("run/config.run", "w")
reporter.gene_scatter_file = io.open("run/gene_scatter.run", "w")
reporter.gene_chase_file = io.open("run/gene_chase.run", "w")

reporter.distrib_catched_target_offset = {}
reporter.distrib_catcher_target_offset = {}

reporter.ghosts_catched = 0
reporter.player_catched = 0
reporter.global_frame_counter = 0

for i=-settings.ghost_target_spread, settings.ghost_target_spread, 1 do
	reporter.distrib_catched_target_offset[i] = 0
	reporter.distrib_catcher_target_offset[i] = 0
end

function reporter.init(grid, args)
    -- save the configuration used in the run to file
    io.output(reporter.config_file)
    io.write("the Configuration used is:")

    io.write("\n\nghost_genetic_on: " .. tostring(settings.ghost_genetic_on))
    io.write("\nghost_fitness_on: " .. tostring(settings.ghost_fitness_on) )
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

    io.write("\nthe grid is: " .. grid.grid_width_n .. " x " .. grid.grid_height_n)
    io.write("\nplayer's start grid is: " .. settings.player_start_grid.x .. ", " .. settings.player_start_grid.y)

    io.write("\nghost_speed_max_factor: " .. settings.ghost_speed_max_factor )
    io.write("\nplayer_speed_grid_size_factor: " .. settings.player_speed_factor )
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

    ----------------------------------------------------------------------------
    -- local function to save to file
    local f = function(start, stop, parameter, file)
        local distrib = {}
        for i=start, stop, 1 do
            distrib[i] = 0
        end

        for i=1, #ghosts, 1 do
            if( ghosts[i]._is_active == true) then -- para criar novos valores
                if ( distrib[ ghosts[i][parameter] ] ~= nil ) then
                    distrib[ ghosts[i][parameter] ] = distrib[ ghosts[i][parameter] ] + 1
                else
                    distrib[ ghosts[i][parameter] ] = 1
                end
            end
        end

        io.output(file)

        for i=start, stop, 1 do
            if ( distrib[i] == 0 ) then
                io.write(" _ ")
            else
                io.write(" " .. distrib[i] .. " ")
            end
        end
        io.write("\n")
    end

    f(  -settings.ghost_target_spread, settings.ghost_target_spread,
        "target_offset", reporter.target_offset_distribution_file )
    f(1, settings.ghost_fear_spread, "fear_group", reporter.fear_group_file)
    f(1, settings.ghost_fear_spread, "fear_target", reporter.fear_target_file)
    f(1,  9, "chase_feared_gene", reporter.gene_chase_file)
    f(1, 5, "scatter_feared_gene", reporter.gene_scatter_file)

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
    reporter.player_catched = reporter.player_catched + 1
end

return reporter
