/// «Смесь для дыхания»: канистры на входы ключом, доля кислорода на смесителе из его окна, канистра на выходе наполняется и проверяется при отсоединении.
/datum/unit_test/antag_training_exercise_mix/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "atmos", "atmos_mix")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в атмос-секторе.")
	var/datum/antag_training_exercise/systems/mix/mix = run.exercise
	var/datum/antag_training_sector/sector = session.arena.sectors["atmos"]
	var/obj/machinery/atmospherics/components/trinary/mixer/mixer = mix.mixer(sector)
	TEST_ASSERT(mixer && !mixer.on && mixer.node1_concentration == 0.5, "Подготовка выключает смеситель и сбрасывает доли.")
	var/list/obj/machinery/atmospherics/components/unary/portables_connector/ports = list(mix.port(mixer, 1), mix.port(mixer, 2), mix.port(mixer, 3))
	for(var/node in 1 to 3)
		TEST_ASSERT_NOTNULL(ports[node], "У узла [node] смесителя есть порт канистры.")
	var/obj/machinery/portable_atmospherics/canister/receiver = locate() in get_turf(ports[3])
	TEST_ASSERT(receiver && !receiver.air_contents.total_moles(), "На выходе стоит пустая канистра.")
	var/mob/living/carbon/human/user = session.current_body
	var/obj/item/wrench/wrench = antag_training_hold(user, new /obj/item/wrench(get_turf(user)))
	for(var/node in 1 to 2)
		var/obj/machinery/portable_atmospherics/canister/source = locate() in get_turf(ports[node])
		TEST_ASSERT_NOTNULL(source, "На входе [node] стоит канистра газа.")
		user.forceMove(get_turf(source))
		wrench.melee_attack_chain(user, source)
		TEST_ASSERT_EQUAL(source.connected_port, ports[node], "Ключ прикручивает канистру к входу [node].")
	TEST_ASSERT(antag_training_wait_step(run, 2), "Подключение засчитано.")
	TEST_ASSERT_EQUAL(mix.oxygen_node(mixer), 1, "Кислород на первом входе.")
	user.forceMove(get_turf(mixer))
	antag_training_machine_act(user, mixer, "AtmosMixer", "node1", list("concentration" = "[ANTAG_TRAINING_MIX_OXYGEN]"))
	antag_training_machine_act(user, mixer, "AtmosMixer", "power")
	TEST_ASSERT(mixer.on, "Смеситель включается из своего окна.")
	TEST_ASSERT(antag_training_wait_step(run, 3), "Настройка засчитана.")

	user.forceMove(get_turf(receiver))
	antag_training_hold(user, wrench)
	wrench.melee_attack_chain(user, receiver)
	TEST_ASSERT_EQUAL(receiver.connected_port, ports[3], "Пустая канистра прикручена к выходу.")
	wrench.melee_attack_chain(user, receiver)
	TEST_ASSERT_NULL(receiver.connected_port, "Канистра откручена сразу.")
	var/list/budget = new_wait_budget(3 SECONDS, "проверка неполной канистры")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT(!run.ended, "Неполная канистра не засчитывается.")
	wrench.melee_attack_chain(user, receiver)
	budget = new_wait_budget(60 SECONDS, "канистра на выходе наполняется")
	while(receiver.air_contents.return_pressure() < ANTAG_TRAINING_MIX_PRESSURE && wait_budget_tick(budget))
		continue
	TEST_ASSERT(receiver.air_contents.return_pressure() >= ANTAG_TRAINING_MIX_PRESSURE, "Канистра наполнилась до [ANTAG_TRAINING_MIX_PRESSURE] кПа, а не [receiver.air_contents.return_pressure()].")
	TEST_ASSERT(!run.ended, "Подключённая канистра ещё не проверяется.")
	wrench.melee_attack_chain(user, receiver)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 5 SECONDS) && run.success, "Отсоединённая канистра со смесью засчитана: [run.result_text]")
	var/oxygen = mix.gas_share(receiver.air_contents, GAS_O2) * 100
	TEST_ASSERT(abs(oxygen - ANTAG_TRAINING_MIX_OXYGEN) <= ANTAG_TRAINING_MIX_TOLERANCE, "В канистре [oxygen]% кислорода.")

