/// Прямые фикстуры не зависят от присутствия настоящей станции в профиле запуска.
/datum/heretic_mansus_visit/mansus_fixture/find_return_turf()
	return return_turf

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

/datum/unit_test/proc/make_mansus_fixture(visit_type = /datum/heretic_mansus_visit/mansus_fixture)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	var/datum/heretic_mansus_visit/visit = allocate(visit_type)
	if(!visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right) || !visit.start())
		Fail("Не удалось открыть посещение Мансуса.")
	return list("victim" = victim, "soul" = soul, "visit" = visit)

/datum/unit_test/heretic_mansus_interactive_exit/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	TEST_ASSERT(visit.contains(victim), "Жертва должна свободно находиться в отдельной комнате.")
	TEST_ASSERT_EQUAL(victim.stat, CONSCIOUS, "В Мансусе жертва просыпается и может двигаться.")
	TEST_ASSERT_EQUAL(length(visit.memories), 3, "Комната содержит три доступных воспоминания.")
	var/obj/effect/heretic_mansus_gate/gate = visit.gate
	victim.forceMove(get_turf(gate))
	TEST_ASSERT(!visit.try_exit(victim), "Без воспоминаний врата ещё закрыты.")
	for(var/obj/effect/heretic_mansus_memory/memory in visit.memories)
		victim.forceMove(get_turf(memory))
		visit.collect_memory(memory, victim)
		var/previous_count = visit.memories_found
		TEST_ASSERT(!visit.collect_memory(memory, victim), "Одно воспоминание нельзя засчитать повторно.")
		TEST_ASSERT_EQUAL(visit.memories_found, previous_count, "Повторный клик не увеличивает счётчик.")
	TEST_ASSERT_EQUAL(visit.memories_found, 3, "Движение и взаимодействие позволяют собрать все воспоминания.")
	victim.forceMove(get_turf(gate))
	TEST_ASSERT(!visit.try_exit(victim), "Сбор воспоминаний не пропускает минимальную длительность эпизода.")
	visit.earliest_exit = world.time - 1
	visit.open_gate()
	TEST_ASSERT(QDELETED(visit), "Открытие врат под стоящей в них жертвой завершает посещение.")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Открытые врата возвращают на безопасный пол.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Врата убирают посещение из реестра.")
	TEST_ASSERT_NOTNULL(victim.GetComponent(/datum/component/heretic_mansus_trace), "После возвращения остаётся косметический след.")
	TEST_ASSERT(!HAS_TRAIT_FROM(victim, TRAIT_NOBREATH, REF(visit)), "Временная защита дыхания снимается при выходе.")

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
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/mind/soul = fixture["soul"]
	var/previous_memory = "До похищения я видел повреждённый шлюз в техническом тоннеле."
	soul.memory = previous_memory
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

/datum/unit_test/heretic_mansus_death/Run()
	var/list/fixture = make_mansus_fixture()
	var/mob/living/carbon/human/victim = fixture["victim"]
	var/datum/heretic_mansus_visit/visit = fixture["visit"]
	victim.death()
	TEST_ASSERT(wait_for_qdeleted(visit), "Смерть запускает аварийный возврат после завершения death().")
	TEST_ASSERT_EQUAL(get_turf(victim), run_loc_floor_top_right, "Умершая внутри жертва возвращается на станцию.")
	TEST_ASSERT(victim.stat != DEAD, "Ритуальное восстановление не перезаписывается продолжающимся death().")

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
	TEST_ASSERT(memory.recalled, "Воспоминание доступно наступившей на него жертве в наручниках.")
	visit.finish()
	TEST_ASSERT_EQUAL(victim.handcuffed, cuffs, "Возвращение также сохраняет наручники.")
	TEST_ASSERT_EQUAL(cuffs.loc, victim, "Имущество остаётся в теле владельца.")

/// Мёртвое тело не принимается ни до подготовки комнаты, ни после неё.
/datum/unit_test/heretic_mansus_rejects_dead/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/mind/soul = allocate(/datum/mind, "mansus_dead_test")
	soul.current = victim
	victim.mind = soul
	var/datum/heretic_mansus_visit/visit = allocate(/datum/heretic_mansus_visit/mansus_fixture)
	victim.death()
	TEST_ASSERT(!visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Труп не открывает посещение.")
	TEST_ASSERT_NULL(visit.reservation, "Отказ не резервирует комнату.")
	victim.revive(full_heal = TRUE)
	TEST_ASSERT(visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Живая цель позволяет подготовить комнату.")
	victim.death()
	TEST_ASSERT(!visit.start(), "Смерть после подготовки отменяет вход.")
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "Отклонённый вход не воскрешает тело.")
	TEST_ASSERT_NULL(GLOB.heretic_mansus_visits[soul], "Отклонённый вход не регистрирует душу.")

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
