/// do_after на уже удалённую цель сразу отказывает и не оставляет её в do_afters пользователя.
/datum/unit_test/do_after_deleted_target/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/structure/deployable_barricade/metal/target = allocate(/obj/structure/deployable_barricade/metal)
	qdel(target)

	TEST_ASSERT(!do_after(user, 1, target), "do_after на удалённую цель должен отказать")
	TEST_ASSERT(!(target in user.do_afters), "Удалённая цель не должна оставаться в do_afters пользователя")

/// do_after_mob без помех завершается успехом и отпускает цель.
/datum/unit_test/do_after_mob_completes/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	TEST_ASSERT(do_after_mob(user, target, 2), "do_after_mob без движения и помех должен завершиться успехом")
	TEST_ASSERT(!(target in user.do_afters), "Цель должна уйти из do_afters после завершения")

/// do_after_mob обрывается, если пользователь сошёл с места.
/datum/unit_test/do_after_mob_user_moved/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom/movable, forceMove), run_loc_floor_top_right), 1)

	TEST_ASSERT(!do_after_mob(user, target, 5), "do_after_mob должен оборваться, когда пользователь ушёл")

/// Скреймл "только буквы" подменяет латиницу, а кириллицу, пробелы и цифры оставляет.
/datum/unit_test/scramble_letters_only_keeps_cyrillic/Run()
	var/result = scramble_message_replace_chars("Ab Вг 1", 100, list("#"), replace_letters_only = TRUE)

	TEST_ASSERT_EQUAL(result, "## Вг 1", "Подменяться должна только латиница")

/// Трек в формате из README (имя+длина+такт) загружается без отдельного id.
/datum/unit_test/jukebox_track_without_id/Run()
	var/datum/track/track = SSjukeboxes.add_track("Grasswalk+1870+17.ogg")

	TEST_ASSERT(istype(track), "Трек без id должен загрузиться")
	TEST_ASSERT_EQUAL(track.song_length, 1870, "Длина трека должна читаться из имени файла")
	TEST_ASSERT_EQUAL(track.song_beat, 17, "Такт трека должен читаться из имени файла")

/// Из пачки удалённой пены в очередь GC встаёт одна на FOAM_GC_SAMPLE, остальные уходят мимо.
/datum/unit_test/foam_skips_gc_queue/Run()
	var/list/foams = list()
	for(var/i in 1 to FOAM_GC_SAMPLE)
		foams += new /obj/effect/particle_effect/foam(run_loc_floor_bottom_left)
	var/foam_type = "[/obj/effect/particle_effect/foam]"
	var/queued_before = 0
	for(var/queued_type in SSgarbage.queue_types[GC_QUEUE_SOFTCHECK])
		if(queued_type == foam_type)
			queued_before++

	for(var/obj/effect/particle_effect/foam/foam as anything in foams)
		qdel(foam)

	var/queued_after = 0
	for(var/queued_type in SSgarbage.queue_types[GC_QUEUE_SOFTCHECK])
		if(queued_type == foam_type)
			queued_after++
	TEST_ASSERT_EQUAL(queued_after - queued_before, 1, "В очередь GC должна встать ровно одна пена из [FOAM_GC_SAMPLE]")

/// Стол исследований отписывается от отстёгнутого любым путём, повторное пристёгивание не ругается.
/datum/unit_test/research_table_rebuckle/Run()
	var/obj/machinery/research_table/table = allocate(/obj/machinery/research_table)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	TEST_ASSERT(table.buckle_mob(user, TRUE), "test premise: моб должен пристегнуться")

	table.unbuckle_mob(user, TRUE)

	TEST_ASSERT(table.buckle_mob(user, TRUE), "Моб должен пристегнуться повторно")

/// Поиск пути не проходит через сторону перил, а вдоль перил и сбоку на их клетку проходит.
/datum/unit_test/railing_blocks_path_only_through_its_side/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/north = get_step(start, NORTH)
	var/turf/east = get_step(start, EAST)
	var/obj/structure/railing/railing = allocate(/obj/structure/railing, start)
	railing.setDir(EAST)

	TEST_ASSERT(!start.LinkBlockedWithAccess(north, null, null), "Вдоль перил путь должен быть открыт")
	TEST_ASSERT(start.LinkBlockedWithAccess(east, null, null), "Через сторону перил путь должен быть закрыт")
	TEST_ASSERT(!north.LinkBlockedWithAccess(start, null, null), "На клетку перил можно войти сбоку")
	TEST_ASSERT(east.LinkBlockedWithAccess(start, null, null), "На клетку перил нельзя войти через их сторону")

