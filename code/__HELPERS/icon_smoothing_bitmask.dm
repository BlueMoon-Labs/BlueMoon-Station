
/atom/proc/smooth_icon_bitmask()
	if(QDELETED(src))
		return
	smoothing_flags &= ~SMOOTH_QUEUED
	flags_1 |= HTML_USE_INITAL_ICON_1
	if(!z)
		return
	if(smoothing_flags & (SMOOTH_BITMASK|SMOOTH_BITMASK_CARDINALS))
		bitmask_smooth()
	else
		return
	SEND_SIGNAL(src, COMSIG_ATOM_SMOOTHED_ICON)

/atom/movable/smooth_icon_bitmask()
	. = ..()
	update_appearance(~UPDATE_SMOOTHING)

/atom/proc/smoothing_allowed(atom/smoothing_with, direction, junction)
	return NONE

/atom/proc/bitmask_smooth()
	var/new_junction = NONE

	var/can_smooth_with = src.canSmoothWith
	var/smooth_border = (smoothing_flags & SMOOTH_BORDER)
	var/smooth_obj = (smoothing_flags & SMOOTH_OBJ)
	var/border_object_smoothing = (smoothing_flags & SMOOTH_BORDER_OBJECT)
	var/smooth_proc_filter = (smoothing_flags & SMOOTH_PROC_FILTER)
	var/just_set_junction = !(border_object_smoothing || smooth_proc_filter)

	#define SEARCH_ADJ_IN_DIR(direction, direction_flag) \
		do {  \
			set_adj_in_dir: { \
			var/turf/neighbor = get_step(src, direction); \
			if(neighbor) { \
				var/neighbor_smoothing_groups = neighbor.smoothing_groups; \
				if(neighbor_smoothing_groups) { \
					SMOOTH_AGAINST(neighbor, direction, direction_flag, neighbor_smoothing_groups); \
				} \
				if(smooth_obj) { \
					for(var/atom/movable/thing as anything in neighbor) { \
						var/thing_smoothing_groups = thing.smoothing_groups; \
						if(isnull(thing_smoothing_groups)) { \
							continue; \
						}; \
						if(!thing.anchored && !istype(thing, /obj/structure/window)) { \
							continue; \
						}; \
						SMOOTH_AGAINST(thing, direction, direction_flag, thing_smoothing_groups); \
					} \
				} \
			} else if (smooth_border) { \
				JUNCTION_FOUND(null, direction, direction_flag); \
			} \
			} \
		} while(FALSE)

	#define SMOOTH_AGAINST(thing, direction, direction_flag, their_groups) \
		for(var/target in can_smooth_with) { \
			if(!(target in their_groups)) \
				continue; \
			if(can_smooth_with[target] & their_groups[target] && \
				(!(thing.smoothing_flags & SMOOTH_PROC_FILTER) || thing.smoothing_allowed(src, REVERSE_DIR(direction), reverse_smoothing_junction(direction_flag)))) { \
				JUNCTION_FOUND(thing, direction, direction_flag); \
			} \
		}

	#define JUNCTION_FOUND(target, direction, direction_flag) \
		if (just_set_junction) { \
			new_junction |= direction_flag; \
			break set_adj_in_dir; \
		} \
		if(smooth_proc_filter) { \
			var/old_junction = new_junction; \
			new_junction |= smoothing_allowed(target, direction, direction_flag); \
			if(old_junction == new_junction) { \
				break; \
			} \
			break set_adj_in_dir; \
		}

	SEARCH_ADJ_IN_DIR(NORTH, NORTH_JUNCTION)
	SEARCH_ADJ_IN_DIR(SOUTH, SOUTH_JUNCTION)
	SEARCH_ADJ_IN_DIR(EAST, EAST_JUNCTION)
	SEARCH_ADJ_IN_DIR(WEST, WEST_JUNCTION)

	if(smoothing_flags & SMOOTH_BITMASK_CARDINALS || !(new_junction & (NORTH|SOUTH)) || !(new_junction & (EAST|WEST)))
		set_smoothed_icon_state(new_junction)
		return

	if(new_junction & NORTH_JUNCTION)
		if(new_junction & WEST_JUNCTION)
			SEARCH_ADJ_IN_DIR(NORTHWEST, NORTHWEST_JUNCTION)
		if(new_junction & EAST_JUNCTION)
			SEARCH_ADJ_IN_DIR(NORTHEAST, NORTHEAST_JUNCTION)

	if(new_junction & SOUTH_JUNCTION)
		if(new_junction & WEST_JUNCTION)
			SEARCH_ADJ_IN_DIR(SOUTHWEST, SOUTHWEST_JUNCTION)
		if(new_junction & EAST_JUNCTION)
			SEARCH_ADJ_IN_DIR(SOUTHEAST, SOUTHEAST_JUNCTION)

	set_smoothed_icon_state(new_junction)

	#undef JUNCTION_FOUND
	#undef SMOOTH_AGAINST
	#undef SEARCH_ADJ_IN_DIR

