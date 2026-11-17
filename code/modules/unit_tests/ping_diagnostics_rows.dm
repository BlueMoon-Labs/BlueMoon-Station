/// Сетка "людей рядом" считает то же, что get_dist по всем парам, включая край радиуса на стыке клеток.
/datum/unit_test/ping_diag_near_grid/Run()
	var/range = PING_DIAG_NEAR_RANGE
	var/list/cells = list()
	ping_diag_grid_add(cells, range - 1, 5, 2, range)
	ping_diag_grid_add(cells, range * 2 - 1, 5, 2, range)
	ping_diag_grid_add(cells, range * 2, 5, 2, range)
	ping_diag_grid_add(cells, range - 1, 5, 3, range)
	TEST_ASSERT_EQUAL(ping_diag_grid_near(cells, range - 1, 5, 2, range), 2, "ровно на радиусе через стык клеток - рядом, на шаг дальше - нет, другой z - нет")

	var/list/points = list()
	cells = list()
	for(var/i in 1 to 300)
		var/list/point = list(rand(1, 80), rand(1, 80), rand(2, 3))
		points += list(point)
		ping_diag_grid_add(cells, point[1], point[2], point[3], range)
	var/mismatches = 0
	for(var/list/point as anything in points)
		var/expected = 0
		for(var/list/other as anything in points)
			if(other[3] == point[3] && max(abs(other[1] - point[1]), abs(other[2] - point[2])) <= range)
				expected++
		if(ping_diag_grid_near(cells, point[1], point[2], point[3], range) != expected)
			mismatches++
	TEST_ASSERT_EQUAL(mismatches, 0, "сетка расходится с перебором пар")

/// Сырые замеры минуты - не новее среза: пришедшее после него уходит в следующую минуту, а не теряется и не дублируется.
/datum/unit_test/ping_diag_raw_until_now/Run()
	var/datum/ping_diagnostics/diag = new("tester")
	diag.record_sample(100, 40, 0, 1, 0)
	diag.record_sample(110, 45, 0, 2, 0)
	diag.record_sample(120, 50, 0, 3, 0)
	var/list/minute = diag.raw_since(115, 0)
	TEST_ASSERT_EQUAL(minute["text"], "0/40/0 10/45/0", "замер новее среза не в этой минуте")
	TEST_ASSERT_EQUAL(minute["last"], 110, "отметка выгрузки - последний замер среза")
	var/list/next = diag.raw_since(125, minute["last"])
	TEST_ASSERT_EQUAL(next["text"], "0/50/0", "он в следующей")
	TEST_ASSERT_EQUAL(next["t0"], 120, "со своим t0")
	qdel(diag)

/// Стоит за клиента в срезе минутной записи: срезу нужны только эти поля.
/datum/ping_diag_fake_client
	var/ckey
	var/mob
	var/view = "15x15"
	var/datum/ping_diagnostics/ping_diag

/datum/ping_diag_fake_client/Destroy()
	QDEL_NULL(ping_diag)
	mob = null
	return ..()

