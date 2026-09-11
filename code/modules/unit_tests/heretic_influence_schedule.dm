/// Геометрию станции заменяем известным полом; создание и владение разломами остаются настоящими.
/datum/reality_smash_tracker/influence_schedule_fixture
	var/list/spawn_locations = list()
	var/spawn_index = 1

/datum/reality_smash_tracker/influence_schedule_fixture/find_spawn_turf()
	if(spawn_index > length(spawn_locations))
		return null
	return spawn_locations[spawn_index++]

/datum/unit_test/proc/allocate_influence_tracker()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate(/datum/reality_smash_tracker/influence_schedule_fixture)
	for(var/turf/open/floor as anything in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		tracker.spawn_locations += floor
	return tracker

/// Поздний участник не ускоряет сеть; в один наступивший срок появляется ровно один разлом.
/datum/unit_test/heretic_influence_schedule_start/Run()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate_influence_tracker()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/start_before = world.time
	tracker.AddMind(first.owner)
	var/start_after = world.time
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Первый еретик получает три доступных стартовых разлома.")
	TEST_ASSERT(tracker.influence_timer, "Следующий разлом должен иметь таймер.")
	TEST_ASSERT(tracker.next_influence_at >= start_before + HERETIC_INFLUENCE_INTERVAL && tracker.next_influence_at <= start_after + HERETIC_INFLUENCE_INTERVAL, "Первый срок отсчитывается от запуска сети.")
	for(var/obj/effect/reality_smash/influence as anything in tracker.smashes)
		TEST_ASSERT_EQUAL(influence.network_ref.resolve(), tracker, "Новый разлом принадлежит породившей его сети.")
		TEST_ASSERT(!(influence in GLOB.reality_smash_track.smashes), "Локальная сеть не должна засорять глобальную.")
	var/original_deadline = tracker.next_influence_at
	var/original_timer = tracker.influence_timer
	var/datum/antagonist/heretic/late = allocate_heretic()
	tracker.AddMind(late.owner)
	tracker.AddMind(first.owner)
	tracker.Generate()
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Поздняя и повторная выдача роли не создаёт стартовых пачек.")
	TEST_ASSERT_EQUAL(tracker.next_influence_at, original_deadline, "Приход участника не переносит срок появления.")
	TEST_ASSERT_EQUAL(tracker.influence_timer, original_timer, "Приход участника не заменяет уже поставленный таймер.")
	TEST_ASSERT(!tracker.spawn_scheduled_influence(), "Досрочный вызов не должен порождать разлом.")
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "До срока сохраняется стартовое количество.")
	tracker.next_influence_at = world.time
	var/spawn_before = world.time
	TEST_ASSERT(tracker.spawn_scheduled_influence(), "Наступивший срок должен породить один разлом.")
	var/spawn_after = world.time
	TEST_ASSERT_EQUAL(length(tracker.smashes), 4, "За один срок сеть вырастает ровно на один разлом.")
	TEST_ASSERT(tracker.next_influence_at >= spawn_before + HERETIC_INFLUENCE_INTERVAL && tracker.next_influence_at <= spawn_after + HERETIC_INFLUENCE_INTERVAL, "Следующий срок отсчитывается от обработки предыдущего.")
	TEST_ASSERT(!tracker.spawn_scheduled_influence(), "Повторный вызов в том же тике не должен ускорять сеть.")
	TEST_ASSERT_EQUAL(length(tracker.smashes), 4, "Повторная обработка не выдаёт ещё один разлом.")

/// Сеть останавливается на прежних пределах 8/10/12, а удаление разлома не запускает пачку замены.
/datum/unit_test/heretic_influence_schedule_capacity/Run()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate_influence_tracker()
	for(var/participant in 1 to 3)
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/count_before = length(tracker.smashes)
		tracker.AddMind(heretic.owner)
		if(participant > 1)
			TEST_ASSERT_EQUAL(length(tracker.smashes), count_before, "Расширение предела не создаёт разлом немедленно.")
		var/expected_limit = 6 + 2 * participant
		while(length(tracker.smashes) < expected_limit)
			tracker.next_influence_at = world.time
			TEST_ASSERT(tracker.spawn_scheduled_influence(), "Сеть должна расти до предела для числа участников.")
		TEST_ASSERT_EQUAL(length(tracker.smashes), expected_limit, "Сеть должна остановиться на своём пределе.")
		TEST_ASSERT_NULL(tracker.influence_timer, "Полная сеть не должна держать пустой таймер.")
		TEST_ASSERT(!tracker.spawn_scheduled_influence(), "Ручной вызов не должен переполнять сеть.")
	var/deadline = tracker.next_influence_at
	var/obj/effect/reality_smash/removed = tracker.smashes[12]
	qdel(removed)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 11, "Удаление разлома освобождает место в его собственной сети.")
	TEST_ASSERT(tracker.influence_timer, "После потери разлома сеть может продолжить расписание.")
	TEST_ASSERT_EQUAL(tracker.next_influence_at, deadline, "Потеря разлома не обнуляет срок замены.")
	tracker.next_influence_at = world.time
	TEST_ASSERT(tracker.spawn_scheduled_influence(), "Наступивший срок восстанавливает один потерянный разлом.")
	TEST_ASSERT_EQUAL(length(tracker.smashes), 12, "После замены сеть снова ограничена двенадцатью разломами.")
	var/datum/mind/departed = tracker.targets[3]
	tracker.RemoveMind(departed)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 12, "Уход еретика не удаляет разломы и историю исследований.")
	TEST_ASSERT_NULL(tracker.influence_timer, "Уменьшенный предел не оставляет бесполезный таймер.")

