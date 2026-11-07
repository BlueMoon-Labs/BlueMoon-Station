/datum/unit_test/proc/antag_training_spellbook_index(obj/item/spellbook/book, entry_type)
	for(var/index in 1 to length(book.entries))
		var/datum/spellbook_entry/entry = book.entries[index]
		if(entry.type == entry_type)
			return index
	return 0

/datum/unit_test/proc/antag_training_spellbook_act(obj/item/spellbook/book, mob/living/user, action, index)
	usr = user
	book.Topic("[action]=[index]", list("[action]" = "[index]"))
	usr = null

/datum/unit_test/proc/antag_training_spells_learned()
	. = 0
	for(var/datum/feedback_variable/feedback as anything in SSblackbox.feedback)
		if(feedback.key != "wizard_spell_learned")
			continue
		var/list/tally = feedback.json["data"]
		for(var/spell_name in tally)
			. += tally[spell_name]

/obj/item/teleportation_scroll/training/probe
	var/answer
	var/list/offered

/obj/item/teleportation_scroll/training/probe/pick_destination(mob/user, list/destinations)
	offered = destinations.Copy()
	return answer

/// Программа мага выдаёт учебного мага на полигоне без переименования, логова и ожидания ответа, не записывая его в маги режима; книга без ритуалов и предметов, зовущих призраков.
/datum/unit_test/antag_training_wizard_setup/Run()
	var/wizards_before = length(SSticker.mode.wizards)
	var/datum/preferences/preferences = new
	allocated += preferences
	preferences.real_name = "Training Wizard"
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/wizard, preferences)
	TEST_ASSERT(session.prepare(), "Полигон готовит мага.")
	var/datum/antag_training_program/antag/wizard/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/wizard/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Кукла получает учебного мага.")
	TEST_ASSERT(session.arena.owns_area(get_area(body)), "Маг остаётся на полигоне, а не в логове.")
	TEST_ASSERT_EQUAL(length(SSticker.mode.wizards), wizards_before, "Учебный маг не записан в маги режима.")
	TEST_ASSERT(!length(role.objectives), "Целей раунда у учебного мага нет.")
	sleep(2)
	TEST_ASSERT_EQUAL(body.real_name, "Training Wizard", "Маг не переименован.")
	var/obj/item/spellbook/training/book = locate() in body.held_items
	TEST_ASSERT(book && book.owner == body, "В руке учебная книга, привязанная к магу.")
	TEST_ASSERT(locate(/obj/item/teleportation_scroll/training) in body.GetAllContents(), "При маге учебный свиток телепортации.")

	var/list/closed_types = list(/datum/spellbook_entry/summon/guns, /datum/spellbook_entry/summon/magic, /datum/spellbook_entry/summon/events, /datum/spellbook_entry/summon/ghosts, /datum/spellbook_entry/item/contract, /datum/spellbook_entry/item/guardian, /datum/spellbook_entry/item/soulstones, /datum/spellbook_entry/item/scryingorb, /datum/spellbook_entry/item/warpwhistle, /datum/spellbook_entry/item/bloodbottle, /datum/spellbook_entry/item/hugbottle, /datum/spellbook_entry/summon/curse_of_madness, /datum/spellbook_entry/alive_bones, /datum/spellbook_entry/lichdom, /datum/spellbook_entry/item/staffnuclear, /datum/spellbook_entry/item/staffchange, /datum/spellbook_entry/item/staffchaos, /datum/spellbook_entry/item/wands)
	for(var/closed_type in closed_types)
		TEST_ASSERT(antag_training_spellbook_closed(closed_type), "[closed_type] закрыт на полигоне.")
		TEST_ASSERT(!antag_training_spellbook_index(book, closed_type), "[closed_type] нет в учебной книге.")
	TEST_ASSERT(antag_training_spellbook_index(book, /datum/spellbook_entry/fireball), "Огненный шар в учебной книге есть.")
	var/datum/spellbook_entry/teleport = book.entries[antag_training_spellbook_index(book, /datum/spellbook_entry/teleport)]
	TEST_ASSERT_EQUAL(teleport?.spell_type, /obj/effect/proc_holder/spell/targeted/area_teleport/teleport/training, "Телепорт книги - учебный, по зонам полигона.")

	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")
	session.avatar_mind.remove_antag_datum(/datum/antagonist/wizard/training)
	var/granted_at = world.time
	TEST_ASSERT(program.grant_role(session), "Роль выдаётся снова.")
	TEST_ASSERT_EQUAL(world.time, granted_at, "Выдача роли не ждёт ответа игрока.")
	TEST_ASSERT_EQUAL(length(SSticker.mode.wizards), wizards_before, "Повторная выдача не трогает магов режима.")

