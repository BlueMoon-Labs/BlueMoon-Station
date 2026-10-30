/proc/antag_training_clock_snapshot()
	var/list/states = list()
	for(var/tier in SSticker.scripture_states)
		states += "[tier]=[SSticker.scripture_states[tier]]"
	return "vitality=[GLOB.clockwork_vitality], script=[GLOB.script_scripture_unlocked], application=[GLOB.application_scripture_unlocked], states=[jointext(states, ";")], servants=[length(SSticker.mode.servants_of_ratvar)], ark=[REF(GLOB.ark_of_the_clockwork_justiciar)], gateway=[GLOB.clockwork_gateway_activated], ratvar=[GLOB.ratvar_awakens]"

/// Слейт раунда на ЦК прибавляет к общей силе 0.1 за тик SSobj, а самое дешёвое писание стоит 25 Вт.
/proc/antag_training_clock_power_steady(power_before)
	return abs(GLOB.clockwork_power - power_before) < 5

/proc/antag_training_slab_scriptures(obj/item/clockwork/slab/slab, mob/user)
	var/list/types = list()
	var/list/categories = slab.ui_data(user)["scripture"]
	for(var/category in categories)
		for(var/list/entry as anything in categories[category])
			types += entry["type"]
	return types

/datum/unit_test/proc/antag_training_slab_act(obj/item/clockwork/slab/slab, mob/living/user, action, list/params)
	var/datum/tgui/ui = allocate(/datum/tgui, user, slab, "ClockworkSlab")
	ui.status = UI_INTERACTIVE
	usr = user
	slab.ui_act(action, params, ui)
	usr = null

/datum/unit_test/proc/antag_training_hold_slab(mob/living/carbon/human/body, obj/item/clockwork/slab/slab)
	if(body.get_active_held_item() != slab)
		body.swap_hand()
	return body.get_active_held_item() == slab

/datum/unit_test/proc/antag_training_free_neighbour(turf/center)
	for(var/turf/open/spot in orange(1, center))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE))
			return spot
	return null

/// Программа выдаёт учебного слугу с учебной командой и слейтом вне списков раунда; учебные писания видит только учебный слейт; Иерофант не выходит за полигон; «Латунь» выдаёт латунь и потерянный слейт.
/datum/unit_test/antag_training_clockcult_setup
	var/datum/antagonist/clockcult/round_role

