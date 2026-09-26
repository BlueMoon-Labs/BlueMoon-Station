/// Прямые фикстуры не зависят от присутствия настоящей станции в профиле запуска.
/// Раскладка фикстуры: врата в комнате 2, вход в 14, осколки в 3, 16 и 9, затворы между 8-12 (a) и 12-16 (b), в комнате 7 колонна и ниша.
GLOBAL_LIST_INIT(heretic_mansus_test_rows, list(
		"#################################",
		"#.......#.......#.......#.......#",
		"#.......#...G...#.......#.......#",
		"#.......#.......#.......#.......#",
		"#.......+...D...+...1...+.......#",
		"#.......#.......#.......#.......#",
		"#.......#.V...V.#.......#.......#",
		"#.......#...+...#.......#.......#",
		"####+#######+####################",
		"#.......#.......#.......#.......#",
		"#.......#.......#.......#.......#",
		"#.......#.......#...#...#.......#",
		"#.......+.......+.......+.......#",
		"#.......#.......#.n.....#.......#",
		"#.......#.......#.......#.......#",
		"#.......#.......#.......#.......#",
		"############+###############a####",
		"#.......#.......#.......#.......#",
		"#.......#.......#.......#.......#",
		"#.......#.......#.......#.......#",
		"#...3...+.......+.......+.......#",
		"#.......#.......#.......#.......#",
		"#.......#.......#.......#.......#",
		"#.......#.......#.......#.......#",
		"############+###############b####",
		"#.......#.......#.......#.......#",
		"#.......#.S...S.#.......#.......#",
		"#.......#.......#.......#.......#",
		"#.......++..E..++.......+...2...#",
		"#.......#.......#.......#.......#",
		"#.......#.V...V.#.......#.......#",
		"#.......#.......#.......#.......#",
		"#################################",
))

/datum/heretic_mansus_visit/mansus_fixture
	recall_duration = 0.3 SECONDS
	delivery_duration = 0.3 SECONDS
	danger_enabled = FALSE

/datum/heretic_mansus_visit/mansus_fixture/New()
	. = ..()
	forced_rows = GLOB.heretic_mansus_test_rows

/datum/heretic_mansus_visit/mansus_fixture/find_return_turf()
	return return_turf

/obj/machinery/telecomms/receiver/mansus_fixture
	var/obj/item/radio/tracked_radio
	var/received_messages = 0

/obj/machinery/telecomms/receiver/mansus_fixture/Destroy()
	tracked_radio = null
	return ..()

/obj/machinery/telecomms/receiver/mansus_fixture/receive_signal(datum/signal/subspace/signal)
	if(signal.source == tracked_radio)
		received_messages++

/obj/item/radio/mansus_receiver
	independent = TRUE
	frequency = FREQ_CENTCOM
	var/received_messages = 0

/obj/item/radio/mansus_receiver/can_receive(freq, level)
	. = ..()
	if(.)
		received_messages++

/datum/signal/subspace/vocal/mansus_fixture
	var/broadcasts = 0

/datum/signal/subspace/vocal/mansus_fixture/broadcast()
	broadcasts++

/// Мансус блокирует приём на всех каналах и восстанавливает его при возвращении вещей.
/datum/unit_test/heretic_mansus_radio_reception/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/item/radio/headset/headset = allocate(/obj/item/radio/headset, victim)
	victim.equip_to_slot_or_del(headset, ITEM_SLOT_EARS_LEFT)
	TEST_ASSERT_EQUAL(victim.ears, headset, "Гарнитура должна быть надета для проверки приёма.")
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, victim)
	var/obj/item/radio/intercom/intercom = allocate(/obj/item/radio/intercom, get_turf(victim))
	var/list/radios = list(
		headset,
		allocate(/obj/item/radio, victim),
		allocate(/obj/item/radio, bag),
		allocate(/obj/item/radio, get_turf(victim)),
		intercom,
	)
	var/obj/item/radio/outside = allocate(/obj/item/radio, visit.return_turf)
	TEST_ASSERT_EQUAL(outside.z, victim.z, "Контрольная рация должна быть на том же z-уровне за пределами Мансуса.")
	TEST_ASSERT(outside.can_receive(FREQ_COMMON, list(outside.z)), "Связь за пределами комнаты сохраняется.")
	for(var/obj/item/radio/radio as anything in radios)
		radio.on = TRUE
		radio.independent = TRUE
		radio.syndie = TRUE
		for(var/frequency in list(FREQ_COMMON, FREQ_SYNDICATE, FREQ_CENTCOM))
			radio.set_frequency(frequency)
			TEST_ASSERT(!radio.can_receive(frequency, list(victim.z)), "Мансус блокирует приём на частоте [frequency] у [radio.type].")
			TEST_ASSERT(!radio.can_receive(frequency, list(0)), "Передача на все уровни не обходит блокировку у [radio.type].")
	visit.finish()
	// У тестовой области нет питания от APC.
	intercom.on = TRUE
	for(var/obj/item/radio/radio as anything in radios)
		TEST_ASSERT(!QDELETED(radio), "Возвращение сохраняет рацию.")
		TEST_ASSERT_EQUAL(get_turf(radio), get_turf(victim), "Радио возвращается вместе с жертвой, включая брошенные устройства.")
		for(var/frequency in list(FREQ_COMMON, FREQ_SYNDICATE, FREQ_CENTCOM))
			radio.set_frequency(frequency)
			TEST_ASSERT(radio.can_receive(frequency, list(victim.z)), "После выхода приём на частоте [frequency] у [radio.type] восстанавливается.")

/// Обычная и независимая радиопередача блокируются в Мансусе и возобновляются после выхода.
/datum/unit_test/heretic_mansus_radio_transmission/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/item/radio/radio = allocate(/obj/item/radio, victim)
	radio.subspace_transmission = TRUE
	var/obj/machinery/telecomms/receiver/mansus_fixture/receiver = allocate(/obj/machinery/telecomms/receiver/mansus_fixture, visit.return_turf)
	receiver.tracked_radio = radio
	var/obj/item/radio/independent = allocate(/obj/item/radio, victim)
	independent.independent = TRUE
	independent.set_frequency(FREQ_CENTCOM)
	var/obj/item/radio/mansus_receiver/listener = allocate(/obj/item/radio/mansus_receiver, visit.return_turf)
	radio.talk_into_impl(victim, "Проверка обычной связи", spans = list())
	TEST_ASSERT_EQUAL(receiver.received_messages, 0, "Передача из Мансуса не попадает в телекоммы.")
	independent.talk_into_impl(victim, "Проверка независимой связи", spans = list())
	TEST_ASSERT_EQUAL(listener.received_messages, 0, "Независимая передача из Мансуса не достигает внешней рации.")
	visit.finish()
	radio.talk_into_impl(victim, "Проверка обычной связи", spans = list())
	TEST_ASSERT_EQUAL(receiver.received_messages, 1, "После выхода передача вновь поступает в телекоммы.")
	independent.talk_into_impl(victim, "Проверка независимой связи", spans = list())
	TEST_ASSERT_EQUAL(listener.received_messages, 1, "После выхода независимая передача достигает внешней рации.")

/// Отложенная резервная передача повторно проверяет область после перемещения рации.
/datum/unit_test/heretic_mansus_radio_backup/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/item/radio/radio = allocate(/obj/item/radio, visit.return_turf)
	var/datum/signal/subspace/vocal/mansus_fixture/signal = new(radio, FREQ_COMMON)
	allocated += signal
	radio.forceMove(victim)
	radio.backup_transmission(signal)
	TEST_ASSERT_EQUAL(signal.broadcasts, 0, "Вход в Мансус блокирует резервную передачу, подготовленную снаружи.")
	visit.finish()
	radio.backup_transmission(signal)
	TEST_ASSERT_EQUAL(signal.broadcasts, 1, "После выхода резервная передача снова работает.")

/// Пропавший выход не отправляет жертву и вещи в nullspace и не освобождает занятую комнату.
/datum/unit_test/heretic_mansus_missing_exit/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/turf/destination = visit.return_turf
	var/obj/item/pen/item = allocate(/obj/item/pen, get_turf(victim))
	visit.return_turf = null
	TEST_ASSERT(!visit.finish(), "Без выхода посещение откладывает завершение.")
	TEST_ASSERT(!visit.finished && visit.contains(victim), "Жертва остаётся в действующей комнате.")
	TEST_ASSERT(visit.contains(item), "Брошенная вещь не теряется при отсутствии выхода.")
	visit.return_turf = destination
	TEST_ASSERT(visit.finish(), "После восстановления выхода посещение завершается.")
	TEST_ASSERT_EQUAL(get_turf(victim), destination, "Жертва выходит на действительный турф.")
	TEST_ASSERT_EQUAL(get_turf(item), destination, "Брошенная вещь возвращается вместе с жертвой.")

/datum/unit_test/proc/make_mansus_fixture(visit_type = /datum/heretic_mansus_visit/mansus_fixture, previous_memory, path_id = PATH_ASH, random_layout = FALSE)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	soul.memory = previous_memory
	var/datum/heretic_mansus_visit/visit = allocate(visit_type)
	if(random_layout)
		visit.forced_rows = null
	if(!visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right, path_id) || !visit.start())
		Fail("Не удалось открыть посещение Мансуса.")
	return list("victim" = victim, "soul" = soul, "visit" = visit)