/datum/unit_test/proc/assert_jps_route(turf/start, turf/goal)
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, start)
	var/list/path = get_path_to(walker, goal, 30)
	TEST_ASSERT(length(path) && path[length(path)] == goal, "JPS не нашёл путь от ([start.x],[start.y]) до ([goal.x],[goal.y])")
	var/turf/from_turf = start
	for(var/turf/next_turf as anything in path)
		TEST_ASSERT(!from_turf.LinkBlockedWithAccess(next_turf, walker, null), "Путь проходит сквозь перила: ([from_turf.x],[from_turf.y]) -> ([next_turf.x],[next_turf.y])")
		from_turf = next_turf

/// JPS обходит с торца ряд перил, за которым стоит цель.
/datum/unit_test/jps_detours_railing_line/Run()
	var/turf/origin = run_loc_floor_bottom_left
	for(var/offset in 1 to 3)
		var/obj/structure/railing/railing = allocate(/obj/structure/railing, locate(origin.x + 2, origin.y + offset, origin.z))
		railing.setDir(EAST)

	assert_jps_route(locate(origin.x, origin.y + 2, origin.z), locate(origin.x + 3, origin.y + 2, origin.z))

/// JPS заходит на клетку перил сбоку, когда перила смотрят на идущего.
/datum/unit_test/jps_enters_railing_tile_from_side/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/goal = locate(origin.x + 4, origin.y + 1, origin.z)
	var/obj/structure/railing/railing = allocate(/obj/structure/railing, goal)
	railing.setDir(NORTH)

	assert_jps_route(locate(origin.x + 4, origin.y + 4, origin.z), goal)

/// Адаптер этажей не падает на партнёре в nullspace и отпускает удалённого партнёра.
/datum/unit_test/deck_relay_lost_partner/Run()
	var/obj/machinery/power/deck_relay/relay = allocate(/obj/machinery/power/deck_relay)
	var/obj/machinery/power/deck_relay/partner = allocate(/obj/machinery/power/deck_relay)
	relay.above = partner
	partner.below = relay
	partner.moveToNullspace()

	relay.refresh()
	qdel(partner)

	TEST_ASSERT_NULL(relay.above, "Адаптер не должен держать удалённого партнёра")

/// Снятая с кола мишень оказывается в руках снявшего.
/datum/unit_test/target_stake_remove_target/Run()
	var/obj/structure/target_stake/stake = allocate(/obj/structure/target_stake)
	var/obj/item/target/target = allocate(/obj/item/target)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.put_in_active_hand(target)
	stake.attackby(target, user)
	TEST_ASSERT_EQUAL(stake.pinned_target, target, "test premise: мишень должна встать на кол")

	stake.removeTarget(user)

	TEST_ASSERT_NULL(stake.pinned_target, "Кол должен отпустить мишень")
	TEST_ASSERT(target in user.held_items, "Снятая мишень должна оказаться в руках")

/// Удалённый посреди Life слайм не разбирает речь.
/datum/unit_test/slime_speech_after_qdel/Run()
	var/mob/living/simple_animal/slime/slime = allocate(/mob/living/simple_animal/slime)
	qdel(slime)

	slime.handle_speech()

	TEST_ASSERT(QDELETED(slime), "test premise: слайм должен быть удалён")

/// Ядерный взрыв убивает и тех, кто на его этажах сидит в шкафу.
/datum/unit_test/nuke_kills_mobs_in_containers/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet)
	victim.forceMove(closet)

	KillEveryoneOnZLevels(list(run_loc_floor_bottom_left.z))

	TEST_ASSERT(QDELETED(victim) || victim.stat == DEAD, "Моб в шкафу на уровне взрыва должен погибнуть")

/// Киборг-подкрепление InteQ получает язык команды.
/datum/unit_test/nukeop_cyborg_team_language/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	var/datum/mind/mind = allocate_mind()
	mind.current = borg
	borg.mind = mind
	var/datum/antagonist/nukeop/operative = new
	allocated += operative
	operative.owner = mind

	operative.equip_op()

	TEST_ASSERT(borg.has_language(/datum/language/old_codes), "Киборг InteQ должен знать язык команды")

/// Закрытие окна жучка камер у моба без клиента не падает и снимает его с просмотра.
/datum/unit_test/camera_bug_ui_close_without_client/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/camera_bug/bug = allocate(/obj/item/camera_bug)
	bug.concurrent_users += REF(user)

	bug.ui_close(user)

	TEST_ASSERT(!(REF(user) in bug.concurrent_users), "Закрывший окно должен уйти из зрителей жучка")
