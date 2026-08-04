/// Сажает трубу на тестовую сеть, сперва снеся ту, которую ей построил SSair
/// при создании. Без этого брошенный pipeline остаётся висеть и портит
/// GC-тесты, а сама труба числится сразу в двух сетях.
/proc/attach_test_pipe(obj/machinery/atmospherics/pipe/pipe, datum/pipeline/net)
	pipe.destroy_network()
	pipe.parent = net
	net.track_member(pipe)

/// Номинал у свежей трубы и размен усиленной стенки на просвет.
/datum/unit_test/atmos_pipe_rating_defaults

/datum/unit_test/atmos_pipe_rating_defaults/Run()
	var/obj/machinery/atmospherics/pipe/simple/plain = allocate(/obj/machinery/atmospherics/pipe/simple)
	TEST_ASSERT_EQUAL(plain.pressure_rating, PIPE_PRESSURE_RATING_STANDARD, "обычная труба должна иметь стандартный номинал")
	TEST_ASSERT_EQUAL(plain.volume, PIPE_VOLUME_PER_NODE_STANDARD * plain.device_type, "объём обычной трубы должен считаться от стандартного просвета")
	TEST_ASSERT_EQUAL(plain.damage_stage, PIPE_DAMAGE_INTACT, "новая труба должна быть целой")

	var/obj/machinery/atmospherics/pipe/simple/reinforced/strong = allocate(/obj/machinery/atmospherics/pipe/simple/reinforced)
	TEST_ASSERT_EQUAL(strong.pressure_rating, PIPE_PRESSURE_RATING_REINFORCED, "усиленная труба должна нести усиленный номинал")
	TEST_ASSERT_EQUAL(strong.volume, PIPE_VOLUME_PER_NODE_REINFORCED * strong.device_type, "усиленная труба должна платить за стенку просветом")
	// Без этого размена усиленная труба вытеснила бы обычную: RPD бесконечен,
	// и брать более слабую было бы незачем.
	TEST_ASSERT(strong.volume < plain.volume, "усиленная труба обязана быть теснее обычной")

/// Сеть держит столько, сколько держит её слабейшее звено.
/datum/unit_test/atmos_pipe_weakest_link

/datum/unit_test/atmos_pipe_weakest_link/Run()
	var/datum/pipeline/net = allocate(/datum/pipeline)
	var/obj/machinery/atmospherics/pipe/simple/reinforced/strong = allocate(/obj/machinery/atmospherics/pipe/simple/reinforced)
	var/obj/machinery/atmospherics/pipe/simple/weak = allocate(/obj/machinery/atmospherics/pipe/simple)
	attach_test_pipe(strong, net)
	TEST_ASSERT_EQUAL(net.min_rating, PIPE_PRESSURE_RATING_REINFORCED, "сеть из одной усиленной трубы должна нести её номинал")
	attach_test_pipe(weak, net)
	TEST_ASSERT_EQUAL(net.min_rating, PIPE_PRESSURE_RATING_STANDARD, "обычная труба в сети должна опустить номинал до своего")

/// Полосы напряжения: насос на максимуме упирается в течь и дальше не идёт.
/datum/unit_test/atmos_pipe_stress_bands

/datum/unit_test/atmos_pipe_stress_bands/Run()
	var/datum/pipeline/net = allocate(/datum/pipeline)
	TEST_ASSERT_EQUAL(net.stress_stage_cap(0.9), PIPE_DAMAGE_INTACT, "под номиналом стадия расти не должна")
	TEST_ASSERT_EQUAL(net.stress_stage_cap(1.2), PIPE_DAMAGE_INTACT, "в полосе гула стадия расти не должна")
	// 4500 кПа газового насоса на номинале 3000 - это ровно 1.5.
	TEST_ASSERT_EQUAL(net.stress_stage_cap(1.5), PIPE_DAMAGE_LEAK, "насос на максимуме должен упираться в течь")
	// 9000 кПа объёмного насоса на том же номинале - это 3.
	TEST_ASSERT_EQUAL(net.stress_stage_cap(3), PIPE_DAMAGE_RUPTURE, "тройное превышение должно доходить до разрыва")

/// Потолок прироста усталости - это и есть обещание "мгновенных отказов не бывает".
/datum/unit_test/atmos_pipe_fatigue_cap

/datum/unit_test/atmos_pipe_fatigue_cap/Run()
	var/datum/pipeline/net = allocate(/datum/pipeline)
	var/gain = net.fatigue_gain(100)
	TEST_ASSERT_EQUAL(gain, PIPE_FATIGUE_GAIN_CAP, "прирост усталости обязан быть ограничен потолком")
	TEST_ASSERT(PIPE_FATIGUE_MAX / gain >= 5, "от целой трубы до отказа должно быть не меньше пяти проходов свипа")
	TEST_ASSERT(net.fatigue_gain(1.5) < gain, "полутора номиналам полагается расти медленнее абсурдного давления")

/// Течь роняет давление, но выдохшаяся линия не тянет воздух из комнаты обратно.
/datum/unit_test/atmos_pipe_leak_drains

