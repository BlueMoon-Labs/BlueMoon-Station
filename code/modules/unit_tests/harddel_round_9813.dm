/// Регрессии по hard delete из прод-раунда 9813 (2026-07-27).
/// Все проверяемые здесь типы реально уходили в warnfail с известным числом
/// внешних держателей; в комментариях к тестам указан замер из runtime.log.

/// Общая база: даёт мягкий GC-прогон и, при провале, полный скан ссылок в harddels.log.
/datum/unit_test/harddel_9813_base
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/harddel_9813_base/Run()
	return

/// Изолирует очереди GC под тест. Счётчики по типу (qdel_item.failures) для
/// проверки НЕ годятся: с нулевыми таймаутами фоновый прогон Master успевает
/// провести softcheck по объекту, которого BYOND ещё физически не отпустил, и
/// пишет провал на живой цепочке Destroy. Глушить SSgarbage тоже нельзя - на
/// полной карте оставленный выключенным сборщик копит очередь и вешает
/// последующие тесты. Поэтому проверяем не счётчик, а конкретный экземпляр.
/datum/unit_test/harddel_9813_base/proc/begin_isolated_gc()
	configure_immediate_gc()
	SSgarbage.recent_failures = list()

/// Снимок цели до qdel: держать сам датум в переменной теста нельзя - фрейм
/// пиннит его и softcheck честно провалится на чистом объекте.
/datum/unit_test/harddel_9813_base/proc/target_record(datum/target, label)
	return list(
		"ref" = REF(target),
		"type_path" = target.type,
		"label" = label,
	)

/// Сколько внешних держателей SSgarbage насчитал у последнего провала этого типа.
/datum/unit_test/harddel_9813_base/proc/recorded_holders(type_path)
	for(var/i in length(SSgarbage.recent_failures) to 1 step -1)
		var/list/entry = SSgarbage.recent_failures[i]
		if(length(entry) >= 5 && entry[2] == "[type_path]")
			return entry[5]
	return "?"

/// Цель обязана исчезнуть из мира. `locate()` по ref BYOND переиспользует, поэтому
/// живой объект засчитывается провалом только если он ещё и в состоянии qdel -
/// свежий датум, занявший тот же ref, тестом не считается.
/datum/unit_test/harddel_9813_base/proc/assert_soft_collected(list/target)
	var/label = target["label"]
	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(target["type_path"])
	TEST_ASSERT(item.qdels > 0, "[label] не попал в qdel")
	var/datum/still_alive = locate(target["ref"])
	TEST_ASSERT(isnull(still_alive) || !QDELING(still_alive), "[label] пережил qdel и не собран (внешних держателей: [recorded_holders(target["type_path"])])")

/// ДИАГНОСТИКА: если цель ещё жива после qdel, пишет полный скан держателей
/// в data/logs/<раунд>/harddels.log. Вызывать строго между qdel и GC-прогоном.
/datum/unit_test/harddel_9813_base/proc/scan_holders(list/target, stage = "после qdel")
	var/datum/leaked = locate(target["ref"])
	if(!leaked)
		log_reftracker("=== ТЕСТ [target["label"]] ([stage]): цель уже собрана ===")
		return
	// EXTERNAL_REFCOUNT уже вычитает локалку этого фрейма.
	var/holders = EXTERNAL_REFCOUNT(leaked)
	log_reftracker("=== ТЕСТ [target["label"]] ([stage]): жива, держателей [holders] ===")
	leaked.find_references(max(holders, 1), skip_alert = TRUE)

/// Сливает отложенную очередь SSauto_cryo синхронно: в бою она растянута по тикам
/// (wait = 10 SECONDS), тесту ждать нечего.
/datum/unit_test/harddel_9813_base/proc/drain_cryo_queue()
	while(length(SSauto_cryo.delete_queue))
		var/atom/movable/victim = SSauto_cryo.delete_queue[1]
		SSauto_cryo.delete_queue.Cut(1, 2)
		if(!QDELETED(victim))
			qdel(victim)

/// Раздвоение личности: травма, два бэксит-моба и два экшена держат друг друга
/// по кругу. Бэксит хранит `body` - живого человека со всем графом органов и
/// экипировки, поэтому утёкший бэксит тянет за собой и тело.
/// Раунд 9813: /datum/brain_trauma/severe/split_personality (5 ссылок),
/// /mob/living/split_personality (1), /mob/living/carbon/human (32 штуки).
/datum/unit_test/split_personality_teardown_releases_body
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/split_personality_teardown_releases_body/proc/build_trauma(mob/living/carbon/human/host)
	var/datum/brain_trauma/severe/split_personality/trauma = new
	trauma.owner = host
	trauma.make_backseats()
	trauma.setup_personality_actions()
	return trauma

