/// Сколько живых декалей лежит на турфе.
/proc/unit_test_count_turf_cleanables(turf/target)
	. = 0
	for(var/obj/effect/decal/cleanable/decal in target)
		if(QDELETED(decal))
			continue
		. += 1

/// Пул разнотипных декалей: разные типы не схлопываются через replace_decal().
/proc/unit_test_cleanable_filler_types()
	return list(
		/obj/effect/decal/cleanable/dirt,
		/obj/effect/decal/cleanable/dirt/dust,
		/obj/effect/decal/cleanable/ash,
		/obj/effect/decal/cleanable/generic,
		/obj/effect/decal/cleanable/glass,
		/obj/effect/decal/cleanable/cobweb,
		/obj/effect/decal/cleanable/cobweb/cobweb2,
		/obj/effect/decal/cleanable/shreds,
		/obj/effect/decal/cleanable/molten_object,
		/obj/effect/decal/cleanable/insectguts,
		/obj/effect/decal/cleanable/salt,
		/obj/effect/decal/cleanable/wrapping,
	)

/// Каждое создание декали оставляет турф под CLEANABLE_DECAL_TURF_CAP.
/datum/unit_test/cleanable_decal_turf_cap_holds/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/list/filler_types = unit_test_cleanable_filler_types()
	TEST_ASSERT(length(filler_types) > CLEANABLE_DECAL_TURF_CAP, "Пул наполнителей ([length(filler_types)] типов) должен быть больше капа ([CLEANABLE_DECAL_TURF_CAP]), иначе тест ничего не проверяет")

	var/placed = 0
	for(var/decal_type as anything in filler_types)
		new decal_type(arena)
		placed++
		var/on_turf = unit_test_count_turf_cleanables(arena)
		TEST_ASSERT(on_turf <= CLEANABLE_DECAL_TURF_CAP, "После [placed] положенных декалей на турфе [on_turf] декалей при капе [CLEANABLE_DECAL_TURF_CAP]")

	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан быть забит ровно до капа после [placed] положенных декалей [length(filler_types)] разных типов")

/// Кап поглощает старую декаль своего типа и забирает её реагенты, кровь и форензику.
/datum/unit_test/cleanable_decal_turf_cap_absorbs_same_type/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/list/filler_types = unit_test_cleanable_filler_types()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP - 1)
		var/decal_type = filler_types[i]
		new decal_type(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP - 1, "Наполнители должны были лечь все: они разных типов и до капа ещё одно место")

	var/obj/effect/decal/cleanable/blood/gibs/first = new(arena)
	TEST_ASSERT(!QDELETED(first), "Первый гиб обязан уместиться: турф ровно на капе, а не сверх него")
	first.fingerprints = list("ТЕСТОВЫЙ-ОТПЕЧАТОК" = "ТЕСТОВЫЙ-ОТПЕЧАТОК")
	first.suit_fibers = list("Тестовое волокно")
	first.blood_DNA["ТЕСТ-ДНК"] = "O-"
	var/first_volume = first.reagents.total_volume
	TEST_ASSERT(first_volume > 0, "Гиб должен нести реагенты (liquidgibs), иначе проверять перенос нечего")

	var/obj/effect/decal/cleanable/blood/gibs/second = new(arena)
	TEST_ASSERT(!QDELETED(second), "Новая декаль должна оставаться на турфе: кап поглощает старую, а не отменяет новую")
	TEST_ASSERT(QDELETED(first), "Кап обязан поглотить старую декаль СВОЕГО типа, а не чужую")
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф после поглощения должен остаться ровно на капе")

	TEST_ASSERT(second.blood_DNA["ТЕСТ-ДНК"], "ДНК крови поглощённой декали обязана перейти к новой: иначе кап стирает улики")
	TEST_ASSERT(("Тестовое волокно" in second.suit_fibers), "Волокна поглощённой декали обязаны перейти к новой")
	TEST_ASSERT(second.fingerprints?["ТЕСТОВЫЙ-ОТПЕЧАТОК"], "Отпечатки поглощённой декали обязаны перейти к новой")
	TEST_ASSERT(second.reagents.total_volume > first_volume, "Реагенты поглощённой декали обязаны перейти к новой: у новой [second.reagents.total_volume]ед при собственных [first_volume]ед")

