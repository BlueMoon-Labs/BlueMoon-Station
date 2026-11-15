/// Машина, не держащая трубу в своих nodes, не попадает в её сеть при обходе.
/datum/unit_test/atmos_pipenet_skips_one_sided_component_link/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/port_spot = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, port_spot)
	port.setDir(WEST)
	port.SetInitDirections()
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 2)
	port.atmosinit()
	var/obj/machinery/atmospherics/pipe/simple/last = pipes[2]
	TEST_ASSERT(port in last.nodes, "предпосылка: труба не увидела порт")
	TEST_ASSERT(last in port.nodes, "предпосылка: порт не увидел трубу")

	port.nodes[1] = null
	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	first.build_network(blocking = TRUE)
	var/datum/pipeline/net = first.parent
	TEST_ASSERT_NOTNULL(net, "сеть не построилась")
	TEST_ASSERT_EQUAL(length(net.members), 2, "в сети [length(net.members)] труб вместо 2")
	TEST_ASSERT(!(port in net.other_atmosmch), "порт без обратной связи попал в машины сети")
	TEST_ASSERT_EQUAL(length(net.other_airs), 0, "в сети появилась газовая смесь машины без связи")

/// Симметричная связь по-прежнему делает машину членом сети.
/datum/unit_test/atmos_pipenet_keeps_two_sided_component_link/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/port_spot = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, port_spot)
	port.setDir(WEST)
	port.SetInitDirections()
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 2)
	port.atmosinit()

	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	first.build_network(blocking = TRUE)
	var/datum/pipeline/net = first.parent
	TEST_ASSERT_NOTNULL(net, "сеть не построилась")
	TEST_ASSERT(port in net.other_atmosmch, "порт с обратной связью не стал машиной сети")
	TEST_ASSERT_EQUAL(length(net.other_airs), 1, "у сети [length(net.other_airs)] смесей машин вместо 1")
	TEST_ASSERT_EQUAL(port.parents[1], net, "порт не запомнил сеть")

#define METADOLLAR_PROBE_AMOUNT 16000000

/**
 * Пересбор лидерборда сам переносит баланс из старого preferences.sav в metadollars.json.
 *
 * Тестовые миры делят один data/player_saves, поэтому у каждого теста свой ckey, а пересбор
 * обходит только букву "x": чужой мир в ту же секунду держит свои .sav открытыми, и открыть их
 * из другого процесса нельзя.
 */
/datum/unit_test/metadollar_refresh_recovers_legacy_balance
	var/probe_ckey = "xunittestmdprobe"
	var/list/saved_leaderboard
	var/had_cache_entry = FALSE

/datum/unit_test/metadollar_refresh_recovers_legacy_balance/proc/probe_dir()
	return "data/player_saves/[probe_ckey[1]]/[probe_ckey]"

/// Старый preferences.sav пробного ckey с этими ключами, без metadollars.json и без записи в кэше.
/datum/unit_test/metadollar_refresh_recovers_legacy_balance/proc/seed_legacy_save(list/keys)
	had_cache_entry = (probe_ckey in SSmetadollars.metadollar_amount_cache)
	SSmetadollars.metadollar_amount_cache -= probe_ckey
	fdel(bm_metadollar_json_path(probe_ckey))
	var/savefile/legacy = new /savefile("[probe_dir()]/preferences.sav")
	legacy.cd = "/"
	for(var/key in keys)
		var/value = keys[key]
		WRITE_FILE(legacy[key], value)
	legacy = null
	// Закрытый savefile доезжает на диск только после сна мира; в том же тике он читается пустым.
	sleep(1)
	return fexists("[probe_dir()]/preferences.sav")

/datum/unit_test/metadollar_refresh_recovers_legacy_balance/Run()
	TEST_ASSERT(!SSmetadollars.leaderboard_refresh_running, "предпосылка: пересбор уже идёт")
	saved_leaderboard = SSmetadollars.metadollar_leaderboard.Copy()
	TEST_ASSERT(seed_legacy_save(list("metadollars" = METADOLLAR_PROBE_AMOUNT)), "предпосылка: savefile не создан")
	TEST_ASSERT_EQUAL(bm_read_legacy_metadollars_from_prefs_sav(probe_ckey), METADOLLAR_PROBE_AMOUNT, "предпосылка: legacy-баланс не читается")

	TEST_ASSERT(SSmetadollars.refresh_metadollar_leaderboard_from_saves(list("x")), "пересбор не запустился")

	TEST_ASSERT(fexists(bm_metadollar_json_path(probe_ckey)), "legacy-баланс не перенесён в metadollars.json")
	TEST_ASSERT_EQUAL(SSmetadollars.get_metadollars(probe_ckey), METADOLLAR_PROBE_AMOUNT, "перенесённый баланс не совпал")
	var/list/board = SSmetadollars.metadollar_leaderboard
	TEST_ASSERT_EQUAL(board[probe_ckey], METADOLLAR_PROBE_AMOUNT, "лидерборд не увидел перенесённый баланс, ключи: [board.Join(", ")]")

