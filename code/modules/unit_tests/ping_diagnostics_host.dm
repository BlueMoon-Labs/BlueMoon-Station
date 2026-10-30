/datum/unit_test/ping_diag_host_parse/Run()
	var/snmp = "Ip: Forwarding DefaultTTL\nIp: 1 64\nTcp: RtoAlgorithm RtoMin RtoMax MaxConn ActiveOpens PassiveOpens AttemptFails EstabResets CurrEstab InSegs OutSegs RetransSegs InErrs OutRsts InCsumErrors\nTcp: 1 200 120000 -1 10 20 0 0 5 1000 2000 30 0 0 0\nUdp: InDatagrams\nUdp: 5\n"
	var/list/tcp = ping_diag_parse_snmp(snmp)
	TEST_ASSERT_NOTNULL(tcp, "строки Tcp найдены")
	TEST_ASSERT_EQUAL(tcp["out"], 2000, "OutSegs")
	TEST_ASSERT_EQUAL(tcp["retrans"], 30, "RetransSegs")
	TEST_ASSERT_NULL(ping_diag_parse_snmp("Ip: 1 2\n"), "без Tcp - null")

	var/netdev = "Inter-|   Receive                                                |  Transmit\n face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n    lo: 500 5 0 0 0 0 0 0 500 5 0 0 0 0 0 0\n  eth0: 1000 10 0 0 0 0 0 0 4000 40 0 0 0 0 0 0\n  eth1:   200 2 0 0 0 0 0 0   100 1 0 0 0 0 0 0\ndocker0: 70 1 0 0 0 0 0 0 70 1 0 0 0 0 0 0\nveth1a2b: 70 1 0 0 0 0 0 0 70 1 0 0 0 0 0 0\nbr-5f3c: 70 1 0 0 0 0 0 0 70 1 0 0 0 0 0 0\nvirbr0: 70 1 0 0 0 0 0 0 70 1 0 0 0 0 0 0\n"
	var/list/dev = ping_diag_parse_netdev(netdev)
	TEST_ASSERT_EQUAL(dev["rx"], 1200, "rx без lo и мостов контейнеров")
	TEST_ASSERT_EQUAL(dev["tx"], 4100, "tx без lo и мостов контейнеров")
	TEST_ASSERT_NULL(ping_diag_parse_netdev("Inter-| Receive\n"), "без интерфейсов - null")

/datum/unit_test/ping_diag_host_rates/Run()
	var/datum/ping_host_net/net = new
	TEST_ASSERT(net.update(0, list("out" = 1000, "retrans" = 10), list("rx" = 0, "tx" = 0)), "первый замер принят")
	TEST_ASSERT_EQUAL(net.tx_kbps, 0, "по одному замеру скорость не считаем")
	TEST_ASSERT(!net.rated, "в ping-host по одному замеру пустые ячейки")
	net.update(600, list("out" = 3000, "retrans" = 50), list("rx" = 750000, "tx" = 1500000))
	TEST_ASSERT(net.rated, "со второго замера скорости есть")
	TEST_ASSERT_EQUAL(net.tx_kbps, 200, "1.5 МБ за минуту = 200 кбит/с")
	TEST_ASSERT_EQUAL(net.rx_kbps, 100, "rx")
	TEST_ASSERT_EQUAL(net.retrans_per_min, 40, "повторы за минуту")
	TEST_ASSERT_EQUAL(net.retrans_pct, 2, "40 из 2000 = 2%")
	TEST_ASSERT(!net.update(1200, null, list("rx" = 0, "tx" = 0)), "нет счётчиков - замер пропущен")
	qdel(net)

/// Событие получает world.time и долю повторов хоста, строка ping-host обнуляет счётчики минуты.
/datum/unit_test/ping_diag_host_minute/Run()
	var/list/saved = ping_diag_save_state()
	var/datum/ping_host_net/net = new
	net.available = FALSE
	net.retrans_pct = 2.5
	SSping_diag.host_net = net
	SSping_diag.minute_events = 0
	SSping_diag.record_event(list("type" = PING_EVENT_HOST_NETWORK, "clients" = 5, "fraction" = 1, "extra_ms" = 80, "stall_ms" = 0), "МК: Air (90% тика)")
	SSping_diag.record_event(list("type" = PING_EVENT_HOST_NETWORK, "clients" = 5, "fraction" = 1, "extra_ms" = 80, "stall_ms" = 0), "-")
	var/list/event = SSping_diag.events[1]
	TEST_ASSERT_EQUAL(event["world_time"], world.time, "у события есть world.time")
	TEST_ASSERT_EQUAL(event["host_retrans_pct"], 2.5, "у события доля повторов хоста")
	TEST_ASSERT_EQUAL(SSping_diag.minute_events, 2, "события посчитаны в минуте")
	var/list/sources = SSping_diag.round_summary()["event_sources"]
	TEST_ASSERT_EQUAL(sources["МК: Air"], 1, "итог раунда считает источники")
	TEST_ASSERT_EQUAL(length(sources), 1, "прочерк в источники не идёт")
	SSping_diag.write_host_row("12:00:00", 0)
	TEST_ASSERT_EQUAL(SSping_diag.minute_events, 0, "строка ping-host обнулила минуту")
	ping_diag_restore_state(saved)
	qdel(net)

/datum/unit_test/ping_diag_raw_samples/Run()
	var/datum/ping_diagnostics/diag = new("tester")
	diag.record_sample(100, 40, 0, 1, 0)
	diag.record_sample(118, 45, 3, 2, 0)
	diag.note_chat(300, 120)
	diag.record_sample(123, 300, 0, 0, 0)
	diag.record_sample(125, 50, 0, 3, 0)
	var/list/raw = diag.raw_since(125, 0)
	TEST_ASSERT_EQUAL(raw["t0"], 100, "время первого")
	TEST_ASSERT_EQUAL(raw["last"], 125, "время последнего")
	TEST_ASSERT_EQUAL(raw["text"], "0/40/0 18/45/3 5/300/0pf 2/50/0f", "dt/rtt/stall, ускоренный и замер под потоком помечены")
	var/list/tail = diag.raw_since(125, 118)
	TEST_ASSERT_EQUAL(tail["text"], "0/300/0pf 2/50/0f", "только новее отметки")
	var/list/nothing = diag.raw_since(125, 125)
	TEST_ASSERT_EQUAL(nothing["text"], "", "нового нет - пусто")
	qdel(diag)