/datum/unit_test/atmos_pipe_leak_drains/Run()
	var/obj/machinery/atmospherics/pipe/simple/pipe = allocate(/obj/machinery/atmospherics/pipe/simple)
	var/datum/pipeline/net = allocate(/datum/pipeline)
	net.air = new
	net.air.set_volume(CELL_VOLUME)
	attach_test_pipe(pipe, net)
	net.air.set_moles(GAS_O2, MOLES_CELLSTANDARD * 50)
	net.air.set_temperature(T20C)
	pipe.damage_stage = PIPE_DAMAGE_LEAK
	LAZYOR(net.damaged_members, pipe)

	var/before = net.air.return_pressure()
	net.vent_damaged_members()
	TEST_ASSERT(net.air.return_pressure() < before, "течь обязана ронять давление в сети")

	net.air.set_moles(GAS_O2, 0)
	var/empty = net.air.return_pressure()
	net.vent_damaged_members()
	TEST_ASSERT_EQUAL(net.air.return_pressure(), empty, "выдохшаяся линия не должна менять давление")

/// Ремонт возвращает трубу в строй и снимает сеть с учёта.
/datum/unit_test/atmos_pipe_weld_repair

/datum/unit_test/atmos_pipe_weld_repair/Run()
	var/obj/machinery/atmospherics/pipe/simple/pipe = allocate(/obj/machinery/atmospherics/pipe/simple)
	var/datum/pipeline/net = allocate(/datum/pipeline)
	net.air = new
	net.air.set_volume(CELL_VOLUME)
	attach_test_pipe(pipe, net)
	pipe.damage_stage = PIPE_DAMAGE_RUPTURE
	LAZYOR(net.damaged_members, pipe)
	net.fatigue = PIPE_FATIGUE_MAX - 1

	// Зовём последствие напрямую: welder_act требует живого игрока и do_after,
	// а проверяем мы результат, не ввод.
	pipe.finish_pressure_repair()
	TEST_ASSERT_EQUAL(pipe.damage_stage, PIPE_DAMAGE_INTACT, "сварка обязана вернуть трубу в целое состояние")
	TEST_ASSERT_EQUAL(length(net.damaged_members), 0, "починенная труба должна уйти из списка повреждённых")
	TEST_ASSERT_EQUAL(net.fatigue, 0, "ремонт обязан обнулять усталость сети")
	TEST_ASSERT(!net.update_stress(), "сеть без повреждений и без перегруза обязана сниматься с учёта")

/// Эскалация бьёт по слабому звену, а не по усиленной секции рядом с ним.
/datum/unit_test/atmos_pipe_escalation_targets_weakest

/datum/unit_test/atmos_pipe_escalation_targets_weakest/Run()
	var/datum/pipeline/net = allocate(/datum/pipeline)
	net.air = new
	net.air.set_volume(CELL_VOLUME)
	var/obj/machinery/atmospherics/pipe/simple/reinforced/strong = allocate(/obj/machinery/atmospherics/pipe/simple/reinforced)
	var/obj/machinery/atmospherics/pipe/simple/weak = allocate(/obj/machinery/atmospherics/pipe/simple)
	attach_test_pipe(strong, net)
	attach_test_pipe(weak, net)

	TEST_ASSERT(net.escalate_damage(PIPE_DAMAGE_RUPTURE), "эскалация обязана найти кандидата")
	TEST_ASSERT_EQUAL(strong.damage_stage, PIPE_DAMAGE_INTACT, "усиленная секция не должна страдать за обычную")
	TEST_ASSERT_EQUAL(weak.damage_stage, PIPE_DAMAGE_LEAK, "стадия обязана подниматься по одной, а не прыгать сразу в разрыв")

/// Штатное мапповое оборудование не имеет права продавливать обычную трубу.
///
/// Сифонные вентиляторы газовых хранилищ стояли на 4000 кПа - числе, которое до
/// появления номинала трубы не значило ничего. С номиналом 3000 оно даёт
/// напряжение 1.333 при пороге течи 1.3, то есть линии выхода танков на КАЖДОЙ
/// станции начинали течь сами, без участия игрока. Сифон при этом компрессирует
/// без ограничения по мощности: в формуле переноса участвует только разность
/// между его потолком и давлением в трубе, давление комнаты не участвует.
///
/// Проверяются вентиляторы, которые мапповая раскладка включает сама и у которых
/// задан внутренний порог: именно он и есть то давление, до которого линия
/// доедет без единого игрока рядом. Направление не важно - сифон качает В трубу
/// до порога, выпускающий держит трубу НЕ НИЖЕ порога, и порог выше номинала
/// плох в обоих случаях.
///
/// Константы SIPHONING/INT_BOUND здесь не используются намеренно: они объявлены
/// файл-локально внутри vent_pump.dm и за его пределами не существуют.
/datum/unit_test/atmos_mapped_vents_respect_pipe_rating

/datum/unit_test/atmos_mapped_vents_respect_pipe_rating/Run()
	var/checked = 0
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/vent_type as anything in typesof(/obj/machinery/atmospherics/components/unary/vent_pump))
		if(!initial(vent_type.on))
			continue
		var/bound = initial(vent_type.internal_pressure_bound)
		if(bound <= 0)
			continue
		checked++
		TEST_ASSERT(bound <= PIPE_PRESSURE_RATING_STANDARD, \
			"[vent_type] выводит линию на [bound] кПа при номинале обычной трубы [PIPE_PRESSURE_RATING_STANDARD] кПа")
	// Без этой предпосылки проверка прошла бы вхолостую, если бы включённых по
	// карте вентиляторов с внутренним порогом однажды не осталось вовсе.
	TEST_ASSERT(checked, "предпосылка: в дереве должен быть хотя бы один включённый по карте вентилятор с внутренним порогом")