/// Вытесняется самая старая декаль турфа.
/datum/unit_test/cleanable_decal_turf_cap_evicts_oldest/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/list/filler_types = unit_test_cleanable_filler_types()
	var/overflow = 2
	TEST_ASSERT(length(filler_types) >= CLEANABLE_DECAL_TURF_CAP + overflow, "Пул наполнителей мал для проверки вытеснения: нужно [CLEANABLE_DECAL_TURF_CAP + overflow] типов, есть [length(filler_types)]")

	var/list/placed = list()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP + overflow)
		var/decal_type = filler_types[i]
		placed += new decal_type(arena)

	for(var/i in 1 to overflow)
		var/obj/effect/decal/cleanable/evicted = placed[i]
		TEST_ASSERT(QDELETED(evicted), "Декаль №[i] ([evicted.type]) - одна из самых старых на турфе и обязана была уйти под кап")

	for(var/i in (overflow + 1) to length(placed))
		var/obj/effect/decal/cleanable/survivor = placed[i]
		TEST_ASSERT(!QDELETED(survivor), "Декаль №[i] ([survivor.type]) моложе вытесненных и обязана была остаться")

	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан остаться ровно на капе")

/// Гиб в streak() оседает на соседнем турфе мимо Initialize, поэтому кап досылается руками.
/// Сам streak() тут не зовётся: он waitfor = FALSE и решает дальность через prob().
/datum/unit_test/cleanable_decal_turf_cap_after_move/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")
	var/turf/neighbour = locate(arena.x + 1, arena.y, arena.z)
	TEST_ASSERT_NOTNULL(neighbour, "Арене теста нужен сосед с востока, откуда приедет гиб")

	var/list/filler_types = unit_test_cleanable_filler_types()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP)
		var/decal_type = filler_types[i]
		new decal_type(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан стоять ровно на капе до приезда гиба")

	var/obj/effect/decal/cleanable/blood/gibs/traveller = new(neighbour)
	traveller.forceMove(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP + 1, "Премиса теста: переезд декали идёт мимо Initialize и пробивает кап")

	traveller.enforce_turf_decal_cap()
	TEST_ASSERT(!QDELETED(traveller), "Досылка капа не должна убивать саму приехавшую декаль")
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Досылка капа обязана вернуть турф под кап")

/// Настоящий streak() по полосе забитых турфов не оставляет ни один из них сверх капа.
/datum/unit_test/cleanable_decal_turf_cap_gib_streak/Run()
	var/turf/arena = run_loc_floor_bottom_left
	var/list/turf/lane = list(arena, locate(arena.x + 1, arena.y, arena.z), locate(arena.x + 2, arena.y, arena.z))
	for(var/turf/lane_turf as anything in lane)
		TEST_ASSERT_NOTNULL(lane_turf, "Для проверки streak() нужна полоса из трёх турфов на восток")

	var/list/filler_types = unit_test_cleanable_filler_types()
	for(var/turf/lane_turf as anything in lane)
		for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP)
			var/decal_type = filler_types[i]
			new decal_type(lane_turf)
		TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(lane_turf), CLEANABLE_DECAL_TURF_CAP, "Каждый турф полосы обязан стоять ровно на капе перед streak()")

	for(var/attempt in 1 to 10)
		var/obj/effect/decal/cleanable/blood/gibs/gib = new(arena)
		gib.streak(list(EAST))
		for(var/turf/lane_turf as anything in lane)
			var/on_turf = unit_test_count_turf_cleanables(lane_turf)
			TEST_ASSERT(on_turf <= CLEANABLE_DECAL_TURF_CAP, "После streak() №[attempt] на турфе [COORD(lane_turf)] лежит [on_turf] декалей при капе [CLEANABLE_DECAL_TURF_CAP]")

