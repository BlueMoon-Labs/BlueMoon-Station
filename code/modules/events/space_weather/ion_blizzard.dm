/**
 * # Ионная буря
 *
 * Заряженный фронт, который кратно поднимает выработку солнечных панелей - и наказывает
 * ту же станцию, если приток некуда девать.
 *
 * Событие целиком про подготовку. Подход намеренно длиннее пика: за него надо развернуть
 * массив под фронт и освободить накопители. Кто освободил - получает столько энергии,
 * сколько станция за смену не видит. Кто не тронул ничего - получает выбитое освещение
 * в секциях, где накопитель и так был полон и избытку было некуда идти.
 *
 * Перегруз бьёт ИМЕННО по заполненным секциям, а не по случайным: иначе подготовка
 * ничего не решала бы, и событие превратилось бы в лотерею с бесплатной энергией.
 */

/// Во сколько раз ионный фронт поднимает выработку панелей на пике.
#define ION_BLIZZARD_SOLAR_BOOST 4
/// Шанс скачка за тик на полной интенсивности, в процентах. Восемь, а не больше: пик
/// длится шестьдесят тиков, и уже при сорока пяти буря выбивала бы освещение почти на
/// трёх десятках участков - это не наказание за неподготовленность, это ночная смена
/// уборки для всей станции.
#define ION_BLIZZARD_SURGE_CHANCE 8
/// Доля заряда накопителя, выше которой секция считается неподготовленной.
#define ION_BLIZZARD_HEADROOM 0.9

/datum/round_event_control/space_weather/ion_blizzard
	name = "Ion Blizzard"
	typepath = /datum/round_event/space_weather/ion_blizzard
	enabled = TRUE
	weight = 6
	earliest_start = 15 MINUTES
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MODERATE
	cost = 6
	disruption = DIRECTOR_DISRUPTION_MILD
	// Без инженеров подготовиться некому, и событие превращается в чистый штраф с
	// бесплатной энергией, которую никто не подберёт.
	min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	description = "An ion blizzard supercharges the solar array and overloads the sections \
		whose cells had no headroom left."

/datum/round_event/space_weather/ion_blizzard
	profile_id = "ion_blizzard"
	token = "event_ion_blizzard"
	phenomenon_name = "Ионная буря"
	peak_layer = /atom/movable/screen/parallax_layer/eris/far/ion_blizzard/peak
	tint_low = "#000000"
	tint_high = "#1c4878"
	// Подход длиннее пика: буря вознаграждает подготовленную энергосеть, а подготовка
	// требует времени. Короткий подход превратил бы событие в лотерею.
	approach_ticks = 40
	peak_ticks = 60
	departure_ticks = 25
	announce_source = "Отдел Метеорологии NanoTrasen"
	announce_text = "К станции подходит ионная буря. Заряженные частицы кратно поднимут выработку солнечных панелей. Инженерному отделу рекомендуется развернуть массив под фронт и заранее освободить накопители: избыток, которому некуда идти, уйдёт в освещение."
	peak_announce_text = "Фронт ионной бури накрыл станцию. Выработка панелей на максимуме. Секции с заполненными накопителями под угрозой скачка."
	announce_end_text = "Ионная буря прошла. Выработка возвращается к расчётной."

/datum/round_event/space_weather/ion_blizzard/apply_intensity(current_intensity)
	// Выработка растёт с самого подхода: именно по ней инженерия и видит, что успевает.
	GLOB.solar_output_multiplier = 1 + (ION_BLIZZARD_SOLAR_BOOST - 1) * current_intensity
	// Скачки бьют только на пике. Подход - это окно подготовки, и жечь в нём лампы
	// значило бы наказывать за то, к чему ещё только предлагалось подготовиться.
	if(phase != PHENOMENON_PHASE_PEAK)
		return
	surge_unprepared_sections(current_intensity)

/datum/round_event/space_weather/ion_blizzard/cleanup_effects()
	GLOB.solar_output_multiplier = 1

/datum/round_event/space_weather/ion_blizzard/sensor_readout()
	. = list("Спектр: поток заряженных частиц высокой плотности, жёсткой составляющей нет.")
	. += "Прогноз на пик: выработка панелей x[ION_BLIZZARD_SOLAR_BOOST]."
	. += "Секции с накопителями заполненнее [round(ION_BLIZZARD_HEADROOM * 100)]% примут скачок на освещение."
	if(phase == PHENOMENON_PHASE_APPROACH)
		. += "До фронта есть время развернуть массив и освободить накопители."

/**
 * Разряжает избыток в секцию, которой некуда его принять.
 *
 * Кандидаты берутся из GLOB.apcs_list - готового отфильтрованного списка, - а не обходом
 * машинерии: полный проход ради одного контроллера за тик стоил бы дороже всего события.
 */
/datum/round_event/space_weather/ion_blizzard/proc/surge_unprepared_sections(current_intensity)
	if(!prob(current_intensity * ION_BLIZZARD_SURGE_CHANCE))
		return
	var/list/obj/machinery/power/apc/candidates = list()
	for(var/obj/machinery/power/apc/controller as anything in GLOB.apcs_list)
		if(QDELETED(controller) || !controller.cell || !controller.operating)
			continue
		if(controller.machine_stat & (BROKEN|MAINT))
			continue
		if(!is_station_level(controller.z))
			continue
		// Заполненный накопитель и означает "принять избыток нечем".
		if(controller.cell.charge < controller.cell.maxcharge * ION_BLIZZARD_HEADROOM)
			continue
		candidates += controller
	if(!length(candidates))
		return
	var/obj/machinery/power/apc/unlucky = pick(candidates)
	var/area/hit_area = get_area(unlucky)
	unlucky.overload_lighting()
	if(hit_area)
		for(var/mob/living/witness in hit_area)
			if(witness.client)
				to_chat(witness, span_warning("Свет вспыхивает и с треском гаснет - по сети прошёл скачок."))

#undef ION_BLIZZARD_SOLAR_BOOST
#undef ION_BLIZZARD_SURGE_CHANCE
#undef ION_BLIZZARD_HEADROOM
