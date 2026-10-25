/datum/unit_test/proc/wait_for_abductor_ship(datum/team/abductor_team/training/crew)
	var/list/budget = new_wait_budget(30 SECONDS, "корабль учебных абдукторов в отсеке")
	while(!QDELETED(crew) && QDELETED(crew.console) && wait_budget_tick(budget))
		continue
	return !QDELETED(crew) && !QDELETED(crew.console)

/// Агент и учёный полигона получают одну учебную команду вне счёта раунда, корабль встаёт в отсек макета и привязывает снаряжение, телепатия не выходит за корабль полигона.
/datum/unit_test/antag_training_abductor_team

/datum/unit_test/antag_training_abductor_team/Run()
	var/round_teams = /datum/team/abductor_team::team_count
	var/teams_before = length(GLOB.antagonist_teams)
	var/datum/antag_training_session/agent_session = allocate_training_session(/datum/antag_training_program/antag/abductor/agent)
	TEST_ASSERT(agent_session.prepare(), "Полигон готовит агента.")
	var/datum/antag_training_session/scientist_session = allocate_training_session(/datum/antag_training_program/antag/abductor/scientist)
	TEST_ASSERT(scientist_session.prepare(), "Полигон готовит учёного.")
	var/datum/antag_training_program/antag/abductor/agent_program = agent_session.program
	var/datum/antag_training_program/antag/abductor/scientist_program = scientist_session.program
	var/datum/antagonist/abductor/training/agent_role = agent_program.role(agent_session)
	var/datum/antagonist/abductor/training/scientist_role = scientist_program.role(scientist_session)
	TEST_ASSERT(istype(agent_role, /datum/antagonist/abductor/training/agent), "Кукла получает учебного агента.")
	TEST_ASSERT(istype(scientist_role, /datum/antagonist/abductor/training/scientist), "Вторая кукла получает учебного учёного.")
	var/datum/team/abductor_team/training/crew = agent_role.team
	TEST_ASSERT(istype(crew), "У агента учебная команда.")
	TEST_ASSERT_EQUAL(scientist_role.team, crew, "Учёный на том же корабле полигона.")
	TEST_ASSERT_EQUAL(/datum/team/abductor_team::team_count, round_teams, "Счётчик команд раунда не сдвинулся.")
	TEST_ASSERT(crew.team_number > ABDUCTOR_MAX_TEAMS, "Номер учебной команды вне номеров раунда.")
	TEST_ASSERT(!(crew in GLOB.antagonist_teams) && length(GLOB.antagonist_teams) == teams_before, "Команд раунда не прибавилось.")

	TEST_ASSERT(wait_for_abductor_ship(crew), "Корабль встаёт в отсек.")
	var/datum/antag_training_arena/arena = agent_session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	var/turf/bay = station.landmark_turf("abductor")
	var/obj/machinery/abductor/console/training/console = crew.console
	for(var/obj/machinery/piece as anything in list(console, console.pad, console.experiment, console.camera))
		TEST_ASSERT_NOTNULL(piece, "Консоль связана со всеми машинами корабля.")
		TEST_ASSERT_EQUAL(piece.vars["team_number"], crew.team_number, "[piece.type]: номер команды корабля.")
		TEST_ASSERT(arena.owns_area(get_area(piece)) && get_dist(piece, bay) <= 3, "[piece.type] стоит в отсеке абдукторов макета.")
	var/mob/living/carbon/human/agent = agent_session.current_body
	var/mob/living/carbon/human/scientist = scientist_session.current_body
	TEST_ASSERT(isabductor(agent) && isabductor(scientist), "Обе куклы - абдукторы.")
	TEST_ASSERT_EQUAL(get_turf(agent), bay, "Агент на борту корабля.")
	TEST_ASSERT_EQUAL(console.vest, locate(/obj/item/clothing/suit/armor/abductor/vest) in agent, "Жилет агента привязан к консоли.")
	TEST_ASSERT(istype(console.gizmo, /obj/item/abductor/gizmo/training) && (console.gizmo in scientist.GetAllContents()), "Инструмент учёного привязан к консоли.")
	var/obj/item/implant/abductor/training/beacon = locate() in scientist.implants
	TEST_ASSERT_EQUAL(beacon?.home, console.pad, "Имплант возврата учёного ведёт на телепад корабля.")

	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human)
	var/obj/item/organ/tongue/abductor/outsider_tongue = new
	outsider_tongue.Insert(outsider)
	outsider_tongue.mothership = crew.name
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	TEST_ASSERT(ghost in GLOB.dead_mob_list, "Наблюдатель в списке мёртвых.")
	GLOB.unit_test_chat_capture = list()
	agent.say("abductor-arena-probe")
	TEST_ASSERT(antag_training_heard(scientist, "abductor-arena-probe"), "Учёный слышит телепатию агента.")
	TEST_ASSERT(!antag_training_heard(ghost, "abductor-arena-probe"), "Мёртвые не слышат телепатию полигона.")
	TEST_ASSERT(!antag_training_heard(outsider, "abductor-arena-probe"), "Носитель языка того же корабля вне полигона её не слышит.")

/datum/unit_test/antag_training_abductor_team/Destroy()
	GLOB.unit_test_chat_capture = null
	return ..()