/// Авторские декали (граффити) кап не вытесняет, даже когда они самые старые на турфе.
/datum/unit_test/cleanable_decal_turf_cap_spares_player_art/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/list/filler_types = unit_test_cleanable_filler_types()
	TEST_ASSERT(length(filler_types) > CLEANABLE_DECAL_TURF_CAP, "Пул наполнителей ([length(filler_types)] типов) должен быть больше капа ([CLEANABLE_DECAL_TURF_CAP]), иначе тест ничего не проверяет")

	// Рисунок кладём первым: так он самый старый на турфе и первый кандидат в жертвы.
	var/obj/effect/decal/cleanable/crayon/art = new(arena)
	TEST_ASSERT(art.cap_exempt, "Граффити обязано быть cap_exempt, иначе тест проверяет не тот инвариант")

	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP - 1)
		var/decal_type = filler_types[i]
		new decal_type(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан стоять ровно на капе: рисунок считается в кап наравне с грязью")

	for(var/i in CLEANABLE_DECAL_TURF_CAP to length(filler_types))
		var/decal_type = filler_types[i]
		new decal_type(arena)
		TEST_ASSERT(!QDELETED(art), "Кап вытеснил граффити на [i - CLEANABLE_DECAL_TURF_CAP + 1]-й лишней декали ([decal_type]), хотя авторские декали не вытесняются никогда")
		var/on_turf = unit_test_count_turf_cleanables(arena)
		TEST_ASSERT(on_turf <= CLEANABLE_DECAL_TURF_CAP, "На турфе [on_turf] декалей при капе [CLEANABLE_DECAL_TURF_CAP]: exempt-декаль не должна отменять вытеснение остальных")

	var/obj/effect/decal/cleanable/crayon/second_art = new(arena)
	TEST_ASSERT(!QDELETED(art), "Новое граффити не должно вытеснять старое: оба авторские")
	TEST_ASSERT(!QDELETED(second_art), "Новое граффити обязано лечь на турф")

/// Exempt-декаль рисовать не мешает: на забитом турфе она ложится, вытеснив самую старую грязь.
/datum/unit_test/cleanable_decal_turf_cap_art_still_draws/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/list/filler_types = unit_test_cleanable_filler_types()
	var/list/placed = list()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP)
		var/decal_type = filler_types[i]
		placed += new decal_type(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан стоять ровно на капе до рисования")

	var/obj/effect/decal/cleanable/crayon/art = new(arena)
	TEST_ASSERT(!QDELETED(art), "Граффити обязано лечь на забитый турф: cap_exempt защищает от вытеснения, а не запрещает рисовать")
	var/obj/effect/decal/cleanable/oldest_dirt = placed[1]
	TEST_ASSERT(QDELETED(oldest_dirt), "Рисование на забитом турфе обязано вытеснить самую старую грязь ([oldest_dirt.type]), иначе турф уходит сверх капа")
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф после рисования обязан остаться ровно на капе")

/// Следы одного типа крови схлопываются в один объект и сохраняют направления.
/datum/unit_test/cleanable_footprints_converge_on_one_decal/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/obj/effect/decal/cleanable/blood/footprints/first = new(arena)
	first.entered_dirs |= NORTH
	first.exited_dirs |= SOUTH

	var/obj/effect/decal/cleanable/blood/footprints/second = new(arena)
	TEST_ASSERT(!QDELETED(second), "Новый след должен выживать при схлопывании")
	TEST_ASSERT(QDELETED(first), "Два следа одного типа крови обязаны схлопнуться в один объект")
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 1, "На турфе должен остаться ровно один след")
	TEST_ASSERT(second.entered_dirs & NORTH, "Направления входа схлопнутого следа обязаны перейти выжившему, иначе рисунок следов теряется")
	TEST_ASSERT(second.exited_dirs & SOUTH, "Направления выхода схлопнутого следа обязаны перейти выжившему")

/// Декаль, которую родительский Initialize отбраковывает на любом турфе.
/obj/effect/decal/cleanable/unit_test_stillborn
	name = "stillborn test decal"

/obj/effect/decal/cleanable/unit_test_stillborn/NeverShouldHaveComeHere(turf/T)
	return TRUE

/// Мертворождённая декаль (INITIALIZE_HINT_QDEL) соседей капом не вытесняет.
/datum/unit_test/cleanable_decal_turf_cap_ignores_stillborn/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/list/filler_types = unit_test_cleanable_filler_types()
	var/list/placed = list()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP)
		var/decal_type = filler_types[i]
		placed += new decal_type(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан стоять ровно на капе до мертворождённой декали")

	var/obj/effect/decal/cleanable/unit_test_stillborn/stillborn = new(arena)
	TEST_ASSERT(QDELETED(stillborn), "Премиса теста: мертворождённая декаль обязана быть отбракована родительским Initialize")
	for(var/obj/effect/decal/cleanable/survivor as anything in placed)
		TEST_ASSERT(!QDELETED(survivor), "Мертворождённая декаль вытеснила [survivor.type], хотя сама сейчас исчезнет")
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "После мертворождённой декали турф обязан остаться ровно на капе")

/// Вытесненный капом след отдаёт выжившему направления и типы обуви.
/datum/unit_test/cleanable_decal_turf_cap_keeps_evicted_footprints/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")

	var/obj/effect/decal/cleanable/blood/footprints/oil_prints = new(arena)
	oil_prints.blood_state = BLOOD_STATE_OIL
	oil_prints.entered_dirs |= NORTH
	oil_prints.exited_dirs |= EAST
	oil_prints.shoe_types |= /obj/item/clothing/shoes/jackboots

	var/list/filler_types = unit_test_cleanable_filler_types()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP - 1)
		var/decal_type = filler_types[i]
		new decal_type(arena)
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), CLEANABLE_DECAL_TURF_CAP, "Турф обязан стоять ровно на капе перед вторым следом")

	var/obj/effect/decal/cleanable/blood/footprints/blood_prints = new(arena)
	blood_prints.entered_dirs |= SOUTH
	TEST_ASSERT(!QDELETED(blood_prints), "Новый след обязан лечь на турф")
	TEST_ASSERT(QDELETED(oil_prints), "Премиса теста: кап обязан вытеснить след другого состояния как самую старую декаль своего типа")
	TEST_ASSERT(blood_prints.entered_dirs & NORTH, "Направления входа вытесненного следа обязаны перейти выжившему")
	TEST_ASSERT(blood_prints.exited_dirs & EAST, "Направления выхода вытесненного следа обязаны перейти выжившему")
	TEST_ASSERT(blood_prints.entered_dirs & SOUTH, "Собственные направления выжившего следа обязаны сохраниться")
	TEST_ASSERT((/obj/item/clothing/shoes/jackboots in blood_prints.shoe_types), "Типы обуви вытесненного следа обязаны перейти выжившему - это улика для осмотра")

