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

/// Повторное заражение яйцами террора заменяет старый одноразовый орган.
/// Его Remove() сам вызывает qdel(), поэтому общий Insert() не должен затем
/// пытаться выложить удалённый орган на пол.
/datum/unit_test/terror_egg_replacement_skips_deleted_organ/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	var/obj/item/organ/body_egg/terror_eggs/first_egg = new(host)
	var/obj/item/organ/body_egg/terror_eggs/replacement_egg = new(host)

	TEST_ASSERT(QDELETED(first_egg), "Заменённые яйца террора не удалились")
	TEST_ASSERT_EQUAL(replacement_egg.owner, host, "Новые яйца террора не установились после замены")
	TEST_ASSERT_EQUAL(host.getorganslot(replacement_egg.slot), replacement_egg, "Слот паразита не указывает на новые яйца")

/// Деталь модульного компьютера удаляют прямо в собранном устройстве - так делает
/// QDEL_LIST(contents) при разборке комнаты отеля Гильберта. Её Destroy() зовёт
/// uninstall_component(), и выкладывать удаляемую деталь на пол тот не имеет права:
/// forceMove qdel-нутого атома пинит её ссылкой из contents турфа (гвард в doMove).
/datum/unit_test/computer_component_qdel_stays_out_of_world/Run()
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda)
	var/obj/item/computer_hardware/hard_drive/drive = pda.all_components[MC_HDD]
	TEST_ASSERT_NOTNULL(drive, "Санити: у PDA нет установленного диска")

	qdel(drive)

	TEST_ASSERT_NULL(drive.loc, "Удаляемую деталь выложили в мир из uninstall_component")
	TEST_ASSERT_NULL(pda.all_components[MC_HDD], "PDA не отпустил удалённый диск")
	TEST_ASSERT_NULL(drive.holder, "У удалённой детали остался holder")

/// Снаряд, удалённый в Bump(), не должен продолжать Move() даже если успел включить PHASING.
/obj/structure/unit_test_projectile_bump_blocker
	density = TRUE

/obj/item/projectile/unit_test_qdel_phasing_bump/Bump(atom/bumped_atom)
	movement_type |= PHASING
	qdel(src)

/datum/unit_test/projectile_qdeleted_phasing_bump_stops_move/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/destination = get_step(start, EAST)
	allocate(/obj/structure/unit_test_projectile_bump_blocker, destination)
	var/obj/item/projectile/unit_test_qdel_phasing_bump/projectile = allocate(/obj/item/projectile/unit_test_qdel_phasing_bump, start)

	projectile.Move(destination, EAST)

	TEST_ASSERT(QDELETED(projectile), "Тестовый снаряд не удалился в Bump()")
	TEST_ASSERT_NULL(projectile.loc, "Удалённый снаряд завершил Move() после Bump()")

/// Пена после разлива мигрирует на медленный процессинг, спред при этом работает как раньше.
/datum/unit_test/foam_slow_phase/Run()
	var/obj/effect/particle_effect/foam/foam = allocate(/obj/effect/particle_effect/foam)
	var/turf/foam_turf = get_turf(foam)

	foam.amount = 1
	foam.process() // разлив: должен создать соседнюю пену и остаться на быстром тике
	var/spread_normally = FALSE
	for(var/turf/adjacent in foam_turf.GetAtmosAdjacentTurfs())
		if(locate(/obj/effect/particle_effect/foam) in adjacent)
			spread_normally = TRUE
			break
	// Расползшуюся пену подчистит Destroy() базового теста - он qdel-ит содержимое зоны.
	TEST_ASSERT(spread_normally, "Спред пены перестал работать")
	TEST_ASSERT(!foam.slow_processing, "Пена ушла в медленную фазу до конца разлива")

	foam.process() // amount уходит ниже нуля - конец разлива
	TEST_ASSERT(foam.slow_processing, "Пена не перешла в медленную фазу после разлива")
	TEST_ASSERT(!(foam in SSfastprocess.processing), "Пена осталась в SSfastprocess после миграции")
	TEST_ASSERT(foam in SSprocessing.processing, "Пена не встала в SSprocessing после миграции")

	var/lifetime_before = foam.lifetime
	foam.process() // медленная фаза списывает жизнь с множителем
	TEST_ASSERT_EQUAL(lifetime_before - foam.lifetime, 5, "Медленная фаза должна списывать жизнь с множителем 5")

	var/obj/effect/particle_effect/foam/firefighting/extinguisher_foam = allocate(/obj/effect/particle_effect/foam/firefighting)
	extinguisher_foam.process()
	TEST_ASSERT(!extinguisher_foam.slow_processing, "Пожарная пена не должна уходить с быстрого тика")

/// Клик по пустому клоункару не должен рантаймить на LAZY-списке пассажиров.
/datum/unit_test/car_attacked_by_empty/Run()
	var/obj/vehicle/sealed/car/clowncar/car = allocate(/obj/vehicle/sealed/car/clowncar)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/weapon = allocate(/obj/item)
	weapon.force = 5
	car.attacked_by(weapon, attacker)
	TEST_ASSERT_NULL(LAZYACCESS(car.occupants, attacker), "Атакующий не должен был оказаться в occupants")