/// Опыт над учебной целью с железой через экспериментатор засчитывает очки без игрока в цели и оставляет её на полигоне; консоль продаёт снаряжение за кредиты пульта; телепад без точки высадки не уходит на станцию.
/datum/unit_test/antag_training_abductor_experiment/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/abductor/agent)
	TEST_ASSERT(session.prepare(), "Полигон готовит агента.")
	var/datum/antag_training_program/antag/abductor/program = session.program
	var/datum/antagonist/abductor/training/role = program.role(session)
	var/datum/team/abductor_team/training/crew = role.team
	TEST_ASSERT(wait_for_abductor_ship(crew), "Корабль встаёт в отсек.")
	var/datum/antag_training_arena/arena = session.arena
	var/list/station_bounds = arena.zones["station"]["bounds"]
	var/obj/machinery/abductor/console/training/console = crew.console
	var/obj/machinery/abductor/experiment/training/experimenter = console.experiment
	var/obj/machinery/abductor/pad/training/pad = console.pad
	var/mob/living/carbon/human/agent = session.current_body
	var/datum/tgui/panel = allocate(/datum/tgui, agent, session, "AntagTraining")
	var/datum/tgui/console_ui = allocate(/datum/tgui, agent, console, "AbductorConsole")
	console_ui.status = UI_INTERACTIVE
	var/datum/tgui/experiment_ui = allocate(/datum/tgui, agent, experimenter, "ProbingConsole")
	experiment_ui.status = UI_INTERACTIVE

	TEST_ASSERT_EQUAL(experimenter.credits, 0, "Кредитов в начале нет.")
	antag_training_console_act(session, panel, "program_option", list("option" = "Пополнить кредиты"))
	var/credits = experimenter.credits
	TEST_ASSERT(credits > 0, "«Пополнить кредиты» наполняет консоль.")
	usr = agent
	console.ui_act("buy", list("name" = "Science Tool"), console_ui)
	usr = null
	TEST_ASSERT_EQUAL(experimenter.credits, credits - 1, "Покупка списывает кредит.")
	TEST_ASSERT(locate(/obj/item/abductor/gizmo/training) in get_turf(pad), "Инструмент учёного приходит на телепад учебным.")
	usr = agent
	console.ui_act("buy", list("name" = "Reagent Synthesizer"), console_ui)
	usr = null
	var/obj/item/abductor_machine_beacon/chem_dispenser/training/beacon = locate() in get_turf(pad)
	TEST_ASSERT_NOTNULL(beacon, "Синтезатор приходит учебным маяком.")
	var/turf/free_spot = get_step(pad, NORTH)
	agent.forceMove(free_spot)
	agent.put_in_active_hand(beacon)
	beacon.attack_self(agent)
	TEST_ASSERT(wait_for_qdeleted(beacon, 10 SECONDS), "Маяк ставит синтезатор.")
	var/obj/machinery/chem_dispenser/abductor/synthesizer = locate() in free_spot
	TEST_ASSERT_NOTNULL(synthesizer, "Синтезатор стоит на месте маяка.")
	TEST_ASSERT(WEAKREF(synthesizer) in arena.issued_items, "Синтезатор считается в лимите выданного.")
	credits = experimenter.credits

	antag_training_console_act(session, panel, "program_option", list("option" = "Цель с железой"))
	var/mob/living/carbon/human/dummy = program.recent_target(session)
	TEST_ASSERT_NOTNULL(dummy, "Пульт ставит учебную цель.")
	TEST_ASSERT(locate(/obj/item/organ/heart/gland) in dummy.internal_organs, "В цели железа.")
	TEST_ASSERT(dummy.mind && !dummy.ckey, "Цель с разумом, но без игрока.")
	TEST_ASSERT(get_dist(dummy, agent) <= 3, "Цель встаёт рядом с агентом.")

	var/turf/release = arena.zones["station"]["target"]
	console.SetDroppoint(release, agent)
	agent.forceMove(get_step(experimenter, WEST))
	dummy.forceMove(get_step(agent, WEST))
	experimenter.MouseDrop_T(dummy, agent)
	TEST_ASSERT_EQUAL(experimenter.occupant, dummy, "Цель в экспериментаторе.")
	usr = agent
	experimenter.ui_act("experiment", list("experiment_type" = "1"), experiment_ui)
	usr = null
	TEST_ASSERT_EQUAL(experimenter.points, 1, "Опыт засчитан без игрока в цели.")
	TEST_ASSERT_EQUAL(experimenter.credits, credits + 1, "Опыт приносит кредит.")
	TEST_ASSERT_EQUAL(get_turf(dummy), release, "Цель уходит в точку высадки на полигоне.")
	TEST_ASSERT(!dummy.mind.has_antag_datum(/datum/antagonist/abductee), "Цель не получает роль похищенного.")
	TEST_ASSERT(crew.experiment_objective.completed, "Учебное задание команды выполнено.")

	pad.teleport_target = null
	agent.forceMove(get_turf(pad))
	usr = agent
	console.ui_act("teleporter_send", list(), console_ui)
	usr = null
	TEST_ASSERT(arena.owns_area(get_area(agent)) && arena.inside_bounds(get_turf(agent), station_bounds), "Телепад без точки высадки отправляет в макет полигона.")
	TEST_ASSERT(pad.teleport_target && arena.inside_bounds(pad.teleport_target, station_bounds), "Точка высадки телепада - в макете.")
	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(crew, 1 MINUTES) && QDELETED(console) && QDELETED(experimenter) && QDELETED(pad), "Выход последнего абдуктора убирает команду и корабль.")