/// Поглощение чистой декали не обнуляет последнего трогавшего у поглотителя.
/datum/unit_test/cleanable_decal_turf_cap_keeps_last_toucher/Run()
	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")
	var/turf/neighbour = locate(arena.x + 1, arena.y, arena.z)
	TEST_ASSERT_NOTNULL(neighbour, "Арене теста нужен сосед с востока")

	var/list/filler_types = unit_test_cleanable_filler_types()
	var/list/placed = list()
	for(var/i in 1 to CLEANABLE_DECAL_TURF_CAP)
		var/decal_type = filler_types[i]
		placed += new decal_type(arena)
	var/obj/effect/decal/cleanable/oldest = placed[1]
	TEST_ASSERT_NULL(oldest.fingerprintslast, "Премиса теста: у свежей грязи нет последнего трогавшего")

	// Переезд идёт мимо Initialize - кап досылается руками, как в gibs/streak().
	var/obj/effect/decal/cleanable/blood/gibs/absorber = new(neighbour)
	absorber.fingerprintslast = "absorber-ckey"
	absorber.forceMove(arena)
	absorber.enforce_turf_decal_cap()
	TEST_ASSERT(QDELETED(oldest), "Премиса теста: досылка капа обязана вытеснить самую старую грязь")
	TEST_ASSERT_EQUAL(absorber.fingerprintslast, "absorber-ckey", "Поглощение чистой декали обнулило последнего трогавшего у поглотителя")

	// Тип другой: иначе жертвой стал бы первый гиб как самая старая декаль своего типа.
	var/obj/effect/decal/cleanable/next_oldest = placed[2]
	next_oldest.fingerprintslast = "victim-ckey"
	var/obj/effect/decal/cleanable/oil/clean_absorber = new(neighbour)
	TEST_ASSERT_NULL(clean_absorber.fingerprintslast, "Премиса теста: у свежего масла нет последнего трогавшего")
	clean_absorber.forceMove(arena)
	clean_absorber.enforce_turf_decal_cap()
	TEST_ASSERT(QDELETED(next_oldest), "Премиса теста: вторая досылка обязана вытеснить следующую по старшинству грязь")
	TEST_ASSERT_EQUAL(clean_absorber.fingerprintslast, "victim-ckey", "Последний трогавший жертвы обязан перейти поглотителю без собственного следа")

/// Функциональные декали (сортировщик конвейера, щебень под подом) кап не вытесняет.
/datum/unit_test/cleanable_decal_turf_cap_spares_functional_decals/Run()
	var/obj/effect/decal/cleanable/conveyor_sorter/sorter_type = /obj/effect/decal/cleanable/conveyor_sorter
	var/obj/effect/decal/cleanable/supplypod_rubble/rubble_type = /obj/effect/decal/cleanable/supplypod_rubble
	TEST_ASSERT(initial(sorter_type.cap_exempt), "Сортировщик конвейера обязан быть cap_exempt: он настроен игроком и лежит на турфе первым")
	TEST_ASSERT(initial(rubble_type.cap_exempt), "Щебень под подом обязан быть cap_exempt: под держит на него ссылку и рисует по нему передний план")

	var/turf/arena = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(unit_test_count_turf_cleanables(arena), 0, "Арена теста должна начинаться без декалей")
	var/obj/effect/decal/cleanable/conveyor_sorter/sorter = new(arena)
	var/list/filler_types = unit_test_cleanable_filler_types()
	for(var/decal_type as anything in filler_types)
		new decal_type(arena)
		TEST_ASSERT(!QDELETED(sorter), "Кап вытеснил сортировщик конвейера грязью [decal_type]")
	TEST_ASSERT(unit_test_count_turf_cleanables(arena) <= CLEANABLE_DECAL_TURF_CAP, "Exempt-сортировщик не должен отменять вытеснение остальной грязи")
