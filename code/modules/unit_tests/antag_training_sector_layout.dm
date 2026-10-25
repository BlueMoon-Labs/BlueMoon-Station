/// Загруженные сектора и вестибюль хаба без наложений: одна плотная вещь на клетку, стул не на столе, вещи не на плотных машинах, диваны цепочкой.
/datum/unit_test/antag_training_sector_layout/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон готовится.")
	TEST_ASSERT(session.arena.hub?.ready, "Вестибюль хаба загружен.")
	for(var/turf/place as anything in session.arena.hub.turfs)
		check_turf(place, "hub")
	for(var/sector_id in session.arena.sectors)
		var/datum/antag_training_sector/sector = session.arena.sectors[sector_id]
		TEST_ASSERT(sector.load(), "Сектор [sector_id] загружается.")
		for(var/turf/place as anything in sector.turfs)
			check_turf(place, sector_id)

/datum/unit_test/antag_training_sector_layout/proc/check_turf(turf/place, sector_id)
	var/blockers = 0
	var/has_surface = FALSE
	var/has_seat = FALSE
	var/obj/blocker
	for(var/obj/thing in place)
		if(istype(thing, /obj/structure/table) || istype(thing, /obj/structure/rack))
			has_surface = TRUE
		if(istype(thing, /obj/structure/chair) && !istype(thing, /obj/structure/chair/stool))
			has_seat = TRUE
	for(var/obj/thing in place)
		// Микроволновка и прочее настольное стоит на столе.
		if(has_surface && istype(thing, /obj/machinery))
			continue
		if(!thing.density || (thing.flags_1 & ON_BORDER_1) || istype(thing, /obj/machinery/door) || istype(thing, /obj/structure/window) || istype(thing, /obj/structure/grille))
			continue
		blockers++
		blocker = thing
	TEST_ASSERT(blockers <= 1, "[sector_id] [place.x],[place.y]: [blockers] плотных вещей на клетке.")
	TEST_ASSERT(!(has_seat && has_surface), "[sector_id] [place.x],[place.y]: стул стоит на столе или стеллаже.")
	if(blocker && !has_surface && !istype(blocker, /obj/structure/closet))
		for(var/obj/item/item in place)
			TEST_FAIL("[sector_id] [place.x],[place.y]: [item.type] лежит на [blocker.type].")
	for(var/obj/structure/chair/sofa/seat in place)
		check_sofa(seat, sector_id)

/datum/unit_test/antag_training_sector_layout/proc/check_sofa(obj/structure/chair/sofa/seat, sector_id)
	var/end = findtext("[seat.type]", "/left") || findtext("[seat.type]", "/right")
	var/middle = findtext("[seat.type]", "/middle")
	if(!end && !middle)
		return
	var/axis = (seat.dir & (NORTH|SOUTH)) ? EAST : NORTH
	var/neighbours = 0
	for(var/step_dir in list(axis, REVERSE_DIR(axis)))
		for(var/obj/structure/chair/sofa/other in get_step(seat, step_dir))
			if(other.dir == seat.dir)
				neighbours++
	if(middle)
		TEST_ASSERT_EQUAL(neighbours, 2, "[sector_id] [seat.x],[seat.y]: середина дивана без соседей с двух сторон.")
	else
		TEST_ASSERT_EQUAL(neighbours, 1, "[sector_id] [seat.x],[seat.y]: конец дивана не на краю ряда.")
