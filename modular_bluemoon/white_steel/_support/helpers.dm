//WHITE-STEEL PORT - хелперы и обвязка совместимости с bluemoon

//Проcтейшие хелперы, отсутствующие в bluemoon
/proc/invertDir(input_dir)
	switch(input_dir)
		if(UP)
			return DOWN
		if(DOWN)
			return UP
		if(-INFINITY to 0, 11 to INFINITY)
			CRASH("Can't turn invalid directions!")
	return turn(input_dir, 180)

/proc/dir2ru_text(direction)
	switch(direction)
		if(NORTH)
			return "север"
		if(SOUTH)
			return "юг"
		if(EAST)
			return "восток"
		if(WEST)
			return "запад"
		if(NORTHEAST)
			return "северо-восток"
		if(SOUTHEAST)
			return "юго-восток"
		if(NORTHWEST)
			return "северо-запад"
		if(SOUTHWEST)
			return "юго-запад"
	return "неизвестность"

/area/proc/get_unobstructed_turfs()
	var/list/turf/unobstructed = list()
	for(var/turf/T in contents)
		var/contains_dense = FALSE
		for(var/atom/A in T.contents)
			if(A.density)
				contains_dense = TRUE
				break
		if(!contains_dense)
			unobstructed.Add(T)
			break
	return unobstructed

//В bluemoon нет виртуальных z-уровней, поэтому маппинг тождественный
/turf/proc/get_virtual_z_level()
	return z

//Визуальный импульс для пеленгатора и сканера
/proc/pulse_effect(turf/T, radius)
	if(!T)
		return
	new /obj/effect/temp_visual/pulse_ring(T, radius)

/obj/effect/temp_visual/pulse_ring
	icon = 'icons/effects/alphacolors.dmi'
	icon_state = "white"
	duration = 12
	layer = ABOVE_OPEN_TURF_LAYER

/obj/effect/temp_visual/pulse_ring/Initialize(mapload, radius = 4)
	. = ..()
	transform = matrix().Scale(0.2, 0.2)
	animate(src, transform = matrix().Scale(radius * 2, radius * 2), alpha = 0, time = duration, flags = ANIMATION_PARALLEL)

//Залп иерофантовых снарядов (упрощённая замена white-прока)
/proc/hierophant_burst(atom/caster, turf/T, count = 4)
	if(!T)
		return
	for(var/i in 1 to count)
		var/obj/effect/temp_visual/hierophant/chaser/C = new(T, caster, null, 3, FALSE)
		C.moving = 3
		C.moving_dir = pick(GLOB.cardinals)
		C.damage = 20

//Химический вихрь (порт из white code/modules/reagents/chemistry/recipes.dm)
/proc/goonchem_vortex(turf/T, setting_type, affect_range)
	for(var/atom/movable/X in orange(affect_range, T))
		if(X.anchored)
			continue
		if(iseffect(X) || isdead(X))
			continue
		var/distance = get_dist(X, T)
		var/moving_power = max(affect_range - distance, 1)
		if(moving_power > 2)
			if(setting_type)
				var/atom/throw_target = get_edge_target_turf(X, get_dir(X, get_step_away(X, T)))
				X.throw_at(throw_target, moving_power, 1)
			else
				X.throw_at(T, moving_power, 1)
		else
			if(setting_type)
				step_away(X, T)
			else
				step_towards(X, T)

//Корректировка старых портов/консолей (bluemoon хранит стыковочные порты иначе)
/obj/docking_port/mobile
	var/datum/orbital_object/shuttle/shuttle_object_type = /datum/orbital_object/shuttle
