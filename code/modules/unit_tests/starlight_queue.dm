/// Сколько раз клетка стоит в списке.
/datum/unit_test/proc/count_in_list(list/haystack, needle)
	. = 0
	for(var/entry in haystack)
		if(entry == needle)
			.++

/// Массовая перестройка космоса ставит каждую клетку в очередь старлайта один раз, а не по разу на каждого перестроенного соседа.
/datum/unit_test/starlight_queue_dedup/Run()
	var/list/tiles = block(run_loc_floor_bottom_left, run_loc_floor_top_right)
	for(var/pass in 1 to 2)
		for(var/turf/tile as anything in tiles)
			tile.ChangeTurf(/turf/open/space)
	for(var/turf/tile as anything in tiles)
		var/count = count_in_list(GLOB.lighting_starlight_queue, tile)
		TEST_ASSERT(count <= 1, "Клетка [tile.x],[tile.y] стоит в очереди старлайта [count] раз.")

/// Обработанная клетка снова встаёт в очередь при следующей перестройке соседа.
/datum/unit_test/starlight_queue_requeue/Run()
	var/list/tiles = block(run_loc_floor_bottom_left, run_loc_floor_top_right)
	for(var/turf/tile as anything in tiles)
		tile.ChangeTurf(/turf/open/space)
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	TEST_ASSERT(center in GLOB.lighting_starlight_queue, "Перестроенная клетка стоит в очереди старлайта.")
	var/list/budget = new_wait_budget(30 SECONDS, "очередь старлайта разобрана")
	while((center in GLOB.lighting_starlight_queue) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!(center in GLOB.lighting_starlight_queue), "SSlighting разбирает очередь старлайта.")
	get_step(center, EAST).ChangeTurf(/turf/open/space)
	TEST_ASSERT(center in GLOB.lighting_starlight_queue, "Перестройка соседа снова ставит обработанную клетку в очередь.")

/datum/unit_test/starlight_update_noop
	var/set_light_calls = 0

/datum/unit_test/starlight_update_noop/proc/on_set_light(atom/source)
	SIGNAL_HANDLER
	set_light_calls++

/// update_starlight() зажигает клетку у не-космоса и гасит среди космоса, ведёт GLOB.starlight без повторов и не трогает свет, если ничего не изменилось.
/datum/unit_test/starlight_update_noop/Run()
	TEST_ASSERT(CONFIG_GET(flag/starlight), "Звёздный свет включён в конфиге тестов.")
	var/list/tiles = block(run_loc_floor_bottom_left, run_loc_floor_top_right)
	for(var/turf/tile as anything in tiles)
		tile.ChangeTurf(/turf/open/space)
	var/turf/open/space/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/turf/open/space/edge = run_loc_floor_bottom_left
	center.update_starlight()
	edge.update_starlight()
	TEST_ASSERT(!center.light_range, "Клетка среди космоса не светится.")
	TEST_ASSERT_EQUAL(count_in_list(GLOB.starlight, center), 0, "Клетки среди космоса нет в GLOB.starlight.")
	TEST_ASSERT(edge.light_range, "Клетка у стены светится.")
	TEST_ASSERT_EQUAL(count_in_list(GLOB.starlight, edge), 1, "Клетка у стены в GLOB.starlight один раз.")

	RegisterSignal(center, COMSIG_ATOM_SET_LIGHT, PROC_REF(on_set_light))
	RegisterSignal(edge, COMSIG_ATOM_SET_LIGHT, PROC_REF(on_set_light))
	center.update_starlight()
	edge.update_starlight()
	TEST_ASSERT_EQUAL(set_light_calls, 0, "Повторный update_starlight() без перемен свет не трогает.")
	UnregisterSignal(center, COMSIG_ATOM_SET_LIGHT)
	UnregisterSignal(edge, COMSIG_ATOM_SET_LIGHT)

	var/turf/side = get_step(center, EAST)
	side.ChangeTurf(/turf/open/floor/plasteel)
	center.update_starlight()
	TEST_ASSERT(center.light_range, "Клетка зажигается, когда рядом появился пол.")
	TEST_ASSERT_EQUAL(count_in_list(GLOB.starlight, center), 1, "Зажжённая клетка в GLOB.starlight один раз.")
	side.ChangeTurf(/turf/open/space)
	center.update_starlight()
	TEST_ASSERT(!center.light_range, "Клетка гаснет, когда пол снова стал космосом.")
	TEST_ASSERT_EQUAL(count_in_list(GLOB.starlight, center), 0, "Погасшая клетка уходит из GLOB.starlight.")

	edge.ChangeTurf(/turf/open/space)
	edge.update_starlight()
	TEST_ASSERT(edge.light_range, "Перестроенная клетка у стены снова светится.")
	TEST_ASSERT_EQUAL(count_in_list(GLOB.starlight, edge), 1, "Перестройка космоса в космос не дублирует клетку в GLOB.starlight.")
