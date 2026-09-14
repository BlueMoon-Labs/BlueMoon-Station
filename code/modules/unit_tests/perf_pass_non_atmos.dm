/// Покрытие оптимизационного прохода по не-атмосным горячим точкам
/// (профили SSMachines / SSfastprocess / SStgui раундов 9859-9860).
///
/// Каждый тест пришпиливает ОБЕ стороны правки: и снятую работу, и сохранённое
/// поведение - оптимизация не имеет права менять наблюдаемый результат.

// ===== Эмиттер: холостая перерисовка иконки =====

/// Считает перестроения иконки: update_icon_state() зовётся только из update_icon().
/obj/machinery/power/emitter/unit_test_icon_counter
	var/icon_state_updates = 0

/obj/machinery/power/emitter/unit_test_icon_counter/update_icon_state()
	icon_state_updates++
	return ..()

/// Незаваренный эмиттер (то самое состояние, в котором мапповые эмиттеры стоят почти
/// весь раунд) не имеет права перестраивать иконку на каждом проходе SSmachines.
/datum/unit_test/emitter_idle_skips_icon_rebuild/Run()
	var/obj/machinery/power/emitter/unit_test_icon_counter/emitter = allocate(/obj/machinery/power/emitter/unit_test_icon_counter)
	emitter.active = FALSE
	emitter.icon_state_updates = 0

	for(var/i in 1 to 5)
		emitter.process()

	TEST_ASSERT_EQUAL(emitter.icon_state_updates, 0, "холостой незаваренный эмиттер не должен перестраивать иконку ни разу за пять проходов")
	TEST_ASSERT(!emitter.active, "холостой незаваренный эмиттер обязан оставаться выключенным")
	TEST_ASSERT_EQUAL(emitter.icon_state, initial(emitter.icon_state), "у выключенного эмиттера должен стоять базовый icon_state")

/// Сохранённое поведение: включённый, но не заваренный эмиттер обязан выключиться
/// и перерисоваться - ровно один раз, а не на каждом последующем проходе.
/datum/unit_test/emitter_active_deactivates_once/Run()
	var/obj/machinery/power/emitter/unit_test_icon_counter/emitter = allocate(/obj/machinery/power/emitter/unit_test_icon_counter)
	emitter.active = TRUE
	emitter.icon_state_updates = 0

	emitter.process()
	TEST_ASSERT(!emitter.active, "не заваренный эмиттер обязан выключаться на первом же проходе")
	TEST_ASSERT_EQUAL(emitter.icon_state_updates, 1, "выключение обязано перестроить иконку ровно один раз")

	for(var/i in 1 to 5)
		emitter.process()
	TEST_ASSERT_EQUAL(emitter.icon_state_updates, 1, "после выключения дальнейшие проходы не должны трогать иконку")

/// Учёт попаданий по суперматерии больше не ищет кристаллы обходом range(20), но
/// снимать регистрацию обязан ровно с тех кристаллов, где её ставил.
/datum/unit_test/emitter_supermatter_registration_roundtrip/Run()
	var/obj/machinery/power/emitter/emitter = allocate(/obj/machinery/power/emitter)
	var/obj/machinery/power/supermatter_crystal/crystal = allocate(/obj/machinery/power/supermatter_crystal)

	TEST_ASSERT(!(emitter in crystal.emitter_beam_active), "до выстрела эмиттер не должен числиться бьющим по кристаллу")

	emitter.register_supermatter_beam_hit(crystal)
	TEST_ASSERT(emitter in crystal.emitter_beam_active, "после регистрации попадания эмиттер обязан числиться бьющим по кристаллу")
	TEST_ASSERT_EQUAL(length(emitter.registered_supermatters), 1, "эмиттер обязан запомнить ровно один кристалл")

	// Повторное попадание в тот же кристалл не должно плодить записи.
	emitter.register_supermatter_beam_hit(crystal)
	TEST_ASSERT_EQUAL(length(emitter.registered_supermatters), 1, "повторное попадание в тот же кристалл не должно дублировать запись")

	emitter.clear_supermatter_beam_registrations()
	TEST_ASSERT(!(emitter in crystal.emitter_beam_active), "снятие регистрации обязано убрать эмиттер из списка кристалла")
	TEST_ASSERT_EQUAL(length(emitter.registered_supermatters), 0, "после снятия регистрации список кристаллов обязан опустеть")

// ===== sortmobs(): сортировка подмножества =====