/// Учебная книга учит огненный шар покупкой из книги, возвращает очки за заклинание на полигоне и не пишет статистику раунда; «Пополнить очки» доводит счёт до полного.
/datum/unit_test/antag_training_wizard_spellbook/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/wizard)
	TEST_ASSERT(session.prepare(), "Полигон готовит мага.")
	var/datum/antag_training_program/antag/wizard/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/wizard/training/role = program.role(session)
	var/obj/item/spellbook/training/book = locate() in body.held_items
	var/full_points = book.uses
	TEST_ASSERT(!SSblackbox.sealed, "Статистика раунда пишется.")
	var/learned_before = antag_training_spells_learned()

	var/fireball_index = antag_training_spellbook_index(book, /datum/spellbook_entry/fireball)
	var/datum/spellbook_entry/fireball = book.entries[fireball_index]
	antag_training_spellbook_act(book, body, "buy", fireball_index)
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/aimed/fireball) in body.mind.spell_list, "Маг выучил огненный шар.")
	TEST_ASSERT_EQUAL(book.uses, full_points - fireball.cost, "Покупка списывает очки.")
	TEST_ASSERT_EQUAL(antag_training_spells_learned(), learned_before, "Учебная покупка не пишет статистику раунда.")

	antag_training_spellbook_act(book, body, "refund", fireball_index)
	TEST_ASSERT_EQUAL(book.uses, full_points, "Возврат заклинания на полигоне отдаёт очки.")
	TEST_ASSERT_NULL(locate(/obj/effect/proc_holder/spell/aimed/fireball) in body.mind.spell_list, "Возвращённое заклинание забыто.")

	var/armour_index = antag_training_spellbook_index(book, /datum/spellbook_entry/item/battlemage)
	var/datum/spellbook_entry/armour = book.entries[armour_index]
	antag_training_spellbook_act(book, body, "buy", fireball_index)
	antag_training_spellbook_act(book, body, "buy", armour_index)
	TEST_ASSERT_EQUAL(book.uses, full_points - fireball.cost - armour.cost, "Две покупки списали очки.")
	TEST_ASSERT_EQUAL(armour.limit, 0, "Броня боевого мага продаётся один раз.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить очки"))
	TEST_ASSERT_EQUAL(book.uses, full_points, "«Пополнить очки» возвращает полный счёт.")
	TEST_ASSERT_EQUAL(armour.limit, initial(armour.limit), "«Пополнить очки» возвращает разовые покупки.")
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/aimed/fireball) in body.mind.spell_list, "Выученное остаётся после пополнения.")
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(role, 1 MINUTES) && QDELETED(book), "Выход снимает роль и книгу.")