/// Минутная запись идёт кусками по фаерам, строки минуты - с одной меткой времени, соседи и z - на момент среза.
/datum/unit_test/ping_diag_minute_rows_sliced/Run()
	var/list/saved = ping_diag_save_state()
	var/datum/ping_host_net/net = new
	net.available = FALSE
	SSping_diag.host_net = net
	SSping_diag.watched = list()
	SSping_diag.next_csv_at = world.time + 1000
	SSping_diag.verdict_started_at = world.time
	SSping_diag.clients_log = "[GLOB.log_directory]/ping-test-rows-clients.csv"
	SSping_diag.samples_log = "[GLOB.log_directory]/ping-test-rows-samples.log"
	SSping_diag.host_log = "[GLOB.log_directory]/ping-test-rows-host.csv"
	var/list/paths = list(SSping_diag.clients_log, SSping_diag.samples_log, SSping_diag.host_log)
	for(var/path in paths)
		fdel(path)
	// Живая подсистема могла прервать свою минуту на полпути.
	SSping_diag.minute_rows_slices = 0
	var/now = REALTIMEOFDAY
	var/list/fakes = list()
	var/obj/item/marker = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	for(var/i in 1 to 100)
		var/datum/ping_diag_fake_client/fake = new
		fake.ckey = "rows[i]"
		fake.mob = i <= 30 ? marker : null
		fake.ping_diag = new(fake.ckey)
		for(var/sample in 1 to PING_DIAG_BASE_SAMPLES)
			fake.ping_diag.record_sample(now - PING_DIAG_BASE_SAMPLES * 15 + sample * 15, 40 + sample % 30, 0, 1, 0)
		fake.ping_diag.recompute(now, 40, 0)
		fakes += fake

	SSping_diag.start_minute_rows(fakes)
	var/stamp = SSping_diag.rows_stamp
	var/fires = ping_diag_finish_minute()
	TEST_ASSERT(fires > 1, "100 клиентов записаны за [fires] фаер - снова одним куском")

	var/list/clients_header = splittext(PING_DIAG_CSV_HEADER, ",")
	var/list/rows = splittext(trim(file2text(paths[1])), "\n")
	TEST_ASSERT_EQUAL(length(rows), 100, "строка на каждого клиента среза")
	var/list/first = splittext(rows[1], ",")
	TEST_ASSERT_EQUAL(length(first), length(clients_header), "колонки ping-clients как в заголовке")
	var/inconsistent = 0
	var/list/neighbours = list()
	for(var/row in rows)
		var/list/cells = splittext(row, ",")
		if(cells[1] != stamp || cells[2] != first[2])
			inconsistent++
		var/key = "[cells[clients_header.Find("z_clients")]]/[cells[clients_header.Find("near_clients")]]"
		neighbours[key] = (neighbours[key] || 0) + 1
	TEST_ASSERT_EQUAL(inconsistent, 0, "у всех строк минуты одна метка времени")
	TEST_ASSERT_EQUAL(neighbours["30/29"], 30, "на одном тайле: 30 на z, 29 рядом")
	TEST_ASSERT_EQUAL(neighbours["0/0"], 70, "без турфа - ни z, ни соседей")
	TEST_ASSERT_EQUAL(length(splittext(trim(file2text(paths[2])), "\n")), 100, "сырые замеры каждого")

	var/list/host_header = splittext(PING_DIAG_HOST_CSV_HEADER, ",")
	var/list/host_rows = splittext(trim(file2text(paths[3])), "\n")
	TEST_ASSERT_EQUAL(length(host_rows), 1, "строка ping-host одна, в конце минуты")
	var/list/host = splittext(host_rows[1], ",")
	TEST_ASSERT_EQUAL(length(host), length(host_header), "колонки ping-host как в заголовке")
	TEST_ASSERT_EQUAL(host[1], stamp, "та же метка, что у строк клиентов")
	TEST_ASSERT_EQUAL(host[host_header.Find("clients")], "100", "клиентов на момент среза")
	TEST_ASSERT_EQUAL(host[host_header.Find("ss_rows_slices")], "[fires]", "сколько фаеров заняла запись")
	TEST_ASSERT(text2num(host[host_header.Find("ss_rows_raw_ms")]) > 0, "выборка сырых замеров замерена")
	for(var/probe in list("str_probe_time_us", "str_probe_sqltime_us"))
		TEST_ASSERT(text2num(host[host_header.Find(probe)]) >= 0, "[probe] числом: [host[host_header.Find(probe)]]")
	TEST_ASSERT_EQUAL(SSping_diag.rows_step, PING_DIAG_ROWS_IDLE, "запись закончена")
	TEST_ASSERT_NULL(SSping_diag.rows_entries, "срез отпущен")

	ping_diag_restore_state(saved)
	qdel(net)
	QDEL_LIST(fakes)
	for(var/path in paths)
		fdel(path)