/// Предупреждение об амнезии появляется при входе, сохраняет старые записи и не дублируется при выходе.
/datum/unit_test/heretic_mansus_memory_on_entry/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/mind/soul = allocate(/datum/mind, "mansus_memory_test")
	soul.current = victim
	victim.mind = soul
	var/previous_memory = "До похищения я видел повреждённый шлюз в техническом тоннеле."
	soul.memory = previous_memory
	var/datum/heretic_mansus_visit/visit = allocate(/datum/heretic_mansus_visit/mansus_fixture)
	TEST_ASSERT(visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Комната подготавливается для живой жертвы.")
	TEST_ASSERT_EQUAL(soul.memory, previous_memory, "Подготовка комнаты ещё не меняет заметки.")
	TEST_ASSERT(visit.start(), "Жертва входит в Мансус.")
	TEST_ASSERT(visit.contains(victim), "Предупреждение проверяется внутри Мансуса.")
	TEST_ASSERT_EQUAL(visit.memories_found, 0, "Предупреждение доступно до сбора первого воспоминания.")
	TEST_ASSERT(findtext(soul.memory, visit.amnesia_note), "При входе в заметках уже есть ограничение на опознание похитителя.")	TEST_ASSERT(findtext(soul.memory, previous_memory), "Вход сохраняет прежние записи.")
	var/memory_at_entry = soul.memory
	TEST_ASSERT(!visit.start(), "Повторный запуск действующего посещения отклоняется.")
	TEST_ASSERT_EQUAL(soul.memory, memory_at_entry, "Повторный запуск не дублирует предупреждение.")
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Жертва собирает первое воспоминание после сосредоточения.")
	TEST_ASSERT_EQUAL(soul.memory, memory_at_entry, "Сбор воспоминаний не меняет предупреждение об амнезии.")
	TEST_ASSERT(visit.finish(), "Посещение завершается.")
	TEST_ASSERT_EQUAL(soul.memory, memory_at_entry, "После выхода предупреждение сохраняется без дубликата.")

/// Три доставленных осколка открывают выход без минимального таймера.
/datum/unit_test/heretic_mansus_interactive_exit/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	TEST_ASSERT(visit.contains(victim), "Жертва находится в отдельной комнате.")
	TEST_ASSERT_EQUAL(length(visit.memories), 3, "Каждой комнате соответствует один осколок.")
	TEST_ASSERT(visit.forced_exit > world.time + 145 SECONDS, "Предельное время не зависит от успехов жертвы.")
	var/obj/effect/heretic_mansus_gate/gate = visit.gate
	var/list/memories = visit.memories.Copy()
	var/count = 0
	for(var/obj/effect/heretic_mansus_memory/memory as anything in memories)
		TEST_ASSERT(memory.awake, "Доставленный осколок открывает следующий этап.")
		victim.forceMove(get_turf(memory))
		TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Сосредоточение собирает осколок.")
		TEST_ASSERT_EQUAL(visit.carried_memory, memory, "Осколок нужно донести к вратам.")
		TEST_ASSERT_EQUAL(visit.memories_found, count, "Подбор без доставки не увеличивает прогресс.")
		TEST_ASSERT(!visit.collect_memory(memory, victim), "Повторный клик не дублирует осколок.")
		victim.forceMove(get_turf(gate))
		count++
		if(count < length(memories))
			TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), count), "Врата закрепляют доставленный осколок.")
			TEST_ASSERT(memory.delivered, "Доставленный осколок защищён от потери.")
		else
			TEST_ASSERT(wait_for_qdeleted(visit), "Последняя доставка сразу завершает испытание.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Испытание возвращает жертву на станцию.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Запись посещения удалена.")
	TEST_ASSERT(!victim.alerts["heretic_mansus"], "Индикатор испытания снят.")

/datum/unit_test/heretic_mansus_cleanup_inventory/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/turf_reservation/reserved = visit.reservation
	var/obj/item/pen/dropped = allocate(/obj/item/pen, get_turf(victim))
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, get_turf(victim))
	var/obj/item/pen/packed = allocate(/obj/item/pen, bag)
	var/obj/item/pen/carried = allocate(/obj/item/pen, victim)
	var/channel = visit.music_channel
	qdel(visit)
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Удаление посещения аварийно возвращает тело.")
	TEST_ASSERT_EQUAL(get_turf(dropped), run_loc_floor_top_right, "Выпавший предмет возвращается вместе с жертвой.")
	TEST_ASSERT_EQUAL(get_turf(bag), run_loc_floor_top_right, "Брошенная сумка не удаляется при освобождении комнаты.")
	TEST_ASSERT_EQUAL(packed.loc, bag, "Содержимое сумки остаётся в ней.")
	TEST_ASSERT_EQUAL(carried.loc, victim, "Имущество на теле остаётся у владельца.")
	TEST_ASSERT(QDELETED(reserved), "Резервирование комнаты освобождается.")
	TEST_ASSERT_EQUAL(length(visit.timers), 0, "Аварийный выход отменяет все таймеры.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Аварийный выход освобождает запись души.")
	if(channel)
		TEST_ASSERT_NULL(SSsounds.using_channels["[channel]"], "Зарезервированный музыкальный канал освобождается.")

/datum/unit_test/heretic_mansus_external_rescue/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.adjustBruteLoss(10)
	var/damage_before = victim.getBruteLoss()
	TEST_ASSERT(damage_before > 0, "Перед внешним спасением жертва ранена.")
	victim.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(wait_for_qdeleted(visit), "Внешнее перемещение закрывает посещение после обработки сигнала.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_bottom_left, "Мансус не отменяет внешнее спасение тела.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), damage_before, "Внешнее спасение не даёт дополнительное удалённое лечение.")

/datum/unit_test/heretic_mansus_mind_transfer/Run()
	var/previous_memory = "До похищения я видел повреждённый шлюз в техническом тоннеле."
	var/list/fixture = make_mansus_fixture(previous_memory = previous_memory)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/memory_at_entry = soul.memory
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	new_body.adjustBruteLoss(15)
	soul.transfer_to(new_body)
	TEST_ASSERT(QDELETED(visit), "Смена тела немедленно закрывает старое посещение.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Оставленное тело возвращается на станцию.")
	TEST_ASSERT_EQUAL(get_turf(new_body), run_loc_floor_bottom_left, "Новый носитель души не телепортируется.")
	TEST_ASSERT_EQUAL(new_body.getBruteLoss(), 15, "Новый носитель души не получает чужое лечение.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Смена тела не оставляет запись о незавершённом посещении.")
	TEST_ASSERT(findtext(soul.memory, previous_memory), "Мансус не стирает знания, полученные до похищения.")
	TEST_ASSERT(length(soul.memory) > length(previous_memory), "Напоминание об амнезии сохраняется у души после смены тела.")
	TEST_ASSERT_EQUAL(soul.memory, memory_at_entry, "Смена тела сохраняет предупреждение, полученное при входе, без дубликата.")
	var/memory_after = soul.memory
	visit.finish()
	TEST_ASSERT_EQUAL(soul.memory, memory_after, "Повторное завершение не дублирует воспоминание о Доме.")

/datum/unit_test/heretic_mansus_reservation_deleted/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/item/pen/dropped = allocate(/obj/item/pen, get_turf(victim))
	qdel(visit.reservation)
	TEST_ASSERT(QDELETED(visit), "Удаление резервирования закрывает посещение до очистки турфов.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Жертва эвакуируется до удаления комнаты.")
	TEST_ASSERT_EQUAL(get_turf(dropped), run_loc_floor_top_right, "Выпавшие вещи эвакуируются до удаления комнаты.")

/datum/unit_test/heretic_mansus_victim_deleted/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/item/pen/dropped = allocate(/obj/item/pen, get_turf(victim))
	qdel(victim)
	TEST_ASSERT(QDELETED(visit), "Удаление тела не оставляет бесхозную комнату.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Удалённое тело не удерживает посещение по душе.")
	TEST_ASSERT_EQUAL(get_turf(dropped), run_loc_floor_top_right, "Вещи из комнаты сохраняются после удаления тела.")

/datum/unit_test/heretic_mansus_mind_force_deleted/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/turf_reservation/reserved = visit.reservation
	var/obj/item/pen/dropped = allocate(/obj/item/pen, get_turf(victim))
	var/channel = visit.music_channel
	TEST_ASSERT(channel, "Для проверки force-аргумента требуется выделенный музыкальный канал.")
	soul.memory = "Запись, которую удаление разума не должно дополнять."
	var/previous_memory = soul.memory
	qdel(soul, force = TRUE)
	TEST_ASSERT(QDELETED(visit), "Принудительное удаление разума завершает посещение без runtime.")
	TEST_ASSERT(QDELETED(reserved), "Принудительное удаление разума освобождает комнату.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Тело эвакуируется после принудительного удаления разума.")
	TEST_ASSERT_EQUAL(get_turf(dropped), run_loc_floor_top_right, "Выпавшие вещи сохраняются после удаления разума.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Реестр не удерживает принудительно удалённый разум.")
	TEST_ASSERT_NULL(SSsounds.using_channels["[channel]"], "Музыкальный канал освобождается при удалении разума.")
	TEST_ASSERT_EQUAL(length(visit.timers), 0, "Все таймеры посещения отменяются при удалении разума.")
	TEST_ASSERT_EQUAL(soul.memory, previous_memory, "Амнезия не записывается в уже удаляемый разум.")

/datum/heretic_mansus_visit/timeout_fixture
	parent_type = /datum/heretic_mansus_visit/mansus_fixture
	visit_duration = 2

/datum/unit_test/heretic_mansus_timeout/Run()
	var/list/fixture = make_mansus_fixture(/datum/heretic_mansus_visit/timeout_fixture)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	TEST_ASSERT(!victim.client, "Фикстура проверяет возврат жертвы без клиента.")
	TEST_ASSERT(wait_for_qdeleted(visit), "Реальный таймер возвращает бездействующую жертву без клиента.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Автоматический выход работает без воспоминаний и врат.")
	TEST_ASSERT_EQUAL(victim.stat, CONSCIOUS, "После автоматического возврата жертва остаётся в сознании.")

/// Смерть восстанавливает жертву внутри комнаты, сохраняя сроки посещения.
/datum/unit_test/heretic_mansus_death/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/forced_exit = visit.forced_exit
	victim.death()
	TEST_ASSERT(wait_for_var(victim, NAMEOF(victim, stat), CONSCIOUS), "Дом восстанавливает жертву после завершения death().")
	TEST_ASSERT(!QDELETED(visit) && visit.contains(victim), "Смерть не позволяет досрочно выйти из комнаты.")
	TEST_ASSERT_EQUAL(visit.forced_exit, forced_exit, "Смерть не продлевает посещение.")

