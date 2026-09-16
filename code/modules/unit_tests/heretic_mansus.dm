/// Прямые фикстуры не зависят от присутствия настоящей станции в профиле запуска.
/datum/heretic_mansus_visit/mansus_fixture
	recall_duration = 0.3 SECONDS
	delivery_duration = 0.3 SECONDS
	danger_enabled = FALSE

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

/datum/unit_test/proc/make_mansus_fixture(visit_type = /datum/heretic_mansus_visit/mansus_fixture, previous_memory, path_id = PATH_ASH)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	soul.memory = previous_memory
	var/datum/heretic_mansus_visit/visit = allocate(visit_type)
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
	TEST_ASSERT(findtext(soul.memory, "По воспоминаниям о похищении вы не можете опознать"), "При входе в заметках уже есть ограничение на опознание похитителя.")
	TEST_ASSERT(findtext(soul.memory, previous_memory), "Вход сохраняет прежние записи.")
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

/// Декор и провал оставляют связный маршрут ко всем воспоминаниям и вратам.
/datum/unit_test/heretic_mansus_layout/Run()
	var/list/fixture = make_mansus_fixture()
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/list/reachable = list(visit.entry_turf)
	var/next_turf = 1
	while(next_turf <= length(reachable))
		var/turf/current = reachable[next_turf++]
		for(var/direction in GLOB.cardinals)
			var/turf/neighbor = get_step(current, direction)
			if(!visit.contains(neighbor) || neighbor.density || (neighbor in reachable))
				continue
			var/blocked = FALSE
			for(var/atom/movable/obstacle in neighbor)
				if(obstacle.density)
					blocked = TRUE
					break
			if(!blocked)
				reachable += neighbor
	for(var/obj/effect/heretic_mansus_memory/memory as anything in visit.memories)
		TEST_ASSERT(get_turf(memory) in reachable, "Каждое воспоминание доступно пешком из прихожей.")
	TEST_ASSERT(get_turf(visit.gate) in reachable, "Врата доступны пешком из прихожей.")
	TEST_ASSERT(visit.gate.y > visit.entry_turf.y, "Врата находятся к северу от прихожей, как сказано в подсказке.")
	var/list/chambers = list(0, 0, 0)
	var/previous_chamber = 0
	var/list/positions = list()
	for(var/obj/effect/heretic_mansus_memory/memory as anything in visit.memories)
		TEST_ASSERT(memory.chamber != previous_chamber, "Два последовательных задания не ведут в одну комнату.")
		TEST_ASSERT(!(get_turf(memory) in positions), "Осколки занимают разные клетки.")
		positions += get_turf(memory)
		chambers[memory.chamber]++
		previous_chamber = memory.chamber
	TEST_ASSERT_EQUAL(chambers[1], 1, "Западная комната участвует один раз.")
	TEST_ASSERT_EQUAL(chambers[2], 1, "Восточная комната участвует один раз.")
	TEST_ASSERT_EQUAL(chambers[3], 1, "Северная комната участвует один раз.")
	var/abyss_tiles = 0
	for(var/turf/closed/indestructible/heretic_mansus/abyss/abyss in visit.reservation.reserved_turfs)
		abyss_tiles++
		TEST_ASSERT(!(abyss in reachable), "В провал нельзя войти.")
	TEST_ASSERT_EQUAL(abyss_tiles, 9, "Внутренний двор содержит провал 3 на 3.")
	TEST_ASSERT(length(visit.scenery) > 20, "Комнаты содержат постоянный декор.")

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
		TEST_ASSERT(walk_mansus_route(visit, get_turf(memory)), "Стрелки ведут к осколку по проходимым клеткам.")
		TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Связанная жертва собирает осколок без клика рукой.")
		TEST_ASSERT(walk_mansus_route(visit, get_turf(offering)), "После подбора стрелки ведут к открытой площадке сдачи.")
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

/// Во всех оформлениях осколки и площадка сдачи лежат вне прямоугольника спрайта врат.
/datum/unit_test/heretic_mansus_visible_objectives/Run()
	var/icon/gate_icon = icon('modular_bluemoon/icons/obj/heretic_mansus_gates.dmi', "ash_gate_closed")
	for(var/path_id in GLOB.heretic_paths)
		var/list/fixture = make_mansus_fixture(path_id = path_id)
		var/datum/heretic_mansus_visit/visit = fixture["visit"]
		var/gate_left = visit.gate.x * world.icon_size + visit.gate.pixel_x
		var/gate_bottom = visit.gate.y * world.icon_size + visit.gate.pixel_y
		var/list/objectives = visit.memories + visit.offering
		for(var/atom/target as anything in objectives)
			var/target_left = target.x * world.icon_size
			var/target_bottom = target.y * world.icon_size
			TEST_ASSERT(target_left + world.icon_size <= gate_left || target_left >= gate_left + gate_icon.Width() || target_bottom + world.icon_size <= gate_bottom || target_bottom >= gate_bottom + gate_icon.Height(), "Врата не скрывают цель в оформлении [path_id].")
		var/obj/effect/heretic_mansus_memory/first = visit.memories[1]
		TEST_ASSERT_EQUAL(first.chamber, 3, "Вводный этап знакомит с северными вратами.")
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
	TEST_ASSERT_NULL(visit.hunter, "Первый этап не запускает преследователя.")
	TEST_ASSERT_EQUAL(length(visit.hazards), 0, "Первый этап не создаёт разломы.")
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	TEST_ASSERT(wait_for_var(memory, NAMEOF(memory, recalled), TRUE), "Первый осколок можно собрать.")
	victim.forceMove(get_turf(visit.offering))
	TEST_ASSERT(wait_for_var(visit, NAMEOF(visit, memories_found), 1), "Печать завершает вводный этап.")
	TEST_ASSERT_NOTNULL(visit.hunter, "После первой доставки появляется тень.")
	TEST_ASSERT_NOTNULL(visit.hunter_timer, "Преследование получает собственный таймер шагов.")
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