/// «Заделай пробой»: окно камеры бьётся, заслонка закрывается сама, ломом её открывают, стекло на решётку, отвёртка, давление в зале держится; сброс закрепляет окно или ставит новое.
/datum/unit_test/antag_training_exercise_breach/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "atmos", "atmos_breach")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в атмос-секторе.")
	var/datum/antag_training_exercise/systems/breach/breach = run.exercise
	var/datum/antag_training_sector/sector = session.arena.sectors["atmos"]
	var/list/spot = breach.breach(sector)
	TEST_ASSERT_NOTNULL(spot, "У камеры есть окно с заслонкой.")
	var/turf/open/edge = spot[1]
	var/turf/open/hall = spot[2]
	TEST_ASSERT(!breach.sealed(edge), "Подготовка разбивает окно.")
	var/obj/machinery/door/firedoor/shutter = locate() in edge
	TEST_ASSERT(wait_for_var(shutter, "density", TRUE, 10 SECONDS) && wait_for_var(shutter, "operating", FALSE, 5 SECONDS), "Пробой закрывает аварийная заслонка.")
	var/mob/living/carbon/human/user = session.current_body
	user.forceMove(hall)
	var/obj/item/crowbar/crowbar = antag_training_hold(user, new /obj/item/crowbar(hall))
	crowbar.melee_attack_chain(user, shutter)
	TEST_ASSERT(wait_for_var(shutter, "density", FALSE, 5 SECONDS), "Лом открывает заслонку.")
	var/obj/structure/grille/grille = locate() in edge
	TEST_ASSERT_NOTNULL(grille, "Решётка окна на месте.")
	var/obj/item/stack/sheet/glass/glass = antag_training_hold(user, new /obj/item/stack/sheet/glass(hall, 5))
	glass.melee_attack_chain(user, grille)
	var/obj/structure/window/pane = locate() in edge
	TEST_ASSERT(pane?.fulltile, "Стекло на решётке становится окном.")
	TEST_ASSERT(!run.ended && run.step_index == 1, "Неприкрученное окно не засчитано.")
	var/obj/item/screwdriver/screwdriver = antag_training_hold(user, new /obj/item/screwdriver(hall))
	screwdriver.melee_attack_chain(user, pane)
	TEST_ASSERT(pane.anchored, "Отвёртка прикручивает окно.")
	TEST_ASSERT(antag_training_wait_step(run, 2), "Окно засчитано.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 30 SECONDS) && run.success, "Давление в зале держится: [hall.air.return_pressure()] кПа, [run.result_text]")
	TEST_ASSERT(hall.air.return_pressure() >= ANTAG_TRAINING_BREACH_PRESSURE, "В зале не меньше [ANTAG_TRAINING_BREACH_PRESSURE] кПа.")

	antag_training_console_act(session, ui, "exercise_start", list("id" = "atmos_breach"))
	var/datum/antag_training_exercise_run/second = session.exercise_run
	TEST_ASSERT(second && second != run && !breach.sealed(edge), "Повтор снова разбивает окно.")
	wait_for_var(shutter, "operating", FALSE, 5 SECONDS)
	if(shutter.density)
		antag_training_hold(user, crowbar)
		crowbar.melee_attack_chain(user, shutter)
	TEST_ASSERT(wait_for_var(shutter, "density", FALSE, 5 SECONDS), "Заслонка открыта.")
	antag_training_hold(user, glass)
	glass.melee_attack_chain(user, grille)
	antag_training_console_act(session, ui, "exercise_stop", list())
	var/panes = 0
	for(var/obj/structure/window/window in edge)
		panes++
	TEST_ASSERT(breach.sealed(edge) && panes == 1, "Сброс закрепляет уже положенное окно, а не ставит второе: окон [panes].")

/// «Потуши пожар»: плазма вспыхивает, когда участник входит в комнату с огнетушителем без предохранителя, огнетушитель сбивает пламя; сброс возвращает воздух.
/datum/unit_test/antag_training_exercise_fire/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "atmos", "atmos_fire")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в атмос-секторе.")
	var/datum/antag_training_exercise/systems/fire/fire = run.exercise
	var/list/turf/open/room = fire.room(session.arena.sectors["atmos"])
	TEST_ASSERT(length(room) > 4, "Вентиляционная комната найдена от пульта воздуха.")
	var/turf/open/inside = antag_training_room_center(room)
	var/mob/living/carbon/human/user = session.current_body
	user.status_flags |= GODMODE
	user.forceMove(inside)
	var/list/budget = new_wait_budget(3 SECONDS, "без огнетушителя пожар не начинается")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT(run.step_index == 1 && !antag_training_room_plasma(room), "Без огнетушителя в руке плазма не вспыхивает.")
	var/obj/item/extinguisher/extinguisher = antag_training_hold(user, new /obj/item/extinguisher(inside))
	extinguisher.attack_self(user)
	TEST_ASSERT(!extinguisher.safety, "Предохранитель снят.")
	TEST_ASSERT(antag_training_wait_step(run, 2), "С огнетушителем в комнате начинается пожар.")
	TEST_ASSERT(antag_training_room_plasma(room) > 0, "В комнату выпущена плазма.")
	budget = new_wait_budget(30 SECONDS, "огнетушитель сбивает пламя")
	while(!run.ended && wait_budget_tick(budget))
		if(world.time < extinguisher.last_use + 1.2 SECONDS)
			continue
		var/turf/open/target
		for(var/turf/open/tile as anything in room)
			if(!QDELETED(tile.active_hotspot) && (!target || get_dist(user, tile) < get_dist(user, target)))
				target = tile
		if(target)
			extinguisher.afterattack(target, user, get_dist(user, target) <= 1)
	TEST_ASSERT(run.ended && run.success, "Пожар потушен: [run.result_text]")
	TEST_ASSERT(!antag_training_room_plasma(room), "После тушения вентиляция убрала остаток плазмы.")
	for(var/turf/open/tile as anything in room)
		TEST_ASSERT(QDELETED(tile.active_hotspot) && tile.air.return_temperature() < FIRE_MINIMUM_TEMPERATURE_TO_EXIST, "Клетка [tile.x],[tile.y] остыла.")
	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(!antag_training_room_plasma(room), "Сброс убирает плазму из комнаты.")