/atom/proc/set_smoothed_icon_state(new_junction)
	. = smoothing_junction
	smoothing_junction = new_junction
	icon_state = "[base_icon_state]-[smoothing_junction]"

/turf/closed/set_smoothed_icon_state(new_junction)
	var/old_junction = smoothing_junction
	smoothing_junction = new_junction

	if(!(smoothing_flags & SMOOTH_DIAGONAL_CORNERS))
		icon_state = "[base_icon_state]-[smoothing_junction]"
		return

	switch(new_junction)
		if(
			NORTH_JUNCTION|WEST_JUNCTION,
			NORTH_JUNCTION|EAST_JUNCTION,
			SOUTH_JUNCTION|WEST_JUNCTION,
			SOUTH_JUNCTION|EAST_JUNCTION,
			NORTH_JUNCTION|WEST_JUNCTION|NORTHWEST_JUNCTION,
			NORTH_JUNCTION|EAST_JUNCTION|NORTHEAST_JUNCTION,
			SOUTH_JUNCTION|WEST_JUNCTION|SOUTHWEST_JUNCTION,
			SOUTH_JUNCTION|EAST_JUNCTION|SOUTHEAST_JUNCTION,
		)
			icon_state = "[base_icon_state]-[smoothing_junction]-diagonal"
			if(new_junction == old_junction || fixed_underlay)
				return

			var/junction_dir = reverse_smoothing_junction_to_dir(smoothing_junction)
			var/turned_adjacency = REVERSE_DIR(junction_dir)
			var/turf/neighbor_turf = get_step(src, turned_adjacency & (NORTH|SOUTH))
			var/mutable_appearance/underlay_appearance = mutable_appearance(layer = TURF_LAYER, plane = FLOOR_PLANE)
			if(!neighbor_turf?.get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
				neighbor_turf = get_step(src, turned_adjacency & (EAST|WEST))
				if(!neighbor_turf?.get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
					neighbor_turf = get_step(src, turned_adjacency)
					if(!neighbor_turf?.get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
						if(!get_smooth_underlay_icon(underlay_appearance, src, turned_adjacency))
							underlay_appearance.icon = DEFAULT_UNDERLAY_ICON
							underlay_appearance.icon_state = DEFAULT_UNDERLAY_ICON_STATE
			underlays += underlay_appearance
		else
			icon_state = "[base_icon_state]-[smoothing_junction]"

/proc/reverse_smoothing_junction(junction)
	var/handback = NONE
	if(junction & NORTH_JUNCTION)
		handback |= SOUTH_JUNCTION
	if(junction & SOUTH_JUNCTION)
		handback |= NORTH_JUNCTION
	if(junction & EAST_JUNCTION)
		handback |= WEST_JUNCTION
	if(junction & WEST_JUNCTION)
		handback |= EAST_JUNCTION
	if(junction & NORTHEAST_JUNCTION)
		handback |= SOUTHWEST_JUNCTION
	if(junction & SOUTHWEST_JUNCTION)
		handback |= NORTHEAST_JUNCTION
	if(junction & NORTHWEST_JUNCTION)
		handback |= SOUTHEAST_JUNCTION
	if(junction & SOUTHEAST_JUNCTION)
		handback |= NORTHWEST_JUNCTION
	return handback

/proc/reverse_smoothing_junction_to_dir(ndir)
	switch(ndir)
		if(NORTH_JUNCTION)
			return NORTH
		if(SOUTH_JUNCTION)
			return SOUTH
		if(WEST_JUNCTION)
			return WEST
		if(EAST_JUNCTION)
			return EAST
		if(NORTHWEST_JUNCTION)
			return NORTHWEST
		if(NORTHEAST_JUNCTION)
			return NORTHEAST
		if(SOUTHEAST_JUNCTION)
			return SOUTHEAST
		if(SOUTHWEST_JUNCTION)
			return SOUTHWEST
		if(NORTH_JUNCTION | WEST_JUNCTION)
			return NORTHWEST
		if(NORTH_JUNCTION | EAST_JUNCTION)
			return NORTHEAST
		if(SOUTH_JUNCTION | WEST_JUNCTION)
			return SOUTHWEST
		if(SOUTH_JUNCTION | EAST_JUNCTION)
			return SOUTHEAST
		if(NORTH_JUNCTION | WEST_JUNCTION | NORTHWEST_JUNCTION)
			return NORTHWEST
		if(NORTH_JUNCTION | EAST_JUNCTION | NORTHEAST_JUNCTION)
			return NORTHEAST
		if(SOUTH_JUNCTION | WEST_JUNCTION | SOUTHWEST_JUNCTION)
			return SOUTHWEST
		if(SOUTH_JUNCTION | EAST_JUNCTION | SOUTHEAST_JUNCTION)
			return SOUTHEAST
		else
			return NONE

/proc/smooth_zlevel_bitmask(zlevel, now = FALSE)
	var/list/away_turfs = block(locate(1, 1, zlevel), locate(world.maxx, world.maxy, zlevel))
	for(var/turf/turf_to_smooth as anything in away_turfs)
		if(!(turf_to_smooth.flags_1 & INITIALIZED_1))
			continue
		if(turf_to_smooth.smoothing_flags & USES_SMOOTHING)
			if(now)
				turf_to_smooth.smooth_icon_bitmask()
			else
				QUEUE_SMOOTH(turf_to_smooth)
		for(var/atom/movable/movable_to_smooth as anything in turf_to_smooth)
			if(!(movable_to_smooth.flags_1 & INITIALIZED_1))
				continue
			if(movable_to_smooth.smoothing_flags & USES_SMOOTHING)
				if(now)
					movable_to_smooth.smooth_icon_bitmask()
				else
					QUEUE_SMOOTH(movable_to_smooth)

/atom/proc/set_can_smooth_with(canSmoothWith)
	if(!canSmoothWith)
		src.canSmoothWith = null
		return
	PARSE_CAN_SMOOTH_WITH(canSmoothWith, src.canSmoothWith, smoothing_flags)

/atom/proc/set_smoothing_groups(smoothing_groups)
	if(!smoothing_groups)
		src.smoothing_groups = null
		return
	PARSE_SMOOTHING_GROUPS(smoothing_groups, src.smoothing_groups)

/proc/queue_smooth_bitmask_neighbors(atom/A)
	for(var/atom/T in orange(1, A))
		if(T.smoothing_flags & USES_SMOOTHING)
			QUEUE_SMOOTH(T)

/proc/queue_smooth_bitmask(atom/A)
	if(!(A.smoothing_flags & USES_SMOOTHING) || A.smoothing_flags & SMOOTH_QUEUED)
		return
	SSicon_smooth.add_to_queue(A)