/// sortmobs() принимает произвольный список и обязан сохранить прежний порядок
/// "сначала по типу, потом по имени", не подмешивая мобов вне списка.
/datum/unit_test/sortmobs_respects_source_list/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey)
	var/mob/living/carbon/monkey/excluded = allocate(/mob/living/carbon/monkey)

	// Порядок в источнике намеренно обратный итоговому.
	var/list/sorted = sortmobs(list(monkey, human))

	TEST_ASSERT_EQUAL(length(sorted), 2, "sortmobs() обязан вернуть ровно переданных мобов")
	TEST_ASSERT_EQUAL(sorted[1], human, "человек в раскладке по типам идёт раньше обезьяны")
	TEST_ASSERT_EQUAL(sorted[2], monkey, "обезьяна обязана идти второй")
	TEST_ASSERT(!(excluded in sorted), "моб вне переданного списка не имеет права попасть в результат")

// ===== Статус-дисплей: переиспользование оверлея короткой строки =====

/// Тикающий таймер шаттла меняет только текст короткой строки. Пересоздавать ради
/// этого объект-оверлей (qdel + new + vis_contents) не нужно - у короткой строки нет
/// ни маски-фильтра, ни анимации бегущей строки.
/datum/unit_test/status_display_short_line_reuses_overlay/Run()
	var/obj/machinery/status_display/display = allocate(/obj/machinery/status_display)
	display.set_machine_stat(display.machine_stat & ~(NOPOWER|BROKEN))
	display.current_mode = SD_MESSAGE

	display.set_messages("EVAC", "1:23")
	var/obj/effect/overlay/status_display_text/timer_overlay = display.message2_overlay
	TEST_ASSERT_NOTNULL(timer_overlay, "короткая строка обязана получить оверлей")
	TEST_ASSERT_EQUAL(timer_overlay.message, "1:23", "оверлей обязан помнить свой текст")

	display.set_messages("EVAC", "1:22")
	TEST_ASSERT_EQUAL(display.message2_overlay, timer_overlay, "смена одной короткой строки на другую обязана переиспользовать тот же оверлей")
	TEST_ASSERT_EQUAL(display.message2_overlay.message, "1:22", "переиспользованный оверлей обязан показывать новый текст")
	TEST_ASSERT(findtext(display.message2_overlay.maptext, "1:22"), "maptext переиспользованного оверлея обязан быть перерисован")

	// Длинная строка это уже бегущая строка с маской и анимацией - её нельзя чинить на месте.
	display.set_messages("EVAC", "OVERFLOWING")
	TEST_ASSERT_NOTEQUAL(display.message2_overlay, timer_overlay, "переход на длинную строку обязан пересоздать оверлей")
	TEST_ASSERT_EQUAL(display.message2_overlay.message, "OVERFLOWING", "новый оверлей обязан нести длинный текст")

// ===== Пена: холостой проход по содержимому турфа =====

/// Считает проходы реакции реагентов и суммарную долю объёма.
/obj/effect/foam_exposure_probe
	name = "foam exposure probe"
	anchored = TRUE
	density = FALSE
	level = 2
	var/exposures = 0
	var/total_fraction = 0

/obj/effect/foam_exposure_probe/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_reagent_exposure))

/obj/effect/foam_exposure_probe/proc/on_reagent_exposure(datum/source, list/reagents, datum/reagents/holder, method, volume_modifier)
	SIGNAL_HANDLER
	exposures++
	total_fraction += volume_modifier

/// Пена для потикового прогона: без растекания, без медленного процессинга (множитель тика равен единице), с химией.
/datum/unit_test/proc/setup_foam_tick_probe(obj/effect/particle_effect/foam/foam, lifetime)
	foam.amount = 0
	foam.allow_slow_processing = FALSE
	foam.lifetime = lifetime
	foam.reagents.add_reagent(/datum/reagent/consumable/sugar, 10)

/// Сохранённое поведение: на рабочем тике пена обрабатывает содержимое своего турфа.
/datum/unit_test/foam_exposes_turf_contents/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/foam = allocate(/obj/effect/particle_effect/foam)
	setup_foam_tick_probe(foam, foam.reagent_divisor + 2) // после декремента остаток от деления ненулевой

	probe.exposures = 0
	foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 1, "пена обязана обработать предмет на своём турфе на рабочем тике")

/// Сохранённое поведение: на тике, где lifetime кратен reagent_divisor, реакции нет.
/datum/unit_test/foam_skips_turf_contents_on_idle_tick/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/foam = allocate(/obj/effect/particle_effect/foam)
	setup_foam_tick_probe(foam, foam.reagent_divisor + 1) // после декремента делится нацело

	probe.exposures = 0
	foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 0, "на холостом тике пена не имеет права трогать содержимое турфа")