/datum/unit_test/metadollar_refresh_recovers_legacy_balance/Destroy()
	fdel("[probe_dir()]/")
	if(!had_cache_entry)
		SSmetadollars.metadollar_amount_cache -= probe_ckey
	if(saved_leaderboard)
		SSmetadollars.metadollar_leaderboard = saved_leaderboard
		SSmetadollars.save_metadollar_leaderboard()
	return ..()

/// Нулевой legacy-баланс тоже завершает перенос: иначе лидерборд каждый раунд открывает старые .sav игрока.
/datum/unit_test/metadollar_zero_legacy_balance_is_finalized
	parent_type = /datum/unit_test/metadollar_refresh_recovers_legacy_balance
	probe_ckey = "unittestmdzero"

/datum/unit_test/metadollar_zero_legacy_balance_is_finalized/Run()
	TEST_ASSERT(seed_legacy_save(list("ooccolor" = "#ffffff")), "предпосылка: savefile не создан")

	TEST_ASSERT_EQUAL(SSmetadollars.read_metadollar_balance_from_save(probe_ckey, recover = TRUE), 0, "баланс без ключа в .sav не ноль")
	TEST_ASSERT(fexists(bm_metadollar_json_path(probe_ckey)), "нулевой баланс не записан в metadollars.json - .sav будет открываться каждый раунд")

/// Пустой или оборванный metadollars.json не роняет чтение и не заменяется старым балансом из .sav, а запись кладёт целый JSON.
/datum/unit_test/metadollar_unreadable_json_is_not_finalized
	parent_type = /datum/unit_test/metadollar_refresh_recovers_legacy_balance
	probe_ckey = "unittestmdunreadable"

/datum/unit_test/metadollar_unreadable_json_is_not_finalized/Run()
	TEST_ASSERT(seed_legacy_save(list("metadollars" = METADOLLAR_PROBE_AMOUNT)), "предпосылка: savefile не создан")
	var/json_path = bm_metadollar_json_path(probe_ckey)
	for(var/unreadable in list("", "{\"metadollar_count\": 12"))
		SSmetadollars.metadollar_amount_cache -= probe_ckey
		fdel(json_path)
		rustg_file_write(unreadable, json_path)
		TEST_ASSERT(fexists(json_path), "предпосылка: metadollars.json не создан")
		var/scanned = SSmetadollars.read_metadollar_balance_from_save(probe_ckey, recover = TRUE)
		var/json_after_scan = file2text(json_path)
		var/amount = SSmetadollars.get_metadollars(probe_ckey)
		TEST_ASSERT_EQUAL(scanned, 0, "нечитаемый metadollars.json \"[unreadable]\" прочитан как баланс")
		TEST_ASSERT_EQUAL(json_after_scan, unreadable, "пересбор переписал нечитаемый metadollars.json \"[unreadable]\"")
		TEST_ASSERT_EQUAL(amount, 0, "нечитаемый metadollars.json \"[unreadable]\" дал баланс")

	SSmetadollars.set_metadollars(probe_ckey, 42)
	var/list/saved = safe_json_decode(file2text(json_path), null)
	TEST_ASSERT_EQUAL(saved?["metadollar_count"], 42, "запись не положила целый metadollars.json")
	var/list/left = flist("[probe_dir()]/")
	left -= list("preferences.sav", "metadollars.json")
	TEST_ASSERT_EQUAL(length(left), 0, "запись metadollars.json оставила файлы: [jointext(left, ", ")]")

#undef METADOLLAR_PROBE_AMOUNT

/// Сброс вида госта снимает его с наблюдаемого и чистит observers цели.
/datum/unit_test/ghost_reset_perspective_releases_observed_target/Run()
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	ghost.observetarget = target
	LAZYADD(target.observers, ghost)

	ghost.reset_perspective(null)

	TEST_ASSERT_NULL(ghost.observetarget, "гост остался привязан к цели")
	TEST_ASSERT(!(ghost in target.observers), "гост остался в observers цели")
