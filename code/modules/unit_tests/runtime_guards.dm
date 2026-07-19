/// UI эмпориума генлинга с исчезнувшим антаг-датумом не должен рантаймить.
/datum/unit_test/cellular_emporium_null_changeling/Run()
	// Не через allocate(): он подменяет первый null-аргумент турфом, а нам нужен именно null-генлинг.
	var/datum/cellular_emporium/emporium = new(null)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/list/data = emporium.ui_data(user)
	var/abilities = islist(data) ? data["abilities"] : "не список"
	emporium.ui_act("readapt", list())
	qdel(emporium)
	TEST_ASSERT(islist(data), "ui_data без генлинга должен вернуть список")
	TEST_ASSERT_NULL(abilities, "ui_data без генлинга не должен собирать способности")

/// Волна Door Runtime обязана молча пропускать удалённые двери.
/datum/unit_test/door_runtime_wave_skips_deleted/Run()
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock)
	var/list/doors = list(door)
	qdel(door)
	door_runtime_set_lockdown(doors, TRUE)
	door_runtime_set_lockdown(doors, FALSE)
	TEST_ASSERT(!door.locked, "Удалённая дверь не должна была получить локдаун")

/// qdel-нутый мувер не должен возвращаться в мир: гард в doMove отказывает
/// и трассирует виновника (класс "post-qdel forceMove" из улик раунда 9746).
/datum/unit_test/no_post_qdel_move
	allowed_runtime_patterns = list("doMove qdel-нутого")

/datum/unit_test/no_post_qdel_move/Run()
	var/obj/item/thing = allocate(/obj/item)
	qdel(thing)
	TEST_ASSERT_NULL(thing.loc, "qdel не увёл предмет в nullspace")
	thing.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(thing.loc, "qdel-нутый предмет вернулся в мир через forceMove")

/// Кап активной пены глушит спред, а без капа спред работает.
/datum/unit_test/foam_active_cap/Run()
	var/obj/effect/particle_effect/foam/foam = allocate(/obj/effect/particle_effect/foam)
	foam.amount = 5
	var/turf/foam_turf = get_turf(foam)
	var/saved_count = GLOB.foam_active_count

	GLOB.foam_active_count = 99999
	foam.spread_foam()
	var/spread_over_cap = FALSE
	for(var/turf/adjacent in foam_turf.GetAtmosAdjacentTurfs())
		if(locate(/obj/effect/particle_effect/foam) in adjacent)
			spread_over_cap = TRUE
			break
	TEST_ASSERT(!spread_over_cap, "Спред пены прошёл сквозь кап FOAM_ACTIVE_CAP")

	GLOB.foam_active_count = saved_count
	foam.spread_foam()
	var/spread_normally = FALSE
	for(var/turf/adjacent in foam_turf.GetAtmosAdjacentTurfs())
		var/obj/effect/particle_effect/foam/new_foam = locate() in adjacent
		if(new_foam)
			spread_normally = TRUE
			break
	// Расползшуюся пену подчистит Destroy() базового теста - он qdel-ит содержимое зоны.
	TEST_ASSERT(spread_normally, "Обычный спред пены перестал работать")

/// Клик по пустому клоункару не должен рантаймить на LAZY-списке пассажиров.
/datum/unit_test/car_attacked_by_empty/Run()
	var/obj/vehicle/sealed/car/clowncar/car = allocate(/obj/vehicle/sealed/car/clowncar)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/weapon = allocate(/obj/item)
	weapon.force = 5
	car.attacked_by(weapon, attacker)
	TEST_ASSERT_NULL(LAZYACCESS(car.occupants, attacker), "Атакующий не должен был оказаться в occupants")