/// Обычная пена дозирует каждый рабочий тик: пороговые по объёму reaction_obj/turf
/// разрушают от одного крупного удара не то, что от нескольких мелких.
/datum/unit_test/foam_doses_turf_contents_every_tick/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/foam = allocate(/obj/effect/particle_effect/foam)
	setup_foam_tick_probe(foam, foam.reagent_divisor) // три следующих тика все рабочие

	probe.exposures = 0
	for(var/i in 1 to 3)
		foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 3, "обычная пена обязана дозировать каждый рабочий тик, а не копить дозу")

/// Короткоживущая пена копит дозу и выдаёт её раз в reagent_divisor рабочих тиков.
/datum/unit_test/short_life_foam_batches_turf_doses/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/short_life/foam = allocate(/obj/effect/particle_effect/foam/short_life)
	setup_foam_tick_probe(foam, foam.reagent_divisor * 4)
	TEST_ASSERT(foam.batch_reagent_doses, "Sanity: короткоживущая пена обязана копить дозу")

	probe.exposures = 0
	foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 1, "короткоживущая пена обязана применить химию первым же тиком")
	foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 1, "следующий тик обязан копить дозу, а не обходить содержимое турфа")

	for(var/i in 3 to foam.reagent_divisor + 1)
		foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 1, "холостой тик не должен считаться в накопление: выдача набирается только рабочими тиками")
	foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 2, "накопленная за reagent_divisor рабочих тиков доза обязана выдаться одним проходом")

/// Суммарная доза за жизнь короткоживущей пены равна дозе обычной: батч меняет ритм, а не количество.
/datum/unit_test/short_life_foam_total_dose_matches_plain_foam/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/short_life/batched = allocate(/obj/effect/particle_effect/foam/short_life)
	var/foam_lifetime = initial(batched.lifetime)
	setup_foam_tick_probe(batched, foam_lifetime)

	probe.exposures = 0
	probe.total_fraction = 0
	for(var/i in 1 to foam_lifetime)
		batched.process()
	TEST_ASSERT(batched.lifetime < 1, "Sanity: за [foam_lifetime] тиков пена обязана дожить до смерти")
	var/batched_exposures = probe.exposures
	var/batched_total = probe.total_fraction

	var/obj/effect/particle_effect/foam/plain = allocate(/obj/effect/particle_effect/foam)
	setup_foam_tick_probe(plain, foam_lifetime)
	probe.exposures = 0
	probe.total_fraction = 0
	for(var/i in 1 to foam_lifetime)
		plain.process()
	TEST_ASSERT(plain.lifetime < 1, "Sanity: обычная пена с той же жизнью тоже обязана умереть")

	TEST_ASSERT(batched_exposures < probe.exposures, "батч обязан ходить по содержимому турфа реже обычной пены ([batched_exposures] против [probe.exposures])")
	TEST_ASSERT(abs(batched_total - probe.total_fraction) < 0.001, "суммарная доза батча ([batched_total]) обязана совпасть с дозой обычной пены ([probe.total_fraction])")

/// Пена, убитая не естественной смертью, выдаёт накопленный остаток ровно один раз.
/datum/unit_test/short_life_foam_flushes_dose_on_kill/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/short_life/foam = allocate(/obj/effect/particle_effect/foam/short_life)
	setup_foam_tick_probe(foam, foam.reagent_divisor * 4)

	foam.process()
	foam.process()
	foam.process()
	TEST_ASSERT_EQUAL(foam.react_ticks, 2, "Sanity: к третьему тику накоплено два рабочих тика")

	probe.exposures = 0
	probe.total_fraction = 0
	foam.kill_foam()
	TEST_ASSERT_EQUAL(probe.exposures, 1, "kill_foam обязан выдать накопленный остаток дозы")
	TEST_ASSERT(abs(probe.total_fraction - 2 / foam.reagent_divisor) < 0.001, "остаток обязан быть ровно накопленной долей: [probe.total_fraction] против [2 / foam.reagent_divisor]")
	TEST_ASSERT_EQUAL(foam.react_ticks, 0, "после выдачи остатка накопление обязано обнулиться")

	foam.kill_foam()
	TEST_ASSERT_EQUAL(probe.exposures, 1, "повторная смерть не должна выдавать остаток второй раз")