/// Штатный путь: тело живо, травму снимают - on_lose() разбирает всё сам.
/datum/unit_test/split_personality_teardown_releases_body/proc/teardown_with_owner()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/brain_trauma/severe/split_personality/trauma = build_trauma(host)
	var/mob/living/split_personality/stranger = trauma.stranger_backseat
	var/mob/living/split_personality/backseat = trauma.owner_backseat

	TEST_ASSERT_NOTNULL(stranger, "make_backseats() не создал stranger_backseat")
	TEST_ASSERT_NOTNULL(backseat, "make_backseats() не создал owner_backseat")
	TEST_ASSERT_EQUAL(stranger.body, host, "Бэксит не запомнил тело")
	TEST_ASSERT_EQUAL(stranger.trauma, trauma, "Бэксит не запомнил травму")

	qdel(trauma)

	TEST_ASSERT(QDELETED(stranger), "Снятие травмы не удалило stranger_backseat")
	TEST_ASSERT(QDELETED(backseat), "Снятие травмы не удалило owner_backseat")
	TEST_ASSERT_NULL(stranger.body, "Удалённый бэксит продолжает держать тело")
	TEST_ASSERT_NULL(stranger.trauma, "Удалённый бэксит продолжает держать травму")

/// Тело отвалилось раньше травмы: базовый Destroy пропускает on_lose() при
/// пустом owner, и до фикса бэкситы с экшенами оставались висеть навсегда.
/datum/unit_test/split_personality_teardown_releases_body/proc/teardown_without_owner()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/brain_trauma/severe/split_personality/trauma = build_trauma(host)
	var/mob/living/split_personality/stranger = trauma.stranger_backseat
	var/datum/action/backseat_action = trauma.backseat_action

	TEST_ASSERT_NOTNULL(backseat_action, "setup_personality_actions() не создал экшены")
	trauma.owner = null
	qdel(trauma)

	TEST_ASSERT(QDELETED(stranger), "Травма без owner оставила живой бэксит")
	TEST_ASSERT(QDELETED(backseat_action), "Травма без owner оставила живой экшен")
	TEST_ASSERT_NULL(stranger.body, "Осиротевший бэксит продолжает держать тело")

/// Отдельное удаление бэксита (BiologicalLife зовёт qdel(src) при мёртвом теле)
/// обязано отпускать обе ссылки, иначе моб-призрак пиннит человека.
/datum/unit_test/split_personality_teardown_releases_body/proc/qdel_backseat_directly()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/split_personality/lone = new(host, null)
	TEST_ASSERT_EQUAL(lone.body, host, "Бэксит не запомнил тело")
	var/list/record = target_record(lone, "split_personality backseat")
	qdel(lone)
	TEST_ASSERT_NULL(lone.body, "Удалённый бэксит продолжает держать тело")
	return record

/datum/unit_test/split_personality_teardown_releases_body/Run()
	teardown_with_owner()
	teardown_without_owner()

	begin_isolated_gc()
	var/list/record = qdel_backseat_directly()
	scan_holders(record)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	scan_holders(record, "после GC-прогона")
	assert_soft_collected(record)

/// Партийная граната создаёт 20 декалей конфетти в собственном loc. Если граната
/// сработала в руках, loc - это карбон, а /obj/effect/decal/Initialize отвечает
/// INITIALIZE_HINT_QDEL на любой не-турф: конструктор возвращает уже удалённую
/// декаль, и `stomach_contents += gib` клал в вечный список труп.
/// stomach_contents вычищался только для /mob/living (handle_stomach), так что
/// эти 20 декалей гарантированно уходили в hard delete - ровно то, что видно в
/// раунде 9813: 20 /obj/effect/decal/cleanable/confetti одним тиком, по 1 ссылке.
/datum/unit_test/stomach_contents_releases_qdeleted_content
	parent_type = /datum/unit_test/harddel_9813_base

