#define DARK_TEST_LIGHT 0.2
#define DARK_TEST_LIT_SHARE 0.25
#define DARK_TEST_SETTLE (2 SECONDS)

/// Нижний ярус: одна-две мигающие аварийные лампы, остальные плафоны разбиты, проход засады и большая часть пола в темноте.
/datum/unit_test/antag_training_sector_dark/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["dark"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/list/emergency = list()
	var/list/whole = list()
	var/fixtures = 0
	for(var/turf/tile as anything in sector.turfs)
		for(var/obj/machinery/light/lamp in tile)
			fixtures++
			if(istype(lamp, /obj/machinery/light/small/red/antag_training_flicker))
				emergency += lamp
			else if(lamp.status == LIGHT_OK)
				whole += "[lamp.x],[lamp.y]"
	TEST_ASSERT(length(emergency) >= 1 && length(emergency) <= 2, "В секторе одна-две аварийные лампы, а не [length(emergency)].")
	TEST_ASSERT(fixtures > length(emergency), "Кроме аварийных, в секторе есть разбитые плафоны.")
	TEST_ASSERT(!length(whole), "Обычные плафоны разбиты: [whole.Join("; ")].")

	var/settled_at = world.time + DARK_TEST_SETTLE
	while(world.time < settled_at)
		sleep(world.tick_lag)
	for(var/obj/machinery/light/small/red/antag_training_flicker/lamp as anything in emergency)
		TEST_ASSERT_EQUAL(lamp.status, LIGHT_OK, "Аварийная лампа [lamp.x],[lamp.y] цела после загрузки.")
		TEST_ASSERT(lamp.on, "Аварийная лампа [lamp.x],[lamp.y] горит.")
		TEST_ASSERT(lamp.damage_flickering, "Аварийная лампа [lamp.x],[lamp.y] мигает.")

	var/datum/antag_training_exercise/drill/dark/ambush/ambush = GLOB.antag_training_exercises["dark_ambush"]
	var/turf/route = ambush.runner_route(sector)
	TEST_ASSERT_NOTNULL(route, "У входа есть проход для засады.")
	TEST_ASSERT(route.get_lumcount() < DARK_TEST_LIGHT, "Проход засады в темноте.")
	var/floors = 0
	var/lit = 0
	for(var/turf/open/floor/tile in sector.turfs)
		floors++
		if(tile.get_lumcount() >= DARK_TEST_LIGHT)
			lit++
	TEST_ASSERT(floors && lit / floors < DARK_TEST_LIT_SHARE, "Освещено [lit] клеток пола из [floors]: тьма должна остаться.")

#undef DARK_TEST_LIGHT
#undef DARK_TEST_LIT_SHARE
#undef DARK_TEST_SETTLE