/// Пене без реагентов реагировать нечем - обход содержимого турфа ей не нужен.
/datum/unit_test/foam_without_reagents_skips_turf_contents/Run()
	var/obj/effect/foam_exposure_probe/probe = allocate(/obj/effect/foam_exposure_probe)
	var/obj/effect/particle_effect/foam/foam = allocate(/obj/effect/particle_effect/foam)
	foam.amount = 0
	foam.allow_slow_processing = FALSE
	foam.lifetime = foam.reagent_divisor + 2

	probe.exposures = 0
	foam.process()
	TEST_ASSERT_EQUAL(probe.exposures, 0, "пена с пустым холдером не имеет права обходить содержимое турфа")

// ===== Покрытие противометеоритного щита =====

/// Кэш покрытия отдаётся без пересчёта и сбрасывается при изменении сети спутников.
/datum/unit_test/shield_coverage_is_cached
	var/saved_cache
	var/saved_expiry
	var/cache_saved = FALSE

/datum/unit_test/shield_coverage_is_cached/Destroy()
	if(cache_saved)
		GLOB.shield_coverage_cache = saved_cache
		GLOB.shield_coverage_cache_expiry = saved_expiry
	return ..()

/datum/unit_test/shield_coverage_is_cached/Run()
	saved_cache = GLOB.shield_coverage_cache
	saved_expiry = GLOB.shield_coverage_cache_expiry
	cache_saved = TRUE
	var/datum/station_goal/station_shield/goal = GLOB.shield_goal_coverage_dummy
	TEST_ASSERT_NOTNULL(goal, "Sanity: дамми цели станции обязан существовать")

	GLOB.shield_coverage_cache = 4242
	GLOB.shield_coverage_cache_expiry = world.time + 1 MINUTES
	TEST_ASSERT_EQUAL(goal.get_coverage(), 4242, "Живой кэш обязан отдаваться без пересчёта view() по спутникам")

	GLOB.shield_coverage_cache_expiry = world.time - 1
	var/after_expiry = goal.get_coverage()
	TEST_ASSERT_NOTEQUAL(after_expiry, 4242, "Просроченный кэш обязан пересчитываться, а не отдавать старое число")

	GLOB.shield_coverage_cache = 4242
	GLOB.shield_coverage_cache_expiry = world.time + 1 MINUTES
	invalidate_shield_coverage()
	TEST_ASSERT(GLOB.shield_coverage_cache_expiry <= world.time, "Сброс обязан помечать кэш протухшим")
	var/recomputed = goal.get_coverage()
	TEST_ASSERT_NOTEQUAL(recomputed, 4242, "После сброса кэша покрытие обязано пересчитаться, а не отдать старое число")
	TEST_ASSERT_EQUAL(GLOB.shield_coverage_cache, recomputed, "Пересчёт обязан положить результат обратно в кэш")
	TEST_ASSERT(GLOB.shield_coverage_cache_expiry > world.time, "Пересчёт обязан продлить срок жизни кэша")

// ===== Список игнора ботов =====

/// ignore_list стал ассоциативным множеством. Проверяем, что членство читается,
/// вытеснение самого старого работает и повторная запись не плодит дублей.
/datum/unit_test/bot_ignore_list_is_a_set/Run()
	var/mob/living/simple_animal/bot/cleanbot/bot = allocate(/mob/living/simple_animal/bot/cleanbot)
	var/obj/effect/foam_exposure_probe/mess = allocate(/obj/effect/foam_exposure_probe)
	var/mess_ref = REF(mess)

	bot.ignore_list = list()
	bot.add_to_ignore(mess)
	TEST_ASSERT(bot.ignore_list[mess_ref], "добавленная цель обязана читаться из ignore_list по ключу")
	TEST_ASSERT_EQUAL(length(bot.ignore_list), 1, "одна цель - одна запись")

	bot.add_to_ignore(mess)
	TEST_ASSERT_EQUAL(length(bot.ignore_list), 1, "повторное добавление той же цели не должно плодить записи")

	// Переполнение: список держит не больше 50 записей, вытесняя самую старую.
	bot.ignore_list = list()
	for(var/i in 1 to 50)
		bot.ignore_list["synthetic_ref_[i]"] = TRUE

	bot.add_to_ignore(mess)
	TEST_ASSERT_EQUAL(length(bot.ignore_list), 50, "переполненный ignore_list обязан держать ровно пятьдесят записей")
	TEST_ASSERT(bot.ignore_list[mess_ref], "новая запись обязана попасть в переполненный список")
	TEST_ASSERT(!bot.ignore_list["synthetic_ref_1"], "самая старая запись обязана вытесниться")
	TEST_ASSERT(bot.ignore_list["synthetic_ref_2"], "вытесняться должна ровно одна запись, самая старая")