/datum/unit_test/heretic_mansus_restoration/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, victim)
	victim.handcuffed = cuffs
	victim.update_handcuffed()
	victim.adjustBruteLoss(30)
	victim.Unconscious(30 SECONDS)
	var/datum/heretic_mansus_visit/visit = allocate(/datum/heretic_mansus_visit/mansus_fixture)
	TEST_ASSERT(visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Комната подготавливается для живой жертвы без сознания.")
	TEST_ASSERT(visit.start(), "Мансус принимает живую жертву.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Восстановление снимает полученные при похищении раны.")
	TEST_ASSERT_EQUAL(victim.stat, CONSCIOUS, "Жертва просыпается.")
	TEST_ASSERT(!QDELETED(cuffs), "Лечение не удаляет наручники из имущества жертвы.")
	TEST_ASSERT_EQUAL(victim.handcuffed, cuffs, "Вход сохраняет существующие наручники.")
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Воспоминание доступно стоящей на нём жертве в наручниках.")
	visit.finish()
	TEST_ASSERT_EQUAL(victim.handcuffed, cuffs, "Возвращение также сохраняет наручники.")
	TEST_ASSERT_EQUAL(cuffs.loc, victim, "Имущество остаётся в теле владельца.")

/// Мёртвое тело не принимается ни до подготовки комнаты, ни после неё.
/datum/unit_test/heretic_mansus_rejects_dead/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/mind/soul = allocate(/datum/mind, "mansus_dead_test")
	soul.current = victim
	victim.mind = soul
	var/previous_memory = "Запись до прерванного ритуала."
	soul.memory = previous_memory
	var/datum/heretic_mansus_visit/visit = allocate(/datum/heretic_mansus_visit/mansus_fixture)
	victim.death()
	TEST_ASSERT(!visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Труп не открывает посещение.")
	TEST_ASSERT_NULL(visit.reservation, "Отказ не резервирует комнату.")
	victim.revive(full_heal = TRUE)
	TEST_ASSERT(visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Живая цель позволяет подготовить комнату.")
	victim.death()
	var/memory_before_rejection = soul.memory
	TEST_ASSERT(!visit.start(), "Смерть после подготовки отменяет вход.")
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "Отклонённый вход не воскрешает тело.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Отклонённый вход не регистрирует душу.")
	qdel(visit)
	TEST_ASSERT_EQUAL(soul.memory, memory_before_rejection, "Отклонённый вход и удаление подготовленной комнаты не добавляют предупреждение об амнезии.")

/// Общая область переиспользуется, а комнаты и выходы одновременных посещений остаются отдельными.
/datum/unit_test/heretic_mansus_shared_area/Run()
	var/list/first_fixture = make_mansus_fixture()
	var/list/second_fixture = make_mansus_fixture()
	var/datum/heretic_mansus_visit/first = first_fixture["visit"]
	var/datum/heretic_mansus_visit/second = second_fixture["visit"]
	var/area/shared_area = first.room
	var/mob/living/second_victim = second.victim
	TEST_ASSERT_EQUAL(second.room, shared_area, "Посещения используют одну область.")
	TEST_ASSERT_NOTEQUAL(first.reservation, second.reservation, "Комнаты резервируются отдельно.")
	TEST_ASSERT(!first.contains(second.victim) && !second.contains(first.victim), "Жертвы находятся в разных комнатах.")
	first.finish()
	TEST_ASSERT(!QDELETED(shared_area), "Завершение посещения не удаляет общую область.")
	TEST_ASSERT(second.contains(second_victim), "Завершение первого посещения не выталкивает вторую жертву.")
	var/list/third_fixture = make_mansus_fixture()
	var/datum/heretic_mansus_visit/third = third_fixture["visit"]
	TEST_ASSERT_EQUAL(third.room, shared_area, "Новое посещение переиспользует область.")
	second.finish()
	third.finish()
	TEST_ASSERT_EQUAL(length(shared_area.contents), 0, "Завершённые посещения освобождают все турфы области.")

/// Движение и потеря сознания прерывают сосредоточение; чужие и спящие воспоминания недоступны.
/datum/unit_test/heretic_mansus_recall_interruptions/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_memory/first = visit.memories[1]
	var/obj/effect/heretic_mansus_memory/second = visit.memories[2]
	victim.forceMove(get_turf(second))
	TEST_ASSERT(!visit.collect_memory(second, victim), "Порядок воспоминаний нельзя пропустить.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_turf(first))
	TEST_ASSERT(!visit.collect_memory(first, stranger), "Посторонний не собирает воспоминания жертвы.")
	victim.forceMove(get_turf(first))
	TEST_ASSERT_EQUAL(visit.recalling_memory, first, "Наступание начинает сосредоточение.")
	TEST_ASSERT(!visit.collect_memory(first, victim), "Повторный клик не запускает второе сосредоточение.")
	victim.forceMove(visit.entry_turf)
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, recalling_memory), null), "Движение прекращает попытку.")
	TEST_ASSERT(!first.recalled && visit.memories_found == 0, "Прерванная попытка не выдаёт воспоминание.")
	victim.forceMove(get_turf(first))
	victim.Unconscious(5 SECONDS)
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, recalling_memory), null), "Потеря сознания прекращает попытку.")
	TEST_ASSERT(!first.recalled, "Спящая жертва не собирает воспоминание.")
	victim.SetUnconscious(0)
	first.attack_hand(victim)
	TEST_ASSERT(wait_for_var(first, NAMEOF(first, recalled), TRUE), "После пробуждения можно повторить попытку кликом.")
	TEST_ASSERT(!second.awake && visit.carried_memory == first, "Подобранный осколок сначала нужно доставить.")
	victim.forceMove(get_turf(visit.gate))
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), 1), "Доставка открывает следующий этап.")
	victim.forceMove(get_turf(second))
	TEST_ASSERT(visit.finish(), "Посещение завершается во время сосредоточения.")
	TEST_ASSERT(wait_for_var(victim, NAMEOF(victim, do_afters), null), "Ожидающее действие освобождает ссылки после выхода.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Завершение действия не возвращает жертву в удалённую комнату.")

/// Врата севернее входа, все осколки и врата доступны пешком, осколки в разных комнатах.
/datum/unit_test/heretic_mansus_layout/Run()
	var/list/fixture = make_mansus_fixture()
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/list/reachable = mansus_reachable(visit)
	for(var/obj/effect/heretic_mansus_memory/memory as anything in visit.memories)
		TEST_ASSERT(get_turf(memory) in reachable, "Каждое воспоминание доступно пешком из прихожей.")
	TEST_ASSERT(get_turf(visit.offering) in reachable, "Печать доступна пешком из прихожей.")
	TEST_ASSERT(visit.gate.y > visit.entry_turf.y, "Врата находятся к северу от прихожей.")
	var/list/cells = list()
	for(var/obj/effect/heretic_mansus_memory/memory as anything in visit.memories)
		TEST_ASSERT(!(memory.chamber in cells), "Осколки лежат в разных комнатах.")
		cells += memory.chamber
	TEST_ASSERT_EQUAL(length(visit.walkable_turfs), length(reachable), "В раскладке нет закрытых карманов.")
	TEST_ASSERT(locate(/obj/effect/heretic_mansus_niche) in mansus_tile(visit, 19, 14), "Ниша из раскладки стоит на месте.")

/// Генератор: связность при обоих положениях затворов, первый осколок у врат, дальние в разных комнатах.
/datum/unit_test/heretic_mansus_generated_layouts/Run()
	for(var/attempt in 1 to 40)
		var/datum/heretic_mansus_plan/plan = new
		plan.generate(attempt % 2 ? 4 : 0)
		TEST_ASSERT_EQUAL(length(plan.rows), 33, "Раскладка из 33 строк.")
		var/datum/heretic_mansus_plan/parsed = new
		parsed.parse(plan.rows)
		TEST_ASSERT_EQUAL(parsed.gate_cell, plan.gate_cell, "Разбор находит врата.")
		TEST_ASSERT_EQUAL(parsed.entry_cell, plan.entry_cell, "Разбор находит вход.")
		TEST_ASSERT_EQUAL(jointext(parsed.shard_cells, ","), jointext(plan.shard_cells, ","), "Разбор находит осколки.")
		TEST_ASSERT_EQUAL(length(parsed.doors), length(plan.doors), "Разбор находит все проёмы.")
		TEST_ASSERT(plan.cell_row(plan.gate_cell) < plan.cell_row(plan.entry_cell), "Врата севернее входа.")
		TEST_ASSERT(plan.shard_cells[1] in plan.cell_neighbors(plan.gate_cell), "Первый осколок в комнате рядом с вратами.")
		TEST_ASSERT_EQUAL(plan.doors[plan.door_key(plan.gate_cell, plan.shard_cells[1])], "open", "К первому осколку ведёт постоянный проём.")
		TEST_ASSERT_EQUAL(length(uniqueList(plan.shard_cells)), 3, "Осколки в разных комнатах.")
		for(var/cell in plan.shard_cells)
			TEST_ASSERT(cell != plan.gate_cell && cell != plan.entry_cell, "Осколки не лежат у врат и входа.")
		for(var/phase in list("a", "b"))
			var/list/reachable = mansus_rows_reachable(plan.rows, phase)
			for(var/target in list("G", "D", "E", "1", "2", "3"))
				TEST_ASSERT(reachable[target], "Раскладка [attempt], затвор [phase]: цель [target] доступна.")