/// Без огнетушителя прогон проваливается: пожар выжигает плазму или гаснет сам.
/datum/unit_test/antag_training_exercise_fire_burnout/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "atmos", "atmos_fire")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в атмос-секторе.")
	var/datum/antag_training_exercise/systems/fire/fire = run.exercise
	var/list/turf/open/room = fire.room(session.arena.sectors["atmos"])
	var/mob/living/carbon/human/user = session.current_body
	user.status_flags |= GODMODE
	var/obj/item/extinguisher/extinguisher = antag_training_hold(user, new /obj/item/extinguisher(get_turf(user)))
	extinguisher.attack_self(user)
	user.forceMove(antag_training_room_center(room))
	TEST_ASSERT(antag_training_wait_step(run, 2), "С огнетушителем в комнате начинается пожар.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 60 SECONDS), "Несбитое пламя завершает прогон.")
	TEST_ASSERT(!run.success && (findtext(run.result_text, "плазмы") || findtext(run.result_text, "огнетушитель")), "Пожар без огнетушителя - провал: [run.result_text]")
	var/list/records = session.exercise_records()
	TEST_ASSERT_NULL(records["atmos_fire"], "Провал не записан в лучший результат.")

/datum/unit_test/proc/antag_training_room_plasma(list/turf/open/room)
	. = 0
	for(var/turf/open/tile as anything in room)
		. += tile.air.get_moles(GAS_PLASMA)

/// «Разгерметизация»: участник в раздевалке, где давление упало, надевает маску и открывает баллон; сброс возвращает воздух.
/datum/unit_test/antag_training_exercise_internals/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "atmos", "atmos_internals")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в атмос-секторе.")
	var/datum/antag_training_exercise/systems/internals/internals = run.exercise
	var/list/turf/open/room = internals.room(session.arena.sectors["atmos"])
	var/mob/living/carbon/human/user = session.current_body
	var/turf/open/standing = get_turf(user)
	TEST_ASSERT(standing in room, "Участник перенесён в раздевалку.")
	TEST_ASSERT(standing.air.return_pressure() < WARNING_LOW_PRESSURE && standing.air.return_pressure() > HAZARD_LOW_PRESSURE, "Давление в раздевалке упало до [standing.air.return_pressure()] кПа.")
	var/obj/item/clothing/mask/breath/mask = antag_training_hold(user, new /obj/item/clothing/mask/breath(standing))
	user.attack_ui(ITEM_SLOT_MASK)
	TEST_ASSERT_EQUAL(user.wear_mask, mask, "Маска надета.")
	TEST_ASSERT_EQUAL(run.step_index, 2, "Маска засчитана по сигналу.")
	var/obj/item/tank/internals/emergency_oxygen/tank = antag_training_hold(user, new /obj/item/tank/internals/emergency_oxygen(standing))
	tank.ui_action_click(user)
	TEST_ASSERT_EQUAL(user.internal, tank, "Подача из баллона открыта.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 5 SECONDS) && run.success, "Упражнение выполнено: [run.result_text]")
	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(abs(standing.air.return_pressure() - ONE_ATMOSPHERE) < 5, "Сброс возвращает воздух в раздевалку, а не [standing.air.return_pressure()] кПа.")