/// Северные врата дают безопасное место для доставки и не покрываются разломами.
/datum/unit_test/heretic_mansus_gate_safety/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.forceMove(get_turf(visit.gate))
	visit.spawn_hazards()
	TEST_ASSERT_EQUAL(length(visit.hazards), 0, "Разломы не закрывают врата и соседние клетки.")
	TEST_ASSERT(!visit.suffer_hazard(victim), "У врат жертва защищена.")

/// Тень обходит стены и провал, а завершение посещения удаляет все угрозы.
/datum/unit_test/heretic_mansus_hunter_route/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	var/obj/effect/heretic_mansus_memory/memory = visit.memories[1]
	victim.forceMove(get_turf(memory))
	var/obj/effect/heretic_mansus_hunter/hunter = new(visit.entry_turf, visit)
	visit.hunter = hunter
	visit.scenery += hunter
	visit.reset_hunter()
	TEST_ASSERT(get_dist(hunter, victim) >= 6, "Тень появляется вдали от жертвы.")
	TEST_ASSERT(visit.hunter_ready_at >= world.time + 3 SECONDS, "Появление тени оставляет время отойти.")
	for(var/step in 1 to 100)
		if(get_turf(hunter) == get_turf(victim))
			break
		var/turf/previous = get_turf(hunter)
		visit.move_hunter()
		TEST_ASSERT(get_turf(hunter) in visit.walkable_turfs, "Тень остаётся в доступных галереях.")
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

/obj/effect/heretic_mansus_hunter/movement_fixture/Move(atom/destination, direction, glide_size_override)
	var/turf/origin = get_turf(src)
	. = ..()
	if(!.)
		return
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
	visit.hunter = hunter
	visit.scenery += hunter
	visit.hunter_ready_at = world.time
	visit.advance_hunter()
	TEST_ASSERT_EQUAL(hunter.moves, 1, "Ускорение не выполняет два шага в одном вызове.")
	visit.process(1)
	TEST_ASSERT_EQUAL(hunter.moves, 1, "Обработка разломов не добавляет тени шагов.")
	TEST_ASSERT(wait_for_var(hunter, NAMEOF(hunter, moves), 3), "Таймер продолжает равномерное преследование.")
	TEST_ASSERT(hunter.shortest_interval >= 0.5 SECONDS, "Соседние шаги разделены половиной секунды.")
	TEST_ASSERT_EQUAL(hunter.longest_step, 1, "Каждый шаг переносит тень только на соседнюю клетку.")
	TEST_ASSERT_EQUAL(hunter.animate_movement, SLIDE_STEPS, "Шаги используют плавное движение BYOND.")
	TEST_ASSERT(hunter.appearance_flags & LONG_GLIDE, "Запоздавшая анимация не обрывается на середине клетки.")
	TEST_ASSERT_EQUAL(hunter.glide_size, DELAY_TO_GLIDE_SIZE(0.5 SECONDS), "Скорость анимации соответствует ускоренному темпу.")
	victim.forceMove(get_turf(hunter))
	TEST_ASSERT_EQUAL(visit.hits_taken, 1, "Тень опасна и между шагами, пока её спрайт скользит по клетке.")
	visit.finish()
	TEST_ASSERT_NULL(visit.hunter_timer, "Выход отменяет отдельный таймер преследования.")

/// Каждый зарегистрированный путь получает полный набор доступных спрайтов и звуков Мансуса.
/datum/unit_test/heretic_mansus_theme_resources/Run()
	var/list/detail_states = icon_states('modular_bluemoon/icons/obj/heretic_mansus.dmi')
	var/list/gate_states = icon_states('modular_bluemoon/icons/obj/heretic_mansus_gates.dmi')
	var/list/theme_ids = list()
	for(var/path_id in GLOB.heretic_paths)
		var/list/theme = GLOB.heretic_mansus_themes[path_id]
		TEST_ASSERT_NOTNULL(theme, "У пути [path_id] есть оформление Мансуса.")
		var/theme_id = theme["id"]
		TEST_ASSERT(!(theme_id in theme_ids), "Пути используют собственные наборы: [path_id].")
		theme_ids += theme_id
		for(var/role in list("floor0", "floor1", "floor2", "path", "decor", "light", "memory", "hunter", "warning", "danger"))
			TEST_ASSERT("[theme_id]_[role]" in detail_states, "Состояние [theme_id]_[role] доступно клиенту.")
		for(var/mask in 0 to 15)
			TEST_ASSERT("[theme_id]_wall[mask]" in detail_states, "Край стены [theme_id]/[mask] существует.")
			TEST_ASSERT("[theme_id]_abyss[mask]" in detail_states, "Край провала [theme_id]/[mask] существует.")
		for(var/state in list("gate_closed", "gate_open"))
			TEST_ASSERT("[theme_id]_[state]" in gate_states, "Врата [theme_id]/[state] существуют.")
		for(var/event in list("ambience", "pickup", "deposit", "warning", "hit", "escape", "step"))
			TEST_ASSERT(isfile(theme[event]), "Звук [theme_id]/[event] включён в ресурсы.")

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
