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

/// Клик по пустому клоункару не должен рантаймить на LAZY-списке пассажиров.
/datum/unit_test/car_attacked_by_empty/Run()
	var/obj/vehicle/sealed/car/clowncar/car = allocate(/obj/vehicle/sealed/car/clowncar)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/weapon = allocate(/obj/item)
	weapon.force = 5
	car.attacked_by(weapon, attacker)
	TEST_ASSERT_NULL(LAZYACCESS(car.occupants, attacker), "Атакующий не должен был оказаться в occupants")
