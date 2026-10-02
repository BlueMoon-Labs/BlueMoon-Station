/datum/map_template/ruin_part
	keep_cached_map = TRUE
	var/file_name = ""
	var/typegen = "RuinGeneration"
	//Weight of the ruin part.
	var/weight = 0
	//Positions of the connection points.
	var/connection_points = list()
	//Positions of floors.
	var/floor_locations = list()
	//Max occurances of this room.
	var/max_occurances = INFINITY
	//Is this a loot room (Only 1 loot room spawns per station)
	var/loot_room = FALSE
	//Special flags for special fags
	var/special_flags = RUIN_PART_DEFAULT

/datum/map_template/ruin_part/New(path, rename, cache)
	mappath = "_maps/[typegen]/[file_name].dmm"
	. = ..(path, rename, TRUE)
	find_connection_points()
	name = "[file_name]"

//=======
// Absolute shitcode of a proc right here
// Copy paste but editted.
//=======

//Finds connection points on a template without actually spawning it
/datum/map_template/ruin_part/proc/find_connection_points()

	if(!cached_map)
		CRASH("Map [file_name] is fucking retarded, damn")

	var/key_len = cached_map.key_len

	var/list/modelCache = cached_map.build_cache()

	for(var/I in cached_map.gridSets)
		var/datum/grid_set/gset = I
		var/ycrd = gset.ycrd

		for(var/line in gset.gridLines)
			if(ycrd <= world.maxy && ycrd >= 1)
				var/xcrd = gset.xcrd
				for(var/tpos = 1 to length(line) - key_len + 1 step key_len)
					if(xcrd >= 1)
						var/model_key = copytext(line, tpos, tpos + key_len)
						var/list/cache = modelCache[model_key]
						if(!cache)
							CRASH("Undefined model key in DMM: [model_key]")
						build_coordinate(cache, xcrd, ycrd)
						CHECK_TICK
					++xcrd
			--ycrd

		CHECK_TICK

/datum/map_template/ruin_part/proc/build_coordinate(list/model, xcrd, ycrd)
	var/index
	var/list/members = model[1]
	var/list/members_attributes = model[2]

	////////////////
	//Instanciation
	////////////////

	//The next part of the code assumes there's ALWAYS an /area AND a /turf on a given tile
	//first instance the /area and remove it from the members list
	index = members.len

	//then instance the /turf and, if multiple tiles are presents, simulates the DMM underlays piling effect

	var/first_turf_index = 1
	while(first_turf_index <= members.len && !ispath(members[first_turf_index], /turf)) //find first /turf object in members
		first_turf_index++

	if(first_turf_index > members.len)
		//WHITE-STEEL PORT: тайл без /turf в своих членах (например, только зона).
		//Пропускаем его, чтобы не ронять генератор руины.
		log_game("Ruin part [file_name] has a tile at [xcrd]_[ycrd] without a turf member, skipping.")
		return

	if(ispath(members[first_turf_index], /turf/open))
		floor_locations["[xcrd]_[ycrd]"] = TRUE

	//finally instance all remainings objects/mobs
	for(index in 1 to first_turf_index-1)
		instance_atom(members[index],members_attributes[index], xcrd, ycrd)

/datum/map_template/ruin_part/proc/instance_atom(path,list/attributes, xcrd, ycrd)
	var/dir = SOUTH

	if(attributes.Find("dir"))
		dir = attributes["dir"]
		if(istext(dir))
			dir = text2num(dir)

	if(ispath(path, /obj/effect/abstract/open_area_marker))
		connection_points["[xcrd]_[ycrd]"] = OPEN_CONNECTION * dir
	else if(ispath(path, /obj/effect/abstract/doorway_marker))
		connection_points["[xcrd]_[ycrd]"] = ROOM_CONNECTION * dir

	//custom CHECK_TICK here because we don't want things created while we're sleeping to not initialize
	if(TICK_CHECK)
		stoplag()