/// Каждая заготовка во всех поворотах держит проёмы открытыми и пол связным; ледяные разрешимы.
/datum/unit_test/heretic_mansus_templates/Run()
	var/datum/heretic_mansus_plan/plan = new
	for(var/list/template as anything in GLOB.heretic_mansus_templates + GLOB.heretic_mansus_ice_templates)
		for(var/list/variant as anything in mansus_variants(plan, template))
			TEST_ASSERT(mansus_template_valid(variant), "Заготовка [jointext(variant, "|")] связна и открыта у проёмов.")
	for(var/list/template as anything in GLOB.heretic_mansus_ice_templates)
		for(var/list/variant as anything in mansus_variants(plan, template))
			TEST_ASSERT(mansus_ice_solvable(variant), "Лёд [jointext(variant, "|")] проходим из любого проёма.")

/// Указатели проводят связанную жертву по полу через все этапы и завершают испытание на печати.
/datum/unit_test/heretic_mansus_guided_walk/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	var/list/memories = visit.memories.Copy()
	var/obj/effect/heretic_mansus_offering/offering = visit.offering
	var/count = 0
	for(var/obj/effect/heretic_mansus_memory/memory as anything in memories)
		TEST_ASSERT(walk_mansus_route(visit, get_turf(memory)), "Маршрут ведёт к осколку по проходимым клеткам.")
		TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Связанная жертва собирает осколок без клика рукой.")
		TEST_ASSERT(walk_mansus_route(visit, get_turf(offering)), "После подбора маршрут ведёт к печати.")
		count++
		if(count < length(memories))
			TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), count), "Наступание на печать закрепляет осколок.")
		else
			TEST_ASSERT(wait_for_qdeleted(visit), "Третий осколок возвращает жертву без ожидания таймера.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Пешеходное прохождение возвращает жертву на станцию.")
	TEST_ASSERT_NOTNULL(victim.handcuffed, "Испытание не уничтожает наручники.")

/datum/unit_test/proc/walk_mansus_route(datum/heretic_mansus_visit/visit, turf/destination)
	for(var/index in 1 to length(visit.walkable_turfs))
		var/turf/current = get_turf(visit.victim)
		if(current == destination)
			return TRUE
		var/turf/next = visit.route_steps[current]
		if(!next || !visit.victim.Move(next, get_dir(current, next)))
			return FALSE
	return FALSE

/// Во всех оформлениях цели не прячутся под вратами, а граница защиты совпадает с механикой.
/datum/unit_test/heretic_mansus_visible_objectives/Run()
	var/icon/gate_icon = icon('modular_bluemoon/icons/obj/heretic_mansus_gates.dmi', "ash_gate_closed")
	for(var/path_id in GLOB.heretic_paths)
		var/list/fixture = make_mansus_fixture(path_id = path_id, random_layout = TRUE)
		var/datum/heretic_mansus_visit/visit = fixture["visit"]
		var/gate_left = visit.gate.x * world.icon_size + visit.gate.pixel_x
		var/gate_bottom = visit.gate.y * world.icon_size + visit.gate.pixel_y
		var/list/objectives = visit.memories + visit.offering
		for(var/atom/target as anything in objectives)
			var/target_left = target.x * world.icon_size
			var/target_bottom = target.y * world.icon_size
			TEST_ASSERT(target_left + world.icon_size <= gate_left || target_left >= gate_left + gate_icon.Width() || target_bottom + world.icon_size <= gate_bottom || target_bottom >= gate_bottom + gate_icon.Height(), "Врата не скрывают цель в оформлении [path_id].")
		for(var/turf/floor as anything in visit.walkable_turfs)
			TEST_ASSERT_EQUAL(!!(locate(/obj/effect/heretic_mansus_sanctuary) in floor), !!visit.is_safe(floor), "Видимая граница защиты совпадает с механикой.")
		visit.finish()

/// До первой доставки нет угроз; печать защищает от попаданий и появления разломов.
/datum/unit_test/heretic_mansus_tutorial_and_offering/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	visit.danger_enabled = TRUE
	visit.process(1)
	TEST_ASSERT_EQUAL(length(visit.hunters), 0, "Первый этап не запускает преследователя.")
	TEST_ASSERT_EQUAL(length(visit.hazards), 0, "Первый этап не создаёт разломы.")
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Первый осколок можно собрать.")
	victim.forceMove(get_turf(visit.offering))
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), 1), "Печать завершает вводный этап.")
	TEST_ASSERT_EQUAL(length(visit.hunters), 1, "После первой доставки появляется тень.")
	var/obj/effect/heretic_mansus_hunter/hunter = visit.hunters[1]
	TEST_ASSERT_NOTNULL(hunter.step_timer, "Преследование получает собственный таймер шагов.")
	visit.spawn_hazards()
	TEST_ASSERT_EQUAL(length(visit.hazards), 0, "Разломы не перекрывают площадку сдачи.")
	TEST_ASSERT(!visit.suffer_hazard(victim), "Печать защищает жертву.")

/// Разлом предупреждает до удара, выбивает только несомый осколок и оставляет время отойти.
/datum/unit_test/heretic_mansus_hazard_progress/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_memory/first = visit.memories[1]
	var/obj/effect/heretic_mansus_memory/second = visit.memories[2]
	victim.forceMove(get_turf(first))
	TEST_ASSERT(wait_for_var(first, NAMEOF(first, recalled), TRUE), "Первый осколок подобран.")
	victim.forceMove(get_turf(visit.gate))
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), 1), "Первый осколок закреплён.")
	victim.forceMove(get_turf(second))
	TEST_ASSERT(wait_for_var(second, NAMEOF(second, recalled), TRUE), "Второй осколок переносится.")
	var/forced_exit = visit.forced_exit
	visit.spawn_hazards()
	var/obj/effect/heretic_mansus_hazard/hazard = locate() in get_turf(victim)
	TEST_ASSERT_NOTNULL(hazard, "Разлом отмечает клетку жертвы.")
	TEST_ASSERT(hazard.armed_at >= world.time + 2 SECONDS, "На уход даётся две секунды предупреждения.")
	hazard.Crossed(victim)
	TEST_ASSERT_EQUAL(visit.carried_memory, second, "Предупреждение ещё не выбивает осколок.")
	hazard.armed_at = world.time
	visit.danger_enabled = TRUE
	visit.next_hazard_at = visit.forced_exit
	visit.process(1)
	TEST_ASSERT(hazard.armed, "Разлом включается после предупреждения.")
	TEST_ASSERT_NULL(visit.carried_memory, "Попадание выбивает несомый осколок.")
	TEST_ASSERT(second.awake && !second.recalled, "Потерянный осколок снова доступен на исходном месте.")
	TEST_ASSERT(first.delivered && visit.memories_found == 1, "Закреплённый прогресс сохраняется.")
	TEST_ASSERT_EQUAL(visit.forced_exit, forced_exit, "Ошибки не продлевают предельное время.")
	TEST_ASSERT(!visit.suffer_hazard(victim), "Повторное попадание сразу после первого блокируется.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Испытание не наносит физического урона.")
	hazard.expires_at = world.time
	visit.process(1)
	TEST_ASSERT(QDELETED(hazard), "Истёкший разлом удаляется.")

/// Врата дают безопасное место для доставки и не покрываются разломами.
/datum/unit_test/heretic_mansus_gate_safety/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.forceMove(get_turf(visit.gate))
	visit.spawn_hazards()
	TEST_ASSERT_EQUAL(length(visit.hazards), 0, "Разломы не закрывают врата и соседние клетки.")
	TEST_ASSERT(!visit.suffer_hazard(victim), "У врат жертва защищена.")

/// Тень обходит стены, доходит до жертвы по шагам, а выход удаляет все угрозы.
/datum/unit_test/heretic_mansus_hunter_route/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	TEST_ASSERT(get_dist(hunter, victim) >= 6, "Тень появляется вдали от жертвы.")
	TEST_ASSERT(hunter.ready_at >= world.time + 3 SECONDS, "Появление тени оставляет время отойти.")
	for(var/step in 1 to 100)
		if(get_turf(hunter) == get_turf(victim))
			break
		var/turf/previous = get_turf(hunter)
		visit.move_hunter(hunter, get_turf(victim))
		TEST_ASSERT(visit.walkable_turfs[get_turf(hunter)], "Тень остаётся на проходимых клетках.")
		TEST_ASSERT_EQUAL(get_dist(previous, hunter), 1, "Тень продвигается на одну клетку без телепортации.")
	TEST_ASSERT_EQUAL(get_turf(hunter), get_turf(victim), "Тень находит путь до жертвы.")
	visit.spawn_hazards()
	var/list/hazards = visit.hazards.Copy()
	START_PROCESSING(SSprocessing, visit)
	visit.finish()
	TEST_ASSERT(!(visit in SSprocessing.processing), "Посещение снято с обработки.")
	TEST_ASSERT(QDELETED(hunter), "Преследователь удалён.")
	for(var/obj/effect/heretic_mansus_hazard/hazard as anything in hazards)
		TEST_ASSERT(QDELETED(hazard), "Разлом удалён.")

/obj/effect/heretic_mansus_hunter/movement_fixture
	var/moves = 0
	var/previous_step_at
	var/shortest_interval = INFINITY
	var/longest_step = 0
	var/expected_glide_size

/obj/effect/heretic_mansus_hunter/movement_fixture/Move(atom/destination, direction, glide_size_override)
	var/turf/origin = get_turf(src)
	var/step_glide_size = DELAY_TO_GLIDE_SIZE(0.5 SECONDS)
	. = ..()
	if(!.)
		return
	expected_glide_size = step_glide_size
	moves++
	longest_step = max(longest_step, get_dist(origin, src))
	if(!isnull(previous_step_at))
		shortest_interval = min(shortest_interval, world.time - previous_step_at)
	previous_step_at = world.time