/datum/unit_test/antag_training_clockcult_setup/Run()
	var/teams_before = length(GLOB.antagonist_teams)
	var/clock_before = antag_training_clock_snapshot()
	var/power_before = GLOB.clockwork_power
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/clockcult)
	TEST_ASSERT(session.prepare(), "Полигон готовит слугу Ратвара.")
	var/datum/antag_training_program/antag/clockcult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/clockcult/training/servant = program.role(session)
	TEST_ASSERT(istype(servant), "Кукла получает учебного слугу Ратвара.")
	var/datum/team/clockcult/training/team = servant.get_team()
	TEST_ASSERT(istype(team) && (body.mind in team.members), "Слуга в учебной команде.")
	TEST_ASSERT(!(team in GLOB.antagonist_teams) && length(GLOB.antagonist_teams) == teams_before, "Учебная команда не в списке команд раунда.")
	TEST_ASSERT_NULL(servant.clock_team, "Поиск команды раунда по слугам учебную команду не находит.")
	TEST_ASSERT(!(body.mind in SSticker.mode.servants_of_ratvar), "Слуга полигона не в списке слуг режима.")
	TEST_ASSERT_NULL(body.alerts["clockinfo"], "Сводка культа раунда учебному слуге не показывается.")
	var/obj/item/clockwork/slab/training/slab = servant.slab_ref?.resolve()
	TEST_ASSERT(istype(slab) && body.contains_atom(slab), "Учебный слейт у слуги.")
	TEST_ASSERT(!(slab.datum_flags & DF_ISPROCESSING), "Учебный слейт не вырабатывает общую энергию.")
	var/list/data = session.ui_data(body)
	for(var/option in program.options)
		TEST_ASSERT(length(data["option_hints"][option]), "У кнопки «[option]» есть подсказка.")

	var/list/training_types = antag_training_slab_scriptures(slab, body)
	TEST_ASSERT("[/datum/clockwork_scripture/create_object/sigil_of_submission/training]" in training_types, "Учебный слейт показывает учебный сигил подчинения.")
	TEST_ASSERT("[/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training]" in training_types, "Учебный слейт показывает учебный Ковчег.")
	for(var/blocked in list(/datum/clockwork_scripture/create_object/stargazer, /datum/clockwork_scripture/create_object/integration_cog, /datum/clockwork_scripture/spatial_gateway, /datum/clockwork_scripture/create_object/replicant, /datum/clockwork_scripture/create_object/sigil_of_submission, /datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar, /datum/clockwork_scripture/clockwork_armaments))
		TEST_ASSERT(!("[blocked]" in training_types), "Учебный слейт не показывает [blocked].")
	var/obj/item/clockwork/slab/round_slab = allocate(/obj/item/clockwork/slab, run_loc_floor_bottom_left)
	var/list/round_types = antag_training_slab_scriptures(round_slab, body)
	TEST_ASSERT("[/datum/clockwork_scripture/create_object/sigil_of_submission]" in round_types, "Слейт раунда показывает свой сигил подчинения.")
	for(var/path in round_types)
		TEST_ASSERT(!ispath(text2path(path), /datum/clockwork_scripture/create_object/sigil_of_submission/training) && !ispath(text2path(path), /datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training), "Слейт раунда не показывает учебное писание [path].")

	var/mob/living/carbon/human/station_servant = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	station_servant.mind_initialize()
	allocated += station_servant.mind
	round_role = new
	round_role.silent = TRUE
	station_servant.mind.add_antag_datum(round_role)
	var/datum/team/clockcult/round_team = round_role.clock_team
	allocated += round_team
	TEST_ASSERT(round_team && !istype(round_team, /datum/team/clockcult/training) && !(station_servant.mind in team.members), "Слуга раунда без команды не вступает в учебную.")
	station_servant.put_in_active_hand(round_slab)
	antag_training_slab_act(round_slab, station_servant, "recite", list("script" = "[/datum/clockwork_scripture/create_object/sigil_of_submission/training]"))
	TEST_ASSERT_NULL(locate(/obj/effect/clockwork/sigil/submission) in get_turf(station_servant), "Слейт раунда не читает учебный сигил.")

	GLOB.unit_test_chat_capture = list()
	titled_hierophant_message(station_servant, "clock-round-probe")
	TEST_ASSERT(antag_training_heard(station_servant, "clock-round-probe"), "Иерофант раунда работает.")
	TEST_ASSERT(!antag_training_heard(body, "clock-round-probe"), "Слуга полигона не слышит Иерофанта раунда.")
	titled_hierophant_message(body, "clock-arena-probe")
	TEST_ASSERT(antag_training_heard(body, "clock-arena-probe"), "Иерофант полигона работает.")
	TEST_ASSERT(!antag_training_heard(station_servant, "clock-arena-probe"), "Слуга раунда не слышит Иерофанта полигона.")
	GLOB.unit_test_chat_capture = null
	station_servant.mind.remove_antag_datum(/datum/antagonist/clockcult)
	qdel(round_slab)

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Латунь"))
	var/obj/item/stack/tile/brass/brass = locate() in body.held_items
	TEST_ASSERT_EQUAL(brass?.amount, ANTAG_TRAINING_BRASS_SHEETS, "«Латунь» выдаёт латунь в руки.")
	qdel(slab)
	session.next_supply_at = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Латунь"))
	var/obj/item/clockwork/slab/training/replacement = servant.slab_ref?.resolve()
	TEST_ASSERT(istype(replacement) && replacement != slab && body.contains_atom(replacement), "Потерянный слейт выдаётся заново.")
	TEST_ASSERT_EQUAL(antag_training_clock_snapshot(), clock_before, "Выдача роли и латуни не трогает силу, жизненную силу, ступени и списки культа раунда.")
	TEST_ASSERT(antag_training_clock_power_steady(power_before), "Общая сила культа: было [power_before], стало [GLOB.clockwork_power].")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(servant, 1 MINUTES), "Выход снимает роль слуги.")
	TEST_ASSERT(QDELETED(team), "Учебная команда снимается вместе со слугой.")

/datum/unit_test/antag_training_clockcult_setup/Destroy()
	GLOB.unit_test_chat_capture = null
	if(!QDELETED(round_role))
		round_role.owner?.remove_antag_datum(/datum/antagonist/clockcult)
	round_role = null
	return ..()

