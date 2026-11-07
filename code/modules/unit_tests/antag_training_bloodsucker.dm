/datum/unit_test/proc/antag_training_bloodsucker_session()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/bloodsucker)
	if(!session.prepare())
		return null
	var/datum/antag_training_sector/dark = session.arena.sectors["dark"]
	if(!wait_for_var(dark, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS))
		return null
	var/list/budget = new_wait_budget(5 SECONDS, "участник в тёмном секторе")
	while(!session.arena.inside_bounds(get_turf(session.current_body), dark.bounds))
		if(!wait_budget_tick(budget))
			return null
	return session

/// Программа выдаёт учебного кровососа без списка кровососов режима и солнца раунда; кровь пополняется, повышение растит поколение и открывает выбранную силу.
/datum/unit_test/antag_training_bloodsucker_setup/Run()
	var/bloodsuckers_before = length(SSticker.mode.bloodsuckers)
	var/obj/effect/sunlight/sun_before = SSticker.mode.bloodsucker_sunlight
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/bloodsucker)
	TEST_ASSERT(session.prepare(), "Полигон готовит кровососа.")
	var/datum/antag_training_program/antag/bloodsucker/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/bloodsucker/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Кукла получает учебного кровососа.")
	TEST_ASSERT(!(role.owner in SSticker.mode.bloodsuckers) && length(SSticker.mode.bloodsuckers) == bloodsuckers_before, "Учебный кровосос не записан в кровососы режима.")
	TEST_ASSERT_EQUAL(SSticker.mode.bloodsucker_sunlight, sun_before, "Солнце раунда не создаётся.")
	TEST_ASSERT(locate(/datum/action/cooldown/bloodsucker/feed) in role.powers, "Feed выдан сразу.")
	TEST_ASSERT(!length(role.objectives), "Целей раунда у учебного кровососа нет.")
	var/datum/action/cooldown/bloodsucker/fortitude = /datum/action/cooldown/bloodsucker/fortitude
	var/fortitude_option = "Сила при повышении: [initial(fortitude.name)]"
	TEST_ASSERT(fortitude_option in program.options, "Пульт предлагает ещё не открытую силу.")
	TEST_ASSERT(!("Сила при повышении: Feed" in program.options), "Пульт не предлагает уже открытую силу.")
	var/list/data = session.ui_data(body)
	TEST_ASSERT_EQUAL(copytext(json_encode(data["options"]), 1, 2), "\[", "Кнопки роли уходят в пульт массивом, а не объектом.")
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	body.blood_volume = BLOOD_VOLUME_BAD
	antag_training_console_act(session, console, "program_option", list("option" = "Пополнить кровь"))
	TEST_ASSERT_EQUAL(round(body.blood_volume), role.max_blood_volume, "«Пополнить кровь» доводит кровь до максимума.")

	var/level_before = role.bloodsucker_level || 0
	var/blood_before = body.blood_volume
	var/cost = role.max_blood_volume * BLOODSUCKER_RANK_BLOOD_SHARE
	antag_training_console_act(session, console, "program_option", list("option" = fortitude_option))
	antag_training_console_act(session, console, "program_option", list("option" = "Повысить уровень"))
	TEST_ASSERT_EQUAL(role.bloodsucker_level, level_before + 1, "«Повысить уровень» растит поколение.")
	var/datum/action/cooldown/bloodsucker/fortitude/learned = locate() in role.powers
	TEST_ASSERT(learned && learned.owner == body, "Повышение открывает выбранную силу.")
	TEST_ASSERT(abs(body.blood_volume - (blood_before - cost)) < 1, "Повышение стоит доли максимума крови.")
	TEST_ASSERT(!(fortitude_option in program.options), "Открытая сила уходит из выбора.")
	TEST_ASSERT(!(role.owner in SSticker.mode.bloodsuckers), "После повышения кровосос по-прежнему вне режима.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(role, 1 MINUTES), "Роль снимается с сессией.")
	TEST_ASSERT_EQUAL(length(SSticker.mode.bloodsuckers), bloodsuckers_before, "После выхода список кровососов режима прежний.")
	TEST_ASSERT_EQUAL(SSticker.mode.bloodsucker_sunlight, sun_before, "После выхода солнце раунда прежнее.")

/// Feed у схваченной учебной цели в тёмном секторе пьёт её кровь и пополняет кровь кровососа.
/datum/unit_test/antag_training_bloodsucker_feed/Run()
	var/datum/antag_training_session/session = antag_training_bloodsucker_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит кровососа в тёмном секторе.")
	var/datum/antag_training_program/antag/bloodsucker/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/bloodsucker/training/role = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для кормления"))
	var/mob/living/carbon/human/prey = program.recent_target(session)
	TEST_ASSERT(prey && (prey.mind in session.arena.target_minds), "Учебная цель для кормления появилась.")
	TEST_ASSERT(get_dist(prey, body) <= 1, "Цель стоит рядом с кровососом.")
	prey.grabbedby(body)
	prey.grabbedby(body)
	TEST_ASSERT(body.pulling == prey && body.grab_state >= GRAB_AGGRESSIVE, "Кровосос держит цель агрессивным захватом.")
	body.blood_volume = BLOOD_VOLUME_BAD
	var/prey_blood = prey.blood_volume
	var/datum/action/cooldown/bloodsucker/feed/feed = locate() in role.powers
	var/list/feeding = list()
	INVOKE_ASYNC(src, PROC_REF(feed_until_stopped), feed, feeding)
	var/list/budget = new_wait_budget(20 SECONDS, "кровь кровососа растёт")
	while(body.blood_volume <= BLOOD_VOLUME_BAD + 1)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(body.blood_volume > BLOOD_VOLUME_BAD + 1, "Feed пополняет кровь кровососа.")
	TEST_ASSERT(prey.blood_volume < prey_blood, "Feed пьёт кровь цели.")
	feed.Trigger()
	budget = new_wait_budget(5 SECONDS, "кормление закончилось")
	while(!length(feeding))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(length(feeding) && !role.poweron_feed, "Повторное нажатие Feed прекращает кормление.")

/datum/unit_test/antag_training_bloodsucker_feed/proc/feed_until_stopped(datum/action/cooldown/bloodsucker/feed/feed, list/feeding)
	feed.Trigger()
	feeding += TRUE

/// Гроб в тёмном секторе становится логовом, когда кровосос закрывает его, лёжа внутри; на дыбе учебная цель получает учебного вассала, не попадая в списки режима.
/datum/unit_test/antag_training_bloodsucker_lair_vassal/Run()
	var/vassals_before = length(SSticker.mode.vassals)
	var/datum/antag_training_session/session = antag_training_bloodsucker_session()
	TEST_ASSERT_NOTNULL(session, "Полигон готовит кровососа в тёмном секторе.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/dark = arena.sectors["dark"]
	var/datum/antag_training_program/antag/bloodsucker/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/bloodsucker/training/role = program.role(session)
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Повысить уровень"))
	TEST_ASSERT(role.bloodsucker_level >= 1, "Поколения хватает на вассала.")

	antag_training_console_act(session, console, "program_option", list("option" = "Гроб и дыба"))
	var/obj/structure/closet/crate/coffin/coffin = role.training_coffin_ref?.resolve()
	var/obj/structure/bloodsucker/vassalrack/rack = role.training_rack_ref?.resolve()
	TEST_ASSERT(coffin && rack, "Гроб и дыба поставлены.")
	TEST_ASSERT(arena.inside_bounds(get_turf(coffin), dark.bounds) && arena.inside_bounds(get_turf(rack), dark.bounds), "Гроб и дыба - в тёмном секторе.")
	TEST_ASSERT(rack.anchored && rack.owner == body, "Дыба закреплена за кровососом.")
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для кормления"))
	var/mob/living/carbon/human/prey = program.recent_target(session)
	TEST_ASSERT_NOTNULL(prey, "Учебная цель появилась.")

	coffin.attack_hand(body)
	TEST_ASSERT(coffin.opened, "Гроб открывается.")
	body.forceMove(get_turf(coffin))
	body.set_resting(TRUE, TRUE)
	coffin.attack_hand(body)
	TEST_ASSERT(!coffin.opened && (body in coffin), "Кровосос лежит в закрытом гробу.")
	TEST_ASSERT(role.coffin == coffin && coffin.resident == body, "Гроб занят.")
	TEST_ASSERT_EQUAL(role.lair, get_area(coffin), "Тёмный сектор стал логовом.")
	coffin.open(body)
	body.set_resting(FALSE, TRUE)
	TEST_ASSERT(!(body in coffin), "Кровосос выходит из гроба.")

	session.next_supply_at = 0
	antag_training_console_act(session, console, "equipment", list("id" = "knife"))
	var/obj/item/kitchen/knife/combat/knife = locate() in get_turf(body)
	TEST_ASSERT(knife && body.put_in_hands(knife), "Кровосос берёт нож.")
	prey.forceMove(get_turf(rack))
	rack.MouseDrop_T(prey, body)
	TEST_ASSERT_EQUAL(prey.buckled, rack, "Цель закреплена на дыбе.")
	for(var/step in 1 to 4)
		TEST_ASSERT(rack_click(rack, knife, body), "Пытка [step] заканчивается.")
	TEST_ASSERT_EQUAL(rack.convert_progress, 0, "Цель готова к ритуалу крови.")
	TEST_ASSERT(rack_click(rack, knife, body), "Ритуал крови заканчивается.")
	var/datum/antagonist/vassal/training/vassal = prey.mind.has_antag_datum(/datum/antagonist/vassal/training)
	TEST_ASSERT(istype(vassal), "Ритуал на дыбе делает цель учебным вассалом.")
	TEST_ASSERT(vassal.master == role && (vassal in role.vassals), "Вассал служит учебному кровососу.")
	TEST_ASSERT(!(prey.mind in SSticker.mode.vassals) && length(SSticker.mode.vassals) == vassals_before, "Учебный вассал не записан в вассалы режима.")
	TEST_ASSERT(vassal.soft_antag && !vassal.show_in_roundend && !vassal.show_in_antagpanel && !vassal.show_to_ghosts && !vassal.threat(), "Учебный вассал скрыт от раунда.")

	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	outsider.mind_initialize()
	allocated += outsider.mind
	TEST_ASSERT(!SSticker.mode.can_make_vassal(outsider, role.owner, FALSE), "Человек без игрока вне полигона вассалом не становится.")
	var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(guest.prepare(arena), "Второй участник входит на ту же арену.")
	TEST_ASSERT(!SSticker.mode.can_make_vassal(guest.current_body, role.owner, FALSE), "Участник другой сессии вассалом не становится.")
	var/mob/living/carbon/human/shared = arena.spawn_creature("human", "laboratory")
	TEST_ASSERT(shared && !SSticker.mode.can_make_vassal(shared, role.owner, FALSE), "Общая цель, созданная не пультом кровососа, вассалом не становится.")
	qdel(guest)

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(role, 1 MINUTES), "Роль снимается с сессией.")
	TEST_ASSERT(QDELETED(vassal), "Выход снимает вассала.")
	TEST_ASSERT(QDELETED(coffin) && QDELETED(rack), "Выход убирает гроб и дыбу.")
	TEST_ASSERT_EQUAL(length(SSticker.mode.vassals), vassals_before, "После выхода список вассалов режима прежний.")
	TEST_ASSERT(wait_for_qdeleted(prey, 1 MINUTES), "Учебная цель уходит с полигоном.")
	// Кэш последнего view() держит атомы до следующего вызова, а в тихом тестовом мире его больше никто не зовёт.
	qdel(outsider)
	pass(view(0, run_loc_floor_bottom_left))

/datum/unit_test/antag_training_bloodsucker_lair_vassal/proc/rack_click(obj/structure/bloodsucker/vassalrack/rack, obj/item/tool, mob/living/user)
	rack.attackby(tool, user)
	var/list/budget = new_wait_budget(20 SECONDS, "дыба освободилась")
	while(rack.useLock)
		if(!wait_budget_tick(budget))
			return FALSE
	return TRUE