/// Ускоренная тень делает отдельные соседние шаги с паузой и удаляет таймер при выходе.
/datum/unit_test/heretic_mansus_hunter_smooth_steps/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[3]
	victim.forceMove(get_turf(memory))
	visit.memories_found = 2
	visit.danger_enabled = TRUE
	visit.next_hazard_at = visit.forced_exit
	var/obj/effect/heretic_mansus_hunter/movement_fixture/hunter = new(visit.entry_turf, visit)
	visit.hunters += hunter
	visit.scenery += hunter
	hunter.ready_at = world.time
	hunter.last_seen_turf = get_turf(victim)
	visit.advance_hunter(hunter)
	TEST_ASSERT_EQUAL(hunter.moves, 1, "Ускорение не выполняет два шага в одном вызове.")
	visit.process(1)
	TEST_ASSERT_EQUAL(hunter.moves, 1, "Обработка разломов не добавляет тени шагов.")
	TEST_ASSERT(wait_for_var(hunter, NAMEOF(hunter, moves), 3), "Таймер продолжает равномерное преследование.")
	TEST_ASSERT(hunter.shortest_interval >= 0.5 SECONDS, "Соседние шаги разделены половиной секунды.")
	TEST_ASSERT_EQUAL(hunter.longest_step, 1, "Каждый шаг переносит тень только на соседнюю клетку.")
	TEST_ASSERT_EQUAL(hunter.animate_movement, SLIDE_STEPS, "Шаги используют плавное движение BYOND.")
	TEST_ASSERT(hunter.appearance_flags & LONG_GLIDE, "Запоздавшая анимация не обрывается на середине клетки.")
	TEST_ASSERT_EQUAL(hunter.glide_size, hunter.expected_glide_size, "Скорость анимации соответствует ускоренному темпу на момент шага.")
	victim.forceMove(get_turf(hunter))
	TEST_ASSERT_EQUAL(visit.hits_taken, 1, "Тень опасна и между шагами, пока её спрайт скользит по клетке.")
	visit.finish()
	TEST_ASSERT_NULL(hunter.step_timer, "Выход отменяет отдельный таймер преследования.")

/// Каждый путь получает полный набор спрайтов и звуков Мансуса и собственное правило.
/datum/unit_test/heretic_mansus_theme_resources/Run()
	var/list/detail_states = icon_states('modular_bluemoon/icons/obj/heretic_mansus.dmi')
	var/list/gate_states = icon_states('modular_bluemoon/icons/obj/heretic_mansus_gates.dmi')
	var/list/theme_ids = list()
	var/list/rule_types = list()
	for(var/path_id in GLOB.heretic_paths)
		var/list/theme = GLOB.heretic_mansus_themes[path_id]
		TEST_ASSERT_NOTNULL(theme, "У пути [path_id] есть оформление Мансуса.")
		var/theme_id = theme["id"]
		TEST_ASSERT(!(theme_id in theme_ids), "Пути используют собственные наборы: [path_id].")
		theme_ids += theme_id
		TEST_ASSERT(ispath(theme["rule"], /datum/heretic_mansus_rule) && theme["rule"] != /datum/heretic_mansus_rule, "У пути [path_id] своё правило Дома.")
		TEST_ASSERT(!(theme["rule"] in rule_types), "Правило пути [path_id] не повторяется.")
		rule_types += theme["rule"]
		var/datum/heretic_mansus_rule/rule_type = theme["rule"]
		TEST_ASSERT(length(initial(rule_type.hint)), "Правило пути [path_id] объяснено жертве.")
		for(var/role in list("floor0", "floor1", "floor2", "path", "decor", "light", "memory", "hunter", "warning", "danger"))
			TEST_ASSERT("[theme_id]_[role]" in detail_states, "Состояние [theme_id]_[role] доступно клиенту.")
		for(var/mask in 0 to 15)
			TEST_ASSERT("[theme_id]_wall[mask]" in detail_states, "Край стены [theme_id]/[mask] существует.")
			TEST_ASSERT("[theme_id]_abyss[mask]" in detail_states, "Край провала [theme_id]/[mask] существует.")
		for(var/state in list("gate_closed", "gate_open"))
			TEST_ASSERT("[theme_id]_[state]" in gate_states, "Врата [theme_id]/[state] существуют.")
		for(var/event in list("ambience", "pickup", "deposit", "warning", "hit", "escape", "step"))
			TEST_ASSERT(isfile(theme[event]), "Звук [theme_id]/[event] включён в ресурсы.")
	var/list/rule_states = icon_states('modular_bluemoon/icons/obj/heretic_mansus_rules.dmi')
	for(var/state in list("ash_ember", "rust_plate", "rust_plate_broken", "flesh_sphincter", "flesh_sphincter_closed", "void_ice", "blade_strip", "blade_strike", "cosmic_portal", "lock_key", "lock_door", "sand_hourglass", "sand_hourglass_spent", "spirit_cage", "spirit_cage_open", "spirit_soul", "blood_step"))
		TEST_ASSERT(state in rule_states, "Спрайт правила [state] существует.")
	var/list/guidance_states = icon_states('modular_bluemoon/icons/obj/heretic_mansus_guidance.dmi')
	for(var/state in list("trail", "sanctuary", "niche", "name"))
		TEST_ASSERT(state in guidance_states, "Указатель [state] существует.")

/// Одновременные комнаты сохраняют оформление своего ритуала при общей области.
/datum/unit_test/heretic_mansus_theme_isolation/Run()
	var/list/ash_fixture = make_mansus_fixture(path_id = PATH_ASH)
	var/list/glass_fixture = make_mansus_fixture(path_id = PATH_GLASS)
	var/datum/heretic_mansus_visit/ash_visit = ash_fixture["visit"]
	var/datum/heretic_mansus_visit/glass_visit = glass_fixture["visit"]
	TEST_ASSERT_EQUAL(ash_visit.room, glass_visit.room, "Проверяются посещения с общей областью.")
	TEST_ASSERT_EQUAL(ash_visit.gate.icon_state, "ash_gate_closed", "Пепельные врата сохраняют собственное оформление.")
	TEST_ASSERT_EQUAL(glass_visit.gate.icon_state, "glass_gate_closed", "Врата второй жертвы используют Стекло.")
	for(var/atom/decoration as anything in glass_visit.scenery)
		TEST_ASSERT(findtext(decoration.icon_state, "glass_") == 1 || decoration.icon == 'modular_bluemoon/icons/obj/heretic_mansus_guidance.dmi', "Комната использует оформление Стекла и общие указатели испытания.")
	for(var/turf/tile as anything in glass_visit.reservation.reserved_turfs)
		TEST_ASSERT(findtext(tile.icon_state, "glass_") == 1, "Пол, стены и провал принадлежат выбранному пути.")
	var/mob/living/carbon/human/victim = glass_fixture["victim"]
	victim.forceMove(mansus_tile(glass_visit, 4, 13))
	glass_visit.spawn_hazards()
	var/obj/effect/heretic_mansus_hazard/hazard = locate() in get_turf(victim)
	TEST_ASSERT_EQUAL(hazard.icon_state, "glass_warning", "Разлом предупреждает в стиле Стекла.")
	glass_visit.danger_enabled = TRUE
	glass_visit.next_hazard_at = glass_visit.forced_exit
	hazard.armed_at = world.time
	glass_visit.process(1)
	TEST_ASSERT_EQUAL(hazard.icon_state, "glass_danger", "Срабатывание переключает видимую фазу разлома.")
	var/atom/movable/screen/alert/heretic_mansus/indicator = victim.alerts["heretic_mansus"]
	TEST_ASSERT_EQUAL(indicator.icon_state, "glass_memory", "Подсказка использует тот же путь.")
	glass_visit.finish()
	TEST_ASSERT_EQUAL(ash_visit.gate.icon_state, "ash_gate_closed", "Выход второй жертвы не меняет оставшуюся комнату.")

/// Доставка меняет затворы местами; занятая клетка не закрывается.
/datum/unit_test/heretic_mansus_shutters_toggle/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/turf/shutter_a = mansus_tile(visit, 29, 17)
	var/turf/shutter_b = mansus_tile(visit, 29, 25)
	TEST_ASSERT(!shutter_a.density && visit.walkable_turfs[shutter_a], "Затвор a открыт при входе.")
	TEST_ASSERT(shutter_b.density && !visit.walkable_turfs[shutter_b], "Затвор b закрыт при входе.")
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Первый осколок подобран.")
	victim.forceMove(get_turf(visit.offering))
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), 1), "Первый осколок закреплён.")
	TEST_ASSERT(shutter_a.density && !visit.walkable_turfs[shutter_a], "Доставка закрывает затвор a.")
	TEST_ASSERT(findtext(shutter_a.icon_state, "ash_wall") == 1, "Закрытый затвор выглядит стеной пути.")
	TEST_ASSERT(!shutter_b.density && visit.walkable_turfs[shutter_b], "Доставка открывает затвор b.")
	for(var/turf/step as anything in visit.route_steps)
		TEST_ASSERT(!step.density, "Маршрут не ведёт через закрытый затвор.")
	victim.forceMove(shutter_b)
	visit.toggle_shutters()
	TEST_ASSERT(!shutter_b.density, "Затвор не смыкается на жертве.")
	TEST_ASSERT(!shutter_a.density, "Свободный затвор другой группы открывается.")

/// Второй залп трещин ложится линией по ходу жертвы.
/datum/unit_test/heretic_mansus_hazard_line/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.forceMove(mansus_tile(visit, 4, 13))
	victim.setDir(EAST)
	visit.spawn_hazards()
	TEST_ASSERT_EQUAL(length(visit.hazards), 3, "Первый залп накрывает жертву и две соседние клетки.")
	QDEL_LIST(visit.hazards)
	visit.spawn_hazards()
	TEST_ASSERT_EQUAL(length(visit.hazards), 5, "Второй залп кладёт пять трещин.")
	for(var/column in 4 to 8)
		TEST_ASSERT(locate(/obj/effect/heretic_mansus_hazard) in mansus_tile(visit, column, 13), "Линия идёт вперёд по взгляду жертвы, столбец [column].")