/// Учебный свиток предлагает только зоны полигона и переносит в выбранную; пульт выдаёт новый свиток и манекен для заклинаний.
/datum/unit_test/antag_training_wizard_scroll/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/wizard)
	TEST_ASSERT(session.prepare(), "Полигон готовит мага.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/body = session.current_body
	body.drop_all_held_items()
	var/obj/item/teleportation_scroll/training/probe/scroll = allocate(/obj/item/teleportation_scroll/training/probe, get_turf(body))
	TEST_ASSERT(body.put_in_hands(scroll), "Маг берёт свиток.")
	scroll.answer = arena.zones["range"]["name"]
	var/uses = scroll.uses
	usr = body
	scroll.Topic("spell_teleport=1", list("spell_teleport" = "1"))
	usr = null
	var/list/zone_names = list()
	for(var/zone_id in arena.zones)
		zone_names += arena.zones[zone_id]["name"]
	TEST_ASSERT_EQUAL(length(scroll.offered), length(zone_names), "Свиток предлагает столько мест, сколько зон у полигона.")
	for(var/place in scroll.offered)
		TEST_ASSERT(place in zone_names, "«[place]» - зона полигона.")
	TEST_ASSERT(arena.inside_bounds(get_turf(body), arena.zones["range"]["bounds"]), "Свиток переносит в выбранную зону.")
	TEST_ASSERT_EQUAL(scroll.uses, uses - 1, "Перенос тратит заряд свитка.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	body.drop_all_held_items()
	antag_training_console_act(session, console, "program_option", list("option" = "Новый свиток"))
	var/obj/item/teleportation_scroll/training/fresh = locate() in body.held_items
	TEST_ASSERT(fresh && fresh != scroll && arena.owns_area(get_area(fresh)), "Пульт выдаёт новый учебный свиток в руки.")
	var/targets_before = length(arena.targets)
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для заклинаний"))
	TEST_ASSERT_EQUAL(length(arena.targets), targets_before + 1, "Пульт ставит манекен для заклинаний.")
	var/mob/living/carbon/human/dummy = arena.targets[length(arena.targets)]
	TEST_ASSERT(ishuman(dummy) && (dummy.mind in arena.target_minds), "Манекен - учебная цель с разумом.")
	TEST_ASSERT(arena.inside_bounds(get_turf(dummy), arena.zones["range"]["bounds"]), "Манекен встаёт в зоне мага.")

/// Учебная форма стержня, пущенная к краю арены, отпускает мага на полигоне без бессмертия, хотя стержень упирается в изоляцию раньше своей дальности.
/datum/unit_test/antag_training_wizard_rod_form/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/wizard)
	TEST_ASSERT(session.prepare(), "Полигон готовит мага.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/spellbook/training/book = locate() in body.held_items
	antag_training_spellbook_act(book, body, "buy", antag_training_spellbook_index(book, /datum/spellbook_entry/rod_form))
	var/obj/effect/proc_holder/spell/targeted/rod_form/training/rod_form = locate() in body.mind.spell_list
	TEST_ASSERT_NOTNULL(rod_form, "Книга учит учебную форму стержня.")
	TEST_ASSERT(findtext(rod_form.action.desc, "На полигоне"), "Кнопка заклинания называет срок стержня на полигоне.")
	var/turf/center = arena.zones["hub"]["spawn"]
	body.forceMove(locate(ANTAG_TRAINING_SIZE - 4, center.y, center.z))
	body.setDir(EAST)
	usr = body
	rod_form.action.Trigger()
	usr = null
	var/obj/effect/immovablerod/wizard/rod = body.loc
	TEST_ASSERT(istype(rod), "Маг стал стержнем.")
	TEST_ASSERT(wait_for_qdeleted(rod, 10 SECONDS), "Стержень у края арены распадается.")
	TEST_ASSERT(isturf(body.loc) && arena.owns_area(get_area(body)), "Маг свободен и остался на полигоне.")
	TEST_ASSERT(!(body.status_flags & GODMODE) && !body.mob_transforming, "Маг снова уязвим и может действовать.")

/// «Книга и огненный шар»: покупка огненного шара в книге и крит цели от его снарядов засчитываются по шагам; предмет и заклинание без снаряда шаг не засчитывают, снаряд посоха не идёт в зачёт, цель, сваленная до покупки или не заклинанием, проваливает упражнение; «Что дальше» ведёт по шагу упражнения раньше целей роли.
/datum/unit_test/antag_training_wizard_exercise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/wizard)
	TEST_ASSERT(session.prepare(), "Полигон готовит мага.")
	var/datum/antag_training_program/antag/wizard/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/wizard/training/role = program.role(session)
	TEST_ASSERT(findtext(role.briefing(), "Книга и огненный шар"), "Приветствие называет упражнение.")
	var/obj/item/spellbook/training/book = locate() in body.held_items
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "move", list("zone" = "range"))
	TEST_ASSERT_EQUAL(arena.match_zone(body), "range", "Маг в тире.")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, console, "wizard_fireball")
	TEST_ASSERT(run && !run.ended, "Упражнение мага стартует в тире.")
	var/mob/living/carbon/human/dummy = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(dummy?.mind && (dummy.mind in arena.target_minds), "Цель упражнения - учебный манекен.")
	TEST_ASSERT(arena.inside_bounds(get_turf(dummy), arena.zones["range"]["bounds"]), "Цель стоит в тире.")

	goal = new
	goal.explanation_text = "Учебная проверка: цель роли."
	role.objectives += goal
	var/list/console_data = session.ui_data(body)
	TEST_ASSERT(findtext(console_data["role_next"], "Книга и огненный шар"), "«Что дальше» - сначала шаг идущего упражнения: [console_data["role_next"]]")

	antag_training_spellbook_act(book, body, "buy", antag_training_spellbook_index(book, /datum/spellbook_entry/item/battlemage))
	TEST_ASSERT_EQUAL(run.step_index, 1, "Предмет из книги заклинанием не считается.")
	antag_training_spellbook_act(book, body, "buy", antag_training_spellbook_index(book, /datum/spellbook_entry/blink))
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/targeted/turf_teleport/blink) in body.mind.spell_list, "Маг выучил Blink.")
	TEST_ASSERT_EQUAL(run.step_index, 1, "Заклинание без снаряда шаг не засчитывает.")
	var/fireball_index = antag_training_spellbook_index(book, /datum/spellbook_entry/fireball)
	antag_training_spellbook_act(book, body, "buy", fireball_index)
	TEST_ASSERT_EQUAL(run.step_index, 2, "Покупка огненного шара засчитана.")
	var/obj/effect/proc_holder/spell/aimed/fireball/fireball = locate() in body.mind.spell_list
	TEST_ASSERT_NOTNULL(fireball, "Маг выучил огненный шар.")

	var/turf/open/floor/firing_spot = locate(dummy.x - 4, dummy.y, dummy.z)
	TEST_ASSERT(istype(firing_spot) && !firing_spot.is_blocked_turf(exclude_mobs = FALSE), "Перед целью есть место для броска.")
	body.forceMove(firing_spot)
	body.setDir(EAST)
	for(var/cast in 1 to 6)
		// Наведение шара - перехват клика клиента, он ведёт в тот же perform().
		fireball.perform(list(dummy), FALSE, body)
		if(wait_for_drill_step(run, 3, 4 SECONDS))
			break
	TEST_ASSERT(run.ended && run.success, "Цель в крите от огненного шара завершает упражнение: [run.result_text]")
	TEST_ASSERT(dummy.health <= dummy.crit_threshold, "Цель в крите.")
	console_data = session.ui_data(body)
	TEST_ASSERT_EQUAL(console_data["role_next"], goal.explanation_text, "Без идущего упражнения «Что дальше» - цель роли.")
	role.objectives -= goal

	run = start_training_drill(session, console, "wizard_fireball")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается заново.")
	dummy = run.find_prop(/mob/living/carbon/human)
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить очки"))
	antag_training_spellbook_act(book, body, "buy", fireball_index)
	TEST_ASSERT_EQUAL(run.step_index, 2, "Усиление огненного шара - тоже покупка заклинания.")
	var/blade_index = antag_training_spellbook_index(book, /datum/spellbook_entry/item/spellblade)
	TEST_ASSERT(blade_index, "Spellblade есть в учебной книге.")
	antag_training_spellbook_act(book, body, "buy", blade_index)
	var/obj/item/gun/magic/staff/spellblade/blade = locate() in get_turf(body)
	TEST_ASSERT_NOTNULL(blade, "Книга призывает Spellblade под ноги.")
	body.drop_all_held_items()
	TEST_ASSERT(body.put_in_active_hand(blade), "Маг берёт Spellblade.")
	body.forceMove(locate(dummy.x - 4, dummy.y, dummy.z))
	body.setDir(EAST)
	var/burn_before = dummy.getFireLoss()
	blade.process_fire(dummy, body)
	var/list/budget = new_wait_budget(5 SECONDS, "снаряд Spellblade в цели")
	while(dummy.getFireLoss() <= burn_before && wait_budget_tick(budget))
		continue
	TEST_ASSERT(dummy.getFireLoss() > burn_before, "Снаряд Spellblade попал в цель.")
	dummy.adjustBruteLoss(dummy.maxHealth * 1.5)
	wait_for_drill_step(run, 3, 3 SECONDS)
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "не заклинанием"), "Крит после снаряда посоха - не от заклинания: [run.result_text]")

	run = start_training_drill(session, console, "wizard_fireball")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается в третий раз.")
	dummy = run.find_prop(/mob/living/carbon/human)
	dummy.adjustBruteLoss(dummy.maxHealth * 1.5)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 3 SECONDS) && !run.success && findtext(run.result_text, "раньше, чем вы выучили"), "Цель в крите до покупки заклинания проваливает упражнение понятной причиной: [run.result_text]")

/datum/unit_test/antag_training_wizard_exercise
	var/datum/objective/antag_training/goal

/datum/unit_test/antag_training_wizard_exercise/Destroy()
	QDEL_NULL(goal)
	return ..()
