// Подпись вентиляции в интерфейсе воздушной тревоги - единственный способ
// отличить друг от друга три венты, стоящие на одном тайле в разных слоях труб.

/// Номер брался как длина реестра ареала плюс один, а Destroy() запись из
/// реестра удаляет - поэтому каждый снятый вент освобождал свой номер
/// следующему, и в отсеке, который хоть раз пересобирали, появлялись два и три
/// "#20" разом.
/datum/unit_test/vent_label_numbering/Run()
	var/list/live_names = list()
	var/list/vents = list()
	for(var/i in 1 to 3)
		var/obj/machinery/atmospherics/components/unary/vent_pump/vent = allocate(/obj/machinery/atmospherics/components/unary/vent_pump)
		vent.set_frequency(vent.frequency)
		vent.broadcast_status()
		TEST_ASSERT(findtext(vent.name, "#"), "вент не получил номерную подпись: [vent.name]")
		TEST_ASSERT(!(vent.name in live_names), "два венты сразу получили подпись [vent.name]")
		live_names += vent.name
		vents += vent

	// Снимаем средний: именно освободившаяся запись реестра и создавала двойника.
	var/obj/machinery/atmospherics/components/unary/vent_pump/retired = vents[2]
	live_names -= retired.name
	qdel(retired)

	var/obj/machinery/atmospherics/components/unary/vent_pump/replacement = allocate(/obj/machinery/atmospherics/components/unary/vent_pump)
	replacement.set_frequency(replacement.frequency)
	replacement.broadcast_status()
	TEST_ASSERT(!(replacement.name in live_names), "новый вент занял подпись живого соседа: [replacement.name]")

/// Скруббер считает номер по своему реестру тем же способом и ломался так же.
/datum/unit_test/scrubber_label_numbering/Run()
	var/list/live_names = list()
	var/list/scrubbers = list()
	for(var/i in 1 to 3)
		var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber)
		scrubber.set_frequency(scrubber.frequency)
		scrubber.broadcast_status()
		TEST_ASSERT(findtext(scrubber.name, "#"), "скруббер не получил номерную подпись: [scrubber.name]")
		TEST_ASSERT(!(scrubber.name in live_names), "два скруббера сразу получили подпись [scrubber.name]")
		live_names += scrubber.name
		scrubbers += scrubber

	var/obj/machinery/atmospherics/components/unary/vent_scrubber/retired = scrubbers[2]
	live_names -= retired.name
	qdel(retired)

	var/obj/machinery/atmospherics/components/unary/vent_scrubber/replacement = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber)
	replacement.set_frequency(replacement.frequency)
	replacement.broadcast_status()
	TEST_ASSERT(!(replacement.name in live_names), "новый скруббер занял подпись живого соседа: [replacement.name]")