/// На последнем осколке выходит вторая, медленная тень; первая ускоряется.
/datum/unit_test/heretic_mansus_second_hunter/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	visit.danger_enabled = TRUE
	for(var/index in 1 to 2)
		var/obj/effect/heretic_mansus_memory/memory = visit.memories[index]
		victim.forceMove(get_turf(memory))
		TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Осколок [index] подобран.")
		victim.forceMove(get_turf(visit.offering))
		TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), index), "Осколок [index] закреплён.")
		visit.next_hazard_at = visit.forced_exit
		TEST_ASSERT_EQUAL(length(visit.hunters), index, "После доставки [index] теней: [index].")
	var/obj/effect/heretic_mansus_hunter/first = visit.hunters[1]
	var/obj/effect/heretic_mansus_hunter/second = visit.hunters[2]
	TEST_ASSERT(get_dist(first, second) >= 6, "Тени выходят с разных сторон.")
	TEST_ASSERT_EQUAL(visit.hunter_step_delay(first), 0.5 SECONDS, "Первая тень ускоряется на последнем осколке.")
	TEST_ASSERT_EQUAL(visit.hunter_step_delay(second), 1 SECONDS, "Вторая тень остаётся медленной.")
	TEST_ASSERT_NOTNULL(second.step_timer, "Вторая тень шагает по собственному таймеру.")
	TEST_ASSERT_EQUAL(visit.name_charges, 2, "Каждая доставка даёт заряд «Имени».")
	visit.finish()
	TEST_ASSERT(QDELETED(first) && QDELETED(second), "Выход удаляет обе тени.")

/// Стрелок три, с осколком в руках две.
/datum/unit_test/heretic_mansus_trail_shortens/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/lit = 0
	for(var/obj/effect/heretic_mansus_trail/marker as anything in visit.trail)
		lit += marker.alpha > 0
	TEST_ASSERT_EQUAL(lit, 3, "К осколку ведут три стрелки.")
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Осколок подобран.")
	victim.forceMove(visit.entry_turf)
	lit = 0
	for(var/obj/effect/heretic_mansus_trail/marker as anything in visit.trail)
		lit += marker.alpha > 0
	TEST_ASSERT_EQUAL(lit, 2, "С осколком в руках видно две стрелки.")
	var/atom/movable/screen/alert/heretic_mansus/indicator = victim.alerts["heretic_mansus"]
	visit.update_guidance()
	TEST_ASSERT(findtext(indicator.name, "на север"), "Значок называет сторону цели: [indicator.name].")

/// Таймаут оставляет эффект по минуте за недоставленный осколок; другие выходы его не дают.
/datum/unit_test/heretic_mansus_timeout_penalty/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	visit.memories_found = 1
	var/expected_end = world.time + 120 SECONDS
	visit.finish(exit_reason = "timeout")
	var/datum/status_effect/heretic_mansus_unreturned/penalty = victim.has_status_effect(/datum/status_effect/heretic_mansus_unreturned)
	TEST_ASSERT_NOTNULL(penalty, "Таймаут оставляет след недовозвращённой памяти.")
	TEST_ASSERT_EQUAL(penalty.duration, expected_end, "Два недоставленных осколка дают две минуты.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss() + victim.getStaminaLoss(), 0, "Эффект не наносит урона.")
	fixture = make_mansus_fixture()
	victim = fixture["victim"]
	visit = fixture["visit"]
	visit.finish()
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_mansus_unreturned), "Прерванное посещение не наказывает жертву.")
	fixture = make_mansus_fixture()
	victim = fixture["victim"]
	visit = fixture["visit"]
	visit.memories_found = 3
	visit.finish(exit_reason = "completed")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_mansus_unreturned), "Пройденное испытание не наказывает жертву.")

/// Тень видит по прямой; колонна и ниша скрывают жертву, осколок в руках выдаёт её.
/datum/unit_test/heretic_mansus_hunter_sight/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	victim.forceMove(mansus_tile(visit, 21, 10))
	hunter.forceMove(mansus_tile(visit, 23, 10))
	TEST_ASSERT(visit.hunter_sees(hunter), "Тень видит жертву на открытом месте.")
	TEST_ASSERT_EQUAL(visit.hunter_goal(hunter), get_turf(victim), "Увидев жертву, тень идёт к ней.")
	var/turf/last_seen = get_turf(victim)
	hunter.forceMove(mansus_tile(visit, 21, 14))
	TEST_ASSERT(!visit.hunter_sees(hunter), "Колонна закрывает обзор.")
	TEST_ASSERT_EQUAL(visit.hunter_goal(hunter), last_seen, "Потеряв жертву, тень идёт туда, где видела её в последний раз.")
	hunter.forceMove(last_seen)
	victim.forceMove(mansus_tile(visit, 30, 13))
	var/turf/search = visit.hunter_goal(hunter)
	TEST_ASSERT(search && search != last_seen && visit.walkable_turfs[search], "Дойдя до последней точки, тень обходит комнаты.")
	victim.forceMove(mansus_tile(visit, 19, 14))
	hunter.forceMove(mansus_tile(visit, 23, 14))
	TEST_ASSERT(!visit.hunter_sees(hunter), "Ниша прячет жертву с пустыми руками.")
	hunter.forceMove(mansus_tile(visit, 20, 14))
	TEST_ASSERT(visit.hunter_sees(hunter), "Вплотную ниша не спасает.")
	hunter.forceMove(mansus_tile(visit, 23, 14))
	visit.carried_memory = visit.memories[1]
	TEST_ASSERT(visit.hunter_sees(hunter), "С осколком в руках ниша не прячет.")
	visit.carried_memory = null

/// Тень на вспыхнувшей трещине рассыпается и возвращается нескоро; «Имя» отталкивает её за заряд.
/datum/unit_test/heretic_mansus_counterplay/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.forceMove(mansus_tile(visit, 4, 13))
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	var/turf/trap = mansus_tile(visit, 6, 13)
	hunter.forceMove(trap)
	var/obj/effect/heretic_mansus_hazard/hazard = visit.place_hazard(trap)
	hazard.armed_at = world.time
	visit.danger_enabled = TRUE
	visit.next_hazard_at = visit.forced_exit
	visit.process(1)
	TEST_ASSERT(get_turf(hunter) != trap, "Тень рассыпается на вспышке.")
	TEST_ASSERT(hunter.ready_at >= world.time + 7 SECONDS, "Рассыпавшаяся тень возвращается не сразу.")
	TEST_ASSERT_EQUAL(visit.hits_taken, 0, "Вспышка под тенью не задевает жертву.")
	TEST_ASSERT(!visit.invoke_name(victim), "Без заряда «Имя» не срабатывает.")
	visit.name_charges = 1
	hunter.forceMove(mansus_tile(visit, 7, 13))
	hunter.ready_at = world.time
	TEST_ASSERT(visit.invoke_name(victim), "Заряд «Имени» тратится.")
	TEST_ASSERT(get_dist(hunter, victim) >= 6, "«Имя» отбрасывает тень далеко.")
	TEST_ASSERT_EQUAL(visit.name_charges, 0, "Заряд израсходован.")
	TEST_ASSERT(visit.name_action?.owner == victim, "Кнопка «Имени» выдана жертве.")
	visit.finish()
	TEST_ASSERT(!(locate(/datum/action/innate/heretic_mansus_name) in victim.actions), "Кнопка снимается при выходе.")

/// Пепел: за жертвой тлеет след из пяти углей, тень их не переходит.
/datum/unit_test/heretic_mansus_rule_ash/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_ASH)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	visit.danger_enabled = TRUE
	visit.rule.on_danger()
	victim.forceMove(mansus_tile(visit, 2, 13))
	for(var/column in 3 to 8)
		victim.Move(mansus_tile(visit, column, 13), EAST)
	var/obj/effect/heretic_mansus_hazard/ember/ember = locate() in mansus_tile(visit, 7, 13)
	TEST_ASSERT_NOTNULL(ember, "Шаг оставляет уголь.")
	TEST_ASSERT(ember.armed_at >= world.time + 2 SECONDS, "Уголь вспыхивает не сразу.")
	TEST_ASSERT(!(locate(/obj/effect/heretic_mansus_hazard/ember) in mansus_tile(visit, 2, 13)), "След не длиннее пяти клеток.")
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	TEST_ASSERT(!visit.rule.hunter_can_enter(hunter, mansus_tile(visit, 7, 13)), "Тень не переходит угли.")

/// Ржавчина: плиты не рвут связность и проваливаются на время.
/datum/unit_test/heretic_mansus_rule_rust/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_RUST)
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/rust/rule = visit.rule
	TEST_ASSERT(length(rule.plates) > 10, "В Доме есть ржавые плиты.")
	var/list/keep = list(visit.entry_turf, get_turf(visit.offering))
	for(var/obj/effect/heretic_mansus_memory/memory as anything in visit.memories)
		keep += get_turf(memory)
	TEST_ASSERT(rule.connected_without(rule.plates, keep), "Провал всех плит сразу не отрезает цели.")
	var/turf/plate = rule.plates[1]
	rule.collapse(plate)
	TEST_ASSERT(!visit.walkable_turfs[plate], "Провалившаяся плита непроходима.")
	rule.restore(plate)
	TEST_ASSERT(visit.walkable_turfs[plate], "Дыра затягивается.")

/// Плоть: проходы сжимаются вместе, занятый проход не смыкается.
/datum/unit_test/heretic_mansus_rule_flesh/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_FLESH)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/flesh/rule = visit.rule
	TEST_ASSERT(length(rule.sphincters) >= 5, "Внутренние проходы дышат.")
	TEST_ASSERT(!(mansus_tile(visit, 13, 25) in rule.sphincters), "Проход у входа не сжимается.")
	var/turf/occupied = mansus_tile(visit, 9, 13)
	victim.forceMove(occupied)
	rule.set_closed(TRUE)
	TEST_ASSERT(!occupied.density, "Проход не смыкается на жертве.")
	var/turf/closed = mansus_tile(visit, 25, 13)
	TEST_ASSERT(closed.density && !visit.walkable_turfs[closed], "Свободный проход сжат.")
	rule.set_closed(FALSE)
	TEST_ASSERT(!closed.density && visit.walkable_turfs[closed], "Проход разжимается.")

