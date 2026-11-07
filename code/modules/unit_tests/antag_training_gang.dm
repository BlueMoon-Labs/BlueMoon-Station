/// Выбор семьи в пульте выдаёт учебного бандита этой семьи с учебной командой вне команд раунда; бандит раунда той же семьи в неё не вступает.
/datum/unit_test/antag_training_gang_family/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/gang)
	TEST_ASSERT(session.prepare(), "Полигон готовит бандита.")
	var/datum/antag_training_program/antag/gang/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/datum/antagonist/gang/training/first_gangster = program.role(session)
	var/datum/team/gang/training/first_team = first_gangster?.my_gang
	var/obj/item/gangster_cellphone/antag_training/first_phone = first_gangster?.phone_ref?.resolve()
	TEST_ASSERT(istype(first_team) && istype(first_phone), "Вход выдаёт учебного бандита с телефоном.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(/datum/antagonist/gang/yakuza)))
	var/datum/antagonist/gang/training/gangster = program.role(session)
	TEST_ASSERT(istype(gangster) && gangster != first_gangster, "Смена семьи перевыдаёт учебного бандита.")
	TEST_ASSERT(QDELETED(first_team) && QDELETED(first_phone), "Прежняя учебная семья и её телефон убираются.")
	TEST_ASSERT(gangster.family_type == /datum/antagonist/gang/yakuza && gangster.gang_name == "Tojo Clan" && gangster.gang_id == "YAK", "Учебный бандит - из выбранной семьи.")
	TEST_ASSERT((/obj/item/clothing/under/costume/yakuza in gangster.free_clothes), "Учебный бандит получает одежду семьи.")
	var/datum/team/gang/training/team = gangster.get_team()
	TEST_ASSERT(istype(team) && (body.mind in team.members), "Бандит в учебной семье.")
	TEST_ASSERT(isnull(gangster.handler) && !(team in GLOB.antagonist_teams), "Учебная семья без хендлера и вне команд раунда.")
	var/obj/item/gangster_cellphone/antag_training/phone = gangster.phone_ref?.resolve()
	TEST_ASSERT(istype(phone) && body.contains_atom(phone) && phone.gang_id == team.phone_line && phone.gang_id != gangster.gang_name, "Телефон бандита - на своей учебной линии.")
	TEST_ASSERT(!(phone in GLOB.gangster_cell_phones), "Учебный телефон не в списке телефонов раунда.")

	var/mob/living/carbon/human/station_gangster = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	station_gangster.mind_initialize()
	allocated += station_gangster.mind
	var/datum/antagonist/gang/round_gangster = station_gangster.mind.add_antag_datum(/datum/antagonist/gang/yakuza)
	var/datum/team/gang/round_team = round_gangster?.my_gang
	allocated += round_team
	TEST_ASSERT(round_team && round_team != team && !(station_gangster.mind in team.members), "Бандит раунда той же семьи не вступает в учебную.")
	round_team.my_gang_datum = null
	station_gangster.mind.remove_antag_datum(/datum/antagonist/gang)

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(gangster, 1 MINUTES), "Выход снимает роль бандита.")
	TEST_ASSERT(QDELETED(team) && QDELETED(phone), "Учебная семья и телефон снимаются вместе с бандитом.")

