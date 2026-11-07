/datum/unit_test/proc/nightmare_in_dark_sector(datum/antag_training_session/session)
	var/datum/antag_training_sector/sector = session.arena.sectors["dark"]
	var/list/budget = new_wait_budget(30 SECONDS, "кошмар в тёмном секторе")
	while(!(sector.state == ANTAG_TRAINING_SECTOR_READY && session.arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
		continue
	return sector.state == ANTAG_TRAINING_SECTOR_READY && session.arena.inside_bounds(get_turf(session.current_body), sector.bounds)

/// Кнопка сердца тьмы: пожиратель света в руке участника.
/datum/unit_test/proc/nightmare_draw_blade(mob/living/carbon/human/body)
	var/obj/item/organ/heart/nightmare/training/heart = body.getorganslot(ORGAN_SLOT_HEART)
	for(var/datum/action/item_action/organ_action/use/button in body.actions)
		if(button.target == heart)
			button.Trigger()
	return locate(/obj/item/light_eater/training) in body.held_items

/datum/unit_test/proc/nightmare_free_beside(atom/thing)
	for(var/direction in GLOB.alldirs)
		var/turf/open/spot = get_step(thing, direction)
		if(istype(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			return spot

/datum/unit_test/proc/nightmare_wait_dark(turf/spot, max_wait = 5 SECONDS)
	var/list/budget = new_wait_budget(max_wait, "темнота на клетке")
	while(spot.get_lumcount() >= SHADOW_SPECIES_LIGHT_THRESHOLD && wait_budget_tick(budget))
		continue
	return spot.get_lumcount() < SHADOW_SPECIES_LIGHT_THRESHOLD

/// Программа «Кошмар»: тело теневого вида без одежды, скрытый датум, подъём сердцем тьмы и его ожидание, кнопки пульта, изоляция пожирателя и Великой тьмы от чужого и общего света хаба.
/datum/unit_test/antag_training_nightmare/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nightmare)
	TEST_ASSERT(session.prepare(), "Полигон готовит кошмара.")
	TEST_ASSERT(nightmare_in_dark_sector(session), "Кошмар появляется в тёмном секторе.")
	var/datum/antag_training_program/antag/nightmare/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	TEST_ASSERT(istype(body) && body.dna.species.id == SPECIES_NIGHTMARE, "Тело участника - кошмар.")
	TEST_ASSERT(istype(body.getorganslot(ORGAN_SLOT_HEART), /obj/item/organ/heart/nightmare/training), "Сердце тьмы учебное.")
	TEST_ASSERT(!body.w_uniform && !body.back && !body.shoes, "Кошмар без одежды учебного участника.")
	var/datum/antagonist/nightmare/training/role = program.role(session)
	TEST_ASSERT(istype(role) && role.training == session, "Учебный датум кошмара привязан к сеансу.")
	TEST_ASSERT(!(role in GLOB.antagonists), "Датум кошмара снят с GLOB.antagonists: обходы раунда его не видят.")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")
	var/datum/action/cooldown/nightmare/darkness/darkness = locate() in body.actions
	TEST_ASSERT_NOTNULL(darkness, "У кошмара есть Великая тьма.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")

	TEST_ASSERT(nightmare_wait_dark(get_turf(body)), "Вход в сектор тёмный.")
	body.death()
	TEST_ASSERT(wait_for_var(session, "recovery_timer", null, 10 SECONDS), "Сеанс отработал смерть.")
	TEST_ASSERT(body.stat == DEAD && session.arena.inside_bounds(get_turf(body), session.arena.sectors["dark"].bounds), "Убитого в темноте кошмара сеанс не уносит в хаб.")
	TEST_ASSERT(program.heart_timer, "Сеанс ждёт сердце тьмы.")
	var/beats = 0
	while(body.stat == DEAD && beats < 200)
		beats++
		body.handle_organs(SSmobs.wait / (1 SECONDS), beats)
	TEST_ASSERT(body.stat != DEAD, "Сердце тьмы поднимает тело в темноте за фазы органов Life.")
	TEST_ASSERT(beats * SSmobs.wait * 2 <= antag_training_nightmare_heart_wait(), "Сеанс ждёт сердце дольше, чем оно бьётся у тела без клиента: [beats] ударов.")
	TEST_ASSERT_NULL(program.heart_timer, "Подъём тела снимает ожидание сердца.")
	TEST_ASSERT(session.arena.inside_bounds(get_turf(body), session.arena.sectors["dark"].bounds), "Поднятое сердцем тело осталось в секторе.")
	body.death()
	TEST_ASSERT(wait_for_var(session, "recovery_timer", null, 10 SECONDS), "Сеанс отработал вторую смерть.")
	TEST_ASSERT(body.stat == DEAD && program.heart_timer, "Вторая смерть в темноте снова ждёт сердце, а не уносит в хаб.")
	var/datum/timedevent/heart_event = SStimer.timer_id_dict[program.heart_timer]
	var/datum/callback/give_up = heart_event?.callBack
	TEST_ASSERT_NOTNULL(give_up, "Ожидание сердца - таймер с восстановлением.")
	give_up.Invoke()
	TEST_ASSERT(body.stat != DEAD && get_turf(body) == session.arena.entry_turf, "Если сердце не подняло тело, участник восстанавливается в хабе.")
	TEST_ASSERT(!program.heart_gave_up, "После восстановления сердце снова ждёт.")
	session.enter_sector(session.arena.sectors["dark"])

	var/obj/item/light_eater/training/blade = nightmare_draw_blade(body)
	TEST_ASSERT_NOTNULL(blade, "Кнопка сердца тьмы даёт учебный пожиратель света.")
	body.a_intent = INTENT_HARM
	antag_training_console_act(session, console, "program_option", list("option" = "Лампы для пожирателя"))
	var/list/lamps = list()
	for(var/obj/machinery/light/floor/lamp in range(2, body))
		if(lamp.training_owner?.resolve() == session)
			lamps += lamp
	TEST_ASSERT(length(lamps), "Вокруг кошмара стоят лампы участника.")
	var/obj/machinery/light/floor/eaten = lamps[1]
	TEST_ASSERT(wait_for_var(eaten, "on", TRUE, 5 SECONDS), "Лампа горит.")
	blade.melee_attack_chain(body, eaten, null, ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT(QDELETED(eaten) || eaten.status != LIGHT_OK, "Пожиратель гасит свою лампу.")

	var/datum/antag_training_session/neighbour = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(neighbour.prepare(), "Второй участник входит на тот же полигон.")
	var/mob/living/carbon/human/stranger = neighbour.current_body
	stranger.forceMove(nightmare_free_beside(body))
	var/obj/item/flashlight/torch = antag_training_light_torch(stranger)
	TEST_ASSERT(torch?.light_on, "Фонарь второго участника горит.")
	blade.melee_attack_chain(body, stranger, null, ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT(torch.light_on, "Пожиратель не гасит фонарь другого участника.")
	darkness.next_use_time = 0
	darkness.Trigger()
	TEST_ASSERT(torch.light_on && darkness.next_use_time <= world.time, "Великая тьма не срабатывает рядом со светом другого участника.")
	for(var/obj/machinery/light/floor/lamp as anything in lamps)
		if(!QDELETED(lamp))
			TEST_ASSERT_EQUAL(lamp.status, LIGHT_OK, "Отказ Великой тьмы не гасит и свои лампы.")
	torch.attack_self(stranger)
	TEST_ASSERT(!torch.light_on, "Второй участник выключил фонарь.")
	var/obj/item/gun/energy/disabler/stranger_gun = allocate(/obj/item/gun/energy/disabler, get_turf(stranger))
	stranger.put_in_hands(stranger_gun)
	TEST_ASSERT(stranger_gun.loc == stranger && !stranger_gun.gun_light, "У второго участника оружие без фонаря.")
	darkness.Trigger()
	TEST_ASSERT(darkness.next_use_time > world.time, "Выключенный фонарь и оружие без фонаря рядом не мешают Великой тьме: [role.darkness_refusal(darkness)]")
	TEST_ASSERT(!QDELETED(torch) && !QDELETED(stranger_gun), "Великая тьма не тронула вещи второго участника.")
	for(var/obj/machinery/light/floor/lamp as anything in lamps)
		if(!QDELETED(lamp))
			TEST_ASSERT(lamp.status != LIGHT_OK, "Великая тьма гасит лампы вокруг.")
	antag_training_console_act(session, console, "program_option", list("option" = "Здоровье и Великая тьма"))
	TEST_ASSERT(darkness.next_use_time <= world.time, "Кнопка сбрасывает задержку Великой тьмы.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель во тьме"))
	var/mob/living/carbon/human/dummy
	for(var/mob/living/carbon/human/candidate in session.arena.targets)
		if(candidate.training_owner?.resolve() == session)
			dummy = candidate
	TEST_ASSERT_NOTNULL(dummy, "Кнопка ставит цель во тьме.")
	var/obj/item/flashlight/dummy_torch = locate() in dummy.held_items
	TEST_ASSERT(dummy_torch?.light_on, "У цели во тьме горит фонарь.")
	blade.melee_attack_chain(body, dummy, null, ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT(!dummy_torch.light_on, "Пожиратель гасит фонарь своей цели.")

	body.forceMove(session.arena.entry_turf)
	antag_training_console_act(session, console, "program_option", list("option" = "Здоровье и Великая тьма"))
	var/list/hub_lamps = list()
	for(var/obj/machinery/light/lamp in range(darkness.aoe_radius, body))
		if(lamp.status == LIGHT_OK)
			hub_lamps += lamp
	TEST_ASSERT(length(hub_lamps), "В вестибюле хаба горят общие лампы.")
	darkness.Trigger()
	TEST_ASSERT(darkness.next_use_time <= world.time, "В вестибюле хаба Великая тьма не срабатывает.")
	var/obj/machinery/light/hub_lamp = hub_lamps[1]
	body.forceMove(nightmare_free_beside(hub_lamp))
	blade.melee_attack_chain(body, hub_lamp, null, ATTACK_IGNORE_CLICKDELAY)
	for(var/obj/machinery/light/lamp as anything in hub_lamps)
		TEST_ASSERT(!QDELETED(lamp) && lamp.status == LIGHT_OK, "Общие лампы хаба целы после Великой тьмы и пожирателя.")
	qdel(neighbour)
	allocated -= neighbour

/// «Охота во тьме»: лампы у входа гаснут от пожирателя, фонарь цели гасят Великой тьмой с расстояния из подсказки, гибель цели на последнем шаге завершает упражнение; свет за спиной цели, её ранняя смерть и перенос из сектора его проваливают.
/datum/unit_test/antag_training_nightmare_hunt/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/nightmare)
	TEST_ASSERT(session.prepare(), "Полигон готовит кошмара.")
	TEST_ASSERT(nightmare_in_dark_sector(session), "Кошмар в тёмном секторе.")
	var/mob/living/carbon/human/body = session.current_body
	body.a_intent = INTENT_HARM
	var/datum/tgui/ui = allocate(/datum/tgui, body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "nightmare_hunt")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в тёмном секторе.")
	var/mob/living/carbon/human/target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Упражнение ставит цель.")
	var/obj/item/flashlight/torch = locate() in target.held_items
	TEST_ASSERT(torch?.light_on, "У цели горит фонарь.")
	var/list/lamps = list()
	for(var/obj/machinery/light/floor/lamp in run.props)
		lamps += lamp
	TEST_ASSERT_EQUAL(length(lamps), 3, "У входа три лампы.")
	for(var/obj/machinery/light/floor/lamp as anything in lamps)
		TEST_ASSERT(wait_for_var(lamp, "on", TRUE, 5 SECONDS), "Лампа упражнения горит.")
	var/obj/item/light_eater/training/blade = nightmare_draw_blade(body)
	TEST_ASSERT_NOTNULL(blade, "Пожиратель света в руке.")
	for(var/obj/machinery/light/floor/lamp as anything in lamps)
		body.forceMove(nightmare_free_beside(lamp))
		blade.melee_attack_chain(body, lamp, null, ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT_EQUAL(run.step_index, 2, "Погашенные лампы засчитаны.")

	var/datum/action/cooldown/nightmare/darkness/darkness = locate() in body.actions
	var/reach = CEILING(torch.light_range, 1)
	var/datum/antag_training_exercise_step/stalk = run.current_step()
	TEST_ASSERT(findtext(stalk.hint, "[reach + 1]-[darkness.aoe_radius] клетках"), "Подсказка шага называет расстояние до цели для Великой тьмы.")
	var/turf/hideout
	var/list/budget = new_wait_budget(5 SECONDS, "тёмная клетка в [reach + 1]-[darkness.aoe_radius] клетках от цели")
	while(!hideout && wait_budget_tick(budget))
		for(var/turf/open/spot in range(darkness.aoe_radius, target))
			if(get_dist(spot, target) > reach && session.arena.match_zone(spot) == "dark" && !spot.is_blocked_turf(exclude_mobs = FALSE) && spot.get_lumcount() < SHADOW_SPECIES_LIGHT_THRESHOLD)
				hideout = spot
				break
	TEST_ASSERT_NOTNULL(hideout, "Рядом с целью есть тёмная клетка из подсказки.")
	body.forceMove(hideout)
	TEST_ASSERT(!run.ended, "Шаг по темноте не выдаёт участника: [run.result_text]")
	darkness.Trigger()
	TEST_ASSERT(!torch.light_on, "Великая тьма из [get_dist(hideout, target)] клеток гасит фонарь цели.")
	antag_training_console_act(session, ui, "program_option", list("option" = "Здоровье и Великая тьма"))
	TEST_ASSERT(darkness.next_use_time > world.time, "Во время охоты кнопка пульта не сбрасывает Великую тьму.")
	var/turf/beside = nightmare_free_beside(target)
	TEST_ASSERT(nightmare_wait_dark(beside), "Без фонаря у цели темно.")
	body.forceMove(beside)
	TEST_ASSERT_EQUAL(run.step_index, 3, "Цель достигнута в темноте: [run.result_text]")
	var/list/zones = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	for(var/hit in 1 to 40)
		if(target.stat == DEAD)
			break
		body.zone_selected = zones[(hit % length(zones)) + 1]
		blade.melee_attack_chain(body, target, null, ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT_EQUAL(target.stat, DEAD, "Пожиратель убивает цель.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE), "Гибель цели завершает упражнение.")
	TEST_ASSERT(run.success, "Упражнение выполнено: [run.result_text]")

	run = nightmare_hunt_stalk(session, ui, blade)
	TEST_ASSERT_NOTNULL(run, "Повтор доходит до шага подкрадывания.")
	target = run.find_prop(/mob/living/carbon/human)
	var/turf/behind
	for(var/turf/open/spot in range(3, target))
		if(get_dist(spot, target) == 3 && session.arena.match_zone(spot) == "dark" && !spot.is_blocked_turf(exclude_mobs = FALSE) && can_see(target, spot, 3))
			behind = spot
			break
	TEST_ASSERT_NOTNULL(behind, "В комнате цели есть клетка в 3 клетках от неё.")
	target.setDir(get_dir(behind, target))
	budget = new_wait_budget(5 SECONDS, "свет фонаря за спиной цели")
	while(behind.get_lumcount() < SHADOW_SPECIES_LIGHT_THRESHOLD && wait_budget_tick(budget))
		continue
	TEST_ASSERT(behind.get_lumcount() >= SHADOW_SPECIES_LIGHT_THRESHOLD, "Фонарь освещает клетку в 3 клетках за спиной цели.")
	body.forceMove(behind)
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "увидели"), "Шаг в 3 клетках за спиной цели проваливает упражнение: [run.result_text]")

	run = nightmare_hunt_stalk(session, ui, blade)
	TEST_ASSERT_NOTNULL(run, "Третий прогон доходит до шага подкрадывания.")
	target = run.find_prop(/mob/living/carbon/human)
	target.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "раньше, чем вы к ней подкрались"), "Смерть цели до подкрадывания проваливает упражнение: [run.result_text]")

	run = nightmare_hunt_stalk(session, ui, blade)
	TEST_ASSERT_NOTNULL(run, "Четвёртый прогон доходит до шага подкрадывания.")
	antag_training_console_act(session, ui, "hub", list())
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "покинули"), "Перенос пультом в хаб - выход из сектора, а не выход на свет: [run.result_text]")

/// Новый прогон «Охоты во тьме» от входа сектора до шага подкрадывания после поблажки на свет погашенных ламп.
/datum/unit_test/proc/nightmare_hunt_stalk(datum/antag_training_session/session, datum/tgui/ui, obj/item/light_eater/training/blade)
	session.current_body.forceMove(session.arena.sectors["dark"].spawn_turf())
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "nightmare_hunt")
	if(!run?.find_prop(/mob/living/carbon/human))
		return null
	for(var/obj/machinery/light/floor/lamp in run.props)
		session.current_body.forceMove(nightmare_free_beside(lamp))
		blade.melee_attack_chain(session.current_body, lamp, null, ATTACK_IGNORE_CLICKDELAY)
	var/datum/antag_training_exercise_step/drill/nightmare_stalk/stalk = run.current_step()
	if(!istype(stalk))
		return null
	var/list/budget = new_wait_budget(5 SECONDS, "конец поблажки шага подкрадывания")
	while(world.time < stalk.grace_until && wait_budget_tick(budget))
		continue
	return run