/// Пустота: на льду жертва скользит до преграды.
/datum/unit_test/heretic_mansus_rule_void/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_VOID, random_layout = TRUE)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/void/rule = visit.rule
	TEST_ASSERT(length(visit.ice_turfs) > 60, "В Доме есть ледяные комнаты.")
	var/turf/start
	var/direction
	for(var/turf/ice as anything in visit.ice_turfs)
		for(var/candidate in GLOB.cardinals)
			var/turf/next = get_step(ice, candidate)
			if(visit.ice_turfs[next] && visit.walkable_turfs[next] && visit.walkable_turfs[get_step(next, candidate)] && !(locate(/obj/effect/heretic_mansus_memory) in next))
				start = ice
				direction = candidate
				break
		if(start)
			break
	TEST_ASSERT_NOTNULL(start, "На льду есть разбег.")
	var/turf/expected = get_step(start, direction)
	while(visit.ice_turfs[expected] && visit.walkable_turfs[get_step(expected, direction)])
		var/obj/effect/heretic_mansus_memory/memory = locate() in expected
		if(memory?.awake)
			break
		expected = get_step(expected, direction)
	victim.forceMove(start)
	victim.Move(get_step(start, direction), direction)
	TEST_ASSERT(wait_for_var(rule, NAMEOF(rule, sliding), FALSE), "Скольжение заканчивается.")
	TEST_ASSERT_EQUAL(get_turf(victim), expected, "Жертва скользит до первой преграды.")

/// Клинок: полоса предупреждает, удар сбивает жертву, тень лезвий не боится.
/datum/unit_test/heretic_mansus_rule_blade/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_BLADE)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/blade/rule = visit.rule
	TEST_ASSERT_EQUAL(length(rule.traps), 5, "Лезвия стоят в пяти проходах.")
	var/turf/trap = rule.traps[1]
	rule.warn(trap)
	var/obj/effect/heretic_mansus_hazard/blade/strip = locate() in trap
	TEST_ASSERT_NOTNULL(strip, "Сначала появляется полоса.")
	TEST_ASSERT(!strip.dispels_hunters, "Лезвия не рассеивают тень.")
	victim.forceMove(trap)
	rule.strike(strip)
	TEST_ASSERT_EQUAL(visit.hits_taken, 1, "Удар клинков сбивает жертву в проходе.")

/// Луна: у осколка два отражения без тени, отражение выдаёт жертву.
/datum/unit_test/heretic_mansus_rule_moon/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_MOON)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/moon/rule = visit.rule
	visit.danger_enabled = TRUE
	mansus_deliver_first(visit)
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[2]
	TEST_ASSERT_EQUAL(length(rule.reflections), 2, "У осколка два отражения.")
	for(var/obj/effect/heretic_mansus_device/reflection/reflection as anything in rule.reflections)
		TEST_ASSERT_EQUAL(visit.cell_of(reflection), memory.chamber, "Отражение лежит в комнате осколка.")
	TEST_ASSERT(memory.get_filter("moon_shadow"), "Настоящий осколок отбрасывает тень.")
	TEST_ASSERT(visit.route_target() != get_turf(memory), "Маршрут не выдаёт настоящий осколок.")
	var/obj/effect/heretic_mansus_device/reflection/fake = rule.reflections[1]
	var/turf/fake_turf = get_turf(fake)
	victim.forceMove(fake_turf)
	TEST_ASSERT(wait_for_qdeleted(fake), "Отражение рассыпается.")
	var/obj/effect/heretic_mansus_hunter/hunter = visit.hunters[1]
	TEST_ASSERT_EQUAL(hunter.last_seen_turf, fake_turf, "Отражение выдаёт жертву тени.")

/// Космос: врата парные и переносят к паре, маршрут их учитывает.
/datum/unit_test/heretic_mansus_rule_cosmic/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_COSMIC)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/cosmic/rule = visit.rule
	TEST_ASSERT_EQUAL(length(rule.portals), 6, "Три пары звёздных врат.")
	var/obj/effect/heretic_mansus_portal/portal = rule.portals[1]
	TEST_ASSERT(visit.cell_of(portal) != visit.cell_of(portal.partner), "Пара стоит в другой комнате.")
	TEST_ASSERT(get_turf(portal.partner) in rule.route_links(get_turf(portal)), "Маршрут знает о вратах.")
	victim.forceMove(get_turf(portal))
	TEST_ASSERT(wait_for_var(victim, NAMEOF(victim, loc), get_turf(portal.partner)), "Шаг в врата переносит к паре.")
	TEST_ASSERT_EQUAL(get_turf(victim), get_turf(portal.partner), "Жертва не прыгает обратно сразу.")

/// Замок: комната второго осколка заперта до ключа.
/datum/unit_test/heretic_mansus_rule_lock/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_LOCK)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/lock/rule = visit.rule
	TEST_ASSERT_NULL(rule.locked_cell, "Вводный осколок не заперт.")
	mansus_deliver_first(visit)
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[2]
	TEST_ASSERT_EQUAL(rule.locked_cell, memory.chamber, "Комната второго осколка заперта.")
	TEST_ASSERT_EQUAL(length(rule.doors), 2, "Заперты все проёмы комнаты, включая затвор.")
	TEST_ASSERT(visit.cell_of(rule.key) != memory.chamber, "Ключ лежит в другой комнате.")
	TEST_ASSERT_EQUAL(visit.route_target(), get_turf(rule.key), "Маршрут ведёт к ключу.")
	TEST_ASSERT(!rule.try_unlock(victim), "Без ключа дверь не открыть.")
	var/obj/effect/heretic_mansus_device/key/key = rule.key
	victim.forceMove(get_turf(key))
	TEST_ASSERT(wait_for_var(rule, NAMEOF(rule, has_key), TRUE), "Ключ подбирается наступанием.")
	TEST_ASSERT(rule.try_unlock(victim), "С ключом дверь открывается.")
	TEST_ASSERT_EQUAL(length(rule.doors), 0, "Двери убраны.")
	TEST_ASSERT(memory.chamber in rule.opened_cells, "Открытая комната больше не запирается.")

/// Пучина: прилив замедляет жертву на юге и прячет трещины.
/datum/unit_test/heretic_mansus_rule_tide/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_TIDE)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/tide/rule = visit.rule
	victim.forceMove(mansus_tile(visit, 4, 29))
	rule.flood()
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_mansus_tide), "В воде жертва медленнее.")
	visit.spawn_hazards()
	var/obj/effect/heretic_mansus_hazard/hazard = locate() in get_turf(victim)
	TEST_ASSERT_EQUAL(hazard.alpha, 60, "Трещина в воде видна рябью.")
	victim.forceMove(mansus_tile(visit, 4, 5))
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_mansus_tide), "На севере сухо.")
	rule.recede()
	victim.forceMove(mansus_tile(visit, 4, 29))
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_mansus_tide), "После отлива замедления нет.")

/// Стекло: отражение идёт через центр Дома, встреча с ним - удар.
/datum/unit_test/heretic_mansus_rule_glass/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_GLASS)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/glass/rule = visit.rule
	TEST_ASSERT_EQUAL(rule.mirror_turf(mansus_tile(visit, 4, 13)), mansus_tile(visit, 30, 21), "Отражение зеркально через центр.")
	victim.forceMove(mansus_tile(visit, 4, 13))
	rule.on_danger()
	TEST_ASSERT_EQUAL(get_turf(rule.reflection), mansus_tile(visit, 30, 21), "Отражение появляется напротив.")
	victim.Move(mansus_tile(visit, 5, 13), EAST)
	TEST_ASSERT_EQUAL(get_turf(rule.reflection), mansus_tile(visit, 29, 21), "Отражение повторяет шаг зеркально.")
	rule.reflection.forceMove(get_turf(victim))
	rule.check_meeting()
	TEST_ASSERT_EQUAL(visit.hits_taken, 1, "Встреча с отражением сбивает жертву.")

/// Кровь: тень идёт по следам по порядку и быстрее.
/datum/unit_test/heretic_mansus_rule_blood/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_BLOOD)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/blood/rule = visit.rule
	rule.on_danger()
	victim.forceMove(mansus_tile(visit, 2, 13))
	for(var/column in 3 to 5)
		victim.Move(mansus_tile(visit, column, 13), EAST)
	TEST_ASSERT_EQUAL(length(rule.steps), 3, "Каждый шаг оставляет след.")
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	hunter.forceMove(mansus_tile(visit, 2, 20))
	TEST_ASSERT_EQUAL(visit.hunter_goal(hunter), mansus_tile(visit, 2, 13), "Тень начинает с самого старого следа.")
	hunter.forceMove(mansus_tile(visit, 2, 13))
	TEST_ASSERT_EQUAL(visit.hunter_goal(hunter), mansus_tile(visit, 3, 13), "Тень идёт по следам по порядку.")
	TEST_ASSERT(visit.hunter_step_delay(hunter) < 1 SECONDS, "По следу тень идёт быстрее.")
	rule.on_hit()
	TEST_ASSERT_EQUAL(length(rule.steps), 0, "Удар стирает след.")

/// Эхо: тень слепа и слышит бег издалека, шаг только рядом.
/datum/unit_test/heretic_mansus_rule_echo/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_ECHO)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	victim.forceMove(mansus_tile(visit, 3, 13))
	hunter.forceMove(mansus_tile(visit, 8, 13))
	TEST_ASSERT(!visit.hunter_sees(hunter), "Тень слепа даже на открытом месте.")
	victim.m_intent = MOVE_INTENT_WALK
	victim.Move(mansus_tile(visit, 4, 13), EAST)
	TEST_ASSERT_NULL(hunter.last_seen_turf, "Шаг не слышен издалека.")
	victim.m_intent = MOVE_INTENT_RUN
	victim.Move(mansus_tile(visit, 3, 13), WEST)
	TEST_ASSERT_EQUAL(hunter.last_seen_turf, mansus_tile(visit, 3, 13), "Бег слышен.")