/// Декаль, рождённая внутри моба, уже мертва - в желудок её пускать нельзя.
/datum/unit_test/stomach_contents_releases_qdeleted_content/proc/swallow_stillborn_decal()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/effect/decal/cleanable/confetti/gib = new(host)
	TEST_ASSERT(QDELETED(gib), "Декаль внутри моба неожиданно выжила (предпосылка теста сломана)")

	var/list/record = target_record(gib, "stomach_contents: /obj/effect/decal/cleanable/confetti")
	host.add_to_stomach(gib)
	TEST_ASSERT(!length(host.stomach_contents), "add_to_stomach принял уже удалённую декаль")
	return record

/// Содержимое, удалённое кем-то со стороны, обязано уйти на ближайшем Life-тике.
/datum/unit_test/stomach_contents_releases_qdeleted_content/proc/swallow_and_qdel()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/swallowed = new(host)

	host.add_to_stomach(swallowed)
	TEST_ASSERT(swallowed in host.stomach_contents, "add_to_stomach не положил предмет в желудок")

	var/list/record = target_record(swallowed, "stomach_contents: /obj/item")
	qdel(swallowed)
	host.prune_stomach_contents()
	TEST_ASSERT(!length(host.stomach_contents), "stomach_contents удержал удалённое содержимое")
	return record

/// Передача содержимого между мобами не должна оставлять хвостов ни у кого.
/datum/unit_test/stomach_contents_releases_qdeleted_content/proc/swallow_and_release()
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/swallowed = new(first)

	first.add_to_stomach(swallowed)
	first.remove_from_stomach(swallowed)
	TEST_ASSERT(!length(first.stomach_contents), "remove_from_stomach не снял содержимое")

	swallowed.forceMove(second)
	second.add_to_stomach(swallowed)
	qdel(swallowed)
	second.prune_stomach_contents()
	first.prune_stomach_contents()
	TEST_ASSERT(!length(second.stomach_contents), "Второй моб удержал удалённое содержимое")
	TEST_ASSERT(!length(first.stomach_contents), "Первый моб получил чужое содержимое обратно")

/datum/unit_test/stomach_contents_releases_qdeleted_content/Run()
	begin_isolated_gc()
	var/list/stillborn = swallow_stillborn_decal()
	var/list/swallowed = swallow_and_qdel()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(stillborn)
	assert_soft_collected(swallowed)

	swallow_and_release()

/// Экшен-кнопка держит linked_action. Remove() удаляет кнопки, итерируясь по
/// `viewers`, а action_button/Destroy правит этот же список - индекс сдвигается
/// и следующий hud пропускается. Его кнопка переживает экшен и держит его до
/// конца раунда: раунд 9813 - antag_info (5 штук), sizecode_smallsprite,
/// item_action/toggle_firemode, все ровно с 1 внешней ссылкой.
/datum/unit_test/action_remove_kills_every_button
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/action_remove_kills_every_button/proc/build_hud(mob/living/carbon/human/viewer)
	var/datum/hud/hud = new(viewer)
	viewer.set_hud_used(hud)
	return hud

/datum/unit_test/action_remove_kills_every_button/proc/remove_with_two_viewers()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/watcher = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	build_hud(owner)
	build_hud(watcher)

	var/datum/action/action = new /datum/action(owner)
	action.Grant(owner)
	action.ShowTo(watcher)
	TEST_ASSERT_EQUAL(length(action.viewers), 2, "Экшен не набрал двух зрителей (предпосылка теста сломана)")

	var/list/buttons = list()
	for(var/datum/hud/hud in action.viewers)
		buttons += action.viewers[hud]

	action.Remove(owner)

	for(var/atom/movable/screen/movable/action_button/button as anything in buttons)
		TEST_ASSERT(QDELETED(button), "Remove() оставил живую кнопку [button] с linked_action на экшене")
	TEST_ASSERT(!length(action.viewers), "Remove() не очистил viewers")
	qdel(action)

/// antag_info хранит свой antag_datum и до фикса не отпускал его в Destroy().
/datum/unit_test/action_remove_kills_every_button/proc/antag_info_releases_datum()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/antag_mind = new
	var/datum/antagonist/antag = new /datum/antagonist()
	// Destroy() антагониста stack_trace'ит без owner - выдаём формального владельца.
	antag.owner = antag_mind
	var/datum/action/antag_info/info = new(host, antag)
	info.Grant(host)

	var/list/record = target_record(info, "antag_info action")
	qdel(info)
	TEST_ASSERT_NULL(info.antag_datum, "antag_info не отпустил antag_datum")
	TEST_ASSERT(!(info in host.actions), "Удалённый antag_info остался в mob.actions")
	qdel(antag)
	qdel(antag_mind)
	return record

