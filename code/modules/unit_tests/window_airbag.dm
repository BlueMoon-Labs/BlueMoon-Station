/// The whole point of the module is that a broken window stops being a hole in
/// the hull for a while. If the membrane spawns but does not actually block the
/// tile, the feature looks like it works and does nothing at all.
/datum/unit_test/window_airbag_seals_break/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	TEST_ASSERT(istype(room), "test location is not an open turf")

	// air_update_turf only queues the recalculation, so the test drives it by hand
	// at each step; what is under test is whether the membrane blocks, not when
	// SSair gets around to noticing. The baseline is taken on the bare tile - a
	// full tile window blocks the air by itself, which would prove nothing.
	room.ImmediateCalculateAdjacentTurfs()
	var/adjacent_before = LAZYLEN(room.atmos_adjacent_turfs)
	TEST_ASSERT(adjacent_before, "the test tile has no atmos neighbours to begin with")

	var/obj/structure/window/glass = allocate(/obj/structure/window/reinforced/fulltile, room)
	var/obj/item/airbag_module/module = allocate(/obj/item/airbag_module, room)
	glass.airbag = module
	module.forceMove(glass)

	glass.deconstruct(FALSE)

	var/obj/structure/inflatable/airbag/membrane = locate() in room
	TEST_ASSERT_NOTNULL(membrane, "breaking a window with an airbag left no membrane behind")
	TEST_ASSERT_EQUAL(membrane.CanAtmosPass, ATMOS_PASS_NO, "the membrane does not block air")
	TEST_ASSERT(module.spent, "the module survived deployment unspent")
	room.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT_EQUAL(LAZYLEN(room.atmos_adjacent_turfs), 0,
		"the tile still shares air with [LAZYLEN(room.atmos_adjacent_turfs)] neighbour(s) through the membrane")

	// And it has to give the tile back, or one broken window seals a doorway forever.
	qdel(membrane)
	room.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT_EQUAL(LAZYLEN(room.atmos_adjacent_turfs), adjacent_before,
		"the tile did not go back to sharing air after the membrane was gone")

/// Taking a window apart on purpose is not an emergency, so the module has to
/// come back out in one piece rather than be burned on nothing.
/datum/unit_test/window_airbag_survives_disassembly/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	var/obj/structure/window/glass = allocate(/obj/structure/window/reinforced/fulltile, room)
	var/obj/item/airbag_module/module = allocate(/obj/item/airbag_module, room)
	glass.airbag = module
	module.forceMove(glass)

	glass.deconstruct(TRUE)

	TEST_ASSERT(!module.spent, "disassembling the window spent the airbag")
	TEST_ASSERT_EQUAL(module.loc, room, "the airbag did not end up on the floor after disassembly")
	TEST_ASSERT_NULL(locate(/obj/structure/inflatable/airbag) in room,
		"disassembling the window inflated the membrane anyway")

/// Восемь модулей из вендора - это восемь окон на всю смену, и с одноразовым
/// модулем функцией просто не начинают пользоваться. Порванная мембрана
/// складывается заново из пластика, и модуль после этого снова рабочий.
/datum/unit_test/window_airbag_repack/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	var/obj/item/airbag_module/module = allocate(/obj/item/airbag_module/spent, room)
	var/obj/item/stack/sheet/plastic/patch = allocate(/obj/item/stack/sheet/plastic, room)
	patch.amount = 4
	TEST_ASSERT(module.spent, "предпосылка: модуль должен быть отработавшим")

	TEST_ASSERT(module.repack(null, patch), "перепаковка отработавшего модуля не прошла")
	TEST_ASSERT(!module.spent, "перепакованный модуль остался отработавшим")
	TEST_ASSERT_EQUAL(module.icon_state, initial(module.icon_state), "перепакованный модуль остался с порванным спрайтом")
	TEST_ASSERT_EQUAL(patch.amount, 2, "перепаковка списала не то количество пластика")

	// Целый модуль перепаковывать нечего - иначе пластик уходит в никуда.
	TEST_ASSERT(!module.repack(null, patch), "целый модуль дал себя перепаковать")
	TEST_ASSERT_EQUAL(patch.amount, 2, "отказ в перепаковке всё равно списал пластик")

	// И пустой пачкой пластика тоже нельзя: модуль обязан остаться порванным.
	var/obj/item/airbag_module/second = allocate(/obj/item/airbag_module/spent, room)
	patch.amount = 1
	TEST_ASSERT(!second.repack(null, patch), "одного листа хватило на перепаковку")
	TEST_ASSERT(second.spent, "неудачная перепаковка всё равно зарядила модуль")

/// The colour adapter exists so a network can cross a paint boundary on purpose.
/// If it stops joining either side, it is worse than the grey pipe it replaces.
/datum/unit_test/color_adapter_bridges_paint/Run()
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/east = locate(room.x + 1, room.y, room.z)
	var/turf/open/west = locate(room.x - 1, room.y, room.z)
	TEST_ASSERT(istype(east) && istype(west), "test location has no open turfs on both sides")

	var/obj/machinery/atmospherics/pipe/color_adapter/adapter = allocate(/obj/machinery/atmospherics/pipe/color_adapter, room)
	var/obj/machinery/atmospherics/pipe/simple/red = allocate(/obj/machinery/atmospherics/pipe/simple, west)
	var/obj/machinery/atmospherics/pipe/simple/blue = allocate(/obj/machinery/atmospherics/pipe/simple, east)
	for(var/obj/machinery/atmospherics/piece as anything in list(adapter, red, blue))
		piece.setDir(EAST)
		piece.SetInitDirections()
	red.pipe_color = GLOB.pipe_paint_colors["red"]
	blue.pipe_color = GLOB.pipe_paint_colors["blue"]

	TEST_ASSERT(!red.connection_check(blue, red.piping_layer),
		"two differently painted pipes connected without an adapter between them")
	TEST_ASSERT(adapter.connection_check(red, adapter.piping_layer), "the adapter refused the red side")
	TEST_ASSERT(adapter.connection_check(blue, adapter.piping_layer), "the adapter refused the blue side")
	TEST_ASSERT(!adapter.paintable, "the adapter can be painted, which would mean nothing")
	TEST_ASSERT(!adapter.paint(GLOB.pipe_paint_colors["red"]), "painting the adapter reported success")
