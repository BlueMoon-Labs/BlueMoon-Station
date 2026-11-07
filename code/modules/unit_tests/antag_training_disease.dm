/datum/unit_test/proc/antag_training_disease_crew()
	var/turf/station_spot = SSmapping.get_station_center()
	TEST_ASSERT(is_station_level(station_spot.z), "Центр станции в тесте - станционный уровень.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, station_spot)
	var/datum/disease/advance/sentient_disease/probe = new
	var/susceptible = crew.CanContractDisease(probe)
	qdel(probe)
	TEST_ASSERT(susceptible, "Человек на станции восприимчив к разумной болезни.")
	return crew

/datum/unit_test/proc/antag_training_disease_hosts(datum/antag_training_session/session, datum/tgui/console)
	antag_training_console_act(session, console, "program_option", list("option" = "Носители"))
	var/list/dummies = list()
	for(var/mob/living/carbon/human/dummy in session.arena.targets)
		if(dummy.training_owner?.resolve() == session)
			dummies += dummy
	return dummies

/datum/unit_test/proc/antag_training_disease_buy(mob/camera/disease/training/camera, datum/disease_ability/ability)
	var/datum/tgui/menu = allocate(/datum/tgui, camera, camera, "SentientDisease")
	menu.status = UI_INTERACTIVE
	usr = camera
	. = camera.ui_act("buy_ability", list("ability" = REF(ability)), menu)
	usr = null

/// Предохранитель: по истечении срока свободного полёта учебная болезнь берёт нулевого пациента только из манекенов полигона, а без них продлевает ожидание, не трогая экипаж станции и не удаляя камеру.
/datum/unit_test/antag_training_disease_patient_zero/Run()
	var/mob/living/carbon/human/crew = antag_training_disease_crew()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(session.prepare(), "Полигон готовит болезнь.")
	var/mob/camera/disease/training/camera = session.current_body
	TEST_ASSERT(istype(camera), "Тело сеанса - камера болезни.")
	TEST_ASSERT(istype(camera.disease_template, /datum/disease/advance/sentient_disease/training), "Шаблон вируса учебный.")
	TEST_ASSERT_EQUAL(camera.training_origin?.resolve(), session.arena, "Камера принадлежит полигону.")

	TEST_ASSERT(camera.arm_freemove(1), "Срок выбора нулевого пациента перезаводится.")
	var/first_deadline = camera.freemove_end
	var/list/budget = new_wait_budget(10 SECONDS, "срок выбора нулевого пациента без манекенов")
	while(camera.freemove_end == first_deadline && wait_budget_tick(budget))
		continue
	TEST_ASSERT_NOTEQUAL(camera.freemove_end, first_deadline, "Без манекенов срок продлевается.")
	TEST_ASSERT(camera.freemove && !QDELETED(camera) && !session.finished, "Без носителей камера и сеанс остаются.")
	TEST_ASSERT(!length(crew.diseases), "Человек на станционном уровне не заражён.")

	var/datum/tgui/console = allocate(/datum/tgui, camera, session, "AntagTraining")
	var/list/dummies = antag_training_disease_hosts(session, console)
	TEST_ASSERT_EQUAL(length(dummies), ANTAG_TRAINING_DISEASE_HOSTS, "Кнопка «Носители» ставит [ANTAG_TRAINING_DISEASE_HOSTS] манекена.")
	var/second_deadline = camera.freemove_end
	TEST_ASSERT(camera.arm_freemove(1), "Срок выбора перезаводится с манекенами на полигоне.")
	budget = new_wait_budget(10 SECONDS, "нулевой пациент по истечении срока")
	while(camera.freemove && camera.freemove_end != second_deadline && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!camera.freemove, "По истечении срока болезнь сама берёт нулевого пациента.")
	TEST_ASSERT_EQUAL(length(camera.disease_instances), 1, "Нулевой пациент один.")
	var/datum/disease/advance/sentient_disease/training/virus = camera.disease_instances[1]
	TEST_ASSERT(virus.affected_mob in dummies, "Нулевой пациент - манекен полигона.")
	TEST_ASSERT(!length(crew.diseases), "Выбор нулевого пациента не задел человека на станции.")
	TEST_ASSERT(!QDELETED(camera) && !session.finished, "Камера и сеанс целы после заражения.")

/// Щелчок по манекену делает его нулевым пациентом, кашель носителя заражает соседний манекен, а излечение последнего возвращает участника в своё тело.
/datum/unit_test/antag_training_disease_spread/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(session.prepare(), "Полигон готовит болезнь.")
	var/mob/camera/disease/training/camera = session.current_body
	var/datum/tgui/console = allocate(/datum/tgui, camera, session, "AntagTraining")
	var/list/dummies = antag_training_disease_hosts(session, console)
	TEST_ASSERT(length(dummies) >= 2, "Для заражения соседа нужно хотя бы два манекена.")
	var/mob/living/carbon/human/zero = dummies[1]
	var/mob/living/carbon/human/neighbour = dummies[2]
	TEST_ASSERT(get_dist(zero, neighbour) <= 2, "Манекены встают рядом: [get_dist(zero, neighbour)] клеток.")

	camera.ClickOn(zero)
	TEST_ASSERT(!camera.freemove, "Щелчок по манекену выбирает нулевого пациента.")
	TEST_ASSERT_NOTNULL(camera.hosts[zero], "Манекен стал носителем.")
	TEST_ASSERT_EQUAL(camera.following_host, zero, "Камера следит за первым носителем.")

	antag_training_console_act(session, console, "program_option", list("option" = "Очки адаптации"))
	TEST_ASSERT_EQUAL(camera.points, ANTAG_TRAINING_DISEASE_POINTS, "Кнопка пульта пополняет очки адаптации.")
	var/datum/disease_ability/symptom/mild/cough/adaptation = locate() in GLOB.disease_ability_singletons
	TEST_ASSERT_NOTNULL(adaptation, "Адаптация кашля есть в списке.")
	antag_training_disease_buy(camera, adaptation)
	TEST_ASSERT(camera.purchased_abilities[adaptation], "Меню адаптации покупает симптом за очки.")
	TEST_ASSERT_EQUAL(camera.points, ANTAG_TRAINING_DISEASE_POINTS - adaptation.cost, "Покупка списывает очки.")
	var/datum/action/cooldown/disease_cough/cough = locate() in camera.actions
	TEST_ASSERT_NOTNULL(cough, "После первого носителя выдан добровольный кашель.")
	var/list/budget = new_wait_budget(20 SECONDS, "заражение соседнего манекена кашлем")
	while(!camera.hosts[neighbour] && wait_budget_tick(budget))
		cough.next_use_time = 0
		cough.Trigger()
	TEST_ASSERT_NOTNULL(camera.hosts[neighbour], "Кашель носителя заражает соседний манекен.")
	var/list/infected = camera.hosts.Copy()
	TEST_ASSERT(length(infected) >= 2, "Носителей больше одного: [length(infected)].")
	TEST_ASSERT_EQUAL(length(camera.disease_instances), length(infected), "Список носителей и список заражений совпадают.")

	for(var/index in 1 to length(infected))
		var/mob/living/carbon/human/host = infected[index]
		antag_training_console_act(session, console, "target_heal", list("id" = REF(host)))
		TEST_ASSERT(!length(host.diseases), "Лечение манекена снимает учебную болезнь.")
		if(index < length(infected))
			TEST_ASSERT_EQUAL(session.current_body, camera, "Пока носители остаются, участник - камера болезни.")
	TEST_ASSERT(!session.finished, "Излечение последнего носителя не закрывает сеанс.")
	var/mob/living/carbon/human/returned = session.current_body
	TEST_ASSERT(ishuman(returned), "После излечения последнего носителя участник в своём теле.")
	TEST_ASSERT_EQUAL(returned.mind, session.avatar_mind, "Разум участника в теле.")
	TEST_ASSERT_EQUAL(returned.training_origin?.resolve(), session.arena, "Тело принадлежит полигону.")
	TEST_ASSERT(locate(/datum/action/antag_training_controls) in returned.actions, "Пульт переходит в тело участника.")
	TEST_ASSERT(QDELETED(camera), "Камера болезни убрана.")
	TEST_ASSERT_EQUAL(session.avatar, returned, "Возвращённое тело - кукла сеанса.")
	TEST_ASSERT_EQUAL(returned.w_uniform?.training_kit_owner?.resolve(), session, "Форма возвращённой куклы помечена набором участника.")
	returned.adjustBruteLoss(40)
	session.next_heal_at = 0
	antag_training_console_act(session, console, "heal", list())
	TEST_ASSERT(abs(returned.health - returned.maxHealth) < 0.1, "Восстановление лечит куклу, а не пересоздаёт тело.")
	TEST_ASSERT_EQUAL(session.current_body, returned, "Восстановление оставляет ту же куклу.")

	returned.death()
	var/list/revive_budget = new_wait_budget(10 SECONDS, "подъём куклы после смерти")
	while(returned.stat == DEAD && !session.finished && wait_budget_tick(revive_budget))
		continue
	TEST_ASSERT(!session.finished && session.current_body == returned, "Смерть куклы не создаёт новую болезнь и не закрывает сеанс.")
	TEST_ASSERT(returned.stat != DEAD, "Сеанс поднимает куклу на месте.")
	qdel(returned)
	TEST_ASSERT(!session.finished, "Удаление куклы не закрывает сеанс.")
	TEST_ASSERT(ishuman(session.current_body) && session.avatar == session.current_body, "Вместо удалённой куклы появляется кукла, а не камера болезни.")

	var/targets_before = length(session.arena.targets)
	GLOB.unit_test_chat_capture = list()
	antag_training_console_act(session, console, "program_option", list("option" = "Носители"))
	var/refused = antag_training_chat_heard(session.current_body, "Вы не в камере болезни")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(refused, "Кнопки роли в кукле объясняют, что болезни нет.")
	TEST_ASSERT_EQUAL(length(session.arena.targets), targets_before, "Кнопка «Носители» без болезни целей не создаёт.")

/// Учебный вирус не берёт никого вне полигона ни одним путём заражения, обращение носителя в обезьяну закрыто, а смена программы и выход лечат носителей.
/datum/unit_test/antag_training_disease_isolated/Run()
	var/mob/living/carbon/human/crew = antag_training_disease_crew()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(session.prepare(), "Полигон готовит болезнь.")
	var/mob/camera/disease/training/camera = session.current_body
	var/datum/tgui/console = allocate(/datum/tgui, camera, session, "AntagTraining")
	var/list/dummies = antag_training_disease_hosts(session, console)
	var/mob/living/carbon/human/zero = dummies[1]
	camera.ClickOn(zero)
	TEST_ASSERT_NOTNULL(camera.hosts[zero], "Нулевой пациент заражён.")

	var/datum/disease/advance/sentient_disease/training/sample = camera.disease_template.Copy()
	TEST_ASSERT(istype(sample) && sample.overmind == camera, "Копия учебного вируса помнит свою камеру.")
	TEST_ASSERT(!crew.ForceContractDisease(sample), "Принудительное заражение не берёт человека вне полигона.")
	crew.ContactContractDisease(sample)
	crew.AirborneContractDisease(sample, 4)
	TEST_ASSERT(!sample.try_infect(crew), "Учебный вирус отказывается заражать вне полигона.")
	sample.infect(crew)
	TEST_ASSERT(!length(crew.diseases), "Человек вне полигона чист после всех путей заражения.")
	var/mob/living/carbon/human/participant = allocate(/mob/living/carbon/human, session.arena.entry_turf)
	participant.register_training_atom()
	TEST_ASSERT(!sample.try_infect(participant), "Заразить можно только манекены-цели, не всех на полигоне.")
	TEST_ASSERT(!length(participant.diseases), "Нецель на полигоне не заражается.")
	qdel(sample)

	var/datum/disease_ability/monkey = locate(/datum/disease_ability/symptom/powerful/monkey_transform) in GLOB.disease_ability_singletons
	TEST_ASSERT_NOTNULL(monkey, "Адаптация обращения в обезьяну есть в раунде.")
	camera.grant_points()
	antag_training_disease_buy(camera, monkey)
	TEST_ASSERT(!camera.purchased_abilities[monkey], "Обращение носителя в обезьяну на полигоне не покупается.")
	var/monkey_shown = FALSE
	var/monkey_buyable = TRUE
	for(var/list/entry as anything in camera.ui_data(camera)["abilities"])
		if(entry["path"] != "[monkey.type]")
			continue
		monkey_shown = TRUE
		monkey_buyable = entry["can_buy"]
	TEST_ASSERT(monkey_shown, "Закрытая адаптация есть в меню адаптации.")
	TEST_ASSERT(!monkey_buyable, "Меню адаптации показывает закрытую адаптацию недоступной.")

	var/datum/antag_training_session/neighbour_session = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(neighbour_session.prepare(session.arena), "Второй участник входит на тот же полигон.")
	var/mob/camera/disease/training/neighbour_camera = neighbour_session.current_body
	var/datum/tgui/neighbour_console = allocate(/datum/tgui, neighbour_camera, neighbour_session, "AntagTraining")
	var/list/neighbour_dummies = antag_training_disease_hosts(neighbour_session, neighbour_console)
	var/mob/living/carbon/human/other_dummy = length(neighbour_dummies) ? neighbour_dummies[1] : null
	TEST_ASSERT_NOTNULL(other_dummy, "Второй участник поставил свой манекен.")
	TEST_ASSERT(other_dummy in session.arena.targets, "Чужой манекен стоит на том же полигоне.")
	var/mob/living/carbon/human/foreign_dummy = dummies[2]
	TEST_ASSERT(neighbour_camera.freemove && !length(foreign_dummy.diseases), "Второй участник ещё выбирает нулевого пациента, манекен первого чист.")
	neighbour_camera.ClickOn(foreign_dummy)
	TEST_ASSERT(!length(foreign_dummy.diseases), "Щелчок по чужому манекену его не заражает.")
	TEST_ASSERT(neighbour_camera.freemove, "Чужой манекен не становится нулевым пациентом.")
	var/datum/disease/advance/sentient_disease/training/foreign_sample = camera.disease_template.Copy()
	TEST_ASSERT(!foreign_sample.try_infect(other_dummy), "Вирус первого участника не заражает манекен второго.")
	other_dummy.ContactContractDisease(foreign_sample)
	TEST_ASSERT(!length(other_dummy.diseases), "Контакт не переносит вирус на чужой манекен.")
	qdel(foreign_sample)
	qdel(neighbour_session)

	var/datum/disease_ability/symptom/medium/dizzy/adaptation = locate() in GLOB.disease_ability_singletons
	TEST_ASSERT(adaptation?.cost > 0, "Для проверки сброса нужна платная адаптация.")
	camera.grant_points()
	antag_training_disease_buy(camera, adaptation)
	TEST_ASSERT(camera.purchased_abilities[adaptation], "Симптом куплен до сброса.")
	var/points_left = camera.points
	TEST_ASSERT_EQUAL(points_left, ANTAG_TRAINING_DISEASE_POINTS - adaptation.cost, "Покупка списала очки.")
	TEST_ASSERT_NOTNULL(locate(/datum/symptom/dizzy) in camera.disease_template.symptoms, "Купленный симптом добавлен в болезнь.")
	antag_training_console_act(session, console, "program_option", list("option" = "Сбросить адаптации"))
	TEST_ASSERT(!camera.purchased_abilities[adaptation], "Сброс снимает купленную адаптацию.")
	TEST_ASSERT(camera.unpurchased_abilities[adaptation], "Сброшенная адаптация возвращается в список.")
	TEST_ASSERT_EQUAL(camera.points, points_left + adaptation.cost, "Сброс возвращает очки на счёт.")
	TEST_ASSERT_NULL(locate(/datum/symptom/dizzy) in camera.disease_template.symptoms, "Сброшенный симптом снят с болезни.")
	var/datum/disease_ability/kept_start
	for(var/datum/disease_ability/kept as anything in camera.purchased_abilities)
		if(kept.start_with)
			kept_start = kept
	TEST_ASSERT_NOTNULL(kept_start, "Стартовый добровольный кашель после сброса остаётся.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/disease_cough) in camera.actions, "Кнопка кашля после сброса на месте.")
	GLOB.unit_test_chat_capture = list()
	antag_training_console_act(session, console, "program_option", list("option" = "Сбросить адаптации"))
	var/empty_refusal = antag_training_chat_heard(camera, "Купленных адаптаций нет")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(empty_refusal, "Сброс без покупок объясняет отказ.")

	TEST_ASSERT(session.restart(/datum/antag_training_program/free), "Смена программы проходит.")
	TEST_ASSERT(QDELETED(camera), "Смена программы убирает камеру болезни.")
	TEST_ASSERT(!length(zero.diseases), "Смена программы лечит манекенов-носителей.")
	var/datum/atom_hud/disease_hud = GLOB.huds[DATA_HUD_SENTIENT_DISEASE]
	TEST_ASSERT(!(zero in disease_hud.hudatoms), "Излеченный манекен не остаётся помеченным заражённым.")

	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(second.prepare(session.arena), "Второй сеанс входит на тот же полигон.")
	var/mob/camera/disease/training/second_camera = second.current_body
	var/datum/tgui/second_console = allocate(/datum/tgui, second_camera, second, "AntagTraining")
	var/list/second_dummies = antag_training_disease_hosts(second, second_console)
	second_camera.ClickOn(second_dummies[1])
	var/datum/disease/advance/sentient_disease/training/host_virus = second_camera.disease_instances[1]
	TEST_ASSERT_NOTNULL(host_virus, "Второй сеанс заразил манекен.")
	qdel(second)
	TEST_ASSERT(QDELETED(host_virus), "Выход с полигона снимает болезнь с носителей.")
	TEST_ASSERT(!length(crew.diseases), "Экипаж станции не заражён за весь сеанс.")

/// Сброс зоны с последним носителем не закрывает сеанс: участник возвращается в своё тело, когда сброс закончится.
/datum/unit_test/antag_training_disease_reset/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(session.prepare(), "Полигон готовит болезнь.")
	var/datum/antag_training_arena/arena = session.arena
	var/mob/camera/disease/training/camera = session.current_body
	TEST_ASSERT(camera.forceMove(arena.zones["laboratory"]["spawn"]), "Камера перелетает в лабораторию.")
	var/datum/tgui/console = allocate(/datum/tgui, camera, session, "AntagTraining")
	var/list/dummies = antag_training_disease_hosts(session, console)
	TEST_ASSERT(length(dummies), "Носители встали в лаборатории.")
	camera.ClickOn(dummies[1])
	TEST_ASSERT_NOTNULL(camera.hosts[dummies[1]], "Нулевой пациент заражён.")
	TEST_ASSERT(arena.reset_zone("laboratory"), "Лаборатория сбрасывается.")
	var/list/budget = new_wait_budget(10 SECONDS, "возврат в тело после сброса зоны")
	while(!ishuman(session.current_body) && !session.finished && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!session.finished, "Сброс зоны с носителем не закрывает сеанс.")
	TEST_ASSERT(ishuman(session.current_body) && session.current_body.mind == session.avatar_mind, "После сброса участник в своём теле.")
	TEST_ASSERT(QDELETED(camera), "Камера болезни убрана после возврата.")

/// Сеанс болезни не оставляет после себя учебных вирусов в общих списках и в архиве болезней.
/datum/unit_test/antag_training_disease_cleanup/Run()
	var/instances_before = length(GLOB.sentient_disease_instances)
	var/archive_before = length(SSdisease.archive_diseases)
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/disease)
	TEST_ASSERT(session.prepare(), "Полигон готовит болезнь.")
	var/mob/camera/disease/training/camera = session.current_body
	var/datum/tgui/console = allocate(/datum/tgui, camera, session, "AntagTraining")
	var/list/dummies = antag_training_disease_hosts(session, console)
	camera.ClickOn(dummies[1])
	TEST_ASSERT_NOTNULL(camera.hosts[dummies[1]], "Нулевой пациент заражён.")
	TEST_ASSERT(length(GLOB.sentient_disease_instances) > instances_before, "Учебные вирусы появились в общем списке.")
	var/archive_key = "[camera.template_type]|[camera.tag]"
	TEST_ASSERT_NOTNULL(SSdisease.archive_diseases[archive_key], "Шаблон болезни попал в архив под своим ключом.")
	var/datum/disease/advance/sentient_disease/training/template = camera.disease_template
	var/datum/disease/advance/sentient_disease/training/host_virus = camera.disease_instances[1]
	qdel(session)
	TEST_ASSERT_NULL(SSdisease.archive_diseases[archive_key], "Выход убирает шаблон из архива болезней.")
	TEST_ASSERT(QDELETED(template) && QDELETED(host_virus), "Шаблон и вирус носителя удалены вместе с камерой.")
	var/list/leftovers = list()
	for(var/datum/disease/advance/sentient_disease/leftover as anything in GLOB.sentient_disease_instances)
		if(leftover == template || leftover == host_virus || leftover.overmind == camera)
			leftovers += leftover.type
	TEST_ASSERT(!length(leftovers), "После выхода в общем списке остались вирусы сеанса: [english_list(leftovers)].")
	// Снимок болезни под ключом "...|null" заводится один раз на мир, остальное растёт только по сеансам.
	TEST_ASSERT(length(GLOB.sentient_disease_instances) <= instances_before + 1, "Общий список вирусов не растёт на каждый сеанс: [length(GLOB.sentient_disease_instances)] против [instances_before].")
	TEST_ASSERT(length(SSdisease.archive_diseases) <= archive_before + 1, "Архив болезней не растёт на каждый сеанс.")