/// Песок: часы замораживают тени и забирают время; без теней не срабатывают.
/datum/unit_test/heretic_mansus_rule_sand/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_SAND)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_device/hourglass/hourglass
	for(var/obj/effect/heretic_mansus_device/hourglass/candidate in visit.scenery)
		hourglass = candidate
		break
	TEST_ASSERT_NOTNULL(hourglass, "В Доме есть песочные часы.")
	victim.forceMove(get_turf(hourglass))
	TEST_ASSERT(!hourglass.try_use(victim) && !hourglass.used, "Без теней часы не переворачиваются.")
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	var/forced_exit = visit.forced_exit
	hourglass.attack_hand(victim)
	TEST_ASSERT(wait_for_var(hourglass, NAMEOF(hourglass, used), TRUE), "Часы переворачиваются стоя на них.")
	TEST_ASSERT(hunter.ready_at >= world.time + 5 SECONDS, "Тень замирает.")
	TEST_ASSERT_EQUAL(visit.forced_exit, forced_exit - 10 SECONDS, "Дом забирает десять секунд.")

/// Воск: свет тает со временем, свеча под ногами возвращает его.
/datum/unit_test/heretic_mansus_rule_wax/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_WAX)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/wax/rule = visit.rule
	rule.on_danger()
	rule.melt()
	TEST_ASSERT_EQUAL(rule.darkness, 1, "Свет тает.")
	TEST_ASSERT(victim.fullscreens["heretic_mansus_wax"], "Обзор затемнён.")
	var/obj/effect/heretic_mansus_candle/candle = locate() in mansus_tile(visit, 11, 7)
	TEST_ASSERT_NOTNULL(candle, "У врат стоит свеча.")
	victim.forceMove(mansus_tile(visit, 11, 8))
	victim.Move(get_turf(candle), NORTH)
	TEST_ASSERT_EQUAL(rule.darkness, 0, "Свеча разжигает свет.")
	rule.melt()
	TEST_ASSERT_EQUAL(rule.darkness, 0, "Разожжённый свет какое-то время держится.")

/// Дух: открытая клетка уводит тени за душой.
/datum/unit_test/heretic_mansus_rule_spirit/Run()
	var/list/fixture = make_mansus_fixture(path_id = PATH_SPIRIT)
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/datum/heretic_mansus_rule/spirit/rule = visit.rule
	var/obj/effect/heretic_mansus_device/cage/cage
	for(var/obj/effect/heretic_mansus_device/cage/candidate in visit.scenery)
		cage = candidate
		break
	TEST_ASSERT_NOTNULL(cage, "В Доме есть клетки с душами.")
	var/obj/effect/heretic_mansus_hunter/hunter = visit.spawn_hunter()
	victim.forceMove(get_turf(cage))
	TEST_ASSERT(wait_for_var(cage, NAMEOF(cage, used), TRUE), "Клетка открывается.")
	TEST_ASSERT_NOTNULL(rule.decoy, "Душа вылетает.")
	hunter.forceMove(get_turf(rule.decoy))
	TEST_ASSERT_EQUAL(visit.hunter_goal(hunter), get_turf(rule.decoy), "Тень гонится за душой.")

/// Клетка фикстурной раскладки: столбец и строка от 1 до 33, строки с севера.
/datum/unit_test/proc/mansus_tile(datum/heretic_mansus_visit/visit, column, row)
	return visit.local_turf(column, row)

/datum/unit_test/proc/mansus_reachable(datum/heretic_mansus_visit/visit)
	var/list/reachable = list(visit.entry_turf)
	var/next_turf = 1
	while(next_turf <= length(reachable))
		var/turf/current = reachable[next_turf++]
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current, direction)
			if(visit.walkable_turfs[neighbor] && !(neighbor in reachable))
				reachable += neighbor
	return reachable

/datum/unit_test/proc/mansus_deliver_first(datum/heretic_mansus_visit/visit)
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	visit.victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Первый осколок подобран.")
	visit.victim.forceMove(get_turf(visit.offering))
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), 1), "Первый осколок закреплён.")

/// Цели, достижимые по символам раскладки, при открытом затворе `open_shutter`.
/datum/unit_test/proc/mansus_rows_reachable(list/rows, open_shutter)
	var/list/found = list()
	var/list/seen = list()
	var/list/frontier = list()
	for(var/row in 1 to length(rows))
		var/column = findtext(rows[row], "E")
		if(column)
			frontier += list(list(column, row))
			seen["[column],[row]"] = TRUE
	var/index = 1
	while(index <= length(frontier))
		var/list/current = frontier[index++]
		var/tile = copytext(rows[current[2]], current[1], current[1] + 1)
		found[tile] = TRUE
		for(var/list/offset in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
			var/column = current[1] + offset[1]
			var/row = current[2] + offset[2]
			if(row < 1 || row > length(rows) || column < 1 || column > length(rows[row]) || seen["[column],[row]"])
				continue
			var/next_tile = copytext(rows[row], column, column + 1)
			if(next_tile == "#" || next_tile == "O" || next_tile == "S" || ((next_tile == "a" || next_tile == "b") && next_tile != open_shutter))
				continue
			seen["[column],[row]"] = TRUE
			frontier += list(list(column, row))
	return found

/datum/unit_test/proc/mansus_variants(datum/heretic_mansus_plan/plan, list/template)
	. = list()
	var/list/current = template.Copy()
	for(var/turn in 1 to 4)
		. += list(current)
		var/list/mirrored = list()
		for(var/line in current)
			mirrored += reverse_text(line)
		. += list(mirrored)
		current = plan.rotate_template(current)

/datum/unit_test/proc/mansus_template_passable(list/template, column, row)
	if(row < 1 || row > 7 || column < 1 || column > 7)
		return FALSE
	var/tile = copytext(template[row], column, column + 1)
	return tile != "#" && tile != "O" && tile != "S"

/datum/unit_test/proc/mansus_template_valid(list/template)
	for(var/list/middle in list(list(4, 1), list(4, 7), list(1, 4), list(7, 4)))
		if(!mansus_template_passable(template, middle[1], middle[2]))
			return FALSE
	var/total = 0
	for(var/row in 1 to 7)
		for(var/column in 1 to 7)
			total += mansus_template_passable(template, column, row)
	var/list/seen = list("4,1" = TRUE)
	var/list/frontier = list(list(4, 1))
	var/index = 1
	while(index <= length(frontier))
		var/list/current = frontier[index++]
		for(var/list/offset in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
			var/column = current[1] + offset[1]
			var/row = current[2] + offset[2]
			if(!mansus_template_passable(template, column, row) || seen["[column],[row]"])
				continue
			seen["[column],[row]"] = TRUE
			frontier += list(list(column, row))
	return length(seen) == total

/// Скольжение до преграды; выход через середину края означает уход в проём.
/datum/unit_test/proc/mansus_slide(list/template, column, row, list/offset, stop_on_shard)
	while(TRUE)
		var/tile = copytext(template[row], column, column + 1)
		if(tile != "i" && tile != "*")
			return list(column, row)
		if(stop_on_shard && tile == "*")
			return list(column, row)
		var/exit = mansus_ice_exit(column, row, offset)
		if(exit)
			return exit
		if(!mansus_template_passable(template, column + offset[1], row + offset[2]))
			return list(column, row)
		column += offset[1]
		row += offset[2]

/datum/unit_test/proc/mansus_ice_exit(column, row, list/offset)
	if(column == 4 && row == 1 && offset[2] == -1)
		return "north"
	if(column == 4 && row == 7 && offset[2] == 1)
		return "south"
	if(column == 1 && row == 4 && offset[1] == -1)
		return "west"
	if(column == 7 && row == 4 && offset[1] == 1)
		return "east"
	return null

/datum/unit_test/proc/mansus_ice_solvable(list/template)
	var/list/entries = list("north" = list(4, 1, 0, 1), "south" = list(4, 7, 0, -1), "west" = list(1, 4, 1, 0), "east" = list(7, 4, -1, 0))
	var/list/shard
	for(var/row in 1 to 7)
		var/column = findtext(template[row], "*")
		if(column)
			shard = list(column, row)
	for(var/entry in entries)
		var/list/start = entries[entry]
		var/list/result = mansus_ice_explore(template, mansus_slide(template, start[1], start[2], list(start[3], start[4]), TRUE), TRUE)
		for(var/exit in entries)
			if(!result["exits"][exit])
				return FALSE
		if(shard && !result["seen"]["[shard[1]],[shard[2]]"])
			return FALSE
	if(shard)
		var/list/result = mansus_ice_explore(template, shard, FALSE)
		if(!length(result["exits"]))
			return FALSE
	return TRUE

/datum/unit_test/proc/mansus_ice_explore(list/template, first, stop_on_shard)
	var/list/exits = list()
	var/list/seen = list()
	var/list/frontier = list()
	if(istext(first))
		exits[first] = TRUE
	else
		seen["[first[1]],[first[2]]"] = TRUE
		frontier += list(first)
	var/index = 1
	while(index <= length(frontier))
		var/list/current = frontier[index++]
		for(var/list/offset in list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1)))
			var/exit = mansus_ice_exit(current[1], current[2], offset)
			if(exit)
				exits[exit] = TRUE
				continue
			if(!mansus_template_passable(template, current[1] + offset[1], current[2] + offset[2]))
				continue
			var/stop = mansus_slide(template, current[1] + offset[1], current[2] + offset[2], offset, stop_on_shard)
			if(istext(stop))
				exits[stop] = TRUE
				continue
			if(seen["[stop[1]],[stop[2]]"])
				continue
			seen["[stop[1]],[stop[2]]"] = TRUE
			frontier += list(stop)
	return list("exits" = exits, "seen" = seen)