/// Снятие роли останавливает таймер, но не забывает срок и личный предел шести исследований.
/datum/unit_test/heretic_influence_schedule_resume/Run()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate_influence_tracker()
	var/datum/antagonist/heretic/original = allocate_heretic()
	var/datum/mind/mind = original.owner
	var/mob/living/body = mind.current
	tracker.AddMind(mind)
	var/deadline = tracker.next_influence_at
	tracker.harvest_counts[mind] = HERETIC_INFLUENCE_LIMIT
	original.influences_harvested = HERETIC_INFLUENCE_LIMIT
	tracker.RemoveMind(mind)
	TEST_ASSERT_NULL(tracker.influence_timer, "Без еретиков таймер должен останавливаться.")
	TEST_ASSERT_EQUAL(tracker.next_influence_at, deadline, "Остановка не забывает прежний срок.")
	qdel(original)
	var/datum/antagonist/heretic/replacement = allocate(/datum/antagonist/heretic)
	replacement.owner = mind
	replacement.silent = TRUE
	mind.antag_datums = list(replacement)
	tracker.AddMind(mind)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Повторная выдача роли не возвращает стартовую пачку.")
	TEST_ASSERT_EQUAL(tracker.next_influence_at, deadline, "Повторная выдача не откладывает следующий разлом.")
	TEST_ASSERT_EQUAL(replacement.influences_harvested, HERETIC_INFLUENCE_LIMIT, "Личный предел переживает замену антагониста.")
	tracker.RemoveMind(mind)
	tracker.next_influence_at = world.time - 40 MINUTES
	tracker.AddMind(mind)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Возобновление после простоя не выдаёт пропущенные разломы пачкой.")
	TEST_ASSERT(tracker.spawn_scheduled_influence(), "Просроченный срок выдаёт один разлом при возобновлении.")
	TEST_ASSERT_EQUAL(length(tracker.smashes), 4, "Сорок минут простоя не превращаются в пять разломов.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, body)
	var/obj/effect/reality_smash/new_influence = tracker.smashes[4]
	body.forceMove(get_turf(new_influence))
	TEST_ASSERT(!new_influence.can_harvest(body, book), "Новые разломы не обходят личный предел повторно выданной роли.")
	qdel(tracker)
	TEST_ASSERT_NULL(tracker.influence_timer, "Удаление сети отменяет её таймер.")
	TEST_ASSERT(QDELETED(new_influence), "Удаление локальной сети забирает её разломы.")

/// Ошибка выбора пола не теряет стартовую выдачу и не создаёт быстрый цикл повторов.
/datum/unit_test/heretic_influence_schedule_missing_turf/Run()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate_influence_tracker()
	var/list/available_locations = tracker.spawn_locations.Copy()
	tracker.spawn_locations.Cut()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	tracker.AddMind(heretic.owner)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 0, "Без подходящего пола сеть остаётся пустой.")
	TEST_ASSERT(!tracker.initial_influences_seeded, "Неудачная попытка не засчитывается как стартовая выдача.")
	TEST_ASSERT(tracker.influence_timer, "Неудачная попытка оставляет одну отложенную попытку.")
	tracker.spawn_locations = available_locations.Copy()
	tracker.next_influence_at = world.time
	tracker.spawn_scheduled_influence()
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "После готовности карты появляется только стартовая тройка.")
	TEST_ASSERT(tracker.initial_influences_seeded, "Успешная стартовая выдача больше не повторяется.")
	tracker.spawn_locations.Cut()
	tracker.next_influence_at = world.time
	var/retry_before = world.time
	TEST_ASSERT(!tracker.spawn_scheduled_influence(), "Отсутствие свободного пола не создаёт ложный разлом.")
	var/retry_after = world.time
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Неудачный срок сохраняет существующую сеть.")
	TEST_ASSERT(tracker.next_influence_at >= retry_before + HERETIC_INFLUENCE_INTERVAL && tracker.next_influence_at <= retry_after + HERETIC_INFLUENCE_INTERVAL, "Ошибка выбора пола сохраняет полный интервал до повторной попытки.")
	tracker.spawn_locations = available_locations.Copy()
	tracker.next_influence_at = world.time
	TEST_ASSERT(tracker.spawn_scheduled_influence(), "Освободившийся пол принимается при следующем сроке.")
	TEST_ASSERT_EQUAL(length(tracker.smashes), 4, "После неудачи выдаётся только один новый разлом.")

/// Ложные следы аномальной станции остаются мгновенными и не вмешиваются в расписание настоящих разломов.
/datum/unit_test/heretic_influence_schedule_fake/Run()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate_influence_tracker()
	tracker.Generate(fake_count = 2)
	var/list/traces = list()
	for(var/turf/location as anything in tracker.spawn_locations)
		for(var/obj/effect/broken_illusion/trace in location)
			allocated |= trace
			traces |= trace
	TEST_ASSERT_EQUAL(length(traces), 2, "Ложные разломы создаются сразу, даже без еретиков.")
	for(var/obj/effect/broken_illusion/trace as anything in traces)
		TEST_ASSERT(trace.fake, "Разломы станции сохраняют признак ложного следа.")
	TEST_ASSERT_EQUAL(length(tracker.smashes), 0, "Ложные следы не считаются настоящими разломами.")
	TEST_ASSERT(!tracker.initial_influences_seeded, "Ложные следы не расходуют стартовую выдачу еретика.")
	TEST_ASSERT_NULL(tracker.influence_timer, "Ложные следы не запускают расписание без еретиков.")
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	tracker.AddMind(heretic.owner)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Еретик получает полную стартовую тройку после ложных следов.")
