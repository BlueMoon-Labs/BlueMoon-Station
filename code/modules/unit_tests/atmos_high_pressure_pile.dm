// Фаза high-pressure и завалы после взрывов (раунд 9911): MC_TICK_CHECK стоит
// только МЕЖДУ турфами, поэтому куча из сотен предметов на одном тайле
// обрабатывалась одним атомарным куском по 300+мс внутри слота SSair, а визуал
// ветра плодился на каждом проходе и раздувал очередь GC до 47 тысяч.

/// Кап попыток движения за проход: остаток кучи дожуют следующие проходы, пока
/// ветер держится, но ни один турф больше не съедает треть тика одним куском.
/datum/unit_test/high_pressure_pile_cap/Run()
	TEST_ASSERT(SSair.times_fired > 0, "SSair ещё ни разу не отработал - гейт по циклам не отличит свежие предметы")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/pile = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(pile), "нет открытого турфа для кучи")

	var/item_count = HIGH_PRESSURE_MOVES_PER_TURF + 10
	for(var/i in 1 to item_count)
		allocate(/obj/item/shard, pile)

	// Сила ниже порога броска: предметы шагают на соседний тайл, а не летят
	// через всю резервацию. move_prob при таком перепаде выходит за 100,
	// поэтому исход детерминирован.
	pile.pressure_vector_x = 150
	pile.pressure_vector_y = 0
	pile.high_pressure_movements()

	var/stayed = 0
	for(var/obj/item/shard/debris in pile)
		stayed++
	var/moved = item_count - stayed
	TEST_ASSERT_EQUAL(moved, HIGH_PRESSURE_MOVES_PER_TURF, "за один проход обязан сдвинуться ровно кап предметов, сдвинулось [moved] из [item_count]")

	pile.pressure_vector_x = 0
	pile.pressure_difference = 0
	pile.pressure_direction = NONE
	for(var/obj/effect/temp_visual/dir_setting/space_wind/wind in pile)
		qdel(wind)

/// Повторный проход в пределах кулдауна не имеет права плодить второй визуал
/// ветра: живой ещё не отыграл свою анимацию.
/datum/unit_test/space_wind_visual_cooldown/Run()
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/subject = locate(origin.x + 3, origin.y + 1, origin.z)
	TEST_ASSERT(istype(subject), "нет открытого турфа для визуала")

	subject.pressure_vector_x = 150
	subject.high_pressure_movements()
	subject.pressure_vector_x = 150
	subject.high_pressure_movements()

	var/winds = 0
	for(var/obj/effect/temp_visual/dir_setting/space_wind/wind in subject)
		winds++
		qdel(wind)
	TEST_ASSERT_EQUAL(winds, 1, "два прохода в один тик создали [winds] визуала ветра вместо одного")

	subject.pressure_vector_x = 0
	subject.pressure_difference = 0
	subject.pressure_direction = NONE
	subject.next_space_wind_at = 0