/datum/unit_test/action_remove_kills_every_button/Run()
	remove_with_two_viewers()

	begin_isolated_gc()
	var/list/record = antag_info_releases_datum()
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// Экипированный человек, ушедший через cryoMob(), обязан собираться.
/// Раунд 9813: девять таких мобов ушли в hard delete с 17-70 внешними ссылками,
/// каждый - ровно через delete_queue SSauto_cryo после входа в крио-под.
/datum/unit_test/gc_cryo_despawn_releases_occupant
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/gc_cryo_despawn_releases_occupant/proc/despawn_via_cryo()
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	occupant.equipOutfit(/datum/outfit/job/assistant, FALSE)
	var/datum/mind/occupant_mind = new
	occupant_mind.transfer_to(occupant)
	occupant_mind.assigned_role = "Assistant"

	var/list/record = target_record(occupant, "cryoMob occupant: /mob/living/carbon/human")
	// Тест владеет мобом сам: teardown не должен вторично удалять его.
	allocated -= occupant
	cryoMob(occupant, null, null, FALSE, "cryo pod")
	TEST_ASSERT(!(occupant in GLOB.ssd_mob_list), "cryoMob не снял моба со списка SSD")
	TEST_ASSERT_NULL(occupant.loc, "cryoMob не отправил моба в nullspace")
	drain_cryo_queue()
	TEST_ASSERT(QDELETED(occupant), "Очередь SSauto_cryo не удалила моба")
	qdel(occupant_mind)
	return record

/// Вторая ветка: настоящий крио-под. С подом cryoMob раскладывает шмот по поду и
/// пакету выдачи, вытряхивает вложенных мобов и закрывает капсулу - именно этот
/// путь дал девять хардделов в раунде 9813 (игроки садились в под руками).
/datum/unit_test/gc_cryo_despawn_releases_occupant/proc/despawn_via_pod()
	var/obj/machinery/cryopod/pod = allocate(/obj/machinery/cryopod, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	occupant.equipOutfit(/datum/outfit/job/assistant, FALSE)
	var/datum/mind/occupant_mind = new
	occupant_mind.transfer_to(occupant)
	occupant_mind.assigned_role = "Assistant"

	pod.close_machine(occupant)
	TEST_ASSERT_EQUAL(pod.occupant, occupant, "Моб не попал в крио-под")

	var/list/record = target_record(occupant, "cryopod despawn_occupant: /mob/living/carbon/human")
	allocated -= occupant
	pod.despawn_occupant()
	TEST_ASSERT_NULL(pod.occupant, "Под не отпустил жильца после despawn_occupant()")
	drain_cryo_queue()
	TEST_ASSERT(QDELETED(occupant), "Очередь SSauto_cryo не удалила жильца пода")
	qdel(occupant_mind)
	return record

/// Удаление личного КПК и айди-карты - единственная защита крио от кражи доступов.
/// Удаление ступенчатое (очередь SSauto_cryo), а вещи к этому моменту уже лежат ВНУТРИ
/// капсулы, которую open_machine() тут же вытряхивает на пол: КПК вместе с картой внутри
/// успевали подобрать раньше, чем очередь до него доходила.
/datum/unit_test/cryopod_does_not_drop_doomed_pda/Run()
	var/turf/pod_turf = run_loc_floor_bottom_left
	var/obj/machinery/cryopod/pod = allocate(/obj/machinery/cryopod, pod_turf)
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human, pod_turf)
	var/datum/mind/occupant_mind = new
	occupant_mind.transfer_to(occupant)
	occupant_mind.assigned_role = "Assistant"

	var/obj/item/modular_computer/pda/personal_pda = allocate(/obj/item/modular_computer/pda, pod_turf)
	occupant.put_in_hands(personal_pda)
	personal_pda.owner = occupant.real_name //именно по owner крио отличает свой КПК от чужого
	TEST_ASSERT_EQUAL(personal_pda.loc, occupant, "Sanity: КПК должен лежать в руках жильца, иначе get_all_gear его не увидит")

	pod.close_machine(occupant)
	TEST_ASSERT_EQUAL(pod.occupant, occupant, "Sanity: моб не попал в крио-под")

	allocated -= occupant //мобом дальше владеет очередь SSauto_cryo
	pod.despawn_occupant()

	TEST_ASSERT(!(personal_pda in pod_turf.contents), "Личный КПК жильца вытряхнуло из капсулы на пол - его успевают подобрать вместе с айди-картой внутри")
	TEST_ASSERT(isnull(personal_pda.loc) || QDELETED(personal_pda), "Личный КПК жильца обязан покинуть мир сразу, а не ждать своей очереди на виду у всех")

	while(length(SSauto_cryo.delete_queue))
		var/atom/movable/victim = SSauto_cryo.delete_queue[1]
		SSauto_cryo.delete_queue.Cut(1, 2)
		if(!QDELETED(victim))
			qdel(victim)
	qdel(occupant_mind)

