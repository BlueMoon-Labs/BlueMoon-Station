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

#define METADOLLAR_PROBE_CKEY "unittestmdprobe"
#define METADOLLAR_PROBE_DIR "data/player_saves/u/" + METADOLLAR_PROBE_CKEY
#define METADOLLAR_PROBE_AMOUNT 16000000

/// Пересбор лидерборда сам переносит баланс из старого preferences.sav в metadollars.json.
/datum/unit_test/metadollar_refresh_recovers_legacy_balance
	var/list/saved_leaderboard
	var/had_cache_entry = FALSE

/datum/unit_test/metadollar_refresh_recovers_legacy_balance/Run()
	TEST_ASSERT(!SSmetadollars.leaderboard_refresh_running, "предпосылка: пересбор уже идёт")
	saved_leaderboard = SSmetadollars.metadollar_leaderboard.Copy()
	had_cache_entry = (METADOLLAR_PROBE_CKEY in SSmetadollars.metadollar_amount_cache)
	SSmetadollars.metadollar_amount_cache -= METADOLLAR_PROBE_CKEY
	var/json_path = bm_metadollar_json_path(METADOLLAR_PROBE_CKEY)
	if(fexists(json_path))
		fdel(json_path)
	var/legacy_path = "[METADOLLAR_PROBE_DIR]/preferences.sav"
	var/savefile/legacy = new /savefile(legacy_path)
	legacy.cd = "/"
	WRITE_FILE(legacy["metadollars"], METADOLLAR_PROBE_AMOUNT)
	legacy = null
	// Закрытый savefile доезжает на диск только после сна мира; в том же тике он читается пустым.
	sleep(1)
	TEST_ASSERT(fexists(legacy_path), "предпосылка: savefile не создан")
	TEST_ASSERT_EQUAL(bm_read_legacy_metadollars_from_prefs_sav(METADOLLAR_PROBE_CKEY), METADOLLAR_PROBE_AMOUNT, "предпосылка: legacy-баланс не читается")

	TEST_ASSERT(SSmetadollars.refresh_metadollar_leaderboard_from_saves(), "пересбор не запустился")

	TEST_ASSERT(fexists(json_path), "legacy-баланс не перенесён в metadollars.json")
	TEST_ASSERT_EQUAL(SSmetadollars.get_metadollars(METADOLLAR_PROBE_CKEY), METADOLLAR_PROBE_AMOUNT, "перенесённый баланс не совпал")
	var/list/board = SSmetadollars.metadollar_leaderboard
	TEST_ASSERT_EQUAL(board[METADOLLAR_PROBE_CKEY], METADOLLAR_PROBE_AMOUNT, "лидерборд не увидел перенесённый баланс, ключи: [board.Join(", ")]")

/datum/unit_test/metadollar_refresh_recovers_legacy_balance/Destroy()
	var/json_path = bm_metadollar_json_path(METADOLLAR_PROBE_CKEY)
	if(fexists(json_path))
		fdel(json_path)
	fdel("[METADOLLAR_PROBE_DIR]/")
	if(!had_cache_entry)
		SSmetadollars.metadollar_amount_cache -= METADOLLAR_PROBE_CKEY
	if(saved_leaderboard)
		SSmetadollars.metadollar_leaderboard = saved_leaderboard
		SSmetadollars.save_metadollar_leaderboard()
	return ..()

#undef METADOLLAR_PROBE_CKEY
#undef METADOLLAR_PROBE_DIR
#undef METADOLLAR_PROBE_AMOUNT

