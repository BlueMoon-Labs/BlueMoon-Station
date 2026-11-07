/// Снежное облако расползается на холодный соседний турф.
/datum/unit_test/snowcloud_spreads_to_cold_neighbour/Run()
	var/obj/machinery/snow_machine/machine = allocate(/obj/machinery/snow_machine)
	machine.infinite_snow = TRUE
	machine.cooling_speed = 19
	var/turf/open/center = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y + 1, run_loc_floor_bottom_left.z)
	for(var/turf/open/neighbour in get_adjacent_open_turfs(center))
		neighbour.return_air().set_temperature(T0C - 5)
	var/obj/effect/snowcloud/cloud = allocate(/obj/effect/snowcloud, center, machine)
	cloud.try_to_spread_cloud()
	var/spread = FALSE
	for(var/turf/open/neighbour in get_adjacent_open_turfs(center))
		for(var/obj/effect/snowcloud/new_cloud in neighbour)
			spread = TRUE
			qdel(new_cloud)
	TEST_ASSERT(spread, "облако не расползлось ни на один холодный соседний турф")

/// Отказанный перенос шнура обратно в имплант не уходит в бесконечную рекурсию.
/datum/unit_test/arm_implant_retract_refused_move/Run()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/arm/power_cord/implant = new
	implant.Insert(body)
	var/obj/item/apc_powercord/cord = locate() in implant
	TEST_ASSERT_NOTNULL(cord, "в импланте нет шнура")
	implant.Extend(cord)
	TEST_ASSERT(cord in body.held_items, "шнур не вышел в руку")
	var/datum/gone_arena = new
	cord.training_origin = WEAKREF(gone_arena)
	qdel(gone_arena)
	implant.Retract()
	cord.training_origin = null
	TEST_ASSERT_NULL(implant.holder, "имплант держит шнур после втягивания")

/// Кнопка модуля без МОДа удаляется, а не падает.
/datum/unit_test/mod_module_button_without_suit/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/mod/module/module = allocate(/obj/item/mod/module)
	var/datum/action/cooldown/module_action/button = new(module)
	button.Grant(wearer)
	button.Trigger(0)
	TEST_ASSERT(QDELETED(button), "кнопка модуля без МОДа не удалилась")

/// Автоматический сбор реплика-пода не создаёт пустого человека.
/datum/unit_test/replicapod_userless_harvest/Run()
	var/obj/machinery/hydroponics/constructable/tray = allocate(/obj/machinery/hydroponics/constructable)
	var/obj/item/seeds/replicapod/seed = new(tray)
	tray.myseed = seed
	tray.harvest = TRUE
	seed.harvest_userless()
	for(var/mob/living/carbon/human/stray in get_turf(tray))
		TEST_FAIL("автосбор реплика-пода создал [stray]")
		qdel(stray)
	TEST_ASSERT(locate(/obj/item/seeds/replicapod) in get_turf(tray), "автосбор реплика-пода не вернул семена")