/// Учебный сигил подчинения обращает учебную цель в слугу учебной команды; ни обращение, ни сорванное чтение не меняют силу, жизненную силу и ступени писаний раунда.
/datum/unit_test/antag_training_clockcult_conversion/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/clockcult)
	TEST_ASSERT(session.prepare(), "Полигон готовит слугу Ратвара.")
	var/datum/antag_training_arena/arena = session.arena
	TEST_ASSERT(wait_for_var(arena.sectors["station"], "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/clock_before = antag_training_clock_snapshot()
	var/power_before = GLOB.clockwork_power
	var/datum/antag_training_program/antag/clockcult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/clockcult/training/servant = program.role(session)
	var/datum/team/clockcult/training/team = servant.training_team
	var/obj/item/clockwork/slab/training/slab = servant.slab_ref?.resolve()
	TEST_ASSERT(antag_training_hold_slab(body, slab), "Слейт в активной руке.")
	body.forceMove(arena.zones["melee"]["spawn"])
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для обращения"))
	var/mob/living/carbon/human/dummy = program.recent_target(session)
	TEST_ASSERT(dummy && !is_servant_of_ratvar(dummy) && isnull(dummy.client), "Рядом встаёт учебная цель без игрока.")

	slab.speed_multiplier = 0
	antag_training_slab_act(slab, body, "recite", list("script" = "[/datum/clockwork_scripture/create_object/sigil_of_submission/training]"))
	var/obj/effect/clockwork/sigil/submission/training/sigil = locate() in get_turf(body)
	TEST_ASSERT_NOTNULL(sigil, "Слейт чертит учебный сигил подчинения.")
	var/turf/sigil_turf = get_turf(sigil)
	body.forceMove(antag_training_free_neighbour(sigil_turf))
	dummy.forceMove(sigil_turf)
	var/datum/antagonist/clockcult/convert = dummy.mind.has_antag_datum(/datum/antagonist/clockcult)
	TEST_ASSERT(istype(convert, /datum/antagonist/clockcult/training), "Сигил обращает учебную цель в учебного слугу.")
	TEST_ASSERT(convert.get_team() == team && (dummy.mind in team.members) && isnull(convert.clock_team), "Обращённый - в учебной команде, а не в команде раунда.")
	TEST_ASSERT(!(dummy.mind in SSticker.mode.servants_of_ratvar), "Обращённый не в списке слуг режима.")
	TEST_ASSERT_NULL(locate(/obj/item/clockwork/slab) in sigil_turf, "Учебный сигил не оставляет слейт раунда.")
	TEST_ASSERT_EQUAL(antag_training_clock_snapshot(), clock_before, "Обращение не открывает писания раунда и не трогает силу культа.")
	TEST_ASSERT(antag_training_clock_power_steady(power_before), "Общая сила культа: было [power_before], стало [GLOB.clockwork_power].")

	slab.speed_multiplier = 1
	INVOKE_ASYNC(slab, TYPE_PROC_REF(/obj/item/clockwork/slab, recite_scripture), /datum/clockwork_scripture/create_object/sigil_of_transgression, body)
	TEST_ASSERT(slab.busy, "Чтение сигила нарушения началось.")
	body.forceMove(antag_training_free_neighbour(get_turf(body)))
	TEST_ASSERT(wait_for_var(slab, "busy", null, 10 SECONDS), "Сорванное чтение заканчивается.")
	TEST_ASSERT_EQUAL(antag_training_clock_snapshot(), clock_before, "Сорванное чтение не трогает ступени и списки культа раунда.")
	TEST_ASSERT(antag_training_clock_power_steady(power_before), "Сорванное чтение учебного слейта не возвращает в общую силу то, чего не брало: было [power_before], стало [GLOB.clockwork_power].")

/// Учебный Ковчег встаёт только в станционном макете при слугах вокруг, запускается касанием и пробуждает учебного Ратвара без Ковчега раунда, тревоги, шаттла и общей силы.
/datum/unit_test/antag_training_clockcult_ark/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/clockcult)
	TEST_ASSERT(session.prepare(), "Полигон готовит слугу Ратвара.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/clock_before = antag_training_clock_snapshot()
	var/power_before = GLOB.clockwork_power
	var/security_before = GLOB.security_level
	var/hostile_before = length(SSshuttle.hostileEnvironments)
	var/datum/antag_training_program/antag/clockcult/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/clockcult/training/servant = program.role(session)
	var/datum/team/clockcult/training/team = servant.training_team
	var/obj/item/clockwork/slab/training/slab = servant.slab_ref?.resolve()
	TEST_ASSERT(antag_training_hold_slab(body, slab), "Слейт в активной руке.")
	slab.speed_multiplier = 0
	var/ark_script = "[/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training]"

	body.forceMove(arena.zones["melee"]["spawn"])
	antag_training_slab_act(slab, body, "recite", list("script" = ark_script))
	TEST_ASSERT(QDELETED(team.ark), "Вне станционного макета Ковчег не встаёт.")
	var/turf/ritual = station.landmark_turf("ritual")
	body.forceMove(ritual)
	antag_training_slab_act(slab, body, "recite", list("script" = ark_script))
	TEST_ASSERT(QDELETED(team.ark), "Без слуг вокруг Ковчег не встаёт.")

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Слуги для Ковчега"))
	var/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/round_ark = /datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar
	var/helpers = 0
	for(var/mob/living/carbon/human/helper in range(1, body))
		if(helper != body && antag_training_clock_team(helper) == team && (helper.mind in arena.target_minds))
			helpers++
	TEST_ASSERT_EQUAL(helpers, initial(round_ark.invokers_required) - 1, "Кнопка ставит недостающих слуг вплотную к участнику.")

	antag_training_slab_act(slab, body, "recite", list("script" = ark_script))
	var/obj/structure/destructible/antag_training_ark/ark = team.ark
	TEST_ASSERT(istype(ark) && get_turf(ark) == ritual, "Учебный Ковчег встаёт на месте чтения.")
	TEST_ASSERT(get_turf(body) != ritual && get_dist(body, ark) == 1, "Ковчег отодвигает стоящих на его клетке.")
	TEST_ASSERT(!(ark in GLOB.all_clockwork_objects) && !(ark in GLOB.poi_list), "Учебный Ковчег не в списках построек и интересных мест раунда.")
	TEST_ASSERT_EQUAL(antag_training_clock_snapshot(), clock_before, "Ковчег раунда не появился, сила и ступени прежние.")
	TEST_ASSERT(antag_training_clock_power_steady(power_before), "Общая сила культа: было [power_before], стало [GLOB.clockwork_power].")

	ark.attack_hand(body)
	TEST_ASSERT(ark.active, "Касание слуги запускает Ковчег.")
	TEST_ASSERT(abs(timeleft(ark.awaken_timer) - ANTAG_TRAINING_ARK_DELAY) < 1 SECONDS, "Учебный Ратвар пробуждается через ANTAG_TRAINING_ARK_DELAY.")
	TEST_ASSERT(!(ark in SSshuttle.hostileEnvironments) && length(SSshuttle.hostileEnvironments) == hostile_before, "Ковчег не держит шаттл.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Запуск не меняет уровень тревоги.")

	deltimer(ark.awaken_timer)
	ark.awaken()
	TEST_ASSERT(team.ratvar_awakened && QDELETED(ark), "Срок вышел - учебный Ратвар пробуждён, Ковчег исчезает.")
	TEST_ASSERT(locate(/obj/effect/temp_visual/antag_training_ratvar) in ritual, "Над местом Ковчега встаёт образ Ратвара.")
	TEST_ASSERT(findtext(session.ui_data(body)["last_feedback"], "Учебный Ратвар пробуждён"), "Пульт сообщает о пробуждении.")
	TEST_ASSERT_EQUAL(GLOB.security_level, security_before, "Пробуждение не меняет уровень тревоги.")
	TEST_ASSERT_EQUAL(antag_training_clock_snapshot(), clock_before, "Пробуждение не будит Ратвара раунда и не трогает силу культа.")
	TEST_ASSERT(antag_training_clock_power_steady(power_before), "Общая сила культа: было [power_before], стало [GLOB.clockwork_power].")
	for(var/atom/thing as anything in GLOB.poi_list)
		TEST_ASSERT(!istype(thing, /obj/structure/destructible/clockwork/massive/ratvar), "Настоящий Ратвар не создан.")

	qdel(session)
	TEST_ASSERT(wait_for_qdeleted(servant, 1 MINUTES), "Выход снимает роль слуги.")
	TEST_ASSERT(QDELETED(team), "Учебная команда снимается вместе со слугой.")

/obj/structure/destructible/clockwork/massive/celestial_gateway/unit_test
	purpose_fulfilled = TRUE
	second_sound_played = TRUE
	first_sound_played = TRUE

/obj/structure/destructible/clockwork/massive/celestial_gateway/unit_test/spawn_animation()
	return

/obj/structure/destructible/clockwork/massive/celestial_gateway/unit_test/conversion_pulse()
	return

/proc/antag_training_has_servitude(mob/living/target)
	for(var/mutable_appearance/overlay as anything in target.overlays)
		if(overlay.icon_state == "servitude")
			return TRUE
	return FALSE

/proc/antag_training_flash_timers(mob/target)
	. = 0
	for(var/datum/timedevent/timer as anything in SStimer.clienttime_timers)
		if(timer.callBack?.object == target)
			.++

/datum/unit_test/antag_training_clockcult_round_paths
	var/datum/antagonist/clockcult/round_role
	var/list/saved_players

/// Активный Ковчег раунда не тянет и не слепит слуг полигона и не метит их; рост культа раунда и рассылки Епископа их не считают.
/datum/unit_test/antag_training_clockcult_round_paths/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/clockcult)
	TEST_ASSERT(session.prepare(), "Полигон готовит слугу Ратвара.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	TEST_ASSERT(wait_for_var(station, "state", ANTAG_TRAINING_SECTOR_READY, 30 SECONDS), "Станционный макет загружается.")
	var/mob/living/carbon/human/body = session.current_body
	body.forceMove(station.landmark_turf("ritual"))
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/unit_test/round_ark = allocate(/obj/structure/destructible/clockwork/massive/celestial_gateway/unit_test, center)
	TEST_ASSERT_EQUAL(GLOB.ark_of_the_clockwork_justiciar, round_ark, "Ковчег раунда зарегистрирован.")
	round_ark.active = TRUE
	round_ark.seconds_until_activation = 0

	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Слуги для Ковчега"))
	var/list/arena_servants = list(body)
	for(var/mob/living/carbon/human/helper in range(1, body))
		if(helper != body && antag_training_clock_team(helper))
			arena_servants += helper
			TEST_ASSERT(!antag_training_has_servitude(helper), "Слуга полигона не получает метку активного Ковчега раунда.")
			helper.regenerate_icons()
			TEST_ASSERT(!antag_training_has_servitude(helper), "Перерисовка не возвращает слуге полигона метку Ковчега раунда.")
	TEST_ASSERT(length(arena_servants) > 1, "Учебные слуги встали.")

	var/mob/living/carbon/human/round_servant = allocate(/mob/living/carbon/human)
	round_servant.mind_initialize()
	allocated += round_servant.mind
	round_role = new
	round_role.silent = TRUE
	round_servant.mind.add_antag_datum(round_role)
	var/datum/team/clockcult/round_team = round_role.clock_team
	allocated += round_team
	round_servant.moveToNullspace()
	var/list/crew = list()
	for(var/index in 1 to 10)
		crew += allocate(/mob/living/carbon/human)

	var/turf/body_turf = get_turf(body)
	var/flashes_before = antag_training_flash_timers(body)
	var/power_before = GLOB.clockwork_power
	saved_players = GLOB.player_list
	GLOB.player_list = list(round_servant) + crew + arena_servants
	round_ark.process()
	GLOB.clockwork_power = power_before
	var/list/addressees = servants_and_ghosts()
	round_team.check_size()
	GLOB.player_list = saved_players
	saved_players = null

	TEST_ASSERT_EQUAL(get_turf(round_servant), get_step(round_ark, SOUTH), "Ковчег раунда стягивает своих слуг.")
	TEST_ASSERT_EQUAL(get_turf(body), body_turf, "Ковчег раунда не тянет слугу полигона.")
	TEST_ASSERT_EQUAL(antag_training_flash_timers(body), flashes_before, "Ковчег раунда не слепит слугу полигона попыткой переноса.")
	TEST_ASSERT((round_servant in addressees) && !(body in addressees), "Рассылки Епископа идут слугам раунда, но не слугам полигона.")
	TEST_ASSERT(!round_team.clock_risen && !round_team.clock_ascendent, "Слуги полигона не раздувают долю культа раунда.")

	var/atom/movable/screen/alert/clockwork/infodump/info = round_servant.alerts["clockinfo"]
	TEST_ASSERT_NOTNULL(info, "У слуги раунда есть сводка культа.")
	usr = round_servant
	info.MouseEntered()
	usr = null
	TEST_ASSERT(findtext(info.desc, "Сейчас у Ратвара <b>1</b>"), "Сводка культа раунда не считает слуг полигона: [info.desc]")

/datum/unit_test/antag_training_clockcult_round_paths/Destroy()
	if(saved_players)
		GLOB.player_list = saved_players
		saved_players = null
	if(!QDELETED(round_role))
		round_role.owner?.remove_antag_datum(/datum/antagonist/clockcult)
	round_role = null
	return ..()