/// Учебная цель принимает рукопожатие кнопкой и получает учебный датум семьи, чужой человек и цель с имплантом - нет; телефоны учебной линии слышат друг друга, но не телефон настоящей семьи.
/datum/unit_test/antag_training_gang_induction/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/gang)
	TEST_ASSERT(session.prepare(), "Полигон готовит бандита.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/antag/gang/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/gang/training/gangster = program.role(session)
	var/datum/team/gang/training/team = gangster.my_gang
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")

	body.drop_all_held_items()
	var/targets_before = length(arena.targets)
	antag_training_console_act(session, console, "program_option", list("option" = "Индукция учебной цели"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before + 1, "Без цели рядом кнопка ставит учебную цель.")
	var/mob/living/carbon/human/recruit = arena.targets[length(arena.targets)]
	TEST_ASSERT(ishuman(recruit) && recruit.mind, "Поставленная цель - человек с разумом.")
	if(!body.Adjacent(recruit))
		for(var/direction in GLOB.cardinals)
			var/turf/open/floor/spot = get_step(body, direction)
			if(istype(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE))
				recruit.forceMove(spot)
				break
	TEST_ASSERT(body.Adjacent(recruit), "Учебная цель стоит вплотную.")

	antag_training_console_act(session, console, "program_option", list("option" = "Индукция учебной цели"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before + 1, "С целью рядом кнопка новую не ставит.")
	TEST_ASSERT_NULL(recruit.mind.has_antag_datum(/datum/antagonist/gang), "Без протянутого рукопожатия кнопка никого не принимает.")
	var/mob/living/carbon/human/outsider
	for(var/direction in GLOB.cardinals)
		var/turf/open/floor/spot = get_step(body, direction)
		if(istype(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			outsider = allocate(/mob/living/carbon/human, spot)
			break
	TEST_ASSERT(outsider && body.Adjacent(outsider), "Чужой человек стоит рядом.")
	outsider.mind_initialize()
	allocated += outsider.mind
	GLOB.unit_test_chat_capture = list()
	gangster.package_spawner.Trigger()
	TEST_ASSERT(body.has_status_effect(STATUS_EFFECT_HANDSHAKE), "Способность протягивает рукопожатие.")
	var/atom/movable/screen/alert/give/secret_handshake/foreign = outsider.alerts["[body]"]
	TEST_ASSERT(istype(foreign), "Чужой человек видит рукопожатие.")
	foreign.handle_transfer()
	TEST_ASSERT_NULL(outsider.mind.has_antag_datum(/datum/antagonist/gang), "Не учебную цель участника в учебную семью не принимают.")
	TEST_ASSERT(heard(body, "принимают только ваши учебные цели"), "Бандит узнаёт, почему чужой не вступил.")
	ADD_TRAIT(recruit, TRAIT_MINDSHIELD, REF(src))
	antag_training_console_act(session, console, "program_option", list("option" = "Индукция учебной цели"))
	TEST_ASSERT_NULL(recruit.mind.has_antag_datum(/datum/antagonist/gang), "Цель с имплантом защиты разума не вступает.")
	TEST_ASSERT(heard(body, "имплант защиты разума"), "Кнопка называет причину отказа.")
	REMOVE_TRAIT(recruit, TRAIT_MINDSHIELD, REF(src))
	antag_training_console_act(session, console, "program_option", list("option" = "Индукция учебной цели"))
	var/datum/antagonist/gang/training/recruited = recruit.mind.has_antag_datum(/datum/antagonist/gang)
	TEST_ASSERT(istype(recruited), "Учебная цель получает учебный датум банды.")
	TEST_ASSERT(recruited.my_gang == team && (recruit.mind in team.members), "Принятая цель - в учебной семье бандита.")
	TEST_ASSERT(recruited.family_type == gangster.family_type && recruited.gang_name == gangster.gang_name, "Принятая цель - из той же семьи.")
	TEST_ASSERT(!body.has_status_effect(STATUS_EFFECT_HANDSHAKE), "Рукопожатие израсходовано.")

	var/obj/item/gangster_cellphone/antag_training/phone = gangster.phone_ref?.resolve()
	var/obj/item/gangster_cellphone/antag_training/recruit_phone = recruited.phone_ref?.resolve()
	TEST_ASSERT(istype(phone) && istype(recruit_phone) && get_turf(recruit_phone) == get_turf(recruit) && recruit_phone.gang_id == phone.gang_id, "Принятая цель получает телефон учебной линии.")
	var/mob/living/carbon/human/station_listener = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/gangster_cellphone/station_phone = allocate(/obj/item/gangster_cellphone, run_loc_floor_bottom_left)
	station_phone.gang_id = gangster.gang_name

	body.drop_all_held_items()
	body.put_in_active_hand(phone)
	phone.attack_self(body)
	GLOB.unit_test_chat_capture = list()
	body.say("gang-line-probe")
	TEST_ASSERT(heard(recruit, "gang-line-probe"), "Телефон учебной линии передаёт речь члену семьи.")
	TEST_ASSERT(!heard(station_listener, "gang-line-probe"), "Телефон настоящей семьи учебную линию не слышит.")
	station_phone.broadcast_message("station-line-probe", station_listener)
	TEST_ASSERT(heard(station_listener, "station-line-probe"), "Телефон настоящей семьи слышит свою линию.")
	TEST_ASSERT(!heard(recruit, "station-line-probe"), "Учебная линия не слышит настоящую семью.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(gangster, 1 MINUTES), "Выход снимает роль бандита.")
	TEST_ASSERT(QDELETED(team) && QDELETED(recruited), "Учебная семья и принятые снимаются вместе с бандитом.")

/datum/unit_test/antag_training_gang_induction/proc/heard(mob/listener, marker)
	for(var/list/entry as anything in GLOB.unit_test_chat_capture)
		var/target = entry[1]
		if((target == listener || (islist(target) && (listener in target))) && findtext(entry[2], marker))
			return TRUE
	return FALSE

/datum/unit_test/antag_training_gang_induction/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Баллон из кнопки «Новый баллон» ставит метку семьи на стене станционного макета.
/datum/unit_test/antag_training_gang_tag/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/gang)
	TEST_ASSERT(session.prepare(), "Полигон готовит бандита.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/datum/antag_training_program/antag/gang/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/gang/training/gangster = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")

	var/turf/closed/wall/wall
	for(var/turf/closed/wall/candidate in station.turfs)
		if(!istype(get_area(candidate), station.area_type))
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/open/floor/spot = get_step(candidate, direction)
			if(istype(spot) && istype(get_area(spot), station.area_type) && !spot.is_blocked_turf(exclude_mobs = FALSE))
				body.forceMove(spot)
				wall = candidate
				break
		if(wall)
			break
	TEST_ASSERT(wall && body.Adjacent(wall), "Бандит стоит у стены макета.")

	body.drop_all_held_items()
	antag_training_console_act(session, console, "program_option", list("option" = "Новый баллон"))
	var/obj/item/toy/crayon/spraycan/can = body.get_active_held_item()
	TEST_ASSERT(istype(can), "Кнопка выдаёт баллон в руки.")
	can.AltClick(body)
	TEST_ASSERT(!can.is_capped, "Колпачок снимается.")
	can.afterattack(wall, body, TRUE, null)
	var/obj/effect/decal/cleanable/crayon/gang/tag = locate() in wall
	TEST_ASSERT(istype(tag), "Метка семьи встаёт на стене макета.")
	TEST_ASSERT(tag.my_gang == gangster.my_gang && tag.icon_state == "[gangster.gang_id]_tag", "Метка - учебной семьи бандита.")

	var/datum/team/gang/training/old_team = gangster.my_gang
	var/next_family = program.choice == /datum/antagonist/gang/saints ? /datum/antagonist/gang/yakuza : /datum/antagonist/gang/saints
	antag_training_console_act(session, console, "program_option", list("option" = program.choice_option(next_family)))
	TEST_ASSERT(QDELETED(old_team) && QDELETED(tag), "Смена семьи убирает прежнюю семью и её метки.")
	for(var/obj/effect/decal/cleanable/crayon/gang/left_tag as anything in GLOB.gang_tags)
		TEST_ASSERT(left_tag.my_gang != old_team, "Ни одна метка не держит прежнюю семью.")

/// Стены станционного макета со свободной клеткой пола рядом: list(стена, пол) на каждую.
/datum/unit_test/proc/antag_training_gang_walls(datum/antag_training_sector/station, count)
	. = list()
	var/list/used = list()
	for(var/turf/closed/wall/candidate in station.turfs)
		if(!istype(get_area(candidate), station.area_type))
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/open/floor/spot = get_step(candidate, direction)
			if(istype(spot) && !(spot in used) && istype(get_area(spot), station.area_type) && !spot.is_blocked_turf(exclude_mobs = FALSE))
				. += list(list(candidate, spot))
				used += spot
				break
		if(length(.) >= count)
			return

/// Бандит встаёт у стены, берёт баллон кнопкой «Новый баллон» и распыляет метку на стену.
/datum/unit_test/proc/antag_training_gang_spray(datum/antag_training_session/session, datum/tgui/console, list/wall_spot)
	var/mob/living/carbon/human/body = session.current_body
	body.forceMove(wall_spot[2])
	body.drop_all_held_items()
	session.next_supply_at = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Новый баллон"))
	var/obj/item/toy/crayon/spraycan/can = body.get_active_held_item()
	if(!istype(can))
		return null
	if(can.is_capped)
		can.AltClick(body)
	can.afterattack(wall_spot[1], body, TRUE, null)
	return locate(/obj/effect/decal/cleanable/crayon/gang) in wall_spot[1]

/// Бандит принимает цель упражнения: цель вплотную, рукопожатие и кнопка индукции.
/datum/unit_test/proc/antag_training_gang_induct(datum/antag_training_session/session, datum/tgui/console, mob/living/carbon/human/recruit)
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antag_training_program/antag/gang/program = session.program
	var/datum/antagonist/gang/training/gangster = program.role(session)
	if(!body.Adjacent(recruit))
		for(var/direction in GLOB.cardinals)
			var/turf/open/floor/spot = get_step(body, direction)
			if(istype(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE))
				recruit.forceMove(spot)
				break
	body.drop_all_held_items()
	gangster.package_spawner.StartCooldownSelf(0)
	gangster.package_spawner.Trigger()
	antag_training_console_act(session, console, "program_option", list("option" = "Индукция учебной цели"))

/// «Вербовка и метка»: форма семьи на теле, приём цели кнопкой индукции и метка баллоном в макете засчитываются по шагам; прежние свои метки шаг убирает, чужую показывает маяком; смерть цели до приёма проваливает упражнение.
/datum/unit_test/antag_training_gang_exercise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/gang)
	TEST_ASSERT(session.prepare(), "Полигон готовит бандита.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_program/antag/gang/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/gang/training/gangster = program.role(session)
	TEST_ASSERT(findtext(gangster.briefing(), "Вербовка и метка"), "Приветствие называет упражнение.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/datum/antag_training_sector/station = enter_training_sector(session, console, "station")
	TEST_ASSERT_EQUAL(arena.match_zone(body), "station", "Бандит в станционном макете.")
	var/list/walls = antag_training_gang_walls(station, 3)
	TEST_ASSERT_EQUAL(length(walls), 3, "В макете есть три стены со свободным полом рядом.")
	var/obj/effect/decal/cleanable/crayon/gang/old_tag = antag_training_gang_spray(session, console, walls[1])
	TEST_ASSERT(old_tag?.my_gang == gangster.my_gang, "Метка своей семьи до упражнения стоит в макете.")

	var/datum/antag_training_exercise_run/run = start_training_drill(session, console, "gang_recruit")
	TEST_ASSERT(run && !run.ended, "Упражнение банды стартует в макете.")
	var/mob/living/carbon/human/recruit = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(recruit?.mind && (recruit.mind in arena.target_minds), "Цель упражнения - учебный манекен.")

	var/obj/item/clothing/under/family_uniform
	for(var/obj/item/clothing/under/candidate in body.GetAllContents())
		if(candidate != body.w_uniform && (candidate.type in gangster.free_clothes))
			family_uniform = candidate
	TEST_ASSERT_NOTNULL(family_uniform, "Форма семьи лежит в вещах бандита.")
	TEST_ASSERT(!wait_for_drill_step(run, 2, 2 SECONDS), "Форма в рюкзаке шаг не засчитывает.")
	body.drop_all_held_items()
	TEST_ASSERT(body.dropItemToGround(body.w_uniform), "Бандит снимает свой комбинезон.")
	TEST_ASSERT(body.put_in_active_hand(family_uniform) && body.equip_to_slot_if_possible(family_uniform, ITEM_SLOT_ICLOTHING), "Бандит надевает форму семьи.")
	TEST_ASSERT(wait_for_drill_step(run, 2), "Форма семьи на теле засчитана: [run.result_text]")

	var/turf/open/floor/far_spot
	for(var/turf/open/floor/spot in station.turfs)
		if(get_dist(spot, body) >= 3 && istype(get_area(spot), station.area_type) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			far_spot = spot
			break
	TEST_ASSERT_NOTNULL(far_spot, "В макете есть место вдали от бандита.")
	recruit.forceMove(far_spot)
	var/targets_before = length(arena.targets)
	GLOB.unit_test_chat_capture = list()
	antag_training_console_act(session, console, "program_option", list("option" = "Индукция учебной цели"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before, "Во время упражнения кнопка индукции не ставит новую цель.")
	TEST_ASSERT(antag_training_heard(body, "подойдите вплотную к его цели"), "Кнопка ведёт к цели упражнения.")
	antag_training_gang_induct(session, console, recruit)
	TEST_ASSERT(wait_for_drill_step(run, 3), "Приём цели засчитан: [run.result_text]")
	var/datum/antagonist/gang/training/recruited = recruit.mind.has_antag_datum(/datum/antagonist/gang/training)
	TEST_ASSERT(recruited?.my_gang == gangster.my_gang, "Цель - в семье бандита.")

	TEST_ASSERT(QDELETED(old_tag), "Шаг метки убирает прежнюю метку своей семьи в макете.")
	var/obj/effect/decal/cleanable/crayon/gang/counted = antag_training_gang_spray(session, console, walls[2])
	TEST_ASSERT(istype(counted), "Метка встаёт на свободной стене макета.")
	TEST_ASSERT(wait_for_drill_step(run, 4) && run.ended && run.success, "Метка семьи в макете завершает упражнение: [run.result_text]")
	TEST_ASSERT(counted in run.props, "Засчитанная метка уходит вместе с прогоном.")

	var/datum/antag_training_session/rival = allocate_training_session(/datum/antag_training_program/antag/gang)
	TEST_ASSERT(rival.prepare(arena), "Второй бандит входит на тот же полигон.")
	var/datum/tgui/rival_console = allocate(/datum/tgui, rival.current_body, rival, "AntagTraining")
	enter_training_sector(rival, rival_console, "station")
	run = start_training_drill(session, console, "gang_recruit")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается заново.")
	TEST_ASSERT(QDELETED(counted), "Метка прошлого прогона убрана.")
	var/obj/effect/decal/cleanable/crayon/gang/foreign = antag_training_gang_spray(rival, rival_console, walls[3])
	TEST_ASSERT(foreign && foreign.my_gang != gangster.my_gang, "Другой бандит ставит метку своей семьи в макете.")
	TEST_ASSERT(wait_for_drill_step(run, 2), "Форма семьи уже надета: [run.result_text]")
	antag_training_gang_induct(session, console, run.find_prop(/mob/living/carbon/human))
	TEST_ASSERT(wait_for_drill_step(run, 3), "Новая цель принята: [run.result_text]")
	var/obj/effect/antag_training_beacon/lit/beacon = run.find_prop(/obj/effect/antag_training_beacon/lit)
	TEST_ASSERT(beacon && get_turf(beacon) == walls[3][1], "Над чужой меткой горит маяк.")
	var/datum/antag_training_exercise_step/tag_step = run.current_step()
	TEST_ASSERT(findtext(tag_step.hint, "другой семьи") && findtext(tag_step.hint, "маяк"), "Подсказка шага говорит, где чужая метка: [tag_step.hint]")
	TEST_ASSERT_NULL(antag_training_gang_spray(session, console, walls[2]), "Мимо чужой метки новая не встаёт.")
	var/obj/effect/decal/cleanable/crayon/gang/over = antag_training_gang_spray(session, console, walls[3])
	TEST_ASSERT(over?.my_gang == gangster.my_gang, "Метка ложится поверх чужой.")
	TEST_ASSERT(wait_for_drill_step(run, 4) && run.ended && run.success, "Метка поверх чужой завершает упражнение: [run.result_text]")

	run = start_training_drill(session, console, "gang_recruit")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается в третий раз.")
	recruit = run.find_prop(/mob/living/carbon/human)
	recruit.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "раньше, чем вы приняли её"), "Смерть цели до приёма проваливает упражнение: [run.result_text]")

/datum/unit_test/antag_training_gang_exercise/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()