/datum/unit_test/gc_cryo_despawn_releases_occupant/Run()
	begin_isolated_gc()
	var/list/record = despawn_via_cryo()
	scan_holders(record)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	scan_holders(record, "после GC-прогона")
	assert_soft_collected(record)

	begin_isolated_gc()
	var/list/pod_record = despawn_via_pod()
	scan_holders(pod_record)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	scan_holders(pod_record, "после GC-прогона (под)")
	assert_soft_collected(pod_record)

/// /mob/dead/observer/Destroy() обнулял `mind` до вызова родителя, а /mob/Destroy
/// чистит mind.current только по проверке `if(mind?.current == src)` - она видела
/// уже пустое поле. Разум живёт в SSticker.minds весь раунд, поэтому mind.current
/// оставался вечной единственной ссылкой на удалённого госта.
/// Раунд 9813: 10 хардделов /mob/dead/observer, у девяти ровно 1 внешняя ссылка.
/datum/unit_test/observer_destroy_releases_mind
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/observer_destroy_releases_mind/proc/ghost_and_qdel(datum/mind/ghost_mind)
	var/mob/dead/observer/ghost = new(run_loc_floor_bottom_left)
	ghost.mind = ghost_mind
	ghost_mind.set_current(ghost)
	var/list/record = target_record(ghost, "observer with mind: /mob/dead/observer")

	qdel(ghost)
	TEST_ASSERT_NULL(ghost_mind.current, "mind.current держит удалённого обсервера")
	return record

/datum/unit_test/observer_destroy_releases_mind/Run()
	begin_isolated_gc()
	var/datum/mind/ghost_mind = new
	var/list/record = ghost_and_qdel(ghost_mind)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)
	qdel(ghost_mind)

/// SSaugury держит гостов ключами в двух ассоциациях и не чистил их по qdel;
/// вдобавок ветка сброса снимала ключи прямо во время обхода того же списка.
/datum/unit_test/augury_drops_qdeleted_observers
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/augury_drops_qdeleted_observers/Run()
	var/list/saved_given = SSaugury.observers_given_action
	var/list/saved_watchers = SSaugury.watchers
	var/list/saved_doom = SSaugury.doombringers
	SSaugury.observers_given_action = list()
	SSaugury.watchers = list()
	SSaugury.doombringers = list()

	// Без "предвестника" fire() уходит в ветку полного сброса и вычистил бы список
	// и без прунинга - тест обязан идти по рабочей ветке.
	var/obj/effect/doom = allocate(/obj/effect)
	SSaugury.register_doom(doom, 100)

	var/mob/dead/observer/first = new(run_loc_floor_bottom_left)
	var/mob/dead/observer/second = new(run_loc_floor_bottom_left)
	SSaugury.observers_given_action[first] = TRUE
	SSaugury.observers_given_action[second] = TRUE
	SSaugury.watchers += first
	SSaugury.watchers += second
	qdel(first)
	qdel(second)

	SSaugury.fire()

	// Результат снимаем до восстановления: провал TEST_ASSERT выходит из Run() и
	// оставил бы подсистему с временными пустыми списками на весь прогон.
	var/given_pruned = !length(SSaugury.observers_given_action)
	var/watchers_pruned = !length(SSaugury.watchers)

	SSaugury.observers_given_action = saved_given
	SSaugury.watchers = saved_watchers
	SSaugury.doombringers = saved_doom

	TEST_ASSERT(given_pruned, "SSaugury удержал удалённых гостов в observers_given_action")
	TEST_ASSERT(watchers_pruned, "SSaugury удержал удалённых гостов в watchers")
