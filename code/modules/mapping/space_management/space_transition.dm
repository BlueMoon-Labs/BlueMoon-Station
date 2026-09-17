/datum/space_level/proc/set_linkage(new_linkage)
	linkage = new_linkage
	if(linkage == SELFLOOPING)
		neigbours = list(TEXT_NORTH,TEXT_SOUTH,TEXT_EAST,TEXT_WEST)
		for(var/A in neigbours)
			neigbours[A] = src

/// Края z-уровней: соседство клеток сетки переводится в destination_x/y/z космических турфов.
/datum/controller/subsystem/mapping/proc/setup_map_transitions()
	var/datum/space_grid/grid = get_space_grid()

	//Уровни без назначенной клетки: секторы свои заняли ещё при загрузке.
	for(var/datum/space_level/level as anything in z_list)
		if(level.linkage != CROSSLINKED)
			continue
		if(grid.coords_of(level))
			continue
		place_stack_column(grid, level)
		CHECK_TICK

	grid.link_horizontal()
	grid.apply_explicit_links()

	//Этаж без соседей по горизонтали заворачивает края на себя, иначе он упрётся в границу мира.
	for(var/datum/space_level/level as anything in grid.placements)
		if(level.linkage != CROSSLINKED || length(level.neigbours))
			continue
		var/list/spot = grid.placements[level]
		if(spot[3] <= 0)
			continue
		for(var/side in list(TEXT_NORTH, TEXT_SOUTH, TEXT_EAST, TEXT_WEST))
			level.neigbours[side] = level

	log_space_grid_report()

	//Lists below are pre-calculated values arranged in the list in such a way to be easily accessable in the loop by the counter
	//Its either this or madness with lotsa math

	var/list/x_pos_beginning = list(1, 1, world.maxx - TRANSITIONEDGE, 1)  //x values of the lowest-leftest turfs of the respective 4 blocks on each side of zlevel
	var/list/y_pos_beginning = list(world.maxy - TRANSITIONEDGE, 1, 1 + TRANSITIONEDGE, 1 + TRANSITIONEDGE)  //y values respectively
	var/list/x_pos_ending = list(world.maxx, world.maxx, world.maxx, 1 + TRANSITIONEDGE)	//x values of the highest-rightest turfs of the respective 4 blocks on each side of zlevel
	var/list/y_pos_ending = list(world.maxy, 1 + TRANSITIONEDGE, world.maxy - TRANSITIONEDGE, world.maxy - TRANSITIONEDGE)	//y values respectively
	var/list/x_pos_transition = list(1, 1, TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 1)		//values of x for the transition from respective blocks on the side of zlevel, 1 is being translated into turfs respective x value later in the code
	var/list/y_pos_transition = list(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 1, 1, 1)		//values of y for the transition from respective blocks on the side of zlevel, 1 is being translated into turfs respective y value later in the code

	for(var/datum/space_level/level as anything in z_list)
		if(!length(level.neigbours))
			continue
		for(var/side in 1 to 4)
			var/turf/beginning = locate(x_pos_beginning[side], y_pos_beginning[side], level.z_value)
			var/turf/ending = locate(x_pos_ending[side], y_pos_ending[side], level.z_value)
			var/list/turfblock = block(beginning, ending)
			var/dirside = 2**(side-1)
			var/zdestination = level.z_value

			var/datum/space_level/neighbour = level.neigbours["[dirside]"]
			if(neighbour && neighbour != level)
				zdestination = neighbour.z_value
			else
				//Край заворачивает на дальний конец ряда. Счётчик шагов - страховка от кольца из явных связей.
				var/datum/space_level/walker = level
				var/opposite = "[turn(dirside, 180)]"
				var/steps = 0
				var/datum/space_level/next_level = walker.neigbours[opposite]
				while(next_level && next_level != walker && steps++ < length(z_list))
					walker = next_level
					next_level = walker.neigbours[opposite]
				zdestination = walker.z_value

			for(var/turf/open/space/S in turfblock)
				S.destination_x = x_pos_transition[side] == 1 ? S.x : x_pos_transition[side]
				S.destination_y = y_pos_transition[side] == 1 ? S.y : y_pos_transition[side]
				S.destination_z = zdestination

				// Mirage border code
				var/mirage_dir
				if(S.x == 1 + TRANSITIONEDGE)
					mirage_dir |= WEST
				else if(S.x == world.maxx - TRANSITIONEDGE)
					mirage_dir |= EAST
				if(S.y == 1 + TRANSITIONEDGE)
					mirage_dir |= SOUTH
				else if(S.y == world.maxy - TRANSITIONEDGE)
					mirage_dir |= NORTH
				if(!mirage_dir)
					continue

				var/turf/place = locate(S.destination_x, S.destination_y, S.destination_z)
				S.AddComponent(/datum/component/mirage_border, place, mirage_dir)

/// Сажает связку одной колонкой: дно в свободную клетку нулевого этажа, остальные этажи над ним.
/datum/controller/subsystem/mapping/proc/place_stack_column(datum/space_grid/grid, datum/space_level/level)
	var/list/column = list()
	for(var/z in get_connected_levels(level.z_value))
		var/datum/space_level/member = z_list[z]
		if(member.linkage != CROSSLINKED || grid.coords_of(member))
			continue
		column += member

	if(!grid.place_floating(column[1]))
		return
	var/list/spot = grid.coords_of(column[1])
	for(var/index in 2 to length(column))
		grid.place(column[index], spot[1], spot[2], spot[3] + index - 1)
